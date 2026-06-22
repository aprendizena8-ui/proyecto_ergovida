import 'package:flutter/material.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  Widget card(
      String titulo,
      String valor,
      IconData icono,
      Color color,
      ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
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
            Text(titulo),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Estadísticas"),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(20),
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        children: [
          card(
            "Rutinas",
            "15",
            Icons.repeat,
            Colors.green,
          ),
          card(
            "Ejercicios",
            "42",
            Icons.fitness_center,
            Colors.blue,
          ),
          card(
            "Horas Activas",
            "8h",
            Icons.timer,
            Colors.orange,
          ),
          card(
            "Cumplimiento",
            "85%",
            Icons.star,
            Colors.purple,
          ),
        ],
      ),
    );
  }
}

