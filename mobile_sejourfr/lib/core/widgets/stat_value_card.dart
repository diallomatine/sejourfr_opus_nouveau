import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_card.dart';

/// Petite carte de stat centrée : valeur en Bricolage colorée + libellé
/// discret (cf. lignes de stat cards d'Accueil, Profil et Examens maquette).
class StatValueCard extends StatelessWidget {
  const StatValueCard({
    super.key,
    required this.value,
    required this.label,
    this.color = AppColors.ink,
    this.valueSize = 24,
  });

  final String value;
  final String label;
  final Color color;
  final double valueSize;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: AppFonts.display(size: valueSize, color: color)),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.ui(
              size: 11.5,
              weight: FontWeight.w600,
              color: AppColors.inkFaint,
            ),
          ),
        ],
      ),
    );
  }
}
