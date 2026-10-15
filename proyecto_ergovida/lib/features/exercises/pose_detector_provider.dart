import 'package:pose_detection/pose_detection.dart';
import 'exercise_camera_models.dart';

/// Cache global del PoseDetector (se crea una sola vez por sesión).
PoseDetector? _globalPoseDetector;

/// Obtiene el detector global. La primera vez tarda 1-2 seg,
/// después es instantáneo.
Future<PoseDetector> getPoseDetector() async {
  if (_globalPoseDetector != null) return _globalPoseDetector!;
  _globalPoseDetector = useHeavyModel
      ? await PoseDetector.create(landmarkModel: PoseLandmarkModel.heavy)
      : await PoseDetector.create();
  return _globalPoseDetector!;
}