/// Shared relay HTTP timing: per-request timeout, retry budget, and poll spacing.
///
/// One logical relay HTTP call may attempt up to [maxAttempts] times (initial +
/// [maxRetries] retries), each waiting up to [requestTimeout]. After that the
/// client throws [RelayUnreachableException] — ~2 minutes wall-clock before the
/// app treats the relay as unreachable for that operation.
abstract final class RelayHttpPolicy {
  /// Max wait for one HTTP round-trip attempt (not invitation validity).
  static const Duration requestTimeout = Duration(seconds: 30);

  /// Retries after the initial attempt fails with no HTTP response.
  static const int maxRetries = 3;

  /// Initial attempt plus [maxRetries].
  static const int maxAttempts = maxRetries + 1;

  /// Gap after a poll cycle completes before the next cycle may start.
  static const Duration pollCooldown = Duration(seconds: 1);

  /// Minimum spacing between poll cycles: [requestTimeout] + [pollCooldown].
  static const Duration pollInterval = Duration(seconds: 31);

  /// Wall-clock upper bound before declaring the relay unreachable (4 × 30 s).
  static const Duration maxUnreachableDuration = Duration(
    seconds: 30 * maxAttempts,
  );
}
