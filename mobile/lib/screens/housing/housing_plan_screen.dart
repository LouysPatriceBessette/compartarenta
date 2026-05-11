import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import '../../db/app_database.dart';
import '../../housing/agreement_rules_json.dart';
import '../../housing/projection/plan_projection.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../util/display_date.dart';

sealed class _SplitListEntry {}

final class _SplitListGroup extends _SplitListEntry {
  _SplitListGroup(this.group, this.memberLines);
  final PlanGroup group;
  final List<PlanLine> memberLines;
}

/// Uncategorized lines (no group, or unknown group id).
final class _SplitUncategorized extends _SplitListEntry {
  _SplitUncategorized(this.lines, {this.showHeading = true});
  final List<PlanLine> lines;
  final bool showHeading;
}

/// Housing plan setup: vertical stepper (1–6) then summary.
class HousingPlanScreen extends StatefulWidget {
  const HousingPlanScreen({super.key, required this.prefs});

  final AppPreferences prefs;

  @override
  State<HousingPlanScreen> createState() => _HousingPlanScreenState();
}

class _HousingPlanScreenState extends State<HousingPlanScreen> {
  late final AppDatabase _db = AppDatabase();

  static const _planId = 'housing:default';
  static const _agreementId = 'agreement:housing:default';

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

  static const int _housingPlanStepCount = 6;

  List<String> _housingStepTitles(AppLocalizations l10n) => [
        l10n.housingPlanStepParticipants,
        l10n.housingPlanStepPlanDates,
        l10n.housingPlanStepExpenseCategories,
        l10n.housingPlanStepExpenses,
        l10n.housingPlanStepSplit,
        l10n.housingPlanStepAgreementRules,
      ];

  AppLocalizations _lookupAppLocalizationsSync() {
    final loc = WidgetsBinding.instance.platformDispatcher.locale;
    final code = loc.languageCode;
    if (code == 'fr') return lookupAppLocalizations(const Locale('fr'));
    if (code == 'es') return lookupAppLocalizations(const Locale('es'));
    return lookupAppLocalizations(const Locale('en'));
  }

  /// 0–5 = wizard steps; summary when true.
  bool _showSummary = false;
  int _stepIndex = 0;
  int _linesEpoch = 0;
  int _linesFutureSerial = -1;
  Future<List<PlanLine>>? _cachedPlanLinesFuture;

  int _groupsEpoch = 0;
  int _groupsFutureSerial = -1;
  Future<List<PlanGroup>>? _cachedPlanGroupsFuture;

  /// Other people on the plan (not including the signed-in profile).
  int _otherParticipantCount = 1;
  /// Which co-participant form is shown when [_otherParticipantCount] > 1.
  int _coEditorIndex = 0;

  final List<TextEditingController> _nameControllers = [];
  final List<String> _avatarIds = [];

  DateTime? _periodStart;
  DateTime? _periodEnd;

  int _ratioParticipantIndex = 0;

  /// Selected participant when editing per-person withdrawal rules (same order as Split).
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

  final TextEditingController _curfewNotes = TextEditingController();
  bool _curfewExpanded = false;
  bool _curfewEditing = false;
  String _curfewEditSnapshot = '';

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

  final Map<String, TextEditingController> _shareAmountControllers = {};
  final Map<String, int> _draftRatioWeightsBps = {};
  /// Minor units to show after a manual amount commit when the persisted
  /// weight grid cannot round-trip to the typed cents exactly.
  final Map<String, int> _shareAmountMinorOverride = {};

  late final Future<void> _boot;

  @override
  void initState() {
    super.initState();
    _resizeCoParticipantEditors(_otherParticipantCount);
    _resizeWithdrawalEditors(1 + _otherParticipantCount);
    _boot = _loadFromDb();
  }

  @override
  void dispose() {
    for (final c in _nameControllers) {
      c.dispose();
    }
    for (final c in _perParticipantNotice) {
      c.dispose();
    }
    for (final c in _perParticipantPenalty) {
      c.dispose();
    }
    for (final c in _shareAmountControllers.values) {
      c.dispose();
    }
    _shareAmountControllers.clear();
    _globalNotice.dispose();
    _globalPenalty.dispose();
    _buildingRulesBody.dispose();
    _curfewNotes.dispose();
    _customRuleEditTitle?.dispose();
    _customRuleEditBody?.dispose();
    _db.close();
    super.dispose();
  }

  TextEditingController _shareAmountControllerFor(String lineId, String participantId) {
    final key = '$lineId:$participantId';
    return _shareAmountControllers.putIfAbsent(key, () => TextEditingController());
  }

  /// Major units string with exactly two decimals; invalid / NaN → `0.00`.
  String _formatMoneyMajorTwoDecimals(String raw) {
    final t = raw.trim().replaceAll(',', '.');
    if (t.isEmpty) return '0.00';
    final v = double.tryParse(t);
    if (v == null || v.isNaN) return '0.00';
    return v.toStringAsFixed(2);
  }

  /// Horizontal inset and track width matching [Slider] / [BaseSliderTrackShape.getPreferredRect].
  (double leftInset, double trackWidth) _sliderTrackHorizontalMetrics(
    BuildContext context,
    double parentWidth, {
    required bool sliderInteractive,
  }) {
    final st = SliderTheme.of(context);
    final thumbShape = st.thumbShape;
    final overlayShape = st.overlayShape;
    if (thumbShape == null || overlayShape == null) {
      const pad = 12.0;
      return (pad, math.max(0.0, parentWidth - 2 * pad));
    }
    final discrete = false;
    final thumbW = thumbShape.getPreferredSize(sliderInteractive, discrete).width;
    final overlayW = overlayShape.getPreferredSize(sliderInteractive, discrete).width;
    if (st.padding != null) {
      return (0, math.max(0.0, parentWidth));
    }
    final leftInset = math.max(overlayW / 2, thumbW / 2);
    final trackWidth = parentWidth - math.max(thumbW, overlayW);
    return (leftInset, math.max(0.0, trackWidth));
  }

  EdgeInsets _sliderThemeOuterPadding(BuildContext context) {
    return SliderTheme.of(context).padding?.resolve(Directionality.of(context)) ?? EdgeInsets.zero;
  }

