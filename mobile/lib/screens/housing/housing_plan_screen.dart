import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;

import '../../db/app_database.dart';
import '../../housing/projection/plan_projection.dart';
import '../../housing/proposals/plan_contract_proposal_service.dart';
import '../../l10n/app_localizations.dart';

class HousingPlanScreen extends StatefulWidget {
  const HousingPlanScreen({super.key});

  @override
  State<HousingPlanScreen> createState() => _HousingPlanScreenState();
}

class _HousingPlanScreenState extends State<HousingPlanScreen> {
  late final AppDatabase _db = AppDatabase();
  late final PlanContractProposalService _proposals =
      PlanContractProposalService(_db);

  static const _planId = 'housing:default';
  static const _contractId = 'contract:housing:default';
  static const _localParticipantId = 'local';

  @override
  void dispose() {
    _db.close();
    super.dispose();
  }

  Future<void> _ensureSeed() async {
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
    final existing = await _db.listPlanLines(_planId);
    if (existing.isNotEmpty) return;

    await _db.upsertPlanLine(
      PlanLinesCompanion.insert(
        id: 'line:rent',
        planId: _planId,
        isRecurring: true,
        title: 'Rent',
        currency: 'CAD',
        amountMinor: drift.Value(120000),
        minAmountMinor: const drift.Value.absent(),
        maxAmountMinor: const drift.Value.absent(),
        cadence: drift.Value('monthly'),
        groupId: const drift.Value.absent(),
        createdAt: DateTime.now().toUtc(),
      ),
    );

    // Seed a minimal contract so preview can work.
    await _db.upsertContract(
      AgreementContractsCompanion.insert(
        id: _contractId,
        planId: _planId,
        periodStart: DateTime.now().toUtc(),
        periodEnd: DateTime.now().toUtc().add(const Duration(days: 30 * 6)),
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }

  Stream<List<PlanLine>> _watchLines() => (_db.select(_db.planLines)
        ..where((t) => t.planId.equals(_planId))
        ..orderBy([(t) => drift.OrderingTerm.asc(t.createdAt)]))
      .watch();

  Stream<AgreementContract?> _watchContract() => (_db.select(_db.agreementContracts)
        ..where((t) => t.planId.equals(_planId)))
      .watchSingleOrNull();

  Stream<ProposalPackage?> _watchProposalPackage() => (_db.select(_db.proposalPackages)
        ..where((t) => t.planId.equals(_planId)))
      .watchSingleOrNull();

  Stream<List<ProposalResponse>> _watchResponses(String revisionId) =>
      (_db.select(_db.proposalResponses)
            ..where((t) => t.revisionId.equals(revisionId)))
          .watch();

  Future<void> _proposeCurrent() async {
    await _ensureSeed();
    await _db.upsertParticipant(
      ParticipantsCompanion.insert(
        id: _localParticipantId,
        displayName: 'Local',
        avatarId: 'mdi:local',
        createdAt: DateTime.now().toUtc(),
      ),
    );
    await _proposals.createRevisionFromCurrentDraft(
      planId: _planId,
      proposerParticipantId: _localParticipantId,
    );
  }

  Future<void> _respondToPending({
    required ProposalResponseStatus status,
    required String revisionId,
  }) async {
    await _proposals.recordResponse(
      revisionId: revisionId,
      participantId: _localParticipantId,
      status: status,
    );
    final participants = await _db.listParticipants();
    await _proposals.tryActivateIfUnanimous(
      planId: _planId,
      revisionId: revisionId,
      participantIds: participants.map((p) => p.id).toList(),
    );
  }

  Future<void> _addOrEditLine({PlanLine? existing}) async {
    final result = await showDialog<_LineDraft>(
      context: context,
      builder: (context) => _LineEditorDialog(initial: existing),
    );
    if (result == null) return;

    final now = DateTime.now().toUtc();
    final id = existing?.id ?? 'line:${now.microsecondsSinceEpoch}';
    await _db.upsertPlanLine(
      PlanLinesCompanion.insert(
        id: id,
        planId: _planId,
        isRecurring: result.isRecurring,
        title: result.title,
        currency: result.currency,
        amountMinor: result.isRecurring
            ? drift.Value(result.amountMinor)
            : const drift.Value.absent(),
        minAmountMinor: result.isRecurring
            ? const drift.Value.absent()
            : drift.Value(result.minMinor),
        maxAmountMinor: result.isRecurring
            ? const drift.Value.absent()
            : drift.Value(result.maxMinor),
        cadence: drift.Value(result.cadence),
        groupId: const drift.Value.absent(),
        createdAt: existing?.createdAt ?? now,
      ),
    );
  }

  Future<void> _deleteLine(PlanLine line) async {
    await (_db.delete(_db.planLines)..where((t) => t.id.equals(line.id))).go();
  }

  Future<void> _editContract(AgreementContract? existing) async {
    final result = await showDialog<_ContractDraft>(
      context: context,
      builder: (context) => _ContractEditorDialog(initial: existing),
    );
    if (result == null) return;
    final now = DateTime.now().toUtc();
    await _db.upsertContract(
      AgreementContractsCompanion.insert(
        id: existing?.id ?? _contractId,
        planId: _planId,
        periodStart: result.periodStart,
        periodEnd: result.periodEnd,
        minNoticeDays: drift.Value(result.minNoticeDays),
        penaltyMinor: drift.Value(result.penaltyMinor),
        clauses: drift.Value(result.clauses),
        version: drift.Value(existing?.version ?? 1),
        createdAt: existing?.createdAt ?? now,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeHousingPlan)),
      body: FutureBuilder(
        future: _ensureSeed(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return DefaultTabController(
            length: 3,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'Plan'),
                    Tab(text: 'Contract'),
                    Tab(text: 'Preview'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _PlanTab(
                        lines: _watchLines(),
                        onAdd: () => _addOrEditLine(),
                        onEdit: (line) => _addOrEditLine(existing: line),
                        onDelete: _deleteLine,
                        onPropose: _proposeCurrent,
                        proposalPackage: _watchProposalPackage(),
                        responsesForRevision: _watchResponses,
                        onRespond: _respondToPending,
                      ),
                      _ContractTab(
                        contract: _watchContract(),
                        onEdit: _editContract,
                      ),
                      _PreviewTab(
                        lines: _watchLines(),
                        contract: _watchContract(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addOrEditLine,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _PlanTab extends StatelessWidget {
  const _PlanTab({
    required this.lines,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onPropose,
    required this.proposalPackage,
    required this.responsesForRevision,
    required this.onRespond,
  });

  final Stream<List<PlanLine>> lines;
  final VoidCallback onAdd;
  final void Function(PlanLine line) onEdit;
  final void Function(PlanLine line) onDelete;
  final Future<void> Function() onPropose;
  final Stream<ProposalPackage?> proposalPackage;
  final Stream<List<ProposalResponse>> Function(String revisionId)
      responsesForRevision;
  final Future<void> Function({
    required ProposalResponseStatus status,
    required String revisionId,
  }) onRespond;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: lines,
      builder: (context, AsyncSnapshot<List<PlanLine>> s) {
        final items = s.data ?? const <PlanLine>[];
        final missing = items.isEmpty;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Draft plan editor',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (missing)
              const Text('Add at least one line item to start.'),
            StreamBuilder(
              stream: proposalPackage,
              builder: (context, AsyncSnapshot<ProposalPackage?> ps) {
                final pkg = ps.data;
                final pending = pkg?.pendingRevisionId;
                final active = pkg?.activeRevisionId;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Proposal status',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 6),
                        Text('Active revision: ${active ?? '—'}'),
                        Text('Pending revision: ${pending ?? '—'}'),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            FilledButton(
                              onPressed: onPropose,
                              child: const Text('Propose current draft'),
                            ),
                            const SizedBox(width: 8),
                            if (pending != null) ...[
                              OutlinedButton(
                                onPressed: () => onRespond(
                                  status: ProposalResponseStatus.accepted,
                                  revisionId: pending,
                                ),
                                child: const Text('Accept'),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: () => onRespond(
                                  status: ProposalResponseStatus.rejected,
                                  revisionId: pending,
                                ),
                                child: const Text('Reject'),
                              ),
                            ],
                          ],
                        ),
                        if (pending != null) ...[
                          const SizedBox(height: 8),
                          StreamBuilder(
                            stream: responsesForRevision(pending),
                            builder: (context,
                                AsyncSnapshot<List<ProposalResponse>> rs) {
                              final responses =
                                  rs.data ?? const <ProposalResponse>[];
                              if (responses.isEmpty) {
                                return const Text('No responses yet.');
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Responses:'),
                                  for (final r in responses)
                                    Text('${r.participantId}: ${r.status}'),
                                ],
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
            for (final line in items)
              Card(
                child: ListTile(
                  title: Text(line.title),
                  subtitle: Text(
                    line.isRecurring
                        ? 'Recurring • ${(line.amountMinor ?? 0) / 100} ${line.currency} / ${line.cadence}'
                        : 'One-off • ${(line.minAmountMinor ?? 0) / 100}–${(line.maxAmountMinor ?? 0) / 100} ${line.currency}',
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') onEdit(line);
                      if (value == 'delete') onDelete(line);
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                  onTap: () => onEdit(line),
                ),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onAdd,
              child: const Text('Add line'),
            ),
          ],
        );
      },
    );
  }
}

class _ContractTab extends StatelessWidget {
  const _ContractTab({
    required this.contract,
    required this.onEdit,
  });

  final Stream<AgreementContract?> contract;
  final void Function(AgreementContract? contract) onEdit;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: contract,
      builder: (context, AsyncSnapshot<AgreementContract?> s) {
        final c = s.data;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Agreement contract',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (c == null)
              const Text('No contract set yet.'),
            if (c != null) ...[
              ListTile(
                title: const Text('Period'),
                subtitle: Text('${c.periodStart.toIso8601String()} → ${c.periodEnd.toIso8601String()}'),
              ),
              ListTile(
                title: const Text('Minimum notice (days)'),
                subtitle: Text('${c.minNoticeDays}'),
              ),
              ListTile(
                title: const Text('Penalty (minor units)'),
                subtitle: Text('${c.penaltyMinor}'),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => onEdit(c),
              child: const Text('Edit contract'),
            ),
          ],
        );
      },
    );
  }
}

class _PreviewTab extends StatelessWidget {
  const _PreviewTab({
    required this.lines,
    required this.contract,
  });

  final Stream<List<PlanLine>> lines;
  final Stream<AgreementContract?> contract;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: contract,
      builder: (context, AsyncSnapshot<AgreementContract?> cs) {
        final c = cs.data;
        return StreamBuilder(
          stream: lines,
          builder: (context, AsyncSnapshot<List<PlanLine>> ls) {
            final items = ls.data ?? const <PlanLine>[];
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Preview only • Not binding until accepted'),
                  ),
                ),
                const SizedBox(height: 12),
                if (c == null)
                  const Text('Set a contract period to see projections.'),
                if (c != null) ...[
                  Text(
                    'Period: ${c.periodStart.toIso8601String()} → ${c.periodEnd.toIso8601String()}',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Projected total (single participant placeholder): ${PlanProjection.projectTotalMinor(lines: items, contract: c) / 100}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

class _LineDraft {
  const _LineDraft({
    required this.title,
    required this.currency,
    required this.isRecurring,
    required this.amountMinor,
    required this.minMinor,
    required this.maxMinor,
    required this.cadence,
  });

  final String title;
  final String currency;
  final bool isRecurring;
  final int amountMinor;
  final int minMinor;
  final int maxMinor;
  final String cadence;
}

class _LineEditorDialog extends StatefulWidget {
  const _LineEditorDialog({this.initial});
  final PlanLine? initial;

  @override
  State<_LineEditorDialog> createState() => _LineEditorDialogState();
}

class _LineEditorDialogState extends State<_LineEditorDialog> {
  late bool _isRecurring = widget.initial?.isRecurring ?? true;
  late final TextEditingController _title =
      TextEditingController(text: widget.initial?.title ?? '');
  late final TextEditingController _amount =
      TextEditingController(text: _minorToText(widget.initial?.amountMinor));
  late final TextEditingController _min =
      TextEditingController(text: _minorToText(widget.initial?.minAmountMinor));
  late final TextEditingController _max =
      TextEditingController(text: _minorToText(widget.initial?.maxAmountMinor));

  String _currency = 'CAD';

  @override
  void initState() {
    super.initState();
    _currency = widget.initial?.currency ?? 'CAD';
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _title.text.trim().isNotEmpty &&
        (_isRecurring ? _parseMinor(_amount.text) != null : _rangeValid());
    return AlertDialog(
      title: Text(widget.initial == null ? 'Add line' : 'Edit line'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Recurring'),
              value: _isRecurring,
              onChanged: (v) => setState(() => _isRecurring = v),
            ),
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
              onChanged: (_) => setState(() {}),
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Currency (ISO)'),
              controller: TextEditingController(text: _currency),
              readOnly: true,
            ),
            if (_isRecurring)
              TextField(
                controller: _amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount (e.g. 1200.00)'),
                onChanged: (_) => setState(() {}),
              )
            else ...[
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
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: canSave
              ? () {
                  final amt = _parseMinor(_amount.text) ?? 0;
                  final minV = _parseMinor(_min.text) ?? 0;
                  final maxV = _parseMinor(_max.text) ?? 0;
                  Navigator.of(context).pop(
                    _LineDraft(
                      title: _title.text.trim(),
                      currency: _currency,
                      isRecurring: _isRecurring,
                      amountMinor: amt,
                      minMinor: minV,
                      maxMinor: maxV,
                      cadence: 'monthly',
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

class _ContractDraft {
  const _ContractDraft({
    required this.periodStart,
    required this.periodEnd,
    required this.minNoticeDays,
    required this.penaltyMinor,
    required this.clauses,
  });

  final DateTime periodStart;
  final DateTime periodEnd;
  final int minNoticeDays;
  final int penaltyMinor;
  final String clauses;
}

class _ContractEditorDialog extends StatefulWidget {
  const _ContractEditorDialog({this.initial});
  final AgreementContract? initial;

  @override
  State<_ContractEditorDialog> createState() => _ContractEditorDialogState();
}

class _ContractEditorDialogState extends State<_ContractEditorDialog> {
  late DateTime _start = widget.initial?.periodStart ?? DateTime.now().toUtc();
  late DateTime _end =
      widget.initial?.periodEnd ?? DateTime.now().toUtc().add(const Duration(days: 30));
  late final TextEditingController _notice =
      TextEditingController(text: (widget.initial?.minNoticeDays ?? 0).toString());
  late final TextEditingController _penalty =
      TextEditingController(text: _minorToText(widget.initial?.penaltyMinor ?? 0));
  late final TextEditingController _clauses =
      TextEditingController(text: widget.initial?.clauses ?? '');

  @override
  void dispose() {
    _notice.dispose();
    _penalty.dispose();
    _clauses.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notice = int.tryParse(_notice.text.trim()) ?? 0;
    final penalty = _parseMinor(_penalty.text) ?? 0;
    final validFloor = notice > 0 || penalty > 0;
    final validPeriod = _start.isBefore(_end);
    final canSave = validFloor && validPeriod;

    return AlertDialog(
      title: const Text('Edit contract'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Start date'),
              subtitle: Text(_start.toIso8601String()),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                  initialDate: _start.toLocal(),
                );
                if (picked == null) return;
                setState(() => _start = DateTime(picked.year, picked.month, picked.day).toUtc());
              },
            ),
            ListTile(
              title: const Text('End date'),
              subtitle: Text(_end.toIso8601String()),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                  initialDate: _end.toLocal(),
                );
                if (picked == null) return;
                setState(() => _end = DateTime(picked.year, picked.month, picked.day).toUtc());
              },
            ),
            TextField(
              controller: _notice,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Min notice days'),
              onChanged: (_) => setState(() {}),
            ),
            TextField(
              controller: _penalty,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Penalty amount'),
              onChanged: (_) => setState(() {}),
            ),
            TextField(
              controller: _clauses,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Optional clauses'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            if (!validPeriod)
              const Text('End date must be after start date.'),
            if (!validFloor)
              const Text('Set either min notice or penalty (or both).'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: canSave
              ? () {
                  Navigator.of(context).pop(
                    _ContractDraft(
                      periodStart: _start,
                      periodEnd: _end,
                      minNoticeDays: notice,
                      penaltyMinor: penalty,
                      clauses: _clauses.text.trim(),
                    ),
                  );
                }
              : null,
          child: const Text('Save'),
        ),
      ],
    );
  }

  int? _parseMinor(String text) {
    final t = text.trim().replaceAll(',', '.');
    if (t.isEmpty) return 0;
    final v = double.tryParse(t);
    if (v == null) return null;
    return (v * 100).round();
  }

  String _minorToText(int minor) => (minor / 100).toStringAsFixed(2);
}

