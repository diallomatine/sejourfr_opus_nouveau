import 'dart:ui';

import 'package:flutter/material.dart';

/// **Le rideau posé sur du contenu réel** qu'un compte gratuit ne peut pas
/// encore atteindre.
///
/// 🛑 **Rien n'est fabriqué derrière le flou.** Ce qu'on floute, c'est ce que
/// le serveur a servi — le vrai titre, la vraie compétence. On ne compose
/// jamais de fausse ligne pour remplir : le flou est un rideau posé sur du
/// vrai, pas un décor.
///
/// Le bloc est `ExcludeSemantics` **et** `IgnorePointer` : ce qui est illisible
/// à l'œil doit l'être aussi au lecteur d'écran, sinon le verrou ne tient pas.
/// Le geste reste possible — c'est l'ancêtre tappable (la ligne, la carte) qui
/// le porte, et il mène à l'offre.
///
/// ⚠️ **Ce qui doit rester lisible vit à côté, jamais dedans** : un compteur,
/// un rang, un cadenas, un appel à l'action. On floute l'**action pas encore
/// accessible**, jamais le **résultat mesuré** — ce sont ses productions.
class BlurredContent extends StatelessWidget {
  const BlurredContent({
    super.key,
    required this.child,
    this.sigma = 4,
    this.opacity = 0.55,
  });

  final Widget child;

  /// Le rayon du flou. Assez fort pour qu'aucun mot ne se devine, assez faible
  /// pour qu'on voie qu'il y a bien quelque chose.
  final double sigma;

  final double opacity;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: IgnorePointer(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
            child: Opacity(opacity: opacity, child: child),
          ),
        ),
      );
}
