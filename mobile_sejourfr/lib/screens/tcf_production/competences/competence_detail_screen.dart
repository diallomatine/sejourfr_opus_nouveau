import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/api/api_client.dart';
import '../../../core/models/skill_models.dart';
import '../../../core/router/route_observer.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_date.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/premium_lock.dart';
import '../../../core/widgets/progress_dots.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/skill_mastery_tag.dart';
import '../../plan/learning_plan_provider.dart';
import '../../plan/plan_step_labels.dart';
import '../widgets/exam_filter_chips.dart';
import '../tcf_production_module.dart';
import 'competences_nav.dart';
import 'competences_providers.dart';
import '../widgets/production_blocks.dart';
import '../widgets/production_state_views.dart';
import 'widgets/skill_prompt_row.dart';

/// Les deux actions proposées sur un petit sujet **déjà traité** : relire son
/// dernier retour, ou le refaire. Libellés gelés, **miroirs mot pour mot** de
/// `SKILL_PROMPT_REPORT_CTA` / `SKILL_PROMPT_ANSWER_CTA` /
/// `SKILL_PROMPT_REDO_CTA` (`web_sejoufr/app/_components/skill-ui/SkillLayout.tsx`).
///
/// ⚠️ Le premier libellé **suit le statut servi**, et c'est volontaire : une
/// tentative `TREATED` a été produite **sans analyse IA** (quota épuisé, ou
/// production rendue sans la demander). Son écran de résultat le dit lui-même
/// (« Sujet marqué comme traité ») et ne montre que la production et les
/// références — lui promettre un « rapport » serait faux.
const String kSkillPromptReportCta = 'Voir mon dernier rapport';
const String kSkillPromptAnswerCta = 'Voir ma dernière réponse';
const String kSkillPromptRedoCta = 'Refaire ce sujet';

/// Le libellé exact du premier choix, selon qu'un verdict existe ou non.
String skillPromptLastAttemptCta(SkillPromptStatus status) =>
    status == SkillPromptStatus.validated ||
            status == SkillPromptStatus.toReinforce
        ? kSkillPromptReportCta
        : kSkillPromptAnswerCta;

/// Surtitre de la carte qui met en avant le sujet à faire maintenant.
const String kNextPromptEyebrow = 'Prochain sujet recommandé';

/// Ce qu'on dit d'un sujet qu'on **repropose**. Formulation positive, règle
/// gelée du dépôt : on nomme ce que la reprise apporte, jamais un manque — et
/// on n'affirme aucun nombre de passages, un sujet pouvant être repris
/// plusieurs fois. Miroir mot pour mot de `NEXT_PROMPT_REINFORCE_REASON` côté
/// web (`app/_components/competences/CompetenceDetail.tsx`).
const String kNextPromptReinforceReason =
    'Déjà traité : le reprendre consolide ce qui restait fragile.';

/// Le rappel de pied de liste. « Tout traité » n'est pas « acquis » : la preuve
/// se fait en situation, sur une production complète, et c'est le Plan qui la
/// déclenche. Sans cette ligne, une série au complet se lit comme une
/// compétence maîtrisée.
const String kSkillSeriesNote =
    'Avoir traité tous les sujets ne veut pas dire que la compétence est '
    'acquise : elle se confirme sur une production complète, que ton plan te '
    'proposera.';

/// Détail d'une compétence : carte de résumé, sujet recommandé mis en avant,
/// puis la liste des petits sujets avec leur statut.
///
/// ⚠️ **Deux vues, selon la porte d'entrée** (décision produit, cf.
/// `screens/plan/plan_step_labels.dart`). Ouvert **depuis le Plan**
/// ([planStep]) et tant que la compétence est une priorité, l'écran se limite
/// aux **sujets de l'étape** et compte « 2/5 » ; par « Réviser → épreuve →
/// Compétences », il garde la fiche complète et son « x/15 », **strictement
/// inchangée**. Sans périmètre exploitable — Plan pas chargé, compétence sortie
/// des priorités, étape vide — on retombe **silencieusement** sur la fiche
/// complète : jamais d'erreur, jamais d'écran vide.
class CompetenceDetailScreen extends ConsumerStatefulWidget {
  const CompetenceDetailScreen({
    super.key,
    required this.module,
    required this.skillId,
    this.planStep = false,
  });

