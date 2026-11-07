// Production run-input provider (H06/H07 glue): assembles the bounded
// evidence snapshot, code-computed metrics, live position view, prior
// assessment slice and current price for one claimed run.
//
// Honesty rules (CONTRACTS §3/§4):
// - Observed bars only. A failed/empty market fetch is coverage 'partial' or
//   'unavailable' with recorded gaps — never synthetic fill.
// - Metrics are computed in code (metrics.js) with method/basis/inputs.
// - currentPrice.adjustment_basis is emitted in the position COST_BASES
//   vocabulary ('split_reconciled': Yahoo chart close is split-adjusted, not
//   dividend-adjusted), so P/L comparison is valid for split_reconciled costs
//   and correctly unavailable for raw_purchase costs.
// - Prior assessment state is passed as prior decisions, never as facts.

const {
  annualizedVolatility,
  cumulativeReturn,
  createMetric,
  maxDrawdown,
  meanOf,
} = require('./metrics');

const YAHOO_CHART_URL = 'https://query1.finance.yahoo.com/v8/finance/chart';
const MARKET_EVIDENCE_ID = 'ev-market-daily-1y';
const METHOD_VERSION = 'v1';
const ET_ZONE = 'America/New_York';
const MAX_BARS = 400;
// Reserve one prompt evidence slot for the observed market-history item.
const MAX_EXTERNAL_EVIDENCE_ITEMS = 19;

function ymdInZone(seconds, timeZone = ET_ZONE) {
  return new Intl.DateTimeFormat('en-CA', {
    timeZone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(new Date(seconds * 1000));
}

function decimalString(value) {
  return value.toFixed(2);
}

function addGap(gaps, gap) {
  if (!gaps.includes(gap)) gaps.push(gap);
}

function boundedEvidenceItems(items, { instrumentId, cutoffAt }) {
  return (Array.isArray(items) ? items : [])
    .filter((item) => item && item.instrument_id === instrumentId)
    .filter((item) => {
      const availableAt = item.available_at || item.published_at;
      return !availableAt || availableAt <= cutoffAt;
    })
    // EvidenceService sorts ascending; retain the most recent valid material.
    .slice(-MAX_EXTERNAL_EVIDENCE_ITEMS);
}

function priorDecisionFromDocument(priorDoc) {
  // ResearchAssessment persists the assessment under `assessment`; tolerate
  // the legacy flat shape without changing the fact/decision boundary.
  const assessment = priorDoc?.assessment && typeof priorDoc.assessment === 'object'
    ? priorDoc.assessment
    : priorDoc;
  const thesis = assessment?.market_thesis && typeof assessment.market_thesis === 'object'
    ? assessment.market_thesis
    : {};
  const thesisSections = ['business_assessment', 'price_technical_assessment', 'valuation_assessment']
    .map((key) => ({ key, summary: thesis[key]?.summary }))
    .filter((entry) => typeof entry.summary === 'string' && entry.summary.length > 0);

  return {
    assessment_id: String(priorDoc._id),
    session_as_of: typeof priorDoc.session_as_of === 'string' ? priorDoc.session_as_of : null,
    market_thesis_summary: typeof thesis.summary === 'string'
      ? thesis.summary
      : thesisSections.map((entry) => `${entry.key}: ${entry.summary}`).join('\n'),
    thesis_sections: thesisSections,
    recommendation: assessment?.recommendation && typeof assessment.recommendation === 'object'
      ? {
        action: assessment.recommendation.action,
        headline: assessment.recommendation.headline,
        evidence_quality: assessment.recommendation.evidence_quality,
      }
      : null,
    outlooks: Array.isArray(assessment?.outlooks)
      ? assessment.outlooks.map((outlook) => ({
        horizon_months: outlook?.horizon_months,
        direction: outlook?.direction,
        data_limitations: outlook?.data_limitations,
      }))
      : [],
    missing_data: Array.isArray(assessment?.missing_data) ? assessment.missing_data : [],
    checkpoints: Array.isArray(assessment?.checkpoints) ? assessment.checkpoints : [],
  };
}

async function fetchDailyBars({ symbol, fetchImpl, timeoutMs = 15000 }) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const url = `${YAHOO_CHART_URL}/${encodeURIComponent(symbol)}?range=1y&interval=1d`;
    const response = await fetchImpl(url, {
      headers: { 'user-agent': 'Mozilla/5.0 (compatible; HorizonResearch/1.0)' },
      signal: controller.signal,
    });
    if (!response.ok) {
      throw new Error(`yahoo chart HTTP ${response.status}`);
    }
    const payload = await response.json();
    const result = payload?.chart?.result?.[0];
    const stamps = result?.timestamp;
    const quote = result?.indicators?.quote?.[0];
    if (!Array.isArray(stamps) || !quote || !Array.isArray(quote.close)) {
      throw new Error('yahoo chart returned no usable series');
    }
    const bars = [];
    const seen = new Set();
    for (let i = 0; i < stamps.length; i += 1) {
      const close = quote.close[i];
      const high = quote.high?.[i];
      const low = quote.low?.[i];
      const open = quote.open?.[i];
      if (![close, high, low, open].every((v) => Number.isFinite(v) && v > 0)) continue;
      const session_date = ymdInZone(stamps[i]);
      if (seen.has(session_date)) continue;
      seen.add(session_date);
      bars.push({
        session_date,
        open,
        high,
        low,
        close,
        volume: Number.isFinite(quote.volume?.[i]) ? Math.round(quote.volume[i]) : null,
      });
    }
    bars.sort((a, b) => a.session_date.localeCompare(b.session_date));
    return {
      bars: bars.slice(-MAX_BARS),
      currency: typeof result?.meta?.currency === 'string' ? result.meta.currency : null,
    };
  } finally {
    clearTimeout(timer);
  }
}

