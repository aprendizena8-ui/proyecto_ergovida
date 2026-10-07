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
main
  final TextEditingController correoController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final AuthService auth = AuthService();

  final TextEditingController correoController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  final FocusNode passwordFocusNode = FocusNode();

 develop
  bool ocultarPassword = true;

  bool cargando = false;

  String? errorCorreo;
  String? errorPassword;

  @override
  void dispose() {
    correoController.dispose();
    passwordController.dispose();

    passwordFocusNode.dispose();

    super.dispose();
  }

main
  void iniciarSesion() {
    final correo = correoController.text.trim();
    final password = passwordController.text.trim();

  Future<void> iniciarSesion() async {
    String correo = correoController.text.trim();
    String password = passwordController.text.trim();
develop

    setState(() {
      errorCorreo = null;
      errorPassword = null;
    });

    if (correo.isEmpty && password.isEmpty) {

      setState(() {
        errorCorreo = "Este campo es obligatorio";
        errorPassword = "Este campo es obligatorio";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
 main
          backgroundColor: Color(0xFF0E2238),
          content: Text('Por favor completa todos los campos'),
          backgroundColor: Color(0xFF455A64),

          content: Text(
            "Por favor completa todos los campos.",
          ),
develop
        ),
      );
      return;
    }

main
    final auth = AuthService();
    final acceso = auth.login(correo, password);
    if (correo.isEmpty) {

      setState(() {
        errorCorreo = "Este campo es obligatorio";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(

          backgroundColor: Color(0xFF455A64),

          content: Text(

            "Ingresa tu correo electrónico.",
          ),
        ),
      );
      return;
    }

    if (password.isEmpty) {

      setState(() {
        errorPassword = "Este campo es obligatorio";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(

          backgroundColor: Color(0xFF455A64),

          content: Text(
            "Ingresa tu contraseña.",
          ),
        ),
      );
      return;
    }

    // final auth = AuthService();

    setState(() {
      cargando = true;
    });

    // await Future.delayed(
    //   const Duration(seconds: 3),
    // );

    final respuesta = await auth.login(
      correo,
      password,
    );
develop

    if (!mounted) return;

    setState(() {
      cargando = false;
    });

if (respuesta.success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
main
          builder: (context) => HomePage(themeController: widget.themeController),
          builder: (context) => HomePage(
            usuario: respuesta.user!,
          ),
develop
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
main
        const SnackBar(
          backgroundColor: Color(0xFFCF3A3A),
          content: Text('Correo o contraseña incorrectos'),

        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            respuesta.message,
          ),
develop
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F9FD), Color(0xFFE6EFF7)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: 460,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A0E2238),
                    blurRadius: 24,
                    offset: Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ErgoVidaLogo(size: 118, showText: false),
                  const SizedBox(height: 18),
                  const Text(
                    'Bienvenido a ErgoVida',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF10243A),
                    ),
                  ),
main
                  const SizedBox(height: 8),
                  const Text(
                    'Inicia sesión para continuar con tu bienestar laboral.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF5E7387),
                    ),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: correoController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: passwordController,
                    obscureText: ocultarPassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          ocultarPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(() => ocultarPassword = !ocultarPassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text(
                        '¿Olvidaste tu contraseña?',
                        style: TextStyle(color: Color(0xFF1F7FC0)),
                      ),
                ),

                const SizedBox(height: 30),

                TextField(
                  enabled: !cargando,
                  controller: correoController,

                  textInputAction: TextInputAction.next,

                  onSubmitted: (_) {
                    FocusScope.of(context).requestFocus(passwordFocusNode);
                  },

                  onChanged: (value) {
                    final emailValido = RegExp(
                      r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$',
                    );

                    setState(() {
                      if (value.trim().isEmpty) {
                        errorCorreo = "Este campo es obligatorio";
                      } else if (!emailValido.hasMatch(value.trim())) {
                        errorCorreo =
                            "Ingresa un correo electrónico válido.";
                      } else {
                        errorCorreo = null;
                      }
                    });
                  },

                  decoration: InputDecoration(
                    labelText: "Correo electrónico",

                    prefixIcon: const Icon(Icons.email),

                    errorText: errorCorreo,

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.green,
                        width: 2,
                      ),
                    ),

                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 2,
                      ),
                    ),

                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                TextField(
                  enabled: !cargando,
                  controller: passwordController,

                  focusNode: passwordFocusNode,

                  obscureText: ocultarPassword,

                  textInputAction: TextInputAction.done,

                  onSubmitted: (_) {
                    if (!cargando) {
                      iniciarSesion();
                    }
                  },

                  onChanged: (value) {
                    setState(() {
                      if (value.isEmpty) {
                        errorPassword = "Este campo es obligatorio";

                      } else {
                        errorPassword = null;
                      }
                    });
                  },

                  decoration: InputDecoration(
                    labelText: "Contraseña",
                    prefixIcon: const Icon(Icons.lock),

                    errorText: errorPassword,

                    suffixIcon: IconButton(
                      icon: Icon(
                        ocultarPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      // onPressed: () {
                      onPressed: cargando
                          ? null
                          : () {
                              setState(() {
                                ocultarPassword =
                                    !ocultarPassword;
                              });
                            },
                    ),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.green,
                        width: 2,
                      ),
                    ),

                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 2,
                      ),
                    ),

                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                  
                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  height: 50,

                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cargando
                          ? Colors.grey.shade300
                          : Colors.green,
                      foregroundColor: Colors.white,
develop
                    ),
                    
                    onPressed: cargando ? null : iniciarSesion,

                    child: cargando

                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [

                              SizedBox(
                                width: 22,
                                height: 22,

                                child: CircularProgressIndicator(
                                  strokeWidth: 3,

                                  valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF2E7D32),
                                  ),
                                ),
                              ),

                              SizedBox(width: 15),

                              Text(
                                "Ingresando...",
                                style: TextStyle(

                                  color: Colors.black87,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                          

                        : const Text(
                            "Iniciar Sesión",
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                  ),
main
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1F7FC0), Color(0xFF2DD4BF)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x332DD4BF),
                            blurRadius: 12,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: iniciarSesion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        child: const Text(
                          'Iniciar sesión',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: const [
                      Expanded(child: Divider(color: Color(0xFFDCE7F2))),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'o',
                          style: TextStyle(color: Color(0xFF5E7387)),
                        ),
                      ),
                      Expanded(child: Divider(color: Color(0xFFDCE7F2))),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterPage()),
                      );
                    },
                    child: const Text(
                      'Crear cuenta nueva',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0E2238),
                      ),
                    ),
                ),

                const SizedBox(height: 15),

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

                    if (correoRegistrado != null) {

                      setState(() {
                        correoController.text = correoRegistrado;
                        passwordController.clear();

                        errorCorreo = null;
                        errorPassword = null;
                      });

                      FocusScope.of(context).requestFocus(passwordFocusNode);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Colors.green,
                          content: Text(
                            "Cuenta creada correctamente. Ahora inicia sesión.",
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    "¿No tienes cuenta? Regístrate",
develop
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
