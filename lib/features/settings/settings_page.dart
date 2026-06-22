import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Configuración")),
      body: const Center(
        child: Text(
          "Configuraciones de la aplicación",
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}
