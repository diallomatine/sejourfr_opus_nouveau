import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/models/enums.dart';
import '../../core/models/journey_models.dart';
import '../../core/router/app_router.dart';
import '../../core/router/retour.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format_date.dart';
import '../../core/utils/parcours_affiche.dart';
import '../../core/widgets/sejour/sejour_kit.dart';
import 'journey_labels.dart';
import 'learning_plan_provider.dart';

/// **Un cycle terminé, consulté tel qu'il était** — l'écran ouvert depuis
/// « Mes cycles » (`/plan/progression/cycle/:journeyId`, 2026-09-27).
///
/// 🛑 **Le MÊME écran que le cycle du Plan, en lecture seule.** Mêmes briques
/// du kit — [SfCycleProgress], [SfCycleRail] / [SfCycleRailStep] /
/// [SfCycleRailEnd], [SfBlocAccordion], [SfJourneyList] / [SfJourneyRow],
/// [SfExamStepAction] —, les mêmes libellés (`journey_labels.dart`) sur les
/// mêmes modèles ([JourneyCycleArchive] porte le `cycle` et les `blocs` du
/// Plan). Ce qui fait la consultation est SERVI : aucune étape verrouillée,
/// aucune action, une étape restée ouverte [JourneyStepStatus.nonFaite], un
/// bloc incomplet [JourneyBlocStatus.inacheve]. L'écran ne pose donc **aucun**
/// geste — ni « Commencer », ni « Débloquer », ni « Faire cette étape » — et
/// aucun cadenas.
///
/// 🛑 **La fin du cycle est FRANCHIE** ([SfCycleRailEnd.done]) : son titre est
/// le geste qui l'a clos, servi (`finDeCycle`, V077) ; inconnu ⇒ « Cycle
/// terminé ».
///
/// 🛑 **Miroir de `PlanCycleArchiveView` côté web**, brique pour brique.
class PlanCycleArchiveScreen extends ConsumerStatefulWidget {
  const PlanCycleArchiveScreen({super.key, required this.journeyId});

  final String journeyId;

  @override
  ConsumerState<PlanCycleArchiveScreen> createState() =>
      _PlanCycleArchiveScreenState();
}

class _PlanCycleArchiveScreenState
    extends ConsumerState<PlanCycleArchiveScreen> {
  /// `false` = le candidat n'a rien choisi : le premier bloc est déplié. Une
  /// fois qu'il a touché un en-tête, c'est **son** choix qui vaut.
  bool _aChoisi = false;
  String? _choix;

  @override
  Widget build(BuildContext context) {
    /// Le parcours ne sert qu'au MOT de la mesure : le cycle porte le sien côté
    /// serveur. Même autorité que « Mes cycles », qui a poussé cet écran.
    final module = (ref.watch(parcoursCiviqueProvider) ?? false)
        ? AppModule.civique
        : AppModule.tcf;
    final async = ref.watch(journeyCycleArchiveProvider(widget.journeyId));
    final archive = async.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          children: [
            SfTop(
              onBack: () =>
                  retourOuRepli(context, repli: AppRoutes.planProgress),
              kicker: kJourneyArchiveKicker,
              title: archive == null
                  ? kJourneyArchiveKicker
                  : journeyHistoryCycleTitle(archive.numero),
              lead: archive == null
                  ? null
                  : formatDateRange(archive.debut, archive.fin),
            ),
            ...async.when(
              loading: () => const [
                SfSection(
                  flush: true,
                  child: SfStack(
                    pad: false,
                    children: [SfCard(child: SfTiny(kJourneyHistoryLoading))],
                  ),
                ),
              ],
              // 🛑 **Un échec se DIT** — y compris le 404 d'un cycle qui n'est
              // pas le sien : jamais un écran vide.
              error: (error, _) => [
                SfSection(
                  flush: true,
                  child: SfStack(
                    pad: false,
                    children: [
                      SfCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SfTiny(ApiClient.toApiException(error).message),
                            const SizedBox(height: 10),
                            SfButton(
                              label: kJourneyHistoryRetry,
                              variant: SfButtonVariant.blue,
                              onPressed: () => ref.invalidate(
                                  journeyCycleArchiveProvider(
                                      widget.journeyId)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              data: (data) => [_corps(data, module)],
            ),
          ],
        ),
      ),
    );
  }

  Widget _corps(JourneyCycleArchive archive, AppModule module) {
    final cycle = archive.cycle;
    final premier = archive.blocs.isEmpty ? null : archive.blocs.first.bloc.code;
    final ouvert = _aChoisi ? _choix : premier;
    return SfSection(
      title: journeyTitle(archive.objectif),
      child: SfStack(
        children: [
          SfCycleProgress(
            label: journeyCycleLabel(cycle),
            done: cycle.etapesTerminees,
            total: cycle.etapesTotal,
            hint: journeyArchiveHint(archive, module),
            // 🛑 Servi, jamais déduit de `done == total`.
            complete: cycle.complete,
          ),
          SfCycleRail(
            children: [
              for (final bloc in archive.blocs)
                SfCycleRailStep(
                  state: journeyBlocRailState(bloc.status),
                  child: SfBlocAccordion(
                    mark: journeyBlocMark(bloc.bloc),
                    title: journeyBlocTitle(bloc.bloc),
                    meta: bloc.meta,
                    status: journeyBlocStatus(bloc.status),
                    open: ouvert == bloc.bloc.code,
                    onToggle: () => setState(() {
                      _aChoisi = true;
                      _choix = ouvert == bloc.bloc.code ? null : bloc.bloc.code;
                    }),
                    child: _bloc(bloc),
                  ),
                ),
              SfCycleRailEnd(
                eyebrow: kJourneyRailEndEyebrow,
                title: journeyArchiveEndTitle(archive.finDeCycle),
                note: journeyArchiveEndNote(archive.fin),
                reached: false,
                done: true,
              ),
            ],
          ),
          SfInfoNote(
            child: Text(
              kJourneyArchiveNote,
              style: AppFonts.ui(size: 12, color: AppColors.muted, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  /// Le corps d'un bloc clos : ses étapes, puis son examen. 🛑 **Aucun geste**
  /// — ni `onTap`, ni `actionLabel`, ni `locked` : les états sont lus, jamais
  /// actionnés.
  Widget _bloc(JourneyBloc bloc) {
    final exam = bloc.exam;
    final resultat = exam == null ? null : journeyArchiveExamResult(exam);
    return SfJourneyList(
      variant: SfJourneyVariant.cycle,
      exam: exam == null
          ? null
          : SfExamStepAction(
              title: kJourneyExamTitle,
              subtitle: journeyArchiveExamSubtitle(exam),
              trailing:
                  resultat == null ? null : SfExamStepDone(label: resultat),
            ),
      children: [
        for (final step in bloc.steps)
          SfJourneyRow(
            title: journeyCycleStepTitle(step),
            subtitle: journeyCycleStepSubtitle(step),
            state: journeyKitState(step),
            kind: journeyKind(step),
            badge: journeyBadge(step),
          ),
      ],
    );
  }
}
