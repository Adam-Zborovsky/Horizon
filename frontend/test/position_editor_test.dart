// H12 — widget tests for the position editor and candidate/owned experience.
//
// Contract basis: docs/horizon/CONTRACTS.md §1–§2 and the accepted H11 typed
// domain (frontend/lib/src/features/positions/position_models.dart). These
// tests exercise only the H12 widgets (position_editor.dart,
// position_badge.dart); the repository is faked, never called live.
//
// EXECUTION STATUS: DEFERRED_TO_DEV_PC (no Dart/Flutter SDK on this host, per
// AMENDMENT-2026-10-30). Authored here; must be run on the development PC:
//   flutter test test/position_editor_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:horizon/src/features/positions/position_models.dart';
import 'package:horizon/src/features/positions/position_repository.dart';
import 'package:horizon/src/features/positions/widgets/position_badge.dart';
import 'package:horizon/src/features/positions/widgets/position_editor.dart';
import 'package:horizon/src/core/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Fixtures — backend wire shapes (nested instrument object, UTC timestamps).
// ---------------------------------------------------------------------------

const _instrumentJson = {
  'instrument_id': 'prov-abc-123',
  'symbol': 'MSFT',
  'exchange': 'NASDAQ',
  'currency': 'USD',
  'provider_symbol': 'MSFT',
};

const _instrument = PositionInstrument(
  instrumentId: 'prov-abc-123',
  symbol: 'MSFT',
  exchange: 'NASDAQ',
  currency: 'USD',
  providerSymbol: 'MSFT',
);

Position _position(Map<String, dynamic> overrides) {
  return Position.fromJson({
    'id': 'pos-1',
    'instrument': _instrumentJson,
    'state': 'owned',
    'average_cost': {'amount': '310.50', 'currency': 'USD'},
    'quantity': '10',
    'opened_on': '2026-01-15',
    'preferred_horizon_months': 3,
    'original_thesis': 'Cloud growth thesis.',
    'review_conditions': ['Re-review after next earnings'],
    'risk_context': null,
    'archived': false,
    'revision': 4,
    'created_at': '2026-01-15T09:30:00.000Z',
    'updated_at': '2026-02-01T10:00:00.000Z',
  }..addAll(overrides));
}

Position get _owned => _position({});
Position get _candidate => _position({
      'state': 'candidate',
      'average_cost': null,
      'quantity': null,
      'opened_on': null,
      'original_thesis': null,
      'review_conditions': [],
      'revision': 2,
    });
Position get _legacy => _position({
      'state': 'legacy_unclassified',
      'average_cost': null,
      'quantity': null,
      'opened_on': null,
      'original_thesis': null,
      'review_conditions': [],
      'revision': 7,
    });

class _SaveSpy {
  _SaveSpy({this.error, this.conflictOnFirstCall = false});

  final List<PositionWrite> writes = [];
  final Object? error;
  final bool conflictOnFirstCall;
  int calls = 0;

