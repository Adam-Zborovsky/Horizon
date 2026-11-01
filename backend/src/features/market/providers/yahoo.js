const RANGE_PARAMETERS = Object.freeze({
  '1D': { range: '1d', interval: '5m' },
  '1W': { range: '5d', interval: '30m' },
  '1M': { range: '1mo', interval: '1d' },
  '3M': { range: '3mo', interval: '1d' },
  '6M': { range: '6mo', interval: '1d' },
  '1Y': { range: '1y', interval: '1d' },
});

function providerError(code, message) {
  const error = new Error(message);
  error.code = code;
  return error;
}

function utcTimestamp(seconds) {
  if (!Number.isFinite(seconds)) return null;
  const value = new Date(seconds * 1000);
  return Number.isNaN(value.valueOf()) ? null : value.toISOString();
}

function sessionDate(timestamp, timezone) {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone: timezone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).formatToParts(new Date(timestamp));
  const part = (type) => parts.find((entry) => entry.type === type)?.value;
  const year = part('year');
  const month = part('month');
  const day = part('day');
  return year && month && day ? `${year}-${month}-${day}` : null;
}

class YahooMarketProvider {
  constructor({ fetch = globalThis.fetch, timeoutMs = 8_000, now = () => new Date() } = {}) {
    if (typeof fetch !== 'function') throw new TypeError('YahooMarketProvider requires fetch');
    this.fetch = fetch;
    this.timeoutMs = timeoutMs;
    this.now = now;
  }

  async fetchHistory(instrument, { range, resolution }) {
    const parameters = RANGE_PARAMETERS[range];
    if (!parameters || parameters.interval !== resolution) {
      throw providerError('UNSUPPORTED_RESOLUTION', 'Requested range/resolution is unsupported by the Yahoo adapter');
    }
    if (!instrument || typeof instrument.provider_symbol !== 'string' || instrument.provider_symbol.length === 0) {
      throw providerError('INVALID_INSTRUMENT', 'Instrument has no vetted provider symbol');
    }

    const controller = new AbortController();
    let timeout;
    const timeoutPromise = new Promise((_, reject) => {
      timeout = setTimeout(() => {
        controller.abort();
        reject(providerError('PROVIDER_TIMEOUT', 'Market provider timed out'));
      }, this.timeoutMs);
    });
    let response;
    let payload;
    try {
      const symbol = encodeURIComponent(instrument.provider_symbol);
      const url = new URL(`https://query1.finance.yahoo.com/v8/finance/chart/${symbol}`);
      url.searchParams.set('range', parameters.range);
      url.searchParams.set('interval', parameters.interval);
      url.searchParams.set('includePrePost', 'false');
      url.searchParams.set('events', 'history');
      try {
        response = await Promise.race([
          this.fetch(url, { signal: controller.signal, headers: { accept: 'application/json' } }),
          timeoutPromise,
        ]);
      } catch (error) {
        if (error?.code === 'PROVIDER_TIMEOUT' || error?.name === 'AbortError') {
          throw providerError('PROVIDER_TIMEOUT', 'Market provider timed out');
        }
        throw providerError('PROVIDER_UNAVAILABLE', 'Market provider request failed');
      }

      if (!response?.ok) {
        throw providerError('PROVIDER_UNAVAILABLE', 'Market provider returned an unsuccessful response');
      }

      try {
        payload = await Promise.race([response.json(), timeoutPromise]);
      } catch (error) {
        if (error?.code === 'PROVIDER_TIMEOUT' || error?.name === 'AbortError') {
          throw providerError('PROVIDER_TIMEOUT', 'Market provider timed out');
        }
        throw providerError('PROVIDER_INVALID_RESPONSE', 'Market provider returned invalid JSON');
      }
    } finally {
      clearTimeout(timeout);
    }
    if (payload?.chart?.error) {
      throw providerError('PROVIDER_UNAVAILABLE', 'Market provider reported an unavailable instrument or range');
    }

    const result = payload?.chart?.result?.[0];
    const quote = result?.indicators?.quote?.[0];
    const timestamps = result?.timestamp;
    const timezone = result?.meta?.exchangeTimezoneName;
    if (!result || !quote || !Array.isArray(timestamps) || typeof timezone !== 'string') {
      throw providerError('PROVIDER_INVALID_RESPONSE', 'Market provider omitted required chart fields');
    }

    const adjusted = result.indicators?.adjclose?.[0]?.adjclose || [];
    const lastTimestamp = result.meta?.regularMarketTime;
    const bars = [];
    let invalidBarCount = 0;
    for (let index = 0; index < timestamps.length; index += 1) {
      const time = utcTimestamp(timestamps[index]);
      const open = quote.open?.[index];
      const high = quote.high?.[index];
      const low = quote.low?.[index];
      const close = quote.close?.[index];
      const volume = quote.volume?.[index];
      const adjustedClose = adjusted[index];
      const date = time ? sessionDate(time, timezone) : null;
      if (!time || !date || ![open, high, low, close].every(Number.isFinite)
        || open <= 0 || high <= 0 || low <= 0 || close <= 0
        || low > Math.min(open, close) || high < Math.max(open, close)
        || (volume != null && (!Number.isInteger(volume) || volume < 0))
        || (adjustedClose != null && (!Number.isFinite(adjustedClose) || adjustedClose <= 0))) {
        invalidBarCount += 1;
        continue;
      }
      bars.push({
        time,
        session_date: date,
        open,
        high,
        low,
        close,
        volume: volume ?? null,
        adjusted_close: adjustedClose ?? null,
        is_final: Number.isFinite(lastTimestamp) ? timestamps[index] <= lastTimestamp : false,
      });
    }

    const delay = result.meta?.exchangeDataDelayedBy;
    return {
      bars,
      invalid_bar_count: invalidBarCount,
      actual_resolution: result.meta?.dataGranularity || resolution,
      exchange_timezone: timezone,
      adjustment_basis: 'raw_ohlc_unadjusted',
      delay_status: Number.isFinite(delay) && delay > 0 ? 'delayed' : 'unknown',
      as_of: utcTimestamp(lastTimestamp) || bars.at(-1)?.time || null,
      fetched_at: this.now().toISOString(),
      source: {
        provider: 'yahoo_chart',
        name: 'Yahoo Finance chart',
        requested_range: parameters.range,
        requested_interval: parameters.interval,
      },
      warnings: invalidBarCount > 0 ? [{ code: 'INVALID_PROVIDER_ROWS_OMITTED', count: invalidBarCount }] : [],
    };
  }
}

module.exports = { YahooMarketProvider, RANGE_PARAMETERS };
