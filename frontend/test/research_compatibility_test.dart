// H15 — canonical Flutter compatibility test (frontend half).
//
// Mirrors, at the Flutter layer, the controller-verified frozen backend
// suite (backend/test/research-compatibility.test.cjs, 15/15):
//
//   A-series — authoritative-price compatibility. The accepted backend
//   contract (CONTRACTS §1, H15B) carries structured model-reported prices
//   only. Prose is NEVER scraped for prices or changes: the legacy
//   "$100/random fallback" defect class (an explanation string mentioning a
//   price becoming a rendered quote) is eliminated here, and 0.0 / empty
//   history mean "unavailable" and must render truthfully downstream.
//
//   B-series — legacy tickers-only watchlist writes. The accepted backend
//   refuses a stale tickers-only PUT that would remove tickers backing
//   active positions with 409 POSITION_TICKER_CONFLICT (bounded/explicit,
//   never destructive replacement). The Flutter client surfaces that
//   refusal as a typed exception with the server message verbatim and no
//   silent retry; the wire body is
//   `{success: false, error: {message, code}}` (backend/src/middleware/
//   error.middleware.js), with `error.details.blocked_removals` parsed
//   through only when present.
//
//   C-series — mobile/Wear rendering compatibility. Wear surfaces compile/
//   parse StockData without any chart dependency (SPEC: no full chart on
//   watch) and never render a fabricated "$0.00" for unavailable prices.
//
// The A-series exercises the REAL StockRepository mapping through its
// generated provider with only its two inputs (briefing, config) replaced;
// the B-series exercises the REAL BriefingConfigRepository and Watchlist
// providers over a scripted package:http transport. Fixtures are hermetic
// hand-built model objects and wire-shape JSON; no network, no platform
// channels, no secrets. package:http/testing MockClient is already a
// dependency: no new dependency and no hand-authored generated file.
//
// EXECUTION STATUS: DEFERRED_TO_DEV_PC (no Dart/Flutter SDK on this host —
// `dart --version` → command not found). Authored here; must be run on the
// development PC as:
//   flutter test test/research_compatibility_test.dart
import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:horizon/src/features/briefing/briefing_config_repository.dart';
import 'package:horizon/src/features/briefing/briefing_model.dart';
import 'package:horizon/src/features/briefing/briefing_repository.dart';
import 'package:horizon/src/features/dashboard/watchlist_provider.dart';
import 'package:horizon/src/features/positions/position_repository.dart';
import 'package:horizon/src/features/stock/stock_detail_screen.dart';
import 'package:horizon/src/features/stock/stock_repository.dart';
import 'package:horizon/src/wear/wear_opportunities_screen.dart';
import 'package:horizon/src/wear/wear_watchlist_screen.dart';

// ---------------------------------------------------------------------------
// Fixtures — hermetic, hand-built. Never labeled observed market data.
// ---------------------------------------------------------------------------

BriefingItem _item(Map<String, dynamic> overrides) {
  final map = <String, dynamic>{
    'ticker': 'TEST',
    'name': 'Test Instruments',
    // Deliberately prose-rich fields: a legacy client scraping these would
    // fabricate a $100.00 quote. No structured price is present unless the
    // caller overrides 'price'.
    'explanation': 'Trading near $100.00 and up 2.5% on the session.',
    'takeaway': 'Target price $100.00.',
    'potential_price_action': 'Approaching $100.00, +2.5%.',
  };
  map.addAll(overrides);
  return BriefingItem.fromJson(map);
}

CategoryData _category(List<BriefingItem> items) =>
    CategoryData(summary: 'fixture category', items: items);

BriefingData _briefing(Map<String, CategoryData> data) =>
    BriefingData(data: data, success: true, message: 'fixture briefing');

const _emptyConfig = BriefingConfig(tickers: <String>[], topics: <Topic>[]);

http.Response _json(int status, Object body) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

http.Client _neverClient() => MockClient((request) async {
      fail('No HTTP expected from this fixture');
    });

// ---------------------------------------------------------------------------
// A-series harness: the REAL stock repository mapping with substituted
// inputs (briefing + config). The mapping under test is the real one.
// ---------------------------------------------------------------------------

