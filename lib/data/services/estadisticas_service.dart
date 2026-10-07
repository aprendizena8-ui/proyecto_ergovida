import 'dart:convert';
import 'package:http/http.dart' as http;

class EstadisticasService {
  static const String baseUrl = "http://localhost:8080/api/estadisticas";

  Future<Map<String, dynamic>?> obtenerEstadisticasUsuario(int usuarioId) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/usuario/$usuarioId"));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print("Error al obtener estadísticas: $e");
      return null;
    }
  }
}