import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarea/core/theme/app_theme.dart';
import 'package:tarea/data/models/user_model.dart';
import 'package:tarea/features/home/home_page.dart';
import 'package:tarea/main.dart';

void main() {
  testWidgets('el dashboard renderiza sin errores en escritorio', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: HomePage(
          themeController: AppThemeController.instance,
          usuario: const UserModel(
            id: 1,
            nombre: 'Ana',
            correo: 'ana@ergovida.com',
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 600));

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Hola, Ana'), findsOneWidget);
    expect(find.text('Acciones rápidas'), findsOneWidget);

    final accionesAntes = tester.getTopLeft(find.text('Acciones rápidas'));
    await tester.drag(
      find.byType(CustomScrollView),
      const Offset(0, -220),
    );
    await tester.pumpAndSettle();
    final accionesDespues = tester.getTopLeft(find.text('Acciones rápidas'));
    expect(accionesDespues.dy, lessThan(accionesAntes.dy));

    await tester.tap(find.byTooltip('Cambiar tema'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Hola, Ana'), findsOneWidget);
    expect(find.text('Acciones rápidas'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
