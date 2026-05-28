import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Leaves the housing module: pops a pushed child route when possible,
/// otherwise returns to the app home (`/`).
void exitHousingModule(BuildContext context) {
  final navigator = Navigator.of(context);
  if (navigator.canPop()) {
    navigator.pop();
    return;
  }
  final router = GoRouter.of(context);
  if (router.canPop()) {
    router.pop();
    return;
  }
  router.go('/');
}
