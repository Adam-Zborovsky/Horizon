const crypto = require('node:crypto');
const { evidenceItemSchema } = require('../contracts');

const ALLOWED_NEWS_HOSTS = Object.freeze([
  'www.prnewswire.com',
  'prnewswire.com',
  'www.businesswire.com',
  'businesswire.com',
  'www.globenewswire.com',
  'globenewswire.com',
  'finance.yahoo.com',
  'feeds.finance.yahoo.com',
  'news.company.com',
  'investor.company.com',
  'press.company.com',
]);

const MAX_FEED_ENTRIES = 50;

function providerError(code, message) {
  const error = new Error(message);
  error.code = code;
  return error;
}

function isInternalNewsHost(hostname) {
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
    return dotted ? isInternalNewsHost(dotted) : true; // unparseable mapped address: deny conservatively
  }
  return false;
}

function assertAllowedNewsUrl(url) {
  let parsed;
  try {
    parsed = new URL(url);
  } catch {
    throw providerError('URL_NOT_ALLOWED', 'Invalid News URL format');
  }
  if (parsed.protocol !== 'https:' && parsed.protocol !== 'http:') {
    throw providerError('URL_NOT_ALLOWED', 'Disallowed protocol for News URL');
  }
  const hostname = parsed.hostname.toLowerCase();
  if (isInternalNewsHost(hostname)) {
    throw providerError('URL_NOT_ALLOWED', 'Local or internal IP destinations forbidden');
  }
  if (!ALLOWED_NEWS_HOSTS.includes(hostname)) {
    throw providerError('URL_NOT_ALLOWED', `News URL host "${hostname}" is not allowlisted`);
  }
  return parsed;
}

function deriveNewsFeedUrl(instrument) {
  const explicitFeedUrl = instrument?.news_feed_url || instrument?.ir_feed_url;
  if (explicitFeedUrl) {
    return String(explicitFeedUrl);
  }
  const symbol = String(instrument?.symbol || '').trim();
  if (!symbol) {
    return null;
  }
  return `https://feeds.finance.yahoo.com/rss/2.0/headline?s=${encodeURIComponent(symbol)}&region=US&lang=en-US`;
}

function decodeFeedEntities(text) {
  return String(text || '')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&apos;/g, "'")
    .replace(/&#0?39;/g, "'")
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&');
}

function stripCdata(text) {
  return String(text || '').replace(/^\s*<!\[CDATA\[/, '').replace(/\]\]>\s*$/, '');
}

function extractFeedTag(block, tag) {
  const match = new RegExp(`<${tag}(?:\\s[^>]*)?>([\\s\\S]*?)</${tag}>`, 'i').exec(block);
  if (match) {
    const value = decodeFeedEntities(stripCdata(match[1])).trim();
    return value || null;
  }
  if (tag === 'link') {
    const hrefMatch = /<link\b[^>]*\bhref=["']([^"']+)["']/i.exec(block);
    if (hrefMatch) {
      const value = decodeFeedEntities(hrefMatch[1]).trim();
      return value || null;
    }
  }
  return null;
}

function parseFeedText(text) {
  const trimmed = String(text || '').trim();
  if (!trimmed) return [];

  if (trimmed[0] === '{' || trimmed[0] === '[') {
    try {
      const parsed = JSON.parse(trimmed);
      if (Array.isArray(parsed)) return parsed;
      if (Array.isArray(parsed?.items)) return parsed.items;
      if (Array.isArray(parsed?.articles)) return parsed.articles;
      return [];
    } catch {
      return [];
    }
  }

  const entries = [];
  const blocks = trimmed.match(/<(?:item|entry)\b[\s\S]*?<\/(?:item|entry)>/gi) || [];
  for (const block of blocks.slice(0, MAX_FEED_ENTRIES)) {
    const title = extractFeedTag(block, 'title');
    const link = extractFeedTag(block, 'link');
    if (!title && !link) continue;

    const publishedRaw = extractFeedTag(block, 'pubDate')
      || extractFeedTag(block, 'published')
      || extractFeedTag(block, 'updated');
    const publishedDate = publishedRaw ? new Date(publishedRaw) : null;

    entries.push({
      title: title || 'Untitled Announcement',
      source_url: link || undefined,
      source_name: extractFeedTag(block, 'source') || 'Yahoo Finance',
      excerpt: extractFeedTag(block, 'description') || extractFeedTag(block, 'summary') || null,
      published_at: publishedDate && !Number.isNaN(publishedDate.valueOf())
        ? publishedDate.toISOString()
        : undefined,
    });
  }
  return entries;
}

