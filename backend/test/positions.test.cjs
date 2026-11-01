const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const http = require('node:http');
const test = require('node:test');
const express = require('express');

const Position = require('../src/features/positions/position.model');
const {
  PositionService,
  planLegacyMigration,
  reconcileLegacyTickerUpdate,
  legacyInstrumentId,
} = require('../src/features/positions/position.service');
const { createPositionRouter } = require('../src/features/positions/position.routes');

// ---------------------------------------------------------------------------
// Hermetic in-memory repository (no MongoDB touched anywhere in this suite)
// ---------------------------------------------------------------------------
function makeRepository(seed = []) {
  const docs = new Map();
  let nextId = 1;
  let seedTick = 0;
  for (const doc of seed) {
    const id = doc.id || `pos-${nextId++}`;
    seedTick += 1;
    const stored = {
      revision: 1,
      archived: false,
      owner_id: 'owner-1',
      preferred_horizon_months: 3,
      original_thesis: '',
      review_conditions: [],
      risk_context: null,
      created_at: new Date(Date.UTC(2026, 9, 31, 11, 0, seedTick)).toISOString(),
      updated_at: new Date(Date.UTC(2026, 9, 31, 11, 0, seedTick)).toISOString(),
      ...structuredClone(doc),
      id,
    };
    docs.set(id, stored);
  }
  return {
    docs,
    async findActive(ownerId, instrumentId) {
      for (const doc of docs.values()) {
        if (doc.owner_id === ownerId && doc.instrument.instrument_id === instrumentId && !doc.archived) {
          return structuredClone(doc);
        }
      }
      return null;
    },
    async listByOwner(ownerId) {
      return [...docs.values()]
        .filter((d) => d.owner_id === ownerId)
        .sort((a, b) => a.created_at.localeCompare(b.created_at))
        .map((d) => structuredClone(d));
    },
    async findById(id) {
      return docs.has(id) ? structuredClone(docs.get(id)) : null;
    },
    async insert(doc) {
      const id = `pos-${nextId++}`;
      const stored = structuredClone(doc);
      stored.id = id;
      docs.set(id, stored);
      return structuredClone(stored);
    },
    async update(doc) {
      docs.set(doc.id, structuredClone(doc));
      return structuredClone(doc);
    },
  };
}

function makeService(seed = [], overrides = {}) {
  const repository = overrides.repository || makeRepository(seed);
  let tick = 0;
  const now = overrides.now || (() => {
    tick += 1;
    return new Date(Date.UTC(2026, 9, 31, 12, 0, tick));
  });
  const service = new PositionService({ positionRepository: repository, now });
  return { service, repository };
}

const OWNED_INPUT = Object.freeze({
  state: 'owned',
  instrument: {
    instrument_id: 'inst-MSFT-US',
    symbol: 'MSFT',
    exchange: 'NASDAQ',
    currency: 'USD',
    provider_symbol: 'MSFT',
  },
  average_cost: { amount: '100.25', currency: 'USD' },
  quantity: '2',
  opened_on: '2026-01-15',
  preferred_horizon_months: 3,
});

const CANDIDATE_INPUT = Object.freeze({
  state: 'candidate',
  instrument: {
    instrument_id: 'inst-NVDA-US',
    symbol: 'NVDA',
    exchange: 'NASDAQ',
    currency: 'USD',
    provider_symbol: 'NVDA',
  },
  review_conditions: ['Enters below 90 on rising volume'],
});

// ---------------------------------------------------------------------------
// 1. Model schema validation (offline validateSync — no DB connection)
// ---------------------------------------------------------------------------
test('model: accepts a valid owned position document', () => {
  const doc = new Position({ owner_id: 'owner-1', ...structuredClone(OWNED_INPUT) });
  const error = doc.validateSync();
  assert.equal(error, undefined);
});

test('model: candidate documents reject cost/quantity/open date', () => {
  const doc = new Position({
    owner_id: 'owner-1',
    ...structuredClone(CANDIDATE_INPUT),
    average_cost: { amount: '10', currency: 'USD' },
  });
  const error = doc.validateSync();
  assert.ok(error, 'expected validation error');
  const fields = Object.keys(error.errors || {});
  assert.ok(fields.some((f) => f.startsWith('average_cost')), `average_cost error expected, got: ${JSON.stringify(fields)}`);
});

test('model: legacy_unclassified documents reject any economics', () => {
  const doc = new Position({
    owner_id: 'owner-1',
    state: 'legacy_unclassified',
    instrument: { instrument_id: legacyInstrumentId('AAPL'), symbol: 'AAPL' },
    quantity: '5',
  });
  const error = doc.validateSync();
  assert.ok(error, 'expected validation error');
  assert.ok('quantity' in error.errors);
});

