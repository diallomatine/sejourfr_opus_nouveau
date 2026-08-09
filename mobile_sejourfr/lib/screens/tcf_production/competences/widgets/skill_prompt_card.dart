import 'package:flutter/material.dart';

import '../../../../core/models/skill_models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format_date.dart';
import '../../../../core/widgets/pressable_card.dart';
import '../../widgets/production_blocks.dart';
import 'skill_status_badge.dart';

/// Carte d'un petit sujet (`.micro-card` du prototype) : grille
/// `48px 1fr auto`, `gap 12`, `padding 15`, `radius 23`.
///
/// Un sujet **traité** porte un liseré vertical de 3 px en bord gauche, en
/// retrait haut et bas (17 px) et arrondi côté intérieur — c'est le repère qui
/// distingue les statuts au premier coup d'œil (§13.8). Un sujet « à faire »
/// n'en porte **aucun** : sinon le repère ne repère plus rien.
class SkillPromptCard extends StatelessWidget {
  const SkillPromptCard({
    super.key,
    required this.prompt,
    required this.accent,
    required this.onTap,
  });

  final SkillPromptSummary prompt;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final treated = prompt.status.isTreated;
    final statusColor = skillStatusColor(prompt.status);

    return PressableCard(
      onTap: onTap,
      borderColor: treated
          ? statusColor.withValues(alpha: 0.30)
          : AppColors.line,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ProductionIndexChip(
                  order: prompt.displayOrder,
                  done: treated,
                  foreground: treated ? statusColor : accent,
                  background: treated
                      ? statusColor.withValues(alpha: 0.12)
                      : AppColors.surface2,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prompt.title,
                        style: AppFonts.ui(
                          size: 15,
                          weight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SkillStatusBadgeRow(prompt: prompt),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const CardChevron(),
              ],
            ),
          ),
          if (treated)
            Positioned(
              left: 0,
              top: 17,
              bottom: 17,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(5),
                    bottomRight: Radius.circular(5),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Badge de statut + méta « N tentatives · date » sur une ligne qui s'enroule
/// proprement sur un écran étroit (360 px).
class SkillStatusBadgeRow extends StatelessWidget {
  const SkillStatusBadgeRow({super.key, required this.prompt});

  final SkillPromptSummary prompt;

  @override
  Widget build(BuildContext context) {
    final meta = <String>[
      if (prompt.attemptCount > 0)
        '${prompt.attemptCount} tentative${prompt.attemptCount > 1 ? 's' : ''}',
      if (prompt.lastAttemptAt != null) formatShortDate(prompt.lastAttemptAt!),
    ].join(' · ');

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SkillStatusBadge(status: prompt.status),
        if (meta.isNotEmpty)
          Text(
            meta,
            style: AppFonts.ui(
              size: 10,
              weight: FontWeight.w700,
              color: AppColors.inkFaint,
            ),
          ),
      ],
    );
  }
}
