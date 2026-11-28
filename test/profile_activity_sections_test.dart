import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarea/core/theme/app_theme.dart';
import 'package:tarea/data/models/user_model.dart';
import 'package:tarea/features/profile/profile_page.dart';

void main() {
  testWidgets('el perfil separa ejercicios SST de rutinas opcionales', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: ProfilePage(
          usuario: const UserModel(
            id: 0,
            nombre: 'Prueba',
            correo: 'prueba@ergovida.com',
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));

    expect(tester.takeException(), isNull);
    expect(find.text('Ejercicios obligatorios'), findsOneWidget);
    expect(find.text('Cuenta para tu seguimiento de SST'), findsOneWidget);
    expect(
      find.text(
        'Tu líder de SST solo revisa los ejercicios con detección de movimiento. Haz muchos de estos cada día.',
      ),
      findsOneWidget,
    );
    expect(find.text('0 de 8 hechos esta semana'), findsOneWidget);
    expect(find.text('No completo'), findsOneWidget);

    expect(find.text('Rutinas adicionales (opcionales)'), findsOneWidget);
    expect(
      find.text('Opcional: no cuenta para SST, pero sí para tus logros'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
