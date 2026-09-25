import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/fixed_action_bar.dart';
import 'diagnostic_common.dart';
import 'diagnostic_outcomes.dart';

/// Écran de bascule : le visiteur a produit, il crée maintenant son compte
/// pour que l'analyse parte. Miroir texte pour texte de
/// `DiagnosticAccountGate.tsx` (web) : même titre, même phrase, même
/// argumentaire (`diagnostic_outcomes.dart`).
///
/// 🛑 Aucun résultat n'est affiché ici — l'analyse n'a pas encore eu lieu et
/// elle coûte un appel au correcteur. Et aucun exemple chiffré non plus : un
/// faux bilan « B1 / A2 » juste avant l'inscription se lit comme une promesse.
class DiagnosticAccountGate extends StatelessWidget {
  const DiagnosticAccountGate({
    super.key,
    required this.hasOral,
    required this.onRegister,
    required this.onLogin,
    this.errorMessage,
    this.noticeMessage,
  });

  /// Ce diagnostic comportait-il une étape orale ? 🛑 `false` sur le
  /// diagnostic rapide : l'écran ne parle alors ni de « deux réponses » ni
  /// d'enregistrement — le candidat n'a rien enregistré.
  final bool hasOral;
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
                      'DERNIÈRE ÉTAPE · COMPTE GRATUIT',
                      style: AppFonts.label(
                        color: AppColors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      hasOral
                          ? 'Vos deux réponses sont prêtes'
                          : 'Votre texte est enregistré',
                      style: AppFonts.display(size: 26, color: AppColors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Créez votre compte gratuit pour lancer l’analyse. '
                      'C’est lui qui portera votre résultat et votre plan '
                      'de travail.',
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
                            hasOral
                                ? 'Votre texte et votre enregistrement sont '
                                    'gardés sur ce téléphone. Ils partent au '
                                    'moment où votre compte existe — même si '
                                    'vous fermez l’application d’ici là.'
                                : 'Votre texte est gardé sur ce téléphone. Il '
                                    'part au moment où votre compte existe — '
                                    'même si vous fermez l’application d’ici '
                                    'là.',
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
                kTcfDiagnosticGatePanelTitle.toUpperCase(),
                style: AppFonts.label(color: AppColors.inkFaint),
              ),
              const SizedBox(height: 10),
              DiagnosticOutcomesCard(items: kTcfDiagnosticGateOutcomes),
              const SizedBox(height: 12),
              Text(
                kDiagnosticDisclaimer,
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
