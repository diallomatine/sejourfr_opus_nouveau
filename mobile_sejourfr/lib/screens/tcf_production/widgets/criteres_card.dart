import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';

/// Carte "Criteres d'evaluation" fond bleu-soft + liste a puces bleues.
/// Equivalent de `.criteres-card` du mockup HTML.
class CriteresCard extends StatelessWidget {
  const CriteresCard({
    super.key,
    required this.criteres,
    this.title = "Critères d'évaluation",
  });

  final List<String> criteres;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (criteres.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.listChecks, size: 18, color: AppColors.blue),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppFonts.ui(
                  size: 14,
                  weight: FontWeight.w700,
                  color: AppColors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...criteres.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7, right: 9),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AppColors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: AppFonts.ui(
                        size: 13,
                        color: AppColors.ink,
                        height: 1.5,
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
