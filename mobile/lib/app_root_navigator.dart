import 'package:flutter/material.dart';

/// [GoRouter] is wired with this key so notification taps can call `context.go`.
final GlobalKey<NavigatorState> appRootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'appRootNavigator');