  final TcfProductionModule module;
  final String skillId;

  /// Marqueur `?etape=1` : on arrive du Plan.
  final bool planStep;

  @override
  ConsumerState<CompetenceDetailScreen> createState() =>
      _CompetenceDetailScreenState();
}

class _CompetenceDetailScreenState extends ConsumerState<CompetenceDetailScreen>
    with RouteAware {
  /// 0 = Tous · 1 = À faire · 2 = Traités
  int _filter = 0;

  Color get _accent => widget.module.accent;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  /// Retour depuis un petit sujet : son statut vient de changer (§13.3 — le
  /// sujet doit passer « traité » immédiatement).
  @override
  void didPopNext() {
    ref.invalidate(skillDetailProvider(widget.skillId));
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    // Venu du Plan, on y retourne : l'étape est son écran, pas l'épreuve.
    context.go(widget.planStep ? '/plan' : '/tcf/${widget.module.routeKey}');
  }

  /// Verrou freemium servi par le serveur : un sujet fermé ouvre l'offre, pas
  /// un écran de production que le serveur refuserait (403).
  void _openPrompt(SkillPromptSummary prompt) {
    if (prompt.locked) {
      unawaited(showTcfLockPaywall(context));
      return;
    }
    context.push(
      competencePromptPath(widget.module, widget.skillId, prompt.id),
    );
  }

  /// Taper une **ligne** de la liste. Un sujet déjà traité dont le dernier
  /// retour est relisible propose un choix ; tout le reste entre directement en
  /// production, comme avant — on n'ajoute pas d'étape là où il n'y a rien à
  /// choisir.
  ///
  /// ⚠️ La carte « Prochain sujet recommandé » ne passe **pas** par ici : son
  /// libellé annonce déjà ce qui va se passer (« Commencer le prochain sujet »
  /// / « Retravailler ce sujet »), une feuille par-dessus serait une
  /// confirmation de rien.
  void _onPromptTap(SkillPromptSummary prompt) {
    if (!prompt.locked &&
        prompt.status.isTreated &&
        prompt.lastAttemptId != null) {
      _openDoneSheet(prompt);
      return;
    }
    _openPrompt(prompt);
  }

  /// Feuille « sujet déjà traité » : relire le dernier retour, ou refaire le
  /// sujet. Même geste et même composant que sur un examen déjà passé
  /// (`showAppSheet`) — deux façons de faire le même geste dans le même produit,
  /// c'est ce que le dépôt interdit.
  void _openDoneSheet(SkillPromptSummary prompt) {
    final attemptId = prompt.lastAttemptId;
    if (attemptId == null) return;
    final meta = <String>[
      prompt.status.label,
      if (prompt.lastAttemptAt != null) formatShortDate(prompt.lastAttemptAt!),
    ].join(' · ');

    showAppSheet<void>(
      context,
      icon: LucideIcons.fileText,
      iconBg: _accent.withValues(alpha: 0.10),
      iconColor: _accent,
      title: prompt.title,
      sub: meta,
      children: [
        AppButton(
          label: skillPromptLastAttemptCta(prompt.status),
          icon: LucideIcons.fileText,
          variant: AppButtonVariant.ghost,
          height: 46,
          onPressed: () {
            Navigator.of(context).pop();
            context.push(competenceResultPath(widget.module, attemptId));
          },
        ),
        AppButton(
          label: kSkillPromptRedoCta,
          icon: LucideIcons.refreshCw,
          variant: widget.module.isEo
              ? AppButtonVariant.accent
              : AppButtonVariant.primary,
          height: 46,
          onPressed: () {
            Navigator.of(context).pop();
            _openPrompt(prompt);
          },
        ),
      ],
    );
  }

  /// L'étape du Plan qui porte cette compétence, ou `null` (cas normal).
  ///
  /// Le Plan est **déjà chargé** : on n'arrive ici avec le marqueur qu'en
  /// venant de l'écran Plan, qui reste monté sous celui-ci — le provider est
  /// donc vivant et rend sa valeur **sans aucun appel réseau**.
  PlanStepScope? _step() {
    if (!widget.planStep) return null;
    return planStepFor(
      ref.watch(learningPlanProvider).valueOrNull,
      widget.skillId,
    );
  }

  /// Les sujets de l'étape, **dans l'ordre servi**. On ne rejoue aucune règle
  /// (« les 5 premiers par rang ») : on retrouve simplement les sujets des
  /// identifiants servis. Vide ⇒ l'appelant se replie sur la fiche complète.
  List<SkillPromptSummary> _stepPrompts(
    List<SkillPromptSummary> prompts,
    PlanStepScope step,
  ) {
    final byId = {for (final p in prompts) p.id: p};
    return [
      for (final id in step.stepPromptIds)
        if (byId[id] != null) byId[id]!,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(skillDetailProvider(widget.skillId));
    final detail = async.valueOrNull;
    final step = _step();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ScreenHeader(
              title: detail?.skill.title ?? 'Compétence',
              sub: detail == null
                  ? widget.module.title
                  : '${detail.skill.code} · ${widget.module.title}',
              onBack: _back,
            ),
            Expanded(
              child: async.when(
                skipLoadingOnReload: true,
                loading: () =>
                    Center(child: CircularProgressIndicator(color: _accent)),
                error: (e, _) => ProductionErrorView(
                  message: ApiClient.toApiException(e).message,
                  onRetry: () =>
                      ref.invalidate(skillDetailProvider(widget.skillId)),
                ),
                data: (detail) => _list(detail, step),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ce que l'écran propose de faire **maintenant**.
  ///
  /// **En mode étape**, la cible est celle **désignée par le serveur**
  /// (`recommendedExercise.skillPromptId`, périmètre déjà borné aux 5 sujets de
  /// l'étape) : le Plan et cet écran ne peuvent donc pas désigner deux sujets
  /// différents. Sans désignation exploitable (fiche complète, pas d'exercice
  /// recommandé, vérification), on garde le comportement historique : le
  /// premier sujet **ouvert** encore à faire, sinon le premier sujet ouvert.
  ///
  /// Un sujet verrouillé reste **désigné**, jamais détourné — l'action ouvre
  /// alors l'offre.
  _NextStep _next(SkillDetail detail, PlanStepScope? step) {
    final prompts = _prompts(detail, step);
    final scoped = !identical(prompts, detail.prompts);
    final designated = scoped ? planStepRecommendedPrompt(step, prompts) : null;

    if (designated != null) {
      final locked =
          designated.locked || step?.recommendedExercise?.locked == true;
      final fresh = !designated.status.isTreated;
      return _NextStep(
        prompt: designated,
        locked: locked,
        label: fresh ? kPlanStepStartCta : kPlanStepRetryCta,
        icon: fresh ? LucideIcons.play : LucideIcons.refreshCw,
      );
    }

    // L'action historique vise toujours un sujet **ouvert** : proposer
    // « Commencer » sur un sujet verrouillé mènerait droit au paywall alors que
    // d'autres sujets sont disponibles.
    final open = prompts.where((p) => !p.locked).toList();
    if (open.isEmpty) {
      return const _NextStep(
        prompt: null,
        locked: true,
        label: kPremiumLockCta,
        icon: LucideIcons.lock,
      );
    }
    final todo = open.where((p) => !p.status.isTreated).toList();
    final fresh = todo.isNotEmpty;
    return _NextStep(
      prompt: fresh ? todo.first : open.first,
      locked: false,
      label: fresh ? kPlanStepStartCta : kPlanStepRetryCta,
      icon: fresh ? LucideIcons.play : LucideIcons.refreshCw,
    );
  }

  /// Le périmètre affiché : l'étape quand on vient du Plan et qu'elle est
  /// exploitable, la compétence entière sinon.
  List<SkillPromptSummary> _prompts(
    SkillDetail detail,
    PlanStepScope? step,
  ) {
    if (step == null) return detail.prompts;
    final scoped = _stepPrompts(detail.prompts, step);
    return scoped.isEmpty ? detail.prompts : scoped;
  }

  Widget _list(SkillDetail detail, PlanStepScope? step) {
    final prompts = _prompts(detail, step);
    // `_prompts` rend **l'instance** de la fiche complète quand il se replie :
    // c'est ce qui distingue les deux vues sans recompter quoi que ce soit.
    final scoped = !identical(prompts, detail.prompts);
    if (prompts.isEmpty) {
      return const ProductionEmptyView(
        description: 'Les sujets de cette compétence ne sont pas encore prêts.',
      );
    }

    // DEUX seaux disjoints, dont la somme fait exactement « Tous » — un
    // compteur qui ne totalise pas est un compteur qui ment. « Traités » décrit
    // l'historique (un sujet produit y reste, même si le verrou est retombé
    // dessus depuis) ; « À faire » contient tout le reste, **verrouillés
    // compris**. Ils sont bien à faire ; le verrou est commercial, il se dit
    // sur la ligne (cadenas) et au tap (l'offre).
    final treated = prompts.where((p) => p.status.isTreated).length;
    final todo = prompts.where((p) => !p.status.isTreated).length;
    final lockedTodo =
        prompts.where((p) => !p.status.isTreated && p.locked).length;
    final filter = _filter;
    final visible = prompts.where((p) {
      if (filter == 1) return !p.status.isTreated;
      if (filter == 2) return p.status.isTreated;
      return true;
    }).toList();

    // Étape finie : on ne fabrique **aucun** second parcours de vérification
    // ici — « Vérifier ma progression » vit sur le Plan, qui seul sait si le
    // moteur de maîtrise est prêt. On y ramène.
    final stepDone = scoped && step!.stepCompleted;
    final next = _next(detail, step);

    // Les compteurs affichés viennent du **serveur** en mode étape
    // (`step*Count`) et des sujets servis sinon : rien n'est inventé, et ce
    // sont exactement ceux qui pilotent la barre de segments.
    final attempted = scoped ? step!.stepAttemptedCount : treated;
    final total = scoped ? step!.stepPromptCount : detail.skill.promptCount;
    final validated =
        scoped ? step!.stepValidatedCount : detail.skill.validatedCount;

    return RefreshIndicator(
      color: _accent,
      onRefresh: () async {
        ref.invalidate(skillDetailProvider(widget.skillId));
        await ref.read(skillDetailProvider(widget.skillId).future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _SummaryCard(
            skill: detail.skill,
            accent: _accent,
            attempted: attempted,
            total: total,
            validated: validated,
            stepPill: scoped,
            icon: widget.module.icon,
          ),
          const SizedBox(height: 14),
          if (stepDone)
            _StepDoneCard(
              total: step.stepPromptCount,
              onOpenPlan: () => context.go('/plan'),
            )
          else
            _NextPromptCard(
              next: next,
              accent: _accent,
              isEo: widget.module.isEo,
              onAction: () {
                final target = next.prompt;
                if (target == null) {
                  unawaited(showTcfLockPaywall(context));
                  return;
                }
                _openPrompt(target);
              },
            ),
          const SizedBox(height: 21),
          ProductionSectionHead(
            title: scoped ? kPlanStepSectionTitle : 'Petits sujets',
            description: scoped
                ? planStepSectionText(step!.stepPromptCount)
                : 'Les sujets déjà réalisés restent clairement identifiables.',
            accent: _accent,
          ),
          const SizedBox(height: 11),
          ExamFilterChips(
            active: filter,
            accent: _accent,
            labels: [
              'Tous · ${prompts.length}',
              'À faire · $todo',
              'Traités · $treated',
            ],
            onChanged: (i) => setState(() => _filter = i),
          ),
          const SizedBox(height: 12),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Text(
                _emptyMessage(filter: filter, lockedTodo: lockedTodo),
                textAlign: TextAlign.center,
                style: AppFonts.ui(size: 13.5, color: AppColors.inkSoft),
              ),
            )
          else
            SkillPromptGroup(
              children: [
                for (final prompt in visible)
                  SkillPromptRow(
                    prompt: prompt,
                    accent: _accent,
                    highlighted: prompt.id == next.prompt?.id,
                    onTap: () => _onPromptTap(prompt),
                  ),
              ],
            ),
          const SizedBox(height: 14),
          const _SeriesNote(),
        ],
      ),
    );
  }

  /// « Plus rien à faire » n'a pas le même sens selon qu'il ne reste rien ou
  /// qu'il ne reste que du verrouillé.
  String _emptyMessage({required int filter, required int lockedTodo}) {
    if (filter == 2) return 'Aucun sujet traité pour le moment.';
    if (filter == 1 && lockedTodo > 0) {
      return 'Les sujets restants sont réservés à l\'abonnement Intégral.';
    }
    return 'Tous les sujets de cette compétence ont été traités.';
  }
}

/// Le sujet que l'écran propose, et comment on le dit. [prompt] `null` = plus
/// aucun sujet ouvert : la carte devient une porte vers l'offre.
class _NextStep {
  const _NextStep({
    required this.prompt,
    required this.locked,
    required this.label,
    required this.icon,
  });

  final SkillPromptSummary? prompt;
  final bool locked;
  final String label;
  final IconData icon;
}

/// La carte qui met en avant **une seule** action : le sujet à faire
/// maintenant. Elle remplace la barre d'action fixe du bas — l'action et le
/// sujet qu'elle vise se lisent désormais au même endroit, au lieu d'un bouton
/// dont on ne savait pas où il menait.
class _NextPromptCard extends StatelessWidget {
  const _NextPromptCard({
    required this.next,
    required this.accent,
    required this.isEo,
    required this.onAction,
  });

  final _NextStep next;
  final Color accent;
  final bool isEo;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final prompt = next.prompt;

    final title = Text(
      prompt?.title ?? 'Les sujets suivants sont réservés à l\'abonnement',
      style: AppFonts.display(size: 18, height: 1.2),
    );
    final reason = prompt == null
        ? null
        : (prompt.status == SkillPromptStatus.toReinforce
            ? kNextPromptReinforceReason
            : prompt.uniqueCriterion.trim());

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  accent.withValues(alpha: 0.10),
                  accent.withValues(alpha: 0),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      next.locked ? LucideIcons.lock : LucideIcons.zap,
                      size: 13,
                      color: accent,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        kNextPromptEyebrow.toUpperCase(),
                        style: AppFonts.label(size: 10, color: accent),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Verrouillé, le sujet reste **nommé** : la règle du module est
                // « rien n'est masqué, tout est annoncé ». Seul le bouton
                // change — il mène à l'offre.
                title,
                if (reason != null && reason.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    reason,
                    style: AppFonts.ui(
                      size: 13,
                      height: 1.45,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: AppButton(
              label: next.label,
              icon: next.icon,
              variant: next.locked
                  ? AppButtonVariant.soft
                  : (isEo ? AppButtonVariant.accent : AppButtonVariant.primary),
              onPressed: onAction,
            ),
          ),
        ],
      ),
    );
  }
}

