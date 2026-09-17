import 'package:flutter/material.dart';
import '../../data/services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {

  final AuthService auth = AuthService();

  final TextEditingController nombreController =
      TextEditingController();

  final TextEditingController correoController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  final FocusNode correoFocusNode = FocusNode();

  final FocusNode passwordFocusNode = FocusNode();

  bool ocultarPassword = true;

  bool cargando = false;

  String? errorNombre;
  String? errorCorreo;
  String? errorPassword;

  final emailValido = RegExp(
    r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$',
  );

  final nombreValido = RegExp(
  r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ]+(?: [a-zA-ZáéíóúÁÉÍÓÚñÑ]+)*$',
  );

  String capitalizarNombre(String texto) {

  return texto
      .toLowerCase()
      .split(' ')
      .map((palabra) {

        if (palabra.isEmpty) {
          return palabra;
        }

        return palabra[0].toUpperCase() +
            palabra.substring(1);

      })
      .join(' ');
  }

  String? validarPassword(String password) {
  final errores = <String>[];

  if (password.length < 8) {
    errores.add("mínimo 8 caracteres");
  }

  if (!RegExp(r'[A-Z]').hasMatch(password)) {
    errores.add("una mayúscula");
  }

  if (!RegExp(r'[a-z]').hasMatch(password)) {
    errores.add("una minúscula");
  }

  if (!RegExp(r'\d').hasMatch(password)) {
    errores.add("un número");
  }

  if (errores.isEmpty) {
    return null;
  }

  return "Falta: ${errores.join(", ")}.";
}

  @override
  void dispose() {
    nombreController.dispose();
    correoController.dispose();
    passwordController.dispose();

    correoFocusNode.dispose();
    passwordFocusNode.dispose();

    super.dispose();
  }

  Future<void> registrarUsuario() async {

    FocusScope.of(context).unfocus();

    if (cargando) return;

    // final nombre = nombreController.text.trim();
    // final nombre =
    final nombre = capitalizarNombre(
        nombreController.text
        .trim()
        .replaceAll(RegExp(r'\s+'), ' '),
    );

    // final correo = correoController.text.trim();
    final correo =
        correoController.text
        .trim()
        .toLowerCase();

    final password =
        passwordController.text.trim();

    setState(() {
      errorNombre = null;
      errorCorreo = null;
      errorPassword = null;
    });

    if (nombre.isEmpty ||
        correo.isEmpty ||
        password.isEmpty) {

      setState(() {
        if (nombre.isEmpty) {
          errorNombre = "Este campo es obligatorio";
        }

        if (correo.isEmpty) {
          errorCorreo = "Este campo es obligatorio";
        }

        if (password.isEmpty) {
          errorPassword = "Este campo es obligatorio";
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF455A64),
          content: Text(
            "Por favor completa todos los campos",
          ),
        ),
      );
      return;
    }

    if (!nombreValido.hasMatch(nombre)) {

        setState(() {
          errorNombre = "Solo se permiten letras y espacios.";
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF455A64),
            content: Text(
              "Solo se permiten letras y espacios.",
            ),
          ),
        );

        return;
    }

    if (nombre.length < 3) {

      setState(() {
        errorNombre =
            "El nombre debe tener mínimo 3 caracteres.";
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF455A64),
          content: Text(
            "El nombre debe tener mínimo 3 caracteres.",
          ),
        ),
      );

      return;
    }

    if (!emailValido.hasMatch(correo)) {

      setState(() {
        errorCorreo = "Ingresa un correo electrónico válido.";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF455A64),
          content: Text(
            "Ingresa un correo electrónico válido",
          ),
        ),
      );
      return;
    }

    final errorValidacionPassword =
        validarPassword(password);

    if (errorValidacionPassword != null) {
      setState(() {
        errorPassword = errorValidacionPassword;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF455A64),
          content: Text(
            errorValidacionPassword,
          ),
        ),
      );

      return;
    }

    // final auth = AuthService();

    setState(() {
      cargando = true;
    });

    final respuesta = await auth.registrar(
      nombre,
      correo,
      password,
    );

    if (respuesta.success) {

      nombreController.clear();
      correoController.clear();
      passwordController.clear();

      // if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            "Usuario registrado correctamente.",
          ),
          // duration: Duration(seconds: 2),
          duration: Duration(seconds: 1),
        ),
      );

      // Navigator.pop(
      //   context,
      //   correo,
      // );

      await Future.delayed(
        // const Duration(milliseconds: 800),
        const Duration(seconds: 1),
      );

      if (!mounted) return;

      Navigator.pop(
        context,
        correo
      );
      
    } else {

      setState(() {
        cargando = false;
      });

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

    return PopScope(
      canPop: !cargando,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FA),

        appBar: AppBar(
          title: const Text("Registro ErgoVida"),
          centerTitle: true,
        ),

      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(35),

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),

            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                const Icon(
                  Icons.person_add_alt_1,
                  size: 90,
                  color: Colors.green,
                ),

                const SizedBox(height: 20),

                const Text(
                  "Crear Cuenta",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  "Regístrate para comenzar a utilizar ErgoVida",
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 30),

                TextField(
                  enabled: !cargando,
                  controller: nombreController,

                  textCapitalization: TextCapitalization.words,

                  autofillHints: const [
                    AutofillHints.name,
                  ],

                  maxLength: 80,

                  textInputAction: TextInputAction.next,

                  onSubmitted: (_) {
                    FocusScope.of(context).requestFocus(correoFocusNode);
                  },

                  onChanged: (value) {

                    String texto = value;

                    // Elimina espacios al inicio
                    texto = texto.trimLeft();

                    // Reemplaza varios espacios por uno solo
                    texto = texto.replaceAll(RegExp(r'\s+'), ' ');

                    // Capitaliza el nombre
                    texto = capitalizarNombre(texto);

                    // if (value.startsWith(" ")) {
                    //   nombreController.text = value.trimLeft();

                    //   nombreController.selection = TextSelection.fromPosition(
                    //     TextPosition(offset: nombreController.text.length),
                    //   );
                    // }

                    if (texto != value) {
                      nombreController.value = TextEditingValue(
                        text: texto,
                        selection: TextSelection.collapsed(
                          offset: texto.length,
                        ),
                      );
                    }

                    setState(() {
                      // if (value.trim().isEmpty) {
                      if (nombreController.text.trim().isEmpty) {
                        errorNombre = "Este campo es obligatorio";
                      // } else if (value.trim().length < 3) {
                      } else if (!nombreValido.hasMatch(nombreController.text.trim())) {
                        errorNombre = "Solo se permiten letras y espacios.";
                      } else if (nombreController.text.trim().length < 3) {
                        errorNombre = "El nombre debe tener mínimo 3 caracteres.";
                      } else {
                        errorNombre = null;
                      }
                    });
                  },

                  decoration: InputDecoration(

                    counterText: "",

                    labelText: "Nombre completo",
                    prefixIcon: const Icon(Icons.person),

                    errorText: errorNombre,

                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),
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
                  controller: correoController,

                  focusNode: correoFocusNode,

                  autofillHints: const [
                    AutofillHints.email,
                  ],

                  maxLength: 100,

                  keyboardType:
                      TextInputType.emailAddress,

                  textInputAction: TextInputAction.next,

                  onSubmitted: (_) {
                    FocusScope.of(context).requestFocus(passwordFocusNode);
                  },

                  onChanged: (value) {

                    // if (value.contains(" ")) {
                    if (RegExp(r'\s').hasMatch(value)) {
                      // correoController.text = value.replaceAll(" ", "");
                      correoController.text =
                          value.replaceAll(RegExp(r'\s+'), '');

                      correoController.selection =
                          TextSelection.fromPosition(
                        TextPosition(offset: correoController.text.length),
                      );
                    }

                    setState(() {

                      // if (value.trim().isEmpty) {
                      if (correoController.text.isEmpty) {
                        errorCorreo = "Este campo es obligatorio";
                      // } else if (!emailValido.hasMatch(value.trim())) {
                      } else if (!emailValido.hasMatch(correoController.text)) {
                        errorCorreo = "Ingresa un correo electrónico válido.";
                      } else {
                        errorCorreo = null;
                      }

                    });
                    
                  },

                  decoration: InputDecoration(

                    counterText: "",

                    labelText: "Correo electrónico",
                    prefixIcon: const Icon(Icons.email),

                    errorText: errorCorreo,

                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                TextField(
                  enabled: !cargando,
                  controller: passwordController,

                  focusNode: passwordFocusNode,

                  autofillHints: const [
                    AutofillHints.newPassword,
                  ],

                  maxLength: 50,

                  enableInteractiveSelection: false,
                  
                  obscureText: ocultarPassword,

                  onChanged: (value) {

                    if (value.startsWith(" ")) {
                      passwordController.text = value.trimLeft();

                      passwordController.selection =
                          TextSelection.fromPosition(
                        TextPosition(
                          offset: passwordController.text.length,
                        ),
                      );
                    }

                    setState(() {
                      if (value.isEmpty) {
                        errorPassword = "Este campo es obligatorio";
                      } else {
                        errorPassword = validarPassword(value);
                      }
                    });
                  },

                  textInputAction: TextInputAction.done,

                  onSubmitted: (_) {
                    if (!cargando) {
                      registrarUsuario();
                    }
                  },

                  decoration: InputDecoration(

                    counterText: "",

                    labelText: "Contraseña",
                    prefixIcon: const Icon(Icons.lock),

                    errorText: errorPassword,

                    suffixIcon: IconButton(
                      icon: Icon(
                        ocultarPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),

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
                      borderRadius:
                          BorderRadius.circular(12),
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
                
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(

                    onPressed: cargando ? null : registrarUsuario,

                    style: ElevatedButton.styleFrom(

                      backgroundColor:
                          cargando ? Colors.grey.shade300 : Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                    ),

                    child: cargando
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [

                              SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(
                                    Color(0xFF2E7D32),
                                  ),
                                ),
                              ),

                              SizedBox(width: 15),

                              Text(
                                "Registrando...",
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )

                        : const Text(
                            "Registrarse",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 15),

                TextButton(

                  onPressed: cargando
                      ? null
                      : () {
                          Navigator.pop(context);
                        },
                  child: const Text(
                    "Ya tengo una cuenta",
                    style: TextStyle(
                      fontSize: 16,
                      ),
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