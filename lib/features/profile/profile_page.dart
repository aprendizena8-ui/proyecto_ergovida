import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/estadisticas_service.dart';
import '../../data/services/pausa_service.dart';
import '../../data/services/profile_preferences.dart';
import '../../data/services/reminder_service.dart';
import '../../data/services/usuario_service.dart';
import '../../main.dart';
import '../../widgets/user_avatar.dart';
import '../auth/login_page.dart';
import '../settings/settings_page.dart';

class ProfilePage extends StatefulWidget {
  final UserModel usuario;

  const ProfilePage({super.key, required this.usuario});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UsuarioService _usuarioService = UsuarioService();
  final EstadisticasService _estadisticasService = EstadisticasService();
  final PausaService _pausaService = PausaService();
  final ImagePicker _imagePicker = ImagePicker();

  late UserModel _usuario;
  ProfileData _perfil = ProfileData.empty();

  bool _cargando = true;
  bool _guardando = false;
  bool _eliminando = false;
  bool _subiendoFoto = false;
  bool _cambiandoPassword = false;

  int _totalPausas = 0;
  int _pausasCompletadas = 0;
  int _minutos = 0;
  int _pausasSemana = 0;
  int _racha = 0;

  @override
  void initState() {
    super.initState();
    _usuario = widget.usuario;
    _cargar();
  }

