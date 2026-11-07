class RecordatorioGlobal {
  final int id;
  final String hora;
  final String diasSemana;
  final String mensaje;
  final bool activo;

  const RecordatorioGlobal({
    required this.id,
    required this.hora,
    required this.diasSemana,
    required this.mensaje,
    required this.activo,
  });

  factory RecordatorioGlobal.fromJson(Map<String, dynamic> json) {
    return RecordatorioGlobal(
      id: _asInt(json['id']),
      hora: _normalizarHora((json['hora'] ?? '').toString()),
      diasSemana: (json['diasSemana'] ?? '1,2,3,4,5,6,7').toString(),
      mensaje: (json['mensaje'] ?? '').toString().trim(),
      activo: json['activo'] != false,
    );
  }

  Map<String, dynamic> toJson() => {
    'hora': hora,
    'diasSemana': diasSemana,
    'mensaje': mensaje,
    'activo': activo,
  };

  RecordatorioGlobal copyWith({
    int? id,
    String? hora,
    String? diasSemana,
    String? mensaje,
    bool? activo,
  }) {
    return RecordatorioGlobal(
      id: id ?? this.id,
      hora: hora ?? this.hora,
      diasSemana: diasSemana ?? this.diasSemana,
      mensaje: mensaje ?? this.mensaje,
      activo: activo ?? this.activo,
    );
  }

  String get diasEtiqueta {
    final dias = diasSemana
        .split(',')
        .map((dia) => dia.trim())
        .where((dia) => dia.isNotEmpty)
        .toSet();
    if (dias.length == 7) return 'Todos los días';
    const nombres = {
      '1': 'Lun',
      '2': 'Mar',
      '3': 'Mié',
      '4': 'Jue',
      '5': 'Vie',
      '6': 'Sáb',
      '7': 'Dom',
    };
    return dias.map((dia) => nombres[dia] ?? dia).join(', ');
  }

  bool get esHoy {
    final hoy = DateTime.now().weekday.toString();
    return diasSemana.split(',').map((dia) => dia.trim()).contains(hoy);
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _normalizarHora(String value) {
    final partes = value.split(':');
    if (partes.length < 2) return value;
    return '${partes[0].padLeft(2, '0')}:${partes[1].padLeft(2, '0')}';
  }
}
