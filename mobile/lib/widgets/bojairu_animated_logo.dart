import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BojairuAnimatedLogo extends StatefulWidget {
  const BojairuAnimatedLogo({
    super.key,
    this.duration = const Duration(seconds: 5),
  });

  static const spiralKey = Key('bojairu-animated-spiral');

  final Duration duration;

  @override
  State<BojairuAnimatedLogo> createState() => _BojairuAnimatedLogoState();
}

class _BojairuAnimatedLogoState extends State<BojairuAnimatedLogo>
    with SingleTickerProviderStateMixin {
  static const _designSize = 460.0;
  static const _centerX = 230.0;
  static const _centerY = 228.0;
  static const _playbackSpeed = 1.5;
  static const _spiralAlignment = Alignment(0, -2 / 230);
  static const _assetRoot = 'assets/brand/splash';

  static const _icons = [
    _IconMotion(
      asset: '$_assetRoot/icon_house.svg',
      orbitSeconds: 18,
      spinSeconds: 10,
      breathSeconds: 8,
      radius: 72,
      inwardDistance: 28,
      startAngleDegrees: 63,
      initialTwistDegrees: -10,
      scale: 2.55,
    ),
    _IconMotion(
      asset: '$_assetRoot/icon_car.svg',
      orbitSeconds: 22,
      spinSeconds: 14,
      breathSeconds: 9,
      radius: 108,
      inwardDistance: 36,
      startAngleDegrees: 207,
      initialTwistDegrees: 8,
      scale: 2.45,
    ),
    _IconMotion(
      asset: '$_assetRoot/icon_dollar.svg',
      orbitSeconds: 26,
      spinSeconds: 12,
      breathSeconds: 10,
      radius: 148,
      inwardDistance: 48,
      startAngleDegrees: 9,
      initialTwistDegrees: -6,
      scale: 2.7,
    ),
    _IconMotion(
      asset: '$_assetRoot/icon_calendar.svg',
      orbitSeconds: 30,
      spinSeconds: 16,
      breathSeconds: 11,
      radius: 178,
      inwardDistance: 55,
      startAngleDegrees: 171,
      initialTwistDegrees: 6,
      scale: 2.55,
    ),
  ];

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox.square(
        dimension: _designSize,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final sourceSeconds =
                _controller.value *
                widget.duration.inMicroseconds /
                Duration.microsecondsPerSecond *
                _playbackSpeed;
            return Stack(
              alignment: Alignment.topLeft,
              fit: StackFit.expand,
              children: [
                _buildTornado(sourceSeconds),
                for (final icon in _icons) _buildIcon(icon, sourceSeconds),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTornado(double sourceSeconds) {
    final rotation = -2 * math.pi * sourceSeconds / 5;
    return Transform.rotate(
      key: BojairuAnimatedLogo.spiralKey,
      angle: rotation,
      alignment: _spiralAlignment,
      child: Stack(
        alignment: Alignment.topLeft,
        fit: StackFit.expand,
        children: [
          _buildBreathingArm(
            asset: '$_assetRoot/tornado_arm_main.svg',
            sourceSeconds: sourceSeconds,
            minimum: 0.92,
            maximum: 1.08,
            periodSeconds: 7,
            beginSeconds: 0,
          ),
          _buildBreathingArm(
            asset: '$_assetRoot/tornado_arm_thick.svg',
            sourceSeconds: sourceSeconds,
            minimum: 0.88,
            maximum: 1.12,
            periodSeconds: 9,
            beginSeconds: -2.5,
          ),
          _buildBreathingArm(
            asset: '$_assetRoot/tornado_arm_fine.svg',
            sourceSeconds: sourceSeconds,
            minimum: 0.9,
            maximum: 1.1,
            periodSeconds: 11,
            beginSeconds: -5,
          ),
          _svgLayer('$_assetRoot/tornado_streaks.svg'),
        ],
      ),
    );
  }

  Widget _buildBreathingArm({
    required String asset,
    required double sourceSeconds,
    required double minimum,
    required double maximum,
    required double periodSeconds,
    required double beginSeconds,
  }) {
    final middle = (minimum + maximum) / 2;
    final phase = _phase(sourceSeconds - beginSeconds, periodSeconds);
    final values = [middle, maximum, middle, minimum, middle];
    final position = phase * 4;
    final segment = position.floor().clamp(0, 3);
    final eased = Curves.easeInOut.transform(position - segment);
    final scale = _lerp(values[segment], values[segment + 1], eased);

    return Transform.scale(
      scale: scale,
      alignment: _spiralAlignment,
      child: _svgLayer(asset),
    );
  }

  Widget _buildIcon(_IconMotion icon, double sourceSeconds) {
    final orbitAngle = _radians(
      icon.startAngleDegrees - 360 * sourceSeconds / icon.orbitSeconds,
    );
    final radius = _breathingRadius(icon, sourceSeconds);
    final iconSize = 24 * icon.scale;
    final x = _centerX + radius * math.cos(orbitAngle);
    final y = _centerY + radius * math.sin(orbitAngle) * 1.1;
    final selfRotation = _radians(
      icon.initialTwistDegrees - 360 * sourceSeconds / icon.spinSeconds,
    );

    return Positioned(
      left: x - iconSize / 2,
      top: y - iconSize / 2,
      width: iconSize,
      height: iconSize,
      child: Transform.scale(
        scaleY: 1.1,
        child: Transform.rotate(
          angle: selfRotation,
          child: RepaintBoundary(child: SvgPicture.asset(icon.asset)),
        ),
      ),
    );
  }

  double _breathingRadius(_IconMotion icon, double sourceSeconds) {
    final phase = _phase(sourceSeconds, icon.breathSeconds);
    final minimum = icon.radius - icon.inwardDistance;
    if (phase < 0.5) {
      return _lerp(icon.radius, minimum, Curves.easeInOut.transform(phase * 2));
    }
    return _lerp(
      minimum,
      icon.radius,
      Curves.easeInOut.transform((phase - 0.5) * 2),
    );
  }

  Widget _svgLayer(String asset) {
    return RepaintBoundary(child: SvgPicture.asset(asset, fit: BoxFit.fill));
  }

  double _phase(double seconds, double periodSeconds) {
    return (seconds / periodSeconds) % 1;
  }

  double _radians(double degrees) => degrees * math.pi / 180;

  double _lerp(double start, double end, double progress) {
    return start + (end - start) * progress;
  }
}

final class _IconMotion {
  const _IconMotion({
    required this.asset,
    required this.orbitSeconds,
    required this.spinSeconds,
    required this.breathSeconds,
    required this.radius,
    required this.inwardDistance,
    required this.startAngleDegrees,
    required this.initialTwistDegrees,
    required this.scale,
  });

  final String asset;
  final double orbitSeconds;
  final double spinSeconds;
  final double breathSeconds;
  final double radius;
  final double inwardDistance;
  final double startAngleDegrees;
  final double initialTwistDegrees;
  final double scale;
}
