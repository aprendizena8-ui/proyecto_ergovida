class RankingEntry {
  final int usuarioId;
  final String nombre;
  final String? avatar;
  final String? fotoPerfil;
  final int totalPausas;

  const RankingEntry({
    required this.usuarioId,
    required this.nombre,
    this.avatar,
    this.fotoPerfil,
    this.totalPausas = 0,
  });

  factory RankingEntry.fromJson(Map<String, dynamic> json) {
    final nombre = (json['nombre'] ?? '').toString().trim();
    final avatar = (json['avatar'] ?? '').toString().trim();
    final foto = (json['fotoPerfil'] ?? json['foto_perfil'] ?? '')
        .toString()
        .trim();

    return RankingEntry(
      usuarioId: _asInt(json['usuarioId'] ?? json['id']),
      nombre: nombre.isEmpty ? 'Usuario' : nombre,
      avatar: avatar.isEmpty ? null : avatar,
      fotoPerfil: foto.isEmpty ? null : foto,
      totalPausas: _asInt(json['totalPausas'] ?? json['pausas']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
