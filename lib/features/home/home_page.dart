import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/ejercicio_service.dart';
import '../../data/services/estadisticas_service.dart';
import '../../data/services/pausa_service.dart';
import '../../data/services/reminder_service.dart';
import '../../data/services/wellness_service.dart';
import '../../main.dart';
import '../../widgets/design_system.dart';
import '../../widgets/ergovida_logo.dart';
import '../../widgets/user_avatar.dart';
import '../admin/admin_page.dart';
import '../auth/login_page.dart';
import '../exercises/exercises_page.dart';
import '../pauses/guided_pause_page.dart';
import '../profile/profile_page.dart';
import '../routines/routine_page.dart';
import '../settings/settings_page.dart';
import '../statistics/statistics_page.dart';
import '../wellness/wellness_page.dart';

class HomePage extends StatefulWidget {
  final AppThemeController? themeController;
  final UserModel? usuario;

  const HomePage({super.key, this.themeController, this.usuario});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final EstadisticasService _estadisticasService = EstadisticasService();
  final PausaService _pausaService = PausaService();
  final EjercicioService _ejercicioService = EjercicioService();
  final WellnessService _wellnessService = WellnessService();

  UserModel? _usuario;
  WellnessData _bienestar = WellnessData.empty();
  int _pausas = 0;
  int _completados = 0;
  int _minutos = 0;
  int _racha = 0;
  int _pausasHoy = 0;
  bool _cargando = true;
  List<_ActividadReciente> _actividad = const [];

  int get _usuarioId => _usuario?.id ?? AuthService.usuarioId;
  bool get _esAdmin =>
      (_usuario?.rol ?? AuthService.usuarioRol).toUpperCase() ==
      'ADMINISTRADOR';

