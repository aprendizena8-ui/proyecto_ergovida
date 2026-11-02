import 'package:flutter/material.dart';

import '../../data/models/ranking_model.dart';
import '../../data/models/user_model.dart';
import '../../data/services/ejercicio_service.dart';
import '../../data/services/estadisticas_service.dart';
import '../../data/services/pausa_service.dart';
import '../../data/services/ranking_service.dart';
import '../../main.dart';
import '../../widgets/user_avatar.dart';

class StatisticsPage extends StatefulWidget {
  final int? usuarioId;

  const StatisticsPage({super.key, this.usuarioId});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> with RouteAware {
  final EstadisticasService _estadisticasService = EstadisticasService();
  final PausaService _pausaService = PausaService();
  final EjercicioService _ejercicioService = EjercicioService();
  final RankingService _rankingService = RankingService();

  bool _cargando = true;
  int _pausas = 0;
  int _completadas = 0;
  int _minutos = 0;
  int _racha = 0;
  int _pausasSemana = 0;

  List<RankingEntry> _ranking = [];
  List<_Actividad> _actividad = [];
  Set<String> _diasActivos = {};
  late DateTime _mesCalendario = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    _cargar();
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  Future<void> _cargar() async {
    final usuarioId = widget.usuarioId;
    if (usuarioId == null || usuarioId <= 0) {
      if (mounted) setState(() => _cargando = false);
      return;
    }

    if (mounted) setState(() => _cargando = true);

    final resultados = await Future.wait([
      _estadisticasService.obtenerPorUsuario(usuarioId),
      _pausaService.obtenerPorUsuario(usuarioId),
      _ejercicioService.obtenerEjercicios(),
      _rankingService.obtenerRanking(),
    ]);

    final estadisticas = resultados[0];
    final pausas = resultados[1];
    final ejercicios = resultados[2];
    final ranking = resultados[3] as List<RankingEntry>;

    final nombres = <String, String>{};
    for (final e in ejercicios.whereType<Map>()) {
      final id = _asInt(e['id']);
      final nombre = e['nombre']?.toString();
      if (id > 0 && nombre != null && nombre.isNotEmpty) {
        nombres['$id'] = nombre;
      }
    }

    var totalPausas = 0;
    var totalMinutos = 0;
    final porDia = <String, int>{};

    for (final e in estadisticas.whereType<Map>()) {
      final p = _asInt(e['pausasRealizadas']);
      totalPausas += p;
      totalMinutos += _asInt(e['minutosActivos']);
      final fecha = _fechaKey(e['fecha']);
      if (fecha != null) {
        porDia[fecha] = (porDia[fecha] ?? 0) + p;
      }
    }

    final completadas = pausas
        .where((p) => p is Map && p['completada'] == true)
        .length;

    final diasActivos = <String>{};
    for (final entry in porDia.entries) {
      if (entry.value > 0) diasActivos.add(entry.key);
    }
    for (final pausa in pausas.whereType<Map>()) {
      final fecha = _parseFecha(pausa['fecha']);
      if (fecha != null) diasActivos.add(_keyOf(fecha));
    }

    if (totalPausas == 0 && pausas.isNotEmpty) {
      totalPausas = pausas.length;
      totalMinutos = pausas.length * 2;
    }

    final hoy = DateTime.now();
    final inicioSemana = DateTime(
      hoy.year,
      hoy.month,
      hoy.day,
    ).subtract(const Duration(days: 6));
    final finSemana = DateTime(hoy.year, hoy.month, hoy.day);

    var pausasSemana = 0;
    for (final entry in porDia.entries) {
      final fecha = DateTime.tryParse(entry.key);
      if (fecha == null) continue;
      if (!fecha.isBefore(inicioSemana) && !fecha.isAfter(finSemana)) {
        pausasSemana += entry.value;
      }
    }
    if (pausasSemana == 0 && pausas.isNotEmpty) {
      for (final pausa in pausas.whereType<Map>()) {
        final fecha = _parseFecha(pausa['fecha']);
        if (fecha == null) continue;
        final dia = DateTime(fecha.year, fecha.month, fecha.day);
        if (!dia.isBefore(inicioSemana) && !dia.isAfter(finSemana)) {
          pausasSemana++;
        }
      }
    }

    var racha = 0;
    var cursor = DateTime(hoy.year, hoy.month, hoy.day);
    if ((porDia[_keyOf(cursor)] ?? 0) == 0) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    while ((porDia[_keyOf(cursor)] ?? 0) > 0) {
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

    final actividad = listaPausas.take(6).map((p) {
      final nombre = nombres['${_asInt(p['ejercicioId'])}'] ?? 'Pausa activa';
      return _Actividad(
        nombre: nombre,
        completada: p['completada'] == true,
        fecha: _parseFecha(p['fecha']),
      );
    }).toList();

    if (!mounted) return;
    setState(() {
      _pausas = totalPausas;
      _completadas = completadas;
      _minutos = totalMinutos;
      _racha = racha;
      _pausasSemana = pausasSemana;
      _ranking = ranking;
      _actividad = actividad;
      _diasActivos = diasActivos;
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : brandText;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF08111F)
          : const Color(0xFFF1F7FC),
      appBar: AppBar(
        title: const Text(
          'Estadísticas',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
        backgroundColor: isDark
            ? const Color(0xFF08111F)
            : const Color(0xFFF1F7FC),
        surfaceTintColor: Colors.transparent,
        foregroundColor: textPrimary,
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _cargar,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [Color(0xFF08111F), Color(0xFF0D1B2E)]
                : const [Color(0xFFF1F7FC), Color(0xFFE6F1F8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: widget.usuarioId == null || widget.usuarioId! <= 0
            ? _sinSesion(isDark)
            : _cargando
            ? const Center(child: CircularProgressIndicator(color: brandBlue))
            : RefreshIndicator(
                onRefresh: _cargar,
                color: brandBlue,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 34),
                  children: [
                    _heroHeader(isDark),
                    const SizedBox(height: 18),
                    _resumen(isDark),
                    const SizedBox(height: 20),
                    _rankingCard(isDark),
                    const SizedBox(height: 20),
                    _calendarioCard(isDark),
                    const SizedBox(height: 20),
                    _actividadCard(isDark),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _sinSesion(bool isDark) {
    final textSecondary = isDark ? const Color(0xFF9FB3C8) : brandMuted;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _panel(
          isDark: isDark,
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [brandBlue, brandTeal],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Inicia sesión para ver tus estadísticas',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white : brandText,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Registra tus pausas y aquí verás tu evolución semanal.',
                textAlign: TextAlign.center,
                style: TextStyle(color: textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroHeader(bool isDark) {
    final progreso = (_pausasSemana / 5).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0E2238), Color(0xFF135B7E), Color(0xFF1F7FC0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: brandBlue.withValues(alpha: 0.3),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -48,
            right: -34,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -64,
            left: -30,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: brandTeal.withValues(alpha: 0.08),
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
                        Text(
                          'PANEL DE BIENESTAR',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.62),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tu progreso',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 29,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.7,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          _mensajeProgreso,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.74),
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  _anilloProgreso(progreso),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _heroChip(
                    Icons.local_fire_department_rounded,
                    'Racha $_racha d',
                  ),
                  _heroChip(Icons.military_tech_rounded, 'Nivel $_nivel'),
                  _heroChip(Icons.flag_rounded, '$_pausasSemana/5 esta semana'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _anilloProgreso(double progreso) {
    final porcentaje = (progreso * 100).round();

    return SizedBox(
      width: 78,
      height: 78,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 78,
            height: 78,
            child: CircularProgressIndicator(
              value: progreso,
              strokeWidth: 7,
              strokeCap: StrokeCap.round,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              color: brandTeal,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$porcentaje%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'meta',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.62),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroChip(IconData icono, String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 14, color: Colors.white.withValues(alpha: 0.86)),
          const SizedBox(width: 6),
          Text(
            texto,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resumen(bool isDark) {
    final cards = [
      _Metric(
        'Pausas',
        '$_pausas',
        'Registros totales',
        Icons.self_improvement_rounded,
        const Color(0xFF22C55E),
      ),
      _Metric(
        'Completadas',
        '$_completadas',
        'Ejercicios completados',
        Icons.check_circle_rounded,
        brandBlue,
      ),
      _Metric(
        'Minutos',
        '$_minutos',
        'Tiempo activo',
        Icons.access_time_rounded,
        const Color(0xFFF59E0B),
      ),
      _Metric(
        'Racha',
        '$_racha',
        'Días consecutivos',
        Icons.local_fire_department_rounded,
        const Color(0xFFEF4444),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnas = constraints.maxWidth >= 760 ? 4 : 2;
        final ancho = (constraints.maxWidth - (columnas - 1) * 14) / columnas;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            for (final card in cards)
              SizedBox(width: ancho, child: _metricCard(card, isDark)),
          ],
        );
      },
    );
  }

  Widget _metricCard(_Metric data, bool isDark) {
    final color = data.color;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1E31) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF1E3350) : const Color(0xFFE1EEF7),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.22)
                : brandNavy.withValues(alpha: 0.05),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -18,
            right: -18,
            child: Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: isDark ? 0.1 : 0.06),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.95),
                      color.withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(data.icono, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 16),
              Text(
                data.valor,
                style: TextStyle(
                  color: isDark ? Colors.white : brandNavy,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.titulo,
                style: TextStyle(
                  color: isDark ? Colors.white : brandText,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.subtitulo,
                style: TextStyle(
                  color: isDark ? const Color(0xFF9FB3C8) : brandMuted,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rankingCard(bool isDark) {
    return _panel(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            isDark: isDark,
            icono: Icons.emoji_events_rounded,
            color: const Color(0xFFF59E0B),
            titulo: 'Ranking de Usuarios',
            subtitulo: 'Los más constantes de ErgoVida',
            trailing: _pill('${_ranking.length} usuarios', brandBlue, isDark),
          ),
          const SizedBox(height: 16),
          if (_ranking.isEmpty)
            _emptyState(
              isDark,
              Icons.emoji_events_outlined,
              'Aún no hay usuarios con pausas registradas',
            )
          else
            ..._ranking.asMap().entries.map((entry) {
              return _rankingTile(entry.key + 1, entry.value, isDark);
            }),
        ],
      ),
    );
  }

  Widget _rankingTile(int position, RankingEntry item, bool isDark) {
    final esTop = position <= 3;
    final accent = position == 1
        ? const Color(0xFFF59E0B)
        : position == 2
        ? const Color(0xFF94A3B8)
        : position == 3
        ? const Color(0xFFB45309)
        : brandBlue;
    final esYo = item.usuarioId == widget.usuarioId;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: esTop
            ? accent.withValues(alpha: isDark ? 0.12 : 0.08)
            : (isDark
                  ? Colors.white.withValues(alpha: 0.02)
                  : const Color(0xFFF8FAFD)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: esTop
              ? accent.withValues(alpha: 0.32)
              : (isDark ? const Color(0xFF1E3350) : const Color(0xFFEDF4FA)),
          width: esTop ? 1.3 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: esTop ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _posicion(position),
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 10),
          UserAvatar(
            usuario: UserModel(
              id: item.usuarioId,
              nombre: item.nombre,
              correo: '',
              avatar: item.avatar,
              fotoPerfil: item.fotoPerfil,
            ),
            radius: 19,
            ringWidth: 1,
            ringColor: accent.withValues(alpha: 0.45),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark ? Colors.white : brandText,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    if (esYo) ...[
                      const SizedBox(width: 6),
                      _miniTag('Tú', brandTeal),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.totalPausas} pausas acumuladas',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF9FB3C8) : brandMuted,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.14),
            ),
            child: Icon(
              esTop
                  ? Icons.workspace_premium_rounded
                  : Icons.trending_up_rounded,
              size: 18,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _calendarioCard(bool isDark) {
    final hoy = DateTime.now();
    final mes = _mesCalendario;
    final primerDia = DateTime(mes.year, mes.month, 1);
    final offset = primerDia.weekday - 1;
    final diasEnMes = DateTime(mes.year, mes.month + 1, 0).day;
    final totalCeldas = ((offset + diasEnMes + 6) ~/ 7) * 7;
    final siguienteMes = DateTime(mes.year, mes.month + 1);
    final puedeAvanzar = siguienteMes.isBefore(
      DateTime(hoy.year, hoy.month + 1),
    );

    final activosMes = List.generate(diasEnMes, (index) => index + 1)
        .where(
          (dia) =>
              _diasActivos.contains(_keyOf(DateTime(mes.year, mes.month, dia))),
        )
        .length;

    final textSecondary = isDark ? const Color(0xFF9FB3C8) : brandMuted;

    return _panel(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            isDark: isDark,
            icono: Icons.calendar_month_rounded,
            color: brandTeal,
            titulo: 'Calendario de actividad',
            subtitulo: 'Días en los que realizaste ejercicios',
            trailing: _pill('$activosMes activos', brandTeal, isDark),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _monthButton(
                isDark: isDark,
                icono: Icons.chevron_left_rounded,
                onPressed: () => _cambiarMes(-1),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : const Color(0xFFF3F8FC),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF1E3350)
                          : const Color(0xFFE8F1F8),
                    ),
                  ),
                  child: Text(
                    '${_mesNombre(mes.month)} ${mes.year}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white : brandText,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _monthButton(
                isDark: isDark,
                icono: Icons.chevron_right_rounded,
                onPressed: puedeAvanzar ? () => _cambiarMes(1) : null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final dia in const [
                'Lun',
                'Mar',
                'Mié',
                'Jue',
                'Vie',
                'Sáb',
                'Dom',
              ])
                Expanded(
                  child: Text(
                    dia,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCeldas,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final dia = index - offset + 1;
              if (dia < 1 || dia > diasEnMes) {
                return const SizedBox.shrink();
              }
              return _diaCalendario(mes, dia, isDark);
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _leyenda(
                color: brandTeal,
                texto: 'Con ejercicio',
                isDark: isDark,
                activo: true,
              ),
              const SizedBox(width: 16),
              _leyenda(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
                texto: 'Sin registro',
                isDark: isDark,
                activo: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _monthButton({
    required bool isDark,
    required IconData icono,
    required VoidCallback? onPressed,
  }) {
    return Material(
      color: isDark ? const Color(0xFF15263D) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? const Color(0xFF1E3350) : const Color(0xFFE1EEF7),
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icono),
        color: isDark ? Colors.white : brandBlue,
        disabledColor: isDark
            ? const Color(0xFF475569)
            : const Color(0xFFB6C5D3),
        iconSize: 20,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _diaCalendario(DateTime mes, int dia, bool isDark) {
    final fecha = DateTime(mes.year, mes.month, dia);
    final activo = _diasActivos.contains(_keyOf(fecha));
    final hoy = DateTime.now();
    final esHoy =
        fecha.year == hoy.year &&
        fecha.month == hoy.month &&
        fecha.day == hoy.day;
    final esFuturo = fecha.isAfter(DateTime(hoy.year, hoy.month, hoy.day));

    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: activo
            ? const LinearGradient(
                colors: [brandBlue, brandTeal],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: activo
            ? null
            : (isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : const Color(0xFFF6FAFD)),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: esHoy
              ? brandBlue
              : (isDark ? const Color(0xFF1E3350) : const Color(0xFFE8F1F8)),
          width: esHoy ? 2 : 1,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            '$dia',
            style: TextStyle(
              color: activo
                  ? Colors.white
                  : esFuturo
                  ? (isDark ? const Color(0xFF64748B) : const Color(0xFFB6C5D3))
                  : (isDark ? const Color(0xFFCBD5E1) : brandText),
              fontSize: 12,
              fontWeight: activo || esHoy ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
          if (activo)
            Positioned(
              bottom: 5,
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _leyenda({
    required Color color,
    required String texto,
    required bool isDark,
    required bool activo,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            gradient: activo
                ? const LinearGradient(colors: [brandBlue, brandTeal])
                : null,
            color: activo ? null : color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          texto,
          style: TextStyle(
            color: isDark ? const Color(0xFF9FB3C8) : brandMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  void _cambiarMes(int delta) {
    setState(() {
      _mesCalendario = DateTime(
        _mesCalendario.year,
        _mesCalendario.month + delta,
      );
    });
  }

  Widget _actividadCard(bool isDark) {
    return _panel(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            isDark: isDark,
            icono: Icons.history_rounded,
            color: brandBlue,
            titulo: 'Actividad reciente',
            subtitulo: 'Tus últimos ejercicios registrados',
            trailing: _pill('${_actividad.length}', brandBlue, isDark),
          ),
          const SizedBox(height: 16),
          if (_actividad.isEmpty)
            _emptyState(
              isDark,
              Icons.self_improvement_rounded,
              'Aún no registras pausas. ¡Empieza con una!',
            )
          else
            ..._actividad.map((a) => _actividadTile(a, isDark)),
        ],
      ),
    );
  }

  Widget _actividadTile(_Actividad a, bool isDark) {
    final color = a.completada
        ? const Color(0xFF22C55E)
        : const Color(0xFFF59E0B);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.02)
            : const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E3350) : const Color(0xFFEDF4FA),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              a.completada ? Icons.check_rounded : Icons.timelapse_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white : brandText,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _fechaTexto(a.fecha),
                  style: TextStyle(
                    color: isDark ? const Color(0xFF9FB3C8) : brandMuted,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              a.completada ? 'Completada' : 'Registrada',
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel({
    required bool isDark,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(20),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1E31) : Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isDark ? const Color(0xFF1E3350) : const Color(0xFFE1EEF7),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.22)
                : brandNavy.withValues(alpha: 0.05),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionHeader({
    required bool isDark,
    required IconData icono,
    required Color color,
    required String titulo,
    required String subtitulo,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.24),
                color.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.24)),
          ),
          child: Icon(icono, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: TextStyle(
                  color: isDark ? Colors.white : brandText,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitulo,
                style: TextStyle(
                  color: isDark ? const Color(0xFF9FB3C8) : brandMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 10), trailing],
      ],
    );
  }

  Widget _pill(String texto, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _miniTag(String texto, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _emptyState(bool isDark, IconData icono, String texto) {
    final muted = isDark ? const Color(0xFF64748B) : const Color(0xFF9FB3C8);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: Column(
          children: [
            Icon(icono, color: muted, size: 32),
            const SizedBox(height: 8),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? const Color(0xFF9FB3C8) : brandMuted,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _nivel {
    if (_pausas >= 50) return 'Experto';
    if (_pausas >= 20) return 'Constante';
    if (_pausas >= 5) return 'En marcha';
    return 'Inicial';
  }

  String get _mensajeProgreso {
    if (_pausas == 0) {
      return 'Comienza hoy tu primera pausa activa y cuida tu bienestar.';
    }
    if (_pausasSemana >= 5) {
      return '¡Meta semanal cumplida! Sigue así para mantener tu racha.';
    }
    final faltan = 5 - _pausasSemana;
    return 'Te faltan $faltan pausas para completar tu meta semanal.';
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _parseFecha(dynamic value) {
    if (value == null) return null;
    if (value is List && value.length >= 3) {
      return DateTime(_asInt(value[0]), _asInt(value[1]), _asInt(value[2]));
    }
    final raw = value.toString();
    return DateTime.tryParse(raw) ?? DateTime.tryParse(raw.split('T').first);
  }

  static String? _fechaKey(dynamic value) {
    final parsed = _parseFecha(value);
    if (parsed == null) return null;
    return _keyOf(parsed);
  }

  static String _keyOf(DateTime date) {
    final mes = date.month.toString().padLeft(2, '0');
    final dia = date.day.toString().padLeft(2, '0');
    return '${date.year}-$mes-$dia';
  }

  static String _posicion(int posicion) {
    if (posicion == 1) return '1ro';
    if (posicion == 2) return '2do';
    if (posicion == 3) return '3ro';
    return '${posicion}to';
  }

  static String _mesNombre(int mes) {
    const nombres = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return nombres[(mes - 1).clamp(0, 11)];
  }

  static String _fechaTexto(DateTime? fecha) {
    if (fecha == null) return 'Sin fecha';
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final hora = fecha.hour.toString().padLeft(2, '0');
    final min = fecha.minute.toString().padLeft(2, '0');

    final hoy = DateTime.now();
    final base = DateTime(fecha.year, fecha.month, fecha.day);
    final hoyBase = DateTime(hoy.year, hoy.month, hoy.day);
    final diferencia = hoyBase.difference(base).inDays;

    final prefijo = diferencia == 0
        ? 'Hoy'
        : diferencia == 1
        ? 'Ayer'
        : '';
    if (prefijo.isNotEmpty) return '$prefijo · $hora:$min';

    return '$dia/$mes/${fecha.year} · $hora:$min';
  }
}

class _Metric {
  final String titulo;
  final String valor;
  final String subtitulo;
  final IconData icono;
  final Color color;

  const _Metric(
    this.titulo,
    this.valor,
    this.subtitulo,
    this.icono,
    this.color,
  );
}

class _Actividad {
  final String nombre;
  final bool completada;
  final DateTime? fecha;

  const _Actividad({
    required this.nombre,
    required this.completada,
    required this.fecha,
  });
}
