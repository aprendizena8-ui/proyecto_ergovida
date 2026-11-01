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
    case ExerciseKind.armsUp:
      return [
        "Siéntate derecho y deja los brazos a los lados, visibles para la cámara.",
        "Sube ambos brazos estirados por encima de la cabeza.",
        "Mantén un instante arriba sin encoger los hombros.",
        "Baja los brazos con control hasta pasarlos por debajo de los hombros.",
        "Repite el movimiento con calma, sin arquear la espalda.",
      ];
    case ExerciseKind.curls:
      return [
        "Siéntate derecho con los brazos junto al cuerpo.",
        "Muestra los hombros, codos y manos a la cámara.",
        "Flexiona ambos codos llevando las manos hacia los hombros.",
        "Mantén los codos pegados al costado y sube con control.",
        "Extiende los brazos lentamente para completar cada repetición.",
      ];
    case ExerciseKind.chest:
      return [
        "Siéntate derecho y separa los brazos del cuerpo.",
        "Abre los brazos hacia los lados a la altura de los hombros.",
        "Junta ligeramente los omóplatos y saca el pecho sin arquear la espalda.",
        "Mantén la apertura mientras la app cuenta los segundos.",
        "Baja los brazos, relaja y repite.",
      ];
    case ExerciseKind.sideBend:
      return [
        "Siéntate derecho con los hombros y la cabeza visibles.",
        "Quédate recto un momento para que la app mida tu postura.",
        "Inclina el tronco suavemente hacia un lado, sin mover las caderas.",
        "Mantén el estiramiento y vuelve al centro.",
        "Repite hacia el otro lado con el mismo control.",
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
    case ExerciseKind.armsUp:
      return "Consejo: aléjate hasta que se vean tus hombros, codos y manos completas, incluso con los brazos arriba.";
    case ExerciseKind.curls:
      return "Consejo: mantén los codos visibles y cerca del cuerpo. La app cuenta cuando flexionas y vuelves a extender.";
    case ExerciseKind.chest:
      return "Consejo: la cámara necesita ver ambas manos. Abre los brazos a la altura de los hombros y mantén la espalda recta.";
    case ExerciseKind.sideBend:
      return "Consejo: mantén la cabeza y ambos hombros dentro del encuadre. El movimiento debe venir del tronco, no del cuello.";
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
  if (s.contains('brazo')) return ExerciseKind.armsUp;
  if (s.contains('codo')) return ExerciseKind.curls;
  if (s.contains('pecho')) return ExerciseKind.chest;
  if (s.contains('tronco')) return ExerciseKind.sideBend;
  if (s.contains('visual')) return ExerciseKind.visual;
  return ExerciseKind.other;
}
