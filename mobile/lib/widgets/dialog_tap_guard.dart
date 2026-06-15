/// Prevents duplicate modals from rapid repeated taps while one open flow is
/// in progress (including async work before [showDialog] and until it closes).
///
/// Prefer this over debounce or arbitrary button-disable timers for modal entry
/// points: the guard covers the full open lifecycle, not a fixed delay.
class DialogTapGuard {
  DialogTapGuard._();

  static final Set<Object> _inFlight = <Object>{};

  /// Runs [action] once per [key] until the previous invocation completes.
  ///
  /// Returns null when a matching invocation is already in flight.
  static Future<T?> run<T>(Object key, Future<T?> Function() action) async {
    if (_inFlight.contains(key)) return null;
    _inFlight.add(key);
    try {
      return await action();
    } finally {
      _inFlight.remove(key);
    }
  }

  /// Stable guard key for a modal entry point.
  static Object key(String scope, [Object? suffix]) =>
      suffix == null ? scope : (scope, suffix);
}
