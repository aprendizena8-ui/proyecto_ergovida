import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'data/models/user_model.dart';
import 'data/services/auth_service.dart';
import 'data/services/reminder_service.dart';
import 'features/auth/login_page.dart';
import 'features/home/home_page.dart';

final RouteObserver<PageRoute<dynamic>> appRouteObserver =
    RouteObserver<PageRoute<dynamic>>();

const Color brandNavy = Color(0xFF0E2238);
const Color brandBlue = Color(0xFF1F7FC0);
const Color brandCyan = Color(0xFF39C7D5);
const Color brandTeal = Color(0xFF2DD4BF);
const Color brandBackground = Color(0xFFF4F7FB);
const Color brandCard = Color(0xFFFFFFFF);
const Color brandText = Color(0xFF10243A);
const Color brandMuted = Color(0xFF5E7387);

class AppThemeController extends ChangeNotifier {
  static const String _themeKey = 'theme_dark_mode';

  static final AppThemeController instance = AppThemeController._internal();

  factory AppThemeController() => instance;

  AppThemeController._internal();

  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = prefs.getBool(_themeKey) == true
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }

  Future<void> setTheme(bool dark) async {
    _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, dark);
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppThemeController _themeController = AppThemeController();

  late final Future<UserModel?> _initialSession;

  static final ThemeData _lightTheme = AppTheme.lightTheme;
  static final ThemeData _darkTheme = AppTheme.darkTheme;

  ThemeData _buildLightTheme() => _lightTheme;

  ThemeData _buildDarkTheme() => _darkTheme;

  @override
  void initState() {
    super.initState();
    _initialSession = AuthService.restoreSession();
    _themeController.loadTheme();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'ErgoVida',
          debugShowCheckedModeBanner: false,
          navigatorObservers: [appRouteObserver],
          scaffoldMessengerKey: ReminderService.messengerKey,
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            scrollbars: false,
          ),
          themeMode: _themeController.themeMode,
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          home: FutureBuilder(
            future: _initialSession,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _SplashScreen();
              }

              final usuario = snapshot.data;
              if (usuario != null) {
                return HomePage(
                  themeController: _themeController,
                  usuario: usuario,
                );
              }

              return LoginPage(themeController: _themeController);
            },
          ),
        );
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [brandNavy, Color(0xFF123A56)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: brandTeal,
                ),
              ),
              SizedBox(height: 18),
              Text(
                'ErgoVida',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
