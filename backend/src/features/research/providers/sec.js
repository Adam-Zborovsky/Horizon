const { evidenceItemSchema } = require('../contracts');

const ALLOWED_SEC_HOSTS = Object.freeze([
  'data.sec.gov',
  'www.sec.gov',
  'sec.gov',
]);

function providerError(code, message) {
  const error = new Error(message);
  error.code = code;
  return error;
}

function isInternalSecHost(hostname) {
  let host = String(hostname || '').toLowerCase();
  if (host.startsWith('[') && host.endsWith(']')) host = host.slice(1, -1); // WHATWG keeps brackets for IPv6
  if (host === 'localhost' || host.endsWith('.localhost') || host.endsWith('.local')) return true;
  if (host === '0.0.0.0' || host === '169.254.169.254') return true;
  if (host.startsWith('127.')) return true; // remainder of 127.0.0.0/8
  if (host.startsWith('10.')) return true;
  if (host.startsWith('192.168.')) return true;
  if (host.startsWith('172.')) {
    const secondOctet = Number.parseInt(host.split('.')[1], 10);
    if (Number.isInteger(secondOctet) && secondOctet >= 16 && secondOctet <= 31) return true; // 172.16.0.0/12
  }
  if (host === '::1' || host === '::') return true; // IPv6 loopback
  if (host.startsWith('fe80:')) return true; // IPv6 link-local fe80::/10
  if (host.startsWith('::ffff:')) { // IPv4-mapped IPv6, dotted or hex-normalized by WHATWG
    const mapped = host.slice('::ffff:'.length);
    let dotted = mapped.includes('.') ? mapped : null;
    if (!dotted) {
      const groups = mapped.split(':').filter(Boolean);
      const hi = Number.parseInt(groups.length === 2 ? groups[0] : '0', 16);
      const lo = Number.parseInt(groups[groups.length - 1] || '', 16);
      dotted = Number.isInteger(hi) && Number.isInteger(lo)
        ? `${(hi >> 8) & 0xff}.${hi & 0xff}.${(lo >> 8) & 0xff}.${lo & 0xff}`
        : '';
    }
    return dotted ? isInternalSecHost(dotted) : true; // unparseable mapped address: deny conservatively
  }
  return false;
}

function assertAllowedSecUrl(url) {
  let parsed;
  try {
    parsed = new URL(url);
  } catch {
    throw providerError('URL_NOT_ALLOWED', 'Invalid SEC URL format');
  }
  if (parsed.protocol !== 'https:' && parsed.protocol !== 'http:') {
    throw providerError('URL_NOT_ALLOWED', 'Disallowed protocol for SEC URL');
  }
  const hostname = parsed.hostname.toLowerCase();
  if (isInternalSecHost(hostname)) {
    throw providerError('URL_NOT_ALLOWED', 'Local or internal IP destinations forbidden');
  }
  if (!ALLOWED_SEC_HOSTS.includes(hostname)) {
    throw providerError('URL_NOT_ALLOWED', `SEC URL host "${hostname}" is not allowlisted`);
  }
  return parsed;
}

function normalizeTimestamp(value) {
  if (!value) return null;
  const date = new Date(value);
  return Number.isNaN(date.valueOf()) ? null : date.toISOString();
}

function cleanCik(rawCik) {
  const digits = String(rawCik || '').replace(/\D/g, '');
  return digits.padStart(10, '0');
}

// A ticker is not a CIK: a missing CIK must surface as explicit SEC unavailability,
// never as a fabricated zero-CIK query.
function requireCik(instrument) {
  const digits = String(instrument?.cik || '').replace(/\D/g, '');
  if (!digits) {
    throw providerError('CIK_MISSING', 'Instrument has no SEC CIK; SEC evidence is explicitly unavailable');
  }
  return digits.padStart(10, '0');
}

class SecEvidenceAdapter {
  constructor({
    fetch = globalThis.fetch,
    userAgent = 'HorizonResearch contact@horizon.local',
    timeoutMs = 8_000,
    now = () => new Date(),
  } = {}) {
    if (typeof fetch !== 'function') throw new TypeError('SecEvidenceAdapter requires fetch');
    this.fetch = fetch;
    this.userAgent = userAgent;
    this.timeoutMs = timeoutMs;
    this.now = now;
  }

