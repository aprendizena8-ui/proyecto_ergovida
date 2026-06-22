import 'package:flutter/material.dart';

class RoutinePage extends StatelessWidget {
  const RoutinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rutinas")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            _routineCard(
              "Rutina Oficina",
              "5 ejercicios",
              "10 minutos",
            ),

            const SizedBox(height: 20),

            _routineCard(
              "Rutina Casa",
              "4 ejercicios",
              "8 minutos",
            ),
          ],
        ),
      ),
    );
  }

  Widget _routineCard(
    String nombre,
    String ejercicios,
    String tiempo,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              nombre,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(ejercicios),
            Text(tiempo),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () {},
              child: const Text("Iniciar Rutina"),
            )
          ],
        ),
      ),
    );
  }
}
