const crypto = require('node:crypto');
const EvidenceSnapshot = require('./evidence.model');
const { evidenceItemSchema } = require('./contracts');

const LEAN_SOURCE_GAPS = Object.freeze([
  'consensus_estimates_unavailable',
  'complete_transcripts_unavailable',
  'broker_price_targets_unavailable',
]);

function serviceError(code, message) {
  const error = new Error(message);
  error.code = code;
  return error;
}

// Point-in-time invariant: cutoff comparisons are string comparisons against ISO UTC
// timestamps, so any caller-supplied cutoff is normalized to one canonical ISO string.
function normalizeCutoffAt(cutoffAt, now) {
  if (cutoffAt == null || cutoffAt === '') {
    return now().toISOString();
  }
  let date;
  if (cutoffAt instanceof Date) {
    date = cutoffAt;
  } else if (typeof cutoffAt === 'string') {
    date = new Date(cutoffAt);
  } else {
    throw serviceError('INVALID_CUTOFF', 'cutoffAt must be an ISO string or a Date');
  }
  if (Number.isNaN(date.valueOf())) {
    throw serviceError('INVALID_CUTOFF', 'cutoffAt is not a valid timestamp');
  }
  return date.toISOString();
}

function createMongooseEvidenceRepository(model = EvidenceSnapshot) {
  return {
    async findById(snapshotId) {
      const record = await model.findOne({ snapshot_id: snapshotId }).lean();
      return record ? {
        id: record.snapshot_id,
        snapshot_id: record.snapshot_id,
        instrument_id: record.instrument_id,
        cutoff_at: record.cutoff_at.toISOString(),
        session_as_of: record.session_as_of,
        market_snapshot_ids: record.market_snapshot_ids,
        evidence_ids: record.evidence_ids,
        metric_ids: record.metric_ids,
        coverage: record.coverage,
        content_digest: record.content_digest,
        items: record.items,
      } : null;
    },
    async latestForCutoff(instrumentId, cutoffAt) {
      const record = await model.findOne({
        instrument_id: instrumentId,
        cutoff_at: { $lte: new Date(cutoffAt) },
      }).sort({ cutoff_at: -1 }).lean();
      return record ? {
        id: record.snapshot_id,
        snapshot_id: record.snapshot_id,
        instrument_id: record.instrument_id,
        cutoff_at: record.cutoff_at.toISOString(),
        session_as_of: record.session_as_of,
        market_snapshot_ids: record.market_snapshot_ids,
        evidence_ids: record.evidence_ids,
        metric_ids: record.metric_ids,
        coverage: record.coverage,
        content_digest: record.content_digest,
        items: record.items,
      } : null;
    },
    async create(snapshot) {
      await model.create(snapshot);
      return structuredClone(snapshot);
    },
  };
}

class EvidenceService {
  constructor({
    secProvider,
    newsProvider,
    evidenceRepository,
    instrumentNormalizer = (instrument) => instrument,
    now = () => new Date(),
    snapshotIdFactory = () => `snapshot-evidence-${crypto.randomUUID()}`,
  } = {}) {
    if (!secProvider || typeof secProvider.fetchEvidence !== 'function') {
      throw new TypeError('EvidenceService requires a SEC provider');
    }
    if (!newsProvider || typeof newsProvider.fetchNews !== 'function') {
      throw new TypeError('EvidenceService requires a company news provider');
    }
    if (!evidenceRepository || typeof evidenceRepository.findById !== 'function'
      || typeof evidenceRepository.create !== 'function') {
      throw new TypeError('EvidenceService requires an evidence repository');
    }

    this.secProvider = secProvider;
    this.newsProvider = newsProvider;
    this.evidenceRepository = evidenceRepository;
    if (typeof instrumentNormalizer !== 'function') {
      throw new TypeError('EvidenceService instrumentNormalizer must be a function');
    }
    this.instrumentNormalizer = instrumentNormalizer;
    this.now = now;
    this.snapshotIdFactory = snapshotIdFactory;
  }

