import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Declarative navigation to [location] (GoRouter [GoRouter.go]).
///
/// Prefer this over [GoRouter.push] so the URL stack matches the logical
/// destination and the system back button does not walk unrelated history.
void navigateTo(BuildContext context, String location, {Object? extra}) {
  context.go(location, extra: extra);
}

/// Opens a full-screen [route] without growing the navigator stack.
Future<T?> navigateToRoute<T extends Object?>(
  BuildContext context,
  Route<T> route, {
  bool rootNavigator = false,
}) {
  return Navigator.of(context, rootNavigator: rootNavigator)
      .pushReplacement(route);
}
