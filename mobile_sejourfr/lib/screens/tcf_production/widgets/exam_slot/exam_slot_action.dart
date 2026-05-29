import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Bouton d'action à droite d'un slot d'examen. 3 états mutuellement
/// exclusifs : locked (chip Premium), done (Refaire en ghost), next (Démarrer
/// en filled), available (Démarrer en outline). [accent] = couleur du module
/// (bleu QCM, bleu sur EE/EO car le CTA principal est aligné même côté EE/EO).
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
          const Icon(Icons.workspace_premium_outlined,
              size: 14, color: AppColors.muted2),
          const SizedBox(width: 4),
          Text(
            'Premium',
            style: AppFonts.jakarta(
                size: 11, weight: FontWeight.w700, color: AppColors.muted2),
          ),
        ],
      );
    }
    if (done) {
      return _ActionButton(
        label: 'Refaire',
        onPressed: onPressed,
        filled: false,
        outlineColor: AppColors.line,
        fillColor: AppColors.white,
        textColor: AppColors.muted,
      );
    }
    if (next) {
      return _ActionButton(
        label: 'Démarrer',
        onPressed: onPressed,
        filled: true,
        outlineColor: accent,
        fillColor: accent,
        textColor: AppColors.white,
      );
    }
    return _ActionButton(
      label: 'Démarrer',
      onPressed: onPressed,
      filled: false,
      outlineColor: accent,
      fillColor: AppColors.white,
      textColor: accent,
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
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: filled ? null : Border.all(color: outlineColor, width: 1),
          ),
          child: Text(
            label,
            style: AppFonts.jakarta(
              size: 12,
              weight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
