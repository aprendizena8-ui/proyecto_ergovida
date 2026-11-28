import 'package:flutter/material.dart';

import '../../data/services/auth_service.dart';
import '../../data/services/ejercicio_service.dart';
import '../../main.dart';
import 'exercise_camera_logic.dart';
import 'exercise_camera_models.dart';
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
  bool get _esAdmin => widget.esAdmin ?? AuthService.isAdmin;
  bool get _puedeCrearEjercicios => _esAdmin || AuthService.isLiderSst;

  static const List<_EjercicioDef> _definiciones = [
    _EjercicioDef(
      nombre: 'Estiramiento de Cuello',
      duracionMin: 4,
      categoria: 'Cuello',
      icono: Icons.accessibility_new_rounded,
      color: brandBlue,
      kind: ExerciseKind.neck,
      descripcion:
          'Libera la tensión del cuello con inclinaciones laterales suaves y controladas.',
      instrucciones:
          'Pon la cabeza recta, mira al frente y realiza pequeños movimientos lentos.',
    ),
    _EjercicioDef(
      nombre: 'Movilidad de Hombros',
      duracionMin: 5,
      categoria: 'Hombros',
      icono: Icons.fitness_center_rounded,
      color: brandNavy,
      kind: ExerciseKind.shoulders,
      descripcion:
          'Activa la circulación de hombros y espalda alta con encogimientos y círculos.',
      instrucciones:
          'Eleva y baja los hombros con control, manteniendo la espalda recta.',
    ),
    _EjercicioDef(
      nombre: 'Descanso Visual',
      duracionMin: 5,
      categoria: 'Vista',
      icono: Icons.visibility_rounded,
      color: brandTeal,
      kind: ExerciseKind.visual,
      descripcion:
          'Reduce la fatiga visual alternando la mirada lejana con el descanso ocular.',
      instrucciones:
          'Mira a lo lejos y alterna la mirada para aliviar la fatiga visual.',
    ),
    _EjercicioDef(
      nombre: 'Movilidad de Muñecas',
      duracionMin: 4,
      categoria: 'Muñecas',
      icono: Icons.pan_tool_rounded,
      color: brandCyan,
      kind: ExerciseKind.wrists,
      descripcion:
          'Previene molestias por teclado y mouse movilizando tus muñecas.',
      instrucciones:
          'Gira las muñecas con suavidad y mantén codos flexionados.',
    ),
    _EjercicioDef(
      nombre: 'Elevación de Brazos',
      duracionMin: 4,
      categoria: 'Brazos',
      icono: Icons.arrow_upward_rounded,
      color: brandBlue,
      kind: ExerciseKind.armsUp,
      descripcion:
          'Moviliza hombros y brazos con elevaciones completas por encima de la cabeza.',
      instrucciones:
          'Sube ambos brazos estirados y bájalos con control, sin arquear la espalda.',
    ),
    _EjercicioDef(
      nombre: 'Flexión de Codos',
      duracionMin: 4,
      categoria: 'Brazos',
      icono: Icons.fitness_center_rounded,
      color: brandNavy,
      kind: ExerciseKind.curls,
      descripcion:
          'Activa brazos y antebrazos con flexiones de codo controladas junto al cuerpo.',
      instrucciones:
          'Lleva las manos hacia los hombros y extiende los brazos sin separar los codos.',
    ),
    _EjercicioDef(
      nombre: 'Apertura de Pecho',
      duracionMin: 5,
      categoria: 'Espalda',
      icono: Icons.open_in_full_rounded,
      color: brandTeal,
      kind: ExerciseKind.chest,
      descripcion:
          'Contrarresta la postura encorvada abriendo el pecho y juntando los omóplatos.',
      instrucciones:
          'Abre los brazos a la altura de los hombros y mantén la apertura unos segundos.',
    ),
    _EjercicioDef(
      nombre: 'Inclinación Lateral de Tronco',
      duracionMin: 5,
      categoria: 'Espalda',
      icono: Icons.swap_horiz_rounded,
      color: brandCyan,
      kind: ExerciseKind.sideBend,
      descripcion:
          'Estira la espalda y los costados con inclinaciones laterales suaves del tronco.',
      instrucciones:
          'Inclina el tronco hacia un lado sin mover las caderas, mantén y cambia de lado.',
    ),
    _EjercicioDef(
      nombre: 'Rotación de Cuello',
      duracionMin: 4,
      categoria: 'Cuello',
      icono: Icons.screen_rotation_rounded,
      color: brandBlue,
      kind: ExerciseKind.neckRotation,
      descripcion:
          'Mejora la movilidad cervical girando la cabeza a cada lado sin mover los hombros.',
      instrucciones:
          'Gira la cabeza como mirando por encima del hombro, mantén y cambia de lado.',
    ),
    _EjercicioDef(
      nombre: 'Flexión y Extensión de Cuello',
      duracionMin: 4,
      categoria: 'Cuello',
      icono: Icons.swap_vert_rounded,
      color: brandNavy,
      kind: ExerciseKind.neckNod,
      descripcion:
          'Alivia la tensión cervical alternando la barbilla al pecho y la mirada al techo.',
      instrucciones:
          'Baja la barbilla sin encorvar la espalda, vuelve al centro y mira hacia arriba.',
    ),
    _EjercicioDef(
      nombre: 'Círculos de Brazos',
      duracionMin: 4,
      categoria: 'Hombros',
      icono: Icons.refresh_rounded,
      color: brandTeal,
      kind: ExerciseKind.armCircles,
      descripcion:
          'Activa hombros y espalda alta dibujando círculos amplios con los brazos extendidos.',
      instrucciones:
          'Abre los brazos a la altura de los hombros y dibuja círculos lentos en ambas direcciones.',
    ),
    _EjercicioDef(
      nombre: 'Elevación Lateral de Brazos',
      duracionMin: 4,
      categoria: 'Hombros',
      icono: Icons.open_with_rounded,
      color: brandCyan,
      kind: ExerciseKind.lateralRaise,
      descripcion:
          'Fortalece los hombros elevando los brazos hasta la altura de la línea del hombro.',
      instrucciones:
          'Sube ambos brazos hacia los lados hasta la altura de los hombros y baja con control.',
    ),
    _EjercicioDef(
      nombre: 'Abrazo de Oso',
      duracionMin: 4,
      categoria: 'Espalda',
      icono: Icons.accessibility_new_rounded,
      color: brandBlue,
      kind: ExerciseKind.selfHug,
      descripcion:
          'Estira la espalda alta cruzando los brazos frente al pecho como un abrazo.',
      instrucciones:
          'Cruza los brazos y lleva cada mano al hombro opuesto; mantén y abre lentamente.',
    ),
    _EjercicioDef(
      nombre: 'Prensa de Palmas',
      duracionMin: 4,
      categoria: 'Pecho',
      icono: Icons.front_hand_rounded,
      color: brandNavy,
      kind: ExerciseKind.prayerPress,
      descripcion:
          'Activa pecho y brazos presionando las palmas juntas frente al esternón.',
      instrucciones:
          'Junta las palmas, mantén los codos afuera y presiona suavemente sin subir los hombros.',
    ),
    _EjercicioDef(
      nombre: 'Estiramiento Cruzado de Hombro',
      duracionMin: 5,
      categoria: 'Hombros',
      icono: Icons.sync_alt_rounded,
      color: brandTeal,
      kind: ExerciseKind.crossShoulder,
      descripcion:
          'Libera la parte posterior del hombro llevando un brazo cruzado al pecho.',
      instrucciones:
          'Pasa un brazo frente al pecho, sujeta el codo con la otra mano y mantén; cambia de lado.',
    ),
    _EjercicioDef(
      nombre: 'Postura de Cactus',
      duracionMin: 5,
      categoria: 'Espalda',
      icono: Icons.accessibility_new_rounded,
      color: brandCyan,
      kind: ExerciseKind.goalpost,
      descripcion:
          'Corrige la postura con codos en cruz y antebrazos hacia arriba, juntando omóplatos.',
      instrucciones:
          'Levanta los codos a la altura de los hombros, manos arriba, y mantén la postura.',
    ),
    _EjercicioDef(
      nombre: 'Encogimiento Alterno de Hombros',
      duracionMin: 4,
      categoria: 'Hombros',
      icono: Icons.unfold_more_rounded,
      color: brandNavy,
      kind: ExerciseKind.alternatingShrug,
      descripcion:
          'Relaja cuello y hombros subiendo un hombro a la vez de forma controlada.',
      instrucciones:
          'Sube un hombro hacia la oreja, baja y sube el otro, alternando sin mover la cabeza.',
    ),
    _EjercicioDef(
      nombre: 'Apertura de Dedos',
      duracionMin: 4,
      categoria: 'Manos',
      icono: Icons.pan_tool_rounded,
      color: brandTeal,
      kind: ExerciseKind.fingerSpread,
      descripcion:
          'Estimula manos y antebrazos abriendo y cerrando los dedos por completo.',
      instrucciones:
          'Levanta las manos, abre bien los dedos y cierra en puño suave; repite.',
    ),
    _EjercicioDef(
      nombre: 'Círculos de Antebrazos',
      duracionMin: 4,
      categoria: 'Codos',
      icono: Icons.autorenew_rounded,
      color: brandCyan,
      kind: ExerciseKind.forearmCircles,
      descripcion:
          'Moviliza codos y muñecas dibujando círculos con los antebrazos junto al cuerpo.',
      instrucciones:
          'Mantén los codos pegados al costado y dibuja círculos con las manos.',
    ),
    _EjercicioDef(
      nombre: 'Toques de Hombro Alternos',
      duracionMin: 4,
      categoria: 'Hombros',
      icono: Icons.touch_app_rounded,
      color: brandBlue,
      kind: ExerciseKind.shoulderTaps,
      descripcion:
          'Mejora la coordinación y movilidad de hombros tocando el hombro opuesto.',
      instrucciones:
          'Toca el hombro contrario con una mano, vuelve y alterna con la otra.',
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

    // Refresca id y rol desde el backend para no crear el catálogo con una
    // sesión obsoleta (mismo problema que se corrigió en el panel admin).
    if (widget.usuarioId == null && AuthService.usuarioId > 0) {
      await AuthService.restoreSession();
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
        // Solo los roles con permiso de escritura pueden dar de alta el
        // catálogo. Para el resto mostramos el ejercicio en modo local para
        // que pueda practicarlo aunque todavía no exista en la base de datos.
        if (!_puedeCrearEjercicios) {
          items.add(def.toItem(0));
          continue;
        }

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
      _sinConexion =
          registros.isEmpty && items.every((ejercicio) => ejercicio.id <= 0);
      _cargando = false;
    });

    if (fallos > 0) {
      final detalle = EjercicioService.ultimoError;
      _mensaje(
        detalle ?? 'No se pudieron registrar $fallos ejercicios en el servidor.',
        ok: false,
      );
    }
  }

  Future<void> _iniciar(_EjercicioItem ejercicio) async {
    if (_usuarioId <= 0) {
      _mensaje('Inicia sesión para registrar tus pausas.', ok: false);
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExerciseCameraPage(
          nombre: ejercicio.nombre,
          duracion: ejercicio.duracion,
          icono: ejercicio.icono,
          kind: ejercicio.kind,
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
                              'Los ejercicios con detección de movimiento cuentan para SST. '
                              'El descanso visual y los genéricos solo suman a logros.',
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
                  ..._seccionEjercicios(
                    'Cuentan para SST',
                    'Ejercicios con detección de movimiento confirmada.',
                    _ejercicios.where(_cuentaParaSst).toList(),
                    isDark,
                  ),
                  ..._seccionEjercicios(
                    'No cuentan para SST',
                    'Descanso visual y ejercicios genéricos: solo suman a logros.',
                    _ejercicios.where((e) => !_cuentaParaSst(e)).toList(),
                    isDark,
                  ),
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

  bool _cuentaParaSst(_EjercicioItem ejercicio) {
    final kind = kindFor(ejercicio.nombre);
    return kind != ExerciseKind.visual && kind != ExerciseKind.other;
  }

  List<Widget> _seccionEjercicios(
    String titulo,
    String descripcion,
    List<_EjercicioItem> ejercicios,
    bool isDark,
  ) {
    if (ejercicios.isEmpty) return const [];

    final esSst = titulo == 'Cuentan para SST';
    final color = esSst ? brandTeal : const Color(0xFFF59E0B);
    final textPrimary = isDark ? Colors.white : brandNavy;
    final textSecondary = isDark ? const Color(0xFFCBD5E1) : brandMuted;

    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            esSst ? Icons.verified_rounded : Icons.info_outline_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  descripcion,
                  style: TextStyle(color: textSecondary, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      ...ejercicios.map((e) => _card(e, isDark)),
      const SizedBox(height: 10),
    ];
  }

  Widget _card(_EjercicioItem ejercicio, bool isDark) {
    final card = isDark ? const Color(0xFF111C2E) : Colors.white;
    final border = isDark ? const Color(0xFF24364C) : const Color(0xFFDBEAF3);
    final cuentaSst = _cuentaParaSst(ejercicio);

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
                    _chip(
                      cuentaSst
                          ? Icons.check_circle_outline_rounded
                          : Icons.info_outline_rounded,
                      cuentaSst ? 'Cuenta para SST' : 'No cuenta para SST',
                      cuentaSst ? brandTeal : const Color(0xFFF59E0B),
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
      text: e == null ? '4' : e.duracionMin.toString(),
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
                          if (n == null || n < 4 || n > 30) {
                            return 'Entre 4 y 30 minutos';
                          }
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
  final ExerciseKind kind;
  final String descripcion;
  final String instrucciones;

  const _EjercicioDef({
    required this.nombre,
    required this.duracionMin,
    required this.categoria,
    required this.icono,
    required this.color,
    required this.kind,
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
      kind: kind,
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
  final ExerciseKind kind;
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
    required this.kind,
    required this.descripcion,
    required this.instrucciones,
  });

  factory _EjercicioItem.fromDb(
    Map<String, dynamic> data, {
    _EjercicioDef? def,
  }) {
    final nombre = (def?.nombre ?? data['nombre'] ?? 'Ejercicio').toString();
    var minutos = _int(data['duracion']) ?? def?.duracionMin ?? 3;
    // Los ejercicios del catálogo ya sembrados en el backend tenían tiempos
    // muy cortos (1-3 min). Respetamos valores personalizados más largos, pero
    // nunca mostramos menos del nuevo mínimo recomendado.
    if (def != null && minutos < def.duracionMin) {
      minutos = def.duracionMin;
    }
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
      kind: def?.kind ?? kindFor(nombre),
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
