import 'api_client.dart';

class UsuarioService {
  // GET: Listar todos los usuarios
  Future<List<dynamic>> obtenerUsuarios() async {
    try {
      final data = await ApiClient.get('/users');
      return data as List<dynamic>;
    } catch (e) {
      print('Error al obtener usuarios: $e');
      return [];
    }
  }

  // GET: Usuario por ID
  Future<Map<String, dynamic>?> obtenerUsuarioPorId(int id) async {
    try {
      final data = await ApiClient.get('/users/$id');
      return data as Map<String, dynamic>;
    } catch (e) {
      print('Error al obtener usuario: $e');
      return null;
    }
  }

  // PUT: Actualizar usuario
  Future<bool> actualizarUsuario(int id, Map<String, dynamic> datos) async {
    try {
      await ApiClient.put('/users/$id', datos);
      return true;
    } catch (e) {
      print('Error al actualizar usuario: $e');
      return false;
    }
  }

  // DELETE: Eliminar usuario
  Future<bool> eliminarUsuario(int id) async {
    try {
      await ApiClient.delete('/users/$id');
      return true;
    } catch (e) {
      print('Error al eliminar usuario: $e');
      return false;
    }
  }
}