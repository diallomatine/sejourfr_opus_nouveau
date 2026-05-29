import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/enums.dart';

/// Palette de couleurs officielle SejourFR — exactement les valeurs du template.
class AppColors {
  static const blue = Color(0xFF1E3A8C);
  static const blueDark = Color(0xFF15296B);
  static const blueLight = Color(0xFFE8ECF8);
  static const blueSoft = Color(0xFFF4F6FC);

  static const red = Color(0xFFE1372F);
  static const redDark = Color(0xFFB5251E);
  static const redLight = Color(0xFFFDECEB);

  static const ink = Color(0xFF0F1839);
  static const ink2 = Color(0xFF1F2950);
  static const muted = Color(0xFF6B7299);
  static const muted2 = Color(0xFF9CA2BD);

  static const line = Color(0xFFE4E7F2);
  static const line2 = Color(0xFFEEF0F8);
  static const bg = Color(0xFFF7F8FC);
  static const white = Color(0xFFFFFFFF);

  static const green = Color(0xFF168F5B);
  static const amber = Color(0xFFE8A317);
}

/// Couleur associée à un niveau CECRL pour les badges / barres de niveau.
/// **Jamais de rouge** (réservé aux CTA/urgence) : un niveau faible est en
/// ambre, B1 en bleu, B2+ en vert. Helper canonique partagé par le hub TCF,
/// le bilan d'examen complet et les résultats EE/EO.
extension CecrlColor on NiveauCecrl {
  Color get color => switch (this) {
        NiveauCecrl.a1NonAtteint ||
        NiveauCecrl.a1 ||
        NiveauCecrl.a2 =>
          AppColors.amber,
        NiveauCecrl.b1 => AppColors.blue,
        NiveauCecrl.b2 || NiveauCecrl.c1 || NiveauCecrl.c2 => AppColors.green,
      };
}

/// Ombres réutilisables partagées entre les cartes du produit.
class AppShadows {
  /// Ombre douce sous les cartes blanches (hubs TCF, Civique, EE/EO).
  static const card = <BoxShadow>[
    BoxShadow(
      color: Color(0x0A0F1839),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];
}

/// Helpers pour les polices Google Fonts.
class AppFonts {
  static TextStyle jakarta({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.ink,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextStyle fraunces({
    double size = 28,
    FontWeight weight = FontWeight.w600,
    Color color = AppColors.ink,
    double? height,
    double? letterSpacing = -0.02,
    FontStyle? fontStyle,
  }) =>
      GoogleFonts.fraunces(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
        fontStyle: fontStyle,
      );

  static TextStyle mono({
    double size = 11,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.muted,
    double letterSpacing = 1.8,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      );

  /// Eyebrow typographique : petits labels en monospace majuscule.
  static TextStyle eyebrow({Color color = AppColors.muted}) =>
      mono(size: 10, color: color, letterSpacing: 2.0).copyWith(
        height: 1.0,
      );
}

/// Configuration du Material Theme.
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.blue,
      primary: AppColors.blue,
      secondary: AppColors.red,
      surface: AppColors.white,
      error: AppColors.red,
      brightness: Brightness.light,
    ),
    textTheme: GoogleFonts.plusJakartaSansTextTheme().apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: AppFonts.jakarta(
        size: 16,
        weight: FontWeight.w700,
        color: AppColors.ink,
      ),
      iconTheme: const IconThemeData(color: AppColors.ink),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.red),
      ),
      labelStyle: AppFonts.mono(color: AppColors.muted, size: 10),
      hintStyle: AppFonts.jakarta(color: AppColors.muted2),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.line,
      thickness: 1,
      space: 1,
    ),
  );
}
