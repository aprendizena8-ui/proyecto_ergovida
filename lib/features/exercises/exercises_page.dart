import 'package:flutter/material.dart';
import 'exercise_camera_page.dart'; // ← Cambiado a la pantalla de cámara

class ExercisesPage extends StatelessWidget {
  const ExercisesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ejercicios = [
      {
        "nombre": "Estiramiento de Cuello",
        "duracion": "2 min",
        "icono": Icons.accessibility_new
      },
      {
        "nombre": "Movilidad de Hombros",
        "duracion": "3 min",
        "icono": Icons.fitness_center
      },
      {
        "nombre": "Descanso Visual",
        "duracion": "1 min",
        "icono": Icons.visibility
      },
      {
        "nombre": "Movilidad de Muñecas",
        "duracion": "2 min",
        "icono": Icons.pan_tool
      }
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Ejercicios")),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: ejercicios.length,
        itemBuilder: (context, index) {
          final ejercicio = ejercicios[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(
                ejercicio["icono"] as IconData,
                color: Colors.green,
                size: 28,
              ),
              title: Text(
                ejercicio["nombre"] as String,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text("Duración: ${ejercicio["duracion"]}"),
              trailing: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExerciseCameraPage(
                        nombre: ejercicio["nombre"] as String,
                        duracion: ejercicio["duracion"] as String,
                        icono: ejercicio["icono"] as IconData,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Iniciar"),
              ),
            ),
          );
        },
      ),
    );
  }
}
