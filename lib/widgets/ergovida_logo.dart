import 'package:flutter/material.dart';

class ErgoVidaLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool compact;

  const ErgoVidaLogo({
    super.key,
    this.size = 120,
    this.showText = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.headlineLarge?.copyWith(
          color: const Color(0xFF0B1F33),
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ) ??
        const TextStyle(
          color: Color(0xFF0B1F33),
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(size * 0.12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [
                Color(0xFF0A8EC9),
                Color(0xFF1789C4),
                Color(0xFF27C3A8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: const [
              BoxShadow(
                blurRadius: 18,
                offset: Offset(0, 12),
                color: Color(0x1F0B1F33),
              ),
            ],
          ),
          child: CustomPaint(
            painter: _ErgoVidaBrandPainter(),
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 8),
          Text(
            compact ? 'ERGOVIDA' : 'ERGOVIDA',
            style: textStyle.copyWith(
              fontSize: compact ? size * 0.26 : size * 0.38,
            ),
          ),
        ],
      ],
    );
  }
}

class _ErgoVidaBrandPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.10
      ..color = Colors.white.withOpacity(0.95);

    final innerPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF0B1F33);

    final accentPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF7BE2D0);

    final softPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withOpacity(0.9);

    canvas.drawArc(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.92,
        height: size.height * 0.92,
      ),
      1.2,
      1.8,
      false,
      ringPaint,
    );

    final headRect = Rect.fromCenter(
      center: Offset(center.dx, size.height * 0.29),
      width: size.width * 0.22,
      height: size.width * 0.22,
    );
    canvas.drawOval(headRect, softPaint);

    final neck = Path()
      ..moveTo(center.dx - size.width * 0.04, size.height * 0.38)
      ..lineTo(center.dx + size.width * 0.04, size.height * 0.38)
      ..lineTo(center.dx + size.width * 0.06, size.height * 0.56)
      ..lineTo(center.dx - size.width * 0.06, size.height * 0.56)
      ..close();
    canvas.drawPath(neck, softPaint);

    final torso = Path()
      ..moveTo(center.dx - size.width * 0.18, size.height * 0.52)
      ..quadraticBezierTo(
        center.dx,
        size.height * 0.82,
        center.dx + size.width * 0.18,
        size.height * 0.52,
      )
      ..lineTo(center.dx + size.width * 0.12, size.height * 0.52)
      ..quadraticBezierTo(
        center.dx,
        size.height * 0.72,
        center.dx - size.width * 0.12,
        size.height * 0.52,
      )
      ..close();
    canvas.drawPath(torso, accentPaint);

    final leftArm = Path()
      ..moveTo(center.dx - size.width * 0.12, size.height * 0.50)
      ..quadraticBezierTo(
        center.dx - size.width * 0.28,
        size.height * 0.62,
        center.dx - size.width * 0.20,
        size.height * 0.76,
      )
      ..lineTo(center.dx - size.width * 0.08, size.height * 0.75)
      ..quadraticBezierTo(
        center.dx - size.width * 0.18,
        size.height * 0.60,
        center.dx - size.width * 0.08,
        size.height * 0.48,
      )
      ..close();
    canvas.drawPath(leftArm, softPaint);

    final rightArm = Path()
      ..moveTo(center.dx + size.width * 0.12, size.height * 0.50)
      ..quadraticBezierTo(
        center.dx + size.width * 0.28,
        size.height * 0.62,
        center.dx + size.width * 0.20,
        size.height * 0.76,
      )
      ..lineTo(center.dx + size.width * 0.08, size.height * 0.75)
      ..quadraticBezierTo(
        center.dx + size.width * 0.18,
        size.height * 0.60,
        center.dx + size.width * 0.08,
        size.height * 0.48,
      )
      ..close();
    canvas.drawPath(rightArm, softPaint);

    final legs = Path()
      ..moveTo(center.dx - size.width * 0.12, size.height * 0.72)
      ..lineTo(center.dx - size.width * 0.06, size.height * 0.92)
      ..lineTo(center.dx + size.width * 0.02, size.height * 0.92)
      ..lineTo(center.dx + size.width * 0.06, size.height * 0.72)
      ..close();
    canvas.drawPath(legs, innerPaint);

    final leftLeg = Path()
      ..moveTo(center.dx + size.width * 0.02, size.height * 0.92)
      ..lineTo(center.dx + size.width * 0.16, size.height * 0.92)
      ..lineTo(center.dx + size.width * 0.12, size.height * 0.76)
      ..lineTo(center.dx - size.width * 0.02, size.height * 0.76)
      ..close();
    canvas.drawPath(leftLeg, accentPaint);

    final rightLeg = Path()
      ..moveTo(center.dx - size.width * 0.02, size.height * 0.92)
      ..lineTo(center.dx - size.width * 0.16, size.height * 0.92)
      ..lineTo(center.dx - size.width * 0.12, size.height * 0.76)
      ..lineTo(center.dx + size.width * 0.02, size.height * 0.76)
      ..close();
    canvas.drawPath(rightLeg, accentPaint);

    final sparkles = Paint()..color = Colors.white.withOpacity(0.9);
    for (int i = 0; i < 7; i++) {
      final dx = center.dx + size.width * (0.18 + i * 0.05);
      final dy = center.dy + size.height * (0.20 - i * 0.03);
      canvas.drawCircle(Offset(dx, dy), size.width * 0.018, sparkles);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
