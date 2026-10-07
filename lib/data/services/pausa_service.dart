import 'dart:convert';
import 'package:http/http.dart' as http;

class PausaService {
  static const String baseUrl = "http://localhost:8080/api/pausas-realizadas";

  // Registrar una pausa cuando se presione "Finalizar"
  Future<bool> registrarPausa({
    required int usuarioId,
    required String ejercicioNombre,
    required int duracionSegundos,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "usuario": {"id": usuarioId},
          "ejercicioNombre": ejercicioNombre,
          "duracionSegundos": duracionSegundos,
          "fecha": DateTime.now().toIso8601String(),
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Error al registrar pausa en backend: $e");
      return false;
    }
  }

  // Obtener historial de pausas de un usuario
  Future<List<dynamic>> obtenerPausasPorUsuario(int usuarioId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/usuario/$usuarioId"),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print("Error al consultar pausas: $e");
      return [];
    }
  }
}