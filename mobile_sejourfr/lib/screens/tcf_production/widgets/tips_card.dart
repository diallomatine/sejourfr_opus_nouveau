import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Carte "Conseils" fond bleu-soft + liste a check verts.
/// Equivalent de `.tips-card` du mockup HTML.
class TipsCard extends StatelessWidget {
  const TipsCard({
    super.key,
    required this.tips,
    this.title = 'Conseils',
    this.icon = Icons.lightbulb_outline_rounded,
  });

  final List<String> tips;
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    if (tips.isEmpty) return const SizedBox.shrink();
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
              Icon(icon, size: 18, color: AppColors.blue),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppFonts.jakarta(
                  size: 14,
                  weight: FontWeight.w700,
                  color: AppColors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1, right: 8),
                    child: Icon(Icons.check_rounded, size: 16, color: AppColors.green),
                  ),
                  Expanded(
                    child: Text(
                      tip,
                      style: AppFonts.jakarta(
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
