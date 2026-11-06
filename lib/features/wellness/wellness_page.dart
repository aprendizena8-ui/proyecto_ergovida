import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/services/estadisticas_service.dart';
import '../../data/services/pausa_service.dart';
import '../../data/services/wellness_service.dart';
import '../../widgets/design_system.dart';
import '../pauses/guided_pause_page.dart';

class WellnessPage extends StatefulWidget {
  final int usuarioId;

  const WellnessPage({super.key, required this.usuarioId});

  @override
  State<WellnessPage> createState() => _WellnessPageState();
}

class _WellnessPageState extends State<WellnessPage> {
  final WellnessService _wellnessService = WellnessService();
  final EstadisticasService _estadisticasService = EstadisticasService();
  final PausaService _pausaService = PausaService();

  WellnessData _bienestar = WellnessData.empty();
  bool _cargando = true;
  int _totalPausas = 0;
  int _completadas = 0;
  int _minutos = 0;
  int _rachaApi = 0;
  int _pausasHoyApi = 0;

  int get _racha {
    final local = _bienestar.streak;
    return local > _rachaApi ? local : _rachaApi;
  }

  int get _progresoHoy {
    final local = _bienestar.todaySessions().count;
    return local > _pausasHoyApi ? local : _pausasHoyApi;
  }

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (mounted) setState(() => _cargando = true);

    final bienestar = await _wellnessService.load(widget.usuarioId);
    var estadisticas = <dynamic>[];
    var pausas = <dynamic>[];

    if (widget.usuarioId > 0) {
      final resultados = await Future.wait([
        _estadisticasService.obtenerPorUsuario(widget.usuarioId),
        _pausaService.obtenerPorUsuario(widget.usuarioId),
      ]);
      estadisticas = resultados[0];
      pausas = resultados[1];
    }

    var totalPausas = 0;
    var totalMinutos = 0;
    var pausasHoy = 0;
    final porDia = <String, int>{};
    final hoyKey = WellnessService.dateKey(DateTime.now());

    for (final e in estadisticas.whereType<Map>()) {
      final cantidad = _asInt(e['pausasRealizadas']);
      totalPausas += cantidad;
      totalMinutos += _asInt(e['minutosActivos']);
      final fecha = _parseFecha(e['fecha']);
      if (fecha == null) continue;
      final key = WellnessService.dateKey(fecha);
      porDia[key] = (porDia[key] ?? 0) + cantidad;
      if (key == hoyKey) pausasHoy += cantidad;
    }

    final completadas = pausas
        .where((p) => p is Map && p['completada'] == true)
        .length;

    if (totalPausas == 0 && pausas.isNotEmpty) {
      totalPausas = pausas.length;
      totalMinutos = pausas.length * 2;
    }

    for (final pausa in pausas.whereType<Map>()) {
      final fecha = _parseFecha(pausa['fecha']);
      if (fecha == null) continue;
      final key = WellnessService.dateKey(fecha);
      porDia[key] = porDia[key] ?? 0;
    }

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

