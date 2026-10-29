import 'package:flutter/material.dart';

import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/usuario_service.dart';
import '../../main.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final UsuarioService _usuarioService = UsuarioService();

  List<UserModel> _usuarios = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (mounted) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }

    final data = await _usuarioService.obtenerUsuarios();
    if (!mounted) return;

    setState(() {
      _usuarios = data
          .whereType<Map>()
          .map((e) => UserModel.fromJson(Map<String, dynamic>.from(e)))
          .toList()
        ..sort((a, b) => a.id.compareTo(b.id));
      _cargando = false;
      if (data.isEmpty) {
        _error = 'No se pudieron cargar los usuarios. Verifica el backend.';
      }
    });
  }

  int get _admins => _usuarios.where((u) => u.esAdmin).length;
  int get _activos => _usuarios.where((u) => u.activo).length;

  Future<void> _cambiarRol(UserModel usuario) async {
    final nuevoRol = usuario.esAdmin ? 'USUARIO' : 'ADMINISTRADOR';
    final ok = await _usuarioService.actualizarUsuario(usuario.id, {
      'rol': nuevoRol,
    });

    if (!mounted) return;
    _mensaje(
      ok
          ? '${usuario.nombre} ahora es $nuevoRol'
          : 'No se pudo cambiar el rol',
      ok: ok,
    );
    if (ok) _cargar();
  }

  Future<void> _cambiarActivo(UserModel usuario) async {
    final nuevoEstado = !usuario.activo;
    final ok = await _usuarioService.actualizarUsuario(usuario.id, {
      'activo': nuevoEstado,
    });

    if (!mounted) return;
    _mensaje(
      ok
          ? '${usuario.nombre} ${nuevoEstado ? 'habilitado' : 'deshabilitado'}'
          : 'No se pudo actualizar el usuario',
      ok: ok,
    );
    if (ok) _cargar();
  }

  Future<void> _eliminar(UserModel usuario) async {
    if (usuario.id == AuthService.usuarioId) {
      _mensaje('No puedes eliminar tu propia cuenta desde el panel', ok: false);
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text(
          '¿Eliminar la cuenta de ${usuario.nombre}? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;
    final ok = await _usuarioService.eliminarUsuario(usuario.id);

    if (!mounted) return;
    _mensaje(
      ok ? 'Usuario eliminado' : 'No se pudo eliminar el usuario',
      ok: ok,
    );
    if (ok) _cargar();
  }

  void _mensaje(String texto, {required bool ok}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ok ? const Color(0xFF15803D) : const Color(0xFFCF3A3A),
        behavior: SnackBarBehavior.floating,
        content: Text(texto),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0B1424) : const Color(0xFFEAF3F8);
    final textPrimary = isDark ? Colors.white : brandText;
    final textSecondary = isDark ? const Color(0xFFCBD5E1) : brandMuted;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text(
          'Panel administrador',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _cargar,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: brandBlue))
          : RefreshIndicator(
              onRefresh: _cargar,
              color: brandBlue,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 30),
                children: [
                  Text(
                    'Administración de usuarios',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Gestiona roles, cuentas activas y ejercicios del sistema.',
                    style: TextStyle(color: textSecondary),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: _resumen(
                          'Usuarios',
                          '${_usuarios.length}',
                          Icons.groups_rounded,
                          brandBlue,
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _resumen(
                          'Administradores',
                          '$_admins',
                          Icons.admin_panel_settings_rounded,
                          brandTeal,
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _resumen(
                          'Activos',
                          '$_activos',
                          Icons.verified_user_rounded,
                          const Color(0xFF22C55E),
                          isDark,
                        ),
                      ),
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEDED),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Color(0xFFB42323)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ..._usuarios.map((u) => _usuarioTile(u, isDark)),
                ],
              ),
            ),
    );
  }

  Widget _resumen(
    String titulo,
    String valor,
    IconData icono,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111C2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF24364C) : const Color(0xFFDBEAF3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icono, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  valor,
                  style: TextStyle(
                    color: isDark ? Colors.white : brandNavy,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? const Color(0xFFCBD5E1) : brandMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _usuarioTile(UserModel usuario, bool isDark) {
    final card = isDark ? const Color(0xFF111C2E) : Colors.white;
    final border = isDark ? const Color(0xFF24364C) : const Color(0xFFDBEAF3);
    final esYo = usuario.id == AuthService.usuarioId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: usuario.esAdmin
                ? brandTeal.withValues(alpha: 0.2)
                : const Color(0xFFE1F2FF),
            child: Text(
              usuario.inicial,
              style: TextStyle(
                color: usuario.esAdmin ? const Color(0xFF12897B) : brandBlue,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        usuario.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark ? Colors.white : brandText,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (esYo) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: brandBlue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Tú',
                          style: TextStyle(
                            color: brandBlue,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  usuario.correo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF9FB3C8) : brandMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: usuario.esAdmin
                      ? brandTeal.withValues(alpha: 0.16)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  usuario.rol,
                  style: TextStyle(
                    color: usuario.esAdmin
                        ? const Color(0xFF0F766E)
                        : brandMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                usuario.activo ? 'Activo' : 'Deshabilitado',
                style: TextStyle(
                  color: usuario.activo
                      ? const Color(0xFF15803D)
                      : const Color(0xFFB42323),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          PopupMenuButton<String>(
            tooltip: 'Acciones',
            onSelected: (value) {
              if (value == 'rol') _cambiarRol(usuario);
              if (value == 'activo') _cambiarActivo(usuario);
              if (value == 'eliminar') _eliminar(usuario);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'rol',
                child: Text(
                  usuario.esAdmin
                      ? 'Quitar rol administrador'
                      : 'Hacer administrador',
                ),
              ),
              PopupMenuItem(
                value: 'activo',
                child: Text(
                  usuario.activo ? 'Deshabilitar cuenta' : 'Habilitar cuenta',
                ),
              ),
              if (!esYo)
                const PopupMenuItem(
                  value: 'eliminar',
                  child: Text(
                    'Eliminar usuario',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
