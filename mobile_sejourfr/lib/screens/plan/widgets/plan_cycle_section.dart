import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_events.dart';
import '../../../core/api/repositories.dart';
import '../../../core/models/attempt_models.dart';
import '../../../core/models/diagnostic_models.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/journey_models.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/selected_module.dart';
import '../../../core/utils/start_failure.dart';
import '../../../core/widgets/paywall_sheet.dart';
import '../../../core/widgets/sejour/sejour_kit.dart';
import '../../module_detail/tcf_full_exams_screen.dart'
    show fullExamsHistoryProvider;
import '../journey_labels.dart';
import '../learning_plan_provider.dart';
import '../plan_actions.dart';
import '../plan_cta.dart';
import '../plan_labels.dart';
import '../plan_now_card.dart';

/// **Le cycle du Plan** — tout ce que l'écran affiche à partir du titre
/// « Votre parcours vers le B2 » (D-22, 2026-09-18).
///
/// 🛑 **Section COMMUNE aux deux modules depuis P8.7** (D-50, décision technique
/// validée) : le cycle civique a le même moteur et les mêmes primitives, il
/// n'avait aucune raison d'avoir un second écran. Ce qui change avec [module]
/// tient en deux points, et deux seulement : **l'action d'une étape** (une série
/// sur l'unité officielle servie, au lieu de l'exercice du Plan TCF) et **la
/// sortie de fin de cycle** (l'examen civique complet, au lieu de l'examen TCF
/// complet).
///
/// Maquettes du propriétaire : `docs/progression/plan_cycle.html` et
/// `docs/progression/cycle_termine.html`. Ordre, définitif :
///
/// 1. l'**encart de cycle** ([SfCycleProgress]) — la barre continue et son
///    compteur ;
/// 2. les **blocs d'épreuve** ([SfBlocAccordion]), un par entrée de `blocs`,
///    **dans l'ordre servi**, le premier seul déplié ;
/// 3. dans chaque bloc : les **lignes d'étape** ([SfJourneyRow]) puis l'**encart
///    d'examen** ([SfExamStepBox]) ;
/// 4. la **note** de liberté d'ordre ([SfInfoNote]) ;
/// 5. sur un cycle terminé : « Prochaine étape » et la **carte à deux actions**
///    ([SfNextStepCard]).
///
/// 🛑 **Rien n'est décidé ici.** L'ordre des blocs, leur état, le nombre de
/// compétences restantes, le verrou de chaque étape et « le cycle est-il
/// terminé ? » sont **servis**. L'écran ne tient qu'une chose : **quel bloc est
/// déplié**, ce qui est une préférence d'affichage et rien d'autre.
///
/// 🛑 **Ce qui a disparu avec cette passe** : la file plate `_journeySection` et
/// son « + N étapes » (`hiddenUpcomingCount`). Les blocs portent *toutes* les
/// étapes non obsolètes — il n'y a plus rien à replier.
///
/// 🛑 **`lot`, `step`, `journey` ne s'affichent jamais** (D-21) : chaque bloc est
/// nommé par son **épreuve**, en clair, et chaque ligne dit la sienne.
///
/// 🛑 **Une étape VERROUILLÉE porte un geste, pas un cadenas muet** (demande du
/// propriétaire, 2026-09-20) : là où un abonné lit « Faire cette étape », un
/// compte gratuit lit « Débloquer mon plan » et le tap ouvre l'offre. Le cadenas
/// reste à sa place — il code l'état —, c'est le **silence** qui disparaît. Le
/// bouton rouge « Débloquer mon plan » reste le seul CTA critique de l'écran,
/// dans la barre basse (A46) : ce geste-ci est le **lien bleu** de la ligne.
class PlanCycleSection extends ConsumerStatefulWidget {
  const PlanCycleSection({
    super.key,
    required this.plan,
    required this.journey,
    this.module = AppModule.tcf,
  });

  /// Le Plan TCF, **seulement** pour résoudre l'action d'une étape TCF.
  /// 🛑 `null` côté civique : l'action y est la série sur l'**unité** servie, et
  /// demander au Plan TCF de la résoudre aurait rendu `null` — donc une ligne
  /// sans geste.
  final LearningPlan? plan;

