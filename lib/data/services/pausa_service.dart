import '../../core/constants/activity_types.dart';
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
    int? ejercicioId,
    required bool completada,
    String tipo = ActivityTypes.detectedExercise,
  }) async {
    try {
      await ApiClient.post('/pausas-realizadas', {
        'usuarioId': usuarioId,
        // Las rutinas no tienen ejercicio de catálogo; el backend normaliza 0.
        'ejercicioId': ejercicioId ?? 0,
        'completada': completada,
        'tipo': ActivityTypes.normalize(tipo),
      });
      return true;
    } catch (e) {
      print('Error al registrar pausa: $e');
      return false;
    }
  }
}