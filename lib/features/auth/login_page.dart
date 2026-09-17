import 'package:flutter/material.dart';
import '../home/home_page.dart';
import 'register_page.dart';
import '../../data/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final AuthService auth = AuthService();

  final TextEditingController correoController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  final FocusNode passwordFocusNode = FocusNode();

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

  Future<void> iniciarSesion() async {
    String correo = correoController.text.trim();
    String password = passwordController.text.trim();

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
          backgroundColor: Color(0xFF455A64),

          content: Text(
            "Por favor completa todos los campos.",
          ),
        ),
      );
      return;
    }

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

    if (!mounted) return;

    setState(() {
      cargando = false;
    });

if (respuesta.success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(
            usuario: respuesta.user!,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            respuesta.message,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),

      appBar: AppBar(
        title: const Text("ErgoVida"),
        centerTitle: true,
      ),

      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(30),

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),

            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                const Icon(
                  Icons.accessibility_new,
                  size: 80,
                  color: Colors.green,
                ),

                const SizedBox(height: 15),

                const Text(
                  "Bienvenido a ErgoVida",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  "Inicia sesión para continuar",
                  style: TextStyle(
                    color: Colors.grey,
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
