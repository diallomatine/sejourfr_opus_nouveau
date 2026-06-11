import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/lot_models.dart';
import '../../../core/theme/app_theme.dart';

/// Bottom sheet affiché quand l'utilisateur tape un lot déjà fait
/// (TCF QCM ou Civique) : deux CTAs « Voir le détail » (rapport
/// Q-par-Q) / « Reprendre » (nouveau passage). Le détail prend la
/// couleur d'accent passée, la reprise est rouge plein.
class LotDoneSheet extends StatelessWidget {
  const LotDoneSheet({
    super.key,
    required this.lot,
    required this.accent,
    required this.onViewDetail,
    required this.onResume,
  });

  final LotDto lot;
  final Color accent;
  final VoidCallback onViewDetail;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final score = lot.lastScore;
    final total = lot.totalQuestions;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.line2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Lot ${lot.numero}',
                style: AppFonts.ui(
                    size: 18, weight: FontWeight.w800, color: AppColors.ink),
              ),
              const SizedBox(height: 4),
              if (score != null)
                Text(
                  'Dernier score : $score / $total',
                  style: AppFonts.ui(size: 12.5, color: AppColors.muted),
                ),
              const SizedBox(height: 18),
              _LotSheetButton(
                label: 'Voir le détail',
                icon: LucideIcons.fileText,
                background: accent.withValues(alpha: 0.10),
                foreground: accent,
                onPressed: onViewDetail,
              ),
              const SizedBox(height: 10),
              _LotSheetButton(
                label: 'Refaire',
                icon: LucideIcons.refreshCw,
                background: AppColors.red,
                foreground: AppColors.white,
                onPressed: onResume,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LotSheetButton extends StatelessWidget {
  const _LotSheetButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: foreground),
                const SizedBox(width: 8),
                Text(label,
                    style: AppFonts.ui(
                        size: 14, weight: FontWeight.w800, color: foreground)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
