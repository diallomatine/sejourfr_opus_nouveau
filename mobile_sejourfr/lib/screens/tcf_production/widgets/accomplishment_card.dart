import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/production_models.dart';
import '../../../core/theme/app_theme.dart';

/// Check-list « ce que vous avez fait » de la consigne, affichee AVANT le
/// detail de langue : le candidat doit voir tout de suite s'il a oublie un
/// point demande.
///
/// Distinction capitale : un point **obligatoire** oublie pese sur la note ;
/// une **piste** non abordee est informative et ne coute rien. Le libelle le
/// dit explicitement pour qu'aucune piste ne soit lue comme une faute.
///
/// Renvoie [SizedBox.shrink] quand le backend n'a pas fourni le bloc
/// (evaluations anterieures au contrat v4).
class AccomplishmentCard extends StatelessWidget {
  const AccomplishmentCard({super.key, required this.accomplissement});

  final Accomplissement? accomplissement;

  @override
  Widget build(BuildContext context) {
    final data = accomplissement;
    if (data == null || data.isEmpty) return const SizedBox.shrink();

    final traites = data.pointsTraites;
    final manques = data.manques;
    final pistes = data.pistesNonAbordees;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.listChecks, size: 18, color: AppColors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ce que demandait la consigne',
                  style: AppFonts.ui(
                    size: 15,
                    weight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final point in traites)
            _PointRow(
              libelle: point.libelle,
              icon: LucideIcons.circleCheck,
              color: AppColors.green,
              tag: point.obligatoire ? null : 'piste abordée',
            ),
          for (final point in manques)
            _PointRow(
              libelle: point.libelle,
              icon: LucideIcons.circleX,
              color: AppColors.red,
              tag: 'demandé',
            ),
          for (final point in pistes)
            _PointRow(
              libelle: point.libelle,
              icon: LucideIcons.circleDashed,
              color: AppColors.muted2,
              tag: 'piste',
              muted: true,
            ),
          if (pistes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Les pistes étaient facultatives : ne pas les traiter '
              "n'enlève aucun point.",
              style: AppFonts.ui(
                size: 12,
                color: AppColors.muted,
                height: 1.4,
              ),
            ),
          ],
          if (manques.isEmpty && traites.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Tous les points demandés ont été traités.',
              style: AppFonts.ui(
                size: 12,
                weight: FontWeight.w600,
                color: AppColors.green,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PointRow extends StatelessWidget {
  const _PointRow({
    required this.libelle,
    required this.icon,
    required this.color,
    this.tag,
    this.muted = false,
  });

  final String libelle;
  final IconData icon;
  final Color color;
  final String? tag;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final tagLabel = tag;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  libelle,
                  style: AppFonts.ui(
                    size: 13.5,
                    weight: muted ? FontWeight.w500 : FontWeight.w600,
                    color: muted ? AppColors.muted : AppColors.ink,
                    height: 1.35,
                  ),
                ),
                if (tagLabel != null) _Tag(label: tagLabel, color: color),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: AppFonts.ui(
          size: 11,
          weight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
