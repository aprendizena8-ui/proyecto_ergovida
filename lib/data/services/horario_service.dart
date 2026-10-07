import 'dart:convert';
import 'package:http/http.dart' as http;

class HorarioService {
  static const String baseUrl = "http://localhost:8080/api/horarios";

  Future<List<dynamic>> obtenerHorariosPorUsuario(int usuarioId) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/usuario/$usuarioId"));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      print("Error al consultar horarios: $e");
      return [];
    }
  }

  Future<bool> guardarHorario(int usuarioId, String hora) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "usuario": {"id": usuarioId},
          "hora": hora,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Error al guardar horario: $e");
      return false;
    }
  }
}