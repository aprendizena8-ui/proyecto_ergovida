import 'package:flutter/material.dart';

import '../../data/services/auth_service.dart';
import '../../data/services/ejercicio_service.dart';
import '../../main.dart';
import 'exercise_camera_page.dart';

class ExercisesPage extends StatefulWidget {
  final int? usuarioId;
  final bool? esAdmin;

  const ExercisesPage({super.key, this.usuarioId, this.esAdmin});

  @override
  State<ExercisesPage> createState() => _ExercisesPageState();
}

class _ExercisesPageState extends State<ExercisesPage> {
  final EjercicioService _ejercicioService = EjercicioService();

  List<_EjercicioItem> _ejercicios = [];
  bool _cargando = true;
  bool _sinConexion = false;

  int get _usuarioId => widget.usuarioId ?? AuthService.usuarioId;
  bool get _esAdmin {
    final rol = (AuthService.usuarioRol).toUpperCase();
    return widget.esAdmin ?? (rol == 'ADMINISTRADOR');
  }

  static const List<_EjercicioDef> _definiciones = [
    _EjercicioDef(
      nombre: 'Estiramiento de Cuello',
      duracionMin: 2,
      categoria: 'Cuello',
      icono: Icons.accessibility_new_rounded,
      color: brandBlue,
      descripcion:
          'Libera la tensión del cuello con inclinaciones laterales suaves y controladas.',
      instrucciones:
          'Pon la cabeza recta, mira al frente y realiza pequeños movimientos lentos.',
    ),
    _EjercicioDef(
      nombre: 'Movilidad de Hombros',
      duracionMin: 3,
      categoria: 'Hombros',
      icono: Icons.fitness_center_rounded,
      color: brandNavy,
      descripcion:
          'Activa la circulación de hombros y espalda alta con encogimientos y círculos.',
      instrucciones:
          'Eleva y baja los hombros con control, manteniendo la espalda recta.',
    ),
    _EjercicioDef(
      nombre: 'Descanso Visual',
      duracionMin: 1,
      categoria: 'Vista',
      icono: Icons.visibility_rounded,
      color: brandTeal,
      descripcion:
          'Reduce la fatiga visual alternando la mirada lejana con el descanso ocular.',
      instrucciones:
          'Mira a lo lejos y alterna la mirada para aliviar la fatiga visual.',
    ),
    _EjercicioDef(
      nombre: 'Movilidad de Muñecas',
      duracionMin: 2,
      categoria: 'Muñecas',
      icono: Icons.pan_tool_rounded,
      color: brandCyan,
      descripcion:
          'Previene molestias por teclado y mouse movilizando tus muñecas.',
      instrucciones:
          'Gira las muñecas con suavidad y mantén codos flexionados.',
    ),
    _EjercicioDef(
      nombre: 'Elevación de Brazos',
      duracionMin: 2,
      categoria: 'Brazos',
      icono: Icons.arrow_upward_rounded,
      color: brandBlue,
      descripcion:
          'Moviliza hombros y brazos con elevaciones completas por encima de la cabeza.',
      instrucciones:
          'Sube ambos brazos estirados y bájalos con control, sin arquear la espalda.',
    ),
    _EjercicioDef(
      nombre: 'Flexión de Codos',
      duracionMin: 2,
      categoria: 'Brazos',
      icono: Icons.fitness_center_rounded,
      color: brandNavy,
      descripcion:
          'Activa brazos y antebrazos con flexiones de codo controladas junto al cuerpo.',
      instrucciones:
          'Lleva las manos hacia los hombros y extiende los brazos sin separar los codos.',
    ),
    _EjercicioDef(
      nombre: 'Apertura de Pecho',
      duracionMin: 3,
      categoria: 'Espalda',
      icono: Icons.open_in_full_rounded,
      color: brandTeal,
      descripcion:
          'Contrarresta la postura encorvada abriendo el pecho y juntando los omóplatos.',
      instrucciones:
          'Abre los brazos a la altura de los hombros y mantén la apertura unos segundos.',
    ),
    _EjercicioDef(
      nombre: 'Inclinación Lateral de Tronco',
      duracionMin: 3,
      categoria: 'Espalda',
      icono: Icons.swap_horiz_rounded,
      color: brandCyan,
      descripcion:
          'Estira la espalda y los costados con inclinaciones laterales suaves del tronco.',
      instrucciones:
          'Inclina el tronco hacia un lado sin mover las caderas, mantén y cambia de lado.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (mounted) {
      setState(() {
        _cargando = true;
        _sinConexion = false;
      });
    }

    final registros = await _ejercicioService.obtenerEjercicios();
    final porNombre = <String, Map<String, dynamic>>{};
    for (final registro in registros.whereType<Map>()) {
      final map = Map<String, dynamic>.from(registro);
      final nombre = map['nombre']?.toString().trim().toLowerCase();
      if (nombre != null && nombre.isNotEmpty) {
        porNombre[nombre] = map;
      }
    }

    final items = <_EjercicioItem>[];
    var fallos = 0;

    for (final def in _definiciones) {
      var registro = porNombre.remove(def.nombre.toLowerCase());

      if (registro == null) {
        registro = await _ejercicioService.crearEjercicio({
          'nombre': def.nombre,
          'descripcion': def.descripcion,
          'duracion': def.duracionMin,
          'categoria': def.categoria,
        });

        if (registro == null) {
          fallos++;
          items.add(def.toItem(0));
          continue;
        }
      }

      items.add(_EjercicioItem.fromDb(registro, def: def));
    }

    for (final registro in porNombre.values) {
      items.add(_EjercicioItem.fromDb(registro));
    }

    if (!mounted) return;
    setState(() {
      _ejercicios = items;
      _sinConexion = registros.isEmpty && fallos == _definiciones.length;
      _cargando = false;
    });
  }

