import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_responsive.dart';
import '../../data/services/auth_service.dart';
import '../../main.dart';
import '../../widgets/ergovida_logo.dart';
import '../home/home_page.dart';
import 'register_page.dart';
import 'recover_password_page.dart';

class LoginPage extends StatefulWidget {
  final AppThemeController? themeController;

  const LoginPage({super.key, this.themeController});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final correoController = TextEditingController();
  final passwordController = TextEditingController();
  final passwordFocusNode = FocusNode();
  final emailValido = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  bool ocultarPassword = true;
  bool cargando = false;

  @override
  void initState() {
    super.initState();
    _cargarCorreoGuardado();
  }

  Future<void> _cargarCorreoGuardado() async {
    final prefs = await SharedPreferences.getInstance();
    final correo = prefs.getString('ultimo_correo');
    if (correo != null && mounted) {
      correoController.text = correo;
    }
  }

  @override
  void dispose() {
    correoController.dispose();
    passwordController.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> iniciarSesion() async {
    if (!_formKey.currentState!.validate()) return;

    final correo = correoController.text.trim();
    final password = passwordController.text.trim();

    setState(() => cargando = true);

    try {
      final auth = AuthService();
      final usuario = await auth.login(correo, password);

      if (!mounted) return;

      if (usuario == null) {
        setState(() => cargando = false);
        _mostrarMensaje('Correo o contraseña incorrectos', esError: true);
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ultimo_correo', correo);

      if (!mounted) return;
      setState(() => cargando = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(
            themeController: widget.themeController,
            usuario: usuario,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => cargando = false);
      _mostrarMensaje(
        error.toString().replaceFirst('Exception: ', ''),
        esError: true,
      );
    }
  }

  void _mostrarMensaje(String texto, {bool esError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: esError ? const Color(0xFFCF3A3A) : brandNavy,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Icon(
              esError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(texto)),
          ],
        ),
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
        child: Center(
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(
              context,
            ).copyWith(scrollbars: false),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: AppResponsive.gutter(context),
                vertical: 24,
              ),
              child: Form(
                key: _formKey,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(
                      AppResponsive.isMobile(context) ? 22 : 32,
                    ),
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
                        const ErgoVidaLogo(width: 170, showText: true),
                        const SizedBox(height: 10),
                        const Text(
                          'Bienvenido a ErgoVida',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: brandText,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Inicia sesión para continuar con tu bienestar laboral.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.4,
                            color: brandMuted,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: correoController,
                          enabled: !cargando,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          // 🔹 CORREGIDO AQUÍ
                          onFieldSubmitted: (_) {
                            FocusScope.of(
                              context,
                            ).requestFocus(passwordFocusNode);
                          },
                          decoration: const InputDecoration(
                            labelText: 'Correo electrónico',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'El correo es obligatorio';
                            if (!emailValido.hasMatch(v.trim()))
                              return 'Ingresa un correo válido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: passwordController,
                          focusNode: passwordFocusNode,
                          enabled: !cargando,
                          obscureText: ocultarPassword,
                          textInputAction: TextInputAction.done,

                          onFieldSubmitted: (_) {
                            if (!cargando) {
                              iniciarSesion();
                            }
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
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'La contraseña es obligatoria'
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: cargando
                                ? null
                                : () async {
                                    final correoRecuperado =
                                        await Navigator.push<String>(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const RecoverPasswordPage(),
                                          ),
                                        );
                                    if (correoRecuperado != null && mounted) {
                                      setState(() {
                                        correoController.text =
                                            correoRecuperado;
                                        passwordController.clear();
                                      });
                                      FocusScope.of(
                                        context,
                                      ).requestFocus(passwordFocusNode);
                                    }
                                  },
                            child: const Text(
                              '¿Olvidaste tu contraseña?',
                              style: TextStyle(
                                color: brandBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _BotonPrincipal(
                          cargando: cargando,
                          texto: 'Iniciar sesión',
                          icono: Icons.login_rounded,
                          onPressed: iniciarSesion,
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              '¿No tienes cuenta?',
                              style: TextStyle(fontSize: 15, color: brandMuted),
                            ),
                            TextButton(
                              onPressed: cargando
                                  ? null
                                  : () async {
                                      final correoRegistrado =
                                          await Navigator.push<String>(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const RegisterPage(),
                                            ),
                                          );
                                      if (correoRegistrado != null && mounted) {
                                        setState(() {
                                          correoController.text =
                                              correoRegistrado;
                                          passwordController.clear();
                                        });
                                        FocusScope.of(
                                          context,
                                        ).requestFocus(passwordFocusNode);
                                      }
                                    },
                              child: const Text(
                                'Regístrate',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: brandNavy,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