  double _snapToDevicePixels(BuildContext context, double logicalX) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return (logicalX * dpr).round() / dpr;
  }

  /// Picks a weight in `[0, assignable]` that minimizes
  /// `|(basisMinor * w / 10000).round() - targetMinor|`.
  int _bestWeightBpsForShareMinor(int targetMinor, int basisMinor, int assignable) {
    if (basisMinor <= 0 || assignable <= 0) return 0;
    var bestW = 0;
    var bestErr = 1 << 30;
    for (var w = 0; w <= assignable; w++) {
      final got = (basisMinor * w / 10000).round();
      final err = (got - targetMinor).abs();
      if (err < bestErr) {
        bestErr = err;
        bestW = w;
      }
    }
    return bestW;
  }

  Future<void> _commitShareAmountTextField(
    PlanLine line,
    List<String> pids,
    int participantIndex,
    int basisMinor,
    int assignable,
    String controllerKey,
  ) async {
    final ctrl = _shareAmountControllers[controllerKey];
    if (ctrl == null) return;
    final formatted = _formatMoneyMajorTwoDecimals(ctrl.text);
    ctrl.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    final major = double.tryParse(formatted.replaceAll(',', '.')) ?? 0.0;
    var minor = (major * 100).round();
    final maxShareMinor = basisMinor <= 0 ? 0 : (basisMinor * assignable / 10000).round();
    minor = minor.clamp(0, maxShareMinor);
    final display = (minor / 100).toStringAsFixed(2);
    if (display != formatted) {
      ctrl.value = TextEditingValue(
        text: display,
        selection: TextSelection.collapsed(offset: display.length),
      );
    }
    final wClamped = _bestWeightBpsForShareMinor(minor, basisMinor, assignable);
    await _setRatioWeightBps(line, pids, participantIndex, wClamped);
    if (mounted) {
      setState(() {
        _shareAmountMinorOverride[controllerKey] = minor;
      });
    }
  }

  String _shareSplitControllerKeyForGroup(String groupId, String participantId) =>
      'g:$groupId:$participantId';

  TextEditingController _shareAmountControllerForGroup(String groupId, String participantId) {
    final key = _shareSplitControllerKeyForGroup(groupId, participantId);
    return _shareAmountControllers.putIfAbsent(key, () => TextEditingController());
  }

  Future<void> _commitShareGroupAmountTextField(
    PlanGroup group,
    List<String> pids,
    int participantIndex,
    int basisMinor,
    int assignable,
    String controllerKey,
  ) async {
    final ctrl = _shareAmountControllers[controllerKey];
    if (ctrl == null) return;
    final formatted = _formatMoneyMajorTwoDecimals(ctrl.text);
    ctrl.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    final major = double.tryParse(formatted.replaceAll(',', '.')) ?? 0.0;
    var minor = (major * 100).round();
    final maxShareMinor = basisMinor <= 0 ? 0 : (basisMinor * assignable / 10000).round();
    minor = minor.clamp(0, maxShareMinor);
    final display = (minor / 100).toStringAsFixed(2);
    if (display != formatted) {
      ctrl.value = TextEditingValue(
        text: display,
        selection: TextSelection.collapsed(offset: display.length),
      );
    }
    final wClamped = _bestWeightBpsForShareMinor(minor, basisMinor, assignable);
    await _setGroupRatioWeightBps(group, pids, participantIndex, wClamped);
    if (mounted) {
      setState(() {
        _shareAmountMinorOverride[controllerKey] = minor;
      });
    }
  }

  int _groupBasisMinor(List<PlanLine> memberLines) =>
      memberLines.fold<int>(0, (a, l) => a + _splitBasisMinor(l));

  List<double> _splitTickFractionsForParticipantCount(int n) {
    final s = <double>{};
    void add(int a, int b) => s.add(a / b);

    add(1, 2);
    add(1, 3);
    add(2, 3);
    add(1, 4);
    add(3, 4);

    if (n >= 5) {
      add(1, 5);
      add(2, 5);
      add(3, 5);
      add(4, 5);
    }
    if (n >= 6) {
      add(1, 6);
      add(5, 6);
    }
    if (n >= 7) {
      add(1, 7);
      add(2, 7);
      add(3, 7);
      add(4, 7);
      add(5, 7);
      add(6, 7);
    }
    if (n >= 8) {
      add(1, 8);
      add(3, 8);
      add(5, 8);
      add(7, 8);
    }

    final out = s.toList()..sort();
    return out;
  }

  double _nearestTick(double v, List<double> ticks) {
    var best = ticks.first;
    var bestD = (v - best).abs();
    for (final t in ticks.skip(1)) {
      final d = (v - t).abs();
      if (d < bestD) {
        bestD = d;
        best = t;
      }
    }
    return best;
  }

  Future<void> _setRatioWeightBps(
    PlanLine line,
    List<String> pids,
    int participantIndex,
    int newW,
  ) async {
    final last = pids.last;
    if (participantIndex >= pids.length - 1) return;

    var assignedBefore = 0;
    for (var i = 0; i < participantIndex; i++) {
      assignedBefore += await _ratioWeight(line.id, pids[i]);
    }
    final assignable = (10000 - assignedBefore).clamp(0, 10000);
    final clampedW = newW.clamp(0, assignable);
    final pid = pids[participantIndex];
    await _db.upsertPlanRatio(
      PlanRatiosCompanion.insert(
        id: 'ratio:$_planId:${line.id}:$pid',
        planId: _planId,
        participantId: pid,
        lineId: drift.Value(line.id),
        groupId: const drift.Value.absent(),
        weight: clampedW,
        createdAt: DateTime.now().toUtc(),
      ),
    );

    var sumExceptLast = 0;
    for (var i = 0; i < pids.length - 1; i++) {
      sumExceptLast += await _ratioWeight(line.id, pids[i]);
    }
    final lastW = (10000 - sumExceptLast).clamp(0, 10000);
    await _db.upsertPlanRatio(
      PlanRatiosCompanion.insert(
        id: 'ratio:$_planId:${line.id}:$last',
        planId: _planId,
        participantId: last,
        lineId: drift.Value(line.id),
        groupId: const drift.Value.absent(),
        weight: lastW,
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<void> _setGroupRatioWeightBps(
    PlanGroup group,
    List<String> pids,
    int participantIndex,
    int newW,
  ) async {
    final last = pids.last;
    if (participantIndex >= pids.length - 1) return;

    var assignedBefore = 0;
    for (var i = 0; i < participantIndex; i++) {
      assignedBefore += await _ratioWeightGroup(group.id, pids[i]);
    }
    final assignable = (10000 - assignedBefore).clamp(0, 10000);
    final clampedW = newW.clamp(0, assignable);
    final pid = pids[participantIndex];
    await _db.upsertPlanRatio(
      PlanRatiosCompanion.insert(
        id: 'ratio:$_planId:grp:${group.id}:$pid',
        planId: _planId,
        participantId: pid,
        lineId: const drift.Value.absent(),
        groupId: drift.Value(group.id),
        weight: clampedW,
        createdAt: DateTime.now().toUtc(),
      ),
    );

    var sumExceptLast = 0;
    for (var i = 0; i < pids.length - 1; i++) {
      sumExceptLast += await _ratioWeightGroup(group.id, pids[i]);
    }
    final lastW = (10000 - sumExceptLast).clamp(0, 10000);
    await _db.upsertPlanRatio(
      PlanRatiosCompanion.insert(
        id: 'ratio:$_planId:grp:${group.id}:$last',
        planId: _planId,
        participantId: last,
        lineId: const drift.Value.absent(),
        groupId: drift.Value(group.id),
        weight: lastW,
        createdAt: DateTime.now().toUtc(),
      ),
    );
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
    }
    while (_nameControllers.length > n) {
      _nameControllers.removeLast().dispose();
      _avatarIds.removeLast();
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

  Future<void> _ensurePlanShell() async {
    final l10n = _lookupAppLocalizationsSync();
    await _db.upsertPlan(
      PlansCompanion.insert(
        id: _planId,
        type: 'housing',
        createdAt: DateTime.now().toUtc(),
        title: drift.Value(l10n.homeHousingPlan),
        currency: drift.Value('CAD'),
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

  Future<void> _loadFromDb() async {
    await _ensurePlanShell();
    _shareAmountMinorOverride.clear();
    final roster = await _db.listParticipants();
    final coRows = roster.where((p) => p.id.startsWith('$_planId:p')).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    if (coRows.isNotEmpty) {
      _otherParticipantCount = coRows.length.clamp(1, 7);
      _resizeParticipantEditors(_otherParticipantCount);
      for (var i = 0; i < coRows.length; i++) {
        _nameControllers[i].text = coRows[i].displayName;
        _avatarIds[i] = coRows[i].avatarId;
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
        final map = jsonDecode(agr.withdrawalPerParticipantJson) as Map<String, dynamic>?;
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
      _curfewNotes.text = _rulesDraft.curfewNotes;
    }

    _rulesRemovalLocked = await _db.planHasActiveAcceptedProposal(_planId);

    if (widget.prefs.housingDefaultPlanSummaryReached) {
      _showSummary = true;
    }
  }

  Future<List<PlanLine>> _planLinesFuture() {
    if (_linesFutureSerial != _linesEpoch) {
      _linesFutureSerial = _linesEpoch;
      _cachedPlanLinesFuture = _db.listPlanLines(_planId);
    }
    return _cachedPlanLinesFuture!;
  }

  Future<List<PlanGroup>> _planGroupsFuture() {
    if (_groupsFutureSerial != _groupsEpoch) {
      _groupsFutureSerial = _groupsEpoch;
      _cachedPlanGroupsFuture = _db.listPlanGroups(_planId);
    }
    return _cachedPlanGroupsFuture!;
  }

  bool _stepDone(int i) {
    if (_showSummary) return true;
    return i < _stepIndex;
  }

  bool get _anyAgreementRuleEditing =>
      _curfewEditing || _withdrawalEditing || _buildingRulesEditing || _customRuleEditingId != null;

  /// While editing agreement rule content, block wizard navigation on step 6.
  bool get _agreementRulesStepFooterLocked => _stepIndex == 5 && _anyAgreementRuleEditing;

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
    e = DateTime(sd.year, sd.month, sd.day).add(const Duration(days: 1)).toUtc();
    _periodEnd = e;
  }

  DateTime _endDatePickerFirstDate() {
    if (_periodStart == null) return DateTime(2020);
    return DateUtils.dateOnly(_periodStart!.toLocal()).add(const Duration(days: 1));
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
          if (_nameControllers[j].text.trim().isEmpty) return false;
          if (_avatarIds[j].isEmpty) return false;
        }
        return true;
      case 1:
        return _datesStepValid();
      case 2:
        return true; // categories are optional (see expense plan specs)
      case 3:
        return true; // validated async: at least one expense line
      case 4:
        return true; // validated async: ratios sum to 100%
      case 5:
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

  Future<void> _unassignLinesAndDeletePlanGroup(String groupId) async {
    await (_db.update(_db.planLines)..where((t) => t.groupId.equals(groupId))).write(
      PlanLinesCompanion(groupId: const drift.Value(null)),
    );
    await (_db.delete(_db.planGroups)..where((t) => t.id.equals(groupId))).go();
  }

  Future<void> _editPlanCategory(PlanGroup? existing) async {
    final result = await showDialog<_CategoryDraft>(
      context: context,
      builder: (context) => _CategoryEditorDialog(initial: existing),
    );
    if (result == null) return;
    final now = DateTime.now().toUtc();
    final id = existing?.id ?? 'group:${now.microsecondsSinceEpoch}';
    await _db.upsertPlanGroup(
      PlanGroupsCompanion(
        id: drift.Value(id),
        planId: drift.Value(_planId),
        title: drift.Value(result.title),
        description: drift.Value(result.description),
        createdAt: drift.Value(existing?.createdAt ?? now),
      ),
    );
  }

  Future<bool> _validateStep2Expenses() async {
    final lines = await _db.listPlanLines(_planId);
    if (lines.isEmpty) return false;
    for (final l in lines) {
      if (l.isRecurring &&
          (l.recurrenceDayOfMonth == null ||
              l.recurrenceDayOfMonth! < 1 ||
              l.recurrenceDayOfMonth! > 31)) {
        return false;
      }
      if (l.amountUsesRange) {
        final mn = l.minAmountMinor;
        final mx = l.maxAmountMinor;
        if (mn == null || mx == null || mn > mx) return false;
      } else {
        if (l.amountMinor == null) return false;
      }
    }
    return true;
  }

  Future<bool> _validateStep3Ratios(
    List<PlanLine> lines,
    List<PlanGroup> groups,
    List<String> pids,
  ) async {
    final ratios = await _db.listPlanRatios(_planId);
    final knownGroupIds = groups.map((g) => g.id).toSet();

    for (final g in groups) {
      final members = lines.where((l) => l.groupId == g.id).toList();
      if (members.isEmpty) continue;
      var sum = 0;
      for (final pid in pids) {
        final w = ratios
            .where((r) => r.groupId == g.id && r.participantId == pid)
            .fold<int>(0, (a, r) => a + r.weight);
        sum += w;
      }
      if (sum != 10000) return false;
    }

    for (final line in lines) {
      final gid = line.groupId;
      if (gid != null && knownGroupIds.contains(gid)) continue;
      var sum = 0;
      for (final pid in pids) {
        final w = ratios
            .where((r) => r.lineId == line.id && r.participantId == pid)
            .fold<int>(0, (a, r) => a + r.weight);
        sum += w;
      }
      if (sum != 10000) return false;
    }
    return true;
  }

  Future<void> _persistParticipants() async {
    final selfName = widget.prefs.displayName.trim();
    final selfAvatar = widget.prefs.avatarId.trim();
    await _db.upsertParticipant(
      ParticipantsCompanion.insert(
        id: _selfParticipantId,
        displayName: selfName.isEmpty ? _lookupAppLocalizationsSync().housingPlanYou : selfName,
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
        ),
      );
    }
    final all = await _db.listParticipants();
    for (final p in all) {
      if (p.id.startsWith('$_planId:p')) {
        final idx = int.tryParse(p.id.split(':p').last);
        if (idx == null || idx >= _otherParticipantCount) {
          await (_db.delete(_db.participants)..where((t) => t.id.equals(p.id))).go();
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
        withdrawalPerParticipantJson: drift.Value(cur.withdrawalPerParticipantJson),
        agreementRulesJson: drift.Value(cur.agreementRulesJson),
        version: drift.Value(cur.version),
        createdAt: drift.Value(cur.createdAt),
      ),
    );
  }

  Future<void> _initRatiosIfNeeded() async {
    final lines = await _db.listPlanLines(_planId);
    final groups = await _db.listPlanGroups(_planId);
    final pids = _allParticipantIds();
    if (pids.length < 2) return;
    final existing = await _db.listPlanRatios(_planId);
    final knownGroupIds = groups.map((g) => g.id).toSet();
    final last = pids.last;

    for (final g in groups) {
      final members = lines.where((l) => l.groupId == g.id).toList();
      if (members.isEmpty) continue;
      var sum = 0;
      for (final pid in pids) {
        sum += existing
            .where((r) => r.groupId == g.id && r.participantId == pid)
            .fold<int>(0, (a, r) => a + r.weight);
      }
      if (sum == 10000) continue;
      await (_db.delete(_db.planRatios)..where((t) => t.groupId.equals(g.id))).go();
      for (var i = 0; i < pids.length - 1; i++) {
        await _db.upsertPlanRatio(
          PlanRatiosCompanion.insert(
            id: 'ratio:$_planId:grp:${g.id}:${pids[i]}',
            planId: _planId,
            participantId: pids[i],
            lineId: const drift.Value.absent(),
            groupId: drift.Value(g.id),
            weight: 0,
            createdAt: DateTime.now().toUtc(),
          ),
        );
      }
      await _db.upsertPlanRatio(
        PlanRatiosCompanion.insert(
          id: 'ratio:$_planId:grp:${g.id}:$last',
          planId: _planId,
          participantId: last,
          lineId: const drift.Value.absent(),
          groupId: drift.Value(g.id),
          weight: 10000,
          createdAt: DateTime.now().toUtc(),
        ),
      );
    }

    for (final line in lines) {
      final gid = line.groupId;
      if (gid != null && knownGroupIds.contains(gid)) {
        await (_db.delete(_db.planRatios)..where((t) => t.lineId.equals(line.id))).go();
        continue;
      }
      final lineSum = existing
          .where((r) => r.lineId == line.id)
          .fold<int>(0, (a, r) => a + r.weight);
      if (lineSum == 10000) continue;
      await (_db.delete(_db.planRatios)..where((t) => t.lineId.equals(line.id))).go();
      for (var i = 0; i < pids.length - 1; i++) {
        await _db.upsertPlanRatio(
          PlanRatiosCompanion.insert(
            id: 'ratio:$_planId:${line.id}:${pids[i]}',
            planId: _planId,
            participantId: pids[i],
            lineId: drift.Value(line.id),
            groupId: const drift.Value.absent(),
            weight: 0,
            createdAt: DateTime.now().toUtc(),
          ),
        );
      }
      await _db.upsertPlanRatio(
        PlanRatiosCompanion.insert(
          id: 'ratio:$_planId:${line.id}:$last',
          planId: _planId,
          participantId: last,
          lineId: drift.Value(line.id),
          groupId: const drift.Value.absent(),
          weight: 10000,
          createdAt: DateTime.now().toUtc(),
        ),
      );
    }
  }

  Future<int> _ratioWeightGroup(String groupId, String participantId) async {
    final rows = await _db.listPlanRatios(_planId);
    return rows
        .where((r) => r.groupId == groupId && r.participantId == participantId)
        .fold<int>(0, (a, r) => a + r.weight);
  }

  Future<int> _ratioWeight(String lineId, String participantId) async {
    final rows = await _db.listPlanRatios(_planId);
    return rows
        .where((r) => r.lineId == lineId && r.participantId == participantId)
        .fold<int>(0, (a, r) => a + r.weight);
  }

  /// Amount this line contributes to **monthly** split math (one month for recurring).
  int _splitBasisMinor(PlanLine line) => PlanProjection.unitMinor(line);

  String _money2FromMinor(int minor) => (minor / 100).toStringAsFixed(2);

  Future<void> _persistAgreementRules() async {
    final cur = await _db.getAgreementForPlan(_planId);
    if (cur == null) throw StateError('No agreement row for $_planId');

    _rulesDraft.curfewNotes = _curfewNotes.text;
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
            'minNoticeDays': int.tryParse(_perParticipantNotice[i].text.trim()) ?? 0,
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
          _rulesDraft.earlyWithdrawalEnabled && _withdrawalSameForAll ? notice : 0,
        ),
        penaltyMinor: drift.Value(
          _rulesDraft.earlyWithdrawalEnabled && _withdrawalSameForAll ? penalty : 0,
        ),
        clauses: drift.Value(_buildingRulesBody.text),
        withdrawalSameForAll: drift.Value(_withdrawalSameForAll ? 'true' : 'false'),
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

  Future<void> _onDestroyPlan() async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.housingPlanDestroyTitle),
        content: Text(l10n.housingPlanDestroyBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.housingPlanCancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.housingPlanDestroyConfirm)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _db.deletePlanRelatedData(_planId);
    await widget.prefs.setHousingDefaultPlanSummaryReached(false);
    await _ensurePlanShell();
    setState(() {
      _showSummary = false;
      _stepIndex = 0;
      _ratioParticipantIndex = 0;
      _withdrawalParticipantIndex = 0;
      _shareAmountMinorOverride.clear();
    });
    await _loadFromDb();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.housingPlanRemovedSnackbar)),
      );
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
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
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
              db: _db,
              planId: _planId,
              avatarIcons: _avatarIcons,
              shareMinorOverrides: _shareAmountMinorOverride,
              onEditPlan: () => setState(() {
                _showSummary = false;
                _stepIndex = 0;
              }),
              onInvite: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.housingPlanInviteComingSoon)),
                );
              },
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
                                    tooltip: l10n.housingPlanFewerParticipantsTooltip,
                                    onPressed: _otherParticipantCount <= 1
                                        ? null
                                        : () => _applyOtherParticipantCount(_otherParticipantCount - 1),
                                    icon: const Icon(Icons.remove),
                                  ),
                                  Expanded(
                                    child: Text(
                                      l10n.housingPlanParticipantsCount(1 + _otherParticipantCount),
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.headlineSmall,
                                    ),
                                  ),
                                  IconButton.filledTonal(
                                    tooltip: l10n.housingPlanMoreParticipantsTooltip,
                                    onPressed: _otherParticipantCount >= 7
                                        ? null
                                        : () => _applyOtherParticipantCount(_otherParticipantCount + 1),
                                    icon: const Icon(Icons.add),
                                  ),
                                ],
                              ),
                            )
                          else
                            Expanded(
                              child: Text(
                                _housingStepTitles(l10n)[_stepIndex],
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                            ),
                          if (_stepIndex == 2)
                            IconButton.filledTonal(
                              tooltip: l10n.housingPlanAddCategoryTooltip,
                              onPressed: () async {
                                await _editPlanCategory(null);
                                if (mounted) setState(() => _groupsEpoch++);
                              },
                              icon: const Icon(Icons.add),
                            ),
                          if (_stepIndex == 3)
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
                    Expanded(
                      child: _buildStepBody(),
                    ),
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
                                    final messenger = ScaffoldMessenger.of(context);
                                    try {
                                      if (_stepIndex == 0) await _persistParticipants();
                                      if (_stepIndex == 1) await _persistPeriod();
                                      if (_stepIndex == 3) {
                                        if (!await _validateStep2Expenses()) {
                                          if (mounted) {
                                            messenger.showSnackBar(
                                              SnackBar(
                                                content: Text(l10n.housingPlanExpenseValidationMessage),
                                              ),
                                            );
                                          }
                                          return;
                                        }
                                      }
                                      if (_stepIndex == 4) {
                                        final lines = await _db.listPlanLines(_planId);
                                        final groups = await _db.listPlanGroups(_planId);
                                        final pids = _allParticipantIds();
                                        if (!await _validateStep3Ratios(lines, groups, pids)) {
                                          if (mounted) {
                                            messenger.showSnackBar(
                                              SnackBar(
                                                content: Text(l10n.housingPlanSplitValidationMessage),
                                              ),
                                            );
                                          }
                                          return;
                                        }
                                      }
                                      if (_stepIndex == 5) {
                                        await _persistAgreementRules();
                                        await widget.prefs.setHousingDefaultPlanSummaryReached(true);
                                        if (mounted) {
                                          setState(() => _showSummary = true);
                                        }
                                        return;
                                      }
                                      if (_stepIndex == 3) {
                                        await _initRatiosIfNeeded();
                                      }
                                      if (mounted) setState(() => _stepIndex++);
                                    } catch (e, st) {
                                      assert(() {
                                        debugPrint('Housing plan Next: $e\n$st');
                                        return true;
                                      }());
                                      if (mounted) {
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(l10n.housingPlanCouldNotContinue('$e')),
                                          ),
                                        );
                                      }
                                    }
                                  }
                                : null),
                            child: Text(_stepIndex == 5 ? l10n.housingPlanFinish : l10n.housingPlanNext),
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
        return _stepExpenseCategories();
      case 3:
        return _stepExpenses();
      case 4:
        return _stepRatios();
      case 5:
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
      _ratioParticipantIndex = _ratioParticipantIndex.clamp(0, maxPid);
      _withdrawalParticipantIndex = _withdrawalParticipantIndex.clamp(0, maxPid);
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
                onPressed: _coEditorIndex > 0 ? () => setState(() => _coEditorIndex--) : null,
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
        TextField(
          controller: _nameControllers[i],
          decoration: InputDecoration(labelText: l10n.housingPlanParticipantNameLabel),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 88,
          child: GridView.builder(
            scrollDirection: Axis.horizontal,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemCount: _avatarIcons.length,
            itemBuilder: (context, idx) {
              final id = 'mdi:$idx';
              final sel = _avatarIds[i] == id;
              return InkWell(
                onTap: () => setState(() => _avatarIds[i] = id),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: sel ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor,
                      width: sel ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_avatarIcons[idx]),
                ),
              );
            },
          ),
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
        final durationText = formatContractCalendarDuration(_periodStart, _periodEnd, l10n);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.housingPlanPlanStart, textAlign: TextAlign.center),
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
                          _periodStart = DateTime(picked.year, picked.month, picked.day).toUtc();
                          _ensureEndAfterStartCalendar();
                        });
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.housingPlanPlanEnd, textAlign: TextAlign.center),
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
                          () => _periodEnd = DateTime(picked.year, picked.month, picked.day).toUtc(),
                        );
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

  Widget _stepExpenseCategories() {
    return FutureBuilder<List<PlanGroup>>(
      future: _planGroupsFuture(),
      builder: (context, snap) {
        final l10n = AppLocalizations.of(context);
        final groups = snap.data ?? [];
        return Column(
          children: [
            Expanded(
              child: groups.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l10n.housingPlanCategoriesEmptyHint,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: groups.length,
                      itemBuilder: (context, i) {
                        final g = groups[i];
                        return Card(
                          child: ListTile(
                            title: Text(g.title),
                            subtitle: g.description.isNotEmpty
                                ? Text(
                                    g.description,
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) {
                                    final d10n = AppLocalizations.of(ctx);
                                    return AlertDialog(
                                      title: Text(d10n.housingPlanDeleteCategoryTitle),
                                      content: Text(d10n.housingPlanDeleteCategoryBody),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: Text(d10n.housingPlanCancel),
                                        ),
                                        FilledButton(
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: Text(d10n.housingPlanDelete),
                                        ),
                                      ],
                                    );
                                  },
                                );
                                if (ok == true) {
                                  await _unassignLinesAndDeletePlanGroup(g.id);
                                  if (mounted) setState(() => _groupsEpoch++);
                                }
                              },
                            ),
                            onTap: () async {
                              await _editPlanCategory(g);
                              if (mounted) setState(() => _groupsEpoch++);
                            },
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

  Widget _stepExpenses() {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([_planLinesFuture(), _planGroupsFuture()]),
      builder: (context, snap) {
        final l10n = AppLocalizations.of(context);
        final lines = (snap.data?[0] as List<PlanLine>?) ?? [];
        final groups = (snap.data?[1] as List<PlanGroup>?) ?? [];
        final groupTitle = <String, String>{for (final g in groups) g.id: g.title};
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
                          await _db.upsertPlanLine(
                            PlanLinesCompanion(
                              id: drift.Value(c.id),
                              planId: drift.Value(c.planId),
                              isRecurring: drift.Value(c.isRecurring),
                              title: drift.Value(c.title),
                              currency: drift.Value(c.currency),
                              amountMinor: drift.Value(c.amountMinor),
                              minAmountMinor: drift.Value(c.minAmountMinor),
                              maxAmountMinor: drift.Value(c.maxAmountMinor),
                              cadence: drift.Value(c.cadence),
                              recurrenceDayOfMonth: drift.Value(c.recurrenceDayOfMonth),
                              sortOrder: drift.Value(i),
                              groupId: drift.Value(c.groupId),
                              amountUsesRange: drift.Value(c.amountUsesRange),
                              description: drift.Value(c.description),
                              createdAt: drift.Value(c.createdAt),
                            ),
                          );
                        }
                        if (mounted) setState(() => _linesEpoch++);
                      },
                      itemBuilder: (context, index) {
                        final line = lines[index];
                        return ReorderableDelayedDragStartListener(
                          key: ValueKey(line.id),
                          index: index,
                          child: Card(
                            child: ListTile(
                              title: Text(line.title),
                              subtitle: line.groupId != null && groupTitle[line.groupId!] != null
                                  ? Text('(${groupTitle[line.groupId!]})')
                                  : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${_money2FromMinor(_splitBasisMinor(line))} ${line.currency}',
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () async {
                                      await (_db.delete(_db.planLines)..where((t) => t.id.equals(line.id))).go();
                                      if (mounted) setState(() => _linesEpoch++);
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
    final groups = await _db.listPlanGroups(_planId);
    if (!mounted) return;
    final result = await showDialog<_LineDraft>(
      context: context,
      builder: (context) => _LineEditorDialog(initial: existing, groups: groups),
    );
    if (result == null) return;
    final now = DateTime.now().toUtc();
    final lines = await _db.listPlanLines(_planId);
    final nextOrder = lines.isEmpty ? 0 : lines.map((e) => e.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
    final id = existing?.id ?? 'line:${now.microsecondsSinceEpoch}';
    await _db.upsertPlanLine(
      PlanLinesCompanion.insert(
        id: id,
        planId: _planId,
        isRecurring: result.isRecurring,
        title: result.title,
        currency: result.currency,
        amountMinor: result.amountUsesRange
            ? const drift.Value.absent()
            : drift.Value(result.amountMinor),
        minAmountMinor: result.amountUsesRange
            ? drift.Value(result.minMinor)
            : const drift.Value.absent(),
        maxAmountMinor: result.amountUsesRange
            ? drift.Value(result.maxMinor)
            : const drift.Value.absent(),
        amountUsesRange: drift.Value(result.amountUsesRange),
        description: drift.Value(result.description),
        cadence: drift.Value(result.cadence),
        recurrenceDayOfMonth: result.isRecurring
            ? drift.Value(result.recurrenceDayOfMonth)
            : const drift.Value.absent(),
        sortOrder: drift.Value(existing?.sortOrder ?? nextOrder),
        groupId: drift.Value(result.groupId),
        createdAt: existing?.createdAt ?? now,
      ),
    );
  }

  List<_SplitListEntry> _splitDisplayEntries(List<PlanLine> lines, List<PlanGroup> groups) {
    final sorted = [...lines]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final knownGroupIds = groups.map((g) => g.id).toSet();
    final out = <_SplitListEntry>[];
    for (final g in groups) {
      final inGroup = sorted.where((l) => l.groupId == g.id).toList();
      if (inGroup.isEmpty) continue;
      out.add(_SplitListGroup(g, inGroup));
    }
    final uncategorized = sorted.where((l) {
      final gid = l.groupId;
      return gid == null || !knownGroupIds.contains(gid);
    }).toList();
    if (uncategorized.isNotEmpty) {
      out.add(_SplitUncategorized(uncategorized, showHeading: groups.isNotEmpty));
    }
    return out;
  }

  Widget _buildSplitRatioLineCard(BuildContext context, PlanLine line, List<String> pids) {
    final lastIdx = pids.length - 1;
    final isLast = _ratioParticipantIndex >= lastIdx;
    final basisMinor = _splitBasisMinor(line);
    return FutureBuilder<List<int>>(
      future: Future.wait([
        for (final pid in pids) _ratioWeight(line.id, pid),
      ]),
      builder: (context, snapW) {
        final weights = snapW.data ?? List.filled(pids.length, 0);
        var before = 0;
        for (var j = 0; j < _ratioParticipantIndex; j++) {
          before += weights[j];
        }
        final assignable = (10000 - before).clamp(0, 10000);
        final pidCur = pids[_ratioParticipantIndex];
        final key = '${line.id}:$pidCur';
        final wDb = weights[_ratioParticipantIndex];
        final wEff = _draftRatioWeightsBps[key] ?? wDb;
        final amountShareMinorComputed = (basisMinor * wEff / 10000).round();
        final amountShareMinor = _shareAmountMinorOverride[key] ?? amountShareMinorComputed;
        final percentEff = basisMinor > 0 ? (amountShareMinor / basisMinor) * 100 : 0.0;

        final shareCtrl = _shareAmountControllerFor(line.id, pidCur);
        final shareText = _money2FromMinor(amountShareMinor);

        final tickFractions = _splitTickFractionsForParticipantCount(pids.length);
        final maxFrac = (assignable / 10000.0).clamp(0.0, 1.0);
        final ticks = <double>[0, ...tickFractions.where((t) => t <= maxFrac), maxFrac]..sort();

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(line.title, style: Theme.of(context).textTheme.titleSmall)),
                    SizedBox(
                      width: 86,
                      child: Focus(
                        onFocusChange: (hasFocus) {
                          if (!hasFocus) {
                            WidgetsBinding.instance.addPostFrameCallback((_) async {
                              if (!mounted) return;
                              await _commitShareAmountTextField(
                                line,
                                pids,
                                _ratioParticipantIndex,
                                basisMinor,
                                assignable,
                                key,
                              );
                            });
                          }
                        },
                        child: Builder(
                          builder: (focusCtx) {
                            final typing = Focus.maybeOf(focusCtx)?.hasFocus ?? false;
                            if (!typing && shareCtrl.text != shareText) {
                              shareCtrl.value = TextEditingValue(
                                text: shareText,
                                selection: TextSelection.collapsed(offset: shareText.length),
                              );
                            }
                            return TextField(
                              controller: shareCtrl,
                              enabled: !isLast && assignable > 0,
                              textAlign: TextAlign.right,
                              textInputAction: TextInputAction.done,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onEditingComplete: () {
                                Future.microtask(() async {
                                  if (!mounted) return;
                                  await _commitShareAmountTextField(
                                    line,
                                    pids,
                                    _ratioParticipantIndex,
                                    basisMinor,
                                    assignable,
                                    key,
                                  );
                                  FocusManager.instance.primaryFocus?.unfocus();
                                });
                              },
                              onTapOutside: (_) {
                                Future.microtask(() async {
                                  if (!mounted) return;
                                  await _commitShareAmountTextField(
                                    line,
                                    pids,
                                    _ratioParticipantIndex,
                                    basisMinor,
                                    assignable,
                                    key,
                                  );
                                });
                              },
                              onSubmitted: (_) {
                                Future.microtask(() async {
                                  if (!mounted) return;
                                  await _commitShareAmountTextField(
                                    line,
                                    pids,
                                    _ratioParticipantIndex,
                                    basisMinor,
                                    assignable,
                                    key,
                                  );
                                  FocusManager.instance.primaryFocus?.unfocus();
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    Text(
                      ' / ${_money2FromMinor(basisMinor)} ${line.currency}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Text(
                        '${percentEff.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Slider(
                          min: 0,
                          max: maxFrac > 0 ? maxFrac : 1,
                          value: (wEff / 10000.0).clamp(0.0, maxFrac > 0 ? maxFrac : 1),
                          onChanged: assignable <= 0
                              ? null
                              : (v) {
                                  final w = (v * 10000).round().clamp(0, assignable);
                                  setState(() {
                                    _shareAmountMinorOverride.remove(key);
                                    _draftRatioWeightsBps[key] = w;
                                  });
                                },
                          onChangeEnd: assignable <= 0
                              ? null
                              : (v) async {
                                  final snapped = _nearestTick(v, ticks);
                                  final w = (snapped * 10000).round().clamp(0, assignable);
                                  setState(() => _draftRatioWeightsBps[key] = w);
                                  await _setRatioWeightBps(line, pids, _ratioParticipantIndex, w);
                                  if (mounted) {
                                    setState(() {
                                      _draftRatioWeightsBps.remove(key);
                                      _shareAmountMinorOverride.remove(key);
                                    });
                                  }
                                },
                        ),
                        const SizedBox(height: 2),
                        LayoutBuilder(
                          builder: (context, c) {
                            final outer = _sliderThemeOuterPadding(context);
                            final innerW = math.max(0.0, c.maxWidth - outer.horizontal);
                            final sliderInteractive = assignable > 0 && !isLast;
                            final (leftInset, trackWidth) = _sliderTrackHorizontalMetrics(
                              context,
                              innerW,
                              sliderInteractive: sliderInteractive,
                            );
                            final color = Theme.of(context).colorScheme.outlineVariant;
                            return SizedBox(
                              height: 10,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  if (maxFrac > 0 && trackWidth > 0)
                                    for (final t in ticks.where((e) => e > 0 && e < maxFrac))
                                      Positioned(
                                        left: _snapToDevicePixels(
                                          context,
                                          outer.left + leftInset + (t / maxFrac) * trackWidth - 1,
                                        ),
                                        top: 0,
                                        bottom: 0,
                                        child: Container(width: 2, color: color),
                                      ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  )
                else
                  Slider(
                    value: (wDb / 10000).clamp(0.0, 1.0),
                    onChanged: null,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSplitRatioGroupCard(
    BuildContext context,
    PlanGroup group,
    List<PlanLine> memberLines,
    List<String> pids,
  ) {
    final lastIdx = pids.length - 1;
    final isLast = _ratioParticipantIndex >= lastIdx;
    final basisMinor = _groupBasisMinor(memberLines);
    final currency = memberLines.isEmpty ? '' : memberLines.first.currency;
    final memberLabel = memberLines.map((l) => l.title).join(' · ');

    return FutureBuilder<List<int>>(
      future: Future.wait([
        for (final pid in pids) _ratioWeightGroup(group.id, pid),
      ]),
      builder: (context, snapW) {
        final weights = snapW.data ?? List.filled(pids.length, 0);
        var before = 0;
        for (var j = 0; j < _ratioParticipantIndex; j++) {
          before += weights[j];
        }
        final assignable = (10000 - before).clamp(0, 10000);
        final pidCur = pids[_ratioParticipantIndex];
        final key = _shareSplitControllerKeyForGroup(group.id, pidCur);
        final wDb = weights[_ratioParticipantIndex];
        final wEff = _draftRatioWeightsBps[key] ?? wDb;
        final amountShareMinorComputed = (basisMinor * wEff / 10000).round();
        final amountShareMinor = _shareAmountMinorOverride[key] ?? amountShareMinorComputed;
        final percentEff = basisMinor > 0 ? (amountShareMinor / basisMinor) * 100 : 0.0;

        final shareCtrl = _shareAmountControllerForGroup(group.id, pidCur);
        final shareText = _money2FromMinor(amountShareMinor);

        final tickFractions = _splitTickFractionsForParticipantCount(pids.length);
        final maxFrac = (assignable / 10000.0).clamp(0.0, 1.0);
        final ticks = <double>[0, ...tickFractions.where((t) => t <= maxFrac), maxFrac]..sort();

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        group.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    SizedBox(
                      width: 86,
                      child: Focus(
                        onFocusChange: (hasFocus) {
                          if (!hasFocus) {
                            WidgetsBinding.instance.addPostFrameCallback((_) async {
                              if (!mounted) return;
                              await _commitShareGroupAmountTextField(
                                group,
                                pids,
                                _ratioParticipantIndex,
                                basisMinor,
                                assignable,
                                key,
                              );
                            });
                          }
                        },
                        child: Builder(
                          builder: (focusCtx) {
                            final typing = Focus.maybeOf(focusCtx)?.hasFocus ?? false;
                            if (!typing && shareCtrl.text != shareText) {
                              shareCtrl.value = TextEditingValue(
                                text: shareText,
                                selection: TextSelection.collapsed(offset: shareText.length),
                              );
                            }
                            return TextField(
                              controller: shareCtrl,
                              enabled: !isLast && assignable > 0,
                              textAlign: TextAlign.right,
                              textInputAction: TextInputAction.done,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onEditingComplete: () {
                                Future.microtask(() async {
                                  if (!mounted) return;
                                  await _commitShareGroupAmountTextField(
                                    group,
                                    pids,
                                    _ratioParticipantIndex,
                                    basisMinor,
                                    assignable,
                                    key,
                                  );
                                  FocusManager.instance.primaryFocus?.unfocus();
                                });
                              },
                              onTapOutside: (_) {
                                Future.microtask(() async {
                                  if (!mounted) return;
                                  await _commitShareGroupAmountTextField(
                                    group,
                                    pids,
                                    _ratioParticipantIndex,
                                    basisMinor,
                                    assignable,
                                    key,
                                  );
                                });
                              },
                              onSubmitted: (_) {
                                Future.microtask(() async {
                                  if (!mounted) return;
                                  await _commitShareGroupAmountTextField(
                                    group,
                                    pids,
                                    _ratioParticipantIndex,
                                    basisMinor,
                                    assignable,
                                    key,
                                  );
                                  FocusManager.instance.primaryFocus?.unfocus();
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    Text(
                      ' / ${_money2FromMinor(basisMinor)} $currency',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
                if (memberLabel.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: 0.75,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        memberLabel,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Text(
                        '${percentEff.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Slider(
                          min: 0,
                          max: maxFrac > 0 ? maxFrac : 1,
                          value: (wEff / 10000.0).clamp(0.0, maxFrac > 0 ? maxFrac : 1),
                          onChanged: assignable <= 0
                              ? null
                              : (v) {
                                  final w = (v * 10000).round().clamp(0, assignable);
                                  setState(() {
                                    _shareAmountMinorOverride.remove(key);
                                    _draftRatioWeightsBps[key] = w;
                                  });
                                },
                          onChangeEnd: assignable <= 0
                              ? null
                              : (v) async {
                                  final snapped = _nearestTick(v, ticks);
                                  final w = (snapped * 10000).round().clamp(0, assignable);
                                  setState(() => _draftRatioWeightsBps[key] = w);
                                  await _setGroupRatioWeightBps(group, pids, _ratioParticipantIndex, w);
                                  if (mounted) {
                                    setState(() {
                                      _draftRatioWeightsBps.remove(key);
                                      _shareAmountMinorOverride.remove(key);
                                    });
                                  }
                                },
                        ),
                        const SizedBox(height: 2),
                        LayoutBuilder(
                          builder: (context, c) {
                            final outer = _sliderThemeOuterPadding(context);
                            final innerW = math.max(0.0, c.maxWidth - outer.horizontal);
                            final sliderInteractive = assignable > 0 && !isLast;
                            final (leftInset, trackWidth) = _sliderTrackHorizontalMetrics(
                              context,
                              innerW,
                              sliderInteractive: sliderInteractive,
                            );
                            final color = Theme.of(context).colorScheme.outlineVariant;
                            return SizedBox(
                              height: 10,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  if (maxFrac > 0 && trackWidth > 0)
                                    for (final t in ticks.where((e) => e > 0 && e < maxFrac))
                                      Positioned(
                                        left: _snapToDevicePixels(
                                          context,
                                          outer.left + leftInset + (t / maxFrac) * trackWidth - 1,
                                        ),
                                        top: 0,
                                        bottom: 0,
                                        child: Container(width: 2, color: color),
                                      ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  )
                else
                  Slider(
                    value: (wDb / 10000).clamp(0.0, 1.0),
                    onChanged: null,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _stepRatios() {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        _db.listPlanLines(_planId),
        _db.listPlanGroups(_planId),
      ]),
      builder: (context, snapLinesAndGroups) {
        return FutureBuilder<Agreement?>(
          future: _db.getAgreementForPlan(_planId),
          builder: (context, snapAgr) {
            final l10n = AppLocalizations.of(context);
            final combined = snapLinesAndGroups.data;
            final lines = combined == null ? <PlanLine>[] : combined[0] as List<PlanLine>;
            final groups = combined == null ? <PlanGroup>[] : combined[1] as List<PlanGroup>;
            final agr = snapAgr.data;
            if (lines.isEmpty || agr == null) {
              return Center(child: Text(l10n.housingPlanAddExpensesFirst));
            }
            final pids = _allParticipantIds();
            final entries = _splitDisplayEntries(lines, groups);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: FutureBuilder<double>(
                    future: _participantTotalMinor(pids[_ratioParticipantIndex], lines, groups),
                    builder: (context, snapT) {
                      final t = snapT.data ?? 0;
                      return Text(
                        '${t.toStringAsFixed(2)} ${lines.first.currency}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (var i = 0; i < pids.length; i++)
                        ChoiceChip(
                          label: Text(_ratioParticipantLabel(l10n, i)),
                          selected: _ratioParticipantIndex == i,
                          onSelected: (sel) {
                            if (!sel) return;
                            if (i > 0) {
                              // Encourage order: warn if skipping ahead without prior filled — soft check omitted for UX tap
                            }
                            setState(() => _ratioParticipantIndex = i);
                          },
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: entries.length,
                    itemBuilder: (context, i) {
                      final e = entries[i];
                      return switch (e) {
                        _SplitListGroup(:final group, :final memberLines) =>
                          _buildSplitRatioGroupCard(context, group, memberLines, pids),
                        _SplitUncategorized(:final lines, :final showHeading) => Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (showHeading)
                                Padding(
                                  padding: EdgeInsets.fromLTRB(4, i == 0 ? 8 : 18, 4, 6),
                                  child: Text(
                                    l10n.housingPlanSplitNoCategory,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              for (final line in lines)
                                _buildSplitRatioLineCard(context, line, pids),
                            ],
                          ),
                      };
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<double> _participantTotalMinor(
    String participantId,
    List<PlanLine> lines,
    List<PlanGroup> groups,
  ) async {
    var sumMinor = 0;
    final knownGroupIds = groups.map((g) => g.id).toSet();
    final sorted = [...lines]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    for (final g in groups) {
      final members = sorted.where((l) => l.groupId == g.id).toList();
      if (members.isEmpty) continue;
      final basis = _groupBasisMinor(members);
      final key = _shareSplitControllerKeyForGroup(g.id, participantId);
      final o = _shareAmountMinorOverride[key];
      if (o != null) {
        sumMinor += o;
        continue;
      }
      final w = await _ratioWeightGroup(g.id, participantId);
      sumMinor += (basis * w / 10000).round();
    }

    for (final line in sorted) {
      final gid = line.groupId;
      if (gid != null && knownGroupIds.contains(gid)) continue;
      final key = '${line.id}:$participantId';
      final o = _shareAmountMinorOverride[key];
      if (o != null) {
        sumMinor += o;
        continue;
      }
      final w = await _ratioWeight(line.id, participantId);
      final basis = _splitBasisMinor(line);
      sumMinor += (basis * w / 10000).round();
    }
    return sumMinor / 100.0;
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
        contentPadding: const EdgeInsetsDirectional.fromSTEB(_kAgreementRuleHPad, 0, _kAgreementRuleHPad, 0),
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
          decoration: InputDecoration(labelText: l10n.housingPlanMinimumNoticeDays),
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
          decoration: InputDecoration(labelText: l10n.housingPlanMinimumNoticeDays),
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
      final n = i < _perParticipantNotice.length ? _perParticipantNotice[i].text.trim() : '';
      final p = i < _perParticipantPenalty.length ? _perParticipantPenalty[i].text.trim() : '';
      lines.add('$label — ${l10n.housingPlanMinimumNoticeDays}: $n; ${l10n.housingPlanPenaltyAmount}: $p');
    }
    return Text(lines.join('\n'), style: Theme.of(context).textTheme.bodyMedium);
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
    return _agreementLeadingCheckbox(
      value: true,
      onChanged: null,
    );
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
              padding: const EdgeInsetsDirectional.fromSTEB(_kAgreementRuleHPad, 4, _kAgreementRuleHPad, 4),
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
              padding: const EdgeInsets.fromLTRB(_kAgreementRuleHPad, 0, _kAgreementRuleHPad, 12),
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

  void _disposeTextControllersNextFrame(TextEditingController? a, TextEditingController? b) {
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
    if (_customRuleEditingId != rule.id || _customRuleEditTitle == null || _customRuleEditBody == null) {
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

  Widget _buildingRulesReadOnlyContent(AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    final bodyStyle = Theme.of(context).textTheme.bodyMedium;
    final raw = _buildingRulesBody.text;
    final display = raw.trim().isEmpty ? l10n.housingAgreementRuleBuildingHint : raw;
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
        onChanged: _curfewEditing ? null : (v) => setState(() => _rulesDraft.curfewEnabled = v ?? false),
      ),
      title: Text(l10n.housingAgreementRuleCurfewTitle),
      expanded: _curfewExpanded,
      onHeaderTap: onHeaderTap,
      expandedChildren: [
        _agreementRulesActionRow(
          l10n: l10n,
          pencilEnabled: !_curfewEditing,
          onPencil: () => setState(() {
            _curfewEditSnapshot = _curfewNotes.text;
            _curfewEditing = true;
            _curfewExpanded = true;
          }),
          trashEnabled: false,
          onTrash: null,
          trashTooltip: l10n.housingAgreementRuleRemove,
        ),
        if (_curfewEditing)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _curfewNotes,
                maxLines: 6,
                minLines: 3,
                decoration: InputDecoration(
                  hintText: l10n.housingAgreementRuleCurfewPlaceholder,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: () => setState(() {
                      _curfewNotes.text = _curfewEditSnapshot;
                      _curfewEditing = false;
                    }),
                    child: Text(l10n.housingPlanCancel),
                  ),
                  FilledButton(
                    onPressed: () => setState(() {
                      _rulesDraft.curfewNotes = _curfewNotes.text;
                      _curfewEditing = false;
                    }),
                    child: Text(l10n.housingPlanSave),
                  ),
                ],
              ),
            ],
          )
        else
          _curfewNotes.text.trim().isEmpty
              ? Text(
                  l10n.housingAgreementRuleCurfewPlaceholder,
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              : SelectableText(
                  _curfewNotes.text,
                  style: Theme.of(context).textTheme.bodyMedium,
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
            : (v) => setState(() => _rulesDraft.earlyWithdrawalEnabled = v ?? false),
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
          child: Text(l10n.housingPlanWithdrawalIntro, style: Theme.of(context).textTheme.bodySmall),
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
            : (v) => setState(() => _rulesDraft.buildingRulesEnabled = v ?? false),
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
                    onPressed: () => setState(() => _buildingRulesEditing = false),
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
        onChanged: isEditing ? null : (v) => setState(() => rule.enabled = v ?? true),
      ),
      title: Text(
        rule.title.isEmpty ? l10n.housingAgreementRuleCustomTitleLabel : rule.title,
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
                decoration: InputDecoration(labelText: l10n.housingAgreementRuleCustomTitleLabel),
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
                : Text(rule.body, style: Theme.of(context).textTheme.bodyMedium),
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
                    if (!_rulesDraft.dismissedSuggestionIds.contains(suggestionId)) {
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
                    decoration: InputDecoration(labelText: d10n.housingAgreementRuleCustomTitleLabel),
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
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(d10n.housingPlanCancel)),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(d10n.housingPlanSave)),
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
        Text(l10n.housingAgreementRulesIntro, style: Theme.of(context).textTheme.bodyMedium),
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
        if (!_rulesDraft.dismissedSuggestionIds.contains(kAgreementSuggestionCommonCleanliness))
          _suggestionAgreementRuleTile(
            l10n,
            suggestionId: kAgreementSuggestionCommonCleanliness,
            title: l10n.housingAgreementSuggestionCleanlinessTitle,
            body: l10n.housingAgreementSuggestionCleanlinessBody,
          ),
        if (!_rulesDraft.dismissedSuggestionIds.contains(kAgreementSuggestionFridgeManagement))
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
            onPressed: _rulesRemovalLocked ? null : () => _showAddAgreementRuleDialog(),
            icon: const Icon(Icons.add),
            label: Text(l10n.housingAgreementRuleAdd),
          ),
        ),
      ],
    );
  }
}

class _SummaryView extends StatelessWidget {
  const _SummaryView({
    required this.db,
    required this.planId,
    required this.avatarIcons,
    required this.shareMinorOverrides,
    required this.onEditPlan,
    required this.onInvite,
    required this.onDestroy,
  });

  final AppDatabase db;
  final String planId;
  final List<IconData> avatarIcons;
  /// Keys `lineId:participantId`; same map as split-step manual amount pins.
  final Map<String, int> shareMinorOverrides;
  final VoidCallback onEditPlan;
  final VoidCallback onInvite;
  final VoidCallback onDestroy;

  IconData _iconForAvatar(String avatarId) {
    if (!avatarId.startsWith('mdi:')) return MdiIcons.account;
    final idx = int.tryParse(avatarId.split(':').last);
    if (idx == null || idx < 0 || idx >= avatarIcons.length) return MdiIcons.account;
    return avatarIcons[idx];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([
        db.listParticipants(),
        db.listPlanLines(planId),
        db.getAgreementForPlan(planId),
        db.listPlanRatios(planId),
        db.listPlanGroups(planId),
      ]),
      builder: (context, AsyncSnapshot<List<dynamic>> snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final l10n = AppLocalizations.of(context);
        int rosterOrder(String id) {
          if (id.endsWith(':self')) return -1;
          final tail = id.split(':p').last;
          return int.tryParse(tail) ?? 999;
        }

        final roster = (snap.data![0] as List<Participant>)
            .where((p) => p.id == '$planId:self' || p.id.startsWith('$planId:p'))
            .toList()
          ..sort((a, b) => rosterOrder(a.id).compareTo(rosterOrder(b.id)));
        final lines = snap.data![1] as List<PlanLine>;
        final agr = snap.data![2] as Agreement?;
        final ratios = snap.data![3] as List<PlanRatio>;
        final planGroups = snap.data![4] as List<PlanGroup>;
        if (agr == null) return Center(child: Text(l10n.housingPlanSummaryMissingAgreement));

        var planMonthlyTotalMinor = 0;
        for (final line in lines) {
          planMonthlyTotalMinor += PlanProjection.unitMinor(line);
        }

        final knownGroupIds = planGroups.map((g) => g.id).toSet();
        final sortedLines = [...lines]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        int participantShareMinor(String participantId) {
          var participantMonthlyMinor = 0;
          for (final g in planGroups) {
            final mem = sortedLines.where((l) => l.groupId == g.id).toList();
            if (mem.isEmpty) continue;
            final basis = mem.fold<int>(0, (a, l) => a + PlanProjection.unitMinor(l));
            final gKey = 'g:${g.id}:$participantId';
            final o = shareMinorOverrides[gKey];
            if (o != null) {
              participantMonthlyMinor += o;
              continue;
            }
            final w = ratios
                .where((r) => r.groupId == g.id && r.participantId == participantId)
                .fold<int>(0, (a, r) => a + r.weight);
            participantMonthlyMinor += (basis * w / 10000).round();
          }
          for (final line in sortedLines) {
            final gid = line.groupId;
            if (gid != null && knownGroupIds.contains(gid)) continue;
            final key = '${line.id}:$participantId';
            final o = shareMinorOverrides[key];
            if (o != null) {
              participantMonthlyMinor += o;
              continue;
            }
            final w = ratios
                .where((r) => r.lineId == line.id && r.participantId == participantId)
                .fold<int>(0, (a, r) => a + r.weight);
            final basis = PlanProjection.unitMinor(line);
            participantMonthlyMinor += (basis * w / 10000).round();
          }
          return participantMonthlyMinor;
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: roster.length,
                itemBuilder: (context, i) {
                  final p = roster[i];
                  final participantMonthlyMinor = participantShareMinor(p.id);
                  final sharePct = planMonthlyTotalMinor > 0
                      ? (participantMonthlyMinor / planMonthlyTotalMinor) * 100
                      : 0.0;
                  final currency = lines.isEmpty ? '' : lines.first.currency;
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
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        p.displayName,
                                        style: Theme.of(context).textTheme.titleMedium,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '${sharePct.toStringAsFixed(2)}%',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  l10n.housingPlanSummaryMonthlyTotal,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${(participantMonthlyMinor / 100).toStringAsFixed(2)} $currency',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
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
                  FilledButton.tonal(onPressed: onEditPlan, child: Text(l10n.housingPlanSummaryEditPlan)),
                  const SizedBox(height: 8),
                  FilledButton(onPressed: onInvite, child: Text(l10n.housingPlanSummaryInvite)),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: onDestroy,
                    child: Text(l10n.housingPlanSummaryDestroy),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CategoryDraft {
  const _CategoryDraft({required this.title, required this.description});

  final String title;
  final String description;
}

class _CategoryEditorDialog extends StatefulWidget {
  const _CategoryEditorDialog({this.initial});

  final PlanGroup? initial;

  @override
  State<_CategoryEditorDialog> createState() => _CategoryEditorDialogState();
}

class _CategoryEditorDialogState extends State<_CategoryEditorDialog> {
  late final TextEditingController _title =
      TextEditingController(text: widget.initial?.title ?? '');
  late final TextEditingController _description =
      TextEditingController(text: widget.initial?.description ?? '');

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canSave = _title.text.trim().isNotEmpty;
    return AlertDialog(
      title: Text(widget.initial == null ? l10n.housingPlanAddCategoryTitle : l10n.housingPlanEditCategoryTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _title,
              decoration: InputDecoration(labelText: l10n.housingPlanCategoryNameLabel),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                l10n.housingPlanCategoryDescriptionLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                maxLines: 2,
                softWrap: true,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _description,
              decoration: const InputDecoration(
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              minLines: 2,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.housingPlanCancel)),
        FilledButton(
          onPressed: canSave
              ? () {
                  Navigator.of(context).pop(
                    _CategoryDraft(
                      title: _title.text.trim(),
                      description: _description.text.trim(),
                    ),
                  );
                }
              : null,
          child: Text(l10n.housingPlanSave),
        ),
      ],
    );
  }
}

class _LineDraft {
  const _LineDraft({
    required this.title,
    required this.currency,
    required this.isRecurring,
    required this.amountUsesRange,
    required this.amountMinor,
    required this.minMinor,
    required this.maxMinor,
    required this.description,
    required this.cadence,
    required this.recurrenceDayOfMonth,
    this.groupId,
  });

  final String title;
  final String currency;
  final bool isRecurring;
  final bool amountUsesRange;
  final int amountMinor;
  final int minMinor;
  final int maxMinor;
  final String description;
  final String cadence;
  final int recurrenceDayOfMonth;
  final String? groupId;
}

class _LineEditorDialog extends StatefulWidget {
  const _LineEditorDialog({this.initial, this.groups = const []});

  final PlanLine? initial;
  final List<PlanGroup> groups;

  @override
  State<_LineEditorDialog> createState() => _LineEditorDialogState();
}

class _LineEditorDialogState extends State<_LineEditorDialog> {
  late bool _isRecurring = widget.initial?.isRecurring ?? true;
  late bool _amountUsesRange = widget.initial?.amountUsesRange ?? false;
  late final TextEditingController _title =
      TextEditingController(text: widget.initial?.title ?? '');
  late final TextEditingController _amount =
      TextEditingController(text: _minorToText(widget.initial?.amountMinor));
  late final TextEditingController _min =
      TextEditingController(text: _minorToText(widget.initial?.minAmountMinor));
  late final TextEditingController _max =
      TextEditingController(text: _minorToText(widget.initial?.maxAmountMinor));
  late final TextEditingController _description =
      TextEditingController(text: widget.initial?.description ?? '');
  late int _dayOfMonth;
  late String _currency;
  String? _groupId;

  @override
  void initState() {
    super.initState();
    _dayOfMonth = widget.initial?.recurrenceDayOfMonth ?? 1;
    _currency = widget.initial?.currency ?? 'CAD';
    final gid = widget.initial?.groupId;
    _groupId = gid != null && widget.groups.any((g) => g.id == gid) ? gid : null;
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _min.dispose();
    _max.dispose();
    _description.dispose();
    super.dispose();
  }

  bool get _fixedOk => _parseMinor(_amount.text) != null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canSave = _title.text.trim().isNotEmpty &&
        (!_isRecurring || (_dayOfMonth >= 1 && _dayOfMonth <= 31)) &&
        (_amountUsesRange ? _rangeValid() : _fixedOk);
    return AlertDialog(
      title: Text(widget.initial == null ? l10n.housingPlanAddExpenseTitle : l10n.housingPlanEditExpenseTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              title: Text(l10n.housingPlanRecurringSwitch),
              value: _isRecurring,
              onChanged: (v) => setState(() => _isRecurring = v),
            ),
            SwitchListTile(
              title: Text(l10n.housingPlanApproximateAmountSwitch),
              value: _amountUsesRange,
              onChanged: (v) => setState(() => _amountUsesRange = v),
            ),
            TextField(
              controller: _title,
              decoration: InputDecoration(labelText: l10n.housingPlanExpenseTitleLabel),
              onChanged: (_) => setState(() {}),
            ),
            if (widget.groups.isNotEmpty) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                key: ValueKey<String?>(_groupId),
                initialValue: _groupId,
                decoration: InputDecoration(labelText: l10n.housingPlanCategoryOptionalLabel),
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.housingPlanCategoryNone)),
                  ...widget.groups.map(
                    (g) => DropdownMenuItem(value: g.id, child: Text(g.title)),
                  ),
                ],
                onChanged: (v) => setState(() => _groupId = v),
              ),
            ],
            const SizedBox(height: 8),
            TextField(
              controller: _description,
              decoration: InputDecoration(
                labelText: l10n.housingPlanExpenseDescriptionLabel,
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              minLines: 2,
              onChanged: (_) => setState(() {}),
            ),
            if (_isRecurring) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _dayOfMonth,
                decoration: InputDecoration(labelText: l10n.housingPlanDayOfMonthLabel),
                items: [for (var d = 1; d <= 31; d++) DropdownMenuItem(value: d, child: Text('$d'))],
                onChanged: (v) => setState(() => _dayOfMonth = v ?? 1),
              ),
            ],
            if (_amountUsesRange) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _min,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.housingPlanMinLabel),
                onChanged: (_) => setState(() {}),
              ),
              TextField(
                controller: _max,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.housingPlanMaxLabel),
                onChanged: (_) => setState(() {}),
              ),
            ] else ...[
              const SizedBox(height: 8),
              TextField(
                controller: _amount,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.housingPlanAmountLabel),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.housingPlanCancel)),
        FilledButton(
          onPressed: canSave
              ? () {
                  Navigator.of(context).pop(
                    _LineDraft(
                      title: _title.text.trim(),
                      currency: _currency,
                      isRecurring: _isRecurring,
                      amountUsesRange: _amountUsesRange,
                      amountMinor: _parseMinor(_amount.text) ?? 0,
                      minMinor: _parseMinor(_min.text) ?? 0,
                      maxMinor: _parseMinor(_max.text) ?? 0,
                      description: _description.text.trim(),
                      cadence: 'monthly',
                      recurrenceDayOfMonth: _dayOfMonth,
                      groupId: _groupId,
                    ),
                  );
                }
              : null,
          child: Text(l10n.housingPlanSave),
        ),
      ],
    );
  }

  bool _rangeValid() {
    final a = _parseMinor(_min.text);
    final b = _parseMinor(_max.text);
    if (a == null || b == null) return false;
    return a <= b;
  }

  int? _parseMinor(String text) {
    final t = text.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    final v = double.tryParse(t);
    if (v == null) return null;
    return (v * 100).round();
  }

  String _minorToText(int? minor) {
    if (minor == null) return '';
    return (minor / 100).toStringAsFixed(2);
  }
}
