import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/models/diagnostic_models.dart';
import '../../../core/models/enums.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_tag.dart';
import '../../../core/widgets/blurred_content.dart';
import '../../../core/widgets/gradient_hero.dart';
import '../../../core/widgets/premium_lock.dart';
import '../../plan/learning_plan_provider.dart';
import '../../plan/plan_actions.dart';
import '../../plan/plan_labels.dart';
import '../../plan/plan_series_launcher.dart';
import '../../plan/widgets/plan_tokens.dart';
import '../diagnostic_variant.dart';
import 'diagnostic_report_labels.dart';

/// **Mon diagnostic** — le bilan in-app d'un candidat connecté.
///
/// L'écran répond à une seule question, et il y répond **épreuve par épreuve** :
/// *quel est mon niveau, et quelles compétences l'expliquent ?* D'où sa forme —
/// un résumé global, puis quatre cartes dépliables, une par épreuve.
///
/// Ordre figé, identique au web :
/// 1. le **résumé global** (niveau estimé, objectif, rail, les 4 colonnes) ;
/// 2. **Mes 4 épreuves**, dans l'ordre EE · EO · CE · CO ;
/// 3. la **prochaine étape** (abonné) ou la **carte d'offre** (compte gratuit) ;
/// 4. la mention d'estimation.
///
/// 🛑 **Chaque bloc rend une donnée que le serveur a réellement produite**, et
/// un bloc sans donnée n'est pas rendu — jamais de squelette, jamais de « non
/// disponible », jamais un compteur de maquette recopié.
///
/// 🛑 **On floute l'ACTION pas encore accessible, jamais le RÉSULTAT mesuré.**
/// Les niveaux, le rail, les quatre colonnes, la phrase qui explique chaque
/// niveau et la première compétence restent en clair pour tout le monde : ce
/// sont ses productions et ses mesures. Ce qu'un compte sans accès ne lit pas,
/// c'est la **suite** de la liste — derrière un rideau posé sur du **vrai**
/// contenu ([BlurredContent] : `ExcludeSemantics` + `IgnorePointer`), avec un
/// compteur **exact** servi par le serveur juste à côté, hors du flou.
class DiagnosticResultView extends ConsumerStatefulWidget {
  const DiagnosticResultView({
    super.key,
    required this.result,
    required this.hasTcfAccess,
    required this.variant,
    required this.onOpenPlan,
    required this.onSubscribe,
    this.objective,
  });

  final DiagnosticResult result;

  /// Le palier visé, déjà résolu pour l'écran (`TargetProcedure.niveauVise`,
  /// plancher de la démarche). `null` = pas encore choisi : on l'écrit, on
  /// n'invente pas de « B2 ».
  final String? objective;

  /// Ce que le candidat a choisi à l'entrée. **Rien n'est persisté** : elle ne
  /// sert plus qu'à dire la vérité à l'audience quand une épreuve de
  /// compréhension est lancée depuis ce bilan.
  final DiagnosticVariant variant;

  /// Accès TCF réel du compte (`AuthUser.hasTcf`). Il décide de ce qui est
  /// **flouté** ; aucune règle de verrou n'est recalculée ici — celui d'une
  /// compétence vient de `PlanDomainSkill.locked`, posé par le serveur.
  final bool hasTcfAccess;

  final VoidCallback onOpenPlan;
  final VoidCallback onSubscribe;

  @override
  ConsumerState<DiagnosticResultView> createState() =>
      _DiagnosticResultViewState();
}

/// **Les seuils d'affichage, déclarés UNE fois.**
///
/// Miroirs du web (`FREE_WORK_VISIBLE` / `FREE_SOLID_VISIBLE` /
/// `COLLAPSED_WORK_VISIBLE`) : ce sont des plafonds d'**affichage**, jamais des
/// règles d'accès — le verrou réel vit sur `PlanDomainSkill.locked`, posé par le
/// serveur.
const int _kFreeWorkVisible = 1;
const int _kFreeSolidVisible = 1;
const int _kCollapsedWorkVisible = 2;

class _DiagnosticResultViewState extends ConsumerState<DiagnosticResultView> {
  /// L'épreuve dépliée. `null` = tout replié, état légitime. L'écrit s'ouvre en
  /// premier : c'est la production que le candidat vient de rendre.
  EpreuveType? _open = EpreuveType.tcfEe;

  /// Une clé par carte, pour amener la bonne épreuve sous les yeux quand on
  /// touche sa colonne du résumé.
  final Map<EpreuveType, GlobalKey> _cards = {
    for (final epreuve in kDiagnosticEpreuveOrder) epreuve: GlobalKey(),
  };

  /// Ce que le rideau a déjà été vu couvrir, pour ne le compter qu'une fois
  /// par épreuve et par affichage de l'écran. En mémoire : rien de plus n'est
  /// écrit sur l'appareil pour ça.
  final Set<EpreuveType> _rideauCompte = <EpreuveType>{};
  bool _offreComptee = false;

  /// 🛑 Le rideau se mesure **là où il est rendu**, et une seule fois par
  /// épreuve : on veut savoir combien de fois il s'affiche, pas combien de fois
  /// Flutter reconstruit. Les deux compteurs sont ceux qui sont vraiment à
  /// l'écran — visibles en clair d'un côté, cachés de l'autre —, jamais une
  /// longueur de liste tronquée.
  void _compterRideau(_EpreuveView view) {
    final cache = view.fragileTotal + view.solidTotal - _visiblesEnClair(view);
    if (cache <= 0 || !_rideauCompte.add(view.epreuve)) return;
    ref.read(analyticsServiceProvider).track(
          AnalyticsEvent.planCurtainShown,
          path: AnalyticsPath.diagnostic,
          ctaLocation: AnalyticsCtaLocation.diagnosticReport,
          epreuve: view.epreuve.wire,
          visibleCount: _visiblesEnClair(view),
          totalCount: view.fragileTotal + view.solidTotal,
        );
  }

  /// Ce qu'un compte sans accès voit en clair sur une carte : une ligne à
  /// travailler, une ligne solide. Les seuils d'affichage vivent sur la carte
  /// (`_kFreeWorkVisible`, `_kFreeSolidVisible`) — on lit les mêmes, on n'en invente pas.
  static int _visiblesEnClair(_EpreuveView view) =>
      (view.work.isEmpty ? 0 : _kFreeWorkVisible) + (view.solid.isEmpty ? 0 : _kFreeSolidVisible);

