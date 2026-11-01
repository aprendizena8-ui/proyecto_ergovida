import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ProfilePreferences {
  static String _key(int userId) => 'profile_data_$userId';

  static Future<ProfileData> load(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(userId));

    var data = ProfileData.empty();
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          data = ProfileData.fromJson(Map<String, dynamic>.from(decoded));
        }
      } on FormatException {
        data = ProfileData.empty();
      }
    }

    if (data.miembroDesde == null) {
      data = data.copyWith(miembroDesde: DateTime.now());
      await save(userId, data);
    }

    return data;
  }

  static Future<void> save(int userId, ProfileData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(userId), jsonEncode(data.toJson()));
  }

  static Future<void> remove(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(userId));
  }
}

class ProfileData {
  final String telefono;
  final String cargo;
  final String ciudad;
  final String fechaNacimiento;
  final String biografia;
  final DateTime? miembroDesde;
  final bool notificaciones;
  final bool recordatorios;

  const ProfileData({
    this.telefono = '',
    this.cargo = '',
    this.ciudad = '',
    this.fechaNacimiento = '',
    this.biografia = '',
    this.miembroDesde,
    this.notificaciones = true,
    this.recordatorios = true,
  });

  factory ProfileData.empty() => const ProfileData();

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      telefono: (json['telefono'] ?? '').toString(),
      cargo: (json['cargo'] ?? '').toString(),
      ciudad: (json['ciudad'] ?? '').toString(),
      fechaNacimiento: (json['fechaNacimiento'] ?? '').toString(),
      biografia: (json['biografia'] ?? '').toString(),
      miembroDesde: DateTime.tryParse((json['miembroDesde'] ?? '').toString()),
      notificaciones: json['notificaciones'] is bool
          ? json['notificaciones'] as bool
          : true,
      recordatorios: json['recordatorios'] is bool
          ? json['recordatorios'] as bool
          : true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'telefono': telefono,
      'cargo': cargo,
      'ciudad': ciudad,
      'fechaNacimiento': fechaNacimiento,
      'biografia': biografia,
      'miembroDesde': miembroDesde?.toIso8601String() ?? '',
      'notificaciones': notificaciones,
      'recordatorios': recordatorios,
    };
  }

  ProfileData copyWith({
    String? telefono,
    String? cargo,
    String? ciudad,
    String? fechaNacimiento,
    String? biografia,
    DateTime? miembroDesde,
    bool? notificaciones,
    bool? recordatorios,
  }) {
    return ProfileData(
      telefono: telefono ?? this.telefono,
      cargo: cargo ?? this.cargo,
      ciudad: ciudad ?? this.ciudad,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      biografia: biografia ?? this.biografia,
      miembroDesde: miembroDesde ?? this.miembroDesde,
      notificaciones: notificaciones ?? this.notificaciones,
      recordatorios: recordatorios ?? this.recordatorios,
    );
  }
}
