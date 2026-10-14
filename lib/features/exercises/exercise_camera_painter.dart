import 'package:flutter/material.dart';
import 'package:pose_detection/pose_detection.dart';
import 'exercise_camera_models.dart';

/// Devuelve la posición del punto entre 0 y 1.
/// Si la librería entrega píxeles (valores > 1.5), los divide por el tamaño
/// del frame; si ya vienen normalizados, los deja igual.
Offset normalizedPoint(PoseLandmark lm, Size? imageSize) {
  double x = lm.x;
  double y = lm.y;
  if (imageSize != null && (x > 1.5 || y > 1.5)) {
    x = x / imageSize.width;
    y = y / imageSize.height;
  }
  return Offset(x, y);
}

/// Dibuja el esqueleto de la parte superior del cuerpo.
class PosePainter extends CustomPainter {
  final Map<PoseLandmarkType, BodyPoint> pts;
  final bool mirror;

  PosePainter(this.pts, this.mirror);

  Offset _o(BodyPoint p, Size size) {
    final x = mirror ? 1 - p.x : p.x;
    return Offset(x * size.width, p.y * size.height);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.lightGreenAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final dot = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.fill;

    for (final bone in bones) {
      final a = pts[bone[0]];
      final b = pts[bone[1]];
      if (a == null || b == null || a.v < minVis || b.v < minVis) continue;
      canvas.drawLine(_o(a, size), _o(b, size), line);
    }
    for (final p in pts.values) {
      if (p.v >= minVis) {
        canvas.drawCircle(_o(p, size), 6, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}