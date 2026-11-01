import 'package:pose_detection/pose_detection.dart';
import 'exercise_camera_models.dart';

/// Cache global del PoseDetector (se crea una sola vez por sesión).
PoseDetector? _globalPoseDetector;

/// Obtiene el detector global. La primera vez tarda 1-2 seg,
/// después es instantáneo.
Future<PoseDetector> getPoseDetector() async {
  if (_globalPoseDetector != null) return _globalPoseDetector!;
  _globalPoseDetector = await PoseDetector.create(
    landmarkModel: poseLandmarkModel,
    // Solo analizamos a la persona principal: menos post-proceso por frame.
    maxDetections: 2,
    // Tolerante con cuerpos parcialmente fuera de cuadro, pero exigente con
    // la calidad global de los landmarks.
    detectorConf: poseDetectorConf,
    minLandmarkScore: poseMinLandmarkScore,
  );
  return _globalPoseDetector!;
}
