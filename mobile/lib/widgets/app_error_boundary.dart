import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_root_navigator.dart';
import '../l10n/app_localizations.dart';

class AppErrorBoundary extends StatefulWidget {
  const AppErrorBoundary({super.key, required this.child});

  final Widget child;

  @override
  State<AppErrorBoundary> createState() => _AppErrorBoundaryState();
}

class _AppErrorBoundaryState extends State<AppErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  FlutterExceptionHandler? _previousFlutterOnError;
  late final FlutterExceptionHandler _chainedHandler;

  @override
  void initState() {
    super.initState();
    _previousFlutterOnError = FlutterError.onError;
    _chainedHandler = (FlutterErrorDetails details) {
      _previousFlutterOnError?.call(details);
      _scheduleCapture(details.exception, details.stack);
    };
    FlutterError.onError = _chainedHandler;
  }

  @override
  void dispose() {
    if (FlutterError.onError == _chainedHandler) {
      FlutterError.onError = _previousFlutterOnError;
    }
    super.dispose();
  }

  void _scheduleCapture(Object error, StackTrace? stackTrace) {
    if (_error != null) return;
    // Never call setState synchronously from the error path: it races with
    // element teardown (e.g. process death, activity stop, "close all") and can
    // trigger framework assertions such as _InactiveElements.remove.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_error != null) return;
      setState(() {
        _error = error;
        _stackTrace = stackTrace;
      });
    });
  }

  void _restart() {
    setState(() {
      _error = null;
      _stackTrace = null;
    });
    // Rebuild the same route (e.g. /housing) that just crashed; go home first.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = appRootNavigatorKey.currentContext;
      if (ctx == null || !ctx.mounted) return;
      GoRouter.of(ctx).go('/');
    });
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    if (error == null) return widget.child;

    return _FallbackErrorScreen(
      error: error,
      stackTrace: _stackTrace,
      onRestart: _restart,
    );
  }
}

class _FallbackErrorScreen extends StatelessWidget {
  const _FallbackErrorScreen({
    required this.error,
    required this.stackTrace,
    required this.onRestart,
  });

  final Object error;
  final StackTrace? stackTrace;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final details = kDebugMode && stackTrace != null
        ? '\n\n$stackTrace'
        : '';

    return Material(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.errorSomethingWentWrongTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(l10n.errorSomethingWentWrongBody),
              const SizedBox(height: 12),
              Text(
                '$error$details',
                maxLines: 10,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              FilledButton(
                onPressed: onRestart,
                child: Text(l10n.commonRestart),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
