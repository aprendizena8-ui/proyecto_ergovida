import 'api_client.dart';

class SolicitudAyudaService {
  static Future<Map<String, dynamic>> enviar({
    required String asunto,
    required String descripcion,
  }) async {
    final response = await ApiClient.post('/solicitudes-ayuda', {
      'asunto': asunto,
      'descripcion': descripcion,
    });

    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    return <String, dynamic>{};
  }

  static Future<List<dynamic>> misSolicitudes() async {
    final response = await ApiClient.get(
      '/solicitudes-ayuda/mis-solicitudes',
    );

    if (response is List) return response;
    return const [];
  }
}
