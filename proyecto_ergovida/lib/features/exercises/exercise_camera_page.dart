import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:pose_detection/pose_detection.dart';
import '../../data/services/ejercicio_service.dart';
import 'exercise_camera_models.dart';
import 'exercise_camera_logic.dart';
import 'exercise_camera_painter.dart';
import 'pose_detector_provider.dart';

// ============================================================
//  Página
// ============================================================

// // Cache global del PoseDetector (se crea una sola vez)
// PoseDetector? _globalPoseDetector;

// Future<PoseDetector> _getPoseDetector() async {
//   if (_globalPoseDetector != null) return _globalPoseDetector!;
//   _globalPoseDetector = useHeavyModel
//       ? await PoseDetector.create(landmarkModel: PoseLandmarkModel.heavy)
//       : await PoseDetector.create();
//   return _globalPoseDetector!;
// }

class ExerciseCameraPage extends StatefulWidget {
  final String nombre;
  final String duracion;
  final IconData icono;
  final int usuarioId;
  final int ejercicioId;

  const ExerciseCameraPage({
    super.key,
    required this.nombre,
    required this.duracion,
    required this.icono,
    required this.usuarioId,
    required this.ejercicioId,
  });

  @override
  State<ExerciseCameraPage> createState() => _ExerciseCameraPageState();
}

class _ExerciseCameraPageState extends State<ExerciseCameraPage> {
  final EjercicioService _ejercicioService = EjercicioService();

  CameraController? _cameraController;
  PoseDetector? _poseDetector;
  bool _isCameraReady = false;
  bool _isDetecting = false;

  bool _yaGuardado = false;
  bool _guardando = false;

  bool _lastPositioned = false;

  String _feedback = "Colócate frente a la cámara";
  Color _feedbackColor = Colors.orange;
  String _progressLabel = "";
  double _progress = 0;

  final Map<PoseLandmarkType, BodyPoint> _pts = {};
  Size? _imageSize;
  bool _personVisible = false;
  DateTime? _lastFrame;
  double _clock = 0;

  Timer? _timer;
  late final ExerciseKind _kind;
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
  final MotionSeries _shoulderMx = MotionSeries(1.5);
  final MotionSeries _shoulderMy = MotionSeries(1.5);

  // Muñecas
  final AngleTracker _leftHand = AngleTracker(2.0);
  final AngleTracker _rightHand = AngleTracker(2.0);

  DateTime? _lastDetection;
  // FPS dinámicos: 5 cuando no corre, 10 cuando corre
  Duration get _detectionInterval => _isRunning
      ? const Duration(milliseconds: 100)  // 10 FPS corriendo
      : const Duration(milliseconds: 100); // 10 FPS en espera

  // En Windows la vista previa va en espejo, pero los frames del stream no.
  bool get _mirrorOverlay => Platform.isWindows;

  @override
  void initState() {
    super.initState();
    _kind = kindFor(widget.nombre);
    _totalSeconds = int.parse(widget.duracion.split(" ")[0]) * 60;
    _remainingSeconds = _totalSeconds;
    if (_kind == ExerciseKind.visual) {
      _feedback = "Presiona Iniciar: te guiaremos para descansar la vista";
      _feedbackColor = Colors.blue;
    }
    _initCameraAndDetector();
  }

  // ------------------------------------------------------------
  //  Cámara y detección
  // ------------------------------------------------------------

