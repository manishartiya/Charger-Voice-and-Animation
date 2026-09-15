import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'charging_animation.dart';
import 'port_glow.dart';

/// Full-bleed artwork with a slow camera move, elemental particles and a port aura.
class CinematicScene extends StatefulWidget {
  const CinematicScene({
    super.key,
    required this.style,
    this.portGlow = true,
    this.portPosition = 'bottom',
    this.portOptions = const PortGlowOptions(),
  });
  final ChargeStyle style;
  final bool portGlow;
  final String portPosition;
  final PortGlowOptions portOptions;
  @override
  State<CinematicScene> createState() => _CinematicSceneState();
}

class _CinematicSceneState extends State<CinematicScene>
    with SingleTickerProviderStateMixin {
  late final motion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) ||
        !TickerMode.valuesOf(context).enabled) {
      motion.stop();
    } else {
      motion.repeat();
    }
  }

  @override
  void dispose() {
    motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: ClipRect(
      child: AnimatedBuilder(
        animation: motion,
        builder: (context, child) => Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -.4),
                  radius: 1.1,
                  colors: [Color(0xFF38275C), Color(0xFF100E1C)],
                ),
              ),
            ),
            if (widget.style == ChargeStyle.eevee) child!,
            if (widget.style.hasArtwork && widget.style != ChargeStyle.eevee)
              Transform.translate(
                offset: Offset(
                  math.sin(motion.value * math.pi * 2) * 7,
                  math.cos(motion.value * math.pi * 2) * 8,
                ),
                child: Transform.scale(
                  scale: 1.07 + .025 * math.sin(motion.value * math.pi * 2),
                  child: child,
                ),
              ),
            if (!widget.style.hasArtwork)
              Opacity(
                opacity: .85,
                child: Transform.scale(
                  scale: 1.55,
                  child: ChargingArt(style: widget.style, showLabel: false),
                ),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: widget.style == ChargeStyle.eevee
                      ? const [
                          Color(0x22100E1C),
                          Color(0x00100E1C),
                          Color(0x00100E1C),
                          Color(0x22100E1C),
                        ]
                      : const [
                          Color(0x55100E1C),
                          Color(0x00100E1C),
                          Color(0x33100E1C),
                          Color(0xF2100E1C),
                        ],
                  stops: [0, .22, .5, .85],
                ),
              ),
            ),
            CustomPaint(
              painter: EnergyField(
                widget.style.color,
                motion.value,
                widget.style.name,
              ),
            ),
            if (widget.portGlow)
              PortGlow(
                options: widget.portOptions,
                position: widget.portPosition,
                themeColor: widget.style.color,
              ),
          ],
        ),
        child: widget.style.hasArtwork
            ? LayoutBuilder(
                builder: (context, box) => Padding(
                  padding: widget.style == ChargeStyle.pikachu
                      ? EdgeInsets.fromLTRB(
                          24,
                          box.maxHeight * .14,
                          24,
                          box.maxHeight * .3,
                        )
                      : EdgeInsets.zero,
                  child: Image.asset(
                    'assets/characters/${widget.style.name}.png',
                    fit: widget.style.isPokemon ? BoxFit.contain : BoxFit.cover,
                    alignment: widget.style == ChargeStyle.eevee
                        ? Alignment.center
                        : Alignment.topCenter,
                    filterQuality: FilterQuality.medium,
                    cacheWidth: 1080,
                  ),
                ),
              )
            : null,
      ),
    ),
  );
}

