/// Drift table keys for full-device export/import (keep in sync with
/// `@DriftDatabase.tables` in `app_database.dart`).
abstract final class DeviceDataTableCatalog {
  /// Import/delete order: children before parents.
  static const List<String> orderedKeys = [
    'realizedExpenseAcceptances',
    'realizedExpenseAttachments',
    'realizedExpenses',
    'archivedPlanLineSnapshots',
    'housingParticipationDecisions',
    'housingParticipationChanges',
    'housingPaymentOverdueJournalEntries',
    'housingPlanMemberships',
    'housingInactiveParticipants',
    'planPeerEstablishments',
    'relayActivityLogEntries',
    'proposalResponses',
    'proposalRevisions',
    'proposalPackages',
    'agreements',
    'planRatios',
    'planGroups',
    'planLines',
    'planRatioTemplates',
    'participants',
    'plans',
    'pendingHandshakes',
    'contactInvitations',
    'contacts',
  ];
}