/// L'étape est allée au bout : on ne propose pas un sujet de plus, on renvoie
/// là où la suite se décide.
class _StepDoneCard extends StatelessWidget {
  const _StepDoneCard({required this.total, required this.onOpenPlan});

  final int total;
  final VoidCallback onOpenPlan;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.greenLight,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.circleCheck,
                size: 14,
                color: AppColors.green,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  kPlanStepDoneTitle.toUpperCase(),
                  style: AppFonts.label(size: 10, color: AppColors.green),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            planStepDoneText(total),
            style: AppFonts.ui(size: 13.5, height: 1.5, color: AppColors.ink2),
          ),
          const SizedBox(height: 14),
          AppButton(
            label: kPlanStepDoneCta,
            icon: LucideIcons.arrowRight,
            variant: AppButtonVariant.soft,
            onPressed: onOpenPlan,
          ),
        ],
      ),
    );
  }
}

/// Le rappel de pied de liste, en texte discret : traité ≠ acquis.
class _SeriesNote extends StatelessWidget {
  const _SeriesNote();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Text(
          kSkillSeriesNote,
          style: AppFonts.ui(size: 12, height: 1.5, color: AppColors.inkFaint),
        ),
      );
}

/// Carte de résumé de la compétence : icône 48×48, état de maîtrise, titre,
/// pastille d'information, puis la progression **en segments** et l'encart
/// « Critère travaillé ».
///
/// L'explication de la compétence (`skill.description`) ne vit **pas** dans le
/// corps de la carte : six lignes de texte y repoussaient le critère et la
/// liste des sujets. Elle est derrière la pastille d'information en haut à
/// droite, qui disparaît quand il n'y a rien à expliquer.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.skill,
    required this.accent,
    required this.attempted,
    required this.total,
    required this.validated,
    required this.icon,
    this.stepPill = false,
  });

  final SkillDto skill;
  final Color accent;

  /// Progression affichée. En mode étape, ces trois nombres **viennent du
  /// serveur** (`step*Count`) : rien n'est recompté ici.
  final int attempted;
  final int total;
  final int validated;
  final IconData icon;

  /// Pastille « Étape de ton plan » : on dit d'où l'on vient, sinon l'écran
  /// ressemble à la fiche complète tout en n'en montrant qu'une partie.
  final bool stepPill;

  @override
  Widget build(BuildContext context) {
    final complete = total > 0 && attempted >= total;
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 23, color: accent),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (stepPill) ...[
                      _StepPill(accent: accent),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      skill.title,
                      style: AppFonts.display(size: 19, height: 1.2),
                    ),
                    // Ce que le candidat *maîtrise*, pas ce qu'il a *fait* —
                    // le compteur, lui, est juste en dessous. Rien quand le
                    // serveur n'a rien observé : on n'invente pas un état.
                    if (skill.masteryState != null) ...[
                      const SizedBox(height: 7),
                      SkillMasteryTag(state: skill.masteryState!),
                    ],
                  ],
                ),
              ),
              // Deux textes, deux endroits : l'explication dit à quoi la
              // compétence sert au TCF (ici, à la demande), le critère général
              // dit ce qui est travaillé (dans la carte, toujours visible).
              if (skill.description.trim().isNotEmpty)
                _SkillInfoButton(
                  title: skill.title,
                  description: skill.description,
                  accent: accent,
                ),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, thickness: 1, color: AppColors.line2),
            const SizedBox(height: 13),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$attempted / $total sujets travaillés',
                    style: AppFonts.ui(size: 13, weight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  complete
                      ? 'Série terminée'
                      : validated > 0
                          ? '$validated validé${validated > 1 ? 's' : ''}'
                          : '',
                  style: AppFonts.ui(
                    size: 12,
                    weight: FontWeight.w700,
                    color: complete ? AppColors.green : AppColors.inkFaint,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ProgressDots(done: attempted, total: total, color: accent),
          ],
          if (skill.generalCriterion.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, thickness: 1, color: AppColors.line2),
            const SizedBox(height: 13),
            _CriterionBox(criterion: skill.generalCriterion),
          ],
        ],
      ),
    );
  }
}

