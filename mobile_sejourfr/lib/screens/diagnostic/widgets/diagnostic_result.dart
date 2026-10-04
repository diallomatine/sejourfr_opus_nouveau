import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/diagnostic_models.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/cecrl_track.dart';
import '../../../core/widgets/sejour/sejour_kit.dart';
import '../diagnostic_rapport_labels.dart';

/// **Le rapport du diagnostic rapide TCF** (2026-10-04) — un seul composant,
/// rendu par `/diagnostic` après l'analyse et par le rapport clos
/// `/diagnostic/rapport/:sessionId`. Miroir web : `DiagnosticReport`.
///
/// Ordre de la maquette `docs/diagnostic/maquette-rapport-diagnostic-premium.html` :
/// carte de niveau (niveau, objectif, situation, piste, synthèse) → « Ce que
/// nous avons observé » (point fort, puis une carte par priorité du lot du
/// Plan) → encart d'honnêteté → « Découvrir mon plan » → « Revoir ma réponse ».
///
/// 🛑 **Rien n'est flouté, aucune offre** : un constat mesuré se montre en
/// clair, l'offre vit dans le Plan. 🛑 **Aucun tri ni recalcul** : priorités,
/// situation et objectif arrivent servis.
class DiagnosticResultView extends StatelessWidget {
  const DiagnosticResultView({
    super.key,
    required this.result,
    required this.sessionId,
  });

  final DiagnosticResult result;

  /// La session du rapport : elle adresse la transition et « Revoir ma
  /// réponse ». `null` ⇒ ces deux gestes mènent au Plan / disparaissent.
  final String? sessionId;

  @override
  Widget build(BuildContext context) {
    final observations = diagnosticObservations(result);
    final id = sessionId;
    return ListView(
      padding: const EdgeInsets.only(top: 14, bottom: 32),
      children: [
        Padding(padding: sfGutter, child: _LevelCard(result: result)),
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
            children: [
              const SfNoteCard(
                icon: LucideIcons.info,
                title: kDiagnosticInfoTitle,
                child: SfInsight(kDiagnosticInfoText),
              ),
              const SizedBox(height: 4),
              SfButton(
                label: kDiagnosticReportPlanCta,
                onPressed: () => id == null
                    ? context.go(AppRoutes.tcfPlan)
                    : context.push(AppRoutes.diagnosticRapportPlanPath(id)),
              ),
              if (id != null)
                SfTextLink(
                  label: kDiagnosticReportAnswerLink,
                  onTap: () =>
                      context.push(AppRoutes.diagnosticRapportReponsePath(id)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// La carte de niveau : ce que l'exercice a permis d'estimer, et rien de plus.
///
/// 🛑 **Production non évaluable** (P3, `evaluabilite` servi) : niveau « — » et
/// « Évaluation incomplète », ni situation, ni piste, ni phrase 1.
class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.result});

  final DiagnosticResult result;

  @override
  Widget build(BuildContext context) {
    final incomplet = diagnosticNonEvaluable(result);
    final niveau = incomplet ? null : result.written?.levelEstimate;
    final objectif = result.objectiveLevel;
    final situation = incomplet
        ? null
        : diagnosticSituationPhrase(result.situationObjectif, objectif);
    final track = incomplet ? null : cecrlTrack(niveau, objectif?.asNiveau);
    final phrase1 = incomplet
        ? null
        : diagnosticSynthesePhrase1(result.written?.communicationStatus);
    final phrase2 = diagnosticSynthesePhrase2(result);
    final synthese = [
      if (phrase1 != null) phrase1,
      if (phrase2 != null) phrase2,
    ];

    return SfCard(
      variant: SfCardVariant.hero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SfLabel(kDiagnosticLevelEyebrow),
          const SizedBox(height: 8),
          SfLevelGoal(
            level: niveau?.shortName ?? kDiagnosticLevelUnknown,
            goalLabel: kDiagnosticGoalLabel,
            goal: objectif?.wire,
          ),
          if (incomplet) ...[
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: SfBadge(kDiagnosticIncompleteTag, tone: SfTone.muted),
            ),
          ],
          if (situation != null) ...[
            const SizedBox(height: 18),
            SfCard(
              variant: SfCardVariant.soft,
              padding: const EdgeInsets.all(14),
              child: SfEmphasis(situation),
            ),
          ],
          if (track != null) ...[
            SfLevelTrack(
              levels: diagnosticTrackLevels(track),
              currentIndex: track.currentIndex,
              goalIndex: track.goalIndex,
              youLabel: '',
              goalLabel: kDiagnosticTrackGoal,
            ),
            const SizedBox(height: 6),
            const Center(child: SfTiny(kDiagnosticTrackLegend)),
          ],
          if (synthese.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.line2),
            const SizedBox(height: 16),
            SfInsight(synthese.join(' ')),
          ],
        ],
      ),
    );
  }
}
