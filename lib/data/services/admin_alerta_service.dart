import 'api_client.dart';

class CorreoAlerta {
  final int id;
  final String correo;
  final String nombre;
  final bool activo;

  const CorreoAlerta({
    required this.id,
    required this.correo,
    required this.nombre,
    required this.activo,
  });

  factory CorreoAlerta.fromJson(Map<String, dynamic> json) {
    return CorreoAlerta(
      id: (json['id'] as num?)?.toInt() ?? 0,
      correo: json['correo']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      activo: json['activo'] != false,
    );
  }
}

class SolicitudAyudaAdmin {
  final int id;
  final int usuarioId;
  final String nombre;
  final String correo;
  final String rol;
  final String asunto;
  final String descripcion;
  final String estado;
  final String fechaCreacion;

  const SolicitudAyudaAdmin({
    required this.id,
    required this.usuarioId,
    required this.nombre,
    required this.correo,
    required this.rol,
    required this.asunto,
    required this.descripcion,
    required this.estado,
    required this.fechaCreacion,
  });

  bool get pendiente => estado.toUpperCase() == 'PENDIENTE';

  factory SolicitudAyudaAdmin.fromJson(Map<String, dynamic> json) {
    return SolicitudAyudaAdmin(
      id: (json['id'] as num?)?.toInt() ?? 0,
      usuarioId: (json['usuarioId'] as num?)?.toInt() ?? 0,
      nombre: json['nombre']?.toString() ?? '',
      correo: json['correo']?.toString() ?? '',
      rol: json['rol']?.toString() ?? '',
      asunto: json['asunto']?.toString() ?? '',
      descripcion: json['descripcion']?.toString() ?? '',
      estado: json['estado']?.toString() ?? 'PENDIENTE',
      fechaCreacion: json['fechaCreacion']?.toString() ?? '',
    );
  }
}

class HistorialRecordatorioAdmin {
  final int id;
  final String tipo;
  final String canal;
  final bool exito;
  final String error;
  final String fecha;
  final int usuarioId;

  const HistorialRecordatorioAdmin({
    required this.id,
    required this.tipo,
    required this.canal,
    required this.exito,
    required this.error,
    required this.fecha,
    required this.usuarioId,
  });

  factory HistorialRecordatorioAdmin.fromJson(Map<String, dynamic> json) {
    return HistorialRecordatorioAdmin(
      id: (json['id'] as num?)?.toInt() ?? 0,
      tipo: json['tipoRecordatorio']?.toString() ?? '',
      canal: json['canal']?.toString() ?? '',
      exito: json['exito'] == true,
      error: json['error']?.toString() ?? '',
      fecha: json['fechaHora']?.toString() ?? json['fecha']?.toString() ?? '',
      usuarioId: (json['usuarioId'] as num?)?.toInt() ?? 0,
    );
  }
}

class AlertaErrorAdmin {
  final int id;
  final String tipo;
  final String modulo;
  final String mensaje;
  final int veces;
  final String ultimoEnvio;

  const AlertaErrorAdmin({
    required this.id,
    required this.tipo,
    required this.modulo,
    required this.mensaje,
    required this.veces,
    required this.ultimoEnvio,
  });

  factory AlertaErrorAdmin.fromJson(Map<String, dynamic> json) {
    return AlertaErrorAdmin(
      id: (json['id'] as num?)?.toInt() ?? 0,
      tipo: json['tipo']?.toString() ?? '',
      modulo: json['modulo']?.toString() ?? '',
      mensaje: json['mensaje']?.toString() ?? '',
      veces: (json['veces'] as num?)?.toInt() ?? 0,
      ultimoEnvio: json['ultimoEnvio']?.toString() ?? '',
    );
  }
}

class AdminAlertaService {
  static Future<List<CorreoAlerta>> correos() async {
    final data = await ApiClient.get('/admin/correos-alertas');
    return _lista(data)
        .map((item) => CorreoAlerta.fromJson(item))
        .toList();
  }

  static Future<CorreoAlerta> crearCorreo({
    required String correo,
    String nombre = '',
  }) async {
    final data = await ApiClient.post('/admin/correos-alertas', {
      'correo': correo,
      'nombre': nombre,
      'activo': true,
    });
    return CorreoAlerta.fromJson(_mapa(data));
  }

  static Future<CorreoAlerta> actualizarCorreo(
    int id, {
    required String correo,
    String nombre = '',
    required bool activo,
  }) async {
    final data = await ApiClient.put('/admin/correos-alertas/$id', {
      'correo': correo,
      'nombre': nombre,
      'activo': activo,
    });
    return CorreoAlerta.fromJson(_mapa(data));
  }

  static Future<void> eliminarCorreo(int id) async {
    await ApiClient.delete('/admin/correos-alertas/$id');
  }

  static Future<Map<String, dynamic>> probar() async {
    final data = await ApiClient.post('/admin/correos-alertas/probar', {});
    return _mapa(data);
  }

  static Future<Map<String, dynamic>> probarAlertaError() async {
    final data = await ApiClient.post('/app-errores', {
      'tipo': 'Prueba manual',
      'modulo': 'Perfil administrador',
      'mensaje':
          'Alerta de prueba enviada desde el perfil del administrador de ErgoVida.',
      'stack': '',
    });
    return _mapa(data);
  }

  static Future<List<SolicitudAyudaAdmin>> solicitudes({
    String? estado,
  }) async {
    final query = estado == null || estado.isEmpty
        ? ''
        : '?estado=$estado';
    final data = await ApiClient.get('/admin/solicitudes-ayuda$query');
    return _lista(data)
        .map((item) => SolicitudAyudaAdmin.fromJson(item))
        .toList();
  }

  static Future<void> cambiarEstadoSolicitud(int id, String estado) async {
    await ApiClient.put(
      '/admin/solicitudes-ayuda/$id/estado',
      {'estado': estado},
    );
  }

  static Future<List<HistorialRecordatorioAdmin>> historial() async {
    final data = await ApiClient.get('/admin/recordatorios-historial');
    return _lista(data)
        .map((item) => HistorialRecordatorioAdmin.fromJson(item))
        .toList();
  }

  static Future<List<AlertaErrorAdmin>> alertas() async {
    final data = await ApiClient.get('/admin/alertas-error');
    return _lista(data).map((item) => AlertaErrorAdmin.fromJson(item)).toList();
  }

  static List<Map<String, dynamic>> _lista(dynamic data) {
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Map<String, dynamic> _mapa(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }
}
