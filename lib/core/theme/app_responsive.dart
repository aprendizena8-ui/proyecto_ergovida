import 'package:flutter/material.dart';

/// Breakpoints compartidos para que la app se comporte igual en todas las
/// pantallas. Los valores están pensados para móvil real (320–430 dp), tablet
/// y escritorio.
class AppBreakpoints {
  const AppBreakpoints._();

  static const double compact = 380;
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1040;
}

/// Utilidades de layout derivadas del ancho disponible.
///
/// Se usa `MediaQuery.sizeOf` en lugar de `MediaQuery.of` para que el widget
/// solo se reconstruya cuando cambia el tamaño y no ante cambios de texto,
/// brillo, etc.
class AppResponsive {
  const AppResponsive._();

  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;

  static bool isCompact(BuildContext context) =>
      width(context) < AppBreakpoints.compact;

  static bool isMobile(BuildContext context) =>
      width(context) < AppBreakpoints.mobile;

  static bool isTablet(BuildContext context) =>
      width(context) >= AppBreakpoints.mobile &&
      width(context) < AppBreakpoints.desktop;

  /// Margen horizontal recomendado para listas y formularios.
  static double gutter(BuildContext context) {
    final w = width(context);
    if (w < AppBreakpoints.compact) return 14;
    if (w < AppBreakpoints.mobile) return 16;
    if (w < AppBreakpoints.tablet) return 20;
    return 26;
  }

  /// Padding interno de las tarjetas. En móvil es más ajustado para dejar
  /// espacio a los controles táctiles.
  static double cardPadding(BuildContext context) =>
      isMobile(context) ? 16 : 22;

  /// Altura mínima cómoda para botones táctiles.
  static double buttonHeight(BuildContext context) =>
      isMobile(context) ? 48 : 44;
}
