import 'package:flutter/material.dart';

class RoutinePage extends StatelessWidget {
  const RoutinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rutina")),
      body: const Center(
        child: Text("Rutina en progreso", style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
