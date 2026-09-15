import 'dart:math' as math;
import 'package:flutter/material.dart';

const portStyles = {
  'streams': 'Energy streams',
  'ripple': 'Pulse rings',
  'flame': 'Flame jet',
  'lightning': 'Lightning',
  'bubbles': 'Floating bubbles',
  'wave': 'Aurora ribbon',
};
const portColors = {
  'theme': 'Match scene',
  'violet': 'Violet',
  'cyan': 'Ice blue',
  'pink': 'Pink',
  'gold': 'Gold',
  'mint': 'Mint',
  'rainbow': 'Rainbow',
};

@immutable
class PortGlowOptions {
  const PortGlowOptions({
    this.style = 'streams',
    this.color = 'theme',
    this.size = 1,
    this.intensity = .7,
    this.speed = 1,
    this.offset = .5,
  });
  factory PortGlowOptions.fromData(Map<String, dynamic> data) {
    double number(String key, double fallback, double min, double max) =>
        (data[key] is num ? (data[key] as num).toDouble() : fallback).clamp(
          min,
          max,
        );
    return PortGlowOptions(
      style: portStyles.containsKey(data['portStyle'])
          ? data['portStyle'] as String
          : 'streams',
      color: portColors.containsKey(data['portColor'])
          ? data['portColor'] as String
          : 'theme',
      size: number('portSize', 1, .7, 1.4),
      intensity: number('portIntensity', .7, .4, 1),
      speed: number('portSpeed', 1, .5, 1.5),
      offset: number('portOffset', .5, .15, .85),
    );
  }
  final String style, color;
  final double size, intensity, speed, offset;
  Color resolveColor(Color theme, double phase) => switch (color) {
    'violet' => const Color(0xFFB8A4FF),
    'cyan' => const Color(0xFF68E4FF),
    'pink' => const Color(0xFFFF83C4),
    'gold' => const Color(0xFFFFCA70),
    'mint' => const Color(0xFF75F8C0),
    'rainbow' => HSVColor.fromAHSV(1, phase * 360, .65, 1).toColor(),
    _ => theme,
  };
}

/// Shared by the settings preview and the actual lock-screen charging scene.
class PortGlow extends StatefulWidget {
  const PortGlow({
    super.key,
    this.options = const PortGlowOptions(),
    this.position = 'bottom',
    required this.themeColor,
  });
  final PortGlowOptions options;
  final String position;
  final Color themeColor;
  @override
  State<PortGlow> createState() => _PortGlowState();
}

class _PortGlowState extends State<PortGlow>
    with SingleTickerProviderStateMixin {
  late final motion = AnimationController(vsync: this);
  void sync() {
    motion.duration = Duration(
      milliseconds: (4000 / widget.options.speed).round(),
    );
    if (MediaQuery.disableAnimationsOf(context) ||
        !TickerMode.valuesOf(context).enabled) {
      motion.stop();
    } else {
      motion.repeat();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    sync();
  }

  @override
  void didUpdateWidget(PortGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.options.speed != widget.options.speed) sync();
  }

  @override
  void dispose() {
    motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: RepaintBoundary(
      child: AnimatedBuilder(
        animation: motion,
        builder: (_, _) => CustomPaint(
          painter: PortGlowPainter(
            options: widget.options,
            position: widget.position,
            color: widget.options.resolveColor(widget.themeColor, motion.value),
            phase: motion.value,
          ),
        ),
      ),
    ),
  );
}