test('model: unknown top-level fields are rejected (strict throw)', () => {
  assert.throws(() => new Position({ owner_id: 'owner-1', bogus_field: 'x', ...structuredClone(CANDIDATE_INPUT) }));
});

test('model: rejects non-ISO currency, non-positive amounts and malformed decimals', () => {
  const bad = [
    { amount: '-1', currency: 'USD' },
    { amount: '0', currency: 'USD' },
    { amount: 'abc', currency: 'USD' },
    { amount: '1e5', currency: 'USD' },
    { amount: '10', currency: 'usd' },
    { amount: '10', currency: 'USDD' },
    { amount: '10', currency: '12A' },
  ];
  for (const average_cost of bad) {
    const doc = new Position({ owner_id: 'owner-1', ...structuredClone(OWNED_INPUT), average_cost });
    const error = doc.validateSync();
    const fields = Object.keys((error && error.errors) || {});
    assert.ok(fields.some((f) => f.startsWith('average_cost')), `expected rejection for ${JSON.stringify(average_cost)}, got: ${JSON.stringify(fields)}`);
  }
});

test('model: rejects malformed opened_on calendar dates', () => {
  for (const opened_on of ['2026-02-30', '2026-13-01', '31-12-2026', '2026-1-5', 'not-a-date']) {
    const doc = new Position({ owner_id: 'owner-1', ...structuredClone(OWNED_INPUT), opened_on });
    const error = doc.validateSync();
    assert.ok(error && error.errors.opened_on, `expected rejection for ${opened_on}`);
  }
  const ok = new Position({ owner_id: 'owner-1', ...structuredClone(OWNED_INPUT), opened_on: '2024-02-29' });
  assert.equal(ok.validateSync(), undefined, 'leap day must validate');
});

// ---------------------------------------------------------------------------
// 2. Service input validation
// ---------------------------------------------------------------------------
test('service: decimal validation matrix', async () => {
  const { service } = makeService();
  const bad = ['abc', '-1', '0', '-0.5', '1e5', 'NaN', 'Infinity', '', '1..2', '+1', '1,5', '0x10'];
  for (const amount of bad) {
    await assert.rejects(
      () => service.create('owner-1', { ...structuredClone(OWNED_INPUT), average_cost: { amount, currency: 'USD' } }),
      (err) => err.code === 'INVALID_DECIMAL',
      `expected INVALID_DECIMAL for ${JSON.stringify(amount)}`,
    );
  }
  for (const good of ['0.5', '100', '1234.56789012', '0.00000001']) {
    const created = await service.create('owner-1', {
      ...structuredClone(OWNED_INPUT),
      instrument: { ...OWNED_INPUT.instrument, instrument_id: `inst-x-${crypto.randomUUID()}`, symbol: 'X' },
      average_cost: { amount: good, currency: 'USD' },
    });
    assert.equal(created.average_cost.amount, good);
  }
});

test('service: candidate creation with economics is rejected — desired entry belongs in review_conditions', async () => {
  const { service } = makeService();
  await assert.rejects(
    () => service.create('owner-1', {
      ...structuredClone(CANDIDATE_INPUT),
      average_cost: { amount: '90', currency: 'USD' },
    }),
    (err) => err.code === 'INVALID_CANDIDATE_ECONOMICS',
  );
});

test('service: legacy_unclassified positions carry null economics — no cost inferred from tickers or prose', async () => {
  const { service } = makeService();
  const created = await service.create('owner-1', {
    state: 'legacy_unclassified',
    instrument: { instrument_id: legacyInstrumentId('AAPL'), symbol: 'AAPL' },
    original_thesis: 'I probably bought this around 120 with fees',
  });
  assert.equal(created.average_cost, null);
  assert.equal(created.quantity, null);
  assert.equal(created.opened_on, null);
  assert.equal(created.state, 'legacy_unclassified');
});

