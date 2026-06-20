import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Leaves the housing module and returns to the app home (`/`).
void exitHousingModule(BuildContext context) {
  final router = GoRouter.of(context);
  if (router.state.matchedLocation == '/housing') {
    router.go('/');
    return;
  }
  if (router.canPop()) {
    router.pop();
    return;
  }
  router.go('/');
}
