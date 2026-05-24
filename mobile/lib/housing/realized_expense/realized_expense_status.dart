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
}

/// Per-participant review decision.
class RealizedExpenseDecision {
  static const String pending = 'pending';
  static const String accepted = 'accepted';
  static const String rejected = 'rejected';
}
