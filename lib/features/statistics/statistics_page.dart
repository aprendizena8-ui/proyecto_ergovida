import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/services/ejercicio_service.dart';
import '../../data/services/estadisticas_service.dart';
import '../../data/services/pausa_service.dart';
import '../../main.dart';

class StatisticsPage extends StatefulWidget {
  final int? usuarioId;

  const StatisticsPage({super.key, this.usuarioId});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final EstadisticasService _estadisticasService = EstadisticasService();
  final PausaService _pausaService = PausaService();
  final EjercicioService _ejercicioService = EjercicioService();

  bool _cargando = true;
  int _pausas = 0;
  int _completadas = 0;
  int _minutos = 0;
  int _racha = 0;

  List<_DayData> _semana = [];
  List<_Actividad> _actividad = [];

  @override
  void initState() {
    super.initState();
    _cargar();
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

    if (totalPausas == 0 && pausas.isNotEmpty) {
      totalPausas = pausas.length;
      totalMinutos = pausas.length * 2;
    }

    final hoy = DateTime.now();
    final inicio = DateTime(hoy.year, hoy.month, hoy.day)
        .subtract(const Duration(days: 6));
    final semana = <_DayData>[];
    for (var i = 0; i < 7; i++) {
      final dia = inicio.add(Duration(days: i));
      final key = _keyOf(dia);
      semana.add(_DayData(dia: dia, pausas: porDia[key] ?? 0));
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
      final nombre = nombres['${_asInt(p['ejercicioId'])}'] ??
          'Pausa activa';
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
      _semana = semana;
      _actividad = actividad;
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0B1424) : const Color(0xFFEAF3F8);
    final textPrimary = isDark ? Colors.white : brandText;
    final textSecondary = isDark ? const Color(0xFFCBD5E1) : brandMuted;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text(
          'Estadísticas',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.transparent,
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
      body: widget.usuarioId == null || widget.usuarioId! <= 0
          ? _sinSesion(textPrimary, textSecondary)
          : _cargando
          ? const Center(child: CircularProgressIndicator(color: brandBlue))
          : RefreshIndicator(
              onRefresh: _cargar,
              color: brandBlue,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 32),
                children: [
                  Text(
                    'Tu progreso',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Revisa tus pausas activas y mantén el hábito saludable.',
                    style: TextStyle(color: textSecondary),
                  ),
                  const SizedBox(height: 22),
                  _resumen(isDark),
                  const SizedBox(height: 20),
                  _chartCard(isDark),
                  const SizedBox(height: 20),
                  _actividadCard(isDark),
                ],
              ),
            ),
    );
  }

  Widget _sinSesion(Color textPrimary, Color textSecondary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insights_rounded, size: 54, color: brandBlue),
            const SizedBox(height: 12),
            Text(
              'Inicia sesión para ver tus estadísticas',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Registra tus pausas y aquí verás tu evolución semanal.',
              textAlign: TextAlign.center,
              style: TextStyle(color: textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resumen(bool isDark) {
    final cards = [
      _Metric('Pausas', '$_pausas', Icons.timer_rounded, const Color(0xFF22C55E)),
      _Metric(
        'Completadas',
        '$_completadas',
        Icons.check_circle_rounded,
        brandBlue,
      ),
      _Metric('Minutos', '$_minutos', Icons.access_time_rounded, const Color(0xFFF59E0B)),
      _Metric('Racha', '$_racha d', Icons.local_fire_department_rounded, const Color(0xFFEF4444)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnas = constraints.maxWidth >= 760 ? 4 : 2;
        final ancho =
            (constraints.maxWidth - (columnas - 1) * 14) / columnas;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            for (final card in cards)
              SizedBox(
                width: ancho,
                child: _metricCard(card, isDark),
              ),
          ],
        );
      },
    );
  }

  Widget _metricCard(_Metric data, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111C2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF24364C) : const Color(0xFFDBEAF3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(data.icono, color: data.color, size: 23),
          ),
          const SizedBox(height: 14),
          Text(
            data.valor,
            style: TextStyle(
              color: isDark ? Colors.white : brandNavy,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.titulo,
            style: TextStyle(
              color: isDark ? const Color(0xFFCBD5E1) : brandMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartCard(bool isDark) {
    final maxPausas = _semana.isEmpty
        ? 0
        : _semana.map((d) => d.pausas).reduce(math.max);
    final escala = math.max(1, maxPausas);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111C2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF24364C) : const Color(0xFFDBEAF3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: brandBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: brandBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Últimos 7 días',
                      style: TextStyle(
                        color: isDark ? Colors.white : brandText,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Pausas registradas por día',
                      style: TextStyle(
                        color: isDark ? const Color(0xFFCBD5E1) : brandMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'máx $maxPausas',
                style: TextStyle(
                  color: isDark ? const Color(0xFFCBD5E1) : brandMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 190,
            child: _semana.isEmpty
                ? Center(
                    child: Text(
                      'Sin datos todavía',
                      style: TextStyle(
                        color: isDark ? const Color(0xFFCBD5E1) : brandMuted,
                      ),
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final dia in _semana)
                        Expanded(
                          child: _barra(dia, escala, isDark),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _barra(_DayData dia, int escala, bool isDark) {
    final alto = dia.pausas == 0
        ? 4.0
        : (dia.pausas / escala * 110).clamp(8.0, 110.0);
    final esHoy = _esHoy(dia.dia);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '${dia.pausas}',
          style: TextStyle(
            color: dia.pausas == 0
                ? (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))
                : brandBlue,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 22,
          height: alto,
          decoration: BoxDecoration(
            gradient: dia.pausas == 0
                ? null
                : const LinearGradient(
                    colors: [brandBlue, brandTeal],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
            color: dia.pausas == 0
                ? (isDark
                      ? const Color(0xFF24364C)
                      : const Color(0xFFE2E8F0))
                : null,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _weekday(dia.dia),
          style: TextStyle(
            color: esHoy
                ? brandBlue
                : (isDark ? const Color(0xFFCBD5E1) : brandMuted),
            fontSize: 11,
            fontWeight: esHoy ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _actividadCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111C2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF24364C) : const Color(0xFFDBEAF3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actividad reciente',
            style: TextStyle(
              color: isDark ? Colors.white : brandText,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          if (_actividad.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  'Aún no registras pausas. ¡Empieza con una!',
                  style: TextStyle(
                    color: isDark ? const Color(0xFFCBD5E1) : brandMuted,
                  ),
                ),
              ),
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
              a.completada
                  ? Icons.check_rounded
                  : Icons.timelapse_rounded,
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
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _fechaTexto(a.fecha),
                  style: TextStyle(
                    color: isDark ? const Color(0xFF9FB3C8) : brandMuted,
                    fontSize: 11,
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

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _parseFecha(dynamic value) {
    if (value == null) return null;
    if (value is List && value.length >= 3) {
      return DateTime(
        _asInt(value[0]),
        _asInt(value[1]),
        _asInt(value[2]),
      );
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

  static String _weekday(DateTime date) {
    const nombres = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return nombres[(date.weekday - 1).clamp(0, 6)];
  }

  static bool _esHoy(DateTime date) {
    final hoy = DateTime.now();
    return date.year == hoy.year &&
        date.month == hoy.month &&
        date.day == hoy.day;
  }

  static String _fechaTexto(DateTime? fecha) {
    if (fecha == null) return 'Sin fecha';
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final hora = fecha.hour.toString().padLeft(2, '0');
    final min = fecha.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year} · $hora:$min';
  }
}

class _Metric {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color color;

  const _Metric(this.titulo, this.valor, this.icono, this.color);
}

class _DayData {
  final DateTime dia;
  final int pausas;

  const _DayData({required this.dia, required this.pausas});
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
