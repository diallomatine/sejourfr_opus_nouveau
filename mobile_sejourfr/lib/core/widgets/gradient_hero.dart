import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Bloc héros en dégradé des maquettes Diagnostic / Plan : grand rayon, ombre
/// portée et **anneau décoratif** débordant en haut à droite (`:after` des
/// maquettes HTML).
///
/// Extrait dès la 2ᵉ occurrence (résultat du diagnostic + Plan) : les deux
/// écrans se lisent comme un même produit, et l'anneau ne se redessine pas
/// dans chaque écran. Aucune couleur en dur — le dégradé descend en paramètre.
class GradientHero extends StatelessWidget {
  const GradientHero({
    super.key,
    required this.child,
    this.from = AppColors.blueDark,
    this.to = AppColors.blue,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius,
  });

  final Widget child;
  final Color from;
  final Color to;
  final EdgeInsets padding;

  /// Rayon du bloc. `null` = le grand rayon des maquettes. On le surcharge
  /// quand le héros est le **bandeau haut d'une carte** qui porte autre chose
  /// en dessous (bande des domaines du rapport de diagnostic) : ses coins bas
  /// doivent alors être droits, sinon la carte laisse voir deux échancrures
  /// blanches sous le dégradé.
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppGradients.hero(from, to),
        borderRadius: borderRadius ?? BorderRadius.circular(AppRadii.xl),
        boxShadow: borderRadius == null ? AppShadows.md : null,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -52,
            top: -56,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.07),
                  width: 25,
                ),
              ),
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}
