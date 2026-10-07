import 'package:flutter/material.dart';

main
import '../../main.dart';
import '../../widgets/ergovida_logo.dart';
=======
import '../../data/services/auth_service.dart';

develop
import '../auth/login_page.dart';
import '../exercises/exercises_page.dart';
import '../routines/routine_page.dart';
import '../settings/settings_page.dart';
import '../statistics/statistics_page.dart';

class HomePage extends StatelessWidget {
main
  final AppThemeController? themeController;

  const HomePage({super.key, this.themeController});
=======

  final LoginUser usuario;

  // const HomePage({super.key});
  const HomePage({
    super.key,
    required this.usuario,
  });
develop

  @override
  Widget build(BuildContext context) {
    final isDark = themeController?.isDark ?? Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFEAF3F8);
    final panelBg = isDark ? const Color(0xFF111C2E) : const Color(0xFFF8FBFD);
    final textPrimary = isDark ? Colors.white : const Color(0xFF10243A);
    final textSecondary = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF5E7387);
    final sidebarTop = isDark ? const Color(0xFF0B1B2B) : const Color(0xFF0E2238);
    final sidebarBottom = isDark ? const Color(0xFF13233A) : const Color(0xFF122D46);

    return Scaffold(
      backgroundColor: pageBg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D2032), Color(0xFFEAF3F8), Color(0xFFEAF3F8)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 270,
              padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [sidebarTop, sidebarBottom],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Column(
                    children: const [
                      ErgoVidaLogo(size: 78, showText: false),
                      SizedBox(height: 12),
                      Text(
                        'ErgoVida',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                _menuItem(
                  context,
                  Icons.dashboard_rounded,
                  'Dashboard',
                  true,
                  () {},
                ),
                _menuItem(
                  context,
                  Icons.fitness_center_rounded,
                  'Ejercicios',
                  false,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ExercisesPage()),
                    );
                  },
                ),
                _menuItem(
                  context,
                  Icons.repeat_rounded,
                  'Rutinas',
                  false,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RoutinePage()),
                    );
                  },
                ),
                _menuItem(
                  context,
                  Icons.bar_chart_rounded,
                  'Estadísticas',
                  false,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StatisticsPage()),
                    );
                  },
                ),
                _menuItem(
                  context,
                  Icons.settings_rounded,
                  'Configuración',
                  false,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SettingsPage(themeController: themeController),
                      ),
                    );
                  },
                ),
                const Spacer(),
                const Divider(color: Color(0xFF31506C), thickness: 1),
                const SizedBox(height: 8),
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    leading: const Icon(Icons.logout_rounded, color: Color(0xFFFF7A7A), size: 22),
                    title: const Text(
                      'Cerrar sesión',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                        (route) => false,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
main
            Expanded(
              child: Container(
                color: pageBg,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bienvenido a ErgoVida',
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 38,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Gestiona tus pausas activas y mejora tu bienestar laboral.',
                              style: TextStyle(
                                fontSize: 17,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF123A35)
                              : const Color(0xFFDCF9F2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Hoy',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF8BE7D7) : const Color(0xFF116A5D),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],

          // CONTENIDO PRINCIPAL
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(30),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  // const Text(
                  //   "Bienvenido a ErgoVida",
                  Text(
                    " Hola, ${usuario.nombre}",
                    // style: TextStyle(
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    // "Gestiona tus pausas activas y mejora tu bienestar laboral.",
                    "Bienvenido a ErgoVida",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      // color: Colors.grey,
                      color: Colors.black87,
                      // fontSize: 18,
                    ),
                  ),

                  SizedBox(height: 6),

                  const Text(
                    "Gestiona tus pausas activas y mejora tu bienestar laboral.",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
develop
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          isDark,
                          panelBg,
                          'Pausas realizadas',
                          '24',
                          Icons.timer_rounded,
                          const Color(0xFF22C55E),
                          const Color(0xFFDCFBE7),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: _statCard(
                          isDark,
                          panelBg,
                          'Ejercicios completados',
                          '58',
                          Icons.fitness_center_rounded,
                          const Color(0xFF1F7FC0),
                          const Color(0xFFE1F2FF),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: _statCard(
                          isDark,
                          panelBg,
                          'Tiempo activo',
                          '12h',
                          Icons.access_time_rounded,
                          const Color(0xFFF59E0B),
                          const Color(0xFFFFF1D6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Acciones rápidas',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      _actionButton(
                        context,
                        'Iniciar pausa activa',
                        Icons.play_circle_fill_rounded,
                        const Color(0xFF22C55E),
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RoutinePage()),
                          );
                        },
                      ),
                      _actionButton(
                        context,
                        'Ver ejercicios',
                        Icons.fitness_center_rounded,
                        const Color(0xFF1F7FC0),
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ExercisesPage()),
                          );
                        },
                      ),
                      _actionButton(
                        context,
                        'Consultar estadísticas',
                        Icons.bar_chart_rounded,
                        const Color(0xFFF59E0B),
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const StatisticsPage()),
                          );
                        },
                      ),
                      _actionButton(
                        context,
                        'Configuración',
                        Icons.settings_rounded,
                        const Color(0xFF7C4DFF),
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SettingsPage(themeController: themeController),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _menuItem(
    BuildContext context,
    IconData icon,
    String title,
    bool active,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: active
            ? (isDark ? const Color(0xFF1F7FC0).withValues(alpha: 0.26) : const Color(0xFF1F7FC0).withValues(alpha: 0.18))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          leading: Icon(icon, color: Colors.white, size: 22),
          title: Text(
            title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          onTap: onTap,
        ),
      ),
    );
  }

  static Widget _statCard(
    bool isDark,
    Color panelBg,
    String title,
    String value,
    IconData icon,
    Color color,
    Color surface,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      height: 200,
      decoration: BoxDecoration(
        color: panelBg,
        border: Border.all(
          color: isDark ? const Color(0xFF24364C) : const Color(0xFFDBEAF3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0E2238),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0E2238),
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF5E7387),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _actionButton(
    BuildContext context,
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final actionColor = isDark
      ? Color.alphaBlend(const Color(0xFF0E2238), color).withValues(alpha: 0.9)
      : color;

    return SizedBox(
      width: 260,
      height: 94,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 26),
        label: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: actionColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
      ),
    );
  }
}