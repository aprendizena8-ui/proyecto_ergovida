import 'package:flutter/material.dart';

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
          return Card(
            child: ListTile(
              leading: Icon(
                ejercicios[index]["icono"] as IconData,
                color: Colors.green,
              ),
              title: Text(ejercicios[index]["nombre"] as String),
              subtitle:
                  Text("Duración: ${ejercicios[index]["duracion"]}"),
              trailing: ElevatedButton(
                onPressed: () {},
                child: const Text("Iniciar"),
              ),
            ),
          );
        },
      ),
    );
  }
}
