import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:local_notifier/local_notifier.dart';

class DesktopNotificationService {
  DesktopNotificationService._();

  static final DesktopNotificationService instance =
      DesktopNotificationService._();

  bool _inicializado = false;

  bool get disponible =>
      !kIsWeb &&
      (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  Future<void> inicializar() async {
    if (!disponible || _inicializado) return;
    try {
      await localNotifier.setup(appName: 'ErgoVida');
      _inicializado = true;
    } catch (error) {
      debugPrint('No se pudo iniciar el notificador de escritorio: $error');
    }
  }

  Future<void> mostrar({
    required String titulo,
    required String cuerpo,
    String subtitulo = 'ErgoVida',
  }) async {
    if (!disponible) return;
    await inicializar();
    if (!_inicializado) return;

    try {
      final notificacion = LocalNotification(
        title: titulo,
        subtitle: subtitulo,
        body: cuerpo,
      );
      await notificacion.show();
    } catch (error) {
      debugPrint('No se pudo mostrar la notificación de escritorio: $error');
    }
  }
}
