import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/activity_types.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/auth_service.dart';
import '../../widgets/design_system.dart';
import '../../widgets/routine_avatar.dart';
import '../pauses/guided_pause_page.dart';
import 'routine_models.dart';

export 'routine_models.dart';

class RoutinePage extends StatefulWidget {
  const RoutinePage({super.key});

  @override
  State<RoutinePage> createState() => _RoutinePageState();
}

class _RoutinePageState extends State<RoutinePage> {
  static const List<String> _ordenCategorias = [
    'Oficina',
    'Casa',
    'Día',
    'Mañana',
    'Noche',
  ];

  static const List<RoutineAvatarKind> _heroKinds = [
    RoutineAvatarKind.march,
    RoutineAvatarKind.squat,
    RoutineAvatarKind.seatedStretch,
    RoutineAvatarKind.wallPush,
    RoutineAvatarKind.breathing,
    RoutineAvatarKind.childPose,
  ];

  static const String _prefsFavoritasBase = 'rutinas_favoritas';

  final Set<String> _favoritas = {};
  final Set<String> _expandidas = {};

  String get _prefsFavoritasKey =>
      '${_prefsFavoritasBase}_${AuthService.usuarioId}';

  String _filtro = 'Todas';
  int _heroIndex = 0;
  Timer? _heroTimer;

