/// One-shot dialog queued after a device-binding duplicate handshake outcome.
enum ContactDuplicateDialogKind {
  /// Inviter: duplicate blocked by module anchor (case A).
  inviterRejectedAnchor,

  /// Inviter: duplicate merged into pre-existing contact (case B).
  inviterMerged,

  /// Invitee: inviter rejected with [AckRejectionReason.duplicateModuleAnchor].
  inviteeRejectedAnchor,
}

class PendingContactDuplicateDialog {
  const PendingContactDuplicateDialog({
    required this.kind,
    this.anchorKind = '',
  });

  final ContactDuplicateDialogKind kind;

  /// [DuplicateModuleAnchorKind] wire value; empty for [ContactDuplicateDialogKind.inviterMerged].
  final String anchorKind;
}
