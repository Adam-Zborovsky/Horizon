// Operator-provisioned model client: OpenAI-compatible chat completions
// (works with Gemini's OpenAI-compatible endpoint and any compatible proxy).
//
// Contract (H09 agent_runtime): modelClient.complete(request) where request is
// { system, user, context_digest?, deadline_at? } and the resolved value is
// { output: <parsed JSON object>, model, usage? }. Structured output is
// enforced server-side afterwards by result_validator — the client only
// guarantees "the model returned parseable JSON".
//
// Credentials come from backend/.env only (RESEARCH_LLM_*); they are never
// logged, never serialized into run artifacts, and never sent anywhere except
// the configured base URL.

const DEFAULT_TIMEOUT_MS = 120000;
const DEFAULT_MAX_OUTPUT_TOKENS = Number(process.env.RESEARCH_LLM_MAX_OUTPUT_TOKENS) || 16384;
// Every retry reaches the provider and may be billable. This is a *total*
// per-completion request budget, shared by malformed JSON and transient
// transport responses; nested retry loops would silently multiply spend.
const MAX_MODEL_REQUEST_ATTEMPTS = 2;

function sanitizeJsonText(text) {
  let cleaned = text.trim();
  const fenceMatch = cleaned.match(/```(?:json)?\s*([\s\S]*?)\s*```/i);
  if (fenceMatch) {
    cleaned = fenceMatch[1].trim();
  } else {
    const firstBrace = cleaned.indexOf('{');
    const lastBrace = cleaned.lastIndexOf('}');
    if (firstBrace !== -1 && lastBrace !== -1 && lastBrace > firstBrace) {
      cleaned = cleaned.substring(firstBrace, lastBrace + 1).trim();
    }
  }
  // Remove trailing commas before } or ]
  cleaned = cleaned.replace(/,\s*([\]}])/g, '$1');
  return cleaned;
}

function deadlineTimeoutMs(deadlineAt, now = () => new Date(), timeoutMs = DEFAULT_TIMEOUT_MS) {
  if (typeof deadlineAt !== 'string') return timeoutMs;
  const deadline = Date.parse(deadlineAt);
  if (!Number.isFinite(deadline)) return timeoutMs;
  const remaining = deadline - now().getTime() - 2000; // 2s transport margin
  if (!Number.isFinite(remaining) || remaining <= 0) return 0;
  return Math.min(timeoutMs, remaining);
}

function rejectWhenAborted(promise, signal) {
  if (signal.aborted) {
    const error = new Error('deadline exceeded');
    error.name = 'AbortError';
    return Promise.reject(error);
  }
  return new Promise((resolve, reject) => {
    const onAbort = () => {
      const error = new Error('deadline exceeded');
      error.name = 'AbortError';
      reject(error);
    };
    signal.addEventListener('abort', onAbort, { once: true });
    Promise.resolve(promise).then(
      (value) => {
        signal.removeEventListener('abort', onAbort);
        resolve(value);
      },
      (error) => {
        signal.removeEventListener('abort', onAbort);
        reject(error);
      },
    );
  });
}

function waitWhenNotAborted(delayMs, signal) {
  if (signal.aborted) {
    const error = new Error('deadline exceeded');
    error.name = 'AbortError';
    return Promise.reject(error);
  }
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      signal.removeEventListener('abort', onAbort);
      resolve();
    }, delayMs);
    const onAbort = () => {
      clearTimeout(timer);
      const error = new Error('deadline exceeded');
      error.name = 'AbortError';
      reject(error);
    };
    signal.addEventListener('abort', onAbort, { once: true });
  });
}

