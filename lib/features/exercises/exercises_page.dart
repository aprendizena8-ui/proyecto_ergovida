import 'package:flutter/material.dart';

import 'exercise_camera_page.dart';

class ExercisesPage extends StatelessWidget {
  const ExercisesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ejercicios = [
      {
        "nombre": "Estiramiento de Cuello",
        "duracion": "2 min",
        "icono": Icons.accessibility_new,
        "instrucciones": "Pon la cabeza recta, mira al frente y realiza pequeños movimientos lentos."
      },
      {
        "nombre": "Movilidad de Hombros",
        "duracion": "3 min",
        "icono": Icons.fitness_center,
        "instrucciones": "Eleva y baja los hombros con control, manteniendo la espalda recta."
      },
      {
        "nombre": "Descanso Visual",
        "duracion": "1 min",
        "icono": Icons.visibility,
        "instrucciones": "Mira a lo lejos y alterna la mirada para aliviar la fatiga visual."
      },
      {
        "nombre": "Movilidad de Muñecas",
        "duracion": "2 min",
        "icono": Icons.pan_tool,
        "instrucciones": "Gira las muñecas con suavidad y mantén codos flexionados."
      }
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Ejercicios")),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: ejercicios.length,
        itemBuilder: (context, index) {
          final ejercicio = ejercicios[index];
          final nombre = ejercicio['nombre'] as String;
          final duracion = ejercicio['duracion'] as String;
          final icono = ejercicio['icono'] as IconData;
          final instrucciones = ejercicio['instrucciones'] as String;

          return Card(
            child: ListTile(
              leading: Icon(
                icono,
                color: Colors.green,
              ),
              title: Text(nombre),
              subtitle: Text("Duración: $duracion"),
              trailing: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExerciseCameraPage(
                        exerciseName: nombre,
                        instructions: instrucciones,
                      ),
                    ),
                  );
                },
                child: const Text("Iniciar"),
              ),
            ),
          );
        },
      ),
    );
  }
}
