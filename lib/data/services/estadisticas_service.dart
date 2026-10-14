import 'api_client.dart';

class EstadisticasService {
  // GET: Todas las estadísticas
  Future<List<dynamic>> obtenerTodas() async {
    try {
      final data = await ApiClient.get('/estadisticas');
      return data as List<dynamic>;
    } catch (e) {
      print('Error al obtener estadísticas: $e');
      return [];
    }
  }

  // GET: Estadísticas por usuario
  Future<List<dynamic>> obtenerPorUsuario(int usuarioId) async {
    try {
      final data = await ApiClient.get('/estadisticas/usuario/$usuarioId');
      return data as List<dynamic>;
    } catch (e) {
      print('Error al obtener estadísticas del usuario: $e');
      return [];
    }
  }

  // POST: Crear o actualizar estadística
  Future<Map<String, dynamic>?> guardarEstadistica({
    required int usuarioId,
    required int pausasRealizadas,
    required int minutosActivos,
    required String fecha,
  }) async {
    try {
      final data = await ApiClient.post('/estadisticas', {
        'usuarioId': usuarioId,
        'pausasRealizadas': pausasRealizadas,
        'minutosActivos': minutosActivos,
        'fecha': fecha,
      });
      return data as Map<String, dynamic>;
    } catch (e) {
      print('Error al guardar estadística: $e');
      return null;
    }
  }
}