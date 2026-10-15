import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tarea/features/exercises/exercise_camera_page.dart';
import 'package:tarea/features/routines/routine_page.dart';
import 'package:tarea/main.dart';

void main() {
  testWidgets('La app muestra la pantalla de login', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Bienvenido a ErgoVida'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Crear cuenta nueva'), findsOneWidget);
  });

  test('La cámara informa que no es compatible en Windows', () {
    final message = ExerciseCameraPage.unsupportedCameraMessageForPlatform(TargetPlatform.windows);

    expect(message, contains('no está disponible'));
    expect(ExerciseCameraPage.isCameraSupportedOnPlatform(TargetPlatform.windows), isFalse);
  });

  test('El tema oscuro se guarda y carga correctamente', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = AppThemeController();

    await controller.setTheme(true);
    expect(controller.isDark, isTrue);

    final storage = await SharedPreferences.getInstance();
    expect(storage.getBool('theme_dark_mode'), isTrue);

    final reloaded = AppThemeController();
    await reloaded.loadTheme();
    expect(reloaded.isDark, isTrue);
  });

  testWidgets('La página de rutinas muestra planes con detalle', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: RoutinePage()));

    expect(find.text('Rutinas recomendadas'), findsOneWidget);
    expect(find.textContaining('Rutina'), findsWidgets);
    expect(find.textContaining('Iniciar'), findsWidgets);
  });
}
