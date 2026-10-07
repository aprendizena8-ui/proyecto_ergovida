import 'package:flutter/material.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/ejercicio_service.dart';
import 'exercise_camera_page.dart';

class ExercisesPage extends StatefulWidget {
  final LoginUser usuario;
  final int usuarioId;

  const ExercisesPage({
    super.key,
    required this.usuario,
    required this.usuarioId,
  });

  @override
  State<ExercisesPage> createState() => _ExercisesPageState();
}

class _ExercisesPageState extends State<ExercisesPage> {
  final EjercicioService _ejercicioService = EjercicioService();

  // Función para asignar íconos según el nombre del ejercicio
  IconData _obtenerIcono(String nombre) {
    final n = nombre.toLowerCase();
    if (n.contains("cuello")) return Icons.accessibility_new;
    if (n.contains("hombro")) return Icons.fitness_center;
    if (n.contains("visual") || n.contains("ojo")) return Icons.visibility;
    if (n.contains("muñeca") || n.contains("mano")) return Icons.pan_tool;
    return Icons.fitness_center;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ejercicios"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _ejercicioService.obtenerEjercicios(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text("Error al conectar con la BD: ${snapshot.error}"),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("No hay ejercicios registrados en la Base de Datos."),
            );
          }

          final ejercicios = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: ejercicios.length,
            itemBuilder: (context, index) {
              final ejercicio = ejercicios[index];
              
              final int ejercicioId = ejercicio["id"] ?? 0;
              final String nombre = ejercicio["nombre"]?.toString() ?? "Ejercicio";
              final String duracion = ejercicio["duracion"] != null
                  ? "${ejercicio["duracion"]} min" 
                  : "2 min";
              final IconData icono = _obtenerIcono(nombre);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                clipBehavior: Clip.antiAlias,
                child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                    leading: Icon(
                      icono,
                      color: Colors.green,
                      size: 28,
                    ),
                    title: Text(
                      nombre,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text("Duración: $duracion"),
                    trailing: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ExerciseCameraPage(
                              nombre: nombre,
                              duracion: duracion,
                              icono: icono,
                              usuarioId: widget.usuarioId,
                              ejercicioId: ejercicioId, // <-- PASAR ID DEL EJERCICIO
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
                ),
              );
            },
          );
        },
      ),
    );
  }
}