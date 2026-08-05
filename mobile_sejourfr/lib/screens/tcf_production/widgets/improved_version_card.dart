import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';

/// Votre production, reecrite en entier — le seul endroit du rapport ou le
/// candidat voit ce qu'on attendait de lui, en continu, plutot qu'en morceaux.
///
/// N'existe qu'en expression ECRITE : a l'oral, on ne demande pas de reciter un
/// texte, et reecrire un discours n'apprendrait rien. Le bloc disparait donc
/// entierement cote EO, sans trou visuel.
class ImprovedVersionCard extends StatelessWidget {
  const ImprovedVersionCard({super.key, required this.texte});

  final String? texte;

  @override
  Widget build(BuildContext context) {
    final content = texte;
    if (content == null || content.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.fileCheck, size: 18, color: AppColors.green),
              const SizedBox(width: 8),
              Text(
                'Version améliorée',
                style: AppFonts.ui(
                  size: 13,
                  weight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Vos idées, réécrites comme elles auraient pu être rendues. '
            'Comparez avec votre texte : ce sont les mêmes idées, dites '
            'autrement.',
            style: AppFonts.ui(size: 12, color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.line),
            ),
            child: Text(
              content,
              style: AppFonts.ui(
                size: 13.5,
                color: AppColors.ink,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