  int get _metaDiaria => _bienestar.dailyGoal;
  double get _progresoMeta => _metaDiaria <= 0
      ? 0
      : (_pausasHoy / _metaDiaria).clamp(0.0, 1.0);
  int get _rachaTotal {
    final local = _bienestar.streak;
    return local > _racha ? local : _racha;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _usuario = widget.usuario ?? AuthService.currentUser;
    final usuario = _usuario;
    if (usuario != null && usuario.id > 0) {
      ReminderService.instance.start(usuario);
    }
    _cargarResumen();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ReminderService.instance.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ReminderService.instance.refresh().then((_) {
        ReminderService.instance.checkNow();
      });
      _cargarResumen();
    }
  }

  Future<void> _cargarResumen() async {
    if (_usuarioId <= 0) {
      if (mounted) setState(() => _cargando = false);
      return;
    }

    if (mounted) setState(() => _cargando = true);

    final bienestar = await _wellnessService.load(_usuarioId);
    final resultados = await Future.wait([
      _estadisticasService.obtenerPorUsuario(_usuarioId),
      _pausaService.obtenerPorUsuario(_usuarioId),
      _ejercicioService.obtenerEjercicios(),
    ]);

    final estadisticas = resultados[0];
    final pausas = resultados[1];
    final ejercicios = resultados[2];

    final nombres = <String, String>{};
    for (final e in ejercicios.whereType<Map>()) {
      final id = _asInt(e['id']);
      final nombre = e['nombre']?.toString();
      if (id > 0 && nombre != null && nombre.isNotEmpty) {
        nombres['$id'] = nombre;
      }
    }

    var pausasTotales = 0;
    var minutosTotales = 0;
    var pausasHoy = 0;
    final porDia = <String, int>{};
    final hoyKey = WellnessService.dateKey(DateTime.now());

    for (final e in estadisticas.whereType<Map>()) {
      final cantidad = _asInt(e['pausasRealizadas']);
      pausasTotales += cantidad;
      minutosTotales += _asInt(e['minutosActivos']);
      final fecha = _parseFecha(e['fecha']);
      if (fecha == null) continue;
      final key = WellnessService.dateKey(fecha);
      porDia[key] = (porDia[key] ?? 0) + cantidad;
      if (key == hoyKey) pausasHoy += cantidad;
    }

    final completadas = pausas
        .where((p) => p is Map && p['completada'] == true)
        .length;

    if (pausasTotales == 0 && pausas.isNotEmpty) {
      pausasTotales = pausas.length;
      minutosTotales = pausas.length * 2;
    }

    for (final pausa in pausas.whereType<Map>()) {
      final fecha = _parseFecha(pausa['fecha']);
      if (fecha == null) continue;
      final key = WellnessService.dateKey(fecha);
      porDia[key] = porDia[key] ?? 0;
    }

    final localHoy = bienestar.todaySessions().count;
    if (localHoy > pausasHoy) pausasHoy = localHoy;

    var racha = 0;
    var cursor = DateTime.now();
    if ((porDia[WellnessService.dateKey(cursor)] ?? 0) == 0) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    while (racha < 365 &&
        (porDia[WellnessService.dateKey(cursor)] ?? 0) > 0) {
      racha++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    final listaPausas = pausas.whereType<Map>().toList()
      ..sort((a, b) {
        final fa = _parseFecha(a['fecha']);
        final fb = _parseFecha(b['fecha']);
        if (fa == null && fb == null) return 0;
        if (fa == null) return 1;
        if (fb == null) return -1;
        return fb.compareTo(fa);
      });

    final actividad = listaPausas.take(4).map((p) {
      final nombre = nombres['${_asInt(p['ejercicioId'])}'] ?? 'Pausa activa';
      return _ActividadReciente(
        nombre: nombre,
        completada: p['completada'] == true,
        fecha: _parseFecha(p['fecha']),
      );
    }).toList();

    if (!mounted) return;
    setState(() {
      _bienestar = bienestar;
      _pausas = pausasTotales;
      _completados = completadas;
      _minutos = minutosTotales;
      _racha = racha;
      _pausasHoy = pausasHoy;
      _actividad = actividad;
      _cargando = false;
    });
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime? _parseFecha(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
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

  Future<void> _abrirPausaGuiada({String? nombre, int? ejercicioId}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GuidedPausePage(
          usuarioId: _usuarioId,
          nombre: nombre,
          ejercicioId: ejercicioId,
        ),
      ),
    );
    if (mounted) _cargarResumen();
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
    await ReminderService.instance.stop();
    await AuthService.clearSession();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _alternarTema() {
    final controller = widget.themeController ?? AppThemeController.instance;
    controller.setTheme(!controller.isDark);
  }

  Future<void> _mostrarCentroBienestar() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? AppPalette.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final mood = _bienestar.todayMood();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppPalette.darkBorder
                          : const Color(0xFFD8E4EF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Tu resumen de hoy',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                _sheetRow(
                  Icons.check_circle_rounded,
                  '$_pausasHoy de $_metaDiaria pausas completadas',
                  AppPalette.teal,
                ),
                _sheetRow(
                  Icons.local_fire_department_rounded,
                  'Racha actual: $_rachaTotal días',
                  const Color(0xFFF97316),
                ),
                _sheetRow(
                  Icons.mood_rounded,
                  mood == null
                      ? 'Aún no registras tu ánimo hoy'
                      : 'Ánimo de hoy: ${MoodOption.forScore(mood.score).label}',
                  AppPalette.blue,
                ),
                const SizedBox(height: 12),
                GradientButton(
                  label: 'Ir a Bienestar',
                  icon: Icons.spa_rounded,
                  onPressed: () {
                    Navigator.pop(context);
                    _abrir(WellnessPage(usuarioId: _usuarioId));
                  },
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _abrir(
                      SettingsPage(
                        themeController: widget.themeController,
                        usuario: _usuario,
                      ),
                    );
                  },
                  icon: const Icon(Icons.alarm_rounded, size: 19),
                  label: const Text('Configurar recordatorios'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sheetRow(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          IconBadge(icon: icon, color: color, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppThemeController.instance,
      builder: (context, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final pageBg = isDark ? AppPalette.darkBackground : AppPalette.background;

        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1040;
            final contentWidth =
                constraints.maxWidth -
                (wide ? 288 : 0) -
                (wide ? 68 : 36);

            return Scaffold(
              backgroundColor: pageBg,
              drawer: wide ? null : Drawer(width: 290, child: _sidebar(true)),
              body: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? const [Color(0xFF08111F), Color(0xFF0C1A2B)]
                        : const [Color(0xFFEAF2F9), AppPalette.background],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    if (wide)
                      SizedBox(
                        width: 288,
                        child: _sidebar(false),
                      ),
                    Expanded(
                      child: CustomScrollView(
                        slivers: [
                          SliverAppBar(
                            pinned: true,
                            backgroundColor: pageBg.withValues(alpha: 0.92),
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
                              IconButton(
                                tooltip: 'Resumen del día',
                                onPressed: _mostrarCentroBienestar,
                                icon: Badge(
                                  isLabelVisible: _pausasHoy < _metaDiaria,
                                  label: const Text('!'),
                                  backgroundColor: AppPalette.teal,
                                  child: const Icon(
                                    Icons.notifications_none_rounded,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Cambiar tema',
                                onPressed: _alternarTema,
                                icon: Icon(
                                  isDark
                                      ? Icons.light_mode_rounded
                                      : Icons.dark_mode_rounded,
                                ),
                              ),
                              if (!wide)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(999),
                                    onTap: _abrirPerfil,
                                    child: UserAvatar(
                                      usuario: _usuario,
                                      radius: 18,
                                      backgroundColor: AppPalette.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              if (wide) const SizedBox(width: 12),
                            ],
                          ),
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              wide ? 34 : 18,
                              10,
                              wide ? 34 : 18,
                              40,
                            ),
                            sliver: SliverList(
                              delegate: SliverChildListDelegate([
                                AnimatedEntrance(child: _hero(isDark)),
                                const SizedBox(height: 20),
                                AnimatedEntrance(
                                  index: 1,
                                  child: _statsGrid(contentWidth),
                                ),
                                const SizedBox(height: 30),
                                AnimatedEntrance(
                                  index: 2,
                                  child: const SectionHeader(
                                    title: 'Acciones rápidas',
                                    subtitle:
                                        'Todo lo que necesitas para tu bienestar',
                                    icon: Icons.bolt_rounded,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                AnimatedEntrance(
                                  index: 3,
                                  child: _accionesRapidas(),
                                ),
                                const SizedBox(height: 26),
                                AnimatedEntrance(
                                  index: 4,
                                  child: _filaBienestar(
                                    contentWidth >= 760,
                                    isDark,
                                  ),
                                ),
                                const SizedBox(height: 26),
                                AnimatedEntrance(
                                  index: 5,
                                  child: _actividadCard(isDark),
                                ),
                                const SizedBox(height: 20),
                                AnimatedEntrance(
                                  index: 6,
                                  child: _consejoCard(isDark),
                                ),
                              ]),
                            ),
                          ),
                        ],
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

  Widget _sidebar(bool closeOnTap) {
    void go(VoidCallback action) {
      if (closeOnTap) Navigator.pop(context);
      action();
    }

    return _Sidebar(
      usuario: _usuario,
      esAdmin: _esAdmin,
      isDark: Theme.of(context).brightness == Brightness.dark,
      onDashboard: () {
        if (closeOnTap) Navigator.pop(context);
      },
      onPausa: () => go(() => _abrirPausaGuiada()),
      onEjercicios: () => go(() => _abrir(ExercisesPage(usuarioId: _usuarioId))),
      onRutinas: () => go(() => _abrir(const RoutinePage())),
      onEstadisticas: () =>
          go(() => _abrir(StatisticsPage(usuarioId: _usuarioId))),
      onBienestar: () => go(() => _abrir(WellnessPage(usuarioId: _usuarioId))),
      onPerfil: () => go(_abrirPerfil),
      onAdmin: () => go(() => _abrir(const AdminPage())),
      onConfiguracion: () => go(
        () => _abrir(
          SettingsPage(
            themeController: widget.themeController,
            usuario: _usuario,
          ),
        ),
      ),
      onSalir: _cerrarSesion,
      onTema: _alternarTema,
    );
  }

  Widget _hero(bool isDark) {
    final nombre = _usuario?.nombre.trim() ?? '';
    final primerNombre = nombre.isEmpty ? '' : nombre.split(' ').first;
    final saludo = primerNombre.isEmpty
        ? 'Bienvenido a ErgoVida'
        : 'Hola, $primerNombre';
    final porcentaje = (_progresoMeta * 100).round();
    final fecha = _fechaBonita(DateTime.now());
    final compact = MediaQuery.sizeOf(context).width < 430;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppPalette.navyDeep,
            AppPalette.navy,
            Color(0xFF145277),
            AppPalette.blue,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadii.xl),
        boxShadow: AppShadows.glow(AppPalette.blue),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -70,
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -90,
            left: -50,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppPalette.teal.withValues(alpha: 0.08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AppPill(
                              text: fecha.toUpperCase(),
                              color: Colors.white,
                              icon: Icons.calendar_today_rounded,
                              outlined: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          saludo,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: compact ? 28 : 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                            height: 1.08,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tu bienestar empieza con pequeños momentos de pausa.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 14.5,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: compact ? 10 : 18),
                  ProgressRing(
                    value: _progresoMeta,
                    size: compact ? 86 : 108,
                    strokeWidth: compact ? 8 : 10,
                    color: AppPalette.teal,
                    trackColor: Colors.white.withValues(alpha: 0.16),
                    center: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$porcentaje%',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: compact ? 18 : 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'meta diaria',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: compact ? 8 : 9.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _heroChip(
                    Icons.local_fire_department_rounded,
                    'Racha $_rachaTotal d',
                  ),
                  _heroChip(
                    Icons.check_circle_rounded,
                    '$_pausasHoy/$_metaDiaria hoy',
                  ),
                  _heroChip(
                    Icons.access_time_rounded,
                    _tiempoActivo,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 190,
                    child: GradientButton(
                      label: 'Iniciar pausa',
                      icon: Icons.play_arrow_rounded,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 15,
                      ),
                      onPressed: _abrirPausaGuiada,
                      gradient: const LinearGradient(
                        colors: [AppPalette.teal, AppPalette.cyan],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 190,
                    child: _heroSecondaryButton(
                      icon: Icons.spa_rounded,
                      label: 'Mi bienestar',
                      onTap: () =>
                          _abrir(WellnessPage(usuarioId: _usuarioId)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.84)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroSecondaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white.withValues(alpha: 0.9),
                size: 19,
              ),
              const SizedBox(width: 9),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statsGrid(double maxWidth) {
    final cards = [
      StatTile(
        title: 'Pausas realizadas',
        value: _cargando ? '...' : '$_pausas',
        caption: 'Totales',
        icon: Icons.self_improvement_rounded,
        color: AppPalette.blue,
      ),
      StatTile(
        title: 'Ejercicios completados',
        value: _cargando ? '...' : '$_completados',
        caption: 'Completados',
        icon: Icons.check_circle_rounded,
        color: AppPalette.teal,
      ),
      StatTile(
        title: 'Tiempo activo',
        value: _cargando ? '...' : _tiempoActivo,
        caption: 'Acumulado',
        icon: Icons.access_time_rounded,
        color: AppPalette.cyan,
      ),
      StatTile(
        title: 'Racha actual',
        value: _cargando ? '...' : '$_rachaTotal días',
        caption: 'Constancia',
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFF97316),
      ),
    ];

    final columnas = maxWidth >= 1180
        ? 4
        : maxWidth >= 760
        ? 2
        : 1;
    final spacing = 14.0;
    final ancho = columnas == 1
        ? maxWidth
        : (maxWidth - (columnas - 1) * spacing) / columnas;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        for (final card in cards) SizedBox(width: ancho, child: card),
      ],
    );
  }

  Widget _accionesRapidas() {
    final acciones = [
      _AccionRapida(
        titulo: 'Pausa guiada',
        descripcion: 'Temporizador y respiración',
        icono: Icons.timer_rounded,
        color: AppPalette.teal,
        onTap: _abrirPausaGuiada,
        destacada: true,
      ),
      _AccionRapida(
        titulo: 'Ejercicios',
        descripcion: 'Rutinas con cámara',
        icono: Icons.fitness_center_rounded,
        color: AppPalette.blue,
        onTap: () => _abrir(ExercisesPage(usuarioId: _usuarioId)),
      ),
      _AccionRapida(
        titulo: 'Rutinas',
        descripcion: 'Planes por momento',
        icono: Icons.repeat_rounded,
        color: AppPalette.cyan,
        onTap: () => _abrir(const RoutinePage()),
      ),
      _AccionRapida(
        titulo: 'Estadísticas',
        descripcion: 'Tu progreso detallado',
        icono: Icons.bar_chart_rounded,
        color: AppPalette.navySoft,
        onTap: () => _abrir(StatisticsPage(usuarioId: _usuarioId)),
      ),
      _AccionRapida(
        titulo: 'Bienestar',
        descripcion: 'Ánimo, logros y consejos',
        icono: Icons.spa_rounded,
        color: const Color(0xFF16A34A),
        onTap: () => _abrir(WellnessPage(usuarioId: _usuarioId)),
      ),
      _AccionRapida(
        titulo: 'Configuración',
        descripcion: 'Recordatorios y tema',
        icono: Icons.settings_rounded,
        color: AppPalette.muted,
        onTap: () => _abrir(
          SettingsPage(
            themeController: widget.themeController,
            usuario: _usuario,
          ),
        ),
      ),
      if (_esAdmin)
        _AccionRapida(
          titulo: 'Administración',
          descripcion: 'Gestiona usuarios y datos',
          icono: Icons.admin_panel_settings_rounded,
          color: const Color(0xFF7C3AED),
          onTap: () => _abrir(const AdminPage()),
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnas = constraints.maxWidth >= 1120
            ? 3
            : constraints.maxWidth >= 700
            ? 2
            : 1;
        final spacing = 14.0;
        final ancho = columnas == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - (columnas - 1) * spacing) / columnas;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final accion in acciones)
              SizedBox(width: ancho, child: _accionCard(accion)),
          ],
        );
      },
    );
  }

  Widget _accionCard(_AccionRapida accion) {
    return AppSurface(
      padding: const EdgeInsets.all(16),
      onTap: accion.onTap,
      borderGradient: accion.destacada
          ? LinearGradient(
              colors: [
                accion.color.withValues(alpha: 0.55),
                AppPalette.blue.withValues(alpha: 0.35),
              ],
            )
          : null,
      child: Row(
        children: [
          IconBadge(
            icon: accion.icono,
            color: accion.color,
            size: 46,
            filled: accion.destacada,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  accion.titulo,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  accion.descripcion,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppPalette.muted,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: AppPalette.muted.withValues(alpha: 0.7),
          ),
        ],
      ),
    );
  }

  Widget _filaBienestar(bool wide, bool isDark) {
    final recomendada = _tarjetaRecomendada(isDark);
    final animo = _tarjetaAnimo(isDark);

    if (!wide) {
      return Column(
        children: [
          recomendada,
          const SizedBox(height: 16),
          animo,
        ],
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 3, child: recomendada),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: animo),
        ],
      ),
    );
  }

  Widget _tarjetaRecomendada(bool isDark) {
    return AppSurface(
      gradient: isDark
          ? null
          : const LinearGradient(
              colors: [Colors.white, Color(0xFFF3F9FD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(
                icon: Icons.auto_awesome_rounded,
                color: AppPalette.teal,
                size: 44,
                filled: true,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pausa recomendada',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Ideal para este momento del día',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppPalette.muted,
                      ),
                    ),
                  ],
                ),
              ),
              AppPill(
                text: '2 min',
                color: AppPalette.teal,
                icon: Icons.schedule_rounded,
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Respiración consciente',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Inhala en 4 tiempos, mantén 2 y exhala en 6. '
            'Una pausa breve para bajar el ritmo y recuperar la concentración.',
            style: TextStyle(
              fontSize: 13,
              color: AppPalette.muted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: GradientButton(
                  label: 'Comenzar ahora',
                  icon: Icons.play_arrow_rounded,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  onPressed: () => _abrirPausaGuiada(
                    nombre: 'Respiración consciente',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () => _abrir(const RoutinePage()),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                child: const Text('Ver rutinas'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tarjetaAnimo(bool isDark) {
    final mood = _bienestar.todayMood();
    final seleccion = mood == null ? null : MoodOption.forScore(mood.score);

    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              IconBadge(
                icon: Icons.mood_rounded,
                color: Color(0xFFEC4899),
                size: 44,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '¿Cómo te sientes hoy?',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final option in MoodOption.options)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _miniMood(
                      option,
                      seleccion?.score == option.score,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            seleccion == null
                ? 'Registra tu ánimo y descubre tu evolución semanal.'
                : 'Hoy te sientes: ${seleccion.label}.',
            style: const TextStyle(
              fontSize: 12,
              color: AppPalette.muted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => _abrir(WellnessPage(usuarioId: _usuarioId)),
            icon: const Icon(Icons.arrow_forward_rounded, size: 17),
            label: const Text('Ver mi bienestar'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniMood(MoodOption option, bool selected) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        await _wellnessService.saveMood(
          option.score,
          userId: _usuarioId,
        );
        if (mounted) {
          setState(() {
            final moods = Map<String, MoodEntry>.from(_bienestar.moods);
            moods[WellnessService.dateKey(DateTime.now())] = MoodEntry(
              score: option.score,
            );
            _bienestar = _bienestar.copyWith(moods: moods);
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? Color(option.color).withValues(alpha: 0.14)
              : const Color(0xFFF5F9FC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? Color(option.color).withValues(alpha: 0.45)
                : const Color(0xFFE8F0F7),
          ),
        ),
        child: Text(
          option.emoji,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22),
        ),
      ),
    );
  }

  Widget _actividadCard(bool isDark) {
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Actividad reciente',
            subtitle: 'Últimas pausas registradas',
            icon: Icons.history_rounded,
            trailing: TextButton(
              onPressed: () =>
                  _abrir(StatisticsPage(usuarioId: _usuarioId)),
              child: const Text('Ver todo'),
            ),
          ),
          const SizedBox(height: 16),
          if (_actividad.isEmpty)
            const AppEmptyState(
              icon: Icons.history_toggle_off_rounded,
              title: 'Aún no hay actividad',
              message:
                  'Completa tu primera pausa guiada para ver tu historial aquí.',
            )
          else
            for (var i = 0; i < _actividad.length; i++) ...[
              _actividadTile(_actividad[i]),
              if (i != _actividad.length - 1) const AppDivider(vertical: 10),
            ],
        ],
      ),
    );
  }

  Widget _actividadTile(_ActividadReciente item) {
    return Row(
      children: [
        IconBadge(
          icon: item.completada
              ? Icons.check_circle_rounded
              : Icons.timelapse_rounded,
          color: item.completada ? AppPalette.teal : AppPalette.blue,
          size: 40,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.fecha == null
                    ? 'Sin fecha'
                    : _fechaRelativa(item.fecha!),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppPalette.muted,
                ),
              ),
            ],
          ),
        ),
        AppPill(
          text: item.completada ? 'Completada' : 'En curso',
          color: item.completada ? AppPalette.teal : AppPalette.blue,
        ),
      ],
    );
  }

  Widget _consejoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF13253A), Color(0xFF0F1D2E)]
              : const [Color(0xFF0E2238), Color(0xFF17587D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.lightbulb_rounded,
              color: AppPalette.teal,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Consejo del día',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _consejoDelDia(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _consejoDelDia() {
    const consejos = [
      'Aplica la regla 20-20-20: cada 20 minutos mira 20 segundos algo a 6 metros de distancia.',
      'Mantén la espalda apoyada y los pies en el suelo. Tu postura también descansa.',
      'Bebe agua durante la jornada. La hidratación mejora tu concentración.',
      'Sube y baja los hombros lentamente 5 veces para liberar la tensión del cuello.',
      'Una pausa de 2 minutos cada hora puede mejorar tu productividad y tu ánimo.',
      'Parpadea con frecuencia frente a la pantalla para evitar la fatiga visual.',
      'Camina unos pasos cada hora: activa la circulación y despeja la mente.',
    ];
    return consejos[DateTime.now().weekday % consejos.length];
  }

  static String _fechaBonita(DateTime date) {
    const meses = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    const dias = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ];
    return '${dias[date.weekday - 1]} ${date.day} ${meses[date.month - 1]}';
  }

  static String _fechaRelativa(DateTime fecha) {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final dia = DateTime(fecha.year, fecha.month, fecha.day);
    final diferencia = hoy.difference(dia).inDays;
    final hora =
        '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';

    if (diferencia == 0) return 'Hoy · $hora';
    if (diferencia == 1) return 'Ayer · $hora';
    if (diferencia < 7) return 'Hace $diferencia días · $hora';
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }
}

class _ActividadReciente {
  final String nombre;
  final bool completada;
  final DateTime? fecha;

  const _ActividadReciente({
    required this.nombre,
    required this.completada,
    this.fecha,
  });
}

class _AccionRapida {
  final String titulo;
  final String descripcion;
  final IconData icono;
  final Color color;
  final VoidCallback onTap;
  final bool destacada;

  const _AccionRapida({
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.color,
    required this.onTap,
    this.destacada = false,
  });
}

class _Sidebar extends StatelessWidget {
  final UserModel? usuario;
  final bool esAdmin;
  final bool isDark;
  final VoidCallback onDashboard;
  final VoidCallback onPausa;
  final VoidCallback onEjercicios;
  final VoidCallback onRutinas;
  final VoidCallback onEstadisticas;
  final VoidCallback onBienestar;
  final VoidCallback onPerfil;
  final VoidCallback onAdmin;
  final VoidCallback onConfiguracion;
  final VoidCallback onSalir;
  final VoidCallback onTema;

  const _Sidebar({
    required this.usuario,
    required this.esAdmin,
    required this.isDark,
    required this.onDashboard,
    required this.onPausa,
    required this.onEjercicios,
    required this.onRutinas,
    required this.onEstadisticas,
    required this.onBienestar,
    required this.onPerfil,
    required this.onAdmin,
    required this.onConfiguracion,
    required this.onSalir,
    required this.onTema,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF081527), Color(0xFF0E2238), Color(0xFF143A56)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: ErgoVidaLogo(width: 38),
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ErgoVida',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      'Bienestar laboral',
                      style: TextStyle(
                        color: Color(0xFF8FA9C2),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 22),
            _perfil(usuario),
            const SizedBox(height: 20),
            _grupo('PRINCIPAL'),
            _item(Icons.dashboard_rounded, 'Dashboard', true, onDashboard),
            _item(
              Icons.timer_rounded,
              'Pausa guiada',
              false,
              onPausa,
              destacado: true,
            ),
            _item(Icons.fitness_center_rounded, 'Ejercicios', false, onEjercicios),
            _item(Icons.repeat_rounded, 'Rutinas', false, onRutinas),
            const SizedBox(height: 14),
            _grupo('BIENESTAR'),
            _item(Icons.bar_chart_rounded, 'Estadísticas', false, onEstadisticas),
            _item(Icons.spa_rounded, 'Bienestar', false, onBienestar),
            _item(Icons.person_rounded, 'Mi perfil', false, onPerfil),
            if (esAdmin) ...[
              const SizedBox(height: 14),
              _grupo('ADMINISTRACIÓN'),
              _item(
                Icons.admin_panel_settings_rounded,
                'Panel administrador',
                false,
                onAdmin,
                destacado: true,
              ),
            ],
            const SizedBox(height: 14),
            _grupo('SISTEMA'),
            _item(
              Icons.settings_rounded,
              'Configuración',
              false,
              onConfiguracion,
            ),
            _item(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              isDark ? 'Tema claro' : 'Tema oscuro',
              false,
              onTema,
            ),
            const SizedBox(height: 14),
            Material(
              color: Colors.transparent,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                leading: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFFF8A8A),
                  size: 21,
                ),
                title: const Text(
                  'Cerrar sesión',
                  style: TextStyle(
                    color: Color(0xFFFFB4B4),
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
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

  Widget _grupo(String texto) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Text(
        texto,
        style: const TextStyle(
          color: Color(0xFF6F8AA5),
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.6,
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
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Row(
        children: [
          UserAvatar(
            usuario: usuario,
            radius: 22,
            backgroundColor: AppPalette.teal,
            foregroundColor: AppPalette.navy,
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
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  correo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF8FA9C2),
                    fontSize: 10.5,
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
                        ? AppPalette.teal.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    rol,
                    style: TextStyle(
                      color: rol.toUpperCase() == 'ADMINISTRADOR'
                          ? const Color(0xFF7FF3E1)
                          : const Color(0xFFCBD5E1),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
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
    final color = destacado ? const Color(0xFF7FF3E1) : Colors.white;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: active
            ? AppPalette.blue.withValues(alpha: 0.28)
            : destacado
            ? AppPalette.teal.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                if (active)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppPalette.teal,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
