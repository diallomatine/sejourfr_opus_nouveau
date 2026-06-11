import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';

/// Encart "À noter" affiché avant les autres sections de feedback quand
/// l'IA renvoie des avertissements (durée trop courte, dépassement de mots…).
/// Renvoie [SizedBox.shrink] si la liste est vide.
class AvertissementsCard extends StatelessWidget {
  const AvertissementsCard({super.key, required this.avertissements});

  final List<String> avertissements;

  @override
  Widget build(BuildContext context) {
    if (avertissements.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.triangleAlert,
                size: 18,
                color: AppColors.amber,
              ),
              const SizedBox(width: 8),
              Text(
                'À noter',
                style: AppFonts.ui(
                  size: 13,
                  weight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...avertissements.map(
            (msg) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6, right: 8),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.amber,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      msg,
                      style: AppFonts.ui(
                        size: 13,
                        color: AppColors.ink,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