function createOpenAICompatibleModelClient({
  baseUrl,
  apiKey,
  model,
  timeoutMs = DEFAULT_TIMEOUT_MS,
  maxOutputTokens = DEFAULT_MAX_OUTPUT_TOKENS,
  temperature = 0.2,
  fetchImpl = globalThis.fetch,
  now = () => new Date(),
} = {}) {
  if (typeof baseUrl !== 'string' || !/^https:\/\//.test(baseUrl)) {
    throw new TypeError('createOpenAICompatibleModelClient requires an HTTPS RESEARCH_LLM_BASE_URL');
  }
  if (typeof apiKey !== 'string' || apiKey.length < 8) {
    throw new TypeError('createOpenAICompatibleModelClient requires RESEARCH_LLM_API_KEY');
  }
  if (typeof model !== 'string' || model.length === 0) {
    throw new TypeError('createOpenAICompatibleModelClient requires RESEARCH_LLM_MODEL');
  }
  if (typeof fetchImpl !== 'function') {
    throw new TypeError('createOpenAICompatibleModelClient requires a fetch implementation');
  }

  const endpoint = `${baseUrl.replace(/\/+$/, '')}/chat/completions`;

  async function complete(request) {
    if (!request || typeof request.user !== 'string' || request.user.length === 0) {
      throw Object.assign(new Error('model client requires a non-empty user prompt'), { code: 'MODEL_CLIENT_FAILED' });
    }
    const budgetMs = deadlineTimeoutMs(request.deadline_at, now, timeoutMs);
    if (budgetMs <= 0) {
      throw Object.assign(new Error('no time budget remains for a model call'), { code: 'MODEL_CLIENT_FAILED' });
    }
    const messages = [];
    if (typeof request.system === 'string' && request.system.length > 0) {
      messages.push({ role: 'system', content: request.system });
    }
    messages.push({ role: 'user', content: request.user });

    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), budgetMs);
    // The runtime has its own schema-repair budget. At this client boundary,
    // transient transport errors and malformed JSON share one extra request.
    const retryStatuses = new Set([429, 500, 502, 503]);
    try {
      for (let requestAttempt = 1; requestAttempt <= MAX_MODEL_REQUEST_ATTEMPTS; requestAttempt += 1) {
        let response;
        try {
          response = await fetchImpl(endpoint, {
              method: 'POST',
              headers: {
                'content-type': 'application/json',
                authorization: `Bearer ${apiKey}`,
              },
              body: JSON.stringify({
                model,
                messages,
                temperature,
                max_tokens: maxOutputTokens,
                reasoning_effort: process.env.RESEARCH_LLM_REASONING_EFFORT || 'low',
                response_format: { type: 'json_object' },
              }),
              signal: controller.signal,
          });
        } catch (error) {
          throw Object.assign(new Error(`model transport failed: ${error.name === 'AbortError' ? 'timeout' : error.message}`), { code: 'MODEL_CLIENT_FAILED' });
        }

        if (retryStatuses.has(response.status) && requestAttempt < MAX_MODEL_REQUEST_ATTEMPTS) {
          try {
            // Backoff itself observes the original deadline; it must not keep
            // the worker alive after the fetch has been aborted.
            await waitWhenNotAborted(2000, controller.signal);
          } catch (error) {
            throw Object.assign(new Error(`model transport failed: ${error.name === 'AbortError' ? 'timeout' : error.message}`), { code: 'MODEL_CLIENT_FAILED' });
          }
          continue;
        }
        if (!response.ok) {
          // Status only — never the body (it can echo prompt fragments).
          throw Object.assign(new Error(`model endpoint returned HTTP ${response.status}`), { code: 'MODEL_CLIENT_FAILED' });
        }

        let payload;
        try {
          // response.json() is not required to observe the request signal.
          // Race it explicitly so a stalled body cannot outlive the deadline.
          payload = await rejectWhenAborted(response.json(), controller.signal);
        } catch (error) {
          if (error.name === 'AbortError') {
            throw Object.assign(new Error('model endpoint response body timed out'), { code: 'MODEL_CLIENT_FAILED' });
          }
          throw Object.assign(new Error('model endpoint returned a non-JSON body'), { code: 'MODEL_CLIENT_FAILED' });
        }
        const text = payload?.choices?.[0]?.message?.content;
        if (typeof text !== 'string' || text.length === 0) {
          throw Object.assign(new Error('model response contained no message content'), { code: 'MODEL_CLIENT_FAILED' });
        }
        try {
          return {
            output: JSON.parse(sanitizeJsonText(text)),
            model,
            finish_reason: payload?.choices?.[0]?.finish_reason ?? null,
          };
        } catch (error) {
          if (payload?.choices?.[0]?.finish_reason === 'length') {
            throw Object.assign(new Error('model response was truncated (max_tokens reached)'), { code: 'MODEL_CLIENT_FAILED' });
          }
          if (requestAttempt === MAX_MODEL_REQUEST_ATTEMPTS) {
            // Do not include model content or parser detail; either can expose a prompt echo.
            throw Object.assign(new Error('model response was not parseable JSON after retry'), { code: 'MODEL_CLIENT_FAILED' });
          }
        }
      }
    } finally {
      // This timer spans every transport and JSON-repair attempt so retries
      // cannot extend the caller's original deadline.
      clearTimeout(timer);
    }
  }

  return Object.freeze({ complete });
}

module.exports = { createOpenAICompatibleModelClient, deadlineTimeoutMs };
