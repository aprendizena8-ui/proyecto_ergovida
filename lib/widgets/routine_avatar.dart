import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

enum RoutineAvatarKind {
  march,
  squat,
  bridge,
  wallPush,
  seatedStretch,
  catCow,
  calfRaise,
  sideBend,
  torsoRotation,
  armCircles,
  legSwing,
  backExtension,
  neckStretch,
  breathing,
  childPose,
  forwardFold,
  supineTwist,
  calfStretch,
  officePosture,
  visualRest,
  general,
}

extension RoutineAvatarKindLabel on RoutineAvatarKind {
  String get label {
    switch (this) {
      case RoutineAvatarKind.march:
        return 'Marcha en el sitio';
      case RoutineAvatarKind.squat:
        return 'Sentadilla con silla';
      case RoutineAvatarKind.bridge:
        return 'Puente de glúteos';
      case RoutineAvatarKind.wallPush:
        return 'Flexión en pared';
      case RoutineAvatarKind.seatedStretch:
        return 'Estiramiento sentado';
      case RoutineAvatarKind.catCow:
        return 'Gato-vaca';
      case RoutineAvatarKind.calfRaise:
        return 'Elevación de talones';
      case RoutineAvatarKind.sideBend:
        return 'Inclinación lateral';
      case RoutineAvatarKind.torsoRotation:
        return 'Rotación de tronco';
      case RoutineAvatarKind.armCircles:
        return 'Círculos de brazos';
      case RoutineAvatarKind.legSwing:
        return 'Balanceo de piernas';
      case RoutineAvatarKind.backExtension:
        return 'Extensión de espalda';
      case RoutineAvatarKind.neckStretch:
        return 'Estiramiento de cuello';
      case RoutineAvatarKind.breathing:
        return 'Respiración guiada';
      case RoutineAvatarKind.childPose:
        return 'Postura del niño';
      case RoutineAvatarKind.forwardFold:
        return 'Flexión sentado';
      case RoutineAvatarKind.supineTwist:
        return 'Torsión suave';
      case RoutineAvatarKind.calfStretch:
        return 'Pantorrillas en pared';
      case RoutineAvatarKind.officePosture:
        return 'Postura de oficina';
      case RoutineAvatarKind.visualRest:
        return 'Descanso visual';
      case RoutineAvatarKind.general:
        return 'Movimiento guiado';
    }
  }
}

class RoutineAvatar extends StatefulWidget {
  final RoutineAvatarKind kind;
  final Color color;
  final Color? lineColor;
  final double opacity;
  final bool showFloor;

  const RoutineAvatar({
    super.key,
    required this.kind,
    this.color = AppPalette.blue,
    this.lineColor,
    this.opacity = 1,
    this.showFloor = true,
  });

  @override
  State<RoutineAvatar> createState() => _RoutineAvatarState();
}

