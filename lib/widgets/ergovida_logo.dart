import 'package:flutter/material.dart';

class ErgoVidaLogo extends StatelessWidget {
  final double? width;
  final double size;
  final bool showText;

  const ErgoVidaLogo({
    super.key,
    this.width,
    this.size = 120,
    this.showText = false,
  });

  @override
  Widget build(BuildContext context) {
    final anchoFinal = width ?? size;

    return Image.asset(
      'assets/images/logo_ergovida3.png',
      width: anchoFinal,
      fit: BoxFit.contain,
    );
  }
}
