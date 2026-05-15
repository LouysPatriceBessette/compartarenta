import 'dart:async';

import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../db/repositories/contacts_repository.dart';
import '../l10n/app_localizations.dart';
import '../relay/handshake_orchestrator.dart';

/// Listens for [HandshakeOrchestrator.profileLabelConflict] and shows a
/// one-shot dialog so the user can align to a peer's new canonical name or
/// keep their local display label.
class ProfileLabelConflictHost extends StatefulWidget {
  const ProfileLabelConflictHost({super.key, required this.child});

  final Widget child;

  @override
  State<ProfileLabelConflictHost> createState() =>
      _ProfileLabelConflictHostState();
}

class _ProfileLabelConflictHostState extends State<ProfileLabelConflictHost> {
  HandshakeOrchestrator? _orch;

  @override
  void initState() {
    super.initState();
    _orch = HandshakeOrchestrator.maybeInstance;
    _orch?.profileLabelConflict.addListener(_onConflict);
  }

  @override
  void dispose() {
    _orch?.profileLabelConflict.removeListener(_onConflict);
    super.dispose();
  }

  void _onConflict() {
    final orch = HandshakeOrchestrator.maybeInstance;
    final conflict = orch?.profileLabelConflict.value;
    if (conflict == null || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final orch = HandshakeOrchestrator.maybeInstance;
      if (orch == null) return;
      final conflict = orch.profileLabelConflict.value;
      if (conflict == null) return;
      final l10n = AppLocalizations.of(context);
      final repo = ContactsRepository(AppDatabase.processScope);
      final choice = await showDialog<_ConflictChoice>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.peerNameConflictTitle),
          content: Text(
            l10n.peerNameConflictBody(
              conflict.localDisplayLabel,
              conflict.newCanonicalDisplayName,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(_ConflictChoice.keep),
              child: Text(l10n.peerNameConflictKeepMine),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(_ConflictChoice.align),
              child: Text(l10n.peerNameConflictUseTheirs),
            ),
          ],
        ),
      );
      orch.profileLabelConflict.value = null;
      if (choice == _ConflictChoice.align) {
        await repo.clearLocalDisplayLabel(conflict.contactId);
        unawaited(orch.notifyPeerOfLocalDisplayLabelChange(conflict.contactId));
        orch.steadyStateInboxTick.value = orch.steadyStateInboxTick.value + 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

enum _ConflictChoice { align, keep }
