// H12 — position editor: add candidate, classify legacy, edit owned,
// archive, and explicit state transitions.
//
// Contract basis: docs/horizon/CONTRACTS.md §1–§2 (position lifecycle rules)
// and the accepted H11 typed domain. The editor never calls the network
// itself: saves flow through an injected `onSave(PositionWrite)` callback so
// H15 wires the H11 `PositionRepository`. Client-side validation mirrors the
// backend rules (positive bounded decimal strings, ISO 4217 currency codes,
// real calendar dates, horizons 1/2/3) and all failures are visible text —
// nothing is silently repaired or defaulted.
//
// Lifecycle invariants enforced here (CONTRACTS §2):
// - A candidate never carries executed economics: create mode offers no
//   cost/quantity/open-date inputs, so a hypothetical entry can never become
//   a filled purchase and no portfolio sizing is faked.
// - candidate -> owned and legacy classification are explicit, confirmed user
//   actions; owned economics may stay unknown ("Unknown" is stated, never
//   invented).
// - owned -> candidate (closing) is confirmed and the changes payload drops
//   the economics; the backend clears them and keeps the revision history.
// - Every PATCH carries `expected_revision` from the loaded position;
//   REVISION_CONFLICT surfaces as a distinct, actionable state.
//
// Flutter checks (analyze/test/a11y audit) are DEFERRED_TO_DEV_PC per
// AMENDMENT-2026-10-30; widget tests live in test/position_editor_test.dart.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../position_models.dart';
import '../position_repository.dart';
import 'position_badge.dart';

const _maxThesisLength = 4000; // frontend parse limit (see position_models.dart)
const _maxConditions = 20;
const _maxConditionLength = 500;

final RegExp _isoCurrencyRe = RegExp(r'^[A-Z]{3}$');

const _buttonMinSize = Size(64, 48); // ≥ 48dp touch targets

const _goldAmber = Color(0xFFFFB800);
const _obsidian = Color(0xFF0C0C0C);
const _charcoalBlack = Color(0xFF161618);
const _softCrimson = Color(0xFFFF4B5C);

/// Async persistence delegate. Implementations should map transport failures
/// to the H11 [ApiException] (409 REVISION_CONFLICT is handled distinctly).
typedef PositionSaveCallback = Future<Position> Function(PositionWrite write);

/// Called after a successful save with the server-serialized position.
typedef PositionSavedCallback = void Function(Position saved);

/// Called when the user asks to reload after a revision conflict.
typedef PositionConflictCallback = void Function();

/// Position lifecycle editor. Use [PositionEditor.create] to add a candidate
/// for a resolved instrument identity, or [PositionEditor.edit] to classify,
/// update or archive an existing position.
///
/// The widget is embeddable (sheet, dialog, page section) and does not own
/// scrolling; the host provides it (e.g. inside a scroll view or bottom
/// sheet).
class PositionEditor extends StatefulWidget {
  const PositionEditor._({
    super.key,
    required this.onSave,
    this.onSaved,
    this.onConflict,
    this.initial,
    this.instrument,
    this.padding = const EdgeInsets.fromLTRB(24, 20, 24, 28),
  }) : assert(
          (initial == null) != (instrument == null),
          'Provide either initial (edit mode) or instrument (create mode).',
        );

  /// Create mode: add a candidate for an already-resolved instrument
  /// identity (CONTRACTS §1 — identity comes from a vetted provider
  /// resolution, never free-text invented here).
  const PositionEditor.create({
    Key? key,
    required PositionInstrument instrument,
    required PositionSaveCallback onSave,
    PositionSavedCallback? onSaved,
    PositionConflictCallback? onConflict,
    EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(24, 20, 24, 28),
  }) : this._(
          key: key,
          instrument: instrument,
          onSave: onSave,
          onSaved: onSaved,
          onConflict: onConflict,
          padding: padding,
        );

