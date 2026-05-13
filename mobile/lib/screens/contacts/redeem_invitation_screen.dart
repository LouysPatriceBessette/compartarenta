import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../contacts/invitation_code.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../relay/handshake_orchestrator.dart';

/// Screen for the invitee to enter a received invitation code.
///
/// Performs a local checksum validation, then — when the user taps
/// Connect — dispatches the encrypted `hello` envelope to the relay via
/// [HandshakeOrchestrator]. The accepted/rejected outcome is surfaced
/// later by the orchestrator's poller (see `ContactsListScreen`).
class RedeemInvitationScreen extends StatefulWidget {
  const RedeemInvitationScreen({super.key});

  @override
  State<RedeemInvitationScreen> createState() => _RedeemInvitationScreenState();
}

class _RedeemInvitationScreenState extends State<RedeemInvitationScreen> {
  final _controller = TextEditingController();
  InvitationCodeParseResult? _result;
  bool _dispatching = false;
  String? _dispatchError;
  bool _dispatched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validate() {
    final value = _controller.text;
    setState(() {
      _result = parseInvitationInput(value);
      _dispatchError = null;
      _dispatched = false;
    });
  }

  Future<void> _connect(InvitationCode code) async {
    if (_dispatching) return;
    final orchestrator = HandshakeOrchestrator.maybeInstance;
    if (orchestrator == null) {
      _showHandshakeUnavailable(context);
      return;
    }
    setState(() {
      _dispatching = true;
      _dispatchError = null;
      _dispatched = false;
    });
    try {
      final prefs = await AppPreferences.load();
      final selfName = prefs.displayName.isEmpty ? 'Unknown' : prefs.displayName;
      final selfAvatar = prefs.avatarId.isEmpty ? 'a01' : prefs.avatarId;
      await orchestrator.redeemInvitation(
        code: code,
        selfDisplayName: selfName,
        selfAvatarId: selfAvatar,
      );
      // Kick the poller immediately so the invitee sees the ack as soon
      // as it lands. Errors here are swallowed and surfaced through
      // the steady-state poller instead.
      // ignore: unawaited_futures
      orchestrator.processAllPendingHandshakes();
      if (!mounted) return;
      setState(() {
        _dispatching = false;
        _dispatched = true;
      });
    } on HandshakeOrchestratorError catch (e) {
      if (!mounted) return;
      setState(() {
        _dispatching = false;
        _dispatchError = e.code;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _dispatching = false;
        _dispatchError = e.toString();
      });
    }
  }

  String _errorLabel(BuildContext context, String code) {
    final l10n = AppLocalizations.of(context);
    return switch (code) {
      'relay_unavailable' => l10n.contactsHandshakeErrorRelayUnavailable,
      'relay_error' => l10n.contactsHandshakeErrorRelayUnavailable,
      'already_completed' => l10n.contactsHandshakeErrorAlreadyCompleted,
      'nonce_already_consumed' => l10n.contactsHandshakeErrorNonceConsumed,
      'expired_code' => l10n.contactsHandshakeErrorExpired,
      _ => l10n.contactsHandshakeErrorUnknown,
    };
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (!mounted) return;
    final text = _displayTextForScannedValue(data?.text ?? '');
    _controller.text = text;
    _validate();
  }

  Future<void> _scanQrCode() async {
    final scanned = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _InvitationQrScannerScreen()),
    );
    if (!mounted || scanned == null) return;
    _controller.text = _displayTextForScannedValue(scanned);
    _validate();
  }

  String _displayTextForScannedValue(String value) {
    final parsed = parseInvitationInput(value);
    if (parsed is InvitationCodeOk) {
      return parsed.code.renderShort();
    }
    return value;
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
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.qr_code_scanner),
                label: Text(l10n.contactsEnterInviteCodeScanQr),
                onPressed: _scanQrCode,
              ),
              const SizedBox(height: 16),
              if (result is InvitationCodeOk)
                _OkResult(invitationIdHex: result.code.invitationIdHex()),
              if (result is InvitationCodeBad) _BadResult(error: result.error),
              if (_dispatchError != null) ...[
                const SizedBox(height: 8),
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: ListTile(
                    leading: const Icon(Icons.cloud_off_outlined),
                    title: Text(_errorLabel(context, _dispatchError!)),
                  ),
                ),
              ],
              if (_dispatched) ...[
                const SizedBox(height: 8),
                Card(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: ListTile(
                    leading: const Icon(Icons.hourglass_top_outlined),
                    title: Text(l10n.contactsHandshakeDispatched),
                  ),
                ),
              ],
              const Spacer(),
              FilledButton.icon(
                icon: _dispatching
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text(
                  _dispatching
                      ? l10n.contactsHandshakeDispatching
                      : l10n.contactsEnterInviteCodeSubmit,
                ),
                onPressed: (result is InvitationCodeOk && !_dispatching && !_dispatched)
                    ? () => _connect(result.code)
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

class _InvitationQrScannerScreen extends StatefulWidget {
  const _InvitationQrScannerScreen();

  @override
  State<_InvitationQrScannerScreen> createState() =>
      _InvitationQrScannerScreenState();
}

class _InvitationQrScannerScreenState
    extends State<_InvitationQrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  bool _returned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDetect(BarcodeCapture capture) {
    if (_returned) return;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value == null || value.trim().isEmpty) continue;
      _returned = true;
      Navigator.of(context).pop(value);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.contactsEnterInviteCodeScanQr)),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _handleDetect),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.contactsEnterInviteCodeScanQrHint,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
