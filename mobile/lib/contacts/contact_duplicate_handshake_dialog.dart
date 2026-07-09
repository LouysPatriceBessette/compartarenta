import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../contacts/contact_duplicate_handshake_dialog_state.dart';
import '../contacts/contact_duplicate_module_anchor.dart';
import '../l10n/app_localizations.dart';
import '../util/product_legal_urls.dart';
import '../widgets/app_dialog.dart';

String duplicateModuleAnchorLabel(AppLocalizations l10n, String anchorKind) {
  return switch (anchorKind) {
    DuplicateModuleAnchorKind.vehicle =>
      l10n.contactsDuplicateAnchorVehicleSharing,
    DuplicateModuleAnchorKind.housingAndVehicle =>
      l10n.contactsDuplicateAnchorHousingAndVehicle,
    DuplicateModuleAnchorKind.housing ||
    _ =>
      l10n.contactsDuplicateAnchorHousingActive,
  };
}

Future<void> showContactDuplicateHandshakeDialog(
  BuildContext context, {
  required PendingContactDuplicateDialog pending,
}) async {
  final l10n = AppLocalizations.of(context);
  final locale = Localizations.localeOf(context);
  final faqUrl = contactDuplicateFaqUrlForLocale(locale);
  final readMoreRecognizer = TapGestureRecognizer()
    ..onTap = () {
      unawaited(
        launchUrl(faqUrl, mode: LaunchMode.externalApplication),
      );
    };

  Widget buildReadMoreLink() {
    return Text.rich(
      TextSpan(
        text: l10n.contactsDuplicateReadMore,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
        recognizer: readMoreRecognizer,
      ),
    );
  }

  Widget content;
  switch (pending.kind) {
    case ContactDuplicateDialogKind.inviterRejectedAnchor:
      final anchor = duplicateModuleAnchorLabel(l10n, pending.anchorKind);
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.contactsDuplicateInviterRejectedIntro(anchor)),
          const SizedBox(height: 12),
          Text(
            l10n.contactsDuplicateInviterNotAdded,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 12),
          Text(l10n.contactsDuplicateInviterInformRestore),
          const SizedBox(height: 12),
          buildReadMoreLink(),
        ],
      );
    case ContactDuplicateDialogKind.inviterMerged:
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.contactsDuplicateInviterMergedBody),
          const SizedBox(height: 12),
          buildReadMoreLink(),
        ],
      );
    case ContactDuplicateDialogKind.inviteeRejectedAnchor:
      final anchor = duplicateModuleAnchorLabel(l10n, pending.anchorKind);
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.contactsDuplicateInviteeRejectedIntro(anchor)),
          const SizedBox(height: 12),
          Text(
            l10n.contactsDuplicateInviteeMustRestore,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          buildReadMoreLink(),
        ],
      );
  }

  try {
    await showAppDialog<void>(
      context: context,
      guardKey: 'contactDuplicateHandshake.${pending.kind.name}',
      builder: (ctx) => AlertDialog(
        content: SingleChildScrollView(child: content),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.contactsDuplicateDialogOk),
          ),
        ],
      ),
    );
  } finally {
    readMoreRecognizer.dispose();
  }
}
