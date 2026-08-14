import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/diagnostic_models.dart';
import '../models/enums.dart';

/// Palette SejourFR — refonte 2026 (maquette `SejourFR_Mobile_Autonome.html`).
///
/// Marque : Bleu France + Rouge France conservés. Neutres calmes en trois
/// niveaux de surface (surface > surface2 > surface3) sur fond très clair.
/// Sémantique maquette : `primary` = bleu, `accent` = rouge (usage rare),
/// TCF = rouge, Civique = bleu.
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
  static const bg = Color(0xFFF9FAFD);
  static const white = Color(0xFFFFFFFF);

  /// Surfaces intermédiaires (cartes dans cartes, fonds de pastilles).
  static const surface2 = Color(0xFFF3F5FA);
  static const surface3 = Color(0xFFEBEEF5);

  static const green = Color(0xFF168F5B);
  static const greenLight = Color(0xFFE3F4EB);

  /// Vert **posé sur un fond foncé** (coches du bloc offre, sur l'encre).
  /// [greenLight] y vire au blanc et la coche perd son sens « acquis » ;
  /// [green] y devient sombre et se noie. C'est la seule teinte verte du
  /// produit dont le contraste est calculé contre l'encre, pas contre le blanc.
  static const greenBright = Color(0xFF6DE0B1);
  static const amber = Color(0xFFE8A317);
  static const amberLight = Color(0xFFFCF1DA);

  /// Ambre **de texte**. [amber] est un ambre de remplissage : illisible en
  /// lettres sur fond clair. Toute mention ambre écrite (badge « À renforcer »,
  /// tipline) passe par ici — c'est ce qui évite qu'un hex ressorte dans un
  /// widget.
  static const amberDark = Color(0xFF9A6A0B);

  // Alias sémantiques maquette.
  static const inkSoft = muted;
  static const inkFaint = muted2;
  static const lineSoft = line2;

  /// Voile sombre des bottom sheets.
  static const scrim = Color(0x660E1624);
}

/// Rayons standardisés de la maquette.
class AppRadii {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 18.0;
  static const xl = 26.0;
  static const pill = 999.0;
}

/// Couleur associée à un niveau CECRL pour les badges / barres de niveau.
/// **Jamais de rouge** (réservé aux CTA/urgence) : un niveau faible est en
/// ambre, B1 en bleu, B2+ en vert. Helper canonique partagé par le hub TCF,
/// le bilan d'examen complet et les résultats EE/EO.
///
/// **Seul endroit** qui décide de la teinte d'un niveau : le ton de badge
/// équivalent (`CecrlTagTone.tagTone`, `core/widgets/app_tag.dart`) en dérive
/// au lieu de rejouer les mêmes paliers dans un second `switch`.
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

/// Teinte d'un statut de compétence du Plan — **seule** table qui en décide,
/// partagée par le Plan et le résultat du diagnostic (les deux écrans lisent
/// les mêmes observations serveur, ils ne doivent pas les peindre autrement).
///
/// `AppColors.amber` est un ambre de **remplissage** : illisible en lettres,
/// d'où `amberDark` pour « À renforcer ».
extension LearningPlanSkillStatusColor on LearningPlanSkillStatus {
  Color get color => switch (this) {
        LearningPlanSkillStatus.priority => AppColors.red,
        LearningPlanSkillStatus.toReinforce => AppColors.amberDark,
        LearningPlanSkillStatus.solid => AppColors.green,
        LearningPlanSkillStatus.notObserved => AppColors.inkFaint,
      };
}

/// Rampe de couleur d'une maîtrise 0-100 (rouge → corail → ardoise → bleu →
/// Bleu France). Reprise de `mBarColor` de la maquette, re-teintée marque.
Color masteryColor(num value) {
  if (value < 40) return const Color(0xFFCB4341);
  if (value < 55) return const Color(0xFFC96A3F);
  if (value < 70) return const Color(0xFF5C73A6);
  if (value < 85) return const Color(0xFF3355B0);
  return AppColors.blue;
}

/// Rampe **pastel** de la barre de niveau A1 → B2, pensée pour rester lisible
/// sur le dégradé foncé du bilan. Distincte de [CecrlColor] — qui reste la
/// seule table à décider de la teinte d'un niveau **plein** (badge, pastille) :
/// ici on peint un dégradé continu, pas un palier.
const cecrlScaleRamp = <Color>[
  Color(0xFFF87171), // A1
  Color(0xFFFB923C), // A2
  Color(0xFFFBBF24), // B1
  Color(0xFF34D399), // B2
];

/// Bleu et rouge **officiels du drapeau** (Pantone Reflex Blue / Red 032).
/// Volontairement hors palette produit : ils ne servent qu'au drapeau, jamais
/// à peindre de l'interface. Ils vivent ici parce qu'aucune couleur ne se
/// déclare ailleurs que dans ce fichier.
const kFlagBlue = Color(0xFF0055A4);
const kFlagRed = Color(0xFFEF4135);

