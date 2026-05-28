import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// En-tête plat partagé par les écrans TCF (hubs CO/CE/Structure, page Examens,
/// page Erreurs, hub EE/EO, page Examens EE/EO). Bouton retour à gauche,
/// titre + sous-titre au centre, slot optionnel à droite (pour le drapeau
/// France sur les pages « Examens blancs »).
class ModuleScreenHeader extends StatelessWidget {
  const ModuleScreenHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onBack,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;

  /// Widget rendu à droite du titre (sur la même ligne). Utilisé pour les
  /// pages d'examens blancs avec `FlagBadge`.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 16, 10),
      color: AppColors.white,
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: AppFonts.jakarta(
                          size: 17,
                          weight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 8),
                      trailing!,
                    ],
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: AppFonts.jakarta(size: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
