import 'api_client.dart';

class EjercicioService {
  static String get baseUrl => ApiClient.baseUrl;

  // GET: Obtiene la lista de ejercicios desde MySQL vía Spring Boot
  Future<List<dynamic>> obtenerEjercicios() async {
    try {
      final data = await ApiClient.get('/ejercicios');
      return data is List ? data : [];
    } catch (e) {
      print('Error al obtener ejercicios: $e');
      return [];
    }
  }

  // POST: Guarda la pausa realizada asociada a usuario_id y ejercicio_id en la BD
  Future<bool> registrarPausa({
    required int usuarioId,
    required int ejercicioId,
    required bool completada,
  }) async {
    try {
      await ApiClient.post('/pausas-realizadas', {
        'usuarioId': usuarioId,
        'ejercicioId': ejercicioId,
        'completada': completada,
      });
      return true;
    } catch (e) {
      print('Error al guardar pausa en la BD: $e');
      return false;
    }
  }

  // POST: Crear ejercicio y devolver el registro creado (con su id)
  Future<Map<String, dynamic>?> crearEjercicio(
    Map<String, dynamic> datos,
  ) async {
    try {
      final data = await ApiClient.post('/ejercicios', datos);
      if (data is Map) return Map<String, dynamic>.from(data);
      return null;
    } catch (e) {
      print('Error al crear ejercicio: $e');
      return null;
    }
  }

  // PUT: Actualizar ejercicio
  Future<bool> actualizarEjercicio(int id, Map<String, dynamic> datos) async {
    try {
      await ApiClient.put('/ejercicios/$id', datos);
      return true;
    } catch (e) {
      print('Error al actualizar ejercicio: $e');
      return false;
    }
  }

  // DELETE: Eliminar ejercicio
  Future<bool> eliminarEjercicio(int id) async {
    try {
      await ApiClient.delete('/ejercicios/$id');
      return true;
    } catch (e) {
      print('Error al eliminar ejercicio: $e');
      return false;
    }
  }
}
