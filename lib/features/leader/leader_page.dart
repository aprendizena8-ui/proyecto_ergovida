import 'package:flutter/material.dart';

import '../../data/models/recordatorio_global_model.dart';
import '../../data/models/usuario_estadistica_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/leader_service.dart';
import '../../data/services/recordatorio_global_service.dart';
import '../../main.dart';
import '../../widgets/design_system.dart';
import '../support/support_page.dart';

class LeaderPage extends StatefulWidget {
  const LeaderPage({super.key});

  @override
  State<LeaderPage> createState() => _LeaderPageState();
}

class _LeaderPageState extends State<LeaderPage>
    with SingleTickerProviderStateMixin {
  final LeaderService _leaderService = LeaderService();
  final RecordatorioGlobalService _recordatorioService =
      RecordatorioGlobalService();

  late final TabController _tabController;
  List<UsuarioEstadistica> _usuarios = const [];
  List<RecordatorioGlobal> _recordatorios = const [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _cargar();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        _leaderService.obtenerEstadisticasUsuarios(),
        _recordatorioService.obtenerTodos(),
      ]);
      if (!mounted) return;
      setState(() {
        _usuarios = resultados[0] as List<UsuarioEstadistica>;
        _recordatorios = resultados[1] as List<RecordatorioGlobal>;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'No se pudo cargar la información del líder SST.';
      });
    }
  }

  Future<void> _abrirEditor([RecordatorioGlobal? recordatorio]) async {
    final resultado = await showDialog<RecordatorioGlobal>(
      context: context,
      builder: (_) => _RecordatorioDialog(recordatorio: recordatorio),
    );
    if (resultado == null) return;

    try {
      if (recordatorio == null) {
        await _recordatorioService.crear(
          hora: resultado.hora,
          diasSemana: resultado.diasSemana,
          mensaje: resultado.mensaje,
          activo: resultado.activo,
        );
      } else {
        await _recordatorioService.actualizar(
          resultado.copyWith(id: recordatorio.id),
        );
      }
      if (!mounted) return;
      _mensaje('Recordatorio guardado');
      _cargar();
    } catch (_) {
      if (!mounted) return;
      _mensaje('No se pudo guardar el recordatorio', ok: false);
    }
  }

  Future<void> _alternarRecordatorio(RecordatorioGlobal recordatorio) async {
    try {
      await _recordatorioService.actualizar(
        recordatorio.copyWith(activo: !recordatorio.activo),
      );
      if (!mounted) return;
      _cargar();
    } catch (_) {
      if (!mounted) return;
      _mensaje('No se pudo actualizar el recordatorio', ok: false);
    }
  }

  Future<void> _eliminarRecordatorio(RecordatorioGlobal recordatorio) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar recordatorio'),
        content: Text('¿Eliminar "${recordatorio.mensaje}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      await _recordatorioService.eliminar(recordatorio.id);
      if (!mounted) return;
      _mensaje('Recordatorio eliminado');
      _cargar();
    } catch (_) {
      if (!mounted) return;
      _mensaje('No se pudo eliminar el recordatorio', ok: false);
    }
  }

  void _mensaje(String texto, {bool ok = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ok ? const Color(0xFF15803D) : const Color(0xFFCF3A3A),
        behavior: SnackBarBehavior.floating,
        content: Text(texto),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthService.isLiderSst) {
      return Scaffold(
        appBar: AppBar(title: const Text('Panel líder SST')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Esta sección está disponible únicamente para el rol Líder SST.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0B1424) : const Color(0xFFEAF3F8);
    final textPrimary = isDark ? Colors.white : brandText;
    final textSecondary = isDark ? const Color(0xFFCBD5E1) : brandMuted;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text(
          'Panel líder SST',
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
          IconButton(
            tooltip: 'Ayuda y soporte',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SupportPage()),
            ),
            icon: const Icon(Icons.help_outline_rounded),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: brandBlue,
          unselectedLabelColor: textSecondary,
          indicatorColor: brandBlue,
          tabs: const [
            Tab(text: 'Usuarios', icon: Icon(Icons.groups_rounded)),
            Tab(text: 'Recordatorios', icon: Icon(Icons.notifications_rounded)),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(
              onPressed: () => _abrirEditor(),
              backgroundColor: brandBlue,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_alarm_rounded),
              label: const Text('Nuevo recordatorio'),
            )
          : null,
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: brandBlue))
          : TabBarView(
              controller: _tabController,
              children: [
                _vistaUsuarios(isDark, textPrimary, textSecondary),
                _vistaRecordatorios(isDark, textPrimary, textSecondary),
              ],
            ),
    );
  }

  Widget _vistaUsuarios(bool isDark, Color textPrimary, Color textSecondary) {
    final completos = _usuarios.where((u) => u.completo).length;
    final pendientes = _usuarios.length - completos;

    return RefreshIndicator(
      onRefresh: _cargar,
      color: brandBlue,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 90),
        children: [
          Text(
            'Estadísticas de usuarios',
            style: TextStyle(
              color: textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Consulta quiénes han realizado ejercicios y su estado actual.',
            style: TextStyle(color: textSecondary),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(_error!, style: const TextStyle(color: Color(0xFFB42323))),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _resumen(
                  'Usuarios',
                  '${_usuarios.length}',
                  Icons.groups_rounded,
                  brandBlue,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _resumen(
                  'Completo',
                  '$completos',
                  Icons.check_circle_rounded,
                  const Color(0xFF15803D),
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _resumen(
                  'No completo',
                  '$pendientes',
                  Icons.error_outline_rounded,
                  const Color(0xFFCF3A3A),
                  isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_usuarios.isEmpty)
            _vacio('No hay usuarios registrados todavía.')
          else
            ..._usuarios.map((u) => _usuarioTile(u, isDark)),
        ],
      ),
    );
  }

  Widget _vistaRecordatorios(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    return RefreshIndicator(
      onRefresh: _cargar,
      color: brandBlue,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 100),
        children: [
          Text(
            'Recordatorios globales',
            style: TextStyle(
              color: textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Estos recordatorios se muestran a todos los usuarios de ErgoVida.',
            style: TextStyle(color: textSecondary),
          ),
          const SizedBox(height: 14),
          AppSurface(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.mark_email_read_rounded, color: brandBlue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Los correos se envían automáticamente desde el servidor '
                    'a la hora programada, sin necesidad de abrir la app.',
                    style: TextStyle(color: textSecondary, fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SupportPage()),
                  ),
                  child: const Text('Ayuda'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (_recordatorios.isEmpty)
            _vacio('Aún no hay recordatorios globales.')
          else
            ..._recordatorios.map((r) => _recordatorioTile(r, isDark)),
        ],
      ),
    );
  }

  Widget _resumen(
    String titulo,
    String valor,
    IconData icono,
    Color color,
    bool isDark,
  ) {
    return AppSurface(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            valor,
            style: TextStyle(
              color: isDark ? Colors.white : brandNavy,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            titulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? const Color(0xFFCBD5E1) : brandMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _usuarioTile(UsuarioEstadistica usuario, bool isDark) {
    final color = usuario.completo
        ? const Color(0xFF15803D)
        : const Color(0xFFCF3A3A);
    final nombre = usuario.nombre.isEmpty ? 'Usuario' : usuario.nombre;

    return AppSurface(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(
              usuario.completo
                  ? Icons.check_rounded
                  : Icons.priority_high_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white : brandText,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  usuario.correo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF9FB3C8) : brandMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${usuario.ejerciciosRealizados} ejercicios con detección',
                  style: TextStyle(
                    color: isDark ? const Color(0xFFCBD5E1) : brandMuted,
                    fontSize: 11,
                  ),
                ),
                if (usuario.rutinasAdicionales > 0)
                  Text(
                    '${usuario.rutinasAdicionales} rutinas adicionales (no suman a SST)',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF9FB3C8) : brandMuted,
                      fontSize: 10.5,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              usuario.completo ? 'Completo' : 'No completo',
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

  Widget _recordatorioTile(RecordatorioGlobal recordatorio, bool isDark) {
    return AppSurface(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: brandBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.alarm_rounded, color: brandBlue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recordatorio.mensaje,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white : brandText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${recordatorio.horaEtiqueta} · ${recordatorio.diasEtiqueta}',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF9FB3C8) : brandMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: recordatorio.activo,
            activeThumbColor: brandBlue,
            onChanged: (_) => _alternarRecordatorio(recordatorio),
          ),
          PopupMenuButton<String>(
            tooltip: 'Acciones',
            onSelected: (value) {
              if (value == 'editar') _abrirEditor(recordatorio);
              if (value == 'eliminar') _eliminarRecordatorio(recordatorio);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'editar', child: Text('Editar')),
              PopupMenuItem(
                value: 'eliminar',
                child: Text('Eliminar', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _vacio(String texto) {
    return AppSurface(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const Icon(Icons.inbox_rounded, size: 42, color: brandMuted),
          const SizedBox(height: 10),
          Text(texto, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _RecordatorioDialog extends StatefulWidget {
  final RecordatorioGlobal? recordatorio;

  const _RecordatorioDialog({this.recordatorio});

  @override
  State<_RecordatorioDialog> createState() => _RecordatorioDialogState();
}

class _RecordatorioDialogState extends State<_RecordatorioDialog> {
  late final TextEditingController _mensajeController;
  late TimeOfDay _hora;
  late Set<String> _dias;
  late bool _activo;

  @override
  void initState() {
    super.initState();
    final recordatorio = widget.recordatorio;
    _mensajeController = TextEditingController(
      text: recordatorio?.mensaje ?? '',
    );
    _hora = _parseHora(recordatorio?.hora ?? '10:00');
    _dias = (recordatorio?.diasSemana ?? '1,2,3,4,5,6,7')
        .split(',')
        .map((dia) => dia.trim())
        .where((dia) => dia.isNotEmpty)
        .toSet();
    _activo = recordatorio?.activo ?? true;
  }

  @override
  void dispose() {
    _mensajeController.dispose();
    super.dispose();
  }

  TimeOfDay _parseHora(String hora) {
    final partes = hora.split(':');
    if (partes.length < 2) return const TimeOfDay(hour: 10, minute: 0);
    return TimeOfDay(
      hour: int.tryParse(partes[0]) ?? 10,
      minute: int.tryParse(partes[1]) ?? 0,
    );
  }

  String get _horaTexto =>
      '${_hora.hour.toString().padLeft(2, '0')}:${_hora.minute.toString().padLeft(2, '0')}';

  String get _horaEtiqueta {
    final sufijo = _hora.hour >= 12 ? 'PM' : 'AM';
    final hora12 = _hora.hour % 12 == 0 ? 12 : _hora.hour % 12;
    return '$hora12:${_hora.minute.toString().padLeft(2, '0')} $sufijo';
  }

  @override
  Widget build(BuildContext context) {
    const dias = {
      '1': 'Lun',
      '2': 'Mar',
      '3': 'Mié',
      '4': 'Jue',
      '5': 'Vie',
      '6': 'Sáb',
      '7': 'Dom',
    };

    return AlertDialog(
      title: Text(
        widget.recordatorio == null
            ? 'Nuevo recordatorio'
            : 'Editar recordatorio',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _mensajeController,
              maxLength: 255,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Mensaje',
                hintText: 'Hora de estirar y descansar',
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final seleccion = await showTimePicker(
                  context: context,
                  initialTime: _hora,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(alwaysUse24HourFormat: false),
                    child: child!,
                  ),
                );
                if (seleccion != null) setState(() => _hora = seleccion);
              },
              icon: const Icon(Icons.schedule_rounded),
              label: Text('Hora: $_horaEtiqueta'),
            ),
            const SizedBox(height: 14),
            const Text(
              'Días de la semana',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: dias.entries.map((entry) {
                final seleccionado = _dias.contains(entry.key);
                return FilterChip(
                  label: Text(entry.value),
                  selected: seleccionado,
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        _dias.add(entry.key);
                      } else {
                        _dias.remove(entry.key);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Activo'),
              value: _activo,
              onChanged: (value) => setState(() => _activo = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final mensaje = _mensajeController.text.trim();
            if (mensaje.isEmpty || _dias.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Escribe un mensaje y selecciona al menos un día.',
                  ),
                ),
              );
              return;
            }
            Navigator.pop(
              context,
              RecordatorioGlobal(
                id: widget.recordatorio?.id ?? 0,
                hora: _horaTexto,
                diasSemana: (_dias.toList()..sort()).join(','),
                mensaje: mensaje,
                activo: _activo,
              ),
            );
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
