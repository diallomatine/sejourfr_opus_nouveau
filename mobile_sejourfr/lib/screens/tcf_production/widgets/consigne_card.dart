import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Bannière de consigne (cf. `MPractice` maquette) : fond teinté + liseré
/// accent à gauche — bleu pour l'EE, rouge pour l'EO ([accent]).
/// Optionnellement un sur-titre court (ex: "Durée attendue : 2 à 3 minutes")
/// affiché entre le titre et le corps (cf. briefing EO « Entretien dirigé »).
class ConsigneCard extends StatelessWidget {
  const ConsigneCard({
    super.key,
    required this.consigne,
    this.title = 'Consigne',
    this.subtitle,
    this.subTitleHero,
    this.accent = AppColors.blue,
    this.soft = AppColors.blueLight,
  });

  final String consigne;
  final String title;
  final String? subtitle;

  /// Si non-null, on affiche `subTitleHero` en gros au-dessus du
  /// subtitle/corps — utilisé pour le briefing EO "Entretien dirigé".
  final String? subTitleHero;

  final Color accent;
  final Color soft;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border(left: BorderSide(color: accent, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subTitleHero != null) ...[
            Text(
              subTitleHero!,
              style: AppFonts.display(size: 18),
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: AppFonts.ui(size: 13, color: AppColors.inkSoft),
              ),
            ],
            const SizedBox(height: 12),
          ] else ...[
            Text(
              title.toUpperCase(),
              style: AppFonts.label(size: 11, color: accent),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            consigne,
            style: AppFonts.ui(
              size: 14.5,
              weight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
