import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/models/enums.dart';
import '../../core/router/app_router.dart';
import '../../core/router/retour.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/parcours_affiche.dart';
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
///
/// ## Le parcours affiché vient de [parcoursCiviqueProvider] (P8.9, 2026-09-20)
///
/// 🛑 **Un seul écran pour les deux parcours**, scopé par l'état **partagé** du
/// parcours affiché — le pendant Dart du `?module=` du web, et déjà l'autorité
/// de l'Accueil, du Plan et de Réviser. Une seconde route aurait été une
/// deuxième façon de dire la même chose.
///
/// ⚠️ **L'écran est POUSSÉ depuis le Plan**, qui a déjà fait le choix : la
/// bascule n'existe pas ici, et l'état ne peut donc pas changer sous les pieds
/// du candidat pendant qu'il lit.
///
/// Ce qui change avec le parcours, et **rien d'autre** : le **mot** de l'unité
/// travaillée (compétence ⇄ unité officielle) et la **mesure** de fin de cycle
/// (palier CECRL ⇄ score sur 40 rapporté au seuil de 32).
///
/// ## Un cycle terminé OUVRE SON ÉCRAN (2026-09-27)
///
/// 🛑 **La ligne d'un cycle est un lien** ([SfBlocAccordion.lien]) vers
/// [PlanCycleArchiveScreen] — son plan tel qu'il était, comme l'écran Plan, en
/// lecture seule. ⚠️ **Révoque** l'accordéon déplié ici, dont le seul contenu
/// était une carte « Examens réalisés · NIVEAU A2 » **cadenassée** : un cadenas
/// sur un cycle terminé ne voulait rien dire. Un écran plutôt qu'un accordéon :
/// à 360 px, un rail d'étapes et ses blocs dépliables imbriqués dans une carte
/// de liste perdaient la largeur qui rend le Plan lisible.
///
/// ⚠️ **Pas de menu burger ici** (le web l'ajoute à la flèche, `Top keepMenu`) :
/// l'app n'a pas de menu latéral, sa navigation principale est la barre
/// d'onglets. Écart de forme, pas de parcours.
class PlanHistoryScreen extends ConsumerWidget {
  const PlanHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    /// 🛑 **Le défaut est TCF**, pas une déduction : l'écran est atteint depuis
    /// le Plan, qui a déjà posé le parcours affiché.
    final module = (ref.watch(parcoursCiviqueProvider) ?? false)
        ? AppModule.civique
        : AppModule.tcf;
    final historyAsync = ref.watch(journeyHistoryProvider(module));
    final history = historyAsync.valueOrNull;

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
                              history?.stats.competencesTravaillees ?? 0,
                              module),
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
                                  ref.invalidate(journeyHistoryProvider(module)),
                            ),
                          ],
                        ),
                      ),
                    ],
                    data: (data) => data.cycles.isEmpty
                        ? [
                            SfCard(
                              child: SfPanelHead(
                                title: kJourneyHistoryEmptyTitle,
                                sub: journeyHistoryEmptyText(module),
                              ),
                            ),
                          ]
                        : [
                            const SfPanelHead(
                              title: kJourneyHistorySectionTitle,
                              sub: kJourneyHistorySectionSub,
                            ),
                            for (final cycle in data.cycles)
                              SfBlocAccordion.lien(
                                mark: journeyHistoryCycleMark(cycle.numero),
                                title: journeyHistoryCycleTitle(cycle.numero),
                                meta: journeyHistoryCycleMeta(cycle, module),
                                status: (
                                  label: kJourneyHistoryDonePill,
                                  tone: SfTone.ok,
                                ),
                                onOpen: () => context.push(
                                  AppRoutes.planCycleArchivePath(
                                      cycle.journeyId),
                                ),
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
                        TextSpan(text: journeyHistoryFootText(module)),
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
