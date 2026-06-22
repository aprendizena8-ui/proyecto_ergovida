import 'package:flutter/material.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Estadísticas")),
      body: const Center(
        child: Text(
          "Estadísticas de pausas activas",
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}

