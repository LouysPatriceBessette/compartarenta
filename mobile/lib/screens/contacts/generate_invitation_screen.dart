import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../contacts/contact_invitations_repository.dart';
import '../../db/app_database.dart';
import '../../l10n/app_localizations.dart';
import '../../notifications/notification_flow_permission_trigger.dart';
import '../../prefs/app_preferences.dart';
import '../../relay/handshake_orchestrator.dart';
import '../../widgets/standard_validity_duration_bar.dart';

/// Screen that generates a new invitation code and presents it for out-of-band
/// sharing.
class GenerateInvitationScreen extends StatefulWidget {
  const GenerateInvitationScreen({super.key, this.reconnectContactId});

  final String? reconnectContactId;

  @override
  State<GenerateInvitationScreen> createState() =>
      _GenerateInvitationScreenState();
}

class _GenerateInvitationScreenState extends State<GenerateInvitationScreen> {
  AppDatabase get _db => AppDatabase.processScope;
  late final ContactInvitationsRepository _repo = ContactInvitationsRepository(
    _db,
  );

  Duration _validFor = const Duration(hours: 24);
  _GeneratedInvitation? _generated;
  HandshakeOrchestrator? _incomingListenerOrchestrator;
  Timer? _generatedPollTimer;
  bool _generating = false;
  bool _processingGeneratedPoll = false;
  bool _routingToIncoming = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _attachIncomingListener();
  }

  @override
  void dispose() {
    _generatedPollTimer?.cancel();
    _incomingListenerOrchestrator?.incomingHandshakes.removeListener(
      _onIncomingHandshakesChanged,
    );
    super.dispose();
  }

  void _attachIncomingListener() {
    final orchestrator = HandshakeOrchestrator.maybeInstance;
    if (orchestrator == null ||
        identical(orchestrator, _incomingListenerOrchestrator)) {
      return;
    }
    _incomingListenerOrchestrator?.incomingHandshakes.removeListener(
      _onIncomingHandshakesChanged,
    );
    _incomingListenerOrchestrator = orchestrator;
    orchestrator.incomingHandshakes.addListener(_onIncomingHandshakesChanged);
  }

  void _onIncomingHandshakesChanged() {
    _routeToIncomingIfCurrentInvitationHasRequest();
  }

  void _startGeneratedPolling(HandshakeOrchestrator orchestrator) {
    _generatedPollTimer?.cancel();
    _generatedPollTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => unawaited(_pollGeneratedInvitation(orchestrator)),
    );
    unawaited(_pollGeneratedInvitation(orchestrator));
  }

  Future<void> _pollGeneratedInvitation(
    HandshakeOrchestrator orchestrator,
  ) async {
    if (_processingGeneratedPoll || _routingToIncoming || _generated == null) {
      return;
    }
    _processingGeneratedPoll = true;
    try {
      await orchestrator.processAllPendingHandshakes();
      _routeToIncomingIfCurrentInvitationHasRequest();
    } on HandshakeOrchestratorError catch (e) {
      debugPrint('Generated invitation polling failed: ${e.code}');
    } catch (error, stack) {
      debugPrint('Generated invitation polling failed: $error\n$stack');
    } finally {
      _processingGeneratedPoll = false;
    }
  }

  void _routeToIncomingIfCurrentInvitationHasRequest() {
    if (!mounted || _routingToIncoming) return;
    final generated = _generated;
    if (generated == null) return;
    final orchestrator =
        _incomingListenerOrchestrator ?? HandshakeOrchestrator.maybeInstance;
    if (orchestrator == null) return;
    final hasIncomingRequest = orchestrator.incomingHandshakes.value.any(
      (view) => view.invitationIdHex == generated.row.id,
    );
    if (!hasIncomingRequest) return;
    _routingToIncoming = true;
    _generatedPollTimer?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go('/contacts/incoming');
    });
  }

  Future<void> _generate() async {
    if (_generating) return;
    final l10n = AppLocalizations.of(context);
    final orchestrator = HandshakeOrchestrator.maybeInstance;
    if (orchestrator == null) {
      setState(() {
        _error = l10n.contactsHandshakeNotAvailableYet;
      });
      return;
    }
    final prefs = await AppPreferences.load();
    final notificationResult = await const NotificationFlowPermissionTrigger()
        .ensure(
          context: context,
          prefs: prefs,
          switches: const {
            NotificationFlowSwitch.contactAddRequests,
            NotificationFlowSwitch.contactInvitationExpiration,
          },
        );
    if (notificationResult == NotificationFlowPermissionResult.abortFlow) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _generating = true;
      _error = null;
    });
    try {
      final stubName = prefs.displayName.isEmpty
          ? 'Pending invitation'
          : '${prefs.displayName}\u2019s contact';
      final stubAvatar = prefs.avatarId.isEmpty ? 'a01' : prefs.avatarId;
      final r = await orchestrator.generateInvitation(
        validFor: _validFor,
        stubDisplayName: stubName,
        stubAvatarId: stubAvatar,
        reconnectContactId: widget.reconnectContactId,
      );
      final result = _GeneratedInvitation(
        row: r.invitation,
        shortCode: r.shortCode,
        deepLink: r.deepLink,
        webLink: r.webLink,
      );
      if (!mounted) return;
      setState(() {
        _generated = result;
        _generating = false;
      });
      _attachIncomingListener();
      _startGeneratedPolling(orchestrator);
      _routeToIncomingIfCurrentInvitationHasRequest();
    } on HandshakeOrchestratorError catch (e) {
      if (!mounted) return;
      setState(() {
        _generating = false;
        _error = _handshakeErrorLabel(l10n, e.code);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _generating = false;
        _error = e.toString();
      });
    }
  }

  String _handshakeErrorLabel(AppLocalizations l10n, String code) {
    return switch (code) {
      'relay_unavailable' ||
      'relay_error' => l10n.contactsHandshakeErrorRelayUnavailable,
      'already_completed' => l10n.contactsHandshakeErrorAlreadyCompleted,
      'nonce_already_consumed' => l10n.contactsHandshakeErrorNonceConsumed,
      'expired_code' || 'expired' => l10n.contactsHandshakeErrorExpired,
      _ => l10n.contactsHandshakeErrorUnknown,
    };
  }

  Future<void> _revoke() async {
    final invitation = _generated;
    if (invitation == null) return;
    await _repo.revoke(invitation.row.id);
    if (!mounted) return;
    _generatedPollTimer?.cancel();
    setState(() => _generated = null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final generated = _generated;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.contactsInviteTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: generated == null
              ? _IntroForm(
                  selected: _validFor,
                  onSelect: (d) => setState(() => _validFor = d),
                  onGenerate: _generate,
                  busy: _generating,
                  error: _error,
                )
              : _GeneratedView(
                  shortCode: generated.shortCode,
                  deepLink: generated.deepLink,
                  webLink: generated.webLink,
                  expiresAt: generated.row.expiresAt,
                  onRevoke: _revoke,
                  onDone: () => context.pop(),
                ),
        ),
      ),
    );
  }
}

