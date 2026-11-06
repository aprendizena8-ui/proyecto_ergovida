import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/user_model.dart';
import '../../data/services/horario_service.dart';
import '../../data/services/profile_preferences.dart';
import '../../data/services/reminder_service.dart';
import '../../data/services/usuario_service.dart';
import '../../main.dart';
import '../../widgets/design_system.dart';
import '../wellness/wellness_page.dart';

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
  bool recordatoriosCorreo = true;

  List<dynamic> _horarios = [];
  bool _cargandoHorarios = true;

  @override
  void initState() {
    super.initState();
    _cargarPreferencias();
    _cargarHorarios();
  }

  Future<void> _cargarPreferencias() async {
    final usuario = widget.usuario;
    if (usuario == null) return;

    final perfil = await ProfilePreferences.load(usuario.id);
    if (!mounted) return;
    setState(() {
      notificaciones = perfil.notificaciones;
      recordatorios = perfil.recordatorios;
      recordatoriosCorreo = perfil.recordatoriosCorreo;
    });
  }

  Future<void> _guardarPreferencias() async {
    final usuario = widget.usuario;
    if (usuario == null) return;

    final perfil = await ProfilePreferences.load(usuario.id);
    await ProfilePreferences.save(
      usuario.id,
      perfil.copyWith(
        notificaciones: notificaciones,
        recordatorios: recordatorios,
        recordatoriosCorreo: recordatoriosCorreo,
      ),
    );
    await ReminderService.instance.refresh();
    await ReminderService.instance.checkNow();
    await UsuarioService().actualizarUsuario(usuario.id, {
      'notificaciones': notificaciones,
      'recordatorios': recordatorios,
      'recordatoriosCorreo': recordatoriosCorreo,
    });
  }

  String _horaAmPm(String hora) {
    final partes = hora.split(':');
    if (partes.isEmpty) return hora;

    final hora24 = int.tryParse(partes[0]);
    final minuto = partes.length > 1 ? int.tryParse(partes[1]) : 0;
    if (hora24 == null || hora24 < 0 || hora24 > 23) return hora;

    final sufijo = hora24 >= 12 ? 'PM' : 'AM';
    final hora12 = hora24 % 12 == 0 ? 12 : hora24 % 12;
    final minutos = (minuto ?? 0).toString().padLeft(2, '0');
    return '$hora12:$minutos $sufijo';
  }

  Future<void> _cargarHorarios() async {
    if (widget.usuario == null) {
      setState(() => _cargandoHorarios = false);
      return;
    }
    setState(() => _cargandoHorarios = true);
    try {
      final data = await _horarioService.obtenerPorUsuario(widget.usuario!.id);
      if (!mounted) return;
      setState(() {
        _horarios = data;
        _cargandoHorarios = false;
      });
    } catch (_) {
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
      helpText: 'Selecciona la hora del recordatorio (AM/PM)',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: child ?? const SizedBox.shrink(),
      ),
    );

    if (horaSeleccionada == null) return;

    final horaStr =
        '${horaSeleccionada.hour.toString().padLeft(2, '0')}:${horaSeleccionada.minute.toString().padLeft(2, '0')}:00';
    final horaAmPm = _horaAmPm(horaStr);

    final creado = await _horarioService.crearHorario(
      usuarioId: widget.usuario!.id,
      hora: horaStr,
    );

    if (!mounted) return;
    if (creado != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppPalette.blue,
          content: Text(
            'Recordatorio diario creado a las $horaAmPm. Te avisaremos en la app y por correo.',
          ),
        ),
      );
      await _cargarHorarios();
      await ReminderService.instance.refresh();
      await ReminderService.instance.checkNow();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppPalette.danger,
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.danger,
            ),
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
          backgroundColor: AppPalette.success,
          content: Text('Recordatorio eliminado'),
        ),
      );
      await _cargarHorarios();
      await ReminderService.instance.refresh();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppPalette.danger,
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
    final bg = isDark ? AppPalette.darkBackground : AppPalette.background;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Configuración'),
      ),
      floatingActionButton: widget.usuario == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _agregarHorario,
              backgroundColor: AppPalette.blue,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_alarm_rounded),
              label: const Text('Recordatorio'),
            ),
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
          children: [
            _seccion('Apariencia'),
            AppSurface(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: SwitchListTile.adaptive(
                secondary: const IconBadge(
                  icon: Icons.dark_mode_rounded,
                  color: AppPalette.blue,
                  size: 42,
                ),
                title: const Text(
                  'Tema oscuro',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'Ajusta la interfaz para mejor visibilidad nocturna',
                ),
                value: isDark,
                onChanged: (v) {
                  (widget.themeController ?? AppThemeController.instance)
                      .setTheme(v);
                },
              ),
            ),
            const SizedBox(height: 20),
            _seccion('Notificaciones'),
            AppSurface(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                children: [
                  _switch(
                    icon: Icons.notifications_active_rounded,
                    color: AppPalette.cyan,
                    title: 'Notificaciones',
                    subtitle: 'Recibir notificaciones en el sistema',
                    value: notificaciones,
                    onChanged: (v) {
                      setState(() => notificaciones = v);
                      _guardarPreferencias();
                    },
                  ),
                  const AppDivider(vertical: 4),
                  _switch(
                    icon: Icons.alarm_on_rounded,
                    color: AppPalette.teal,
                    title: 'Recordatorios activos',
                    subtitle: 'Activa o desactiva tus pausas programadas',
                    value: recordatorios,
                    onChanged: (v) {
                      setState(() => recordatorios = v);
                      _guardarPreferencias();
                    },
                  ),
                  const AppDivider(vertical: 4),
                  _switch(
                    icon: Icons.mark_email_read_rounded,
                    color: AppPalette.blue,
                    title: 'Recordatorios por correo',
                    subtitle: 'Enviar un correo diario a la hora que elijas',
                    value: recordatorios && recordatoriosCorreo,
                    onChanged: recordatorios
                        ? (v) {
                            setState(() => recordatoriosCorreo = v);
                            _guardarPreferencias();
                          }
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _seccion(
              'Recordatorios de pausas',
              trailing: widget.usuario == null
                  ? null
                  : TextButton.icon(
                      onPressed: _agregarHorario,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Agregar'),
                    ),
            ),
            if (widget.usuario == null)
              const AppSurface(
                child: AppEmptyState(
                  icon: Icons.lock_outline_rounded,
                  title: 'Inicia sesión',
                  message:
                      'Inicia sesión para gestionar tus recordatorios diarios.',
                ),
              )
            else if (_cargandoHorarios)
              const AppSurface(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (_horarios.isEmpty)
              const AppSurface(
                child: AppEmptyState(
                  icon: Icons.alarm_off_rounded,
                  title: 'Sin recordatorios',
                  message:
                      'Presiona el botón + para programar tu primera pausa activa.',
                ),
              )
            else
              AppSurface(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < _horarios.length; i++) ...[
                      _horarioTile(_horarios[i]),
                      if (i != _horarios.length - 1)
                        const AppDivider(vertical: 6),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 20),
            _seccion('Bienestar'),
            AppSurface(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: const IconBadge(
                  icon: Icons.spa_rounded,
                  color: AppPalette.teal,
                  size: 42,
                ),
                title: const Text(
                  'Mi bienestar',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'Meta diaria, check-in de ánimo y logros',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onTap: widget.usuario == null
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WellnessPage(
                            usuarioId: widget.usuario!.id,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            _seccion('Acerca de'),
            AppSurface(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                children: [
                  ListTile(
                    leading: const IconBadge(
                      icon: Icons.info_outline_rounded,
                      color: AppPalette.muted,
                      size: 42,
                    ),
                    title: const Text(
                      'Versión',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text('ErgoVida 1.0'),
                  ),
                  const AppDivider(vertical: 4),
                  ListTile(
                    leading: const IconBadge(
                      icon: Icons.groups_rounded,
                      color: AppPalette.blue,
                      size: 42,
                    ),
                    title: const Text(
                      'Desarrollado por',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text('Equipo ErgoVida'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _seccion(String titulo, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Row(
        children: [
          Text(
            titulo.toUpperCase(),
            style: const TextStyle(
              color: AppPalette.muted,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }

  Widget _switch({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return SwitchListTile.adaptive(
      secondary: IconBadge(icon: icon, color: color, size: 42),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _horarioTile(dynamic h) {
    final hora = h['hora']?.toString() ?? '';
    final horaCorta = hora.length >= 5 ? hora.substring(0, 5) : hora;
    final horaAmPm = _horaAmPm(horaCorta);

    return ListTile(
      leading: const IconBadge(
        icon: Icons.alarm_on_rounded,
        color: AppPalette.teal,
        size: 42,
      ),
      title: Text(
        'Recordatorio a las $horaAmPm',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        recordatoriosCorreo
            ? 'Aviso en la app y correo electrónico'
            : 'Solo aviso dentro de la app',
      ),
      trailing: IconButton(
        tooltip: 'Eliminar recordatorio',
        icon: const Icon(
          Icons.delete_outline_rounded,
          color: AppPalette.danger,
        ),
        onPressed: () => _eliminarHorario(h['id'], horaAmPm),
      ),
    );
  }
}
