import 'api_client.dart';

/// Envia errores graves de la app Flutter al backend para que los
/// administradores reciban una alerta por correo.
class AppErrorService {
  static bool _reportando = false;

  static Future<void> reportar({
    required String tipo,
    required String modulo,
    required String mensaje,
    String? stack,
  }) async {
    if (_reportando) return;
    _reportando = true;
    try {
      await ApiClient.post('/app-errores', {
        'tipo': tipo,
        'modulo': modulo,
        'mensaje': mensaje,
        'stack': stack ?? '',
      });
    } catch (_) {
      // Si el backend no responde no hay forma de notificar el error.
    } finally {
      _reportando = false;
    }
  }
}
