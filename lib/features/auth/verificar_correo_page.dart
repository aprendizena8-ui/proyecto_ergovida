import 'package:flutter/material.dart';
import '../../data/services/auth_service.dart';
import '../../main.dart';

class VerificarCorreoPage extends StatefulWidget {
  final String correo;

  const VerificarCorreoPage({super.key, required this.correo});

  @override
  State<VerificarCorreoPage> createState() => _VerificarCorreoPageState();
}

class _VerificarCorreoPageState extends State<VerificarCorreoPage> {
  final TextEditingController _codigoCtrl = TextEditingController();
  bool _cargando = false;

  @override
  void dispose() {
    _codigoCtrl.dispose();
    super.dispose();
  }

  Future<void> _verificar() async {
    final codigo = _codigoCtrl.text.trim();
    if (codigo.length != 6) return;

    setState(() => _cargando = true);
    final ok = await AuthService.verificarCodigo(widget.correo, codigo);
    if (!mounted) return;
    setState(() => _cargando = false);

    if (ok) {
      // Mostramos mensaje y cerramos retornando true
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: brandBlue, content: Text('✅ Correo verificado. Ya puedes iniciar sesión.')));
      Navigator.pop(context, true); 
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Color(0xFFCF3A3A), content: Text('Código incorrecto o expirado')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificar correo'),
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
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A0E2238),
                  blurRadius: 30,
                  offset: Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mark_email_read_rounded,
                    size: 80, color: brandBlue),
                const SizedBox(height: 16),
                const Text(
                  'Verifica tu correo',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: brandText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hemos enviado un código de 6 dígitos a:\n${widget.correo}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: brandMuted),
                ),
                const SizedBox(height: 26),
                TextField(
                  controller: _codigoCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    letterSpacing: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    counterText: '',
                    hintText: '000000',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _cargando ? null : _verificar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: _cargando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Verificar código',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
