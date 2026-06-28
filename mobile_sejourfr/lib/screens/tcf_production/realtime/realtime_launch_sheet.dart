import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';

/// Choix de l'utilisateur au lancement d'une T1/T2 EO.
enum RealtimeLaunchChoice { realtime, classic }

/// Modal §2.3 : on SÉLECTIONNE un format — TEMPS RÉEL avec un examinateur (une
/// IA) ou CLASSIQUE (enregistrement solo) — puis on confirme avec « Valider ».
/// ✕ en haut ferme sans rien lancer (retourne `null`). Cartes à texte complet
/// (jamais tronqué), badge « IA », mention du décompte sur le pass. Quota 0 →
/// carte temps réel désactivée ; le candidat n'est jamais bloqué.
Future<RealtimeLaunchChoice?> showRealtimeLaunchSheet(
  BuildContext context, {
  required int remaining,
}) {
  return showModalBottomSheet<RealtimeLaunchChoice>(
    context: context,
    backgroundColor: AppColors.white,
    barrierColor: AppColors.scrim,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
    ),
    builder: (ctx) => _LaunchSheetBody(remaining: remaining),
  );
}

class _LaunchSheetBody extends StatefulWidget {
  const _LaunchSheetBody({required this.remaining});

  final int remaining;

  @override
  State<_LaunchSheetBody> createState() => _LaunchSheetBodyState();
}

class _LaunchSheetBodyState extends State<_LaunchSheetBody> {
  late RealtimeLaunchChoice _selected;

  bool get _hasQuota => widget.remaining > 0;

  @override
  void initState() {
    super.initState();
    // Pré-sélection : temps réel si quota dispo, sinon classique.
    _selected =
        _hasQuota ? RealtimeLaunchChoice.realtime : RealtimeLaunchChoice.classic;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(LucideIcons.x,
                      size: 20, color: AppColors.muted),
                ),
              ),
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                ),
              ),
              Text('Comment passer cette tâche ?',
                  textAlign: TextAlign.center, style: AppFonts.display(size: 19)),
              const SizedBox(height: 4),
              Text('Choisissez votre format, puis validez.',
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
                enabled: _hasQuota,
                selected: _selected == RealtimeLaunchChoice.realtime,
                footer: _hasQuota
                    ? _QuotaChip(remaining: widget.remaining)
                    : const _LockedChip(),
                onTap: _hasQuota
                    ? () => setState(
                        () => _selected = RealtimeLaunchChoice.realtime)
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
                selected: _selected == RealtimeLaunchChoice.classic,
                onTap: () =>
                    setState(() => _selected = RealtimeLaunchChoice.classic),
              ),
              const SizedBox(height: 18),
              AppButton(
                label: 'Valider',
                variant: AppButtonVariant.primary,
                onPressed: () => Navigator.of(context).pop(_selected),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
    required this.selected,
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
  final bool selected;
  final VoidCallback? onTap;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: Material(
        color: selected ? accentBg.withValues(alpha: 0.4) : AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(
                color: selected ? accent : AppColors.line,
                width: selected ? 2 : 1,
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
                    const SizedBox(width: 8),
                    _RadioDot(accent: accent, selected: selected),
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

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.accent, required this.selected});

  final Color accent;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? accent : AppColors.white,
        border: Border.all(
          color: selected ? accent : AppColors.line,
          width: 1.5,
        ),
      ),
      child: selected
          ? const Icon(LucideIcons.check, size: 13, color: AppColors.white)
          : null,
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
