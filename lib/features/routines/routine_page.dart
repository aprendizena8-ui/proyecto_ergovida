import 'package:flutter/material.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/rutina_service.dart';
import '../../data/services/ejercicio_service.dart';

class RoutinePage extends StatefulWidget {
  final LoginUser? usuario;

  const RoutinePage({super.key, this.usuario});

  @override
  State<RoutinePage> createState() => _RoutinePageState();
}

class _RoutinePageState extends State<RoutinePage> {
  final RutinaService _rutinaService = RutinaService();
  final EjercicioService _ejercicioService = EjercicioService();

  List<dynamic> _rutinas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarRutinas();
  }

  Future<void> _cargarRutinas() async {
    setState(() => _cargando = true);
    final data = await _rutinaService.obtenerRutinas();
    if (!mounted) return;
    setState(() {
      _rutinas = data;
      _cargando = false;
    });
  }

  Future<void> _mostrarDialogoCrear() async {
    final nombreController = TextEditingController();
    final descripcionController = TextEditingController();

    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva rutina'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descripcionController,
              decoration: const InputDecoration(labelText: 'Descripción'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nombreController.text.trim().isEmpty) return;
              await _rutinaService.crearRutina(
                nombre: nombreController.text.trim(),
                descripcion: descripcionController.text.trim(),
              );
              if (!context.mounted) return;
              Navigator.pop(context, true);
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (resultado == true) {
      _cargarRutinas();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Rutina creada correctamente'),
        ),
      );
    }
  }

  Future<void> _mostrarDialogoEditar(Map<String, dynamic> rutina) async {
    final nombreController = TextEditingController(text: rutina['nombre'] ?? '');
    final descripcionController =
        TextEditingController(text: rutina['descripcion'] ?? '');

    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar rutina'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descripcionController,
              decoration: const InputDecoration(labelText: 'Descripción'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nombreController.text.trim().isEmpty) return;
              await _rutinaService.actualizarRutina(
                rutina['id'],
                nombre: nombreController.text.trim(),
                descripcion: descripcionController.text.trim(),
              );
              if (!context.mounted) return;
              Navigator.pop(context, true);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (resultado == true) {
      _cargarRutinas();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.blue,
          content: Text('Rutina actualizada'),
        ),
      );
    }
  }

  Future<void> _confirmarEliminar(Map<String, dynamic> rutina) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar rutina'),
        content: Text(
            '¿Estás seguro de eliminar "${rutina['nombre']}"? Esta acción no se puede deshacer.'),
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
      await _rutinaService.eliminarRutina(rutina['id']);
      _cargarRutinas();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Rutina eliminada'),
        ),
      );
    }
  }

  Future<void> _abrirDialogoAsignar(Map<String, dynamic> rutina) async {
    // 1. Cargar todos los ejercicios
    final ejercicios = await _ejercicioService.obtenerEjercicios();
    if (ejercicios.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Text('No hay ejercicios disponibles para asignar'),
        ),
      );
      return;
    }
    // 2. Obtener los IDs de ejercicios ya asignados a esta rutina
    final ejerciciosAsignados =
        (rutina['ejercicios'] as List<dynamic>? ?? [])
            .map((e) => e['id'])
            .toSet();

    if (!mounted) return;

    // 3. Mostrar diálogo con la lista de ejercicios
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Asignar a "${rutina['nombre']}"'),
          content: SizedBox(
            width: 400,
            height: 400,
            child: ListView.builder(
              itemCount: ejercicios.length,
              itemBuilder: (context, index) {
                final ej = ejercicios[index];
                final id = ej['id'];
                final nombre = ej['nombre'] ?? 'Ejercicio';
                final yaAsignado = ejerciciosAsignados.contains(id);

                return CheckboxListTile(
                  title: Text(nombre),
                  subtitle: Text(ej['categoria'] ?? ''),
                  value: yaAsignado,
                  onChanged: yaAsignado
                      ? null
                      : (v) async {
                          if (v == true) {
                            final ok = await _rutinaService.asignarEjercicio(
                              rutina['id'],
                              id,
                            );
                            if (!context.mounted) return;
                            if (ok != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.green,
                                  content: Text('"$nombre" asignado'),
                                ),
                              );
                              Navigator.pop(context);
                              _cargarRutinas();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: Colors.red,
                                  content: Text('Error al asignar'),
                                ),
                              );
                            }
                          }
                        },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rutinas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarRutinas,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoCrear,
        icon: const Icon(Icons.add),
        label: const Text('Nueva rutina'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarRutinas,
              child: _rutinas.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        Center(
                          child: Text(
                            'No hay rutinas registradas.\n¡Crea la primera!',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _rutinas.length,
                      itemBuilder: (context, index) {
                        final rutina = _rutinas[index];
                        final ejercicios = rutina['ejercicios'] as List<dynamic>? ?? [];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.repeat, color: Colors.green, size: 28),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        rutina['nombre'] ?? 'Sin nombre',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  rutina['descripcion'] ?? 'Sin descripción',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Chip(
                                      avatar: const Icon(Icons.fitness_center, size: 16),
                                      label: Text('${ejercicios.length} ejercicios'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () =>
                                           _abrirDialogoAsignar(rutina),
                                      icon: const Icon(Icons.playlist_add,
                                          size: 18),
                                      label: const Text('Asignar'),
                                    ),
                                    TextButton.icon(
                                      onPressed: () =>
                                          _mostrarDialogoEditar(rutina),
                                      icon: const Icon(Icons.edit, size: 18),
                                      label: const Text('Editar'),
                                    ),
                                    TextButton.icon(
                                      onPressed: () => _confirmarEliminar(rutina),
                                      icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                      label: const Text(
                                        'Eliminar',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}