  async gatherEvidence({
    instrument,
    sessionAsOf,
    cutoffAt,
    options = {},
  } = {}) {
    // Identity is supplied exclusively by the server-owned position that
    // queued this run. Do not resolve an arbitrary instrument_id here: an ID
    // can collide across owners and may originate in a client request.
    if (!instrument || typeof instrument !== 'object'
      || typeof instrument.instrument_id !== 'string' || instrument.instrument_id.length === 0) {
      throw serviceError('INSTRUMENT_CONTEXT_REQUIRED', 'A server-bound instrument context is required');
    }
    const normalizedInstrument = await this.instrumentNormalizer(instrument);
    if (!normalizedInstrument || normalizedInstrument.instrument_id !== instrument.instrument_id) {
      throw serviceError('INSTRUMENT_CONTEXT_INVALID', 'Server-bound instrument context is invalid');
    }

    const effectiveCutoff = normalizeCutoffAt(cutoffAt, this.now);

    // 1. Fetch from registered primary evidence providers
    let secItems = [];
    let secAvailabilityGap = null;
    try {
      secItems = await this.secProvider.fetchEvidence(normalizedInstrument, { cutoffAt: effectiveCutoff });
    } catch (error) {
      secItems = [];
      // Provider errors are intentionally reduced to stable coverage labels;
      // do not copy network details into model-visible evidence.
      if (error?.code === 'CIK_NOT_FOUND' || error?.code === 'TICKER_MISSING') secAvailabilityGap = 'sec_cik_mapping_unavailable';
      else if (error?.code === 'PROVIDER_TIMEOUT') secAvailabilityGap = 'sec_provider_timeout';
      else secAvailabilityGap = 'sec_provider_unavailable';
    }

    let newsItems = [];
    try {
      newsItems = await this.newsProvider.fetchNews(normalizedInstrument, { cutoffAt: effectiveCutoff });
    } catch (error) {
      newsItems = [];
    }

    // 2. Strict point-in-time cutoff check on all gathered items
    const allProviderItems = [...secItems, ...newsItems];
    const combined = allProviderItems.filter((item) => {
      const itemAvailability = item.available_at || item.published_at;
      return !effectiveCutoff || !itemAvailability || itemAvailability <= effectiveCutoff;
    });
    const excludedPostCutoff = combined.length !== allProviderItems.length;

    // 3. Schema validation on every item
    const validatedItems = [];
    for (const item of combined) {
      const parsed = evidenceItemSchema.parse(item);
      validatedItems.push(parsed);
    }

    // 4. Deterministic sort: ascending available_at/published_at, then ID
    validatedItems.sort((a, b) => {
      const timeA = a.available_at || a.published_at || '';
      const timeB = b.available_at || b.published_at || '';
      const timeComp = timeA.localeCompare(timeB);
      return timeComp !== 0 ? timeComp : a.id.localeCompare(b.id);
    });

    // 5. Explicit Lean-Source Gaps & Coverage Evaluation. Count only items
    // that survived the exact cutoff and schema validation; raw provider
    // counts could otherwise falsely advertise coverage from future evidence.
    const secCount = validatedItems.filter((item) => item.kind === 'filing' || item.source_name === 'SEC EDGAR').length;
    const newsCount = validatedItems.filter((item) => item.kind === 'news' || item.kind === 'company_ir').length;
    const gaps = [...LEAN_SOURCE_GAPS];
    if (this.secProvider.availabilityGap) gaps.push(this.secProvider.availabilityGap);
    if (this.newsProvider.availabilityGap) gaps.push(this.newsProvider.availabilityGap);
    if (secAvailabilityGap) gaps.push(secAvailabilityGap);
    if (excludedPostCutoff) gaps.push('post_cutoff_evidence_excluded');

    let coverageStatus = 'unavailable';
    if (secCount > 0 && newsCount > 0) {
      coverageStatus = 'available';
    } else if (secCount > 0 || newsCount > 0) {
      coverageStatus = 'partial';
      if (secCount === 0) gaps.push('sec_filings_unavailable');
      if (newsCount === 0) gaps.push('news_coverage_unavailable');
    } else {
      coverageStatus = 'unavailable';
      gaps.push('sec_filings_unavailable');
      gaps.push('news_coverage_unavailable');
    }

    const coverage = {
      status: coverageStatus,
      sec_filings: secCount > 0 ? 'available' : 'unavailable',
      company_news: newsCount > 0 ? 'available' : 'unavailable',
      gaps,
    };

    // 6. Deterministic content digest (SHA-256 of JSON canonical items)
    const digestPayload = JSON.stringify(validatedItems.map((item) => ({
      id: item.id,
      kind: item.kind,
      title: item.title,
      source_url: item.source_url,
      available_at: item.available_at,
      source_locator: item.source_locator,
      facts: item.facts,
      excerpt: item.excerpt,
    })));
    const contentDigest = crypto.createHash('sha256').update(digestPayload).digest('hex');

    // 7. Create and persist EvidenceSnapshot
    const snapshotId = this.snapshotIdFactory();
    const snapshot = {
      id: snapshotId,
      snapshot_id: snapshotId,
      instrument_id: normalizedInstrument.instrument_id,
      cutoff_at: effectiveCutoff,
      session_as_of: sessionAsOf,
      market_snapshot_ids: options.marketSnapshotIds || [],
      evidence_ids: validatedItems.map((item) => item.id),
      metric_ids: [],
      coverage,
      content_digest: contentDigest,
      created_at: this.now().toISOString(),
      items: validatedItems,
    };

    await this.evidenceRepository.create(snapshot);
    return { snapshot, items: validatedItems };
  }

