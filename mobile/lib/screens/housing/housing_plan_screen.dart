import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import '../../contacts/contact_display.dart';
import '../../db/app_database.dart';
import '../../housing/agreement_rules_json.dart';
import '../../housing/quiet_hours_week_grid.dart';
import 'housing_invitation_status_dialog.dart';
import '../../housing/projection/plan_projection.dart';
import '../../housing/proposals/agreement_period_day_overlap.dart';
import '../../housing/proposals/housing_plan_period_gate.dart';
import '../../housing/proposals/housing_proposal_transport_service.dart';
import '../../housing/expense_form/expense_plan_line_form_screen.dart';
import '../../housing/expense_form/expense_recurrence_spec.dart';
import '../../housing/housing_plan_draft_backup.dart';
import '../../housing/proposals/plan_agreement_proposal_service.dart';
import '../../housing/split_minor_by_weights.dart';
import '../../l10n/app_localizations.dart';
import '../../notifications/notification_flow_permission_trigger.dart';
import '../../prefs/app_preferences.dart';
import '../../relay/handshake_orchestrator.dart';
import '../../util/display_date.dart';
import '../../util/format_money.dart';
import '../../widgets/rational_percent_text.dart';
import '../../widgets/standard_validity_duration_bar.dart';
import '../contacts/contact_picker_sheet.dart';
import 'housing_archive_entry_screen.dart';
import 'housing_invite_proposal_screen.dart';
import 'housing_invite_sunburst.dart';
import 'housing_module_entry_screen.dart';
import 'housing_proposal_expenses_detail_screen.dart';

/// Housing plan setup: vertical stepper (4 steps) then summary.
class HousingPlanScreen extends StatefulWidget {
  const HousingPlanScreen({
    super.key,
    required this.prefs,
    this.planId = 'housing:default',
    this.openEditorInitially = false,
  });

  final AppPreferences prefs;

  /// Stable plan row id (participants use `{planId}:self`, `{planId}:p0`, …).
  final String planId;
  final bool openEditorInitially;

  @override
  State<HousingPlanScreen> createState() => _HousingPlanScreenState();
}

