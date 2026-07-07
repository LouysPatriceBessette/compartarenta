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

Widget qaContactSemantics({
  required String identifier,
  required Widget child,
  String? label,
  bool button = false,
  bool header = false,
}) {
  if (!kDebugMode) return child;
  return Semantics(
    identifier: identifier,
    label: label,
    button: button,
    header: header,
    child: child,
  );
}
