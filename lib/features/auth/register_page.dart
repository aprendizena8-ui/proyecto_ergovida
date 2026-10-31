import 'package:flutter/material.dart';
import '../../data/services/auth_service.dart';
import '../../widgets/ergovida_logo.dart';
import 'verificar_correo_page.dart';
import '../../main.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final nombreController = TextEditingController();
  final correoController = TextEditingController();
  final passwordController = TextEditingController();
  bool ocultarPassword = true;

  final emailValido = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  final nombreValido = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$');

  @override
  void dispose() {
    nombreController.dispose();
    correoController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> registrarUsuario() async {
    if (!_formKey.currentState!.validate()) return;

    final correo = correoController.text.trim();

    try {
      await AuthService.registrar(nombreController.text.trim(), correo, passwordController.text.trim());
      if (!mounted) return;

      final enviado = await AuthService.enviarCodigoVerificacion(correo);
      if (!mounted) return;

      if (!enviado) {
        _mostrarMensaje('Error al enviar el código de verificación', esError: true);
        return;
      }

      _mostrarMensaje('Código enviado a tu correo. Verifícalo.');
      
      // Navegamos a la pantalla de verificación sin esperar un resultado booleano
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => VerificarCorreoPage(correo: correo))
      );
    } catch (error) {
      if (!mounted) return;
      _mostrarMensaje(error.toString().replaceFirst('Exception: ', ''), esError: true);
    }
  }

  void _mostrarMensaje(String texto, {bool esError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: esError ? const Color(0xFFCF3A3A) : brandBlue,
      behavior: SnackBarBehavior.floating,
      content: Row(children: [
        Icon(esError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white),
        const SizedBox(width: 10),
        Expanded(child: Text(texto)),
      ]),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFFF5F9FD), Color(0xFFE6EFF7)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: Center(
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Container(
                  width: 500,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [BoxShadow(color: Color(0x1A0E2238), blurRadius: 24, offset: Offset(0, 18))],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const ErgoVidaLogo(width: 170),
                      const SizedBox(height: 10),
                      const Text('Crear cuenta', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: brandText)),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: nombreController,
                        decoration: const InputDecoration(labelText: 'Nombre completo', prefixIcon: Icon(Icons.person_outline)),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'El nombre es obligatorio';
                          if (!nombreValido.hasMatch(v.trim())) return 'Solo se permiten letras y espacios';
                          if (v.trim().length < 3) return 'Mínimo 3 caracteres';
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: correoController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Correo electrónico', prefixIcon: Icon(Icons.email_outlined)),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'El correo es obligatorio';
                          if (!emailValido.hasMatch(v.trim())) return 'Ingresa un correo válido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: passwordController,
                        obscureText: ocultarPassword,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(ocultarPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            onPressed: () => setState(() => ocultarPassword = !ocultarPassword),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'La contraseña es obligatoria';
                          if (v.length < 8) return 'Mínimo 8 caracteres';
                          if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Falta una mayúscula';
                          if (!RegExp(r'[0-9]').hasMatch(v)) return 'Falta un número';
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: registrarUsuario,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brandBlue,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          ),
                          child: const Text('Registrarse', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Ya tengo una cuenta', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: brandNavy)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
