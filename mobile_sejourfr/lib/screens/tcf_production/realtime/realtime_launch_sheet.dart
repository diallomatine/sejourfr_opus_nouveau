import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';

/// Choix de l'utilisateur au lancement d'une T1/T2 EO. `paywall` = il a touché
/// la carte temps réel alors qu'il n'est pas abonné (incitation à s'abonner).
enum RealtimeLaunchChoice { realtime, classic, paywall }

/// Modal §2.3 : s'ouvre POUR TOUT LE MONDE (abonné ou non). On SÉLECTIONNE un
/// format — TEMPS RÉEL avec un examinateur (une IA) ou CLASSIQUE (enregistrement
/// solo) — puis on confirme avec « Valider ». ✕ en haut ferme sans rien lancer
/// (retourne `null`). Trois états de la carte temps réel selon le quota :
///  - `cap == 0` (non-abonné) → verrouillée, un tap retourne `paywall` ;
///  - `cap > 0 && remaining == 0` (abonné, quota épuisé) → désactivée ;
///  - sinon → sélectionnable.
Future<RealtimeLaunchChoice?> showRealtimeLaunchSheet(
  BuildContext context, {
  required int remaining,
  required int cap,
}) {
  return showModalBottomSheet<RealtimeLaunchChoice>(
    context: context,
    backgroundColor: AppColors.white,
    barrierColor: AppColors.scrim,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
    ),
    builder: (ctx) => _LaunchSheetBody(remaining: remaining, cap: cap),
  );
}

class _LaunchSheetBody extends StatefulWidget {
  const _LaunchSheetBody({required this.remaining, required this.cap});

  final int remaining;
  final int cap;

  @override
  State<_LaunchSheetBody> createState() => _LaunchSheetBodyState();
}

class _LaunchSheetBodyState extends State<_LaunchSheetBody> {
  late RealtimeLaunchChoice _selected;

  bool get _locked => widget.cap == 0; // non-abonné → paywall
  // Sinon non disponible = abonné mais quota épuisé (carte grisée, pas de paywall).
  bool get _available => widget.cap > 0 && widget.remaining > 0;

  @override
  void initState() {
    super.initState();
    // Pré-sélection : temps réel si dispo, sinon classique.
    _selected =
        _available ? RealtimeLaunchChoice.realtime : RealtimeLaunchChoice.classic;
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
                enabled: _available,
                locked: _locked,
                selected:
                    _available && _selected == RealtimeLaunchChoice.realtime,
                footer: _available
                    ? _QuotaChip(remaining: widget.remaining)
                    : _locked
                        ? const _PremiumLockedChip()
                        : const _ExhaustedChip(),
                onTap: _available
                    ? () => setState(
                        () => _selected = RealtimeLaunchChoice.realtime)
                    : _locked
                        // Non-abonné : un tap ouvre le paywall (incitation).
                        ? () => Navigator.of(context)
                            .pop(RealtimeLaunchChoice.paywall)
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
    this.locked = false,
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
  final bool locked;
  final VoidCallback? onTap;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    // Verrouillé (non-abonné) = pleine opacité, c'est un CTA vers le paywall ;
    // épuisé (ni enabled ni locked) = grisé.
    return Opacity(
      opacity: enabled || locked ? 1 : 0.6,
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
                color: selected || locked ? accent : AppColors.line,
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
                    if (enabled)
                      _RadioDot(accent: accent, selected: selected)
                    else
                      Icon(LucideIcons.lock,
                          size: 18,
                          color: locked ? accent : AppColors.muted),
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

/// Abonné dont le quota est épuisé (pas de paywall : il est déjà Premium).
class _ExhaustedChip extends StatelessWidget {
  const _ExhaustedChip();

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

/// Non-abonné : carte verrouillée, un tap ouvre le paywall (incitation Intégral).
class _PremiumLockedChip extends StatelessWidget {
  const _PremiumLockedChip();

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
          const Icon(LucideIcons.lock, size: 14, color: AppColors.redDark),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              'Réservé à l\'abonnement Intégral — touchez pour vous abonner',
              style: AppFonts.label(color: AppColors.redDark, size: 11),
            ),
          ),
        ],
      ),
    );
  }
}