  /// Edit mode: classify a legacy record, edit an owned position, or archive.
  const PositionEditor.edit({
    Key? key,
    required Position initial,
    required PositionSaveCallback onSave,
    PositionSavedCallback? onSaved,
    PositionConflictCallback? onConflict,
    EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(24, 20, 24, 28),
  }) : this._(
          key: key,
          initial: initial,
          onSave: onSave,
          onSaved: onSaved,
          onConflict: onConflict,
          padding: padding,
        );

  final Position? initial;
  final PositionInstrument? instrument;
  final PositionSaveCallback onSave;
  final PositionSavedCallback? onSaved;
  final PositionConflictCallback? onConflict;
  final EdgeInsetsGeometry padding;

  @override
  State<PositionEditor> createState() => _PositionEditorState();
}

class _PositionEditorState extends State<PositionEditor> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _amountController;
  late final TextEditingController _currencyController;
  late final TextEditingController _quantityController;
  late final TextEditingController _openedOnController;
  late final TextEditingController _thesisController;
  late final TextEditingController _conditionsController;

  late int _horizon;

  /// The lifecycle state the next save will produce. Null in edit mode until
  /// the user classifies a legacy record.
  PositionState? _targetState;

  bool _archived = false;
  bool _economicsCleared = false;
  bool _submitting = false;
  ApiException? _apiError;
  PositionWrite? _pendingWrite;

  bool get _isCreate => widget.initial == null;
  PositionInstrument get _instrument =>
      widget.initial?.instrument ?? widget.instrument!;
  bool get _showEconomics => _targetState == PositionState.owned;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _targetState = initial == null
        ? PositionState.candidate
        : (initial.state == PositionState.legacyUnclassified
            ? null
            : initial.state);
    _horizon = initial?.preferredHorizonMonths ?? 3;
    _archived = initial?.archived ?? false;
    _amountController =
        TextEditingController(text: initial?.averageCost?.amount ?? '');
    _currencyController =
        TextEditingController(text: initial?.averageCost?.currency ?? '');
    _quantityController =
        TextEditingController(text: initial?.quantity ?? '');
    _openedOnController = TextEditingController(text: initial?.openedOn ?? '');
    _thesisController =
        TextEditingController(text: initial?.originalThesis ?? '');
    _conditionsController = TextEditingController(
        text: (initial?.reviewConditions ?? []).join('\n'));
    // The currency-mismatch banner is derived from live controller text, so
    // controller edits must rebuild this widget.
    for (final controller in [_amountController, _currencyController]) {
      controller.addListener(_onEconomicsTextChanged);
    }
  }

  void _onEconomicsTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _amountController.dispose();
    _currencyController.dispose();
    _quantityController.dispose();
    _openedOnController.dispose();
    _thesisController.dispose();
    _conditionsController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Save flow
  // ---------------------------------------------------------------------------

  PositionWrite _buildWrite() {
    final initial = widget.initial;
    if (initial == null) {
      return PositionWrite(
        instrument: _instrument,
        state: _targetState ?? PositionState.candidate,
        preferredHorizonMonths: _horizon,
        originalThesis: _textOrNull(_thesisController),
        reviewConditions: _conditionLines(),
        averageCost: _moneyOrNull(),
        quantity: _decimalOrNull(_quantityController),
        openedOn: _dateOrNull(),
      );
    }

    final targetState = _targetState ?? initial.state;
    final clearEconomics =
        _economicsCleared || targetState == PositionState.candidate;
    return PositionWrite(
      instrument: initial.instrument,
      state: targetState,
      expectedRevision: initial.revision,
      averageCost: clearEconomics ? null : _moneyOrNull(),
      quantity: clearEconomics ? null : _decimalOrNull(_quantityController),
      openedOn: clearEconomics ? null : _dateOrNull(),
      preferredHorizonMonths: _horizon,
      originalThesis: _textOrNull(_thesisController),
      reviewConditions: _conditionLines(),
      archived: _archived == initial.archived ? null : _archived,
    );
  }

  String? _textOrNull(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  String? _decimalOrNull(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  MoneyAmount? _moneyOrNull() {
    final amount = _amountController.text.trim();
    final currency = _currencyController.text.trim();
    if (amount.isEmpty || currency.isEmpty) return null;
    return MoneyAmount(amount: amount, currency: currency);
  }

  String? _dateOrNull() {
    final text = _openedOnController.text.trim();
    return text.isEmpty ? null : text;
  }

  List<String>? _conditionLines() {
    final lines = _conditionsController.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    return lines.isEmpty ? null : lines;
  }

  Future<void> _save() async {
    if (_submitting) return;
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;
    if (_targetState == null) return; // legacy record not yet classified
    final write = _buildWrite();
    setState(() {
      _pendingWrite = write;
      _apiError = null;
      _submitting = true;
    });
    await _submit(write);
  }

  Future<void> _submit(PositionWrite write) async {
    setState(() => _submitting = true);
    try {
      final saved = await widget.onSave(write);
      widget.onSaved?.call(saved);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _apiError = error;
        _submitting = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _apiError = ApiException(
          0,
          code: 'REQUEST_FAILED',
          message: error.toString(),
        );
        _submitting = false;
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _retry() async {
    final write = _pendingWrite;
    if (write == null) return;
    await _submit(write);
  }

  // ---------------------------------------------------------------------------
  // Transitions and archive
  // ---------------------------------------------------------------------------

  Future<bool> _confirm(String title, String body) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _charcoalBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text(
          body,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(foregroundColor: Colors.white60),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('position-editor-confirm'),
            style: FilledButton.styleFrom(
              backgroundColor: _goldAmber,
              foregroundColor: _obsidian,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Confirm',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _transitionToOwned() async {
    final confirmed = await _confirm(
      'Do you own this instrument?',
      'This records the position as owned. You can enter your average cost, '
      'quantity and open date now or leave them unknown — they are never '
      'invented. A candidate idea is not converted automatically.',
    );
    if (!confirmed) return;
    setState(() {
      _targetState = PositionState.owned;
      _economicsCleared = false;
    });
  }

  void _classify(PositionState state) {
    setState(() {
      _targetState = state;
      _economicsCleared = false;
    });
  }

  Future<void> _transitionToCandidate() async {
    final confirmed = await _confirm(
      'Close this position?',
      'This moves the record back to candidate and clears its average cost, '
      'quantity and open date. The change is recorded as a new revision; no '
      'history is deleted. Lot-level realized tax accounting is out of scope.',
    );
    if (!confirmed) return;
    setState(() {
      _targetState = PositionState.candidate;
      _economicsCleared = true;
    });
  }

  Future<void> _archive() async {
    final confirmed = await _confirm(
      'Archive this position?',
      'Archiving removes the position from active coverage. It is reversible '
      'and keeps the full history; nothing is deleted.',
    );
    if (!confirmed) return;
    setState(() => _archived = true);
  }

  // ---------------------------------------------------------------------------
  // Validation (visible text, mirrors backend rules)
  // ---------------------------------------------------------------------------

  String? _validateAmount(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      // Unknown is allowed for owned records; nothing is invented.
      return null;
    }
    if (!isValidPositiveDecimal(text)) {
      return 'Enter a positive decimal amount (e.g. 310.50).';
    }
    return null;
  }

  String? _validateCurrency(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      if (_amountController.text.trim().isNotEmpty) {
        return 'Required when a cost is entered.';
      }
      return null;
    }
    if (!_isoCurrencyRe.hasMatch(text)) {
      return 'Enter a 3-letter ISO 4217 currency code (e.g. USD).';
    }
    return null;
  }

  String? _validateQuantity(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (!isValidPositiveDecimal(text)) {
      return 'Enter a positive decimal quantity (fractional shares allowed).';
    }
    return null;
  }

  String? _validateOpenedOn(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (!isValidSessionDate(text)) {
      return 'Enter a real calendar date (YYYY-MM-DD).';
    }
    return null;
  }

  String? _validateConditions(String? value) {
    final lines = _conditionLines() ?? const <String>[];
    if (lines.length > _maxConditions) {
      return 'Use at most $_maxConditions conditions.';
    }
    if (lines.any((line) => line.length > _maxConditionLength)) {
      return 'Each condition is limited to $_maxConditionLength characters.';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Build & Styling
  // ---------------------------------------------------------------------------

  bool get _currencyMismatch {
    final instrumentCurrency = _instrument.currency;
    final costCurrency = _currencyController.text.trim();
    if (!_showEconomics) return false;
    if (instrumentCurrency == null || costCurrency.isEmpty) return false;
    if (!_isoCurrencyRe.hasMatch(costCurrency)) return false;
    return costCurrency != instrumentCurrency;
  }

  InputDecoration _inputDecoration({
    required String labelText,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      alignLabelWithHint: true,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.04),
      labelStyle: const TextStyle(color: Colors.white60, fontSize: 13),
      floatingLabelStyle: const TextStyle(
        color: _goldAmber,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: TextStyle(
        color: Colors.white.withValues(alpha: 0.25),
        fontSize: 13,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _goldAmber, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _softCrimson, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _softCrimson, width: 1.5),
      ),
      errorMaxLines: 2,
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _charcoalBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLegacyRecord =
        !_isCreate && widget.initial?.state == PositionState.legacyUnclassified;

    return Padding(
      padding: widget.padding,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            if (_isCreate) ...[
              _buildCreateStateSection(context),
              const SizedBox(height: 14),
            ],
            if (isLegacyRecord) ...[
              _buildClassifySection(context),
              const SizedBox(height: 14),
            ],
            if (_showEconomics) ...[
              _buildEconomicsSection(context),
              const SizedBox(height: 14),
            ],
            _buildDetailsSection(context),
            if (!_isCreate) ...[
              const SizedBox(height: 14),
              _buildDangerSection(context),
            ],
            const SizedBox(height: 20),
            if (_apiError != null)
              _buildErrorPanel(theme)
            else ...[
              FilledButton(
                key: const Key('position-editor-save'),
                style: FilledButton.styleFrom(
                  minimumSize: _buttonMinSize,
                  backgroundColor: _goldAmber,
                  foregroundColor: _obsidian,
                  disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
                  disabledForegroundColor: Colors.white38,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 0.3,
                  ),
                ),
                onPressed: _targetState == null || _submitting ? null : _save,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _obsidian,
                        ),
                      )
                    : const Text('Save position'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final route = ModalRoute.of(context);
    final showClose = route is PopupRoute && (Navigator.maybeOf(context)?.canPop() ?? false);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_instrument.symbol}'
                '${_instrument.exchange == null ? '' : ' · ${_instrument.exchange}'}'
                '${_instrument.currency == null ? '' : ' · ${_instrument.currency}'}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 8),
              PositionStateBadge(
                state: _targetState ?? PositionState.legacyUnclassified,
                archived: _archived,
              ),
            ],
          ),
        ),
        if (showClose)
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              foregroundColor: Colors.white70,
            ),
            icon: const Icon(Icons.close_rounded, size: 20),
            tooltip: 'Close',
          ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String text) {
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
        ),
      ),
    );
  }

  Widget _buildCreateStateSection(BuildContext context) {
    final isOwned = _targetState == PositionState.owned;
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, 'New candidate'),
          Text(
            'A candidate is a watchlist idea. No cost, quantity or open date is '
            'recorded here — marking it as owned later is a separate, explicit '
            'step.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white60,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('position-editor-transition-owned'),
            style: OutlinedButton.styleFrom(
              minimumSize: _buttonMinSize,
              foregroundColor: isOwned ? Colors.white38 : _goldAmber,
              side: BorderSide(
                color: isOwned
                    ? Colors.white.withValues(alpha: 0.1)
                    : _goldAmber.withValues(alpha: 0.45),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: isOwned ? null : _transitionToOwned,
            icon: const Icon(Icons.shopping_bag_outlined, size: 18),
            label: const Text('I now own this…'),
          ),
        ],
      ),
    );
  }

  Widget _buildClassifySection(BuildContext context) {
    final isCandidateSelected = _targetState == PositionState.candidate;
    final isOwnedSelected = _targetState == PositionState.owned;

    ButtonStyle classifyButtonStyle(bool selected) {
      return OutlinedButton.styleFrom(
        minimumSize: _buttonMinSize,
        backgroundColor: selected
            ? _goldAmber.withValues(alpha: 0.16)
            : Colors.white.withValues(alpha: 0.03),
        foregroundColor: selected ? _goldAmber : Colors.white,
        side: BorderSide(
          color: selected
              ? _goldAmber
              : _goldAmber.withValues(alpha: 0.35),
          width: selected ? 1.5 : 1.0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      );
    }

    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, 'Classify this legacy ticker'),
          Text(
            'This record was imported without economics. Nothing about cost or '
            'ownership is inferred from it — choose what it actually is.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white60,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('position-editor-classify-candidate'),
                  style: classifyButtonStyle(isCandidateSelected),
                  onPressed: () => _classify(PositionState.candidate),
                  child: const Text('Track as candidate'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  key: const Key('position-editor-classify-owned'),
                  style: classifyButtonStyle(isOwnedSelected),
                  onPressed: () => _classify(PositionState.owned),
                  child: const Text('I own this'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEconomicsSection(BuildContext context) {
    final mismatch = _currencyMismatch;
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, 'Executed economics'),
          Text(
            'Unknown is OK. Leave a field empty if you do not know it — it is '
            'never guessed, and research continues without it. Candidate ideas '
            'never carry these values.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white60,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _amountController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(
                    labelText: 'Average cost',
                    hintText: 'e.g. 310.50',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  // No rewriting input formatter: what the user typed is what
                  // gets validated. Invalid input must surface as a visible
                  // error, never be silently stripped into a valid value.
                  validator: _validateAmount,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _currencyController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(
                    labelText: 'Currency',
                    hintText: 'USD',
                  ),
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                    LengthLimitingTextInputFormatter(3),
                  ],
                  validator: _validateCurrency,
                ),
              ),
            ],
          ),
          if (mismatch)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _mismatchBanner(context),
            ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _quantityController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(
                    labelText: 'Quantity',
                    hintText: 'e.g. 12.5',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  // Same rule as the cost field: no silent input rewriting.
                  validator: _validateQuantity,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _openedOnController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(
                    labelText: 'Opened on',
                    hintText: 'YYYY-MM-DD',
                  ),
                  keyboardType: TextInputType.datetime,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: _validateOpenedOn,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mismatchBanner(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.5)),
      ),
      child: Text(
        'Cost currency ${_currencyController.text.trim()} differs from the '
        'instrument currency (${_instrument.currency}). Comparable '
        'profit/loss is unavailable until a sourced FX conversion is '
        'implemented — nothing is converted silently.',
        style: theme.textTheme.bodySmall,
      ),
    );
  }

  Widget _buildDetailsSection(BuildContext context) {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, 'Details'),
          const SizedBox(height: 4),
          TextFormField(
            controller: _thesisController,
            style: const TextStyle(color: Colors.white, height: 1.4),
            decoration: _inputDecoration(
              labelText: 'Original thesis',
              hintText: 'Why this instrument? (optional)',
            ),
            maxLines: 3,
            maxLength: _maxThesisLength,
            buildCounter: (_,
                    {required currentLength,
                    required maxLength,
                    required isFocused}) =>
                null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _conditionsController,
            style: const TextStyle(color: Colors.white, height: 1.4),
            decoration: _inputDecoration(
              labelText: 'Review conditions',
              hintText: 'One condition per line (optional)',
            ),
            maxLines: 3,
            validator: _validateConditions,
          ),
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Text(
              'Review horizon',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              style: SegmentedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.03),
                foregroundColor: Colors.white70,
                selectedBackgroundColor: _goldAmber.withValues(alpha: 0.18),
                selectedForegroundColor: _goldAmber,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              segments: const [
                ButtonSegment(value: 1, label: Text('1 mo')),
                ButtonSegment(value: 2, label: Text('2 mo')),
                ButtonSegment(value: 3, label: Text('3 mo')),
              ],
              selected: {_horizon},
              onSelectionChanged: (selection) =>
                  setState(() => _horizon = selection.first),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerSection(BuildContext context) {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, 'Lifecycle'),
          if (widget.initial?.state == PositionState.candidate &&
              _targetState == PositionState.candidate) ...[
            OutlinedButton.icon(
              key: const Key('position-editor-transition-owned'),
              style: OutlinedButton.styleFrom(
                minimumSize: _buttonMinSize,
                foregroundColor: _goldAmber,
                side: BorderSide(color: _goldAmber.withValues(alpha: 0.45)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _submitting ? null : _transitionToOwned,
              icon: const Icon(Icons.shopping_bag_outlined, size: 18),
              label: const Text('I now own this…'),
            ),
            const SizedBox(height: 10),
          ],
          if (widget.initial?.state == PositionState.owned &&
              _targetState == PositionState.owned) ...[
            OutlinedButton.icon(
              key: const Key('position-editor-transition-candidate'),
              style: OutlinedButton.styleFrom(
                minimumSize: _buttonMinSize,
                foregroundColor: Colors.white70,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _submitting ? null : _transitionToCandidate,
              icon: const Icon(Icons.undo, size: 18),
              label: const Text('No longer owned…'),
            ),
            const SizedBox(height: 10),
          ],
          OutlinedButton.icon(
            key: const Key('position-editor-archive'),
            style: OutlinedButton.styleFrom(
              minimumSize: _buttonMinSize,
              foregroundColor: _archived ? Colors.white38 : _goldAmber,
              side: BorderSide(
                color: _archived
                    ? Colors.white.withValues(alpha: 0.1)
                    : _goldAmber.withValues(alpha: 0.35),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _archived || _submitting ? null : _archive,
            icon: const Icon(Icons.archive_outlined, size: 18),
            label: const Text(_archivedText),
          ),
        ],
      ),
    );
  }

  static const _archivedText = 'Archive position';

  Widget _buildErrorPanel(ThemeData theme) {
    final error = _apiError!;
    final isConflict =
        error.statusCode == 409 && error.code == 'REVISION_CONFLICT';

    if (isConflict) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.error.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This position changed elsewhere since you opened it.',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  error.message ??
                      'Your edit was not applied. Reload the position and '
                      'reapply your changes on the latest revision.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  key: const Key('position-editor-reload'),
                  style: FilledButton.styleFrom(minimumSize: _buttonMinSize),
                  onPressed: widget.onConflict,
                  child: const Text('Reload position'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  key: const Key('position-editor-retry'),
                  style: OutlinedButton.styleFrom(minimumSize: _buttonMinSize),
                  onPressed: _submitting ? null : _retry,
                  child: const Text('Retry anyway'),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.error.withValues(alpha: 0.4),
            ),
          ),
          child: Text(
            'Could not save: ${error.message ?? error.code}',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          key: const Key('position-editor-retry'),
          style: OutlinedButton.styleFrom(
            minimumSize: _buttonMinSize,
            foregroundColor: _goldAmber,
            side: BorderSide(color: _goldAmber.withValues(alpha: 0.4)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _submitting ? null : _retry,
          child: const Text('Retry'),
        ),
      ],
    );
  }
}
