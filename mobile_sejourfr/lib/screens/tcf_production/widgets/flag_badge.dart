import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Drapeau France 3 bandes (12×18) — signal officiel sur les pages d'examens
/// blancs TCF (QCM CO/CE/Structure et EE/EO). Ses couleurs sont nationales
/// (Pantone Reflex Blue / Red 032), distinctes de la palette produit : elles
/// sont déclarées dans le thème (`kFlagBlue` / `kFlagRed`) comme toutes les
/// autres, et ne servent qu'ici.
class FlagBadge extends StatelessWidget {
  const FlagBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: const SizedBox(
        height: 12,
        width: 18,
        child: Row(
          children: [
            Expanded(child: ColoredBox(color: kFlagBlue)),
            Expanded(child: ColoredBox(color: Colors.white)),
            Expanded(child: ColoredBox(color: kFlagRed)),
          ],
        ),
      ),
    );
  }
}
