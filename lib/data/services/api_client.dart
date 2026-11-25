import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class ApiClient {
  /// Identidad de la sesión activa. AuthService la actualiza al iniciar,
  /// restaurar o cerrar sesión. El backend usa estos datos para validar roles.
  static int currentUserId = 0;
  static String currentUserEmail = '';

    // URL base dinámica según plataforma
  static String get baseUrl {
    // 1. Si hay una URL configurada por variable de entorno, se usa esa.
    const configurada = String.fromEnvironment('API_BASE_URL');
    if (configurada.trim().isNotEmpty) {
      final normalizada = configurada.trim().replaceAll(RegExp(r'/+$'), '');
      return normalizada.endsWith('/api') ? normalizada : '$normalizada/api';
    }

    // 2. URL por defecto para producción (Render)
    const urlRender = 'https://proyecto-ergovida-backend.onrender.com/api';

    // En web no se puede usar dart:io, por eso se resuelve antes de Platform.
    if (kIsWeb) {
      return urlRender;
    }

    // Forzamos a Windows a usar Render para probar el backend en la nube
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return urlRender;
    }

    // 4. Para Android/iOS, usa Render directamente (o localhost si estás en emulador)
    if (Platform.isAndroid) {
      return urlRender;  // Emulador Android
    }
    if (Platform.isIOS) {
      return urlRender; // Emulador iOS
    }

    return urlRender; // Por defecto, usa Render
  }

  // Headers comunes
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (currentUserId > 0) 'X-Usuario-Id': '$currentUserId',
    if (currentUserEmail.trim().isNotEmpty)
      'X-Usuario-Correo': currentUserEmail.trim(),
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
  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
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
  static Future<dynamic> delete(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: body == null ? null : jsonEncode(body),
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
