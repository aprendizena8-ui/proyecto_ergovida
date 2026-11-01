import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pose_detection/pose_detection.dart';

import 'exercise_camera_models.dart';

/// Cache global del PoseDetector (se crea una sola vez por sesión).
PoseDetector? _globalPoseDetector;

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

/// Obtiene el detector global. La primera vez tarda 1-2 seg,
/// después es instantáneo.
Future<PoseDetector> getPoseDetector() async {
  if (_globalPoseDetector != null) return _globalPoseDetector!;

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
    minLandmarkScore: poseMinLandmarkScore,
  );

  _globalPoseDetector = detector;
  return detector;
}
