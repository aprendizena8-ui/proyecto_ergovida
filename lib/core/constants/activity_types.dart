/// Tipos explícitos de actividad guardada en `pausas_realizadas`.
///
/// Coinciden con los valores de `TiposActividad` en el backend Spring.
class ActivityTypes {
  static const detectedExercise = 'ejercicio_detectado';
  static const additionalRoutine = 'rutina_adicional';

  static String normalize(Object? tipo) {
    final valor = tipo?.toString().trim().toLowerCase() ?? '';
    return valor == additionalRoutine ? additionalRoutine : detectedExercise;
  }

  static bool isDetected(Object? tipo) => normalize(tipo) == detectedExercise;

  static bool isRoutine(Object? tipo) => normalize(tipo) == additionalRoutine;
}

/// Conteos derivados de la lista de registros del usuario.
///
/// SST cuenta únicamente ejercicios detectados confirmados. Los logros cuentan
/// esos mismos ejercicios más las rutinas adicionales completadas.
class ActivityCounts {
  final int detectedCompleted;
  final int routinesCompleted;

  const ActivityCounts({this.detectedCompleted = 0, this.routinesCompleted = 0});

  factory ActivityCounts.fromPausas(List<dynamic> pausas) {
    var detectados = 0;
    var rutinas = 0;
    for (final pausa in pausas) {
      if (pausa is! Map || pausa['completada'] != true) continue;
      final tipo = pausa['tipo'];
      if (ActivityTypes.isRoutine(tipo)) {
        rutinas++;
      } else if (ActivityTypes.isDetected(tipo)) {
        detectados++;
      }
    }
    return ActivityCounts(detectedCompleted: detectados, routinesCompleted: rutinas);
  }

  /// Total que suma para logros, nunca para el seguimiento SST.
  int get paraLogros => detectedCompleted + routinesCompleted;

  bool get completoSst => detectedCompleted > 0;

  ActivityCounts copyWith({int? detectedCompleted, int? routinesCompleted}) {
    return ActivityCounts(
      detectedCompleted: detectedCompleted ?? this.detectedCompleted,
      routinesCompleted: routinesCompleted ?? this.routinesCompleted,
    );
  }
}
