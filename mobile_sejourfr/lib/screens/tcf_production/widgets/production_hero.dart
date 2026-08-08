import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Hero de l'écran d'accueil « Compétences » (`.hero` du prototype).
///
/// Bandeau en dégradé, anneau décoratif débordant, eyebrow, titre de tâche,
/// pilule de palier, puis la **barre de progression globale** de la tâche.
/// Le dégradé prend l'accent du module (bleu en EE, rouge en EO) : la
/// géométrie vient du prototype, les couleurs de l'application.
class ProductionHero extends StatelessWidget {
  const ProductionHero({
    super.key,
    required this.accent,
    required this.accentDark,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.percent,
    required this.progressLabel,
    this.level,
  });

  final Color accent;
  final Color accentDark;
  final String eyebrow;
  final String title;
  final String description;

  /// Progression globale de la tâche, 0-100.
  final double percent;

  /// Détail chiffré affiché à droite du libellé (« 7/40 sujets traités »).
  final String progressLabel;

  /// Palier visé de la tâche (`A2`…`B2`). Absent tant qu'aucune compétence
  /// n'est chargée — on n'invente pas de niveau.
  final String? level;

  @override
  Widget build(BuildContext context) {
    final rounded = percent.clamp(0, 100).round();

    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        gradient: AppGradients.hero(accentDark, accent),
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppShadows.md,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Anneau décoratif du prototype : 150×150, bord 28, blanc à 7 %.
          Positioned(
            right: -95,
            top: -91,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.07),
                  width: 28,
                ),
              ),
            ),
          ),
          Column(
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
                          eyebrow.toUpperCase(),
                          style: AppFonts.label(
                            size: 11,
                            color: AppColors.white.withValues(alpha: 0.72),
                          ).copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          title,
                          style: AppFonts.display(
                            size: 20,
                            height: 1.2,
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          description,
                          style: AppFonts.ui(
                            size: 12,
                            height: 1.45,
                            color: AppColors.white.withValues(alpha: 0.84),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (level != null && level!.trim().isNotEmpty) ...[
                    const SizedBox(width: 12),
                    _LevelPill(label: level!),
                  ],
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Progression · $progressLabel',
                      style: AppFonts.ui(
                        size: 11,
                        weight: FontWeight.w800,
                        color: AppColors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                  Text(
                    '$rounded %',
                    style: AppFonts.ui(
                      size: 11,
                      weight: FontWeight.w800,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              ProgressTrackOnDark(percent: percent),
            ],
          ),
        ],
      ),
    );
  }
}

/// Rail translucide + remplissage blanc. `ProgressTrack` ne convient pas ici :
/// sa piste est une teinte opaque du thème clair, invisible sur un dégradé.
class ProgressTrackOnDark extends StatelessWidget {
  const ProgressTrackOnDark({super.key, required this.percent});

  final double percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 7,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: (percent.clamp(0, 100)) / 100),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) => FractionallySizedBox(
          widthFactor: value,
          heightFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelPill extends StatelessWidget {
  const _LevelPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.17),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: AppFonts.ui(
          size: 11,
          weight: FontWeight.w900,
          color: AppColors.white,
        ),
      ),
    );
  }
}
