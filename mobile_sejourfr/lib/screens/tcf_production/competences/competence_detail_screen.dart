import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/api/api_client.dart';
import '../../../core/models/skill_models.dart';
import '../../../core/router/route_observer.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/fixed_action_bar.dart';
import '../../../core/widgets/premium_lock.dart';
import '../../../core/widgets/progress_track.dart';
import '../../../core/widgets/screen_header.dart';
import '../../plan/learning_plan_provider.dart';
import '../../plan/plan_step_labels.dart';
import '../widgets/exam_filter_chips.dart';
import '../tcf_production_module.dart';
import 'competences_nav.dart';
import 'competences_providers.dart';
import '../widgets/production_blocks.dart';
import '../widgets/production_state_views.dart';
import 'widgets/skill_prompt_card.dart';
import 'widgets/skill_trajectory.dart';

/// Détail d'une compétence : carte de résumé, progression en sujets traités,
/// filtres, puis la liste des petits sujets avec leur statut.
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

class _CompetenceDetailScreenState
    extends ConsumerState<CompetenceDetailScreen> with RouteAware {
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
            ), /// Diallo
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
            if (detail != null && _prompts(detail, step).isNotEmpty)
              FixedActionBar(
                child: _primaryAction(detail, step),
              ),
          ],
        ),
      ),
    );
  }

  /// L'action principale de l'écran.
  ///
  /// **En mode étape**, elle vise le sujet **désigné par le serveur**
  /// (`recommendedExercise.skillPromptId`, périmètre déjà borné aux 5 sujets de
  /// l'étape) : le Plan et cet écran ne peuvent donc pas désigner deux sujets
  /// différents. Le libellé dit ce qui va se passer — commencer un sujet neuf
  /// et revenir sur un sujet déjà rendu ne se disent pas pareil —, et c'est le
  /// **statut servi** du sujet qui tranche. Un sujet verrouillé reste
  /// **désigné**, jamais détourné : le bouton ouvre l'offre.
  ///
  /// Sans désignation exploitable (fiche complète, pas d'exercice recommandé,
  /// vérification), on garde le comportement historique décrit ci-dessous.
  Widget _primaryAction(SkillDetail detail, PlanStepScope? step) {
    final prompts = _prompts(detail, step);
    final scoped = !identical(prompts, detail.prompts);
    final target =
        scoped ? planStepRecommendedPrompt(step, prompts) : null;
    if (target != null) {
      final locked =
          target.locked || step?.recommendedExercise?.locked == true;
      if (locked) {
        return AppButton(
          label: kPremiumLockCta,
          icon: LucideIcons.lock,
          variant: AppButtonVariant.soft,
          onPressed: () => unawaited(showTcfLockPaywall(context)),
        );
      }
      final fresh = !target.status.isTreated;
      return AppButton(
        label: fresh ? kPlanStepStartCta : kPlanStepRetryCta,
        icon: fresh ? LucideIcons.play : LucideIcons.refreshCw,
        variant: widget.module.isEo
            ? AppButtonVariant.accent
            : AppButtonVariant.primary,
        onPressed: () => _openPrompt(target),
      );
    }
    return _fallbackAction(prompts);
  }

  /// L'action historique : elle vise toujours un sujet **ouvert** — proposer
  /// « Commencer » sur un sujet verrouillé mènerait droit au paywall alors que
  /// d'autres sujets sont disponibles. Quand plus rien n'est ouvert, le bouton
  /// dit la seule chose vraie qui reste.
  Widget _fallbackAction(List<SkillPromptSummary> prompts) {
    final open = prompts.where((p) => !p.locked);
    if (open.isEmpty) {
      return AppButton(
        label: kPremiumLockCta,
        icon: LucideIcons.lock,
        variant: AppButtonVariant.soft,
        onPressed: () => unawaited(showTcfLockPaywall(context)),
      );
    }
    final todo = open.where((p) => !p.status.isTreated);
    final target = todo.isNotEmpty ? todo.first : open.first;
    final isTodo = todo.isNotEmpty;
    return AppButton(
      label: isTodo ? 'Commencer le premier sujet' : 'Refaire un sujet',
      icon: isTodo ? LucideIcons.play : LucideIcons.refreshCw,
      variant: widget.module.isEo
          ? AppButtonVariant.accent
          : AppButtonVariant.primary,
      onPressed: () => _openPrompt(target),
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

    // Les compteurs ne doivent pas mentir. Un sujet verrouillé n'est pas « à
    // faire » : il n'est pas ouvert. Il reste compté dans « Tous » (il est bien
    // affiché) et dans « Traités » s'il a déjà été produit — un abonnement échu
    // ne réécrit pas l'historique du candidat. Le 4ᵉ filet « Verrouillés »
    // n'apparaît que s'il y en a, et c'est lui qui rend la somme juste :
    // `Tous = À faire + Traités + Verrouillés` (miroir du web).
    final treated = prompts.where((p) => p.status.isTreated).length;
    final todo =
        prompts.where((p) => !p.status.isTreated && !p.locked).length;
    final lockedTodo =
        prompts.where((p) => !p.status.isTreated && p.locked).length;
    // Le 4ᵉ filtre disparaît avec le dernier sujet verrouillé (abonnement pris
    // pendant la session) : on retombe sur « Tous » plutôt que de laisser un
    // filtre actif qui ne correspond plus à aucune pastille.
    final filter = _filter == 3 && lockedTodo == 0 ? 0 : _filter;
    final visible = prompts.where((p) {
      if (filter == 1) return !p.status.isTreated && !p.locked;
      if (filter == 2) return p.status.isTreated;
      if (filter == 3) return !p.status.isTreated && p.locked;
      return true;
    }).toList();

    return RefreshIndicator(
      color: _accent,
      onRefresh: () async {
        ref.invalidate(skillDetailProvider(widget.skillId));
        await ref.read(skillDetailProvider(widget.skillId).future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _SummaryCard(
            skill: detail.skill,
            accent: _accent,
            // En mode étape, la progression affichée est **celle du serveur**
            // (`stepAttemptedCount` / `stepPromptCount`) : on ne la recompte
            // pas depuis la liste.
            attempted: scoped ? step!.stepAttemptedCount : treated,
            total: scoped ? step!.stepPromptCount : detail.skill.promptCount,
            validated:
                scoped ? step!.stepValidatedCount : detail.skill.validatedCount,
            stepPill: scoped,
            icon: widget.module.icon,
          ),
          // Étape finie : on ne fabrique **aucun** second parcours de
          // vérification ici — « Vérifier ma progression » vit sur le Plan,
          // qui seul sait si le moteur de maîtrise est prêt. On y ramène.
          if (scoped && step!.stepCompleted) ...[
            const SizedBox(height: 14),
            ProductionNotice(
              icon: LucideIcons.circleCheck,
              tone: AppColors.green,
              toneSoft: AppColors.greenLight,
              title: kPlanStepDoneTitle,
              body: planStepDoneText(step.stepPromptCount),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: kPlanStepDoneCta,
              icon: LucideIcons.arrowRight,
              variant: AppButtonVariant.soft,
              onPressed: () => context.go('/plan'),
            ),
          ],
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
              if (lockedTodo > 0) 'Verrouillés · $lockedTodo',
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
            for (final prompt in visible) ...[
              SkillPromptCard(
                prompt: prompt,
                accent: _accent,
                onTap: () => _openPrompt(prompt),
              ),
              const SizedBox(height: 11),
            ],
          // La frise arrive APRÈS les sujets : elle raconte le chemin déjà
          // parcouru, l'écran sert d'abord à en produire un de plus. Vide,
          // elle ne prend pas un pixel.
          if (detail.trajectory.isNotEmpty) ...[
            const SizedBox(height: 10),
            SkillTrajectorySection(points: detail.trajectory),
          ],
        ],
      ),
    );
  }

  /// « Plus rien à faire » n'a pas le même sens selon qu'il ne reste rien ou
  /// qu'il ne reste que du verrouillé.
  String _emptyMessage({required int filter, required int lockedTodo}) {
    if (filter == 2) return 'Aucun sujet traité pour le moment.';
    if (filter == 3) return 'Aucun sujet verrouillé sur cette compétence.';
    if (filter == 1 && lockedTodo > 0) {
      return 'Les sujets restants sont réservés à l\'abonnement Intégral.';
    }
    return 'Tous les sujets de cette compétence ont été traités.';
  }
}

/// Carte de résumé de la compétence (`.skill-summary` du prototype) : icône
/// 48×48 en tête, pilule de palier, titre, puis l'encart « Critère travaillé »
/// et la progression en sujets traités.
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
          if (skill.generalCriterion.trim().isNotEmpty) ...[
            const SizedBox(height: 13),
            _CriterionBox(criterion: skill.generalCriterion),
          ],
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: ProgressTrack(
                  value: total == 0 ? 0 : attempted / total * 100,
                  color: accent,
                  height: 5,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$attempted/$total traités',
                style: AppFonts.ui(
                  size: 11,
                  weight: FontWeight.w800,
                  color: AppColors.inkSoft,
                ),
              ),
              if (validated > 0) ...[
                const SizedBox(width: 8),
                Text(
                  '$validated ✓',
                  style: AppFonts.ui(
                    size: 11,
                    weight: FontWeight.w800,
                    color: AppColors.green,
                  ),
                ),
              ],
            ],
          ),
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
