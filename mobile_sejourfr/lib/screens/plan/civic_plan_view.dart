import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/repositories.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/billing_models.dart';
import '../../core/models/civic_plan_models.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/start_failure.dart';
import '../../core/widgets/paywall_sheet.dart';
import '../../core/widgets/sejour/sejour_kit.dart';
import 'civic_plan_labels.dart';

/// **Le plan civique** (L10, `20_` §6), dans l'ordre de la maquette.
///
/// Le plan est un **moteur** : il relit tout l'historique des réponses à chaque
/// lecture, y compris celles des séries et des examens blancs, et il dit
/// **quand y revenir**.
///
/// 🛑 **Rien n'est dérivé ici.** L'ordre des cibles, leur état de maîtrise,
/// l'état de leur thème, leur échéance et leur verrou arrivent **servis**. Cet
/// écran les met en mots (`civic_plan_labels.dart`) et ouvre ce qui existe déjà.
///
/// 🛑 **La boîte Leitner ne s'affiche jamais** : on montre `maitrise` et
/// `prochaineRevue`, jamais `boite`.
///
/// 🛑 **Le plan travaille au grain que le tagging permet**, et il le dit
/// (`20_` §3.3) : thème par thème tant que les questions ne sont pas taguées,
/// notion par notion ensuite. Ce n'est pas une panne, c'est la phase 1.
///
/// 🛑 **Le constat est intégralement gratuit.** Le `locked` servi porte sur la
/// **série**, jamais sur ce que le candidat a mesuré : un compte sans pass voit
/// ses priorités entières, avec leurs états.
class CivicPlanView extends ConsumerStatefulWidget {
  const CivicPlanView({super.key});

  @override
  ConsumerState<CivicPlanView> createState() => _CivicPlanViewState();
}