// H11 cross-lane empty-thesis repair: RED-FIRST regression. On the pre-repair
// service this fails — create stored '' and serialize emitted it verbatim, so
// the wire carried original_thesis: '' and the H11 Dart parser
// (optionalBoundedText) rejected it with ContractFormatException, silently
// breaking the primary create path.
test('service: create without original_thesis serializes null, never empty string', async () => {
  const { service } = makeService();
  const created = await service.create('owner-1', structuredClone(CANDIDATE_INPUT));
  assert.equal(created.original_thesis, null, 'absent thesis must serialize as null');
  assert.notEqual(created.original_thesis, '');
  assert.ok(!JSON.stringify(created).includes('"original_thesis":""'),
    'wire must never carry an empty-string original_thesis');

  // Explicit null at create is treated as absent (CONTRACTS §2: optional field).
  const explicitNull = await service.create('owner-1', {
    ...structuredClone(CANDIDATE_INPUT),
    instrument: { ...CANDIDATE_INPUT.instrument, instrument_id: 'inst-null-thesis' },
    original_thesis: null,
  });
  assert.equal(explicitNull.original_thesis, null);

  // Legacy stored rows may still carry '' (pre-repair default) — serialize
  // normalizes at the wire boundary so every producer sees null.
  const legacy = makeService([{ id: 'pos-legacy-empty', ...structuredClone(OWNED_INPUT), original_thesis: '' }]);
  const fetched = await legacy.service.get('owner-1', 'pos-legacy-empty');
  assert.equal(fetched.original_thesis, null, "legacy stored '' must serialize as null");
  const listed = await legacy.service.list('owner-1');
  assert.ok(listed.length >= 1);
  for (const doc of listed) {
    assert.equal(doc.original_thesis, null);
  }

  // Overlength validation is unchanged.
  const { service: svc2 } = makeService();
  await assert.rejects(
    () => svc2.create('owner-1', {
      ...structuredClone(CANDIDATE_INPUT),
      instrument: { ...CANDIDATE_INPUT.instrument, instrument_id: 'inst-long-thesis' },
      original_thesis: 'x'.repeat(5001),
    }),
    (err) => err.code === 'INVALID_INPUT',
  );
});

test('service: unknown fields in create and update payloads are rejected', async () => {
  const { service } = makeService();
  await assert.rejects(
    () => service.create('owner-1', { ...structuredClone(CANDIDATE_INPUT), nifty_extra: true }),
    (err) => err.code === 'UNKNOWN_FIELD',
  );
  const { service: svc2 } = makeService([structuredClone(OWNED_INPUT)]);
  const listed = await svc2.list('owner-1');
  await assert.rejects(
    () => svc2.update('owner-1', listed[0].id, { expected_revision: 1, changes: { sneaky: 1 } }),
    (err) => err.code === 'UNKNOWN_FIELD',
  );
});

// ---------------------------------------------------------------------------
// 3. Owner isolation (server-derived owner)
// ---------------------------------------------------------------------------
test('service: another owner gets an indistinguishable NOT_FOUND, never a leak', async () => {
  const { service } = makeService([structuredClone(OWNED_INPUT)]);
  const listed = await service.list('owner-1');
  assert.equal(listed.length, 1);
  const missing = await service.get('owner-2', 'pos-does-not-exist').then(
    () => { throw new Error('should have thrown'); },
    (err) => err,
  );
  const foreign = await service.get('owner-2', listed[0].id).then(
    () => { throw new Error('should have thrown'); },
    (err) => err,
  );
  assert.equal(missing.code, 'NOT_FOUND');
  assert.equal(foreign.code, 'NOT_FOUND');
  assert.equal(missing.message, foreign.message, 'indistinguishable denial');
  await assert.rejects(
    () => service.update('owner-2', listed[0].id, { expected_revision: 1, changes: {} }),
    (err) => err.code === 'NOT_FOUND',
  );
});

test('service: owner fields are not writable by clients (server-derived owner)', async () => {
  const { service } = makeService();
  await assert.rejects(
    () => service.create('attacker-1', { ...structuredClone(CANDIDATE_INPUT), owner_id: 'victim-9' }),
    (err) => err.code === 'OWNER_FIELD_NOT_WRITABLE',
  );
  await assert.rejects(
    () => service.create('attacker-1', { ...structuredClone(CANDIDATE_INPUT), user_id: 'victim-9' }),
    (err) => err.code === 'OWNER_FIELD_NOT_WRITABLE',
  );
});

test('service: list is scoped to the authenticated owner', async () => {
  const { service } = makeService([structuredClone(OWNED_INPUT)]);
  await service.create('owner-2', structuredClone(CANDIDATE_INPUT));
  const mine = await service.list('owner-1');
  const theirs = await service.list('owner-2');
  assert.equal(mine.length, 1);
  assert.equal(mine[0].instrument.symbol, 'MSFT');
  assert.equal(theirs.length, 1);
  assert.equal(theirs[0].instrument.symbol, 'NVDA');
});

test('service: serialized positions never expose owner_id', async () => {
  const { service } = makeService([structuredClone(OWNED_INPUT)]);
  const listed = await service.list('owner-1');
  assert.equal('owner_id' in listed[0], false);
  const single = await service.get('owner-1', listed[0].id);
  assert.equal('owner_id' in single, false);
});

