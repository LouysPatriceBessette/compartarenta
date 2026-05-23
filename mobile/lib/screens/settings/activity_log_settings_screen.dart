import 'package:flutter/material.dart';

import '../../activity/relay_activity_log_service.dart';
import '../../db/app_database.dart';
import '../../l10n/app_localizations.dart';
import '../../util/display_date.dart';
import '../../prefs/app_preferences.dart';

class ActivityLogSettingsScreen extends StatefulWidget {
  const ActivityLogSettingsScreen({super.key, required this.prefs});

  final AppPreferences prefs;

  @override
  State<ActivityLogSettingsScreen> createState() =>
      _ActivityLogSettingsScreenState();
}

class _ActivityLogSettingsScreenState extends State<ActivityLogSettingsScreen> {
  final _db = AppDatabase.processScope;
  late Future<List<RelayActivityLogEntry>> _load = _fetch();

  String? _initiatorFilter;
  String? _contactIdFilter;
  DateTime? _fromUtc;
  DateTime? _toUtc;

  Future<List<RelayActivityLogEntry>> _fetch() {
    return RelayActivityLogService(_db).listFiltered(
      fromUtc: _fromUtc,
      toUtc: _toUtc,
      initiatorKind: _initiatorFilter,
      initiatorContactId: _contactIdFilter,
    );
  }

  void _reload() => setState(() => _load = _fetch());

  String _kindLabel(AppLocalizations l10n, String kind) => switch (kind) {
        RelayActivityLogKinds.contactHandshakeReceived =>
          l10n.activityLogKindContactHandshakeReceived,
        RelayActivityLogKinds.contactDisconnected =>
          l10n.activityLogKindContactDisconnected,
        RelayActivityLogKinds.contactDeleted =>
          l10n.activityLogKindContactDeleted,
        RelayActivityLogKinds.housingProposalSent =>
          l10n.activityLogKindHousingProposalSent,
        RelayActivityLogKinds.housingProposalReceived =>
          l10n.activityLogKindHousingProposalReceived,
        RelayActivityLogKinds.housingProposalResponse =>
          l10n.activityLogKindHousingProposalResponse,
        RelayActivityLogKinds.housingProposalInvalidated =>
          l10n.activityLogKindHousingProposalInvalidated,
        RelayActivityLogKinds.housingProposalExpired =>
          l10n.activityLogKindHousingProposalExpired,
        RelayActivityLogKinds.housingProposalForkCreated =>
          l10n.activityLogKindHousingProposalForkCreated,
        _ => kind,
      };

  String _initiatorLabel(AppLocalizations l10n, RelayActivityLogEntry row) {
    return switch (row.initiatorKind) {
      RelayActivityLogService.initiatorSelf => l10n.activityLogFilterInitiatorSelf,
      RelayActivityLogService.initiatorContact =>
        row.initiatorDisplayName.isNotEmpty
            ? row.initiatorDisplayName
            : (row.initiatorContactId ?? l10n.activityLogFilterInitiatorContact),
      _ => row.initiatorDisplayName.isNotEmpty
          ? row.initiatorDisplayName
          : row.initiatorKind,
    };
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = (isFrom ? _fromUtc : _toUtc)?.toLocal() ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    final utc = DateTime(picked.year, picked.month, picked.day).toUtc();
    setState(() {
      if (isFrom) {
        _fromUtc = utc;
      } else {
        _toUtc = DateTime.utc(
          picked.year,
          picked.month,
          picked.day,
          23,
          59,
          59,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateFmt = effectiveDateFormat(widget.prefs);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsActivityLogTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String?>(
                  key: ValueKey<String?>(_initiatorFilter),
                  initialValue: _initiatorFilter,
                  decoration: InputDecoration(
                    labelText: l10n.activityLogFilterInitiatorLabel,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(l10n.activityLogFilterInitiatorAll),
                    ),
                    DropdownMenuItem(
                      value: RelayActivityLogService.initiatorSelf,
                      child: Text(l10n.activityLogFilterInitiatorSelf),
                    ),
                    DropdownMenuItem(
                      value: RelayActivityLogService.initiatorContact,
                      child: Text(l10n.activityLogFilterInitiatorContact),
                    ),
                  ],
                  onChanged: (v) => setState(() {
                    _initiatorFilter = v;
                    _contactIdFilter = null;
                  }),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pickDate(isFrom: true),
                        child: Text(
                          _fromUtc == null
                              ? l10n.activityLogFilterFromLabel
                              : formatPreferenceDate(_fromUtc, dateFmt),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pickDate(isFrom: false),
                        child: Text(
                          _toUtc == null
                              ? l10n.activityLogFilterToLabel
                              : formatPreferenceDate(_toUtc, dateFmt),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _reload,
                  child: Text(l10n.activityLogApplyFilters),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<RelayActivityLogEntry>>(
              future: _load,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final rows = snap.data!;
                if (rows.isEmpty) {
                  return Center(child: Text(l10n.activityLogEmpty));
                }
                return ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    final when = formatPreferenceDateTime(
                      row.occurredAt,
                      dateFmt,
                    );
                    return ListTile(
                      title: Text(_kindLabel(l10n, row.kind)),
                      subtitle: Text(
                        '${_initiatorLabel(l10n, row)}\n$when',
                      ),
                      isThreeLine: true,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
