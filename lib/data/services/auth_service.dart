import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _sessionEmailKey = 'session_email';
  static const String _sessionPasswordKey = 'session_password';

  static String nombreGuardado = '';
  static String correoGuardado = '';
  static String passwordGuardada = '';

  static const String _baseUrl = 'http://127.0.0.1:8080';

  static Future<void> saveSession(String correo, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionEmailKey, correo.trim());
    await prefs.setString(_sessionPasswordKey, password);
    correoGuardado = correo.trim();
    passwordGuardada = password;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionEmailKey);
    await prefs.remove(_sessionPasswordKey);
    correoGuardado = '';
    passwordGuardada = '';
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_sessionEmailKey);
    final password = prefs.getString(_sessionPasswordKey);
    return email != null && email.isNotEmpty && password != null && password.isNotEmpty;
  }

  static Future<void> registrar(
    String nombre,
    String correo,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': nombre,
          'email': correo,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 && data['success'] == true) {
        nombreGuardado = nombre;
        correoGuardado = correo.trim();
        passwordGuardada = password;
        return;
      }

      throw Exception(data['message'] ?? 'No se pudo registrar el usuario');
    } on http.ClientException {
      nombreGuardado = nombre;
      correoGuardado = correo.trim();
      passwordGuardada = password;
    }
  }

  Future<bool> login(
    String correo,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': correo,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        correoGuardado = correo.trim();
        passwordGuardada = password;
        await saveSession(correo, password);
        return true;
      }

      if (response.statusCode == 401 || response.statusCode == 400) {
        return false;
      }
    } on http.ClientException {
      return correo.trim() == correoGuardado && password == passwordGuardada;
    }

    return correo.trim() == correoGuardado && password == passwordGuardada;
  }
}
