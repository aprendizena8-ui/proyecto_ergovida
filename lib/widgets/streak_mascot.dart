import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'design_system.dart';

/// Mascota animada de la racha. Es una llama con cara que cambia de energía
/// según los días consecutivos y sirve para hacer la app más cercana.
class StreakMascot extends StatefulWidget {
  final int streak;
  final double size;

  const StreakMascot({super.key, required this.streak, this.size = 108});

  @override
  State<StreakMascot> createState() => _StreakMascotState();
}

class _StreakMascotState extends State<StreakMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Mascota de racha: ${widget.streak} ${widget.streak == 1 ? 'día' : 'días'}',
      child: SizedBox(
        width: widget.size,
        height: widget.size * 1.12,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                size: Size(widget.size, widget.size * 1.12),
                painter: _StreakMascotPainter(
                  t: _controller.value,
                  streak: widget.streak,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StreakMascotPainter extends CustomPainter {
  final double t;
  final int streak;

  _StreakMascotPainter({required this.t, required this.streak});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    final cx = w * 0.5;
    final heat = (streak / 14).clamp(0.0, 1.0);
    final wave = math.sin(t * 2 * math.pi);
    final bob = wave * h * 0.022;
    final lean = math.sin(t * 2 * math.pi + 0.7) * w * 0.018;

    final outerTop = Color.lerp(
      const Color(0xFFFFC24B),
      const Color(0xFFFF5A3C),
      heat,
    )!;
    final outerBottom = Color.lerp(
      const Color(0xFFFF8A1F),
      const Color(0xFFD9265F),
      heat,
    )!;
    const innerTop = Color(0xFFFFF4B0);
    const innerBottom = Color(0xFFFFC12F);

    // Sombra fija en el suelo.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, h * 0.945),
        width: w * 0.48,
        height: h * 0.055,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.14),
    );

    // Resplandor cálido alrededor de la llama.
    canvas.drawCircle(
      Offset(cx, h * 0.58),
      w * 0.56,
      Paint()
        ..shader = RadialGradient(
          colors: [
            outerTop.withValues(alpha: streak > 0 ? 0.28 : 0.14),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCircle(center: Offset(cx, h * 0.58), radius: w * 0.56),
        ),
    );

    canvas.save();
    canvas.translate(0, bob);

    // Llama exterior.
    final outerPath = _flamePath(
      cx: cx,
      halfWidth: w * 0.34,
      topY: h * 0.09,
      bottomY: h * 0.90,
      lean: lean,
    );
    canvas.drawPath(
      outerPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [outerTop, outerBottom],
        ).createShader(Rect.fromLTWH(0, h * 0.09, w, h * 0.81)),
    );

    // Llama interior (brillo).
    final innerPath = _flamePath(
      cx: cx + lean * 0.4,
      halfWidth: w * 0.20,
      topY: h * 0.40,
      bottomY: h * 0.86,
      lean: -lean * 0.6,
    );
    canvas.drawPath(
      innerPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [innerTop, innerBottom],
        ).createShader(Rect.fromLTWH(0, h * 0.40, w, h * 0.46)),
    );

    // Brazos que saludan.
    final armWave = math.sin(t * 2 * math.pi + 0.4) * h * 0.035;
    final armPaint = Paint()
      ..color = outerBottom
      ..strokeWidth = w * 0.055
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final leftHand = Offset(cx - w * 0.43, h * 0.58 - armWave);
    final rightHand = Offset(cx + w * 0.43, h * 0.58 + armWave);
    canvas.drawLine(Offset(cx - w * 0.25, h * 0.64), leftHand, armPaint);
    canvas.drawLine(Offset(cx + w * 0.25, h * 0.64), rightHand, armPaint);
    final handPaint = Paint()..color = outerTop;
    canvas.drawCircle(leftHand, w * 0.04, handPaint);
    canvas.drawCircle(rightHand, w * 0.04, handPaint);

    // Cara.
    final blinkPhase = (t * 3) % 1.0;
    final eyeOpen = blinkPhase > 0.94 ? 0.12 : 1.0;
    final eyeY = h * 0.55;
    final eyeDx = w * 0.105;
    final eyeW = w * 0.10;
    final eyeH = math.max(h * 0.012, h * 0.095 * eyeOpen);
    final eyePaint = Paint()..color = Colors.white;

    for (final sign in [-1, 1]) {
      final eyeCenter = Offset(cx + sign * eyeDx, eyeY);
      canvas.drawOval(
        Rect.fromCenter(center: eyeCenter, width: eyeW, height: eyeH),
        eyePaint,
      );
      if (eyeOpen > 0.5) {
        final pupilDx = math.sin(t * 2 * math.pi) * w * 0.012;
        final pupilDy = math.cos(t * 2 * math.pi) * h * 0.006;
        canvas.drawCircle(
          eyeCenter + Offset(pupilDx, pupilDy),
          w * 0.033,
          Paint()..color = const Color(0xFF2B1620),
        );
        canvas.drawCircle(
          eyeCenter + Offset(pupilDx + w * 0.012, pupilDy - h * 0.01),
          w * 0.011,
          Paint()..color = Colors.white,
        );
      }
    }

    // Mejillas.
    final cheekPaint = Paint()
      ..color = const Color(0xFFFF7A9A).withValues(alpha: 0.55);
    canvas.drawCircle(
      Offset(cx - w * 0.18, h * 0.64),
      w * 0.028,
      cheekPaint,
    );
    canvas.drawCircle(
      Offset(cx + w * 0.18, h * 0.64),
      w * 0.028,
      cheekPaint,
    );

    // Sonrisa.
    final smile = Path()
      ..moveTo(cx - w * 0.065, h * 0.655)
      ..quadraticBezierTo(cx, h * 0.72, cx + w * 0.065, h * 0.655);
    canvas.drawPath(
      smile,
      Paint()
        ..color = const Color(0xFF2B1620)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.018
        ..strokeCap = StrokeCap.round,
    );

    // Chispas que suben cuando la racha está activa.
    if (streak > 0) {
      final sparkColors = [outerTop, innerTop, Colors.white];
      for (var i = 0; i < 5; i++) {
        final phase = (t + i * 0.19) % 1.0;
        final ex =
            cx + math.sin(t * 2 * math.pi + i * 1.7) * w * 0.38;
        final ey = h * 0.80 - phase * h * 0.58;
        final alpha = (1 - phase) * 0.7;
        final radius = w * 0.013 * (1 - phase) + 0.8;
        canvas.drawCircle(
          Offset(ex, ey),
          radius,
          Paint()
            ..color = sparkColors[i % sparkColors.length].withValues(
              alpha: alpha,
            ),
        );
      }
    }

    // Estrellitas para rachas largas.
    if (streak >= 7) {
      final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.9);
      for (final offset in [
        Offset(cx - w * 0.34, h * 0.20),
        Offset(cx + w * 0.31, h * 0.27),
        Offset(cx + w * 0.20, h * 0.12),
      ]) {
        _drawSparkle(canvas, offset, w * 0.028, starPaint);
      }
    }

    canvas.restore();
  }

  Path _flamePath({
    required double cx,
    required double halfWidth,
    required double topY,
    required double bottomY,
    required double lean,
  }) {
    final height = bottomY - topY;
    return Path()
      ..moveTo(cx + lean * 0.3, topY)
      ..cubicTo(
        cx - halfWidth * 0.20 + lean,
        topY + height * 0.18,
        cx - halfWidth * 0.98,
        topY + height * 0.56,
        cx - halfWidth * 0.86,
        topY + height * 0.82,
      )
      ..cubicTo(
        cx - halfWidth * 0.76,
        bottomY,
        cx - halfWidth * 0.32,
        bottomY,
        cx,
        bottomY,
      )
      ..cubicTo(
        cx + halfWidth * 0.32,
        bottomY,
        cx + halfWidth * 0.76,
        bottomY,
        cx + halfWidth * 0.86,
        topY + height * 0.82,
      )
      ..cubicTo(
        cx + halfWidth * 0.98,
        topY + height * 0.56,
        cx + halfWidth * 0.20 + lean,
        topY + height * 0.18,
        cx + lean * 0.3,
        topY,
      )
      ..close();
  }

  void _drawSparkle(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..quadraticBezierTo(
        center.dx + radius * 0.18,
        center.dy - radius * 0.18,
        center.dx + radius,
        center.dy,
      )
      ..quadraticBezierTo(
        center.dx + radius * 0.18,
        center.dy + radius * 0.18,
        center.dx,
        center.dy + radius,
      )
      ..quadraticBezierTo(
        center.dx - radius * 0.18,
        center.dy + radius * 0.18,
        center.dx - radius,
        center.dy,
      )
      ..quadraticBezierTo(
        center.dx - radius * 0.18,
        center.dy - radius * 0.18,
        center.dx,
        center.dy - radius,
      )
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _StreakMascotPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.streak != streak;
  }
}

