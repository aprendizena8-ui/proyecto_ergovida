import 'api_client.dart';

class RutinaService {
  // GET: Listar todas las rutinas
  Future<List<dynamic>> obtenerRutinas() async {
    try {
      final data = await ApiClient.get('/rutinas');
      return data as List<dynamic>;
    } catch (e) {
      print('Error al obtener rutinas: $e');
      return [];
    }
  }

  // GET: Rutina por ID
  Future<Map<String, dynamic>?> obtenerRutinaPorId(int id) async {
    try {
      final data = await ApiClient.get('/rutinas/$id');
      return data as Map<String, dynamic>;
    } catch (e) {
      print('Error al obtener rutina: $e');
      return null;
    }
  }

  // POST: Crear rutina
  Future<Map<String, dynamic>?> crearRutina({
    required String nombre,
    required String descripcion,
  }) async {
    try {
      final data = await ApiClient.post('/rutinas', {
        'nombre': nombre,
        'descripcion': descripcion,
      });
      return data as Map<String, dynamic>;
    } catch (e) {
      print('Error al crear rutina: $e');
      return null;
    }
  }

  // PUT: Actualizar rutina
  Future<bool> actualizarRutina(
    int id, {
    required String nombre,
    required String descripcion,
  }) async {
    try {
      await ApiClient.put('/rutinas/$id', {
        'nombre': nombre,
        'descripcion': descripcion,
      });
      return true;
    } catch (e) {
      print('Error al actualizar rutina: $e');
      return false;
    }
  }

  // DELETE: Eliminar rutina
  Future<bool> eliminarRutina(int id) async {
    try {
      await ApiClient.delete('/rutinas/$id');
      return true;
    } catch (e) {
      print('Error al eliminar rutina: $e');
      return false;
    }
  }

  // POST: Asignar un ejercicio a una rutina
  Future<Map<String, dynamic>?> asignarEjercicio(
    int rutinaId,
    int ejercicioId,
  ) async {
    try {
      final data = await ApiClient.post(
        '/rutinas/$rutinaId/ejercicios/$ejercicioId',
        {},
      );
      return data as Map<String, dynamic>;
    } catch (e) {
      print('Error al asignar ejercicio: $e');
      return null;
    }
  }
}