import '../models/ranking_model.dart';
import 'api_client.dart';

class RankingService {
  Future<List<RankingEntry>> obtenerRanking() async {
    final ranking = await _desdeEndpoint();
    if (ranking.isNotEmpty) return ranking;

    // Respaldo: si el backend aún no expone /ranking, calculamos el ranking
    // con los endpoints CRUD existentes para reflejar siempre las pausas
    // registradas en la base de datos.
    return _desdePausasYUsuarios();
  }

  Future<List<RankingEntry>> _desdeEndpoint() async {
    try {
      final data = await ApiClient.get('/ranking');
      if (data is! List) return [];
      return data
          .whereType<Map>()
          .map((item) => RankingEntry.fromJson(Map<String, dynamic>.from(item)))
          .where((item) => item.totalPausas > 0)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<RankingEntry>> _desdePausasYUsuarios() async {
    try {
      final resultados = await Future.wait([
        ApiClient.get('/pausas-realizadas'),
        ApiClient.get('/users'),
      ]);

      final pausas = resultados[0];
      final usuarios = resultados[1];

      final conteo = <int, int>{};
      if (pausas is List) {
        for (final pausa in pausas.whereType<Map>()) {
          final usuarioId = _asInt(pausa['usuarioId'] ?? pausa['usuario_id']);
          if (usuarioId > 0) {
            conteo[usuarioId] = (conteo[usuarioId] ?? 0) + 1;
          }
        }
      }

      final usuariosPorId = <int, Map<String, dynamic>>{};
      if (usuarios is List) {
        for (final usuario in usuarios.whereType<Map>()) {
          final data = Map<String, dynamic>.from(usuario);
          final id = _asInt(data['id']);
          if (id > 0) usuariosPorId[id] = data;
        }
      }

      final ranking = conteo.entries.where((entry) => entry.value > 0).map((
        entry,
      ) {
        final usuario = usuariosPorId[entry.key];
        final nombre = (usuario?['nombre'] ?? '').toString().trim();
        final avatar = (usuario?['avatar'] ?? '').toString().trim();
        final foto = (usuario?['fotoPerfil'] ?? usuario?['foto_perfil'] ?? '')
            .toString()
            .trim();

        return RankingEntry(
          usuarioId: entry.key,
          nombre: nombre.isEmpty ? 'Usuario' : nombre,
          avatar: avatar.isEmpty ? null : avatar,
          fotoPerfil: foto.isEmpty ? null : foto,
          totalPausas: entry.value,
        );
      }).toList()..sort((a, b) => b.totalPausas.compareTo(a.totalPausas));

      return ranking;
    } catch (_) {
      return [];
    }
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
