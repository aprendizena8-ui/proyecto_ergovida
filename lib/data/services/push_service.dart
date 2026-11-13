import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';

/// Registra el dispositivo para recibir notificaciones push con FCM.
///
/// Las claves se inyectan al compilar (no se guardan en el codigo):
///   --dart-define=FIREBASE_API_KEY=...
///   --dart-define=FIREBASE_APP_ID=...
///   --dart-define=FIREBASE_MESSAGING_SENDER_ID=...
///   --dart-define=FIREBASE_PROJECT_ID=...
///   --dart-define=FIREBASE_STORAGE_BUCKET=...
class PushService {
  PushService._();

  static final PushService instance = PushService._();

  bool _firebaseListo = false;
  bool _permisoConcedido = false;
  bool _listenersRegistrados = false;

  Future<void> inicializar() async {
    if (kIsWeb) return;

    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    if (_firebaseListo) {
      await _registrarTokenActual();
      return;
    }

    const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
    const appId = String.fromEnvironment('FIREBASE_APP_ID');
    const senderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
    const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
    const storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');

    if (apiKey.isEmpty ||
        appId.isEmpty ||
        senderId.isEmpty ||
        projectId.isEmpty) {
      debugPrint(
        'PushService: Firebase no esta configurado. '
        'Los recordatorios seguiran llegando por correo.',
      );
      return;
    }

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: FirebaseOptions(
            apiKey: apiKey,
            appId: appId,
            messagingSenderId: senderId,
            projectId: projectId,
            storageBucket: storageBucket.isEmpty ? null : storageBucket,
          ),
        );
      }

      final messaging = FirebaseMessaging.instance;

      final ajustes = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (ajustes.authorizationStatus == AuthorizationStatus.denied) {
        _firebaseListo = true;
        debugPrint('PushService: permiso de notificaciones denegado.');
        return;
      }

      _permisoConcedido = true;
      _firebaseListo = true;
      await _registrarTokenActual();

      if (!_listenersRegistrados) {
        _listenersRegistrados = true;
        messaging.onTokenRefresh.listen(_registrarToken);

        FirebaseMessaging.onMessage.listen((mensaje) {
          debugPrint(
            'Push recibido: ${mensaje.notification?.title ?? ''} '
            '${mensaje.notification?.body ?? ''}',
          );
        });
      }
    } catch (error) {
      debugPrint('PushService: no se pudo iniciar Firebase: $error');
    }
  }

  Future<void> _registrarTokenActual() async {
    if (!_permisoConcedido || ApiClient.currentUserId <= 0) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await _registrarToken(token);
      }
    } catch (error) {
      debugPrint('PushService: no se pudo obtener el token: $error');
    }
  }

  Future<void> _registrarToken(String token) async {
    if (ApiClient.currentUserId <= 0) return;

    try {
      await ApiClient.post('/push/tokens', {
        'token': token,
        'plataforma': _plataforma(),
      });
    } catch (error) {
      debugPrint('PushService: no se pudo registrar el token: $error');
    }
  }

  Future<void> eliminarTokenActual() async {
    if (kIsWeb || !_firebaseListo || ApiClient.currentUserId <= 0) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await ApiClient.delete('/push/tokens', body: {'token': token});
    } catch (error) {
      debugPrint('PushService: no se pudo eliminar el token: $error');
    }
  }

  String _plataforma() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return 'otra';
    }
  }
}
