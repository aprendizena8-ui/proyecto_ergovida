import 'api_client.dart';

class UsuarioService {
  /// Último error devuelto por el backend. El panel administrador lo usa para
  /// mostrar la causa real en lugar de un mensaje genérico.
  static String? ultimoError;

  static String _detalleError(Object error) {
    final texto = error.toString().replaceAll('Exception: ', '').trim();
    return texto.isEmpty ? 'No se pudo conectar con el backend.' : texto;
  }

  // GET: Listar todos los usuarios
  Future<List<dynamic>> obtenerUsuarios() async {
    try {
      final data = await ApiClient.get('/users');
      ultimoError = null;
      return data as List<dynamic>;
    } catch (e) {
      ultimoError = _detalleError(e);
      print('Error al obtener usuarios: $e');
      return [];
    }
  }

  // GET: Usuario por ID
  Future<Map<String, dynamic>?> obtenerUsuarioPorId(int id) async {
    try {
      final data = await ApiClient.get('/users/$id');
      ultimoError = null;
      return data as Map<String, dynamic>;
    } catch (e) {
      ultimoError = _detalleError(e);
      print('Error al obtener usuario: $e');
      return null;
    }
  }

  // PUT: Actualizar usuario
  Future<bool> actualizarUsuario(int id, Map<String, dynamic> datos) async {
    try {
      await ApiClient.put('/users/$id', datos);
      ultimoError = null;
      return true;
    } catch (e) {
      ultimoError = _detalleError(e);
      print('Error al actualizar usuario: $e');
      return false;
    }
  }

  // DELETE: Eliminar usuario
  Future<bool> eliminarUsuario(int id) async {
    try {
      await ApiClient.delete('/users/$id');
      ultimoError = null;
      return true;
    } catch (e) {
      ultimoError = _detalleError(e);
      print('Error al eliminar usuario: $e');
      return false;
    }
  }
}