import 'package:flutter/material.dart';
import '../../data/services/ejercicio_service.dart';

class ExerciseFormPage extends StatefulWidget {
  final Map<String, dynamic>? ejercicio; // null = crear, no-null = editar
  final VoidCallback? onSaved;

  const ExerciseFormPage({
    super.key,
    this.ejercicio,
    this.onSaved,
  });

  @override
  State<ExerciseFormPage> createState() => _ExerciseFormPageState();
}

class _ExerciseFormPageState extends State<ExerciseFormPage> {
  final _formKey = GlobalKey<FormState>();
  final EjercicioService _service = EjercicioService();

  late TextEditingController _nombreCtrl;
  late TextEditingController _descripcionCtrl;
  late TextEditingController _duracionCtrl;
  late TextEditingController _categoriaCtrl;

  bool _guardando = false;
  bool get _esEdicion => widget.ejercicio != null;

  @override
  void initState() {
    super.initState();
    final e = widget.ejercicio;
    _nombreCtrl = TextEditingController(text: e?['nombre'] ?? '');
    _descripcionCtrl = TextEditingController(text: e?['descripcion'] ?? '');
    _duracionCtrl = TextEditingController(
      text: e?['duracion'] != null ? '${e!['duracion']}' : '',
    );
    _categoriaCtrl = TextEditingController(text: e?['categoria'] ?? '');
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _duracionCtrl.dispose();
    _categoriaCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    final datos = {
      'nombre': _nombreCtrl.text.trim(),
      'descripcion': _descripcionCtrl.text.trim(),
      'duracion': int.tryParse(_duracionCtrl.text.trim()) ?? 1,
      'categoria': _categoriaCtrl.text.trim(),
    };

    bool ok;
    if (_esEdicion) {
      final id = int.tryParse('${widget.ejercicio!['id']}') ?? 0;
      ok = await _service.actualizarEjercicio(id, datos);
    } else {
      ok = await _service.crearEjercicio(datos) != null;
    }

    if (!mounted) return;
    setState(() => _guardando = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(_esEdicion
              ? 'Ejercicio actualizado correctamente'
              : 'Ejercicio creado correctamente'),
        ),
      );
      widget.onSaved?.call();
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Error al guardar el ejercicio'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar ejercicio' : 'Nuevo ejercicio'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                prefixIcon: Icon(Icons.fitness_center),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descripcionCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _duracionCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Duración (minutos)',
                prefixIcon: Icon(Icons.timer),
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Campo obligatorio';
                final n = int.tryParse(v.trim());
                if (n == null || n <= 0) return 'Ingresa un número válido';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _categoriaCtrl,
              decoration: const InputDecoration(
                labelText: 'Categoría (Cuello, Hombros, etc.)',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _guardando ? null : _guardar,
                icon: _guardando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_guardando
                    ? 'Guardando...'
                    : (_esEdicion ? 'Actualizar' : 'Crear')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}