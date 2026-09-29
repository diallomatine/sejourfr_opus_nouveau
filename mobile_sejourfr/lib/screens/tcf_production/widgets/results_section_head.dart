import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Intertitre du rapport de correction : un titre a gauche, une indication
/// discrete a droite.
///
/// Les sections du rapport n'avaient pas de titre propre — chaque bloc portait
/// le sien dans un encadre colore, ce qui empilait les cadres et faisait lire
/// le rapport comme une suite d'alertes. Le titre sort de la carte, la carte
/// redevient du contenu.
class ResultsSectionHead extends StatelessWidget {
  const ResultsSectionHead({super.key, required this.title, this.hint});

  final String title;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              title,
              style: AppFonts.display(
                size: 16,
                weight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
          if (hint != null) ...[
            const SizedBox(width: 10),
            Text(
              hint!,
              style: AppFonts.ui(size: 11.5, color: AppColors.muted2),
            ),
          ],
        ],
      ),
    );
  }
}
