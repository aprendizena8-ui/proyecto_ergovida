import 'exercise_camera_models.dart';

  // ------------------------------------------------------------
  //  Instrucciones
  // ------------------------------------------------------------

/// Devuelve las instrucciones según el tipo de ejercicio.
List<String> getInstructions(ExerciseKind kind) {
  switch (kind) {
    case ExerciseKind.neck:
      return [
        "Siéntate derecho con la espalda recta, a una distancia donde se vean tus hombros.",
        "Inclina suavemente la cabeza hacia un lado, como acercando la oreja al hombro.",
        "Mantén la posición unos segundos sin levantar el hombro.",
        "Vuelve al centro y repite hacia el otro lado.",
        "Respira profundo durante todo el ejercicio.",
      ];
    case ExerciseKind.shoulders:
      return [
        "Siéntate derecho, relajado, con los hombros y codos a la vista.",
        "Quédate quieto 2 segundos mientras medimos tu postura.",
        "Sube ambos hombros hacia las orejas y mantén 1-2 segundos.",
        "Suelta de golpe y repite 5 veces.",
        "Luego haz círculos grandes con los hombros, adelante y atrás.",
      ];
    case ExerciseKind.wrists:
      return [
        "Levanta los antebrazos frente al pecho, con los codos doblados.",
        "Mantén las manos abiertas y a la vista de la cámara.",
        "Gira las muñecas en círculos hacia afuera y luego hacia adentro.",
        "También puedes flexionarlas hacia arriba y hacia abajo.",
        "Sacude las manos suavemente al terminar.",
      ];
    case ExerciseKind.visual:
      return [
        "Aparta la mirada de la pantalla.",
        "Durante 20 segundos enfoca un objeto lejano (mínimo 6 metros).",
        "Luego cierra los ojos y relájalos durante 10 segundos.",
        "Parpadea varias veces de forma consciente.",
        "El ciclo se repite hasta que termine el tiempo.",
      ];
    case ExerciseKind.other:
      return ["Sigue las indicaciones del ejercicio."];
  }
}

/// Devuelve un tip según el tipo de ejercicio.
String getTip(ExerciseKind kind) {
  switch (kind) {
    case ExerciseKind.neck:
    case ExerciseKind.shoulders:
      return "Consejo: aléjate de la cámara hasta que se vean tu cabeza, hombros y codos. Con buena luz la detección mejora mucho.";
    case ExerciseKind.wrists:
      return "Consejo: la cámara debe ver tus codos y manos. Mantén las manos abiertas y de frente.";
    case ExerciseKind.visual:
      return "Nota: la cámara no puede comprobar si miras lejos o si cierras los ojos. Esta rutina te guía con el temporizador.";
    case ExerciseKind.other:
      return "";
  }
}

/// Convierte el nombre del ejercicio al tipo.
ExerciseKind kindFor(String nombre) {
  final s = nombre.toLowerCase();
  if (s.contains('cuello')) return ExerciseKind.neck;
  if (s.contains('hombro')) return ExerciseKind.shoulders;
  if (s.contains('muñeca') || s.contains('muneca')) return ExerciseKind.wrists;
  if (s.contains('visual')) return ExerciseKind.visual;
  return ExerciseKind.other;
}