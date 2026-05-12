import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../contacts/invitation_code.dart';
import '../../l10n/app_localizations.dart';

/// Screen for the invitee to enter a received invitation code.
///
/// At this stage (Wave A) the screen only performs **local** checksum
/// validation and stores the parsed code in the local state — it never
/// dispatches a `hello` envelope to the relay. The actual relay handshake
/// is wired in Wave B together with the cryptographic primitives.
class RedeemInvitationScreen extends StatefulWidget {
  const RedeemInvitationScreen({super.key});

  @override
  State<RedeemInvitationScreen> createState() => _RedeemInvitationScreenState();
}

class _RedeemInvitationScreenState extends State<RedeemInvitationScreen> {
  final _controller = TextEditingController();
  InvitationCodeParseResult? _result;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validate() {
    final value = _controller.text;
    setState(() => _result = parseInvitationCode(value));
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (!mounted) return;
    final text = data?.text ?? '';
    _controller.text = text;
    _validate();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final result = _result;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.contactsEnterInviteCodeTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.contactsEnterInviteCodeIntro,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: l10n.contactsEnterInviteCodeFieldLabel,
                  hintText: 'XXXXX-XXXXX-XXXXX-XXXXX-XXXXX-XXXXX-XXXXX',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.paste),
                    tooltip: l10n.commonPaste,
                    onPressed: _pasteFromClipboard,
                  ),
                ),
                onChanged: (_) => _validate(),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 16),
              if (result is InvitationCodeOk)
                _OkResult(invitationIdHex: result.code.invitationIdHex()),
              if (result is InvitationCodeBad)
                _BadResult(error: result.error),
              const Spacer(),
              FilledButton.icon(
                icon: const Icon(Icons.send_outlined),
                label: Text(l10n.contactsEnterInviteCodeSubmit),
                onPressed: result is InvitationCodeOk
                    ? () {
                        _showHandshakeUnavailable(context);
                      }
                    : null,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.contactsEnterInviteCodeWaveBNote,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHandshakeUnavailable(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.contactsHandshakeNotAvailableYet)),
    );
  }
}

class _OkResult extends StatelessWidget {
  const _OkResult({required this.invitationIdHex});

  final String invitationIdHex;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: ListTile(
        leading: const Icon(Icons.check_circle_outline),
        title: Text(l10n.contactsEnterInviteCodeValid),
        subtitle: Text(
          l10n.contactsEnterInviteCodeInvitationId(invitationIdHex),
        ),
      ),
    );
  }
}

class _BadResult extends StatelessWidget {
  const _BadResult({required this.error});

  final InvitationCodeError error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final message = switch (error) {
      InvitationCodeError.empty => l10n.contactsCodeErrorEmpty,
      InvitationCodeError.tooShort => l10n.contactsCodeErrorTooShort,
      InvitationCodeError.tooLong => l10n.contactsCodeErrorTooLong,
      InvitationCodeError.invalidCharacters =>
        l10n.contactsCodeErrorInvalidCharacters,
      InvitationCodeError.badChecksum => l10n.contactsCodeErrorBadChecksum,
      InvitationCodeError.unsupportedVersion =>
        l10n.contactsCodeErrorUnsupportedVersion,
    };
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: ListTile(
        leading: const Icon(Icons.error_outline),
        title: Text(message),
      ),
    );
  }
}