  Future<Position> call(PositionWrite write) async {
    calls += 1;
    if (calls == 1 && conflictOnFirstCall) {
      throw ApiException(409, code: 'REVISION_CONFLICT',
          message: 'expected_revision 4 does not match current revision 5');
    }
    if (calls == 1 && error != null) {
      throw error!;
    }
    writes.add(write);
    // Echo the write back as the serialized position, mirroring the backend.
    return _owned;
  }
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: SingleChildScrollView(child: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _field(String label) => find.widgetWithText(TextFormField, label);

void main() {
  group('PositionEditor — add candidate (create mode)', () {
    testWidgets('create mode shows no executed-economics inputs',
        (tester) async {
      final spy = _SaveSpy();
      await _pump(
        tester,
        PositionEditor.create(instrument: _instrument, onSave: spy),
      );

      // Candidate creation must not offer cost, quantity or open date:
      // a hypothetical entry can never become a filled purchase here.
      expect(_field('Average cost'), findsNothing);
      expect(_field('Quantity'), findsNothing);
      expect(_field('Opened on'), findsNothing);
      // The explicit state of the record being created is visible.
      expect(find.text('Candidate'), findsWidgets);
    });

    testWidgets('saving a candidate emits state=candidate with no economics',
        (tester) async {
      final spy = _SaveSpy();
      await _pump(
        tester,
        PositionEditor.create(instrument: _instrument, onSave: spy),
      );

      await tester.enterText(
          _field('Original thesis'), 'Watching for a pullback entry.');
      await tester.enterText(_field('Review conditions'),
          'RSI below 40\nEarnings confirmed');
      await tester.tap(find.text('3 mo'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('position-editor-save')));
      await tester.pumpAndSettle();

      expect(spy.writes, hasLength(1));
      final json = spy.writes.single.toJson();
      expect(json['state'], 'candidate');
      expect(json.containsKey('average_cost'), isFalse);
      expect(json.containsKey('quantity'), isFalse);
      expect(json.containsKey('opened_on'), isFalse);
      expect(json['original_thesis'], 'Watching for a pullback entry.');
      expect(json['review_conditions'],
          ['RSI below 40', 'Earnings confirmed']);
      expect(json['preferred_horizon_months'], 3);
      expect(json['instrument'], _instrument.toContractJson());
      expect(json.containsKey('expected_revision'), isFalse);
    });

    testWidgets('candidate editor offers an explicit, confirmed own transition',
        (tester) async {
      final spy = _SaveSpy();
      await _pump(
        tester,
        PositionEditor.create(instrument: _instrument, onSave: spy),
      );

      // The transition is never automatic: an explicit action opens it.
      await tester.tap(find.byKey(const Key('position-editor-transition-owned')));
      await tester.pumpAndSettle();
      // Confirmation dialog states the consequence.
      expect(find.textContaining('own'), findsWidgets);
      await tester.tap(find.byKey(const Key('position-editor-confirm')));
      await tester.pumpAndSettle();

      // Now the economics inputs exist, prefilled empty (unknown allowed),
      // and currency is fixed to US Dollars rather than an open text field.
      expect(_field('Average cost'), findsOneWidget);
      expect(_field('Currency'), findsNothing);
      expect(find.textContaining('US Dollars'), findsOneWidget);
      expect(spy.writes, isEmpty);
    });
  });

  group('PositionEditor — classify legacy', () {
    testWidgets('legacy record requires an explicit classification',
        (tester) async {
      final spy = _SaveSpy();
      await _pump(tester, PositionEditor.edit(initial: _legacy, onSave: spy));

      expect(find.byKey(const Key('position-editor-classify-candidate')),
          findsOneWidget);
      expect(find.byKey(const Key('position-editor-classify-owned')),
          findsOneWidget);
      // No economics inputs until a state is chosen.
      expect(_field('Average cost'), findsNothing);
    });

    testWidgets('classify as candidate emits candidate with no economics',
        (tester) async {
      final spy = _SaveSpy();
      await _pump(tester, PositionEditor.edit(initial: _legacy, onSave: spy));

      await tester.tap(find.byKey(const Key('position-editor-classify-candidate')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('position-editor-save')));
      await tester.pumpAndSettle();

      expect(spy.writes, hasLength(1));
      final json = spy.writes.single.toJson();
      expect(json['state'], 'candidate');
      expect(json.containsKey('average_cost'), isFalse);
      expect(json['instrument']['instrument_id'], 'prov-abc-123');
    });

    testWidgets('classify as owned with unknown economics stays honest',
        (tester) async {
      final spy = _SaveSpy();
      await _pump(tester, PositionEditor.edit(initial: _legacy, onSave: spy));

      await tester.tap(find.byKey(const Key('position-editor-classify-owned')));
      await tester.pumpAndSettle();
      // Leave cost/quantity empty: unknown is allowed, never invented.
      expect(find.textContaining('Unknown'), findsWidgets);
      await tester.tap(find.byKey(const Key('position-editor-save')));
      await tester.pumpAndSettle();

      expect(spy.writes, hasLength(1));
      final json = spy.writes.single.toJson();
      expect(json['state'], 'owned');
      expect(json.containsKey('average_cost'), isFalse);
      expect(json.containsKey('quantity'), isFalse);
    });

    testWidgets('classify as owned validates economics visibly',
        (tester) async {
      final spy = _SaveSpy();
      await _pump(tester, PositionEditor.edit(initial: _legacy, onSave: spy));

      await tester.tap(find.byKey(const Key('position-editor-classify-owned')));
      await tester.pumpAndSettle();
      await tester.enterText(_field('Average cost'), '0');
      await tester.tap(find.byKey(const Key('position-editor-save')));
      await tester.pumpAndSettle();

      // Nothing was saved; the problems are visible text, not silent repair.
      expect(spy.writes, isEmpty);
      expect(find.textContaining('positive'), findsWidgets);
    });

    testWidgets('classify as owned with valid economics emits them',
        (tester) async {
      final spy = _SaveSpy();
      await _pump(tester, PositionEditor.edit(initial: _legacy, onSave: spy));

      await tester.tap(find.byKey(const Key('position-editor-classify-owned')));
      await tester.pumpAndSettle();
      await tester.enterText(_field('Average cost'), '287.25');
      await tester.enterText(_field('Quantity'), '12.5');
      await tester.enterText(_field('Opened on'), '2026-03-02');
      await tester.tap(find.byKey(const Key('position-editor-save')));
      await tester.pumpAndSettle();

      final json = spy.writes.single.toJson();
      expect(json['state'], 'owned');
      expect(json['average_cost'], {'amount': '287.25', 'currency': 'USD'});
      expect(json['quantity'], '12.5');
      expect(json['opened_on'], '2026-03-02');
    });
  });

  group('PositionEditor — edit owned', () {
    testWidgets('edits carry expected_revision from the loaded position',
        (tester) async {
      final spy = _SaveSpy();
      await _pump(tester, PositionEditor.edit(initial: _owned, onSave: spy));

      expect(_field('Average cost'), findsOneWidget);
      await tester.enterText(_field('Average cost'), '305');
      await tester.enterText(_field('Quantity'), '15');
      await tester.tap(find.text('1 mo'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('position-editor-save')));
      await tester.pumpAndSettle();

      final write = spy.writes.single;
      expect(write.expectedRevision, 4);
      final json = write.toJson();
      expect(json['average_cost'], {'amount': '305', 'currency': 'USD'});
      expect(json['quantity'], '15');
      expect(json['preferred_horizon_months'], 1);
      expect(json['state'], 'owned');
    });

    testWidgets('invalid decimal input is rejected with a visible message',
        (tester) async {
      final spy = _SaveSpy();
      await _pump(tester, PositionEditor.edit(initial: _owned, onSave: spy));

      await tester.enterText(_field('Average cost'), '-5');
      await tester.enterText(_field('Quantity'), 'abc');
      await tester.tap(find.byKey(const Key('position-editor-save')));
      await tester.pumpAndSettle();

      expect(spy.writes, isEmpty);
      expect(find.textContaining('positive decimal'), findsWidgets);
    });

    testWidgets('currency mismatch with the instrument is visible',
        (tester) async {
      final spy = _SaveSpy();
      final ilsOwned = _position({
        'instrument': {
          'instrument_id': 'prov-abc-123',
          'symbol': 'MSFT',
          'exchange': 'TASE',
          'currency': 'ILS',
          'provider_symbol': 'MSFT',
        },
      });
      await _pump(tester, PositionEditor.edit(initial: ilsOwned, onSave: spy));

      await tester.enterText(_field('Average cost'), '1000');
      await tester.pumpAndSettle();

      expect(
          find.textContaining(
              'differs from the instrument currency'),
          findsOneWidget);
    });

    testWidgets('closing to candidate requires confirmation and clears '
        'economics from the write', (tester) async {
      final spy = _SaveSpy();
      await _pump(tester, PositionEditor.edit(initial: _owned, onSave: spy));

      await tester.tap(find.byKey(const Key('position-editor-transition-candidate')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('position-editor-confirm')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('position-editor-save')));
      await tester.pumpAndSettle();

      final json = spy.writes.single.toJson();
      expect(json['state'], 'candidate');
      // The cleared economics are explicitly null in the changes payload:
      // the backend clears them on owned -> candidate.
      expect(json['average_cost'], isNull);
      expect(json['quantity'], isNull);
      expect(json['opened_on'], isNull);
    });

    testWidgets('archive requires confirmation and emits archived: true',
        (tester) async {
      final spy = _SaveSpy();
      await _pump(tester, PositionEditor.edit(initial: _owned, onSave: spy));

      await tester.tap(find.byKey(const Key('position-editor-archive')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('position-editor-confirm')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('position-editor-save')));
      await tester.pumpAndSettle();

      final json = spy.writes.single.toJson();
      expect(json['archived'], true);
      expect(json['state'], 'owned');
    });

    testWidgets('touch targets meet the 48dp minimum',
        (tester) async {
      final spy = _SaveSpy();
      await _pump(tester, PositionEditor.edit(initial: _owned, onSave: spy));

      for (final key in const [
        Key('position-editor-save'),
        Key('position-editor-archive'),
        Key('position-editor-transition-candidate'),
      ]) {
        final size = tester.getSize(find.byKey(key));
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      }
    });
  });

  group('PositionEditor — error, retry and revision conflict', () {
    testWidgets('API error shows a message and Retry resubmits',
        (tester) async {
      final spy = _SaveSpy(
          error: ApiException(500, code: 'INTERNAL', message: 'boom'));
      await _pump(tester, PositionEditor.edit(initial: _owned, onSave: spy));

      await tester.enterText(_field('Average cost'), '305');
      await tester.tap(find.byKey(const Key('position-editor-save')));
      await tester.pumpAndSettle();

      expect(find.textContaining('boom'), findsOneWidget);
      expect(find.byKey(const Key('position-editor-retry')), findsOneWidget);

      await tester.tap(find.byKey(const Key('position-editor-retry')));
      await tester.pumpAndSettle();
      expect(spy.writes, hasLength(1));
    });

    testWidgets('revision conflict is shown distinctly with reload guidance',
        (tester) async {
      final spy = _SaveSpy(conflictOnFirstCall: true);
      await _pump(tester, PositionEditor.edit(initial: _owned, onSave: spy));

      await tester.enterText(_field('Average cost'), '305');
      await tester.tap(find.byKey(const Key('position-editor-save')));
      await tester.pumpAndSettle();

      expect(find.textContaining('changed elsewhere'), findsWidgets);
      expect(find.byKey(const Key('position-editor-reload')), findsOneWidget);
      expect(spy.writes, isEmpty);

      // Retry resubmits the same edit; the harness succeeds on the second
      // call, exercising the retry path with the original expected_revision.
      await tester.tap(find.byKey(const Key('position-editor-retry')));
      await tester.pumpAndSettle();
      expect(spy.writes, hasLength(1));
      expect(spy.writes.single.expectedRevision, 4);
    });
  });

  group('PositionEditor — text scaling', () {
    testWidgets('layout survives 2.0 text scaling without exceptions',
        (tester) async {
      final spy = _SaveSpy();
      await _pump(
        tester,
        PositionEditor.edit(initial: _owned, onSave: spy),
        textScale: 2.0,
      );

      expect(tester.takeException(), isNull);
      expect(_field('Average cost'), findsOneWidget);
      expect(find.byKey(const Key('position-editor-save')), findsOneWidget);
    });

    testWidgets('classification choice survives 2.0 text scaling',
        (tester) async {
      final spy = _SaveSpy();
      await _pump(
        tester,
        PositionEditor.edit(initial: _legacy, onSave: spy),
        textScale: 2.0,
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('position-editor-classify-candidate')),
          findsOneWidget);
    });
  });

  group('PositionStateBadge', () {
    testWidgets('exposes state and archive status to semantics',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(
        tester,
        Column(children: [
          PositionStateBadge(state: PositionState.owned),
          PositionStateBadge(
              state: PositionState.candidate, archived: true),
        ]),
      );

      expect(find.text('Owned'), findsOneWidget);
      expect(find.text('Candidate'), findsOneWidget);
      expect(find.text('Archived'), findsOneWidget);

      expect(find.bySemanticsLabel('Owned position'), findsOneWidget);
      expect(
          find.bySemanticsLabel(
              'Candidate position: a watchlist idea, no executed purchase, '
              'archived'),
          findsOneWidget);
      semantics.dispose();
    });

    testWidgets('unknown economics are labeled, never invented',
        (tester) async {
      final unknownCost = _position({
        'average_cost': null,
        'quantity': null,
      });
      await _pump(tester, PositionEconomicsLine(position: unknownCost));

      expect(find.textContaining('Cost unknown'), findsOneWidget);
      expect(find.textContaining('10'), findsNothing);
    });

    testWidgets('known economics render the stored values',
        (tester) async {
      await _pump(tester, PositionEconomicsLine(position: _owned));

      expect(find.textContaining('310.50'), findsOneWidget);
      expect(find.textContaining('USD'), findsOneWidget);
    });
  });
}