  /// 🛑 **Le module du cycle affiché** (D-50) : c'est lui qui dit quelle série
  /// une étape ouvre, et où repartir après une fin de cycle.
  final AppModule module;

  /// 🛑 `null` est un cas NORMAL — pas encore lu, ou backend antérieur à
  /// l'endpoint : la section disparaît, elle n'affiche jamais un squelette.
  final Journey? journey;

  @override
  ConsumerState<PlanCycleSection> createState() => _PlanCycleSectionState();
}

class _PlanCycleSectionState extends ConsumerState<PlanCycleSection> {
  /// `false` = le candidat n'a rien choisi, on suit le premier bloc. Une fois
  /// qu'il a touché un en-tête, c'est **son** choix qui vaut — y compris « tout
  /// replié » ([_choix] à `null`).
  bool _aChoisi = false;
  /// Le CODE du bloc ouvert, jamais un `EpreuveType` : le bloc est servi
  /// et sa clé vaut pour une épreuve TCF comme pour une thématique (D-47).
  String? _choix;

  /// Une action de fin de cycle est en vol : les deux historisent le cycle, on
  /// ne les rejoue pas par un second appui.
  bool _occupe = false;
  String? _erreur;

  @override
  Widget build(BuildContext context) {
    final parcours = widget.journey;
    if (parcours == null) return const SizedBox.shrink();

    // 🛑 **Aucun objectif déclaré ⇒ aucun parcours en base** (arbitrage D-3).
    // Ce n'est pas un cycle vide : c'est l'absence de cycle, et le distinguer
    // évite de féliciter un candidat qui n'a rien commencé.
    if (parcours.state == JourneyState.needsObjective) {
      return SfSection(
        title: kJourneyNeedsObjectiveTitle,
        child: SfStack(
          children: [
            const SfCard(child: Text(kJourneyNeedsObjectiveText)),
            SfButton(
              label: kJourneyNeedsObjectiveCta,
              onPressed: () => context.push(AppRoutes.targetPathFrom(AppRoutes.plan)),
            ),
          ],
        ),
      );
    }

    // Plus rien d'ouvert, et plus rien à proposer. 🛑 La **suggestion** est hors
    // cycle : elle n'a pas de position, elle ne se clôt pas, et l'ignorer ne
    // laisse rien « en attente ».
    if (parcours.state == JourneyState.upToDate) {
      return SfSection(
        title: kJourneyUpToDateTitle,
        child: SfStack(
          children: [
            SfCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kJourneyUpToDateText,
                    style: AppFonts.ui(size: 14, color: AppColors.inkSoft),
                  ),
                  if (parcours.suggestion == JourneySuggestionType.mockExam) ...[
                    const SizedBox(height: 8),
                    Text(
                      kJourneySuggestionMockExam,
                      style: AppFonts.ui(size: 12, color: AppColors.muted),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    final cycle = parcours.cycle;
    if (cycle == null || parcours.blocs.isEmpty) return const SizedBox.shrink();

    final termine = parcours.state == JourneyState.cycleCompleted;

    // 🛑 **Le PREMIER bloc servi est le seul déplié** (demande du propriétaire,
    // 2026-09-20). Il suivait auparavant `status == enCours`, ce qui était juste
    // tant que l'ordre était figé — mais depuis que les blocs porteurs de
    // travail passent devant (D-56), le bloc courant peut être en 2ᵈ position :
    // le candidat arrivait alors sur un cycle dont la tête était repliée et le
    // milieu ouvert. L'ordre servi dit déjà ce qui compte d'abord ; le dépli le
    // suit, il ne le contredit pas.
    //
    // ⚠️ **Sauf sur un cycle TERMINÉ** : les quatre blocs restent repliés, comme
    // dans `cycle_termine.html` — la maquette de référence de D-22. Il n'y a
    // alors plus rien à faire dedans, et c'est la carte de fin de cycle qui
    // porte le geste.
    final premier = parcours.blocs.first;
    final ouvert = _aChoisi ? _choix : (termine ? null : premier.bloc.code);
    final nextStep = parcours.nextStep;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SfSection(
          title: journeyTitle(parcours.objectif),
          child: SfStack(
            children: [
              SfCycleProgress(
                label: journeyCycleLabel(cycle),
                done: cycle.etapesTerminees,
                total: cycle.etapesTotal,
                badge: journeyCycleBadge(cycle),
                hint: journeyCycleHint(cycle),
                // 🛑 **Servi, jamais déduit de `done == total`** : un cycle peut
                // afficher « 8 sur 8 » sans être clos côté serveur.
                complete: cycle.complete,
              ),

              // 🛑 **L'ordre servi est l'autorité** : aucun tri, aucun filtre —
              // les quatre épreuves sont là, même celles que la file n'a pas
              // encore peuplées.
              for (final bloc in parcours.blocs)
                SfBlocAccordion(
                  mark: journeyBlocMark(bloc.bloc),
                  title: journeyBlocTitle(bloc.bloc),
                  meta: bloc.meta,
                  status: journeyBlocStatus(bloc.status),
                  current: bloc.status == JourneyBlocStatus.enCours,
                  open: ouvert == bloc.bloc.code,
                  onToggle: () => setState(() {
                    _aChoisi = true;
                    _choix = ouvert == bloc.bloc.code ? null : bloc.bloc.code;
                  }),
                  child: _corpsDuBloc(bloc),
                ),

              SfInfoNote(
                child: Text(
                  kJourneyCycleNote,
                  style: AppFonts.ui(
                      size: 12, color: AppColors.muted, height: 1.45),
                ),
              ),

              // 🛑 Des étapes restent, mais **aucune n'est exécutable** : on le
              // dit, au lieu de laisser un cycle sans étape courante qui se
              // lirait comme une panne.
              if (parcours.state == JourneyState.locked)
                SfTiny(journeyLockedCaption(widget.module)),
            ],
          ),
        ),
        if (termine && nextStep != null)
          // 🛑 **`examenCompletPossible` est SERVI** : il dit déjà « ce cycle est
          // un cycle de mesure », et le redéduire de `cycle.cycleDeMesure`
          // ferait deux autorités pour un fait.
          _finDeCycle(nextStep.examenCompletPossible),
      ],
    );
  }

  /// Le corps d'un bloc : ses **lignes d'étape** puis son **encart d'examen**.
  ///
  /// 🛑 L'examen est servi **à part** (`bloc.exam`) et rendu en fin de bloc :
  /// c'est un checkpoint, pas une étape de plus dans la liste.
  ///
  /// 🛑 **Toutes les etapes du bloc, y compris celles deja closes** : le
  /// serveur sert les `COMPLETED` (seules les OBSOLETE sont exclues), et c'est
  /// ce qui donne a la file son « avant / maintenant / apres ». Aucun filtre.
  Widget _corpsDuBloc(JourneyBloc bloc) {
    final exam = bloc.exam;
    return SfJourneyList(
      variant: SfJourneyVariant.cycle,
      // 🛑 L'examen est la DERNIERE etape de la file, sur le rail et avec sa
      // pastille « ◎ » : c'est la maquette. Il reste servi a part
      // (`bloc.exam`), l'ecran ne fait que le ranger.
      exam: exam == null
          ? null
          : SfExamStepBox(
              title: journeyExamTitle(exam),
              state: journeyExamState(exam),
              note: journeyExamNote(bloc, exam),
              locked: exam.locked,
              onTap: _actionDe(exam),
            ),
      children: [for (final step in bloc.steps) _ligne(step)],
    );
  }

  /// Une ligne d'étape.
  ///
  /// 🛑 **Le libellé suit le geste**, et les deux viennent du même endroit :
  /// « Faire cette étape → » quand l'étape est ouverte, « Débloquer mon plan → »
  /// quand elle ne l'est pas. Le kit ne compose ni l'un ni l'autre.
  Widget _ligne(JourneyStep step) {
    final geste = _gesteDe(step);
    return SfJourneyRow(
      // 🛑 **La composition du CYCLE** : « Tâche 3 » en titre, l'intitulé
      // dessous, et **pas d'épreuve** — l'en-tête du bloc la nomme déjà. Les
      // autres lectures de `journeyStep*` la gardent (cf. `journey_labels.dart`).
      title: journeyCycleStepTitle(step, _niveauDe(step)),
      subtitle: journeyCycleStepSubtitle(step),
      state: journeyKitState(step),
      kind: journeyKind(step),
      badge: journeyBadge(step),
      locked: step.locked,
      actionLabel: geste?.label,
      onTap: geste?.onTap,
    );
  }

  /// **Le geste d'une ligne d'étape** : son action, ou l'offre quand elle est
  /// verrouillée.
  ///
  /// 🛑 **Le verrou est LU, jamais déduit** (`JourneyStep.locked`, D-18) : ni un
  /// rang, ni un statut d'abonnement lu côté client, ni une position.
  ///
  /// 🛑 **Sur une étape d'entraînement, `locked` est TOUJOURS commercial** —
  /// `JourneyReadService` §5 bis le pose depuis `SkillAccessService`, et
  /// `JourneyBloc.steps` ne porte que des étapes d'entraînement (l'examen est
  /// servi à part, dans `bloc.exam`). Le seul verrou **pédagogique** du cycle
  /// est celui d'un examen de bloc, et il garde son encart muet : sa phrase
  /// servie dit déjà ce qui l'ouvrira, et ce n'est pas un pass.
  /// La porte unique vers l'offre, depuis le cycle — quel que soit le module.
  void _versEcranDeDeblocage(BuildContext context) => context.push(
        AppRoutes.planUnlockPath(civique: widget.module == AppModule.civique),
      );

  /// 🛑 **Le palier vient du PLAN**, un fait servi sur la compétence
  /// (`PlanDomainSkill.targetLevel`) — [JourneyStep] n'en porte aucun, et le
  /// dériver ici en ferait une seconde autorité. `null` en civique (pas de plan
  /// TCF, pas de CECRL) et sur une tâche d'expression, qui porte son rang et
  /// non un palier.
  String? _niveauDe(JourneyStep etape) {
    final plan = widget.plan;
    if (plan == null || etape.taskCode != null) return null;
    return planSkillTargetLevelDeCode(plan, etape.skillCode)?.wire;
  }

  ({String label, VoidCallback onTap})? _gesteDe(JourneyStep etape) {
    if (etape.locked) {
      // 🛑 **Le geste passe par l'ÉCRAN DE TRANSITION**, jamais directement par
      // l'offre (demande du propriétaire, 2026-09-20). Le CTA ancré sous le
      // cycle y menait déjà ; une ligne d'étape qui ouvrait le paywall d'un
      // coup sautait l'écran qui **dit au candidat ce qu'il achète** — ses
      // priorités, son écart à l'objectif, le prix d'entrée. Deux chemins vers
      // le même achat, dont un plus pauvre.
      return (
        label: kJourneyStepUnlockLink,
        onTap: () => _versEcranDeDeblocage(context),
      );
    }
    final action = _actionDe(etape);
    if (action != null) {
      return (label: kJourneyStepActionLink, onTap: action);
    }
    // 🛑 **L'action existe mais elle est fermée** : la ligne **nomme son geste
    // d'achat**, elle ne dit plus « Faire cette étape → » sur une étape qu'on ne
    // peut pas faire. La destination ne change pas — c'était déjà l'écran de
    // transition, par l'`onVerrou` du lanceur —, c'est le **libellé** qui
    // divergeait du web.
    return _actionVerrouillee(etape)
        ? (
            label: kJourneyStepUnlockLink,
            onTap: () => _versEcranDeDeblocage(context),
          )
        : null;
  }

  /// **L'action de cette ligne est-elle SERVIE mais verrouillée ?**
  ///
  /// 🛑 **Le verrou de l'ACTION n'est pas celui de l'ÉTAPE** (A146) :
  /// [planStepActionLocked] est l'autorité, partagée avec le web.
  ///
  /// ⚠️ **Rien à lancer ⇒ `false`** : une ligne sans action ne se voit pas poser
  /// un geste d'achat qui ne la débloquerait pas (garde-fou A25).
  bool _actionVerrouillee(JourneyStep etape) {
    if (etape.locked || journeyEtapeASeries(etape)) return false;
    if (widget.module == AppModule.civique) return false;
    final plan = widget.plan;
    if (plan == null) return false;
    final action = planStepAction(plan, etape);
    return action != null && planStepActionLocked(action);
  }


  /// 🛑 **L'action d'une ligne passe par le MÊME chemin que la carte « À faire
  /// maintenant »** : [planStepAction] résout avec les deux autorités de
  /// [planNowCard], et les lanceurs sont ceux du Plan. Rien ne se résout ⇒
  /// **aucun geste** : la ligne nomme l'étape, sans bouton (garde-fou du
  /// 2026-09-17).
  ///
  /// 🛑 **Une étape verrouillée ne lance rien depuis le Plan** : le Plan d'un
  /// compte sans accès est un constat, le déblocage passe par la barre basse
  /// « Débloquer mon plan », ancrée sous le cycle.
  VoidCallback? _actionDe(JourneyStep etape) {
    if (etape.locked) return null;
    // 🛑 **UNE ÉTAPE DE SÉRIES OUVRE SON ÉCRAN, ELLE NE LANCE PLUS RIEN**
    // (demande du propriétaire, 2026-09-20). Compréhension CO/CE et civique :
    // le candidat voit d'abord ce que l'étape demande — la compétence ou
    // l'unité travaillée, le seuil, ses deux séries — puis choisit la série
    // qu'il lance.
    //
    // ⚠️ **Révoque** le lancement direct depuis la ligne du cycle : la série
    // ciblée partait de [planStepAction] côté TCF et de `startCivicUniteSerie`
    // côté civique, et ce lanceur a quitté cet écran avec elle (ses autres
    // appelants le gardent).
    //
    // ⚠️ **Les étapes d'EXPRESSION ne sont PAS concernées** : elles portent une
    // tâche et gardent leur chemin vers leurs petits sujets.
    if (journeyEtapeASeries(etape)) {
      return () => context.push(AppRoutes.planEtapePath(etape.id));
    }
    // 🛑 **Le Plan TCF n'a rien à dire d'une étape civique** (A86) : hors étape
    // de séries, une ligne civique n'a pas de geste — l'examen d'un bloc se
    // lance depuis son propre encart.
    if (widget.module == AppModule.civique) return null;
    final plan = widget.plan;
    if (plan == null) return null;
    final action = planStepAction(plan, etape);
    if (action == null) return null;
    // 🛑 **Une action SERVIE mais verrouillée ne se lance pas** : son geste est
    // un geste d'achat, rendu par [_gesteDe]. Les lanceurs gardent leur
    // `onVerrou` — c'est la même porte, et la garde de dernier recours.
    if (planStepActionLocked(action)) return null;
    final mesure = action.mesure;
    if (mesure != null) {
      return () => unawaited(startPlanSeanceItem(
            context,
            ref,
            mesure,
            origine: PlanOrigine.plan,
            onVerrou: () => _versEcranDeDeblocage(context),
          ));
    }
    final exercise = action.exercise!;
    return () => unawaited(openPlanExercise(
          context,
          ref,
          exercise,
          origine: PlanOrigine.plan,
          masteryBefore: action.priority?.masteryState,
          onVerrou: () => _versEcranDeDeblocage(context),
        ));
  }

  /* --------------------------------------------------- fin de cycle (§6) --- */

  /// **La fin de cycle** : « Prochaine étape », puis un vrai choix.
  ///
  /// - « Passer l'examen blanc complet » appelle `POST …/measurement-cycle`
  ///   **puis** lance l'examen complet par le chemin existant
  ///   (`FullTcfExamRepository.start`) — le geste crée le cycle de mesure, il ne
  ///   démarre rien par lui-même côté serveur. 🛑 **Il n'apparaît que si
  ///   `examenCompletPossible`** : à la fin d'un cycle de mesure, enchaîner un
  ///   second examen complet ne mesurerait rien de nouveau.
  /// - « Actualiser mon plan sans examen complet » appelle `POST …/refresh`.
  ///
  /// 🛑 **Les deux relancent les lectures vivantes** ([signalerMesureEcrite]) :
  /// Plan et parcours se rafraîchissent **ensemble**, jamais l'un sans l'autre.
  ///
  /// 🛑 **Un échec réseau se DIT** : le bouton ne reste jamais muet.
  Widget _finDeCycle(bool examenCompletPossible) {
    final erreur = _erreur;
    return SfSection(
      title: kJourneyNextStepTitle,
      child: SfStack(
        children: [
          SfNextStepCard(
            eyebrow: kJourneyNextStepEyebrow,
            title: kJourneyNextStepHeadline,
            text: examenCompletPossible
                ? kJourneyNextStepText
                : kJourneyNextStepTextMesure,
            // 🛑 Les repères décrivent l'examen complet : sans lui, ils n'ont
            // rien à dire.
            facts: examenCompletPossible
                ? kJourneyNextStepFacts
                : const <SfNextStepFact>[],
            // Une carte à deux actions dont la première n'existe pas :
            // l'actualisation prend la place principale, et c'est la seule issue
            // d'un cycle de mesure clos.
            primary: examenCompletPossible
                ? (
                    label: _occupe
                        ? kJourneyNextStepBusy
                        : kJourneyNextStepExamCta,
                    onPressed: _lancerExamenComplet,
                  )
                : (
                    label: _occupe
                        ? kJourneyNextStepBusy
                        : kJourneyNextStepRefreshOnlyCta,
                    onPressed: _actualiser,
                  ),
            // 🛑 **Absente quand l'examen complet n'est pas proposé** : il ne
            // reste qu'une issue, et fabriquer un second bouton pour tenir la
            // forme ferait deux fois le même geste.
            secondary: examenCompletPossible
                ? (
                    label: kJourneyNextStepRefreshCta,
                    onPressed: _actualiser,
                  )
                : null,
          ),
          // 🛑 La note ne se lit que face à un choix : sans examen complet à
          // proposer, elle décrirait une option absente.
          if (examenCompletPossible)
            SfInfoNote(
              child: Text(
                kJourneyNextStepNote,
                style:
                    AppFonts.ui(size: 12, color: AppColors.muted, height: 1.45),
              ),
            ),
          if (erreur != null)
            Text(
              erreur,
              style: AppFonts.ui(size: 12, color: AppColors.red, height: 1.45),
            ),
        ],
      ),
    );
  }

  void _actualiser() {
    if (_occupe) return;
    unawaited(_faire(() async {
      await ref
          .read(learningPlanRepositoryProvider)
          .refresh(module: widget.module);
    }));
  }

  void _lancerExamenComplet() {
    if (_occupe) return;
    unawaited(_faire(() async {
      await ref
          .read(learningPlanRepositoryProvider)
          .measurementCycle(module: widget.module);
      // Le cycle de mesure existe désormais : il reste à ouvrir l'examen, par
      // le **chemin existant de SON module** — aucune route n'est créée.
      ref.read(selectedModuleProvider.notifier).state = widget.module;
      if (widget.module == AppModule.civique) {
        final attempt = await ref.read(attemptsRepositoryProvider).start(
              StartAttemptRequest(
                type: AttemptType.mockExam,
                module: AppModule.civique,
              ),
            );
        if (!mounted) return;
        context.push(AppRoutes.runner.replaceFirst(':attemptId', attempt.id));
        return;
      }
      final exam = await ref.read(fullTcfExamRepositoryProvider).start();
      if (!mounted) return;
      ref.invalidate(fullExamsHistoryProvider);
      context.go(
        AppRoutes.tcfFullExamProgress.replaceFirst(':parentId', exam.id),
      );
    }));
  }

  Future<void> _faire(Future<void> Function() geste) async {
    setState(() {
      _occupe = true;
      _erreur = null;
    });
    try {
      await geste();
      // 🛑 Le signal recharge les cinq lectures gardées en vie, Plan et parcours
      // compris : c'est ce qui repeint l'écran sans le remonter.
      if (mounted) signalerMesureEcrite(ref);
    } catch (error) {
      if (!mounted) return;
      // Un **403** au démarrage de l'examen n'est pas une panne : c'est le
      // verrou freemium que le serveur oppose, et il ouvre l'offre. Le cycle de
      // mesure, lui, est déjà créé — le candidat le retrouvera.
      //
      // 🛑 **Pas de `showPaywallOrError` ici** : sa branche « message » est une
      // SnackBar, qui disparaît — et un bouton de fin de cycle qui a échoué doit
      // rester expliqué à l'écran. On garde donc sa CLASSIFICATION, qui est
      // l'autorité (`classifyStartFailure`), et on pose la phrase soi-même.
      if (classifyStartFailure(error) == StartFailure.paywall) {
        unawaited(showPaywallSheet(
          context,
          ctaLocation: AnalyticsCtaLocation.lockedPlan,
          journeyId: widget.journey?.journeyId,
        ));
      } else {
        setState(() => _erreur = kJourneyNextStepError);
      }
    } finally {
      if (mounted) setState(() => _occupe = false);
    }
  }
}
