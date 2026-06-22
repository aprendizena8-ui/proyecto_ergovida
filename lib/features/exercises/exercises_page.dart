import 'package:flutter/material.dart';

class ExercisesPage extends StatelessWidget {
  const ExercisesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ejercicios")),
      body: ListView(
        children: const [
          ListTile(title: Text("Cuello"), subtitle: Text("2 minutos")),
          ListTile(title: Text("Espalda"), subtitle: Text("3 minutos")),
        ],
      ),
    );
  }
}
