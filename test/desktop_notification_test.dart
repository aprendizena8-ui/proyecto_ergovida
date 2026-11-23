import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarea/data/services/desktop_notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('local_notifier');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'setup') return true;
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('muestra un recordatorio como notificación del sistema', () async {
    if (!DesktopNotificationService.instance.disponible) return;

    await DesktopNotificationService.instance.mostrar(
      titulo: 'ErgoVida - Tu pausa activa',
      cuerpo: 'Es momento de estirar el cuerpo.',
    );

    final notify = calls.firstWhere((call) => call.method == 'notify');
    expect(notify.arguments['title'], 'ErgoVida - Tu pausa activa');
    expect(notify.arguments['body'], contains('estirar el cuerpo'));
    expect(notify.arguments['subtitle'], 'ErgoVida');
  });
}
