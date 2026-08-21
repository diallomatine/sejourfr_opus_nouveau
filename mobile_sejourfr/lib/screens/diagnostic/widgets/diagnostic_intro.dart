import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/diagnostic_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/eyebrow.dart';
import '../../../core/widgets/fixed_action_bar.dart';
import '../diagnostic_intro_labels.dart';
import '../diagnostic_variant.dart';
import 'diagnostic_common.dart';

/// L'entrée du diagnostic : le budget annoncé, le **choix de la variante**,
/// puis le détail des deux exercices.
///
/// 🛑 Les deux variantes lancent **le même parcours** (écrit puis oral) : la
/// différence se joue **après l'analyse**, quand le bilan propose ou non de
/// mesurer la compréhension. Rien n'est envoyé au serveur ici — cf.
/// `diagnostic_variant.dart`.
class DiagnosticIntro extends StatelessWidget {
  const DiagnosticIntro({
    super.key,
    required this.isStarting,
    required this.onStart,
    required this.variant,
    required this.onVariantChanged,
    this.written,
    this.oral,
    this.isGuest = false,
    this.errorMessage,
  });

  final bool isStarting;
  final VoidCallback onStart;

  /// L'intention courante et son changement — un simple état de front.
  final DiagnosticVariant variant;
  final ValueChanged<DiagnosticVariant> onVariantChanged;

  /// Les deux sujets servis, quand ils existent : c'est d'eux que sortent les
  /// mesures annoncées. Absents (compte sans session, réseau), l'écran retombe
  /// sur une description sans chiffre plutôt que d'en inventer un.
  final DiagnosticExerciseView? written;
  final DiagnosticExerciseView? oral;

  /// Un visiteur peut produire avant de créer son compte : on le lui dit.
  final bool isGuest;

  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                decoration: BoxDecoration(
                  gradient:
                      AppGradients.hero(AppColors.blueDark, AppColors.blue),
                  borderRadius: BorderRadius.circular(AppRadii.xl),
                  boxShadow: AppShadows.md,
                ),
                // 🛑 **Aucune pilule de budget en tête.** Le coût est annoncé
                // sur **chaque carte de variante**, une fois par option — comme
                // sur la maquette et sur le web. Un second chiffre au-dessus du
                // titre resservait celui de l'option sélectionnée et se
                // désaccordait dès qu'on changeait d'avis.
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Découvrez votre niveau TCF',
                      style: AppFonts.display(
                        size: 28,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Obtenez une première estimation de votre niveau et '
                      'découvrez ce qui vous bloque pour atteindre votre '
                      'objectif.',
                      style: AppFonts.ui(
                        size: 14.5,
                        color: AppColors.white.withValues(alpha: 0.9),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              for (final option in DiagnosticVariant.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _VariantCard(
                    variant: option,
                    selected: option == variant,
                    // La variante « rapide » est celle que le produit
                    // recommande : deux productions suffisent à ouvrir un Plan,
                    // la compréhension se complète ensuite sans rien perdre.
                    recommended: option == DiagnosticVariant.rapide,
                    duration: diagnosticVariantDurationLabel(
                      option,
                      written,
                      oral,
                    ),
                    onSelect: () => onVariantChanged(option),
                  ),
                ),
              const SizedBox(height: 8),
              const Eyebrow('LES DEUX PREMIERS EXERCICES'),
              const SizedBox(height: 10),
              _IntroItem(
                icon: LucideIcons.penLine,
                title: 'Écrit',
                measure:
                    diagnosticWrittenMeasureLabel(written) ?? 'un court texte',
                text: 'Vous rédigez un court texte.',
              ),
              const SizedBox(height: 10),
              _IntroItem(
                icon: LucideIcons.mic,
                title: 'Oral',
                measure: diagnosticOralMeasureLabel(oral) ??
                    'un court enregistrement',
                text: 'Vous vous enregistrez, sans conversation en direct.',
              ),
              const SizedBox(height: 16),
              Text(
                'Pas besoin d’être parfait. Répondez naturellement : '
                'l’objectif est simplement d’estimer votre niveau et de '
                'construire votre plan.',
                style: AppFonts.ui(
                  size: 13.5,
                  color: AppColors.inkSoft,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              if (errorMessage != null) ...[
                DiagnosticErrorBanner(message: errorMessage!),
                const SizedBox(height: 18),
              ],
              Text(
                'Votre diagnostic reste accessible ensuite : vous pouvez '
                'compléter les épreuves manquantes quand vous voulez.',
                style: AppFonts.ui(
                  size: 12,
                  color: AppColors.inkFaint,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isGuest
                    ? 'Commencez sans compte. Il ne vous sera demandé qu’au '
                        'moment de l’analyse. Estimation d’entraînement, non '
                        'officielle.'
                    : 'Estimation d’entraînement, non officielle.',
                textAlign: TextAlign.center,
                style: AppFonts.ui(size: 12, color: AppColors.inkFaint),
              ),
            ],
          ),
        ),
        FixedActionBar(
          child: AppButton(
            label: diagnosticVariantCta(variant),
            iconRight: LucideIcons.arrowRight,
            isLoading: isStarting,
            onPressed: isStarting ? null : onStart,
          ),
        ),
      ],
    );
  }
}

