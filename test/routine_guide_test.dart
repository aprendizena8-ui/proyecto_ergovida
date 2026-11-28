import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarea/core/theme/app_theme.dart';
import 'package:tarea/features/pauses/guided_pause_page.dart';
import 'package:tarea/features/routines/routine_page.dart';
import 'package:tarea/widgets/routine_avatar.dart';

void main() {
  testWidgets('la sección de rutinas se organiza por categorías', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const RoutinePage()),
    );
    await tester.pump(const Duration(milliseconds: 700));

    expect(tester.takeException(), isNull);
    expect(find.text('Rutinas adicionales (opcionales)'), findsOneWidget);
    expect(find.text('Rutina Oficina'), findsOneWidget);

    await tester.tap(find.text('Casa').first);
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    expect(find.text('Rutina Casa'), findsOneWidget);
    expect(find.text('Rutina Oficina'), findsNothing);
    expect(find.byType(RoutineAvatar), findsWidgets);
    expect(find.text('Opcional · no suma a SST'), findsWidgets);
    expect(find.text('Suma a logros'), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('guarda y recupera las rutinas favoritas', (tester) async {
    SharedPreferences.setMockInitialValues({
      'rutinas_favoritas_0': ['Rutina Casa'],
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const RoutinePage()),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('1 favorita'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.favorite_border_rounded).first);
    await tester.pump(const Duration(milliseconds: 200));

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getStringList('rutinas_favoritas_0'),
      contains('Rutina Oficina'),
    );
    expect(find.text('2 favoritas'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('la sesión guiada muestra el avatar y el movimiento', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const GuidedPausePage(
          nombre: 'Sentadillas con silla',
          duracionMin: 5,
          categoria: 'Casa',
          avatarKind: RoutineAvatarKind.squat,
          avatarColor: AppPalette.teal,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
    expect(find.text('SIGUE AL AVATAR'), findsOneWidget);
    expect(find.text(RoutineAvatarKind.squat.label), findsOneWidget);
    expect(find.text('5 min'), findsOneWidget);
    expect(find.byType(RoutineAvatar), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('las tarjetas muestran la información de cada ejercicio', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const RoutinePage()),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Ver 5 ejercicios · 10 min'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Ver 5 ejercicios · 10 min'),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Ver 5 ejercicios · 10 min'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Acomoda tu puesto'), findsOneWidget);
    expect(
      find.text(
        'Pantalla a la altura de los ojos, hombros atrás y pies apoyados.',
      ),
      findsOneWidget,
    );
    expect(find.text('120 s'), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('la sesión guiada avanza de ejercicio y muestra sus pasos', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const GuidedPausePage(
          nombre: 'Rutina de prueba',
          duracionMin: 1,
          categoria: 'Casa',
          pasos: [
            RoutinePaso(
              nombre: 'Primer movimiento',
              detalle: 'Haz el primer movimiento despacio.',
              segundos: 1,
              kind: RoutineAvatarKind.squat,
            ),
            RoutinePaso(
              nombre: 'Segundo movimiento',
              detalle: 'Continúa con el segundo movimiento.',
              segundos: 59,
              kind: RoutineAvatarKind.neckStretch,
            ),
          ],
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(find.text('PASO 1 DE 2'), findsOneWidget);
    expect(find.text('Primer movimiento'), findsWidgets);
    expect(find.text('Haz el primer movimiento despacio.'), findsOneWidget);

    await tester.ensureVisible(find.text('Iniciar pausa'));
    await tester.tap(find.text('Iniciar pausa'));
    await tester.pump(const Duration(seconds: 2));

    expect(tester.takeException(), isNull);
    expect(find.text('PASO 2 DE 2'), findsOneWidget);
    expect(find.text('Segundo movimiento'), findsWidgets);
    expect(find.text('Continúa con el segundo movimiento.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('el avatar dibuja todos los movimientos', (tester) async {
    for (final kind in RoutineAvatarKind.values) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 160,
                height: 190,
                child: RoutineAvatar(
                  kind: kind,
                  color: AppPalette.teal,
                  lineColor: Colors.white,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 420));
      expect(tester.takeException(), isNull);
    }

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
