'use strict';

const assert = require('node:assert/strict');
const http = require('node:http');
const test = require('node:test');
const express = require('express');

const { createResearchRouter } = require('../src/features/research/research.routes');

const OWNER_A = 'owner-route-a';
const OWNER_B = 'owner-route-b';
const POSITION = Object.freeze({
  _id: 'pos-route-1',
  owner_id: OWNER_A,
  revision: 7,
  instrument: { instrument_id: 'instrument-route-1' },
});

async function withServer(app, fn) {
  const server = http.createServer(app);
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  try {
    await fn(`http://127.0.0.1:${server.address().port}`);
  } finally {
    await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
  }
}

async function queue(baseUrl, owner, body, key) {
  const response = await fetch(`${baseUrl}/api/v1/research/positions/${POSITION._id}/runs`, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      'idempotency-key': key,
      'x-test-owner': owner,
    },
    body: JSON.stringify(body),
  });
  return { status: response.status, body: await response.json() };
}

test('manual queue resolves the route position in owner scope and rejects supplied binding mismatches', async () => {
  const lookups = [];
  const queued = [];
  const service = {
    async queueRun(request) {
      queued.push(request);
      return {
        run: { id: `run-${queued.length}`, status: 'queued', ...request },
        idempotent_replay: false,
      };
    },
    async getRun() { return null; },
    async getPositionResearchState() { return {}; },
    async listAssessments() { return { assessments: [], next_cursor: null }; },
  };
  const app = express();
  app.use(express.json());
  app.use('/api/v1/research', createResearchRouter({
    researchService: service,
    authenticate: (req, _res, next) => {
      req.user = { _id: req.get('x-test-owner') };
      next();
    },
    positionLookup: async (positionId, ownerId) => {
      lookups.push({ positionId, ownerId });
      return positionId === POSITION._id && ownerId === OWNER_A ? POSITION : null;
    },
  }));

  await withServer(app, async (baseUrl) => {
    const crossOwner = await queue(baseUrl, OWNER_B, {
      position_revision: POSITION.revision,
      instrument_id: POSITION.instrument.instrument_id,
      request_payload: { trigger: 'manual' },
    }, 'cross-owner');
    assert.equal(crossOwner.status, 404);
    assert.equal(crossOwner.body.code, 'NOT_FOUND');
    assert.equal(queued.length, 0);

    const staleRevision = await queue(baseUrl, OWNER_A, {
      position_revision: POSITION.revision - 1,
      instrument_id: POSITION.instrument.instrument_id,
      request_payload: { trigger: 'manual' },
    }, 'stale-revision');
    assert.equal(staleRevision.status, 409);
    assert.equal(staleRevision.body.code, 'REVISION_CONFLICT');
    assert.equal(queued.length, 0);

    const swappedInstrument = await queue(baseUrl, OWNER_A, {
      position_revision: POSITION.revision,
      instrument_id: 'instrument-other-owner',
      request_payload: { trigger: 'manual' },
    }, 'swapped-instrument');
    assert.equal(swappedInstrument.status, 400);
    assert.equal(swappedInstrument.body.code, 'INVALID_INPUT');
    assert.equal(queued.length, 0);

    // The owner-scoped lookup remains mandatory even when body values are
    // omitted; only the server-resolved position binding reaches queueRun.
    const canonical = await queue(baseUrl, OWNER_A, {
      request_payload: { trigger: 'manual' },
    }, 'canonical');
    assert.equal(canonical.status, 202);
    assert.deepEqual(queued, [{
      owner_id: OWNER_A,
      position_id: POSITION._id,
      position_revision: POSITION.revision,
      instrument_id: POSITION.instrument.instrument_id,
      run_kind: 'manual_refresh',
      idempotency_key: 'canonical',
      request_payload: { trigger: 'manual' },
    }]);
  });

  assert.deepEqual(lookups, [
    { positionId: POSITION._id, ownerId: OWNER_B },
    { positionId: POSITION._id, ownerId: OWNER_A },
    { positionId: POSITION._id, ownerId: OWNER_A },
    { positionId: POSITION._id, ownerId: OWNER_A },
  ]);
});