// ---------------------------------------------------------------------------
// 4. Duplicate identity
// ---------------------------------------------------------------------------
test('service: duplicate active identity for the same owner returns 409-class error', async () => {
  const { service } = makeService([structuredClone(OWNED_INPUT)]);
  await assert.rejects(
    () => service.create('owner-1', structuredClone(OWNED_INPUT)),
    (err) => err.code === 'DUPLICATE_POSITION',
  );
});

test('service: same instrument for different owners is allowed', async () => {
  const { service } = makeService([structuredClone(OWNED_INPUT)]);
  const created = await service.create('owner-2', structuredClone(OWNED_INPUT));
  assert.equal(created.instrument.symbol, 'MSFT');
});

test('service: archived positions free the identity; unarchive conflicts with a newer active position', async () => {
  const { service } = makeService([structuredClone(OWNED_INPUT)]);
  const listed = await service.list('owner-1');
  await service.update('owner-1', listed[0].id, { expected_revision: 1, changes: { archived: true } });
  const recreated = await service.create('owner-1', structuredClone(OWNED_INPUT));
  assert.equal(recreated.archived, false);
  await assert.rejects(
    () => service.update('owner-1', listed[0].id, { expected_revision: 2, changes: { archived: false } }),
    (err) => err.code === 'DUPLICATE_POSITION',
  );
});

// ---------------------------------------------------------------------------
// 5. Transitions
// ---------------------------------------------------------------------------
test('service: candidate -> owned is an explicit action with validated economics', async () => {
  const { service } = makeService([structuredClone(CANDIDATE_INPUT)]);
  const listed = await service.list('owner-1');
  const updated = await service.update('owner-1', listed[0].id, {
    expected_revision: 1,
    changes: {
      state: 'owned',
      average_cost: { amount: '88.5', currency: 'USD' },
      quantity: '10',
      opened_on: '2026-03-02',
    },
  });
  assert.equal(updated.state, 'owned');
  assert.equal(updated.average_cost.amount, '88.5');
  assert.equal(updated.revision, 2);
});

test('service: owned -> candidate clears active economics and preserves the audit trail via revision', async () => {
  const { service } = makeService([structuredClone(OWNED_INPUT)]);
  const listed = await service.list('owner-1');
  const updated = await service.update('owner-1', listed[0].id, {
    expected_revision: 1,
    changes: { state: 'candidate' },
  });
  assert.equal(updated.state, 'candidate');
  assert.equal(updated.average_cost, null);
  assert.equal(updated.quantity, null);
  assert.equal(updated.opened_on, null);
  assert.equal(updated.revision, 2);
});

test('service: invalid transitions are rejected', async () => {
  const { service } = makeService([structuredClone(OWNED_INPUT), structuredClone(CANDIDATE_INPUT)]);
  const owned = (await service.list('owner-1'))[0];
  await assert.rejects(
    () => service.update('owner-1', owned.id, { expected_revision: 1, changes: { state: 'legacy_unclassified' } }),
    (err) => err.code === 'INVALID_TRANSITION',
  );
  const candidate = (await service.list('owner-1'))[1];
  await assert.rejects(
    () => service.update('owner-1', candidate.id, { expected_revision: 1, changes: { state: 'legacy_unclassified' } }),
    (err) => err.code === 'INVALID_TRANSITION',
  );
});

test('service: transition to owned with malformed economics fails and leaves the position untouched', async () => {
  const { service } = makeService([structuredClone(CANDIDATE_INPUT)]);
  const listed = await service.list('owner-1');
  await assert.rejects(
    () => service.update('owner-1', listed[0].id, {
      expected_revision: 1,
      changes: { state: 'owned', average_cost: { amount: '0', currency: 'USD' } },
    }),
    (err) => err.code === 'INVALID_DECIMAL',
  );
  const unchanged = await service.get('owner-1', listed[0].id);
  assert.equal(unchanged.state, 'candidate');
  assert.equal(unchanged.revision, 1);
});

// ---------------------------------------------------------------------------
// 6. Optimistic concurrency (revision)
// ---------------------------------------------------------------------------
test('service: missing or stale expected_revision is rejected; correct revision increments', async () => {
  const { service } = makeService([structuredClone(OWNED_INPUT)]);
  const listed = await service.list('owner-1');
  const id = listed[0].id;

  await assert.rejects(
    () => service.update('owner-1', id, { changes: { preferred_horizon_months: 2 } }),
    (err) => err.code === 'MISSING_EXPECTED_REVISION',
  );
  await assert.rejects(
    () => service.update('owner-1', id, { expected_revision: 99, changes: { preferred_horizon_months: 2 } }),
    (err) => err.code === 'REVISION_CONFLICT',
  );
  const updated = await service.update('owner-1', id, {
    expected_revision: 1,
    changes: { preferred_horizon_months: 2 },
  });
  assert.equal(updated.revision, 2);
  assert.equal(updated.preferred_horizon_months, 2);
});

