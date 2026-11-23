import 'api_client.dart';

class EjercicioService {
  static String get baseUrl => ApiClient.baseUrl;

  /// Último error devuelto por el backend al sincronizar el catálogo.
  static String? ultimoError;

  static String _detalleError(Object error) {
    final texto = error.toString().replaceAll('Exception: ', '').trim();
    return texto.isEmpty ? 'No se pudo conectar con el backend.' : texto;
  }

  // GET: Obtiene la lista de ejercicios desde MySQL vía Spring Boot
  Future<List<dynamic>> obtenerEjercicios() async {
    try {
      final data = await ApiClient.get('/ejercicios');
      ultimoError = null;
      return data is List ? data : [];
    } catch (e) {
      ultimoError = _detalleError(e);
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
      ultimoError = null;
      return true;
    } catch (e) {
      ultimoError = _detalleError(e);
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
      if (data is Map) {
        ultimoError = null;
        return Map<String, dynamic>.from(data);
      }
      return null;
    } catch (e) {
      ultimoError = _detalleError(e);
      print('Error al crear ejercicio: $e');
      return null;
    }
  }

  // PUT: Actualizar ejercicio
  Future<bool> actualizarEjercicio(int id, Map<String, dynamic> datos) async {
    try {
      await ApiClient.put('/ejercicios/$id', datos);
      ultimoError = null;
      return true;
    } catch (e) {
      ultimoError = _detalleError(e);
      print('Error al actualizar ejercicio: $e');
      return false;
    }
  }

  // DELETE: Eliminar ejercicio
  Future<bool> eliminarEjercicio(int id) async {
    try {
      await ApiClient.delete('/ejercicios/$id');
      ultimoError = null;
      return true;
    } catch (e) {
      ultimoError = _detalleError(e);
      print('Error al eliminar ejercicio: $e');
      return false;
    }
  }
}