    if (!mounted) return;
    setState(() {
      _bienestar = bienestar;
      _totalPausas = totalPausas;
      _completadas = completadas;
      _minutos = totalMinutos;
      _rachaApi = racha;
      _pausasHoyApi = pausasHoy;
      _cargando = false;
    });
  }

  Future<void> _guardarMood(MoodOption option) async {
    await _wellnessService.saveMood(
      option.score,
      userId: widget.usuarioId,
    );
    if (!mounted) return;
    setState(() {
      final moods = Map<String, MoodEntry>.from(_bienestar.moods);
      moods[WellnessService.dateKey(DateTime.now())] = MoodEntry(
        score: option.score,
      );
      _bienestar = _bienestar.copyWith(moods: moods);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Check-in guardado: ${option.label}. ¡Gracias por compartir!'),
      ),
    );
  }

  Future<void> _agregarNota() async {
    final actual = _bienestar.todayMood();
    final controller = TextEditingController(text: actual?.note ?? '');
    final nota = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nota de bienestar'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          maxLength: 220,
          decoration: const InputDecoration(
            hintText: '¿Qué influyó en cómo te sientes hoy?',
            alignLabelWithHint: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (nota == null) return;
    final score = _bienestar.todayMood()?.score ?? 3;
    await _wellnessService.saveMood(
      score,
      note: nota,
      userId: widget.usuarioId,
    );
    if (!mounted) return;
    setState(() {
      final moods = Map<String, MoodEntry>.from(_bienestar.moods);
      moods[WellnessService.dateKey(DateTime.now())] = MoodEntry(
        score: score,
        note: nota,
      );
      _bienestar = _bienestar.copyWith(moods: moods);
    });
  }

  Future<void> _cambiarMeta(int delta) async {
    final nueva = (_bienestar.dailyGoal + delta).clamp(1, 12);
    if (nueva == _bienestar.dailyGoal) return;
    await _wellnessService.setDailyGoal(nueva, widget.usuarioId);
    if (!mounted) return;
    setState(() {
      _bienestar = _bienestar.copyWith(dailyGoal: nueva);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargar,
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 130,
                    backgroundColor: AppPalette.navy,
                    foregroundColor: Colors.white,
                    surfaceTintColor: Colors.transparent,
                    flexibleSpace: FlexibleSpaceBar(
                      title: const Text(
                        'Bienestar',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppPalette.navyDeep,
                              AppPalette.navy,
                              Color(0xFF15527A),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _hero(),
                        const SizedBox(height: 18),
                        _metaDiaria(),
                        const SizedBox(height: 18),
                        _checkIn(),
                        const SizedBox(height: 18),
                        _animoSemana(),
                        const SizedBox(height: 18),
                        _logros(),
                        const SizedBox(height: 18),
                        _consejos(),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _hero() {
    final progreso = _bienestar.dailyGoal <= 0
        ? 0.0
        : (_progresoHoy / _bienestar.dailyGoal).clamp(0.0, 1.0);
    final porcentaje = (progreso * 100).round();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppPalette.navy, Color(0xFF135B7E), AppPalette.blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadii.xl),
        boxShadow: AppShadows.glow(AppPalette.blue),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TU MOMENTO DE CALMA',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.62),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Cuida tu bienestar, un día a la vez',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$_progresoHoy pausas hoy · racha de $_racha días',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: 190,
                      child: GradientButton(
                        label: 'Iniciar pausa',
                        icon: Icons.play_arrow_rounded,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GuidedPausePage(
                                usuarioId: widget.usuarioId,
                              ),
                            ),
                          );
                          if (mounted) _cargar();
                        },
                        gradient: const LinearGradient(
                          colors: [AppPalette.teal, AppPalette.cyan],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ProgressRing(
                value: progreso,
                size: 96,
                strokeWidth: 9,
                color: AppPalette.teal,
                trackColor: Colors.white.withValues(alpha: 0.16),
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$porcentaje%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'meta',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metaDiaria() {
    final hoy = _progresoHoy;
    final meta = _bienestar.dailyGoal;
    final restantes = (meta - hoy).clamp(0, meta);

    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBadge(
                icon: Icons.flag_rounded,
                color: AppPalette.blue,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Meta diaria de pausas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      restantes == 0
                          ? '¡Meta cumplida! Sigue así.'
                          : 'Te faltan $restantes pausa${restantes == 1 ? '' : 's'} para cumplir tu meta.',
                      style: const TextStyle(
                        color: AppPalette.muted,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  child: LinearProgressIndicator(
                    value: meta == 0 ? 0 : (hoy / meta).clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: const Color(0xFFE6EFF7),
                    color: AppPalette.blue,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                '$hoy / $meta',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppPalette.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _stepper(
                icon: Icons.remove_rounded,
                onTap: () => _cambiarMeta(-1),
              ),
              const SizedBox(width: 10),
              _stepper(
                icon: Icons.add_rounded,
                onTap: () => _cambiarMeta(1),
              ),
              const Spacer(),
              Text(
                'Ajusta tu objetivo',
                style: TextStyle(
                  color: AppPalette.muted.withValues(alpha: 0.9),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepper({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppPalette.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppPalette.blue.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, size: 19, color: AppPalette.blue),
      ),
    );
  }

  Widget _checkIn() {
    final mood = _bienestar.todayMood();
    final seleccion = mood == null ? null : MoodOption.forScore(mood.score);

    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Check-in de bienestar',
            subtitle: '¿Cómo te sientes en este momento?',
            icon: Icons.favorite_rounded,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              for (final option in MoodOption.options)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _moodButton(
                      option,
                      seleccion?.score == option.score,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (seleccion != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Color(seleccion.color).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Text(
                    seleccion.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      (mood?.note.isNotEmpty ?? false)
                          ? mood!.note
                          : 'Hoy te sientes: ${seleccion.label}. Puedes añadir una nota.',
                      style: TextStyle(
                        color: Color(seleccion.color),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _agregarNota,
                    child: const Text('Nota'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _moodButton(MoodOption option, bool selected) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _guardarMood(option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? Color(option.color).withValues(alpha: 0.14)
              : const Color(0xFFF5F9FC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? Color(option.color).withValues(alpha: 0.5)
                : const Color(0xFFE6EFF7),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(option.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 5),
            Text(
              option.label.split(' ').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? Color(option.color) : AppPalette.muted,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _animoSemana() {
    final dias = <_DiaAnimo>[];
    for (var i = 6; i >= 0; i--) {
      final fecha = DateTime.now().subtract(Duration(days: i));
      final mood = _bienestar.moods[WellnessService.dateKey(fecha)];
      dias.add(
        _DiaAnimo(
          fecha: fecha,
          score: mood?.score,
          label: _diaSemana(fecha.weekday),
        ),
      );
    }

    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Ánimo de la semana',
            subtitle: 'Tu registro emocional de los últimos 7 días',
            icon: Icons.insights_rounded,
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final dia in dias)
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 84,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            width: 22,
                            height: dia.score == null
                                ? 10
                                : 18.0 + (dia.score! * 12),
                            decoration: BoxDecoration(
                              gradient: dia.score == null
                                  ? null
                                  : LinearGradient(
                                      colors: [
                                        AppPalette.blue,
                                        AppPalette.teal,
                                      ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                              color: dia.score == null
                                  ? const Color(0xFFE6EFF7)
                                  : null,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dia.label,
                        style: const TextStyle(
                          color: AppPalette.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _logros() {
    final logros = <_Logro>[
      _Logro(
        titulo: 'Primer paso',
        descripcion: 'Completa tu primera pausa',
        icono: Icons.flag_rounded,
        color: AppPalette.blue,
        progreso: (_totalPausas >= 1) ? 1 : 0,
      ),
      _Logro(
        titulo: 'Constancia',
        descripcion: 'Mantén una racha de 3 días',
        icono: Icons.local_fire_department_rounded,
        color: const Color(0xFFF97316),
        progreso: (_racha / 3).clamp(0.0, 1.0),
      ),
      _Logro(
        titulo: 'En racha',
        descripcion: 'Mantén una racha de 7 días',
        icono: Icons.bolt_rounded,
        color: const Color(0xFFEF4444),
        progreso: (_racha / 7).clamp(0.0, 1.0),
      ),
      _Logro(
        titulo: 'Explorador',
        descripcion: 'Completa 10 ejercicios',
        icono: Icons.explore_rounded,
        color: AppPalette.teal,
        progreso: (_completadas / 10).clamp(0.0, 1.0),
      ),
      _Logro(
        titulo: 'Equilibrio',
        descripcion: 'Acumula 60 minutos activos',
        icono: Icons.timer_rounded,
        color: AppPalette.cyan,
        progreso: (_minutos / 60).clamp(0.0, 1.0),
      ),
      _Logro(
        titulo: 'Autocuidado',
        descripcion: 'Registra tu ánimo',
        icono: Icons.favorite_rounded,
        color: const Color(0xFFEC4899),
        progreso: _bienestar.moods.isEmpty ? 0 : 1,
      ),
    ];

    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Logros',
            subtitle: 'Desbloquea insignias mientras cuidas de ti',
            icon: Icons.workspace_premium_rounded,
            trailing: AppPill(
              text: '${logros.where((l) => l.progreso >= 1).length}/${logros.length}',
              color: AppPalette.teal,
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final columnas = constraints.maxWidth >= 620 ? 3 : 2;
              final ancho =
                  (constraints.maxWidth - (columnas - 1) * 12) / columnas;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final logro in logros)
                    SizedBox(width: ancho, child: _logroCard(logro)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _logroCard(_Logro logro) {
    final desbloqueado = logro.progreso >= 1;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: desbloqueado
            ? logro.color.withValues(alpha: 0.08)
            : const Color(0xFFF7FAFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: desbloqueado
              ? logro.color.withValues(alpha: 0.3)
              : const Color(0xFFE8F0F7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(
                icon: desbloqueado ? logro.icono : Icons.lock_outline_rounded,
                color: desbloqueado ? logro.color : AppPalette.muted,
                size: 38,
              ),
              const Spacer(),
              if (desbloqueado)
                Icon(
                  Icons.verified_rounded,
                  color: logro.color,
                  size: 18,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            logro.titulo,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: desbloqueado ? AppPalette.text : AppPalette.muted,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            logro.descripcion,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppPalette.muted,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: logro.progreso,
              minHeight: 5,
              backgroundColor: const Color(0xFFE8F0F7),
              color: logro.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _consejos() {
    const consejos = [
      _Consejo(
        titulo: 'Regla 20-20-20',
        texto:
            'Cada 20 minutos, mira 20 segundos algo a 20 pies (6 metros) para descansar la vista.',
        icono: Icons.visibility_rounded,
      ),
      _Consejo(
        titulo: 'Hidratación consciente',
        texto:
            'Ten una botella de agua cerca y bebe pequeños sorbos durante la jornada.',
        icono: Icons.water_drop_rounded,
      ),
      _Consejo(
        titulo: 'Pausas cortas, grandes cambios',
        texto:
            '2 minutos de movimiento cada hora reducen la tensión muscular y mejoran la concentración.',
        icono: Icons.self_improvement_rounded,
      ),
    ];

    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Consejos de bienestar',
            subtitle: 'Pequeños hábitos que suman',
            icon: Icons.spa_rounded,
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < consejos.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconBadge(
                  icon: consejos[i].icono,
                  color: AppPalette.teal,
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        consejos[i].titulo,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        consejos[i].texto,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppPalette.muted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (i != consejos.length - 1) const AppDivider(vertical: 14),
          ],
        ],
      ),
    );
  }

  static String _diaSemana(int weekday) {
    const dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return dias[(weekday - 1).clamp(0, 6)];
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _parseFecha(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}

class _DiaAnimo {
  final DateTime fecha;
  final int? score;
  final String label;

  const _DiaAnimo({
    required this.fecha,
    required this.score,
    required this.label,
  });
}

class _Logro {
  final String titulo;
  final String descripcion;
  final IconData icono;
  final Color color;
  final double progreso;

  const _Logro({
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.color,
    required this.progreso,
  });
}

class _Consejo {
  final String titulo;
  final String texto;
  final IconData icono;

  const _Consejo({
    required this.titulo,
    required this.texto,
    required this.icono,
  });
}
