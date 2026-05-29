import 'package:flutter/material.dart';

/// Drapeau France 3 bandes (12×18) — signal officiel sur les pages d'examens
/// blancs TCF (QCM CO/CE/Structure et EE/EO). Couleurs locales hardcodées :
/// ce sont des couleurs nationales (Pantone Reflex Blue / Red 032), distinctes
/// de la palette produit AppColors et utilisées uniquement ici.
class FlagBadge extends StatelessWidget {
  const FlagBadge({super.key});

  // Bleu et rouge officiels du drapeau, hors palette produit.
  // ignore: avoid_redundant_argument_values
  static const Color _flagBlue = Color(0xFF0055A4);
  static const Color _flagRed = Color(0xFFEF4135);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: const SizedBox(
        height: 12,
        width: 18,
        child: Row(
          children: [
            Expanded(child: ColoredBox(color: _flagBlue)),
            Expanded(child: ColoredBox(color: Colors.white)),
            Expanded(child: ColoredBox(color: _flagRed)),
          ],
        ),
      ),
    );
  }
}