  Future<void> _initCameraAndDetector() async {
    try {
      // Reutilizar el detector global (mucho más rápido)
      _poseDetector = await getPoseDetector();

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
        ResolutionPreset.low,
        enableAudio: false,
        // En Windows usar bgra8888 (default). En Android usar yuv420
        imageFormatGroup: Platform.isWindows
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();

      // Esperar un frame para que la cámara esté estable
      await Future.delayed(const Duration(milliseconds: 300));
      
      await _cameraController!.startImageStream(_processCameraImage);

      if (!mounted) return;
      setState(() {
        _isCameraReady = true;
        if (_kind != ExerciseKind.visual) {
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
    if (_kind == ExerciseKind.visual) return;

    // Si ya se está procesando un frame, ignóralo
    if (_isDetecting || _poseDetector == null) return;

    // Si el ejercicio ya terminó, no proceses más
    if (_finished || _yaGuardado) return;

    // Limitar a ~10 FPS para no saturar la CPU
    final ahora = DateTime.now();
    if (_lastDetection != null &&
        ahora.difference(_lastDetection!) < _detectionInterval) {
      return;
    }
    _lastDetection = ahora;

    _isDetecting = true;

    try {
      _imageSize = Size(image.width.toDouble(), image.height.toDouble());
      final sw = Stopwatch()..start();
      final poses = await _poseDetector!.detectFromCameraImage(image);
      debugPrint('inferencia: ${sw.elapsedMilliseconds} ms');
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

      // Si el ejercicio NO está corriendo y ya está "positioned",
      //    no hacemos setState cada frame (ahorra CPU)
      // Evaluar posición UNA sola vez por frame
      final positioned = _isPositioned();
      final hayQueActualizar = _isRunning || positioned != _lastPositioned;
      _lastPositioned = positioned;
      _evaluate(dt);

      if (hayQueActualizar) {
        setState(() {});
      }
    } catch (e) {
      // Silenciar errores de frames individuales
    } finally {
      _isDetecting = false;
    }
  }

  void _updatePoints(Pose pose) {
    for (final t in usedTypes) {
      final lm = pose.getLandmark(t);
      if (lm == null) {
        _pts.remove(t);
        continue;
      }
      final n = normalizedPoint(lm, _imageSize);
      final prev = _pts[t];
      if (prev == null) {
        _pts[t] = BodyPoint(n.dx, n.dy, lm.visibility);
      } else {
        _pts[t] = BodyPoint(
          prev.x + (n.dx - prev.x) * smooth,
          prev.y + (n.dy - prev.y) * smooth,
          lm.visibility,
        );
      }
    }
  }

  double get _ar {
    final s = _imageSize;
    if (s == null || s.height == 0) return 1.0;
    return s.width / s.height;
  }

  Offset _u(BodyPoint p) => Offset(p.x * _ar, p.y); // unidades de "alto de imagen"
  double _dist(BodyPoint a, BodyPoint b) => (_u(a) - _u(b)).distance;

  BodyPoint? _p(PoseLandmarkType t) {
    final p = _pts[t];
    if (p == null || p.v < minVis) return null;
    return p;
  }

  void _setFeedback(String text, Color color) {
    _feedback = text;
    _feedbackColor = color;
  }

  bool _isPositioned() {
    if (_kind == ExerciseKind.wrists) {
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

  String get _positionHint => _kind == ExerciseKind.wrists
      ? 'Levanta los antebrazos frente al pecho y aléjate hasta que se vean tus codos y manos'
      : 'Aléjate un poco: deben verse tu cabeza, tus hombros completos y tus codos';

  // ------------------------------------------------------------
  //  Evaluación por ejercicio
  // ------------------------------------------------------------

  // Contador de frames consecutivos fuera de posición
  int _framesOutOfPosition = 0;
  static const _maxFramesOutOfPosition = 15; // ~1.5 seg a 10 FPS

  void _evaluate(double dt) {
    if (_finished) return;

    if (_kind == ExerciseKind.other) {
      _setFeedback('Cuerpo detectado - Sigue las instrucciones', Colors.green);
      return;
    }

    final ok = _isPositioned();

    if (!_isRunning) {
      // Antes de iniciar: feedback suave (no cambia con cada micro-movimiento)
      _setFeedback(
        ok ? 'Te veo bien. Presiona Iniciar para comenzar' : _positionHint,
        ok ? Colors.green : Colors.orange,
      );
      _framesOutOfPosition = 0;
      return;
    }


    // Ya está corriendo: aplicar histéresis
    if (!ok) {
      _framesOutOfPosition++;
      // Solo mostramos el mensaje naranja si lleva MÁS de 1.5s fuera de posición
      if (_framesOutOfPosition > _maxFramesOutOfPosition) {
        _setFeedback(_positionHint, Colors.orange);
      }
      // Si no ha pasado el umbral, MANTENER el último mensaje
      return;
    } else {
      // Volvió a estar bien → resetear contador
      _framesOutOfPosition = 0;
    }

    switch (_kind) {
      case ExerciseKind.neck:
        _evalNeck(dt);
        break;
      case ExerciseKind.shoulders:
        _evalShoulders(dt);
        break;
      case ExerciseKind.wrists:
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

    _progressLabel = 'Lados completados: $_reps / $neckTargetSides';
    _progress = _reps / neckTargetSides;

    if (_needCenter) {
      if (absA < 8) {
        _needCenter = false;
        _setFeedback('Muy bien. Ahora inclina hacia el otro lado', Colors.green);
      } else {
        _setFeedback('Regresa la cabeza al centro', Colors.orange);
      }
      return;
    }

    if (absA >= neckTiltDeg) {
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
      if (_holdTime >= neckHoldSec) {
        _reps++;
        _lastDoneSide = side;
        _holdSide = 0;
        _holdTime = 0;
        _needCenter = true;
        _progressLabel = 'Lados completados: $_reps / $neckTargetSides';
        _progress = _reps / neckTargetSides;
        if (_reps >= neckTargetSides) {
          _finish(timeUp: false);
          return;
        }
        _setFeedback('¡Lado completado! Regresa al centro', Colors.green);
      } else {
        final left = (neckHoldSec - _holdTime).ceil();
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

      _progressLabel = 'Encogimientos: $_reps / $shrugTarget';
      _progress = (_reps / shrugTarget) * 0.5;

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
        if (ratio < shrugRatio) {
          _shrugUp = true;
          _shrugHold = 0;
          _setFeedback('Mantén los hombros arriba...', Colors.green);
        } else {
          _baseH = _baseH! * 0.98 + h * 0.02; // adapta a tu postura
          _setFeedback('Sube los hombros hacia las orejas', Colors.orange);
        }
      } else {
        _shrugHold += dt;
        if (ratio > shrugRelease) {
          _shrugUp = false;
          if (_shrugHold >= shrugMinHold) {
            _reps++;
            _progressLabel = 'Encogimientos: $_reps / $shrugTarget';
            _progress = (_reps / shrugTarget) * 0.5;
            if (_reps >= shrugTarget) {
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
      final active = math.max(_shoulderMx.range, _shoulderMy.range) >= circleMove;
      if (active) _motionSeconds += dt;

      _progressLabel =
          'Círculos: ${_motionSeconds.floor()} / ${circlesTargetSec.toInt()} s';
      _progress = 0.5 + (_motionSeconds / circlesTargetSec).clamp(0.0, 1.0) * 0.5;

      if (_motionSeconds >= circlesTargetSec) {
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

    void track(PoseLandmarkType wrist, PoseLandmarkType index, AngleTracker tr) {
      final pw = _p(wrist);
      final pi2 = _p(index);
      if (pw == null || pi2 == null) return;
      tracked = true;
      final a = _u(pw);
      final b = _u(pi2);
      tr.add(_clock, math.atan2(b.dy - a.dy, b.dx - a.dx));
      if (tr.rangeDeg >= wristMoveDeg) active = true;
    }

    track(PoseLandmarkType.leftWrist, PoseLandmarkType.leftIndex, _leftHand);
    track(PoseLandmarkType.rightWrist, PoseLandmarkType.rightIndex, _rightHand);

    if (active) _motionSeconds += dt;

    _progressLabel =
        'Movimiento: ${_motionSeconds.floor()} / ${wristTargetSec.toInt()} s';
    _progress = (_motionSeconds / wristTargetSec).clamp(0.0, 1.0);

    if (_motionSeconds >= wristTargetSec) {
      _finish(timeUp: false);
      return;
    }

    if (!tracked) {
      _setFeedback('Muestra tus manos a la cámara', Colors.orange);
    } else if (active) {
      final left = (wristTargetSec - _motionSeconds).ceil();
      _setFeedback('✅ ¡Bien! Sigue moviendo las muñecas ($left s)', Colors.green);
    } else {
      _setFeedback(
          'Gira las muñecas en círculos o flexiónalas arriba y abajo', Colors.orange);
    }
  }

  // ---------- Descanso visual (guiado por tiempo) ----------
  void _updateVisual() {
    final elapsed = _totalSeconds - _remainingSeconds;
    final pos = elapsed % visualCycleSec;
    final target = math.max(1, _totalSeconds ~/ visualCycleSec);
    _reps = elapsed ~/ visualCycleSec;
    _progressLabel = 'Ciclos completados: $_reps / $target';
    _progress = (elapsed / _totalSeconds).clamp(0.0, 1.0);

    if (pos < visualFarSec) {
      _setFeedback(
        '👀 Mira un objeto lejano, lejos de la pantalla (${visualFarSec - pos} s)',
        Colors.green,
      );
    } else {
      _setFeedback(
        '😌 Cierra los ojos y relájalos (${visualCycleSec - pos} s)',
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
      if (_kind == ExerciseKind.visual) {
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
          if (_kind == ExerciseKind.visual) _updateVisual();
        });
      }
      if (_remainingSeconds <= 0) {
        _finish(timeUp: true);
      }
    });
  }

  String _summary() {
    switch (_kind) {
      case ExerciseKind.neck:
        return 'Lados completados: $_reps de $neckTargetSides.';
      case ExerciseKind.shoulders:
        return _circlesPhase
            ? 'Encogimientos completos y ${_motionSeconds.floor()} s de círculos.'
            : 'Encogimientos: $_reps de $shrugTarget.';
      case ExerciseKind.wrists:
        return 'Movimiento detectado: ${_motionSeconds.floor()} s de ${wristTargetSec.toInt()} s.';
      case ExerciseKind.visual:
        return 'Completaste tu pausa visual.';
      case ExerciseKind.other:
        return 'Excelente trabajo.';
    }
  }

    Future<void> _finalizarYGuardarEnBackend(bool completada) async {
    // Si ya se envió el registro, evitamos duplicar la petición
    if (_yaGuardado || _guardando) return;
    _yaGuardado = true;
    _guardando = true;

    // 1️ PRIMERO cerramos la pantalla (evita el error de cámara disposed)
    if (mounted) {
      Navigator.pop(context, completada);
    }

    // 2️ DESPUÉS detenemos la cámara con un pequeño delay
    await Future.delayed(const Duration(milliseconds: 150));

    try {
      await _cameraController?.stopImageStream();
    } catch (_) {}
    try {
      await _cameraController?.dispose();
    } catch (_) {}
    _cameraController = null;
    _poseDetector = null;

    // 3️ Guardar en backend con timeout de 8 segundos
    final guardado = await _ejercicioService
        .registrarPausa(
          usuarioId: widget.usuarioId,
          ejercicioId: widget.ejercicioId,
          completada: completada,
        )
        .timeout(const Duration(seconds: 8), onTimeout: () => false);

    if (!guardado) {
      debugPrint('No se pudo guardar la pausa en el backend');
    }
  }

  void _finish({required bool timeUp, bool manual = false}) {
    _timer?.cancel();
    if (!mounted) return;

    final completada = !manual &&
        (!timeUp ||
            _kind == ExerciseKind.visual ||
            _kind == ExerciseKind.other);

    setState(() {
      _isRunning = false;
      _finished = true;
      _feedbackColor = completada ? Colors.green : Colors.orange;

      if (timeUp) {
        _feedback = '¡Tiempo terminado! ${_summary()}';
      } else {
        _progress = completada ? 1.0 : _progress;
        _feedback = completada
            ? '🎉 ¡Ejercicio completado! Excelente trabajo'
            : 'Ejercicio detenido: ${_summary()}';
      }
    });

    _finalizarYGuardarEnBackend(completada);
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
    // NO disponer del detector global
    _poseDetector = null;
    super.dispose();
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
              CustomPaint(painter: PosePainter(_pts, _mirrorOverlay)),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionPanel() {
    final steps = getInstructions(_kind);
    final tip = getTip(_kind);
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
                  onPressed: _isRunning
                      ? () {
                          _finish(timeUp: false, manual: true);
                        }
                      : () => Navigator.pop(context),
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