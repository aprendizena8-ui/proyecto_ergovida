import 'package:flutter/material.dart';
import 'verificar_correo_page.dart';
import 'change_password_page.dart';
import '../../data/services/auth_service.dart';
import '../../main.dart';

class RecoverPasswordPage extends StatefulWidget {
  const RecoverPasswordPage({super.key});
  @override
  State<RecoverPasswordPage> createState() => _RecoverPasswordPageState();
}

class _RecoverPasswordPageState extends State<RecoverPasswordPage> {
  final correoController = TextEditingController();
  bool cargando = false;

  Future<void> _enviarEnlace() async {
    final correo = correoController.text.trim();
    if (correo.isEmpty || !correo.contains('@')) return;

    setState(() => cargando = true);
    final enviado = await AuthService.enviarCodigoVerificacion(correo);
    if (!mounted) return;
    setState(() => cargando = false);

    if (enviado) {
      final verificado = await Navigator.push<bool>(context, MaterialPageRoute(
        builder: (context) => VerificarCorreoPage(correo: correo),
      ));
      
      // Si verificó el código, va a cambiar la contraseña
      if (verificado == true && mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (context) => ChangePasswordPage(correo: correo),
        ));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Color(0xFFCF3A3A), content: Text('Error al enviar el código')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar contraseña'),
        backgroundColor: brandNavy,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 460,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A0E2238),
                  blurRadius: 40,
                  offset: Offset(0, 22),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_reset_rounded,
                    size: 80, color: brandBlue),
                const SizedBox(height: 16),
                const Text(
                  '¿Olvidaste tu contraseña?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: brandText,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ingresa tu correo y te enviaremos un enlace para restablecerla.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: brandMuted),
                ),
                const SizedBox(height: 26),
                TextField(
                  controller: correoController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _enviarEnlace,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Enviar enlace',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
