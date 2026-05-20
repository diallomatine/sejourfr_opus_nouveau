import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Carte blanche avec titre "Consigne" + icone signet bleue + corps.
/// Optionnellement un sur-titre court (ex: "Durée attendue : 2 à 3 minutes")
/// affiche entre le titre et le corps (cf. EO 01 du HTML).
class ConsigneCard extends StatelessWidget {
  const ConsigneCard({
    super.key,
    required this.consigne,
    this.title = 'Consigne',
    this.subtitle,
    this.subTitleHero,
  });

  final String consigne;
  final String title;
  final String? subtitle;

  /// Si non-null, on affiche `subTitleHero` en gros (18px bold) au-dessus du
  /// subtitle/corps -- utilise pour le briefing EO "Entretien dirige".
  final String? subTitleHero;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subTitleHero != null) ...[
            Text(
              subTitleHero!,
              style: AppFonts.jakarta(
                size: 18,
                weight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: AppFonts.jakarta(
                  size: 13,
                  color: AppColors.muted,
                ),
              ),
            ],
            const SizedBox(height: 14),
          ] else ...[
            Row(
              children: [
                const Icon(Icons.assignment_outlined, size: 18, color: AppColors.blue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: AppFonts.jakarta(
                    size: 14,
                    weight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Text(
            consigne,
            style: AppFonts.jakarta(
              size: 14,
              color: AppColors.ink,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
