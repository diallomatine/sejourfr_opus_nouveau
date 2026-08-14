import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/diagnostic_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/fixed_action_bar.dart';
import '../diagnostic_intro_labels.dart';
import 'diagnostic_common.dart';

class DiagnosticIntro extends StatelessWidget {
  const DiagnosticIntro({
    super.key,
    required this.isStarting,
    required this.onStart,
    this.written,
    this.oral,
    this.isGuest = false,
    this.errorMessage,
  });

  final bool isStarting;
  final VoidCallback onStart;

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Le budget de temps passe AVANT le titre : c'est la
                    // première chose à lire, celle qui dit que ce n'est pas un
                    // examen.
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.clock,
                            size: 14,
                            color: AppColors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            diagnosticBudgetLabel(written, oral),
                            style: AppFonts.label(color: AppColors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Découvrez vos priorités TCF',
                      style: AppFonts.display(
                        size: 28,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Deux exercices courts, pas un examen.',
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
            label: 'Commencer mon diagnostic gratuit',
            iconRight: LucideIcons.arrowRight,
            isLoading: isStarting,
            onPressed: isStarting ? null : onStart,
          ),
        ),
      ],
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