// ---------------------------------------------------------------------------
// 7. P/L guards — misleading economics must be blocked, not approximated
// ---------------------------------------------------------------------------
const quote = (over = {}) => ({ current_price: 150, currency: 'USD', adjustment_basis: 'raw', ...over });

test('pl: unknown cost stays null and P/L is unavailable with unknown_cost', async () => {
  const { service } = makeService([structuredClone(OWNED_INPUT)]);
  const listed = await service.list('owner-1');
  await service.update('owner-1', listed[0].id, { expected_revision: 1, changes: { average_cost: null } });
  const refreshed = await service.get('owner-1', listed[0].id);
  assert.equal(refreshed.average_cost, null);
  const pl = service.computeProfitLoss(refreshed, quote());
  assert.equal(pl.status, 'unavailable');
  assert.equal(pl.reason, 'unknown_cost');
});

test('pl: currency mismatch blocks comparable P/L without silent FX approximation', async () => {
  const { service } = makeService([structuredClone(OWNED_INPUT)]);
  const listed = await service.list('owner-1');
  const pl = service.computeProfitLoss(listed[0], quote({ currency: 'EUR' }));
  assert.equal(pl.status, 'unavailable');
  assert.equal(pl.reason, 'currency_mismatch');
});

test('pl: unreconciled split basis blocks comparable P/L with explanation', async () => {
  const { service } = makeService([structuredClone(OWNED_INPUT)]);
  const listed = await service.list('owner-1');
  const pl = service.computeProfitLoss(listed[0], quote({ adjustment_basis: 'split_adjusted' }));
  assert.equal(pl.status, 'unavailable');
  assert.equal(pl.reason, 'split_basis_unreconciled');
});

test('pl: matching basis yields decimal percent; absolute requires quantity; fees/dividends labeled excluded', async () => {
  const { service } = makeService([structuredClone(OWNED_INPUT)]);
  const listed = await service.list('owner-1');
  const pl = service.computeProfitLoss(listed[0], quote({ current_price: 150 }));
  assert.equal(pl.status, 'available');
  assert.equal(pl.percent, '49.62593516');
  assert.equal(pl.absolute.amount, '99.5');
  assert.equal(pl.absolute.currency, 'USD');
  assert.equal(pl.fees_included, false);
  assert.equal(pl.dividends_included, false);

  const noQuantity = await service.create('owner-1', {
    state: 'owned',
    instrument: { instrument_id: 'inst-noq', symbol: 'NOQ', exchange: 'NASDAQ', currency: 'USD', provider_symbol: 'NOQ' },
    average_cost: { amount: '100', currency: 'USD' },
    quantity: null,
    opened_on: '2026-01-15',
  });
  const pl2 = service.computeProfitLoss(noQuantity, quote());
  assert.equal(pl2.status, 'available');
  assert.equal(pl2.percent, '50');
  assert.equal(pl2.absolute, null, 'absolute P/L requires quantity');
});

test('pl: candidate and legacy_unclassified positions have no owned economics', async () => {
  const { service } = makeService([structuredClone(CANDIDATE_INPUT)]);
  const listed = await service.list('owner-1');
  const pl = service.computeProfitLoss(listed[0], quote());
  assert.equal(pl.status, 'unavailable');
  assert.equal(pl.reason, 'position_not_owned');
});

// ---------------------------------------------------------------------------
// 8. HTTP routes
// ---------------------------------------------------------------------------
async function withServer(router, fn) {
  const app = express();
  app.use(express.json({ limit: '1mb' }));
  app.use(router);
  const server = http.createServer(app);
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  try {
    const { port } = server.address();
    await fn(`http://127.0.0.1:${port}`);
  } finally {
    await new Promise((resolve, reject) => server.close((e) => (e ? reject(e) : resolve())));
  }
}

async function requestJson(baseUrl, path, options = {}) {
  const response = await fetch(`${baseUrl}${path}`, options);
  let body = null;
  try { body = await response.json(); } catch { /* non-JSON */ }
  return { status: response.status, body };
}

