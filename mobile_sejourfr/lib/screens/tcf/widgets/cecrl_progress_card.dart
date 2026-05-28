import 'package:flutter/material.dart';

import '../../../core/models/enums.dart';
import '../../../core/theme/app_theme.dart';

/// Carte « Niveau global estimé » du hub TCF.
///
/// - À gauche : libellé + niveau actuel (déduit du dernier examen blanc
///   complet, fallback « — » si aucun examen passé).
/// - À droite : objectif (niveau CECRL visé via la procédure du user).
/// - En bas : barre CECRL en 6 segments (A1 → C2), colorés jusqu'au niveau
///   actuel inclus.
class CecrlProgressCard extends StatelessWidget {
  const CecrlProgressCard({
    super.key,
    required this.current,
    required this.target,
    this.targetSuffix,
  });

  /// Niveau CECRL estimé courant (null si pas encore d'examen blanc complet
  /// terminé).
  final NiveauCecrl? current;

  /// Niveau CECRL visé (peut être null si le user n'a pas encore choisi son
  /// parcours).
  final NiveauCecrl? target;

  /// Texte secondaire optionnel à droite, ex. « naturalisation ».
  final String? targetSuffix;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NIVEAU GLOBAL ESTIMÉ',
                      style: AppFonts.mono(
                        size: 9.5,
                        color: AppColors.muted,
                        letterSpacing: 1.4,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      current?.displayName ?? '—',
                      style: AppFonts.jakarta(
                        size: 22,
                        weight: FontWeight.w800,
                        color: AppColors.ink,
                      ).copyWith(letterSpacing: -0.4),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'OBJECTIF',
                    style: AppFonts.mono(
                      size: 9.5,
                      color: AppColors.muted,
                      letterSpacing: 1.4,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    target == null
                        ? '—'
                        : targetSuffix == null
                            ? target!.displayName
                            : '${target!.displayName} · $targetSuffix',
                    style: AppFonts.jakarta(
                      size: 13.5,
                      weight: FontWeight.w700,
                      color: AppColors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _CecrlBar(current: current),
          const SizedBox(height: 6),
          const _CecrlLabels(),
        ],
      ),
    );
  }
}

/// Barre 6 segments (A1 → C2). Les segments jusqu'à `current` inclus sont
/// colorés en vert ; au-delà ils restent gris clair.
class _CecrlBar extends StatelessWidget {
  const _CecrlBar({required this.current});

  final NiveauCecrl? current;

  @override
  Widget build(BuildContext context) {
    // current null → aucun segment coloré. scaleIndex va de 0 (A1) à 5 (C2).
    final filledUpTo = current?.scaleIndex ?? -1;
    return Row(
      children: List.generate(6, (i) {
        final filled = i <= filledUpTo;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == 5 ? 0 : 3),
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: filled ? AppColors.green : AppColors.line2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _CecrlLabels extends StatelessWidget {
  const _CecrlLabels();

  @override
  Widget build(BuildContext context) {
    const labels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final l in labels)
          Text(
            l,
            style: AppFonts.mono(
              size: 9,
              color: AppColors.muted2,
              letterSpacing: 0.8,
              weight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}
