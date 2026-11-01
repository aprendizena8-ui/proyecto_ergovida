import 'package:flutter/material.dart';

import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/estadisticas_service.dart';
import '../../data/services/pausa_service.dart';
import '../../main.dart';
import '../../widgets/ergovida_logo.dart';
import '../../widgets/user_avatar.dart';
import '../admin/admin_page.dart';
import '../auth/login_page.dart';
import '../exercises/exercises_page.dart';
import '../profile/profile_page.dart';
import '../routines/routine_page.dart';
import '../settings/settings_page.dart';
import '../statistics/statistics_page.dart';

class HomePage extends StatefulWidget {
  final AppThemeController? themeController;
  final UserModel? usuario;

  const HomePage({super.key, this.themeController, this.usuario});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final EstadisticasService _estadisticasService = EstadisticasService();
  final PausaService _pausaService = PausaService();

  UserModel? _usuario;
  int _pausas = 0;
  int _completados = 0;
  int _minutos = 0;
  bool _cargando = true;

  int get _usuarioId => _usuario?.id ?? AuthService.usuarioId;
  bool get _esAdmin =>
      (_usuario?.rol ?? AuthService.usuarioRol).toUpperCase() ==
      'ADMINISTRADOR';

  @override
  void initState() {
    super.initState();
    _usuario = widget.usuario ?? AuthService.currentUser;
    _cargarResumen();
  }

