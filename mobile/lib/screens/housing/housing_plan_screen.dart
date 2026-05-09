import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import '../../db/app_database.dart';
import '../../housing/projection/plan_projection.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../util/display_date.dart';

/// Housing plan setup: vertical stepper (1–5) then summary (step 6).
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

  static const _stepTitles = <String>[
    'Participants',
    'Plan dates',
    'Expenses',
    'Split',
    'Withdrawal',
  ];

  /// 0–4 = wizard steps; summary when true.
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
    _globalNotice.dispose();
    _globalPenalty.dispose();
    _db.close();
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

  String _ratioParticipantLabel(int index) {
    if (index == 0) return 'You';
    final nm = _nameControllers[index - 1].text.trim();
    return nm.isEmpty ? 'Co-participant $index' : nm;
  }

  Future<void> _ensurePlanShell() async {
    await _db.upsertPlan(
      PlansCompanion.insert(
        id: _planId,
        type: 'housing',
        createdAt: DateTime.now().toUtc(),
        title: drift.Value('Housing plan'),
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
    }

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

  bool _stepDone(int i) {
    if (_showSummary) return true;
    return i < _stepIndex;
  }

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
        return true; // validated async: at least one line
      case 3:
        return true; // validated async: ratios sum to 100%
      case 4:
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

  Future<bool> _validateStep3Ratios(List<PlanLine> lines, List<String> pids) async {
    final ratios = await _db.listPlanRatios(_planId);
    for (final line in lines) {
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
        displayName: selfName.isEmpty ? 'You' : selfName,
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
        version: drift.Value(cur.version),
        createdAt: drift.Value(cur.createdAt),
      ),
    );
  }

  Future<void> _initRatiosIfNeeded() async {
    final lines = await _db.listPlanLines(_planId);
    final pids = _allParticipantIds();
    if (pids.length < 2) return;
    final existing = await _db.listPlanRatios(_planId);
    for (final line in lines) {
      final sum = existing
          .where((r) => r.lineId == line.id)
          .fold<int>(0, (a, r) => a + r.weight);
      if (sum == 10000) continue;
      await (_db.delete(_db.planRatios)
            ..where((t) => t.lineId.equals(line.id)))
          .go();
      final last = pids.last;
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

  Future<int> _ratioWeight(String lineId, String participantId) async {
    final rows = await _db.listPlanRatios(_planId);
    return rows
        .where((r) => r.lineId == lineId && r.participantId == participantId)
        .fold<int>(0, (a, r) => a + r.weight);
  }

  Future<void> _setRatioForParticipant(
    PlanLine line,
    List<String> pids,
    int participantIndex,
    double fractionOfAssignable,
  ) async {
    final last = pids.last;
    if (participantIndex >= pids.length - 1) return;

    var assignedBefore = 0;
    for (var i = 0; i < participantIndex; i++) {
      assignedBefore += await _ratioWeight(line.id, pids[i]);
    }
    final assignable = 10000 - assignedBefore;
    final newW = (fractionOfAssignable * assignable).round().clamp(0, assignable);
    final pid = pids[participantIndex];
    await _db.upsertPlanRatio(
      PlanRatiosCompanion.insert(
        id: 'ratio:$_planId:${line.id}:$pid',
        planId: _planId,
        participantId: pid,
        lineId: drift.Value(line.id),
        groupId: const drift.Value.absent(),
        weight: newW,
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

  int _lineTotalMinor(PlanLine line, Agreement agr) {
    final months = PlanProjection.monthsCoveredInclusive(
      agr.periodStart,
      agr.periodEnd,
    ).clamp(0, 120);
    final unit = PlanProjection.unitMinor(line);
    if (line.isRecurring) {
      return unit * months;
    }
    return unit;
  }

  Future<void> _persistWithdrawal() async {
    final cur = await _db.getAgreementForPlan(_planId);
    final notice = int.tryParse(_globalNotice.text.trim()) ?? 0;
    final penalty = _parseMinor(_globalPenalty.text) ?? 0;
    Map<String, dynamic> per = {};
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
    await _db.upsertAgreement(
      AgreementsCompanion.insert(
        id: _agreementId,
        planId: _planId,
        periodStart: cur!.periodStart,
        periodEnd: cur.periodEnd,
        minNoticeDays: drift.Value(_withdrawalSameForAll ? notice : 0),
        penaltyMinor: drift.Value(_withdrawalSameForAll ? penalty : 0),
        clauses: drift.Value(cur.clauses),
        withdrawalSameForAll: drift.Value(_withdrawalSameForAll ? 'true' : 'false'),
        withdrawalPerParticipantJson: drift.Value(jsonEncode(per)),
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Destroy plan'),
        content: const Text(
          'This removes this housing plan, expenses, ratios, agreement, and draft participants from this device.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Destroy')),
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
    });
    await _loadFromDb();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan removed')),
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
            for (var i = 0; i < _stepTitles.length; i++) ...[
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
      appBar: AppBar(title: Text(l10n.homeHousingPlan)),
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
                  'Could not load plan data.\n${snap.error}',
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
              onEditPlan: () => setState(() {
                _showSummary = false;
                _stepIndex = 0;
              }),
              onInvite: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invite participants (coming soon)')),
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
                          Expanded(
                            child: Text(
                              _stepTitles[_stepIndex],
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                          if (_stepIndex == 2)
                            IconButton.filledTonal(
                              tooltip: 'Add expense',
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
                        children: [
                          if (_stepIndex > 0)
                            OutlinedButton(
                              onPressed: () => setState(() => _stepIndex--),
                              child: const Text('Back'),
                            ),
                          const Spacer(),
                          FilledButton(
                            onPressed: _validateStep(_stepIndex)
                                ? () async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    try {
                                      if (_stepIndex == 0) await _persistParticipants();
                                      if (_stepIndex == 1) await _persistPeriod();
                                      if (_stepIndex == 2) {
                                        if (!await _validateStep2Expenses()) {
                                          if (mounted) {
                                            messenger.showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Add at least one expense. Each needs a valid amount (fixed or min/max range) and recurring items need a day of month.',
                                                ),
                                              ),
                                            );
                                          }
                                          return;
                                        }
                                      }
                                      if (_stepIndex == 3) {
                                        final lines = await _db.listPlanLines(_planId);
                                        final pids = _allParticipantIds();
                                        if (!await _validateStep3Ratios(lines, pids)) {
                                          if (mounted) {
                                            messenger.showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Each expense must total 100% across participants.',
                                                ),
                                              ),
                                            );
                                          }
                                          return;
                                        }
                                      }
                                      if (_stepIndex == 4) {
                                        await _persistWithdrawal();
                                        await widget.prefs.setHousingDefaultPlanSummaryReached(true);
                                        if (mounted) {
                                          setState(() => _showSummary = true);
                                        }
                                        return;
                                      }
                                      if (_stepIndex == 2) {
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
                                            content: Text('Could not continue: $e'),
                                          ),
                                        );
                                      }
                                    }
                                  }
                                : null,
                            child: Text(_stepIndex == 4 ? 'Finish' : 'Next'),
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
        return _stepRatios();
      case 4:
        return _stepWithdrawal();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _stepParticipants() {
    final i = _otherParticipantCount > 1 ? _coEditorIndex : 0;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'You are always included. Choose how many additional people will share this plan.',
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Additional people: '),
            DropdownButton<int>(
              value: _otherParticipantCount,
              items: [
                for (var n = 1; n <= 7; n++) DropdownMenuItem(value: n, child: Text('$n')),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _otherParticipantCount = v;
                  _resizeParticipantEditors(v);
                  _coEditorIndex = _coEditorIndex.clamp(0, v - 1);
                  final maxPid = v;
                  _ratioParticipantIndex = _ratioParticipantIndex.clamp(0, maxPid);
                  _withdrawalParticipantIndex =
                      _withdrawalParticipantIndex.clamp(0, maxPid);
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Names and avatars are placeholders until someone joins for real.'),
        const SizedBox(height: 12),
        if (_otherParticipantCount > 1) ...[
          Text(
            'Person ${_coEditorIndex + 1} of $_otherParticipantCount',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton(
                onPressed: _coEditorIndex > 0 ? () => setState(() => _coEditorIndex--) : null,
                child: const Text('Previous person'),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: _coEditorIndex < _otherParticipantCount - 1
                    ? () => setState(() => _coEditorIndex++)
                    : null,
                child: const Text('Next person'),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        Text(
          _otherParticipantCount > 1 ? 'Co-participant ${_coEditorIndex + 1}' : 'Co-participant',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _nameControllers[i],
          decoration: const InputDecoration(labelText: 'Name'),
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
      ],
    );
  }

  Widget _stepDates() {
    return ListenableBuilder(
      listenable: widget.prefs,
      builder: (context, _) {
        final fmt = widget.prefs.dateFormat;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              title: const Text('Plan start'),
              subtitle: Text(formatPreferenceDate(_periodStart, fmt)),
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
              title: const Text('Plan end'),
              subtitle: Text(formatPreferenceDate(_periodEnd, fmt)),
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
            if (_periodStart != null &&
                _periodEnd != null &&
                !isStrictlyBeforeCalendarDate(_periodStart!, _periodEnd!))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'End date must be after start date (by at least one calendar day).',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
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
        final lines = snap.data ?? [];
        return Column(
          children: [
            Expanded(
              child: lines.isEmpty
                  ? const Center(child: Text('Tap + to add an expense.'))
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
                              subtitle: Text(_expenseLineSubtitle(line)),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  await (_db.delete(_db.planLines)..where((t) => t.id.equals(line.id))).go();
                                  if (mounted) setState(() => _linesEpoch++);
                                },
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

  String _expenseLineSubtitle(PlanLine line) {
    final bits = <String>[];
    if (line.isRecurring) {
      bits.add('Recurring • day ${line.recurrenceDayOfMonth ?? '?'}');
    } else {
      bits.add('One-off');
    }
    if (line.amountUsesRange) {
      final lo = ((line.minAmountMinor ?? 0) / 100).toStringAsFixed(2);
      final hi = ((line.maxAmountMinor ?? 0) / 100).toStringAsFixed(2);
      bits.add('Approx $lo–$hi ${line.currency}');
    } else {
      bits.add('Fixed ${((line.amountMinor ?? 0) / 100).toStringAsFixed(2)} ${line.currency}');
    }
    final d = line.description.trim();
    if (d.isNotEmpty) {
      bits.add(d);
    }
    return bits.join(' • ');
  }

  Future<void> _editLine(PlanLine? existing) async {
    final result = await showDialog<_LineDraft>(
      context: context,
      builder: (context) => _LineEditorDialog(initial: existing),
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
        groupId: const drift.Value.absent(),
        createdAt: existing?.createdAt ?? now,
      ),
    );
  }

  Widget _stepRatios() {
    return FutureBuilder<List<PlanLine>>(
      future: _db.listPlanLines(_planId),
      builder: (context, snapLines) {
        return FutureBuilder<Agreement?>(
          future: _db.getAgreementForPlan(_planId),
          builder: (context, snapAgr) {
            final lines = snapLines.data ?? [];
            final agr = snapAgr.data;
            if (lines.isEmpty || agr == null) {
              return const Center(child: Text('Add expenses first.'));
            }
            final pids = _allParticipantIds();
            final lastIdx = pids.length - 1;
            final isLast = _ratioParticipantIndex >= lastIdx;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    isLast
                        ? '${_ratioParticipantLabel(_ratioParticipantIndex)} (remainder, read-only)'
                        : '${_ratioParticipantLabel(_ratioParticipantIndex)}: set your share of each expense',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: lines.length,
                    itemBuilder: (context, i) {
                      final line = lines[i];
                      final totalMinor = _lineTotalMinor(line, agr);
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
                          final wCur = weights[_ratioParticipantIndex];
                          final frac = assignable > 0 ? wCur / assignable : 0.0;
                          final amountThis = (totalMinor * wCur / 10000).round() / 100.0;

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
                                      Text(
                                        '${(totalMinor / 100).toStringAsFixed(2)} ${line.currency}',
                                        style: Theme.of(context).textTheme.titleSmall,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (!isLast)
                                    Slider(
                                      value: frac.clamp(0.0, 1.0),
                                      divisions: assignable > 0 ? assignable : 1,
                                      onChanged: assignable <= 0
                                          ? null
                                          : (v) async {
                                              await _setRatioForParticipant(
                                                line,
                                                pids,
                                                _ratioParticipantIndex,
                                                v,
                                              );
                                              setState(() {});
                                            },
                                    )
                                  else
                                    Slider(
                                      value: (wCur / 10000).clamp(0.0, 1.0),
                                      onChanged: null,
                                    ),
                                  Text(
                                    'Share: ${(wCur / 100).toStringAsFixed(1)}%  →  $amountThis ${line.currency}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                FutureBuilder<double>(
                  future: _participantTotalMinor(pids[_ratioParticipantIndex], lines, agr),
                  builder: (context, snapT) {
                    final t = snapT.data ?? 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'Total for this participant: ${t.toStringAsFixed(2)} (plan currency minor / 100)',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (var i = 0; i < pids.length; i++)
                        ChoiceChip(
                          label: Text(_ratioParticipantLabel(i)),
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
    Agreement agr,
  ) async {
    var sum = 0;
    for (final line in lines) {
      final w = await _ratioWeight(line.id, participantId);
      final lineTot = _lineTotalMinor(line, agr);
      sum += (lineTot * w / 10000).round();
    }
    return sum / 100.0;
  }

  Widget _stepWithdrawal() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Early withdrawal rules (minimum notice and/or penalty).'),
        const SizedBox(height: 12),
        CheckboxListTile(
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
          title: const Text('Same rule for all participants'),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        if (_withdrawalSameForAll) ...[
          TextField(
            controller: _globalNotice,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Minimum notice (days)'),
            onChanged: (_) => setState(() {}),
          ),
          TextField(
            controller: _globalPenalty,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Penalty amount'),
            onChanged: (_) => setState(() {}),
          ),
        ] else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
            child: Text(
              '${_ratioParticipantLabel(_withdrawalParticipantIndex)}: notice and penalty',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          TextField(
            controller: _perParticipantNotice[_withdrawalParticipantIndex],
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Minimum notice (days)'),
            onChanged: (_) => setState(() {}),
          ),
          TextField(
            controller: _perParticipantPenalty[_withdrawalParticipantIndex],
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Penalty amount'),
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
                    label: Text(_ratioParticipantLabel(i)),
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
      ],
    );
  }
}

class _SummaryView extends StatelessWidget {
  const _SummaryView({
    required this.db,
    required this.planId,
    required this.avatarIcons,
    required this.onEditPlan,
    required this.onInvite,
    required this.onDestroy,
  });

  final AppDatabase db;
  final String planId;
  final List<IconData> avatarIcons;
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
      ]),
      builder: (context, AsyncSnapshot<List<dynamic>> snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
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
        if (agr == null) return const Center(child: Text('Missing agreement'));

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: roster.length,
                itemBuilder: (context, i) {
                  final p = roster[i];
                  var planTotal = 0;
                  for (final line in lines) {
                    planTotal += _lineTot(line, agr);
                  }
                  var moneySum = 0;
                  for (final line in lines) {
                    final w = ratios
                        .where((r) => r.lineId == line.id && r.participantId == p.id)
                        .fold<int>(0, (a, r) => a + r.weight);
                    final lineTot = _lineTot(line, agr);
                    moneySum += (lineTot * w / 10000).round();
                  }
                  final sharePct =
                      planTotal > 0 ? (moneySum / planTotal) * 100 : 0.0;
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.displayName, style: Theme.of(context).textTheme.titleMedium),
                                Text('Share of plan total: ${sharePct.toStringAsFixed(1)}%'),
                                Text('Total amount: ${(moneySum / 100).toStringAsFixed(2)}'),
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
                  FilledButton.tonal(onPressed: onEditPlan, child: const Text('Edit plan')),
                  const SizedBox(height: 8),
                  FilledButton(onPressed: onInvite, child: const Text('Invite my participants')),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: onDestroy,
                    child: const Text('Destroy plan'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  static int _lineTot(PlanLine line, Agreement agr) {
    final months = PlanProjection.monthsCoveredInclusive(
      agr.periodStart,
      agr.periodEnd,
    ).clamp(0, 120);
    final unit = PlanProjection.unitMinor(line);
    if (line.isRecurring) return unit * months;
    return unit;
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
}

class _LineEditorDialog extends StatefulWidget {
  const _LineEditorDialog({this.initial});
  final PlanLine? initial;

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

  @override
  void initState() {
    super.initState();
    _dayOfMonth = widget.initial?.recurrenceDayOfMonth ?? 1;
    _currency = widget.initial?.currency ?? 'CAD';
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
    final canSave = _title.text.trim().isNotEmpty &&
        (!_isRecurring || (_dayOfMonth >= 1 && _dayOfMonth <= 31)) &&
        (_amountUsesRange ? _rangeValid() : _fixedOk);
    return AlertDialog(
      title: Text(widget.initial == null ? 'Add expense' : 'Edit expense'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              title: const Text('Recurring (monthly)'),
              value: _isRecurring,
              onChanged: (v) => setState(() => _isRecurring = v),
            ),
            SwitchListTile(
              title: const Text('Approximate amount (min–max range)'),
              subtitle: const Text('Off = single fixed amount'),
              value: _amountUsesRange,
              onChanged: (v) => setState(() => _amountUsesRange = v),
            ),
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _description,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
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
                decoration: const InputDecoration(labelText: 'Day of month'),
                items: [for (var d = 1; d <= 31; d++) DropdownMenuItem(value: d, child: Text('$d'))],
                onChanged: (v) => setState(() => _dayOfMonth = v ?? 1),
              ),
            ],
            if (_amountUsesRange) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _min,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Min amount'),
                onChanged: (_) => setState(() {}),
              ),
              TextField(
                controller: _max,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Max amount'),
                onChanged: (_) => setState(() {}),
              ),
            ] else ...[
              const SizedBox(height: 8),
              TextField(
                controller: _amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount (e.g. 1200.00)'),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
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
                    ),
                  );
                }
              : null,
          child: const Text('Save'),
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