  async fetchFromUrl(url) {
    assertAllowedSecUrl(url);
    const controller = new AbortController();
    let timeout;
    const timeoutPromise = new Promise((_, reject) => {
      timeout = setTimeout(() => {
        controller.abort();
        reject(providerError('PROVIDER_TIMEOUT', 'SEC provider timed out'));
      }, this.timeoutMs);
    });

    try {
      const response = await Promise.race([
        this.fetch(url, {
          signal: controller.signal,
          headers: {
            'User-Agent': this.userAgent,
            Accept: 'application/json',
          },
        }),
        timeoutPromise,
      ]);

      if (!response?.ok) {
        throw providerError('PROVIDER_UNAVAILABLE', `SEC request returned HTTP ${response?.status || 'unknown'}`);
      }

      return await Promise.race([response.json(), timeoutPromise]);
    } catch (error) {
      if (error?.code === 'PROVIDER_TIMEOUT' || error?.name === 'AbortError') {
        throw providerError('PROVIDER_TIMEOUT', 'SEC provider timed out');
      }
      if (error?.code === 'URL_NOT_ALLOWED') {
        throw error;
      }
      throw providerError('PROVIDER_UNAVAILABLE', error.message || 'SEC provider request failed');
    } finally {
      clearTimeout(timeout);
    }
  }

  async fetchSubmissions(instrument, { cutoffAt } = {}) {
    const cik = requireCik(instrument);
    const url = `https://data.sec.gov/submissions/CIK${cik}.json`;
    return this.fetchFromUrl(url);
  }

  async fetchCompanyFacts(instrument, { cutoffAt } = {}) {
    const cik = requireCik(instrument);
    const url = `https://data.sec.gov/api/xbrl/companyfacts/CIK${cik}.json`;
    return this.fetchFromUrl(url);
  }

