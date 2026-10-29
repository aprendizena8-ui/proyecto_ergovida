class UserModel {
  final int id;
  final String nombre;
  final String correo;
  final String rol;
  final bool activo;

  const UserModel({
    this.id = 0,
    required this.nombre,
    required this.correo,
    this.rol = 'USUARIO',
    this.activo = true,
  });

  bool get esAdmin => rol.toUpperCase() == 'ADMINISTRADOR';

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
  }) {
    return UserModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      correo: correo ?? this.correo,
      rol: rol ?? this.rol,
      activo: activo ?? this.activo,
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

    return UserModel(
      id: _asInt(json['id']),
      nombre: nombre.isEmpty ? correo : nombre,
      correo: correo,
      rol: rol.isEmpty ? 'USUARIO' : rol,
      activo: json['activo'] is bool ? json['activo'] as bool : true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'correo': correo,
      'rol': rol,
      'activo': activo,
    };
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
