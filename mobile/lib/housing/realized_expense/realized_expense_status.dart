/// Lifecycle status for a realized expense on this device.
class RealizedExpenseStatus {
  static const String draft = 'draft';
  static const String proposed = 'proposed';
  static const String accepted = 'accepted';
  static const String published = 'published';
  static const String rejected = 'rejected';
}

/// Payment kind for a realized expense.
class RealizedExpenseKind {
  static const String normal = 'normal';
  static const String reimbursement = 'reimbursement';
  static const String advance = 'advance';
  static const String transfer = 'transfer';

  static bool usesPlanLine(String kind) => kind == normal;

  static bool usesTransferParticipant(String kind) =>
      kind == transfer || kind == reimbursement;

  static String normalizeForForm(String kind) {
    if (kind == reimbursement || kind == advance) {
      return transfer;
    }
    return kind;
  }
}

/// Per-participant review decision.
class RealizedExpenseDecision {
  static const String pending = 'pending';
  static const String accepted = 'accepted';
  static const String rejected = 'rejected';
}
