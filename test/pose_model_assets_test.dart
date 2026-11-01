import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('incluye los modelos de deteccion de pose en la app', () async {
    final yolo = await rootBundle.load('assets/models/yolov8n_float32.tflite');
    final landmark = await rootBundle.load(
      'assets/models/pose_landmark_full.tflite',
    );

    expect(yolo.lengthInBytes, greaterThan(1000000));
    expect(landmark.lengthInBytes, greaterThan(1000000));
  });
}