  Future<void> _cargar() async {
    if (mounted) setState(() => _cargando = true);

    final id = _usuario.id;
    final perfilFuturo = ProfilePreferences.load(id);
    final usuarioFuturo = id > 0
        ? _usuarioService.obtenerUsuarioPorId(id)
        : Future<Map<String, dynamic>?>.value(null);
    final estadisticasFuturo = id > 0
        ? _estadisticasService.obtenerPorUsuario(id)
        : Future<List<dynamic>>.value(const []);
    final pausasFuturo = id > 0
        ? _pausaService.obtenerPorUsuario(id)
        : Future<List<dynamic>>.value(const []);

    final resultados = await Future.wait<dynamic>([
      perfilFuturo,
      usuarioFuturo,
      estadisticasFuturo,
      pausasFuturo,
    ]);

    final perfil = resultados[0] as ProfileData;
    final fresco = resultados[1] as Map<String, dynamic>?;
    final estadisticas = resultados[2] as List<dynamic>;
    final pausas = resultados[3] as List<dynamic>;

    var usuario = _usuario;
    if (fresco != null) {
      final backend = UserModel.fromJson(
        fresco,
        fallbackCorreo: _usuario.correo,
        fallbackNombre: _usuario.nombre,
      );
      final fotoLocal = (_usuario.fotoPerfil ?? '').trim();
      final foto = fotoLocal.isNotEmpty
          ? fotoLocal
          : (backend.fotoPerfil ?? AuthService.usuarioFotoPerfil);
      usuario = backend.copyWith(fotoPerfil: foto);
      await AuthService.actualizarUsuarioActual(usuario);
    }

    var totalPausas = 0;
    var totalMinutos = 0;
    var pausasSemana = 0;
    final porDia = <String, int>{};

    final hoy = DateTime.now();
    final inicioSemana = DateTime(
      hoy.year,
      hoy.month,
      hoy.day,
    ).subtract(const Duration(days: 6));
    final finSemana = DateTime(hoy.year, hoy.month, hoy.day);

    for (final e in estadisticas.whereType<Map>()) {
      final cantidad = _asInt(e['pausasRealizadas']);
      totalPausas += cantidad;
      totalMinutos += _asInt(e['minutosActivos']);

      final fecha = _parseFecha(e['fecha']);
      if (fecha == null) continue;

      final key = _keyOf(fecha);
      porDia[key] = (porDia[key] ?? 0) + cantidad;

      final dia = DateTime(fecha.year, fecha.month, fecha.day);
      if (!dia.isBefore(inicioSemana) && !dia.isAfter(finSemana)) {
        pausasSemana += cantidad;
      }
    }

    final completadas = pausas
        .where((p) => p is Map && p['completada'] == true)
        .length;

    if (totalPausas == 0 && pausas.isNotEmpty) {
      totalPausas = pausas.length;
      totalMinutos = pausas.length * 2;
      pausasSemana = pausas.length;
    }

    var racha = 0;
    var cursor = DateTime(hoy.year, hoy.month, hoy.day);
    if ((porDia[_keyOf(cursor)] ?? 0) == 0) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    while ((porDia[_keyOf(cursor)] ?? 0) > 0) {
      racha++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    if (!mounted) return;
    setState(() {
      _perfil = perfil;
      _usuario = usuario;
      _totalPausas = totalPausas;
      _pausasCompletadas = completadas;
      _minutos = totalMinutos;
      _pausasSemana = pausasSemana;
      _racha = racha;
      _cargando = false;
    });
  }

  void _mensaje(String texto, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: error ? const Color(0xFFCF3A3A) : brandBlue,
        content: Text(texto),
      ),
    );
  }

  Future<void> _editarFoto() async {
    if (_subiendoFoto) return;

    final opcion = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111D2E) : Colors.white,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      sheetContext,
                    ).colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Elegir de la galería'),
                  subtitle: const Text('Selecciona una imagen de tu equipo'),
                  onTap: () => Navigator.pop(sheetContext, 'galeria'),
                ),
                if (_puedeUsarCamara)
                  ListTile(
                    leading: const Icon(Icons.photo_camera_outlined),
                    title: const Text('Tomar una foto'),
                    subtitle: const Text('Usa la cámara de tu dispositivo'),
                    onTap: () => Navigator.pop(sheetContext, 'camara'),
                  ),
                if (_usuario.tieneFoto)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red,
                    ),
                    title: const Text(
                      'Quitar foto',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () => Navigator.pop(sheetContext, 'quitar'),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (opcion == null) return;
    if (opcion == 'quitar') {
      await _quitarFoto();
      return;
    }

    await _seleccionarFoto(
      opcion == 'camara' ? ImageSource.camera : ImageSource.gallery,
    );
  }

  bool get _puedeUsarCamara {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> _seleccionarFoto(ImageSource source) async {
    setState(() => _subiendoFoto = true);
    try {
      final archivo = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (archivo == null) return;

      final bytes = await archivo.readAsBytes();
      final comprimida = await compute(_prepararAvatar, bytes);
      if (comprimida.isEmpty) {
        _mensaje('No se pudo procesar la imagen seleccionada', error: true);
        return;
      }

      final actualizado = _usuario.copyWith(
        fotoPerfil: base64Encode(comprimida),
      );
      await AuthService.actualizarUsuarioActual(actualizado);

      if (!mounted) return;
      setState(() => _usuario = actualizado);
      _mensaje('Foto de perfil actualizada correctamente');
    } catch (_) {
      if (mounted) {
        _mensaje(
          'No se pudo cargar la imagen. Intenta con otra foto.',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _subiendoFoto = false);
    }
  }

  Future<void> _quitarFoto() async {
    setState(() => _subiendoFoto = true);
    final actualizado = _usuario.copyWith(fotoPerfil: '');
    await AuthService.actualizarUsuarioActual(actualizado);
    if (!mounted) return;
    setState(() {
      _usuario = actualizado;
      _subiendoFoto = false;
    });
    _mensaje('Foto de perfil eliminada');
  }

  Future<void> _mostrarEditarPerfil() async {
    final resultado = await showModalBottomSheet<_ProfileEditResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(usuario: _usuario, perfil: _perfil),
    );

    if (resultado == null) return;
    await _guardarPerfil(resultado);
  }

  Future<void> _guardarPerfil(_ProfileEditResult resultado) async {
    final nombre = resultado.nombre.trim();
    final correo = resultado.correo.trim().toLowerCase();

    if (nombre.isEmpty || !correo.contains('@')) {
      _mensaje('Revisa el nombre y el correo ingresados', error: true);
      return;
    }

    setState(() => _guardando = true);

    final cambioCuenta = nombre != _usuario.nombre || correo != _usuario.correo;
    if (cambioCuenta && _usuario.id > 0) {
      final ok = await _usuarioService.actualizarUsuario(_usuario.id, {
        'nombre': nombre,
        'correo': correo,
      });
      if (!ok) {
        if (mounted) setState(() => _guardando = false);
        _mensaje(
          'No se pudieron guardar los datos de la cuenta. Verifica que el backend esté activo.',
          error: true,
        );
        return;
      }
    }

    final actualizado = _usuario.copyWith(nombre: nombre, correo: correo);
    await AuthService.actualizarUsuarioActual(actualizado);

    final nuevoPerfil = _perfil.copyWith(
      telefono: resultado.telefono.trim(),
      cargo: resultado.cargo.trim(),
      ciudad: resultado.ciudad.trim(),
      fechaNacimiento: resultado.fechaNacimiento.trim(),
      biografia: resultado.biografia.trim(),
    );
    await ProfilePreferences.save(_usuario.id, nuevoPerfil);

    if (!mounted) return;
    setState(() {
      _usuario = actualizado;
      _perfil = nuevoPerfil;
      _guardando = false;
    });
    _mensaje('Perfil actualizado correctamente');
  }

  Future<void> _actualizarPreferencias(ProfileData nuevo) async {
    setState(() => _perfil = nuevo);
    await ProfilePreferences.save(_usuario.id, nuevo);
    await ReminderService.instance.refresh();
    await ReminderService.instance.checkNow();
    await _usuarioService.actualizarUsuario(_usuario.id, {
      'notificaciones': nuevo.notificaciones,
      'recordatorios': nuevo.recordatorios,
    });
  }

  Future<void> _cambiarPassword() async {
    if (_cambiandoPassword) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cambiar contraseña'),
        content: Text(
          'Enviaremos un código de verificación a ${_usuario.correo}. '
          'Después podrás definir tu nueva contraseña.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Enviar código'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _cambiandoPassword = true);
    final envio = await AuthService.enviarCodigoVerificacion(
      _usuario.correo,
      tipo: 'recuperacion',
    );

    if (!mounted) return;
    setState(() => _cambiandoPassword = false);

    if (!envio.exito) {
      _mensaje(envio.mensaje, error: true);
      return;
    }

    final aviso = envio.codigo != null
        ? 'No se pudo enviar el correo. Tu código es ${envio.codigo}.'
        : envio.mensaje;

    final cambio = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PasswordSheet(
        correo: _usuario.correo,
        codigoInicial: envio.codigo,
        aviso: aviso,
      ),
    );

    if (cambio == true) {
      _mensaje('Contraseña actualizada correctamente');
    }
  }

  Future<void> _abrirAjustes() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsPage(
          themeController: AppThemeController.instance,
          usuario: _usuario,
        ),
      ),
    );
  }

  Future<void> _cerrarSesion() async {
    final salir = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Deseas salir de tu cuenta de ErgoVida?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: brandBlue),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (salir != true) return;
    await AuthService.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _eliminarCuenta() async {
    final confirmacionCtrl = TextEditingController();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Esta acción eliminará tu cuenta y todos tus datos de forma permanente. '
              'No se puede deshacer.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmacionCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Escribe ELIMINAR para confirmar',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: confirmacionCtrl,
            builder: (context, value, _) {
              final habilitado = value.text.trim().toUpperCase() == 'ELIMINAR';
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  disabledBackgroundColor: Colors.red.withValues(alpha: 0.3),
                ),
                onPressed: habilitado
                    ? () => Navigator.pop(dialogContext, true)
                    : null,
                child: const Text('Eliminar'),
              );
            },
          ),
        ],
      ),
    );
    confirmacionCtrl.dispose();

    if (confirmar != true) return;

    setState(() => _eliminando = true);
    final ok = await _usuarioService.eliminarUsuario(_usuario.id);

    if (!mounted) return;
    setState(() => _eliminando = false);

    if (!ok) {
      _mensaje(
        'No se pudo eliminar la cuenta. Intenta nuevamente.',
        error: true,
      );
      return;
    }

    await ProfilePreferences.remove(_usuario.id);
    await AuthService.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _mostrarPreguntasFrecuentes() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Preguntas frecuentes'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Theme(
              data: Theme.of(
                dialogContext,
              ).copyWith(dividerColor: Colors.transparent),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _FaqItem(
                    pregunta: '¿Cómo funcionan las pausas activas?',
                    respuesta:
                        'Las pausas activas son breves interrupciones durante tu jornada para mover el cuerpo y descansar la vista. Puedes iniciarlas desde la sección Ejercicios y completar la rutina guiada.',
                  ),
                  _FaqItem(
                    pregunta: '¿Cómo se calculan mis estadísticas?',
                    respuesta:
                        'ErgoVida registra las pausas completadas, los minutos activos y tus días de constancia. Los datos se actualizan cada vez que abres el perfil o la sección Estadísticas.',
                  ),
                  _FaqItem(
                    pregunta: '¿Puedo usar la app sin internet?',
                    respuesta:
                        'La sesión y tus preferencias locales se conservan. Algunas funciones, como cargar ejercicios o sincronizar estadísticas, necesitan conexión con el backend.',
                  ),
                  _FaqItem(
                    pregunta: '¿Cómo cambio mi foto de perfil?',
                    respuesta:
                        'Toca la cámara sobre tu avatar y elige una imagen de tu galería. En dispositivos móviles también puedes tomar una foto con la cámara.',
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _mostrarPrivacidad() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Política de privacidad'),
        content: const SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Text(
              'ErgoVida utiliza tus datos para personalizar tu experiencia, '
              'gestionar tus pausas activas y mostrarte estadísticas de progreso.\n\n'
              'Tu foto de perfil y tus preferencias se guardan localmente en este '
              'dispositivo. Los datos de la cuenta se almacenan en el servidor de '
              'ErgoVida para permitir el inicio de sesión y la sincronización.\n\n'
              'No compartimos tu información con terceros. Puedes eliminar tu '
              'cuenta y tus datos desde la zona de peligro de este perfil.',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _mostrarAcercaDe() {
    showAboutDialog(
      context: context,
      applicationName: 'ErgoVida',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.self_improvement_rounded,
        color: brandBlue,
        size: 42,
      ),
      children: const [
        SizedBox(height: 12),
        Text(
          'Tu compañera para incorporar pausas activas y cuidar tu bienestar '
          'durante la jornada laboral.',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppThemeController.instance,
      builder: (context, _) => _buildPage(context),
    );
  }

  Widget _buildPage(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0B1424) : const Color(0xFFF4F7FB);
    final textPrimary = isDark ? Colors.white : brandText;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text(
          'Mi perfil',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _cargando ? null : _cargar,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargar,
        color: brandBlue,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            if (_cargando) ...[
              const ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(99)),
                child: LinearProgressIndicator(
                  minHeight: 3,
                  color: brandBlue,
                  backgroundColor: Color(0xFFDCE9F3),
                ),
              ),
              const SizedBox(height: 12),
            ],
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildActividad(context),
            const SizedBox(height: 16),
            _buildInformacion(context),
            const SizedBox(height: 16),
            _buildPreferencias(context),
            const SizedBox(height: 16),
            _buildSeguridad(context),
            const SizedBox(height: 16),
            _buildSoporte(context),
            const SizedBox(height: 16),
            _buildZonaPeligrosa(context),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'ErgoVida · Versión 1.0.0',
                style: TextStyle(
                  color: isDark ? const Color(0xFF7E93A8) : brandMuted,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [brandNavy, Color(0xFF136B8A), brandBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: brandBlue.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -36,
            right: -24,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: brandTeal.withValues(alpha: 0.08),
              ),
            ),
          ),
          Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: 'Editar perfil',
                    onPressed: _guardando ? null : _mostrarEditarPerfil,
                    icon: const Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -12),
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        UserAvatar(
                          usuario: _usuario,
                          radius: 46,
                          backgroundColor: Colors.white,
                          foregroundColor: brandNavy,
                          ringColor: Colors.white.withValues(alpha: 0.4),
                          ringWidth: 3,
                        ),
                        Positioned(
                          right: -4,
                          bottom: -4,
                          child: Material(
                            color: brandTeal,
                            shape: const CircleBorder(),
                            elevation: 4,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _subiendoFoto ? null : _editarFoto,
                              child: Padding(
                                padding: const EdgeInsets.all(9),
                                child: _subiendoFoto
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: brandNavy,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.camera_alt_rounded,
                                        size: 18,
                                        color: brandNavy,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _usuario.nombre.trim().isEmpty
                          ? 'Tu perfil'
                          : _usuario.nombre,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _usuario.correo,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _HeaderChip(
                          icon: Icons.badge_outlined,
                          label: _usuario.rol.toUpperCase() == 'ADMINISTRADOR'
                              ? 'Administrador'
                              : 'Usuario',
                        ),
                        _HeaderChip(
                          icon: Icons.calendar_month_outlined,
                          label: 'Desde ${_mesAnio(_perfil.miembroDesde)}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: _HeaderStat(
                            icon: Icons.self_improvement_rounded,
                            value: '$_totalPausas',
                            label: 'Pausas',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _HeaderStat(
                            icon: Icons.timer_outlined,
                            value: '$_minutos',
                            label: 'Minutos',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _HeaderStat(
                            icon: Icons.local_fire_department_outlined,
                            value: '$_racha',
                            label: 'Racha',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActividad(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? const Color(0xFFAFC1D4) : brandMuted;
    final progreso = (_pausasSemana / 5).clamp(0.0, 1.0);

    return _SectionCard(
      title: 'Tu actividad',
      icon: Icons.insights_rounded,
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                icon: Icons.check_circle_outline_rounded,
                value: '$_pausasCompletadas',
                label: 'Completadas',
                color: brandTeal,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                icon: Icons.timer_outlined,
                value: '$_minutos min',
                label: 'Tiempo activo',
                color: brandBlue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                icon: Icons.local_fire_department_outlined,
                value: '$_racha',
                label: 'Días de racha',
                color: const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Text(
              'Meta semanal',
              style: TextStyle(
                color: textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            Text(
              '$_pausasSemana / 5',
              style: const TextStyle(
                color: brandBlue,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: progreso,
            minHeight: 8,
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE3EEF6),
            color: brandTeal,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          progreso >= 1
              ? '¡Meta cumplida! Sigue así para mantener tu racha.'
              : 'Completa ${5 - _pausasSemana.clamp(0, 5)} pausas más para cumplir tu meta.',
          style: TextStyle(color: textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildInformacion(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? const Color(0xFFAFC1D4) : brandMuted;

    return _SectionCard(
      title: 'Información personal',
      icon: Icons.person_outline_rounded,
      trailing: TextButton.icon(
        onPressed: _guardando ? null : _mostrarEditarPerfil,
        icon: const Icon(Icons.edit_outlined, size: 16),
        label: const Text('Editar'),
      ),
      children: [
        _InfoTile(
          icon: Icons.phone_outlined,
          label: 'Teléfono',
          value: _perfil.telefono,
        ),
        _InfoTile(
          icon: Icons.work_outline_rounded,
          label: 'Cargo o área',
          value: _perfil.cargo,
        ),
        _InfoTile(
          icon: Icons.place_outlined,
          label: 'Ciudad',
          value: _perfil.ciudad,
        ),
        _InfoTile(
          icon: Icons.cake_outlined,
          label: 'Fecha de nacimiento',
          value: _fechaNacimientoTexto(_perfil.fechaNacimiento),
        ),
        if (_perfil.biografia.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : const Color(0xFFF5F9FC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sobre mí',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _perfil.biografia,
                  style: TextStyle(
                    color: isDark ? Colors.white : brandText,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildPreferencias(BuildContext context) {
    final isDark = AppThemeController.instance.isDark;

    return _SectionCard(
      title: 'Preferencias',
      icon: Icons.tune_rounded,
      children: [
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.dark_mode_outlined),
          title: const Text('Tema oscuro'),
          subtitle: const Text('Interfaz con menos brillo'),
          value: isDark,
          onChanged: (valor) => AppThemeController.instance.setTheme(valor),
        ),
        const Divider(height: 8),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.notifications_none_rounded),
          title: const Text('Notificaciones'),
          subtitle: const Text('Avisos generales de ErgoVida'),
          value: _perfil.notificaciones,
          onChanged: (valor) =>
              _actualizarPreferencias(_perfil.copyWith(notificaciones: valor)),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.alarm_outlined),
          title: const Text('Recordatorios'),
          subtitle: const Text('Pausas activas durante la jornada'),
          value: _perfil.recordatorios,
          onChanged: (valor) =>
              _actualizarPreferencias(_perfil.copyWith(recordatorios: valor)),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.schedule_rounded),
          title: const Text('Horarios de pausas'),
          subtitle: const Text('Configura tus recordatorios'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: _abrirAjustes,
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildSeguridad(BuildContext context) {
    return _SectionCard(
      title: 'Seguridad y sesión',
      icon: Icons.shield_outlined,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.lock_reset_rounded),
          title: const Text('Cambiar contraseña'),
          subtitle: const Text('Te enviaremos un código de verificación'),
          trailing: _cambiandoPassword
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.chevron_right_rounded),
          onTap: _cambiandoPassword ? null : _cambiarPassword,
        ),
        const Divider(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.logout_rounded, color: Color(0xFFE08A1E)),
          title: const Text('Cerrar sesión'),
          subtitle: const Text('Salir de tu cuenta en este dispositivo'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: _cerrarSesion,
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildSoporte(BuildContext context) {
    return _SectionCard(
      title: 'Ayuda y soporte',
      icon: Icons.help_outline_rounded,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.quiz_outlined),
          title: const Text('Preguntas frecuentes'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: _mostrarPreguntasFrecuentes,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('Política de privacidad'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: _mostrarPrivacidad,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.info_outline_rounded),
          title: const Text('Acerca de ErgoVida'),
          subtitle: const Text('Versión 1.0.0'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: _mostrarAcercaDe,
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildZonaPeligrosa(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _SectionCard(
      title: 'Zona peligrosa',
      icon: Icons.warning_amber_rounded,
      accentColor: Colors.red,
      children: [
        Text(
          'Eliminar tu cuenta borrará permanentemente tu perfil y tus datos asociados.',
          style: TextStyle(
            color: isDark ? const Color(0xFFAFC1D4) : brandMuted,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _eliminando ? null : _eliminarCuenta,
            icon: _eliminando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.red,
                    ),
                  )
                : const Icon(Icons.delete_forever_rounded, color: Colors.red),
            label: Text(
              _eliminando ? 'Eliminando...' : 'Eliminar mi cuenta',
              style: const TextStyle(color: Colors.red),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  final UserModel usuario;
  final ProfileData perfil;

  const _EditProfileSheet({required this.usuario, required this.perfil});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _correoCtrl;
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _cargoCtrl;
  late final TextEditingController _ciudadCtrl;
  late final TextEditingController _fechaCtrl;
  late final TextEditingController _bioCtrl;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.usuario.nombre);
    _correoCtrl = TextEditingController(text: widget.usuario.correo);
    _telefonoCtrl = TextEditingController(text: widget.perfil.telefono);
    _cargoCtrl = TextEditingController(text: widget.perfil.cargo);
    _ciudadCtrl = TextEditingController(text: widget.perfil.ciudad);
    _fechaCtrl = TextEditingController(text: widget.perfil.fechaNacimiento);
    _bioCtrl = TextEditingController(text: widget.perfil.biografia);
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _correoCtrl.dispose();
    _telefonoCtrl.dispose();
    _cargoCtrl.dispose();
    _ciudadCtrl.dispose();
    _fechaCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final primera = DateTime(1930);
    final ultima = DateTime.now();
    var inicial = DateTime.tryParse(_fechaCtrl.text) ?? DateTime(1990);
    if (inicial.isBefore(primera)) inicial = primera;
    if (inicial.isAfter(ultima)) inicial = ultima;

    final fecha = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: primera,
      lastDate: ultima,
      helpText: 'Fecha de nacimiento',
    );
    if (fecha == null) return;
    setState(() {
      _fechaCtrl.text =
          '${fecha.year.toString().padLeft(4, '0')}-'
          '${fecha.month.toString().padLeft(2, '0')}-'
          '${fecha.day.toString().padLeft(2, '0')}';
    });
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _ProfileEditResult(
        nombre: _nombreCtrl.text,
        correo: _correoCtrl.text,
        telefono: _telefonoCtrl.text,
        cargo: _cargoCtrl.text,
        ciudad: _ciudadCtrl.text,
        fechaNacimiento: _fechaCtrl.text,
        biografia: _bioCtrl.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF111D2E) : Colors.white;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Editar perfil',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nombreCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (valor) {
                      if (valor == null || valor.trim().isEmpty) {
                        return 'El nombre es obligatorio';
                      }
                      if (valor.trim().length < 3) {
                        return 'Ingresa al menos 3 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _correoCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (valor) {
                      if (valor == null || valor.trim().isEmpty) {
                        return 'El correo es obligatorio';
                      }
                      if (!RegExp(
                        r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$',
                      ).hasMatch(valor.trim())) {
                        return 'Ingresa un correo válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _telefonoCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _cargoCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Cargo o área',
                      prefixIcon: Icon(Icons.work_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _ciudadCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Ciudad',
                      prefixIcon: Icon(Icons.place_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _fechaCtrl,
                    readOnly: true,
                    onTap: _seleccionarFecha,
                    decoration: const InputDecoration(
                      labelText: 'Fecha de nacimiento',
                      hintText: 'AAAA-MM-DD',
                      prefixIcon: Icon(Icons.cake_outlined),
                      suffixIcon: Icon(Icons.calendar_month_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _bioCtrl,
                    maxLines: 3,
                    maxLength: 240,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Sobre mí',
                      hintText: 'Cuéntanos un poco sobre ti',
                      alignLabelWithHint: true,
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 48),
                        child: Icon(Icons.notes_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _guardar,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Guardar cambios'),
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

class _PasswordSheet extends StatefulWidget {
  final String correo;
  final String? codigoInicial;
  final String aviso;

  const _PasswordSheet({
    required this.correo,
    required this.aviso,
    this.codigoInicial,
  });

  @override
  State<_PasswordSheet> createState() => _PasswordSheetState();
}

class _PasswordSheetState extends State<_PasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codigoCtrl;
  final _passwordCtrl = TextEditingController();
  final _confirmarCtrl = TextEditingController();

  bool _cargando = false;
  bool _ocultarPassword = true;
  bool _ocultarConfirmacion = true;
  String? _mensajeAviso;

  @override
  void initState() {
    super.initState();
    _codigoCtrl = TextEditingController(text: widget.codigoInicial ?? '');
    _mensajeAviso = widget.aviso;
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  Future<void> _reenviarCodigo() async {
    if (_cargando) return;
    setState(() => _cargando = true);
    final envio = await AuthService.enviarCodigoVerificacion(
      widget.correo,
      tipo: 'recuperacion',
    );
    if (!mounted) return;
    setState(() {
      _cargando = false;
      _mensajeAviso = envio.codigo != null
          ? 'No se pudo enviar el correo. Tu código es ${envio.codigo}.'
          : envio.mensaje;
      if (envio.codigo != null) _codigoCtrl.text = envio.codigo!;
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate() || _cargando) return;

    final password = _passwordCtrl.text;
    setState(() {
      _cargando = true;
      _mensajeAviso = null;
    });

    final verificacion = await AuthService.verificarCodigo(
      widget.correo,
      _codigoCtrl.text.trim(),
    );

    if (!mounted) return;
    if (!verificacion.exito) {
      setState(() {
        _cargando = false;
        _mensajeAviso = verificacion.mensaje;
      });
      return;
    }

    final error = await AuthService.cambiarPassword(
      correo: widget.correo,
      nuevaPassword: password,
    );

    if (!mounted) return;
    if (error != null) {
      setState(() {
        _cargando = false;
        _mensajeAviso = error;
      });
      return;
    }

    setState(() => _cargando = false);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF111D2E) : Colors.white;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Nueva contraseña',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Enviamos un código a ${widget.correo}.',
                    style: TextStyle(
                      color: isDark ? const Color(0xFFAFC1D4) : brandMuted,
                      fontSize: 13,
                    ),
                  ),
                  if (_mensajeAviso != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F7FC0).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        _mensajeAviso!,
                        style: const TextStyle(fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _codigoCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'Código de verificación',
                      prefixIcon: Icon(Icons.verified_user_outlined),
                      counterText: '',
                    ),
                    validator: (valor) {
                      if (valor == null || valor.trim().length != 6) {
                        return 'Ingresa el código de 6 dígitos';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _ocultarPassword,
                    decoration: InputDecoration(
                      labelText: 'Nueva contraseña',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                          () => _ocultarPassword = !_ocultarPassword,
                        ),
                        icon: Icon(
                          _ocultarPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (valor) {
                      if (valor == null || valor.length < 8) {
                        return 'Mínimo 8 caracteres';
                      }
                      if (!RegExp(r'[A-Z]').hasMatch(valor)) {
                        return 'Falta al menos una mayúscula';
                      }
                      if (!RegExp(r'[0-9]').hasMatch(valor)) {
                        return 'Falta al menos un número';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _confirmarCtrl,
                    obscureText: _ocultarConfirmacion,
                    decoration: InputDecoration(
                      labelText: 'Confirmar contraseña',
                      prefixIcon: const Icon(Icons.lock_reset_rounded),
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                          () => _ocultarConfirmacion = !_ocultarConfirmacion,
                        ),
                        icon: Icon(
                          _ocultarConfirmacion
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (valor) {
                      if (valor != _passwordCtrl.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _cargando ? null : _guardar,
                      icon: _cargando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(
                        _cargando ? 'Actualizando...' : 'Actualizar contraseña',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _cargando ? null : _reenviarCodigo,
                    child: const Text('Reenviar código'),
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

class _ProfileEditResult {
  final String nombre;
  final String correo;
  final String telefono;
  final String cargo;
  final String ciudad;
  final String fechaNacimiento;
  final String biografia;

  const _ProfileEditResult({
    required this.nombre,
    required this.correo,
    required this.telefono,
    required this.cargo,
    required this.ciudad,
    required this.fechaNacimiento,
    required this.biografia,
  });
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final Widget? trailing;
  final Color? accentColor;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
    this.trailing,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF111D2E) : Colors.white;
    final textPrimary = isDark ? Colors.white : brandText;
    final accent = accentColor ?? brandBlue;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : const Color(0xFFE2EBF3),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0x0D0E2238),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeaderChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: brandTeal),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _HeaderStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Icon(icon, color: brandTeal, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _MetricTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.14 : 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? Colors.white : brandText,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? const Color(0xFFAFC1D4) : brandMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? const Color(0xFFAFC1D4) : brandMuted;
    final texto = value.trim().isEmpty ? 'Sin registrar' : value.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  texto,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: value.trim().isEmpty
                        ? textSecondary.withValues(alpha: 0.75)
                        : (isDark ? Colors.white : brandText),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontStyle: value.trim().isEmpty
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  final String pregunta;
  final String respuesta;

  const _FaqItem({required this.pregunta, required this.respuesta});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      title: Text(
        pregunta,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      children: [
        Text(respuesta, style: const TextStyle(fontSize: 13, height: 1.45)),
      ],
    );
  }
}

const List<String> _meses = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

String _mesAnio(DateTime? fecha) {
  if (fecha == null) return 'hoy';
  return '${_meses[fecha.month - 1]} ${fecha.year}';
}

String _fechaNacimientoTexto(String valor) {
  if (valor.trim().isEmpty) return '';
  final fecha = DateTime.tryParse(valor);
  if (fecha == null) return valor;
  final dia = fecha.day.toString().padLeft(2, '0');
  final mes = fecha.month.toString().padLeft(2, '0');
  return '$dia/$mes/${fecha.year}';
}

int _asInt(dynamic valor) {
  if (valor is int) return valor;
  if (valor is num) return valor.toInt();
  return int.tryParse(valor?.toString() ?? '') ?? 0;
}

DateTime? _parseFecha(dynamic valor) {
  if (valor == null) return null;
  if (valor is DateTime) return valor;
  if (valor is List && valor.length >= 3) {
    return DateTime(_asInt(valor[0]), _asInt(valor[1]), _asInt(valor[2]));
  }
  final texto = valor.toString();
  return DateTime.tryParse(texto) ?? DateTime.tryParse(texto.split('T').first);
}

String _keyOf(DateTime fecha) {
  final mes = fecha.month.toString().padLeft(2, '0');
  final dia = fecha.day.toString().padLeft(2, '0');
  return '${fecha.year}-$mes-$dia';
}

Uint8List _prepararAvatar(Uint8List bytes) {
  final original = img.decodeImage(bytes);
  if (original == null) return Uint8List(0);

  final cuadrado = img.copyResizeCropSquare(
    original,
    size: 480,
    interpolation: img.Interpolation.average,
  );
  return Uint8List.fromList(img.encodeJpg(cuadrado, quality: 82));
}
