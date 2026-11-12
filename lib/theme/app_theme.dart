import 'package:flutter/material.dart';

/// Single source of truth for the KowoPay visual language.
///
/// The product theme is intentionally narrow: white surfaces and a purple
/// family only. Screens must read colours from here instead of hard-coding
/// `Colors.deepPurple` so the brand stays unified everywhere.
class AppColors {
  AppColors._();

  static const Color purple = Color(0xFF6D28D9);
  static const Color purpleDeep = Color(0xFF4C1D95);
  static const Color purpleBlack = Color(0xFF2E1065);
  static const Color violet = Color(0xFF8B5CF6);
  static const Color lilac = Color(0xFFEDE9FE);
  static const Color mist = Color(0xFFF7F5FF);
  static const Color white = Color(0xFFFFFFFF);

  static const Color ink = Color(0xFF1B1533);
  static const Color inkMuted = Color(0xFF6B6480);
  static const Color outline = Color(0xFFE4DFF5);

  static const Color success = Color(0xFF16A34A);
  static const Color danger = Color(0xFFDC2626);
  static const Color warning = Color(0xFFD97706);

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [purpleBlack, purple, violet],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient softGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF4F0FF), Color(0xFFFFFFFF)],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [purple, violet],
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.purple,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.purple,
      onPrimary: AppColors.white,
      secondary: AppColors.violet,
      onSecondary: AppColors.white,
      surface: AppColors.white,
      onSurface: AppColors.ink,
      error: AppColors.danger,
      outline: AppColors.outline,
    );

    final ThemeData base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.white,
      fontFamily: 'Roboto',
    );

    return base.copyWith(
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.ink,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.mist,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: const TextStyle(color: AppColors.inkMuted),
        labelStyle: const TextStyle(color: AppColors.inkMuted),
        prefixIconColor: AppColors.purple,
        suffixIconColor: AppColors.inkMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.purple, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.purple,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.lilac,
          disabledForegroundColor: AppColors.inkMuted,
          elevation: 0,
          minimumSize: const Size.fromHeight(54),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.purple),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.outline,
        thickness: 1,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CinematicPageTransitionsBuilder(),
          TargetPlatform.iOS: CinematicPageTransitionsBuilder(),
          TargetPlatform.macOS: CinematicPageTransitionsBuilder(),
          TargetPlatform.windows: CinematicPageTransitionsBuilder(),
          TargetPlatform.linux: CinematicPageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// Fade-through + subtle scale page transition used app-wide.
class CinematicPageTransitionsBuilder extends PageTransitionsBuilder {
  const CinematicPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final CurvedAnimation curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.035),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
