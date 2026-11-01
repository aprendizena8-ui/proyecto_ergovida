import 'package:flutter_test/flutter_test.dart';
import 'package:tarea/features/exercises/exercise_camera_logic.dart';
import 'package:tarea/features/exercises/exercise_camera_models.dart';

void main() {
  test('mapea los ejercicios nuevos a su tipo de deteccion', () {
    expect(kindFor('Elevación de Brazos'), ExerciseKind.armsUp);
    expect(kindFor('Flexión de Codos'), ExerciseKind.curls);
    expect(kindFor('Apertura de Pecho'), ExerciseKind.chest);
    expect(kindFor('Inclinación Lateral de Tronco'), ExerciseKind.sideBend);
  });

  test('mantiene el mapeo de los ejercicios existentes', () {
    expect(kindFor('Estiramiento de Cuello'), ExerciseKind.neck);
    expect(kindFor('Movilidad de Hombros'), ExerciseKind.shoulders);
    expect(kindFor('Movilidad de Muñecas'), ExerciseKind.wrists);
    expect(kindFor('Descanso Visual'), ExerciseKind.visual);
  });

  test('cada tipo nuevo tiene instrucciones y consejo', () {
    for (final kind in [
      ExerciseKind.armsUp,
      ExerciseKind.curls,
      ExerciseKind.chest,
      ExerciseKind.sideBend,
    ]) {
      expect(getInstructions(kind), isNotEmpty);
      expect(getTip(kind), isNotEmpty);
    }
  });
}
