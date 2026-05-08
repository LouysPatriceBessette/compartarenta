import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

class OnboardingSplashStep extends StatefulWidget {
  const OnboardingSplashStep({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<OnboardingSplashStep> createState() => _OnboardingSplashStepState();
}

class _OnboardingSplashStepState extends State<OnboardingSplashStep> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 1), widget.onDone);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        MdiIcons.dog,
        size: 96,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

