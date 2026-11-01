import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tarea/data/models/user_model.dart';

void main() {
  test('lee y serializa la foto de perfil', () {
    final foto = base64Encode([1, 2, 3, 4]);
    final usuario = UserModel.fromJson({
      'id': 3,
      'nombre': 'Ana',
      'correo': 'ana@ergovida.com',
      'rol': 'USUARIO',
      'fotoPerfil': foto,
    });

    expect(usuario.tieneFoto, isTrue);
    expect(usuario.fotoPerfil, foto);
    expect(usuario.toJson()['fotoPerfil'], foto);
  });

  test('permite quitar la foto con copyWith', () {
    const usuario = UserModel(
      id: 1,
      nombre: 'Ana',
      correo: 'ana@ergovida.com',
      fotoPerfil: 'abc',
    );

    final sinFoto = usuario.copyWith(fotoPerfil: '');

    expect(sinFoto.fotoPerfil, isNull);
    expect(sinFoto.tieneFoto, isFalse);
  });
}
