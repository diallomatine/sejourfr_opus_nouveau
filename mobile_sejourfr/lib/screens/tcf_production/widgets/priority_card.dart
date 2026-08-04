import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/production_models.dart';
import '../../../core/theme/app_theme.dart';
import 'correction_example.dart';

/// Une priorite de travail rendue pour ENSEIGNER : le constat ouvre, mais c'est
/// la technique (« comment ») et sa demonstration sur la phrase du candidat qui
/// occupent la place — pas une note de bas de bloc.
///
/// Une evaluation anterieure ne porte qu'une chaine : la carte se reduit alors
/// au constat, sans encadre vide.
class PriorityCard extends StatelessWidget {
  const PriorityCard({super.key, required this.priorite, required this.rang});

  final PointAAmeliorer priorite;

  /// Rang affiche (1, 2) : deux priorites classees, pas un inventaire.
  final int rang;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  '$rang',
                  style: AppFonts.ui(
                    size: 12,
                    weight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  priorite.constat,
                  style: AppFonts.ui(
                    size: 13.5,
                    weight: FontWeight.w700,
                    color: AppColors.ink,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          if (priorite.comment != null) ...[
            const SizedBox(height: 10),
            _CommentBlock(comment: priorite.comment!),
          ],
          if (priorite.exemple != null) ...[
            const SizedBox(height: 10),
            _ExempleBlock(exemple: priorite.exemple!),
          ],
        ],
      ),
    );
  }
}

/// La technique a appliquer : c'est la partie reutilisable du rapport, donc
/// celle qu'on met en avant.
class _CommentBlock extends StatelessWidget {
  const _CommentBlock({required this.comment});

  final String comment;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.blue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: AppColors.blue, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.wrench, size: 14, color: AppColors.blue),
              const SizedBox(width: 6),
              Text(
                'COMMENT FAIRE',
                style: AppFonts.label(size: 10, color: AppColors.blue)
                    .copyWith(letterSpacing: 1.1),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            comment,
            style: AppFonts.ui(
              size: 13,
              color: AppColors.ink,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// La demonstration sur SA phrase : sans elle, la technique reste abstraite.
class _ExempleBlock extends StatelessWidget {
  const _ExempleBlock({required this.exemple});

  final ExempleReecriture exemple;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SUR VOTRE PRODUCTION',
            style: AppFonts.label(size: 10, color: AppColors.muted)
                .copyWith(letterSpacing: 1.1),
          ),
          const SizedBox(height: 8),
          BeforeAfterLines(
            avant: exemple.avant,
            apres: exemple.apres,
            avantLabel: 'Votre phrase :',
            apresLabel: 'Réécrite :',
          ),
        ],
      ),
    );
  }
}