class _RoutineAvatarState extends State<RoutineAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  Duration get _duration {
    switch (widget.kind) {
      case RoutineAvatarKind.march:
      case RoutineAvatarKind.squat:
      case RoutineAvatarKind.calfRaise:
      case RoutineAvatarKind.legSwing:
      case RoutineAvatarKind.armCircles:
      case RoutineAvatarKind.backExtension:
      case RoutineAvatarKind.officePosture:
        return const Duration(milliseconds: 4200);
      case RoutineAvatarKind.bridge:
      case RoutineAvatarKind.wallPush:
      case RoutineAvatarKind.sideBend:
      case RoutineAvatarKind.torsoRotation:
      case RoutineAvatarKind.seatedStretch:
        return const Duration(milliseconds: 5400);
      default:
        return const Duration(milliseconds: 7200);
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration)
      ..repeat();
  }

  @override
  void didUpdateWidget(covariant RoutineAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kind != widget.kind) {
      _controller.duration = _duration;
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(
            constraints.maxWidth.isFinite ? constraints.maxWidth : 120,
            constraints.maxHeight.isFinite ? constraints.maxHeight : 160,
          );
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Opacity(
                opacity: widget.opacity,
                child: CustomPaint(
                  size: size,
                  painter: _RoutineAvatarPainter(
                    kind: widget.kind,
                    t: _controller.value,
                    color: widget.color,
                    lineColor: widget.lineColor ?? widget.color,
                    showFloor: widget.showFloor,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _RoutineAvatarPainter extends CustomPainter {
  static const double _upperArm = 20;
  static const double _foreArm = 18;
  static const double _thigh = 26;
  static const double _shin = 24;
  static const double _torso = 36;

  final RoutineAvatarKind kind;
  final double t;
  final Color color;
  final Color lineColor;
  final bool showFloor;

  late final double s;
  late final double cx;
  late final double gy;

  _RoutineAvatarPainter({
    required this.kind,
    required this.t,
    required this.color,
    required this.lineColor,
    required this.showFloor,
  });

  Offset pt(Offset p) => Offset(cx + p.dx * s, gy + p.dy * s);

  double sc(double value) => value * s;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    s = math.min(size.width / 116, size.height / 136);
    if (s <= 0) return;
    cx = size.width / 2;
    gy = size.height - 8 * s;

    final rig = _buildRig(_buildPose(kind, t));
    final phase = t * 2 * math.pi;
    final breathe = (math.sin(phase) + 1) / 2;

    _drawBackdrop(canvas, breathe);
    if (showFloor) _drawFloor(canvas);
    if (rig.wall) _drawWall(canvas);
    if (rig.chair) _drawChair(canvas, rig.hip);
    _drawMotion(canvas, rig, phase);
    _drawFigure(canvas, rig, breathe);
    _drawSparkles(canvas, phase);
  }

  _Pose _buildPose(RoutineAvatarKind kind, double t) {
    final phase = t * 2 * math.pi;
    final wave = math.sin(phase);
    final pulse = (math.sin(phase - math.pi / 2) + 1) / 2;
    final breathe = (math.sin(phase) + 1) / 2;
    final p = _Pose();

    switch (kind) {
      case RoutineAvatarKind.march:
        p.hipY = -56 + 1.5 * pulse;
        p.lean = 3 + 2 * wave;
        p.headLean = -1.5 * wave;
        p.legU = 10 + 38 * pulse;
        p.legL = 14 - 26 * pulse;
        p.legUb = 10 - 12 * pulse;
        p.legLb = 10 + 6 * pulse;
        p.armU = 12 - 30 * pulse;
        p.armL = 14 + 18 * pulse;
        p.armUb = 12 + 26 * pulse;
        p.armLb = 14 - 12 * pulse;
        p.frontGrounded = pulse < 0.35;
        p.backGrounded = pulse > 0.65;
        break;

      case RoutineAvatarKind.squat:
        final q = pulse;
        p.hipX = -8 * q;
        p.hipY = -56 + 24 * q;
        p.lean = 8 + 18 * q;
        p.headLean = -6 * q;
        p.chair = true;
        p.legU = 20 + 45 * q;
        p.legL = 5 + 35 * q;
        p.legUb = p.legU - 4;
        p.legLb = p.legL + 4;
        p.armU = 25 + 40 * q;
        p.armL = 35 + 35 * q;
        p.armUb = p.armU - 4;
        p.armLb = p.armL - 4;
        break;

      case RoutineAvatarKind.bridge:
        final q = pulse;
        p.hipX = 6;
        p.hipY = -16 - 7 * q;
        p.lean = -88;
        p.headLean = 6;
        p.depth = const Offset(0, 3);
        p.legU = 78;
        p.legL = 68;
        p.legUb = 72;
        p.legLb = 68;
        p.armU = -28;
        p.armL = -72;
        p.armUb = -24;
        p.armLb = -68;
        break;

      case RoutineAvatarKind.wallPush:
        final q = pulse;
        p.wall = true;
        p.hipX = -8;
        p.hipY = -56;
        p.lean = 16 + 6 * q;
        p.headLean = -4 * q;
        p.armU = 76;
        p.armL = 76 + 8 * q;
        p.armUb = 74;
        p.armLb = 74 + 8 * q;
        break;

      case RoutineAvatarKind.seatedStretch:
        final q = pulse;
        p.chair = true;
        p.hipX = -4;
        p.hipY = -42 + 2 * q;
        p.lean = 6 + 16 * q;
        p.headLean = 6 * q;
        p.legU = 42;
        p.legL = 10;
        p.legUb = -42;
        p.legLb = -10;
        p.armU = 40 + 22 * q;
        p.armL = 62 + 18 * q;
        p.armUb = p.armU - 4;
        p.armLb = p.armL - 4;
        break;

      case RoutineAvatarKind.catCow:
        final c = wave;
        p.hipX = 12;
        p.hipY = -40;
        p.lean = -90;
        p.headLean = -10 * c;
        p.spine = 7 * c;
        p.depth = const Offset(0, 3);
        p.legU = 22;
        p.legL = 58;
        p.legUb = 18;
        p.legLb = 62;
        p.armU = 8;
        p.armL = 10;
        p.armUb = 6;
        p.armLb = 12;
        break;

      case RoutineAvatarKind.calfRaise:
        final q = pulse;
        p.hipY = -56 + 3 * q;
        p.heelLift = q;
        p.lean = 2;
        p.armU = 10 + 5 * q;
        p.armL = 12 + 5 * q;
        p.armUb = -8 - 5 * q;
        p.armLb = -12 - 5 * q;
        break;

      case RoutineAvatarKind.sideBend:
        final b = wave;
        p.lean = 16 * b;
        p.headLean = -8 * b;
        p.armU = 118 + 16 * b;
        p.armL = 145 + 10 * b;
        p.armUb = -14;
        p.armLb = -10;
        break;

      case RoutineAvatarKind.torsoRotation:
        final r = wave;
        p.lean = 3 * r;
        p.headLean = 4 * r;
        p.shoulderShift = 4 * r;
        p.faceTurn = 3 * r;
        p.armU = 72 + 18 * r;
        p.armL = 82 + 14 * r;
        p.armUb = 72 - 18 * r;
        p.armLb = 82 - 14 * r;
        break;

      case RoutineAvatarKind.armCircles:
        p.armU = 90 + 70 * wave;
        p.armL = p.armU + 22;
        p.armUb = 90 - 70 * wave;
        p.armLb = p.armUb + 22;
        p.lean = 2;
        break;

      case RoutineAvatarKind.legSwing:
        final sw = wave;
        p.legU = 8 + 34 * sw;
        p.legL = 10 + 16 * sw;
        p.armU = 12 - 14 * sw;
        p.armL = 14 - 8 * sw;
        p.armUb = 12 + 14 * sw;
        p.armLb = 14 + 8 * sw;
        p.frontGrounded = sw < 0.2;
        break;

      case RoutineAvatarKind.backExtension:
        final b = pulse;
        p.lean = -8 - 14 * b;
        p.headLean = 8 * b;
        p.armU = -22 - 10 * b;
        p.armL = -30 - 10 * b;
        p.armUb = p.armU + 4;
        p.armLb = p.armL + 4;
        break;

      case RoutineAvatarKind.neckStretch:
        final n = wave;
        p.chair = true;
        p.hipY = -42;
        p.lean = 3;
        p.headLean = 16 * n;
        p.faceTurn = 2 * n;
        p.legU = 42;
        p.legL = 10;
        p.legUb = -42;
        p.legLb = -10;
        p.armU = 120 + 6 * n;
        p.armL = 145;
        p.armUb = -20;
        p.armLb = -16;
        break;

      case RoutineAvatarKind.breathing:
        p.chair = true;
        p.hipY = -42;
        p.lean = 4 + 2 * breathe;
        p.headLean = -2;
        p.belly = breathe;
        p.legU = 42;
        p.legL = 10;
        p.legUb = -42;
        p.legLb = -10;
        p.armU = -55;
        p.armL = -35;
        p.armUb = 55;
        p.armLb = 35;
        break;

      case RoutineAvatarKind.childPose:
        p.hipY = -30;
        p.lean = 102;
        p.headLean = 8;
        p.spine = 4;
        p.depth = const Offset(0, 3);
        p.legU = 22;
        p.legL = -78;
        p.legUb = -22;
        p.legLb = 78;
        p.armU = 92;
        p.armL = 165;
        p.armUb = 88;
        p.armLb = 160;
        p.frontGrounded = false;
        p.backGrounded = false;
        break;

      case RoutineAvatarKind.forwardFold:
        final q = pulse;
        p.chair = true;
        p.hipY = -42;
        p.lean = 8 + 40 * q;
        p.headLean = 10 * q;
        p.legU = 42;
        p.legL = 10;
        p.legUb = -42;
        p.legLb = -10;
        p.armU = 20 + 30 * q;
        p.armL = 30 + 35 * q;
        p.armUb = p.armU - 4;
        p.armLb = p.armL - 4;
        break;

      case RoutineAvatarKind.supineTwist:
        p.hipX = 14;
        p.hipY = -18;
        p.lean = -80;
        p.headLean = -6;
        p.depth = const Offset(0, 3);
        p.legU = 120 + 10 * wave;
        p.legL = 40;
        p.legUb = 110 + 10 * wave;
        p.legLb = 30;
        p.armU = -95;
        p.armL = -20;
        p.armUb = 95;
        p.armLb = 20;
        p.frontGrounded = false;
        p.backGrounded = false;
        break;

      case RoutineAvatarKind.calfStretch:
        final q = pulse;
        p.wall = true;
        p.hipX = -6;
        p.hipY = -50;
        p.lean = 10 + 4 * q;
        p.headLean = -3 * q;
        p.armU = 76;
        p.armL = 80;
        p.armUb = 74;
        p.armLb = 78;
        p.legU = 75;
        p.legL = 95;
        p.legUb = -18;
        p.legLb = -6;
        p.frontGrounded = false;
        break;

      case RoutineAvatarKind.officePosture:
        final b = wave;
        p.chair = true;
        p.hipY = -42;
        p.lean = 4 + 1.5 * b;
        p.headLean = -3 * b;
        p.legU = 42;
        p.legL = 10;
        p.legUb = -42;
        p.legLb = -10;
        p.armU = 58;
        p.armL = 88 + 5 * b;
        p.armUb = 58;
        p.armLb = 88 - 5 * b;
        break;

      case RoutineAvatarKind.visualRest:
        final n = wave;
        p.chair = true;
        p.hipY = -42;
        p.lean = 2;
        p.headLean = -4 * n;
        p.legU = 42;
        p.legL = 10;
        p.legUb = -42;
        p.legLb = -10;
        p.armU = 50;
        p.armL = 100;
        p.armUb = 50;
        p.armLb = 100;
        break;

      case RoutineAvatarKind.general:
        p.lean = 2 * wave;
        p.headLean = 2 * wave;
        p.armU = 10 + 5 * wave;
        p.armL = 12 + 4 * wave;
        p.armUb = -8 - 5 * wave;
        p.armLb = -12 - 4 * wave;
        break;
    }

    return p;
  }

  _Rig _buildRig(_Pose p) {
    final hip = Offset(p.hipX, p.hipY);
    final shoulder =
        hip + _up(p.lean) * _torso + Offset(p.shoulderShift, 0);
    final headAngle = (p.lean + p.headLean) * math.pi / 180;
    final head = shoulder + _up(p.lean + p.headLean) * 15;
    final neck = shoulder + _up(p.lean + p.headLean * 0.4) * 5;

    final backShoulder = shoulder + p.depth;
    final backHip = hip + p.depth;

    return _Rig(
      hip: hip,
      shoulder: shoulder,
      hipBack: backHip,
      shoulderBack: backShoulder,
      neck: neck,
      head: head,
      elbow: shoulder + _down(p.armU) * _upperArm,
      wrist: shoulder + _down(p.armU) * _upperArm + _down(p.armL) * _foreArm,
      elbowBack: backShoulder + _down(p.armUb) * _upperArm,
      wristBack: backShoulder +
          _down(p.armUb) * _upperArm +
          _down(p.armLb) * _foreArm,
      knee: hip + _down(p.legU) * _thigh,
      ankle: hip + _down(p.legU) * _thigh + _down(p.legL) * _shin,
      kneeBack: backHip + _down(p.legUb) * _thigh,
      ankleBack: backHip + _down(p.legUb) * _thigh + _down(p.legLb) * _shin,
      lean: p.lean,
      headAngle: headAngle,
      spine: p.spine,
      heelLift: p.heelLift,
      belly: p.belly,
      faceTurn: p.faceTurn,
      chair: p.chair,
      wall: p.wall,
      frontGrounded: p.frontGrounded,
      backGrounded: p.backGrounded,
    );
  }

  void _drawBackdrop(Canvas canvas, double breathe) {
    final center = pt(Offset.zero - Offset(0, 70));
    canvas.drawCircle(
      center,
      sc(64),
      Paint()
        ..shader = ui.Gradient.radial(center, sc(64), [
          color.withValues(alpha: 0.24),
          color.withValues(alpha: 0.08),
          color.withValues(alpha: 0),
        ], [0, 0.55, 1]),
    );
    canvas.drawCircle(
      center,
      sc(52 + breathe * 2.5),
      Paint()
        ..color = lineColor.withValues(alpha: 0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sc(1.2),
    );
    canvas.drawCircle(
      center,
      sc(38 - breathe * 1.5),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sc(0.8),
    );
  }

  void _drawFloor(Canvas canvas) {
    canvas.drawOval(
      Rect.fromCenter(
        center: pt(Offset(0, 1)),
        width: sc(74),
        height: sc(10),
      ),
      Paint()
        ..color = AppPalette.navyDeep.withValues(alpha: 0.22)
        ..maskFilter = ui.MaskFilter.blur(BlurStyle.normal, sc(4)),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: pt(Offset(0, 1)),
        width: sc(42),
        height: sc(5),
      ),
      Paint()..color = AppPalette.navyDeep.withValues(alpha: 0.16),
    );
    final left = pt(Offset(-56, 0));
    final right = pt(Offset(56, 0));
    canvas.drawLine(
      left,
      right,
      Paint()
        ..shader = ui.Gradient.linear(left, right, [
          lineColor.withValues(alpha: 0),
          lineColor.withValues(alpha: 0.32),
          lineColor.withValues(alpha: 0),
        ], [0, 0.5, 1])
        ..strokeWidth = sc(1.6)
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawWall(Canvas canvas) {
    final top = pt(Offset(44, -98));
    final bottom = pt(Offset(44, 0));
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(top.dx - sc(3), top.dy, sc(7), bottom.dy - top.dy),
      Radius.circular(sc(3)),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(top.dx - sc(3), top.dy),
          Offset(top.dx + sc(4), bottom.dy),
          [
            lineColor.withValues(alpha: 0.20),
            lineColor.withValues(alpha: 0.04),
          ],
        ),
    );
    canvas.drawLine(
      top,
      bottom,
      Paint()
        ..color = lineColor.withValues(alpha: 0.30)
        ..strokeWidth = sc(1.4)
        ..strokeCap = StrokeCap.round,
    );
    for (final y in [-74.0, -50.0, -26.0]) {
      final mark = pt(Offset(44, y));
      canvas.drawLine(
        mark - Offset(sc(4), 0),
        mark + Offset(sc(1), 0),
        Paint()
          ..color = lineColor.withValues(alpha: 0.18)
          ..strokeWidth = sc(1.2),
      );
    }
  }

  void _drawChair(Canvas canvas, Offset hipDesign) {
    final seatY = hipDesign.dy + 5;
    final leftX = hipDesign.dx - 17;
    final rightX = hipDesign.dx + 17;
    final seat = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        pt(Offset(leftX, seatY)).dx,
        pt(Offset(0, seatY)).dy,
        sc(34),
        sc(5),
      ),
      Radius.circular(sc(2.5)),
    );
    canvas.drawRRect(
      seat,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(seat.left, seat.top),
          Offset(seat.right, seat.bottom),
          [
            lineColor.withValues(alpha: 0.24),
            color.withValues(alpha: 0.16),
          ],
        ),
    );
    canvas.drawRRect(
      seat,
      Paint()
        ..color = lineColor.withValues(alpha: 0.26)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sc(1),
    );

    final legPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.28)
      ..strokeWidth = sc(2.2)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      pt(Offset(leftX + 2, seatY + 3)),
      pt(Offset(leftX + 2, 0)),
      legPaint,
    );
    canvas.drawLine(
      pt(Offset(rightX - 2, seatY + 3)),
      pt(Offset(rightX - 2, 0)),
      legPaint,
    );
    canvas.drawLine(
      pt(Offset(leftX, seatY)),
      pt(Offset(leftX, seatY - 30)),
      legPaint,
    );
  }

  void _drawMotion(Canvas canvas, _Rig rig, double phase) {
    final motionPaint = Paint()
      ..color = color.withValues(alpha: 0.26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = sc(1.7)
      ..strokeCap = StrokeCap.round;

    void arc(Offset centerDesign, double radius, double start, double alpha) {
      canvas.drawArc(
        Rect.fromCircle(center: pt(centerDesign), radius: sc(radius)),
        phase * 0.6 + start,
        1.35,
        false,
        Paint()
          ..color = color.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = sc(1.6)
          ..strokeCap = StrokeCap.round,
      );
    }

    void arrowArc(
      Offset centerDesign,
      double radius,
      double start,
      double sweep,
      double alpha,
    ) {
      final center = pt(centerDesign);
      final begin = start + phase * 0.35;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: sc(radius)),
        begin,
        sweep,
        false,
        Paint()
          ..color = color.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = sc(1.9)
          ..strokeCap = StrokeCap.round,
      );
      final endAngle = begin + sweep;
      final end =
          center + Offset(math.cos(endAngle), math.sin(endAngle)) * sc(radius);
      final tangent = endAngle + math.pi / 2;
      for (final side in const [-0.55, 0.55]) {
        canvas.drawLine(
          end -
              Offset(
                math.cos(tangent + side),
                math.sin(tangent + side),
              ) *
                  sc(4.5),
          end,
          Paint()
            ..color = color.withValues(alpha: alpha)
            ..strokeWidth = sc(1.9)
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    void verticalArrow(Offset centerDesign, double alpha) {
      final center = pt(centerDesign);
      final top = center + Offset(0, -sc(11));
      final bottom = center + Offset(0, sc(11));
      canvas.drawLine(top, bottom, motionPaint..color = color.withValues(alpha: alpha));
      for (final end in [top, bottom]) {
        final direction = end == top ? 1.0 : -1.0;
        canvas.drawLine(
          end + Offset(-sc(4), sc(4) * direction),
          end,
          motionPaint..color = color.withValues(alpha: alpha),
        );
        canvas.drawLine(
          end + Offset(sc(4), sc(4) * direction),
          end,
          motionPaint..color = color.withValues(alpha: alpha),
        );
      }
    }

    switch (kind) {
      case RoutineAvatarKind.armCircles:
      case RoutineAvatarKind.torsoRotation:
        arrowArc(rig.shoulder + const Offset(0, -8), 23, 0.35, 2.1, 0.32);
        break;
      case RoutineAvatarKind.squat:
      case RoutineAvatarKind.bridge:
        verticalArrow(rig.hip + const Offset(17, 0), 0.28);
        break;
      case RoutineAvatarKind.calfRaise:
        verticalArrow(rig.ankle + const Offset(12, 0), 0.26);
        break;
      case RoutineAvatarKind.breathing:
        arrowArc(rig.hip + const Offset(0, -14), 19, 0.7, 1.9, 0.24);
        break;
      case RoutineAvatarKind.sideBend:
      case RoutineAvatarKind.neckStretch:
        arrowArc(rig.head + const Offset(0, -6), 17, 0.5, 1.7, 0.26);
        break;
      default:
        break;
    }

    arc(rig.wrist, 9, 0.2, 0.24);
    arc(rig.wristBack, 8, 2.6, 0.16);
    arc(rig.ankle, 10, 1.5, 0.20);
    arc(rig.ankleBack, 9, 3.4, 0.14);
  }

  void _drawFigure(Canvas canvas, _Rig rig, double breathe) {
    final outline = Color.lerp(lineColor, AppPalette.navyDeep, 0.42)!;
    final skin = const Color(0xFFF5C8A6);
    final skinShade = Color.lerp(skin, AppPalette.navyDeep, 0.22)!;
    final skinLight = Color.lerp(skin, Colors.white, 0.42)!;
    final top = color;
    final topLight = Color.lerp(color, Colors.white, 0.36)!;
    final topShade = Color.lerp(color, AppPalette.navyDeep, 0.28)!;
    final pants = Color.lerp(color, AppPalette.navyDeep, 0.56)!;
    final pantsShade = Color.lerp(pants, AppPalette.navyDeep, 0.24)!;
    final hair = Color.lerp(AppPalette.navyDeep, color, 0.20)!;
    final hairLight = Color.lerp(hair, Colors.white, 0.28)!;

    final hip = pt(rig.hip);
    final shoulder = pt(rig.shoulder);
    final neck = pt(rig.neck);
    final head = pt(rig.head);
    final elbow = pt(rig.elbow);
    final wrist = pt(rig.wrist);
    final elbowBack = pt(rig.elbowBack);
    final wristBack = pt(rig.wristBack);
    final knee = pt(rig.knee);
    final ankle = pt(rig.ankle);
    final kneeBack = pt(rig.kneeBack);
    final ankleBack = pt(rig.ankleBack);

    final hipBack = pt(rig.hipBack);
    final shoulderBack = pt(rig.shoulderBack);
    _drawLimb(
      canvas,
      [hipBack, kneeBack, ankleBack],
      pantsShade,
      outline,
      Colors.white,
      8.4,
      0.55,
    );
    _drawShoe(canvas, rig.ankleBack, rig.backGrounded, 0, true, outline);
    _drawLimb(
      canvas,
      [shoulderBack, elbowBack, wristBack],
      skinShade,
      outline,
      skinLight,
      5.6,
      0.55,
    );
    _drawLimb(
      canvas,
      [shoulderBack, Offset.lerp(shoulderBack, elbowBack, 0.38)!],
      topShade,
      outline,
      topLight,
      8.4,
      0.6,
    );
    _drawHand(canvas, wristBack, 3.0, skinShade, outline, 0.6);

    _drawTorso(canvas, rig, hip, shoulder, outline, topLight, top, topShade, pantsShade);

    _drawLimb(canvas, [hip, knee, ankle], pants, outline, pantsShade, 9.2, 1);
    _drawShoe(canvas, rig.ankle, rig.frontGrounded, rig.heelLift, false, outline);

    _drawLimb(canvas, [shoulder, elbow, wrist], skin, outline, skinLight, 6.2, 1);
    _drawLimb(
      canvas,
      [shoulder, Offset.lerp(shoulder, elbow, 0.38)!],
      top,
      outline,
      topLight,
      9.0,
      1,
    );
    _drawHand(canvas, wrist, 3.3, skin, outline, 1);

    _drawLimb(
      canvas,
      [shoulder + (neck - shoulder) * 0.15, neck + (head - neck) * 0.30],
      skin,
      outline,
      skinLight,
      5.6,
      1,
    );

    if (rig.belly > 0) {
      final u = _up(rig.lean);
      final perp = _perp(rig.lean);
      final center = pt(rig.hip + u * 18 + perp * 4);
      canvas.drawCircle(
        center,
        sc(3 + 2.2 * rig.belly),
        Paint()..color = color.withValues(alpha: 0.10 + 0.16 * rig.belly),
      );
      canvas.drawCircle(
        center,
        sc(3 + 2.2 * rig.belly),
        Paint()
          ..color = lineColor.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = sc(1.1),
      );
    }

    _drawHead(canvas, head, rig.headAngle, rig.faceTurn, {
      'outline': outline,
      'skin': skin,
      'skinShade': skinShade,
      'skinLight': skinLight,
      'hair': hair,
      'hairLight': hairLight,
      'accent': color,
      'breathe': Colors.white.withValues(alpha: 0.10 + 0.10 * breathe),
    });
  }

  void _drawTorso(
    Canvas canvas,
    _Rig rig,
    Offset hip,
    Offset shoulder,
    Color outline,
    Color topLight,
    Color top,
    Color topShade,
    Color pantsShade,
  ) {
    final perp = _perp(rig.lean);
    final u = _up(rig.lean);
    final hipLeft = hip - Offset(perp.dx * sc(7.4), perp.dy * sc(7.4));
    final hipRight = hip + Offset(perp.dx * sc(7.4), perp.dy * sc(7.4));
    final shoulderLeft = shoulder - Offset(perp.dx * sc(10.8), perp.dy * sc(10.8));
    final shoulderRight = shoulder + Offset(perp.dx * sc(10.8), perp.dy * sc(10.8));
    final curve = sc(rig.spine);

    final path = Path()
      ..moveTo(hipLeft.dx, hipLeft.dy)
      ..quadraticBezierTo(
        Offset.lerp(hipLeft, shoulderLeft, 0.5)!.dx + perp.dx * curve,
        Offset.lerp(hipLeft, shoulderLeft, 0.5)!.dy + perp.dy * curve,
        shoulderLeft.dx,
        shoulderLeft.dy,
      )
      ..quadraticBezierTo(
        shoulder.dx + u.dx * sc(2),
        shoulder.dy + u.dy * sc(2),
        shoulderRight.dx,
        shoulderRight.dy,
      )
      ..quadraticBezierTo(
        Offset.lerp(hipRight, shoulderRight, 0.5)!.dx + perp.dx * curve,
        Offset.lerp(hipRight, shoulderRight, 0.5)!.dy + perp.dy * curve,
        hipRight.dx,
        hipRight.dy,
      )
      ..quadraticBezierTo(
        hip.dx - u.dx * sc(1.5),
        hip.dy - u.dy * sc(1.5),
        hipLeft.dx,
        hipLeft.dy,
      )
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.linear(shoulderLeft, hipRight, [
          topLight,
          top,
          topShade,
        ], [0, 0.5, 1]),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = outline.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sc(1.2)
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.drawLine(
      hipLeft + Offset(perp.dx * sc(1), perp.dy * sc(1)),
      hipRight + Offset(perp.dx * sc(1), perp.dy * sc(1)),
      Paint()
        ..color = pantsShade
        ..strokeWidth = sc(4)
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(shoulderLeft, sc(4.4), Paint()..color = topLight.withValues(alpha: 0.55));
    canvas.drawCircle(shoulderRight, sc(4.4), Paint()..color = topLight.withValues(alpha: 0.55));
  }

  void _drawLimb(
    Canvas canvas,
    List<Offset> points,
    Color fill,
    Color outline,
    Color shine,
    double width,
    double alpha,
  ) {
    if (points.length < 2) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length - 1; i++) {
      final mid = Offset.lerp(points[i], points[i + 1], 0.5)!;
      path.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);

    canvas.drawPath(
      path,
      Paint()
        ..color = outline.withValues(alpha: 0.75 * alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sc(width + 2.2)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = fill.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sc(width)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final sheen = Paint()
      ..color = shine.withValues(alpha: 0.34 * alpha)
      ..strokeWidth = sc(width * 0.20)
      ..strokeCap = StrokeCap.round;
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1];
      final b = points[i];
      final delta = b - a;
      final length = delta.distance;
      if (length < 0.01) continue;
      final normal = Offset(-delta.dy / length, delta.dx / length);
      final shift = normal * sc(width * 0.20);
      canvas.drawLine(a + shift, b + shift, sheen);
    }

    for (var i = 1; i < points.length - 1; i++) {
      canvas.drawCircle(
        points[i],
        sc(width * 0.48),
        Paint()
          ..color = outline.withValues(alpha: 0.35 * alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = sc(0.8),
      );
    }
  }

  void _drawShoe(
    Canvas canvas,
    Offset ankleDesign,
    bool grounded,
    double heelLift,
    bool back,
    Color outline,
  ) {
    final ankle = pt(ankleDesign);
    final soleY = grounded ? gy : ankle.dy + sc(4);
    final rotation = -0.22 * heelLift;

    canvas.save();
    canvas.translate(ankle.dx, ankle.dy);
    canvas.rotate(rotation);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(-sc(3), soleY - ankle.dy - sc(6), sc(15), sc(6)),
      Radius.circular(sc(2.8)),
    );
    final fill = Color.lerp(
      AppPalette.navyDeep,
      color,
      back ? 0.16 : 0.28,
    )!;
    canvas.drawRRect(
      rect,
      Paint()
        ..color = fill.withValues(alpha: back ? 0.6 : 1)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..color = outline.withValues(alpha: back ? 0.45 : 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sc(0.9),
    );
    canvas.drawLine(
      Offset(sc(0.5), rect.bottom - sc(1.4)),
      Offset(rect.right - sc(1.2), rect.bottom - sc(1.4)),
      Paint()
        ..color = Colors.white.withValues(alpha: back ? 0.12 : 0.24)
        ..strokeWidth = sc(1)
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  void _drawHand(
    Canvas canvas,
    Offset wrist,
    double radius,
    Color skin,
    Color outline,
    double alpha,
  ) {
    canvas.drawCircle(
      wrist,
      sc(radius),
      Paint()..color = skin.withValues(alpha: alpha),
    );
    canvas.drawCircle(
      wrist,
      sc(radius),
      Paint()
        ..color = outline.withValues(alpha: 0.65 * alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sc(0.9),
    );
    canvas.drawCircle(
      wrist + Offset(-sc(0.7), -sc(0.8)),
      sc(0.8),
      Paint()..color = Colors.white.withValues(alpha: 0.28 * alpha),
    );
  }

  void _drawHead(
    Canvas canvas,
    Offset center,
    double angle,
    double faceTurn,
    Map<String, Color> palette,
  ) {
    final outline = palette['outline']!;
    final skin = palette['skin']!;
    final skinShade = palette['skinShade']!;
    final skinLight = palette['skinLight']!;
    final hair = palette['hair']!;
    final hairLight = palette['hairLight']!;
    final accent = palette['accent']!;
    final breathe = palette['breathe']!;
    final r = sc(9.4);
    final shift = sc(faceTurn * 0.22);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    canvas.drawCircle(
      Offset(0, -sc(0.6)),
      r * 1.04,
      Paint()..color = hair,
    );

    canvas.drawCircle(
      Offset(-r * 0.96, sc(1)),
      sc(1.7),
      Paint()..color = skinShade,
    );
    canvas.drawCircle(
      Offset(r * 0.96, sc(1)),
      sc(1.7),
      Paint()..color = skinShade,
    );

    canvas.drawCircle(
      Offset(shift, sc(0.4)),
      r * 0.92,
      Paint()..color = skin,
    );
    canvas.drawCircle(
      Offset(shift + sc(2.6), sc(1)),
      r * 0.82,
      Paint()..color = breathe,
    );

    final cap = Path()
      ..moveTo(-r * 1.02, -sc(0.8))
      ..cubicTo(-r * 1.08, -r * 1.34, r * 0.52, -r * 1.52, r * 0.96, -r * 0.42)
      ..quadraticBezierTo(r * 0.72, -r * 1.02, r * 0.16, -r * 0.94)
      ..quadraticBezierTo(-r * 0.44, -r * 0.82, -r * 1.02, -sc(0.8))
      ..close();
    canvas.drawPath(cap, Paint()..color = hair);
    canvas.drawPath(
      Path()
        ..moveTo(-r * 0.58, -r * 0.92)
        ..quadraticBezierTo(-r * 0.10, -r * 1.24, r * 0.54, -r * 0.78),
      Paint()
        ..color = hairLight.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sc(1)
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawArc(
      Rect.fromCircle(center: Offset(shift, sc(0.4)), radius: r * 0.90),
      math.pi * 1.08,
      math.pi * 0.84,
      false,
      Paint()
        ..color = accent.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sc(1.7)
        ..strokeCap = StrokeCap.round,
    );

    final eyePaint = Paint()..color = Color.lerp(outline, AppPalette.navyDeep, 0.25)!;
    for (final x in [-3.3, 3.3]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(shift + sc(x), -sc(0.5)),
          width: sc(1.5),
          height: sc(2.2),
        ),
        eyePaint,
      );
    }
    canvas.drawLine(
      Offset(shift - sc(4.5), -sc(3.4)),
      Offset(shift - sc(2.2), -sc(3.7)),
      Paint()
        ..color = hair.withValues(alpha: 0.75)
        ..strokeWidth = sc(0.9)
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(shift + sc(2.2), -sc(3.7)),
      Offset(shift + sc(4.5), -sc(3.4)),
      Paint()
        ..color = hair.withValues(alpha: 0.75)
        ..strokeWidth = sc(0.9)
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(shift, sc(2.1)),
        width: sc(5.6),
        height: sc(3.6),
      ),
      0.25,
      math.pi - 0.5,
      false,
      Paint()
        ..color = skinShade.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sc(0.9)
        ..strokeCap = StrokeCap.round,
    );

    for (final x in [-5.6, 5.6]) {
      canvas.drawCircle(
        Offset(shift + sc(x), sc(1.8)),
        sc(1.2),
        Paint()..color = accent.withValues(alpha: 0.14),
      );
    }
    canvas.drawCircle(
      Offset(shift - sc(2.4), -sc(4.4)),
      sc(0.9),
      Paint()..color = skinLight.withValues(alpha: 0.5),
    );

    canvas.restore();
  }

  void _drawSparkles(Canvas canvas, double phase) {
    final sparkle = Paint()
      ..color = Color.lerp(lineColor, Colors.white, 0.45)!
          .withValues(alpha: 0.22)
      ..strokeWidth = sc(1)
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 3; i++) {
      final angle = phase * 0.7 + i * 2.1;
      final radius = 46 + i * 9;
      final center = pt(Offset(
        math.cos(angle) * radius,
        -74 + math.sin(angle) * radius * 0.5,
      ));
      final pulse = (math.sin(phase * 1.3 + i) + 1) / 2;
      final size = sc(1.1 + pulse * 1.6);
      canvas.drawLine(center + Offset(-size, 0), center + Offset(size, 0), sparkle);
      canvas.drawLine(center + Offset(0, -size), center + Offset(0, size), sparkle);
    }
  }

  @override
  bool shouldRepaint(covariant _RoutineAvatarPainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.kind != kind ||
        oldDelegate.color != color ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.showFloor != showFloor;
  }
}

class _Pose {
  double hipX = 0;
  double hipY = -56;
  double lean = 0;
  double headLean = 0;
  double shoulderShift = 0;
  double spine = 0;
  double heelLift = 0;
  double belly = 0;
  double faceTurn = 0;
  Offset depth = const Offset(-3.2, 0);
  double armU = 10;
  double armL = 12;
  double armUb = -8;
  double armLb = -12;
  double legU = 4;
  double legL = 2;
  double legUb = -4;
  double legLb = -2;
  bool chair = false;
  bool wall = false;
  bool frontGrounded = true;
  bool backGrounded = true;
}

class _Rig {
  final Offset hip;
  final Offset shoulder;
  final Offset hipBack;
  final Offset shoulderBack;
  final Offset neck;
  final Offset head;
  final Offset elbow;
  final Offset wrist;
  final Offset elbowBack;
  final Offset wristBack;
  final Offset knee;
  final Offset ankle;
  final Offset kneeBack;
  final Offset ankleBack;
  final double lean;
  final double headAngle;
  final double spine;
  final double heelLift;
  final double belly;
  final double faceTurn;
  final bool chair;
  final bool wall;
  final bool frontGrounded;
  final bool backGrounded;

  const _Rig({
    required this.hip,
    required this.shoulder,
    required this.hipBack,
    required this.shoulderBack,
    required this.neck,
    required this.head,
    required this.elbow,
    required this.wrist,
    required this.elbowBack,
    required this.wristBack,
    required this.knee,
    required this.ankle,
    required this.kneeBack,
    required this.ankleBack,
    required this.lean,
    required this.headAngle,
    required this.spine,
    required this.heelLift,
    required this.belly,
    required this.faceTurn,
    required this.chair,
    required this.wall,
    required this.frontGrounded,
    required this.backGrounded,
  });
}

Offset _up(double degrees) {
  final radians = degrees * math.pi / 180;
  return Offset(math.sin(radians), -math.cos(radians));
}

Offset _down(double degrees) {
  final radians = degrees * math.pi / 180;
  return Offset(math.sin(radians), math.cos(radians));
}

Offset _perp(double degrees) {
  final radians = degrees * math.pi / 180;
  return Offset(math.cos(radians), math.sin(radians));
}
