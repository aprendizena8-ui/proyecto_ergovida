import 'dart:convert';
import 'package:http/http.dart' as http;

class EjercicioService {
  static const String baseUrl = "http://localhost:8080/api";

  // GET: Obtiene la lista de ejercicios desde MySQL vía Spring Boot
  Future<List<dynamic>> obtenerEjercicios() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/ejercicios"));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      print("Error de servidor: ${response.statusCode}");
      return [];
    } catch (e) {
      print("Error al obtener ejercicios: $e");
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
      final response = await http.post(
        Uri.parse("$baseUrl/pausas-realizadas"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "usuario": {"id": usuarioId},
          "ejercicio": {"id": ejercicioId},
          "fecha": DateTime.now().toIso8601String(),
          "completada": completada,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Error al guardar pausa en la BD: $e");
      return false;
    }
  }
}