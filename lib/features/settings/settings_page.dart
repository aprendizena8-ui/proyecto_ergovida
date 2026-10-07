import 'package:flutter/material.dart';
import '../../main.dart';

class SettingsPage extends StatefulWidget {
  final AppThemeController? themeController;

  const SettingsPage({super.key, this.themeController});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notificaciones = true;
  bool recordatorios = true;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.themeController?.isDark ?? Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              title: const Text('Notificaciones'),
              value: notificaciones,
              onChanged: (v) {
                setState(() {
                  notificaciones = v;
                });
              },
            ),
          ),
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              title: const Text('Recordatorios'),
              value: recordatorios,
              onChanged: (v) {
                setState(() {
                  recordatorios = v;
                });
              },
            ),
          ),
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              title: const Text('Tema oscuro'),
              subtitle: const Text('Ajusta la interfaz para mejor visibilidad nocturna'),
              value: isDark,
              onChanged: (v) {
                widget.themeController?.setTheme(v);
                setState(() {});
              },
            ),
          ),
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
