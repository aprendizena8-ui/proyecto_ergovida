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
              '${rutina.descripcion} Incluye ${rutina.ejercicios} ejercicios guiados.',
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
                    text: 'Desde 4 min',
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
    const filtros = ['Todas', 'Oficina', 'Casa', 'Mañana', 'Noche'];

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
                text: '${rutina.ejercicios} ejercicios',
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
