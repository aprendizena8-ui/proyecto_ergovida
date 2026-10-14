import 'dart:math' as math;
import 'package:pose_detection/pose_detection.dart';

// ============================================================
//  CONSTANTES GLOBALES (OPTIMIZADAS)
// ============================================================

// ============================================================
//  AJUSTES (cambia estos valores si algo se siente muy fácil/difícil)
// ============================================================

/// true = modelo más preciso pero más lento. Si la app va con tirones,
/// ponlo en false.
/// Modelo light (más rápido que heavy)
const bool useHeavyModel = false;

/// Visibilidad mínima para considerar válido un punto del cuerpo.
const double minVis = 0.3;

/// Suavizado de los puntos (0 a 1). Más bajo = más estable pero con retraso.
/// Suavizado (más bajo = más estable, un poco más de lag)
const double smooth = 0.6;

// Cuello
const double neckTiltDeg = 12; // inclinación mínima de la cabeza (grados)
const double neckHoldSec = 10; // segundos que hay que mantener cada lado
const int neckTargetSides = 4; // lados a completar (2 por lado)

// Hombros
const double shrugRatio = 0.88; // hombros "arriba" si bajan a este % de lo normal
const double shrugRelease = 0.95; // hombros "soltados" al volver a este %
const int shrugTarget = 5; // encogimientos a completar
const double shrugMinHold = 1.0; // segundos mínimos arriba
const double circleMove = 0.05; // movimiento mínimo para contar círculos
const double circlesTargetSec = 10; // segundos de círculos

// Muñecas
const double wristMoveDeg = 30; // giro mínimo de la mano (grados)
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
];

const List<List<PoseLandmarkType>> bones = [
  [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
  [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
  [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
  [PoseLandmarkType.leftWrist, PoseLandmarkType.leftIndex],
  [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
  [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
  [PoseLandmarkType.rightWrist, PoseLandmarkType.rightIndex],
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