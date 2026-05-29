import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Bandeau « Lancer un examen blanc » du hub TCF QCM (CO/CE/Structure).
/// Même look que `ExamBlancHero` de la home : dégradé rouge plein, ombre
/// teintée, texte blanc, CTA pill blanche.
class QcmExamHero extends StatelessWidget {
  const QcmExamHero({
    super.key,
    required this.icon,
    required this.examSubtitle,
    required this.description,
    required this.onStart,
  });

  final IconData icon;

  /// Sous-titre repris dans l'eyebrow (« 25 questions · 20 min »).
  final String examSubtitle;

  /// Texte descriptif sous le titre — varie selon le module (les modules
  /// officiels mentionnent la progression CECRL, Structure utilise une
  /// formulation neutre).
  final String description;

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onStart,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.red, AppColors.redDark],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.redDark.withValues(alpha: 0.32),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 14, color: AppColors.white),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'EXAMEN COMPLET · ${examSubtitle.toUpperCase()}',
                      style: AppFonts.mono(
                        size: 10,
                        color: AppColors.white.withValues(alpha: 0.9),
                        letterSpacing: 1.2,
                        weight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Lancer un examen blanc',
                style: AppFonts.jakarta(
                  size: 19,
                  weight: FontWeight.w800,
                  color: AppColors.white,
                ).copyWith(letterSpacing: -0.3),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: AppFonts.jakarta(
                  size: 13,
                  color: AppColors.white.withValues(alpha: 0.85),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              _HeroCta(label: 'Commencer', accent: AppColors.redDark, onTap: onStart),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCta extends StatelessWidget {
  const _HeroCta(
      {required this.label, required this.accent, required this.onTap});

  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_arrow_rounded, size: 16, color: accent),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: AppFonts.jakarta(
                    size: 13,
                    weight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
