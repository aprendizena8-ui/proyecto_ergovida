import 'package:flutter/material.dart';

import '../../core/constants/activity_types.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/usuario_estadistica_model.dart';
import '../../data/services/estadisticas_service.dart';
import '../../data/services/pausa_service.dart';
import '../../data/services/sst_metas_service.dart';
import '../../main.dart';
import '../../widgets/design_system.dart';
import 'sst_metas_dialog.dart';

/// Gráfica semanal de pausas activas de un usuario, vista por el líder SST.
class UserStatsPage extends StatefulWidget {
  final UsuarioEstadistica usuario;

  const UserStatsPage({super.key, required this.usuario});

  @override
  State<UserStatsPage> createState() => _UserStatsPageState();
}

class _UserStatsPageState extends State<UserStatsPage> {
  final EstadisticasService _estadisticasService = EstadisticasService();
  final PausaService _pausaService = PausaService();

  List<dynamic> _estadisticas = const [];
  List<dynamic> _pausas = const [];
  SstMetasConfig _metas = const SstMetasConfig();
  bool _cargando = true;
  String? _error;
  int _diaSeleccionado = 0;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (mounted) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }

    try {
      final resultados = await Future.wait([
        _estadisticasService.obtenerPorUsuario(widget.usuario.id),
        _pausaService.obtenerPorUsuario(widget.usuario.id),
        SstMetasService.instance.cargar(),
      ]);
      if (!mounted) return;
      final indiceHoy = (DateTime.now().weekday - 1).clamp(0, 4);
      setState(() {
        _estadisticas = resultados[0] as List<dynamic>;
        _pausas = resultados[1] as List<dynamic>;
        _metas = resultados[2] as SstMetasConfig;
        _diaSeleccionado = indiceHoy;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'No se pudieron cargar las estadísticas del usuario.';
      });
    }
  }

  Future<void> _abrirMetas() async {
    final resultado = await showDialog<SstMetasConfig>(
      context: context,
      builder: (_) => SstMetasDialog(config: _metas),
    );
    if (resultado == null) return;
    try {
      await SstMetasService.instance.guardar(resultado);
      if (!mounted) return;
      setState(() => _metas = resultado);
      _mensaje('Metas de pausas activas actualizadas');
    } catch (_) {
      if (!mounted) return;
      _mensaje('No se pudieron guardar las metas', ok: false);
    }
  }

  void _mensaje(String texto, {bool ok = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ok ? const Color(0xFF15803D) : AppPalette.danger,
        behavior: SnackBarBehavior.floating,
        content: Text(texto),
      ),
    );
  }

  List<_DiaPausas> _construirDias() {
    final hoy = DateTime.now();
    final inicio = DateTime(
      hoy.year,
      hoy.month,
      hoy.day,
    ).subtract(Duration(days: hoy.weekday - 1));

    final porDia = <String, int>{};
    for (final item in _estadisticas.whereType<Map>()) {
      final clave = _fechaKey(item['fecha']);
      if (clave == null) continue;
      final cantidad = _asInt(item['pausasRealizadas']);
      porDia[clave] = (porDia[clave] ?? 0) + cantidad;
    }

    // Respaldo: si no hay fila de estadísticas para ese día, se cuentan los
    // ejercicios detectados y completados registrados en pausas_realizadas.
    final detectadosPorDia = <String, int>{};
    for (final item in _pausas.whereType<Map>()) {
      if (item['completada'] != true ||
          !ActivityTypes.isDetected(item['tipo'])) {
        continue;
      }
      final clave = _fechaKey(item['fecha']);
      if (clave == null) continue;
      detectadosPorDia[clave] = (detectadosPorDia[clave] ?? 0) + 1;
    }

    const nombres = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'];
    return List.generate(5, (index) {
      final fecha = inicio.add(Duration(days: index));
      final clave = _fechaKey(fecha);
      final cantidad = porDia[clave] ?? detectadosPorDia[clave] ?? 0;
      return _DiaPausas(
        nombre: nombres[index],
        corto: const ['Lun', 'Mar', 'Mié', 'Jue', 'Vie'][index],
        fecha: fecha,
        cantidad: cantidad,
      );
    });
  }

  Color _color(int pausas) {
    if (pausas <= 0) return const Color(0xFF94A3B8);
    if (pausas <= _metas.maloHasta) return AppPalette.danger;
    if (pausas < _metas.buenoDesde) return AppPalette.warning;
    if (pausas < _metas.excelenteDesde) return AppPalette.blue;
    return AppPalette.success;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0B1424) : const Color(0xFFEAF3F8);
    final textPrimary = isDark ? Colors.white : brandText;
    final textSecondary = isDark ? const Color(0xFFCBD5E1) : brandMuted;
    final nombre = widget.usuario.nombre.isEmpty
        ? 'Usuario'
        : widget.usuario.nombre;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estadísticas de pausas',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            Text(
              nombre,
              style: TextStyle(
                color: isDark ? const Color(0xFF9FB3C8) : brandMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _cargar,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Configurar metas',
            onPressed: _abrirMetas,
            icon: const Icon(Icons.tune_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: brandBlue))
          : RefreshIndicator(
              onRefresh: _cargar,
              color: brandBlue,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 80),
                children: [
                  _encabezado(nombre, textPrimary, textSecondary),
                  const SizedBox(height: 16),
                  if (_error != null) ...[
                    Text(
                      _error!,
                      style: const TextStyle(color: AppPalette.danger),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _grafica(_construirDias(), textPrimary, textSecondary),
                  const SizedBox(height: 16),
                  _resumen(_construirDias(), textPrimary, textSecondary),
                  const SizedBox(height: 16),
                  _nota(textSecondary),
                ],
              ),
            ),
    );
  }

  Widget _encabezado(String nombre, Color textPrimary, Color textSecondary) {
    final inicio = _construirDias().first.fecha;
    final fin = _construirDias().last.fecha;
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: brandBlue.withValues(alpha: 0.12),
          child: const Icon(Icons.person_rounded, color: brandBlue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nombre,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Semana del ${inicio.day}/${inicio.month} al '
                '${fin.day}/${fin.month} · lunes a viernes',
                style: TextStyle(color: textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _grafica(
    List<_DiaPausas> dias,
    Color textPrimary,
    Color textSecondary,
  ) {
    var mayor = 0;
    for (final dia in dias) {
      if (dia.cantidad > mayor) mayor = dia.cantidad;
    }
    final techo = mayor > _metas.excelenteDesde ? mayor : _metas.excelenteDesde;
    final escala = (techo * 1.15).toDouble();
    const double altoMaximoBarras = 180.0;

    return AppSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Pausas activas por día',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppPalette.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Meta diaria: ${_metas.buenoDesde}',
                  style: const TextStyle(
                    color: AppPalette.blue,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Toca una barra para ver el detalle del día. '
            'La altura es proporcional al número de pausas.',
            style: TextStyle(color: textSecondary, fontSize: 11.5),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 258,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(dias.length, (index) {
                return Expanded(
                  child: _barra(
                    dias[index],
                    index,
                    escala,
                    altoMaximoBarras,
                    textSecondary,
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 14),
          _leyenda(textSecondary),
          const SizedBox(height: 12),
          _detalle(dias[_diaSeleccionado]),
        ],
      ),
    );
  }

  Widget _barra(
    _DiaPausas dia,
    int index,
    double escala,
    double altoMaximo,
    Color textSecondary,
  ) {
    final color = _color(dia.cantidad);
    final double altura = dia.cantidad <= 0
        ? 6.0
        : (dia.cantidad / escala * altoMaximo).clamp(10.0, altoMaximo);
    final seleccionada = _diaSeleccionado == index;

    return Semantics(
      label: '${dia.nombre}: ${dia.cantidad} pausas activas',
      value: _metas.clasificar(dia.cantidad),
      child: InkWell(
        onTap: () => setState(() => _diaSeleccionado = index),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          decoration: seleccionada
              ? BoxDecoration(
                  color: color.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(14),
                )
              : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${dia.cantidad}',
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: altura,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [color.withValues(alpha: 0.62), color],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                    bottom: Radius.circular(6),
                  ),
                  boxShadow: seleccionada
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                dia.corto,
                style: TextStyle(
                  color: seleccionada ? color : textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${dia.fecha.day}/${dia.fecha.month}',
                style: TextStyle(color: textSecondary, fontSize: 9.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _leyenda(Color textSecondary) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        _chip(AppPalette.danger, 'Bajo ≤ ${_metas.maloHasta}'),
        _chip(
          AppPalette.warning,
          'Regular ${_metas.maloHasta + 1}–${_metas.buenoDesde - 1}',
        ),
        _chip(
          AppPalette.blue,
          'Bueno ${_metas.buenoDesde}–${_metas.excelenteDesde - 1}',
        ),
        _chip(AppPalette.success, 'Excelente ≥ ${_metas.excelenteDesde}'),
      ],
    );
  }

  Widget _chip(Color color, String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            texto,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detalle(_DiaPausas dia) {
    final color = _color(dia.cantidad);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Icon(Icons.insights_rounded, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${dia.nombre} ${dia.fecha.day}/${dia.fecha.month}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
                Text(
                  '${dia.cantidad} pausas activas · '
                  '${_metas.clasificar(dia.cantidad)}',
                  style: TextStyle(color: color, fontSize: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _resumen(
    List<_DiaPausas> dias,
    Color textPrimary,
    Color textSecondary,
  ) {
    var total = 0;
    var activos = 0;
    var mejor = dias.first;
    for (final dia in dias) {
      total += dia.cantidad;
      if (dia.cantidad > 0) activos++;
      if (dia.cantidad > mejor.cantidad) mejor = dia;
    }
    final promedio = (total / dias.length).round();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _metrica(
                'Total de pausas',
                '$total',
                Icons.fact_check_rounded,
                brandBlue,
                textPrimary,
                textSecondary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metrica(
                'Promedio diario',
                '$promedio',
                Icons.show_chart_rounded,
                AppPalette.teal,
                textPrimary,
                textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _metrica(
                'Días activos',
                '$activos de 5',
                Icons.calendar_month_rounded,
                AppPalette.warning,
                textPrimary,
                textSecondary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metrica(
                'Mejor día',
                mejor.corto,
                Icons.emoji_events_outlined,
                AppPalette.success,
                textPrimary,
                textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _metrica(
    String titulo,
    String valor,
    IconData icono,
    Color color,
    Color textPrimary,
    Color textSecondary,
  ) {
    return AppSurface(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            valor,
            style: TextStyle(
              color: textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(titulo, style: TextStyle(color: textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _nota(Color textSecondary) {
    return AppSurface(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: brandBlue, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Los rangos se ajustan con el botón de configuración. '
              'Se guardan en este dispositivo del líder SST; para que apliquen '
              'a todos los usuarios en otros dispositivos se necesitaría un '
              'endpoint en el backend.',
              style: TextStyle(color: textSecondary, fontSize: 11.5),
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
      return DateTime(_asInt(value[0]), _asInt(value[1]), _asInt(value[2]));
    }
    final raw = value.toString();
    return DateTime.tryParse(raw) ?? DateTime.tryParse(raw.split('T').first);
  }

  static String? _fechaKey(dynamic value) {
    final parsed = _parseFecha(value);
    if (parsed == null) return null;
    final mes = parsed.month.toString().padLeft(2, '0');
    final dia = parsed.day.toString().padLeft(2, '0');
    return '${parsed.year}-$mes-$dia';
  }
}

class _DiaPausas {
  final String nombre;
  final String corto;
  final DateTime fecha;
  final int cantidad;

  const _DiaPausas({
    required this.nombre,
    required this.corto,
    required this.fecha,
    required this.cantidad,
  });
}