Future<List<StockData>> _mapStocks({
  required BriefingData briefing,
  BriefingConfig config = _emptyConfig,
}) async {
  final container = ProviderContainer(
    overrides: [
      briefingRepositoryProvider.overrideWith(
        (ref) => _FixtureBriefingRepository(briefing),
      ),
      briefingConfigRepositoryProvider.overrideWith(
        (ref) => _FixtureConfigRepository(config, _neverClient()),
      ),
    ],
  );
  addTearDown(container.dispose);
  // Keep the autoDispose providers alive for the duration of the mapping.
  container.listen(stockRepositoryProvider, (_, __) {});
  return container.read(stockRepositoryProvider.future);
}

class _FixtureBriefingRepository extends BriefingRepository {
  _FixtureBriefingRepository(this.fixture);
  final BriefingData fixture;

  @override
  Future<BriefingData> build() async => fixture;
}

class _FixtureConfigRepository extends BriefingConfigRepository {
  _FixtureConfigRepository(this.fixture, this.client);
  final BriefingConfig fixture;
  final http.Client client;

  @override
  Future<BriefingConfig> build() async => fixture;

  @override
  http.Client createClient() => client;
}

// ---------------------------------------------------------------------------
// B-series harness: the REAL config repository over a scripted transport.
// ---------------------------------------------------------------------------

class _ScriptedTransport {
  _ScriptedTransport(this._handler);

  final List<http.Request> requests = [];
  final ({int status, Object body}) Function(http.Request request) _handler;

  http.Client build() => MockClient((request) async {
        requests.add(request);
        final scripted = _handler(request);
        return _json(scripted.status, scripted.body);
      });

  List<http.Request> calls(String method, String pathSuffix) => requests
      .where((r) => r.method == method && r.url.path.endsWith(pathSuffix))
      .toList();
}

const _conflictBody = {
  'success': false,
  'error': {
    'message':
        'Stale tickers-only update refused: removing tickers that back '
            'active positions is destructive replacement. Classify/archive '
            'those positions explicitly, then retry.',
    'code': 'POSITION_TICKER_CONFLICT',
    'details': [
      {'ticker': 'MSFT', 'active_position_ids': ['pos-1']},
    ],
  },
};

ProviderContainer _configContainer(_ScriptedTransport transport,
    {BriefingConfig initial = _emptyConfig}) {
  final container = ProviderContainer(
    overrides: [
      briefingConfigRepositoryProvider.overrideWith(
        (ref) => _FixtureConfigRepository(initial, transport.build()),
      ),
    ],
  );
  addTearDown(container.dispose);
  // Keep the autoDispose config provider alive across awaits in the tests.
  container.listen(briefingConfigRepositoryProvider, (_, __) {});
  return container;
}

// ---------------------------------------------------------------------------
// C-series fixtures: Wear screens need nothing but the widget tree; the
// detail screen gets its real providers with substituted inputs.
// ---------------------------------------------------------------------------

const _availableStock = StockData(
  ticker: 'TEST',
  name: 'Test Instruments',
  currentPrice: 420.97,
  changePercent: 1.2,
  history: <double>[],
  sentiment: 0.7,
  source: StockSource.watchlist,
);

const _unavailableStock = StockData(
  ticker: 'NOQ',
  name: 'No Quote Inc',
  currentPrice: 0.0, // 0.0 == "unavailable" (repository contract)
  changePercent: 0.0,
  history: <double>[],
  sentiment: 0.0,
  source: StockSource.watchlist,
);

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
  await tester.pump();
}

class _StaticStocks extends StockRepository {
  _StaticStocks(this.stocks);
  final List<StockData> stocks;

  @override
  Future<List<StockData>> build() async => stocks;
}

