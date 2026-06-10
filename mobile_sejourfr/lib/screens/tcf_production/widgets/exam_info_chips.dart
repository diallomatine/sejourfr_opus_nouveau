import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Chips d'info d'une épreuve complète (cf. `MExamens` maquette) : pills
/// teintées par l'accent du parcours (durée, seuil, composition…).
class ExamInfoChips extends StatelessWidget {
  const ExamInfoChips({
    super.key,
    required this.items,
    required this.accent,
    required this.soft,
  });

  final List<({IconData icon, String label})> items;
  final Color accent;
  final Color soft;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: soft,
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.icon, size: 14, color: accent),
                const SizedBox(width: 6),
                Text(
                  item.label,
                  style: AppFonts.ui(
                    size: 12,
                    weight: FontWeight.w600,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
