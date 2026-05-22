import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';

/// Bottom sheet de briefing affichée avant le démarrage d'un examen blanc
/// civique. Rappelle les conditions (40 Q, 45 min, seuil 32/40, pas de
/// retour arrière) puis appelle `onStart` au tap du CTA primaire.
Future<void> showCiviqueExamBriefingSheet(
  BuildContext context, {
  required VoidCallback onStart,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetCtx) => _CiviqueExamBriefingSheet(
      onStart: () {
        Navigator.of(sheetCtx).pop();
        onStart();
      },
    ),
  );
}

class _CiviqueExamBriefingSheet extends StatelessWidget {
  const _CiviqueExamBriefingSheet({required this.onStart});

  final VoidCallback onStart;

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
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'EXAMEN BLANC CIVIQUE',
                style: AppFonts.mono(
                  size: 10,
                  color: AppColors.blue,
                  letterSpacing: 1.8,
                  weight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Prêt à passer ?',
                style: AppFonts.fraunces(size: 24, weight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              const _BriefRow(
                icon: Icons.quiz_outlined,
                text: '40 questions tirées sur les 5 thèmes officiels.',
              ),
              const _BriefRow(
                icon: Icons.timer_outlined,
                text: '45 minutes chrono, pas de retour en arrière.',
              ),
              const _BriefRow(
                icon: Icons.check_circle_outline_rounded,
                text: 'Seuil de réussite : 32 / 40 bonnes réponses.',
              ),
              const SizedBox(height: 22),
              AppButton(
                label: 'Commencer maintenant',
                icon: Icons.play_arrow_rounded,
                onPressed: onStart,
              ),
              const SizedBox(height: 8),
              AppButton(
                label: 'Plus tard',
                variant: AppButtonVariant.ghost,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BriefRow extends StatelessWidget {
  const _BriefRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.blueLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: AppColors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                text,
                style: AppFonts.jakarta(
                  size: 13,
                  color: AppColors.ink2,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
