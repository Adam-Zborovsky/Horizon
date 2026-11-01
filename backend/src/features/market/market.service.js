const crypto = require('node:crypto');
const MarketSnapshot = require('./market_snapshot.model');
const { YahooMarketProvider } = require('./providers/yahoo');
const { CONTRACT_VERSION, historyResponseSchema, marketBarSchema } = require('../research/contracts');

const MARKET_RANGE_CONFIG = Object.freeze({
  '1D': { preferred_resolution: '5m', cache_ttl_ms: 60_000 },
  '1W': { preferred_resolution: '30m', cache_ttl_ms: 5 * 60_000 },
  '1M': { preferred_resolution: '1d', cache_ttl_ms: 15 * 60_000 },
  '3M': { preferred_resolution: '1d', cache_ttl_ms: 30 * 60_000 },
  '6M': { preferred_resolution: '1d', cache_ttl_ms: 60 * 60_000 },
  '1Y': { preferred_resolution: '1d', cache_ttl_ms: 60 * 60_000 },
});

function asIso(value) {
  return new Date(value).toISOString();
}

function safeReason(error) {
  return /^[A-Z_]{3,80}$/.test(error?.code || '') ? error.code : 'PROVIDER_UNAVAILABLE';
}

function requestError(status, code) {
  const error = new Error(code);
  error.status = status;
  error.code = code;
  return error;
}

function createMongooseSnapshotRepository(model = MarketSnapshot) {
  return {
    async latestForCacheKey(cacheKey) {
      const record = await model.findOne({ cache_key: cacheKey }).sort({ fetched_at: -1 }).lean();
      return record ? {
        snapshot_id: record.snapshot_id,
        cache_key: record.cache_key,
        expires_at: asIso(record.expires_at),
        response: record.response,
      } : null;
    },
    async findById(snapshotId) {
      const record = await model.findOne({ snapshot_id: snapshotId }).lean();
      return record ? {
        snapshot_id: record.snapshot_id,
        cache_key: record.cache_key,
        expires_at: asIso(record.expires_at),
        response: record.response,
      } : null;
    },
    async create(snapshot) {
      await model.create(snapshot);
      return structuredClone(snapshot);
    },
  };
}

function normalizeBars(bars) {
  const valid = [];
  let invalid = 0;
  for (const bar of bars || []) {
    const parsed = marketBarSchema.safeParse(bar);
    if (!parsed.success) {
      invalid += 1;
      continue;
    }
    valid.push(parsed.data);
  }
  valid.sort((left, right) => left.time.localeCompare(right.time));
  const unique = [];
  const seen = new Set();
  for (const bar of valid) {
    const key = `${bar.session_date}|${bar.time}`;
    if (seen.has(key)) {
      invalid += 1;
      continue;
    }
    seen.add(key);
    unique.push(bar);
  }
  return { bars: unique, invalid };
}

class MarketHistoryService {
  constructor({
    provider = new YahooMarketProvider(),
    snapshotRepository = createMongooseSnapshotRepository(),
    instrumentResolver = async () => null,
    now = () => new Date(),
    snapshotIdFactory = () => crypto.randomUUID(),
  } = {}) {
    if (!provider || typeof provider.fetchHistory !== 'function') throw new TypeError('MarketHistoryService requires a provider adapter');
    if (!snapshotRepository || typeof snapshotRepository.latestForCacheKey !== 'function'
      || typeof snapshotRepository.findById !== 'function' || typeof snapshotRepository.create !== 'function') {
      throw new TypeError('MarketHistoryService requires a snapshot repository');
    }
    this.provider = provider;
    this.snapshotRepository = snapshotRepository;
    this.instrumentResolver = instrumentResolver;
    this.now = now;
    this.snapshotIdFactory = snapshotIdFactory;
  }

  async getHistory({ instrumentId, range, resolution, snapshotId } = {}) {
    const config = MARKET_RANGE_CONFIG[range];
    if (!config) throw requestError(400, 'INVALID_RANGE');
    const requestedResolution = resolution || config.preferred_resolution;
    const instrument = await this.instrumentResolver(instrumentId);
    if (!instrument) throw requestError(404, 'INSTRUMENT_NOT_FOUND');

    if (snapshotId) return this.getSnapshot({ snapshotId, instrumentId, range, requestedResolution });
    const cacheKey = this.cacheKey(instrumentId, range, requestedResolution);
    const cached = await this.snapshotRepository.latestForCacheKey(cacheKey);
    if (cached && new Date(cached.expires_at) > this.now()) return structuredClone(cached.response);
    if (requestedResolution !== config.preferred_resolution) {
      return this.unavailable({ instrument, range, requestedResolution, reason: 'UNSUPPORTED_RESOLUTION' });
    }

    try {
      const providerResult = await this.provider.fetchHistory(instrument, { range, resolution: requestedResolution });
      return this.persistProviderResult({ instrument, range, requestedResolution, cacheKey, providerResult });
    } catch (error) {
      if (cached) return this.staleCache(cached.response, safeReason(error));
      return this.unavailable({ instrument, range, requestedResolution, reason: safeReason(error) });
    }
  }

