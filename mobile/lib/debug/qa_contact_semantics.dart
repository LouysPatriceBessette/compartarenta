import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Maestro-facing [Semantics.identifier] values for Contacts E2E (debug Android).
const kQaHomeContacts = 'qa-home-contacts';
const kQaContactsInviteFab = 'qa-contacts-invite-fab';
const kQaContactsGenerateCode = 'qa-contacts-generate-code';
const kQaContactsInvitationShortCode = 'qa-contacts-invitation-short-code';
const kQaContactsRedeemOpen = 'qa-contacts-redeem-open';
const kQaContactsRedeemCodeField = 'qa-contacts-redeem-code-field';
const kQaContactsRedeemSubmit = 'qa-contacts-redeem-submit';
const kQaContactsIncomingBanner = 'qa-contacts-incoming-banner';
const kQaContactsIncomingAccept = 'qa-contacts-incoming-accept';
const kQaContactsHandshakeError = 'qa-contacts-handshake-error';
const kQaContactsHandshakeDispatched = 'qa-contacts-handshake-dispatched';
const kQaContactsHandshakeCompleted = 'qa-contacts-handshake-completed';
const kQaContactsEmptyState = 'qa-contacts-empty-state';
const kQaContactsInvitationsHub = 'qa-contacts-invitations-hub';
const kQaContactsPickerSheet = 'qa-contacts-picker-sheet';

/// Stable list-row id for a connected contact tile (display name slug).
String qaContactsRowSemanticsId(String displayName) {
  final slug = displayName
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return 'qa-contacts-row-${slug.isEmpty ? 'unnamed' : slug}';
}

/// Known QA persona row ids (seed display names).
const kQaContactsRowMonicaQa = 'qa-contacts-row-monica-qa';
const kQaContactsRowLouysQa = 'qa-contacts-row-louys-qa';

/// Exposed when two or more **connected** contacts share the same [rowSemanticsId]
/// (e.g. stale + refreshed Monica after proposer identity drift).
String qaContactsDuplicateConnectedSemanticsId(String rowSemanticsId) {
  assert(rowSemanticsId.startsWith('qa-contacts-row-'));
  return rowSemanticsId.replaceFirst(
    'qa-contacts-row-',
    'qa-contacts-duplicate-connected-',
  );
}

const kQaContactsDuplicateConnectedMonicaQa =
    'qa-contacts-duplicate-connected-monica-qa';

/// Duplicate device-binding handshake dialogs ([showContactDuplicateHandshakeDialog]).
const kQaContactsDuplicateDialogInviterMerged =
    'qa-contacts-duplicate-dialog-inviter-merged';
const kQaContactsDuplicateDialogInviterRejectedAnchor =
    'qa-contacts-duplicate-dialog-inviter-rejected-anchor';
const kQaContactsDuplicateDialogInviteeRejectedAnchor =
    'qa-contacts-duplicate-dialog-invitee-rejected-anchor';
const kQaContactsDuplicateDialogOk = 'qa-contacts-duplicate-dialog-ok';
const kQaContactsDuplicateAnchorRejectBanner =
    'qa-contacts-duplicate-anchor-reject-banner';

/// In-app notification permission prompt ([NotificationFlowPermissionTrigger]).
const kQaNotificationFlowPermissionPrompt =
    'qa-notification-flow-permission-prompt';
const kQaNotificationFlowPermissionEnable =
    'qa-notification-flow-permission-enable';

Widget qaContactSemantics({
  required String identifier,
  required Widget child,
  String? label,
  bool button = false,
  bool header = false,
  bool textField = false,
  VoidCallback? onTap,
  bool? enabled,
}) {
  if (!kDebugMode) return child;
  final semanticsEnabled = enabled ?? true;
  return Semantics(
    identifier: identifier,
    label: label,
    button: button,
    header: header,
    textField: textField,
    enabled: enabled,
    excludeSemantics: button || textField,
    onTap: (button || textField) && semanticsEnabled ? onTap : null,
    child: child,
  );
}
