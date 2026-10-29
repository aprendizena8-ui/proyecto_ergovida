import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/usuario_service.dart';

class ProfilePage extends StatefulWidget {
  final UserModel usuario;

  const ProfilePage({super.key, required this.usuario});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UsuarioService _usuarioService = UsuarioService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nombreCtrl;
  late TextEditingController _correoCtrl;

  bool _guardando = false;
  bool _eliminando = false;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.usuario.nombre);
    _correoCtrl = TextEditingController(text: widget.usuario.correo);
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _correoCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    final ok = await _usuarioService.actualizarUsuario(widget.usuario.id, {
      'nombre': _nombreCtrl.text.trim(),
      'correo': _correoCtrl.text.trim(),
    });

    if (ok) {
      await AuthService.actualizarUsuarioActual(
        widget.usuario.copyWith(
          nombre: _nombreCtrl.text.trim(),
          correo: _correoCtrl.text.trim(),
        ),
      );
    }

    if (!mounted) return;
    setState(() => _guardando = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ok ? Colors.green : Colors.red,
        content: Text(
          ok
              ? 'Perfil actualizado correctamente'
              : 'Error al actualizar el perfil',
        ),
      ),
    );
  }

  Future<void> _eliminarCuenta() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: const Text(
          '¿Estás seguro? Esta acción eliminará tu cuenta y todos tus datos. No se puede deshacer.',
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
    setState(() => _eliminando = true);

    final ok = await _usuarioService.eliminarUsuario(widget.usuario.id);

    if (!mounted) return;
    setState(() => _eliminando = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Cuenta eliminada'),
        ),
      );
      // Vuelve al login
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Error al eliminar la cuenta'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.green.shade100,
                child: Text(
                  widget.usuario.nombre.isNotEmpty
                      ? widget.usuario.nombre[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            TextFormField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre completo',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _correoCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Campo obligatorio';
                if (!v.contains('@')) return 'Correo inválido';
                return null;
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.badge, color: Colors.grey),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Rol', style: TextStyle(color: Colors.grey)),
                      Text(
                        widget.usuario.rol,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _guardando ? null : _guardar,
                icon: _guardando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_guardando ? 'Guardando...' : 'Guardar cambios'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 20),
            const Text(
              'Zona peligrosa',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _eliminando ? null : _eliminarCuenta,
                icon: _eliminando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.red,
                        ),
                      )
                    : const Icon(Icons.delete_forever, color: Colors.red),
                label: Text(
                  _eliminando ? 'Eliminando...' : 'Eliminar mi cuenta',
                  style: const TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Botón temporal para convertir admin (ELIMINAR EN PRODUCCIÓN)
            TextButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final confirmar = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Modo desarrollo'),
                    content: const Text(
                      '¿Convertir este usuario en ADMINISTRADOR?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Sí'),
                      ),
                    ],
                  ),
                );
                if (confirmar == true) {
                  final ok = await _usuarioService.actualizarUsuario(
                    widget.usuario.id,
                    {'rol': 'ADMINISTRADOR'},
                  );
                  if (ok) {
                    await AuthService.actualizarUsuarioActual(
                      widget.usuario.copyWith(rol: 'ADMINISTRADOR'),
                    );
                  }
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      backgroundColor: ok ? Colors.orange : Colors.red,
                      content: Text(
                        ok
                            ? 'Usuario convertido en ADMIN. Ya puedes usar el panel de administración.'
                            : 'No se pudo convertir el usuario en ADMIN.',
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(
                Icons.admin_panel_settings,
                color: Colors.orange,
                size: 18,
              ),
              label: const Text(
                'Convertir en ADMIN (dev)',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
