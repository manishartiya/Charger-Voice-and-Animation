import 'port_glow.dart';
import 'dart:async';
import 'cinematic_scene.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum ChargeStyle {
  neon('Neon Pulse', 'Electric rings. Pure energy.', Color(0xFFB8A4FF)),
  orbit('Orbit', 'A little universe of your own.', Color(0xFF70DDFF)),
  liquid(
    'Liquid Glow',
    'Watch your battery fill with light.',
    Color(0xFFB49BFF),
  ),
  aurora('Aurora', 'A sky of shifting colour.', Color(0xFFFF98CF)),
  water(
    'Water Breathing',
    'Tanjiro-inspired currents of blue.',
    Color(0xFF53D9F3),
  ),
  flame(
    'Flame Breathing',
    'Rengoku-inspired embers in motion.',
    Color(0xFFFF9A46),
  ),
  thunder(
    'Thunder Breathing',
    'Zenitsu-inspired golden lightning.',
    Color(0xFFFFD65A),
  ),
  mist('Mist Breathing', 'Muichiro-inspired drifting fog.', Color(0xFFB7F3E8)),
  insect(
    'Butterfly Dance',
    'Shinobu-inspired violet wings.',
    Color(0xFFD5A4FF),
  ),
  sun('Hinokami', 'Sun-breathing-inspired crimson fire.', Color(0xFFFF6958)),
  shinchan(
    'Shin-chan',
    'A little mischief. A lot of energy.',
    Color(0xFFFF91AB),
  ),
  pikachu('Pikachu', 'An electric little power-up.', Color(0xFFFFD66C)),
  eevee('Eevee', 'Stardust, warmth and a little wonder.', Color(0xFFFFC29D)),
  doraemon('Doraemon', 'A pocket full of tomorrow.', Color(0xFF7CDFFF)),
  nova('Supernova', 'A star awakening in violet light.', Color(0xFFE1A0FF)),
  comet(
    'Comet Trails',
    'Streaks of light across your universe.',
    Color(0xFF90E8FF),
  ),
  prism('Prism Bloom', 'A kaleidoscope of living light.', Color(0xFFFFB9D0));

  const ChargeStyle(this.title, this.subtitle, this.color);
  final String title;
  final String subtitle;
  final Color color;
  bool get isSlayer => index >= 4 && index <= 9;
  bool get hasArtwork => index >= 4 && index <= 13;
  bool get isPokemon => this == pikachu || this == eevee;
  static ChargeStyle parse(String? value) =>
      values.firstWhere((s) => s.name == value, orElse: () => neon);
}

class ChargingArt extends StatefulWidget {
  const ChargingArt({
    super.key,
    required this.style,
    this.level = 64,
    this.animate = true,
    this.showLabel = true,
  });
  final ChargeStyle style;
  final int level;
  final bool animate;
  final bool showLabel;
  @override
  State<ChargingArt> createState() => _ChargingArtState();
}

class _ChargingArtState extends State<ChargingArt>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    syncMotion();
  }

  @override
  void didUpdateWidget(ChargingArt oldWidget) {
    super.didUpdateWidget(oldWidget);
    syncMotion();
  }

  void syncMotion() {
    if (widget.animate &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled) {
      if (!controller.isAnimating) controller.repeat();
    } else {
      controller.stop();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedBuilder(
      animation: controller,
      builder: (context, child) => CustomPaint(
        painter: ChargeArtPainter(
          widget.style,
          controller.value,
          widget.level < 0 ? 0 : widget.level / 100,
        ),
        child: child,
      ),
      child: Center(
        child: widget.showLabel
            ? LayoutBuilder(
                builder: (context, box) {
                  final extent = math.min(box.maxWidth, box.maxHeight);
                  final tiny = extent < 190;
                  final compact = extent < 300;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bolt_rounded,
                        color: widget.style.color,
                        size: tiny
                            ? 22
                            : compact
                            ? 28
                            : 38,
                      ),
                      Text(
                        widget.level < 0 ? '—' : '${widget.level}%',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: tiny
                              ? 26
                              : compact
                              ? 44
                              : 62,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -2,
                        ),
                      ),
                      if (!tiny)
                        Text(
                          widget.level == 100
                              ? 'FULLY CHARGED'
                              : compact
                              ? 'CHARGING'
                              : 'ENERGY IN MOTION',
                          style: TextStyle(
                            color: widget.style.color,
                            fontSize: 10,
                            letterSpacing: 2,
                          ),
                        ),
                    ],
                  );
                },
              )
            : const SizedBox.expand(),
      ),
    ),
  );
}

