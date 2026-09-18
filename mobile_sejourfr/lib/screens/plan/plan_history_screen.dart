import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/models/journey_models.dart';
import '../../core/router/app_router.dart';
import '../../core/router/retour.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/sejour/sejour_kit.dart';
import 'journey_labels.dart';
import 'learning_plan_provider.dart';

/// **« Ma progression »** — l'archive du parcours, derrière « Voir ma
/// progression » au bas du Plan.
///
/// Maquette du propriétaire : `docs/progression/histo_cycle.html`.
///
/// 🛑 **Rien n'est calculé ici.** Les trois compteurs, les cycles, leur ordre,
/// les titres de compétence et les deux niveaux sont **servis**
/// (`GET /api/me/plan/journey/history`) ; les phrases viennent de
/// `journey_labels.dart`, et les dates de son seul formateur d'intervalle.
///
/// 🛑 **Ce n'est plus l'écran des quatre domaines.** Il disait « où j'en suis
/// sur les quatre domaines », que le Plan et l'Accueil disent déjà ; il dit
/// maintenant ce que le Plan ne peut pas dire : **ce qui a été travaillé
/// avant**. `/plan/evolution` a disparu dans la même passe, pour la même
/// raison — le Plan porte déjà « Progression détectée ».
///
/// 🛑 **Miroir de `PlanHistoryView` côté web**, brique pour brique.
class PlanHistoryScreen extends ConsumerStatefulWidget {
  const PlanHistoryScreen({super.key});

  @override
  ConsumerState<PlanHistoryScreen> createState() => _PlanHistoryScreenState();
}

class _PlanHistoryScreenState extends ConsumerState<PlanHistoryScreen> {
  /// Le cycle déplié. 🛑 **Un seul à la fois, le plus récent par défaut** — et
  /// c'est le `numero` **servi** qui l'identifie, jamais un index de liste :
  /// une liste rechargée pendant qu'on lit ne doit pas rouvrir un autre cycle.
  /// `-1` est le « tout replié » explicite, que `null` ne saurait pas dire.
  int? _ouvert;

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(journeyHistoryProvider);
    final history = historyAsync.valueOrNull;
    final premier = history == null || history.cycles.isEmpty
        ? null
        : history.cycles.first.numero;
    final deplie = _ouvert ?? premier;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          children: [
            SfTop(
              onBack: () => retourOuRepli(context, repli: AppRoutes.plan),
              title: kJourneyHistoryTitle,
            ),
            SfSection(
              flush: true,
              child: SfStack(
                pad: false,
                children: [
                  // 🛑 Le bandeau et ses compteurs restent dans TOUS les
                  // états : ils sont vrais même sans cycle terminé.
                  SfHeroBanner(
                    eyebrow: kJourneyHistoryEyebrow,
                    title: kJourneyHistoryHeadline,
                    text: kJourneyHistoryLead,
                    child: SfStatGrid(
                      onHero: true,
                      accentIndex: 1,
                      stats: [
                        (
                          value: '${history?.stats.competencesTravaillees ?? 0}',
                          label: journeyHistoryStatSkills(
                              history?.stats.competencesTravaillees ?? 0),
                        ),
                        (
                          value: '${history?.stats.examensPasses ?? 0}',
                          label: journeyHistoryStatExams(
                              history?.stats.examensPasses ?? 0),
                        ),
                        (
                          value: '${history?.stats.cyclesTermines ?? 0}',
                          label: journeyHistoryStatCycles(
                              history?.stats.cyclesTermines ?? 0),
                        ),
                      ],
                    ),
                  ),
                  ...historyAsync.when(
                    loading: () => const [
                      SfCard(child: SfTiny(kJourneyHistoryLoading)),
                    ],
                    // 🛑 **Un échec se DIT** : sans ce cas, une panne réseau se
                    // lirait « aucun cycle terminé », c'est-à-dire un mensonge
                    // sur l'archive du candidat.
                    error: (error, _) => [
                      SfCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SfTiny(ApiClient.toApiException(error).message),
                            const SizedBox(height: 10),
                            SfButton(
                              label: kJourneyHistoryRetry,
                              variant: SfButtonVariant.blue,
                              onPressed: () =>
                                  ref.invalidate(journeyHistoryProvider),
                            ),
                          ],
                        ),
                      ),
                    ],
                    data: (data) => data.cycles.isEmpty
                        ? const [
                            SfCard(
                              child: SfPanelHead(
                                title: kJourneyHistoryEmptyTitle,
                                sub: kJourneyHistoryEmptyText,
                              ),
                            ),
                          ]
                        : [
                            const SfPanelHead(
                              title: kJourneyHistorySectionTitle,
                              sub: kJourneyHistorySectionSub,
                            ),
                            for (final cycle in data.cycles)
                              _CycleTermine(
                                cycle: cycle,
                                open: deplie == cycle.numero,
                                onToggle: () => setState(() => _ouvert =
                                    deplie == cycle.numero ? -1 : cycle.numero),
                              ),
                          ],
                  ),
                  SfInfoNote(
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(
                          text: kJourneyHistoryFootLead,
                          style: AppFonts.ui(
                              size: 12,
                              color: AppColors.ink,
                              weight: FontWeight.w700,
                              height: 1.45),
                        ),
                        TextSpan(text: kJourneyHistoryFootText),
                      ]),
                      style: AppFonts.ui(
                          size: 12, color: AppColors.muted, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Un cycle archivé : ses épreuves travaillées, puis son encart de niveau.
///
/// 🛑 **`SfBlocAccordion` est réutilisé tel quel** : son `mark` est un texte, et
/// le numéro du cycle y entre sans qu'un second accordéon soit écrit.
///
/// 🛑 **Aucune action** : un cycle historisé ne se rejoue pas. Les lignes n'ont
/// donc pas d'`onTap`, et l'encart de niveau est `locked` — c'est-à-dire
/// inerte, mais entièrement lisible.
class _CycleTermine extends StatelessWidget {
  const _CycleTermine({
    required this.cycle,
    required this.open,
    required this.onToggle,
  });

  final JourneyHistoryCycle cycle;
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return SfBlocAccordion(
      mark: journeyHistoryCycleMark(cycle.numero),
      title: journeyHistoryCycleTitle(cycle.numero),
      meta: journeyHistoryCycleMeta(cycle),
      status: (label: kJourneyHistoryDonePill, tone: SfTone.ok),
      open: open,
      onToggle: onToggle,
      // 🛑 Une épreuve sans compétence travaillée garde sa ligne : elle a reçu
      // un examen, et l'omettre effacerait ce qui y a été mesuré.
      //
      // Le corps d'un cycle archivé prend la **même** variante que celui du
      // cycle en cours : c'est le même bloc, et deux corps différents sous le
      // même en-tête se liraient comme deux écrans. Les lignes y sont toutes
      // `done` — coche verte, aucune ligne d'action — et l'encart de niveau
      // ferme le rail avec sa pastille « ◎ ».
      child: SfJourneyList(
        variant: SfJourneyVariant.cycle,
        exam: SfExamStepBox(
          title: journeyHistoryLevelTitle(cycle),
          state: journeyHistoryLevelState(cycle),
          note: journeyHistoryLevelNote(cycle),
          locked: true,
        ),
        children: [
          for (final bloc in cycle.blocs)
            SfJourneyRow(
              state: SfJourneyState.done,
              title: journeyBlocTitle(bloc.examType),
              subtitle: journeyHistoryBlocSkills(bloc),
            ),
        ],
      ),
    );
  }
}
