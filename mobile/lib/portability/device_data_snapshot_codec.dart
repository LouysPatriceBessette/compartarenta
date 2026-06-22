import 'package:drift/drift.dart';

import '../db/app_database.dart';
import 'device_data_table_catalog.dart';

Future<Map<String, List<Map<String, dynamic>>>> exportDeviceDataTables(
  AppDatabase db,
) async {
  final tables = <String, List<Map<String, dynamic>>>{};
  for (final key in DeviceDataTableCatalog.orderedKeys) {
    tables[key] = await _exportTable(db, key);
  }
  return tables;
}

Future<bool> deviceOperationalDataIsEmpty(AppDatabase db) async {
  for (final key in DeviceDataTableCatalog.orderedKeys) {
    final rows = await _exportTable(db, key);
    if (rows.isNotEmpty) return false;
  }
  return true;
}

Future<void> wipeDeviceOperationalTables(AppDatabase db) async {
  for (final key in DeviceDataTableCatalog.orderedKeys) {
    await _deleteTable(db, key);
  }
}

Future<void> importDeviceDataTables(
  AppDatabase db,
  Map<String, dynamic> tables,
) async {
  await db.transaction(() async {
    await wipeDeviceOperationalTables(db);
    for (final key in DeviceDataTableCatalog.orderedKeys) {
      await _importTableKey(db, key, tables[key]);
    }
  });
}

Future<List<Map<String, dynamic>>> _exportTable(
  AppDatabase db,
  String key,
) async {
  switch (key) {
    case 'plans':
      return (await db.select(db.plans).get()).map((r) => r.toJson()).toList();
    case 'participants':
      return (await db.select(db.participants).get())
          .map((r) => r.toJson())
          .toList();
    case 'planLines':
      return (await db.select(db.planLines).get())
          .map((r) => r.toJson())
          .toList();
    case 'planGroups':
      return (await db.select(db.planGroups).get())
          .map((r) => r.toJson())
          .toList();
    case 'planRatios':
      return (await db.select(db.planRatios).get())
          .map((r) => r.toJson())
          .toList();
    case 'planRatioTemplates':
      return (await db.select(db.planRatioTemplates).get())
          .map((r) => r.toJson())
          .toList();
    case 'agreements':
      return (await db.select(db.agreements).get())
          .map((r) => r.toJson())
          .toList();
    case 'proposalPackages':
      return (await db.select(db.proposalPackages).get())
          .map((r) => r.toJson())
          .toList();
    case 'proposalRevisions':
      return (await db.select(db.proposalRevisions).get())
          .map((r) => r.toJson())
          .toList();
    case 'proposalResponses':
      return (await db.select(db.proposalResponses).get())
          .map((r) => r.toJson())
          .toList();
    case 'contacts':
      return (await db.select(db.contacts).get())
          .map((r) => r.toJson())
          .toList();
    case 'contactInvitations':
      return (await db.select(db.contactInvitations).get())
          .map((r) => r.toJson())
          .toList();
    case 'pendingHandshakes':
      return (await db.select(db.pendingHandshakes).get())
          .map((r) => r.toJson())
          .toList();
    case 'relayActivityLogEntries':
      return (await db.select(db.relayActivityLogEntries).get())
          .map((r) => r.toJson())
          .toList();
    case 'realizedExpenses':
      return (await db.select(db.realizedExpenses).get())
          .map((r) => r.toJson())
          .toList();
    case 'realizedExpenseAttachments':
      return (await db.select(db.realizedExpenseAttachments).get())
          .map((r) => r.toJson())
          .toList();
    case 'realizedExpenseAcceptances':
      return (await db.select(db.realizedExpenseAcceptances).get())
          .map((r) => r.toJson())
          .toList();
    case 'archivedPlanLineSnapshots':
      return (await db.select(db.archivedPlanLineSnapshots).get())
          .map((r) => r.toJson())
          .toList();
    case 'housingParticipationChanges':
      return (await db.select(db.housingParticipationChanges).get())
          .map((r) => r.toJson())
          .toList();
    case 'housingParticipationDecisions':
      return (await db.select(db.housingParticipationDecisions).get())
          .map((r) => r.toJson())
          .toList();
    case 'housingPlanMemberships':
      return (await db.select(db.housingPlanMemberships).get())
          .map((r) => r.toJson())
          .toList();
    case 'housingInactiveParticipants':
      return (await db.select(db.housingInactiveParticipants).get())
          .map((r) => r.toJson())
          .toList();
    case 'housingPaymentOverdueJournalEntries':
      return (await db.select(db.housingPaymentOverdueJournalEntries).get())
          .map((r) => r.toJson())
          .toList();
    case 'planPeerEstablishments':
      return (await db.select(db.planPeerEstablishments).get())
          .map((r) => r.toJson())
          .toList();
    default:
      throw StateError('Unknown device data table key: $key');
  }
}