test('routes: auth is enforced, owner is server-derived, full CRUD behaves per contract', async () => {
  const { service } = makeService();
  const authenticate = (req, res, next) => {
    const token = req.headers.authorization?.replace('Bearer ', '');
    const user = { alice: 'owner-1', bob: 'owner-2' }[token || ''];
    if (!user) return res.status(401).json({ code: 'UNAUTHENTICATED' });
    req.user = { _id: user };
    next();
  };
  const router = createPositionRouter({ positionService: service, authenticate });
  await withServer(router, async (baseUrl) => {
    // 401 without credentials
    const anon = await requestJson(baseUrl, '/');
    assert.equal(anon.status, 401);

    const aliceHeaders = { authorization: 'Bearer alice', 'content-type': 'application/json' };
    const bobHeaders = { authorization: 'Bearer bob', 'content-type': 'application/json' };

    // 201 create, owner derived from JWT, not from body
    const created = await requestJson(baseUrl, '/', {
      method: 'POST',
      headers: aliceHeaders,
      body: JSON.stringify(structuredClone(OWNED_INPUT)),
    });
    assert.equal(created.status, 201);
    assert.equal('owner_id' in created.body, false);
    assert.equal(created.body.state, 'owned');
    const positionId = created.body.id;

    // duplicate active identity -> 409
    const dup = await requestJson(baseUrl, '/', {
      method: 'POST',
      headers: aliceHeaders,
      body: JSON.stringify(structuredClone(OWNED_INPUT)),
    });
    assert.equal(dup.status, 409);

    // cross-owner PATCH -> 404 indistinguishable from missing
    const foreign = await requestJson(baseUrl, `/${positionId}`, {
      method: 'PATCH',
      headers: bobHeaders,
      body: JSON.stringify({ expected_revision: 1, changes: { archived: true } }),
    });
    assert.equal(foreign.status, 404);
    const missing = await requestJson(baseUrl, '/pos-nope', {
      method: 'PATCH',
      headers: bobHeaders,
      body: JSON.stringify({ expected_revision: 1, changes: { archived: true } }),
    });
    assert.equal(missing.status, 404);
    assert.deepEqual(foreign.body, missing.body);

    // stale revision -> 409; valid revision -> 200
    const stale = await requestJson(baseUrl, `/${positionId}`, {
      method: 'PATCH',
      headers: aliceHeaders,
      body: JSON.stringify({ expected_revision: 99, changes: { preferred_horizon_months: 1 } }),
    });
    assert.equal(stale.status, 409);
    const okPatch = await requestJson(baseUrl, `/${positionId}`, {
      method: 'PATCH',
      headers: aliceHeaders,
      body: JSON.stringify({ expected_revision: 1, changes: { preferred_horizon_months: 1 } }),
    });
    assert.equal(okPatch.status, 200);
    assert.equal(okPatch.body.revision, 2);

    // unknown field in write -> 400
    const unknown = await requestJson(baseUrl, '/', {
      method: 'POST',
      headers: aliceHeaders,
      body: JSON.stringify({ ...structuredClone(CANDIDATE_INPUT), evil: 1 }),
    });
    assert.equal(unknown.status, 400);

    // owner spoof -> 400
    const spoof = await requestJson(baseUrl, '/', {
      method: 'POST',
      headers: aliceHeaders,
      body: JSON.stringify({ ...structuredClone(CANDIDATE_INPUT), owner_id: 'victim' }),
    });
    assert.equal(spoof.status, 400);

    // list scoped per owner
    const aliceList = await requestJson(baseUrl, '/', { headers: aliceHeaders });
    const bobList = await requestJson(baseUrl, '/', { headers: bobHeaders });
    assert.equal(aliceList.status, 200);
    assert.equal(aliceList.body.positions.length, 1);
    assert.equal(bobList.body.positions.length, 0);
  });
});

// ---------------------------------------------------------------------------
// 9. Migration planner (pure functions, isolated fixtures — no DB anywhere)
// ---------------------------------------------------------------------------
function legacyFixture(over = {}) {
  return {
    owner_id: 'owner-1',
    tickers: ['MSFT', 'AAPL'],
    ...over,
  };
}

test('migration: legacy tickers import as legacy_unclassified with null economics and exact counts', () => {
  const plan = planLegacyMigration({
    configs: [legacyFixture()],
    existingPositions: [],
    now: new Date('2026-10-31T00:00:00Z'),
  });
  assert.equal(plan.dry_run, true);
  assert.equal(plan.source_counts.briefing_configs_scanned, 1);
  assert.equal(plan.source_counts.tickers_seen, 2);
  assert.equal(plan.planned.positions_to_create, 2);
  assert.equal(plan.planned.duplicates_skipped, 0);
  for (const change of plan.changes) {
    assert.equal(change.op, 'insert_position');
    assert.equal(change.document.state, 'legacy_unclassified');
    assert.equal(change.document.average_cost, null);
    assert.equal(change.document.quantity, null);
    assert.equal(change.document.opened_on, null);
    assert.equal(change.document.instrument.currency, null, 'no currency inferred from a bare ticker');
    assert.equal(change.document.instrument.exchange, null, 'no exchange inferred from a bare ticker');
  }
  const symbols = plan.changes.map((c) => c.document.instrument.symbol).sort();
  assert.deepEqual(symbols, ['AAPL', 'MSFT']);
});

