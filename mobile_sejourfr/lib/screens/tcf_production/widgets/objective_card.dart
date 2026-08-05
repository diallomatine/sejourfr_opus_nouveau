import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/enums.dart';
import '../../../core/models/production_models.dart';
import '../../../core/theme/app_theme.dart';

/// Verdict d'accomplissement, en TETE du rapport : avant la note, avant la
/// langue. C'est la premiere question du candidat — « est-ce que j'ai fait ce
/// qu'on me demandait ? » — et la seule a laquelle on peut repondre en trois
/// mots.
///
/// Trois traitements visuels distincts pour que le verdict se lise sans etre
/// lu. Les evaluations anterieures aux rubriques v8 n'ont pas ce champ : la
/// carte disparait entierement plutot que d'afficher un statut invente.
class ObjectiveCard extends StatelessWidget {
  const ObjectiveCard({super.key, required this.accomplissement});

  final Accomplissement? accomplissement;

  static ({Color tone, IconData icon}) _style(ObjectifAccomplissement o) =>
      switch (o) {
        ObjectifAccomplissement.atteint => (
            tone: AppColors.green,
            icon: LucideIcons.circleCheck,
          ),
        ObjectifAccomplissement.partiellementAtteint => (
            tone: AppColors.amber,
            icon: LucideIcons.circleDashed,
          ),
        ObjectifAccomplissement.nonAtteint => (
            tone: AppColors.red,
            icon: LucideIcons.circleX,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final objectif = accomplissement?.objectif;
    if (objectif == null) return const SizedBox.shrink();
    final style = _style(objectif);
    final resume = accomplissement?.objectifResume;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: style.tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: style.tone.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: style.tone,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(style.icon, size: 20, color: AppColors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OBJECTIF DE LA TÂCHE',
                      style: AppFonts.label(size: 10, color: AppColors.muted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      objectif.displayName,
                      style: AppFonts.display(
                        size: 20,
                        weight: FontWeight.w700,
                        color: style.tone,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (resume != null) ...[
            const SizedBox(height: 12),
            Text(
              resume,
              style: AppFonts.ui(
                size: 13.5,
                color: AppColors.ink,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