Future<void> _deleteTable(AppDatabase db, String key) async {
  switch (key) {
    case 'plans':
      await db.delete(db.plans).go();
    case 'participants':
      await db.delete(db.participants).go();
    case 'planLines':
      await db.delete(db.planLines).go();
    case 'planGroups':
      await db.delete(db.planGroups).go();
    case 'planRatios':
      await db.delete(db.planRatios).go();
    case 'planRatioTemplates':
      await db.delete(db.planRatioTemplates).go();
    case 'agreements':
      await db.delete(db.agreements).go();
    case 'proposalPackages':
      await db.delete(db.proposalPackages).go();
    case 'proposalRevisions':
      await db.delete(db.proposalRevisions).go();
    case 'proposalResponses':
      await db.delete(db.proposalResponses).go();
    case 'contacts':
      await db.delete(db.contacts).go();
    case 'contactInvitations':
      await db.delete(db.contactInvitations).go();
    case 'pendingHandshakes':
      await db.delete(db.pendingHandshakes).go();
    case 'relayActivityLogEntries':
      await db.delete(db.relayActivityLogEntries).go();
    case 'realizedExpenses':
      await db.delete(db.realizedExpenses).go();
    case 'realizedExpenseAttachments':
      await db.delete(db.realizedExpenseAttachments).go();
    case 'realizedExpenseAcceptances':
      await db.delete(db.realizedExpenseAcceptances).go();
    case 'archivedPlanLineSnapshots':
      await db.delete(db.archivedPlanLineSnapshots).go();
    case 'housingParticipationChanges':
      await db.delete(db.housingParticipationChanges).go();
    case 'housingParticipationDecisions':
      await db.delete(db.housingParticipationDecisions).go();
    case 'housingPlanMemberships':
      await db.delete(db.housingPlanMemberships).go();
    case 'housingInactiveParticipants':
      await db.delete(db.housingInactiveParticipants).go();
    case 'housingPaymentOverdueJournalEntries':
      await db.delete(db.housingPaymentOverdueJournalEntries).go();
    case 'planPeerEstablishments':
      await db.delete(db.planPeerEstablishments).go();
    default:
      throw StateError('Unknown device data table key: $key');
  }
}

Future<void> _importTableKey(
  AppDatabase db,
  String key,
  Object? rawList,
) async {
  switch (key) {
    case 'plans':
      return _importTable(db, db.plans, rawList, Plan.fromJson);
    case 'participants':
      return _importTable(db, db.participants, rawList, Participant.fromJson);
    case 'planLines':
      return _importTable(db, db.planLines, rawList, PlanLine.fromJson);
    case 'planGroups':
      return _importTable(db, db.planGroups, rawList, PlanGroup.fromJson);
    case 'planRatios':
      return _importTable(db, db.planRatios, rawList, PlanRatio.fromJson);
    case 'planRatioTemplates':
      return _importTable(
        db,
        db.planRatioTemplates,
        rawList,
        PlanRatioTemplate.fromJson,
      );
    case 'agreements':
      return _importTable(db, db.agreements, rawList, Agreement.fromJson);
    case 'proposalPackages':
      return _importTable(
        db,
        db.proposalPackages,
        rawList,
        ProposalPackage.fromJson,
      );
    case 'proposalRevisions':
      return _importTable(
        db,
        db.proposalRevisions,
        rawList,
        ProposalRevision.fromJson,
      );
    case 'proposalResponses':
      return _importTable(
        db,
        db.proposalResponses,
        rawList,
        ProposalResponse.fromJson,
      );
    case 'contacts':
      return _importTable(db, db.contacts, rawList, Contact.fromJson);
    case 'contactInvitations':
      return _importTable(
        db,
        db.contactInvitations,
        rawList,
        ContactInvitation.fromJson,
      );
    case 'pendingHandshakes':
      return _importTable(
        db,
        db.pendingHandshakes,
        rawList,
        PendingHandshake.fromJson,
      );
    case 'relayActivityLogEntries':
      return _importTable(
        db,
        db.relayActivityLogEntries,
        rawList,
        RelayActivityLogEntry.fromJson,
      );
    case 'realizedExpenses':
      return _importTable(
        db,
        db.realizedExpenses,
        rawList,
        RealizedExpense.fromJson,
      );
    case 'realizedExpenseAttachments':
      return _importTable(
        db,
        db.realizedExpenseAttachments,
        rawList,
        RealizedExpenseAttachment.fromJson,
      );
    case 'realizedExpenseAcceptances':
      return _importTable(
        db,
        db.realizedExpenseAcceptances,
        rawList,
        RealizedExpenseAcceptance.fromJson,
      );
    case 'archivedPlanLineSnapshots':
      return _importTable(
        db,
        db.archivedPlanLineSnapshots,
        rawList,
        ArchivedPlanLineSnapshot.fromJson,
      );
    case 'housingParticipationChanges':
      return _importTable(
        db,
        db.housingParticipationChanges,
        rawList,
        HousingParticipationChange.fromJson,
      );
    case 'housingParticipationDecisions':
      return _importTable(
        db,
        db.housingParticipationDecisions,
        rawList,
        HousingParticipationDecision.fromJson,
      );
    case 'housingPlanMemberships':
      return _importTable(
        db,
        db.housingPlanMemberships,
        rawList,
        HousingPlanMembership.fromJson,
      );
    case 'housingInactiveParticipants':
      return _importTable(
        db,
        db.housingInactiveParticipants,
        rawList,
        HousingInactiveParticipant.fromJson,
      );
    case 'housingPaymentOverdueJournalEntries':
      return _importTable(
        db,
        db.housingPaymentOverdueJournalEntries,
        rawList,
        HousingPaymentOverdueJournalEntry.fromJson,
      );
    case 'planPeerEstablishments':
      return _importTable(
        db,
        db.planPeerEstablishments,
        rawList,
        PlanPeerEstablishment.fromJson,
      );
    default:
      throw StateError('Unknown device data table key: $key');
  }
}

Future<void> _importTable(
  AppDatabase db,
  TableInfo<Table, DataClass> table,
  Object? rawList,
  DataClass Function(Map<String, dynamic> json) fromJson,
) async {
  if (rawList is! List<dynamic>) return;
  for (final entry in rawList) {
    if (entry is! Map<String, dynamic>) continue;
    final row = fromJson(entry);
    final insertable =
        (row as dynamic).toCompanion(true) as Insertable<DataClass>;
    await db.into(table).insertOnConflictUpdate(insertable);
  }
}