  async fetchEvidence(instrument, { cutoffAt } = {}) {
    let submissions;
    let companyFacts;
    try {
      submissions = await this.fetchSubmissions(instrument, { cutoffAt });
    } catch (error) {
      if (error.code === 'PROVIDER_TIMEOUT' || error.code === 'URL_NOT_ALLOWED' || error.code === 'CIK_MISSING') throw error;
      submissions = null;
    }

    try {
      companyFacts = await this.fetchCompanyFacts(instrument, { cutoffAt });
    } catch (error) {
      if (error.code === 'PROVIDER_TIMEOUT' || error.code === 'URL_NOT_ALLOWED' || error.code === 'CIK_MISSING') throw error;
      companyFacts = null;
    }

    if (!submissions?.filings?.recent) {
      return [];
    }

    const recent = submissions.filings.recent;
    const count = recent.accessionNumber?.length || 0;
    const cikNum = parseInt(cleanCik(submissions.cik || instrument.cik), 10) || 0;

    // Index facts by accession number
    const factsByAccn = new Map();
    if (companyFacts?.facts) {
      for (const taxonomy of Object.keys(companyFacts.facts)) {
        const concepts = companyFacts.facts[taxonomy];
        for (const conceptName of Object.keys(concepts)) {
          const concept = concepts[conceptName];
          const units = concept.units || {};
          for (const unitKey of Object.keys(units)) {
            for (const item of units[unitKey]) {
              const accn = item.accn;
              if (!accn) continue;

              // Check cutoff on the individual fact if filed date is present
              const factFiledTime = item.filed ? `${item.filed}T23:59:59.000Z` : null;
              if (cutoffAt && factFiledTime && factFiledTime > cutoffAt) {
                // Later amended or filed facts cannot enter earlier cutoff evidence
                continue;
              }

              if (!factsByAccn.has(accn)) {
                factsByAccn.set(accn, []);
              }

              const isAmended = item.form && item.form.endsWith('/A');
              const factId = `fact-${conceptName.toLowerCase()}-${accn.replace(/[^a-zA-Z0-9]/g, '')}`;
              const currency = unitKey === 'USD' ? 'USD' : (unitKey.length === 3 ? unitKey : null);
              const reportingPeriod = item.start && item.end && item.start <= item.end
                ? {
                  start: item.start,
                  end: item.end,
                  label: item.fp && item.fy ? `${item.fp} ${item.fy}` : null,
                }
                : item.end
                  ? { start: null, end: item.end, label: item.fp && item.fy ? `${item.fp} ${item.fy}` : null }
                  : null;

              factsByAccn.get(accn).push({
                id: factId,
                label: concept.label || conceptName,
                value: typeof item.val === 'number' ? item.val : String(item.val || ''),
                unit: unitKey,
                currency,
                basis: isAmended ? 'US-GAAP (amended)' : 'US-GAAP',
                reporting_period: reportingPeriod,
              });
            }
          }
        }
      }
    }

    const items = [];
    const supportedForms = new Set(['10-K', '10-Q', '8-K', '10-K/A', '10-Q/A']);

    for (let i = 0; i < count; i += 1) {
      const form = recent.form?.[i];
      if (!form || !supportedForms.has(form)) continue;

      const accn = recent.accessionNumber?.[i];
      const filingDate = recent.filingDate?.[i];
      const reportDate = recent.reportDate?.[i];
      const acceptanceDateTime = recent.acceptanceDateTime?.[i];
      const primaryDoc = recent.primaryDocument?.[i] || `${form}.htm`;

      const availableAt = normalizeTimestamp(acceptanceDateTime)
        || (filingDate ? `${filingDate}T00:00:00.000Z` : null);

      // Strict cutoff filtering
      if (cutoffAt && availableAt && availableAt > cutoffAt) {
        continue;
      }

      const isAmended = form.endsWith('/A');
      const facts = (factsByAccn.get(accn) || []).slice(0, 100);

      // Determine reporting period from filing or matched facts
      let reportingPeriod = null;
      if (facts.length > 0 && facts[0].reporting_period) {
        reportingPeriod = facts[0].reporting_period;
      } else if (reportDate) {
        reportingPeriod = { start: null, end: reportDate, label: null };
      }

      const publishedAt = filingDate ? `${filingDate}T00:00:00.000Z` : availableAt;
      const cleanAccn = accn.replace(/-/g, '');
      const sourceUrl = `https://www.sec.gov/ix?doc=/Archives/edgar/data/${cikNum}/${cleanAccn}/${primaryDoc}`;

      let titleForm = form;
      if (form === '10-K') titleForm = 'Form 10-K Annual Report';
      else if (form === '10-Q') titleForm = 'Form 10-Q Quarterly Report';
      else if (form === '8-K') titleForm = 'Form 8-K Current Report';
      else if (form === '10-K/A') titleForm = 'Form 10-K/A Annual Report (Amended)';
      else if (form === '10-Q/A') titleForm = 'Form 10-Q/A Quarterly Report (Amended)';

      const excerpt = isAmended
        ? `Amended filing ${form} accession ${accn} filed on ${filingDate || 'unknown date'}.`
        : `Official filing ${form} accession ${accn} for reporting period ending ${reportDate || 'N/A'}.`;

      const item = {
        id: `evidence-sec-${accn.replace(/[^a-zA-Z0-9]/g, '-')}`,
        instrument_id: instrument.instrument_id,
        kind: form === '8-K' ? 'corporate_action' : 'filing',
        title: titleForm,
        source_url: sourceUrl,
        source_name: 'SEC EDGAR',
        published_at: publishedAt,
        retrieved_at: this.now().toISOString(),
        available_at: availableAt,
        reporting_period: reportingPeriod,
        excerpt,
        source_locator: `${accn}:${primaryDoc}`,
        facts,
        coverage_status: 'available',
      };

      const validated = evidenceItemSchema.parse(item);
      items.push(validated);
    }

    return items;
  }
}

module.exports = {
  SecEvidenceAdapter,
  ALLOWED_SEC_HOSTS,
};
