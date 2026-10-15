class Helpers {
  static bool validarCorreo(String correo) {
    if (correo.contains("@")) {
      return true;
    }

    return false;
  }
}
