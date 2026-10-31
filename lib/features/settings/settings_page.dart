import 'package:flutter/material.dart';
import '../../main.dart';
import '../../data/models/user_model.dart';
import '../../data/services/horario_service.dart';

class SettingsPage extends StatefulWidget {
  final AppThemeController? themeController;
  final UserModel? usuario;

  const SettingsPage({super.key, this.themeController, this.usuario});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final HorarioService _horarioService = HorarioService();

  bool notificaciones = true;
  bool recordatorios = true;

  List<dynamic> _horarios = [];
  bool _cargandoHorarios = true;

  @override
  void initState() {
    super.initState();
    _cargarHorarios();
  }

  Future<void> _cargarHorarios() async {
    if (widget.usuario == null) {
      setState(() => _cargandoHorarios = false);
      return;
    }
    setState(() => _cargandoHorarios = true);
    try {
      final data = await _horarioService.obtenerPorUsuario(widget.usuario!.id);
      print("Recordatorios obtenidos: $data");
      if (!mounted) return;
      setState(() {
        _horarios = data;
        _cargandoHorarios = false;
      });
    } catch (e) {
      print("Error al cargar recordatorios: $e");
      if (!mounted) return;
      setState(() {
        _horarios = [];
        _cargandoHorarios = false;
      });
    }
  }

  Future<void> _agregarHorario() async {
    final horaSeleccionada = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'Selecciona la hora del recordatorio',
    );

    if (horaSeleccionada == null) return;

    final horaStr =
        '${horaSeleccionada.hour.toString().padLeft(2, '0')}:${horaSeleccionada.minute.toString().padLeft(2, '0')}:00';

    final creado = await _horarioService.crearHorario(
      usuarioId: widget.usuario!.id,
      hora: horaStr,
    );

    if (!mounted) return;
    if (creado != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: brandBlue,
          content: Text('Recordatorio creado a las $horaStr'),
        ),
      );
      await _cargarHorarios();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Error al crear el recordatorio'),
        ),
      );
    }
  }

  Future<void> _eliminarHorario(int id, String hora) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar recordatorio'),
        content: Text('¿Eliminar el recordatorio de las $hora?'),
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
    final ok = await _horarioService.eliminarHorario(id);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Recordatorio eliminado'),
        ),
      );
      _cargarHorarios();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Error al eliminar'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        widget.themeController?.isDark ??
        Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // ----- Notificaciones -----
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              title: const Text('Notificaciones'),
              subtitle: const Text('Recibir notificaciones en el sistema'),
              value: notificaciones,
              onChanged: (v) => setState(() => notificaciones = v),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              title: const Text('Recordatorios activos'),
              subtitle: const Text(
                'Activar o desactivar todos los recordatorios',
              ),
              value: recordatorios,
              onChanged: (v) => setState(() => recordatorios = v),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              title: const Text('Tema oscuro'),
              subtitle: const Text(
                'Ajusta la interfaz para mejor visibilidad nocturna',
              ),
              value: isDark,
              onChanged: (v) {

                AppThemeController.instance.setTheme(v);
              },
            ),
          ),
          const Divider(),

          // ----- Recordatorios (horarios) -----
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.alarm, color: brandBlue),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Recordatorios de pausas activas',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                if (widget.usuario != null)
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: brandBlue),
                    tooltip: 'Agregar recordatorio',
                    onPressed: _agregarHorario,
                  ),
              ],
            ),
          ),
          if (widget.usuario == null)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Inicia sesión para gestionar tus recordatorios.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else if (_cargandoHorarios)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_horarios.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No tienes recordatorios configurados.\nPresiona + para agregar uno.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ..._horarios.map((h) {
              final hora = h['hora']?.toString() ?? '';
              final horaCorta = hora.length >= 5 ? hora.substring(0, 5) : hora;
              return Material(
                color: Colors.transparent,
                child: ListTile(
                  leading: const Icon(Icons.alarm_on, color: brandBlue),
                  title: Text('Recordatorio a las $horaCorta'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _eliminarHorario(h['id'], horaCorta),
                  ),
                ),
              );
            }),

          const Divider(),
          const Material(
            color: Colors.transparent,
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Versión'),
              subtitle: Text('ErgoVida 1.0'),
            ),
          ),
          const Material(
            color: Colors.transparent,
            child: ListTile(
              leading: Icon(Icons.person_outline),
              title: Text('Desarrollado por'),
              subtitle: Text('Equipo ErgoVida'),
            ),
          ),
        ],
      ),
    );
  }
}
