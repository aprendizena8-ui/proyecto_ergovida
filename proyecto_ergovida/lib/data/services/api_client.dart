import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class ApiClient {
  // URL base dinámica según plataforma
  static String get baseUrl {
    if (kIsWeb) {
      // Web (Chrome, Edge) → localhost funciona
      return 'http://localhost:8080/api';
    }
    try {
      if (Platform.isAndroid) {
        // Emulador Android → 10.0.2.2 apunta a la PC
        return 'http://10.0.2.2:8080/api';
      }
      if (Platform.isIOS) {
        // Emulador iOS → localhost funciona
        return 'http://localhost:8080/api';
      }
    } catch (_) {
      // Plataformas sin dart:io (web) ya se manejaron arriba
    }
    // Windows, macOS, Linux → localhost
    return 'http://localhost:8080/api';
  }

  // Headers comunes
  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // GET genérico
  static Future<dynamic> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // POST genérico
  static Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // PUT genérico
  static Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // DELETE genérico
  static Future<dynamic> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Manejo de respuestas
  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      throw Exception('Recurso no encontrado (404)');
    } else if (response.statusCode == 500) {
      throw Exception('Error interno del servidor (500)');
    } else {
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }
  }
}