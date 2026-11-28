import 'package:flutter_test/flutter_test.dart';
import 'package:tarea/features/exercises/exercise_camera_logic.dart';
import 'package:tarea/features/exercises/exercise_camera_models.dart';

void main() {
  test('mapea los doce ejercicios nuevos a su tipo de deteccion', () {
    const esperado = {
      'Rotación de Cuello': ExerciseKind.neckRotation,
      'Flexión y Extensión de Cuello': ExerciseKind.neckNod,
      'Círculos de Brazos': ExerciseKind.armCircles,
      'Elevación Lateral de Brazos': ExerciseKind.lateralRaise,
      'Abrazo de Oso': ExerciseKind.selfHug,
      'Prensa de Palmas': ExerciseKind.prayerPress,
      'Estiramiento Cruzado de Hombro': ExerciseKind.crossShoulder,
      'Postura de Cactus': ExerciseKind.goalpost,
      'Encogimiento Alterno de Hombros': ExerciseKind.alternatingShrug,
      'Apertura de Dedos': ExerciseKind.fingerSpread,
      'Círculos de Antebrazos': ExerciseKind.forearmCircles,
      'Toques de Hombro Alternos': ExerciseKind.shoulderTaps,
    };

    esperado.forEach((nombre, kind) {
      expect(kindFor(nombre), kind, reason: nombre);
    });
  });

  test('mantiene el mapeo de los ejercicios existentes', () {
    expect(kindFor('Estiramiento de Cuello'), ExerciseKind.neck);
    expect(kindFor('Movilidad de Hombros'), ExerciseKind.shoulders);
    expect(kindFor('Movilidad de Muñecas'), ExerciseKind.wrists);
    expect(kindFor('Descanso Visual'), ExerciseKind.visual);
    expect(kindFor('Elevación de Brazos'), ExerciseKind.armsUp);
    expect(kindFor('Flexión de Codos'), ExerciseKind.curls);
    expect(kindFor('Apertura de Pecho'), ExerciseKind.chest);
    expect(kindFor('Inclinación Lateral de Tronco'), ExerciseKind.sideBend);
  });

  test('solo los ejercicios con movimiento detectado cuentan para SST', () {
    bool cuenta(String nombre) {
      final kind = kindFor(nombre);
      return kind != ExerciseKind.visual && kind != ExerciseKind.other;
    }

    expect(cuenta('Elevación de Brazos'), isTrue);
    expect(cuenta('Estiramiento de Cuello'), isTrue);
    expect(cuenta('Descanso Visual'), isFalse);
    expect(cuenta('Ejercicio sin tipo conocido'), isFalse);
  });

  test('cada tipo nuevo tiene instrucciones y consejo', () {
    for (final kind in [
      ExerciseKind.neckRotation,
      ExerciseKind.neckNod,
      ExerciseKind.armCircles,
      ExerciseKind.lateralRaise,
      ExerciseKind.selfHug,
      ExerciseKind.prayerPress,
      ExerciseKind.crossShoulder,
      ExerciseKind.goalpost,
      ExerciseKind.alternatingShrug,
      ExerciseKind.fingerSpread,
      ExerciseKind.forearmCircles,
      ExerciseKind.shoulderTaps,
    ]) {
      expect(getInstructions(kind), isNotEmpty, reason: kind.name);
      expect(getTip(kind), isNotEmpty, reason: kind.name);
    }
  });
}
