import 'dart:math' as math;
import 'package:pose_detection/pose_detection.dart';

// ============================================================
//  CONSTANTES GLOBALES (OPTIMIZADAS)
// ============================================================

// ============================================================
//  AJUSTES (cambia estos valores si algo se siente muy fácil/difícil)
// ============================================================

/// Modelo de landmarks. [full] es el mejor equilibrio precisión/velocidad;
/// [heavy] solo si el equipo tiene recursos de sobra.
const PoseLandmarkModel poseLandmarkModel = PoseLandmarkModel.full;

/// Resolución máxima que se pasa al detector. 640 es suficiente para
/// distinguir manos y hombros sin castigar los FPS.
const int detectionMaxDim = 640;

/// Confianza mínima del detector de personas. Algo por debajo del valor por
/// defecto para tolerar cuerpos parcialmente fuera de cuadro (ejercicios
/// sentado frente al escritorio).
const double poseDetectorConf = 0.40;

/// Confianza mínima global del modelo de landmarks. Se mantiene tolerante:
/// con cuerpos parcialmente fuera de cuadro una pose válida puede puntuar bajo,
/// y descartarla dejaría la pantalla sin esqueleto.
const double poseMinLandmarkScore = 0.35;

/// Visibilidad mínima para considerar válido un punto del cuerpo.
/// Las manos y orejas suelen tener valores más bajos que el torso.
const double minVis = 0.25;

/// Suavizado adaptativo: poco suavizado al moverse rápido, más al estar quieto.
/// Evita que el esqueleto "vaya con retraso" en los movimientos del ejercicio.
const double smoothMin = 0.50;
const double smoothMax = 0.90;
const double smoothLowSpeed = 0.002;
const double smoothHighSpeed = 0.015;

/// Salto normalizado a partir del cual se reinicia el suavizado de un punto
/// (por ejemplo, si la persona se movió de golpe o cambió el encuadre).
const double smoothResetDistance = 0.20;

// Cuello
const double neckTiltDeg = 10; // inclinación para empezar a contar
const double neckKeepDeg = 7; // inclinación mínima para mantener el conteo
const double neckCenterDeg = 6; // ángulo para considerar que volvió al centro
const double neckHoldSec = 10; // segundos que hay que mantener cada lado
const int neckTargetSides = 4; // lados a completar (2 por lado)

// Hombros
const double shrugRatio =
    0.92; // hombros "arriba" si bajan a este % de lo normal
const double shrugRelease = 0.98; // hombros "soltados" al volver a este %
const int shrugTarget = 5; // encogimientos a completar
const double shrugMinHold = 1.0; // segundos mínimos arriba
const int shrugCalibrationFrames = 25; // frames para medir la postura base
const double shrugCalibrationSec = 3.0; // tiempo máximo de calibración
const double circleMove = 0.05; // movimiento mínimo para contar círculos
const double circlesTargetSec = 10; // segundos de círculos

// Muñecas
const double wristMoveDeg = 25; // giro mínimo de la mano (grados)
const double wristMoveNorm = 0.08; // desplazamiento mínimo de la muñeca
const double wristTargetSec = 20; // segundos de movimiento

// Descanso visual
const int visualCycleSec = 30; // 20 s mirando lejos + 10 s ojos cerrados
const int visualFarSec = 20;

// Elevación de brazos
const int armsUpTargetReps = 8; // repeticiones completas
const double armsUpHeadMargin = 0.05; // altura extra sobre la cabeza
const double armsUpDownMargin = 0.15; // debajo de los hombros para cerrar rep

// Flexión de codos
const double curlBentDeg = 75; // codo claramente flexionado
const double curlExtendedDeg = 145; // codo casi extendido
const int curlTargetReps = 10;

// Apertura de pecho
const double chestSpreadMin = 1.9; // separación de manos / ancho de hombros
const double chestSpreadRelease = 1.5; // volver a esta separación para repetir
const double chestHoldSec = 5; // segundos manteniendo el pecho abierto
const int chestTargetReps = 4;

// Inclinación lateral de tronco
const double trunkKeepDeg = 7; // inclinación mínima para mantener
const double trunkCenterDeg = 6; // ángulo para considerar que volvió al centro
const double trunkHoldSec = 5; // segundos por lado
const int trunkTargetSides = 6; // lados completados

// Rotación de cuello (giro de la cabeza a cada lado)
const double neckTurnStartRatio = 0.18; // desplazamiento nariz/hombro
const double neckTurnCenterRatio = 0.08;
const double neckTurnHoldSec = 4;
const int neckTurnTargetSides = 4;
const int neckTurnCalibrationFrames = 12;

// Flexión y extensión de cuello (barbilla al pecho / mirada al techo)
const double nodDownDelta = 0.10;
const double nodUpDelta = 0.08;
const double nodCenterDelta = 0.045;
const double nodHoldSec = 2;
const int nodTargetReps = 6;
const int nodCalibrationFrames = 12;

// Círculos de brazos
const double armCircleSpreadMin = 1.35; // muñecas / ancho de hombros
const double armCircleHeightTol = 0.70;
const double armCircleMove = 0.06;
const double armCircleTargetSec = 15;

// Elevación lateral de brazos
const double lateralDownMargin = 0.18;
const double lateralUpMargin = 0.22;
const double lateralSpreadMin = 1.25;
const int lateralTargetReps = 8;

