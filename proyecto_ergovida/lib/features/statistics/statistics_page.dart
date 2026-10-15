import 'package:flutter/material.dart';
import '../../data/services/estadisticas_service.dart';
import '../../data/services/pausa_service.dart';

class StatisticsPage extends StatefulWidget {
  final int? usuarioId;

  const StatisticsPage({super.key, this.usuarioId});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final EstadisticasService _estadisticasService = EstadisticasService();
  final PausaService _pausaService = PausaService();

  int _totalPausas = 0;
  int _totalMinutos = 0;
  int _totalRegistros = 0;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarEstadisticas();
  }

  Future<void> _cargarEstadisticas() async {
    setState(() => _cargando = true);

    if (widget.usuarioId == null) {
      setState(() => _cargando = false);
      return;
    }

    final estadisticas =
        await _estadisticasService.obtenerPorUsuario(widget.usuarioId!);
    final pausas = await _pausaService.obtenerPorUsuario(widget.usuarioId!);

    int pausasTotales = 0;
    int minutosTotales = 0;
    int registros = estadisticas.length;

    for (final e in estadisticas) {
      pausasTotales += (e['pausasRealizadas'] ?? 0) as int;
      minutosTotales += (e['minutosActivos'] ?? 0) as int;
    }

    // Si no hay estadísticas registradas, cuenta las pausas realizadas
    if (registros == 0 && pausas.isNotEmpty) {
      pausasTotales = pausas.length;
      minutosTotales = pausas.length * 2; // 2 min por pausa aprox.
      registros = pausas.length;
    }

    if (!mounted) return;
    setState(() {
      _totalPausas = pausasTotales;
      _totalMinutos = minutosTotales;
      _totalRegistros = registros;
      _cargando = false;
    });
  }

  Widget _card(
    String titulo,
    String valor,
    IconData icono,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 40, color: color),
            const SizedBox(height: 10),
            Text(
              valor,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              titulo,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarEstadisticas,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarEstadisticas,
              child: widget.usuarioId == null
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Inicia sesión para ver tus estadísticas.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    )
                  : GridView.count(
                      crossAxisCount: 2,
                      padding: const EdgeInsets.all(20),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _card(
                          'Pausas realizadas',
                          '$_totalPausas',
                          Icons.timer,
                          Colors.green,
                        ),
                        _card(
                          'Minutos activos',
                          '$_totalMinutos',
                          Icons.fitness_center,
                          Colors.blue,
                        ),
                        _card(
                          'Registros diarios',
                          '$_totalRegistros',
                          Icons.calendar_today,
                          Colors.orange,
                        ),
                        _card(
                          'Cumplimiento',
                          _totalPausas == 0
                              ? '0%'
                              : '${(_totalPausas / 24 * 100).toStringAsFixed(0)}%',
                          Icons.star,
                          Colors.purple,
                        ),
                      ],
                    ),
            ),
    );
  }
}