  async getSnapshot({ snapshotId, instrumentId, range, requestedResolution }) {
    const snapshot = await this.snapshotRepository.findById(snapshotId);
    if (!snapshot || snapshot.response?.instrument?.instrument_id !== instrumentId
      || snapshot.response?.range !== range || snapshot.response?.requested_resolution !== requestedResolution) {
      throw requestError(404, 'SNAPSHOT_NOT_FOUND');
    }
    return structuredClone(snapshot.response);
  }

  cacheKey(instrumentId, range, resolution) {
    return `market-history:v${CONTRACT_VERSION}:${instrumentId}:${range}:${resolution}`;
  }

  unavailable({ instrument, range, requestedResolution, reason }) {
    return historyResponseSchema.parse({
      contract_version: CONTRACT_VERSION,
      instrument,
      snapshot_id: null,
      range,
      requested_resolution: requestedResolution,
      actual_resolution: requestedResolution,
      exchange_timezone: 'unknown',
      session_mode: 'regular',
      adjustment_basis: 'unavailable',
      as_of: null,
      fetched_at: this.now().toISOString(),
      data_status: 'unavailable',
      delay_status: 'unknown',
      is_stale: false,
      available_ranges: [],
      bars: [],
      warnings: [{ code: reason }],
      next_cursor: null,
      unavailable_reason: reason,
    });
  }

  async persistProviderResult({ instrument, range, requestedResolution, cacheKey, providerResult }) {
    const { bars, invalid } = normalizeBars(providerResult.bars);
    const invalidCount = invalid + (Number.isSafeInteger(providerResult.invalid_bar_count)
      && providerResult.invalid_bar_count > 0 ? providerResult.invalid_bar_count : 0);
    if (bars.length === 0) {
      return this.unavailable({ instrument, range, requestedResolution, reason: 'NO_VALID_BARS' });
    }
    const resolutionFallback = providerResult.actual_resolution !== requestedResolution;
    const warnings = [...(providerResult.warnings || [])];
    if (invalidCount > 0) warnings.push({ code: 'INVALID_BARS_OMITTED', count: invalidCount });
    if (resolutionFallback) warnings.push({
      code: 'RESOLUTION_FALLBACK',
      requested_resolution: requestedResolution,
      actual_resolution: providerResult.actual_resolution,
    });
    const snapshotId = this.snapshotIdFactory();
    const response = historyResponseSchema.parse({
      contract_version: CONTRACT_VERSION,
      instrument,
      snapshot_id: snapshotId,
      range,
      requested_resolution: requestedResolution,
      actual_resolution: providerResult.actual_resolution,
      exchange_timezone: providerResult.exchange_timezone,
      session_mode: 'regular',
      adjustment_basis: providerResult.adjustment_basis,
      as_of: providerResult.as_of,
      fetched_at: providerResult.fetched_at,
      data_status: invalidCount > 0 || resolutionFallback ? 'partial' : 'available',
      delay_status: providerResult.delay_status,
      is_stale: false,
      available_ranges: [range],
      bars,
      warnings,
      next_cursor: null,
      source: providerResult.source,
    });
    const expiresAt = new Date(this.now().valueOf() + MARKET_RANGE_CONFIG[range].cache_ttl_ms).toISOString();
    await this.snapshotRepository.create({
      snapshot_id: snapshotId,
      cache_key: cacheKey,
      instrument_id: instrument.instrument_id,
      range,
      requested_resolution: requestedResolution,
      fetched_at: response.fetched_at,
      expires_at: expiresAt,
      response,
    });
    return structuredClone(response);
  }

  staleCache(response, providerError) {
    const stale = structuredClone(response);
    stale.is_stale = true;
    stale.data_status = 'partial';
    if (stale.delay_status === 'realtime') stale.delay_status = 'unknown';
    stale.warnings = [...stale.warnings, { code: 'STALE_CACHE', provider_error: providerError }];
    return historyResponseSchema.parse(stale);
  }
}

module.exports = {
  MARKET_RANGE_CONFIG,
  MarketHistoryService,
  createMongooseSnapshotRepository,
};