test('migration: second run is idempotent — zero new changes for existing active positions', () => {
  const first = planLegacyMigration({
    configs: [legacyFixture()],
    existingPositions: [],
    now: new Date('2026-10-31T00:00:00Z'),
  });
  const created = first.changes.map((c) => c.document);
  const second = planLegacyMigration({
    configs: [legacyFixture()],
    existingPositions: created,
    now: new Date('2026-10-31T01:00:00Z'),
  });
  assert.equal(second.planned.positions_to_create, 0);
  assert.equal(second.planned.duplicates_skipped, 2);
  assert.equal(second.changes.length, 0);
});

test('migration: archived duplicates do not block re-import, but active ones do', () => {
  const plan = planLegacyMigration({
    configs: [legacyFixture({ tickers: ['MSFT'] })],
    existingPositions: [{
      owner_id: 'owner-1',
      instrument: { instrument_id: legacyInstrumentId('MSFT'), symbol: 'MSFT', exchange: null, currency: null, provider_symbol: null },
      state: 'legacy_unclassified',
      archived: true,
    }],
    now: new Date('2026-10-31T00:00:00Z'),
  });
  assert.equal(plan.planned.positions_to_create, 1);
  assert.equal(plan.planned.duplicates_skipped, 0);
});

test('migration: manifest is reversible — every insert has a matching rollback step', () => {
  const plan = planLegacyMigration({
    configs: [legacyFixture({ tickers: ['A', 'B', 'C'] })],
    existingPositions: [],
    now: new Date('2026-10-31T00:00:00Z'),
  });
  assert.equal(plan.changes.length, 3);
  assert.equal(plan.rollback.steps.length, 3);
  for (const step of plan.rollback.steps) {
    assert.equal(step.op, 'delete_position_by_id');
    assert.equal(typeof step.position_id, 'string');
    assert.ok(step.position_id.length > 0);
  }
  assert.equal(typeof plan.rollback.description, 'string');
  assert.ok(plan.rollback.description.length > 0);
});

test('migration: no cost/ownership facts are inferred from tickers or user prose', () => {
  const plan = planLegacyMigration({
    configs: [legacyFixture({ tickers: ['TSLA'] })],
    existingPositions: [],
    now: new Date('2026-10-31T00:00:00Z'),
  });
  const doc = plan.changes[0].document;
  const serialized = JSON.stringify(doc);
  assert.equal(serialized.match(/amount/), null, 'no amounts anywhere in the migrated document');
  assert.ok(!('average_cost' in doc) || doc.average_cost === null);
});

// ---------------------------------------------------------------------------
// 10. Stale legacy tickers update policy (CONTRACTS §10)
// ---------------------------------------------------------------------------
test('ticker policy: tickers-only PUT that would orphan active positions is blocked explicitly, not destructive', () => {
  const activePositions = [{
    id: 'pos-1',
    owner_id: 'owner-1',
    state: 'legacy_unclassified',
    archived: false,
    instrument: { instrument_id: legacyInstrumentId('MSFT'), symbol: 'MSFT', exchange: null, currency: null, provider_symbol: null },
  }];
  const result = reconcileLegacyTickerUpdate({
    activePositions,
    previousTickers: ['MSFT', 'KO'],
    incomingTickers: ['KO'],
  });
  assert.equal(result.status, 'conflict');
  assert.deepEqual(result.blocked_removals.map((b) => b.ticker), ['MSFT']);
  assert.deepEqual(result.blocked_removals[0].active_position_ids, ['pos-1']);
  assert.deepEqual(result.allowed_removals, [], 'KO stays in the incoming list so nothing else is removed');
  assert.deepEqual(result.additions, []);
});

test('ticker policy: removals without active positions and additions pass through', () => {
  const result = reconcileLegacyTickerUpdate({
    activePositions: [],
    previousTickers: ['KO'],
    incomingTickers: ['KO', 'PLTR'],
  });
  assert.equal(result.status, 'ok');
  assert.deepEqual(result.allowed_removals, []);
  assert.deepEqual(result.additions, ['PLTR']);

  const result2 = reconcileLegacyTickerUpdate({
    activePositions: [{ id: 'pos-9', owner_id: 'owner-1', archived: true, instrument: { instrument_id: legacyInstrumentId('KO'), symbol: 'KO' } }],
    previousTickers: ['KO', 'X'],
    incomingTickers: [],
  });
  assert.equal(result2.status, 'ok', 'archived positions do not block ticker removal');
  assert.deepEqual(result2.allowed_removals, ['KO', 'X']);
});

