import 'package:flutter/material.dart';

import '../data/models/avatar_catalog.dart';

class AvatarBadge extends StatelessWidget {
  final String? avatarId;
  final double size;
  final Color? ringColor;
  final double ringWidth;
  final bool showGlow;

  const AvatarBadge({
    super.key,
    required this.avatarId,
    this.size = 48,
    this.ringColor,
    this.ringWidth = 0,
    this.showGlow = true,
  });

  static const List<List<Color>> _gradients = [
    [Color(0xFF2563EB), Color(0xFF22D3EE)],
    [Color(0xFF0EA5E9), Color(0xFF2DD4BF)],
    [Color(0xFF8B5CF6), Color(0xFFEC4899)],
    [Color(0xFFF59E0B), Color(0xFFEF4444)],
    [Color(0xFF10B981), Color(0xFF84CC16)],
    [Color(0xFF6366F1), Color(0xFFA855F7)],
    [Color(0xFFEC4899), Color(0xFFF97316)],
    [Color(0xFF14B8A6), Color(0xFF0EA5E9)],
    [Color(0xFFF97316), Color(0xFFFACC15)],
    [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
    [Color(0xFFEF4444), Color(0xFFF472B6)],
    [Color(0xFF22C55E), Color(0xFF14B8A6)],
  ];

  static List<Color> gradientFor(String id) {
    final numero = int.tryParse(id.replaceAll(RegExp(r'\D'), '')) ?? 1;
    return _gradients[(numero - 1).abs() % _gradients.length];
  }

  static Color colorFor(String id) => gradientFor(id).first;

  Widget _core(BuildContext context) {
    final option = AvatarCatalog.byId(avatarId);
    final colors = gradientFor(option.id);
    final ring = (size * 0.055).clamp(1.6, 4.5);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: colors.first.withValues(alpha: 0.32),
                  blurRadius: size * 0.30,
                  spreadRadius: size * 0.01,
                  offset: Offset(0, size * 0.08),
                ),
              ]
            : null,
      ),
      padding: EdgeInsets.all(ring),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.35, -0.45),
            radius: 1.05,
            colors: [
              Color.lerp(colors.last, Colors.white, 0.80)!,
              Color.lerp(colors.first, Colors.white, 0.60)!,
            ],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.22),
            width: size * 0.014,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: size * 0.10,
              left: size * 0.13,
              child: Container(
                width: size * 0.44,
                height: size * 0.24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.38),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Text(
              option.emoji,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: size * 0.50,
                height: 1,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: size * 0.06,
                    offset: Offset(0, size * 0.025),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatar = _core(context);

    if (ringWidth <= 0) return avatar;

    return Container(
      padding: EdgeInsets.all(ringWidth),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: ringColor ?? colorFor(AvatarCatalog.byId(avatarId).id),
          width: ringWidth,
        ),
      ),
      child: avatar,
    );
  }
}
