import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/services/sst_metas_service.dart';

/// Diálogo usado por el líder SST para definir los rangos diarios de pausas.
class SstMetasDialog extends StatefulWidget {
  final SstMetasConfig config;

  const SstMetasDialog({super.key, required this.config});

  @override
  State<SstMetasDialog> createState() => _SstMetasDialogState();
}

class _SstMetasDialogState extends State<SstMetasDialog> {
  late final TextEditingController _malo;
  late final TextEditingController _bueno;
  late final TextEditingController _excelente;
  String? _error;

  @override
  void initState() {
    super.initState();
    _malo = TextEditingController(text: '${widget.config.maloHasta}');
    _bueno = TextEditingController(text: '${widget.config.buenoDesde}');
    _excelente = TextEditingController(text: '${widget.config.excelenteDesde}');
  }

  @override
  void dispose() {
    _malo.dispose();
    _bueno.dispose();
    _excelente.dispose();
    super.dispose();
  }

  SstMetasConfig get _configActual => SstMetasConfig(
    maloHasta: int.tryParse(_malo.text.trim()) ?? -1,
    buenoDesde: int.tryParse(_bueno.text.trim()) ?? -1,
    excelenteDesde: int.tryParse(_excelente.text.trim()) ?? -1,
  );

  void _guardar() {
    final config = _configActual;
    if (!config.esValido) {
      setState(() {
        _error =
            'Los valores deben cumplir: bajo < bueno ≤ excelente '
            '(máximo ${SstMetasConfig.maximo} pausas).';
      });
      return;
    }
    Navigator.pop(context, config);
  }

  @override
  Widget build(BuildContext context) {
    final preview = _configActual;
    final textoBajo = preview.maloHasta >= 0 ? '≤ ${preview.maloHasta}' : '—';
    final textoRegular = preview.buenoDesde > preview.maloHasta + 1
        ? '${preview.maloHasta + 1}–${preview.buenoDesde - 1}'
        : '—';
    final textoBueno = preview.excelenteDesde > preview.buenoDesde
        ? '${preview.buenoDesde}–${preview.excelenteDesde - 1}'
        : '—';
    final textoExcelente = preview.excelenteDesde >= 0
        ? '≥ ${preview.excelenteDesde}'
        : '—';

    return AlertDialog(
      title: const Text('Metas de pausas activas'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Define cuántas pausas activas al día son un buen rango para '
              'los usuarios. La gráfica usará estos colores:',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _malo,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Bajo (rojo) hasta',
                hintText: '5',
                helperText: '5 o menos se considera bajo',
                prefixIcon: Icon(Icons.arrow_downward_rounded),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _bueno,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Bueno (azul) desde',
                hintText: '10',
                helperText: 'Meta diaria sugerida',
                prefixIcon: Icon(Icons.check_circle_outline_rounded),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _excelente,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Excelente (verde) desde',
                hintText: '15',
                helperText: 'A partir de aquí se considera excelente',
                prefixIcon: Icon(Icons.emoji_events_outlined),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppPalette.backgroundDeep,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppPalette.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vista previa',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _chip(AppPalette.danger, 'Bajo $textoBajo'),
                      _chip(AppPalette.warning, 'Regular $textoRegular'),
                      _chip(AppPalette.blue, 'Bueno $textoBueno'),
                      _chip(AppPalette.success, 'Excelente $textoExcelente'),
                    ],
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(
                  color: AppPalette.danger,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _guardar, child: const Text('Guardar')),
      ],
    );
  }

  Widget _chip(Color color, String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            texto,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
