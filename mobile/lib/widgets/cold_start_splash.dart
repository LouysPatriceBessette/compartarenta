import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'bojairu_animated_logo.dart';

class ColdStartSplash extends StatefulWidget {
  const ColdStartSplash({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 5),
    this.fadeInDuration = const Duration(milliseconds: 400),
    this.fadeDuration = const Duration(seconds: 1),
  });

  static const splashKey = Key('cold-start-splash');
  static const logoFadeKey = Key('cold-start-splash-logo-fade');
  static const fadeKey = Key('cold-start-splash-fade');

  final Widget child;
  final Duration duration;
  final Duration fadeInDuration;
  final Duration fadeDuration;

  @override
  State<ColdStartSplash> createState() => _ColdStartSplashState();
}

class _ColdStartSplashState extends State<ColdStartSplash> {
  late final Timer _fadeTimer;
  var _isVisible = true;
  var _isLogoVisible = false;
  var _isFading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _isLogoVisible = true);
      }
    });
    _fadeTimer = Timer(widget.duration, () {
      if (mounted) {
        setState(() => _isFading = true);
      }
    });
  }

  @override
  void dispose() {
    _fadeTimer.cancel();
    super.dispose();
  }

  void _finishFade() {
    if (_isFading && mounted) {
      setState(() => _isVisible = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topLeft,
      fit: StackFit.expand,
      children: [
        ExcludeSemantics(excluding: _isVisible, child: widget.child),
        if (_isVisible)
          AnimatedOpacity(
            key: ColdStartSplash.fadeKey,
            opacity: _isFading ? 0 : 1,
            duration: widget.fadeDuration,
            onEnd: _finishFade,
            child: ColoredBox(
              key: ColdStartSplash.splashKey,
              color: AppBrandColors.sand,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ExcludeSemantics(
                      child: AnimatedOpacity(
                        key: ColdStartSplash.logoFadeKey,
                        opacity: _isLogoVisible ? 1 : 0,
                        duration: widget.fadeInDuration,
                        child: BojairuAnimatedLogo(duration: widget.duration),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
