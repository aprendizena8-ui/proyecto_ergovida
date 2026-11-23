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
    case ExerciseKind.neckRotation:
      return [
        "Siéntate derecho con la cabeza y los hombros visibles.",
        "Mira al frente y gira la cabeza lentamente hacia un lado, como mirando por encima del hombro.",
        "Mantén el giro sin mover los hombros ni el tronco.",
        "Vuelve al centro y repite hacia el otro lado.",
        "Hazlo con suavidad, sin llegar a sentir dolor.",
      ];
    case ExerciseKind.neckNod:
      return [
        "Siéntate derecho y mira al frente.",
        "Baja la barbilla hacia el pecho sin encorvar la espalda.",
        "Mantén la flexión y vuelve al centro.",
        "Luego mira hacia el techo sin forzar el cuello.",
        "Alterna flexión y extensión con movimientos lentos.",
      ];
    case ExerciseKind.armCircles:
      return [
        "Siéntate derecho y abre los brazos a la altura de los hombros.",
        "Dibuja círculos pequeños primero y luego más grandes.",
        "Mantén los codos casi estirados y las manos visibles.",
        "Haz círculos hacia adelante y después hacia atrás.",
        "No subas los hombros hacia las orejas.",
      ];
    case ExerciseKind.lateralRaise:
      return [
        "Siéntate derecho con los brazos a los lados.",
        "Eleva ambos brazos hacia los lados hasta la altura de los hombros.",
        "Mantén un instante y baja con control.",
        "No subas los brazos por encima de la cabeza.",
        "Repite sin balancear el tronco.",
      ];
    case ExerciseKind.selfHug:
      return [
        "Siéntate derecho y abre los brazos.",
        "Cruza los brazos frente al pecho como si te abrazaras.",
        "Lleva cada mano hacia el hombro opuesto.",
        "Mantén el abrazo y respira profundo.",
        "Abre los brazos y repite.",
      ];
    case ExerciseKind.prayerPress:
      return [
        "Siéntate derecho y junta las palmas frente al esternón.",
        "Mantén los codos hacia afuera y los hombros abajo.",
        "Presiona las palmas suavemente y mantén.",
        "Relaja la presión y separa un poco las manos.",
        "Repite sin encorvar la espalda.",
      ];
    case ExerciseKind.crossShoulder:
      return [
        "Siéntate derecho y lleva un brazo cruzado frente al pecho.",
        "Apoya la mano en el hombro opuesto.",
        "Con la otra mano, acerca suavemente el codo al pecho.",
        "Mantén el estiramiento sin subir el hombro.",
        "Vuelve al centro y cambia de brazo.",
      ];
    case ExerciseKind.goalpost:
      return [
        "Siéntate derecho y levanta los codos a la altura de los hombros.",
        "Forma una L con cada brazo: codos afuera y manos arriba.",
        "Junta ligeramente los omóplatos y saca el pecho.",
        "Mantén la postura sin arquear la espalda.",
        "Baja los brazos y repite.",
      ];
    case ExerciseKind.alternatingShrug:
      return [
        "Siéntate derecho con los hombros relajados.",
        "Sube un hombro hacia la oreja y mantenlo un instante.",
        "Baja ese hombro y sube el otro.",
        "Alterna sin mover la cabeza.",
        "Respira de forma pausada.",
      ];
    case ExerciseKind.fingerSpread:
      return [
        "Levanta las manos frente al pecho con las palmas visibles.",
        "Abre bien los dedos, separándolos al máximo.",
        "Cierra las manos formando un puño suave.",
        "Repite abriendo y cerrando sin mover los brazos.",
        "Mantén las muñecas rectas.",
      ];
    case ExerciseKind.forearmCircles:
      return [
        "Siéntate derecho con los codos junto al cuerpo y doblados.",
        "Mantén los antebrazos frente al pecho.",
        "Dibuja círculos con las manos, primero pequeños.",
        "Amplía los círculos sin mover los codos.",
        "Cambia de dirección a mitad del ejercicio.",
      ];
    case ExerciseKind.shoulderTaps:
      return [
        "Siéntate derecho y levanta las manos frente a los hombros.",
        "Toca el hombro opuesto con una mano.",
        "Regresa la mano y toca el otro hombro con la mano contraria.",
        "Alterna sin mover el tronco.",
        "Mantén los hombros abajo y el abdomen activo.",
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
    case ExerciseKind.neckRotation:
      return "Consejo: la cámara debe ver tu nariz y ambos hombros. Gira solo la cabeza, no el cuerpo.";
    case ExerciseKind.neckNod:
      return "Consejo: mantén la cara y los hombros visibles; el movimiento debe ser lento y corto.";
    case ExerciseKind.armCircles:
      return "Consejo: aléjate hasta que se vean hombros, codos y manos completas. Haz círculos amplios y lentos.";
    case ExerciseKind.lateralRaise:
      return "Consejo: la cámara necesita ver ambas manos. Sube hasta la línea de los hombros, no más.";
    case ExerciseKind.selfHug:
      return "Consejo: muestra manos y hombros; el cruce debe verse claramente frente al pecho.";
    case ExerciseKind.prayerPress:
      return "Consejo: mantén las palmas juntas y los codos a la vista. Presiona sin subir los hombros.";
    case ExerciseKind.crossShoulder:
      return "Consejo: el brazo cruzado y el hombro opuesto deben verse completos en el encuadre.";
    case ExerciseKind.goalpost:
      return "Consejo: aléjate lo suficiente para que se vean codos y manos; codos a la altura de los hombros.";
    case ExerciseKind.alternatingShrug:
      return "Consejo: mantén cabeza y hombros visibles. El movimiento es solo del hombro.";
    case ExerciseKind.fingerSpread:
      return "Consejo: acerca las manos a la cámara sin tapar los hombros; abre bien los dedos.";
    case ExerciseKind.forearmCircles:
      return "Consejo: mantén los codos cerca del cuerpo y las manos visibles; no muevas los hombros.";
    case ExerciseKind.shoulderTaps:
      return "Consejo: deben verse ambos hombros y manos. Toca el hombro opuesto sin encorvarte.";
    case ExerciseKind.other:
      return "";
  }
}