  Future<void> _iniciar(_EjercicioItem ejercicio) async {
    if (_usuarioId <= 0) {
      _mensaje('Inicia sesión para registrar tus pausas.', ok: false);
      return;
    }
    if (ejercicio.id <= 0) {
      _mensaje(
        'Este ejercicio aún no está guardado en la base de datos. Reintenta.',
        ok: false,
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExerciseCameraPage(
          nombre: ejercicio.nombre,
          duracion: ejercicio.duracion,
          icono: ejercicio.icono,
          usuarioId: _usuarioId,
          ejercicioId: ejercicio.id,
        ),
      ),
    );

    if (mounted) _cargar();
  }

  Future<void> _formulario({_EjercicioItem? ejercicio}) async {
    final datos = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _EjercicioFormDialog(ejercicio: ejercicio),
    );
    if (datos == null) return;

    final ok = ejercicio == null
        ? await _ejercicioService.crearEjercicio(datos) != null
        : await _ejercicioService.actualizarEjercicio(ejercicio.id, datos);

    if (!mounted) return;
    _mensaje(
      ok ? 'Ejercicio guardado' : 'No se pudo guardar el ejercicio',
      ok: ok,
    );
    if (ok) _cargar();
  }

  Future<void> _eliminar(_EjercicioItem ejercicio) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar ejercicio'),
        content: Text('¿Eliminar "${ejercicio.nombre}" del sistema?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    // Realizamos la eliminación
    final ok = await _ejercicioService.eliminarEjercicio(ejercicio.id);

    // Verificamos que el widget siga montado antes de actualizar
    if (!mounted) return;

    _mensaje(
      ok ? 'Ejercicio eliminado' : 'No se pudo eliminar el ejercicio',
      ok: ok,
    );

    if (ok) _cargar();
  }

  void _mensaje(String texto, {required bool ok}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ok ? brandBlue : const Color(0xFFCF3A3A),
        behavior: SnackBarBehavior.floating,
        content: Text(texto),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0B1424) : const Color(0xFFEAF3F8);
    final textPrimary = isDark ? Colors.white : brandText;
    final textSecondary = isDark ? const Color(0xFFCBD5E1) : brandMuted;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text(
          'Ejercicios',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: brandNavy,
        foregroundColor: Colors.white,
        actions: [
          if (_esAdmin)
            IconButton(
              tooltip: 'Nuevo ejercicio',
              onPressed: () => _formulario(),
              icon: const Icon(Icons.add_circle_outline_rounded),
            ),
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _cargar,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: brandBlue))
          : RefreshIndicator(
              onRefresh: _cargar,
              color: brandBlue,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pausas activas guiadas',
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'La cámara analiza tu postura y registra cada pausa en tu progreso.',
                              style: TextStyle(color: textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: brandBlue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${_ejercicios.length} disponibles',
                          style: const TextStyle(
                            color: brandBlue,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_sinConexion) ...[
                    const SizedBox(height: 18),
                    _avisoSinConexion(),
                  ],
                  const SizedBox(height: 22),
                  ..._ejercicios.map((e) => _card(e, isDark)),
                ],
              ),
            ),
    );
  }

  Widget _avisoSinConexion() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE1F2FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB3D9FF)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: brandBlue),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'No se pudo conectar con el backend. Los ejercicios no podrán registrarse hasta que vuelvas a intentarlo.',
              style: TextStyle(color: brandNavy, fontSize: 13),
            ),
          ),
          TextButton(onPressed: _cargar, child: const Text('Reintentar')),
        ],
      ),
    );
  }

  Widget _card(_EjercicioItem ejercicio, bool isDark) {
    final card = isDark ? const Color(0xFF111C2E) : Colors.white;
    final border = isDark ? const Color(0xFF24364C) : const Color(0xFFDBEAF3);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100E2238),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: ejercicio.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(ejercicio.icono, color: ejercicio.color, size: 29),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ejercicio.nombre,
                  style: TextStyle(
                    color: isDark ? Colors.white : brandText,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  ejercicio.descripcion,
                  style: TextStyle(
                    color: isDark ? const Color(0xFFCBD5E1) : brandMuted,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip(
                      Icons.schedule_rounded,
                      ejercicio.duracion,
                      brandBlue,
                    ),
                    _chip(
                      Icons.category_rounded,
                      ejercicio.categoria,
                      brandTeal,
                    ),
                    if (ejercicio.id <= 0)
                      _chip(
                        Icons.cloud_off_rounded,
                        'Sin guardar',
                        const Color(0xFFCF3A3A),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              FilledButton.icon(
                onPressed: () => _iniciar(ejercicio),
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: const Text('Iniciar'),
                style: FilledButton.styleFrom(
                  backgroundColor: brandBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              if (_esAdmin)
                PopupMenuButton<String>(
                  tooltip: 'Gestionar ejercicio',
                  onSelected: (value) {
                    if (value == 'editar') _formulario(ejercicio: ejercicio);
                    if (value == 'eliminar') _eliminar(ejercicio);
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'editar',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'eliminar',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Colors.red,
                          ),
                          SizedBox(width: 8),
                          Text('Eliminar', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EjercicioFormDialog extends StatefulWidget {
  final _EjercicioItem? ejercicio;

  const _EjercicioFormDialog({this.ejercicio});

  @override
  State<_EjercicioFormDialog> createState() => _EjercicioFormDialogState();
}

class _EjercicioFormDialogState extends State<_EjercicioFormDialog> {
  late final TextEditingController _nombre;
  late final TextEditingController _descripcion;
  late final TextEditingController _duracion;
  late final TextEditingController _categoria;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final e = widget.ejercicio;
    _nombre = TextEditingController(text: e?.nombre ?? '');
    _descripcion = TextEditingController(text: e?.descripcion ?? '');
    _duracion = TextEditingController(
      text: e == null ? '2' : e.duracionMin.toString(),
    );
    _categoria = TextEditingController(text: e?.categoria ?? 'General');
  }

  @override
  void dispose() {
    _nombre.dispose();
    _descripcion.dispose();
    _duracion.dispose();
    _categoria.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.ejercicio == null ? 'Nuevo ejercicio' : 'Editar ejercicio',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nombre,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descripcion,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _duracion,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Duración (min)',
                        ),
                        validator: (v) {
                          final n = int.tryParse(v?.trim() ?? '');
                          if (n == null || n <= 0) return 'Minutos válidos';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _categoria,
                        decoration: const InputDecoration(
                          labelText: 'Categoría',
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, {
              'nombre': _nombre.text.trim(),
              'descripcion': _descripcion.text.trim(),
              'duracion': int.parse(_duracion.text.trim()),
              'categoria': _categoria.text.trim().isEmpty
                  ? 'General'
                  : _categoria.text.trim(),
            });
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _EjercicioDef {
  final String nombre;
  final int duracionMin;
  final String categoria;
  final IconData icono;
  final Color color;
  final String descripcion;
  final String instrucciones;

  const _EjercicioDef({
    required this.nombre,
    required this.duracionMin,
    required this.categoria,
    required this.icono,
    required this.color,
    required this.descripcion,
    required this.instrucciones,
  });

  _EjercicioItem toItem(int id, {String? duracion}) {
    return _EjercicioItem(
      id: id,
      nombre: nombre,
      duracion: duracion ?? '$duracionMin min',
      duracionMin: duracionMin,
      categoria: categoria,
      icono: icono,
      color: color,
      descripcion: descripcion,
      instrucciones: instrucciones,
    );
  }
}

class _EjercicioItem {
  final int id;
  final String nombre;
  final String duracion;
  final int duracionMin;
  final String categoria;
  final IconData icono;
  final Color color;
  final String descripcion;
  final String instrucciones;

  const _EjercicioItem({
    required this.id,
    required this.nombre,
    required this.duracion,
    required this.duracionMin,
    required this.categoria,
    required this.icono,
    required this.color,
    required this.descripcion,
    required this.instrucciones,
  });

  factory _EjercicioItem.fromDb(
    Map<String, dynamic> data, {
    _EjercicioDef? def,
  }) {
    final nombre = (def?.nombre ?? data['nombre'] ?? 'Ejercicio').toString();
    final minutos = _int(data['duracion']) ?? def?.duracionMin ?? 2;
    final categoria = (def?.categoria ?? data['categoria'] ?? 'General')
        .toString();
    final color = def?.color ?? _colorPara(categoria);
    final descripcion =
        (data['descripcion'] ??
                def?.descripcion ??
                'Ejercicio de pausa activa para tu bienestar laboral.')
            .toString();

    return _EjercicioItem(
      id: _int(data['id']) ?? 0,
      nombre: nombre,
      duracion: '$minutos min',
      duracionMin: minutos,
      categoria: categoria,
      icono: def?.icono ?? _iconoPara(nombre),
      color: color,
      descripcion: descripcion,
      instrucciones: def?.instrucciones ?? '',
    );
  }

  static int? _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static IconData _iconoPara(String nombre) {
    final n = nombre.toLowerCase();
    if (n.contains('cuello')) return Icons.accessibility_new_rounded;
    if (n.contains('hombro')) return Icons.fitness_center_rounded;
    if (n.contains('visual') || n.contains('ojo')) {
      return Icons.visibility_rounded;
    }
    if (n.contains('muñeca') || n.contains('muneca') || n.contains('mano')) {
      return Icons.pan_tool_rounded;
    }
    if (n.contains('brazo')) return Icons.arrow_upward_rounded;
    if (n.contains('codo')) return Icons.fitness_center_rounded;
    if (n.contains('pecho')) return Icons.open_in_full_rounded;
    if (n.contains('tronco') || n.contains('lateral')) {
      return Icons.swap_horiz_rounded;
    }
    return Icons.self_improvement_rounded;
  }

  static Color _colorPara(String categoria) {
    final c = categoria.toLowerCase();
    if (c.contains('cuello')) return brandBlue;
    if (c.contains('hombro')) return brandNavy;
    if (c.contains('vista') || c.contains('visual')) {
      return brandTeal;
    }
    if (c.contains('muñeca') || c.contains('muneca')) {
      return brandCyan;
    }
    if (c.contains('brazo')) return brandBlue;
    if (c.contains('espalda')) return brandTeal;
    return brandBlue;
  }
}
