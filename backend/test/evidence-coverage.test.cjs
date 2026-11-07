'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');
const { EvidenceService } = require('../src/features/research/evidence.service');

const CUTOFF = '2026-10-30T20:00:00.000Z';
const INSTRUMENT = { instrument_id: 'inst-cutoff', symbol: 'CUT', cik: '1234' };

function evidence(id, kind, availableAt) {
  return {
    id,
    instrument_id: INSTRUMENT.instrument_id,
    kind,
    title: id,
    source_url: kind === 'filing' ? 'https://www.sec.gov/Archives/example.htm' : 'https://finance.yahoo.com/news/example.html',
    source_name: kind === 'filing' ? 'SEC EDGAR' : 'Yahoo Finance',
    published_at: availableAt,
    retrieved_at: CUTOFF,
    available_at: availableAt,
    reporting_period: null,
    excerpt: 'Fixture.',
    source_locator: id,
    facts: [],
    coverage_status: 'available',
  };
}

test('coverage is calculated from cutoff-valid evidence, never raw provider counts', async () => {
  const stored = [];
  const service = new EvidenceService({
    secProvider: { fetchEvidence: async () => [evidence('sec-future', 'filing', '2026-10-31T00:00:00.000Z')] },
    newsProvider: { fetchNews: async () => [evidence('news-future', 'news', '2026-10-31T00:00:00.000Z')] },
    evidenceRepository: {
      findById: async () => null,
      create: async (snapshot) => stored.push(snapshot),
    },
    now: () => new Date(CUTOFF),
    snapshotIdFactory: () => 'snapshot-cutoff-truthful',
  });

  const { snapshot } = await service.gatherEvidence({
    instrument: INSTRUMENT,
    sessionAsOf: '2026-10-30',
    cutoffAt: CUTOFF,
  });

  assert.equal(snapshot.items.length, 0);
  assert.equal(snapshot.coverage.status, 'unavailable');
  assert.equal(snapshot.coverage.sec_filings, 'unavailable');
  assert.equal(snapshot.coverage.company_news, 'unavailable');
  assert.ok(snapshot.coverage.gaps.includes('post_cutoff_evidence_excluded'));
  assert.ok(snapshot.coverage.gaps.includes('sec_filings_unavailable'));
  assert.ok(snapshot.coverage.gaps.includes('news_coverage_unavailable'));
  assert.equal(stored.length, 1);
});
