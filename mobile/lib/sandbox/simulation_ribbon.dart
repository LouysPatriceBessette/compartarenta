import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../prefs/app_preferences.dart';
import 'sandbox_dialogs.dart';
import 'sandbox_mode.dart';

/// Full-width top banner in sandbox. Tap opens exit confirmation.
///
/// Pushes page content down so AppBar actions (e.g. Settings) stay reachable.
class SimulationRibbonHost extends StatelessWidget {
  const SimulationRibbonHost({
    super.key,
    required this.prefs,
    required this.child,
    this.hideWhenActive = false,
  });

  final AppPreferences prefs;
  final Widget child;
  final bool hideWhenActive;

  /// Previous diagonal label used 11; horizontal banner is 10% larger.
  static const double _labelFontSize = 11 * 1.10;

  Future<void> _onTap() async {
    final confirmed = await showSandboxExitConfirmDialog();
    if (!confirmed) return;

    try {
      await performSandboxExitWithRestartDialog(prefs: prefs);
    } catch (e) {
      showSandboxErrorSnackBar(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!SandboxMode.isActive(prefs) || hideWhenActive) return child;
    final label = AppLocalizations.of(context).sandboxRibbonLabel;
    final topInset = MediaQuery.paddingOf(context).top;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: const Color(0xA0CC0000),
          child: Semantics(
            button: true,
            label: label,
            child: InkWell(
              onTap: _onTap,
              child: Padding(
                padding: EdgeInsets.only(top: topInset),
                child: SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: _labelFontSize,
                        letterSpacing: 0.4,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: child,
          ),
        ),
      ],
    );
  }
}
