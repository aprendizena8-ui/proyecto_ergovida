import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:pose_detection/pose_detection.dart';

// ============================================================
//  AJUSTES (cambia estos valores si algo se siente muy fácil/difícil)
// ============================================================

/// true = modelo más preciso pero más lento. Si la app va con tirones,
/// ponlo en false.
const bool _useHeavyModel = true;

/// Visibilidad mínima para considerar válido un punto del cuerpo.
const double _minVis = 0.4;

/// Suavizado de los puntos (0 a 1). Más bajo = más estable pero con retraso.
const double _smooth = 0.5;

// Cuello
const double _neckTiltDeg = 15; // inclinación mínima de la cabeza (grados)
const double _neckHoldSec = 10; // segundos que hay que mantener cada lado
const int _neckTargetSides = 4; // lados a completar (2 por lado)

// Hombros
const double _shrugRatio = 0.85; // hombros "arriba" si bajan a este % de lo normal
const double _shrugRelease = 0.93; // hombros "soltados" al volver a este %
const int _shrugTarget = 5; // encogimientos a completar
const double _shrugMinHold = 1.0; // segundos mínimos arriba
const double _circleMove = 0.07; // movimiento mínimo para contar círculos
const double _circlesTargetSec = 10; // segundos de círculos

// Muñecas
const double _wristMoveDeg = 45; // giro mínimo de la mano (grados)
const double _wristTargetSec = 20; // segundos de movimiento

// Descanso visual
const int _visualCycleSec = 30; // 20 s mirando lejos + 10 s ojos cerrados
const int _visualFarSec = 20;

// ============================================================
//  Tipos auxiliares
// ============================================================

enum _Kind { neck, shoulders, wrists, visual, other }

/// Punto del cuerpo ya normalizado (0 a 1) y suavizado.
class _Pt {
  final double x;
  final double y;
  final double v; // visibilidad
  const _Pt(this.x, this.y, this.v);
}

