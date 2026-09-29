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
    this.hint,
  });

  final String value;
  final String label;
  final Color color;
  final double valueSize;

  /// Précision facultative sous le libellé (périmètre d'un niveau estimé
  /// partiel). Absente ⇒ la carte garde **exactement** ses deux lignes : les
  /// appelants historiques ne bougent pas d'un pixel.
  final String? hint;

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
            // 2 lignes : à 3 cartes par ligne sur un 360 px, un libellé
            // explicite (« Niveau TCF estimé ») ne tient pas sur une seule.
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.ui(
              size: 11.5,
              weight: FontWeight.w600,
              color: AppColors.inkFaint,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 3),
            Text(
              hint!,
              // Une précision, pas une alerte : ni teinte d'avertissement, ni
              // gras. 2 lignes suffisent à « D'après 1 épreuve sur 4 » sur un
              // tiers de largeur à 360 px.
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.ui(
                size: 10,
                weight: FontWeight.w500,
                color: AppColors.inkFaint,
                height: 1.25,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