function sanitizeUntrustedText(text) {
  if (!text || typeof text !== 'string') return null;

  // Strip dangerous HTML/scripts
  let cleaned = text
    .replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '')
    .replace(/<[^>]+>/g, '')
    .replace(/\{\{[\s\S]*?\}\}/g, '[INTERPOLATION_REMOVED]');

  // Neutralize common prompt injection directives
  const injectionPatterns = [
    /\b(?:system\s*:|system\s+update\s*:)/gi,
    /\bignore\s+(?:all\s+)?(?:previous|prior)\s+instructions\b/gi,
    /\bcall\s+tool\s*:\s*\w+/gi,
    /\bexport\s+(?:all\s+)?credentials\b/gi,
    /\bdump\s+env\b/gi,
  ];

  for (const pattern of injectionPatterns) {
    cleaned = cleaned.replace(pattern, '[REDACTED_DIRECTIVE]');
  }

  cleaned = cleaned.trim().slice(0, 3900);
  return `[UNTRUSTED_CONTENT] ${cleaned}`;
}

function sanitizeTitle(title) {
  if (!title || typeof title !== 'string') return 'Untitled Announcement';
  let cleaned = title
    .replace(/<[^>]+>/g, '')
    .replace(/^(?:system\s*:|system\s+update\s*:)/gi, 'Notice:')
    .trim()
    .slice(0, 500);
  return cleaned || 'Untitled Announcement';
}

