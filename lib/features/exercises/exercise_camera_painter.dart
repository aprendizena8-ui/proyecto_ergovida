import 'dart:math' as math;
import 'dart:ui' as ui;

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

/// Overlay del esqueleto detectado sobre la vista previa.
///
/// Se dibujan solo las cadenas del cuerpo (hombros, tronco, brazos y manos):
/// las conexiones de ojos, nariz y boca generan una «telaraña» que distrae y
/// se ve mal sobre el video. Los trazos se suavizan con curvas, se difuminan
/// según la confianza de cada punto y se acompañan de un brillo muy tenue.
class PosePainter extends CustomPainter {
  final Map<PoseLandmarkType, BodyPoint> pts;
  final Size imageSize;
  final bool mirror;

  PosePainter(this.pts, this.imageSize, this.mirror);

  static const Color _accent = Color(0xFF7DE9C6);
  static const double _minDrawVis = 0.12;

  /// Cadenas continuas. Cada cadena se dibuja como una sola curva suave.
  static const List<List<PoseLandmarkType>> _chains = [
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
    [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
    [
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.leftWrist,
      PoseLandmarkType.leftIndex,
    ],
    [
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.rightWrist,
      PoseLandmarkType.rightIndex,
    ],
  ];

  static const List<PoseLandmarkType> _joints = [
    PoseLandmarkType.leftShoulder,
    PoseLandmarkType.rightShoulder,
    PoseLandmarkType.leftElbow,
    PoseLandmarkType.rightElbow,
    PoseLandmarkType.leftWrist,
    PoseLandmarkType.rightWrist,
    PoseLandmarkType.leftHip,
    PoseLandmarkType.rightHip,
  ];

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

  double _chainVisibility(List<BodyPoint> points) {
    var v = 1.0;
    for (final p in points) {
      v = math.min(v, p.v);
    }
    return v;
  }

  void _drawChain(
    Canvas canvas,
    List<Offset> points,
    double alpha,
    double width,
  ) {
    if (points.length < 2) return;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length - 1; i++) {
      final mid = Offset.lerp(points[i], points[i + 1], 0.5)!;
      path.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);

    // Brillo suave, sin el círculo sólido que se veía como una mancha.
    canvas.drawPath(
      path,
      Paint()
        ..color = _accent.withValues(alpha: 0.16 * alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 3.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5),
    );

    final end = points.last == points.first
        ? points.first + const Offset(0.01, 0.01)
        : points.last;
    canvas.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.linear(points.first, end, [
          _accent.withValues(alpha: 0.95 * alpha),
          Colors.white.withValues(alpha: 0.72 * alpha),
        ])
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (pts.isEmpty || size.width <= 0 || size.height <= 0) return;

    final leftShoulder = _p(PoseLandmarkType.leftShoulder);
    final rightShoulder = _p(PoseLandmarkType.rightShoulder);
    final refWidth = leftShoulder != null && rightShoulder != null
        ? (_map(leftShoulder, size) - _map(rightShoulder, size)).distance
        : size.height * 0.12;
    final lineWidth = (size.height * 0.006).clamp(2.0, 4.5);

    for (final chain in _chains) {
      final points = <BodyPoint>[];
      var available = true;
      for (final type in chain) {
        final p = pts[type];
        if (p == null || p.v < _minDrawVis) {
          available = false;
          break;
        }
        points.add(p);
      }
      if (!available) continue;

      final alpha = (_chainVisibility(points) * 0.92).clamp(0.0, 1.0);
      _drawChain(
        canvas,
        points.map((p) => _map(p, size)).toList(growable: false),
        alpha,
        lineWidth,
      );
    }

    // Cabeza: un contorno neutro en lugar de líneas entre ojos y boca.
    final le = pts[PoseLandmarkType.leftEar];
    final re = pts[PoseLandmarkType.rightEar];
    final nose = pts[PoseLandmarkType.nose];
    Offset? headCenter;
    double headRadius = 0;
    double headAlpha = 0;
    if (le != null && re != null && le.v >= _minDrawVis && re.v >= _minDrawVis) {
      final a = _map(le, size);
      final b = _map(re, size);
      headCenter = Offset.lerp(a, b, 0.5);
      headRadius = math.max((a - b).distance * 0.62, refWidth * 0.20);
      headAlpha = math.min(le.v, re.v);
    } else if (nose != null && nose.v >= _minDrawVis) {
      headCenter = _map(nose, size);
      headRadius = refWidth * 0.26;
      headAlpha = nose.v * 0.8;
    }
    if (headCenter != null && headRadius > 0) {
      canvas.drawCircle(
        headCenter,
        headRadius,
        Paint()..color = _accent.withValues(alpha: 0.07 * headAlpha),
      );
      canvas.drawCircle(
        headCenter,
        headRadius,
        Paint()
          ..color = _accent.withValues(alpha: 0.45 * headAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = lineWidth * 0.8,
      );
    }

    // Articulaciones pequeñas y limpias: aro tenue + núcleo blanco.
    for (final type in _joints) {
      final p = pts[type];
      if (p == null || p.v < _minDrawVis) continue;
      final o = _map(p, size);
      final a = (p.v * 0.9).clamp(0.0, 1.0);
      final radius = lineWidth * 1.15;
      canvas.drawCircle(
        o,
        radius,
        Paint()
          ..color = _accent.withValues(alpha: 0.28 * a)
          ..style = PaintingStyle.stroke
          ..strokeWidth = lineWidth * 0.7,
      );
      canvas.drawCircle(
        o,
        radius * 0.38,
        Paint()..color = Colors.white.withValues(alpha: 0.9 * a),
      );
    }
  }

  BodyPoint? _p(PoseLandmarkType type) {
    final p = pts[type];
    if (p == null || p.v < _minDrawVis) return null;
    return p;
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) => true;
}