  /// L'offre a été **vue** — ce n'est pas un clic. C'est l'écart entre les deux
  /// qui dira si le rideau donne envie ou décourage.
  void _compterOffre() {
    if (_offreComptee) return;
    _offreComptee = true;
    ref.read(analyticsServiceProvider).track(
          AnalyticsEvent.planPaywallViewed,
          path: AnalyticsPath.diagnostic,
          ctaLocation: AnalyticsCtaLocation.diagnosticReport,
        );
  }

  void _toggle(EpreuveType epreuve) {
    // Le geste mesuré est l'OUVERTURE : replier n'est pas vouloir voir.
    if (_open != epreuve) {
      ref.read(analyticsServiceProvider).track(
            AnalyticsEvent.planCurtainExpanded,
            path: AnalyticsPath.diagnostic,
            ctaLocation: AnalyticsCtaLocation.diagnosticReport,
            epreuve: epreuve.wire,
          );
    }
    setState(() => _open = _open == epreuve ? null : epreuve);
  }

  /// Déplie l'épreuve **et** l'amène à l'écran. Le défilement attend la frame
  /// suivante : la carte n'a sa hauteur dépliée qu'une fois reconstruite.
  void _focus(EpreuveType epreuve) {
    setState(() => _open = epreuve);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _cards[epreuve]?.currentContext;
      if (target == null) return;
      unawaited(
        Scrollable.ensureVisible(
          target,
          alignment: 0.05,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        ),
      );
    });
  }

  /// Le parcours d'achat de l'app — **le seul**. Le compteur d'audience est
  /// celui du rapport de diagnostic ; on n'en crée pas un second.
  void _subscribe() => widget.onSubscribe();

  /// Ouvre une compétence de la carte.
  ///
  /// 🛑 Le verrou est **lu** (`locked`, posé par le serveur), jamais déduit du
  /// rang de la ligne **ni de l'accès du compte** : `SkillAccessService` ouvre
  /// la compétence de la première place du Plan à un compte gratuit, et refuser
  /// ici sur `hasTcfAccess` fermait une porte que le serveur laisse ouverte —
  /// le web, lui, ne lisait déjà que `locked`. En **compréhension**, la
  /// compétence est un palier : on lance sa série ciblée, exactement comme la
  /// fiche du domaine. En **expression**, on ouvre sa fiche, où vivent ses
  /// petits sujets.
  void _openSkill(PlanDomainSkill skill, EpreuveType epreuve) {
    if (skill.locked) {
      _subscribe();
      return;
    }
    final section = skill.section ?? planDomainSection(epreuve);
    if (section == null) return;
    if (section.isComprehension) {
      unawaited(
        startTargetedSeries(
          context,
          ref,
          skillId: skill.skillId,
          masteryBefore: skill.masteryState,
        ),
      );
      return;
    }
    openPlanSkill(context, skill.skillId, section);
  }

  /// Lance la mesure d'une épreuve encore inconnue.
  ///
  /// ⚠️ L'événement d'audience n'existe que pour la **compréhension** : c'est
  /// le seul endroit de l'app où une CO/CE est lancée *depuis le diagnostic*,
  /// donc le seul où il soit vrai. Il porte la variante **réellement choisie**,
  /// jamais « complet » par défaut.
  void _assess(PlanDomainAssessment assessment) {
    final event = switch (assessment.epreuve) {
      EpreuveType.tcfCo => AnalyticsEvent.diagnosticCoStarted,
      EpreuveType.tcfCe => AnalyticsEvent.diagnosticCeStarted,
      _ => null,
    };
    if (event != null) {
      ref.read(analyticsServiceProvider).track(
            event,
            path: AnalyticsPath.diagnostic,
            diagnosticType: widget.variant.isComplet
                ? AnalyticsDiagnosticType.complete
                : AnalyticsDiagnosticType.rapid,
          );
    }
    openPlanAssessment(context, assessment);
  }

  @override
  Widget build(BuildContext context) {
    // Le Plan n'est lu qu'**ici**, sur le résultat d'un compte authentifié :
    // c'est la seule source des quatre domaines, de leurs compétences et de ce
    // qu'il reste à mesurer. Son absence — chargement, réseau — est un cas
    // NORMAL : les cartes retombent sur « à évaluer », rien n'est deviné.
    final plan = ref.watch(learningPlanProvider).valueOrNull;
    final cycle = plan?.cycle;

    // 🛑 **Sans Plan, aucune carte** — miroir du web. Écrire « cette épreuve
    // n'a pas encore été évaluée » pendant le chargement, ce serait affirmer un
    // fait que le serveur n'a pas servi : un bloc sans donnée n'est pas rendu.
    final epreuves = plan == null
        ? const <_EpreuveView>[]
        : [
            for (final epreuve in kDiagnosticEpreuveOrder)
              _EpreuveView.of(epreuve, plan: plan, result: widget.result),
          ];
    // 🛑 **La couverture se lit sur le CYCLE**, jamais sur la longueur d'une
    // liste : deux surfaces qui compteraient chacune de leur côté finiraient
    // par se contredire. Tant que le Plan n'a pas répondu, rien n'est complet.
    final evaluated = cycle?.domainsEvaluated ?? 0;
    final expected = cycle?.domainsExpected ?? kDiagnosticEpreuveOrder.length;
    final complete = cycle?.profileComplete ?? false;
    // Le compte de l'offre se lit sur le **compteur serveur** de chaque
    // domaine (`fragileSkillCount`), jamais sur une liste affichée.
    final detected = epreuves.fold<int>(0, (sum, e) => sum + e.fragileTotal);
    // 🛑 `SOLID` est un statut **servi** : on filtre dessus, on ne le déduit
    // pas. Un front qui classerait lui-même une observation en « point fort »
    // inventerait un verdict.
    final observees = diagnosticObservations(
      (widget.result.written?.skills ?? const [])
          .where((s) => s.status == LearningPlanSkillStatus.solid)
          .toList(growable: false),
      widget.result.priorities,
    );

    return SingleChildScrollView(
      // La liste tient en quatre cartes : elle est construite d'un bloc pour
      // que `Scrollable.ensureVisible` trouve toujours la carte visée depuis
      // les colonnes du résumé.
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GlobalCard(
            cycle: cycle,
            objective: widget.objective,
            epreuves: epreuves,
            evaluated: evaluated,
            expected: expected,
            complete: complete,
            open: _open,
            onSelect: _focus,
          ),
          // ------------- L3 : la transition, puis le diagnostic complet.
          // Rendus tant que les 4 épreuves ne sont pas mesurées — c'est
          // exactement l'état d'un diagnostic rapide. Profil complet, il n'y a
          // plus rien à relativiser ni à proposer.
          if (!complete) ...[
            const SizedBox(height: 20),
            const _TransitionCard(),
            const SizedBox(height: 14),
            const _DiagnosticCompletCard(),
          ],
          // --------------------------- ce que nous avons observé (bloc 2)
          // Trois lignes, une positive et deux à améliorer. Absent quand le
          // serveur n'a rien classé : un bloc vide ne se remplit pas.
          if (!complete && observees.isNotEmpty) ...[
            const SizedBox(height: 24),
            const _SectionHead(title: kDiagnosticObserveTitle),
            const SizedBox(height: 11),
            for (final observation in observees) ...[
              _ObservationCard(observation: observation),
              const SizedBox(height: 10),
            ],
          ],

          // 🛑 Les 4 épreuves n'apparaissent qu'une fois le profil COMPLET.
          // Après le diagnostic rapide, trois épreuves sur quatre n'ont pas été
          // mesurées : les afficher en « — » juste après avoir dit « ce n'est
          // qu'une première estimation » fait doublon, et transforme un rapport
          // de porte d'entrée en tableau de bord. Le niveau par épreuve est le
          // sujet du rapport du diagnostic COMPLET.
          if (complete && epreuves.isNotEmpty) ...[
            const SizedBox(height: 24),
            const _SectionHead(
              title: kDiagnosticEpreuvesTitle,
              text: kDiagnosticEpreuvesSub,
            ),
            const SizedBox(height: 11),
            for (final epreuve in epreuves) ...[
              if (!widget.hasTcfAccess) Builder(builder: (_) {
                _compterRideau(epreuve);
                return const SizedBox.shrink();
              }),
              _EpreuveCard(
                key: _cards[epreuve.epreuve],
                view: epreuve,
                objective: widget.objective,
                open: _open == epreuve.epreuve,
                hasAccess: widget.hasTcfAccess,
                onToggle: () => _toggle(epreuve.epreuve),
                onSkill: (skill) => _openSkill(skill, epreuve.epreuve),
                onAssess: _assess,
                onSubscribe: _subscribe,
              ),
              const SizedBox(height: 12),
            ],
          ],
          // 🛑 **Le paywall ne se joue PAS ici.** Sur le parcours voulu, le
          // rapport rapide mène au diagnostic complet, et c'est le rapport du
          // COMPLET qui met l'abonnement en avant — le candidat y a alors ses
          // quatre niveaux et ses priorités réelles sous les yeux.
          if (!complete) ...[
          ] else if (widget.hasTcfAccess) ...[
            const SizedBox(height: 8),
            const _SectionHead(title: kDiagnosticNextStepTitle),
            const SizedBox(height: 11),
            _NextStepCard(
              objective: widget.objective,
              onOpenPlan: widget.onOpenPlan,
            ),
          ] else ...[
            const SizedBox(height: 8),
            Builder(builder: (_) {
              _compterOffre();
              return const SizedBox.shrink();
            }),
            _UnlockCard(
              objective: widget.objective,
              detected: detected,
              onSubscribe: _subscribe,
            ),
          ],
          const SizedBox(height: 16),
          // 🛑 **Une seule mention en pied**, miroir du web : ce que vaut
          // l'estimation. Le sens d'un domaine non mesuré est déjà porté par le
          // héros (`diagnosticPartialText`) — le redire ici ferait deux
          // paragraphes pour une seule idée.
          const PlanNote(kDiagnosticEstimationNote),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lecture d'une épreuve
// ---------------------------------------------------------------------------

/// Les trois états d'une carte d'épreuve.
///
/// ⚠️ [incomplete] et [toAssess] ne disent **pas** la même chose : la première
/// est une production **rendue** dont il n'y avait rien à observer, la seconde
/// une épreuve **jamais passée**. Deux phrases, deux gestes.
enum _EpreuveState { ok, toAssess, incomplete }

/// Comment une compétence se range sur la carte.
///
/// 🛑 **La nature passe avant le statut** : une compétence *à acquérir* n'a
/// aucun verdict (rien n'a été observé dessus), donc son `status` vaut
/// `NOT_OBSERVED` — la classer dessus l'aurait rangée parmi les absences de
/// mesure, alors que c'est précisément ce que le Plan va enseigner.
enum _SkillGroup { priority, reinforce, acquire, solid, notObserved }

extension _SkillGroupStyle on _SkillGroup {
  String get label => switch (this) {
        _SkillGroup.priority => kDiagnosticGroupPriority,
        _SkillGroup.reinforce => kDiagnosticGroupReinforce,
        _SkillGroup.acquire => kDiagnosticGroupAcquire,
        _SkillGroup.solid => kDiagnosticGroupSolid,
        _SkillGroup.notObserved => LearningPlanSkillStatus.notObserved.label,
      };

  /// ⚠️ **Aucune teinte nouvelle** : chacune est déjà celle de l'état qu'elle
  /// nomme ailleurs dans l'app (statut de compétence, nature d'action, état de
  /// maîtrise). Un même état ne change pas de couleur d'un écran à l'autre.
  Color get color => switch (this) {
        _SkillGroup.priority => AppColors.red,
        _SkillGroup.reinforce => AppColors.amberDark,
        _SkillGroup.acquire => AppColors.blue,
        _SkillGroup.solid => AppColors.green,
        _SkillGroup.notObserved => AppColors.inkFaint,
      };

  TagTone get tone => switch (this) {
        _SkillGroup.priority => TagTone.red,
        _SkillGroup.reinforce => TagTone.amber,
        _SkillGroup.acquire => TagTone.blue,
        _SkillGroup.solid => TagTone.success,
        _SkillGroup.notObserved => TagTone.ghost,
      };
}

_SkillGroup _groupOf(PlanDomainSkill skill) {
  if (skill.nature == PlanActionNature.aAcquerir) return _SkillGroup.acquire;
  return switch (skill.status) {
    LearningPlanSkillStatus.priority => _SkillGroup.priority,
    LearningPlanSkillStatus.toReinforce => _SkillGroup.reinforce,
    LearningPlanSkillStatus.solid => _SkillGroup.solid,
    LearningPlanSkillStatus.notObserved => _SkillGroup.notObserved,
  };
}

/// Une compétence, telle que la carte la rend : son groupe, et rien d'autre en
/// plus de ce que le serveur a servi.
class _SkillLine {
  const _SkillLine(this.skill, this.group);

  final PlanDomainSkill skill;
  final _SkillGroup group;
}

/// **Tout ce qu'une carte d'épreuve a besoin de savoir**, lu une seule fois.
///
/// 🛑 Les compteurs `fragileTotal` / `solidTotal` viennent du **serveur**
/// (`PlanDomain.fragileSkillCount` / `.solidSkillCount`) : ce sont eux qui
/// rendent le « + N autres » vrai. On ne les recompte jamais depuis une liste
/// tronquée à l'affichage.
class _EpreuveView {
  const _EpreuveView({
    required this.epreuve,
    required this.state,
    required this.work,
    required this.solid,
    required this.notObserved,
    required this.fragileTotal,
    required this.solidTotal,
    this.domain,
    this.assessment,
    this.level,
    this.nextLevel,
    this.resume,
    this.explanation,
  });

  final EpreuveType epreuve;
  final _EpreuveState state;
  final PlanDomain? domain;

  /// La mesure que le serveur désigne pour cette épreuve. `null` = il n'en
  /// propose aucune : on n'invente alors aucun parcours, et la carte n'affiche
  /// pas de bouton.
  final PlanDomainAssessment? assessment;

  final NiveauCecrl? level;
  final TargetLevel? nextLevel;
  final String? resume;
  final String? explanation;

  /// Ce qu'il y a à faire, dans l'ordre des groupes : priorités, puis
  /// fragilités, puis acquisitions. **Jamais tronquée ici** — c'est l'appelant
  /// qui tranche ce qu'il affiche, sinon le compteur serait faux par
  /// construction.
  final List<_SkillLine> work;
  final List<_SkillLine> solid;

  /// Les compétences **jamais observées**, acquisitions exclues : celles-ci
  /// sont déjà rendues plus haut sous « À acquérir », et les compter deux fois
  /// dirait qu'une même compétence est à la fois à apprendre et sans données.
  final int notObserved;

  final int fragileTotal;
  final int solidTotal;

  static _EpreuveView of(
    EpreuveType epreuve, {
    required LearningPlan? plan,
    required DiagnosticResult result,
  }) {
    final domain =
        plan?.domaines.where((d) => d.epreuve == epreuve).firstOrNull;
    final assessment =
        plan?.domainesAEvaluer.where((a) => a.epreuve == epreuve).firstOrNull;

    // 🛑 **L'ORDRE DES TESTS COMPTE, et c'est la MESURE qui passe en premier.**
    // Un domaine réellement mesuré rend son niveau, quoi qu'il soit arrivé à la
    // production du diagnostic : *une production inexploitable ne produit aucun
    // niveau, mais elle n'efface pas un niveau obtenu par ailleurs* (une EE
    // ratée puis une vraie mesure). Tester « non exploitable » d'abord — ce que
    // fait la maquette, qui n'a pas de serveur — figeait cette épreuve sur
    // « évaluation incomplète » à vie.
    if (domain != null && domain.evaluated && domain.niveau != null) {
      return _EpreuveView.mesuree(epreuve, domain, assessment);
    }

    // Sans mesure : « rendue, rien à observer » ≠ « jamais passée ». Deux
    // phrases, deux gestes — et seule la valeur `NON_EVALUABLE` **explicite**
    // se lit ainsi, l'absence du bloc voulant dire « pas encore analysée ».
    final production = switch (epreuve) {
      EpreuveType.tcfEe => result.written,
      EpreuveType.tcfEo => result.oral,
      _ => null,
    };
    return _EpreuveView(
      epreuve: epreuve,
      state: (production?.estNonEvaluable ?? false)
          ? _EpreuveState.incomplete
          : _EpreuveState.toAssess,
      domain: domain,
      assessment: assessment,
      work: const <_SkillLine>[],
      solid: const <_SkillLine>[],
      notObserved: 0,
      fragileTotal: 0,
      solidTotal: 0,
    );
  }

  /// L'épreuve **mesurée** : ses compétences, rangées par groupe, et les
  /// compteurs **servis** qui rendent le « + N autres » vrai.
  static _EpreuveView mesuree(
    EpreuveType epreuve,
    PlanDomain domain,
    PlanDomainAssessment? assessment,
  ) {
    // 🛑 L'ordre **dans** un groupe est celui du serveur : on n'ordonne que les
    // groupes entre eux, et cet ordre est celui de `PlanActionNature` (réparer
    // ce qui est fragile avant d'apprendre ce qui vient).
    final lines = [
      for (final skill in domain.skills) _SkillLine(skill, _groupOf(skill)),
    ];
    final work = <_SkillLine>[
      ...lines.where((l) => l.group == _SkillGroup.priority),
      ...lines.where((l) => l.group == _SkillGroup.reinforce),
      ...lines.where((l) => l.group == _SkillGroup.acquire),
    ];
    final solid =
        lines.where((l) => l.group == _SkillGroup.solid).toList(growable: false);
    final observed = domain.fragileSkillCount + domain.solidSkillCount;

    return _EpreuveView(
      epreuve: epreuve,
      state: _EpreuveState.ok,
      domain: domain,
      assessment: assessment,
      level: domain.niveau,
      // 🛑 SERVI, plus dérivé du niveau : la copie locale ignorait l'objectif
      // du candidat, et un candidat B1 visant le B1 lisait « prochain palier
      // B2 ». Supprimée le 2026-08-26.
      nextLevel: domain.nextTargetLevel,
      resume: diagnosticEpreuveResume(epreuve, domain.niveau),
      explanation: diagnosticEpreuveExplanation(
        domain,
        observed: observed,
        fragile: domain.fragileSkillCount,
        solid: domain.solidSkillCount,
      ),
      work: List.unmodifiable(work),
      solid: solid,
      // 🛑 SERVI aussi : ce compte excluait les acquisitions ici pendant que le
      // serveur les incluait dans `notObservedSkillCount` — deux nombres pour
      // la même épreuve. Le serveur en publie désormais deux, nommés.
      notObserved: domain.notObservedWithoutActionCount,
      fragileTotal: domain.fragileSkillCount,
      solidTotal: domain.solidSkillCount,
    );
  }
}

// ---------------------------------------------------------------------------
// 1 — le résumé global
// ---------------------------------------------------------------------------

/// Le bandeau qui situe le candidat : **niveau estimé** en très grand,
/// objectif sur la même ligne, couverture du profil, rail des paliers — puis,
/// dans la même carte, une colonne par épreuve.
///
/// 🛑 **Le niveau global vient du SERVEUR** (`cycle.startingLevel`, plancher des
/// quatre domaines calculé par `TcfProfileService`) : aucun front ne le rejoue
/// à partir des deux estimations de production, sinon deux surfaces
/// annonceraient deux paliers pour le même candidat. `null` ⇒ « — », jamais un
/// palier deviné.
class _GlobalCard extends StatelessWidget {
  const _GlobalCard({
    required this.cycle,
    required this.objective,
    required this.epreuves,
    required this.evaluated,
    required this.expected,
    required this.complete,
    required this.open,
    required this.onSelect,
  });

  final PlanCycle? cycle;
  final String? objective;
  final List<_EpreuveView> epreuves;
  final int evaluated;
  final int expected;
  final bool complete;
  final EpreuveType? open;
  final ValueChanged<EpreuveType> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppRadii.xl),
        boxShadow: AppShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GradientHero(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 17),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadii.xl),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // 🛑 « sur cet exercice » tant que les 4 épreuves ne sont
                  // pas mesurées (`10_` §3.1, wording imposé) : le candidat ne
                  // connaît pas encore son niveau TCF.
                  (complete
                          ? kDiagnosticLevelEyebrow
                          : kDiagnosticLevelEyebrowExercice)
                      .toUpperCase(),
                  style: AppFonts.eyebrow(
                    color: AppColors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 6),
                // Niveau et objectif sur **une seule ligne**, alignés par le
                // bas : « où j'en suis, où je vais » se lit d'un seul
                // mouvement.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        cycle?.startingLevel?.shortName ?? '—',
                        style: AppFonts.display(
                          size: 44,
                          height: 1.05,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '$kDiagnosticLevelObjective '
                          '${objective ?? kDiagnosticLevelObjectiveUnknown}',
                          style: AppFonts.ui(
                            size: 14,
                            weight: FontWeight.w600,
                            color: AppColors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                _CoveragePill(
                  complete: complete,
                  evaluated: evaluated,
                  expected: expected,
                ),
                if (!complete) ...[
                  const SizedBox(height: 11),
                  Text(
                    diagnosticPartialText(evaluated, expected),
                    style: AppFonts.ui(
                      size: 13,
                      height: 1.5,
                      color: AppColors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
                if (cycle != null) ...[
                  const SizedBox(height: 15),
                  // Le rail du Plan, repris tel quel : le candidat doit
                  // retrouver **la même** échelle d'un écran à l'autre, et le
                  // palier allumé est celui que son cycle construit — jamais
                  // une valeur redérivée ici.
                  PlanLevelRail(current: cycle!.targetLevel, onDark: true),
                ],
              ],
            ),
          ),
          // 🛑 `IntrinsicHeight` n'est pas décoratif : les quatre colonnes se
          // veulent d'égale hauteur — c'est ce qui fait courir le trait de
          // séparation d'un bord à l'autre — et `CrossAxisAlignment.stretch`
          // seul demande une hauteur **tendue sur la contrainte reçue**. Ici
          // elle est infinie (la carte vit dans un `SingleChildScrollView`),
          // donc la `Row` posait `h=Infinity` à ses colonnes : erreur de
          // layout, sous-arbre laissé `NEEDS-LAYOUT`, et plus aucune frame
          // envoyée au moteur. Il faut donc **borner** la hauteur avant de la
          // tendre. Coût négligeable : quatre colonnes d'une ligne chacune.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < epreuves.length; i++)
                  Expanded(
                    child: _DomainColumn(
                      view: epreuves[i],
                      first: i == 0,
                      active: open == epreuves[i].epreuve,
                      onTap: () => onSelect(epreuves[i].epreuve),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoveragePill extends StatelessWidget {
  const _CoveragePill({
    required this.complete,
    required this.evaluated,
    required this.expected,
  });

  final bool complete;
  final int evaluated;
  final int expected;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.fromLTRB(11, 5, 11, 5),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              complete ? LucideIcons.check : LucideIcons.chartColumn,
              size: 14,
              color: AppColors.white,
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                complete
                    ? kDiagnosticProfileComplete
                    : diagnosticEvaluatedCount(evaluated, expected),
                style: AppFonts.ui(
                  size: 12.5,
                  weight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Une des quatre colonnes du pied du résumé : le niveau de l'épreuve, ou
/// « — » quand il n'y en a pas. Un tap déplie sa carte et l'amène à l'écran.
///
/// ⚠️ **Toutes les colonnes sont tappables**, y compris celles sans niveau : la
/// maquette les rend inertes parce qu'un curseur le signale, ce qu'un doigt
/// n'a pas. Une épreuve à mesurer est justement celle qu'on veut atteindre.
class _DomainColumn extends StatelessWidget {
  const _DomainColumn({
    required this.view,
    required this.first,
    required this.active,
    required this.onTap,
  });

  final _EpreuveView view;
  final bool first;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final level = view.state == _EpreuveState.ok ? view.level : null;
    return Semantics(
      button: true,
      label: '${planDomainLabel(view.epreuve)} · '
          '${level?.displayName ?? kDiagnosticToAssessTag}',
      child: Material(
        color: active ? AppColors.surface2 : AppColors.white,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(4, 11, 4, 10),
            decoration: BoxDecoration(
              border: Border(
                top: const BorderSide(color: AppColors.lineSoft),
                left: first
                    ? BorderSide.none
                    : const BorderSide(color: AppColors.lineSoft),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  child: Text(
                    level?.shortName ?? '—',
                    style: AppFonts.display(
                      size: 16,
                      color: level == null ? AppColors.inkFaint : AppColors.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  planDomainShort(view.epreuve),
                  style: AppFonts.ui(
                    size: 10.5,
                    weight: FontWeight.w700,
                    color: AppColors.inkFaint,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2 — une carte par épreuve
// ---------------------------------------------------------------------------

/// **La carte d'une épreuve** : son niveau, la phrase qui l'explique, et les
/// compétences qui l'ont produit.
///
/// Trois formes, décidées par [_EpreuveState] et rien d'autre — jamais par la
/// nullité d'un champ.
class _EpreuveCard extends StatelessWidget {
  const _EpreuveCard({
    super.key,
    required this.view,
    required this.objective,
    required this.open,
    required this.hasAccess,
    required this.onToggle,
    required this.onSkill,
    required this.onAssess,
    required this.onSubscribe,
  });

  final _EpreuveView view;
  final String? objective;
  final bool open;
  final bool hasAccess;
  final VoidCallback onToggle;
  final ValueChanged<PlanDomainSkill> onSkill;
  final ValueChanged<PlanDomainAssessment> onAssess;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    if (view.state != _EpreuveState.ok) return _buildPending(context);
    return _buildOk(context);
  }

  // ---- épreuve jamais mesurée, ou production inexploitable ----------------

  Widget _buildPending(BuildContext context) {
    final empty = view.state == _EpreuveState.toAssess;
    final assessment = view.assessment;
    final label = planDomainLabel(view.epreuve);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 13),
            child: Row(
              children: [
                PlanDomainTile(epreuve: view.epreuve, size: 40),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppFonts.display(size: 17, height: 1.2),
                      ),
                      const SizedBox(height: 6),
                      AppTag(
                        label: empty
                            ? kDiagnosticToAssessTag
                            : kDiagnosticIncompleteTag,
                        tone: empty ? TagTone.ghost : TagTone.red,
                        compact: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '—',
                  style: AppFonts.display(
                    size: 26,
                    color: AppColors.inkFaint,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  empty
                      ? diagnosticToAssessText(view.epreuve)
                      : kDiagnosticIncompleteText,
                  style: AppFonts.ui(
                    size: 13.5,
                    height: 1.55,
                    color: AppColors.inkSoft,
                  ),
                ),
                // 🛑 Sans mesure servie, **aucun bouton** : le serveur ne
                // désigne pas de parcours pour cette épreuve, et on n'en
                // invente pas.
                if (assessment != null) ...[
                  const SizedBox(height: 13),
                  AppButton(
                    label: empty
                        ? diagnosticAssessCta(view.epreuve)
                        : diagnosticRedoCta(view.epreuve),
                    variant: AppButtonVariant.outline,
                    height: 46,
                    icon: empty ? LucideIcons.play : LucideIcons.refreshCw,
                    onPressed: () => onAssess(assessment),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- épreuve mesurée ----------------------------------------------------

  Widget _buildOk(BuildContext context) {
    // Ce qui est montré en clair. Un compte sans accès en voit **un** de chaque
    // famille : sa mesure lui appartient, la suite de la liste est ce qui se
    // débloque.
    final visibleWork = hasAccess
        ? (open
            ? view.work
            : view.work.take(_kCollapsedWorkVisible).toList(growable: false))
        : view.work.take(_kFreeWorkVisible).toList(growable: false);
    final visibleSolid = hasAccess
        ? view.solid
        : view.solid.take(_kFreeSolidVisible).toList(growable: false);
    final moreWork = view.work.length - visibleWork.length;

    // 🛑 Le compteur du verrou se lit sur les **compteurs serveur** du domaine,
    // jamais sur la longueur d'une liste tronquée ici.
    final shownFragile = visibleWork
        .where((l) =>
            l.group == _SkillGroup.priority || l.group == _SkillGroup.reinforce)
        .length;
    final hiddenWork = (view.fragileTotal - shownFragile).clamp(0, 999);
    final hiddenSolid = (view.solidTotal - visibleSolid.length).clamp(0, 999);
    final hiddenLabel = hasAccess
        ? null
        : diagnosticHiddenCount(work: hiddenWork, solid: hiddenSolid);

    final explanation = view.explanation;
    final resume = view.resume;
    final cta = view.work.isEmpty ? null : view.work.first;

    return AppCard(
      padding: EdgeInsets.zero,
      border: Border.all(color: open ? AppColors.blue : AppColors.line),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(),
          if (resume != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(
                resume,
                style: AppFonts.ui(
                  size: 13.5,
                  height: 1.55,
                  color: AppColors.inkSoft,
                ),
              ),
            ),
          if (open && explanation != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: const BoxDecoration(
                color: AppColors.blueLight,
                borderRadius: BorderRadius.all(Radius.circular(AppRadii.md)),
                border: Border(
                  left: BorderSide(color: AppColors.blue, width: 3),
                ),
              ),
              child: Text(
                explanation,
                style: AppFonts.ui(
                  size: 13.5,
                  height: 1.55,
                  color: AppColors.blueDark,
                ),
              ),
            ),
          if (view.work.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 13, 16, 6),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.lineSoft)),
              ),
              child: open && hasAccess
                  ? _groupedWork()
                  : _flatWork(visibleWork, moreWork),
            ),
          if (visibleSolid.isNotEmpty && (open || !hasAccess))
            Container(
              padding: const EdgeInsets.fromLTRB(16, 13, 16, 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.lineSoft)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _GroupHead(
                    label: kDiagnosticGroupSolid,
                    // Le compteur **servi** du domaine, jamais la longueur de
                    // la liste affichée.
                    count: hasAccess && view.solidTotal > 1
                        ? '${view.solidTotal}'
                        : null,
                  ),
                  // 🛑 Ouvrable **pour tout le monde** : le verrou est celui du
                  // serveur (`locked`), lu par `_openSkill`, jamais l'accès du
                  // compte — miroir du web.
                  for (final line in visibleSolid)
                    _SkillRow(line: line, onTap: () => onSkill(line.skill)),
                ],
              ),
            ),
          if (hiddenLabel != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: _LockedPreview(
                title: _blurredTitle(visibleWork.length, visibleSolid.length),
                count: hiddenLabel,
                onSubscribe: onSubscribe,
              ),
            ),
          if (open && hasAccess && (view.notObserved > 0 || cta != null))
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 15),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.lineSoft)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (view.notObserved > 0) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTag(
                          label: _SkillGroup.notObserved.label,
                          tone: _SkillGroup.notObserved.tone,
                          compact: true,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            diagnosticNotObserved(view.notObserved),
                            style: AppFonts.ui(
                              size: 12.5,
                              height: 1.45,
                              color: AppColors.inkFaint,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (cta != null)
                    AppButton(
                      label: view.epreuve.isProduction
                          ? kDiagnosticWorkPrioritiesCta
                          : diagnosticWorkDomainCta(view.epreuve),
                      height: 48,
                      icon: view.epreuve.isProduction
                          ? LucideIcons.target
                          : LucideIcons.play,
                      onPressed: () => onSkill(cta.skill),
                    ),
                ],
              ),
            ),
          _footer(),
        ],
      ),
    );
  }

  Widget _header() => Semantics(
        button: true,
        label: '${planDomainLabel(view.epreuve)} · '
            '${view.level?.displayName ?? ''}',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 15, 16, 13),
              child: Row(
                children: [
                  PlanDomainTile(
                    epreuve: view.epreuve,
                    size: 40,
                    filled: open,
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          planDomainLabel(view.epreuve),
                          style: AppFonts.display(size: 17, height: 1.2),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          diagnosticEpreuveMeta(objective, view.nextLevel),
                          style: AppFonts.ui(
                            size: 12.5,
                            height: 1.35,
                            color: AppColors.inkFaint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        view.level?.shortName ?? '—',
                        style: AppFonts.display(size: 30, height: 1),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        kDiagnosticEstimatedLabel.toUpperCase(),
                        style: AppFonts.label(size: 10.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  /// Les trois familles, séparées et titrées — la lecture d'un abonné qui a
  /// déplié sa carte.
  Widget _groupedWork() {
    const groups = [
      _SkillGroup.priority,
      _SkillGroup.reinforce,
      _SkillGroup.acquire,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final group in groups)
          if (view.work.any((l) => l.group == group)) ...[
            _GroupHead(
              label: group.label,
              count: view.work.where((l) => l.group == group).length > 1
                  ? '${view.work.where((l) => l.group == group).length}'
                  : null,
              note: group == _SkillGroup.acquire
                  ? diagnosticAcquireNote(view.nextLevel)
                  : null,
            ),
            for (final line in view.work.where((l) => l.group == group))
              _SkillRow(line: line, onTap: () => onSkill(line.skill)),
            const SizedBox(height: 6),
          ],
      ],
    );
  }

  /// La lecture **repliée**, et celle d'un compte sans accès : une seule
  /// section, une pastille par ligne.
  Widget _flatWork(List<_SkillLine> visible, int more) {
    final first = view.work.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GroupHead(
          label: hasAccess
              ? kDiagnosticGroupWork
              : (first.group == _SkillGroup.priority
                  ? kDiagnosticGroupMainWork
                  : kDiagnosticGroupFirstWork),
          count: hasAccess
              ? null
              : diagnosticFreeWorkCount(visible.length, view.work.length),
        ),
        for (final line in visible)
          _SkillRow(
            line: line,
            pill: true,
            onTap: () => onSkill(line.skill),
          ),
        if (hasAccess && more > 0)
          Semantics(
            button: true,
            label: diagnosticMoreToWork(more),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onToggle,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 10),
                  child: Text(
                    diagnosticMoreToWork(more),
                    style: AppFonts.ui(
                      size: 13,
                      weight: FontWeight.w700,
                      color: AppColors.blue,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Le **vrai** libellé de la compétence suivante — celle que le rideau laisse
  /// deviner. Le repli n'affirme rien : il ne nomme aucune compétence.
  String _blurredTitle(int shownWork, int shownSolid) {
    if (view.work.length > shownWork) return view.work[shownWork].skill.title;
    if (view.solid.length > shownSolid) {
      return view.solid[shownSolid].skill.title;
    }
    return kDiagnosticLockedFallback;
  }

  Widget _footer() => Semantics(
        button: true,
        label: open ? kDiagnosticCollapse : kDiagnosticExpand,
        child: Material(
          color: AppColors.surface2,
          child: InkWell(
            onTap: onToggle,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.lineSoft)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      open ? kDiagnosticCollapse : kDiagnosticExpand,
                      style: AppFonts.ui(
                        size: 13,
                        weight: FontWeight.w700,
                        color: open ? AppColors.inkSoft : AppColors.blue,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      LucideIcons.chevronDown,
                      size: 16,
                      color: AppColors.inkFaint,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

/// L'en-tête d'une famille de compétences : son nom, son compte, et — pour les
/// acquisitions — ce qu'elle veut dire.
class _GroupHead extends StatelessWidget {
  const _GroupHead({required this.label, this.count, this.note});

  final String label;

  /// `null` = un seul élément, ou rien à compter : on n'affiche pas « 1 ».
  final String? count;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final sub = note;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  style: AppFonts.label(size: 11),
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 7),
                Text(
                  count!,
                  style: AppFonts.label(
                    size: 11,
                    color: AppColors.inkFaint.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
          if (sub != null) ...[
            const SizedBox(height: 3),
            Text(
              sub,
              style: AppFonts.ui(
                size: 12,
                height: 1.45,
                color: AppColors.inkFaint,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Une compétence : sa puce, son titre, son repère, et le chevron quand elle
/// ouvre quelque chose.
///
/// 🛑 **Une compétence solide se lit autrement** : une coche pleine au lieu
/// d'une puce, et un titre moins gras — elle n'appelle aucune action, elle
/// constate un acquis.
class _SkillRow extends StatelessWidget {
  const _SkillRow({required this.line, this.pill = false, this.onTap});

  final _SkillLine line;

  /// Affiche la pastille du groupe à droite du titre : elle n'a de sens que
  /// dans la vue **repliée**, où les familles ne sont pas séparées.
  final bool pill;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final solid = line.group == _SkillGroup.solid;
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          if (solid)
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.greenLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.check,
                size: 12,
                color: AppColors.green,
              ),
            )
          else
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 7),
              decoration: BoxDecoration(
                color: line.group == _SkillGroup.priority
                    ? line.group.color
                    : line.group.color.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.skill.title,
                  style: AppFonts.ui(
                    size: 14.5,
                    weight: solid ? FontWeight.w500 : FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  diagnosticSkillSubtitle(line.skill),
                  style: AppFonts.ui(size: 11.5, color: AppColors.inkFaint),
                ),
              ],
            ),
          ),
          if (pill && !solid) ...[
            const SizedBox(width: 8),
            AppTag(
              label: line.group.label,
              tone: line.group.tone,
              compact: true,
            ),
          ],
          if (onTap != null) ...[
            const SizedBox(width: 4),
            const Icon(
              LucideIcons.chevronRight,
              size: 14,
              color: AppColors.inkFaint,
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return row;
    return Semantics(
      button: true,
      label: '${line.skill.title} · ${diagnosticSkillSubtitle(line.skill)} · '
          '${line.group.label}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, child: row),
      ),
    );
  }
}

/// **Un seul verrou par épreuve** : le vrai libellé de la compétence suivante,
/// flouté, et le compte exact de ce qui reste — lisible, lui, parce qu'il n'est
/// pas dans le rideau.
///
/// 🛑 Rien n'est fabriqué derrière le flou : la ligne vient du serveur. Le
/// rideau ([BlurredContent]) est `ExcludeSemantics` + `IgnorePointer` — ce qui
/// est illisible à l'œil doit l'être aussi au lecteur d'écran. Le geste, lui,
/// est porté par la ligne entière et mène au **seul** parcours d'achat de
/// l'app.
class _LockedPreview extends StatelessWidget {
  const _LockedPreview({
    required this.title,
    required this.count,
    required this.onSubscribe,
  });

  final String title;
  final String count;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$count · $kDiagnosticUnlockShort',
      child: Material(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          onTap: onSubscribe,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Container(
            padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.lock,
                  size: 15,
                  color: AppColors.inkFaint,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BlurredContent(
                        sigma: 4,
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.ui(
                            size: 13.5,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        count,
                        style: AppFonts.ui(
                          size: 12.5,
                          weight: FontWeight.w700,
                          height: 1.35,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  kDiagnosticUnlockShort,
                  style: AppFonts.ui(
                    size: 12.5,
                    weight: FontWeight.w700,
                    color: AppColors.blue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3 — la suite : le plan, ou l'offre
// ---------------------------------------------------------------------------

/// Ce que le rapport enchaîne pour un abonné : son plan, qui traite ces
/// priorités une par une.
class _NextStepCard extends StatelessWidget {
  const _NextStepCard({required this.objective, required this.onOpenPlan});

  final String? objective;
  final VoidCallback onOpenPlan;

  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              diagnosticNextStepText(objective),
              style: AppFonts.ui(
                size: 14,
                height: 1.55,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 13),
            AppButton(
              label: kDiagnosticWorkPrioritiesCta,
              iconRight: LucideIcons.arrowRight,
              onPressed: onOpenPlan,
            ),
            const SizedBox(height: 4),
            AppButton(
              label: kDiagnosticAllSkillsCta,
              variant: AppButtonVariant.ghost,
              height: 44,
              onPressed: () => context.push(AppRoutes.planSkills),
            ),
          ],
        ),
      );
}

/// L'offre ferme le rapport : le candidat a d'abord lu **son** niveau sur les
/// quatre épreuves, et vu **sa** première priorité sur chacune.
///
/// 🛑 Le premier argument porte un **vrai** nombre, celui que le serveur a
/// compté ; à zéro, il n'est pas rendu. Aucun prix, aucun verbe d'achat
/// (guidelines Apple 3.1.1) : les deux gestes mènent au même écran d'offre.
class _UnlockCard extends StatelessWidget {
  const _UnlockCard({
    required this.objective,
    required this.detected,
    required this.onSubscribe,
  });

  final String? objective;
  final int detected;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppRadii.xl),
        boxShadow: AppShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GradientHero(
            padding: const EdgeInsets.fromLTRB(18, 17, 18, 16),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadii.xl),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kDiagnosticUnlockTitle,
                  style: AppFonts.display(
                    size: 20,
                    height: 1.15,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  diagnosticUnlockText(objective),
                  style: AppFonts.ui(
                    size: 13.5,
                    height: 1.55,
                    color: AppColors.white.withValues(alpha: 0.92),
                  ),
                ),
                const SizedBox(height: 13),
                PremiumBenefitList(
                  benefits: diagnosticUnlockBenefits(detected),
                  checkColor: AppColors.greenBright,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppButton(
                  label: kDiagnosticUnlockCta,
                  iconRight: LucideIcons.arrowRight,
                  height: 48,
                  onPressed: onSubscribe,
                ),
                const SizedBox(height: 4),
                AppButton(
                  label: kPlanPaywallFormulas,
                  variant: AppButtonVariant.ghost,
                  height: 44,
                  onPressed: onSubscribe,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Titres de section
// ---------------------------------------------------------------------------

/// Le titre d'une section — **une ligne, rien d'autre** (deux avec son
/// sous-titre). Les en-têtes à trois étages sont ce qui avait alourdi cet écran
/// passe après passe.
class _SectionHead extends StatelessWidget {
  const _SectionHead({required this.title, this.text});

  final String title;
  final String? text;

  @override
  Widget build(BuildContext context) {
    final sub = text;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppFonts.display(size: 19, height: 1.15)),
          if (sub != null) ...[
            const SizedBox(height: 4),
            Text(
              sub,
              style: AppFonts.ui(
                size: 12.5,
                height: 1.45,
                color: AppColors.inkSoft,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bloc 3 de `10_` §3.6 — la mise en perspective.
///
/// 🛑 **Fond distinct, et c'est voulu** : ce bloc contredit partiellement ce
/// que le candidat vient de lire. Il ne doit pas se confondre avec un
/// paragraphe de plus.
class _TransitionCard extends StatelessWidget {
  const _TransitionCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.blueLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kDiagnosticTransitionTitle,
            style: AppFonts.display(size: 18, color: AppColors.blueDark),
          ),
          const SizedBox(height: 8),
          Text(
            kDiagnosticTransitionText,
            style: AppFonts.ui(size: 14, color: AppColors.ink, height: 1.5),
          ),
          const SizedBox(height: 10),
          Text(
            kDiagnosticTransitionEmphasis,
            style: AppFonts.ui(
              size: 14,
              weight: FontWeight.w600,
              color: AppColors.blueDark,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bloc 4 de `10_` §3.6 — le diagnostic TCF complet, qui existe depuis L4.
class _DiagnosticCompletCard extends ConsumerWidget {
  const _DiagnosticCompletCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kDiagnosticCompletTitle,
            style: AppFonts.display(size: 19, color: AppColors.ink),
          ),
          const SizedBox(height: 12),
          for (final e in kDiagnosticCompletEpreuves)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Text(e.icon, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  Text(
                    e.label,
                    style: AppFonts.ui(size: 14, color: AppColors.ink),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Text(
            kDiagnosticCompletPromise,
            style: AppFonts.ui(size: 14, color: AppColors.ink),
          ),
          const SizedBox(height: 6),
          for (final benefit in kDiagnosticCompletBenefits)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(LucideIcons.check, size: 15, color: AppColors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      benefit,
                      style: AppFonts.ui(size: 13.5, color: AppColors.muted),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          AppButton(
            label: kDiagnosticCompletCta,
            onPressed: () => context.push(AppRoutes.tcfDiagnostic),
          ),
          const SizedBox(height: 8),
          Text(
            kDiagnosticCompletNote,
            style: AppFonts.ui(size: 12, color: AppColors.inkFaint),
          ),
        ],
      ),
    );
  }
}

/// Une ligne de « Ce que nous avons observé ».
///
/// La pastille porte la couleur, le texte reste noir — c'est un constat, pas
/// une alerte.
class _ObservationCard extends StatelessWidget {
  const _ObservationCard({required this.observation});

  final DiagnosticObservation observation;

  @override
  Widget build(BuildContext context) {
    final ok = observation.ton == DiagnosticObservationTone.ok;
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: ok ? AppColors.greenLight : AppColors.amberLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              ok ? LucideIcons.check : LucideIcons.arrowUp,
              size: 15,
              color: ok ? AppColors.green : AppColors.amber,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  observation.kicker.toUpperCase(),
                  style: AppFonts.label(
                    size: 10.5,
                    color: ok ? AppColors.green : AppColors.amber,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  observation.titre,
                  style: AppFonts.ui(
                    size: 14.5,
                    weight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                if (observation.texte case final texte?) ...[
                  const SizedBox(height: 4),
                  Text(
                    texte,
                    style: AppFonts.ui(
                        size: 13, color: AppColors.inkSoft, height: 1.5),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
