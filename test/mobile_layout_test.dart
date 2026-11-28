import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarea/core/theme/app_theme.dart';
import 'package:tarea/data/models/user_model.dart';
import 'package:tarea/features/auth/login_page.dart';
import 'package:tarea/features/auth/register_page.dart';
import 'package:tarea/features/exercises/exercises_page.dart';
import 'package:tarea/features/home/home_page.dart';
import 'package:tarea/features/routines/routine_page.dart';
import 'package:tarea/main.dart';

void main() {
  void sinDesborde(WidgetTester tester) {
    expect(tester.takeException(), isNull);
  }

  void configurarPantalla(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> descargarTodo(WidgetTester tester, Finder scrollable) async {
    final position = tester.state<ScrollableState>(scrollable).position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pump(const Duration(milliseconds: 200));
    position.jumpTo(0);
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets('login y registro caben en 320 dp', (tester) async {
    SharedPreferences.setMockInitialValues({});
    configurarPantalla(tester, const Size(320, 568));

    for (final pagina in [const LoginPage(), const RegisterPage()]) {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.lightTheme, home: pagina),
      );
      await tester.pump(const Duration(milliseconds: 300));

      sinDesborde(tester);
      await tester.ensureVisible(find.byType(SingleChildScrollView));
      await tester.pump();
      sinDesborde(tester);
    }

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('el home móvil usa navegación inferior y no desborda', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    configurarPantalla(tester, const Size(360, 640));

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

    sinDesborde(tester);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Ejercicios'), findsOneWidget);
    expect(find.text('Rutinas'), findsOneWidget);

    final scrollable = find
        .descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(Scrollable),
        )
        .first;
    await descargarTodo(tester, scrollable);
    sinDesborde(tester);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('ejercicios y rutinas caben en 320 dp', (tester) async {
    SharedPreferences.setMockInitialValues({});
    configurarPantalla(tester, const Size(320, 568));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const ExercisesPage(usuarioId: 1, esAdmin: false),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));

    sinDesborde(tester);
    expect(find.text('Pausas activas guiadas'), findsOneWidget);
    await descargarTodo(tester, find.byType(Scrollable).first);
    sinDesborde(tester);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const RoutinePage()),
    );
    await tester.pump(const Duration(milliseconds: 700));

    sinDesborde(tester);
    expect(find.text('Rutinas adicionales (opcionales)'), findsOneWidget);
    await descargarTodo(tester, find.byType(Scrollable).first);
    sinDesborde(tester);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
