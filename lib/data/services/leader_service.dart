import '../models/usuario_estadistica_model.dart';
import 'api_client.dart';

class LeaderService {
  Future<List<UsuarioEstadistica>> obtenerEstadisticasUsuarios() async {
    final data = await ApiClient.get('/lider/estadisticas-usuarios');
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(UsuarioEstadistica.fromJson)
        .toList();
  }
}
