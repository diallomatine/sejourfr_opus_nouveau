import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';

/// Bottom sheet de briefing affichée avant le démarrage d'un examen blanc
/// civique **global** (40 Q tous thèmes, 45 min, seuil 32/40). Branchée
/// depuis la card sombre du hub civique.
Future<void> showCiviqueExamBriefingSheet(
  BuildContext context, {
  required VoidCallback onStart,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetCtx) => _CiviqueBriefingBody(
      eyebrow: 'EXAMEN BLANC CIVIQUE',
      title: 'Prêt à passer ?',
      rows: const [
        _BriefRowData(
          icon: LucideIcons.circleHelp,
          text: '40 questions tirées sur les 5 thèmes officiels.',
        ),
        _BriefRowData(
          icon: LucideIcons.timer,
          text: '45 minutes chrono, pas de retour en arrière.',
        ),
        _BriefRowData(
          icon: LucideIcons.circleCheck,
          text: 'Seuil de réussite : 32 / 40 bonnes réponses.',
        ),
      ],
      onStart: () {
        Navigator.of(sheetCtx).pop();
        onStart();
      },
    ),
  );
}

/// Variante theme-scopée : 20 Q de ce thème, 20 min, seuil 16/20. Branchée
/// depuis l'onglet Examens du détail thème civique.
Future<void> showCiviqueThemeExamBriefingSheet(
  BuildContext context, {
  required String themeName,
  required VoidCallback onStart,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetCtx) => _CiviqueBriefingBody(
      eyebrow: 'EXAMEN · ${themeName.toUpperCase()}',
      title: 'Prêt à passer ?',
      rows: [
        _BriefRowData(
          icon: LucideIcons.circleHelp,
          text: '20 questions tirées uniquement du thème « $themeName ».',
        ),
        const _BriefRowData(
          icon: LucideIcons.timer,
          text: '20 minutes chrono, pas de retour en arrière.',
        ),
        const _BriefRowData(
          icon: LucideIcons.circleCheck,
          text: 'Seuil de réussite : 16 / 20 bonnes réponses.',
        ),
      ],
      onStart: () {
        Navigator.of(sheetCtx).pop();
        onStart();
      },
    ),
  );
}

class _BriefRowData {
  const _BriefRowData({required this.icon, required this.text});
  final IconData icon;
  final String text;
}

class _CiviqueBriefingBody extends StatelessWidget {
  const _CiviqueBriefingBody({
    required this.eyebrow,
    required this.title,
    required this.rows,
    required this.onStart,
  });

  final String eyebrow;
  final String title;
  final List<_BriefRowData> rows;
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
                eyebrow,
                style: AppFonts.mono(
                  size: 10,
                  color: AppColors.blueDark,
                  letterSpacing: 1.8,
                  weight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: AppFonts.display(size: 24, weight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              for (final r in rows) _BriefRow(icon: r.icon, text: r.text),
              const SizedBox(height: 22),
              AppButton(
                label: 'Commencer maintenant',
                icon: LucideIcons.play,
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
            child: Icon(icon, size: 16, color: AppColors.blueDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                text,
                style: AppFonts.ui(
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