/// Normaliza el nombre para comparar sin acentos ni signos.
String _slug(String value) {
  var s = value.toLowerCase();
  const replacements = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
    'ñ': 'n',
  };
  replacements.forEach((from, to) => s = s.replaceAll(from, to));
  return s.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
}

/// Convierte el nombre del ejercicio al tipo.
ExerciseKind kindFor(String nombre) {
  final s = _slug(nombre);

  // Los ejercicios nuevos se comprueban primero para evitar que palabras
  // genéricas como "cuello", "hombro" o "brazo" los capturen por error.
  if (s.contains('rotacion de cuello')) return ExerciseKind.neckRotation;
  if (s.contains('flexion y extension de cuello')) {
    return ExerciseKind.neckNod;
  }
  if (s.contains('circulos de brazos')) return ExerciseKind.armCircles;
  if (s.contains('elevacion lateral de brazos')) {
    return ExerciseKind.lateralRaise;
  }
  if (s.contains('abrazo de oso')) return ExerciseKind.selfHug;
  if (s.contains('prensa de palmas')) return ExerciseKind.prayerPress;
  if (s.contains('estiramiento cruzado de hombro')) {
    return ExerciseKind.crossShoulder;
  }
  if (s.contains('postura de cactus')) return ExerciseKind.goalpost;
  if (s.contains('encogimiento alterno de hombros')) {
    return ExerciseKind.alternatingShrug;
  }
  if (s.contains('apertura de dedos')) return ExerciseKind.fingerSpread;
  if (s.contains('circulos de antebrazos')) return ExerciseKind.forearmCircles;
  if (s.contains('toques de hombro')) return ExerciseKind.shoulderTaps;

  if (s.contains('cuello')) return ExerciseKind.neck;
  if (s.contains('hombro')) return ExerciseKind.shoulders;
  if (s.contains('muneca')) return ExerciseKind.wrists;
  if (s.contains('brazo')) return ExerciseKind.armsUp;
  if (s.contains('codo')) return ExerciseKind.curls;
  if (s.contains('pecho')) return ExerciseKind.chest;
  if (s.contains('tronco') || s.contains('lateral')) {
    return ExerciseKind.sideBend;
  }
  if (s.contains('visual')) return ExerciseKind.visual;
  return ExerciseKind.other;
}
