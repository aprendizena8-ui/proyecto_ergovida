class AuthService {
  static String nombreGuardado = "";
  static String correoGuardado = "";
  static String passwordGuardada = "";

  static void registrar(
    String nombre,
    String correo,
    String password,
  ) {
    nombreGuardado = nombre;
    correoGuardado = correo;
    passwordGuardada = password;
  }

  bool login(
    String correo,
    String password,
  ) {
    return correo == correoGuardado &&
        password == passwordGuardada;
  }
}
