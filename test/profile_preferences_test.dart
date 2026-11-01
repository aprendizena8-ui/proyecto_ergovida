import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarea/data/services/profile_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('inicializa la fecha de miembro al crear el perfil local', () async {
    final perfil = await ProfilePreferences.load(7);

    expect(perfil.miembroDesde, isNotNull);
    expect(perfil.notificaciones, isTrue);
    expect(perfil.recordatorios, isTrue);
  });

  test('guarda y recupera los datos personales por usuario', () async {
    final inicial = await ProfilePreferences.load(7);
    final actualizado = inicial.copyWith(
      telefono: '0999999999',
      cargo: 'Diseñadora',
      ciudad: 'Quito',
      fechaNacimiento: '1995-04-12',
      biografia: 'Me gusta cuidar mi postura.',
      notificaciones: false,
      recordatorios: false,
    );

    await ProfilePreferences.save(7, actualizado);
    final recuperado = await ProfilePreferences.load(7);

    expect(recuperado.telefono, '0999999999');
    expect(recuperado.cargo, 'Diseñadora');
    expect(recuperado.ciudad, 'Quito');
    expect(recuperado.fechaNacimiento, '1995-04-12');
    expect(recuperado.biografia, 'Me gusta cuidar mi postura.');
    expect(recuperado.notificaciones, isFalse);
    expect(recuperado.recordatorios, isFalse);

    final otroUsuario = await ProfilePreferences.load(8);
    expect(otroUsuario.telefono, isEmpty);
  });
}
