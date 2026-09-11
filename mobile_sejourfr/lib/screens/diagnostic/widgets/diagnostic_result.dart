import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/diagnostic_models.dart';
import '../../../core/models/enums.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/cecrl_track.dart';
import '../../../core/widgets/app_tag.dart';
import '../../../core/widgets/sejour/sejour_kit.dart';
import 'diagnostic_report_labels.dart';

/// **Résultat du diagnostic rapide TCF.**
///
/// Une seule production écrite a été observée : l'écran annonce l'estimation
/// qu'elle permet, dit ce qu'elle vaut, et ouvre sur le diagnostic complet.
///
/// Ordre figé par la maquette :
/// 1. la carte hero — niveau estimé, objectif, rail, paragraphe d'analyse ;
/// 2. « Ce que nous avons observé » — les positives, puis les à améliorer ;
/// 3. « Ce n'est qu'une première estimation » — la mise au point ;
/// 4. « Découvrez où vous en êtes vraiment au TCF » — les 4 épreuves et le CTA.
///
/// 🛑 **Aucun verrou, aucun paywall ici.** Le rapport rapide mène au diagnostic
/// complet ; c'est le rapport du complet qui met l'abonnement en avant, quand
/// le candidat a ses quatre niveaux sous les yeux.
///
/// 🛑 **Un niveau non estimé est NOMMÉ, jamais rabattu sur A1.** Une production
/// inexploitable rend `levelEstimate == null` : la carte hero affiche l'état,
/// pas un palier de repli.
class DiagnosticResultView extends StatelessWidget {
  const DiagnosticResultView({
    super.key,
    required this.result,
    this.objective,
  });

  final DiagnosticResult result;

  /// Le palier visé, servi par la démarche déclarée du compte. `null` = pas
  /// encore choisi : la ligne d'objectif n'est pas rendue et le rail s'arrête
  /// au palier estimé. On n'invente aucun « B2 ».
  final TargetLevel? objective;

  @override
  Widget build(BuildContext context) {
    final written = result.written;
    final niveau = written?.levelEstimate;
    final observations = diagnosticObservations(result);

    return ListView(
      padding: const EdgeInsets.only(top: 14, bottom: 32),
      children: [
        Padding(
          padding: sfGutter,
          child: _HeroCard(
            niveau: niveau,
            objective: objective,
            summary: written?.summary,
          ),
        ),
        if (observations.isNotEmpty)
          SfSection(
            title: kDiagnosticObserveTitle,
            child: SfStack(
              children: [
                for (final o in observations)
                  SfObservation(
                    positive: o.positive,
                    kicker: o.kicker,
                    title: o.titre,
                    text: o.texte,
                  ),
              ],
            ),
          ),
        SfSection(
          child: SfStack(
            children: const [_TransitionNote()],
          ),
        ),
        SfSection(
          title: kDiagnosticCompletTitle,
          child: SfStack(
            children: [
              for (final e in kDiagnosticCompletEpreuves)
                SfExamRow(icon: e.icon, title: e.label),
              const _PromiseCard(),
              SfButton(
                label: kDiagnosticCompletCta,
                caption: kDiagnosticCompletNote,
                onPressed: () => context.push(AppRoutes.tcfDiagnostic),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// La carte de tête : ce que l'exercice a permis d'estimer, et rien de plus.
class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.niveau,
    required this.objective,
    required this.summary,
  });

  final NiveauCecrl? niveau;
  final TargetLevel? objective;
  final String? summary;

  @override
  Widget build(BuildContext context) {
    final track = cecrlTrack(niveau, objective?.asNiveau);
    // 🛑 Sans niveau estimé, la phrase d'analyse du serveur ne porte sur rien :
    // c'est l'état « rien d'observable » qui s'affiche, sans reproche.
    final insight = niveau == null ? kDiagnosticIncompleteText : summary;

    return SfCard(
      variant: SfCardVariant.hero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SfLabel(kDiagnosticLevelEyebrow),
          const SizedBox(height: 8),
          if (niveau != null)
            SfLevel(niveau!.shortName)
          else
            const AppTag(
              label: kDiagnosticIncompleteTag,
              tone: TagTone.neutral,
            ),
          if (objective != null) ...[
            const SizedBox(height: 12),
            SfGoalLine(
              prefix: kDiagnosticGoalPrefix,
              goal: objective!.wire,
            ),
          ],
          if (track != null)
            SfLevelTrack(
              levels: track.levels,
              currentIndex: track.currentIndex,
              goalIndex: track.goalIndex,
            ),
          if (insight != null) ...[
            const SizedBox(height: 16),
            SfInsight(insight),
          ],
        ],
      ),
    );
  }
}

/// La mise au point : ce que l'estimation ne dit pas encore.
class _TransitionNote extends StatelessWidget {
  const _TransitionNote();

  @override
  Widget build(BuildContext context) {
    return SfNoteCard(
      icon: LucideIcons.info,
      title: kDiagnosticTransitionTitle,
      titleSize: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SfInsight(kDiagnosticTransitionText),
          const SizedBox(height: 10),
          Text(
            kDiagnosticTransitionEmphasis,
            style: AppFonts.ui(
              size: 14,
              weight: FontWeight.w700,
              color: AppColors.blueDark,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ce que le diagnostic complet apporte, en trois coches.
class _PromiseCard extends StatelessWidget {
  const _PromiseCard();

  @override
  Widget build(BuildContext context) {
    return SfCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SfLabel(kDiagnosticCompletPromise),
          const SizedBox(height: 6),
          for (final b in kDiagnosticCompletBenefits) SfCheckRow(label: b),
        ],
      ),
    );
  }
}
