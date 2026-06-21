import 'package:flutter/material.dart';

/// [GoRouter] is wired with this key so notification taps can push routes.
final GlobalKey<NavigatorState> appRootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'appRootNavigator');
