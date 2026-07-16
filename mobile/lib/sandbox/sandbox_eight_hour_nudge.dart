import 'package:flutter/material.dart';

import '../app_root_navigator.dart';
import '../l10n/app_localizations.dart';
import '../prefs/app_preferences.dart';
import 'sandbox_dialogs.dart';
import 'sandbox_mode.dart';

/// Shows the 8-hour suggestion to leave simulation when owed.
class SandboxEightHourNudgeHost extends StatefulWidget {
  const SandboxEightHourNudgeHost({
    super.key,
    required this.prefs,
    required this.child,
  });

  final AppPreferences prefs;
  final Widget child;

  @override
  State<SandboxEightHourNudgeHost> createState() =>
      _SandboxEightHourNudgeHostState();
}

class _SandboxEightHourNudgeHostState extends State<SandboxEightHourNudgeHost> {
  bool _shownThisMount = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeNudge());
  }

  Future<void> _maybeNudge() async {
    if (_shownThisMount || !mounted) return;
    if (!SandboxMode.shouldShowEightHourNudge(widget.prefs)) return;
    _shownThisMount = true;
    final nav = appRootNavigatorKey.currentState;
    if (nav == null || !nav.mounted) return;
    final dialogContext = nav.context;
    final l10n = AppLocalizations.of(dialogContext);
    final choice = await showDialog<bool>(
      context: dialogContext,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.sandboxEightHourNudgeTitle),
        content: Text(l10n.sandboxEightHourNudgeBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.commonYes),
          ),
        ],
      ),
    );
    final entered = widget.prefs.sandboxEnteredAt;
    if (entered != null) {
      await widget.prefs.setSandboxEightHourNudgeShownForEntryMs(
        entered.millisecondsSinceEpoch,
      );
    }
    if (choice == true) {
      try {
        await performSandboxExitWithRestartDialog(prefs: widget.prefs);
      } catch (e) {
        showSandboxErrorSnackBar(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
