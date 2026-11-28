import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/activity_types.dart';
import '../../core/theme/app_responsive.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/ejercicio_service.dart';
import '../../data/services/pausa_service.dart';
import '../../data/services/wellness_service.dart';
import '../../widgets/design_system.dart';
import '../../widgets/routine_avatar.dart';
import '../routines/routine_models.dart';

class GuidedPausePage extends StatefulWidget {
  final int usuarioId;
  final int? ejercicioId;
  final String? nombre;
  final int? duracionMin;
  final String? descripcion;
  final String? categoria;
  final RoutineAvatarKind? avatarKind;
  final Color? avatarColor;
  final List<RoutinePaso> pasos;
  final String tipoActividad;

  const GuidedPausePage({
    super.key,
    this.usuarioId = 0,
    this.ejercicioId,
    this.nombre,
    this.duracionMin,
    this.descripcion,
    this.categoria,
    this.avatarKind,
    this.avatarColor,
    this.pasos = const [],
    this.tipoActividad = ActivityTypes.detectedExercise,
  });

  @override
  State<GuidedPausePage> createState() => _GuidedPausePageState();
}

class _GuidedPausePageState extends State<GuidedPausePage>
    with SingleTickerProviderStateMixin {
  final EjercicioService _ejercicioService = EjercicioService();
  final PausaService _pausaService = PausaService();
  final WellnessService _wellnessService = WellnessService();

  late final AnimationController _breathController;

  Timer? _timer;
  List<_PauseExercise> _ejercicios = [];
  _PauseExercise? _seleccionado;
  bool _cargando = true;
  bool _corriendo = false;
  bool _terminado = false;
  bool _registrando = false;
  int _totalSegundos = 120;
  int _restantes = 120;
  int _minutosSesion = 2;

  bool get _tienePreset =>
      widget.nombre != null && widget.nombre!.trim().isNotEmpty;

  int get _pasoActual {
    if (widget.pasos.isEmpty) return 0;
    final transcurrido = _totalSegundos - _restantes;
    var acumulado = 0;
    for (var i = 0; i < widget.pasos.length; i++) {
      acumulado += widget.pasos[i].segundos;
      if (transcurrido < acumulado) return i;
    }
    return widget.pasos.length - 1;
  }

  RoutinePaso? get _pasoSeleccionado =>
      widget.pasos.isEmpty ? null : widget.pasos[_pasoActual];

  RoutineAvatarKind? get _avatarKind =>
      _pasoSeleccionado?.kind ?? widget.avatarKind;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    if (_tienePreset) {
      final minutos = (widget.duracionMin ?? 2).clamp(1, 30);
      _seleccionado = _PauseExercise(
        id: widget.ejercicioId ?? 0,
        nombre: widget.nombre!.trim(),
        descripcion:
            widget.descripcion ??
            'Respira, estira y libera la tensión acumulada durante tu jornada.',
        categoria: widget.categoria ?? 'Bienestar',
        minutos: minutos,
        icono: Icons.self_improvement_rounded,
        color: AppPalette.teal,
      );
      _minutosSesion = minutos;
      _totalSegundos = minutos * 60;
      _restantes = _totalSegundos;
      _cargando = false;
    } else {
      _cargarEjercicios();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathController.dispose();
    super.dispose();
  }

  Future<void> _cargarEjercicios() async {
    final datos = await _ejercicioService.obtenerEjercicios();
    final items = <_PauseExercise>[];

    for (final item in datos.whereType<Map>()) {
      final map = Map<String, dynamic>.from(item);
      final nombre = (map['nombre'] ?? '').toString().trim();
      if (nombre.isEmpty) continue;
      final minutos = _asInt(map['duracion']);
      items.add(
        _PauseExercise(
          id: _asInt(map['id']),
          nombre: nombre,
          descripcion: (map['descripcion'] ?? '').toString(),
          categoria: (map['categoria'] ?? 'Bienestar').toString(),
          minutos: minutos <= 0 ? 2 : minutos.clamp(1, 30),
          icono: _iconoPara('${map['categoria'] ?? ''}'),
          color: _colorPara(items.length),
        ),
      );
    }

    if (items.isEmpty) {
      items.addAll(_fallback);
    }

    if (!mounted) return;
    setState(() {
      _ejercicios = items;
      _cargando = false;
    });
  }

  List<_PauseExercise> get _fallback => const [
    _PauseExercise(
      id: 0,
      nombre: 'Respiración consciente',
      descripcion:
          'Inhala en 4 tiempos, mantén 2 y exhala en 6. Repite el ciclo para calmar la mente.',
      categoria: 'Respiración',
      minutos: 2,
      icono: Icons.air_rounded,
      color: AppPalette.teal,
    ),
    _PauseExercise(
      id: 0,
      nombre: 'Estiramiento de cuello',
      descripcion:
          'Inclina la cabeza hacia cada hombro sin forzar. Mantén 15 segundos por lado.',
      categoria: 'Cuello',
      minutos: 2,
      icono: Icons.accessibility_new_rounded,
      color: AppPalette.blue,
    ),
    _PauseExercise(
      id: 0,
      nombre: 'Descanso visual 20-20-20',
      descripcion:
          'Cada 20 minutos mira algo a 20 pies de distancia durante 20 segundos.',
      categoria: 'Vista',
      minutos: 1,
      icono: Icons.visibility_rounded,
      color: AppPalette.cyan,
    ),
    _PauseExercise(
      id: 0,
      nombre: 'Movilidad de hombros',
      descripcion:
          'Dibuja círculos lentos con los hombros, primero hacia atrás y luego hacia adelante.',
      categoria: 'Hombros',
      minutos: 3,
      icono: Icons.fitness_center_rounded,
      color: AppPalette.navySoft,
    ),
  ];

  void _seleccionar(_PauseExercise ejercicio, {int? minutos}) {
    final duracion = (minutos ?? ejercicio.minutos).clamp(1, 30);
    setState(() {
      _seleccionado = ejercicio.copyWith(minutos: duracion);
      _minutosSesion = duracion;
      _totalSegundos = duracion * 60;
      _restantes = _totalSegundos;
      _terminado = false;
      _corriendo = false;
    });
  }

  void _iniciar() {
    if (_corriendo || _terminado) return;
    setState(() => _corriendo = true);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_restantes <= 1) {
        _timer?.cancel();
        setState(() {
          _restantes = 0;
          _corriendo = false;
          _terminado = true;
        });
        _finalizar();
        return;
      }
      setState(() => _restantes--);
    });
  }

  void _pausar() {
    _timer?.cancel();
    setState(() => _corriendo = false);
  }

  void _reiniciar() {
    _timer?.cancel();
    setState(() {
      _corriendo = false;
      _terminado = false;
      _restantes = _totalSegundos;
    });
  }

  Future<void> _finalizar() async {
    final ejercicio = _seleccionado;
    if (ejercicio == null) return;

    if (mounted) setState(() => _registrando = true);

    if (widget.usuarioId > 0) {
      // Si se eligió un ejercicio del catálogo es detección; si la sesión viene
      // de una rutina o de una pausa libre, se guarda como adicional.
      final esDetectado = ejercicio.id > 0;
      await _pausaService.registrarPausa(
        usuarioId: widget.usuarioId,
        ejercicioId: esDetectado ? ejercicio.id : null,
        completada: true,
        tipo: esDetectado
            ? ActivityTypes.detectedExercise
            : widget.tipoActividad,
      );
      await _wellnessService.recordSession(
        minutes: _minutosSesion,
        userId: widget.usuarioId,
      );
    }

    if (!mounted) return;
    setState(() => _registrando = false);
  }

  String get _tiempoTexto {
    final minutos = _restantes ~/ 60;
    final segundos = _restantes % 60;
    return '$minutos:${segundos.toString().padLeft(2, '0')}';
  }

  String get _faseRespiracion {
    final ciclo = _totalSegundos - _restantes;
    final fase = ciclo % 12;
    if (fase < 4) return 'Inhala';
    if (fase < 6) return 'Mantén';
    return 'Exhala';
  }

  double get _progreso {
    if (_totalSegundos <= 0) return 0;
    return (1 - (_restantes / _totalSegundos)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.navyDeep,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text(
          'Pausa guiada',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Cerrar',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppPalette.navyDeep, AppPalette.navy, Color(0xFF0F3550)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          top: false,
          child: _cargando
              ? const Center(
                  child: CircularProgressIndicator(color: AppPalette.teal),
                )
              : _seleccionado == null
              ? _vistaSeleccion()
              : _vistaSesion(_seleccionado!),
        ),
      ),
    );
  }

  Widget _vistaSeleccion() {
    final gutter = AppResponsive.gutter(context);
    return ListView(
      padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 30),
      children: [
        Text(
          'Elige tu pausa',
          style: TextStyle(
            color: Colors.white,
            fontSize: AppResponsive.isCompact(context) ? 26 : 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Selecciona un ejercicio, ajusta los minutos y respira con calma. '
          'Al terminar registraremos la pausa en tu progreso.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 22),
        for (var i = 0; i < _ejercicios.length; i++) ...[
          AnimatedEntrance(index: i, child: _tarjetaEjercicio(_ejercicios[i])),
          if (i != _ejercicios.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _minutosYComenzar(_PauseExercise ejercicio) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 460;
        final chips = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final minutos in const [1, 2, 3, 5])
              _chipMinuto(ejercicio, minutos),
          ],
        );
        final boton = FilledButton.icon(
          onPressed: () => _seleccionar(ejercicio),
          icon: const Icon(Icons.play_arrow_rounded, size: 20),
          label: const Text('Comenzar'),
          style: FilledButton.styleFrom(
            backgroundColor: AppPalette.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [chips, const SizedBox(height: 12), boton],
          );
        }
        return Row(
          children: [
            Flexible(child: chips),
            boton,
          ],
        );
      },
    );
  }

  Widget _tarjetaEjercicio(_PauseExercise ejercicio) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(
                icon: ejercicio.icono,
                color: ejercicio.color,
                size: 48,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ejercicio.nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${ejercicio.categoria} · ${ejercicio.minutos} min',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ],
          ),
          if (ejercicio.descripcion.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              ejercicio.descripcion,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 14),
          _minutosYComenzar(ejercicio),
        ],
      ),
    );
  }

  Widget _chipMinuto(_PauseExercise ejercicio, int minutos) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.pill),
      onTap: () => _seleccionar(ejercicio, minutos: minutos),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Text(
          '$minutos min',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _vistaSesion(_PauseExercise ejercicio) {
    final center = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!_terminado)
          Text(
            _faseRespiracion,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.64),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.4,
            ),
          ),
        const SizedBox(height: 4),
        Text(
          _terminado ? '¡Listo!' : _tiempoTexto,
          style: TextStyle(
            color: Colors.white,
            fontSize: _terminado ? 30 : 42,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.4,
          ),
        ),
        if (!_terminado)
          Text(
            'de $_minutosSesion min',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          )
        else
          const Text(
            'Pausa completada',
            style: TextStyle(
              color: AppPalette.teal,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );

    final gutter = AppResponsive.gutter(context);
    return ListView(
      padding: EdgeInsets.fromLTRB(gutter, 6, gutter, 30),
      children: [
        Row(
          children: [
            IconBadge(icon: ejercicio.icono, color: ejercicio.color, size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ejercicio.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${ejercicio.categoria} · $_minutosSesion minutos',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.58),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: _corriendo || _terminado
                  ? null
                  : () => setState(() => _seleccionado = null),
              child: Text(
                'Cambiar',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        if (_avatarKind != null) ...[
          const SizedBox(height: 18),
          _avatarGuia(),
          const SizedBox(height: 12),
          if (widget.pasos.length > 1) _secuenciaPasos(),
          const SizedBox(height: 18),
        ] else
          const SizedBox(height: 28),
        Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = (constraints.maxWidth - 8)
                  .clamp(200.0, 310.0)
                  .toDouble();
              final glowSize = size * 0.84;
              final ringSize = size * 0.77;
              return SizedBox(
                width: size,
                height: size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ScaleTransition(
                      scale: Tween<double>(begin: 0.9, end: 1.06).animate(
                        CurvedAnimation(
                          parent: _breathController,
                          curve: Curves.easeInOut,
                        ),
                      ),
                      child: Container(
                        width: glowSize,
                        height: glowSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppPalette.teal.withValues(alpha: 0.24),
                              AppPalette.blue.withValues(alpha: 0.08),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.62, 1.0],
                          ),
                        ),
                      ),
                    ),
                    ProgressRing(
                      value: _progreso,
                      size: ringSize,
                      strokeWidth: size < 260 ? 9 : 12,
                      color: _terminado ? AppPalette.teal : AppPalette.cyan,
                      trackColor: Colors.white.withValues(alpha: 0.1),
                      center: center,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        if (_terminado) _completadoCard() else _controles(),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                color: AppPalette.teal,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CÓMO HACERLO',
                      style: TextStyle(
                        color: AppPalette.teal,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ejercicio.descripcion,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 12.5,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Consejo: ${_consejo(ejercicio)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.58),
                        fontSize: 11.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _avatarGuia() {
    final kind = _avatarKind!;
    final paso = _pasoSeleccionado;
    final color = widget.avatarColor ?? AppPalette.teal;
    final lineColor = Color.lerp(color, Colors.white, 0.38)!;
    final compact = AppResponsive.isCompact(context);
    final avatarWidth = compact ? 72.0 : 104.0;
    final avatarHeight = avatarWidth * 126 / 104;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.20),
            Colors.white.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: avatarWidth,
            height: avatarHeight,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 18),
              child: RepaintBoundary(
                child: RoutineAvatar(
                  kind: kind,
                  color: color,
                  lineColor: lineColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  paso == null
                      ? 'SIGUE AL AVATAR'
                      : 'PASO ${_pasoActual + 1} DE ${widget.pasos.length}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.58),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  paso?.nombre ?? kind.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  paso?.detalle ??
                      'El avatar repite el movimiento. Copia el ritmo y mantén una postura cómoda.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppPill(
                      text: widget.categoria ?? 'Bienestar',
                      color: AppPalette.teal,
                      icon: Icons.category_rounded,
                    ),
                    AppPill(
                      text: '$_minutosSesion min',
                      color: AppPalette.blueBright,
                      icon: Icons.schedule_rounded,
                    ),
                    if (paso != null)
                      AppPill(
                        text: paso.duracionTexto,
                        color: AppPalette.cyan,
                        icon: Icons.hourglass_top_rounded,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _secuenciaPasos() {
    final actual = _pasoActual;
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.pasos.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final paso = widget.pasos[index];
          final activo = index == actual;
          final completado = index < actual;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: activo
                  ? AppPalette.teal.withValues(alpha: 0.22)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppRadii.pill),
              border: Border.all(
                color: activo
                    ? AppPalette.teal.withValues(alpha: 0.65)
                    : Colors.white.withValues(alpha: 0.10),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  completado ? Icons.check_rounded : Icons.play_arrow_rounded,
                  size: 12,
                  color: activo || completado
                      ? AppPalette.teal
                      : Colors.white54,
                ),
                const SizedBox(width: 5),
                Text(
                  paso.nombre,
                  style: TextStyle(
                    color: activo ? Colors.white : Colors.white70,
                    fontSize: 11,
                    fontWeight: activo ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _controles() {
    return Column(
      children: [
        GradientButton(
          label: _corriendo ? 'Pausar' : 'Iniciar pausa',
          icon: _corriendo ? Icons.pause_rounded : Icons.play_arrow_rounded,
          onPressed: _corriendo ? _pausar : _iniciar,
          gradient: const LinearGradient(
            colors: [AppPalette.blue, AppPalette.teal],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _controlSecundario(
                icon: Icons.replay_rounded,
                label: 'Reiniciar',
                onTap: _reiniciar,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _controlSecundario(
                icon: Icons.check_rounded,
                label: 'Terminar',
                onTap: () {
                  _timer?.cancel();
                  setState(() {
                    _corriendo = false;
                    _terminado = true;
                    _restantes = 0;
                  });
                  _finalizar();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _controlSecundario({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.8)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _completadoCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppPalette.teal.withValues(alpha: 0.18),
            AppPalette.blue.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppPalette.teal.withValues(alpha: 0.36)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppPalette.teal,
                size: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _registrando
                      ? 'Registrando tu pausa...'
                      : widget.usuarioId > 0
                      ? 'Pausa guardada en tu progreso. ¡Buen trabajo!'
                      : 'Pausa completada. Inicia sesión para guardar tu progreso.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GradientButton(
                  label: 'Otra pausa',
                  icon: Icons.refresh_rounded,
                  onPressed: () => setState(() {
                    _seleccionado = null;
                    _terminado = false;
                  }),
                  gradient: const LinearGradient(
                    colors: [AppPalette.blue, AppPalette.cyan],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _controlSecundario(
                  icon: Icons.arrow_back_rounded,
                  label: 'Volver',
                  onTap: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _consejo(_PauseExercise ejercicio) {
    switch (ejercicio.categoria.toLowerCase()) {
      case 'cuello':
        return 'Mantén los hombros relajados y evita girar la cabeza con brusquedad.';
      case 'vista':
        return 'Parpadea con frecuencia y ajusta el brillo de la pantalla si sientes fatiga.';
      case 'hombros':
        return 'Realiza círculos amplios y lentos, sin elevar los hombros hacia las orejas.';
      case 'respiración':
        return 'Respira por la nariz y exhala por la boca. No retengas el aire si te incomoda.';
      default:
        return 'Muévete dentro de un rango cómodo. Si sientes dolor, detente y consulta a un profesional.';
    }
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static IconData _iconoPara(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'cuello':
        return Icons.accessibility_new_rounded;
      case 'vista':
        return Icons.visibility_rounded;
      case 'hombros':
        return Icons.fitness_center_rounded;
      case 'brazos':
        return Icons.sports_martial_arts_rounded;
      case 'espalda':
        return Icons.accessibility_rounded;
      case 'muñecas':
        return Icons.pan_tool_rounded;
      default:
        return Icons.self_improvement_rounded;
    }
  }

  static Color _colorPara(int index) {
    const colors = [
      AppPalette.blue,
      AppPalette.teal,
      AppPalette.cyan,
      AppPalette.navySoft,
    ];
    return colors[index % colors.length];
  }
}

class _PauseExercise {
  final int id;
  final String nombre;
  final String descripcion;
  final String categoria;
  final int minutos;
  final IconData icono;
  final Color color;

  const _PauseExercise({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.categoria,
    required this.minutos,
    required this.icono,
    required this.color,
  });

  _PauseExercise copyWith({int? minutos}) {
    return _PauseExercise(
      id: id,
      nombre: nombre,
      descripcion: descripcion,
      categoria: categoria,
      minutos: minutos ?? this.minutos,
      icono: icono,
      color: color,
    );
  }
}
