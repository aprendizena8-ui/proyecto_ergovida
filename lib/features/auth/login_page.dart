import 'package:flutter/material.dart';

import '../../data/services/auth_service.dart';
import '../../main.dart';
import '../../widgets/ergovida_logo.dart';
import '../home/home_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  final AppThemeController? themeController;

  const LoginPage({super.key, this.themeController});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController correoController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode passwordFocusNode = FocusNode();

  bool ocultarPassword = true;
  bool cargando = false;
  bool accesoAdmin = false;

  @override
  void dispose() {
    correoController.dispose();
    passwordController.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> iniciarSesion({bool admin = false}) async {
    final correo = correoController.text.trim();
    final password = passwordController.text.trim();

    if (correo.isEmpty || password.isEmpty) {
      _mostrarMensaje('Por favor completa todos los campos', esError: true);
      return;
    }

    setState(() => cargando = true);

    try {
      final auth = AuthService();
      final usuario = await auth.login(correo, password);

      if (!mounted) return;

      if (usuario == null) {
        setState(() => cargando = false);
        _mostrarMensaje(
          'Correo o contraseña incorrectos',
          esError: true,
        );
        return;
      }

      if (admin && !usuario.esAdmin) {
        await AuthService.clearSession();
        if (!mounted) return;
        setState(() => cargando = false);
        _mostrarMensaje(
          'Esta cuenta no tiene permisos de administrador',
          esError: true,
        );
        return;
      }

      if (!mounted) return;
      setState(() {
        cargando = false;
        accesoAdmin = admin;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(
            themeController: widget.themeController,
            usuario: usuario,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => cargando = false);
      _mostrarMensaje(
        'No se pudo conectar con el backend local',
        esError: true,
      );
    }
  }

  void _mostrarMensaje(String texto, {bool esError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: esError ? const Color(0xFFCF3A3A) : brandNavy,
        behavior: SnackBarBehavior.floating,
        content: Text(texto),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F9FD), Color(0xFFE2EEF8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -120,
              right: -80,
              child: _glow(const Color(0x332DD4BF), 320),
            ),
            Positioned(
              bottom: -140,
              left: -100,
              child: _glow(const Color(0x331F7FC0), 360),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  width: 460,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFFE2ECF5)),
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
                      const ErgoVidaLogo(size: 104, showText: false),
                      const SizedBox(height: 18),
                      const Text(
                        'Bienvenido a ErgoVida',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: brandText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        accesoAdmin
                            ? 'Acceso administrativo. Ingresa tu cuenta con rol ADMINISTRADOR.'
                            : 'Inicia sesión para continuar con tu bienestar laboral.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          color: brandMuted,
                        ),
                      ),
                      const SizedBox(height: 26),
                      TextField(
                        controller: correoController,
                        enabled: !cargando,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(passwordFocusNode),
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        focusNode: passwordFocusNode,
                        enabled: !cargando,
                        obscureText: ocultarPassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) {
                          if (!cargando) iniciarSesion(admin: accesoAdmin);
                        },
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              ocultarPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: cargando
                                ? null
                                : () => setState(
                                    () => ocultarPassword = !ocultarPassword,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text(
                            '¿Olvidaste tu contraseña?',
                            style: TextStyle(color: brandBlue),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _BotonPrincipal(
                        cargando: cargando,
                        texto: accesoAdmin
                            ? 'Entrar como administrador'
                            : 'Iniciar sesión',
                        icono: accesoAdmin
                            ? Icons.admin_panel_settings_rounded
                            : Icons.login_rounded,
                        onPressed: () => iniciarSesion(admin: accesoAdmin),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: cargando
                              ? null
                              : () => setState(() => accesoAdmin = true),
                          icon: const Icon(Icons.security_rounded, size: 19),
                          label: const Text('Iniciar sesión como administrador'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: brandNavy,
                            side: const BorderSide(color: Color(0xFFC9D9E8)),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                      if (accesoAdmin) ...[
                        const SizedBox(height: 6),
                        TextButton.icon(
                          onPressed: cargando
                              ? null
                              : () => setState(() => accesoAdmin = false),
                          icon: const Icon(Icons.person_outline, size: 18),
                          label: const Text('Volver al acceso normal'),
                          style: TextButton.styleFrom(
                            foregroundColor: brandMuted,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Row(
                        children: const [
                          Expanded(child: Divider(color: Color(0xFFDCE7F2))),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'o',
                              style: TextStyle(color: brandMuted),
                            ),
                          ),
                          Expanded(child: Divider(color: Color(0xFFDCE7F2))),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextButton(
                        onPressed: cargando
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const RegisterPage(),
                                  ),
                                );
                              },
                        child: const Text(
                          'Crear cuenta nueva',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: brandNavy,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glow(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

class _BotonPrincipal extends StatelessWidget {
  final bool cargando;
  final String texto;
  final IconData icono;
  final VoidCallback onPressed;

  const _BotonPrincipal({
    required this.cargando,
    required this.texto,
    required this.icono,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [brandBlue, brandTeal],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x332DD4BF),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: cargando ? null : onPressed,
          icon: cargando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
              : Icon(icono, size: 20),
          label: Text(cargando ? 'Ingresando...' : texto),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
      ),
    );
  }
}
