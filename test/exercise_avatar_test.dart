import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tarea/features/exercises/exercise_avatar.dart';
import 'package:tarea/features/exercises/exercise_camera_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<Uint8List> renderAvatar(ExerciseKind kind, double t) async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    ExerciseAvatarPainter(kind: kind, t: t).paint(canvas, const Size(320, 420));
    final image = await recorder.endRecording().toImage(320, 420);
    final data = await image.toByteData();
    return data!.buffer.asUint8List();
  }

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

  test('cada ejercicio activo cambia de pose entre dos instantes', () async {
    final activos = ExerciseKind.values.where(
      (kind) => kind != ExerciseKind.visual && kind != ExerciseKind.other,
    );

    for (final kind in activos) {
      final inicio = await renderAvatar(kind, 0.0);
      final mitad = await renderAvatar(kind, 0.25);
      expect(inicio, isNot(equals(mitad)), reason: kind.name);
    }
  });
}
