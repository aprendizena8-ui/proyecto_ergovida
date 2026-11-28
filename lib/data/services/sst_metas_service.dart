import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Rangos de pausas activas diarias definidos por el líder SST.
///
/// El backend no expone aún un endpoint de configuración, así que la
/// personalización se guarda en el dispositivo del líder SST y se usa para
/// colorear y clasificar las barras de la gráfica semanal.
class SstMetasConfig {
  /// Pausas por debajo o igual a este valor se consideran 'Bajo'.
  final int maloHasta;

  /// Desde este valor se considera 'Bueno'.
  final int buenoDesde;

  /// Desde este valor se considera 'Excelente'.
  final int excelenteDesde;

  const SstMetasConfig({
    this.maloHasta = 5,
    this.buenoDesde = 10,
    this.excelenteDesde = 15,
  });

  static const int maximo = 100;

  bool get esValido =>
      maloHasta >= 0 &&
      maloHasta < buenoDesde &&
      buenoDesde <= excelenteDesde &&
      excelenteDesde <= maximo;

  /// Etiqueta corta para el panel SST, p. ej. '≤5 · 10–14 · ≥15'.
  String get resumen =>
      '≤$maloHasta · $buenoDesde–${excelenteDesde - 1} · ≥$excelenteDesde';

  String clasificar(int pausas) {
    if (pausas <= 0) return 'Sin pausas';
    if (pausas <= maloHasta) return 'Bajo';
    if (pausas < buenoDesde) return 'Regular';
    if (pausas < excelenteDesde) return 'Bueno';
    return 'Excelente';
  }

  Map<String, dynamic> toJson() => {
    'maloHasta': maloHasta,
    'buenoDesde': buenoDesde,
    'excelenteDesde': excelenteDesde,
  };

  factory SstMetasConfig.fromJson(Map<String, dynamic> json) {
    final candidata = SstMetasConfig(
      maloHasta: _leerEntero(json['maloHasta'], 5),
      buenoDesde: _leerEntero(json['buenoDesde'], 10),
      excelenteDesde: _leerEntero(json['excelenteDesde'], 15),
    );
    return candidata.esValido ? candidata : const SstMetasConfig();
  }

  static int _leerEntero(dynamic valor, int fallback) {
    if (valor is int) return valor;
    if (valor is num) return valor.toInt();
    return int.tryParse(valor?.toString() ?? '') ?? fallback;
  }
}

class SstMetasService {
  SstMetasService._();

  static final SstMetasService instance = SstMetasService._();

  static const String _clave = 'sst_metas_pausas_v1';

  Future<SstMetasConfig> cargar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Compatibilidad: primero se intenta leer el JSON único; si no existe,
      // se leen las tres claves separadas escritas por [guardar].
      final raw = prefs.getString(_clave);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return SstMetasConfig.fromJson(Map<String, dynamic>.from(decoded));
        }
      }
      final guardada = SstMetasConfig(
        maloHasta: prefs.getInt('${_clave}_maloHasta') ?? 5,
        buenoDesde: prefs.getInt('${_clave}_buenoDesde') ?? 10,
        excelenteDesde: prefs.getInt('${_clave}_excelenteDesde') ?? 15,
      );
      return guardada.esValido ? guardada : const SstMetasConfig();
    } catch (_) {
      return const SstMetasConfig();
    }
  }

  Future<void> guardar(SstMetasConfig config) async {
    if (!config.esValido) {
      throw ArgumentError('Los rangos de metas SST no son válidos.');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${_clave}_maloHasta', config.maloHasta);
    await prefs.setInt('${_clave}_buenoDesde', config.buenoDesde);
    await prefs.setInt('${_clave}_excelenteDesde', config.excelenteDesde);
  }
}