/// Libellé qualitatif d'une maîtrise 0-100 (cf. `masteryLabel` maquette).
String masteryLabel(num value) {
  if (value >= 80) return 'Solide';
  if (value >= 60) return 'En bonne voie';
  if (value >= 40) return 'À renforcer';
  return 'Fragile';
}

/// Ombres réutilisables partagées entre les cartes du produit.
class AppShadows {
  /// Ombre très douce des cartes blanches (shadow-sm maquette).
  static const card = <BoxShadow>[
    BoxShadow(
      color: Color(0x0F32405E),
      blurRadius: 3,
      offset: Offset(0, 1),
    ),
    BoxShadow(
      color: Color(0x0A32405E),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  /// Ombre marquée des éléments en avant (héros, sheets, carte pass).
  static const md = <BoxShadow>[
    BoxShadow(
      color: Color(0x1432405E),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x0D32405E),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];
}

/// Dégradés réutilisables.
///
/// Un hero se peint avec l'accent de son module (bleu en EE, rouge en EO) :
/// les deux tons viennent de [AppColors], jamais d'un hex écrit dans un écran.
class AppGradients {
  /// Dégradé de hero, 140° comme la maquette : ton foncé en haut à gauche,
  /// accent plein en bas à droite.
  static LinearGradient hero(Color from, Color to) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [from, to],
      );

  /// Bandeau premium (analyse IA) : encre → Bleu France.
  static LinearGradient get premium => hero(AppColors.ink, AppColors.blue);
}

/// Helpers typographiques.
///
/// Refonte 2026 : **Bricolage Grotesque** pour les titres et les chiffres
/// (display), **Hanken Grotesk** pour tout le reste (ui). Les anciens helpers
/// `jakarta` / `fraunces` / `mono` délèguent vers les nouveaux le temps de la
/// migration écran par écran — ne plus les utiliser dans du code neuf.
class AppFonts {
  /// Titres, gros chiffres, identité (Bricolage Grotesque).
  /// Tracking serré (-0.02em) comme la maquette.
  static TextStyle display({
    double size = 19,
    FontWeight weight = FontWeight.w700,
    Color color = AppColors.ink,
    double? height,
  }) =>
      GoogleFonts.bricolageGrotesque(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height ?? 1.1,
        letterSpacing: size * -0.02,
      );

  /// Corps, boutons, navigation (Hanken Grotesk).
  static TextStyle ui({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.ink,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.hankenGrotesk(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  /// Petits labels d'entête de section (uppercase, tracking léger).
  static TextStyle label({
    double size = 12,
    Color color = AppColors.inkFaint,
  }) =>
      ui(
        size: size,
        weight: FontWeight.w700,
        color: color,
        letterSpacing: size * 0.05,
      );

  @Deprecated('Refonte 2026 : utiliser AppFonts.label')
  static TextStyle mono({
    double size = 11,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.muted,
    double letterSpacing = 1.8,
  }) =>
      ui(
        size: size,
        weight: FontWeight.w700,
        color: color,
        letterSpacing: size * 0.05,
      );

  /// Eyebrow typographique : petits labels en majuscule.
  static TextStyle eyebrow({Color color = AppColors.muted}) =>
      label(size: 10.5, color: color).copyWith(height: 1.0);
}

/// Configuration du Material Theme.
ThemeData buildAppTheme() {
  // Transition unifiée sur toutes les plateformes : fondu + léger glissement
  // horizontal (spec Material 3 récente), sans le zoom Android par défaut.
  const fadeForwards = FadeForwardsPageTransitionsBuilder(
    backgroundColor: AppColors.bg,
  );
  const pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: fadeForwards,
      TargetPlatform.iOS: fadeForwards,
      TargetPlatform.macOS: fadeForwards,
      TargetPlatform.windows: fadeForwards,
      TargetPlatform.linux: fadeForwards,
    },
  );

  return ThemeData(
    useMaterial3: true,
    pageTransitionsTheme: pageTransitions,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.blue,
      primary: AppColors.blue,
      secondary: AppColors.red,
      surface: AppColors.white,
      error: AppColors.red,
      brightness: Brightness.light,
    ),
    textTheme: GoogleFonts.hankenGroteskTextTheme().apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: AppFonts.display(size: 17, color: AppColors.ink),
      iconTheme: const IconThemeData(color: AppColors.ink),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: AppColors.red),
      ),
      labelStyle: AppFonts.ui(
        size: 13,
        weight: FontWeight.w600,
        color: AppColors.muted,
      ),
      hintStyle: AppFonts.ui(color: AppColors.muted2),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.lineSoft,
      thickness: 1,
      space: 1,
    ),
  );
}
