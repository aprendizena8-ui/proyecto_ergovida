import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pose_detection/pose_detection.dart';

import 'exercise_camera_models.dart';

/// Cache global del PoseDetector (se crea una sola vez por sesión).
PoseDetector? _globalPoseDetector;

/// Inicialización en curso, para que dos pantallas abiertas a la vez no carguen
/// los modelos dos veces ni intenten inicializar el mismo detector dos veces.
Future<PoseDetector>? _inicializando;

/// Carga el modelo desde los assets de la app y, si por alguna razón no se
/// empaquetaron, recurre a los assets del paquete [pose_detection].
Future<ByteData> _loadModelAsset(String name) async {
  try {
    return await rootBundle.load('assets/models/$name');
  } catch (error) {
    debugPrint('No se pudo cargar assets/models/$name: $error');
    return rootBundle.load('packages/pose_detection/assets/models/$name');
  }
}

Future<PoseDetector> _createDetector() async {
  final landmarkName = 'pose_landmark_${poseLandmarkModel.name}.tflite';
  final yoloData = await _loadModelAsset('yolov8n_float32.tflite');
  final landmarkData = await _loadModelAsset(landmarkName);

  final detector = PoseDetector();
  await detector.initializeFromBuffers(
    yoloBytes: yoloData.buffer.asUint8List(
      yoloData.offsetInBytes,
      yoloData.lengthInBytes,
    ),
    landmarkBytes: landmarkData.buffer.asUint8List(
      landmarkData.offsetInBytes,
      landmarkData.lengthInBytes,
    ),
    landmarkModel: poseLandmarkModel,
    // Solo analizamos a la persona principal: menos post-proceso por frame.
    maxDetections: 2,
    // Tolerante con cuerpos parcialmente fuera de cuadro, pero exigente con
    // la calidad global de los landmarks.
    detectorConf: poseDetectorConf,
    detectorIou: 0.45,
    minLandmarkScore: poseMinLandmarkScore,
    // XNNPACK permite analizar más frames por segundo con el mismo modelo,
    // que es lo que hace que el seguimiento se sienta fluido.
    performanceConfig: const PerformanceConfig.xnnpack(numThreads: 4),
  );

  _globalPoseDetector = detector;
  return detector;
}

/// Obtiene el detector global. La primera vez tarda 1-2 segundos,
/// después es instantáneo. Las llamadas concurrentes comparten la misma
/// inicialización.
Future<PoseDetector> getPoseDetector() {
  final listo = _globalPoseDetector;
  if (listo != null) return Future.value(listo);

  return _inicializando ??= _createDetector().whenComplete(() {
    _inicializando = null;
  });
}
