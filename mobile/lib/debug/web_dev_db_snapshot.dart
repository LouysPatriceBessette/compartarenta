import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../db/app_database.dart';

/// Debug-only full Drift export/import for web dev host session persistence.
const int kWebDevHostSessionVersion = 2;

Future<Map<String, dynamic>> exportDriftTablesSnapshot(AppDatabase db) async {
  return {
    'plans': (await db.select(db.plans).get()).map((r) => r.toJson()).toList(),
    'participants': (await db.select(db.participants).get())
        .map((r) => r.toJson())
        .toList(),
    'planLines': (await db.select(db.planLines).get())
        .map((r) => r.toJson())
        .toList(),
    'planGroups': (await db.select(db.planGroups).get())
        .map((r) => r.toJson())
        .toList(),
    'planRatios': (await db.select(db.planRatios).get())
        .map((r) => r.toJson())
        .toList(),
    'planRatioTemplates': (await db.select(db.planRatioTemplates).get())
        .map((r) => r.toJson())
        .toList(),
    'agreements': (await db.select(db.agreements).get())
        .map((r) => r.toJson())
        .toList(),
    'proposalPackages': (await db.select(db.proposalPackages).get())
        .map((r) => r.toJson())
        .toList(),
    'proposalRevisions': (await db.select(db.proposalRevisions).get())
        .map((r) => r.toJson())
        .toList(),
    'proposalResponses': (await db.select(db.proposalResponses).get())
        .map((r) => r.toJson())
        .toList(),
    'contacts': (await db.select(db.contacts).get())
        .map((r) => r.toJson())
        .toList(),
    'contactInvitations': (await db.select(db.contactInvitations).get())
        .map((r) => r.toJson())
        .toList(),
    'pendingHandshakes': (await db.select(db.pendingHandshakes).get())
        .map((r) => r.toJson())
        .toList(),
    'relayActivityLogEntries': (await db.select(db.relayActivityLogEntries).get())
        .map((r) => r.toJson())
        .toList(),
    'realizedExpenses': (await db.select(db.realizedExpenses).get())
        .map((r) => r.toJson())
        .toList(),
    'realizedExpenseAttachments':
        (await db.select(db.realizedExpenseAttachments).get())
            .map((r) => r.toJson())
            .toList(),
    'realizedExpenseAcceptances':
        (await db.select(db.realizedExpenseAcceptances).get())
            .map((r) => r.toJson())
            .toList(),
  };
}

Future<void> importDriftTablesSnapshot(
  AppDatabase db,
  Map<String, dynamic> tables,
) async {
  if (!kDebugMode) return;

  await db.transaction(() async {
    await _clearAllDevTables(db);
    await _importRows(db, tables);
  });
  await db.syncWebStorageToDisk();
}

Future<void> _clearAllDevTables(AppDatabase db) async {
  await db.delete(db.realizedExpenseAcceptances).go();
  await db.delete(db.realizedExpenseAttachments).go();
  await db.delete(db.realizedExpenses).go();
  await db.delete(db.relayActivityLogEntries).go();
  await db.delete(db.proposalResponses).go();
  await db.delete(db.proposalRevisions).go();
  await db.delete(db.proposalPackages).go();
  await db.delete(db.agreements).go();
  await db.delete(db.planRatios).go();
  await db.delete(db.planGroups).go();
  await db.delete(db.planLines).go();
  await db.delete(db.planRatioTemplates).go();
  await db.delete(db.participants).go();
  await db.delete(db.plans).go();
  await db.delete(db.pendingHandshakes).go();
  await db.delete(db.contactInvitations).go();
  await db.delete(db.contacts).go();
}

Future<void> _importRows(AppDatabase db, Map<String, dynamic> tables) async {
  await _importTable(db, db.plans, tables['plans'], Plan.fromJson);
  await _importTable(
    db,
    db.participants,
    tables['participants'],
    Participant.fromJson,
  );
  await _importTable(db, db.planLines, tables['planLines'], PlanLine.fromJson);
  await _importTable(
    db,
    db.planGroups,
    tables['planGroups'],
    PlanGroup.fromJson,
  );
  await _importTable(
    db,
    db.planRatios,
    tables['planRatios'],
    PlanRatio.fromJson,
  );
  await _importTable(
    db,
    db.planRatioTemplates,
    tables['planRatioTemplates'],
    PlanRatioTemplate.fromJson,
  );
  await _importTable(
    db,
    db.agreements,
    tables['agreements'],
    Agreement.fromJson,
  );
  await _importTable(
    db,
    db.proposalPackages,
    tables['proposalPackages'],
    ProposalPackage.fromJson,
  );
  await _importTable(
    db,
    db.proposalRevisions,
    tables['proposalRevisions'],
    ProposalRevision.fromJson,
  );
  await _importTable(
    db,
    db.proposalResponses,
    tables['proposalResponses'],
    ProposalResponse.fromJson,
  );
  await _importTable(db, db.contacts, tables['contacts'], Contact.fromJson);
  await _importTable(
    db,
    db.contactInvitations,
    tables['contactInvitations'],
    ContactInvitation.fromJson,
  );
  await _importTable(
    db,
    db.pendingHandshakes,
    tables['pendingHandshakes'],
    PendingHandshake.fromJson,
  );
  await _importTable(
    db,
    db.relayActivityLogEntries,
    tables['relayActivityLogEntries'],
    RelayActivityLogEntry.fromJson,
  );
  await _importTable(
    db,
    db.realizedExpenses,
    tables['realizedExpenses'],
    RealizedExpense.fromJson,
  );
  await _importTable(
    db,
    db.realizedExpenseAttachments,
    tables['realizedExpenseAttachments'],
    RealizedExpenseAttachment.fromJson,
  );
  await _importTable(
    db,
    db.realizedExpenseAcceptances,
    tables['realizedExpenseAcceptances'],
    RealizedExpenseAcceptance.fromJson,
  );
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
