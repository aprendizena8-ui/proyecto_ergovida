import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:pose_detection/pose_detection.dart';
import '../../core/constants/activity_types.dart';
import '../../core/theme/app_responsive.dart';
import '../../data/services/ejercicio_service.dart';
import 'exercise_avatar.dart';
import 'exercise_camera_models.dart';
import 'exercise_camera_logic.dart';
import 'exercise_camera_painter.dart';
import 'pose_detector_provider.dart';

// ============================================================
//  Página
// ============================================================

class ExerciseCameraPage extends StatefulWidget {
  final String nombre;
  final String duracion;
  final IconData icono;
  final ExerciseKind? kind;
  final int usuarioId;
  final int ejercicioId;

  const ExerciseCameraPage({
    super.key,
    required this.nombre,
    required this.duracion,
    required this.icono,
    this.kind,
    required this.usuarioId,
    required this.ejercicioId,
  });

  @override
  State<ExerciseCameraPage> createState() => _ExerciseCameraPageState();
}

class _ExerciseCameraPageState extends State<ExerciseCameraPage> {
  final EjercicioService _ejercicioService = EjercicioService();

  CameraController? _cameraController;
  CameraDescription? _cameraDescription;
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
  int _poseHits = 0;
  int _poseMisses = 0;
  Offset? _trackedCenter;
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
  double _calibStartClock = 0;
  bool _shrugUp = false;
  double _shrugHold = 0;
  bool _circlesPhase = false;
  final MotionSeries _shoulderMx = MotionSeries(1.5);
  final MotionSeries _shoulderMy = MotionSeries(1.5);

  // Muñecas
  final AngleTracker _leftHand = AngleTracker(2.0);
  final AngleTracker _rightHand = AngleTracker(2.0);
  final MotionSeries _leftWristX = MotionSeries(2.0);
  final MotionSeries _leftWristY = MotionSeries(2.0);
  final MotionSeries _rightWristX = MotionSeries(2.0);
  final MotionSeries _rightWristY = MotionSeries(2.0);

  // Elevación de brazos
  bool _armsRaised = false;

  // Flexión de codos
  bool _curlBent = false;

  // Apertura de pecho
  bool _chestOpen = false;
  bool _chestRest = false;
  double _chestHold = 0;

  // Inclinación lateral de tronco
  final List<double> _trunkCalib = [];
  double? _baseTrunkAngle;

  // Rotación de cuello
  final List<double> _neckTurnCalib = [];
  double? _baseNeckTurn;
  int _neckTurnSide = 0;
  int _lastNeckTurnSide = 0;
  double _neckTurnHold = 0;
  bool _neckTurnNeedCenter = false;

  // Flexión y extensión de cuello
  final List<double> _nodCalib = [];
  double? _baseNod;
  int _nodState = 0; // 1 = barbilla abajo, 2 = mirada arriba
  double _nodHold = 0;
  bool _nodNeedCenter = false;

  // Círculos de brazos
  final MotionSeries _armCircleX = MotionSeries(2.0);
  final MotionSeries _armCircleY = MotionSeries(2.0);

  // Elevación lateral de brazos
  bool _lateralRaised = false;

  // Abrazo de oso
  bool _hugHolding = false;
  double _hugHold = 0;
  bool _hugRest = false;

  // Prensa de palmas
  bool _prayerHolding = false;
  double _prayerHold = 0;
  bool _prayerRest = false;

  // Estiramiento cruzado de hombro
  int _crossSide = 0;
  int _lastCrossSide = 0;
  double _crossHold = 0;
  bool _crossNeedCenter = false;

  // Postura de cactus
  bool _goalpostHolding = false;
  double _goalpostHold = 0;
  bool _goalpostRest = false;

  // Encogimiento alterno de hombros
  final List<double> _altShrugCalib = [];
  double? _baseAltShrug;
  int _altShrugSide = 0;
  int _lastAltShrugSide = 0;
  double _altShrugHold = 0;
  bool _altShrugNeedCenter = false;

  // Apertura de dedos
  bool _handsOpen = false;

  // Círculos de antebrazos
  final MotionSeries _forearmCircleX = MotionSeries(2.0);
  final MotionSeries _forearmCircleY = MotionSeries(2.0);

  // Toques de hombro alternos
  int _tapSide = 0;
  int _lastTapSide = 0;
  double _tapHold = 0;
  bool _tapNeedRelease = false;

  DateTime? _lastDetection;
  // Más muestras cuando el ejercicio está activo; menos en espera para ahorrar
  // CPU. El guard de [_isDetecting] evita acumular frames sin procesar.
  Duration get _detectionInterval => _isRunning
      ? const Duration(milliseconds: 45) // hasta ~20 FPS corriendo
      : const Duration(milliseconds: 90); // ~11 FPS en espera

  // En Windows la vista previa va en espejo, pero los frames del stream no.
  // En móvil depende del fabricante, así que el usuario puede corregirlo.
  late bool _mirrorOverlay;
  bool _showSkeleton = true;

  /// El avatar solo tiene sentido en ejercicios cuya cámara identifica el
  /// movimiento. El descanso visual y los ejercicios genéricos no lo usan.
  bool get _showsAvatar =>
      _kind != ExerciseKind.visual && _kind != ExerciseKind.other;

