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

/// Visibilidad mínima para considerar válido un punto del cuerpo.
/// 0.25 es más tolerante con manos y orejas parcialmente visibles.
const double minVis = 0.25;

/// Suavizado adaptativo: poco suavizado al moverse rápido, más al estar quieto.
/// Evita que el esqueleto "vaya con retraso" en los movimientos del ejercicio.
const double smoothMin = 0.50;
const double smoothMax = 0.90;
const double smoothLowSpeed = 0.002;
const double smoothHighSpeed = 0.015;

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

// ============================================================
//  Tipos auxiliares
// ============================================================

enum ExerciseKind { neck, shoulders, wrists, visual, other }

/// Punto del cuerpo ya normalizado (0 a 1) y suavizado.
class BodyPoint {
  final double x;
  final double y;
  final double v; // visibilidad
  const BodyPoint(this.x, this.y, this.v);
}

const List<PoseLandmarkType> usedTypes = [
  PoseLandmarkType.nose,
  PoseLandmarkType.leftEye,
  PoseLandmarkType.rightEye,
  PoseLandmarkType.leftEar,
  PoseLandmarkType.rightEar,
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
];

const List<List<PoseLandmarkType>> bones = [
  [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
  [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
  [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
  [PoseLandmarkType.leftWrist, PoseLandmarkType.leftIndex],
  [PoseLandmarkType.leftWrist, PoseLandmarkType.leftPinky],
  [PoseLandmarkType.leftWrist, PoseLandmarkType.leftThumb],
  [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
  [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
  [PoseLandmarkType.rightWrist, PoseLandmarkType.rightIndex],
  [PoseLandmarkType.rightWrist, PoseLandmarkType.rightPinky],
  [PoseLandmarkType.rightWrist, PoseLandmarkType.rightThumb],
  [PoseLandmarkType.leftEar, PoseLandmarkType.rightEar],
  [PoseLandmarkType.leftEye, PoseLandmarkType.rightEye],
  [PoseLandmarkType.leftEar, PoseLandmarkType.leftShoulder],
  [PoseLandmarkType.rightEar, PoseLandmarkType.rightShoulder],
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
