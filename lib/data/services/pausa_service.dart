import 'api_client.dart';

class PausaService {
  // GET: Todas las pausas
  Future<List<dynamic>> obtenerTodas() async {
    try {
      final data = await ApiClient.get('/pausas-realizadas');
      return data as List<dynamic>;
    } catch (e) {
      print('Error al obtener pausas: $e');
      return [];
    }
  }

  // GET: Pausas por usuario
  Future<List<dynamic>> obtenerPorUsuario(int usuarioId) async {
    try {
      final data = await ApiClient.get('/pausas-realizadas/usuario/$usuarioId');
      return data as List<dynamic>;
    } catch (e) {
      print('Error al obtener pausas del usuario: $e');
      return [];
    }
  }

  // POST: Registrar pausa
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
      print('Error al registrar pausa: $e');
      return false;
    }
  }
}