class PortGlowPainter extends CustomPainter {
  const PortGlowPainter({
    required this.options,
    required this.position,
    required this.color,
    required this.phase,
  });
  final PortGlowOptions options;
  final String position;
  final Color color;
  final double phase;
  @override
  void paint(Canvas canvas, Size size) {
    final origin = switch (position) {
      'top' => Offset(size.width * options.offset, 0),
      'left' => Offset(0, size.height * options.offset),
      'right' => Offset(size.width, size.height * options.offset),
      _ => Offset(size.width * options.offset, size.height),
    };
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(switch (position) {
      'top' => math.pi,
      'left' => math.pi / 2,
      'right' => -math.pi / 2,
      _ => 0.0,
    });
    // Keep the same proportions in a compact preview and on the phone.
    final scale = math.min(size.shortestSide / 300, 1.4) * options.size;
    canvas.scale(scale);
    final t = phase * math.pi * 2;
    Color tint(double opacity) =>
        color.withValues(alpha: opacity * options.intensity);
    final aura = Paint()
      ..shader = RadialGradient(
        colors: [tint(.65), tint(.14), Colors.transparent],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: 140));
    canvas.drawCircle(Offset.zero, 140, aura);
    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var i = 0; i < 9; i++) {
      final p = (phase * 2 + i / 9) % 1;
      final spread = (i - 4) * 13.0;
      ink.color = tint(1 - p * .8);
      ink.shader = null;
      switch (options.style) {
        case 'ripple':
          if (i > 4) continue;
          final progress = (phase * 2 + i / 5) % 1;
          ink.color = tint(1 - progress);
          canvas.drawArc(
            Rect.fromCircle(center: Offset.zero, radius: 12 + progress * 135),
            math.pi,
            math.pi,
            false,
            ink,
          );
        case 'bubbles':
          final point = Offset(spread + math.sin(t + i) * 12, -12 - p * 145);
          canvas.drawCircle(point, 3 + (i % 3) * 2.0, ink);
          canvas.drawCircle(
            point + const Offset(-1, -1),
            1.2,
            Paint()..color = tint(1 - p),
          );
        case 'lightning':
          if (i.isOdd) continue;
          final path = Path()..moveTo(spread * .2, -3);
          for (var step = 1; step <= 7; step++) {
            path.lineTo(
              spread * step / 5 + math.sin(t * 3 + step * 2 + i) * 10,
              -step * 19.0,
            );
          }
          ink.color = tint(.5 + .35 * math.sin(t * 2 + i));
          canvas.drawPath(path, ink);
        case 'flame':
          final height = 85 + 38 * math.sin(t * 2 + i);
          final x = spread * .6;
          final path = Path()
            ..moveTo(x - 12, 0)
            ..quadraticBezierTo(
              x - 26,
              -height * .55,
              x + math.sin(t + i) * 22,
              -height,
            )
            ..quadraticBezierTo(x + 22, -height * .35, x + 12, 0)
            ..close();
          canvas.drawPath(
            path,
            Paint()
              ..shader = LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [tint(.4), tint(.1), Colors.transparent],
              ).createShader(Rect.fromLTWH(-80, -height, 160, height)),
          );
        case 'wave':
          final path = Path()..moveTo(-130, -i * 9.0);
          for (var x = -130.0; x <= 130; x += 4) {
            path.lineTo(x, -i * 9 - 28 - math.sin(x / 45 + t + i * .3) * 22);
          }
          ink.color = tint(.15 + (8 - i) * .08);
          canvas.drawPath(path, ink);
        default:
          final wave = math.sin(t + i) * 12;
          final path = Path()
            ..moveTo(spread * .18, 0)
            ..cubicTo(
              spread * .3 + wave,
              -28,
              spread - wave,
              -70,
              spread * 1.6,
              -140,
            );
          ink.shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [tint(1), tint(.5), Colors.transparent],
          ).createShader(const Rect.fromLTWH(-100, -140, 200, 140));
          canvas.drawPath(path, ink);
          canvas.drawCircle(
            Offset(spread * p * 1.6, -140 * p),
            2,
            Paint()..color = tint(1 - p),
          );
      }
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-20, -4, 40, 7),
        const Radius.circular(4),
      ),
      Paint()
        ..color = tint(.95)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(PortGlowPainter oldDelegate) =>
      phase != oldDelegate.phase ||
      color != oldDelegate.color ||
      position != oldDelegate.position ||
      options != oldDelegate.options;
}