class _CivicPlanViewState extends ConsumerState<CivicPlanView> {
  CivicPlan? _plan;
  bool _loading = true;
  String? _enCours;
  CivicPassDuree _duree = CivicPassDuree.troisMois;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final plan = await ref.read(civicPlanRepositoryProvider).plan();
      if (mounted) {
        setState(() {
          _plan = plan;
          _loading = false;
        });
      }
    } catch (_) {
      // Best-effort : l'onglet reste sobre. Le constat existe déjà côté
      // diagnostic, on ne remplace pas un plan par une erreur.
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Ouvre la série ciblée.
  ///
  /// 🛑 Le **403** est un refus attendu — le verrou du serveur et le `locked`
  /// servi sont la même règle — et il ouvre l'offre, jamais un message d'erreur
  /// technique (`showPaywallOrError`).
  Future<void> _commencer(CivicPlanCible cible) async {
    if (_enCours != null) return;
    if (cible.locked) {
      unawaited(_ouvrirOffre());
      return;
    }
    setState(() => _enCours = cible.id);
    try {
      final attempt = await ref
          .read(civicPlanRepositoryProvider)
          .serie(cible.id, cible.grain);
      if (!mounted) return;
      setState(() => _enCours = null);
      context.push(AppRoutes.runner.replaceFirst(':attemptId', attempt.id));
    } catch (e) {
      if (!mounted) return;
      setState(() => _enCours = null);
      showPaywallOrError(context, e);
    }
  }

  /// **La seule porte d'achat** : l'écran d'offre, qui porte les vrais passes
  /// et leurs prix du store. La durée choisie ici n'est qu'une préférence
  /// affichée — c'est là-bas qu'on achète.
  Future<void> _ouvrirOffre() =>
      showPaywallSheet(context, initialTarget: PlanModuleTarget.civique);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.blue));
    }
    final plan = _plan;
    if (plan == null || !plan.disponible) return const SizedBox.shrink();

    final auth = ref.watch(authControllerProvider);
    final hasCivique = auth is AuthAuthenticated && auth.user.hasCivique;

    if (!hasCivique) {
      return Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              color: AppColors.blue,
              onRefresh: _load,
              child: ListView(children: _free(plan)),
            ),
          ),
          SfStickyBar(
            child: SfButton(
              label: kCivicPlanUnlockCta,
              caption: civicPlanUnlockCaption(_duree),
              variant: SfButtonVariant.blue,
              onPressed: () => unawaited(_ouvrirOffre()),
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      color: AppColors.blue,
      onRefresh: _load,
      child: ListView(children: _premium(plan)),
    );
  }

  /* --------------------------------------------------------- avec pass ---- */

  List<Widget> _premium(CivicPlan plan) {
    final maintenant = DateTime.now();
    return <Widget>[
      const SfTop(
        kicker: kCivicPlanTopKicker,
        title: kCivicPlanScreenTitle,
      ),
      const SizedBox(height: 14),
      _contextCard(plan),
      if (plan.prochaine != null)
        SfSection(
          title: kCivicPlanNowTitle,
          flush: true,
          child: _nowCard(plan.prochaine!, free: false),
        )
      else
        _nothingUrgent(),
      // Le parcours de la notion en cours — c'est ICI que l'effet Leitner
      // devient visible : ce que le candidat a franchi, où il en est, et ce
      // qu'il reste avant que la notion soit tenue.
      // Parcours vide = serveur anterieur au champ : on n'affiche pas une
      // carte creuse plutot que de fabriquer des etapes.
      if (plan.prochaine?.parcours.isNotEmpty ?? false)
        _pathSection(plan.prochaine!),
      ..._prioritiesSection(plan, free: false),
      ..._doneSection(plan),
      ..._reviewSection(plan, maintenant),
      ..._changesSection(plan),
      const SizedBox(height: 28),
    ];
  }

  /* -------------------------------------------------------- sans pass ----- */

  List<Widget> _free(CivicPlan plan) {
    final resultat = plan.resultat;
    return <Widget>[
      const SfTop(
        kicker: kCivicPlanTopKickerFree,
        title: kCivicPlanScreenTitle,
      ),
      const SizedBox(height: 14),
      if (resultat != null)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SfCard(
            variant: SfCardVariant.hero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SfLabel(kCivicPlanResultLabel),
                const SizedBox(height: 6),
                SfScore(
                  score: resultat.bonnes,
                  total: resultat.posees,
                  compact: true,
                ),
                const SizedBox(height: 8),
                SfTiny(civicPlanResultNote(resultat)),
              ],
            ),
          ),
        ),
      ..._themesSection(plan),
      ..._prioritiesSection(plan, free: true),
      if (plan.prochaine != null)
        SfSection(
          title: kCivicPlanFirstStepTitle,
          flush: true,
          child: _nowCard(plan.prochaine!, free: true),
        ),
      const SfSection(
        flush: true,
        child: SfUnlockHero(
          title: kCivicPlanUnlockHeroTitle,
          text: kCivicPlanUnlockHeroText,
        ),
      ),
      _passSection(),
      const SizedBox(height: 24),
    ];
  }

  /* ------------------------------------------------------------ blocs ----- */

  /// Le contexte du plan : ce qu'il reste à renforcer, à quel grain il
  /// travaille, et comment il choisit.
  Widget _contextCard(CivicPlan plan) {
    final themes = civicPlanThemesPill(plan);
    final cibles = civicPlanCiblesPill(plan);
    final grain = civicPlanGrainNote(plan.grain);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SfCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (themes != null || cibles != null) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (themes != null)
                    SfPillMeta(label: themes, icon: LucideIcons.layers),
                  if (cibles != null)
                    SfPillMeta(label: cibles, icon: LucideIcons.target),
                ],
              ),
              const SizedBox(height: 10),
            ],
            SfTiny(civicPlanEngineLine(plan.grain)),
            if (grain != null) ...[
              const SizedBox(height: 6),
              SfTiny(grain),
            ],
          ],
        ),
      ),
    );
  }

  /// La carte d'action. [free] choisit la **mise en page** ; ce qui décide du
  /// bouton ou des cadenas reste le `locked` **servi** sur la cible.
  Widget _nowCard(CivicPlanCible cible, {required bool free}) {
    final card = SfNowCard(
      icon: LucideIcons.landmark,
      title: cible.label,
      subtitle: cible.themeLabel.isEmpty ? null : cible.themeLabel,
      badge: free ? null : kCivicPlanNowBadge,
      objectiveLabel: kCivicPlanNowWhy,
      objective: civicPlanRaison(cible),
      meta: [SfMeta(LucideIcons.list, civicSerieLabel(cible))],
      action: free && cible.locked
          ? null
          : SfButton(
              label: cible.locked ? kCivicPlanLockedCta : kCivicPlanNowCta,
              variant: SfButtonVariant.blue,
              onPressed: _enCours == cible.id
                  ? null
                  : () => unawaited(_commencer(cible)),
            ),
      caption: cible.locked ? kCivicPlanLockedNote : null,
    );

    if (!free || !cible.locked) return card;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        card,
        const SizedBox(height: sfGap),
        SfCard(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final label in kCivicPlanStepLocks) SfLockItem(label: label),
            ],
          ),
        ),
      ],
    );
  }

  /// Les thèmes **mesurés et non solides**, avec leur état servi. Un thème
  /// jamais mesuré n'y figure pas : il n'a rien raté.
  List<Widget> _themesSection(CivicPlan plan) {
    final themes = civicPlanThemesATravailler(plan);
    if (themes.isEmpty) return const <Widget>[];
    return <Widget>[
      SfSection(
        title: kCivicPlanThemesTitle,
        flush: true,
        child: SfCard(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < themes.length; i++)
                SfThemeLine(
                  tone: _tone(civicThemeTone(themes[i].etatDuTheme)),
                  name: themes[i].themeLabel,
                  status: themes[i].etatDuTheme.label,
                  last: i == themes.length - 1,
                ),
            ],
          ),
        ),
      ),
    ];
  }

  /// Le parcours d'une cible, dérivé de sa boîte Leitner **servie**.
  /// 🛑 Le numéro de boîte ne s'affiche jamais : il se rend en position dans
  /// un parcours nommé (`civicPath`).
  Widget _pathSection(CivicPlanCible cible) {
    final etapes = civicPath(cible);
    final courante = etapes.where((e) => e.state == SfStepState.now).firstOrNull;
    return SfSection(
      flush: true,
      title: '$kCivicPathTitle — ${cible.label}',
      child: SfPathCard(
        currentLabel: courante?.label ?? kCivicPathLabels.last,
        counterLabel: civicPathCounter(cible),
        steps: etapes,
      ),
    );
  }

  /// « Progression détectée ».
  ///
  /// 🛑 `changements == null` est le cas NORMAL : le bloc **disparaît**, il ne
  /// s'affiche jamais vide. C'est le seul endroit où le candidat voit son plan
  /// bouger — l'user d'un « rien n'a changé » le rendrait invisible.
  List<Widget> _changesSection(CivicPlan plan) {
    final changements = plan.changements;
    if (changements == null) return const <Widget>[];
    final nouvelle = changements.nouvellePriorite;
    return <Widget>[
      SfSection(
        flush: true,
        title: kCivicChangesTitle,
        child: SfCard(
          variant: SfCardVariant.ok,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SfLabel(changements.fenetre.label, color: AppColors.greenDark),
              const SizedBox(height: 4),
              for (final t in changements.transitions)
                SfCheckRow(label: civicTransitionLabel(t), large: true),
              if (nouvelle != null) ...[
                const SizedBox(height: 8),
                SfInsight(civicNextStepLabel(nouvelle)),
              ],
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _prioritiesSection(CivicPlan plan, {required bool free}) {
    if (plan.priorites.isEmpty) return const <Widget>[];
    final autres = civicPlanAutresLabel(plan);
    return <Widget>[
      SfSection(
        title: kCivicPlanPrioritiesTitle,
        child: SfStack(
          children: [
            for (var i = 0; i < plan.priorites.length; i++)
              _priorityCard(plan.priorites[i], i + 1, free: free),
            if (autres != null)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: SfTiny(autres),
              ),
          ],
        ),
      ),
    ];
  }

  /// Une priorité.
  ///
  /// ⚠️ **Pas de sous-liste de compétences** : le serveur n'en sert aucune sur
  /// une cible civique (`20_` §4). On montre la maîtrise servie et la raison,
  /// jamais un sous-arbre fabriqué.
  Widget _priorityCard(CivicPlanCible cible, int rank, {required bool free}) {
    return SfPrio(
      rank: rank,
      tag: cible.themeLabel.isEmpty ? kCivicPlanPrioritiesTitle : cible.themeLabel,
      title: cible.label,
      text: cible.maitrise.label,
      child: free
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: 6),
              child: SfTiny(civicPlanRaison(cible)),
            ),
    );
  }

  List<Widget> _doneSection(CivicPlan plan) {
    if (plan.solides.isEmpty) return const <Widget>[];
    return <Widget>[
      SfSection(
        title: kCivicPlanDoneTitle,
        flush: true,
        child: SfCard(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final cible in plan.solides)
                SfCheckRow(label: civicPlanDoneRow(cible), large: true),
            ],
          ),
        ),
      ),
    ];
  }

  /// « À revoir bientôt ». 🛑 Jamais une alerte : ce sont des points acquis
  /// qu'on entretient — et **jamais** la boîte Leitner.
  List<Widget> _reviewSection(CivicPlan plan, DateTime maintenant) {
    if (plan.aRevoir.isEmpty) return const <Widget>[];
    return <Widget>[
      SfSection(
        title: kCivicPlanReviewTitle,
        child: SfStack(
          children: [
            for (final cible in plan.aRevoir)
              SfCard(
                variant: SfCardVariant.soft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SfLabel(kCivicPlanReviewPill),
                    const SizedBox(height: 4),
                    Text(
                      cible.label,
                      style: AppFonts.display(size: 15, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    SfTiny(civicPlanReviewText(cible, maintenant)),
                  ],
                ),
              ),
          ],
        ),
      ),
    ];
  }

  /// Le sélecteur de durée du Pass Civique. **Aucun prix** : il dit la durée,
  /// l'écran d'offre porte les tarifs du store et l'achat.
  Widget _passSection() {
    return SfSection(
      flush: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SfLabel(kCivicPassTitle),
          const SizedBox(height: 8),
          for (final duree in CivicPassDuree.values) ...[
            SfChoiceCard(
              label: duree.label,
              subtitle: kCivicPassSubtitle,
              selected: _duree == duree,
              onTap: () => setState(() => _duree = duree),
            ),
            const SizedBox(height: sfGap),
          ],
          const SfTiny(kCivicPassNote),
        ],
      ),
    );
  }

  /// 🛑 Aucune priorité est une BONNE nouvelle, pas un écran vide.
  Widget _nothingUrgent() {
    return SfSection(
      flush: true,
      child: SfNoteCard(
        icon: LucideIcons.circleCheck,
        title: kCivicPlanAllGoodTitle,
        variant: SfCardVariant.ok,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SfTiny(kCivicPlanAllGoodText),
            const SizedBox(height: 12),
            SfButton(
              label: kCivicPlanExamCta,
              variant: SfButtonVariant.blue,
              onPressed: () => context.push(AppRoutes.civiqueExamsBlanc),
            ),
          ],
        ),
      ),
    );
  }

  /// Le ton du kit correspondant au ton servi. `muted` n'a pas d'équivalent —
  /// les cibles non mesurées ne sont jamais rendues avec une couleur d'alerte,
  /// elles sont filtrées en amont.
  SfTone _tone(CivicCibleTone tone) => switch (tone) {
        CivicCibleTone.hot => SfTone.hot,
        CivicCibleTone.warn => SfTone.warn,
        CivicCibleTone.ok => SfTone.ok,
        CivicCibleTone.muted => SfTone.warn,
      };
}