function buildMetrics({ instrumentId, snapshotId, bars, evidenceIds, currency }) {
  const closes = bars.map((b) => b.close);
  const last = closes[closes.length - 1];
  const asOf = bars[bars.length - 1].session_date;
  const base = {
    instrument_id: instrumentId,
    as_of: asOf,
    basis: 'split_adjusted_close',
    method_version: METHOD_VERSION,
    input_evidence_ids: evidenceIds,
    input_snapshot_ids: [snapshotId],
  };
  const defs = [];
  defs.push({ id: 'm-close-latest', value: last, unit: 'price', currency, method: 'last_close' });
  const windowDefs = [
    { id: 'm-return-1m', days: 21, method: 'cumulative_return_21 sessions' },
    { id: 'm-return-3m', days: 63, method: 'cumulative_return_63 sessions' },
  ];
  for (const w of windowDefs) {
    if (closes.length >= 2) {
      const window = closes.slice(-w.days);
      if (window.length >= 2) {
        defs.push({ id: w.id, value: cumulativeReturn(window), unit: 'ratio', currency: null, method: w.method });
      }
    }
  }
  if (closes.length >= 2) {
    defs.push({ id: 'm-return-1y', value: cumulativeReturn(closes), unit: 'ratio', currency: null, method: 'cumulative_return_full_window' });
  }
  const smaDefs = [
    { id: 'm-sma-50', days: 50, method: 'simple_moving_average_50' },
    { id: 'm-sma-200', days: 200, method: 'simple_moving_average_200' },
  ];
  for (const s of smaDefs) {
    if (closes.length >= s.days) {
      defs.push({ id: s.id, value: meanOf(closes.slice(-s.days)), unit: 'price', currency, method: s.method });
    }
  }
  if (closes.length >= 23) {
    try {
      const vol = annualizedVolatility(closes.slice(-22), 252);
      defs.push({ id: 'm-vol-21d-annualized', value: vol, unit: 'ratio', currency: null, method: 'annualized_volatility_21 sessions' });
    } catch {
      // Insufficient return observations: omit, do not invent.
    }
  }
  if (closes.length >= 2) {
    defs.push({ id: 'm-drawdown-1y', value: maxDrawdown(closes).max_drawdown, unit: 'ratio', currency: null, method: 'max_drawdown_full_window' });
  }

  const metrics = [];
  for (const d of defs) {
    metrics.push(createMetric({
      ...base,
      id: d.id,
      value: d.value,
      unit: d.unit,
      currency: d.currency,
      method: d.method,
    }));
  }
  return { metrics, lastClose: last, asOf };
}

