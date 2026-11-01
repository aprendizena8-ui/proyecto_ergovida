import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pose_detection/pose_detection.dart';
import 'exercise_camera_models.dart';

/// Convierte un landmark a coordenadas normalizadas (0 a 1).
///
/// El paquete entrega [PoseLandmark.x] e [PoseLandmark.y] en píxeles del frame
/// que realmente analizó el detector (ya rotado y reescalado). Por eso hay que
/// dividir entre [imageSize], que debe venir de [Pose.imageWidth] y
/// [Pose.imageHeight], no de un tamaño estimado por la app.
Offset normalizedPoint(PoseLandmark lm, Size imageSize) {
  final width = imageSize.width;
  final height = imageSize.height;
  if (width <= 0 || height <= 0) return const Offset(0.5, 0.5);

  return Offset(
    (lm.x / width).clamp(0.0, 1.0),
    (lm.y / height).clamp(0.0, 1.0),
  );
}

/// Dibuja el esqueleto detectado sobre el preview.
///
/// Los puntos llegan normalizados respecto al frame de detección. Para que el
/// esqueleto coincida con el video aunque el widget tenga otro aspecto, se usa
/// el mismo ajuste "cover" que aplica el preview, con espejo opcional.
class PosePainter extends CustomPainter {
  final Map<PoseLandmarkType, BodyPoint> pts;
  final Size imageSize;
  final bool mirror;

  PosePainter(this.pts, this.imageSize, this.mirror);

  Offset _map(BodyPoint p, Size size) {
    if (imageSize.width <= 0 || imageSize.height <= 0) {
      return Offset(p.x * size.width, p.y * size.height);
    }

    final scale = math.max(
      size.width / imageSize.width,
      size.height / imageSize.height,
    );
    final dx = (size.width - imageSize.width * scale) / 2;
    final dy = (size.height - imageSize.height * scale) / 2;
    final x = p.x * imageSize.width * scale + dx;
    final y = p.y * imageSize.height * scale + dy;
    return Offset(mirror ? size.width - x : x, y);
  }

  bool _isFace(PoseLandmarkType type) {
    return switch (type) {
      PoseLandmarkType.nose ||
      PoseLandmarkType.leftEyeInner ||
      PoseLandmarkType.leftEye ||
      PoseLandmarkType.leftEyeOuter ||
      PoseLandmarkType.rightEyeInner ||
      PoseLandmarkType.rightEye ||
      PoseLandmarkType.rightEyeOuter ||
      PoseLandmarkType.leftEar ||
      PoseLandmarkType.rightEar ||
      PoseLandmarkType.mouthLeft ||
      PoseLandmarkType.mouthRight => true,
      _ => false,
    };
  }

  bool _isHand(PoseLandmarkType type) {
    return switch (type) {
      PoseLandmarkType.leftIndex ||
      PoseLandmarkType.rightIndex ||
      PoseLandmarkType.leftPinky ||
      PoseLandmarkType.rightPinky ||
      PoseLandmarkType.leftThumb ||
      PoseLandmarkType.rightThumb => true,
      _ => false,
    };
  }

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.lightGreenAccent.withValues(alpha: 0.9)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final glow = Paint()
      ..color = Colors.lightGreenAccent.withValues(alpha: 0.25);
    final dot = Paint()..color = Colors.greenAccent;
    final center = Paint()..color = Colors.white;

    for (final bone in poseLandmarkConnections) {
      final a = pts[bone[0]];
      final b = pts[bone[1]];
      if (a == null || b == null || a.v < minVis || b.v < minVis) continue;
      canvas.drawLine(_map(a, size), _map(b, size), line);
    }

    for (final entry in pts.entries) {
      final p = entry.value;
      if (p.v < minVis) continue;

      final o = _map(p, size);
      final face = _isFace(entry.key);
      final hand = _isHand(entry.key);
      drawLandmarkMarker(
        canvas,
        o.dx,
        o.dy,
        glowRadius: face ? 4 : (hand ? 6 : 8),
        pointRadius: face ? 2.5 : (hand ? 4 : 5),
        centerRadius: face ? 1 : 2,
        glowPaint: glow,
        pointPaint: dot,
        centerPaint: center,
      );
    }
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) => true;
}