function normalizeTitleForDedup(title) {
  return String(title || '')
    .toLowerCase()
    .replace(/[^a-z0-9]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

class CompanyNewsProvider {
  constructor({
    fetch = globalThis.fetch,
    userAgent,
    timeoutMs = 8_000,
    now = () => new Date(),
    allowedHosts = ALLOWED_NEWS_HOSTS,
  } = {}) {
    if (typeof fetch !== 'function') throw new TypeError('CompanyNewsProvider requires fetch');
    if (typeof userAgent !== 'string' || userAgent.trim().length === 0) throw new TypeError('CompanyNewsProvider requires a configured userAgent');
    this.fetch = fetch;
    this.userAgent = userAgent;
    this.timeoutMs = timeoutMs;
    this.now = now;
    this.allowedHosts = allowedHosts;
  }

  // Bounded retrieval: allowlist check, declared User-Agent, 8s AbortController timeout,
  // HTTP-status check and a body read raced against the same timeout.
  async fetchBounded(url, parseBody) {
    assertAllowedNewsUrl(url);
    const controller = new AbortController();
    let timeout;
    const timeoutPromise = new Promise((_, reject) => {
      timeout = setTimeout(() => {
        controller.abort();
        reject(providerError('PROVIDER_TIMEOUT', 'News provider timed out'));
      }, this.timeoutMs);
    });

    try {
      const response = await Promise.race([
        this.fetch(url, {
          signal: controller.signal,
          headers: {
            'User-Agent': this.userAgent,
            Accept: 'application/json, application/rss+xml, application/xml, text/xml;q=0.9',
          },
        }),
        timeoutPromise,
      ]);
      if (!response?.ok) {
        throw providerError('PROVIDER_UNAVAILABLE', `News provider returned HTTP ${response?.status}`);
      }
      return await Promise.race([parseBody(response), timeoutPromise]);
    } catch (error) {
      if (error.code === 'URL_NOT_ALLOWED') throw error;
      if (error.code === 'PROVIDER_TIMEOUT' || error.name === 'AbortError') {
        throw providerError('PROVIDER_TIMEOUT', 'News provider timed out');
      }
      throw providerError('PROVIDER_UNAVAILABLE', error.message || 'News provider failed');
    } finally {
      clearTimeout(timeout);
    }
  }

  async fetchNews(instrument, { sourceUrl, cutoffAt } = {}) {
    let rawFeed;
    if (sourceUrl) {
      rawFeed = await this.fetchBounded(sourceUrl, (response) => {
        const contentType = response?.headers?.get?.('content-type') || '';
        if (contentType.includes('json')) return response.json();
        return response.text().then(parseFeedText);
      });
    } else {
      const derivedUrl = deriveNewsFeedUrl(instrument);
      if (!derivedUrl) {
        // No derivable allowlisted news source: caller surfaces news_coverage_unavailable
        // explicitly instead of fabricating coverage.
        return [];
      }
      rawFeed = await this.fetchBounded(derivedUrl, async (response) => {
        const contentType = response?.headers?.get?.('content-type') || '';
        if (contentType.includes('json')) return response.json();
        return parseFeedText(await response.text());
      });
    }

    if (!Array.isArray(rawFeed)) {
      rawFeed = [];
    }

    // Step 1: Filter by cutoff and validate URLs
    const filtered = [];
    for (const entry of rawFeed) {
      const url = entry.source_url || entry.url || `https://news.company.com/${instrument.symbol.toLowerCase()}/${Date.now()}`;
      try {
        assertAllowedNewsUrl(url);
      } catch (err) {
        if (sourceUrl) throw err;
        continue; // skip disallowed url in general feed
      }

      const publishedAt = entry.published_at || (entry.date ? new Date(entry.date).toISOString() : this.now().toISOString());
      const availableAt = entry.available_at || publishedAt;

      if (cutoffAt && availableAt > cutoffAt) {
        continue;
      }

      filtered.push({
        ...entry,
        source_url: url,
        published_at: publishedAt,
        available_at: availableAt,
      });
    }

    // Step 2: Deduplication by normalized title + published date (YYYY-MM-DD)
    const dedupMap = new Map();
    for (const item of filtered) {
      const normTitle = normalizeTitleForDedup(item.title);
      const dateKey = item.published_at.slice(0, 10);
      const dedupKey = `${normTitle}|${dateKey}`;

      if (!dedupMap.has(dedupKey)) {
        dedupMap.set(dedupKey, item);
      } else {
        const existing = dedupMap.get(dedupKey);
        // If current has excerpt and existing did not, update existing with the excerpt
        if (!existing.excerpt && item.excerpt) {
          existing.excerpt = item.excerpt;
        }
      }
    }

    // Step 3: Sanitize and construct validated EvidenceItems
    const items = [];
    for (const item of dedupMap.values()) {
      const hasExcerpt = Boolean(item.excerpt && String(item.excerpt).trim().length > 0);
      const sanitizedExcerpt = hasExcerpt ? sanitizeUntrustedText(item.excerpt) : null;
      const sanitizedTitleText = sanitizeTitle(item.title);
      const coverageStatus = hasExcerpt ? 'available' : 'headline_only';

      const locatorId = item.source_locator
        || `news:${item.source_name || 'wire'}:${crypto.createHash('sha256').update(item.source_url).digest('hex').slice(0, 12)}`;

      const evidenceItem = {
        id: `evidence-news-${crypto.createHash('sha256').update(locatorId + item.published_at).digest('hex').slice(0, 16)}`,
        instrument_id: instrument.instrument_id,
        kind: item.kind === 'company_ir' ? 'company_ir' : 'news',
        title: sanitizedTitleText,
        source_url: item.source_url,
        source_name: item.source_name || 'Company Wire',
        published_at: item.published_at,
        retrieved_at: this.now().toISOString(),
        available_at: item.available_at,
        reporting_period: null,
        excerpt: sanitizedExcerpt,
        source_locator: locatorId,
        facts: [],
        coverage_status: coverageStatus,
      };

      const parsed = evidenceItemSchema.parse(evidenceItem);
      items.push(parsed);
    }

    return items;
  }
}

module.exports = {
  CompanyNewsProvider,
  ALLOWED_NEWS_HOSTS,
  sanitizeUntrustedText,
};
