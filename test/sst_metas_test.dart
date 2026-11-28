import 'package:flutter_test/flutter_test.dart';
import 'package:tarea/data/services/sst_metas_service.dart';

void main() {
  group('SstMetasConfig', () {
    test('clasifica los rangos por defecto', () {
      const metas = SstMetasConfig();

      expect(metas.clasificar(0), 'Sin pausas');
      expect(metas.clasificar(5), 'Bajo');
      expect(metas.clasificar(6), 'Regular');
      expect(metas.clasificar(9), 'Regular');
      expect(metas.clasificar(10), 'Bueno');
      expect(metas.clasificar(14), 'Bueno');
      expect(metas.clasificar(15), 'Excelente');
    });

    test('respeta los valores personalizados del líder SST', () {
      const metas = SstMetasConfig(
        maloHasta: 3,
        buenoDesde: 8,
        excelenteDesde: 12,
      );

      expect(metas.esValido, isTrue);
      expect(metas.clasificar(3), 'Bajo');
      expect(metas.clasificar(7), 'Regular');
      expect(metas.clasificar(8), 'Bueno');
      expect(metas.clasificar(12), 'Excelente');
      expect(metas.resumen, '≤3 · 8–11 · ≥12');
    });

    test('rechaza rangos invertidos y valores fuera de rango', () {
      expect(
        const SstMetasConfig(maloHasta: 10, buenoDesde: 5).esValido,
        isFalse,
      );
      expect(
        const SstMetasConfig(buenoDesde: 20, excelenteDesde: 10).esValido,
        isFalse,
      );
      expect(const SstMetasConfig(excelenteDesde: 101).esValido, isFalse);
    });
  });
}