class ChargeArtPainter extends CustomPainter {
  ChargeArtPainter(this.style, this.phase, this.level);
  final ChargeStyle style;
  final double phase;
  final double level;
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = math.min(size.width, size.height) * .36;
    final color = style.color;
    final t = phase * math.pi * 2;
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: .16), color.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: center, radius: r * 1.5));
    canvas.drawCircle(center, r * 1.5, glow);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    switch (style) {
      case ChargeStyle.shinchan:
      case ChargeStyle.pikachu:
      case ChargeStyle.eevee:
      case ChargeStyle.doraemon:
      case ChargeStyle.water:
      case ChargeStyle.flame:
      case ChargeStyle.thunder:
      case ChargeStyle.mist:
      case ChargeStyle.insect:
      case ChargeStyle.sun:
        paintSlayer(canvas, center, r, t, style);
      case ChargeStyle.neon:
        for (var i = 0; i < 3; i++) {
          final pulse = (phase * 2 + i / 3) % 1;
          canvas.drawCircle(
            center,
            r * (.95 + pulse * .4),
            line
              ..strokeWidth = 2
              ..color = color.withValues(alpha: (1 - pulse) * .32),
          );
        }
        canvas.drawCircle(
          center,
          r,
          line
            ..strokeWidth = 6
            ..color = color.withValues(alpha: .13),
        );
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: r),
          -math.pi / 2,
          math.pi * 2 * level.clamp(0, 1),
          false,
          line
            ..strokeWidth = 5
            ..color = color,
        );
        for (var i = 0; i < 32; i++) {
          final a = i * math.pi / 16;
          final d = Offset(math.cos(a), math.sin(a));
          canvas.drawLine(
            center + d * r * .84,
            center + d * r * .88,
            line
              ..strokeWidth = 1.5
              ..color = color.withValues(alpha: .3),
          );
        }
      case ChargeStyle.nova:
      case ChargeStyle.comet:
      case ChargeStyle.prism:
      case ChargeStyle.orbit:
        for (var i = 0; i < 3; i++) {
          canvas.save();
          canvas.translate(center.dx, center.dy);
          canvas.rotate(i * math.pi / 3 + t * .12);
          final rect = Rect.fromCenter(
            center: Offset.zero,
            width: r * 2.5,
            height: r * 1.25,
          );
          canvas.drawOval(
            rect,
            line
              ..strokeWidth = 1.5
              ..color = color.withValues(alpha: .26),
          );
          final a = t + i * 2;
          final particle = Offset(
            math.cos(a) * r * 1.25,
            math.sin(a) * r * .625,
          );
          canvas.drawCircle(
            particle,
            5,
            Paint()..color = i == 1 ? const Color(0xFFC5B6FF) : color,
          );
          canvas.restore();
        }
        canvas.drawCircle(
          center,
          r * .82,
          line
            ..strokeWidth = 1
            ..color = color.withValues(alpha: .25),
        );
      case ChargeStyle.liquid:
        canvas.save();
        canvas.clipPath(
          Path()..addOval(Rect.fromCircle(center: center, radius: r)),
        );
        canvas.drawCircle(
          center,
          r,
          Paint()..color = color.withValues(alpha: .07),
        );
        for (var layer = 0; layer < 2; layer++) {
          final path = Path()..moveTo(center.dx - r, center.dy + r);
          for (var i = 0; i <= 80; i++) {
            final x = center.dx - r + 2 * r * i / 80;
            final y =
                center.dy +
                r -
                2 * r * level.clamp(.05, .97) +
                math.sin(i / 80 * math.pi * 3 + t + layer * 2) * r * .08;
            path.lineTo(x, y);
          }
          path.lineTo(center.dx + r, center.dy + r);
          path.close();
          canvas.drawPath(
            path,
            Paint()..color = color.withValues(alpha: layer == 0 ? .24 : .35),
          );
        }
        for (var i = 0; i < 12; i++) {
          final p = (phase + i / 12) % 1;
          canvas.drawCircle(
            Offset(
              center.dx + math.sin(i * 8.0) * r * .8,
              center.dy + r - p * r * 2,
            ),
            2 + i % 3.0,
            Paint()..color = Colors.white.withValues(alpha: (1 - p) * .4),
          );
        }
        canvas.restore();
        canvas.drawCircle(
          center,
          r,
          line
            ..strokeWidth = 3
            ..color = color.withValues(alpha: .8),
        );
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: r * 1.12),
          t,
          math.pi * .8,
          false,
          line
            ..strokeWidth = 2
            ..color = color.withValues(alpha: .4),
        );
      case ChargeStyle.aurora:
        for (var layer = 0; layer < 3; layer++) {
          final path = Path();
          for (var i = 0; i <= 120; i++) {
            final a = i / 120 * math.pi * 2;
            final radius =
                r *
                (1 +
                    .10 * math.sin(a * 3 + t + layer) +
                    .045 * math.sin(a * 7 - t));
            final p = center + Offset(math.cos(a), math.sin(a)) * radius;
            if (i == 0) {
              path.moveTo(p.dx, p.dy);
            } else {
              path.lineTo(p.dx, p.dy);
            }
          }
          path.close();
          final paint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4 + layer * 4.0
            ..shader = SweepGradient(
              colors: [
                color,
                const Color(0xFFAA85FF),
                const Color(0xFF70DDFF),
                color,
              ],
              transform: GradientRotation(t),
            ).createShader(Rect.fromCircle(center: center, radius: r));
          if (layer > 0) {
            paint.maskFilter = MaskFilter.blur(BlurStyle.normal, layer * 6.0);
          }
          canvas.drawPath(path, paint);
        }
    }
  }

  void paintSlayer(
    Canvas canvas,
    Offset c,
    double r,
    double t,
    ChargeStyle style,
  ) {
    final color = style.color;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // A quiet katana-like vertical accent unites the anime collection.
    canvas.drawLine(
      c + Offset(0, -r * 1.36),
      c + Offset(0, -r * 1.08),
      stroke
        ..strokeWidth = 2
        ..color = color.withValues(alpha: .55),
    );
    canvas.drawLine(
      c + Offset(-r * .09, -r * 1.15),
      c + Offset(r * .09, -r * 1.15),
      stroke
        ..strokeWidth = 2
        ..color = color.withValues(alpha: .4),
    );
    switch (style) {
      case ChargeStyle.water:
        // Ink-like water ribbons, outlined foam, and drifting droplets.
        for (var layer = 0; layer < 4; layer++) {
          final path = Path();
          for (var i = 0; i <= 150; i++) {
            final a = i / 150 * math.pi * 2;
            final radius =
                r *
                (1 + layer * .045 + .07 * math.sin(a * 4 - t * 2 + layer * .6));
            final p = c + Offset(math.cos(a), math.sin(a)) * radius;
            if (i == 0) {
              path.moveTo(p.dx, p.dy);
            } else {
              path.lineTo(p.dx, p.dy);
            }
          }
          path.close();
          canvas.drawPath(
            path,
            stroke
              ..strokeWidth = layer == 0 ? 9 : 3
              ..color = [
                const Color(0xFF1979CB),
                color,
                const Color(0xFFE8FFFF),
                color.withValues(alpha: .3),
              ][layer],
          );
        }
        for (var i = 0; i < 18; i++) {
          final a = i * math.pi / 9 + t * .4;
          final p =
              c +
              Offset(math.cos(a), math.sin(a)) *
                  r *
                  (1.2 + .05 * math.sin(t + i));
          canvas.drawCircle(
            p,
            1.5 + i % 3,
            Paint()..color = color.withValues(alpha: .6),
          );
        }
      case ChargeStyle.flame:
      case ChargeStyle.sun:
        final sun = style == ChargeStyle.sun;
        canvas.drawCircle(
          c,
          r,
          stroke
            ..strokeWidth = 5
            ..color = sun ? const Color(0xFFFFCA64) : const Color(0xFFFFCC6C),
        );
        for (var i = 0; i < 28; i++) {
          final a = i * math.pi / 14 + (sun ? t * .12 : 0);
          final d = Offset(math.cos(a), math.sin(a));
          final tangent = Offset(-d.dy, d.dx);
          final height =
              r * (.16 + .12 * (.5 + .5 * math.sin(t * 2 + i * 1.7)));
          final base = c + d * r * .96;
          final tip = c + d * (r + height) + tangent * r * .10;
          final flame = Path()
            ..moveTo(
              (base - tangent * r * .075).dx,
              (base - tangent * r * .075).dy,
            )
            ..quadraticBezierTo(
              (base + d * height).dx,
              (base + d * height).dy,
              tip.dx,
              tip.dy,
            )
            ..quadraticBezierTo(
              (base + tangent * r * .14).dx,
              (base + tangent * r * .14).dy,
              (base + tangent * r * .075).dx,
              (base + tangent * r * .075).dy,
            )
            ..close();
          canvas.drawPath(
            flame,
            Paint()
              ..shader = LinearGradient(
                colors: [
                  const Color(0xFFFFDC7A),
                  sun ? const Color(0xFFDB234B) : const Color(0xFFFF5436),
                ],
                begin: Alignment.center,
                end: Alignment.topCenter,
              ).createShader(Rect.fromCircle(center: base, radius: height + 1)),
          );
        }
        for (var i = 0; i < 16; i++) {
          final progress = (phase + i / 16) % 1;
          final x = c.dx + math.sin(i * 9.0) * r * 1.1;
          final y = c.dy + r - progress * r * 2.7;
          canvas.drawCircle(
            Offset(x, y),
            1 + i % 3,
            Paint()..color = color.withValues(alpha: (1 - progress) * .65),
          );
        }
        if (sun) {
          canvas.drawArc(
            Rect.fromCircle(center: c, radius: r * .86),
            t * .3,
            math.pi * 1.35,
            false,
            stroke
              ..strokeWidth = 2
              ..color = color.withValues(alpha: .65),
          );
          canvas.drawCircle(
            c,
            r * .78,
            stroke
              ..strokeWidth = 1
              ..color = color.withValues(alpha: .16),
          );
        }
      case ChargeStyle.thunder:
        canvas.drawCircle(
          c,
          r,
          stroke
            ..strokeWidth = 1
            ..color = color.withValues(alpha: .22),
        );
        for (var bolt = 0; bolt < 3; bolt++) {
          final path = Path();
          for (var i = 0; i <= 36; i++) {
            final a =
                i / 36 * math.pi * 1.65 + t * .35 + bolt * math.pi * 2 / 3;
            final radius =
                r * (1 + (i.isEven ? .09 : -.04) + .025 * math.sin(t * 2 + i));
            final p = c + Offset(math.cos(a), math.sin(a)) * radius;
            if (i == 0) {
              path.moveTo(p.dx, p.dy);
            } else {
              path.lineTo(p.dx, p.dy);
            }
          }
          canvas.drawPath(
            path,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 8
              ..color = color.withValues(alpha: .25)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
          );
          canvas.drawPath(
            path,
            stroke
              ..strokeWidth = bolt == 0 ? 3 : 1.5
              ..color = bolt == 0
                  ? const Color(0xFFFFF4C5)
                  : color.withValues(alpha: .65),
          );
        }
        for (var i = 0; i < 12; i++) {
          final a = i * math.pi / 6 - t * .08;
          final p = c + Offset(math.cos(a), math.sin(a)) * r * 1.25;
          final d = r * .035;
          canvas.drawPath(
            Path()
              ..moveTo(p.dx, p.dy - d)
              ..lineTo(p.dx - d, p.dy + d)
              ..lineTo(p.dx + d, p.dy + d)
              ..close(),
            Paint()..color = color.withValues(alpha: .4),
          );
        }
      case ChargeStyle.mist:
        for (var layer = 0; layer < 6; layer++) {
          final fog = Path();
          for (var i = 0; i <= 70; i++) {
            final x = c.dx - r * 1.2 + i / 70 * r * 2.4;
            final y =
                c.dy +
                (layer - 2.5) * r * .4 +
                math.sin(i / 70 * math.pi * 2 + t + layer) * r * .12;
            if (i == 0) {
              fog.moveTo(x, y);
            } else {
              fog.lineTo(x, y);
            }
          }
          canvas.drawPath(
            fog,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = r * .2
              ..color = color.withValues(alpha: .10)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
          );
        }
        for (var i = 0; i < 3; i++) {
          canvas.drawArc(
            Rect.fromCircle(center: c, radius: r * (1 + i * .09)),
            t * (i.isEven ? .18 : -.13) + i * 2,
            math.pi * 1.3,
            false,
            stroke
              ..strokeWidth = i == 0 ? 3 : 1
              ..color = color.withValues(alpha: .7 - i * .2),
          );
        }
      case ChargeStyle.insect:
        canvas.drawCircle(
          c,
          r,
          stroke
            ..strokeWidth = 1
            ..color = color.withValues(alpha: .22),
        );
        for (var i = 0; i < 7; i++) {
          final a = i * math.pi * 2 / 7 + t * .18;
          final p =
              c +
              Offset(math.cos(a), math.sin(a)) *
                  r *
                  (1 + .09 * math.sin(t + i));
          canvas.save();
          canvas.translate(p.dx, p.dy);
          canvas.rotate(a + math.pi / 2);
          final wing = r * (.065 + .025 * math.sin(t * 3 + i).abs());
          for (final side in [-1.0, 1.0]) {
            final wings = Path()
              ..moveTo(0, 0)
              ..cubicTo(
                side * wing * 2,
                -wing * 2,
                side * wing * 2.3,
                wing * .4,
                0,
                wing * .35,
              )
              ..cubicTo(
                side * wing * 1.5,
                wing * 1.9,
                side * wing * 1.4,
                wing * 2,
                0,
                wing * .6,
              )
              ..close();
            canvas.drawPath(
              wings,
              Paint()..color = color.withValues(alpha: .75),
            );
            canvas.drawPath(
              wings,
              stroke
                ..strokeWidth = 1
                ..color = const Color(0xFFF4EDFF),
            );
          }
          canvas.drawLine(
            Offset(0, -wing * .4),
            Offset(0, wing),
            stroke
              ..strokeWidth = 1.5
              ..color = Colors.white,
          );
          canvas.restore();
        }
      default:
        break;
    }
  }

  @override
  bool shouldRepaint(ChargeArtPainter oldDelegate) =>
      oldDelegate.phase != phase ||
      oldDelegate.style != style ||
      oldDelegate.level != level;
}

