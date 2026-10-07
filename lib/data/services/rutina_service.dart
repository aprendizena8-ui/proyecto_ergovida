import 'dart:convert';
import 'package:http/http.dart' as http;

class RutinaService {
  static const String baseUrl = "http://localhost:8080/api/rutinas";

  Future<List<dynamic>> obtenerRutinas() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      print("Error al obtener rutinas: $e");
      return [];
    }
  }
}