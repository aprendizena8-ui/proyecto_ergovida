import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pose_detection/pose_detection.dart';
import 'package:tarea/features/exercises/exercise_camera_painter.dart';

void main() {
  PoseLandmark landmarkAt(double x, double y) => PoseLandmark(
    type: PoseLandmarkType.nose,
    x: x,
    y: y,
    z: 0,
    visibility: 1,
  );

  test('normaliza usando el tamaño real del frame de detección', () {
    final point = normalizedPoint(landmarkAt(320, 240), const Size(640, 480));

    expect(point.dx, closeTo(0.5, 0.0001));
    expect(point.dy, closeTo(0.5, 0.0001));
  });

  test('recorta coordenadas fuera del frame', () {
    expect(
      normalizedPoint(landmarkAt(-20, 900), const Size(640, 480)),
      const Offset(0, 1),
    );
  });
}
