import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Petit label de section (titre minuscule, gris, gras) au-dessus d'une liste
/// dans le hub TCF QCM. Padding gauche/droite calé sur les cartes (18).
class QcmSectionLabel extends StatelessWidget {
  const QcmSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
      child: Text(
        text,
        style: AppFonts.jakarta(
          size: 13,
          weight: FontWeight.w700,
          color: AppColors.muted,
        ),
      ),
    );
  }
}
