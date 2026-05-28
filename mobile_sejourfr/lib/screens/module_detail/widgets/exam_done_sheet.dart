import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Bottom sheet affichée quand on tape un slot d'examen blanc déjà fait
/// (TCF QCM ou Civique). Même visuel que `LotDoneSheet` : titre +
/// sous-titre optionnel (score formaté par le caller), CTA « Voir le
/// détail » en accent tinté, CTA « Reprendre » en rouge plein.
class ExamDoneSheet extends StatelessWidget {
  const ExamDoneSheet({
    super.key,
    required this.title,
    required this.accent,
    required this.onViewDetail,
    required this.onResume,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Color accent;
  final VoidCallback onViewDetail;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
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
                title,
                style: AppFonts.jakarta(
                    size: 18, weight: FontWeight.w800, color: AppColors.ink),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: AppFonts.jakarta(size: 12.5, color: AppColors.muted),
                ),
              ],
              const SizedBox(height: 18),
              _ExamSheetButton(
                label: 'Voir le détail',
                icon: Icons.description_outlined,
                background: accent.withValues(alpha: 0.10),
                foreground: accent,
                onPressed: onViewDetail,
              ),
              const SizedBox(height: 10),
              _ExamSheetButton(
                label: 'Reprendre',
                icon: Icons.refresh_rounded,
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

class _ExamSheetButton extends StatelessWidget {
  const _ExamSheetButton({
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
                    style: AppFonts.jakarta(
                        size: 14, weight: FontWeight.w800, color: foreground)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