  Future<void> _cargarResumen() async {
    if (_usuarioId <= 0) {
      if (mounted) setState(() => _cargando = false);
      return;
    }

    if (mounted) setState(() => _cargando = true);

    final resultados = await Future.wait([
      _estadisticasService.obtenerPorUsuario(_usuarioId),
      _pausaService.obtenerPorUsuario(_usuarioId),
    ]);

    final estadisticas = resultados[0];
    final pausas = resultados[1];

    var pausasTotales = 0;
    var minutosTotales = 0;
    for (final e in estadisticas) {
      pausasTotales += _asInt(e['pausasRealizadas']);
      minutosTotales += _asInt(e['minutosActivos']);
    }

    final completadas = pausas
        .where((p) => p is Map && p['completada'] == true)
        .length;

    if (pausasTotales == 0 && pausas.isNotEmpty) {
      pausasTotales = pausas.length;
    }

    if (!mounted) return;
    setState(() {
      _pausas = pausasTotales;
      _completados = completadas;
      _minutos = minutosTotales;
      _cargando = false;
    });
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String get _tiempoActivo {
    if (_minutos <= 0) return '0 min';
    if (_minutos < 60) return '$_minutos min';
    final horas = _minutos ~/ 60;
    final minutos = _minutos % 60;
    return minutos == 0 ? '${horas}h' : '${horas}h ${minutos}m';
  }

  Future<void> _abrir(Widget pagina) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => pagina));
    if (mounted) {
      setState(() {});
      _cargarResumen();
    }
  }

  Future<void> _abrirPerfil() async {
    final usuario = _usuario;
    if (usuario == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfilePage(usuario: usuario)),
    );
    if (!mounted) return;
    setState(() {
      _usuario = AuthService.currentUser ?? _usuario;
    });
    _cargarResumen();
  }

  Future<void> _cerrarSesion() async {
    await AuthService.clearSession();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppThemeController.instance,
      builder: (context, _) {
        final isDark = AppThemeController.instance.isDark;
        final pageBg = isDark
            ? const Color(0xFF0B1424)
            : const Color(0xFFEAF3F8);
        final textPrimary = isDark ? Colors.white : brandText;
        final textSecondary = isDark ? const Color(0xFFCBD5E1) : brandMuted;

        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 980;

            return Scaffold(
              backgroundColor: pageBg,
              drawer: wide
                  ? null
                  : Drawer(
                      width: 286,
                      child: _Sidebar(
                        usuario: _usuario,
                        esAdmin: _esAdmin,
                        isDark: isDark,
                        onDashboard: () {},
                        onEjercicios: () =>
                            _abrir(ExercisesPage(usuarioId: _usuarioId)),
                        onRutinas: () => _abrir(const RoutinePage()),
                        onEstadisticas: () =>
                            _abrir(StatisticsPage(usuarioId: _usuarioId)),
                        onPerfil: _abrirPerfil,
                        onAdmin: () => _abrir(const AdminPage()),
                        onConfiguracion: () => _abrir(
                          SettingsPage(
                            themeController: widget.themeController,
                            usuario: _usuario,
                          ),
                        ),
                        onSalir: _cerrarSesion,
                      ),
                    ),
              body: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? const [Color(0xFF0B1424), Color(0xFF10243A)]
                        : [const Color(0xFF0D2032), pageBg, pageBg],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: Row(
                  children: [
                    if (wide)
                      SizedBox(
                        width: 286,
                        child: _Sidebar(
                          usuario: _usuario,
                          esAdmin: _esAdmin,
                          isDark: true,
                          onDashboard: () {},
                          onEjercicios: () =>
                              _abrir(ExercisesPage(usuarioId: _usuarioId)),
                          onRutinas: () => _abrir(const RoutinePage()),
                          onEstadisticas: () =>
                              _abrir(StatisticsPage(usuarioId: _usuarioId)),
                          onPerfil: _abrirPerfil,
                          onAdmin: () => _abrir(const AdminPage()),
                          onConfiguracion: () => _abrir(
                            SettingsPage(
                              themeController: widget.themeController,
                              usuario: _usuario,
                            ),
                          ),
                          onSalir: _cerrarSesion,
                        ),
                      ),
                    Expanded(
                      child: Container(
                        color: pageBg,
                        child: CustomScrollView(
                          slivers: [
                            SliverAppBar(
                              pinned: true,
                              backgroundColor: pageBg,
                              surfaceTintColor: Colors.transparent,
                              automaticallyImplyLeading: !wide,
                              title: wide
                                  ? null
                                  : const Text(
                                      'ErgoVida',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                              actions: [
                                if (!wide)
                                  IconButton(
                                    tooltip: 'Actualizar',
                                    onPressed: _cargarResumen,
                                    icon: const Icon(Icons.refresh_rounded),
                                  ),
                                const SizedBox(width: 8),
                              ],
                            ),
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                wide ? 34 : 20,
                                8,
                                wide ? 34 : 20,
                                34,
                              ),
                              sliver: SliverList(
                                delegate: SliverChildListDelegate([
                                  _cabecera(textPrimary, textSecondary, isDark),
                                  const SizedBox(height: 26),
                                  _statGrid(constraints.maxWidth, isDark),
                                  const SizedBox(height: 34),
                                  Text(
                                    'Acciones rápidas',
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Wrap(
                                    spacing: 18,
                                    runSpacing: 18,
                                    children: [
                                      _actionButton(
                                        context,
                                        'Iniciar pausa activa',
                                        Icons.play_circle_fill_rounded,
                                        brandBlue,
                                        () => _abrir(const RoutinePage()),
                                      ),
                                      _actionButton(
                                        context,
                                        'Ver ejercicios',
                                        Icons.fitness_center_rounded,
                                        brandNavy,
                                        () => _abrir(
                                          ExercisesPage(usuarioId: _usuarioId),
                                        ),
                                      ),
                                      _actionButton(
                                        context,
                                        'Consultar estadísticas',
                                        Icons.bar_chart_rounded,
                                        brandTeal,
                                        () => _abrir(
                                          StatisticsPage(usuarioId: _usuarioId),
                                        ),
                                      ),
                                      _actionButton(
                                        context,
                                        'Configuración',
                                        Icons.settings_rounded,
                                        brandCyan,
                                        () => _abrir(
                                          SettingsPage(
                                            themeController:
                                                widget.themeController,
                                            usuario: _usuario,
                                          ),
                                        ),
                                      ),
                                      if (_esAdmin)
                                        _actionButton(
                                          context,
                                          'Panel administrador',
                                          Icons.admin_panel_settings_rounded,
                                          brandTeal,
                                          () => _abrir(const AdminPage()),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 30),
                                  _resumenCard(
                                    textPrimary,
                                    textSecondary,
                                    isDark,
                                  ),
                                ]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _cabecera(Color textPrimary, Color textSecondary, bool isDark) {
    final nombre = _usuario?.nombre.trim() ?? '';
    final saludo = nombre.isEmpty ? 'Bienvenido a ErgoVida' : 'Hola, $nombre';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                saludo,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Gestiona tus pausas activas y mejora tu bienestar laboral.',
                style: TextStyle(fontSize: 16, color: textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF123A56) : const Color(0xFFE1F2FF),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 15,
                color: isDark ? const Color(0xFF8BE7D7) : brandBlue,
              ),
              const SizedBox(width: 7),
              Text(
                "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                style: TextStyle(
                  color: isDark ? const Color(0xFF8BE7D7) : brandBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statGrid(double maxWidth, bool isDark) {
    final tresColumnas = maxWidth >= 900;
    final cards = [
      _StatCardData(
        titulo: 'Pausas realizadas',
        valor: _cargando ? '...' : '$_pausas',
        icono: Icons.timer_rounded,
        color: brandBlue,
        surface: const Color(0xFFE1F2FF),
      ),
      _StatCardData(
        titulo: 'Ejercicios completados',
        valor: _cargando ? '...' : '$_completados',
        icono: Icons.fitness_center_rounded,
        color: brandNavy,
        surface: const Color(0xFFE1F2FF),
      ),
      _StatCardData(
        titulo: 'Tiempo activo',
        valor: _cargando ? '...' : _tiempoActivo,
        icono: Icons.access_time_rounded,
        color: brandCyan,
        surface: const Color(0xFFE0F7FA),
      ),
    ];

    if (!tresColumnas) {
      return Column(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            _statCard(cards[i], isDark),
            if (i != cards.length - 1) const SizedBox(height: 14),
          ],
        ],
      );
    }

    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          Expanded(child: _statCard(cards[i], isDark)),
          if (i != cards.length - 1) const SizedBox(width: 18),
        ],
      ],
    );
  }

  Widget _statCard(_StatCardData data, bool isDark) {
    final panelBg = isDark ? const Color(0xFF111C2E) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(20),
      height: 190,
      decoration: BoxDecoration(
        color: panelBg,
        border: Border.all(
          color: isDark ? const Color(0xFF24364C) : const Color(0xFFDBEAF3),
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140E2238),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: isDark
                  ? Color.alphaBlend(
                      isDark ? const Color(0xFF0E2238) : Colors.white,
                      data.color,
                    ).withValues(alpha: 0.28)
                  : data.surface,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(data.icono, color: data.color, size: 28),
          ),
          const Spacer(),
          Text(
            data.valor,
            style: TextStyle(
              color: isDark ? Colors.white : brandNavy,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.titulo,
            style: TextStyle(
              color: isDark ? const Color(0xFFCBD5E1) : brandMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resumenCard(Color textPrimary, Color textSecondary, bool isDark) {
    final panelBg = isDark ? const Color(0xFF111C2E) : Colors.white;
    final rol = _usuario?.rol ?? 'USUARIO';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: panelBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF24364C) : const Color(0xFFDBEAF3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [brandBlue, brandTeal]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.insights_rounded, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tu actividad',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _cargando
                      ? 'Cargando tu información...'
                      : 'Llevas $_pausas pausas registradas y $_completados completadas. Rol actual: $rol.',
                  style: TextStyle(color: textSecondary, fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Actualizar datos',
            onPressed: _cargarResumen,
            icon: const Icon(Icons.refresh_rounded),
            color: brandBlue,
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    BuildContext context,
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: 240,
      height: 92,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }
}

class _StatCardData {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color color;
  final Color surface;

  const _StatCardData({
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.color,
    required this.surface,
  });
}

class _Sidebar extends StatelessWidget {
  final UserModel? usuario;
  final bool esAdmin;
  final bool isDark;
  final VoidCallback onDashboard;
  final VoidCallback onEjercicios;
  final VoidCallback onRutinas;
  final VoidCallback onEstadisticas;
  final VoidCallback onPerfil;
  final VoidCallback onAdmin;
  final VoidCallback onConfiguracion;
  final VoidCallback onSalir;

  const _Sidebar({
    required this.usuario,
    required this.esAdmin,
    required this.isDark,
    required this.onDashboard,
    required this.onEjercicios,
    required this.onRutinas,
    required this.onEstadisticas,
    required this.onPerfil,
    required this.onAdmin,
    required this.onConfiguracion,
    required this.onSalir,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF0B1B2B), Color(0xFF122D46)]
              : const [Color(0xFF0E2238), Color(0xFF163451)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
          children: [
            // 🔹 Logo corregido sin duplicar los Center
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ErgoVidaLogo(width: 80),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'ErgoVida',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _perfil(usuario),
            const SizedBox(height: 20),
            _item(Icons.dashboard_rounded, 'Dashboard', true, onDashboard),
            _item(
              Icons.fitness_center_rounded,
              'Ejercicios',
              false,
              onEjercicios,
            ),
            _item(Icons.repeat_rounded, 'Rutinas', false, onRutinas),
            _item(
              Icons.bar_chart_rounded,
              'Estadísticas',
              false,
              onEstadisticas,
            ),
            _item(Icons.person_rounded, 'Mi perfil', false, onPerfil),
            if (esAdmin)
              _item(
                Icons.admin_panel_settings_rounded,
                'Administración',
                false,
                onAdmin,
                destacado: true,
              ),
            _item(
              Icons.settings_rounded,
              'Configuración',
              false,
              onConfiguracion,
            ),
            const SizedBox(height: 14),
            const Divider(color: Color(0xFF31506C), thickness: 1),
            const SizedBox(height: 8),
            Material(
              color: Colors.transparent,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 2,
                ),
                leading: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFFF8A8A),
                  size: 22,
                ),
                title: const Text(
                  'Cerrar sesión',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onTap: onSalir,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _perfil(UserModel? usuario) {
    final nombre = usuario?.nombre ?? 'Invitado';
    final correo = usuario?.correo ?? 'Sin sesión';
    final rol = usuario?.rol ?? 'USUARIO';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          UserAvatar(
            usuario: usuario,
            radius: 22,
            backgroundColor: brandTeal,
            foregroundColor: brandNavy,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  correo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFB8CCDD),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: rol.toUpperCase() == 'ADMINISTRADOR'
                        ? brandTeal.withValues(alpha: 0.22)
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    rol,
                    style: TextStyle(
                      color: rol.toUpperCase() == 'ADMINISTRADOR'
                          ? const Color(0xFF7FF3E1)
                          : const Color(0xFFCBD5E1),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(
    IconData icon,
    String title,
    bool active,
    VoidCallback onTap, {
    bool destacado = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: active
            ? brandBlue.withValues(alpha: 0.3)
            : destacado
            ? brandTeal.withValues(alpha: 0.16)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 1,
          ),
          leading: Icon(
            icon,
            color: destacado ? const Color(0xFF7FF3E1) : Colors.white,
            size: 21,
          ),
          title: Text(
            title,
            style: TextStyle(
              color: destacado ? const Color(0xFF7FF3E1) : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
