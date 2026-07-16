import '../prefs/app_preferences.dart';

/// Pref keys and helpers for housing/contacts simulation mode.
///
/// Stored in [SharedPreferences] so values survive [DbReset] database wipes.
abstract final class SandboxMode {
  static const prefsKeyActive = 'sandbox.mode';
  static const prefsKeyEnteredAtMs = 'sandbox.enteredAtMs';
  static const prefsKeyInvitedBotCount = 'sandbox.invitedBotCount';
  static const prefsKeyEightHourNudgeShownForEntry =
      'sandbox.eightHourNudgeShownForEntryMs';

  static bool isActive(AppPreferences prefs) => prefs.sandboxMode;

  static Duration timeInSandbox(AppPreferences prefs) {
    final entered = prefs.sandboxEnteredAt;
    if (entered == null) return Duration.zero;
    return DateTime.now().toUtc().difference(entered.toUtc());
  }

  static bool shouldShowEightHourNudge(AppPreferences prefs) {
    if (!prefs.sandboxMode) return false;
    final entered = prefs.sandboxEnteredAt;
    if (entered == null) return false;
    if (timeInSandbox(prefs) < const Duration(hours: 8)) return false;
    final shownFor = prefs.sandboxEightHourNudgeShownForEntryMs;
    return shownFor != entered.millisecondsSinceEpoch;
  }
}