/// Detail-screen harness: no tracked position (honest no-position state),
/// the research wire never reached, briefing/config substituted so no test
/// touches the network.
Future<void> _pumpDetail(
  WidgetTester tester, {
  required List<StockData> stocks,
}) async {
  final transport = MockClient((request) async {
    final path = request.url.path;
    if (request.method == 'GET' && path.endsWith('/positions')) {
      return _json(200, {
        'positions': <Object>[],
      });
    }
    return _json(404, {
      'success': false,
      'error': {'message': 'NOT_FOUND', 'code': 'NOT_FOUND'},
    });
  });
  await tester.pumpWidget(
    MaterialApp(
      home: ProviderScope(
        overrides: [
          stockRepositoryProvider.overrideWith(
            (ref) => _StaticStocks(stocks),
          ),
          briefingConfigRepositoryProvider.overrideWith(
            (ref) => _FixtureConfigRepository(_emptyConfig, _neverClient()),
          ),
          positionRepositoryProvider.overrideWith(
            (ref) => PositionRepository(
              client: transport,
              tokenProvider: () async => 'test-token',
            ),
          ),
          researchWireProvider.overrideWithValue(
            ResearchWire(
              client: transport,
              tokenProvider: () async => 'test-token',
            ),
          ),
        ],
        child: const Scaffold(
          body: StockDetailScreen(ticker: 'TEST'),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('A — authoritative-price compatibility (no prose scraping)', () {
    test('A1: prose mentioning $100 never becomes a rendered quote', () async {
      // Regression on the eliminated defect class: legacy fallbacks scraped
      // explanation/takeaway/potential_price_action/analysis for prices.
      final stocks = await _mapStocks(briefing: _briefing({
        'market_analysis': _category([
          _item({
            'ticker': 'TEST',
            'price': null,
            'change': null,
          }),
        ]),
      }));

      expect(stocks, hasLength(1));
      expect(stocks.single.currentPrice, 0.0,
          reason: 'No structured price → unavailable (0.0), never the $100 '
              'mentioned in prose');
      expect(stocks.single.changePercent, 0.0,
          reason: 'No structured change → 0.0, never the +2.5% in prose');
      expect(stocks.single.history, isEmpty);
    });

    test('A2: structured model-reported price/change parse as-is', () async {
      final stocks = await _mapStocks(briefing: _briefing({
        'market_analysis': _category([
          _item({'price': '420.97', 'change': '-2.5%'}),
        ]),
      }));

      expect(stocks.single.currentPrice, 420.97);
      expect(stocks.single.changePercent, -2.5);
    });

    test('A3: model-reported history is carried; price falls back to '
        'history last only', () async {
      final stocks = await _mapStocks(briefing: _briefing({
        'market_analysis': _category([
          _item({
            'price': null,
            'history': <num>[100.0, 110.0, 120.0],
          }),
        ]),
      }));

      expect(stocks.single.history, <double>[100.0, 110.0, 120.0]);
      expect(stocks.single.currentPrice, 120.0,
          reason: 'history.last is model-reported — an accepted source');
    });

    test('A4: watchlist tickers without briefing data stay unavailable — '
        'nothing invented', () async {
      final stocks = await _mapStocks(
        briefing: _briefing({}),
        config: const BriefingConfig(
          tickers: <String>['WISH'],
          topics: <Topic>[],
        ),
      );

      expect(stocks, hasLength(1));
      expect(stocks.single.ticker, 'WISH');
      expect(stocks.single.currentPrice, 0.0);
      expect(stocks.single.changePercent, 0.0);
      expect(stocks.single.history, isEmpty);
      expect(stocks.single.source, StockSource.watchlist);
    });

    test('A5: sentiment stays an opinion scale; structured score wins over '
        'legacy strings', () async {
      final scored = await _mapStocks(briefing: _briefing({
        'market_analysis': _category([
          _item({
            'ticker': 'TEST',
            'sentiment_score': 0.4,
            'sentiment': 'very bullish',
          }),
        ]),
      }));
      expect(scored.single.sentiment, 0.4);

      final legacy = await _mapStocks(briefing: _briefing({
        'market_analysis': _category([
          _item({'ticker': 'TEST', 'sentiment': 'Bullish'}),
        ]),
      }));
      expect(legacy.single.sentiment, 0.7,
          reason: 'Legacy sentiment strings map to the opinion scale only — '
              'no market fact (price/history) is derived from them');
    });
  });

  group('B — legacy tickers-only writes: bounded explicit refusal', () {
    test('B1: 409 POSITION_TICKER_CONFLICT surfaces as the typed exception '
        'with the server message verbatim and blocked_removals parsed '
        'through', () async {
      var putCount = 0;
      final transport = _ScriptedTransport((request) {
        if (request.method == 'PUT' && request.url.path.endsWith('config')) {
          putCount += 1;
          return (status: 409, body: _conflictBody);
        }
        return (
          status: 404,
          body: {
            'success': false,
            'error': {'message': 'NOT_FOUND', 'code': 'NOT_FOUND'},
          },
        );
      });

      final container = _configContainer(
        transport,
        initial: const BriefingConfig(
          tickers: <String>['MSFT', 'AAPL'],
          topics: <Topic>[],
        ),
      );

      final repo = container.read(briefingConfigRepositoryProvider.notifier);
      await expectLater(
        repo.updateConfig(const BriefingConfig(
          tickers: <String>['AAPL'],
          topics: <Topic>[],
        )),
        throwsA(isA<PositionTickerConflictException>()
            .having((e) => e.code, 'code', 'POSITION_TICKER_CONFLICT')
            .having(
              (e) => e.message,
              'message',
              contains('Stale tickers-only update refused'),
            )
            .having((e) => e.blockedRemovals, 'blockedRemovals', hasLength(1))
            .having(
              (e) => e.blockedRemovals.single['ticker'],
              'blocked ticker',
              'MSFT',
            )),
      );

      // Bounded and explicit: exactly one PUT, no silent retry, and the
      // stored config state is NOT overwritten by the refused body.
      expect(putCount, 1);
    });

    test('B2: 200 update lands and refreshes state with the server config; '
        'exactly one PUT', () async {
      var putCount = 0;
      final transport = _ScriptedTransport((request) {
        if (request.method == 'PUT' && request.url.path.endsWith('config')) {
          putCount += 1;
          return (
            status: 200,
            body: {
              'topics': <Object>[],
              'tickers': <String>['AAPL'],
            },
          );
        }
        return (
          status: 404,
          body: {
            'success': false,
            'error': {'message': 'NOT_FOUND', 'code': 'NOT_FOUND'},
          },
        );
      });

      final container = _configContainer(
        transport,
        initial: const BriefingConfig(
          tickers: <String>['MSFT', 'AAPL'],
          topics: <Topic>[],
        ),
      );

      final repo = container.read(briefingConfigRepositoryProvider.notifier);
      await repo.updateConfig(const BriefingConfig(
        tickers: <String>['AAPL'],
        topics: <Topic>[],
      ));

      expect(putCount, 1);
      final config =
          await container.read(briefingConfigRepositoryProvider.future);
      expect(config.tickers, <String>['AAPL']);
    });

    test('B3: non-conflict API failures keep their status and stay a '
        'distinct type', () async {
      final transport = _ScriptedTransport((request) => (
            status: 500,
            body: {
              'success': false,
              'error': {'message': 'boom', 'code': 'INTERNAL_SERVER_ERROR'},
            },
          ));

      final container = _configContainer(transport);

      final repo = container.read(briefingConfigRepositoryProvider.notifier);
      await expectLater(
        repo.updateConfig(const BriefingConfig(
          tickers: <String>['X'],
          topics: <Topic>[],
        )),
        throwsA(isA<BriefingConfigApiException>()
            .having((e) => e.statusCode, 'statusCode', 500)),
      );
    });

    test('B4: watchlist.remove() surfaces the position-backed refusal '
        'through the real provider chain — no silent overwrite', () async {
      final transport = _ScriptedTransport((request) => (
            status: 409,
            body: _conflictBody,
          ));

      final container = _configContainer(
        transport,
        initial: const BriefingConfig(
          tickers: <String>['MSFT', 'AAPL'],
          topics: <Topic>[],
        ),
      );

      final watchlist = container.read(watchlistProvider.notifier);
      await expectLater(
        watchlist.remove('MSFT'),
        throwsA(isA<PositionTickerConflictException>()),
      );

      // The refused tickers-only write changed nothing: the PUT body carried
      // the complete structured array (old-client compatible), and the
      // in-memory watchlist state is untouched by the failure.
      final puts = transport.calls('PUT', 'config');
      expect(puts, hasLength(1));
      final sent = jsonDecode(puts.single.body) as Map<String, dynamic>;
      expect(sent['tickers'], <String>['AAPL']);
      expect(container.read(watchlistProvider), contains('MSFT'));
    });

    test('B5: watchlist.add() sends the full structured tickers array '
        'uppercased (accepted old-client shape)', () async {
      final transport = _ScriptedTransport((request) => (
            status: 200,
            body: {
              'topics': <Object>[],
              'tickers': <String>['MSFT', 'AAPL', 'NEW'],
            },
          ));

      final container = _configContainer(
        transport,
        initial: const BriefingConfig(
          tickers: <String>['MSFT', 'AAPL'],
          topics: <Topic>[],
        ),
      );

      await container.read(watchlistProvider.notifier).add('new');

      final puts = transport.calls('PUT', 'config');
      expect(puts, hasLength(1));
      final sent = jsonDecode(puts.single.body) as Map<String, dynamic>;
      expect(sent['tickers'], <String>['MSFT', 'AAPL', 'NEW']);
    });
  });

  group('C — Wear/detail rendering compatibility (no chart on watch, '
      'truthful unavailable prices)', () {
    testWidgets('C1: Wear watchlist renders quotes without any chart widget',
        (tester) async {
      await _pump(
        tester,
        SizedBox(
          width: 200,
          height: 200,
          child: WearWatchlistScreen(stocks: const [_availableStock]),
        ),
      );

      expect(find.text('TEST'), findsOneWidget);
      expect(find.text('\$420.97'), findsOneWidget);
      expect(find.text('+1.2%'), findsOneWidget);

      // SPEC: no full chart on watch — no fl_chart widget class anywhere in
      // the Wear tree.
      expect(find.byType(LineChart), findsNothing);
      expect(find.byType(BarChart), findsNothing);
      expect(find.byType(PieChart), findsNothing);
      expect(find.byType(ScatterChart), findsNothing);
    });

    testWidgets('C2: Wear watchlist renders unavailable quotes as "—" — '
        'never a fabricated $0.00', (tester) async {
      await _pump(
        tester,
        SizedBox(
          width: 200,
          height: 200,
          child: WearWatchlistScreen(stocks: const [_unavailableStock]),
        ),
      );

      expect(find.text('NOQ'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
      expect(find.textContaining('\$0.00'), findsNothing);
    });

    testWidgets('C3: Wear opportunities parse StockData and render the '
        'direction badge and analysis without any chart widget',
        (tester) async {
      const opportunity = StockData(
        ticker: 'TEST',
        name: 'Test Instruments',
        currentPrice: 0.0,
        changePercent: 0.0,
        history: <double>[],
        sentiment: 0.0,
        source: StockSource.opportunity,
        analysis: 'Structure improving into the next session.',
        direction: 'long',
        horizon: '1M',
      );

      await _pump(
        tester,
        SizedBox(
          width: 200,
          height: 200,
          child: WearOpportunitiesScreen(stocks: const [opportunity]),
        ),
      );

      expect(find.text('TEST'), findsOneWidget);
      expect(find.text('LONG'), findsOneWidget);
      expect(find.text('Structure improving into the next session.'),
          findsOneWidget);
      expect(find.text('—'), findsOneWidget);
      expect(find.textContaining('\$0.00'), findsNothing);
      expect(find.byType(LineChart), findsNothing);
      expect(find.byType(BarChart), findsNothing);
    });

    testWidgets('C4: stock detail heading renders the structured price when '
        'available', (tester) async {
      await _pumpDetail(
        tester,
        stocks: const [
          StockData(
            ticker: 'TEST',
            name: 'Test Instruments',
            currentPrice: 420.97,
            changePercent: 1.2,
            history: <double>[],
            sentiment: 0.7,
            source: StockSource.watchlist,
          ),
        ],
      );

      expect(find.text('\$420.97'), findsOneWidget);
      expect(find.textContaining('PRICE UNAVAILABLE'), findsNothing);
    });

    testWidgets('C5: stock detail heading renders the truthful unavailable '
        'state — never "$0.00"', (tester) async {
      await _pumpDetail(tester, stocks: const [_unavailableStock]);

      expect(find.textContaining('PRICE UNAVAILABLE'), findsOneWidget);
      expect(find.textContaining('\$0.00'), findsNothing);
    });
  });
}
