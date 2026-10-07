import 'dart:convert';

import 'package:http/http.dart' as http;

// class AuthResponse {
//   final bool success;
//   final String message;

//   AuthResponse({
//     required this.success,
//     required this.message,
//   });
// }

class LoginUser {
  final int id;
  final String nombre;
  final String correo;
  final String rol;

  LoginUser({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
  });

  factory LoginUser.fromJson(Map<String, dynamic> json) {
    return LoginUser(
      id: json["id"],
      nombre: json["nombre"],
      correo: json["correo"],
      rol: json["rol"],
    );
  }
}

class AuthResponse {
  final bool success;
  final String message;
  final LoginUser? user;

  AuthResponse({
    required this.success,
    required this.message,
    this.user,
  });
}

class AuthService {
  static const String baseUrl = "http://localhost:8080/api/auth";

  // static String nombreGuardado = "";
  // static String correoGuardado = "";
  // static String passwordGuardada = "";


  // static void registrar(
  //   String nombre,
  //   String correo,
  //   String password,
  // ) {
  //   nombreGuardado = nombre;
  //   correoGuardado = correo;
  //   passwordGuardada = password;
  // }

  Future<AuthResponse> registrar(
    String nombre,
    String correo,
    String password,
  ) async {
    try {

      print("URL REGISTRO: $baseUrl/register");
      
      final response = await http.post(
        Uri.parse("$baseUrl/register"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "nombre": nombre,
          "correo": correo,
          "password": password,
        }),
      );

      print(response.statusCode);
      print(response.body);

      if (response.statusCode == 200) {
        return AuthResponse(
            success: true,
            message: "Usuario registrado correctamente.",
          );
      }

      return AuthResponse(
        success: false,
        message: response.body,
      );
    // } catch (e) {
    //   return AuthResponse(
    //     success: false,
    //     message: "No fue posible conectar con el servidor.",
    //   );
    // }
    } catch (e) {
      print("ERROR AL REGISTRAR: $e");

      return AuthResponse(
        success: false,
        message: "Error: $e",
      );
    }
  }
  
  //   bool login(
  //     String correo,
  //     String password,
  //   ) {
  //     return correo == correoGuardado &&
  //         password == passwordGuardada;
  //   }
  // }

  Future<AuthResponse> login(
    String correo,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "correo": correo,
          "password": password,
        }),
      );

    if (response.statusCode == 200) {

      final datos = jsonDecode(response.body);

      return AuthResponse(
          success: true,
          message: "Inicio de sesión exitoso.",
          user: LoginUser.fromJson(datos),
      );
    }

    return AuthResponse(
        success: false,
        message: response.body,
      );
    } catch (e) {
      return AuthResponse(
        success: false,
        message: "No fue posible conectar con el servidor.",
      );
    }
  }
}