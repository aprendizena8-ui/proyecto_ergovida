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
    expect(find.text('Rutinas recomendadas'), findsOneWidget);
    expect(find.text('Rutina Oficina'), findsOneWidget);

    await tester.tap(find.text('Casa').first);
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    expect(find.text('Rutina Casa'), findsOneWidget);
    expect(find.text('Rutina Oficina'), findsNothing);
    expect(find.byType(RoutineAvatar), findsWidgets);

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
