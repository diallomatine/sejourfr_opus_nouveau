import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../diagnostic_controller.dart';
import 'diagnostic_analysis_labels.dart';
import 'diagnostic_common.dart';
import 'diagnostic_wait.dart';

/// Envoi des productions faites avant l'inscription. L'écran nomme l'étape
/// en cours et compte le temps : c'est le seul moment du parcours où le
/// candidat pourrait croire qu'il perd son travail. L'oral n'y figure que si
/// ce passage en comportait un. Miroir de la carte `running` du web.
class DiagnosticSendingView extends StatelessWidget {
  const DiagnosticSendingView({
    super.key,
    required this.stage,
    required this.hasOral,
  });

  final DiagnosticSyncStage stage;
  final bool hasOral;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      children: [
        DiagnosticWaitCard(
          title: TextSpan(text: diagnosticSendingTitle(hasOral)),
          lead: diagnosticSendingText(hasOral),
          steps: diagnosticSendingSteps(hasOral, stage),
        ),
      ],
    );
  }
}

/// L'envoi a échoué : rien n'est perdu, on propose de réessayer.
class DiagnosticSyncFailedView extends StatelessWidget {
  const DiagnosticSyncFailedView({
    super.key,
    required this.hasOral,
    required this.onRetry,
    required this.isBusy,
    this.errorMessage,
  });

  final bool hasOral;
  final VoidCallback onRetry;
  final bool isBusy;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      children: [
        AppCard(
          borderRadius: AppRadii.xl,
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
          child: Column(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  color: AppColors.redLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.cloudOff,
                  size: 30,
                  color: AppColors.red,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                diagnosticSendFailedTitle(hasOral),
                textAlign: TextAlign.center,
                style: AppFonts.display(size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                diagnosticSendFailedText(hasOral),
                textAlign: TextAlign.center,
                style: AppFonts.ui(
                  size: 13.5,
                  color: AppColors.inkSoft,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),
              AppButton(
                label: kDiagnosticSendRetryCta,
                isLoading: isBusy,
                onPressed: isBusy ? null : onRetry,
              ),
            ],
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 14),
          DiagnosticErrorBanner(message: errorMessage!),
        ],
      ],
    );
  }
}

/// Le compte sur lequel le visiteur vient de se connecter a déjà passé son
/// diagnostic. On le dit franchement au lieu de boucler sur une erreur, et on
/// ne touche pas à sa production locale sans son accord.
class DiagnosticAlreadyDoneView extends StatelessWidget {
  const DiagnosticAlreadyDoneView({
    super.key,
    required this.message,
    required this.onContinue,
    required this.onDiscard,
  });

  final String message;
  final VoidCallback onContinue;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      children: [
        AppCard(
          borderRadius: AppRadii.xl,
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
          child: Column(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  color: AppColors.blueLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.fileCheck,
                  size: 30,
                  color: AppColors.blue,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Ce compte a déjà son diagnostic',
                textAlign: TextAlign.center,
                style: AppFonts.display(size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppFonts.ui(
                  size: 13.5,
                  color: AppColors.inkSoft,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),
              AppButton(
                label: 'Voir mon diagnostic',
                iconRight: LucideIcons.arrowRight,
                onPressed: onContinue,
              ),
              const SizedBox(height: 10),
              AppButton(
                label: 'Supprimer mes réponses locales',
                variant: AppButtonVariant.soft,
                height: 48,
                onPressed: onDiscard,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
