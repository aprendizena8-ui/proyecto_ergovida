import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/services/auth_service.dart';
import '../../widgets/design_system.dart';
import '../pauses/guided_pause_page.dart';

class RoutinePage extends StatefulWidget {
  const RoutinePage({super.key});

  @override
  State<RoutinePage> createState() => _RoutinePageState();
}

class _RoutinePageState extends State<RoutinePage> {
  String _filtro = 'Todas';

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
    ),
  ];

  List<RoutineItem> get _visibles {
    if (_filtro == 'Todas') return _rutinas;
    return _rutinas.where((r) => r.categoria == _filtro).toList();
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
          descripcion:
              '${rutina.descripcion} Incluye ${rutina.ejercicios} ${rutina.ejercicios == 1 ? 'ejercicio guiado' : 'ejercicios guiados'}.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppPalette.darkBackground : AppPalette.background;

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
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _hero(),
                    const SizedBox(height: 22),
                    _filtros(),
                    const SizedBox(height: 18),
                    for (var i = 0; i < _visibles.length; i++) ...[
                      AnimatedEntrance(
                        index: i,
                        child: _rutinaCard(_visibles[i], isDark),
                      ),
                      if (i != _visibles.length - 1) const SizedBox(height: 14),
                    ],
                  ]),
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
      padding: const EdgeInsets.all(24),
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
          Column(
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
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Selecciona la rutina ideal para tu momento del día. '
                'Cada plan incluye un temporizador guiado y registro de progreso.',
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
                    text: 'Desde 3 min',
                    color: AppPalette.teal,
                    icon: Icons.schedule_rounded,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filtros() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const filtros = ['Todas', 'Oficina', 'Casa', 'Día', 'Mañana', 'Noche'];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filtros.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filtro = filtros[index];
          final activo = _filtro == filtro;
          return InkWell(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            onTap: () => setState(() => _filtro = filtro),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                gradient: activo
                    ? const LinearGradient(
                        colors: [AppPalette.blue, AppPalette.teal],
                      )
                    : null,
                color: activo
                    ? null
                    : (isDark ? AppPalette.darkSurface : Colors.white),
                borderRadius: BorderRadius.circular(AppRadii.pill),
                border: Border.all(
                  color: activo
                      ? Colors.transparent
                      : (isDark
                            ? AppPalette.darkBorder
                            : AppPalette.border),
                ),
              ),
              child: Text(
                filtro,
                style: TextStyle(
                  color: activo ? Colors.white : AppPalette.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _rutinaCard(RoutineItem rutina, bool isDark) {
    return AppSurface(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(
                icon: rutina.icono,
                color: rutina.color,
                size: 50,
                filled: true,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rutina.nombre,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rutina.descripcion,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppPalette.muted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              AppPill(text: rutina.nivel, color: rutina.color),
            ],
          ),
          const SizedBox(height: 16),
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
                text: rutina.categoria,
                color: AppPalette.muted,
                icon: Icons.category_rounded,
              ),
            ],
          ),
          const SizedBox(height: 18),
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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: rutina.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.timer_rounded,
                  color: rutina.color,
                  size: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
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

  const RoutineItem({
    required this.nombre,
    required this.descripcion,
    required this.ejercicios,
    required this.minutos,
    required this.nivel,
    required this.categoria,
    required this.icono,
    required this.color,
  });
}
