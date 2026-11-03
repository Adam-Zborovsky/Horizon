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

function sanitizeJsonText(text) {
  let cleaned = text.trim();
  if (cleaned.startsWith('```')) {
    cleaned = cleaned.replace(/^```(?:json)?\s*/i, '').replace(/\s*```$/, '').trim();
  }
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
  if (typeof baseUrl !== 'string' || !/^https?:\/\//.test(baseUrl)) {
    throw new TypeError('createOpenAICompatibleModelClient requires an http(s) RESEARCH_LLM_BASE_URL');
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
    let response = null;
    // Transport retries are a separate budget from the schema-repair attempts
    // (CONTRACTS §8): transient 429/5xx get one retry with short backoff.
    const retryStatuses = new Set([429, 500, 502, 503]);
    try {
      for (let attempt = 1; attempt <= 4; attempt += 1) {
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
        if (!retryStatuses.has(response.status) || attempt === 4) break;
        const delayMs = Math.min(10000, 2000 * Math.pow(2, attempt - 1));
        await new Promise((resolve) => setTimeout(resolve, delayMs));
      }
    } catch (error) {
      throw Object.assign(new Error(`model transport failed: ${error.name === 'AbortError' ? 'timeout' : error.message}`), { code: 'MODEL_CLIENT_FAILED' });
    } finally {
      clearTimeout(timer);
    }

    if (!response.ok) {
      // Status only — never the body (it can echo prompt fragments).
      throw Object.assign(new Error(`model endpoint returned HTTP ${response.status}`), { code: 'MODEL_CLIENT_FAILED' });
    }

    let payload;
    try {
      payload = await response.json();
    } catch (error) {
      throw Object.assign(new Error('model endpoint returned a non-JSON body'), { code: 'MODEL_CLIENT_FAILED' });
    }
    const text = payload?.choices?.[0]?.message?.content;
    if (typeof text !== 'string' || text.length === 0) {
      throw Object.assign(new Error('model response contained no message content'), { code: 'MODEL_CLIENT_FAILED' });
    }
    let output;
    try {
      output = JSON.parse(sanitizeJsonText(text));
    } catch (error) {
      if (payload?.choices?.[0]?.finish_reason === 'length') {
        throw Object.assign(new Error('model response was truncated (max_tokens reached)'), { code: 'MODEL_CLIENT_FAILED' });
      }
      throw Object.assign(new Error(`model response was not parseable JSON: ${error.message}`), { code: 'MODEL_CLIENT_FAILED' });
    }
    return {
      output,
      model,
      finish_reason: payload?.choices?.[0]?.finish_reason ?? null,
    };
  }

  return Object.freeze({ complete });
}

module.exports = { createOpenAICompatibleModelClient, deadlineTimeoutMs };
