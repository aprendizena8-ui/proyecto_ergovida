import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/services/admin_alerta_service.dart';
import '../../widgets/design_system.dart';

class AdminAlertasPage extends StatefulWidget {
  const AdminAlertasPage({super.key});

  @override
  State<AdminAlertasPage> createState() => _AdminAlertasPageState();
}

class _AdminAlertasPageState extends State<AdminAlertasPage> {
  List<CorreoAlerta> _correos = const [];
  List<SolicitudAyudaAdmin> _solicitudes = const [];
  List<HistorialRecordatorioAdmin> _historial = const [];
  List<AlertaErrorAdmin> _alertas = const [];

  bool _cargando = true;
  bool _probando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);

    try {
      final correos = await AdminAlertaService.correos();
      if (!mounted) return;
      setState(() => _correos = correos);
    } catch (_) {
      if (!mounted) return;
      setState(() => _correos = const []);
    }

    try {
      final solicitudes = await AdminAlertaService.solicitudes();
      if (!mounted) return;
      setState(() => _solicitudes = solicitudes);
    } catch (_) {
      if (!mounted) return;
      setState(() => _solicitudes = const []);
    }

    try {
      final historial = await AdminAlertaService.historial();
      if (!mounted) return;
      setState(() => _historial = historial);
    } catch (_) {
      if (!mounted) return;
      setState(() => _historial = const []);
    }

    try {
      final alertas = await AdminAlertaService.alertas();
      if (!mounted) return;
      setState(() => _alertas = alertas);
    } catch (_) {
      if (!mounted) return;
      setState(() => _alertas = const []);
    }

    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _agregarCorreo() async {
    final resultado = await _mostrarFormularioCorreo();
    if (resultado == null) return;

    try {
      await AdminAlertaService.crearCorreo(
        correo: resultado.correo,
        nombre: resultado.nombre,
      );
      _mensaje('Correo agregado. Ya recibe las alertas.', AppPalette.success);
      await _cargar();
    } catch (error) {
      _mensaje('No se pudo agregar el correo: $error', AppPalette.danger);
    }
  }

  Future<void> _editarCorreo(CorreoAlerta correo) async {
    final resultado = await _mostrarFormularioCorreo(inicial: correo);
    if (resultado == null) return;

    try {
      await AdminAlertaService.actualizarCorreo(
        correo.id,
        correo: resultado.correo,
        nombre: resultado.nombre,
        activo: resultado.activo,
      );
      _mensaje('Correo actualizado.', AppPalette.success);
      await _cargar();
    } catch (error) {
      _mensaje('No se pudo actualizar el correo: $error', AppPalette.danger);
    }
  }

  Future<void> _eliminarCorreo(CorreoAlerta correo) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar correo'),
        content: Text(
          '¿Dejar de enviar alertas a ${correo.correo}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.danger,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await AdminAlertaService.eliminarCorreo(correo.id);
      _mensaje('Correo eliminado.', AppPalette.success);
      await _cargar();
    } catch (error) {
      _mensaje('No se pudo eliminar: $error', AppPalette.danger);
    }
  }

  Future<void> _probarCorreo() async {
    setState(() => _probando = true);

    try {
      final respuesta = await AdminAlertaService.probar();
      final enviado = respuesta['correoEnviado'] == true;
      final mensaje = respuesta['mensaje']?.toString() ??
          (enviado
              ? 'Correo de prueba enviado.'
              : 'No se pudo enviar el correo de prueba.');

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(enviado ? 'Prueba enviada' : 'No se pudo enviar'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(mensaje),
              if (respuesta['destinatarios'] is List) ...[
                const SizedBox(height: 12),
                const Text(
                  'Destinatarios:',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                for (final correo in (respuesta['destinatarios'] as List))
                  Text('• $correo'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (error) {
      _mensaje('No se pudo probar el correo: $error', AppPalette.danger);
    } finally {
      if (mounted) setState(() => _probando = false);
    }
  }

  Future<void> _cambiarEstadoSolicitud(SolicitudAyudaAdmin solicitud) async {
    final nuevoEstado = solicitud.pendiente ? 'RESUELTA' : 'PENDIENTE';

    try {
      await AdminAlertaService.cambiarEstadoSolicitud(
        solicitud.id,
        nuevoEstado,
      );
      _mensaje(
        nuevoEstado == 'RESUELTA'
            ? 'Solicitud marcada como resuelta.'
            : 'Solicitud reabierta.',
        AppPalette.success,
      );
      await _cargar();
    } catch (error) {
      _mensaje('No se pudo cambiar el estado: $error', AppPalette.danger);
    }
  }

  void _verSolicitud(SolicitudAyudaAdmin solicitud) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                solicitud.asunto,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text('${solicitud.nombre} · ${solicitud.correo}'),
              Text('Rol: ${solicitud.rol}'),
              const SizedBox(height: 16),
              Text(solicitud.descripcion),
            ],
          ),
        ),
      ),
    );
  }

  Future<_DatosCorreo?> _mostrarFormularioCorreo({
    CorreoAlerta? inicial,
  }) async {
    final correoController = TextEditingController(text: inicial?.correo);
    final nombreController = TextEditingController(text: inicial?.nombre);
    var activo = inicial?.activo ?? true;
    final formKey = GlobalKey<FormState>();

    final resultado = await showDialog<_DatosCorreo>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(inicial == null ? 'Agregar correo' : 'Editar correo'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: correoController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo',
                    hintText: 'administrador@empresa.com',
                  ),
                  validator: (valor) {
                    final texto = valor?.trim() ?? '';
                    if (!texto.contains('@') || !texto.contains('.')) {
                      return 'Ingresa un correo valido.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre (opcional)',
                  ),
                ),
                if (inicial != null) ...[
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Recibe alertas'),
                    value: activo,
                    onChanged: (valor) {
                      setDialogState(() => activo = valor);
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(
                  context,
                  _DatosCorreo(
                    correo: correoController.text.trim(),
                    nombre: nombreController.text.trim(),
                    activo: activo,
                  ),
                );
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    correoController.dispose();
    nombreController.dispose();
    return resultado;
  }

  void _mensaje(String texto, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: color, content: Text(texto)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: isDark
            ? AppPalette.darkBackground
            : AppPalette.background,
        appBar: AppBar(
          title: const Text('Alertas y soporte'),
          backgroundColor: Colors.transparent,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Correos'),
              Tab(text: 'Solicitudes'),
              Tab(text: 'Historial'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Actualizar',
              onPressed: _cargando ? null : _cargar,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _cargando ? null : _agregarCorreo,
          backgroundColor: AppPalette.blue,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Correo'),
        ),
        body: _cargando
            ? const Center(
                child: CircularProgressIndicator(color: AppPalette.blue),
              )
            : TabBarView(
                children: [
                  _correosTab(isDark),
                  _solicitudesTab(isDark),
                  _historialTab(isDark),
                ],
              ),
      ),
    );
  }

  Widget _correosTab(bool isDark) {
    return RefreshIndicator(
      onRefresh: _cargar,
      color: AppPalette.blue,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
        children: [
          AppSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Correos de administradores'),
                const SizedBox(height: 8),
                Text(
                  'Estos correos reciben las alertas de errores del servidor '
                  'y las solicitudes de ayuda. Los errores repetidos se '
                  'agrupan cada 15 minutos.',
                  style: TextStyle(
                    color: isDark ? AppPalette.darkMuted : AppPalette.muted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                GradientButton(
                  label: _probando
                      ? 'Enviando prueba...'
                      : 'Enviar correo de prueba',
                  icon: Icons.outgoing_mail,
                  onPressed: _probando ? null : _probarCorreo,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_correos.isEmpty)
            const AppSurface(
              child: AppEmptyState(
                icon: Icons.mark_email_unread_rounded,
                title: 'Sin correos configurados',
                message:
                    'Agrega al menos un correo para recibir alertas y '
                    'solicitudes de ayuda.',
              ),
            )
          else
            AppSurface(
              child: Column(
                children: [
                  for (var i = 0; i < _correos.length; i++) ...[
                    _correoTile(_correos[i], isDark),
                    if (i != _correos.length - 1)
                      const AppDivider(vertical: 6),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _correoTile(CorreoAlerta correo, bool isDark) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const IconBadge(
        icon: Icons.alternate_email_rounded,
        color: AppPalette.blue,
        size: 42,
      ),
      title: Text(
        correo.correo,
        style: TextStyle(
          color: isDark ? Colors.white : AppPalette.text,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        correo.nombre.isEmpty ? 'Administrador' : correo.nombre,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppPill(
            text: correo.activo ? 'Activo' : 'Inactivo',
            color: correo.activo ? AppPalette.success : AppPalette.muted,
          ),
          PopupMenuButton<String>(
            onSelected: (accion) {
              if (accion == 'editar') _editarCorreo(correo);
              if (accion == 'eliminar') _eliminarCorreo(correo);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'editar', child: Text('Editar')),
              PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _solicitudesTab(bool isDark) {
    return RefreshIndicator(
      onRefresh: _cargar,
      color: AppPalette.blue,
      child: _solicitudes.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(18),
              children: const [
                AppSurface(
                  child: AppEmptyState(
                    icon: Icons.support_agent_rounded,
                    title: 'Sin solicitudes',
                    message:
                        'Las solicitudes enviadas desde Ayuda y soporte '
                        'apareceran aqui.',
                  ),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
              itemCount: _solicitudes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final solicitud = _solicitudes[index];
                return AppSurface(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => _verSolicitud(solicitud),
                    leading: IconBadge(
                      icon: solicitud.pendiente
                          ? Icons.mark_email_unread_rounded
                          : Icons.task_alt_rounded,
                      color: solicitud.pendiente
                          ? AppPalette.warning
                          : AppPalette.success,
                      size: 44,
                    ),
                    title: Text(
                      solicitud.asunto,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppPalette.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      '${solicitud.nombre} · ${solicitud.correo}\n'
                      '${_fechaCorta(solicitud.fechaCreacion)}',
                    ),
                    isThreeLine: true,
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppPill(
                          text: solicitud.pendiente ? 'Pendiente' : 'Resuelta',
                          color: solicitud.pendiente
                              ? AppPalette.warning
                              : AppPalette.success,
                        ),
                        TextButton(
                          onPressed: () => _cambiarEstadoSolicitud(solicitud),
                          child: Text(
                            solicitud.pendiente ? 'Resolver' : 'Reabrir',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _historialTab(bool isDark) {
    final items = <Widget>[];

    if (_alertas.isNotEmpty) {
      items.add(const SectionHeader(title: 'Errores agrupados'));
      items.add(const SizedBox(height: 8));
      items.add(
        AppSurface(
          child: Column(
            children: [
              for (var i = 0; i < _alertas.length; i++) ...[
                _alertaTile(_alertas[i], isDark),
                if (i != _alertas.length - 1) const AppDivider(vertical: 6),
              ],
            ],
          ),
        ),
      );
      items.add(const SizedBox(height: 18));
    }

    items.add(const SectionHeader(title: 'Entregas de recordatorios'));
    items.add(const SizedBox(height: 8));

    if (_historial.isEmpty) {
      items.add(
        const AppSurface(
          child: AppEmptyState(
            icon: Icons.history_rounded,
            title: 'Sin entregas registradas',
            message:
                'El servidor registrara aqui cada envio por correo o push.',
          ),
        ),
      );
    } else {
      items.add(
        AppSurface(
          child: Column(
            children: [
              for (var i = 0; i < _historial.length; i++) ...[
                _historialTile(_historial[i], isDark),
                if (i != _historial.length - 1) const AppDivider(vertical: 4),
              ],
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      color: AppPalette.blue,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
        children: items,
      ),
    );
  }

  Widget _alertaTile(AlertaErrorAdmin alerta, bool isDark) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const IconBadge(
        icon: Icons.error_outline_rounded,
        color: AppPalette.danger,
        size: 42,
      ),
      title: Text(
        alerta.tipo.isEmpty ? 'Error' : alerta.tipo,
        style: TextStyle(
          color: isDark ? Colors.white : AppPalette.text,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        '${alerta.modulo}\n'
        '${alerta.mensaje}\n'
        'Veces: ${alerta.veces} · Ultimo aviso: '
        '${_fechaCorta(alerta.ultimoEnvio)}',
      ),
      isThreeLine: true,
    );
  }

  Widget _historialTile(HistorialRecordatorioAdmin item, bool isDark) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: IconBadge(
        icon: item.exito
            ? Icons.check_circle_outline_rounded
            : Icons.error_outline_rounded,
        color: item.exito ? AppPalette.success : AppPalette.danger,
        size: 42,
      ),
      title: Text(
        '${item.tipo} · ${item.canal} · Usuario ${item.usuarioId}',
        style: TextStyle(
          color: isDark ? Colors.white : AppPalette.text,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        item.exito
            ? _fechaCorta(item.fecha)
            : '${_fechaCorta(item.fecha)}\n${item.error}',
      ),
      isThreeLine: !item.exito,
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

class _DatosCorreo {
  final String correo;
  final String nombre;
  final bool activo;

  const _DatosCorreo({
    required this.correo,
    required this.nombre,
    required this.activo,
  });
}
