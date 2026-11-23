import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'exercise_camera_models.dart';

/// Avatar translúcido que sirve como guía visual mientras la cámara detecta
/// el movimiento. Solo se muestra en ejercicios con movimiento identificable.
class ExerciseAvatar extends StatefulWidget {
  final ExerciseKind kind;

  const ExerciseAvatar({super.key, required this.kind});

  @override
  State<ExerciseAvatar> createState() => _ExerciseAvatarState();
}

class _ExerciseAvatarState extends State<ExerciseAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
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
            constraints.maxWidth.isFinite ? constraints.maxWidth : 132,
            constraints.maxHeight.isFinite ? constraints.maxHeight : 180,
          );
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Opacity(
                opacity: 0.55,
                child: CustomPaint(
                  size: size,
                  painter: ExerciseAvatarPainter(
                    kind: widget.kind,
                    t: _controller.value,
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

class ExerciseAvatarPainter extends CustomPainter {
  final ExerciseKind kind;
  final double t;

  ExerciseAvatarPainter({required this.kind, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    if (kind == ExerciseKind.visual || kind == ExerciseKind.other) return;
    if (size.width <= 0 || size.height <= 0) return;

    final bodyWidth = math.min(size.width, size.height * 0.72);
    final cx = size.width / 2;
    final shoulderWidth = bodyWidth * 0.24;
    final hipWidth = bodyWidth * 0.15;
    final headRadius = bodyWidth * 0.085;
    final upperArm = size.height * 0.16;
    final foreArm = size.height * 0.15;
    final upperLeg = size.height * 0.20;
    final lowerLeg = size.height * 0.18;

    final double pulse = (math.sin((t * 2 * math.pi) - math.pi / 2) + 1) / 2;
    final double wave = math.sin(t * 2 * math.pi);

    var headX = cx;
    var headYOffset = 0.0;
    var headTilt = 0.0;
    var leftShoulderLift = 0.0;
    var rightShoulderLift = 0.0;
    var torsoShift = 0.0;
    var leftUpperAngle = 12.0;
    var rightUpperAngle = 12.0;
    var leftElbowBend = 8.0;
    var rightElbowBend = 8.0;
    var leftWristInward = 0.0;
    var rightWristInward = 0.0;
    var handSpin = 0.0;
    var handSpread = 0.0;

    switch (kind) {
      case ExerciseKind.neck:
        headX = cx + wave * bodyWidth * 0.07;
        headTilt = wave * 0.32;
        break;
      case ExerciseKind.shoulders:
        leftShoulderLift = -pulse * size.height * 0.035;
        rightShoulderLift = leftShoulderLift;
        break;
      case ExerciseKind.wrists:
        leftUpperAngle = 52;
        rightUpperAngle = 52;
        leftElbowBend = 88;
        rightElbowBend = 88;
        handSpin = t * math.pi * 4;
        break;
      case ExerciseKind.armsUp:
        leftUpperAngle = 15 + pulse * 155;
        rightUpperAngle = leftUpperAngle;
        leftElbowBend = 4;
        rightElbowBend = 4;
        break;
      case ExerciseKind.curls:
        leftUpperAngle = 12;
        rightUpperAngle = 12;
        leftElbowBend = 10 + pulse * 150;
        rightElbowBend = leftElbowBend;
        break;
      case ExerciseKind.chest:
        leftUpperAngle = 20 + pulse * 75;
        rightUpperAngle = leftUpperAngle;
        leftElbowBend = 8;
        rightElbowBend = 8;
        break;
      case ExerciseKind.sideBend:
        torsoShift = wave * bodyWidth * 0.09;
        headX = cx + torsoShift * 1.25;
        headTilt = wave * 0.10;
        break;
      case ExerciseKind.neckRotation:
        headX = cx + torsoShift + wave * bodyWidth * 0.10;
        headTilt = wave * 0.10;
        break;
      case ExerciseKind.neckNod:
        headYOffset = wave * size.height * 0.035;
        headTilt = wave * 0.04;
        break;
      case ExerciseKind.armCircles:
        leftUpperAngle = 85 + wave * 12;
        rightUpperAngle = 85 - wave * 12;
        leftElbowBend = 22 + pulse * 38;
        rightElbowBend = 22 + (1 - pulse) * 38;
        break;
      case ExerciseKind.lateralRaise:
        leftUpperAngle = 12 + pulse * 80;
        rightUpperAngle = leftUpperAngle;
        leftElbowBend = 6;
        rightElbowBend = 6;
        break;
      case ExerciseKind.selfHug:
        leftUpperAngle = 55;
        rightUpperAngle = 55;
        leftElbowBend = 100;
        rightElbowBend = 100;
        leftWristInward = bodyWidth * 0.40 + pulse * bodyWidth * 0.03;
        rightWristInward = leftWristInward;
        break;
      case ExerciseKind.prayerPress:
        leftUpperAngle = 55;
        rightUpperAngle = 55;
        leftElbowBend = 95;
        rightElbowBend = 95;
        leftWristInward = bodyWidth * 0.33 + pulse * bodyWidth * 0.02;
        rightWristInward = leftWristInward;
        break;
      case ExerciseKind.crossShoulder:
        final crossLeft = wave >= 0;
        if (crossLeft) {
          leftUpperAngle = 55;
          leftElbowBend = 105;
          leftWristInward = bodyWidth * 0.52;
        } else {
          rightUpperAngle = 55;
          rightElbowBend = 105;
          rightWristInward = bodyWidth * 0.52;
        }
        break;
      case ExerciseKind.goalpost:
        leftUpperAngle = 90;
        rightUpperAngle = 90;
        leftElbowBend = 90;
        rightElbowBend = 90;
        break;
      case ExerciseKind.alternatingShrug:
        leftShoulderLift = wave > 0 ? -wave * size.height * 0.04 : 0;
        rightShoulderLift = wave < 0 ? wave * size.height * 0.04 : 0;
        break;
      case ExerciseKind.fingerSpread:
        leftUpperAngle = 55;
        rightUpperAngle = 55;
        leftElbowBend = 90;
        rightElbowBend = 90;
        leftWristInward = bodyWidth * 0.24;
        rightWristInward = bodyWidth * 0.24;
        handSpread = 0.25 + pulse * 0.75;
        break;
      case ExerciseKind.forearmCircles:
        leftUpperAngle = 15 + wave * 8;
        rightUpperAngle = 15 - wave * 8;
        leftElbowBend = 75 + wave * 40;
        rightElbowBend = 75 - wave * 40;
        break;
      case ExerciseKind.shoulderTaps:
        final tapLeft = wave >= 0;
        if (tapLeft) {
          leftUpperAngle = 55;
          leftElbowBend = 115;
          leftWristInward = bodyWidth * 0.48;
        } else {
          rightUpperAngle = 55;
          rightElbowBend = 115;
          rightWristInward = bodyWidth * 0.48;
        }
        break;
      case ExerciseKind.visual:
      case ExerciseKind.other:
        return;
    }

    final shoulderY = size.height * 0.31;
    final neckY = shoulderY - size.height * 0.045;
    final headY =
        neckY -
        headRadius -
        size.height * 0.015 +
        headYOffset;
    final hipY = size.height * 0.61;
    final kneeY = hipY + upperLeg;
    final ankleY = math.min(size.height * 0.96, kneeY + lowerLeg);

    final neck = Offset(cx + torsoShift, neckY);
    final hipCenter = Offset(cx, hipY);
    final leftShoulder = Offset(
      cx + torsoShift - shoulderWidth,
      shoulderY + leftShoulderLift,
    );
    final rightShoulder = Offset(
      cx + torsoShift + shoulderWidth,
      shoulderY + rightShoulderLift,
    );
    final leftHip = Offset(cx - hipWidth, hipY);
    final rightHip = Offset(cx + hipWidth, hipY);
    final leftKnee = Offset(cx - hipWidth * 1.25, kneeY);
    final rightKnee = Offset(cx + hipWidth * 1.25, kneeY);
    final leftAnkle = Offset(cx - hipWidth * 1.35, ankleY);
    final rightAnkle = Offset(cx + hipWidth * 1.35, ankleY);

    final leftArm = _arm(
      shoulder: leftShoulder,
      side: -1,
      upperAngle: leftUpperAngle,
      elbowBend: leftElbowBend,
      wristInward: leftWristInward,
      upperLength: upperArm,
      lowerLength: foreArm,
    );
    final rightArm = _arm(
      shoulder: rightShoulder,
      side: 1,
      upperAngle: rightUpperAngle,
      elbowBend: rightElbowBend,
      wristInward: rightWristInward,
      upperLength: upperArm,
      lowerLength: foreArm,
    );

    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = math.max(2.5, size.width * 0.022)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final glow = Paint()
      ..color = Colors.lightBlueAccent.withValues(alpha: 0.28)
      ..strokeWidth = math.max(8, size.width * 0.06)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final joint = Paint()..color = Colors.lightBlueAccent;
    final headFill = Paint()
      ..color = Colors.lightBlueAccent.withValues(alpha: 0.16)
      ..style = PaintingStyle.fill;

    void bone(Offset a, Offset b) {
      canvas.drawLine(a, b, glow);
      canvas.drawLine(a, b, line);
    }

    // Columna, hombros y caderas.
    bone(neck, hipCenter);
    bone(leftShoulder, rightShoulder);
    bone(leftHip, rightHip);
    bone(leftShoulder, leftHip);
    bone(rightShoulder, rightHip);

    // Piernas.
    bone(leftHip, leftKnee);
    bone(leftKnee, leftAnkle);
    bone(rightHip, rightKnee);
    bone(rightKnee, rightAnkle);

    // Brazos.
    bone(leftShoulder, leftArm.elbow);
    bone(leftArm.elbow, leftArm.wrist);
    bone(rightShoulder, rightArm.elbow);
    bone(rightArm.elbow, rightArm.wrist);

    // Manos / rotación de muñecas / apertura de dedos.
    final handLength = bodyWidth * 0.075;
    if (kind == ExerciseKind.wrists) {
      final leftAngle = handSpin;
      final rightAngle = handSpin + math.pi;
      bone(
        leftArm.wrist,
        leftArm.wrist +
            Offset(math.cos(leftAngle), math.sin(leftAngle)) * handLength,
      );
      bone(
        rightArm.wrist,
        rightArm.wrist +
            Offset(math.cos(rightAngle), math.sin(rightAngle)) * handLength,
      );
    } else if (kind == ExerciseKind.fingerSpread) {
      _fingers(canvas, leftArm.wrist, handLength, handSpread, line);
      _fingers(canvas, rightArm.wrist, handLength, handSpread, line);
    } else {
      bone(leftArm.wrist, leftArm.wrist + const Offset(-2, 10));
      bone(rightArm.wrist, rightArm.wrist + const Offset(2, 10));
    }

    // Cabeza inclinada para el ejercicio de cuello.
    canvas.save();
    canvas.translate(headX, headY);
    canvas.rotate(headTilt);
    canvas.drawCircle(Offset.zero, headRadius, headFill);
    canvas.drawCircle(Offset.zero, headRadius, line);
    canvas.drawLine(
      Offset(-headRadius * 0.42, -headRadius * 0.18),
      Offset(headRadius * 0.42, -headRadius * 0.18),
      line,
    );
    canvas.restore();

    // Articulaciones.
    for (final jointPoint in [
      leftShoulder,
      rightShoulder,
      leftArm.elbow,
      rightArm.elbow,
      leftArm.wrist,
      rightArm.wrist,
      leftHip,
      rightHip,
      leftKnee,
      rightKnee,
      leftAnkle,
      rightAnkle,
    ]) {
      canvas.drawCircle(jointPoint, math.max(2.5, size.width * 0.023), joint);
    }

    // Línea de guía en el suelo.
    final floor = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx - bodyWidth * 0.34, size.height * 0.965),
      Offset(cx + bodyWidth * 0.34, size.height * 0.965),
      floor,
    );
  }

  void _fingers(
    Canvas canvas,
    Offset wrist,
    double handLength,
    double spread,
    Paint paint,
  ) {
    for (final angle in const [-0.55, -0.18, 0.18, 0.55]) {
      final rad = math.pi / 2 + angle * spread;
      final tip =
          wrist +
          Offset(math.cos(rad), math.sin(rad)) * handLength * 1.15;
      canvas.drawLine(wrist, tip, paint);
    }
  }

  _ArmPoints _arm({
    required Offset shoulder,
    required int side,
    required double upperAngle,
    required double elbowBend,
    required double wristInward,
    required double upperLength,
    required double lowerLength,
  }) {
    final upperRad = upperAngle * math.pi / 180;
    final lowerRad = (upperAngle + elbowBend) * math.pi / 180;

    final elbow = shoulder +
        Offset(
          side * math.sin(upperRad) * upperLength,
          math.cos(upperRad) * upperLength,
        );
    final wrist = elbow +
        Offset(
          side * math.sin(lowerRad) * lowerLength,
          math.cos(lowerRad) * lowerLength,
        ) -
        Offset(side * wristInward, 0);

    return _ArmPoints(elbow: elbow, wrist: wrist);
  }

  @override
  bool shouldRepaint(covariant ExerciseAvatarPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.kind != kind;
  }
}

class _ArmPoints {
  final Offset elbow;
  final Offset wrist;

  const _ArmPoints({required this.elbow, required this.wrist});
}
