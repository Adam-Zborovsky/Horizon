'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');

const { createOpenAICompatibleModelClient } = require('../src/features/research/model_client');

function completion(content, finishReason = 'stop') {
  return {
    ok: true,
    status: 200,
    json: async () => ({
      choices: [{ message: { content }, finish_reason: finishReason }],
    }),
  };
}

function createClient(fetchImpl, options = {}) {
  return createOpenAICompatibleModelClient({
    baseUrl: 'https://model.example/v1',
    apiKey: 'test-api-key',
    model: 'fixture-model',
    fetchImpl,
    ...options,
  });
}

test('model client requires an HTTPS provider URL before it can send an API key', () => {
  assert.throws(
    () => createOpenAICompatibleModelClient({
      baseUrl: 'http://model.example/v1',
      apiKey: 'fixture-key-12345',
      model: 'fixture-model',
      fetchImpl: async () => completion('{}'),
    }),
    /HTTPS RESEARCH_LLM_BASE_URL/,
  );
});

test('model client retries one malformed completion and returns the next valid JSON object', async () => {
  const responses = [
    completion('{ malformed JSON'),
    completion('{"recommendation":"hold"}'),
  ];
  const calls = [];
  const client = createClient(async (url, options) => {
    calls.push({ url, options });
    return responses.shift();
  });

  const result = await client.complete({ user: 'synthetic prompt' });

  assert.deepEqual(result.output, { recommendation: 'hold' });
  assert.equal(result.model, 'fixture-model');
  assert.equal(calls.length, 2);
  assert.equal(calls[0].url, 'https://model.example/v1/chat/completions');
  assert.equal(calls[0].options.signal, calls[1].options.signal, 'retries share the original deadline');
});

test('model client stops after its bounded malformed-JSON retry without exposing completion content', async () => {
  let calls = 0;
  const client = createClient(async () => {
    calls += 1;
    return completion('{ secret-prompt-echo');
  });

  await assert.rejects(
    () => client.complete({ user: 'synthetic prompt' }),
    (error) => error.code === 'MODEL_CLIENT_FAILED'
      && error.message === 'model response was not parseable JSON after retry'
      && !error.message.includes('secret-prompt-echo'),
  );
  assert.equal(calls, 2, 'malformed JSON creates exactly one additional paid request');
});

test('model client deadline covers a stalled response body', async () => {
  const client = createClient(async () => ({
    ok: true,
    status: 200,
    json: () => new Promise(() => {}),
  }), { timeoutMs: 25 });

  await assert.rejects(
    () => client.complete({ user: 'synthetic prompt' }),
    (error) => error.code === 'MODEL_CLIENT_FAILED'
      && error.message === 'model endpoint response body timed out',
  );
});

test('model client deadline interrupts transport backoff before another provider request', async () => {
  let calls = 0;
  const client = createClient(async () => {
    calls += 1;
    return { ok: false, status: 429, json: async () => ({}) };
  }, { timeoutMs: 25 });

  await assert.rejects(
    () => client.complete({ user: 'synthetic prompt' }),
    (error) => error.code === 'MODEL_CLIENT_FAILED'
      && error.message === 'model transport failed: timeout',
  );
  assert.equal(calls, 1, 'an expired backoff must not start another provider request');
});