/// Tarjeta reutilizable para mostrar la mascota y la racha actual.
class StreakMascotCard extends StatelessWidget {
  final int streak;
  final VoidCallback? onTap;

  const StreakMascotCard({super.key, required this.streak, this.onTap});

  static const List<int> _milestones = [3, 7, 14, 30, 60, 100, 180, 365];

  int get _nextGoal {
    for (final goal in _milestones) {
      if (goal > streak) return goal;
    }
    return streak + 100;
  }

  int get _previousGoal {
    var previous = 0;
    for (final goal in _milestones) {
      if (goal > streak) break;
      previous = goal;
    }
    return previous;
  }

  double get _progress {
    final next = _nextGoal;
    final previous = _previousGoal;
    final span = next - previous;
    if (span <= 0) return 1;
    return ((streak - previous) / span).clamp(0.0, 1.0);
  }

  String get _message {
    if (streak <= 0) {
      return 'Enciende tu llama con tu primera pausa de hoy.';
    }
    if (streak == 1) return '¡Primer día! Tu llama ya está encendida.';
    if (streak < 3) return '¡Bien! Alimenta la llama otro día más.';
    if (streak < 7) return '¡Estás en racha! No dejes que se apague.';
    if (streak < 14) return '¡Una semana imparable! La llama te sigue.';
    if (streak < 30) return '¡Constancia de fuego! Sigue así.';
    return '¡Eres leyenda! Tu llama no se apaga.';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final warm = Color.lerp(
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      (streak / 14).clamp(0.0, 1.0),
    )!;
    final next = _nextGoal;
    final remaining = next - streak;

    return AppSurface(
      padding: const EdgeInsets.all(18),
      onTap: onTap,
      gradient: LinearGradient(
        colors: isDark
            ? const [Color(0xFF2A1B13), Color(0xFF111D2C)]
            : const [Color(0xFFFFF4E4), Color(0xFFFFFDFC)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderGradient: LinearGradient(
        colors: [
          warm.withValues(alpha: 0.55),
          AppPalette.teal.withValues(alpha: 0.28),
        ],
      ),
      child: Row(
        children: [
          StreakMascot(streak: streak, size: 104),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      color: warm,
                      size: 18,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'TU RACHA',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.6,
                          color: isDark
                              ? AppPalette.darkMuted
                              : AppPalette.muted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '$streak ${streak == 1 ? 'día' : 'días'}',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    color: isDark ? Colors.white : AppPalette.text,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _message,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: isDark ? AppPalette.darkMuted : AppPalette.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 7,
                    backgroundColor: warm.withValues(alpha: 0.16),
                    color: warm,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  remaining == 1
                      ? '¡Solo 1 día para tu próxima meta!'
                      : 'Te faltan $remaining días para tu próxima meta',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppPalette.darkMuted : AppPalette.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
