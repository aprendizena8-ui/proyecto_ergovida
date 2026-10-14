import 'package:flutter/material.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/ejercicio_service.dart';
import 'exercise_camera_page.dart';
import 'exercise_form_page.dart';

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

  // Variable que fuerza recarga del FutureBuilder
  int _refreshKey = 0;

  // Roles con permiso para gestionar ejercicios
  bool get _puedeGestionar {
    final rol = widget.usuario.rol.toUpperCase();
    return rol == 'ADMINISTRADOR' || rol == 'ADMIN' || rol == 'INSTRUCTOR';
  }

  // Función para asignar íconos según el nombre del ejercicio
  IconData _obtenerIcono(String nombre) {
    final n = nombre.toLowerCase();
    if (n.contains("cuello")) return Icons.accessibility_new;
    if (n.contains("hombro")) return Icons.fitness_center;
    if (n.contains("visual") || n.contains("ojo")) return Icons.visibility;
    if (n.contains("muñeca") || n.contains("mano")) return Icons.pan_tool;
    return Icons.fitness_center;
  }

  void _recargar() {
    setState(() => _refreshKey++);
  }

  Future<void> _abrirFormulario({Map<String, dynamic>? ejercicio}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ExerciseFormPage(ejercicio: ejercicio),
      ),
    );
    if (result == true) _recargar();
  }

  Future<void> _confirmarEliminar(int id, String nombre) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar ejercicio'),
        content: Text('¿Estás seguro de eliminar "$nombre"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final ok = await _ejercicioService.eliminarEjercicio(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: ok ? Colors.green : Colors.red,
          content: Text(ok ? 'Ejercicio eliminado' : 'Error al eliminar'),
        ),
      );
      if (ok) _recargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ejercicios"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: _puedeGestionar
          ? FloatingActionButton.extended(
              onPressed: () => _abrirFormulario(),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo ejercicio'),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            )
          : FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.blue,
              content: Text(
                  'Solo administradores pueden crear ejercicios. Contacta a tu SST.'),
            ),
          );
        },
        icon: const Icon(Icons.info_outline),
        label: const Text('Solo lectura'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),

      body: FutureBuilder<List<dynamic>>(
        key: ValueKey(_refreshKey),
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
                    leading: Icon(icono, color: Colors.green, size: 28,),
                    title: Text(
                      nombre,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text("Duración: $duracion"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.play_arrow, color: Colors.green),
                          tooltip: 'Iniciar',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ExerciseCameraPage(
                                  nombre: nombre,
                                  duracion: duracion,
                                  icono: icono,
                                  usuarioId: widget.usuarioId,
                                  ejercicioId: ejercicioId,
                                ),
                              ),
                            );
                          },
                        ),
                        if (_puedeGestionar)
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'editar') {
                                _abrirFormulario(ejercicio: ejercicio);
                              } else if (value == 'eliminar') {
                                _confirmarEliminar(ejercicioId, nombre);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'editar',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 18),
                                    SizedBox(width: 8),
                                    Text('Editar'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'eliminar',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete,
                                        size: 18, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Eliminar',
                                        style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
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