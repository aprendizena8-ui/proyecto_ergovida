import '../../widgets/routine_avatar.dart';

/// Uno de los movimientos que forman una rutina guiada.
///
/// Se usa tanto en la tarjeta de la rutina (para mostrar la secuencia) como en
/// la sesión guiada (para cambiar el avatar y el texto en cada fase).
class RoutinePaso {
  final String nombre;
  final String detalle;
  final int segundos;
  final RoutineAvatarKind kind;

  const RoutinePaso({
    required this.nombre,
    required this.detalle,
    required this.segundos,
    required this.kind,
  });

  String get duracionTexto => '$segundos s';
}