  @override
  void initState() {
    super.initState();
    _cargarFavoritas();
    _heroTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted) return;
      setState(() => _heroIndex = (_heroIndex + 1) % _heroKinds.length);
    });
  }

  Future<void> _cargarFavoritas() async {
    final prefs = await SharedPreferences.getInstance();
    final guardadas = prefs.getStringList(_prefsFavoritasKey) ?? const [];
    if (!mounted) return;
    setState(() {
      _favoritas
        ..clear()
        ..addAll(guardadas);
    });
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    super.dispose();
  }

  RoutineAvatarKind get _heroKind => _heroKinds[_heroIndex];

  static const List<RoutineItem> _rutinas = [
    RoutineItem(
      nombre: 'Rutina Oficina',
      descripcion: 'Recupera postura y energía durante la jornada.',
      ejercicios: 5,
      minutos: 10,
      nivel: 'Moderado',
      categoria: 'Oficina',
      icono: Icons.laptop_mac_rounded,
      color: AppPalette.blue,
      kind: RoutineAvatarKind.officePosture,
      pasos: [
        RoutinePaso(
          nombre: 'Acomoda tu puesto',
          detalle: 'Pantalla a la altura de los ojos, hombros atrás y pies apoyados.',
          segundos: 120,
          kind: RoutineAvatarKind.officePosture,
        ),
        RoutinePaso(
          nombre: 'Cuello suave',
          detalle: 'Inclina la oreja hacia el hombro, sostén y cambia de lado.',
          segundos: 120,
          kind: RoutineAvatarKind.neckStretch,
        ),
        RoutinePaso(
          nombre: 'Círculos de brazos',
          detalle: 'Dibuja círculos amplios y lentos hacia delante y hacia atrás.',
          segundos: 120,
          kind: RoutineAvatarKind.armCircles,
        ),
        RoutinePaso(
          nombre: 'Respiración consciente',
          detalle: 'Inhala por la nariz y exhala largamente por la boca.',
          segundos: 120,
          kind: RoutineAvatarKind.breathing,
        ),
        RoutinePaso(
          nombre: 'Piernas estiradas',
          detalle: 'Extiende una pierna y flexiona el tronco desde la cadera.',
          segundos: 120,
          kind: RoutineAvatarKind.seatedStretch,
        ),
      ],
    ),
    RoutineItem(
      nombre: 'Rutina Casa',
      descripcion: 'Relaja cuello, hombros y espalda tras el trabajo.',
      ejercicios: 4,
      minutos: 8,
      nivel: 'Fácil',
      categoria: 'Casa',
      icono: Icons.home_rounded,
      color: AppPalette.teal,
      kind: RoutineAvatarKind.seatedStretch,
      pasos: [
        RoutinePaso(
          nombre: 'Pierna extendida',
          detalle: 'Siéntate al borde de la silla y estira una pierna con el talón apoyado.',
          segundos: 120,
          kind: RoutineAvatarKind.seatedStretch,
        ),
        RoutinePaso(
          nombre: 'Gato-vaca en silla',
          detalle: 'Alterna curvar la espalda y abrir el pecho de forma suave.',
          segundos: 120,
          kind: RoutineAvatarKind.catCow,
        ),
        RoutinePaso(
          nombre: 'Talones arriba',
          detalle: 'Eleva los talones, sostén un segundo y baja con control.',
          segundos: 120,
          kind: RoutineAvatarKind.calfRaise,
        ),
        RoutinePaso(
          nombre: 'Respiración amplia',
          detalle: 'Inhala inflando el abdomen y exhala sin prisa.',
          segundos: 120,
          kind: RoutineAvatarKind.breathing,
        ),
      ],
    ),
    RoutineItem(
      nombre: 'Cuello y hombros',
      descripcion: 'Reduce la tensión acumulada en la parte superior.',
      ejercicios: 3,
      minutos: 6,
      nivel: 'Leve',
      categoria: 'Oficina',
      icono: Icons.accessibility_new_rounded,
      color: AppPalette.cyan,
      kind: RoutineAvatarKind.neckStretch,
      pasos: [
        RoutinePaso(
          nombre: 'Cuello lateral',
          detalle: 'Oreja hacia el hombro, sin subir el hombro contrario.',
          segundos: 120,
          kind: RoutineAvatarKind.neckStretch,
        ),
        RoutinePaso(
          nombre: 'Hombros en círculo',
          detalle: 'Círculos amplios hacia atrás y luego hacia delante.',
          segundos: 120,
          kind: RoutineAvatarKind.armCircles,
        ),
        RoutinePaso(
          nombre: 'Reajusta la postura',
          detalle: 'Espalda larga, mentón suave y mirada al frente.',
          segundos: 120,
          kind: RoutineAvatarKind.officePosture,
        ),
      ],
    ),
    RoutineItem(
      nombre: 'Descanso visual',
      descripcion: 'Alivia la fatiga ocular frente a pantallas.',
      ejercicios: 3,
      minutos: 4,
      nivel: 'Leve',
      categoria: 'Oficina',
      icono: Icons.visibility_rounded,
      color: AppPalette.blue,
      kind: RoutineAvatarKind.visualRest,
      pasos: [
        RoutinePaso(
          nombre: 'Mirada lejana',
          detalle: 'Mira un objeto a varios metros y parpadea con calma.',
          segundos: 80,
          kind: RoutineAvatarKind.visualRest,
        ),
        RoutinePaso(
          nombre: 'Ojos cerrados',
          detalle: 'Cierra los ojos y deja que la respiración se vuelva lenta.',
          segundos: 60,
          kind: RoutineAvatarKind.breathing,
        ),
        RoutinePaso(
          nombre: 'Cuello descansado',
          detalle: 'Inclina suavemente la cabeza a cada lado.',
          segundos: 100,
          kind: RoutineAvatarKind.neckStretch,
        ),
      ],
    ),
    RoutineItem(
      nombre: 'Activación matutina',
      descripcion: 'Despierta el cuerpo y prepara tu día con energía.',
      ejercicios: 6,
      minutos: 12,
      nivel: 'Moderado',
      categoria: 'Mañana',
      icono: Icons.wb_sunny_rounded,
      color: Color(0xFFF59E0B),
      kind: RoutineAvatarKind.march,
      pasos: [
        RoutinePaso(
          nombre: 'Marcha en el sitio',
          detalle: 'Eleva las rodillas y balancea los brazos con ritmo cómodo.',
          segundos: 120,
          kind: RoutineAvatarKind.march,
        ),
        RoutinePaso(
          nombre: 'Brazos despiertos',
          detalle: 'Círculos amplios hacia delante y hacia atrás.',
          segundos: 120,
          kind: RoutineAvatarKind.armCircles,
        ),
        RoutinePaso(
          nombre: 'Sentadilla suave',
          detalle: 'Baja como si fueras a sentarte y empuja con los talones.',
          segundos: 120,
          kind: RoutineAvatarKind.squat,
        ),
        RoutinePaso(
          nombre: 'Costados',
          detalle: 'Inclina el tronco a un lado sin mover las caderas.',
          segundos: 120,
          kind: RoutineAvatarKind.sideBend,
        ),
        RoutinePaso(
          nombre: 'Cadera móvil',
          detalle: 'Balancea una pierna y luego la otra con control.',
          segundos: 120,
          kind: RoutineAvatarKind.legSwing,
        ),
        RoutinePaso(
          nombre: 'Respiración final',
          detalle: 'Inhala profundo y exhala largo para cerrar la activación.',
          segundos: 120,
          kind: RoutineAvatarKind.breathing,
        ),
      ],
    ),
    RoutineItem(
      nombre: 'Relajación nocturna',
      descripcion: 'Baja el ritmo y libera tensión antes de dormir.',
      ejercicios: 4,
      minutos: 9,
      nivel: 'Fácil',
      categoria: 'Noche',
      icono: Icons.nightlight_round,
      color: Color(0xFF7C3AED),
      kind: RoutineAvatarKind.breathing,
      pasos: [
        RoutinePaso(
          nombre: 'Respiración lenta',
          detalle: 'Inhala por la nariz y exhala por la boca sin hacer ruido.',
          segundos: 150,
          kind: RoutineAvatarKind.breathing,
        ),
        RoutinePaso(
          nombre: 'Postura del niño',
          detalle: 'Rodillas flexionadas, glúteos sobre los talones y brazos extendidos.',
          segundos: 120,
          kind: RoutineAvatarKind.childPose,
        ),
        RoutinePaso(
          nombre: 'Cuello sin tensión',
          detalle: 'Oreja hacia el hombro, hombros relajados y respiración calmada.',
          segundos: 120,
          kind: RoutineAvatarKind.neckStretch,
        ),
        RoutinePaso(
          nombre: 'Cierre en flexión',
          detalle: 'Inclina el tronco hacia delante y deja caer brazos y cabeza.',
          segundos: 150,
          kind: RoutineAvatarKind.forwardFold,
        ),
      ],
    ),
    RoutineItem(
      nombre: 'Sentadillas con silla',
      descripcion:
          'Colócate frente a una silla, baja flexionando rodillas y caderas como si fueras a sentarte, y sube empujando con los talones. Fortalece piernas y glúteos.',
      ejercicios: 1,
      minutos: 5,
      nivel: 'Moderado',
      categoria: 'Casa',
      icono: Icons.chair_rounded,
      color: AppPalette.teal,
      kind: RoutineAvatarKind.squat,
    ),
    RoutineItem(
      nombre: 'Puente de glúteos',
      descripcion:
          'Acostado boca arriba con rodillas flexionadas y pies apoyados, eleva la cadera hasta alinear rodillas, cadera y hombros. Activa glúteos y zona lumbar.',
      ejercicios: 1,
      minutos: 5,
      nivel: 'Fácil',
      categoria: 'Casa',
      icono: Icons.fitness_center_rounded,
      color: AppPalette.blue,
      kind: RoutineAvatarKind.bridge,
    ),
    RoutineItem(
      nombre: 'Flexiones de pared',
      descripcion:
          'Apoya las manos en la pared a la altura del pecho, inclina el cuerpo llevando el pecho hacia la pared y empuja para volver. Trabaja pecho y brazos con bajo impacto.',
      ejercicios: 1,
      minutos: 4,
      nivel: 'Fácil',
      categoria: 'Casa',
      icono: Icons.open_in_full_rounded,
      color: AppPalette.cyan,
      kind: RoutineAvatarKind.wallPush,
    ),
    RoutineItem(
      nombre: 'Estiramiento de isquiotibiales sentado',
      descripcion:
          'Siéntate en el borde de una silla, extiende una pierna con talón apoyado y flexiona el tronco hacia adelante desde la cadera. Alivia tensión en la parte posterior del muslo.',
      ejercicios: 1,
      minutos: 4,
      nivel: 'Leve',
      categoria: 'Casa',
      icono: Icons.airline_seat_legroom_extra_rounded,
      color: AppPalette.teal,
      kind: RoutineAvatarKind.seatedStretch,
    ),
    RoutineItem(
      nombre: 'Gato-vaca en silla',
      descripcion:
          'Sentado con pies firmes, alterna curvar la espalda hacia adelante llevando el mentón al pecho y luego abrir el pecho arqueando suavemente. Mejora movilidad de columna.',
      ejercicios: 1,
      minutos: 4,
      nivel: 'Leve',
      categoria: 'Casa',
      icono: Icons.event_seat_rounded,
      color: AppPalette.blue,
      kind: RoutineAvatarKind.catCow,
    ),
    RoutineItem(
      nombre: 'Elevación de talones de pie',
      descripcion:
          'De pie con apoyo en una silla, eleva los talones hasta quedar de puntillas, sostén un segundo y baja con control. Fortalece pantorrillas y mejora equilibrio.',
      ejercicios: 1,
      minutos: 4,
      nivel: 'Fácil',
      categoria: 'Casa',
      icono: Icons.directions_walk_rounded,
      color: AppPalette.cyan,
      kind: RoutineAvatarKind.calfRaise,
    ),
    RoutineItem(
      nombre: 'Marcha en el sitio',
      descripcion:
          'De pie, eleva alternativamente las rodillas a una altura cómoda mientras balanceas los brazos. Activa circulación y eleva la energía al inicio o mitad del día.',
      ejercicios: 1,
      minutos: 5,
      nivel: 'Fácil',
      categoria: 'Día',
      icono: Icons.directions_run_rounded,
      color: Color(0xFFF59E0B),
      kind: RoutineAvatarKind.march,
    ),
    RoutineItem(
      nombre: 'Estiramiento lateral de tronco de pie',
      descripcion:
          'De pie con pies al ancho de caderas, eleva un brazo y inclina el cuerpo hacia el lado contrario sin rotar el tronco. Estira costados y mejora respiración.',
      ejercicios: 1,
      minutos: 4,
      nivel: 'Leve',
      categoria: 'Día',
      icono: Icons.swap_horiz_rounded,
      color: AppPalette.blue,
      kind: RoutineAvatarKind.sideBend,
    ),
    RoutineItem(
      nombre: 'Rotación torácica de pie',
      descripcion:
          'De pie con rodillas suaves y brazos al frente, gira el tronco hacia un lado y luego al otro manteniendo la cadera estable. Aumenta movilidad de la espalda media.',
      ejercicios: 1,
      minutos: 4,
      nivel: 'Leve',
      categoria: 'Día',
      icono: Icons.sync_alt_rounded,
      color: AppPalette.teal,
      kind: RoutineAvatarKind.torsoRotation,
    ),
    RoutineItem(
      nombre: 'Círculos de brazos amplios',
      descripcion:
          'De pie, extiende los brazos a los lados y realiza círculos amplios hacia adelante y hacia atrás. Calienta hombros y mejora la postura durante el día.',
      ejercicios: 1,
      minutos: 4,
      nivel: 'Fácil',
      categoria: 'Día',
      icono: Icons.autorenew_rounded,
      color: AppPalette.cyan,
      kind: RoutineAvatarKind.armCircles,
    ),
    RoutineItem(
      nombre: 'Balanceo de piernas',
      descripcion:
          'Apóyate en una silla y balancea una pierna hacia adelante y atrás con movimiento controlado, luego cambia de lado. Moviliza cadera y activa la zona inferior.',
      ejercicios: 1,
      minutos: 5,
      nivel: 'Fácil',
      categoria: 'Día',
      icono: Icons.airline_seat_recline_normal_rounded,
      color: AppPalette.blue,
      kind: RoutineAvatarKind.legSwing,
    ),
    RoutineItem(
      nombre: 'Extensión de espalda de pie',
      descripcion:
          'De pie con manos en la zona lumbar, lleva el pecho hacia arriba y atrás suavemente sin forzar el cuello. Contrarresta la postura encorvada y alivia rigidez.',
      ejercicios: 1,
      minutos: 3,
      nivel: 'Leve',
      categoria: 'Día',
      icono: Icons.accessibility_rounded,
      color: Color(0xFFF59E0B),
      kind: RoutineAvatarKind.backExtension,
    ),
    RoutineItem(
      nombre: 'Estiramiento de cuello lateral suave',
      descripcion:
          'Sentado o de pie, inclina la oreja hacia el hombro manteniendo ambos hombros relajados; sostén y cambia de lado. Libera tensión cervical antes de dormir.',
      ejercicios: 1,
      minutos: 4,
      nivel: 'Leve',
      categoria: 'Noche',
      icono: Icons.accessibility_new_rounded,
      color: Color(0xFF7C3AED),
      kind: RoutineAvatarKind.neckStretch,
    ),
    RoutineItem(
      nombre: 'Respiración diafragmática lenta',
      descripcion:
          'Acostado o sentado, coloca una mano en el abdomen, inhala por la nariz inflando el abdomen y exhala lento por la boca. Favorece la relajación y el descanso.',
      ejercicios: 1,
      minutos: 5,
      nivel: 'Leve',
      categoria: 'Noche',
      icono: Icons.air_rounded,
      color: AppPalette.teal,
      kind: RoutineAvatarKind.breathing,
    ),
    RoutineItem(
      nombre: 'Postura del niño',
      descripcion:
          'Arrodíllate, apoya los glúteos sobre los talones y extiende los brazos hacia adelante bajando el pecho. Estira espalda, hombros y ayuda a soltar tensión.',
      ejercicios: 1,
      minutos: 4,
      nivel: 'Fácil',
      categoria: 'Noche',
      icono: Icons.self_improvement_rounded,
      color: AppPalette.blue,
      kind: RoutineAvatarKind.childPose,
    ),
    RoutineItem(
      nombre: 'Flexión hacia adelante sentado',
      descripcion:
          'Sentado con pies apoyados, inclina el tronco hacia adelante dejando caer brazos y cabeza con suavidad. Relaja espalda y cuello para cerrar el día.',
      ejercicios: 1,
      minutos: 4,
      nivel: 'Leve',
      categoria: 'Noche',
      icono: Icons.weekend_rounded,
      color: AppPalette.cyan,
      kind: RoutineAvatarKind.forwardFold,
    ),
    RoutineItem(
      nombre: 'Torsión suave acostado',
      descripcion:
          'Acostado boca arriba, lleva ambas rodillas flexionadas hacia un lado manteniendo hombros apoyados, luego cambia de lado. Libera tensión lumbar con movimiento controlado.',
      ejercicios: 1,
      minutos: 5,
      nivel: 'Leve',
      categoria: 'Noche',
      icono: Icons.bedtime_rounded,
      color: Color(0xFF7C3AED),
      kind: RoutineAvatarKind.supineTwist,
    ),
    RoutineItem(
      nombre: 'Estiramiento de pantorrillas en pared',
      descripcion:
          'Apoya las manos en la pared, lleva una pierna atrás con talón en el suelo y flexiona la pierna adelantada. Estira pantorrillas y favorece la relajación de piernas.',
      ejercicios: 1,
      minutos: 4,
      nivel: 'Fácil',
      categoria: 'Noche',
      icono: Icons.directions_walk_rounded,
      color: AppPalette.teal,
      kind: RoutineAvatarKind.calfStretch,
    ),
  ];

  List<_RoutineEntry> get _entries {
    final categorias = _filtro == 'Todas'
        ? _ordenCategorias
        : _ordenCategorias.where((categoria) => categoria == _filtro).toList();

    final entries = <_RoutineEntry>[];
    for (final categoria in categorias) {
      final items = _rutinas
          .where((rutina) => rutina.categoria == categoria)
          .toList();
      if (items.isEmpty) continue;
      entries.add(_RoutineEntry.section(categoria, items.length));
      for (final item in items) {
        entries.add(_RoutineEntry.item(item));
      }
    }
    return entries;
  }

  int get _totalFavoritas {
    return _rutinas
        .where((rutina) => _favoritas.contains(rutina.nombre))
        .length;
  }

  Future<void> _iniciar(RoutineItem rutina) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GuidedPausePage(
          usuarioId: AuthService.usuarioId,
          nombre: rutina.nombre,
          duracionMin: rutina.minutos,
          categoria: rutina.categoria,
          avatarKind: rutina.kind,
          avatarColor: rutina.color,
          descripcion: rutina.descripcion,
          pasos: rutina.pasos,
          tipoActividad: ActivityTypes.additionalRoutine,
        ),
      ),
    );
  }

  void _alternarFavorita(RoutineItem rutina) {
    setState(() {
      if (!_favoritas.remove(rutina.nombre)) {
        _favoritas.add(rutina.nombre);
      }
    });
    _guardarFavoritas();
  }

  void _alternarDetalle(RoutineItem rutina) {
    setState(() {
      if (!_expandidas.remove(rutina.nombre)) {
        _expandidas.add(rutina.nombre);
      }
    });
  }

  Future<void> _guardarFavoritas() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsFavoritasKey, _favoritas.toList());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppPalette.darkBackground : AppPalette.background;
    final entries = _entries;

    return Scaffold(
      backgroundColor: bg,
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
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: bg.withValues(alpha: 0.92),
                surfaceTintColor: Colors.transparent,
                title: const Text('Rutinas'),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _hero(),
                    const SizedBox(height: 22),
                    _filtros(isDark),
                    const SizedBox(height: 18),
                  ]),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final entry = entries[index];
                    if (entry.isSection) {
                      return Padding(
                        padding: EdgeInsets.only(
                          top: index == 0 ? 0 : 22,
                          bottom: 12,
                        ),
                        child: _categoriaHeader(
                          entry.section!,
                          entry.count,
                          isDark,
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: AnimatedEntrance(
                        index: index % 6,
                        child: _rutinaCard(entry.rutina!, isDark),
                      ),
                    );
                  }, childCount: entries.length),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppPalette.navyDeep, AppPalette.navy, Color(0xFF15527A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadii.xl),
        boxShadow: AppShadows.glow(AppPalette.blue),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final content = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PLANES GUIADOS',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Rutinas recomendadas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.7,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tu avatar te muestra cómo hacer cada movimiento. '
                    'Elige el plan ideal para tu momento del día y sigue el ritmo.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      AppPill(
                        text: '${_rutinas.length} rutinas',
                        color: Colors.white,
                        icon: Icons.repeat_rounded,
                        outlined: true,
                      ),
                      AppPill(
                        text: '5 categorías',
                        color: AppPalette.teal,
                        icon: Icons.self_improvement_rounded,
                      ),
                      AppPill(
                        text: _totalFavoritas > 0
                            ? '$_totalFavoritas ${_totalFavoritas == 1 ? 'favorita' : 'favoritas'}'
                            : 'Guía animada',
                        color: AppPalette.cyan,
                        icon: _totalFavoritas > 0
                            ? Icons.favorite_rounded
                            : Icons.smart_display_rounded,
                      ),
                    ],
                  ),
                ],
              );

              if (constraints.maxWidth < 300) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    content,
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _heroAvatar(),
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: content),
                  const SizedBox(width: 14),
                  _heroAvatar(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _heroAvatar() {
    return Container(
      width: 112,
      height: 154,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.14),
            Colors.white.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 8, 6, 20),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 450),
                child: RepaintBoundary(
                  key: ValueKey(_heroKind),
                  child: RoutineAvatar(
                    kind: _heroKind,
                    color: AppPalette.teal,
                    lineColor: Colors.white,
                    opacity: 0.95,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 6,
            right: 6,
            bottom: 6,
            child: Text(
              _heroKind.label.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.62),
                fontSize: 7.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filtros(bool isDark) {
    const filtros = ['Todas', ..._ordenCategorias];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filtros.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filtro = filtros[index];
          final activo = _filtro == filtro;
          final meta = _categoriaMeta(filtro);

          return InkWell(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            onTap: () => setState(() => _filtro = filtro),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                gradient: activo
                    ? LinearGradient(
                        colors: [
                          meta.color,
                          Color.lerp(meta.color, Colors.white, 0.28)!,
                        ],
                      )
                    : null,
                color: activo
                    ? null
                    : (isDark ? AppPalette.darkSurface : Colors.white),
                borderRadius: BorderRadius.circular(AppRadii.pill),
                border: Border.all(
                  color: activo
                      ? Colors.transparent
                      : (isDark ? AppPalette.darkBorder : AppPalette.border),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    meta.icon,
                    size: 14,
                    color: activo ? Colors.white : meta.color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    filtro,
                    style: TextStyle(
                      color: activo ? Colors.white : AppPalette.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _categoriaHeader(String categoria, int count, bool isDark) {
    final meta = _categoriaMeta(categoria);

    return Row(
      children: [
        Icon(meta.icon, size: 18, color: meta.color),
        const SizedBox(width: 8),
        Text(
          categoria,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(width: 8),
        AppPill(text: '$count', color: meta.color),
        const SizedBox(width: 12),
        Expanded(
          child: Divider(
            height: 1,
            color: isDark ? AppPalette.darkBorder : AppPalette.border,
          ),
        ),
      ],
    );
  }

  Widget _rutinaCard(RoutineItem rutina, bool isDark) {
    final lineColor = isDark
        ? Color.lerp(rutina.color, Colors.white, 0.38)!
        : rutina.color;
    final favorita = _favoritas.contains(rutina.nombre);

    return AppSurface(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _avatarPreview(rutina, isDark, lineColor),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rutina.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      rutina.descripcion,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppPalette.muted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 40,
                height: 40,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  onTap: () => _alternarFavorita(rutina),
                  child: Center(
                    child: Icon(
                      favorita
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 20,
                      color: favorita ? rutina.color : AppPalette.muted,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppPill(
                text: '${rutina.minutos} min',
                color: AppPalette.blue,
                icon: Icons.schedule_rounded,
              ),
              AppPill(
                text:
                    '${rutina.ejercicios} ${rutina.ejercicios == 1 ? 'ejercicio' : 'ejercicios'}',
                color: AppPalette.teal,
                icon: Icons.fitness_center_rounded,
              ),
              AppPill(
                text: rutina.nivel,
                color: rutina.color,
                icon: Icons.signal_cellular_alt_rounded,
              ),
              AppPill(
                text: rutina.categoria,
                color: AppPalette.muted,
                icon: Icons.category_rounded,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _detalleRutina(rutina, isDark),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GradientButton(
                  label: 'Iniciar rutina',
                  icon: Icons.play_arrow_rounded,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  onPressed: () => _iniciar(rutina),
                ),
              ),
              const SizedBox(width: 10),
              Tooltip(
                message: 'Iniciar ${rutina.nombre}',
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _iniciar(rutina),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: rutina.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(rutina.icono, color: rutina.color, size: 22),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detalleRutina(RoutineItem rutina, bool isDark) {
    final abierto = _expandidas.contains(rutina.nombre);
    final pasos = rutina.pasos;
    final total = pasos.fold<int>(0, (sum, paso) => sum + paso.segundos);

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : AppPalette.background.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: isDark ? AppPalette.darkBorder : AppPalette.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => _alternarDetalle(rutina),
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.list_alt_rounded,
                    size: 16,
                    color: rutina.color,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      abierto
                          ? 'Ocultar ejercicios'
                          : 'Ver ${pasos.length} ${pasos.length == 1 ? 'ejercicio' : 'ejercicios'} · ${_minutosTexto(total)}',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppPalette.navy,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    abierto
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: AppPalette.muted,
                  ),
                ],
              ),
            ),
          ),
          if (abierto) ...[
            const Divider(height: 1, thickness: 1),
            for (var i = 0; i < pasos.length; i++)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 11,
                      backgroundColor: rutina.color.withValues(alpha: 0.14),
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          color: rutina.color,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pasos[i].nombre,
                            style: TextStyle(
                              color: isDark ? Colors.white : AppPalette.navy,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            pasos[i].detalle,
                            style: TextStyle(
                              color: AppPalette.muted,
                              fontSize: 11.5,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 11,
                                color: rutina.color,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                pasos[i].duracionTexto,
                                style: TextStyle(
                                  color: rutina.color,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  pasos[i].kind.label,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppPalette.muted,
                                    fontSize: 10.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  String _minutosTexto(int segundos) {
    return '${(segundos / 60).round()} min';
  }

  Widget _avatarPreview(RoutineItem rutina, bool isDark, Color lineColor) {
    return Tooltip(
      message: 'Guía animada: ${rutina.kind.label}',
      child: Container(
        width: 92,
        height: 112,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              rutina.color.withValues(alpha: isDark ? 0.24 : 0.14),
              rutina.color.withValues(alpha: 0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: rutina.color.withValues(alpha: 0.22)),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 18),
                child: RepaintBoundary(
                  child: RoutineAvatar(
                    kind: rutina.kind,
                    color: rutina.color,
                    lineColor: lineColor,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 6,
              right: 6,
              bottom: 5,
              child: Text(
                'GUÍA',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: lineColor.withValues(alpha: 0.75),
                  fontSize: 7.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static _CategoryMeta _categoriaMeta(String categoria) {
    switch (categoria) {
      case 'Oficina':
        return const _CategoryMeta(Icons.laptop_mac_rounded, AppPalette.blue);
      case 'Casa':
        return const _CategoryMeta(Icons.home_rounded, AppPalette.teal);
      case 'Día':
        return const _CategoryMeta(Icons.wb_sunny_rounded, AppPalette.warning);
      case 'Mañana':
        return const _CategoryMeta(
          Icons.wb_twilight_rounded,
          Color(0xFFF97316),
        );
      case 'Noche':
        return const _CategoryMeta(Icons.nightlight_round, Color(0xFF7C3AED));
      default:
        return const _CategoryMeta(Icons.apps_rounded, AppPalette.blue);
    }
  }
}

class _CategoryMeta {
  final IconData icon;
  final Color color;

  const _CategoryMeta(this.icon, this.color);
}

class _RoutineEntry {
  final String? section;
  final int count;
  final RoutineItem? rutina;

  const _RoutineEntry.section(this.section, this.count) : rutina = null;
  const _RoutineEntry.item(this.rutina) : section = null, count = 0;

  bool get isSection => section != null;
}

class RoutineItem {
  final String nombre;
  final String descripcion;
  final int ejercicios;
  final int minutos;
  final String nivel;
  final String categoria;
  final IconData icono;
  final Color color;
  final RoutineAvatarKind kind;
  final List<RoutinePaso>? _pasosDefinidos;

  const RoutineItem({
    required this.nombre,
    required this.descripcion,
    required this.ejercicios,
    required this.minutos,
    required this.nivel,
    required this.categoria,
    required this.icono,
    required this.color,
    required this.kind,
    List<RoutinePaso>? pasos,
  }) : _pasosDefinidos = pasos;

  /// Secuencia que se muestra en la tarjeta y se sigue en la sesión guiada.
  /// Las rutinas con varios ejercicios definen sus pasos; el resto se reparte
  /// en preparación, movimiento principal y cierre para no dejar huecos.
  List<RoutinePaso> get pasos {
    final definidos = _pasosDefinidos;
    if (definidos != null && definidos.isNotEmpty) return definidos;

    final total = minutos * 60;
    final principal = RoutinePaso(
      nombre: nombre,
      detalle: descripcion,
      segundos: total > 90 ? total - 60 : total,
      kind: kind,
    );
    if (total <= 90) return [principal];

    return [
      const RoutinePaso(
        nombre: 'Preparación',
        detalle: 'Respira y colócate en una postura cómoda antes de empezar.',
        segundos: 30,
        kind: RoutineAvatarKind.breathing,
      ),
      principal,
      const RoutinePaso(
        nombre: 'Cierre y respiración',
        detalle: 'Vuelve al centro y respira con calma para terminar.',
        segundos: 30,
        kind: RoutineAvatarKind.breathing,
      ),
    ];
  }
}