class EnergyField extends CustomPainter {
  EnergyField(this.color, this.phase, [this.variant = "neon"]);
  final String variant;
  final Color color;
  final double phase;
  @override
  void paint(Canvas canvas, Size size) {
    final t = phase * math.pi * 2;
    final stroke = Paint()..style = PaintingStyle.stroke;
    if (variant == 'prism' || variant == 'nova') {
      final center = Offset(size.width / 2, size.height * .42);
      for (var ring = 0; ring < 5; ring++) {
        final radius = size.shortestSide * (.18 + ring * .045);
        final path = Path();
        final sides = variant == 'prism' ? 6 : 32;
        for (var point = 0; point <= sides; point++) {
          final angle =
              point * math.pi * 2 / sides + t * (ring.isEven ? 1 : -1) * .2;
          final r =
              radius + (variant == 'nova' ? math.sin(angle * 6 + t) * 12 : 0);
          final p = center + Offset(math.cos(angle), math.sin(angle)) * r;
          if (point == 0) {
            path.moveTo(p.dx, p.dy);
          } else {
            path.lineTo(p.dx, p.dy);
          }
        }
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = color.withValues(alpha: .65 - ring * .1),
        );
      }
    }
    for (var i = 0; i < 48; i++) {
      final progress = (phase * (1 + i % 3) + i / 48) % 1;
      final x = size.width * ((i * .618) % 1) + math.sin(t + i) * 18;
      final y = size.height * (1 - progress);
      final alpha = math.sin(progress * math.pi) * .65;
      canvas.drawCircle(
        Offset(x, y),
        1 + i % 3 * .7,
        Paint()..color = color.withValues(alpha: alpha),
      );
      if (i % 5 == 0 &&
          ['shinchan', 'pikachu', 'eevee', 'doraemon'].contains(variant)) {
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(t + i);
        final spark = Path();
        if (variant == 'pikachu') {
          spark.moveTo(1, -9);
          spark.lineTo(-5, 1);
          spark.lineTo(0, 1);
          spark.lineTo(-1, 9);
          spark.lineTo(5, -1);
          spark.lineTo(0, -1);
          spark.close();
        } else {
          for (var p = 0; p < 10; p++) {
            final a = p * math.pi / 5;
            final r = p.isEven ? 7.0 : 3.0;
            if (p == 0) {
              spark.moveTo(math.cos(a) * r, math.sin(a) * r);
            } else {
              spark.lineTo(math.cos(a) * r, math.sin(a) * r);
            }
          }
          spark.close();
        }
        canvas.drawPath(spark, Paint()..color = color.withValues(alpha: alpha));
        canvas.restore();
      }
      if (i % 4 == 0) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x - 5, y + 20),
          Paint()
            ..color = color.withValues(alpha: alpha * .3)
            ..strokeWidth = 1,
        );
      }
      if (variant == 'comet' && i % 3 == 0) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x - 65, y - 100),
          Paint()
            ..strokeWidth = 2
            ..shader = LinearGradient(colors: [Colors.transparent, color])
                .createShader(
                  Rect.fromPoints(Offset(x - 65, y - 100), Offset(x, y)),
                ),
        );
      }
    }
    // Slow moving light along all four display edges.
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(28)),
      stroke
        ..strokeWidth = 4
        ..shader = SweepGradient(
          transform: GradientRotation(t),
          colors: [
            Colors.transparent,
            color.withValues(alpha: .75),
            Colors.transparent,
            color.withValues(alpha: .3),
            Colors.transparent,
          ],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(EnergyField old) =>
      old.phase != phase || old.color != color || old.variant != variant;
}

class ChargingLightBar extends StatefulWidget {
  const ChargingLightBar({super.key, required this.color});
  final Color color;
  @override
  State<ChargingLightBar> createState() => _ChargingLightBarState();
}

class _ChargingLightBarState extends State<ChargingLightBar>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) ||
        !TickerMode.valuesOf(context).enabled) {
      controller.stop();
    } else {
      controller.repeat();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (_, _) => Container(
      width: 132,
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0x66171028),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: widget.color.withValues(alpha: .2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(19, (i) {
          final wave =
              (math.sin(controller.value * math.pi * 2 - i * .4) + 1) / 2;
          return Container(
            width: 2,
            height: 3 + wave * 10,
            decoration: BoxDecoration(
              color: Color.lerp(
                widget.color.withValues(alpha: .2),
                Colors.white,
                wave,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    ),
  );
}
