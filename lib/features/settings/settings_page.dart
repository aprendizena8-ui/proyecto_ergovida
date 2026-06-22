import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() =>
      _SettingsPageState();
}

class _SettingsPageState
    extends State<SettingsPage> {

  bool notificaciones = true;
  bool recordatorios = true;
  bool temaOscuro = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Configuración"),
      ),

      body: ListView(
        children: [

          SwitchListTile(
            title: const Text(
              "Notificaciones",
            ),
            value: notificaciones,
            onChanged: (v) {
              setState(() {
                notificaciones = v;
              });
            },
          ),

          SwitchListTile(
            title: const Text(
              "Recordatorios",
            ),
            value: recordatorios,
            onChanged: (v) {
              setState(() {
                recordatorios = v;
              });
            },
          ),

          SwitchListTile(
            title: const Text(
              "Tema Oscuro",
            ),
            value: temaOscuro,
            onChanged: (v) {
              setState(() {
                temaOscuro = v;
              });
            },
          ),

          const Divider(),

          const ListTile(
            leading: Icon(Icons.info),
            title: Text("Versión"),
            subtitle: Text("ErgoVida 1.0"),
          ),

          const ListTile(
            leading: Icon(Icons.person),
            title: Text("Desarrollado por"),
            subtitle: Text("Equipo ErgoVida"),
          ),
        ],
      ),
    );
  }
}
