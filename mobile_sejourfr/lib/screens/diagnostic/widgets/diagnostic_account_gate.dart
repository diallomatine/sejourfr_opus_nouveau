import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/fixed_action_bar.dart';
import 'diagnostic_common.dart';

/// Écran de bascule : le visiteur a produit son écrit **et** son oral, il crée
/// maintenant son compte pour que l'analyse parte.
///
/// Aucun résultat réel n'est affiché ici — l'analyse n'a pas encore eu lieu et
/// elle coûte deux appels au correcteur. Ce que montre l'écran est un
/// **exemple**, étiqueté comme tel à côté de chaque élément inventé.
class DiagnosticAccountGate extends StatelessWidget {
  const DiagnosticAccountGate({
    super.key,
    required this.onRegister,
    required this.onLogin,
    this.errorMessage,
    this.noticeMessage,
  });

  final VoidCallback onRegister;
  final VoidCallback onLogin;
  final String? errorMessage;
  final String? noticeMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              const DiagnosticProgress(activeStep: 2, completedSteps: 2),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
                decoration: BoxDecoration(
                  gradient:
                      AppGradients.hero(AppColors.blueDark, AppColors.blue),
                  borderRadius: BorderRadius.circular(AppRadii.xl),
                  boxShadow: AppShadows.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                      child: const Icon(
                        LucideIcons.checkCheck,
                        color: AppColors.white,
                        size: 25,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Vos deux réponses sont prêtes',
                      style: AppFonts.display(size: 26, color: AppColors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Créez votre compte pour lancer l’analyse et recevoir '
                      'vos priorités.',
                      style: AppFonts.ui(
                        size: 14.5,
                        color: AppColors.white.withValues(alpha: 0.9),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AppCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: AppColors.greenLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.shieldCheck,
                        size: 19,
                        color: AppColors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Votre travail est conservé',
                            style: AppFonts.ui(
                              size: 14.5,
                              weight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Votre texte et votre enregistrement sont gardés '
                            'sur ce téléphone. Ils partent au moment où votre '
                            'compte existe — même si vous fermez '
                            'l’application d’ici là.',
                            style: AppFonts.ui(
                              size: 12.5,
                              color: AppColors.inkSoft,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (noticeMessage != null) ...[
                const SizedBox(height: 12),
                _NoticeBanner(message: noticeMessage!),
              ],
              if (errorMessage != null) ...[
                const SizedBox(height: 12),
                DiagnosticErrorBanner(message: errorMessage!),
              ],
              const SizedBox(height: 22),
              Text(
                'CE QUE VOUS ALLEZ RECEVOIR',
                style: AppFonts.label(color: AppColors.inkFaint),
              ),
              const SizedBox(height: 10),
              const _ExampleResultCard(),
              const SizedBox(height: 12),
              Text(
                'Estimation d’entraînement, non officielle.',
                textAlign: TextAlign.center,
                style: AppFonts.ui(size: 12, color: AppColors.inkFaint),
              ),
            ],
          ),
        ),
        FixedActionBar(
          child: Column(
            children: [
              AppButton(
                label: 'Créer mon compte et analyser',
                iconRight: LucideIcons.arrowRight,
                onPressed: onRegister,
              ),
              const SizedBox(height: 10),
              AppButton(
                label: 'J’ai déjà un compte',
                variant: AppButtonVariant.soft,
                height: 48,
                onPressed: onLogin,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Aperçu **fabriqué** d'un résultat. Rien ici ne vient du serveur : la carte
/// porte son étiquette « exemple » et une phrase qui le redit en toutes
/// lettres, pour qu'aucun candidat ne puisse la lire comme son bilan.
class _ExampleResultCard extends StatelessWidget {
  const _ExampleResultCard();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Exemple de résultat, ce ne sont pas vos réponses',
      child: AppCard(
        borderRadius: AppRadii.xl,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.amberLight,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text(
                    'EXEMPLE',
                    style: AppFonts.label(color: AppColors.amberDark),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ce ne sont pas vos réponses',
                    style: AppFonts.ui(size: 12.5, color: AppColors.inkFaint),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: const [
                Expanded(
                  child: _ExampleLevel(label: 'Écrit', level: 'B1'),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _ExampleLevel(label: 'Oral', level: 'A2'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Priorité 1/3',
              style: AppFonts.label(color: AppColors.blue),
            ),
            const SizedBox(height: 6),
            Text(
              'Donner une raison et un exemple concret',
              style: AppFonts.display(size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              'Vos idées sont claires mais rarement justifiées : une raison '
              'puis un exemple suffisent à passer le palier.',
              style: AppFonts.ui(
                size: 13,
                color: AppColors.inkSoft,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.blueSoft,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.target,
                    size: 17,
                    color: AppColors.blue,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Un exercice de 5 minutes vous est proposé sur cette '
                      'priorité.',
                      style: AppFonts.ui(
                        size: 12.5,
                        color: AppColors.inkSoft,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Exemple illustratif de la mise en page du résultat. Vos '
              'niveaux et vos priorités dépendront de ce que vous venez '
              'd’écrire et d’enregistrer.',
              style: AppFonts.ui(
                size: 12,
                color: AppColors.inkFaint,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExampleLevel extends StatelessWidget {
  const _ExampleLevel({required this.label, required this.level});

  final String label;
  final String level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: AppFonts.label(color: AppColors.inkFaint),
          ),
          const SizedBox(height: 4),
          Text(level, style: AppFonts.display(size: 22)),
        ],
      ),
    );
  }
}

class _NoticeBanner extends StatelessWidget {
  const _NoticeBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.amberLight,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.info, size: 18, color: AppColors.amberDark),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: AppFonts.ui(
                size: 13,
                color: AppColors.amberDark,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