class _HousingPlanScreenState extends State<HousingPlanScreen>
    with WidgetsBindingObserver {
  AppDatabase get _db => AppDatabase.processScope;

  String get _planId => widget.planId;
  String get _agreementId => 'agreement:$_planId';

  static const List<IconData> _avatarIcons = [
    MdiIcons.account,
    MdiIcons.accountCircle,
    MdiIcons.accountCowboyHat,
    MdiIcons.accountHeart,
    MdiIcons.accountStar,
    MdiIcons.alien,
    MdiIcons.cat,
    MdiIcons.dog,
    MdiIcons.penguin,
    MdiIcons.panda,
    MdiIcons.robot,
    MdiIcons.ninja,
    MdiIcons.pirate,
    MdiIcons.faceMan,
    MdiIcons.faceWoman,
    MdiIcons.emoticonHappyOutline,
    MdiIcons.emoticonCoolOutline,
    MdiIcons.ghost,
    MdiIcons.owl,
    MdiIcons.fish,
  ];

  static const int _housingPlanStepCount = 4;

  List<String> _housingStepTitles(AppLocalizations l10n) => [
    l10n.housingPlanStepParticipants,
    l10n.housingPlanStepPlanDates,
    l10n.housingPlanStepExpenses,
    l10n.housingPlanStepAgreementRules,
  ];

  AppLocalizations _lookupAppLocalizationsSync() {
    final loc = WidgetsBinding.instance.platformDispatcher.locale;
    final code = loc.languageCode;
    if (code == 'fr') return lookupAppLocalizations(const Locale('fr'));
    if (code == 'es') return lookupAppLocalizations(const Locale('es'));
    return lookupAppLocalizations(const Locale('en'));
  }

  /// Bumps when the summary should re-query DB (e.g. after creating a proposal revision).
  int _summaryReloadToken = 0;

  /// 0–5 = wizard steps; summary when true.
  bool _showSummary = false;
  int _stepIndex = 0;
  int _linesEpoch = 0;
  int _linesFutureSerial = -1;
  Future<List<PlanLine>>? _cachedPlanLinesFuture;

  /// Other people on the plan (not including the signed-in profile).
  int _otherParticipantCount = 1;

  /// Which co-participant form is shown when [_otherParticipantCount] > 1.
  int _coEditorIndex = 0;

  final List<TextEditingController> _nameControllers = [];
  final List<String> _avatarIds = [];
  final List<String?> _contactIds = [];

  DateTime? _periodStart;
  DateTime? _periodEnd;

  /// Selected participant when editing per-person withdrawal rules.
  int _withdrawalParticipantIndex = 0;

  bool _withdrawalSameForAll = true;
  final TextEditingController _globalNotice = TextEditingController(text: '30');
  final TextEditingController _globalPenalty = TextEditingController(text: '0');
  final List<TextEditingController> _perParticipantNotice = [];
  final List<TextEditingController> _perParticipantPenalty = [];

  AgreementRulesDraft _rulesDraft = AgreementRulesDraft();
  bool _rulesRemovalLocked = false;
  final TextEditingController _buildingRulesBody = TextEditingController();
  bool _buildingRulesEditing = false;
  String? _customRuleEditingId;
  TextEditingController? _customRuleEditTitle;
  TextEditingController? _customRuleEditBody;

  static const double _kAgreementRuleHPad = 8;

  bool _curfewExpanded = false;
  bool _curfewEditing = false;
  int _quietUiDayIndex = 0;
  List<List<int>>? _quietGridSnapshotForEdit;

  bool _withdrawalExpanded = false;
  bool _withdrawalEditing = false;
  bool _wdSnapSameForAll = true;
  int _wdSnapWithdrawalParticipantIndex = 0;
  String _wdSnapGlobalNotice = '';
  String _wdSnapGlobalPenalty = '';
  List<String> _wdSnapPerNotice = [];
  List<String> _wdSnapPerPenalty = [];

  bool _buildingExpanded = false;
  String _buildingEditSnapshot = '';

  final Set<String> _expandedCustomRuleIds = {};
  final Set<String> _expandedSuggestionIds = {};

  late final Future<void> _boot;
  bool _draftLoadedFromDb = false;
  Future<void>? _autosaveChain;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    HandshakeOrchestrator.maybeInstance?.steadyStateInboxTick.addListener(
      _onSteadyInboxTick,
    );
    _pollRelayInbox();
    assert(() {
      debugPrint('HousingPlanScreen planId=$_planId');
      return true;
    }());
    _resizeCoParticipantEditors(_otherParticipantCount);
    _resizeWithdrawalEditors(1 + _otherParticipantCount);
    _boot = _loadFromDb();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _pollRelayInbox();
    }
  }

  void _onSteadyInboxTick() {
    if (!mounted) return;
    setState(() => _summaryReloadToken++);
    unawaited(_openReceivedProposalIfPending());
  }

  void _pollRelayInbox() {
    final orch = HandshakeOrchestrator.maybeInstance;
    if (orch == null) {
      debugPrint('housing plan inbox poll skipped: relay not configured');
      return;
    }
    unawaited(
      orch.pollSteadyStateInboxes().catchError((Object e, StackTrace st) {
        debugPrint('housing plan inbox poll failed: $e\n$st');
      }),
    );
  }

  Future<void> _openReceivedProposalIfPending() async {
    final plans = await housingPlansWithSelfParticipant(_db);
    for (final plan in plans) {
      if (!plan.id.startsWith('received:')) continue;
      final pkg = await (_db.select(
        _db.proposalPackages,
      )..where((t) => t.planId.equals(plan.id))).getSingleOrNull();
      if (pkg?.pendingRevisionId == null) continue;
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.housingInviteReceivedWhileEditingSnack),
          action: SnackBarAction(
            label: l10n.housingInviteReceivedOpenAction,
            onPressed: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => HousingInviteProposalScreen(
                    db: _db,
                    planId: plan.id,
                    prefs: widget.prefs,
                  ),
                ),
              );
            },
          ),
        ),
      );
      return;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    HandshakeOrchestrator.maybeInstance?.steadyStateInboxTick.removeListener(
      _onSteadyInboxTick,
    );
    for (final c in _nameControllers) {
      c.dispose();
    }
    for (final c in _perParticipantNotice) {
      c.dispose();
    }
    for (final c in _perParticipantPenalty) {
      c.dispose();
    }
    _globalNotice.dispose();
    _globalPenalty.dispose();
    _buildingRulesBody.dispose();
    _customRuleEditTitle?.dispose();
    _customRuleEditBody?.dispose();
    if (HousingPlanDraftBackup.appliesToPlan(_planId)) {
      unawaited(
        _autosavePlanDraftToDb().then(
          (_) => HousingPlanDraftBackup.snapshot(_db, widget.prefs, _planId),
        ),
      );
    }
    // Do not close [AppDatabase.processScope] here — it is bound once in
    // bootstrap for the whole process. Closing it breaks any screen that
    // opens after navigating away (e.g. system back from Plan logement).
    super.dispose();
  }

  String get _selfParticipantId => '$_planId:self';

  String _coParticipantId(int i) => '$_planId:p$i';

  List<String> _allParticipantIds() => [
    _selfParticipantId,
    ...List.generate(_otherParticipantCount, _coParticipantId),
  ];

  void _resizeCoParticipantEditors(int n) {
    while (_nameControllers.length < n) {
      _nameControllers.add(TextEditingController());
      _avatarIds.add('mdi:0');
      _contactIds.add(null);
    }
    while (_nameControllers.length > n) {
      _nameControllers.removeLast().dispose();
      _avatarIds.removeLast();
      _contactIds.removeLast();
    }
    if (_coEditorIndex >= n) {
      _coEditorIndex = n > 0 ? n - 1 : 0;
    }
  }

  void _resizeWithdrawalEditors(int total) {
    while (_perParticipantNotice.length < total) {
      _perParticipantNotice.add(TextEditingController(text: '30'));
      _perParticipantPenalty.add(TextEditingController(text: '0'));
    }
    while (_perParticipantNotice.length > total) {
      _perParticipantNotice.removeLast().dispose();
      _perParticipantPenalty.removeLast().dispose();
    }
  }

  void _resizeParticipantEditors(int n) {
    _resizeCoParticipantEditors(n);
    _resizeWithdrawalEditors(1 + n);
  }

  String _ratioParticipantLabel(AppLocalizations l10n, int index) {
    if (index == 0) return l10n.housingPlanYou;
    final nm = _nameControllers[index - 1].text.trim();
    return nm.isEmpty ? l10n.housingPlanCoParticipantUnnamed(index) : nm;
  }

  IconData _avatarIconFor(String avatarId) {
    final idx = int.tryParse(avatarId.split(':').last);
    if (idx == null || idx < 0 || idx >= _avatarIcons.length) {
      return MdiIcons.account;
    }
    return _avatarIcons[idx];
  }

  Future<void> _chooseContactForParticipant(int index) async {
    final excluded = <String>{
      for (var i = 0; i < _contactIds.length; i++)
        if (i != index && _contactIds[i] != null) _contactIds[i]!,
    };
    final selected = await showContactPickerSheet(
      context: context,
      db: _db,
      excludeContactIds: excluded,
    );
    if (selected == null || !mounted) return;
    setState(() {
      _contactIds[index] = selected.id;
      _nameControllers[index].text = selected.effectiveDisplayName;
      _avatarIds[index] = selected.avatarId;
    });
    unawaited(_autosavePlanDraftToDb());
  }

  Future<void> _ensurePlanShell() async {
    final l10n = _lookupAppLocalizationsSync();
    await _db.upsertPlan(
      PlansCompanion.insert(
        id: _planId,
        type: 'housing',
        createdAt: DateTime.now().toUtc(),
        title: drift.Value(l10n.homeHousingPlan),
        currency: drift.Value(
          widget.prefs.currency.trim().isEmpty
              ? 'CAD'
              : widget.prefs.currency.trim(),
        ),
        notes: const drift.Value.absent(),
      ),
    );
    final existing = await _db.getAgreementForPlan(_planId);
    if (existing == null) {
      await _db.upsertAgreement(
        AgreementsCompanion.insert(
          id: _agreementId,
          planId: _planId,
          periodStart: DateTime.now().toUtc(),
          periodEnd: DateTime.now().toUtc().add(const Duration(days: 180)),
          createdAt: DateTime.now().toUtc(),
          minNoticeDays: const drift.Value(30),
          penaltyMinor: const drift.Value(0),
        ),
      );
    }
  }

  /// True when the local DB contains everything required to show the housing
  /// summary (same gates as finishing the wizard). SharedPreferences alone is
  /// not enough: clearing the DB leaves a stale `housingDefaultPlanSummaryReached`.
  Future<bool> _isHousingPlanWizardFullyDoneInDb() async {
    if (!_validateStep(0)) return false;
    if (!_datesStepValid()) return false;
    if (!await _validateExpensesStep()) return false;
    if (!_validateStep(3)) return false;
    return true;
  }

  /// First wizard step that is not satisfied yet (0–3).
  Future<int> _inferResumeStepIndex() async {
    if (!_validateStep(0)) return 0;
    if (!_datesStepValid()) return 1;
    if (!await _validateExpensesStep()) return 2;
    if (!_validateStep(3)) return 3;
    return 3;
  }

  Future<void> _stripOrphanGroupPlanRatios() async {
    await (_db.delete(_db.planRatios)
          ..where((t) => t.planId.equals(_planId))
          ..where((t) => t.groupId.isNotNull())
          ..where((t) => t.lineId.isNull()))
        .go();
  }

  Future<bool> _validateExpensesStep() async {
    final lines = await _db.listPlanLines(_planId);
    if (lines.isEmpty) return false;
    final pids = _allParticipantIds();
    final ratios = await _db.listPlanRatios(_planId);
    for (final l in lines) {
      if (l.amountMinor == null || l.amountMinor! <= 0) return false;
      if (l.isRecurring) {
        final spec = ExpenseRecurrenceSpec.parseStored(l.recurrenceSpecJson);
        if (spec == null) {
          final day = l.recurrenceDayOfMonth;
          if (day == null || day < 1 || day > 31) return false;
        }
      }
      var sum = 0;
      for (final pid in pids) {
        sum += ratios
            .where((r) => r.lineId == l.id && r.participantId == pid)
            .fold<int>(0, (a, r) => a + r.weight);
      }
      if (sum != 10000) return false;
    }
    return true;
  }

  Future<void> _loadFromDb() async {
    await _ensurePlanShell();
    if (kIsWeb && HousingPlanDraftBackup.appliesToPlan(_planId)) {
      final restored = await HousingPlanDraftBackup.restoreIfNeeded(
        _db,
        widget.prefs,
        _planId,
      );
      if (restored) {
        _linesEpoch++;
      }
    }
    await _stripOrphanGroupPlanRatios();
    final roster = await _db.listParticipants();
    final coRows = roster.where((p) => p.id.startsWith('$_planId:p')).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    if (coRows.isNotEmpty) {
      _otherParticipantCount = coRows.length.clamp(1, 7);
      _resizeParticipantEditors(_otherParticipantCount);
      for (var i = 0; i < coRows.length; i++) {
        _nameControllers[i].text = coRows[i].displayName;
        _avatarIds[i] = coRows[i].avatarId;
        _contactIds[i] = coRows[i].contactId;
      }
    }

    final agr = await _db.getAgreementForPlan(_planId);
    if (agr != null) {
      _periodStart = agr.periodStart;
      _periodEnd = agr.periodEnd;
      _withdrawalSameForAll = agr.withdrawalSameForAll != 'false';
      _globalNotice.text = agr.minNoticeDays.toString();
      _globalPenalty.text = (agr.penaltyMinor / 100).toStringAsFixed(2);
      try {
        final map =
            jsonDecode(agr.withdrawalPerParticipantJson)
                as Map<String, dynamic>?;
        if (map != null) {
          final total = 1 + _otherParticipantCount;
          for (var i = 0; i < total && i < _perParticipantNotice.length; i++) {
            final pid = i == 0 ? _selfParticipantId : _coParticipantId(i - 1);
            final row = map[pid] as Map<String, dynamic>?;
            if (row != null) {
              _perParticipantNotice[i].text =
                  (row['minNoticeDays'] as num?)?.toInt().toString() ?? '30';
              final pen = (row['penaltyMinor'] as num?)?.toInt() ?? 0;
              _perParticipantPenalty[i].text = (pen / 100).toStringAsFixed(2);
            }
          }
        }
      } catch (_) {}

      _rulesDraft = AgreementRulesDraft.parseStored(
        agreementRulesJson: agr.agreementRulesJson,
        clausesFallback: agr.clauses,
      );
      _buildingRulesBody.text = _rulesDraft.buildingRulesText;
      if (_buildingRulesBody.text.trim().isEmpty) {
        _buildingRulesBody.text =
            _lookupAppLocalizationsSync().housingAgreementRuleBuildingHint;
      }
    }

    _rulesRemovalLocked = await _db.planHasActiveAcceptedProposal(_planId);

    final dbComplete = await _isHousingPlanWizardFullyDoneInDb();
    if (dbComplete) {
      _showSummary = !widget.openEditorInitially;
      if (_showSummary) {
        _summaryReloadToken++;
      }
      await widget.prefs.setHousingDefaultPlanSummaryReached(true);
    } else {
      _showSummary = false;
      await widget.prefs.setHousingDefaultPlanSummaryReached(false);
      _stepIndex = await _inferResumeStepIndex();
    }
    _draftLoadedFromDb = true;
  }

  Future<void> _onEditPlanFromSummary() async {
    await HousingProposalTransportService(_db).startPreparedForkDraft(_planId);
    if (!mounted) return;
    setState(() {
      _showSummary = false;
      _stepIndex = 0;
    });
  }

  Future<List<PlanLine>> _planLinesFuture() {
    if (_linesFutureSerial != _linesEpoch) {
      _linesFutureSerial = _linesEpoch;
      _cachedPlanLinesFuture = _db.listPlanLines(_planId);
    }
    return _cachedPlanLinesFuture!;
  }

  bool _stepDone(int i) {
    if (_showSummary) return true;
    return i < _stepIndex;
  }

  bool get _anyAgreementRuleEditing =>
      _curfewEditing ||
      _withdrawalEditing ||
      _buildingRulesEditing ||
      _customRuleEditingId != null;

  /// While editing agreement rule content, block wizard navigation on agreement step.
  bool get _agreementRulesStepFooterLocked =>
      _stepIndex == 3 && _anyAgreementRuleEditing;

  bool _datesStepValid() {
    if (_periodStart == null || _periodEnd == null) return false;
    return isStrictlyBeforeCalendarDate(_periodStart!, _periodEnd!);
  }

  /// Ensures [end] is strictly after [start] on the local calendar (mutates [_periodEnd]).
  void _ensureEndAfterStartCalendar() {
    final s = _periodStart;
    var e = _periodEnd;
    if (s == null || e == null) return;
    if (isStrictlyBeforeCalendarDate(s, e)) return;
    final sd = DateUtils.dateOnly(s.toLocal());
    e = DateTime(
      sd.year,
      sd.month,
      sd.day,
    ).add(const Duration(days: 1)).toUtc();
    _periodEnd = e;
  }

  DateTime _endDatePickerFirstDate() {
    if (_periodStart == null) return DateTime(2020);
    return DateUtils.dateOnly(
      _periodStart!.toLocal(),
    ).add(const Duration(days: 1));
  }

  DateTime _endDatePickerInitialDate() {
    final minD = _endDatePickerFirstDate();
    final raw = (_periodEnd ?? _periodStart ?? DateTime.now()).toLocal();
    final rd = DateUtils.dateOnly(raw);
    if (rd.isBefore(DateUtils.dateOnly(minD))) {
      return minD;
    }
    return raw;
  }

  bool _validateStep(int i) {
    switch (i) {
      case 0:
        if (_otherParticipantCount < 1) return false;
        for (var j = 0; j < _otherParticipantCount; j++) {
          if (_contactIds[j] == null) return false;
          if (_nameControllers[j].text.trim().isEmpty) return false;
          if (_avatarIds[j].isEmpty) return false;
        }
        return true;
      case 1:
        return _datesStepValid();
      case 2:
        return true; // validated async: expenses + per-line ratios
      case 3:
        if (!_rulesDraft.earlyWithdrawalEnabled) return true;
        final n = int.tryParse(_globalNotice.text.trim()) ?? 0;
        final p = _parseMinor(_globalPenalty.text) ?? 0;
        if (_withdrawalSameForAll) {
          return n > 0 || p > 0;
        }
        final total = 1 + _otherParticipantCount;
        for (var j = 0; j < total; j++) {
          final nj = int.tryParse(_perParticipantNotice[j].text.trim()) ?? 0;
          final pj = _parseMinor(_perParticipantPenalty[j].text) ?? 0;
          if (nj <= 0 && pj <= 0) return false;
        }
        return true;
      default:
        return true;
    }
  }

  /// Writes the current wizard state to Drift (best-effort, incremental).
  Future<void> _autosavePlanDraftToDb() {
    if (!_draftLoadedFromDb) return Future<void>.value();
    final prior = _autosaveChain ?? Future<void>.value();
    final gate = Completer<void>();
    _autosaveChain = gate.future;
    return prior.then((_) => _runAutosavePlanDraftToDb()).whenComplete(gate.complete);
  }

  Future<void> _runAutosavePlanDraftToDb() async {
    try {
      await _persistParticipants();
    } catch (e, st) {
      assert(() {
        debugPrint('housing_plan_draft autosave participants: $e\n$st');
        return true;
      }());
    }
    try {
      if (_datesStepValid()) {
        await _persistPeriod();
      }
    } catch (e, st) {
      assert(() {
        debugPrint('housing_plan_draft autosave period: $e\n$st');
        return true;
      }());
    }
    try {
      final agr = await _db.getAgreementForPlan(_planId);
      if (agr != null) {
        await _persistAgreementRules();
      }
    } catch (e, st) {
      assert(() {
        debugPrint('housing_plan_draft autosave rules: $e\n$st');
        return true;
      }());
    }
    await _db.syncWebStorageToDisk();
  }

  Future<void> _persistParticipants() async {
    final selfName = widget.prefs.displayName.trim();
    final selfAvatar = widget.prefs.avatarId.trim();
    await _db.upsertParticipant(
      ParticipantsCompanion.insert(
        id: _selfParticipantId,
        displayName: selfName.isEmpty
            ? _lookupAppLocalizationsSync().housingPlanYou
            : selfName,
        avatarId: selfAvatar.isEmpty ? 'mdi:0' : selfAvatar,
        createdAt: DateTime.now().toUtc(),
      ),
    );
    for (var i = 0; i < _otherParticipantCount; i++) {
      await _db.upsertParticipant(
        ParticipantsCompanion.insert(
          id: _coParticipantId(i),
          displayName: _nameControllers[i].text.trim(),
          avatarId: _avatarIds[i],
          createdAt: DateTime.now().toUtc(),
          contactId: drift.Value(_contactIds[i]),
        ),
      );
    }
    final all = await _db.listParticipants();
    for (final p in all) {
      if (p.id.startsWith('$_planId:p')) {
        final idx = int.tryParse(p.id.split(':p').last);
        if (idx == null || idx >= _otherParticipantCount) {
          await (_db.delete(
            _db.participants,
          )..where((t) => t.id.equals(p.id))).go();
        }
      }
    }
  }

  Future<void> _persistPeriod() async {
    await _ensurePlanShell();
    var cur = await _db.getAgreementForPlan(_planId);
    if (cur == null) {
      await _ensurePlanShell();
      cur = await _db.getAgreementForPlan(_planId);
    }
    if (cur == null) {
      throw StateError('No agreement row for $_planId');
    }
    await _db.upsertAgreement(
      AgreementsCompanion(
        id: drift.Value(cur.id),
        planId: drift.Value(cur.planId),
        periodStart: drift.Value(_periodStart!),
        periodEnd: drift.Value(_periodEnd!),
        minNoticeDays: drift.Value(cur.minNoticeDays),
        penaltyMinor: drift.Value(cur.penaltyMinor),
        clauses: drift.Value(cur.clauses),
        withdrawalSameForAll: drift.Value(cur.withdrawalSameForAll),
        withdrawalPerParticipantJson: drift.Value(
          cur.withdrawalPerParticipantJson,
        ),
        agreementRulesJson: drift.Value(cur.agreementRulesJson),
        version: drift.Value(cur.version),
        createdAt: drift.Value(cur.createdAt),
      ),
    );
  }

  /// Monthly basis for presentation (budget cap uses high estimate).
  int _splitBasisMinor(PlanLine line) => PlanProjection.unitMinor(line);

  Future<void> _persistAgreementRules() async {
    final cur = await _db.getAgreementForPlan(_planId);
    if (cur == null) throw StateError('No agreement row for $_planId');

    _rulesDraft.buildingRulesText = _buildingRulesBody.text;

    var notice = 0;
    var penalty = 0;
    var per = <String, dynamic>{};
    if (_rulesDraft.earlyWithdrawalEnabled) {
      notice = int.tryParse(_globalNotice.text.trim()) ?? 0;
      penalty = _parseMinor(_globalPenalty.text) ?? 0;
      if (!_withdrawalSameForAll) {
        final total = 1 + _otherParticipantCount;
        for (var i = 0; i < total; i++) {
          final pid = i == 0 ? _selfParticipantId : _coParticipantId(i - 1);
          per[pid] = {
            'minNoticeDays':
                int.tryParse(_perParticipantNotice[i].text.trim()) ?? 0,
            'penaltyMinor': _parseMinor(_perParticipantPenalty[i].text) ?? 0,
          };
        }
      }
    }

    await _db.upsertAgreement(
      AgreementsCompanion.insert(
        id: _agreementId,
        planId: _planId,
        periodStart: cur.periodStart,
        periodEnd: cur.periodEnd,
        minNoticeDays: drift.Value(
          _rulesDraft.earlyWithdrawalEnabled && _withdrawalSameForAll
              ? notice
              : 0,
        ),
        penaltyMinor: drift.Value(
          _rulesDraft.earlyWithdrawalEnabled && _withdrawalSameForAll
              ? penalty
              : 0,
        ),
        clauses: drift.Value(_buildingRulesBody.text),
        withdrawalSameForAll: drift.Value(
          _withdrawalSameForAll ? 'true' : 'false',
        ),
        withdrawalPerParticipantJson: drift.Value(jsonEncode(per)),
        agreementRulesJson: drift.Value(_rulesDraft.encode()),
        version: drift.Value(cur.version + 1),
        createdAt: cur.createdAt,
      ),
    );
  }

  int? _parseMinor(String text) {
    final t = text.trim().replaceAll(',', '.');
    if (t.isEmpty) return 0;
    final v = double.tryParse(t);
    if (v == null) return null;
    return (v * 100).round();
  }

  void _openInviteProposalFlow() {
    debugPrint('housing_proposal summary send tapped for $_planId');
    unawaited(_sendInviteProposalFlow(context));
  }

  Future<bool> _sendInviteProposalFlow(BuildContext flowContext) async {
    debugPrint('housing_proposal send flow started for $_planId');
    final agr = await _db.getAgreementForPlan(_planId);
    if (!mounted || !flowContext.mounted) return false;
    final l10n = AppLocalizations.of(flowContext);
    if (agr == null) {
      ScaffoldMessenger.of(flowContext).showSnackBar(
        SnackBar(content: Text(l10n.housingPlanSummaryMissingAgreement)),
      );
      return false;
    }

    var selected = StandardValidityDurations.values[2];

    final proceed = await showDialog<bool>(
      context: flowContext,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(l10n.housingInviteResponseWindowTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.housingInviteResponseWindowBody),
                const SizedBox(height: 16),
                StandardValidityDurationSegmented(
                  selected: selected,
                  onChanged: (d) => setLocal(() => selected = d),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.housingPlanCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.commonContinue),
            ),
          ],
        ),
      ),
    );

    if (proceed != true || !mounted || !flowContext.mounted) return false;

    // TODO(pre-prod): evaluate merging this notification trigger with the
    // response-window selector into a single reusable prompt flow.
    final notificationResult = await const NotificationFlowPermissionTrigger()
        .ensure(
          context: flowContext,
          prefs: widget.prefs,
          switches: const {
            NotificationFlowSwitch.housingDecisionChange,
            NotificationFlowSwitch.housingOfferExpiration,
          },
        );
    if (notificationResult == NotificationFlowPermissionResult.abortFlow ||
        !mounted ||
        !flowContext.mounted) {
      return false;
    }

    final responseExpiresAt = DateTime.now().toUtc().add(selected);
    final blocking = await listBlockingAgreementDayRanges(
      _db,
      excludePlanId: _planId,
    );
    if (candidateConflictsWithAnyBlockingRange(
      agr.periodStart,
      agr.periodEnd,
      blocking,
    )) {
      if (!mounted || !flowContext.mounted) return false;
      await showDialog<void>(
        context: flowContext,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.housingInvitePeriodOverlapTitle),
          content: Text(l10n.housingInvitePeriodOverlapBody),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.onboardingOk),
            ),
          ],
        ),
      );
      return false;
    }

    final proposerId = '$_planId:self';
    late final String revisionId;
    try {
      final fork = await HousingProposalTransportService(
        _db,
      ).preparedForkLineage(_planId);
      revisionId = await PlanAgreementProposalService(_db)
          .createRevisionFromCurrentDraft(
            planId: _planId,
            proposerParticipantId: proposerId,
            responseExpiresAt: responseExpiresAt,
            forkedFromPackageId: fork?.packageId,
            forkedFromRevisionId: fork?.revisionId,
          );
    } catch (e, st) {
      if (!mounted || !flowContext.mounted) return false;
      debugPrintStack(stackTrace: st);
      ScaffoldMessenger.of(flowContext).showSnackBar(
        SnackBar(content: Text(l10n.housingPlanCouldNotContinue('$e'))),
      );
      return false;
    }

    final sent = await _deliverHousingProposalRevision(
      flowContext: flowContext,
      revisionId: revisionId,
      rollbackPendingOnTotalFailure: true,
    );
    if (!mounted) return sent;
    setState(() => _summaryReloadToken++);
    return sent;
  }

  Future<void> _resendPendingProposal() async {
    final canResend = await PlanAgreementProposalService(
      _db,
    ).canResendPendingProposal(_planId);
    if (!canResend || !mounted) return;
    final revisionId = await HousingProposalTransportService(
      _db,
    ).pendingRevisionIdForPlan(_planId);
    if (revisionId == null || !mounted) return;
    final sent = await _deliverHousingProposalRevision(
      flowContext: context,
      revisionId: revisionId,
      rollbackPendingOnTotalFailure: false,
    );
    if (!mounted) return;
    setState(() => _summaryReloadToken++);
    if (sent) return;
  }

  /// Posts the pending revision to invitees via the relay. When
  /// [rollbackPendingOnTotalFailure] is true and nobody receives it, clears the
  /// local pending revision so the author can submit again.
  Future<bool> _deliverHousingProposalRevision({
    required BuildContext flowContext,
    required String revisionId,
    required bool rollbackPendingOnTotalFailure,
  }) async {
    final l10n = AppLocalizations.of(flowContext);
    try {
      final orchestrator = HandshakeOrchestrator.maybeInstance;
      if (orchestrator == null) {
        throw HandshakeOrchestratorError('relay_unavailable');
      }
      final send = await orchestrator.sendHousingProposalToPlanParticipants(
        planId: _planId,
        revisionId: revisionId,
      );
      if (!mounted || !flowContext.mounted) return false;
      if (send.sentCount == 0) {
        if (rollbackPendingOnTotalFailure) {
          await PlanAgreementProposalService(_db).abandonPendingRevision(
            _planId,
          );
        }
        ScaffoldMessenger.of(flowContext).showSnackBar(
          SnackBar(content: Text(l10n.housingInviteTransportFailed)),
        );
        return false;
      }
      final message = send.failedParticipantIds.isEmpty
          ? l10n.housingInviteTransportSent(send.sentCount)
          : l10n.housingInviteTransportPartial(
              send.sentCount,
              send.failedParticipantIds.length,
            );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return true;
    } catch (e, st) {
      if (!mounted || !flowContext.mounted) return false;
      debugPrintStack(stackTrace: st);
      if (rollbackPendingOnTotalFailure) {
        await PlanAgreementProposalService(_db).abandonPendingRevision(_planId);
      }
      ScaffoldMessenger.of(flowContext).showSnackBar(
        SnackBar(content: Text(l10n.housingPlanCouldNotContinue('$e'))),
      );
      return false;
    }
  }

  Future<void> _onDestroyPlan() async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.housingPlanDestroyTitle),
        content: Text(l10n.housingPlanDestroyBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.housingPlanCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.housingPlanDestroyConfirm),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _db.deletePlanRelatedData(_planId);
    if (HousingPlanDraftBackup.appliesToPlan(_planId)) {
      await HousingPlanDraftBackup.clear(widget.prefs, _planId);
    }
    await widget.prefs.setHousingDefaultPlanSummaryReached(false);
    await _ensurePlanShell();
    setState(() {
      _showSummary = false;
      _stepIndex = 0;
      _withdrawalParticipantIndex = 0;
    });
    await _loadFromDb();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.housingPlanRemovedSnackbar)));
    }
  }

  Widget _stepperRail() {
    return SizedBox(
      width: 52,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 0, 16),
        child: Column(
          children: [
            for (var i = 0; i < _housingPlanStepCount; i++) ...[
              if (i > 0)
                SizedBox(
                  height: 12,
                  child: Center(
                    child: Container(
                      width: 2,
                      height: 12,
                      color: _stepDone(i) || i <= _stepIndex
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ),
              SizedBox(
                width: 32,
                height: 32,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: i == _stepIndex && !_showSummary
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                      child: _stepDone(i) || (i < _stepIndex)
                          ? Icon(
                              Icons.check,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text(l10n.homeHousingPlan)),
      body: FutureBuilder<void>(
        future: _boot,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.housingPlanLoadError('${snap.error}'),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (_showSummary) {
            return _SummaryView(
              key: ValueKey<int>(_summaryReloadToken),
              db: _db,
              planId: _planId,
              prefs: widget.prefs,
              reloadToken: _summaryReloadToken,
              avatarIcons: _avatarIcons,
              onEditPlan: _onEditPlanFromSummary,
              onInvite: _openInviteProposalFlow,
              onResendProposal: _resendPendingProposal,
              onDestroy: _onDestroyPlan,
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _stepperRail(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (_stepIndex == 0)
                            Expanded(
                              child: Row(
                                children: [
                                  IconButton.filledTonal(
                                    tooltip: l10n
                                        .housingPlanFewerParticipantsTooltip,
                                    onPressed: _otherParticipantCount <= 1
                                        ? null
                                        : () => _applyOtherParticipantCount(
                                            _otherParticipantCount - 1,
                                          ),
                                    icon: const Icon(Icons.remove),
                                  ),
                                  Expanded(
                                    child: Text(
                                      l10n.housingPlanParticipantsCount(
                                        1 + _otherParticipantCount,
                                      ),
                                      textAlign: TextAlign.center,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.headlineSmall,
                                    ),
                                  ),
                                  IconButton.filledTonal(
                                    tooltip:
                                        l10n.housingPlanMoreParticipantsTooltip,
                                    onPressed: _otherParticipantCount >= 7
                                        ? null
                                        : () => _applyOtherParticipantCount(
                                            _otherParticipantCount + 1,
                                          ),
                                    icon: const Icon(Icons.add),
                                  ),
                                ],
                              ),
                            )
                          else
                            Expanded(
                              child: Text(
                                _housingStepTitles(l10n)[_stepIndex],
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                            ),
                          if (_stepIndex == 2)
                            IconButton.filledTonal(
                              tooltip: l10n.housingPlanAddExpenseTooltip,
                              onPressed: () async {
                                await _editLine(null);
                                if (mounted) setState(() => _linesEpoch++);
                              },
                              icon: const Icon(Icons.add),
                            ),
                        ],
                      ),
                    ),
                    Expanded(child: _buildStepBody()),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        16 + MediaQuery.viewPaddingOf(context).bottom,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (_stepIndex > 0) ...[
                            OutlinedButton(
                              onPressed: _agreementRulesStepFooterLocked
                                  ? null
                                  : () => setState(() => _stepIndex--),
                              child: Text(l10n.housingPlanBack),
                            ),
                            const SizedBox(width: 12),
                          ],
                          FilledButton(
                            onPressed: _agreementRulesStepFooterLocked
                                ? null
                                : (_validateStep(_stepIndex)
                                      ? () async {
                                          final messenger =
                                              ScaffoldMessenger.of(context);
                                          if (_stepIndex == 0) {
                                            for (
                                              var j = 0;
                                              j < _otherParticipantCount;
                                              j++
                                            ) {
                                              final id = _contactIds[j]!;
                                              final c = await _db.getContact(
                                                id,
                                              );
                                              if (c == null ||
                                                  c.kind != 'connected' ||
                                                  c.isBlocked) {
                                                if (mounted) {
                                                  messenger.showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        l10n.housingPlanParticipantsMustBeConnected,
                                                      ),
                                                    ),
                                                  );
                                                }
                                                return;
                                              }
                                            }
                                          }
                                          try {
                                            if (_stepIndex == 0) {
                                              await _persistParticipants();
                                            }
                                            if (_stepIndex == 1) {
                                              await _persistPeriod();
                                            }
                                            if (_stepIndex == 2) {
                                              if (!await _validateExpensesStep()) {
                                                if (mounted) {
                                                  messenger.showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        l10n.housingPlanExpenseValidationMessage,
                                                      ),
                                                    ),
                                                  );
                                                }
                                                return;
                                              }
                                            }
                                            if (_stepIndex == 3) {
                                              await _persistAgreementRules();
                                              await widget.prefs
                                                  .setHousingDefaultPlanSummaryReached(
                                                    true,
                                                  );
                                              if (mounted) {
                                                setState(() {
                                                  _showSummary = true;
                                                  _summaryReloadToken++;
                                                });
                                              }
                                              return;
                                            }
                                            if (mounted) {
                                              setState(() => _stepIndex++);
                                            }
                                          } catch (e, st) {
                                            assert(() {
                                              debugPrint(
                                                'Housing plan Next: $e\n$st',
                                              );
                                              return true;
                                            }());
                                            if (mounted) {
                                              messenger.showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    l10n.housingPlanCouldNotContinue(
                                                      '$e',
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      : null),
                            child: Text(
                              _stepIndex == 3
                                  ? l10n.housingPlanFinish
                                  : l10n.housingPlanNext,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStepBody() {
    switch (_stepIndex) {
      case 0:
        return _stepParticipants();
      case 1:
        return _stepDates();
      case 2:
        return _stepExpenses();
      case 3:
        return _stepAgreementRules();
      default:
        return const SizedBox.shrink();
    }
  }

  void _applyOtherParticipantCount(int next) {
    final v = next.clamp(1, 7);
    setState(() {
      _otherParticipantCount = v;
      _resizeParticipantEditors(v);
      _coEditorIndex = _coEditorIndex.clamp(0, v - 1);
      final maxPid = v;
      _withdrawalParticipantIndex = _withdrawalParticipantIndex.clamp(
        0,
        maxPid,
      );
    });
  }

  Widget _stepParticipants() {
    final l10n = AppLocalizations.of(context);
    final i = _otherParticipantCount > 1 ? _coEditorIndex : 0;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_otherParticipantCount > 1) ...[
          Row(
            children: [
              OutlinedButton(
                onPressed: _coEditorIndex > 0
                    ? () => setState(() => _coEditorIndex--)
                    : null,
                child: Text(l10n.housingPlanPreviousPerson),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: _coEditorIndex < _otherParticipantCount - 1
                    ? () => setState(() => _coEditorIndex++)
                    : null,
                child: Text(l10n.housingPlanNextPerson),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        _HousingContactParticipantCard(
          title: l10n.housingPlanCoParticipantUnnamed(i + 1),
          displayName: _nameControllers[i].text.trim(),
          avatarId: _avatarIds[i],
          hasContact: _contactIds[i] != null,
          avatarIconFor: _avatarIconFor,
          onChooseContact: () => _chooseContactForParticipant(i),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.housingPlanParticipantsPlaceholderNote,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _stepDates() {
    return ListenableBuilder(
      listenable: widget.prefs,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context);
        final fmt = widget.prefs.dateFormat;
        final durationText = formatContractCalendarDuration(
          _periodStart,
          _periodEnd,
          l10n,
        );
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      l10n.housingPlanPlanStart,
                      textAlign: TextAlign.center,
                    ),
                    subtitle: Text(
                      formatPreferenceDate(_periodStart, fmt),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        initialDate: (_periodStart ?? DateTime.now()).toLocal(),
                      );
                      if (picked != null) {
                        setState(() {
                          _periodStart = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                          ).toUtc();
                          _ensureEndAfterStartCalendar();
                        });
                        unawaited(_autosavePlanDraftToDb());
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      l10n.housingPlanPlanEnd,
                      textAlign: TextAlign.center,
                    ),
                    subtitle: Text(
                      formatPreferenceDate(_periodEnd, fmt),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: _endDatePickerFirstDate(),
                        lastDate: DateTime(2100),
                        initialDate: _endDatePickerInitialDate(),
                      );
                      if (picked != null) {
                        setState(
                          () => _periodEnd = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                          ).toUtc(),
                        );
                        unawaited(_autosavePlanDraftToDb());
                      }
                    },
                  ),
                ],
              ),
            ),
            if (durationText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Center(
                  child: Text(
                    durationText,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            if (_periodStart != null &&
                _periodEnd != null &&
                !isStrictlyBeforeCalendarDate(_periodStart!, _periodEnd!))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.housingPlanEndDateError,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _stepExpenses() {
    return FutureBuilder<List<PlanLine>>(
      future: _planLinesFuture(),
      builder: (context, snap) {
        final l10n = AppLocalizations.of(context);
        final lines = snap.data ?? [];
        return Column(
          children: [
            Expanded(
              child: lines.isEmpty
                  ? Center(child: Text(l10n.housingPlanTapToAddExpense))
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: lines.length,
                      onReorder: (oldI, newI) async {
                        if (newI > oldI) newI--;
                        final copy = List<PlanLine>.from(lines);
                        final item = copy.removeAt(oldI);
                        copy.insert(newI, item);
                        for (var i = 0; i < copy.length; i++) {
                          final c = copy[i];
                          copy[i] = PlanLine(
                            id: c.id,
                            planId: c.planId,
                            isRecurring: c.isRecurring,
                            title: c.title,
                            currency: c.currency,
                            amountUsesRange: c.amountUsesRange,
                            amountMinor: c.amountMinor,
                            minAmountMinor: c.minAmountMinor,
                            maxAmountMinor: c.maxAmountMinor,
                            description: c.description,
                            cadence: c.cadence,
                            recurrenceDayOfMonth: c.recurrenceDayOfMonth,
                            sortOrder: i,
                            groupId: c.groupId,
                            amountIsBudgetCap: c.amountIsBudgetCap,
                            paymentResponsibleParticipantId:
                                c.paymentResponsibleParticipantId,
                            recurrenceSpecJson: c.recurrenceSpecJson,
                            ratioTemplateId: c.ratioTemplateId,
                            createdAt: c.createdAt,
                          );
                          final row = copy[i];
                          await _db.upsertPlanLine(
                            PlanLinesCompanion(
                              id: drift.Value(row.id),
                              planId: drift.Value(row.planId),
                              isRecurring: drift.Value(row.isRecurring),
                              title: drift.Value(row.title),
                              currency: drift.Value(row.currency),
                              amountMinor: drift.Value(row.amountMinor),
                              minAmountMinor: drift.Value(row.minAmountMinor),
                              maxAmountMinor: drift.Value(row.maxAmountMinor),
                              cadence: drift.Value(row.cadence),
                              recurrenceDayOfMonth: drift.Value(
                                row.recurrenceDayOfMonth,
                              ),
                              sortOrder: drift.Value(row.sortOrder),
                              groupId: drift.Value(row.groupId),
                              amountUsesRange: drift.Value(row.amountUsesRange),
                              amountIsBudgetCap: drift.Value(
                                row.amountIsBudgetCap,
                              ),
                              description: drift.Value(row.description),
                              paymentResponsibleParticipantId: drift.Value(
                                row.paymentResponsibleParticipantId,
                              ),
                              recurrenceSpecJson: drift.Value(
                                row.recurrenceSpecJson,
                              ),
                              ratioTemplateId: drift.Value(row.ratioTemplateId),
                              createdAt: drift.Value(row.createdAt),
                            ),
                          );
                        }
                        if (HousingPlanDraftBackup.appliesToPlan(_planId)) {
                          final ratios = await _db.listPlanRatios(_planId);
                          await HousingPlanDraftBackup.replaceAllLines(
                            prefs: widget.prefs,
                            lines: copy,
                            lineRatios: ratios
                                .where((r) => r.lineId != null)
                                .toList(),
                          );
                        }
                        if (mounted) {
                          setState(() => _linesEpoch++);
                        }
                      },
                      itemBuilder: (context, index) {
                        final line = lines[index];
                        return ReorderableDelayedDragStartListener(
                          key: ValueKey(line.id),
                          index: index,
                          child: Card(
                            child: ListTile(
                              title: Text(line.title),
                              subtitle: line.amountIsBudgetCap
                                  ? Text(l10n.housingExpenseAmountBudgetMax)
                                  : Text(l10n.housingExpenseAmountDetermined),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    formatMinorAsMoney(
                                      context,
                                      _splitBasisMinor(line),
                                      displayCurrencyCodeForPlan(
                                        widget.prefs,
                                        lines,
                                      ),
                                    ),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () async {
                                      await (_db.delete(
                                            _db.planLines,
                                          )..where((t) => t.id.equals(line.id)))
                                          .go();
                                      if (HousingPlanDraftBackup.appliesToPlan(
                                        _planId,
                                      )) {
                                        await HousingPlanDraftBackup.removeLine(
                                          widget.prefs,
                                          _planId,
                                          line.id,
                                        );
                                      }
                                      if (mounted) {
                                        setState(() => _linesEpoch++);
                                      }
                                    },
                                  ),
                                ],
                              ),
                              onTap: () async {
                                await _editLine(line);
                                if (mounted) setState(() => _linesEpoch++);
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editLine(PlanLine? existing) async {
    final agr = await _db.getAgreementForPlan(_planId);
    if (agr == null || !mounted) return;
    final l10n = AppLocalizations.of(context);
    final pids = _allParticipantIds();
    final names = [
      for (var i = 0; i < pids.length; i++) _ratioParticipantLabel(l10n, i),
    ];
    final lines = await _db.listPlanLines(_planId);
    if (!mounted) return;
    final nextOrder = lines.isEmpty
        ? 0
        : lines.map((e) => e.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
    final currency = widget.prefs.currency.trim().isEmpty
        ? 'CAD'
        : widget.prefs.currency.trim();
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ExpensePlanLineFormScreen(
          planId: _planId,
          participantIds: pids,
          participantNames: names,
          periodStart: agr.periodStart,
          periodEnd: agr.periodEnd,
          defaultCurrency: currency,
          dateFormat: widget.prefs.dateFormat.trim().isEmpty
              ? 'YYYY-MM-DD'
              : widget.prefs.dateFormat.trim(),
          prefsForBackup: HousingPlanDraftBackup.appliesToPlan(_planId)
              ? widget.prefs
              : null,
          existingLineId: existing?.id,
          initialSortOrder: existing?.sortOrder ?? nextOrder,
        ),
      ),
    );
    if (saved == true && mounted) {
      setState(() => _linesEpoch++);
      unawaited(_autosavePlanDraftToDb());
    }
  }

  List<Widget> _earlyWithdrawalRuleContent(AppLocalizations l10n) {
    if (!_rulesDraft.earlyWithdrawalEnabled) {
      return [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            l10n.housingAgreementRuleEarlyWithdrawalDisabledHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ];
    }
    return [
      CheckboxListTile(
        contentPadding: const EdgeInsetsDirectional.fromSTEB(
          _kAgreementRuleHPad,
          0,
          _kAgreementRuleHPad,
          0,
        ),
        value: _withdrawalSameForAll,
        onChanged: (v) {
          final same = v ?? true;
          setState(() {
            _withdrawalSameForAll = same;
            if (!same) {
              _withdrawalParticipantIndex = 0;
            }
          });
        },
        title: Text(l10n.housingPlanWithdrawalSameForAll),
        controlAffinity: ListTileControlAffinity.leading,
      ),
      if (_withdrawalSameForAll) ...[
        TextField(
          controller: _globalNotice,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.housingPlanMinimumNoticeDays,
          ),
          onChanged: (_) => setState(() {}),
        ),
        TextField(
          controller: _globalPenalty,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l10n.housingPlanPenaltyAmount),
          onChanged: (_) => setState(() {}),
        ),
      ] else ...[
        TextField(
          controller: _perParticipantNotice[_withdrawalParticipantIndex],
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.housingPlanMinimumNoticeDays,
          ),
          onChanged: (_) => setState(() {}),
        ),
        TextField(
          controller: _perParticipantPenalty[_withdrawalParticipantIndex],
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l10n.housingPlanPenaltyAmount),
          onChanged: (_) => setState(() {}),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < 1 + _otherParticipantCount; i++)
                ChoiceChip(
                  label: Text(_ratioParticipantLabel(l10n, i)),
                  selected: _withdrawalParticipantIndex == i,
                  onSelected: (sel) {
                    if (!sel) return;
                    setState(() => _withdrawalParticipantIndex = i);
                  },
                ),
            ],
          ),
        ),
      ],
    ];
  }

  void _captureWithdrawalSnapshot() {
    _wdSnapSameForAll = _withdrawalSameForAll;
    _wdSnapWithdrawalParticipantIndex = _withdrawalParticipantIndex;
    _wdSnapGlobalNotice = _globalNotice.text;
    _wdSnapGlobalPenalty = _globalPenalty.text;
    _wdSnapPerNotice = [for (final c in _perParticipantNotice) c.text];
    _wdSnapPerPenalty = [for (final c in _perParticipantPenalty) c.text];
  }

  void _restoreWithdrawalSnapshot() {
    _withdrawalSameForAll = _wdSnapSameForAll;
    _withdrawalParticipantIndex = _wdSnapWithdrawalParticipantIndex;
    _globalNotice.text = _wdSnapGlobalNotice;
    _globalPenalty.text = _wdSnapGlobalPenalty;
    final n = _perParticipantNotice.length;
    for (var i = 0; i < n; i++) {
      if (i < _wdSnapPerNotice.length) {
        _perParticipantNotice[i].text = _wdSnapPerNotice[i];
      }
      if (i < _wdSnapPerPenalty.length) {
        _perParticipantPenalty[i].text = _wdSnapPerPenalty[i];
      }
    }
  }

  Widget _withdrawalReadOnlySummary(AppLocalizations l10n) {
    if (!_rulesDraft.earlyWithdrawalEnabled) {
      return Text(
        l10n.housingAgreementRuleEarlyWithdrawalDisabledHint,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    if (_withdrawalSameForAll) {
      return Text(
        '${l10n.housingPlanMinimumNoticeDays}: ${_globalNotice.text.trim()}\n'
        '${l10n.housingPlanPenaltyAmount}: ${_globalPenalty.text.trim()}',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
    final lines = <String>[];
    final total = 1 + _otherParticipantCount;
    for (var i = 0; i < total; i++) {
      final label = _ratioParticipantLabel(l10n, i);
      final n = i < _perParticipantNotice.length
          ? _perParticipantNotice[i].text.trim()
          : '';
      final p = i < _perParticipantPenalty.length
          ? _perParticipantPenalty[i].text.trim()
          : '';
      lines.add(
        '$label — ${l10n.housingPlanMinimumNoticeDays}: $n; ${l10n.housingPlanPenaltyAmount}: $p',
      );
    }
    return Text(
      lines.join('\n'),
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  Widget _agreementLeadingCheckbox({
    required bool value,
    required ValueChanged<bool?>? onChanged,
  }) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Center(
        child: Checkbox(
          value: value,
          onChanged: onChanged,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }

  Widget _agreementLeadingSuggestionCheckbox() {
    return _agreementLeadingCheckbox(value: true, onChanged: null);
  }

  Widget _agreementRuleAccordionShell({
    required Widget leading,
    required Widget title,
    required bool expanded,
    required VoidCallback onHeaderTap,
    required List<Widget> expandedChildren,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onHeaderTap,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                _kAgreementRuleHPad,
                4,
                _kAgreementRuleHPad,
                4,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  leading,
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: title,
                    ),
                  ),
                  Icon(expanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                _kAgreementRuleHPad,
                0,
                _kAgreementRuleHPad,
                12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: expandedChildren,
              ),
            ),
        ],
      ),
    );
  }

  Widget _agreementRulesActionRow({
    required AppLocalizations l10n,
    required bool pencilEnabled,
    required VoidCallback? onPencil,
    required bool trashEnabled,
    required VoidCallback? onTrash,
    required String trashTooltip,
  }) {
    return Align(
      alignment: AlignmentDirectional.topEnd,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: l10n.housingAgreementRuleEdit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: pencilEnabled ? onPencil : null,
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 2, 4),
            ),
          ),
          IconButton(
            tooltip: trashTooltip,
            icon: const Icon(Icons.delete_outline),
            onPressed: trashEnabled ? onTrash : null,
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsetsDirectional.fromSTEB(2, 4, 4, 4),
            ),
          ),
        ],
      ),
    );
  }

  void _disposeTextControllersNextFrame(
    TextEditingController? a,
    TextEditingController? b,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      a?.dispose();
      b?.dispose();
    });
  }

  void _cancelEditingCustomRule() {
    if (_customRuleEditingId == null) return;
    final a = _customRuleEditTitle;
    final b = _customRuleEditBody;
    setState(() {
      _customRuleEditingId = null;
      _customRuleEditTitle = null;
      _customRuleEditBody = null;
    });
    _disposeTextControllersNextFrame(a, b);
  }

  void _startEditingCustomRule(AgreementCustomRule rule) {
    if (_customRuleEditingId == rule.id) return;
    final oldTitle = _customRuleEditTitle;
    final oldBody = _customRuleEditBody;
    setState(() {
      _customRuleEditingId = rule.id;
      _expandedCustomRuleIds.add(rule.id);
      _customRuleEditTitle = TextEditingController(text: rule.title);
      _customRuleEditBody = TextEditingController(text: rule.body);
    });
    _disposeTextControllersNextFrame(oldTitle, oldBody);
  }

  void _saveEditingCustomRule(AppLocalizations l10n, AgreementCustomRule rule) {
    if (_customRuleEditingId != rule.id ||
        _customRuleEditTitle == null ||
        _customRuleEditBody == null) {
      return;
    }
    final t = _customRuleEditTitle!.text.trim();
    if (t.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.housingAgreementRuleTitleRequired)),
      );
      return;
    }
    final a = _customRuleEditTitle;
    final b = _customRuleEditBody;
    setState(() {
      rule.title = t;
      rule.body = b!.text.trim();
      _customRuleEditingId = null;
      _customRuleEditTitle = null;
      _customRuleEditBody = null;
    });
    _disposeTextControllersNextFrame(a, b);
  }

  void _toggleQuietHalfHour(int uiDay, int slot) {
    setState(() {
      final v = _rulesDraft.quietHalfHours[uiDay][slot];
      _rulesDraft.quietHalfHours[uiDay][slot] = (v + 1) % 3;
    });
  }

  Widget _buildingRulesReadOnlyContent(AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    final bodyStyle = Theme.of(context).textTheme.bodyMedium;
    final raw = _buildingRulesBody.text;
    final display = raw.trim().isEmpty
        ? l10n.housingAgreementRuleBuildingHint
        : raw;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: const BorderRadius.all(Radius.circular(4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: SelectableText(display, style: bodyStyle),
      ),
    );
  }

  Widget _agreementCurfewCard(AppLocalizations l10n) {
    void onHeaderTap() {
      if (_curfewExpanded && _curfewEditing) return;
      setState(() => _curfewExpanded = !_curfewExpanded);
    }

    return _agreementRuleAccordionShell(
      leading: _agreementLeadingCheckbox(
        value: _rulesDraft.curfewEnabled,
        onChanged: _curfewEditing
            ? null
            : (v) => setState(() => _rulesDraft.curfewEnabled = v ?? false),
      ),
      title: Text(l10n.housingAgreementRuleCurfewTitle),
      expanded: _curfewExpanded,
      onHeaderTap: onHeaderTap,
      expandedChildren: [
        _agreementRulesActionRow(
          l10n: l10n,
          pencilEnabled: !_curfewEditing,
          onPencil: () => setState(() {
            _quietGridSnapshotForEdit = quietHoursDeepCopy(
              _rulesDraft.quietHalfHours,
            );
            _curfewEditing = true;
            _curfewExpanded = true;
          }),
          trashEnabled: false,
          onTrash: null,
          trashTooltip: l10n.housingAgreementRuleRemove,
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            l10n.housingAgreementRuleCurfewPlaceholder,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        QuietHoursWeekDayEditor(
          grid: _rulesDraft.quietHalfHours,
          uiSelectedDayIndex: _quietUiDayIndex,
          onSelectDay: (i) => setState(() => _quietUiDayIndex = i),
          editing: _curfewEditing,
          onToggleCell: _toggleQuietHalfHour,
          labelAbsolute: l10n.housingQuietHoursAbsolute,
          labelModerate: l10n.housingQuietHoursModerate,
          emptyDayLabel: l10n.housingQuietHoursNoneThisDay,
        ),
        if (_curfewEditing)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton(
                  onPressed: () => setState(() {
                    if (_quietGridSnapshotForEdit != null) {
                      quietHoursReplaceFrom(
                        _rulesDraft.quietHalfHours,
                        _quietGridSnapshotForEdit!,
                      );
                    }
                    _quietGridSnapshotForEdit = null;
                    _curfewEditing = false;
                  }),
                  child: Text(l10n.housingPlanCancel),
                ),
                FilledButton(
                  onPressed: () => setState(() {
                    _quietGridSnapshotForEdit = null;
                    _curfewEditing = false;
                  }),
                  child: Text(l10n.housingPlanSave),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _agreementEarlyWithdrawalCard(AppLocalizations l10n) {
    void onHeaderTap() {
      if (_withdrawalExpanded && _withdrawalEditing) return;
      setState(() => _withdrawalExpanded = !_withdrawalExpanded);
    }

    return _agreementRuleAccordionShell(
      leading: _agreementLeadingCheckbox(
        value: _rulesDraft.earlyWithdrawalEnabled,
        onChanged: _withdrawalEditing
            ? null
            : (v) => setState(
                () => _rulesDraft.earlyWithdrawalEnabled = v ?? false,
              ),
      ),
      title: Text(l10n.housingAgreementRuleEarlyWithdrawalTitle),
      expanded: _withdrawalExpanded,
      onHeaderTap: onHeaderTap,
      expandedChildren: [
        _agreementRulesActionRow(
          l10n: l10n,
          pencilEnabled: !_withdrawalEditing,
          onPencil: () => setState(() {
            _captureWithdrawalSnapshot();
            _withdrawalEditing = true;
            _withdrawalExpanded = true;
          }),
          trashEnabled: false,
          onTrash: null,
          trashTooltip: l10n.housingAgreementRuleRemove,
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            l10n.housingPlanWithdrawalIntro,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        if (_withdrawalEditing)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ..._earlyWithdrawalRuleContent(l10n),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: () => setState(() {
                      _restoreWithdrawalSnapshot();
                      _withdrawalEditing = false;
                    }),
                    child: Text(l10n.housingPlanCancel),
                  ),
                  FilledButton(
                    onPressed: () => setState(() => _withdrawalEditing = false),
                    child: Text(l10n.housingPlanSave),
                  ),
                ],
              ),
            ],
          )
        else
          _withdrawalReadOnlySummary(l10n),
      ],
    );
  }

  Widget _agreementBuildingRulesCard(AppLocalizations l10n) {
    void onHeaderTap() {
      if (_buildingExpanded && _buildingRulesEditing) return;
      setState(() => _buildingExpanded = !_buildingExpanded);
    }

    return _agreementRuleAccordionShell(
      leading: _agreementLeadingCheckbox(
        value: _rulesDraft.buildingRulesEnabled,
        onChanged: _buildingRulesEditing
            ? null
            : (v) =>
                  setState(() => _rulesDraft.buildingRulesEnabled = v ?? false),
      ),
      title: Text(l10n.housingAgreementRuleBuildingTitle),
      expanded: _buildingExpanded,
      onHeaderTap: onHeaderTap,
      expandedChildren: [
        _agreementRulesActionRow(
          l10n: l10n,
          pencilEnabled: !_buildingRulesEditing,
          onPencil: () => setState(() {
            _buildingEditSnapshot = _buildingRulesBody.text;
            _buildingRulesEditing = true;
            _buildingExpanded = true;
          }),
          trashEnabled: false,
          onTrash: null,
          trashTooltip: l10n.housingAgreementRuleRemove,
        ),
        if (_buildingRulesEditing)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _buildingRulesBody,
                maxLines: 8,
                minLines: 4,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: () => setState(() {
                      _buildingRulesBody.text = _buildingEditSnapshot;
                      _buildingRulesEditing = false;
                    }),
                    child: Text(l10n.housingPlanCancel),
                  ),
                  FilledButton(
                    onPressed: () =>
                        setState(() => _buildingRulesEditing = false),
                    child: Text(l10n.housingPlanSave),
                  ),
                ],
              ),
            ],
          )
        else
          _buildingRulesReadOnlyContent(l10n),
      ],
    );
  }

  Widget _customAgreementRuleTile(AppLocalizations l10n, int index) {
    final rule = _rulesDraft.customRules[index];
    final isEditing = _customRuleEditingId == rule.id;
    final expanded = _expandedCustomRuleIds.contains(rule.id);

    void onHeaderTap() {
      if (expanded && isEditing) return;
      setState(() {
        if (expanded) {
          _expandedCustomRuleIds.remove(rule.id);
        } else {
          _expandedCustomRuleIds.add(rule.id);
        }
      });
    }

    return _agreementRuleAccordionShell(
      leading: _agreementLeadingCheckbox(
        value: rule.enabled,
        onChanged: isEditing
            ? null
            : (v) => setState(() => rule.enabled = v ?? true),
      ),
      title: Text(
        rule.title.isEmpty
            ? l10n.housingAgreementRuleCustomTitleLabel
            : rule.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      expanded: expanded,
      onHeaderTap: onHeaderTap,
      expandedChildren: [
        _agreementRulesActionRow(
          l10n: l10n,
          pencilEnabled: !isEditing,
          onPencil: () => _startEditingCustomRule(rule),
          trashEnabled: !isEditing && !_rulesRemovalLocked,
          onTrash: !isEditing && !_rulesRemovalLocked
              ? () {
                  setState(() {
                    _expandedCustomRuleIds.remove(rule.id);
                    if (_customRuleEditingId == rule.id) {
                      _cancelEditingCustomRule();
                    }
                    _rulesDraft.customRules.removeAt(index);
                  });
                }
              : null,
          trashTooltip: l10n.housingAgreementRuleRemove,
        ),
        if (isEditing)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _customRuleEditTitle,
                decoration: InputDecoration(
                  labelText: l10n.housingAgreementRuleCustomTitleLabel,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _customRuleEditBody,
                decoration: InputDecoration(
                  labelText: l10n.housingAgreementRuleCustomBodyLabel,
                  alignLabelWithHint: true,
                ),
                minLines: 3,
                maxLines: 8,
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: _cancelEditingCustomRule,
                    child: Text(l10n.housingPlanCancel),
                  ),
                  FilledButton(
                    onPressed: () => _saveEditingCustomRule(l10n, rule),
                    child: Text(l10n.housingPlanSave),
                  ),
                ],
              ),
            ],
          )
        else
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: rule.body.trim().isEmpty
                ? Text(
                    l10n.housingAgreementRuleCustomBodyLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  )
                : Text(
                    rule.body,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
          ),
      ],
    );
  }

  Widget _suggestionAgreementRuleTile(
    AppLocalizations l10n, {
    required String suggestionId,
    required String title,
    required String body,
  }) {
    final expanded = _expandedSuggestionIds.contains(suggestionId);

    void onHeaderTap() {
      setState(() {
        if (expanded) {
          _expandedSuggestionIds.remove(suggestionId);
        } else {
          _expandedSuggestionIds.add(suggestionId);
        }
      });
    }

    return _agreementRuleAccordionShell(
      leading: _agreementLeadingSuggestionCheckbox(),
      title: Text(title),
      expanded: expanded,
      onHeaderTap: onHeaderTap,
      expandedChildren: [
        _agreementRulesActionRow(
          l10n: l10n,
          pencilEnabled: false,
          onPencil: null,
          trashEnabled: !_rulesRemovalLocked,
          onTrash: !_rulesRemovalLocked
              ? () => setState(() {
                  if (!_rulesDraft.dismissedSuggestionIds.contains(
                    suggestionId,
                  )) {
                    _rulesDraft.dismissedSuggestionIds.add(suggestionId);
                  }
                })
              : null,
          trashTooltip: l10n.housingAgreementRuleDismissSuggestion,
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            l10n.housingAgreementSuggestionLabel,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
        Text(body, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  Future<void> _showAddAgreementRuleDialog() async {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final d10n = AppLocalizations.of(ctx);
          return AlertDialog(
            title: Text(d10n.housingAgreementRuleAddTitle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: d10n.housingAgreementRuleCustomTitleLabel,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bodyCtrl,
                    decoration: InputDecoration(
                      labelText: d10n.housingAgreementRuleCustomBodyLabel,
                      alignLabelWithHint: true,
                    ),
                    minLines: 3,
                    maxLines: 6,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(d10n.housingPlanCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(d10n.housingPlanSave),
              ),
            ],
          );
        },
      );
      if (ok != true || !mounted) return;
      final t = titleCtrl.text.trim();
      if (t.isEmpty) return;
      setState(() {
        _rulesDraft.customRules.add(
          AgreementCustomRule(
            id: 'rule:${DateTime.now().microsecondsSinceEpoch}',
            title: t,
            body: bodyCtrl.text.trim(),
            enabled: true,
          ),
        );
      });
    } finally {
      // Dispose after the dialog route has torn down its subtree; otherwise
      // TextFields may still depend on inherited widgets while controllers are disposed.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        titleCtrl.dispose();
        bodyCtrl.dispose();
      });
    }
  }


  Widget _stepAgreementRules() {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.housingAgreementRulesIntro,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (_rulesRemovalLocked) ...[
          const SizedBox(height: 8),
          Text(
            l10n.housingAgreementRulesRemovalLockedHint,
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
        ],
        const SizedBox(height: 16),
        _agreementCurfewCard(l10n),
        _agreementEarlyWithdrawalCard(l10n),
        _agreementBuildingRulesCard(l10n),
        for (var i = 0; i < _rulesDraft.customRules.length; i++)
          _customAgreementRuleTile(l10n, i),
        if (!_rulesDraft.dismissedSuggestionIds.contains(
          kAgreementSuggestionCommonCleanliness,
        ))
          _suggestionAgreementRuleTile(
            l10n,
            suggestionId: kAgreementSuggestionCommonCleanliness,
            title: l10n.housingAgreementSuggestionCleanlinessTitle,
            body: l10n.housingAgreementSuggestionCleanlinessBody,
          ),
        if (!_rulesDraft.dismissedSuggestionIds.contains(
          kAgreementSuggestionFridgeManagement,
        ))
          _suggestionAgreementRuleTile(
            l10n,
            suggestionId: kAgreementSuggestionFridgeManagement,
            title: l10n.housingAgreementSuggestionFridgeTitle,
            body: l10n.housingAgreementSuggestionFridgeBody,
          ),
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FilledButton.tonalIcon(
            onPressed: _rulesRemovalLocked
                ? null
                : () => _showAddAgreementRuleDialog(),
            icon: const Icon(Icons.add),
            label: Text(l10n.housingAgreementRuleAdd),
          ),
        ),
      ],
    );
  }
}