// Abrazo de oso
const double hugShoulderReach = 0.65;
const double hugHeightTol = 0.55;
const double hugHoldSec = 2;
const int hugTargetReps = 6;

// Prensa de palmas
const double prayerHandsClose = 0.38;
const double prayerHandsRelease = 0.75;
const double prayerChestMin = 0.05;
const double prayerChestMax = 0.85;
const int prayerHoldSec = 3;
const int prayerTargetReps = 6;

// Estiramiento cruzado de hombro
const double crossReach = 0.62;
const double crossHeightTol = 0.45;
const int crossHoldSec = 5;
const int crossTargetSides = 4;

// Postura de cactus (goalpost)
const double goalpostElbowSpreadMin = 1.25;
const double goalpostElbowHeightTol = 0.40;
const double goalpostWristAbove = 0.35;
const double goalpostWristAligned = 0.45;
const int goalpostHoldSec = 4;
const int goalpostTargetReps = 5;

// Encogimiento alterno de hombros
const double altShrugDelta = 0.10;
const double altShrugRelease = 0.05;
const int altShrugTargetReps = 10;
const int altShrugCalibrationFrames = 15;

// Apertura de dedos
const double fingerOpenRatio = 0.145;
const double fingerCloseRatio = 0.075;
const int fingerTargetReps = 10;

// Círculos de antebrazos
const double forearmCircleMove = 0.05;
const double forearmCircleTargetSec = 15;
const double forearmCircleMinBend = 55;
const double forearmCircleMaxBend = 135;

// Toques de hombro alternos
const double tapReach = 0.55;
const double tapRelease = 0.95;
const double tapHoldSec = 0.3;
const int tapTargetReps = 12;

// ============================================================
//  Tipos auxiliares
// ============================================================

enum ExerciseKind {
  neck,
  shoulders,
  wrists,
  visual,
  armsUp,
  curls,
  chest,
  sideBend,
  neckRotation,
  neckNod,
  armCircles,
  lateralRaise,
  selfHug,
  prayerPress,
  crossShoulder,
  goalpost,
  alternatingShrug,
  fingerSpread,
  forearmCircles,
  shoulderTaps,
  other,
}

/// Punto del cuerpo ya normalizado (0 a 1) y suavizado.
class BodyPoint {
  final double x;
  final double y;
  final double v; // visibilidad
  const BodyPoint(this.x, this.y, this.v);
}

/// Puntos que dibujamos y suavizamos. Incluye cara, hombros, brazos, manos y
/// caderas para que el esqueleto se entienda mejor; las piernas se omiten
/// porque estos ejercicios se hacen sentado y suelen quedar fuera de cuadro.
const List<PoseLandmarkType> usedTypes = [
  PoseLandmarkType.nose,
  PoseLandmarkType.leftEyeInner,
  PoseLandmarkType.leftEye,
  PoseLandmarkType.leftEyeOuter,
  PoseLandmarkType.rightEyeInner,
  PoseLandmarkType.rightEye,
  PoseLandmarkType.rightEyeOuter,
  PoseLandmarkType.leftEar,
  PoseLandmarkType.rightEar,
  PoseLandmarkType.mouthLeft,
  PoseLandmarkType.mouthRight,
  PoseLandmarkType.leftShoulder,
  PoseLandmarkType.rightShoulder,
  PoseLandmarkType.leftElbow,
  PoseLandmarkType.rightElbow,
  PoseLandmarkType.leftWrist,
  PoseLandmarkType.rightWrist,
  PoseLandmarkType.leftIndex,
  PoseLandmarkType.rightIndex,
  PoseLandmarkType.leftPinky,
  PoseLandmarkType.rightPinky,
  PoseLandmarkType.leftThumb,
  PoseLandmarkType.rightThumb,
  PoseLandmarkType.leftHip,
  PoseLandmarkType.rightHip,
];

/// Serie de valores en una ventana de tiempo (para medir movimiento).
class MotionSeries {
  final double window;
  final List<double> _t = [];
  final List<double> _v = [];
  MotionSeries(this.window);

  void add(double t, double v) {
    _t.add(t);
    _v.add(v);
    while (_t.isNotEmpty && t - _t.first > window) {
      _t.removeAt(0);
      _v.removeAt(0);
    }
  }

  double get range {
    if (_v.length < 3) return 0;
    var mn = _v.first;
    var mx = _v.first;
    for (final x in _v) {
      if (x < mn) mn = x;
      if (x > mx) mx = x;
    }
    return mx - mn;
  }

  void clear() {
    _t.clear();
    _v.clear();
  }
}

/// Sigue el ángulo de la mano (muñeca -> dedo índice) sin saltos de 360°.
class AngleTracker {
  final MotionSeries series;
  double? _last;
  double _unwrapped = 0;
  AngleTracker(double window) : series = MotionSeries(window);

  void add(double t, double angle) {
    if (_last == null) {
      _unwrapped = angle;
    } else {
      var d = angle - _last!;
      while (d > math.pi) {
        d -= 2 * math.pi;
      }
      while (d < -math.pi) {
        d += 2 * math.pi;
      }
      _unwrapped += d;
    }
    _last = angle;
    series.add(t, _unwrapped);
  }

  double get rangeDeg => series.range * 180 / math.pi;

  void clear() {
    _last = null;
    _unwrapped = 0;
    series.clear();
  }
}
