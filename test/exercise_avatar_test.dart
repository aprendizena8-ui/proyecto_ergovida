import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tarea/features/exercises/exercise_avatar.dart';
import 'package:tarea/features/exercises/exercise_camera_models.dart';

void main() {
  test('pinta el avatar de todos los ejercicios sin errores', () {
    for (final kind in ExerciseKind.values) {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      ExerciseAvatarPainter(
        kind: kind,
        t: 0.37,
      ).paint(canvas, const Size(320, 420));
      recorder.endRecording().dispose();
    }
  });
}
