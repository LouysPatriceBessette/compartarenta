import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Leaves the vehicle module and returns to the app home (`/`).
void exitVehicleModule(BuildContext context) {
  final router = GoRouter.of(context);
  if (router.state.matchedLocation == '/vehicle') {
    router.go('/');
    return;
  }
  if (router.canPop()) {
    router.pop();
    return;
  }
  router.go('/');
}

/// Leaves the vehicle-sharing module and returns to the app home (`/`).
void exitVehicleSharingModule(BuildContext context) {
  final router = GoRouter.of(context);
  if (router.state.matchedLocation == '/vehicle-sharing') {
    router.go('/');
    return;
  }
  if (router.canPop()) {
    router.pop();
    return;
  }
  router.go('/');
}
