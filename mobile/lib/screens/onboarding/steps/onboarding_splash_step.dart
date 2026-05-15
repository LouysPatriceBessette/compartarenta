import 'dart:async';

import 'package:flutter/material.dart';

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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Image.asset(
          'assets/brand/app_logo.png',
          height: 180,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
