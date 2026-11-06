import 'package:flutter/material.dart';

/// Tokens de marca de ErgoVida.
///
/// Se mantiene la paleta corporativa: azul oscuro, blanco y negro,
/// con acentos cian/teal para transmitir bienestar y tecnología.
class AppPalette {
  const AppPalette._();

  static const Color navy = Color(0xFF0E2238);
  static const Color navyDeep = Color(0xFF081527);
  static const Color navySoft = Color(0xFF163451);
  static const Color blue = Color(0xFF1F7FC0);
  static const Color blueBright = Color(0xFF3B9AD9);
  static const Color cyan = Color(0xFF39C7D5);
  static const Color teal = Color(0xFF2DD4BF);
  static const Color background = Color(0xFFF3F6FA);
  static const Color backgroundDeep = Color(0xFFEAF1F8);
  static const Color card = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF10243A);
  static const Color muted = Color(0xFF5E7387);
  static const Color border = Color(0xFFDCE7F1);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFDC2626);

  static const Color darkBackground = Color(0xFF08111F);
  static const Color darkSurface = Color(0xFF101C2E);
  static const Color darkSurfaceAlt = Color(0xFF152338);
  static const Color darkBorder = Color(0xFF22344D);
  static const Color darkMuted = Color(0xFF9FB3C8);
}

/// Radios y sombras compartidas para mantener consistencia visual.
class AppRadii {
  const AppRadii._();

  static const double sm = 14;
  static const double md = 20;
  static const double lg = 26;
  static const double xl = 32;
  static const double pill = 999;
}

class AppShadows {
  const AppShadows._();

  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x100E2238),
      blurRadius: 24,
      offset: Offset(0, 12),
    ),
  ];

  static const List<BoxShadow> lifted = [
    BoxShadow(
      color: Color(0x1A0E2238),
      blurRadius: 40,
      offset: Offset(0, 20),
    ),
  ];

  static List<BoxShadow> glow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.32),
      blurRadius: 30,
      offset: const Offset(0, 16),
    ),
  ];
}

class AppTheme {
  const AppTheme._();

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppPalette.background,
    );

    final scheme = ColorScheme.fromSeed(
      seedColor: AppPalette.blue,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppPalette.blue,
      onPrimary: Colors.white,
      secondary: AppPalette.teal,
      onSecondary: AppPalette.navy,
      surface: AppPalette.card,
      onSurface: AppPalette.text,
      error: AppPalette.danger,
      outline: AppPalette.border,
    );

    return base.copyWith(
      colorScheme: scheme,
      textTheme: _textTheme(AppPalette.text, AppPalette.muted),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppPalette.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppPalette.text,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppPalette.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppPalette.border,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF7FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppPalette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppPalette.blue, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppPalette.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppPalette.danger, width: 1.6),
        ),
        labelStyle: const TextStyle(color: AppPalette.muted),
        hintStyle: const TextStyle(color: AppPalette.muted),
        prefixIconColor: AppPalette.muted,
        suffixIconColor: AppPalette.muted,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.blue,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppPalette.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppPalette.navy,
          side: const BorderSide(color: AppPalette.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppPalette.blue,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppPalette.blue
              : const Color(0xFFCBD5E1),
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFEFF6FB),
        selectedColor: AppPalette.blue.withValues(alpha: 0.14),
        labelStyle: const TextStyle(
          color: AppPalette.text,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppPalette.navy,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppPalette.navy,
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppPalette.blue,
        linearTrackColor: Color(0xFFE2EDF6),
        circularTrackColor: Color(0xFFE2EDF6),
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppPalette.darkBackground,
    );

    final scheme = ColorScheme.fromSeed(
      seedColor: AppPalette.blue,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppPalette.blueBright,
      onPrimary: Colors.white,
      secondary: AppPalette.teal,
      onSecondary: AppPalette.navyDeep,
      surface: AppPalette.darkSurface,
      onSurface: Colors.white,
      error: const Color(0xFFF87171),
      outline: AppPalette.darkBorder,
    );

    return base.copyWith(
      colorScheme: scheme,
      textTheme: _textTheme(Colors.white, AppPalette.darkMuted),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppPalette.darkSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppPalette.darkBorder,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.darkSurfaceAlt,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppPalette.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppPalette.cyan, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFF87171)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFF87171),
            width: 1.6,
          ),
        ),
        labelStyle: const TextStyle(color: AppPalette.darkMuted),
        hintStyle: const TextStyle(color: AppPalette.darkMuted),
        prefixIconColor: AppPalette.darkMuted,
        suffixIconColor: AppPalette.darkMuted,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.blue,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppPalette.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: AppPalette.darkBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppPalette.cyan,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppPalette.blueBright
              : const Color(0xFF334155),
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppPalette.darkSurfaceAlt,
        selectedColor: AppPalette.blue.withValues(alpha: 0.24),
        labelStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppPalette.darkSurfaceAlt,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppPalette.darkSurfaceAlt,
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppPalette.cyan,
        linearTrackColor: Color(0xFF22344D),
        circularTrackColor: Color(0xFF22344D),
      ),
    );
  }

  static TextTheme _textTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: TextStyle(
        color: primary,
        fontSize: 48,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.6,
        height: 1.05,
      ),
      displayMedium: TextStyle(
        color: primary,
        fontSize: 38,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
        height: 1.08,
      ),
      headlineLarge: TextStyle(
        color: primary,
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.9,
        height: 1.1,
      ),
      headlineMedium: TextStyle(
        color: primary,
        fontSize: 26,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
      ),
      headlineSmall: TextStyle(
        color: primary,
        fontSize: 21,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
      titleLarge: TextStyle(
        color: primary,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
      titleMedium: TextStyle(
        color: primary,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: TextStyle(
        color: primary,
        fontSize: 15,
        height: 1.45,
      ),
      bodyMedium: TextStyle(
        color: secondary,
        fontSize: 14,
        height: 1.45,
      ),
      bodySmall: TextStyle(
        color: secondary,
        fontSize: 12,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        color: primary,
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        color: secondary,
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    );
  }
}
