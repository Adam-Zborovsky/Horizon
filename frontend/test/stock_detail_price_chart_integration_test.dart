// PriceChart integration: recorded observed bars through the authenticated
// MarketRepository. The four bars are exact values from
// backend/test/fixtures/research/observed-bars.json (Yahoo Finance recording,
// sha256 dcf75e1922753be1fc0ced05f47892c6dfbc48b4c52fe5bd2c2e0d9e83923caf).
// They are an offline fixture, not a current quote or a projection.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:horizon/src/features/market/market_repository.dart';
import 'package:horizon/src/features/positions/position_repository.dart';
import 'package:horizon/src/features/stock/stock_detail_screen.dart';
import 'package:horizon/src/features/stock/stock_repository.dart';

const _token = 'detail-chart-test-token';
const _instrumentId = 'instrument-ibm-xnys-usd';

class _Stocks extends StockRepository {
  @override
  Future<List<StockData>> build() async => const [
        StockData(
          ticker: 'IBM',
          name: 'International Business Machines',
          currentPrice: 0,
          changePercent: 0,
          history: [],
          sentiment: 0,
          source: StockSource.watchlist,
        ),
      ];
}

Map<String, dynamic> _position() => {
      'id': 'position-ibm',
      'instrument': {
        'instrument_id': _instrumentId,
        'symbol': 'IBM',
        'exchange': 'XNYS',
        'currency': 'USD',
        'provider_symbol': 'IBM',
      },
      'state': 'owned',
      'average_cost': null,
      'quantity': null,
      'opened_on': null,
      'preferred_horizon_months': 3,
      'original_thesis': null,
      'review_conditions': <String>[],
      'risk_context': null,
      'archived': false,
      'revision': 1,
      'created_at': '2024-01-01T00:00:00.000Z',
      'updated_at': '2024-01-01T00:00:00.000Z',
    };

const _bars = [
  {
    'time': '2024-01-02T14:30:00.000Z',
    'session_date': '2024-01-02',
    'open': 162.8300018310547,
    'high': 163.2899932861328,
    'low': 160.4600067138672,
    'close': 161.5,
    'volume': 3825000,
    'adjusted_close': null,
    'is_final': true,
  },
  {
    'time': '2024-01-03T14:30:00.000Z',
    'session_date': '2024-01-03',
    'open': 161,
    'high': 161.72999572753906,
    'low': 160.0800018310547,
    'close': 160.10000610351562,
    'volume': 4086100,
    'adjusted_close': null,
    'is_final': true,
  },
  {
    'time': '2024-01-04T14:30:00.000Z',
    'session_date': '2024-01-04',
    'open': 160.22000122070312,
    'high': 161.80999755859375,
    'low': 160.1699981689453,
    'close': 160.86000061035156,
    'volume': 3212000,
    'adjusted_close': null,
    'is_final': true,
  },
  {
    'time': '2024-01-05T14:30:00.000Z',
    'session_date': '2024-01-05',
    'open': 159.91000366210938,
    'high': 160.5500030517578,
    'low': 158.6699981689453,
    'close': 159.16000366210938,
    'volume': 4199400,
    'adjusted_close': null,
    'is_final': true,
  },
];

Map<String, dynamic> _history() => {
      'contract_version': 1,
      'instrument': {
        'instrument_id': _instrumentId,
        'symbol': 'IBM',
        'exchange': 'XNYS',
        'currency': 'USD',
        'provider_symbol': 'IBM',
      },
      'snapshot_id': null,
      'range': '1M',
      'requested_resolution': '1d',
      'actual_resolution': '1d',
      'exchange_timezone': 'America/New_York',
      'session_mode': 'regular',
      'adjustment_basis':
          'raw provider OHLCV; adjusted close intentionally omitted',
      'as_of': '2024-01-05T21:00:00.000Z',
      'fetched_at': '2024-01-05T21:05:00.000Z',
      'data_status': 'available',
      'delay_status': 'unknown',
      'is_stale': false,
      'available_ranges': ['1D', '1W', '1M', '3M', '6M', '1Y'],
      'bars': _bars,
      'warnings': <Object>[],
      'next_cursor': null,
      'unavailable_reason': null,
    };

void main() {
  testWidgets('resolves identity then renders recorded bars from authenticated history',
      (tester) async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      if (request.method == 'GET' && request.url.path.endsWith('/positions')) {
        return http.Response(jsonEncode({'positions': [_position()]}), 200);
      }
      if (request.method == 'GET' &&
          request.url.path.endsWith('/market/instruments/$_instrumentId/history')) {
        return http.Response(jsonEncode(_history()), 200);
      }
      if (request.method == 'GET' &&
          request.url.path.endsWith('/research/positions/position-ibm/latest')) {
        return http.Response(jsonEncode({
          'position_id': 'position-ibm',
          'latest_assessment': null,
          'run_state': {'last_success': null, 'latest_attempt': null},
        }), 200);
      }
      return http.Response(jsonEncode({'error': {'code': 'NOT_FOUND'}}), 404);
    });

    await tester.pumpWidget(MaterialApp(
      home: ProviderScope(
        overrides: [
          stockRepositoryProvider.overrideWith(_Stocks.new),
          positionRepositoryProvider.overrideWith(
            (ref) => PositionRepository(
              client: client,
              tokenProvider: () async => _token,
            ),
          ),
          marketRepositoryProvider.overrideWith(
            (ref) => MarketRepository(
              client: client,
              tokenProvider: () async => _token,
            ),
          ),
          researchWireProvider.overrideWithValue(
            ResearchWire(
              client: client,
              tokenProvider: () async => _token,
            ),
          ),
        ],
        child: const Scaffold(body: StockDetailScreen(ticker: 'IBM')),
      ),
    ));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chart_line')), findsOneWidget);
    expect(find.text('2024-01-05T14:30:00.000Z'), findsOneWidget);
    expect(find.text(r'$159.16'), findsOneWidget);
    final marketRequests = requests.where((request) =>
        request.url.path.endsWith('/market/instruments/$_instrumentId/history'));
    expect(marketRequests, hasLength(1));
    final request = marketRequests.single;
    expect(request.url.queryParameters['range'], '1M');
    expect(request.headers['authorization'], 'Bearer $_token');
  });
}
