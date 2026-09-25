import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/diagnostic_models.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_tag.dart';
import '../../../core/widgets/eyebrow.dart';
import '../../diagnostic_civique/civic_diagnostic_labels.dart';
import '../diagnostic_intro_labels.dart';
import 'diagnostic_common.dart';

/// Entrée du diagnostic pour un **visiteur** : il y choisit un EXAMEN, TCF IRN
/// ou examen civique. Miroir texte pour texte de `DiagnosticChoice.tsx` (web).
///
/// 🛑 **Les deux se passent SANS COMPTE** (`V053`) : le compte n'arrive qu'au
/// moment de VOIR le résultat — d'où le badge sur les deux cartes, jamais sur
/// une seule.
///
/// 🛑 **Aucun chiffre écrit ici** : durée et nombre de productions TCF dérivent
/// des sujets servis (le diagnostic rapide n'a pas d'oral : `oral == null`), les
/// questions civiques sont [kCivicExamQuestions].
class DiagnosticChoice extends StatelessWidget {
  const DiagnosticChoice({
    super.key,
    required this.written,
    required this.oral,
    required this.onStartTcf,
    this.errorMessage,
  });

  final DiagnosticExerciseView written;
  final DiagnosticExerciseView? oral;

  /// Lance le diagnostic **TCF** sur place. Le civique, lui, est une navigation.
  final VoidCallback onStartTcf;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final minutes = diagnosticExpressionMinutes(written, oral);
    final tcfPills = [
      if (minutes != null) '≈ $minutes min',
      oral != null ? '2 productions' : '1 production écrite',
      'Résultat personnalisé',
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        const Center(child: Eyebrow('DIAGNOSTIC GRATUIT')),
        const SizedBox(height: 10),
        Text(
          'Que préparez-vous ?',
          textAlign: TextAlign.center,
          style: AppFonts.display(size: 34, color: AppColors.ink),
        ),
        const SizedBox(height: 10),
        Text(
          'Choisissez votre examen. Vous commencez immédiatement, sans compte.',
          textAlign: TextAlign.center,
          style: AppFonts.ui(size: 15, color: AppColors.inkSoft, height: 1.5),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 16),
          DiagnosticErrorBanner(message: errorMessage!),
        ],
        const SizedBox(height: 22),
        _ChoiceCard(
          icon: LucideIcons.languages,
          title: 'TCF IRN',
          description: oral != null
              ? 'Évaluez rapidement votre niveau à partir d’une production '
                  'écrite et d’un court enregistrement oral.'
              : 'Évaluez rapidement votre niveau à partir d’une courte '
                  'production écrite.',
          pills: tcfPills,
          primary: true,
          action: AppButton(
            label: 'Commencer le diagnostic',
            iconRight: LucideIcons.arrowRight,
            onPressed: onStartTcf,
          ),
        ),
        const SizedBox(height: 14),
        _ChoiceCard(
          icon: LucideIcons.landmark,
          title: 'Examen civique',
          description: 'Testez vos connaissances avec un questionnaire au '
              'format de l’examen.',
          pills: const [
            '$kCivicExamQuestions questions',
            'Format de l’examen',
            'Résultat clair',
          ],
          action: AppButton(
            label: 'Commencer le diagnostic',
            variant: AppButtonVariant.outline,
            iconRight: LucideIcons.arrowRight,
            onPressed: () => context.push(AppRoutes.civicDiagnostic),
          ),
        ),
        const SizedBox(height: 20),
        // 🛑 Le compte sert à VOIR le résultat, pas seulement à le conserver.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(top: 6),
              decoration: const BoxDecoration(
                color: AppColors.green,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Le compte n’est demandé qu’à la fin, pour voir votre résultat '
                'et conserver votre plan.',
                style: AppFonts.ui(
                  size: 13,
                  color: AppColors.inkSoft,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const AppCard(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              _GainRow(
                title: 'Votre niveau',
                text: 'Une estimation simple à comprendre',
              ),
              _GainRow(
                title: 'Vos priorités',
                text: 'Ce qu’il faut travailler en premier',
              ),
              _GainRow(
                title: 'Votre plan',
                text: 'Un parcours adapté à votre résultat',
                last: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Estimation d’entraînement, non officielle.',
          textAlign: TextAlign.center,
          style: AppFonts.ui(size: 12, color: AppColors.inkFaint),
        ),
      ],
    );
  }
}

/// Une carte d'examen : liseré de marque sur le TCF, mis en avant.
class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.pills,
    required this.action,
    this.primary = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final List<String> pills;
  final Widget action;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      border: Border.all(
        color: primary
            ? AppColors.blue.withValues(alpha: 0.22)
            : AppColors.line,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (primary) Container(height: 4, color: AppColors.blue),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.blueLight,
                          borderRadius: BorderRadius.circular(AppRadii.md),
                        ),
                        child: Icon(icon, size: 23, color: AppColors.blue),
                      ),
                      const Spacer(),
                      const AppTag(label: 'Sans compte', tone: TagTone.ghost),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(title, style: AppFonts.display(size: 26)),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: AppFonts.ui(
                      size: 14.5,
                      color: AppColors.inkSoft,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [for (final pill in pills) _MetaPill(pill)],
                  ),
                  const SizedBox(height: 20),
                  action,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border.all(color: AppColors.line2),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Text(
        label,
        style: AppFonts.label(size: 12, color: AppColors.ink2),
      ),
    );
  }
}

/// Une ligne du bandeau « ce que vous obtenez ».
class _GainRow extends StatelessWidget {
  const _GainRow({required this.title, required this.text, this.last = false});

  final String title;
  final String text;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Text(title, style: AppFonts.ui(size: 13, weight: FontWeight.w700)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.right,
              style: AppFonts.ui(
                size: 12,
                color: AppColors.inkSoft,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
