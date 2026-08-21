import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Progression **en segments**, un segment par unité (la barre `CSujetsDots` de
/// la maquette).
///
/// À la différence de `ProgressTrack`, qui peint un pourcentage continu, cette
/// barre-ci dit **combien d'éléments sur combien** : « 3 sujets travaillés sur
/// 5 » se lit d'un coup d'œil, sans conversion mentale. On l'emploie quand le
/// total est petit et connu (les sujets d'une compétence, ceux d'une étape),
/// jamais pour un ratio abstrait.
///
/// ⚠️ Les deux nombres viennent de l'appelant, qui les tient du **serveur** :
/// cette barre ne compte rien et ne déduit rien. `total <= 0` ⇒ rien n'est
/// rendu, plutôt qu'une piste vide qui laisserait croire à zéro sur zéro.
class ProgressDots extends StatelessWidget {
  const ProgressDots({
    super.key,
    required this.done,
    required this.total,
    this.color = AppColors.blue,
    this.trackColor = AppColors.surface3,
    this.height = 5,
    this.gap = 4,
  });

  final int done;
  final int total;
  final Color color;
  final Color trackColor;
  final double height;
  final double gap;

  @override
  Widget build(BuildContext context) {
    if (total <= 0) return const SizedBox.shrink();
    final filled = done.clamp(0, total);
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) SizedBox(width: gap),
          Expanded(
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: i < filled ? color : trackColor,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
