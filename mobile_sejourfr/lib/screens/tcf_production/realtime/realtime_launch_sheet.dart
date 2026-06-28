import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_sheet.dart';

/// Choix de l'utilisateur au lancement d'une T1/T2 EO.
enum RealtimeLaunchChoice { realtime, classic }

/// Modal §2.3 : propose le mode examinateur temps réel (si quota dispo) ou le
/// mode classique (enregistrement). Affiche le nombre de sessions restantes.
/// Quota 0 → option temps réel désactivée, l'utilisateur ne peut que choisir
/// le mode classique (le candidat n'est jamais bloqué).
Future<RealtimeLaunchChoice?> showRealtimeLaunchSheet(
  BuildContext context, {
  required int remaining,
}) {
  final hasQuota = remaining > 0;
  return showAppSheet<RealtimeLaunchChoice>(
    context,
    icon: LucideIcons.messagesSquare,
    iconBg: AppColors.redLight,
    iconColor: AppColors.redDark,
    title: 'Comment voulez-vous vous exercer ?',
    sub: hasQuota
        ? 'Vous avez $remaining session${remaining > 1 ? 's' : ''} avec un examinateur restante${remaining > 1 ? 's' : ''}.'
        : 'Vous n\'avez plus de session avec un examinateur. Continuez en mode enregistrement.',
    children: [
      AppButton(
        label: 'Passer en temps réel avec un examinateur',
        icon: LucideIcons.mic,
        variant: AppButtonVariant.primary,
        onPressed: hasQuota
            ? () => Navigator.of(context).pop(RealtimeLaunchChoice.realtime)
            : null,
      ),
      AppButton(
        label: 'Le faire en mode classique (enregistrement)',
        variant: AppButtonVariant.outline,
        onPressed: () =>
            Navigator.of(context).pop(RealtimeLaunchChoice.classic),
      ),
      if (hasQuota)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'En temps réel, l\'examinateur vous parle et vous répond. '
            'Votre échange est noté à la fin, comme un vrai oral.',
            textAlign: TextAlign.center,
            style: AppFonts.ui(size: 12, color: AppColors.inkFaint),
          ),
        ),
    ],
  );
}