class _HousingContactParticipantCard extends StatelessWidget {
  const _HousingContactParticipantCard({
    required this.title,
    required this.displayName,
    required this.avatarId,
    required this.hasContact,
    required this.avatarIconFor,
    required this.onChooseContact,
  });

  final String title;
  final String displayName;
  final String avatarId;
  final bool hasContact;
  final IconData Function(String avatarId) avatarIconFor;
  final VoidCallback onChooseContact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            if (hasContact) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(child: Icon(avatarIconFor(avatarId))),
                title: Text(displayName),
                subtitle: Text(l10n.contactsTitle),
              ),
              const SizedBox(height: 8),
            ] else
              Text(
                l10n.housingPlanContactRequired,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            FilledButton.icon(
              icon: const Icon(Icons.contacts),
              label: Text(
                hasContact
                    ? l10n.housingPlanChangeContactAction
                    : l10n.housingPlanChooseContactAction,
              ),
              onPressed: onChooseContact,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummarySnapshot {
  const _SummarySnapshot({
    required this.participants,
    required this.lines,
    required this.agr,
    required this.ratios,
    required this.proposalPkg,
    required this.canResendPendingProposal,
  });

  final List<Participant> participants;
  final List<PlanLine> lines;
  final Agreement? agr;
  final List<PlanRatio> ratios;
  final ProposalPackage? proposalPkg;
  final bool canResendPendingProposal;
}

class _SummaryView extends StatefulWidget {
  const _SummaryView({
    super.key,
    required this.db,
    required this.planId,
    required this.prefs,
    required this.reloadToken,
    required this.avatarIcons,
    required this.onEditPlan,
    required this.onInvite,
    required this.onResendProposal,
    required this.onDestroy,
  });

  final AppDatabase db;
  final String planId;
  final AppPreferences prefs;
  final int reloadToken;
  final List<IconData> avatarIcons;

  final VoidCallback onEditPlan;
  final VoidCallback onInvite;
  final VoidCallback onResendProposal;
  final VoidCallback onDestroy;

  @override
  State<_SummaryView> createState() => _SummaryViewState();
}

class _SummaryViewState extends State<_SummaryView> {
  Future<_SummarySnapshot>? _snapshotFuture;
  int _focusedParticipantIndex = 0;
  bool _hadPendingProposal = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _snapshotFuture = _load();
    _snapshotFuture!.then(_scheduleRefreshTimerIfNeeded);
  }

  /// Polls relay + reloads only while a proposal is pending (responses may arrive).
  /// Draft plan summary (not submitted) does not need periodic UI refresh.
  void _scheduleRefreshTimerIfNeeded(_SummarySnapshot data) {
    if (!mounted) return;
    _refreshTimer?.cancel();
    if (data.proposalPkg?.pendingRevisionId == null) return;
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      await HandshakeOrchestrator.maybeInstance?.pollSteadyStateInboxes();
      if (!mounted) return;
      setState(() {
        _snapshotFuture = _load();
      });
      _snapshotFuture!.then(_scheduleRefreshTimerIfNeeded);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _SummaryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadToken != widget.reloadToken) {
      _snapshotFuture = _load();
    }
  }

  Future<_SummarySnapshot> _load() async {
    final r = await Future.wait([
      widget.db.listParticipants(),
      widget.db.listPlanLines(widget.planId),
      widget.db.getAgreementForPlan(widget.planId),
      widget.db.listPlanRatios(widget.planId),
      (widget.db.select(
        widget.db.proposalPackages,
      )..where((t) => t.planId.equals(widget.planId))).getSingleOrNull(),
    ]);
    final canResend = await PlanAgreementProposalService(
      widget.db,
    ).canResendPendingProposal(widget.planId);
    return _SummarySnapshot(
      participants: r[0] as List<Participant>,
      lines: r[1] as List<PlanLine>,
      agr: r[2] as Agreement?,
      ratios: r[3] as List<PlanRatio>,
      proposalPkg: r[4] as ProposalPackage?,
      canResendPendingProposal: canResend,
    );
  }

  IconData _iconForAvatar(String avatarId) {
    if (!avatarId.startsWith('mdi:')) return MdiIcons.account;
    final idx = int.tryParse(avatarId.split(':').last);
    if (idx == null || idx < 0 || idx >= widget.avatarIcons.length) {
      return MdiIcons.account;
    }
    return widget.avatarIcons[idx];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_SummarySnapshot>(
      future: _snapshotFuture,
      builder: (context, AsyncSnapshot<_SummarySnapshot> snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                AppLocalizations.of(context).housingPlanLoadError(
                  '${snap.error}',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snap.data!;
        final l10n = AppLocalizations.of(context);
        int rosterOrder(String id) {
          if (id.endsWith(':self')) return -1;
          final tail = id.split(':p').last;
          return int.tryParse(tail) ?? 999;
        }

        final roster =
            data.participants
                .where(
                  (p) =>
                      p.id == '${widget.planId}:self' ||
                      p.id.startsWith('${widget.planId}:p'),
                )
                .toList()
              ..sort((a, b) => rosterOrder(a.id).compareTo(rosterOrder(b.id)));
        final lines = data.lines;
        final agr = data.agr;
        final ratios = data.ratios;
        final hasPending = data.proposalPkg?.pendingRevisionId != null;
        if (hasPending) {
          _hadPendingProposal = true;
        } else if (_hadPendingProposal) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.of(context).pushReplacement<void, void>(
              MaterialPageRoute<void>(
                builder: (_) => HousingArchiveEntryScreen(
                  prefs: widget.prefs,
                  planId: widget.planId,
                ),
              ),
            );
          });
          return const Center(child: CircularProgressIndicator());
        }
        if (agr == null) {
          return Center(child: Text(l10n.housingPlanSummaryMissingAgreement));
        }

        var planMonthlyTotalMinor = 0;
        for (final line in lines) {
          planMonthlyTotalMinor += PlanProjection.unitMinor(line);
        }

        final sortedLines = [...lines]
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        final rosterIds = roster.map((e) => e.id).toList();
        final focusIdx = rosterIds.isEmpty
            ? 0
            : _focusedParticipantIndex.clamp(0, rosterIds.length - 1);

        int participantShareMinor(String participantId) {
          final idx = rosterIds.indexOf(participantId);
          if (idx < 0) return 0;
          var participantMonthlyMinor = 0;
          for (final line in sortedLines) {
            final basis = PlanProjection.unitMinor(line);
            if (basis <= 0) continue;
            final ws = <int>[
              for (final rid in rosterIds)
                ratios
                    .where(
                      (r) => r.lineId == line.id && r.participantId == rid,
                    )
                    .fold<int>(0, (a, r) => a + r.weight),
            ];
            participantMonthlyMinor += splitMinorByWeights(basis, ws)[idx];
          }
          return participantMonthlyMinor;
        }

        final focusedParticipant = roster.isEmpty ? null : roster[focusIdx];
        final displayCurrency = displayCurrencyCodeForPlan(widget.prefs, lines);
        final sunSlices = focusedParticipant == null
            ? <InviteSunburstSlice>[]
            : buildInviteSunburstSlices(
                lines: lines,
                groups: const [],
                ratios: ratios,
                participantIdsOrdered: rosterIds,
                participantId: focusedParticipant.id,
                l10n: l10n,
                displayCurrency: displayCurrency,
              );

        const dateIso = 'YYYY-MM-DD';
        final dateRangeLine =
            '${formatPreferenceDate(agr.periodStart, dateIso)}${l10n.housingInviteDateRangeSeparator}${formatPreferenceDate(agr.periodEnd, dateIso)}';

        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    l10n.housingInviteProposalIntroTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Divider(height: 32),
                  Center(
                    child: Text(
                      l10n.housingInviteHousingAgreementTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      dateRangeLine,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      formatContractCalendarDuration(
                        agr.periodStart,
                        agr.periodEnd,
                        l10n,
                      ),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.housingInviteParticipantsSectionTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                    const SizedBox(height: 8),
                    if (roster.isEmpty)
                      Text(
                        l10n.housingPlanSummaryMissingParticipants,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (var i = 0; i < roster.length; i++)
                            ChoiceChip(
                              selected: focusIdx == i,
                              label: Text(roster[i].displayName),
                              onSelected: (selected) {
                                if (!selected) return;
                                setState(() => _focusedParticipantIndex = i);
                              },
                            ),
                        ],
                      ),
                    const SizedBox(height: 20),
                    if (focusedParticipant != null)
                      HousingInviteSunburstChart(
                        l10n: l10n,
                        slices: sunSlices,
                        participantName: focusedParticipant.displayName,
                      ),
                    if (sortedLines.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: FilledButton.tonal(
                          onPressed: roster.isEmpty
                              ? null
                              : () {
                                  final dateFmt =
                                      widget.prefs.dateFormat.trim().isEmpty
                                      ? 'YYYY-MM-DD'
                                      : widget.prefs.dateFormat.trim();
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (context) =>
                                          HousingProposalExpensesDetailScreen(
                                        db: widget.db,
                                        planId: widget.planId,
                                        participantIds: rosterIds,
                                        participantNames: [
                                          for (final p in roster)
                                            p.displayName,
                                        ],
                                        defaultCurrency: displayCurrency,
                                        dateFormat: dateFmt,
                                      ),
                                    ),
                                  );
                                },
                          child: Text(l10n.housingInviteViewExpensesDetail),
                        ),
                      ),
                    ],
                    if (sortedLines.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          l10n.housingPlanAddExpensesFirst,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color:
                                    Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    const SizedBox(height: 20),
                  for (var i = 0; i < roster.length; i++) ...[
                    Builder(
                      builder: (context) {
                        final p = roster[i];
                        final participantMonthlyMinor = participantShareMinor(
                          p.id,
                        );
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  child: Icon(_iconForAvatar(p.avatarId)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              p.displayName,
                                              style: Theme.of(
                                                context,
                                              ).textTheme.titleMedium,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          RationalPercentText(
                                            shareMinor: participantMonthlyMinor,
                                            totalMinor: planMonthlyTotalMinor,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        l10n.housingPlanSummaryMonthlyTotal,
                                        textAlign: TextAlign.center,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleSmall,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        formatMinorAsMoney(
                                          context,
                                          participantMonthlyMinor,
                                          displayCurrency,
                                        ),
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                0,
                16,
                16 + MediaQuery.viewPaddingOf(context).bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (hasPending) ...[
                    FilledButton.tonal(
                      onPressed: () => showHousingInvitationStatusDialog(
                        context,
                        db: widget.db,
                        planId: widget.planId,
                        prefs: widget.prefs,
                        onAfterResend: () {
                          if (!mounted) return;
                          setState(() {
                            _snapshotFuture = _load();
                          });
                        },
                      ),
                      child: Text(l10n.housingInviteInvitationStatusAction),
                    ),
                    if (data.canResendPendingProposal) ...[
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: widget.onResendProposal,
                        child: Text(l10n.housingInviteResendProposalAction),
                      ),
                    ],
                  ] else ...[
                    FilledButton.tonal(
                      onPressed: widget.onEditPlan,
                      child: Text(l10n.housingPlanSummaryEditPlan),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: widget.onInvite,
                      child: Text(l10n.housingPlanSummaryInvite),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: widget.onDestroy,
                      child: Text(l10n.housingPlanSummaryDestroy),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

