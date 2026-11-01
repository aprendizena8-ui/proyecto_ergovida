import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarea/data/models/user_model.dart';
import 'package:tarea/data/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthService.clearSession();
  });

  test('persiste la foto del usuario actual y permite quitarla', () async {
    const conFoto = UserModel(
      id: 9,
      nombre: 'Ana',
      correo: 'ana@ergovida.com',
      fotoPerfil: 'foto-base64',
    );

    await AuthService.actualizarUsuarioActual(conFoto);

    expect(AuthService.currentUser?.fotoPerfil, 'foto-base64');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('profile_photo_9'), 'foto-base64');
    expect(prefs.getString('session_user_photo'), 'foto-base64');

    const sinFoto = UserModel(id: 9, nombre: 'Ana', correo: 'ana@ergovida.com');

    await AuthService.actualizarUsuarioActual(sinFoto);

    expect(AuthService.currentUser?.fotoPerfil, isNull);
    expect(prefs.getString('profile_photo_9'), isNull);
    expect(prefs.getString('session_user_photo'), isEmpty);
  });
}