/// Uses the same Flutter art as the picker, hosted in a dedicated Android activity.
class FullScreenCharging extends StatefulWidget {
  const FullScreenCharging({
    super.key,
    required this.style,
    this.preview = false,
    this.seconds = 20,
  });
  final ChargeStyle style;
  final bool preview;
  final int seconds;
  @override
  State<FullScreenCharging> createState() => _FullScreenChargingState();
}

class _FullScreenChargingState extends State<FullScreenCharging>
    with WidgetsBindingObserver {
  static const channel = MethodChannel('charge_voice/control');
  Timer? timer;
  int level = -1;
  bool portGlow = true;
  PortGlowOptions portOptions = const PortGlowOptions();
  String portPosition = "bottom";
  late ChargeStyle activeStyle = widget.style;
  late bool isPreview = widget.preview;
  late int durationSeconds = widget.seconds;
  bool foreground =
      WidgetsBinding.instance.lifecycleState == null ||
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  String? activeRequest;
  double swipeStart = 0;
  double swipeDistance = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    channel.setMethodCallHandler((call) async {
      if (call.method != 'showCharging' || !mounted) return;
      final args = Map<String, dynamic>.from(call.arguments as Map);
      setState(() {
        activeRequest = args['requestId'] as String?;
        activeStyle = ChargeStyle.parse(args['style'] as String?);
        isPreview = args['preview'] == true;
        durationSeconds = (args['seconds'] as num?)?.toInt() ?? 20;
      });
      if (foreground) start();
      acknowledgeFrame();
    });
    if (foreground) start();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        await channel.invokeMethod<void>('chargingHostReady');
      } on PlatformException {
        /* Older host. */
      } on MissingPluginException {
        /* Widget preview. */
      }
      acknowledgeFrame();
    });
  }

  Future<void> acknowledgeFrame() async {
    if (!mounted || !foreground) return;
    final request = activeRequest;
    final style = activeStyle;
    if (activeStyle.hasArtwork) {
      await precacheImage(
        ResizeImage(
          AssetImage('assets/characters/${activeStyle.name}.png'),
          width: 1080,
        ),
        context,
      );
      if (!mounted ||
          !foreground ||
          request != activeRequest ||
          style != activeStyle) {
        return;
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !foreground) return;
      try {
        await channel.invokeMethod<void>('animationReady', {
          'requestId': request,
        });
      } on PlatformException {
        /* Older host. */
      } on MissingPluginException {
        /* Widget preview. */
      }
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  void start() {
    read();
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (_) => read());
  }

  Future<void> read() async {
    try {
      final data = await channel.invokeMapMethod<String, dynamic>('snapshot');
      if (mounted) {
        setState(() {
          level = (data?['level'] as num?)?.toInt() ?? -1;
          portGlow = data?['portGlow'] != false;
          portOptions = PortGlowOptions.fromData(data ?? {});
          portPosition = data?['portPosition'] as String? ?? 'bottom';
        });
      }
    } on PlatformException {
      /* Keep the last valid level. */
    } on MissingPluginException {
      /* Android-only screen. */
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() => foreground = state == AppLifecycleState.resumed);
    if (foreground) {
      start();
      acknowledgeFrame();
    } else {
      timer?.cancel();
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    channel.setMethodCallHandler(null);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> close() async {
    try {
      await channel.invokeMethod<void>('closeAnimation');
    } on PlatformException {
      if (mounted) Navigator.maybePop(context);
    } on MissingPluginException {
      if (mounted) Navigator.maybePop(context);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF100E1C),
    body: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: (details) {
        swipeStart = details.localPosition.dy;
        swipeDistance = 0;
      },
      onVerticalDragUpdate: (details) => swipeDistance += details.delta.dy,
      onVerticalDragEnd: (details) {
        if (swipeStart >= MediaQuery.sizeOf(context).height * .55 &&
            swipeDistance < -60) {
          close();
        }
      },
      child: TickerMode(
        enabled: foreground,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CinematicScene(
              style: activeStyle,
              portGlow: portGlow,
              portOptions: portOptions,
              portPosition: portPosition,
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          color: activeStyle.color,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isPreview
                                ? 'ANIMATION PREVIEW'
                                : 'CHARGER CONNECTED',
                            style: const TextStyle(
                              fontSize: 10,
                              letterSpacing: 2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Spacer(flex: activeStyle == ChargeStyle.eevee ? 3 : 5),
                    Text(
                      activeStyle.title.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: activeStyle.color,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      child: Text(
                        level < 0 ? '—' : '$level%',
                        style: const TextStyle(
                          fontSize: 88,
                          height: 1.05,
                          fontWeight: FontWeight.w300,
                          letterSpacing: -5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 160,
                      child: LinearProgressIndicator(
                        value: level < 0 ? 0 : level / 100,
                        minHeight: 3,
                        borderRadius: BorderRadius.circular(3),
                        color: activeStyle.color,
                        backgroundColor: Colors.white12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      level == 100 ? 'FULLY CHARGED' : 'POWER FLOWS WITHIN',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        letterSpacing: 3,
                      ),
                    ),
                    Spacer(flex: activeStyle == ChargeStyle.eevee ? 5 : 1),
                    Semantics(
                      label:
                          'Charging animation. Closes after $durationSeconds seconds. Use Android Back to dismiss.',
                      child: ChargingLightBar(color: activeStyle.color),
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
