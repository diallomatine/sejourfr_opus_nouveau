import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Couple « phrase du candidat » → « phrase reecrite » : la demonstration d'une
/// priorite de travail, sur les mots du candidat.
///
/// **Sans etiquettes** : l'ancienne phrase **barree**, la nouvelle en vert. Deux
/// lignes au lieu de quatre, et le sens se lit sans mot d'introduction — la
/// rature dit « avant » mieux que le mot « avant ».
///
/// La forme etiquetee (« Original : » / « Correction : ») a disparu avec les
/// `exemples_corriges` du contrat v15/v9 : plus aucun ecran ne la demandait.
class BeforeAfterLines extends StatelessWidget {
  const BeforeAfterLines({
    super.key,
    required this.avant,
    required this.apres,
  });

  final String avant;
  final String apres;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          avant,
          style: AppFonts.ui(size: 13, color: AppColors.red, height: 1.45)
              .copyWith(decoration: TextDecoration.lineThrough),
        ),
        const SizedBox(height: 6),
        Text(
          apres,
          style: AppFonts.ui(
            size: 13,
            weight: FontWeight.w700,
            color: AppColors.green,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}