/// Une des deux options d'entrée. Sélectionnée, elle se teinte et son bord
/// passe au bleu — aucune information n'est masquée sur l'autre.
class _VariantCard extends StatelessWidget {
  const _VariantCard({
    required this.variant,
    required this.selected,
    required this.recommended,
    required this.duration,
    required this.onSelect,
  });

  final DiagnosticVariant variant;
  final bool selected;
  final bool recommended;
  final String duration;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${diagnosticVariantTitle(variant)} · $duration',
      child: AppCard(
        onTap: onSelect,
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
        color: selected ? AppColors.blueSoft : AppColors.white,
        border: Border.all(
          color: selected ? AppColors.blue : AppColors.line,
          width: selected ? 1.5 : 1,
        ),
        boxShadow: selected ? AppShadows.md : AppShadows.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.blue : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? AppColors.blue : AppColors.line,
                      width: 1.5,
                    ),
                  ),
                  child: selected
                      ? const Icon(
                          LucideIcons.check,
                          size: 12,
                          color: AppColors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    diagnosticVariantTitle(variant),
                    style: AppFonts.display(size: 19),
                  ),
                ),
                if (recommended) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      border: Border.all(color: AppColors.blueLight),
                    ),
                    child: Text(
                      'Recommandé',
                      style: AppFonts.ui(
                        size: 11,
                        weight: FontWeight.w700,
                        color: AppColors.blue,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 7),
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      diagnosticVariantScope(variant),
                      style: AppFonts.ui(
                        size: 12.5,
                        weight: FontWeight.w600,
                        color: AppColors.inkFaint,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    LucideIcons.clock,
                    size: 13,
                    color: AppColors.inkFaint,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    duration,
                    style: AppFonts.ui(
                      size: 12.5,
                      weight: FontWeight.w600,
                      color: AppColors.inkFaint,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final highlight
                      in diagnosticVariantHighlights(variant)) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 3),
                          child: Icon(
                            LucideIcons.check,
                            size: 14,
                            color: AppColors.blue,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            highlight,
                            style: AppFonts.ui(
                              size: 13.5,
                              height: 1.4,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroItem extends StatelessWidget {
  const _IntroItem({
    required this.icon,
    required this.title,
    required this.measure,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String measure;
  final String text;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.blueLight,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Icon(icon, size: 21, color: AppColors.blue),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(title,
                        style:
                            AppFonts.ui(size: 14.5, weight: FontWeight.w700)),
                    Text(
                      measure,
                      style: AppFonts.ui(
                        size: 13.5,
                        weight: FontWeight.w700,
                        color: AppColors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: AppFonts.ui(
                    size: 12.5,
                    color: AppColors.inkFaint,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
