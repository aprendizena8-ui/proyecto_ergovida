class UsuarioEstadistica {
  final int id;
  final String nombre;
  final String correo;
  final String rol;
  final bool activo;
  final int ejerciciosRealizados;
  final bool completo;
  final int rutinasAdicionales;
  final DateTime? ultimaActividad;

  const UsuarioEstadistica({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
    required this.activo,
    required this.ejerciciosRealizados,
    required this.completo,
    this.rutinasAdicionales = 0,
    this.ultimaActividad,
  });

  factory UsuarioEstadistica.fromJson(Map<String, dynamic> json) {
    return UsuarioEstadistica(
      id: _asInt(json['id']),
      nombre: (json['nombre'] ?? '').toString().trim(),
      correo: (json['correo'] ?? '').toString().trim(),
      rol: (json['rol'] ?? 'USUARIO').toString().trim(),
      activo: json['activo'] == true,
      ejerciciosRealizados: _asInt(json['ejerciciosRealizados']),
      completo: json['completo'] == true,
      rutinasAdicionales: _asInt(json['rutinasAdicionales']),
      ultimaActividad: _asDate(json['ultimaActividad']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _asDate(dynamic value) {
    final texto = value?.toString().trim() ?? '';
    if (texto.isEmpty) return null;
    return DateTime.tryParse(texto);
  }
}