test('ticker policy: case-insensitive ticker matching and owner scoping', () => {
  const activePositions = [{
    id: 'pos-2',
    owner_id: 'owner-1',
    archived: false,
    instrument: { instrument_id: legacyInstrumentId('msft'), symbol: 'MSFT' },
  }];
  const result = reconcileLegacyTickerUpdate({
    activePositions,
    previousTickers: ['msft'],
    incomingTickers: [],
  });
  assert.equal(result.status, 'conflict');
  assert.deepEqual(result.blocked_removals.map((b) => b.ticker), ['MSFT']);
});

// ---------------------------------------------------------------------------
// 11. Review repairs (t_f3a6cd05) — opaque string _id (Finding 1), migration
//     deterministic id persistence (Finding 2), model decimal bound (Note B)
// ---------------------------------------------------------------------------
const { buildAppliedDocument } = require('../scripts/migrate-positions.cjs');

test('model: _id is an opaque String schema path — pos-<uuid> ids validate (Finding 1)', () => {
  assert.equal(
    Position.schema.path('_id').instance,
    'String',
    'CONTRACTS §1: identifiers are opaque strings; Mongoose must not default _id to ObjectId',
  );
  const id = `pos-${crypto.randomUUID()}`;
  const doc = new Position({ _id: id, owner_id: 'owner-1', ...structuredClone(CANDIDATE_INPUT) });
  const error = doc.validateSync();
  assert.equal(error, undefined, `string _id must cast cleanly, got: ${error}`);
  assert.equal(doc._id, id);
});

test('model: legacy-mig-* deterministic ids validate on the real schema (Finding 1 + 2)', () => {
  const legacyId = 'legacy-mig-owner-1-MSFT';
  const doc = new Position({
    _id: legacyId,
    owner_id: 'owner-1',
    state: 'legacy_unclassified',
    instrument: { instrument_id: legacyInstrumentId('MSFT'), symbol: 'MSFT' },
  });
  const error = doc.validateSync();
  assert.equal(error, undefined, `legacy-mig-* _id must cast cleanly, got: ${error}`);
  assert.equal(doc._id, legacyId);
});

test('migration: apply-path document persists the deterministic legacy-mig-* _id (Finding 2)', () => {
  const plan = planLegacyMigration({
    configs: [legacyFixture({ tickers: ['MSFT'] })],
    existingPositions: [],
    now: new Date('2026-10-31T00:00:00Z'),
  });
  assert.equal(plan.changes.length, 1);
  const change = plan.changes[0];
  assert.ok(change.position_id.startsWith('legacy-mig-'));
  // Exactly the shape the CLI apply loop passes to Position.create.
  const applied = buildAppliedDocument(change);
  assert.equal(applied._id, change.position_id, 'apply must pass the manifest id as _id');
  const doc = new Position(applied);
  const error = doc.validateSync();
  assert.equal(error, undefined, `applied document must validate, got: ${error}`);
  assert.equal(doc._id, change.position_id, 'created document carries the legacy-mig-* id');
  assert.equal(
    plan.rollback.steps[0].position_id,
    change.position_id,
    'rollback delete_position_by_id targets the persisted id',
  );
});

test('model: decimal validator matches the service bound — <=18 total / <=12 fraction digits (Note B)', () => {
  const rejected = [
    '0.0000000000001', // 13 fraction digits: service rejects, model must too
    '1.0000000000001',
    '1234567890123456789', // 19 total digits
    '0.0',
    '0',
  ];
  for (const amount of rejected) {
    const doc = new Position({ owner_id: 'owner-1', ...structuredClone(OWNED_INPUT), average_cost: { amount, currency: 'USD' } });
    const error = doc.validateSync();
    assert.ok(error && error.errors['average_cost.amount'], `model must reject amount ${amount}`);
  }
  const quantityDoc = new Position({ owner_id: 'owner-1', ...structuredClone(OWNED_INPUT), quantity: '1234567890123456789' });
  assert.ok(quantityDoc.validateSync() && quantityDoc.validateSync().errors.quantity, 'model must reject 19-digit quantity');
  // At the boundary: exactly 18 total / 12 fraction digits must still validate.
  const ok = new Position({
    owner_id: 'owner-1',
    ...structuredClone(OWNED_INPUT),
    average_cost: { amount: '123456.123456789012', currency: 'USD' },
    quantity: '999999999999999.99',
  });
  assert.equal(ok.validateSync(), undefined, 'values within the bound must validate');
});
