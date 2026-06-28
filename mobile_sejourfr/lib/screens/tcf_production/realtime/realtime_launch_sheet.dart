import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';

/// Choix de l'utilisateur au lancement d'une T1/T2 EO.
enum RealtimeLaunchChoice { realtime, classic }

/// Modal §2.3 : deux formats pour passer la tâche — TEMPS RÉEL avec un
/// examinateur (une IA) ou CLASSIQUE (enregistrement solo). Cartes à texte
/// complet (jamais tronqué), badge « IA », et mention explicite que lancer une
/// session temps réel décompte 1 unité du quota du pass. Quota 0 → carte temps
/// réel désactivée ; le candidat n'est jamais bloqué (mode classique dispo).
Future<RealtimeLaunchChoice?> showRealtimeLaunchSheet(
  BuildContext context, {
  required int remaining,
}) {
  final hasQuota = remaining > 0;
  return showModalBottomSheet<RealtimeLaunchChoice>(
    context: context,
    backgroundColor: AppColors.white,
    barrierColor: AppColors.scrim,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
    ),
    builder: (ctx) => SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.9),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                ),
              ),
              Text('Comment passer cette tâche ?',
                  textAlign: TextAlign.center, style: AppFonts.display(size: 19)),
              const SizedBox(height: 4),
              Text('Choisissez votre format pour cet oral.',
                  textAlign: TextAlign.center,
                  style: AppFonts.ui(size: 13, color: AppColors.muted)),
              const SizedBox(height: 18),
              _OptionCard(
                icon: LucideIcons.messagesSquare,
                title: 'Avec un examinateur',
                showIaBadge: true,
                description:
                    'Une intelligence artificielle joue l\'examinateur : elle '
                    'vous parle et vous répond en direct, comme à un vrai oral. '
                    'Votre échange est noté à la fin.',
                accent: AppColors.red,
                accentBg: AppColors.redLight,
                enabled: hasQuota,
                footer: hasQuota
                    ? _QuotaChip(remaining: remaining)
                    : const _LockedChip(),
                onTap: hasQuota
                    ? () => Navigator.of(ctx).pop(RealtimeLaunchChoice.realtime)
                    : null,
              ),
              const SizedBox(height: 12),
              _OptionCard(
                icon: LucideIcons.mic,
                title: 'Tout(e) seul(e) (enregistrement)',
                showIaBadge: false,
                description:
                    'Vous parlez seul, sans interlocuteur ; votre enregistrement '
                    'est ensuite évalué par l\'IA.',
                accent: AppColors.blue,
                accentBg: AppColors.blueLight,
                enabled: true,
                onTap: () =>
                    Navigator.of(ctx).pop(RealtimeLaunchChoice.classic),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.showIaBadge,
    required this.description,
    required this.accent,
    required this.accentBg,
    required this.enabled,
    required this.onTap,
    this.footer,
  });

  final IconData icon;
  final String title;
  final bool showIaBadge;
  final String description;
  final Color accent;
  final Color accentBg;
  final bool enabled;
  final VoidCallback? onTap;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(
                color: enabled ? accent : AppColors.line,
                width: enabled ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: accentBg,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                      child: Icon(icon, size: 21, color: accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(title, style: AppFonts.display(size: 15)),
                    ),
                    if (showIaBadge) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.redLight,
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                        ),
                        child: Text('IA',
                            style:
                                AppFonts.label(color: AppColors.redDark, size: 11)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Text(description,
                    style: AppFonts.ui(size: 13, color: AppColors.muted)),
                if (footer != null) ...[
                  const SizedBox(height: 12),
                  footer!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mention explicite du décompte sur le pass.
class _QuotaChip extends StatelessWidget {
  const _QuotaChip({required this.remaining});

  final int remaining;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.redLight,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.ticket, size: 14, color: AppColors.redDark),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              '−1 session · il vous en reste $remaining sur votre pass',
              style: AppFonts.label(color: AppColors.redDark, size: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _LockedChip extends StatelessWidget {
  const _LockedChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.lock, size: 14, color: AppColors.muted),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              'Plus de session temps réel sur votre pass',
              style: AppFonts.label(color: AppColors.muted, size: 11),
            ),
          ),
        ],
      ),
    );
  }
}
