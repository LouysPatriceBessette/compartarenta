import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../contacts/contact_invitations_repository.dart';
import '../../db/app_database.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../relay/handshake_orchestrator.dart';

/// Screen that generates a new invitation code on-device and presents it
/// for out-of-band sharing. Never contacts the network.
class GenerateInvitationScreen extends StatefulWidget {
  const GenerateInvitationScreen({super.key});

  @override
  State<GenerateInvitationScreen> createState() =>
      _GenerateInvitationScreenState();
}

class _GenerateInvitationScreenState extends State<GenerateInvitationScreen> {
  late final AppDatabase _db = AppDatabase();
  late final ContactInvitationsRepository _repo = ContactInvitationsRepository(
    _db,
  );

  Duration _validFor = const Duration(hours: 24);
  _GeneratedInvitation? _generated;
  bool _generating = false;
  String? _error;

  static const _options = <(Duration, String)>[
    (Duration(hours: 1), '1h'),
    (Duration(hours: 24), '24h'),
    (Duration(days: 7), '7d'),
  ];

  Future<void> _generate() async {
    if (_generating) return;
    setState(() {
      _generating = true;
      _error = null;
    });
    final orchestrator = HandshakeOrchestrator.maybeInstance;
    try {
      _GeneratedInvitation result;
      if (orchestrator != null) {
        final prefs = await AppPreferences.load();
        final stubName = prefs.displayName.isEmpty
            ? 'Pending invitation'
            : '${prefs.displayName}\u2019s contact';
        final stubAvatar = prefs.avatarId.isEmpty ? 'a01' : prefs.avatarId;
        final r = await orchestrator.generateInvitation(
          validFor: _validFor,
          stubDisplayName: stubName,
          stubAvatarId: stubAvatar,
        );
        result = _GeneratedInvitation(
          row: r.invitation,
          shortCode: r.shortCode,
          deepLink: r.deepLink,
        );
      } else {
        final r = await _repo.generate(validFor: _validFor);
        result = _GeneratedInvitation(
          row: r.row,
          shortCode: r.shortCode,
          deepLink: r.deepLink,
        );
      }
      if (!mounted) return;
      setState(() {
        _generated = result;
        _generating = false;
      });
    } on HandshakeOrchestratorError catch (e) {
      if (!mounted) return;
      setState(() {
        _generating = false;
        _error = e.code;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _generating = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _revoke() async {
    final invitation = _generated;
    if (invitation == null) return;
    await _repo.revoke(invitation.row.id);
    if (!mounted) return;
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
                  options: _options,
                  onSelect: (d) => setState(() => _validFor = d),
                  onGenerate: _generate,
                  busy: _generating,
                  error: _error,
                )
              : _GeneratedView(
                  shortCode: generated.shortCode,
                  deepLink: generated.deepLink,
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
  });

  final ContactInvitation row;
  final String shortCode;
  final String deepLink;
}

class _IntroForm extends StatelessWidget {
  const _IntroForm({
    required this.selected,
    required this.options,
    required this.onSelect,
    required this.onGenerate,
    required this.busy,
    this.error,
  });

  final Duration selected;
  final List<(Duration, String)> options;
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
        SegmentedButton<Duration>(
          segments: [
            for (final (duration, label) in options)
              ButtonSegment(value: duration, label: Text(label)),
          ],
          selected: {selected},
          onSelectionChanged: (s) => onSelect(s.first),
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
    required this.expiresAt,
    required this.onRevoke,
    required this.onDone,
  });

  final String shortCode;
  final String deepLink;
  final DateTime expiresAt;
  final VoidCallback onRevoke;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
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
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
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
                        Clipboard.setData(ClipboardData(text: shortCode));
                      },
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.link),
                      label: Text(l10n.contactsInviteCopyDeepLink),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: deepLink));
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
        const Spacer(),
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
