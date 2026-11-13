import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/services/solicitud_ayuda_service.dart';
import '../../widgets/design_system.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final _formKey = GlobalKey<FormState>();
  final _asuntoController = TextEditingController();
  final _descripcionController = TextEditingController();

  bool _enviando = false;
  List<dynamic> _solicitudes = const [];

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  @override
  void dispose() {
    _asuntoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _cargarHistorial() async {
    try {
      final data = await SolicitudAyudaService.misSolicitudes();
      if (!mounted) return;
      setState(() => _solicitudes = data);
    } catch (_) {
      if (!mounted) return;
      setState(() => _solicitudes = const []);
    }
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _enviando = true);

    try {
      final respuesta = await SolicitudAyudaService.enviar(
        asunto: _asuntoController.text.trim(),
        descripcion: _descripcionController.text.trim(),
      );

      if (!mounted) return;

      final correoEnviado = respuesta['correoEnviado'] == true;
      final mensaje = respuesta['mensaje']?.toString() ??
          'Tu solicitud fue enviada al equipo administrador.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppPalette.success,
          content: Text(
            correoEnviado
                ? mensaje
                : '$mensaje El correo se enviara cuando el servidor '
                    'tenga el servicio de correo configurado.',
          ),
        ),
      );

      _asuntoController.clear();
      _descripcionController.clear();
      await _cargarHistorial();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppPalette.danger,
          content: Text('No se pudo enviar la solicitud: $error'),
        ),
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppPalette.darkBackground : AppPalette.background;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Ayuda y soporte'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [Color(0xFF08111F), Color(0xFF0C1A2B)]
                : const [Color(0xFFEAF2F9), AppPalette.background],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
          children: [
            AppSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const IconBadge(
                        icon: Icons.support_agent_rounded,
                        color: AppPalette.blue,
                        size: 48,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cuentanos que necesitas',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : AppPalette.text,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Tu solicitud llegara al equipo administrador '
                              'y quedara registrada.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _asuntoController,
                          maxLength: 150,
                          decoration: const InputDecoration(
                            labelText: 'Asunto',
                            hintText: 'Ej: No recibo mis recordatorios',
                            prefixIcon: Icon(Icons.subject_rounded),
                            border: OutlineInputBorder(),
                          ),
                          validator: (valor) {
                            final texto = valor?.trim() ?? '';
                            if (texto.isEmpty) {
                              return 'Escribe un asunto.';
                            }
                            if (texto.length < 4) {
                              return 'El asunto es demasiado corto.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descripcionController,
                          maxLines: 6,
                          maxLength: 5000,
                          decoration: const InputDecoration(
                            labelText: 'Describe el problema',
                            hintText:
                                'Incluye que estabas haciendo, que esperabas '
                                'y que ocurrio.',
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(),
                          ),
                          validator: (valor) {
                            final texto = valor?.trim() ?? '';
                            if (texto.isEmpty) {
                              return 'Describe el problema.';
                            }
                            if (texto.length < 15) {
                              return 'Agrega un poco mas de detalle.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        GradientButton(
                          label: _enviando
                              ? 'Enviando solicitud...'
                              : 'Enviar solicitud',
                          icon: Icons.send_rounded,
                          onPressed: _enviando ? null : _enviar,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_solicitudes.isNotEmpty) ...[
              const SizedBox(height: 20),
              const SectionHeader(title: 'Mis solicitudes'),
              const SizedBox(height: 10),
              AppSurface(
                child: Column(
                  children: [
                    for (var i = 0; i < _solicitudes.length; i++) ...[
                      _solicitudTile(_solicitudes[i], isDark),
                      if (i != _solicitudes.length - 1)
                        const AppDivider(vertical: 8),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _solicitudTile(dynamic solicitud, bool isDark) {
    final asunto = solicitud['asunto']?.toString() ?? 'Solicitud';
    final estado =
        (solicitud['estado']?.toString() ?? 'PENDIENTE').toUpperCase();
    final pendiente = estado == 'PENDIENTE';
    final fecha = _fechaCorta(solicitud['fechaCreacion']?.toString() ?? '');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: IconBadge(
        icon: pendiente
            ? Icons.hourglass_top_rounded
            : Icons.task_alt_rounded,
        color: pendiente ? AppPalette.warning : AppPalette.success,
        size: 42,
      ),
      title: Text(
        asunto,
        style: TextStyle(
          color: isDark ? Colors.white : AppPalette.text,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        fecha.isEmpty
            ? estado
            : '$fecha · ${pendiente ? 'Pendiente' : 'Resuelta'}',
      ),
      trailing: AppPill(
        text: pendiente ? 'Pendiente' : 'Resuelta',
        color: pendiente ? AppPalette.warning : AppPalette.success,
      ),
    );
  }

  String _fechaCorta(String iso) {
    if (iso.isEmpty) return '';
    final fecha = DateTime.tryParse(iso)?.toLocal();
    if (fecha == null) return iso;
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year} $hora:$minuto';
  }
}
