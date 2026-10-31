import 'package:flutter/material.dart';
import '../../data/services/auth_service.dart';
import '../../main.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../data/services/api_client.dart';

class ChangePasswordPage extends StatefulWidget {
  final String correo;
  const ChangePasswordPage({super.key, required this.correo});
  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final passwordCtrl = TextEditingController();
  bool ocultar = true;
  bool cargando = false;

  Future<void> _cambiarPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => cargando = true);

    try {
      final res = await http.post(
        Uri.parse('${ApiClient.baseUrl}/auth/cambiar-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'correo': widget.correo, 'nuevaPassword': passwordCtrl.text.trim()}),
      );

      print("Status: ${res.statusCode}");
      print("Body: ${res.body}");

      if (!mounted) return;
      setState(() => cargando = false);

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: brandBlue, content: Text('Contraseña actualizada. Inicia sesión.')));
        Navigator.pop(context, widget.correo); // Devuelve el correo al login
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Color(0xFFCF3A3A), content: Text('Error al actualizar contraseña')));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Color(0xFFCF3A3A), content: Text('Error de conexión')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva contraseña'), backgroundColor: brandNavy, foregroundColor: Colors.white),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Container(
              width: 460,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: const [BoxShadow(color: Color(0x1A0E2238), blurRadius: 30, offset: Offset(0, 15))]),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_reset_rounded, size: 80, color: brandBlue),
                  const SizedBox(height: 16),
                  const Text('Crea una nueva contraseña', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: passwordCtrl,
                    obscureText: ocultar,
                    decoration: InputDecoration(
                      labelText: 'Nueva contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(icon: Icon(ocultar ? Icons.visibility_outlined : Icons.visibility_off_outlined), onPressed: () => setState(() => ocultar = !ocultar)),
                    ),
                    validator: (v) {
                      if (v == null || v.length < 8) return 'Mínimo 8 caracteres';
                      if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Falta una mayúscula';
                      if (!RegExp(r'[0-9]').hasMatch(v)) return 'Falta un número';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: cargando ? null : _cambiarPassword,
                      style: ElevatedButton.styleFrom(backgroundColor: brandBlue, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                      child: cargando ? const CircularProgressIndicator(color: Colors.white) : const Text('Actualizar contraseña'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}