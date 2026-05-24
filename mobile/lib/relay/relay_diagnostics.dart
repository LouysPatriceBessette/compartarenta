import 'package:flutter/foundation.dart';

/// Optional relay trace logging (off by default to reduce console noise).
abstract final class RelayDiagnostics {
  /// When true, steady-state inbox poll emits [debugPrint] lines.
  static bool steadyInboxPollLogging = false;

  static void logSteadyInbox(String message) {
    if (steadyInboxPollLogging) {
      debugPrint(message);
    }
  }

  /// Housing realized-expense sync (send / import); off by default.
  static bool housingRealizedExpenseLogging = false;

  static void logHousingRealizedExpense(String message) {
    if (housingRealizedExpenseLogging) {
      debugPrint(message);
    }
  }
}
