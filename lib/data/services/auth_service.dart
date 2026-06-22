class AuthService {
  bool login(String correo, String password) {
    if (correo.isNotEmpty && password.isNotEmpty) {
      return true;
    }

    return false;
  }
}