const List<PoseLandmarkType> _usedTypes = [
  PoseLandmarkType.nose,
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

const List<List<PoseLandmarkType>> _bones = [
  [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
  [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
  [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
  [PoseLandmarkType.leftWrist, PoseLandmarkType.leftIndex],
  [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
  [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
  [PoseLandmarkType.rightWrist, PoseLandmarkType.rightIndex],
  [PoseLandmarkType.leftEar, PoseLandmarkType.nose],
  [PoseLandmarkType.nose, PoseLandmarkType.rightEar],
];

/// Serie de valores en una ventana de tiempo (para medir movimiento).
class _Series {
  final double window;
  final List<double> _t = [];
  final List<double> _v = [];
  _Series(this.window);

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
class _AngleTracker {
  final _Series series;
  double? _last;
  double _unwrapped = 0;
  _AngleTracker(double window) : series = _Series(window);

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

// ============================================================
//  Página
// ============================================================

class ExerciseCameraPage extends StatefulWidget {
  final String nombre;
  final String duracion;
  final IconData icono;

  const ExerciseCameraPage({
    super.key,
    required this.nombre,
    required this.duracion,
    required this.icono,
  });

  @override
  State<ExerciseCameraPage> createState() => _ExerciseCameraPageState();
}

class _ExerciseCameraPageState extends State<ExerciseCameraPage> {
  CameraController? _cameraController;
  PoseDetector? _poseDetector;
  bool _isCameraReady = false;
  bool _isDetecting = false;

  String _feedback = "Colócate frente a la cámara";
  Color _feedbackColor = Colors.orange;
  String _progressLabel = "";
  double _progress = 0;

  final Map<PoseLandmarkType, _Pt> _pts = {};
  Size? _imageSize;
  bool _personVisible = false;
  DateTime? _lastFrame;
  double _clock = 0;

  Timer? _timer;
  late final _Kind _kind;
  late final int _totalSeconds;
  int _remainingSeconds = 0;
  bool _isRunning = false;
  bool _finished = false;

  int _reps = 0;
  double _motionSeconds = 0;

  // Cuello
  int _holdSide = 0;
  double _holdTime = 0;
  int _lastDoneSide = 0;
  bool _needCenter = false;

  // Hombros
  final List<double> _calib = [];
  double? _baseH;
  bool _shrugUp = false;
  double _shrugHold = 0;
  bool _circlesPhase = false;
  final _Series _shoulderMx = _Series(1.5);
  final _Series _shoulderMy = _Series(1.5);

  // Muñecas
  final _AngleTracker _leftHand = _AngleTracker(2.0);
  final _AngleTracker _rightHand = _AngleTracker(2.0);

  // En Windows la vista previa va en espejo, pero los frames del stream no.
  bool get _mirrorOverlay => Platform.isWindows;

  @override
  void initState() {
    super.initState();
    _kind = _kindFor(widget.nombre);
    _totalSeconds = int.parse(widget.duracion.split(" ")[0]) * 60;
    _remainingSeconds = _totalSeconds;
    if (_kind == _Kind.visual) {
      _feedback = "Presiona Iniciar: te guiaremos para descansar la vista";
      _feedbackColor = Colors.blue;
    }
    _initCameraAndDetector();
  }

  _Kind _kindFor(String nombre) {
    final s = nombre.toLowerCase();
    if (s.contains('cuello')) return _Kind.neck;
    if (s.contains('hombro')) return _Kind.shoulders;
    if (s.contains('muñeca') || s.contains('muneca')) return _Kind.wrists;
    if (s.contains('visual')) return _Kind.visual;
    return _Kind.other;
  }

  // ------------------------------------------------------------
  //  Cámara y detección
  // ------------------------------------------------------------

  Future<void> _initCameraAndDetector() async {
    try {
      _poseDetector = _useHeavyModel
          ? await PoseDetector.create(landmarkModel: PoseLandmarkModel.heavy)
          : await PoseDetector.create();

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          _feedback = "No se encontró ninguna cámara";
          _feedbackColor = Colors.red;
        });
        return;
      }

      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();
      await _cameraController!.startImageStream(_processCameraImage);

      if (!mounted) return;
      setState(() {
        _isCameraReady = true;
        if (_kind != _Kind.visual) {
          _feedback = "Cámara lista. Colócate frente a ella";
          _feedbackColor = Colors.green;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _feedback = "Error al iniciar cámara: $e";
        _feedbackColor = Colors.red;
      });
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    // El descanso visual no necesita detectar el cuerpo.
    if (_kind == _Kind.visual) return;
    if (_isDetecting || _poseDetector == null) return;
    _isDetecting = true;

    try {
      _imageSize = Size(image.width.toDouble(), image.height.toDouble());
      final poses = await _poseDetector!.detectFromCameraImage(image);
      if (!mounted) return;

      final now = DateTime.now();
      final raw = _lastFrame == null
          ? 0.0
          : now.difference(_lastFrame!).inMilliseconds / 1000.0;
      final dt = raw > 0.5 ? 0.5 : raw;
      _lastFrame = now;

      if (poses.isEmpty) {
        _personVisible = false;
        _pts.clear();
        if (!_finished) {
          _setFeedback('No te detecto. Colócate frente a la cámara', Colors.orange);
        }
        setState(() {});
        return;
      }

      _clock += dt;
      _personVisible = true;
      _updatePoints(poses.first);
      _evaluate(dt);
      setState(() {});
    } catch (e) {
      // Silenciar errores de frames individuales
    } finally {
      _isDetecting = false;
    }
  }

  void _updatePoints(Pose pose) {
    for (final t in _usedTypes) {
      final lm = pose.getLandmark(t);
      if (lm == null) {
        _pts.remove(t);
        continue;
      }
      final n = normalizedPoint(lm, _imageSize);
      final prev = _pts[t];
      if (prev == null) {
        _pts[t] = _Pt(n.dx, n.dy, lm.visibility);
      } else {
        _pts[t] = _Pt(
          prev.x + (n.dx - prev.x) * _smooth,
          prev.y + (n.dy - prev.y) * _smooth,
          lm.visibility,
        );
      }
    }
  }

  // ------------------------------------------------------------
  //  Utilidades de geometría
  // ------------------------------------------------------------

  double get _ar {
    final s = _imageSize;
    if (s == null || s.height == 0) return 1.0;
    return s.width / s.height;
  }

  Offset _u(_Pt p) => Offset(p.x * _ar, p.y); // unidades de "alto de imagen"
  double _dist(_Pt a, _Pt b) => (_u(a) - _u(b)).distance;

  _Pt? _p(PoseLandmarkType t) {
    final p = _pts[t];
    if (p == null || p.v < _minVis) return null;
    return p;
  }

  void _setFeedback(String text, Color color) {
    _feedback = text;
    _feedbackColor = color;
  }

  bool _isPositioned() {
    if (_kind == _Kind.wrists) {
      return _p(PoseLandmarkType.leftWrist) != null &&
          _p(PoseLandmarkType.rightWrist) != null &&
          _p(PoseLandmarkType.leftElbow) != null &&
          _p(PoseLandmarkType.rightElbow) != null;
    }
    final ls = _p(PoseLandmarkType.leftShoulder);
    final rs = _p(PoseLandmarkType.rightShoulder);
    final le = _p(PoseLandmarkType.leftEar);
    final re = _p(PoseLandmarkType.rightEar);
    if (ls == null || rs == null || le == null || re == null) return false;
    // Los hombros deben verse claramente más anchos que la cabeza.
    return _dist(ls, rs) >= _dist(le, re) * 1.5;
  }

  String get _positionHint => _kind == _Kind.wrists
      ? 'Levanta los antebrazos frente al pecho y aléjate hasta que se vean tus codos y manos'
      : 'Aléjate un poco: deben verse tu cabeza, tus hombros completos y tus codos';

  // ------------------------------------------------------------
  //  Evaluación por ejercicio
  // ------------------------------------------------------------

  void _evaluate(double dt) {
    if (_finished) return;

    if (_kind == _Kind.other) {
      _setFeedback('Cuerpo detectado - Sigue las instrucciones', Colors.green);
      return;
    }

    final ok = _isPositioned();

    if (!_isRunning) {
      _setFeedback(
        ok ? 'Te veo bien. Presiona Iniciar para comenzar' : _positionHint,
        ok ? Colors.green : Colors.orange,
      );
      return;
    }

    if (!ok) {
      _setFeedback(_positionHint, Colors.orange);
      return;
    }

    switch (_kind) {
      case _Kind.neck:
        _evalNeck(dt);
        break;
      case _Kind.shoulders:
        _evalShoulders(dt);
        break;
      case _Kind.wrists:
        _evalWrists(dt);
        break;
      default:
        break;
    }
  }

  // ---------- Cuello ----------
  void _evalNeck(double dt) {
    final l = _p(PoseLandmarkType.leftEar)!;
    final r = _p(PoseLandmarkType.rightEar)!;
    final a = l.x <= r.x ? l : r;
    final b = l.x <= r.x ? r : l;
    final ua = _u(a);
    final ub = _u(b);

    // Ángulo de la línea entre las orejas respecto a la horizontal.
    final angle = math.atan2(ub.dy - ua.dy, ub.dx - ua.dx) * 180 / math.pi;
    final absA = angle.abs();
    final side = angle > 0 ? 1 : -1;

    _progressLabel = 'Lados completados: $_reps / $_neckTargetSides';
    _progress = _reps / _neckTargetSides;

    if (_needCenter) {
      if (absA < 8) {
        _needCenter = false;
        _setFeedback('Muy bien. Ahora inclina hacia el otro lado', Colors.green);
      } else {
        _setFeedback('Regresa la cabeza al centro', Colors.orange);
      }
      return;
    }

    if (absA >= _neckTiltDeg) {
      if (absA > 50) {
        _setFeedback('Inclina con suavidad, no fuerces el cuello', Colors.orange);
        return;
      }
      if (side == _lastDoneSide) {
        _holdTime = 0;
        _holdSide = 0;
        _setFeedback('Ahora inclina hacia el otro lado', Colors.orange);
        return;
      }
      if (_holdSide != side) {
        _holdSide = side;
        _holdTime = 0;
      }
      _holdTime += dt;
      if (_holdTime >= _neckHoldSec) {
        _reps++;
        _lastDoneSide = side;
        _holdSide = 0;
        _holdTime = 0;
        _needCenter = true;
        _progressLabel = 'Lados completados: $_reps / $_neckTargetSides';
        _progress = _reps / _neckTargetSides;
        if (_reps >= _neckTargetSides) {
          _finish(timeUp: false);
          return;
        }
        _setFeedback('¡Lado completado! Regresa al centro', Colors.green);
      } else {
        final left = (_neckHoldSec - _holdTime).ceil();
        _setFeedback('✅ Buen estiramiento. Mantén $left s', Colors.green);
      }
    } else {
      _holdSide = 0;
      _holdTime = 0;
      _setFeedback('Inclina suavemente la cabeza hacia un lado', Colors.orange);
    }
  }

  // ---------- Hombros ----------
  void _evalShoulders(double dt) {
    final ls = _p(PoseLandmarkType.leftShoulder)!;
    final rs = _p(PoseLandmarkType.rightShoulder)!;
    final le = _p(PoseLandmarkType.leftEar)!;
    final re = _p(PoseLandmarkType.rightEar)!;

    final sw = _dist(ls, rs);
    if (sw <= 0) return;

    if (!_circlesPhase) {
      // Fase 1: encogimientos (subir los hombros hacia las orejas)
      final shY = (ls.y + rs.y) / 2;
      final earY = (le.y + re.y) / 2;
      final h = (shY - earY) / sw; // altura relativa hombros-orejas

      _progressLabel = 'Encogimientos: $_reps / $_shrugTarget';
      _progress = (_reps / _shrugTarget) * 0.5;

      if (_baseH == null) {
        _calib.add(h);
        _setFeedback(
            'Relaja los hombros y quédate quieto... midiendo tu postura',
            Colors.orange);
        if (_calib.length >= 20) {
          _baseH = _calib.reduce((a, b) => a + b) / _calib.length;
        }
        return;
      }

      final ratio = h / _baseH!;
      if (!_shrugUp) {
        if (ratio < _shrugRatio) {
          _shrugUp = true;
          _shrugHold = 0;
          _setFeedback('Mantén los hombros arriba...', Colors.green);
        } else {
          _baseH = _baseH! * 0.98 + h * 0.02; // adapta a tu postura
          _setFeedback('Sube los hombros hacia las orejas', Colors.orange);
        }
      } else {
        _shrugHold += dt;
        if (ratio > _shrugRelease) {
          _shrugUp = false;
          if (_shrugHold >= _shrugMinHold) {
            _reps++;
            _progressLabel = 'Encogimientos: $_reps / $_shrugTarget';
            _progress = (_reps / _shrugTarget) * 0.5;
            if (_reps >= _shrugTarget) {
              _circlesPhase = true;
              _motionSeconds = 0;
              _shoulderMx.clear();
              _shoulderMy.clear();
              _setFeedback(
                  '¡Bien! Ahora haz círculos grandes con los hombros', Colors.green);
            } else {
              _setFeedback('✅ Repetición completada. Otra vez', Colors.green);
            }
          } else {
            _setFeedback(
                'Mantén los hombros arriba un poco más (1-2 s)', Colors.orange);
          }
        } else {
          _setFeedback('Mantén arriba y luego suelta', Colors.green);
        }
      }
    } else {
      // Fase 2: círculos con los hombros (se detecta que haya movimiento)
      final mx = ((ls.x + rs.x) / 2) * _ar / sw;
      final my = ((ls.y + rs.y) / 2) / sw;
      _shoulderMx.add(_clock, mx);
      _shoulderMy.add(_clock, my);
      final active = math.max(_shoulderMx.range, _shoulderMy.range) >= _circleMove;
      if (active) _motionSeconds += dt;

      _progressLabel =
          'Círculos: ${_motionSeconds.floor()} / ${_circlesTargetSec.toInt()} s';
      _progress = 0.5 + (_motionSeconds / _circlesTargetSec).clamp(0.0, 1.0) * 0.5;

      if (_motionSeconds >= _circlesTargetSec) {
        _finish(timeUp: false);
        return;
      }
      _setFeedback(
        active
            ? '✅ ¡Muy bien! Sigue haciendo círculos con los hombros'
            : 'Haz círculos grandes con los hombros, hacia adelante y hacia atrás',
        active ? Colors.green : Colors.orange,
      );
    }
  }

  // ---------- Muñecas ----------
  void _evalWrists(double dt) {
    var tracked = false;
    var active = false;

    void track(PoseLandmarkType wrist, PoseLandmarkType index, _AngleTracker tr) {
      final pw = _p(wrist);
      final pi2 = _p(index);
      if (pw == null || pi2 == null) return;
      tracked = true;
      final a = _u(pw);
      final b = _u(pi2);
      tr.add(_clock, math.atan2(b.dy - a.dy, b.dx - a.dx));
      if (tr.rangeDeg >= _wristMoveDeg) active = true;
    }

    track(PoseLandmarkType.leftWrist, PoseLandmarkType.leftIndex, _leftHand);
    track(PoseLandmarkType.rightWrist, PoseLandmarkType.rightIndex, _rightHand);

    if (active) _motionSeconds += dt;

    _progressLabel =
        'Movimiento: ${_motionSeconds.floor()} / ${_wristTargetSec.toInt()} s';
    _progress = (_motionSeconds / _wristTargetSec).clamp(0.0, 1.0);

    if (_motionSeconds >= _wristTargetSec) {
      _finish(timeUp: false);
      return;
    }

    if (!tracked) {
      _setFeedback('Muestra tus manos a la cámara', Colors.orange);
    } else if (active) {
      final left = (_wristTargetSec - _motionSeconds).ceil();
      _setFeedback('✅ ¡Bien! Sigue moviendo las muñecas ($left s)', Colors.green);
    } else {
      _setFeedback(
          'Gira las muñecas en círculos o flexiónalas arriba y abajo', Colors.orange);
    }
  }

  // ---------- Descanso visual (guiado por tiempo) ----------
  void _updateVisual() {
    final elapsed = _totalSeconds - _remainingSeconds;
    final pos = elapsed % _visualCycleSec;
    final target = math.max(1, _totalSeconds ~/ _visualCycleSec);
    _reps = elapsed ~/ _visualCycleSec;
    _progressLabel = 'Ciclos completados: $_reps / $target';
    _progress = (elapsed / _totalSeconds).clamp(0.0, 1.0);

    if (pos < _visualFarSec) {
      _setFeedback(
        '👀 Mira un objeto lejano, lejos de la pantalla (${_visualFarSec - pos} s)',
        Colors.green,
      );
    } else {
      _setFeedback(
        '😌 Cierra los ojos y relájalos (${_visualCycleSec - pos} s)',
        Colors.blue,
      );
    }
  }

  // ------------------------------------------------------------
  //  Temporizador y control del ejercicio
  // ------------------------------------------------------------

  void _resetProgress() {
    _remainingSeconds = _totalSeconds;
    _reps = 0;
    _motionSeconds = 0;
    _holdSide = 0;
    _holdTime = 0;
    _lastDoneSide = 0;
    _needCenter = false;
    _calib.clear();
    _baseH = null;
    _shrugUp = false;
    _shrugHold = 0;
    _circlesPhase = false;
    _shoulderMx.clear();
    _shoulderMy.clear();
    _leftHand.clear();
    _rightHand.clear();
    _progress = 0;
    _progressLabel = '';
  }

  void _startTimer() {
    if (_isRunning) return;
    setState(() {
      _resetProgress();
      _isRunning = true;
      _finished = false;
      if (_kind == _Kind.visual) {
        _updateVisual();
      } else {
        _setFeedback('¡Vamos! Empieza el ejercicio', Colors.green);
      }
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
          if (_kind == _Kind.visual) _updateVisual();
        });
      }
      if (_remainingSeconds <= 0) {
        _finish(timeUp: true);
      }
    });
  }

  String _summary() {
    switch (_kind) {
      case _Kind.neck:
        return 'Lados completados: $_reps de $_neckTargetSides.';
      case _Kind.shoulders:
        return _circlesPhase
            ? 'Encogimientos completos y ${_motionSeconds.floor()} s de círculos.'
            : 'Encogimientos: $_reps de $_shrugTarget.';
      case _Kind.wrists:
        return 'Movimiento detectado: ${_motionSeconds.floor()} s de ${_wristTargetSec.toInt()} s.';
      case _Kind.visual:
        return 'Completaste tu pausa visual.';
      case _Kind.other:
        return 'Excelente trabajo.';
    }
  }

  void _finish({required bool timeUp}) {
    _timer?.cancel();
    if (!mounted) return;
    setState(() {
      _isRunning = false;
      _finished = true;
      _feedbackColor = Colors.green;
      if (timeUp) {
        _feedback = '¡Tiempo terminado! ${_summary()}';
      } else {
        _progress = 1.0;
        _feedback = '🎉 ¡Ejercicio completado! Excelente trabajo';
      }
    });
  }

  String get _formattedTime {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  void dispose() {
    _timer?.cancel();
    try {
      _cameraController?.dispose();
    } catch (_) {}
    _poseDetector?.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  //  Instrucciones
  // ------------------------------------------------------------

  List<String> _instructions() {
    switch (_kind) {
      case _Kind.neck:
        return [
          "Siéntate derecho con la espalda recta, a una distancia donde se vean tus hombros.",
          "Inclina suavemente la cabeza hacia un lado, como acercando la oreja al hombro.",
          "Mantén la posición unos segundos sin levantar el hombro.",
          "Vuelve al centro y repite hacia el otro lado.",
          "Respira profundo durante todo el ejercicio.",
        ];
      case _Kind.shoulders:
        return [
          "Siéntate derecho, relajado, con los hombros y codos a la vista.",
          "Quédate quieto 2 segundos mientras medimos tu postura.",
          "Sube ambos hombros hacia las orejas y mantén 1-2 segundos.",
          "Suelta de golpe y repite 5 veces.",
          "Luego haz círculos grandes con los hombros, adelante y atrás.",
        ];
      case _Kind.wrists:
        return [
          "Levanta los antebrazos frente al pecho, con los codos doblados.",
          "Mantén las manos abiertas y a la vista de la cámara.",
          "Gira las muñecas en círculos hacia afuera y luego hacia adentro.",
          "También puedes flexionarlas hacia arriba y hacia abajo.",
          "Sacude las manos suavemente al terminar.",
        ];
      case _Kind.visual:
        return [
          "Aparta la mirada de la pantalla.",
          "Durante 20 segundos enfoca un objeto lejano (mínimo 6 metros).",
          "Luego cierra los ojos y relájalos durante 10 segundos.",
          "Parpadea varias veces de forma consciente.",
          "El ciclo se repite hasta que termine el tiempo.",
        ];
      case _Kind.other:
        return ["Sigue las indicaciones del ejercicio."];
    }
  }

  String _tip() {
    switch (_kind) {
      case _Kind.neck:
      case _Kind.shoulders:
        return "Consejo: aléjate de la cámara hasta que se vean tu cabeza, hombros y codos. Con buena luz la detección mejora mucho.";
      case _Kind.wrists:
        return "Consejo: la cámara debe ver tus codos y manos. Mantén las manos abiertas y de frente.";
      case _Kind.visual:
        return "Nota: la cámara no puede comprobar si miras lejos o si cierras los ojos. Esta rutina te guía con el temporizador.";
      case _Kind.other:
        return "";
    }
  }

  // ------------------------------------------------------------
  //  Interfaz
  // ------------------------------------------------------------

  Widget _buildCameraArea() {
    if (!(_isCameraReady && _cameraController != null)) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.green),
      );
    }
    return Center(
      child: AspectRatio(
        aspectRatio: _cameraController!.value.aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(_cameraController!),
            if (_personVisible && _pts.isNotEmpty)
              CustomPaint(painter: _PosePainter(_pts, _mirrorOverlay)),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionPanel() {
    final steps = _instructions();
    final tip = _tip();
    return Container(
      color: const Color(0xFF151515),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(widget.icono, color: Colors.greenAccent, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.nombre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (_progressLabel.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                _progressLabel,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _progress.clamp(0.0, 1.0),
                  minHeight: 10,
                  backgroundColor: Colors.white12,
                  color: Colors.greenAccent,
                ),
              ),
            ],
            const SizedBox(height: 20),
            const Text(
              "Cómo hacerlo",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ...steps.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 11,
                          backgroundColor: Colors.green,
                          child: Text(
                            "${e.key + 1}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            e.value,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            if (tip.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  tip,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.nombre),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Mensaje en vivo
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: _feedbackColor.withValues(alpha: 0.9),
            child: Text(
              _feedback,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Cámara + instrucciones
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 900;
                if (wide) {
                  return Row(
                    children: [
                      Expanded(child: _buildCameraArea()),
                      SizedBox(width: 380, child: _buildInstructionPanel()),
                    ],
                  );
                }
                return Column(
                  children: [
                    Expanded(flex: 3, child: _buildCameraArea()),
                    Expanded(flex: 2, child: _buildInstructionPanel()),
                  ],
                );
              },
            ),
          ),

          // Controles (compactos para que no se corten)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: Colors.black87,
            child: Row(
              children: [
                Text(
                  _formattedTime,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _isRunning ? null : _startTimer,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(_finished ? "Repetir" : "Iniciar"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    _timer?.cancel();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.stop),
                  label: const Text("Finalizar"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Devuelve la posición del punto entre 0 y 1.
/// Si la librería entrega píxeles (valores > 1.5), los divide por el tamaño
/// del frame; si ya vienen normalizados, los deja igual.
Offset normalizedPoint(PoseLandmark lm, Size? imageSize) {
  double x = lm.x;
  double y = lm.y;
  if (imageSize != null && (x > 1.5 || y > 1.5)) {
    x = x / imageSize.width;
    y = y / imageSize.height;
  }
  return Offset(x, y);
}

// Dibuja el esqueleto de la parte superior del cuerpo
class _PosePainter extends CustomPainter {
  final Map<PoseLandmarkType, _Pt> pts;
  final bool mirror;

  _PosePainter(this.pts, this.mirror);

  Offset _o(_Pt p, Size size) {
    final x = mirror ? 1 - p.x : p.x;
    return Offset(x * size.width, p.y * size.height);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.lightGreenAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final dot = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.fill;

    for (final bone in _bones) {
      final a = pts[bone[0]];
      final b = pts[bone[1]];
      if (a == null || b == null || a.v < _minVis || b.v < _minVis) continue;
      canvas.drawLine(_o(a, size), _o(b, size), line);
    }
    for (final p in pts.values) {
      if (p.v >= _minVis) {
        canvas.drawCircle(_o(p, size), 6, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}