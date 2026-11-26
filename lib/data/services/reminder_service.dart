import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/recordatorio_global_model.dart';
import '../models/user_model.dart';
import 'desktop_notification_service.dart';
import 'horario_service.dart';
import 'profile_preferences.dart';
import 'recordatorio_global_service.dart';

class ReminderService {
  ReminderService._();

  static final ReminderService instance = ReminderService._();
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  final HorarioService _horarioService = HorarioService();
  final RecordatorioGlobalService _recordatorioGlobalService =
      RecordatorioGlobalService();

  Timer? _timer;
  int? _usuarioId;
  bool _notificaciones = true;
  bool _recordatorios = true;
  int _ticks = 0;
  int _bannerToken = 0;
  List<_ReminderTime> _horarios = const [];
  List<RecordatorioGlobal> _globales = const [];
  Future<void> _refreshChain = Future<void>.value();

  Future<void> start(UserModel usuario) async {
    await DesktopNotificationService.instance.inicializar();
    _usuarioId = usuario.id;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _tick());
    await refresh();
    await _tick();
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _usuarioId = null;
    _horarios = const [];
    _globales = const [];
    _ticks = 0;
  }

  Future<void> refresh() {
    final next = _refreshChain.then((_) => _performRefresh());
    _refreshChain = next.then<void>((_) {}, onError: (_, _) {});
    return next;
  }

  Future<void> _performRefresh() async {
    final usuarioId = _usuarioId;
    if (usuarioId == null) return;

    final perfil = await ProfilePreferences.load(usuarioId);
    if (_usuarioId != usuarioId) return;

    _notificaciones = perfil.notificaciones;
    _recordatorios = perfil.recordatorios;

    try {
      _globales = await _recordatorioGlobalService.obtenerTodos(
        soloActivos: true,
      );
    } catch (_) {
      _globales = const [];
    }
    if (_usuarioId != usuarioId) return;

    if (!_recordatorios) {
      _horarios = const [];
      return;
    }

    final data = await _horarioService.obtenerPorUsuario(usuarioId);
    if (_usuarioId != usuarioId) return;

    _horarios = data
        .whereType<Map>()
        .map((item) => _ReminderTime.fromJson(Map<String, dynamic>.from(item)))
        .whereType<_ReminderTime>()
        .toSet()
        .toList();
  }

  Future<void> checkNow() => _tick();

  Future<void> _tick() async {
    try {
      final usuarioId = _usuarioId;
      if (usuarioId == null) return;

      _ticks++;
      if (_ticks % 4 == 0) {
        await refresh();
      }

      if (!_notificaciones) return;
      if (_horarios.isEmpty && _globales.isEmpty) return;

      final ahora = DateTime.now();
      final marca =
          '${ahora.year}-${ahora.month}-${ahora.day}-'
          '${ahora.hour}-${ahora.minute}';
      final prefs = await SharedPreferences.getInstance();

      if (_recordatorios) {
        _ReminderTime? vencido;
        for (final horario in _horarios) {
          if (horario.hour == ahora.hour && horario.minute == ahora.minute) {
            vencido = horario;
            break;
          }
        }

        if (vencido != null) {
          final storageKey = 'reminder_shown_$usuarioId';
          if (prefs.getString(storageKey) != marca) {
            await prefs.setString(storageKey, marca);
            await _mostrarNotificacion(vencido);
            return;
          }
        }
      }

      for (final global in _globales) {
        if (!global.esHoy) continue;
        final partes = global.hora.split(':');
        if (partes.length < 2) continue;
        final hora = int.tryParse(partes[0]);
        final minuto = int.tryParse(partes[1]);
        if (hora != ahora.hour || minuto != ahora.minute) continue;

        final storageKey = 'global_reminder_shown_${usuarioId}_${global.id}';
        if (prefs.getString(storageKey) == marca) continue;
        await prefs.setString(storageKey, marca);
        await _mostrarNotificacionGlobal(global);
        return;
      }
    } catch (error) {
      debugPrint('No se pudo comprobar el recordatorio: $error');
    }
  }

  Future<void> _mostrarNotificacionGlobal(
    RecordatorioGlobal recordatorio,
  ) async {
    const titulo = 'ErgoVida - Recordatorio de bienestar';
    final cuerpo = recordatorio.mensaje;

    final messenger = messengerKey.currentState;
    if (messenger != null) {
      final token = ++_bannerToken;
      messenger.hideCurrentMaterialBanner();
      messenger.showMaterialBanner(
        MaterialBanner(
          backgroundColor: const Color(0xFFEAF6FF),
          leading: const Icon(Icons.campaign_rounded, color: Color(0xFF1F7FC0)),
          content: Text(
            cuerpo,
            style: const TextStyle(color: Color(0xFF10243A)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (token == _bannerToken) {
                  messenger.hideCurrentMaterialBanner();
                }
              },
              child: const Text('Entendido'),
            ),
          ],
        ),
      );

      Timer(const Duration(seconds: 30), () {
        if (token == _bannerToken) {
          messenger.hideCurrentMaterialBanner();
        }
      });
    }

    await DesktopNotificationService.instance.mostrar(
      titulo: titulo,
      cuerpo: cuerpo,
    );
  }

  Future<void> _mostrarNotificacion(_ReminderTime horario) async {
    final cuerpo =
        'Es momento de tu pausa activa de las ${horario.label}. '
        'Estira el cuerpo y descansa la vista.';
    const titulo = 'ErgoVida - Tu pausa activa';

    final messenger = messengerKey.currentState;
    if (messenger != null) {
      final token = ++_bannerToken;
      messenger.hideCurrentMaterialBanner();
      messenger.showMaterialBanner(
        MaterialBanner(
          backgroundColor: const Color(0xFFEAF6FF),
          leading: const Icon(Icons.alarm_rounded, color: Color(0xFF1F7FC0)),
          content: Text(
            cuerpo,
            style: const TextStyle(color: Color(0xFF10243A)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (token == _bannerToken) {
                  messenger.hideCurrentMaterialBanner();
                }
              },
              child: const Text('Entendido'),
            ),
          ],
        ),
      );

      Timer(const Duration(seconds: 30), () {
        if (token == _bannerToken) {
          messenger.hideCurrentMaterialBanner();
        }
      });
    }

    // En móvil no existe el plugin local_notifier: el servicio ya comprueba
    // la plataforma y solo muestra la notificación en escritorio.
    await DesktopNotificationService.instance.mostrar(
      titulo: titulo,
      cuerpo: cuerpo,
    );
  }
}

class _ReminderTime {
  final int hour;
  final int minute;

  const _ReminderTime(this.hour, this.minute);

  String get label {
    final sufijo = hour >= 12 ? 'PM' : 'AM';
    final hora12 = hour % 12 == 0 ? 12 : hour % 12;
    final minutos = minute.toString().padLeft(2, '0');
    return '$hora12:$minutos $sufijo';
  }

  static _ReminderTime? fromJson(Map<String, dynamic> json) {
    final hora = json['hora']?.toString() ?? '';
    final partes = hora.split(':');
    if (partes.length < 2) return null;

    final hour = int.tryParse(partes[0]);
    final minute = int.tryParse(partes[1]);
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }
    return _ReminderTime(hour, minute);
  }

  @override
  bool operator ==(Object other) =>
      other is _ReminderTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);
}
