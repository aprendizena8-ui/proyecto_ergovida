import '../models/recordatorio_global_model.dart';
import 'api_client.dart';

class RecordatorioGlobalService {
  Future<List<RecordatorioGlobal>> obtenerTodos({
    bool soloActivos = false,
  }) async {
    final data = await ApiClient.get(
      '/recordatorios-globales?soloActivos=$soloActivos',
    );
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(RecordatorioGlobal.fromJson)
        .toList();
  }

  Future<RecordatorioGlobal> crear({
    required String hora,
    required String diasSemana,
    required String mensaje,
    bool activo = true,
  }) async {
    final data = await ApiClient.post('/recordatorios-globales', {
      'hora': hora,
      'diasSemana': diasSemana,
      'mensaje': mensaje,
      'activo': activo,
    });
    return RecordatorioGlobal.fromJson(data as Map<String, dynamic>);
  }

  Future<RecordatorioGlobal> actualizar(RecordatorioGlobal recordatorio) async {
    final data = await ApiClient.put(
      '/recordatorios-globales/${recordatorio.id}',
      recordatorio.toJson(),
    );
    return RecordatorioGlobal.fromJson(data as Map<String, dynamic>);
  }

  Future<void> eliminar(int id) async {
    await ApiClient.delete('/recordatorios-globales/$id');
  }
}
