import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';

/// Action à droite d'un slot d'examen (cf. maquette). 4 états mutuellement
/// exclusifs : locked (chip Premium), done (pill « Fait » teinté accent —
/// le tap rouvre le sheet Refaire / Rapport), next (Démarrer en filled),
/// available (Démarrer en outline). [accent] = couleur du parcours.
class ExamSlotAction extends StatelessWidget {
  const ExamSlotAction({
    super.key,
    required this.done,
    required this.next,
    required this.locked,
    required this.onPressed,
    this.accent = AppColors.blue,
  });

  final bool done;
  final bool next;
  final bool locked;
  final VoidCallback onPressed;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (locked) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.lock, size: 13, color: AppColors.muted2),
          const SizedBox(width: 4),
          Text(
            'Premium',
            style: AppFonts.ui(
                size: 11.5, weight: FontWeight.w700, color: AppColors.muted2),
          ),
        ],
      );
    }
    if (done) {
      return Material(
        color: Color.alphaBlend(
          accent.withValues(alpha: 0.12),
          AppColors.white,
        ),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.check, size: 13, color: accent),
                const SizedBox(width: 5),
                Text(
                  'Fait',
                  style: AppFonts.ui(
                    size: 12,
                    weight: FontWeight.w600,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return _ActionButton(
      label: 'Démarrer',
      onPressed: onPressed,
      filled: next,
      outlineColor: next ? accent : AppColors.line,
      fillColor: next ? accent : AppColors.white,
      textColor: next ? AppColors.white : accent,
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onPressed,
    required this.filled,
    required this.outlineColor,
    required this.fillColor,
    required this.textColor,
  });

  final String label;
  final VoidCallback onPressed;
  final bool filled;
  final Color outlineColor;
  final Color fillColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? fillColor : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: filled ? null : Border.all(color: outlineColor),
          ),
          child: Text(
            label,
            style: AppFonts.ui(
              size: 12.5,
              weight: FontWeight.w600,
              color: textColor,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}
