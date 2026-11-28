import 'package:flutter_test/flutter_test.dart';
import 'package:tarea/core/constants/activity_types.dart';

void main() {
  group('reglas de conteo SST y logros', () {
    test('una rutina no cuenta para SST pero sí para logros', () {
      final conteos = ActivityCounts.fromPausas([
        {
          'completada': true,
          'tipo': ActivityTypes.additionalRoutine,
        },
      ]);

      expect(conteos.detectedCompleted, 0);
      expect(conteos.paraLogros, 1);
      expect(conteos.completoSst, isFalse);
    });

    test('un ejercicio detectado cuenta para SST y para logros', () {
      final conteos = ActivityCounts.fromPausas([
        {
          'completada': true,
          'tipo': ActivityTypes.detectedExercise,
        },
      ]);

      expect(conteos.detectedCompleted, 1);
      expect(conteos.paraLogros, 1);
      expect(conteos.completoSst, isTrue);
    });

    test('abrir o iniciar sin confirmar la detección no cuenta', () {
      final conteos = ActivityCounts.fromPausas([
        {
          'completada': false,
          'tipo': ActivityTypes.detectedExercise,
        },
      ]);

      expect(conteos.detectedCompleted, 0);
      expect(conteos.routinesCompleted, 0);
      expect(conteos.paraLogros, 0);
    });

    test('los registros antiguos sin tipo conservan su progreso', () {
      final conteos = ActivityCounts.fromPausas([
        {'completada': true},
      ]);

      expect(conteos.detectedCompleted, 1);
      expect(ActivityTypes.isDetected(null), isTrue);
    });

    test('ambos tipos suman en logros pero solo uno en SST', () {
      final conteos = ActivityCounts.fromPausas([
        {'completada': true, 'tipo': ActivityTypes.detectedExercise},
        {'completada': true, 'tipo': ActivityTypes.additionalRoutine},
        {'completada': true, 'tipo': ActivityTypes.additionalRoutine},
      ]);

      expect(conteos.detectedCompleted, 1);
      expect(conteos.routinesCompleted, 2);
      expect(conteos.paraLogros, 3);
    });
  });
}
