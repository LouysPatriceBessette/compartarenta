import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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

  ErrorWidgetBuilder? _previousBuilder;

  @override
  void initState() {
    super.initState();
    _previousBuilder = ErrorWidget.builder;
    ErrorWidget.builder = (details) {
      _capture(details.exception, details.stack);
      return _FallbackErrorScreen(
        error: details.exception,
        stackTrace: details.stack,
        onRestart: _restart,
      );
    };
  }

  @override
  void dispose() {
    final previous = _previousBuilder;
    if (previous != null) {
      ErrorWidget.builder = previous;
    }
    super.dispose();
  }

  void _capture(Object error, StackTrace? stackTrace) {
    if (_error != null) return;
    setState(() {
      _error = error;
      _stackTrace = stackTrace;
    });
  }

  void _restart() {
    setState(() {
      _error = null;
      _stackTrace = null;
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