function createMongooseRunInputProvider({
  positionModel,
  assessmentModel,
  evidenceService = null,
  fetchImpl = globalThis.fetch,
  now = () => new Date(),
  logger = null,
} = {}) {
  if (!positionModel || typeof positionModel.findOne !== 'function') {
    throw new TypeError('createMongooseRunInputProvider requires a position model');
  }
  if (!assessmentModel || typeof assessmentModel.findOne !== 'function') {
    throw new TypeError('createMongooseRunInputProvider requires an assessment model');
  }
  if (evidenceService != null && typeof evidenceService.gatherEvidence !== 'function') {
    throw new TypeError('createMongooseRunInputProvider evidenceService must provide gatherEvidence');
  }

  return async function loadRunInputs(claimedRun) {
    const ownerId = claimedRun.owner_id_internal;
    const positionRevision = claimedRun.position_revision;
    const instrumentId = claimedRun.run_input_ref?.instrument_id;
    if (typeof ownerId !== 'string' || ownerId.length === 0
      || !Number.isSafeInteger(positionRevision) || positionRevision < 1
      || typeof instrumentId !== 'string' || instrumentId.length === 0) {
      throw Object.assign(new Error('claimed run lacks immutable position binding'), { code: 'INPUT_UNAVAILABLE' });
    }
    // The worker must re-read exactly the owner/revision/instrument recorded
    // when the run was queued. A position ID alone permits cross-owner reads;
    // a current-but-different revision/instrument would make model inputs
    // disagree with the immutable run and its eventual result binding.
    const positionDoc = await positionModel
      .findOne({
        _id: String(claimedRun.position_id),
        owner_id: ownerId,
        revision: positionRevision,
        'instrument.instrument_id': instrumentId,
      })
      .lean();
    if (!positionDoc) {
      throw Object.assign(new Error('position no longer matches the claimed run binding'), { code: 'INPUT_UNAVAILABLE' });
    }
    const positionId = positionDoc._id;
    const instrument = positionDoc.instrument;

    const cutoffAt = now().toISOString();
    const gaps = [];

    let bars = [];
    let marketCurrency = null;
    const providerSymbol = instrument.provider_symbol || instrument.symbol;
    try {
      const fetched = await fetchDailyBars({ symbol: providerSymbol, fetchImpl });
      bars = fetched.bars;
      marketCurrency = fetched.currency;
      if (bars.length === 0) gaps.push('market_history_empty');
    } catch (error) {
      gaps.push(`market_history_unavailable:${error.message}`.slice(0, 160));
    }

    const retrievedAt = cutoffAt;
    const items = [];
    const evidenceIds = [];
    if (bars.length > 0) {
      const first = bars[0];
      const last = bars[bars.length - 1];
      items.push({
        id: MARKET_EVIDENCE_ID,
        instrument_id: instrument.instrument_id,
        kind: 'market_data',
        title: `Daily price history (${bars.length} sessions, ${first.session_date} to ${last.session_date})`,
        source_url: `${YAHOO_CHART_URL}/${encodeURIComponent(providerSymbol)}`,
        source_name: 'Yahoo Finance chart API',
        published_at: retrievedAt,
        retrieved_at: retrievedAt,
        available_at: retrievedAt,
        reporting_period: null,
        excerpt: `Observed daily OHLCV, split-adjusted close basis. Latest close ${decimalString(last.close)} on ${last.session_date}.`,
        source_locator: null,
        facts: [],
        coverage_status: 'available',
      });
      evidenceIds.push(MARKET_EVIDENCE_ID);
    }

    let externalCoverage = null;
    if (evidenceService) {
      if (bars.length === 0) {
        addGap(gaps, 'fundamental_evidence_skipped_no_market_session');
      } else {
        try {
          const gathered = await evidenceService.gatherEvidence({
            instrument,
            sessionAsOf: bars[bars.length - 1].session_date,
            cutoffAt,
          });
          const externalSnapshot = gathered?.snapshot;
          externalCoverage = externalSnapshot?.coverage ?? null;
          for (const gap of externalCoverage?.gaps || []) addGap(gaps, gap);
          const sourceItems = gathered?.items ?? externalSnapshot?.items ?? [];
          const eligibleItems = sourceItems.filter((item) => item && item.instrument_id === instrument.instrument_id
            && (!(item.available_at || item.published_at) || (item.available_at || item.published_at) <= cutoffAt));
          const externalItems = boundedEvidenceItems(eligibleItems, { instrumentId: instrument.instrument_id, cutoffAt });
          if (sourceItems.length > eligibleItems.length) addGap(gaps, 'external_evidence_excluded');
          if (eligibleItems.length > externalItems.length) addGap(gaps, 'external_evidence_context_truncated');
          items.push(...externalItems);
          evidenceIds.push(...externalItems.map((item) => item.id));
        } catch (error) {
          // Never put provider/network details in model context.
          addGap(gaps, 'fundamental_evidence_service_unavailable');
          if (logger?.warn) logger.warn(`run_inputs: evidence lookup failed for run ${claimedRun.id}`);
        }
      }
    } else {
      addGap(gaps, 'sec_filings_not_configured');
      addGap(gaps, 'company_news_not_configured');
    }

    const coverageStatus = externalCoverage?.status === 'available' && bars.length > 0 && gaps.length === 0
      ? 'available'
      : items.length > 0 ? 'partial' : 'unavailable';
    const snapshotId = claimedRun.input_snapshot_id
      || (claimedRun.run_input_ref && claimedRun.run_input_ref.snapshot_id)
      || `snapshot-${claimedRun.id}`;
    const snapshot = {
      snapshot_id: snapshotId,
      instrument_id: instrument.instrument_id,
      session_as_of: bars.length > 0 ? bars[bars.length - 1].session_date : null,
      cutoff_at: cutoffAt,
      coverage: { status: coverageStatus, gaps },
      items,
    };

    const { metrics, lastClose } = bars.length > 0
      ? buildMetrics({
        instrumentId: instrument.instrument_id,
        snapshotId,
        bars,
        evidenceIds,
        currency: marketCurrency ?? instrument.currency ?? null,
      })
      : { metrics: [], lastClose: null };

    let prior = null;
    try {
      const priorDoc = await assessmentModel
        .findOne({ position_id: String(claimedRun.position_id), status: { $in: ['complete', 'limited'] } })
        .sort({ _id: -1 })
        .lean();
      if (priorDoc) {
        prior = priorDecisionFromDocument(priorDoc);
      }
    } catch (error) {
      if (logger?.warn) logger.warn(`run_inputs: prior lookup failed for run ${claimedRun.id}`);
      addGap(gaps, 'prior_assessment_lookup_failed');
    }

    // The prior lookup is part of the run input as well. Re-evaluate after it
    // so a late coverage gap cannot leave an inconsistent "available" label.
    snapshot.coverage.status = externalCoverage?.status === 'available' && bars.length > 0 && gaps.length === 0
      ? 'available'
      : items.length > 0 ? 'partial' : 'unavailable';

    const currentPrice = lastClose != null
      ? {
        amount: decimalString(lastClose),
        currency: marketCurrency ?? instrument.currency ?? 'USD',
        // Yahoo chart close is split-adjusted (not dividend-adjusted); this is
        // the COST_BASES vocabulary entry it may be compared against.
        adjustment_basis: 'split_reconciled',
        as_of_session: bars[bars.length - 1].session_date,
      }
      : null;

    return {
      snapshot,
      metrics,
      instrument,
      position: {
        position_id: positionId,
        instrument_id: instrument.instrument_id,
        state: positionDoc.state,
        revision: positionDoc.revision,
        average_cost: positionDoc.average_cost ?? null,
        quantity: positionDoc.quantity ?? null,
        opened_on: positionDoc.opened_on ?? null,
        preferred_horizon_months: positionDoc.preferred_horizon_months ?? 3,
      },
      prior,
      currentPrice,
    };
  };
}

module.exports = {
  MAX_EXTERNAL_EVIDENCE_ITEMS,
  boundedEvidenceItems,
  buildMetrics,
  createMongooseRunInputProvider,
  fetchDailyBars,
  priorDecisionFromDocument,
};
