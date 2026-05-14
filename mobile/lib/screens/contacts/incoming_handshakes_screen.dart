import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../contacts/avatar_palette.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../relay/handshake_orchestrator.dart';

/// Lists every pending incoming handshake (inviter side, role=inviter,
/// state=helloReceived) and lets the user accept or reject each one.
class IncomingHandshakesScreen extends StatefulWidget {
  const IncomingHandshakesScreen({super.key});

  @override
  State<IncomingHandshakesScreen> createState() =>
      _IncomingHandshakesScreenState();
}

class _IncomingHandshakesScreenState extends State<IncomingHandshakesScreen> {
  bool _busy = false;

  HandshakeOrchestrator? get _orchestrator =>
      HandshakeOrchestrator.maybeInstance;

  Future<void> _accept(IncomingHandshakeView view) async {
    final orch = _orchestrator;
    if (orch == null || _busy) return;
    setState(() => _busy = true);
    try {
      final prefs = await AppPreferences.load();
      final selfName =
          prefs.displayName.isEmpty ? 'Unknown' : prefs.displayName;
      final selfAvatar = prefs.avatarId.isEmpty ? 'a01' : prefs.avatarId;
      await orch.acceptIncoming(
        view.handshakeId,
        selfDisplayName: selfName,
        selfAvatarId: selfAvatar,
      );
      if (!mounted) return;
      if (orch.incomingHandshakes.value.isEmpty) {
        context.pop();
      }
    } on HandshakeOrchestratorError catch (e) {
      _showError(e.code);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject(IncomingHandshakeView view) async {
    final orch = _orchestrator;
    if (orch == null || _busy) return;
    setState(() => _busy = true);
    try {
      await orch.rejectIncoming(view.handshakeId);
      if (!mounted) return;
      if (orch.incomingHandshakes.value.isEmpty) {
        context.pop();
      }
    } on HandshakeOrchestratorError catch (e) {
      _showError(e.code);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String code) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final msg = switch (code) {
      'relay_unavailable' || 'relay_error' =>
        l10n.contactsHandshakeErrorRelayUnavailable,
      'already_completed' => l10n.contactsHandshakeErrorAlreadyCompleted,
      _ => l10n.contactsHandshakeErrorUnknown,
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final orch = _orchestrator;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.contactsIncomingTitle)),
      body: orch == null
          ? Center(child: Text(l10n.contactsHandshakeNotAvailableYet))
          : ValueListenableBuilder<List<IncomingHandshakeView>>(
              valueListenable: orch.incomingHandshakes,
              builder: (context, items, _) {
                if (items.isEmpty) {
                  return Center(child: Text(l10n.contactsIncomingEmpty));
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 0),
                  itemBuilder: (context, index) {
                    final v = items[index];
                    return _IncomingTile(
                      view: v,
                      busy: _busy,
                      onAccept: () => _accept(v),
                      onReject: () => _reject(v),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _IncomingTile extends StatelessWidget {
  const _IncomingTile({
    required this.view,
    required this.busy,
    required this.onAccept,
    required this.onReject,
  });

  final IncomingHandshakeView view;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      isThreeLine: true,
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(AvatarPalette.iconFor(view.peerAvatarId)),
      ),
      title: Text(
        view.peerDisplayName.isEmpty ? '—' : view.peerDisplayName,
      ),
      subtitle: Text(
        l10n.contactsIncomingBody(
          view.peerDisplayName.isEmpty ? 'Unknown' : view.peerDisplayName,
        ),
      ),
      trailing: Wrap(
        spacing: 4,
        children: [
          IconButton(
            tooltip: l10n.contactsIncomingReject,
            icon: const Icon(Icons.close),
            onPressed: busy ? null : onReject,
          ),
          IconButton(
            tooltip: l10n.contactsIncomingAccept,
            icon: const Icon(Icons.check),
            onPressed: busy ? null : onAccept,
          ),
        ],
      ),
    );
  }
}