/// Pastille « Étape de ton plan » de la carte de résumé, rendue seulement quand
/// la compétence a été ouverte depuis le Plan.
class _StepPill extends StatelessWidget {
  const _StepPill({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        kPlanStepPill.toUpperCase(),
        style: AppFonts.label(size: 10, color: accent),
      ),
    );
  }
}

/// Pastille d'information de la carte de résumé : ouvre l'explication de la
/// compétence dans une feuille. Visuel discret (30×30) mais zone tactile de
/// 44×44 — la cible minimale, pas la taille du dessin.
class _SkillInfoButton extends StatelessWidget {
  const _SkillInfoButton({
    required this.title,
    required this.description,
    required this.accent,
  });

  static const String _label = 'À quoi sert cette compétence ?';

  final String title;
  final String description;
  final Color accent;

  void _open(BuildContext context) {
    showAppSheet<void>(
      context,
      icon: LucideIcons.info,
      iconBg: accent.withValues(alpha: 0.10),
      iconColor: accent,
      title: title,
      children: [
        Text(
          description,
          style: AppFonts.ui(
            size: 13.5,
            color: AppColors.inkSoft,
            height: 1.55,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: _label,
      child: Tooltip(
        message: _label,
        child: InkWell(
          onTap: () => _open(context),
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.line),
                ),
                child: Icon(
                  LucideIcons.info,
                  size: 15,
                  color: AppColors.inkSoft,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `.criterion-box` du prototype : encadré gris neutre, label en petites
/// capitales, critère en 13.
class _CriterionBox extends StatelessWidget {
  const _CriterionBox({required this.criterion});

  final String criterion;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CRITÈRE TRAVAILLÉ',
            style: AppFonts.label(size: 10, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 5),
          Text(criterion, style: AppFonts.ui(size: 13, height: 1.4)),
        ],
      ),
    );
  }
}
