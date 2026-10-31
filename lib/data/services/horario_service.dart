import 'api_client.dart';

class HorarioService {
  // GET: Todos los horarios
  Future<List<dynamic>> obtenerTodos() async {
    try {
      final data = await ApiClient.get('/horarios');
      return data as List<dynamic>;
    } catch (e) {
      print('Error al obtener horarios: $e');
      return [];
    }
  }

  // GET: Horarios por usuario
  Future<List<dynamic>> obtenerPorUsuario(int usuarioId) async {
    try {
      final data = await ApiClient.get('/horarios/usuario/$usuarioId');
      return data as List<dynamic>;
    } catch (e) {
      print('Error al obtener horarios del usuario: $e');
      return [];
    }
  }

  // POST: Crear horario
  Future<Map<String, dynamic>?> crearHorario({
    required int usuarioId,
    required String hora,
  }) async {
    try {
      final data = await ApiClient.post('/horarios', {
        'usuarioId': usuarioId,
        'hora': hora,
      });
      return data as Map<String, dynamic>;
    } catch (e) {
      print('Error al guardar horario: $e');
      return null;
    }
  }

  // DELETE: Eliminar horario
  Future<bool> eliminarHorario(int id) async {
    try {
      await ApiClient.delete('/horarios/$id');
      return true;
    } catch (e) {
      print('Error al eliminar horario: $e');
      return false;
    }
  }
}