  async getFilingExcerpt({ snapshotId, evidenceId, section, url } = {}) {
    if (url) {
      throw serviceError('ARBITRARY_URL_FORBIDDEN', 'Analyst tools cannot fetch arbitrary URLs');
    }

    const snapshot = await this.evidenceRepository.findById(snapshotId);
    if (!snapshot) {
      throw serviceError('SNAPSHOT_NOT_FOUND', `Evidence snapshot not found: ${snapshotId}`);
    }

    const item = (snapshot.items || []).find((entry) => entry.id === evidenceId);
    if (!item) {
      throw serviceError('EVIDENCE_ITEM_NOT_FOUND', `Evidence item not found: ${evidenceId}`);
    }

    if (item.kind !== 'filing') {
      throw serviceError('NOT_A_FILING', `Evidence item ${evidenceId} is kind ${item.kind}, not filing`);
    }

    return {
      evidence_id: item.id,
      title: item.title,
      source_locator: item.source_locator,
      section: section || null,
      excerpt: item.excerpt,
      facts: item.facts,
      reporting_period: item.reporting_period,
    };
  }

  async getMaterialNews({ snapshotId, limit = 5 } = {}) {
    const snapshot = await this.evidenceRepository.findById(snapshotId);
    if (!snapshot) {
      throw serviceError('SNAPSHOT_NOT_FOUND', `Evidence snapshot not found: ${snapshotId}`);
    }

    const newsItems = (snapshot.items || [])
      .filter((entry) => entry.kind === 'news' || entry.kind === 'company_ir')
      .slice(0, limit);

    return newsItems.map((item) => ({
      id: item.id,
      title: item.title,
      source_name: item.source_name,
      published_at: item.published_at,
      available_at: item.available_at,
      coverage_status: item.coverage_status,
      excerpt: item.excerpt,
      source_locator: item.source_locator,
    }));
  }

  async getSnapshot({ snapshotId, instrumentId } = {}) {
    const snapshot = await this.evidenceRepository.findById(snapshotId);
    if (!snapshot) {
      throw serviceError('SNAPSHOT_NOT_FOUND', `Evidence snapshot not found: ${snapshotId}`);
    }
    if (instrumentId && snapshot.instrument_id !== instrumentId) {
      throw serviceError('INSTRUMENT_MISMATCH', 'Snapshot does not match instrument');
    }
    return snapshot;
  }
}

module.exports = {
  EvidenceService,
  createMongooseEvidenceRepository,
  LEAN_SOURCE_GAPS,
};
