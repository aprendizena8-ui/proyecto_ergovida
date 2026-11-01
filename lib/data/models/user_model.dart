class UserModel {
  final int id;
  final String nombre;
  final String correo;
  final String rol;
  final bool activo;

  /// Puede ser una URL, una ruta local o una imagen en base64.
  final String? fotoPerfil;

  const UserModel({
    this.id = 0,
    required this.nombre,
    required this.correo,
    this.rol = 'USUARIO',
    this.activo = true,
    this.fotoPerfil,
  });

  bool get esAdmin => rol.toUpperCase() == 'ADMINISTRADOR';

  bool get tieneFoto => (fotoPerfil ?? '').trim().isNotEmpty;

  String get inicial {
    final base = nombre.trim().isNotEmpty ? nombre.trim() : correo.trim();
    return base.isEmpty ? '?' : base[0].toUpperCase();
  }

  UserModel copyWith({
    int? id,
    String? nombre,
    String? correo,
    String? rol,
    bool? activo,
    String? fotoPerfil,
  }) {
    final foto = fotoPerfil == null
        ? this.fotoPerfil
        : (fotoPerfil.trim().isEmpty ? null : fotoPerfil.trim());

    return UserModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      correo: correo ?? this.correo,
      rol: rol ?? this.rol,
      activo: activo ?? this.activo,
      fotoPerfil: foto,
    );
  }

  factory UserModel.fromJson(
    Map<String, dynamic> json, {
    String fallbackCorreo = '',
    String fallbackNombre = '',
  }) {
    final nombre = (json['nombre'] ?? json['name'] ?? fallbackNombre)
        .toString()
        .trim();
    final correo = (json['correo'] ?? json['email'] ?? fallbackCorreo)
        .toString()
        .trim();
    final rol = (json['rol'] ?? json['role'] ?? 'USUARIO').toString();
    final foto =
        (json['fotoPerfil'] ??
                json['foto_perfil'] ??
                json['foto'] ??
                json['photo'] ??
                '')
            .toString()
            .trim();

    return UserModel(
      id: _asInt(json['id']),
      nombre: nombre.isEmpty ? correo : nombre,
      correo: correo,
      rol: rol.isEmpty ? 'USUARIO' : rol,
      activo: json['activo'] is bool ? json['activo'] as bool : true,
      fotoPerfil: foto.isEmpty ? null : foto,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'correo': correo,
      'rol': rol,
      'activo': activo,
      if (tieneFoto) 'fotoPerfil': fotoPerfil,
    };
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