class _GeneratedInvitation {
  const _GeneratedInvitation({
    required this.row,
    required this.shortCode,
    required this.deepLink,
    required this.webLink,
  });

  final ContactInvitation row;
  final String shortCode;
  final String deepLink;
  final String webLink;
}

class _IntroForm extends StatelessWidget {
  const _IntroForm({
    required this.selected,
    required this.onSelect,
    required this.onGenerate,
    required this.busy,
    this.error,
  });

  final Duration selected;
  final ValueChanged<Duration> onSelect;
  final VoidCallback onGenerate;
  final bool busy;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.contactsInviteIntroTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(l10n.contactsInviteIntroBody),
        const SizedBox(height: 16),
        Text(
          l10n.contactsInviteValidityLabel,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        StandardValidityDurationSegmented(
          selected: selected,
          onChanged: onSelect,
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const Spacer(),
        FilledButton.icon(
          icon: const Icon(Icons.send),
          label: Text(l10n.contactsInviteGenerateAction),
          onPressed: busy ? null : onGenerate,
        ),
      ],
    );
  }
}

class _GeneratedView extends StatelessWidget {
  const _GeneratedView({
    required this.shortCode,
    required this.deepLink,
    required this.webLink,
    required this.expiresAt,
    required this.onRevoke,
    required this.onDone,
  });

  final String shortCode;
  final String deepLink;
  final String webLink;
  final DateTime expiresAt;
  final VoidCallback onRevoke;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shareText = l10n.contactsInviteShareText(webLink, shortCode);
    // The QR card + buttons easily exceed a phone viewport. Make the
    // upper portion scrollable so it never overflows, then keep the
    // action buttons docked at the bottom of the available space.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.contactsInviteShareWarning,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Semantics(
                            label: l10n.contactsInviteQrSemantics,
                            child: QrImageView(
                              data: deepLink,
                              version: QrVersions.auto,
                              size: 192,
                              backgroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.contactsInviteQrLabel,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.contactsInviteShortCodeLabel,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          shortCode,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          children: [
                            OutlinedButton.icon(
                              icon: const Icon(Icons.copy),
                              label: Text(l10n.commonCopy),
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: shortCode),
                                );
                              },
                            ),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.link),
                              label: Text(l10n.contactsInviteCopyShareText),
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: shareText),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.contactsInviteExpiresAt(expiresAt.toLocal().toString()),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.cancel_outlined),
          label: Text(l10n.contactsInviteRevokeAction),
          onPressed: onRevoke,
        ),
        const SizedBox(height: 8),
        FilledButton(onPressed: onDone, child: Text(l10n.commonDone)),
      ],
    );
  }
}