  @override
  void initState() {
    super.initState();
    _mirrorOverlay = Platform.isWindows;
    _kind = widget.kind ?? kindFor(widget.nombre);
    final minutos =
        int.tryParse(widget.duracion.split(RegExp(r'\s+')).first) ?? 4;
    // Ningún ejercicio dura menos de 4 minutos: los tiempos sembrados
    // originalmente eran demasiado cortos para completar el movimiento.
    _totalSeconds = minutos.clamp(4, 30) * 60;
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
      _cameraDescription = camera;

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
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
          _feedback = "Cámara lista. Cargando detector de movimiento...";
          _feedbackColor = Colors.green;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _feedback = "Error al iniciar cámara: $e";
        _feedbackColor = Colors.red;
      });
      return;
    }

    if (_kind == ExerciseKind.visual) return;

    try {
      // Reutilizar el detector global (mucho más rápido)
      _poseDetector = await getPoseDetector();
      if (!mounted) return;
      setState(() {
        if (!_isRunning) {
          _feedback = "Detector listo. Colócate frente a la cámara";
          _feedbackColor = Colors.green;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _feedback = "No se pudo cargar el detector de movimiento: $e";
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

    // Limitar la frecuencia de análisis para no saturar la CPU
    final ahora = DateTime.now();
    if (_lastDetection != null &&
        ahora.difference(_lastDetection!) < _detectionInterval) {
      return;
    }
    _lastDetection = ahora;

    _isDetecting = true;

    try {
      final rotation = _rotationForImage(image);
      // Tamaño de respaldo mientras llega la primera detección. Después se
      // reemplaza por el tamaño real que reporta cada [Pose].
      _imageSize = detectionSize(
        width: image.width,
        height: image.height,
        rotation: rotation,
        maxDim: detectionMaxDim,
      );

      final poses = await _poseDetector!.detectFromCameraImage(
        image,
        rotation: rotation,
        maxDim: detectionMaxDim,
        // camera_desktop entrega BGRA; el paquete asume RGBA salvo macOS.
        isBgra: Platform.isWindows,
      );
      if (!mounted) return;

      final now = DateTime.now();
      final raw = _lastFrame == null
          ? 0.0
          : now.difference(_lastFrame!).inMilliseconds / 1000.0;
      final dt = raw > 0.3 ? 0.3 : raw;
      _lastFrame = now;

      // Un frame aislado sin persona no debe borrar el esqueleto: el modelo
      // duda cuando la persona se mueve rápido o hay poca luz. Confirmamos
      // varias detecciones seguidas antes de mostrarlo u ocultarlo.
      final conLandmarks = poses.where((p) => p.hasLandmarks).toList();
      if (conLandmarks.isEmpty) {
        _poseMisses++;
        _poseHits = 0;
        if (_poseMisses >= poseLostFrames && _personVisible) {
          _personVisible = false;
          _pts.clear();
          _trackedCenter = null;
          if (!_finished) {
            _setFeedback(
              'No te detecto. Colócate frente a la cámara',
              Colors.orange,
            );
          }
          setState(() {});
        } else if (poses.isNotEmpty && !_finished) {
          _setFeedback(
            'Te veo, pero no distingo bien tu postura. Acércate un poco o mejora la luz',
            Colors.orange,
          );
          if (_isRunning) setState(() {});
        } else if (_poseMisses == 2 && !_finished && !_personVisible) {
          _setFeedback(
            'Buscando tu cuerpo: aléjate un poco del encuadre y busca buena luz',
            Colors.orange,
          );
          setState(() {});
        }
        return;
      }

      _poseMisses = 0;
      _poseHits++;
      if (!_personVisible && _poseHits < poseConfirmFrames) return;

      final pose = _bestPose(conLandmarks);
      // El tamaño real del frame analizado es la fuente de verdad para
      // normalizar los landmarks y ajustar el aspecto del overlay.
      if (pose.imageWidth > 0 && pose.imageHeight > 0) {
        _imageSize = Size(
          pose.imageWidth.toDouble(),
          pose.imageHeight.toDouble(),
        );
      }

      _clock += dt;
      _personVisible = true;
      final imageSize = _imageSize;
      if (imageSize != null) {
        _updatePoints(pose, imageSize);
      }

      // Evaluar posición UNA sola vez por frame. Si no está corriendo y la
      // posición no cambió, evitamos reconstruir la interfaz.
      final positioned = _isPositioned();
      final cambioDePosicion = positioned != _lastPositioned;
      final hayQueActualizar = _isRunning || cambioDePosicion;
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

  /// Rotación necesaria para que el modelo vea el frame derecho en móvil.
  /// En escritorio los frames ya vienen derechos y no se rota nada.
  CameraFrameRotation? _rotationForImage(CameraImage image) {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return null;
    }

    final description = _cameraDescription;
    final controller = _cameraController;
    if (description == null || controller == null) return null;

    return rotationForFrame(
      width: image.width,
      height: image.height,
      sensorOrientation: description.sensorOrientation,
      isFrontCamera: description.lensDirection == CameraLensDirection.front,
      deviceOrientation: controller.value.deviceOrientation,
    );
  }

  /// Elige a la persona principal. Además del tamaño, premia la continuidad
  /// con el frame anterior para que el esqueleto no «salte» de una persona a
  /// otra cuando dos cuerpos se acercan o se cruzan.
  Pose _bestPose(List<Pose> poses) {
    var best = poses.first;
    var bestScore = -1.0;

    for (final pose in poses) {
      final size = math.sqrt(_poseArea(pose));
      if (size <= 0) continue;

      final center = Offset(
        pose.boundingBox.center.x /
            (pose.imageWidth == 0 ? 1 : pose.imageWidth),
        pose.boundingBox.center.y /
            (pose.imageHeight == 0 ? 1 : pose.imageHeight),
      );
      var score = size;
      final last = _trackedCenter;
      if (last != null) {
        final distance = (center - last).distance;
        score /= 1.0 + distance * 14;
      }
      if (score > bestScore) {
        bestScore = score;
        best = pose;
      }
    }

    _trackedCenter = Offset(
      best.boundingBox.center.x / (best.imageWidth == 0 ? 1 : best.imageWidth),
      best.boundingBox.center.y /
          (best.imageHeight == 0 ? 1 : best.imageHeight),
    );
    return best;
  }

  double _poseArea(Pose pose) {
    return pose.boundingBox.width * pose.boundingBox.height;
  }

  void _updatePoints(Pose pose, Size imageSize) {
    for (final t in usedTypes) {
      final lm = pose.getLandmark(t);
      if (lm == null) {
        _pts.remove(t);
        continue;
      }
      final n = normalizedPoint(lm, imageSize);
      final prev = _pts[t];
      if (prev == null) {
        _pts[t] = BodyPoint(n.dx, n.dy, lm.visibility);
        continue;
      }

      final dx = n.dx - prev.x;
      final dy = n.dy - prev.y;
      final speed = math.sqrt(dx * dx + dy * dy);

      // Un salto grande suele indicar que cambió la persona o el encuadre.
      // Reiniciar el punto evita que el esqueleto quede "arrastrándose".
      if (speed > smoothResetDistance) {
        _pts[t] = BodyPoint(n.dx, n.dy, lm.visibility);
        continue;
      }

      final t01 =
          ((speed - smoothLowSpeed) / (smoothHighSpeed - smoothLowSpeed)).clamp(
            0.0,
            1.0,
          );
      var alpha = smoothMin + (smoothMax - smoothMin) * t01;
      // Si el modelo duda de este punto (o del anterior), damos más peso a la
      // medición nueva: así no se queda "pegado" un miembro poco visible.
      final confidence = math.min(lm.visibility, prev.v).clamp(0.0, 1.0);
      alpha = (alpha * (0.65 + 0.35 * confidence)).clamp(0.0, 1.0);

      _pts[t] = BodyPoint(
        prev.x + dx * alpha,
        prev.y + dy * alpha,
        lm.visibility,
      );
    }
  }

  double get _ar {
    final s = _imageSize;
    if (s == null || s.height == 0) return 1.0;
    return s.width / s.height;
  }

  Offset _u(BodyPoint p) =>
      Offset(p.x * _ar, p.y); // unidades de "alto de imagen"
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

  /// Línea de la cabeza para medir inclinación. Preferimos orejas; si una
  /// queda oculta al girar la cabeza, usamos los ojos.
  List<BodyPoint>? _headLine() {
    final le = _p(PoseLandmarkType.leftEar);
    final re = _p(PoseLandmarkType.rightEar);
    if (le != null && re != null) return [le, re];

    final lEye = _p(PoseLandmarkType.leftEye);
    final rEye = _p(PoseLandmarkType.rightEye);
    if (lEye != null && rEye != null) return [lEye, rEye];

    return null;
  }

  /// Punto estable de la cabeza para medir el encogimiento de hombros.
  BodyPoint? _headAnchor() {
    final le = _p(PoseLandmarkType.leftEar);
    final re = _p(PoseLandmarkType.rightEar);
    if (le != null && re != null) {
      return BodyPoint((le.x + re.x) / 2, (le.y + re.y) / 2, 1);
    }

    final nose = _p(PoseLandmarkType.nose);
    if (nose != null) return nose;

    final lEye = _p(PoseLandmarkType.leftEye);
    final rEye = _p(PoseLandmarkType.rightEye);
    if (lEye != null && rEye != null) {
      return BodyPoint((lEye.x + rEye.x) / 2, (lEye.y + rEye.y) / 2, 1);
    }

    return null;
  }

  /// Ancho de hombros en unidades de altura de imagen; sirve para normalizar
  /// movimientos sin depender de la distancia a la cámara.
  double get _bodyScale {
    final ls = _p(PoseLandmarkType.leftShoulder);
    final rs = _p(PoseLandmarkType.rightShoulder);
    if (ls != null && rs != null) {
      final d = _dist(ls, rs);
      if (d > 0.05) return d;
    }
    return 0.25;
  }

  bool _isPositioned() {
    if (_kind == ExerciseKind.wrists) {
      // Con un brazo visible ya podemos analizar movimiento; pedimos el otro
      // solo como recomendación para no bloquear el ejercicio.
      final left =
          _p(PoseLandmarkType.leftWrist) != null &&
          _p(PoseLandmarkType.leftElbow) != null;
      final right =
          _p(PoseLandmarkType.rightWrist) != null &&
          _p(PoseLandmarkType.rightElbow) != null;
      return left || right;
    }

    final ls = _p(PoseLandmarkType.leftShoulder);
    final rs = _p(PoseLandmarkType.rightShoulder);
    if (ls == null || rs == null) return false;

    // Si se ven orejas u ojos, comprobamos que los hombros sean más anchos
    // que la cabeza. Si no, no bloqueamos: con la nariz y los hombros ya se
    // puede medir el movimiento (personas sentadas muy cerca de la cámara).
    final head = _headLine();
    if (head != null && _dist(ls, rs) < _dist(head[0], head[1]) * 1.1) {
      return false;
    }

    switch (_kind) {
      case ExerciseKind.neckRotation:
      case ExerciseKind.neckNod:
        return _p(PoseLandmarkType.nose) != null;
      case ExerciseKind.armsUp:
      case ExerciseKind.chest:
      case ExerciseKind.armCircles:
      case ExerciseKind.lateralRaise:
      case ExerciseKind.selfHug:
      case ExerciseKind.prayerPress:
      case ExerciseKind.crossShoulder:
      case ExerciseKind.fingerSpread:
      case ExerciseKind.shoulderTaps:
        return _p(PoseLandmarkType.leftWrist) != null &&
            _p(PoseLandmarkType.rightWrist) != null;
      case ExerciseKind.goalpost:
        return _p(PoseLandmarkType.leftElbow) != null &&
            _p(PoseLandmarkType.rightElbow) != null &&
            _p(PoseLandmarkType.leftWrist) != null &&
            _p(PoseLandmarkType.rightWrist) != null;
      case ExerciseKind.curls:
        final left =
            _p(PoseLandmarkType.leftElbow) != null &&
            _p(PoseLandmarkType.leftWrist) != null;
        final right =
            _p(PoseLandmarkType.rightElbow) != null &&
            _p(PoseLandmarkType.rightWrist) != null;
        return left || right;
      case ExerciseKind.forearmCircles:
        return _p(PoseLandmarkType.leftElbow) != null &&
            _p(PoseLandmarkType.rightElbow) != null &&
            _p(PoseLandmarkType.leftWrist) != null &&
            _p(PoseLandmarkType.rightWrist) != null;
      default:
        return true;
    }
  }

  String get _positionHint {
    switch (_kind) {
      case ExerciseKind.wrists:
        return 'Levanta los antebrazos frente al pecho y aléjate hasta que se vean tus codos y manos';
      case ExerciseKind.armsUp:
      case ExerciseKind.chest:
      case ExerciseKind.armCircles:
      case ExerciseKind.lateralRaise:
      case ExerciseKind.selfHug:
      case ExerciseKind.prayerPress:
      case ExerciseKind.crossShoulder:
      case ExerciseKind.goalpost:
      case ExerciseKind.fingerSpread:
      case ExerciseKind.shoulderTaps:
        return 'Aléjate un poco: deben verse tu cabeza, hombros, codos y ambas manos';
      case ExerciseKind.curls:
      case ExerciseKind.forearmCircles:
        return 'Muestra tus hombros, codos y manos; mantén los brazos dentro del encuadre';
      case ExerciseKind.neckRotation:
        return 'Mira al frente y mantén la nariz y ambos hombros visibles';
      case ExerciseKind.neckNod:
        return 'Mantén la cara y ambos hombros dentro del encuadre';
      default:
        return 'Aléjate un poco: deben verse tu cabeza, tus hombros completos y tus codos';
    }
  }

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
      case ExerciseKind.armsUp:
        _evalArmsUp(dt);
        break;
      case ExerciseKind.curls:
        _evalCurls(dt);
        break;
      case ExerciseKind.chest:
        _evalChest(dt);
        break;
      case ExerciseKind.sideBend:
        _evalSideBend(dt);
        break;
      case ExerciseKind.neckRotation:
        _evalNeckRotation(dt);
        break;
      case ExerciseKind.neckNod:
        _evalNeckNod(dt);
        break;
      case ExerciseKind.armCircles:
        _evalArmCircles(dt);
        break;
      case ExerciseKind.lateralRaise:
        _evalLateralRaise(dt);
        break;
      case ExerciseKind.selfHug:
        _evalSelfHug(dt);
        break;
      case ExerciseKind.prayerPress:
        _evalPrayerPress(dt);
        break;
      case ExerciseKind.crossShoulder:
        _evalCrossShoulder(dt);
        break;
      case ExerciseKind.goalpost:
        _evalGoalpost(dt);
        break;
      case ExerciseKind.alternatingShrug:
        _evalAlternatingShrug(dt);
        break;
      case ExerciseKind.fingerSpread:
        _evalFingerSpread(dt);
        break;
      case ExerciseKind.forearmCircles:
        _evalForearmCircles(dt);
        break;
      case ExerciseKind.shoulderTaps:
        _evalShoulderTaps(dt);
        break;
      default:
        break;
    }
  }

  // ---------- Cuello ----------
  void _evalNeck(double dt) {
    final head = _headLine();
    if (head == null) return;

    final a = head[0].x <= head[1].x ? head[0] : head[1];
    final b = head[0].x <= head[1].x ? head[1] : head[0];
    final ua = _u(a);
    final ub = _u(b);

    // Ángulo de la línea de la cabeza (orejas u ojos) respecto a la horizontal.
    final angle = math.atan2(ub.dy - ua.dy, ub.dx - ua.dx) * 180 / math.pi;
    final absA = angle.abs();
    final side = angle > 0 ? 1 : -1;

    _progressLabel = 'Lados completados: $_reps / $neckTargetSides';
    _progress = _reps / neckTargetSides;

    if (_needCenter) {
      if (absA < neckCenterDeg) {
        _needCenter = false;
        _setFeedback(
          'Muy bien. Ahora inclina hacia el otro lado',
          Colors.green,
        );
      } else {
        _setFeedback('Regresa la cabeza al centro', Colors.orange);
      }
      return;
    }

    final started = absA >= neckTiltDeg;
    final maintaining = absA >= neckKeepDeg;

    // Si ya empezó el estiramiento, toleramos pequeñas variaciones al mantenerlo.
    if (!maintaining) {
      _holdSide = 0;
      _holdTime = 0;
      _setFeedback('Inclina suavemente la cabeza hacia un lado', Colors.orange);
      return;
    }

    if (!started && _holdTime <= 0) {
      _setFeedback(
        'Inclina un poco más la cabeza hacia un lado',
        Colors.orange,
      );
      return;
    }

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
  }

  // ---------- Hombros ----------
  void _evalShoulders(double dt) {
    final ls = _p(PoseLandmarkType.leftShoulder)!;
    final rs = _p(PoseLandmarkType.rightShoulder)!;
    final head = _headAnchor();
    if (head == null) return;

    final sw = _dist(ls, rs);
    if (sw <= 0) return;

    if (!_circlesPhase) {
      // Fase 1: encogimientos (subir los hombros hacia la cabeza)
      final shY = (ls.y + rs.y) / 2;
      final h = (shY - head.y) / sw; // altura relativa hombros-cabeza

      _progressLabel = 'Encogimientos: $_reps / $shrugTarget';
      _progress = (_reps / shrugTarget) * 0.5;

      if (_baseH == null) {
        if (_calib.isEmpty) _calibStartClock = _clock;
        _calib.add(h);
        _setFeedback(
          'Relaja los hombros y quédate quieto... midiendo tu postura',
          Colors.orange,
        );

        final enoughFrames = _calib.length >= shrugCalibrationFrames;
        final enoughTime = _clock - _calibStartClock >= shrugCalibrationSec;
        if (enoughFrames || enoughTime) {
          final sorted = [..._calib]..sort();
          _baseH = sorted[sorted.length ~/ 2];
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
          // Adapta la postura base solo cuando está relajado, para no perder
          // el encogimiento por una deriva lenta.
          if (ratio > 0.98 && ratio < 1.08) {
            _baseH = _baseH! * 0.997 + h * 0.003;
          }
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
                '¡Bien! Ahora haz círculos grandes con los hombros',
                Colors.green,
              );
            } else {
              _setFeedback('✅ Repetición completada. Otra vez', Colors.green);
            }
          } else {
            _setFeedback(
              'Mantén los hombros arriba un poco más (1-2 s)',
              Colors.orange,
            );
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
      final active =
          math.max(_shoulderMx.range, _shoulderMy.range) >= circleMove;
      if (active) _motionSeconds += dt;

      _progressLabel =
          'Círculos: ${_motionSeconds.floor()} / ${circlesTargetSec.toInt()} s';
      _progress =
          0.5 + (_motionSeconds / circlesTargetSec).clamp(0.0, 1.0) * 0.5;

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

  /// Dirección media de la mano usando los tres puntos base de los dedos.
  /// Es más estable que depender solo del índice, que suele perder visibilidad.
  Offset? _handTip(
    PoseLandmarkType index,
    PoseLandmarkType pinky,
    PoseLandmarkType thumb,
  ) {
    final points = <Offset>[];
    for (final type in [index, pinky, thumb]) {
      final p = _p(type);
      if (p != null) points.add(_u(p));
    }
    if (points.isEmpty) return null;

    var x = 0.0;
    var y = 0.0;
    for (final p in points) {
      x += p.dx;
      y += p.dy;
    }
    return Offset(x / points.length, y / points.length);
  }

  // ---------- Muñecas ----------
  void _evalWrists(double dt) {
    var tracked = false;
    var active = false;
    var trackedArms = 0;
    final scale = _bodyScale;

    void track(
      PoseLandmarkType wrist,
      PoseLandmarkType index,
      PoseLandmarkType pinky,
      PoseLandmarkType thumb,
      AngleTracker angleTracker,
      MotionSeries xSeries,
      MotionSeries ySeries,
    ) {
      final pw = _p(wrist);
      if (pw == null) return;

      tracked = true;
      trackedArms++;
      final w = _u(pw);

      // Desplazamiento de la muñeca: detecta círculos aunque no se vean dedos.
      xSeries.add(_clock, w.dx / scale);
      ySeries.add(_clock, w.dy / scale);
      final positionActive =
          math.max(xSeries.range, ySeries.range) >= wristMoveNorm;

      // Rotación/flexión de la mano (índice + meñique + pulgar).
      final tip = _handTip(index, pinky, thumb);
      var angleActive = false;
      if (tip != null) {
        angleTracker.add(_clock, math.atan2(tip.dy - w.dy, tip.dx - w.dx));
        angleActive = angleTracker.rangeDeg >= wristMoveDeg;
      }

      if (positionActive || angleActive) active = true;
    }

    track(
      PoseLandmarkType.leftWrist,
      PoseLandmarkType.leftIndex,
      PoseLandmarkType.leftPinky,
      PoseLandmarkType.leftThumb,
      _leftHand,
      _leftWristX,
      _leftWristY,
    );
    track(
      PoseLandmarkType.rightWrist,
      PoseLandmarkType.rightIndex,
      PoseLandmarkType.rightPinky,
      PoseLandmarkType.rightThumb,
      _rightHand,
      _rightWristX,
      _rightWristY,
    );

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
      final hint = trackedArms < 2 ? ' (muestra también la otra mano)' : '';
      _setFeedback(
        '✅ ¡Bien! Sigue moviendo las muñecas ($left s)$hint',
        Colors.green,
      );
    } else {
      _setFeedback(
        'Gira las muñecas en círculos o flexiónalas arriba y abajo',
        Colors.orange,
      );
    }
  }

  // ---------- Elevación de brazos ----------
  void _evalArmsUp(double dt) {
    final lw = _p(PoseLandmarkType.leftWrist);
    final rw = _p(PoseLandmarkType.rightWrist);
    final ls = _p(PoseLandmarkType.leftShoulder);
    final rs = _p(PoseLandmarkType.rightShoulder);
    final head = _headAnchor();
    if (lw == null || rw == null || ls == null || rs == null || head == null) {
      return;
    }

    final sw = _bodyScale;
    final shY = (ls.y + rs.y) / 2;
    final above =
        lw.y < head.y - sw * armsUpHeadMargin &&
        rw.y < head.y - sw * armsUpHeadMargin;
    final below =
        lw.y > shY + sw * armsUpDownMargin &&
        rw.y > shY + sw * armsUpDownMargin;

    _progressLabel = 'Elevaciones: $_reps / $armsUpTargetReps';
    _progress = (_reps / armsUpTargetReps).clamp(0.0, 1.0);

    if (_armsRaised) {
      if (below) {
        _armsRaised = false;
        _reps++;
        _progressLabel = 'Elevaciones: $_reps / $armsUpTargetReps';
        _progress = (_reps / armsUpTargetReps).clamp(0.0, 1.0);
        if (_reps >= armsUpTargetReps) {
          _finish(timeUp: false);
          return;
        }
        _setFeedback('✅ Repetición completada. Sube otra vez', Colors.green);
      } else {
        _setFeedback('Ahora baja los brazos con control', Colors.green);
      }
      return;
    }

    if (above) {
      _armsRaised = true;
      _setFeedback('¡Arriba! Baja los brazos lentamente', Colors.green);
    } else {
      _setFeedback(
        'Sube ambos brazos estirados por encima de la cabeza',
        Colors.orange,
      );
    }
  }

  // ---------- Flexión de codos ----------
  double? _elbowAngle(
    PoseLandmarkType shoulder,
    PoseLandmarkType elbow,
    PoseLandmarkType wrist,
  ) {
    final ps = _p(shoulder);
    final pe = _p(elbow);
    final pw = _p(wrist);
    if (ps == null || pe == null || pw == null) return null;

    final a = _u(pe) - _u(ps);
    final b = _u(pe) - _u(pw);
    final denom = a.distance * b.distance;
    if (denom <= 0) return null;

    final cos = ((a.dx * b.dx + a.dy * b.dy) / denom).clamp(-1.0, 1.0);
    return math.acos(cos) * 180 / math.pi;
  }

  void _evalCurls(double dt) {
    final left = _elbowAngle(
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.leftWrist,
    );
    final right = _elbowAngle(
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.rightWrist,
    );
    final angles = [left, right].whereType<double>().toList();
    if (angles.isEmpty) return;

    final angle = angles.reduce((a, b) => a + b) / angles.length;
    final bent = angle <= curlBentDeg;
    final extended = angle >= curlExtendedDeg;

    _progressLabel = 'Flexiones: $_reps / $curlTargetReps';
    _progress = (_reps / curlTargetReps).clamp(0.0, 1.0);

    if (_curlBent) {
      if (extended) {
        _curlBent = false;
        _reps++;
        _progressLabel = 'Flexiones: $_reps / $curlTargetReps';
        _progress = (_reps / curlTargetReps).clamp(0.0, 1.0);
        if (_reps >= curlTargetReps) {
          _finish(timeUp: false);
          return;
        }
        _setFeedback(
          '✅ Repetición completada. Flexiona otra vez',
          Colors.green,
        );
      } else {
        _setFeedback('Extiende los brazos lentamente', Colors.green);
      }
      return;
    }

    if (bent) {
      _curlBent = true;
      _setFeedback('Ahora extiende los brazos con control', Colors.green);
    } else {
      _setFeedback(
        'Flexiona los codos llevando las manos hacia los hombros',
        Colors.orange,
      );
    }
  }

  // ---------- Apertura de pecho ----------
  void _evalChest(double dt) {
    final lw = _p(PoseLandmarkType.leftWrist);
    final rw = _p(PoseLandmarkType.rightWrist);
    final ls = _p(PoseLandmarkType.leftShoulder);
    final rs = _p(PoseLandmarkType.rightShoulder);
    if (lw == null || rw == null || ls == null || rs == null) return;

    final sw = _bodyScale;
    final shY = (ls.y + rs.y) / 2;
    final spread = (_u(lw).dx - _u(rw).dx).abs() / sw;
    final heightOk = (lw.y - shY).abs() <= sw && (rw.y - shY).abs() <= sw;
    final open = spread >= chestSpreadMin && heightOk;

    _progressLabel = 'Aperturas: $_reps / $chestTargetReps';
    _progress = (_reps / chestTargetReps).clamp(0.0, 1.0);

    if (_chestRest) {
      if (spread < chestSpreadRelease) _chestRest = false;
      _setFeedback('Baja los brazos y relaja los hombros', Colors.orange);
      return;
    }

    if (!_chestOpen) {
      if (open) {
        _chestOpen = true;
        _chestHold = 0;
        _setFeedback(
          'Mantén el pecho abierto y los omóplatos juntos',
          Colors.green,
        );
      } else {
        _setFeedback(
          'Abre ambos brazos a la altura de los hombros',
          Colors.orange,
        );
      }
      return;
    }

    if (!open) {
      _chestOpen = false;
      _chestHold = 0;
      _setFeedback('No cierres los brazos: mantén la apertura', Colors.orange);
      return;
    }

    _chestHold += dt;
    if (_chestHold >= chestHoldSec) {
      _chestOpen = false;
      _chestHold = 0;
      _chestRest = true;
      _reps++;
      _progressLabel = 'Aperturas: $_reps / $chestTargetReps';
      _progress = (_reps / chestTargetReps).clamp(0.0, 1.0);
      if (_reps >= chestTargetReps) {
        _finish(timeUp: false);
        return;
      }
      _setFeedback('✅ Apertura completada. Baja los brazos', Colors.green);
    } else {
      final left = (chestHoldSec - _chestHold).ceil();
      _setFeedback('✅ Buen estiramiento. Mantén $left s', Colors.green);
    }
  }

  // ---------- Inclinación lateral de tronco ----------
  void _evalSideBend(double dt) {
    final ls = _p(PoseLandmarkType.leftShoulder);
    final rs = _p(PoseLandmarkType.rightShoulder);
    if (ls == null || rs == null) return;

    final a = ls.x <= rs.x ? ls : rs;
    final b = ls.x <= rs.x ? rs : ls;
    final ua = _u(a);
    final ub = _u(b);
    final angle = math.atan2(ub.dy - ua.dy, ub.dx - ua.dx) * 180 / math.pi;

    if (_baseTrunkAngle == null) {
      _trunkCalib.add(angle);
      if (_trunkCalib.length >= 12) {
        final sorted = [..._trunkCalib]..sort();
        _baseTrunkAngle = sorted[sorted.length ~/ 2];
      }
      _progressLabel = 'Lados completados: $_reps / $trunkTargetSides';
      _progress = (_reps / trunkTargetSides).clamp(0.0, 1.0);
      _setFeedback(
        'Siéntate recto y quédate quieto un momento... midiendo tu postura',
        Colors.orange,
      );
      return;
    }

    final rel = angle - _baseTrunkAngle!;
    final absA = rel.abs();
    final side = rel > 0 ? 1 : -1;

    _progressLabel = 'Lados completados: $_reps / $trunkTargetSides';
    _progress = (_reps / trunkTargetSides).clamp(0.0, 1.0);

    if (_needCenter) {
      if (absA < trunkCenterDeg) {
        _needCenter = false;
        _setFeedback(
          'Muy bien. Ahora inclina hacia el otro lado',
          Colors.green,
        );
      } else {
        _setFeedback('Regresa el tronco al centro', Colors.orange);
      }
      return;
    }

    if (absA < trunkKeepDeg) {
      _holdSide = 0;
      _holdTime = 0;
      _setFeedback('Inclina suavemente el tronco hacia un lado', Colors.orange);
      return;
    }

    if (absA > 45) {
      _setFeedback(
        'Inclínate con suavidad, sin forzar la espalda',
        Colors.orange,
      );
      return;
    }

    if (side == _lastDoneSide) {
      _holdTime = 0;
      _holdSide = 0;
      _setFeedback('Ahora inclínate hacia el otro lado', Colors.orange);
      return;
    }

    if (_holdSide != side) {
      _holdSide = side;
      _holdTime = 0;
    }

    _holdTime += dt;
    if (_holdTime >= trunkHoldSec) {
      _reps++;
      _lastDoneSide = side;
      _holdSide = 0;
      _holdTime = 0;
      _needCenter = true;
      _progressLabel = 'Lados completados: $_reps / $trunkTargetSides';
      _progress = (_reps / trunkTargetSides).clamp(0.0, 1.0);
      if (_reps >= trunkTargetSides) {
        _finish(timeUp: false);
        return;
      }
      _setFeedback('¡Lado completado! Regresa al centro', Colors.green);
    } else {
      final left = (trunkHoldSec - _holdTime).ceil();
      _setFeedback('✅ Buen estiramiento. Mantén $left s', Colors.green);
    }
  }

  // ---------- Rotación de cuello ----------
  void _evalNeckRotation(double dt) {
    final nose = _p(PoseLandmarkType.nose);
    final ls = _p(PoseLandmarkType.leftShoulder);
    final rs = _p(PoseLandmarkType.rightShoulder);
    if (nose == null || ls == null || rs == null) return;

    final sw = _bodyScale;
    if (sw <= 0) return;
    final noseU = _u(nose);
    final lsU = _u(ls);
    final rsU = _u(rs);
    final offset = (noseU.dx - (lsU.dx + rsU.dx) / 2) / sw;

    if (_baseNeckTurn == null) {
      _neckTurnCalib.add(offset);
      if (_neckTurnCalib.length >= neckTurnCalibrationFrames) {
        final sorted = [..._neckTurnCalib]..sort();
        _baseNeckTurn = sorted[sorted.length ~/ 2];
      }
      _progressLabel = 'Lados completados: $_reps / $neckTurnTargetSides';
      _progress = (_reps / neckTurnTargetSides).clamp(0.0, 1.0);
      _setFeedback(
        'Mira al frente y quédate quieto un momento... midiendo tu postura',
        Colors.orange,
      );
      return;
    }

    final rel = offset - _baseNeckTurn!;
    final absR = rel.abs();
    final side = rel > 0 ? 1 : -1;

    _progressLabel = 'Lados completados: $_reps / $neckTurnTargetSides';
    _progress = (_reps / neckTurnTargetSides).clamp(0.0, 1.0);

    if (_neckTurnNeedCenter) {
      if (absR < neckTurnCenterRatio) {
        _neckTurnNeedCenter = false;
        _setFeedback('Muy bien. Ahora gira hacia el otro lado', Colors.green);
      } else {
        _setFeedback('Regresa la mirada al frente', Colors.orange);
      }
      return;
    }

    if (absR < neckTurnCenterRatio) {
      _neckTurnSide = 0;
      _neckTurnHold = 0;
      _setFeedback('Gira la cabeza lentamente hacia un lado', Colors.orange);
      return;
    }

    if (absR < neckTurnStartRatio) {
      _setFeedback('Gira un poco más, sin mover los hombros', Colors.orange);
      return;
    }

    if (side == _lastNeckTurnSide) {
      _neckTurnHold = 0;
      _neckTurnSide = 0;
      _setFeedback('Ahora gira hacia el otro lado', Colors.orange);
      return;
    }

    if (_neckTurnSide != side) {
      _neckTurnSide = side;
      _neckTurnHold = 0;
    }

    _neckTurnHold += dt;
    if (_neckTurnHold >= neckTurnHoldSec) {
      _reps++;
      _lastNeckTurnSide = side;
      _neckTurnSide = 0;
      _neckTurnHold = 0;
      _neckTurnNeedCenter = true;
      _progressLabel = 'Lados completados: $_reps / $neckTurnTargetSides';
      _progress = (_reps / neckTurnTargetSides).clamp(0.0, 1.0);
      if (_reps >= neckTurnTargetSides) {
        _finish(timeUp: false);
        return;
      }
      _setFeedback('¡Lado completado! Regresa al frente', Colors.green);
    } else {
      final left = (neckTurnHoldSec - _neckTurnHold).ceil();
      _setFeedback('✅ Buen giro. Mantén $left s', Colors.green);
    }
  }

  // ---------- Flexión y extensión de cuello ----------
  void _evalNeckNod(double dt) {
    final nose = _p(PoseLandmarkType.nose);
    final le = _p(PoseLandmarkType.leftEar);
    final re = _p(PoseLandmarkType.rightEar);
    final lEye = _p(PoseLandmarkType.leftEye);
    final rEye = _p(PoseLandmarkType.rightEye);

    final headY = le != null && re != null
        ? (le.y + re.y) / 2
        : lEye != null && rEye != null
        ? (lEye.y + rEye.y) / 2
        : null;
    if (nose == null || headY == null) return;

    final sw = _bodyScale;
    if (sw <= 0) return;
    final drop = (nose.y - headY) / sw;

    if (_baseNod == null) {
      _nodCalib.add(drop);
      if (_nodCalib.length >= nodCalibrationFrames) {
        final sorted = [..._nodCalib]..sort();
        _baseNod = sorted[sorted.length ~/ 2];
      }
      _progressLabel = 'Movimientos: $_reps / $nodTargetReps';
      _progress = (_reps / nodTargetReps).clamp(0.0, 1.0);
      _setFeedback(
        'Mira al frente y quédate quieto un momento... midiendo tu postura',
        Colors.orange,
      );
      return;
    }

    final rel = drop - _baseNod!;
    _progressLabel = 'Movimientos: $_reps / $nodTargetReps';
    _progress = (_reps / nodTargetReps).clamp(0.0, 1.0);

    if (_nodNeedCenter) {
      if (rel.abs() < nodCenterDelta) {
        _nodNeedCenter = false;
        _setFeedback(
          'Muy bien. Ahora haz el movimiento contrario',
          Colors.green,
        );
      } else {
        _setFeedback('Vuelve a la posición neutral', Colors.orange);
      }
      return;
    }

    final down = rel >= nodDownDelta;
    final up = rel <= -nodUpDelta;
    if (!down && !up) {
      _nodState = 0;
      _nodHold = 0;
      _setFeedback(
        'Baja la barbilla al pecho o mira hacia el techo',
        Colors.orange,
      );
      return;
    }

    final state = down ? 1 : 2;
    if (_nodState != state) {
      _nodState = state;
      _nodHold = 0;
    }
    _nodHold += dt;

    if (_nodHold >= nodHoldSec) {
      _reps++;
      _nodState = 0;
      _nodHold = 0;
      _nodNeedCenter = true;
      _progressLabel = 'Movimientos: $_reps / $nodTargetReps';
      _progress = (_reps / nodTargetReps).clamp(0.0, 1.0);
      if (_reps >= nodTargetReps) {
        _finish(timeUp: false);
        return;
      }
      _setFeedback('✅ Movimiento completado. Vuelve al centro', Colors.green);
    } else {
      final left = (nodHoldSec - _nodHold).ceil();
      _setFeedback(
        state == 1
            ? '✅ Barbilla al pecho. Mantén $left s'
            : '✅ Mirada al techo. Mantén $left s',
        Colors.green,
      );
    }
  }

  // ---------- Círculos de brazos ----------
  void _evalArmCircles(double dt) {
    final lw = _p(PoseLandmarkType.leftWrist);
    final rw = _p(PoseLandmarkType.rightWrist);
    final ls = _p(PoseLandmarkType.leftShoulder);
    final rs = _p(PoseLandmarkType.rightShoulder);
    if (lw == null || rw == null || ls == null || rs == null) return;

    final sw = _bodyScale;
    if (sw <= 0) return;
    final shY = (ls.y + rs.y) / 2;
    final span = (_u(lw).dx - _u(rw).dx).abs() / sw;
    final heightOk =
        (lw.y - shY).abs() <= sw * armCircleHeightTol &&
        (rw.y - shY).abs() <= sw * armCircleHeightTol;
    final extended = span >= armCircleSpreadMin && heightOk;

    if (!extended) {
      _armCircleX.clear();
      _armCircleY.clear();
      _progressLabel =
          'Círculos: ${_motionSeconds.floor()} / ${armCircleTargetSec.toInt()} s';
      _progress = (_motionSeconds / armCircleTargetSec).clamp(0.0, 1.0);
      _setFeedback(
        'Abre los brazos a la altura de los hombros y mantén las manos visibles',
        Colors.orange,
      );
      return;
    }

    final mx = ((lw.x + rw.x) / 2) * _ar / sw;
    final my = ((lw.y + rw.y) / 2) / sw;
    _armCircleX.add(_clock, mx);
    _armCircleY.add(_clock, my);
    final active =
        math.max(_armCircleX.range, _armCircleY.range) >= armCircleMove;
    if (active) _motionSeconds += dt;

    _progressLabel =
        'Círculos: ${_motionSeconds.floor()} / ${armCircleTargetSec.toInt()} s';
    _progress = (_motionSeconds / armCircleTargetSec).clamp(0.0, 1.0);

    if (_motionSeconds >= armCircleTargetSec) {
      _finish(timeUp: false);
      return;
    }

    _setFeedback(
      active
          ? '✅ ¡Muy bien! Sigue dibujando círculos con los brazos'
          : 'Dibuja círculos amplios con ambas manos',
      active ? Colors.green : Colors.orange,
    );
  }

  // ---------- Elevación lateral de brazos ----------
  void _evalLateralRaise(double dt) {
    final lw = _p(PoseLandmarkType.leftWrist);
    final rw = _p(PoseLandmarkType.rightWrist);
    final ls = _p(PoseLandmarkType.leftShoulder);
    final rs = _p(PoseLandmarkType.rightShoulder);
    if (lw == null || rw == null || ls == null || rs == null) return;

    final sw = _bodyScale;
    if (sw <= 0) return;
    final shY = (ls.y + rs.y) / 2;
    final span = (_u(lw).dx - _u(rw).dx).abs() / sw;
    final up =
        span >= lateralSpreadMin &&
        (lw.y - shY).abs() <= sw * lateralUpMargin &&
        (rw.y - shY).abs() <= sw * lateralUpMargin;
    final down =
        lw.y > shY + sw * lateralDownMargin &&
        rw.y > shY + sw * lateralDownMargin;

    _progressLabel = 'Elevaciones: $_reps / $lateralTargetReps';
    _progress = (_reps / lateralTargetReps).clamp(0.0, 1.0);

    if (_lateralRaised) {
      if (down) {
        _lateralRaised = false;
        _reps++;
        _progressLabel = 'Elevaciones: $_reps / $lateralTargetReps';
        _progress = (_reps / lateralTargetReps).clamp(0.0, 1.0);
        if (_reps >= lateralTargetReps) {
          _finish(timeUp: false);
          return;
        }
        _setFeedback('✅ Repetición completada. Sube otra vez', Colors.green);
      } else {
        _setFeedback('Baja los brazos con control', Colors.green);
      }
      return;
    }

    if (up) {
      _lateralRaised = true;
      _setFeedback('¡Arriba! Ahora baja los brazos lentamente', Colors.green);
    } else {
      _setFeedback(
        'Eleva ambos brazos hacia los lados hasta la altura de los hombros',
        Colors.orange,
      );
    }
  }

  // ---------- Abrazo de oso ----------
  void _evalSelfHug(double dt) {
    final lw = _p(PoseLandmarkType.leftWrist);
    final rw = _p(PoseLandmarkType.rightWrist);
    final ls = _p(PoseLandmarkType.leftShoulder);
    final rs = _p(PoseLandmarkType.rightShoulder);
    if (lw == null || rw == null || ls == null || rs == null) return;

    final sw = _bodyScale;
    if (sw <= 0) return;
    final shY = (ls.y + rs.y) / 2;
    final leftToRight = _dist(lw, rs) <= sw * hugShoulderReach;
    final rightToLeft = _dist(rw, ls) <= sw * hugShoulderReach;
    final heightOk =
        (lw.y - shY).abs() <= sw * hugHeightTol &&
        (rw.y - shY).abs() <= sw * hugHeightTol;
    final hugging = leftToRight && rightToLeft && heightOk;

    _progressLabel = 'Abrazos: $_reps / $hugTargetReps';
    _progress = (_reps / hugTargetReps).clamp(0.0, 1.0);

    if (_hugRest) {
      if (!hugging) _hugRest = false;
      _setFeedback('Abre los brazos y relaja los hombros', Colors.orange);
      return;
    }

    if (!_hugHolding) {
      if (hugging) {
        _hugHolding = true;
        _hugHold = 0;
        _setFeedback('Mantén el abrazo y respira profundo', Colors.green);
      } else {
        _setFeedback(
          'Cruza los brazos y lleva cada mano al hombro opuesto',
          Colors.orange,
        );
      }
      return;
    }

    if (!hugging) {
      _hugHolding = false;
      _hugHold = 0;
      _setFeedback('No sueltes el abrazo: mantén la posición', Colors.orange);
      return;
    }

    _hugHold += dt;
    if (_hugHold >= hugHoldSec) {
      _hugHolding = false;
      _hugHold = 0;
      _hugRest = true;
      _reps++;
      _progressLabel = 'Abrazos: $_reps / $hugTargetReps';
      _progress = (_reps / hugTargetReps).clamp(0.0, 1.0);
      if (_reps >= hugTargetReps) {
        _finish(timeUp: false);
        return;
      }
      _setFeedback('✅ Abrazo completado. Abre los brazos', Colors.green);
    } else {
      final left = (hugHoldSec - _hugHold).ceil();
      _setFeedback('✅ Buen abrazo. Mantén $left s', Colors.green);
    }
  }

  // ---------- Prensa de palmas ----------
  void _evalPrayerPress(double dt) {
    final lw = _p(PoseLandmarkType.leftWrist);
    final rw = _p(PoseLandmarkType.rightWrist);
    final ls = _p(PoseLandmarkType.leftShoulder);
    final rs = _p(PoseLandmarkType.rightShoulder);
    if (lw == null || rw == null || ls == null || rs == null) return;

    final sw = _bodyScale;
    if (sw <= 0) return;
    final shY = (ls.y + rs.y) / 2;
    final distance = _dist(lw, rw);
    final chestOk =
        lw.y - shY >= sw * prayerChestMin &&
        lw.y - shY <= sw * prayerChestMax &&
        rw.y - shY >= sw * prayerChestMin &&
        rw.y - shY <= sw * prayerChestMax;
    final pressing = distance <= sw * prayerHandsClose && chestOk;
    final released = distance >= sw * prayerHandsRelease;

    _progressLabel = 'Prensas: $_reps / $prayerTargetReps';
    _progress = (_reps / prayerTargetReps).clamp(0.0, 1.0);

    if (_prayerRest) {
      if (released) _prayerRest = false;
      _setFeedback('Separa un poco las manos y relaja', Colors.orange);
      return;
    }

    if (!_prayerHolding) {
      if (pressing) {
        _prayerHolding = true;
        _prayerHold = 0;
        _setFeedback('Presiona las palmas y mantén', Colors.green);
      } else {
        _setFeedback(
          'Junta las palmas frente al pecho con los codos afuera',
          Colors.orange,
        );
      }
      return;
    }

    if (!pressing) {
      _prayerHolding = false;
      _prayerHold = 0;
      _setFeedback(
        'Mantén las palmas juntas mientras presionas',
        Colors.orange,
      );
      return;
    }

    _prayerHold += dt;
    if (_prayerHold >= prayerHoldSec) {
      _prayerHolding = false;
      _prayerHold = 0;
      _prayerRest = true;
      _reps++;
      _progressLabel = 'Prensas: $_reps / $prayerTargetReps';
      _progress = (_reps / prayerTargetReps).clamp(0.0, 1.0);
      if (_reps >= prayerTargetReps) {
        _finish(timeUp: false);
        return;
      }
      _setFeedback('✅ Prensa completada. Separa las manos', Colors.green);
    } else {
      final left = (prayerHoldSec - _prayerHold).ceil();
      _setFeedback('✅ Buena presión. Mantén $left s', Colors.green);
    }
  }

  // ---------- Estiramiento cruzado de hombro ----------
  void _evalCrossShoulder(double dt) {
    final lw = _p(PoseLandmarkType.leftWrist);
    final rw = _p(PoseLandmarkType.rightWrist);
    final ls = _p(PoseLandmarkType.leftShoulder);
    final rs = _p(PoseLandmarkType.rightShoulder);
    if (lw == null || rw == null || ls == null || rs == null) return;

    final sw = _bodyScale;
    if (sw <= 0) return;
    final shY = (ls.y + rs.y) / 2;
    final leftAcross =
        _dist(lw, rs) <= sw * crossReach &&
        (lw.y - shY).abs() <= sw * crossHeightTol;
    final rightAcross =
        _dist(rw, ls) <= sw * crossReach &&
        (rw.y - shY).abs() <= sw * crossHeightTol;
    final side = leftAcross && !rightAcross
        ? 1
        : rightAcross && !leftAcross
        ? -1
        : 0;

    _progressLabel = 'Lados completados: $_reps / $crossTargetSides';
    _progress = (_reps / crossTargetSides).clamp(0.0, 1.0);

    if (_crossNeedCenter) {
      if (!leftAcross && !rightAcross) {
        _crossNeedCenter = false;
        _setFeedback('Muy bien. Ahora cruza el otro brazo', Colors.green);
      } else {
        _setFeedback('Vuelve al centro y cambia de brazo', Colors.orange);
      }
      return;
    }

    if (side == 0) {
      _crossSide = 0;
      _crossHold = 0;
      _setFeedback(
        'Cruza un brazo frente al pecho y apoya la mano en el hombro opuesto',
        Colors.orange,
      );
      return;
    }

    if (side == _lastCrossSide) {
      _crossSide = 0;
      _crossHold = 0;
      _setFeedback('Ahora cruza el otro brazo', Colors.orange);
      return;
    }

    if (_crossSide != side) {
      _crossSide = side;
      _crossHold = 0;
    }

    _crossHold += dt;
    if (_crossHold >= crossHoldSec) {
      _reps++;
      _lastCrossSide = side;
      _crossSide = 0;
      _crossHold = 0;
      _crossNeedCenter = true;
      _progressLabel = 'Lados completados: $_reps / $crossTargetSides';
      _progress = (_reps / crossTargetSides).clamp(0.0, 1.0);
      if (_reps >= crossTargetSides) {
        _finish(timeUp: false);
        return;
      }
      _setFeedback('¡Lado completado! Vuelve al centro', Colors.green);
    } else {
      final left = (crossHoldSec - _crossHold).ceil();
      _setFeedback('✅ Buen estiramiento. Mantén $left s', Colors.green);
    }
  }

  // ---------- Postura de cactus ----------
  void _evalGoalpost(double dt) {
    final le = _p(PoseLandmarkType.leftElbow);
    final re = _p(PoseLandmarkType.rightElbow);
    final lw = _p(PoseLandmarkType.leftWrist);
    final rw = _p(PoseLandmarkType.rightWrist);
    final ls = _p(PoseLandmarkType.leftShoulder);
    final rs = _p(PoseLandmarkType.rightShoulder);
    if (le == null ||
        re == null ||
        lw == null ||
        rw == null ||
        ls == null ||
        rs == null) {
      return;
    }

    final sw = _bodyScale;
    if (sw <= 0) return;
    final shY = (ls.y + rs.y) / 2;
    final elbowSpread = (_u(le).dx - _u(re).dx).abs() / sw;
    final elbowsOut = elbowSpread >= goalpostElbowSpreadMin;
    final elbowsHigh =
        (le.y - shY).abs() <= sw * goalpostElbowHeightTol &&
        (re.y - shY).abs() <= sw * goalpostElbowHeightTol;
    final wristsUp =
        lw.y < le.y - sw * goalpostWristAbove &&
        rw.y < re.y - sw * goalpostWristAbove;
    final wristsAligned =
        (lw.x - le.x).abs() <= sw * goalpostWristAligned &&
        (rw.x - re.x).abs() <= sw * goalpostWristAligned;
    final open = elbowsOut && elbowsHigh && wristsUp && wristsAligned;
    final lowered = le.y > shY + sw * goalpostElbowHeightTol;

    _progressLabel = 'Posturas: $_reps / $goalpostTargetReps';
    _progress = (_reps / goalpostTargetReps).clamp(0.0, 1.0);

    if (_goalpostRest) {
      if (lowered) _goalpostRest = false;
      _setFeedback('Baja los brazos y relaja', Colors.orange);
      return;
    }

    if (!_goalpostHolding) {
      if (open) {
        _goalpostHolding = true;
        _goalpostHold = 0;
        _setFeedback('Mantén la postura y junta los omóplatos', Colors.green);
      } else {
        _setFeedback(
          'Levanta los codos a la altura de los hombros y las manos hacia arriba',
          Colors.orange,
        );
      }
      return;
    }

    if (!open) {
      _goalpostHolding = false;
      _goalpostHold = 0;
      _setFeedback(
        'No bajes los codos: mantén la L con los brazos',
        Colors.orange,
      );
      return;
    }

    _goalpostHold += dt;
    if (_goalpostHold >= goalpostHoldSec) {
      _goalpostHolding = false;
      _goalpostHold = 0;
      _goalpostRest = true;
      _reps++;
      _progressLabel = 'Posturas: $_reps / $goalpostTargetReps';
      _progress = (_reps / goalpostTargetReps).clamp(0.0, 1.0);
      if (_reps >= goalpostTargetReps) {
        _finish(timeUp: false);
        return;
      }
      _setFeedback('✅ Postura completada. Baja los brazos', Colors.green);
    } else {
      final left = (goalpostHoldSec - _goalpostHold).ceil();
      _setFeedback('✅ Buena postura. Mantén $left s', Colors.green);
    }
  }

  // ---------- Encogimiento alterno de hombros ----------
  void _evalAlternatingShrug(double dt) {
    final ls = _p(PoseLandmarkType.leftShoulder);
    final rs = _p(PoseLandmarkType.rightShoulder);
    if (ls == null || rs == null) return;

    final sw = _bodyScale;
    if (sw <= 0) return;
    final diff = (ls.y - rs.y) / sw;

    if (_baseAltShrug == null) {
      _altShrugCalib.add(diff);
      if (_altShrugCalib.length >= altShrugCalibrationFrames) {
        final sorted = [..._altShrugCalib]..sort();
        _baseAltShrug = sorted[sorted.length ~/ 2];
      }
      _progressLabel = 'Encogimientos: $_reps / $altShrugTargetReps';
      _progress = (_reps / altShrugTargetReps).clamp(0.0, 1.0);
      _setFeedback(
        'Relaja los hombros y quédate quieto... midiendo tu postura',
        Colors.orange,
      );
      return;
    }

    final rel = diff - _baseAltShrug!;
    _progressLabel = 'Encogimientos: $_reps / $altShrugTargetReps';
    _progress = (_reps / altShrugTargetReps).clamp(0.0, 1.0);

    if (_altShrugNeedCenter) {
      if (rel.abs() < altShrugRelease) {
        _altShrugNeedCenter = false;
        _setFeedback('Muy bien. Ahora sube el otro hombro', Colors.green);
      } else {
        _setFeedback('Baja el hombro y vuelve al centro', Colors.orange);
      }
      return;
    }

    final side = rel <= -altShrugDelta
        ? 1
        : rel >= altShrugDelta
        ? -1
        : 0;

    if (side == 0) {
      _altShrugSide = 0;
      _altShrugHold = 0;
      _setFeedback('Sube un hombro hacia la oreja', Colors.orange);
      return;
    }

    if (side == _lastAltShrugSide) {
      _altShrugSide = 0;
      _altShrugHold = 0;
      _setFeedback('Ahora sube el otro hombro', Colors.orange);
      return;
    }

    if (_altShrugSide != side) {
      _altShrugSide = side;
      _altShrugHold = 0;
    }

    _altShrugHold += dt;
    if (_altShrugHold >= shrugMinHold) {
      _reps++;
      _lastAltShrugSide = side;
      _altShrugSide = 0;
      _altShrugHold = 0;
      _altShrugNeedCenter = true;
      _progressLabel = 'Encogimientos: $_reps / $altShrugTargetReps';
      _progress = (_reps / altShrugTargetReps).clamp(0.0, 1.0);
      if (_reps >= altShrugTargetReps) {
        _finish(timeUp: false);
        return;
      }
      _setFeedback('✅ Repetición completada. Baja el hombro', Colors.green);
    } else {
      _setFeedback('Mantén el hombro arriba un instante', Colors.green);
    }
  }

  // ---------- Apertura de dedos ----------
  double? _handSpread(
    PoseLandmarkType wrist,
    PoseLandmarkType index,
    PoseLandmarkType pinky,
  ) {
    final pw = _p(wrist);
    final pi = _p(index);
    final pp = _p(pinky);
    if (pw == null || pi == null || pp == null) return null;

    final handSize = _dist(pw, pi);
    if (handSize <= 0) return null;

    final sw = _bodyScale;
    if (sw <= 0) return null;
    return _dist(pi, pp) / sw;
  }

  void _evalFingerSpread(double dt) {
    final left = _handSpread(
      PoseLandmarkType.leftWrist,
      PoseLandmarkType.leftIndex,
      PoseLandmarkType.leftPinky,
    );
    final right = _handSpread(
      PoseLandmarkType.rightWrist,
      PoseLandmarkType.rightIndex,
      PoseLandmarkType.rightPinky,
    );
    final values = [left, right].whereType<double>().toList();

    _progressLabel = 'Aperturas: $_reps / $fingerTargetReps';
    _progress = (_reps / fingerTargetReps).clamp(0.0, 1.0);

    if (values.isEmpty) {
      _setFeedback('Muestra las manos abiertas a la cámara', Colors.orange);
      return;
    }

    final spread = values.reduce((a, b) => a > b ? a : b);
    if (!_handsOpen) {
      if (spread >= fingerOpenRatio) {
        _handsOpen = true;
        _setFeedback(
          'Ahora cierra las manos formando un puño suave',
          Colors.green,
        );
      } else {
        _setFeedback('Abre bien los dedos y sepáralos', Colors.orange);
      }
      return;
    }

    if (spread <= fingerCloseRatio) {
      _handsOpen = false;
      _reps++;
      _progressLabel = 'Aperturas: $_reps / $fingerTargetReps';
      _progress = (_reps / fingerTargetReps).clamp(0.0, 1.0);
      if (_reps >= fingerTargetReps) {
        _finish(timeUp: false);
        return;
      }
      _setFeedback('✅ Repetición completada. Abre otra vez', Colors.green);
    } else {
      _setFeedback('Cierra los dedos con suavidad', Colors.green);
    }
  }

  // ---------- Círculos de antebrazos ----------
  void _evalForearmCircles(double dt) {
    final leftAngle = _elbowAngle(
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.leftWrist,
    );
    final rightAngle = _elbowAngle(
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.rightWrist,
    );
    final angles = [leftAngle, rightAngle].whereType<double>().toList();
    if (angles.isEmpty) return;

    final lw = _p(PoseLandmarkType.leftWrist);
    final rw = _p(PoseLandmarkType.rightWrist);
    final ls = _p(PoseLandmarkType.leftShoulder);
    final rs = _p(PoseLandmarkType.rightShoulder);
    if (lw == null || rw == null || ls == null || rs == null) return;

    final sw = _bodyScale;
    if (sw <= 0) return;
    final bent = angles.every(
      (a) => a >= forearmCircleMinBend && a <= forearmCircleMaxBend,
    );
    final shY = (ls.y + rs.y) / 2;
    final closeToBody = (lw.y > shY - sw * 0.2) && (rw.y > shY - sw * 0.2);

    _progressLabel =
        'Círculos: ${_motionSeconds.floor()} / ${forearmCircleTargetSec.toInt()} s';
    _progress = (_motionSeconds / forearmCircleTargetSec).clamp(0.0, 1.0);

    if (!bent || !closeToBody) {
      _forearmCircleX.clear();
      _forearmCircleY.clear();
      _setFeedback(
        'Dobla los codos junto al cuerpo y mantén las manos visibles',
        Colors.orange,
      );
      return;
    }

    final mx = ((lw.x + rw.x) / 2) * _ar / sw;
    final my = ((lw.y + rw.y) / 2) / sw;
    _forearmCircleX.add(_clock, mx);
    _forearmCircleY.add(_clock, my);
    final active =
        math.max(_forearmCircleX.range, _forearmCircleY.range) >=
        forearmCircleMove;
    if (active) _motionSeconds += dt;

    _progressLabel =
        'Círculos: ${_motionSeconds.floor()} / ${forearmCircleTargetSec.toInt()} s';
    _progress = (_motionSeconds / forearmCircleTargetSec).clamp(0.0, 1.0);

    if (_motionSeconds >= forearmCircleTargetSec) {
      _finish(timeUp: false);
      return;
    }

    _setFeedback(
      active
          ? '✅ ¡Muy bien! Sigue dibujando círculos con los antebrazos'
          : 'Dibuja círculos con las manos sin mover los codos',
      active ? Colors.green : Colors.orange,
    );
  }

  // ---------- Toques de hombro alternos ----------
  void _evalShoulderTaps(double dt) {
    final lw = _p(PoseLandmarkType.leftWrist);
    final rw = _p(PoseLandmarkType.rightWrist);
    final ls = _p(PoseLandmarkType.leftShoulder);
    final rs = _p(PoseLandmarkType.rightShoulder);
    if (lw == null || rw == null || ls == null || rs == null) return;

    final sw = _bodyScale;
    if (sw <= 0) return;
    final shY = (ls.y + rs.y) / 2;
    final leftTap =
        _dist(lw, rs) <= sw * tapReach && (lw.y - shY).abs() <= sw * 0.5;
    final rightTap =
        _dist(rw, ls) <= sw * tapReach && (rw.y - shY).abs() <= sw * 0.5;
    final side = leftTap && !rightTap
        ? 1
        : rightTap && !leftTap
        ? -1
        : 0;
    final released =
        _dist(lw, rs) >= sw * tapRelease && _dist(rw, ls) >= sw * tapRelease;

    _progressLabel = 'Toques: $_reps / $tapTargetReps';
    _progress = (_reps / tapTargetReps).clamp(0.0, 1.0);

    if (_tapNeedRelease) {
      if (released) {
        _tapNeedRelease = false;
        _setFeedback('Muy bien. Toca el otro hombro', Colors.green);
      } else {
        _setFeedback('Regresa la mano y prepara el otro toque', Colors.orange);
      }
      return;
    }

    if (side == 0) {
      _tapSide = 0;
      _tapHold = 0;
      _setFeedback(
        'Toca el hombro opuesto con una mano, luego alterna',
        Colors.orange,
      );
      return;
    }

    if (side == _lastTapSide) {
      _tapSide = 0;
      _tapHold = 0;
      _setFeedback('Ahora toca con la otra mano', Colors.orange);
      return;
    }

    if (_tapSide != side) {
      _tapSide = side;
      _tapHold = 0;
    }

    _tapHold += dt;
    if (_tapHold >= tapHoldSec) {
      _reps++;
      _lastTapSide = side;
      _tapSide = 0;
      _tapHold = 0;
      _tapNeedRelease = true;
      _progressLabel = 'Toques: $_reps / $tapTargetReps';
      _progress = (_reps / tapTargetReps).clamp(0.0, 1.0);
      if (_reps >= tapTargetReps) {
        _finish(timeUp: false);
        return;
      }
      _setFeedback('✅ Toque válido. Regresa la mano', Colors.green);
    } else {
      _setFeedback('Mantén el toque un instante', Colors.green);
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
    _calibStartClock = 0;
    _baseH = null;
    _shrugUp = false;
    _shrugHold = 0;
    _circlesPhase = false;
    _shoulderMx.clear();
    _shoulderMy.clear();
    _leftHand.clear();
    _rightHand.clear();
    _leftWristX.clear();
    _leftWristY.clear();
    _rightWristX.clear();
    _rightWristY.clear();
    _armsRaised = false;
    _curlBent = false;
    _chestOpen = false;
    _chestRest = false;
    _chestHold = 0;
    _trunkCalib.clear();
    _baseTrunkAngle = null;

    _neckTurnCalib.clear();
    _baseNeckTurn = null;
    _neckTurnSide = 0;
    _lastNeckTurnSide = 0;
    _neckTurnHold = 0;
    _neckTurnNeedCenter = false;

    _nodCalib.clear();
    _baseNod = null;
    _nodState = 0;
    _nodHold = 0;
    _nodNeedCenter = false;

    _armCircleX.clear();
    _armCircleY.clear();
    _lateralRaised = false;

    _hugHolding = false;
    _hugHold = 0;
    _hugRest = false;

    _prayerHolding = false;
    _prayerHold = 0;
    _prayerRest = false;

    _crossSide = 0;
    _lastCrossSide = 0;
    _crossHold = 0;
    _crossNeedCenter = false;

    _goalpostHolding = false;
    _goalpostHold = 0;
    _goalpostRest = false;

    _altShrugCalib.clear();
    _baseAltShrug = null;
    _altShrugSide = 0;
    _lastAltShrugSide = 0;
    _altShrugHold = 0;
    _altShrugNeedCenter = false;

    _handsOpen = false;

    _forearmCircleX.clear();
    _forearmCircleY.clear();

    _tapSide = 0;
    _lastTapSide = 0;
    _tapHold = 0;
    _tapNeedRelease = false;

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
      case ExerciseKind.armsUp:
        return 'Elevaciones completadas: $_reps de $armsUpTargetReps.';
      case ExerciseKind.curls:
        return 'Flexiones completadas: $_reps de $curlTargetReps.';
      case ExerciseKind.chest:
        return 'Aperturas completadas: $_reps de $chestTargetReps.';
      case ExerciseKind.sideBend:
        return 'Lados completados: $_reps de $trunkTargetSides.';
      case ExerciseKind.neckRotation:
        return 'Lados completados: $_reps de $neckTurnTargetSides.';
      case ExerciseKind.neckNod:
        return 'Movimientos completados: $_reps de $nodTargetReps.';
      case ExerciseKind.armCircles:
        return 'Círculos: ${_motionSeconds.floor()} s de ${armCircleTargetSec.toInt()} s.';
      case ExerciseKind.lateralRaise:
        return 'Elevaciones completadas: $_reps de $lateralTargetReps.';
      case ExerciseKind.selfHug:
        return 'Abrazos completados: $_reps de $hugTargetReps.';
      case ExerciseKind.prayerPress:
        return 'Prensas completadas: $_reps de $prayerTargetReps.';
      case ExerciseKind.crossShoulder:
        return 'Lados completados: $_reps de $crossTargetSides.';
      case ExerciseKind.goalpost:
        return 'Posturas completadas: $_reps de $goalpostTargetReps.';
      case ExerciseKind.alternatingShrug:
        return 'Encogimientos completados: $_reps de $altShrugTargetReps.';
      case ExerciseKind.fingerSpread:
        return 'Aperturas completadas: $_reps de $fingerTargetReps.';
      case ExerciseKind.forearmCircles:
        return 'Círculos: ${_motionSeconds.floor()} s de ${forearmCircleTargetSec.toInt()} s.';
      case ExerciseKind.shoulderTaps:
        return 'Toques completados: $_reps de $tapTargetReps.';
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

    // Detenemos el stream antes de pedir el guardado y de cerrar la pantalla.
    try {
      await _cameraController?.stopImageStream();
    } catch (_) {}

    // Catálogo en modo local: el ejercicio se puede practicar, pero no hay
    // un id en la base de datos con el que registrar la pausa.
    if (widget.ejercicioId <= 0) {
      if (mounted) Navigator.pop(context, completada);
      return;
    }

    if (mounted) {
      setState(() => _feedback = 'Guardando tu progreso...');
    }

    // Solo los movimientos con detección confirmada cuentan para SST.
    // Los ejercicios visuales/genericos se guardan como actividad adicional.
    final tipo = _showsAvatar
        ? ActivityTypes.detectedExercise
        : ActivityTypes.additionalRoutine;

    final guardado = await _ejercicioService
        .registrarPausa(
          usuarioId: widget.usuarioId,
          ejercicioId: widget.ejercicioId,
          completada: completada,
          tipo: tipo,
        )
        .timeout(const Duration(seconds: 5), onTimeout: () => false);

    if (!guardado) {
      debugPrint('No se pudo guardar la pausa en el backend');
    }

    if (!mounted) return;
    Navigator.pop(context, completada);
  }

  void _finish({required bool timeUp, bool manual = false}) {
    _timer?.cancel();
    if (!mounted) return;

    final completada =
        !manual &&
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

  Widget _overlayButton({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: active ? 0.55 : 0.35),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: active ? 0.40 : 0.18),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: active ? Colors.tealAccent : Colors.white70,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraArea() {
    if (!(_isCameraReady && _cameraController != null)) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.green),
      );
    }
    // El overlay se calcula sobre el frame ya rotado. Usar el mismo aspecto
    // que ese frame evita que el esqueleto quede desplazado respecto al video.
    final frameSize = _imageSize;
    final aspectRatio =
        frameSize != null && frameSize.width > 0 && frameSize.height > 0
        ? frameSize.width / frameSize.height
        : _cameraController!.value.aspectRatio;

    return Center(
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(_cameraController!),
            if (_showSkeleton &&
                _personVisible &&
                _pts.isNotEmpty &&
                frameSize != null)
              CustomPaint(
                painter: PosePainter(_pts, frameSize, _mirrorOverlay),
              ),
            if (_kind != ExerciseKind.visual)
              Positioned(
                top: 10,
                left: 10,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _overlayButton(
                      icon: _showSkeleton
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      label: _showSkeleton ? 'Ocultar guía' : 'Ver guía',
                      active: _showSkeleton,
                      onTap: () =>
                          setState(() => _showSkeleton = !_showSkeleton),
                    ),
                    const SizedBox(width: 8),
                    _overlayButton(
                      icon: Icons.flip_rounded,
                      label: 'Espejo',
                      active: _mirrorOverlay,
                      onTap: () =>
                          setState(() => _mirrorOverlay = !_mirrorOverlay),
                    ),
                  ],
                ),
              ),
            if (_showsAvatar)
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Container(
                    width: 148,
                    height: 214,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.30),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.26),
                      ),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                            child: ExerciseAvatar(kind: _kind),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            'GUÍA',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.55),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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

          // Controles adaptados al ancho: en móvil los botones se vuelven
          // compactos (e incluso solo icono) para no empujar el reloj.
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppResponsive.gutter(context),
              vertical: 10,
            ),
            color: Colors.black87,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 520;
                final soloIcono = constraints.maxWidth < 380;
                final estiloBoton = ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 12 : 24,
                    vertical: 12,
                  ),
                  minimumSize: Size(soloIcono ? 46 : 0, 46),
                  visualDensity: compact ? VisualDensity.compact : null,
                );
                final estiloFinalizar = estiloBoton.copyWith(
                  backgroundColor: WidgetStatePropertyAll<Color>(Colors.red),
                );

                return Row(
                  children: [
                    Text(
                      _formattedTime,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 24 : 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Tooltip(
                      message: 'Iniciar ejercicio',
                      child: ElevatedButton.icon(
                        onPressed: _isRunning || _guardando
                            ? null
                            : _startTimer,
                        icon: const Icon(Icons.play_arrow),
                        label: soloIcono
                            ? const SizedBox.shrink()
                            : Text(_finished ? "Repetir" : "Iniciar"),
                        style: estiloBoton,
                      ),
                    ),
                    SizedBox(width: compact ? 8 : 12),
                    Tooltip(
                      message: 'Finalizar ejercicio',
                      child: ElevatedButton.icon(
                        onPressed: _guardando
                            ? null
                            : _isRunning
                            ? () {
                                _finish(timeUp: false, manual: true);
                              }
                            : () => Navigator.pop(context),
                        icon: const Icon(Icons.stop),
                        label: soloIcono
                            ? const SizedBox.shrink()
                            : const Text("Finalizar"),
                        style: estiloFinalizar,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
