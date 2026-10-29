import 'package:flutter/material.dart';
import 'package:pose_detection/pose_detection.dart';
import 'exercise_camera_models.dart';

/// Devuelve la posición del punto entre 0 y 1.
/// El paquete entrega píxeles del frame ya rotado/reescalado, así que se
/// dividen por el tamaño reportado por [detectionSize].
Offset normalizedPoint(PoseLandmark lm, Size? imageSize) {
  if (imageSize == null || imageSize.width <= 0 || imageSize.height <= 0) {
    return Offset(lm.x.clamp(0.0, 1.0), lm.y.clamp(0.0, 1.0));
  }

  return Offset(
    (lm.x / imageSize.width).clamp(0.0, 1.0),
    (lm.y / imageSize.height).clamp(0.0, 1.0),
  );
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
