import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import 'api_client.dart';

class AuthService {
  static const String _sessionEmailKey = 'session_email';
  static const String _sessionPasswordKey = 'session_password';
  static const String _sessionIdKey = 'session_user_id';
  static const String _sessionNameKey = 'session_user_name';
  static const String _sessionRoleKey = 'session_user_role';

  static String nombreGuardado = '';
  static String correoGuardado = '';
  static String passwordGuardada = '';

  static int usuarioId = 0;
  static String usuarioNombre = '';
  static String usuarioCorreo = '';
  static String usuarioRol = 'USUARIO';

  static bool get isAdmin => usuarioRol.toUpperCase() == 'ADMINISTRADOR';

  static UserModel? get currentUser {
    if (usuarioCorreo.trim().isEmpty) return null;
    return UserModel(
      id: usuarioId,
      nombre: usuarioNombre.trim().isEmpty ? usuarioCorreo : usuarioNombre,
      correo: usuarioCorreo,
      rol: usuarioRol,
    );
  }

  static Map<String, dynamic> _decodeBody(http.Response response) {
    final body = response.body.trim();
    if (body.isEmpty) return {};

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return {'message': body};
    } on FormatException {
      return {'message': body};
    }
  }

  static String _errorMessage(Map<String, dynamic> data, String fallback) {
    final message = data['message']?.toString().trim();
    return (message == null || message.isEmpty) ? fallback : message;
  }

  static UserModel? _userFromResponse(
    Map<String, dynamic> data, {
    String correo = '',
    String nombre = '',
  }) {
    final nested = data['user'];
    if (nested is Map) {
      return UserModel.fromJson(
        Map<String, dynamic>.from(nested),
        fallbackCorreo: correo,
        fallbackNombre: nombre,
      );
    }
    if (data.isEmpty) return null;
    return UserModel.fromJson(
      data,
      fallbackCorreo: correo,
      fallbackNombre: nombre,
    );
  }

  static Future<_LoginAttempt> _requestLogin(
    String correo,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'correo': correo,
          'email': correo,
          'password': password,
        }),
      );

      final data = _decodeBody(response);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _LoginAttempt(user: _userFromResponse(data, correo: correo));
      }

      return _LoginAttempt(
        offline: response.statusCode >= 500,
        message: _errorMessage(data, 'Correo o contraseña incorrectos'),
      );
    } catch (_) {
      return const _LoginAttempt(offline: true);
    }
  }

  static Future<void> _persistSession(
    UserModel user,
    String correo,
    String password,
  ) async {
    usuarioId = user.id;
    usuarioNombre = user.nombre;
    usuarioCorreo = user.correo.trim().isEmpty ? correo.trim() : user.correo;
    usuarioRol = user.rol;
    correoGuardado = usuarioCorreo;
    nombreGuardado = user.nombre;
    passwordGuardada = password;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionEmailKey, usuarioCorreo);
    await prefs.setString(_sessionPasswordKey, password);
    await prefs.setInt(_sessionIdKey, usuarioId);
    await prefs.setString(_sessionNameKey, usuarioNombre);
    await prefs.setString(_sessionRoleKey, usuarioRol);
  }

  static Future<void> _loadCachedUser(SharedPreferences prefs) async {
    usuarioId = prefs.getInt(_sessionIdKey) ?? 0;
    usuarioNombre = prefs.getString(_sessionNameKey) ?? '';
    usuarioCorreo = prefs.getString(_sessionEmailKey) ?? '';
    usuarioRol = prefs.getString(_sessionRoleKey) ?? 'USUARIO';
    correoGuardado = usuarioCorreo;
    nombreGuardado = usuarioNombre;
    passwordGuardada = prefs.getString(_sessionPasswordKey) ?? '';
  }

  static Future<void> saveSession(String correo, String password) async {
    final user = currentUser;
    if (user != null) {
      await _persistSession(user, correo, password);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionEmailKey, correo.trim());
    await prefs.setString(_sessionPasswordKey, password);
    correoGuardado = correo.trim();
    passwordGuardada = password;
  }

  /// Actualiza en memoria y en disco los datos del usuario con sesión activa
  /// (por ejemplo, tras editar el perfil o cambiar de rol).
  static Future<void> actualizarUsuarioActual(UserModel user) async {
    usuarioId = user.id;
    usuarioNombre = user.nombre;
    usuarioCorreo = user.correo;
    usuarioRol = user.rol;
    nombreGuardado = user.nombre;
    correoGuardado = user.correo;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sessionIdKey, usuarioId);
    await prefs.setString(_sessionNameKey, usuarioNombre);
    await prefs.setString(_sessionEmailKey, usuarioCorreo);
    await prefs.setString(_sessionRoleKey, usuarioRol);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionEmailKey);
    await prefs.remove(_sessionPasswordKey);
    await prefs.remove(_sessionIdKey);
    await prefs.remove(_sessionNameKey);
    await prefs.remove(_sessionRoleKey);

    nombreGuardado = '';
    correoGuardado = '';
    passwordGuardada = '';
    usuarioId = 0;
    usuarioNombre = '';
    usuarioCorreo = '';
    usuarioRol = 'USUARIO';
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_sessionEmailKey);
    final password = prefs.getString(_sessionPasswordKey);
    if (email == null || email.isEmpty || password == null || password.isEmpty) {
      return false;
    }

    await _loadCachedUser(prefs);
    return true;
  }

  /// Recupera la sesión guardada y refresca los datos del usuario (id y rol)
  /// contra el backend. Si el backend no responde, mantiene la sesión local.
  static Future<UserModel?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_sessionEmailKey);
    final password = prefs.getString(_sessionPasswordKey);

    if (email == null ||
        email.isEmpty ||
        password == null ||
        password.isEmpty) {
      return null;
    }

    await _loadCachedUser(prefs);

    final attempt = await _requestLogin(email, password);
    if (attempt.user != null) {
      await _persistSession(attempt.user!, email, password);
      return attempt.user;
    }

    if (attempt.offline) {
      return currentUser;
    }

    await clearSession();
    return null;
  }

  static Future<UserModel?> registrar(
    String nombre,
    String correo,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': nombre,
          'correo': correo,
          'name': nombre,
          'email': correo,
          'password': password,
        }),
      );

      final data = _decodeBody(response);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        nombreGuardado = nombre;
        correoGuardado = correo.trim();
        passwordGuardada = password;
        return _userFromResponse(
          data,
          correo: correo.trim(),
          nombre: nombre,
        );
      }

      throw Exception(
        _errorMessage(data, 'No se pudo registrar el usuario'),
      );
    } on http.ClientException {
      throw Exception('No se pudo conectar con el backend local');
    } catch (error) {
      if (error is Exception && error.toString().startsWith('Exception:')) {
        rethrow;
      }
      throw Exception('No se pudo conectar con el backend local');
    }
  }

  Future<UserModel?> login(String correo, String password) async {
    final email = correo.trim();
    final attempt = await _requestLogin(email, password);

    if (attempt.user != null) {
      await _persistSession(attempt.user!, email, password);
      return attempt.user;
    }

    if (attempt.offline) {
      final coincide =
          email == correoGuardado && password == passwordGuardada;
      return coincide ? currentUser : null;
    }

    return null;
  }
}

class _LoginAttempt {
  final UserModel? user;
  final bool offline;
  final String? message;

  const _LoginAttempt({this.user, this.offline = false, this.message});
}
