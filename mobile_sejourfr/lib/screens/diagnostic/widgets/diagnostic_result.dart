import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/diagnostic_models.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/skill_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_tag.dart';
import '../../../core/widgets/blurred_content.dart';
import '../../../core/widgets/fixed_action_bar.dart';
import '../../../core/widgets/gradient_hero.dart';
import '../../../core/widgets/premium_lock.dart';
import '../../plan/learning_plan_provider.dart';
import '../../plan/plan_actions.dart';
import '../../plan/plan_labels.dart';
import '../../plan/widgets/plan_tokens.dart';
import '../diagnostic_variant.dart';
import 'diagnostic_report_labels.dart';

/// Écran de fin de diagnostic, refondu le 2026-08-21 sur la maquette
/// `MRapportGratuit` — *« claire, compréhensible et épurée »*.
///
/// Il dit **où en est le candidat**, **par où commencer**, puis lui présente
/// son plan et l'offre. Rien n'y est décoratif : chaque bloc rend une donnée
/// que le serveur a réellement produite, et **un bloc sans donnée n'est pas
/// rendu** (jamais de squelette, jamais de « non disponible »).
///
/// 🛑 **Ce que la maquette N'A PAS, et qui a donc été retiré de cet écran** :
/// le « avant / après » (`exempleCible`), le détail des deux productions, et la
/// section « Compléter mon profil ». Le premier reste servi par le contrat et
/// affiché par les rapports EE/EO et le résultat de compétence
/// (`ActionPlanExempleCard`, intacte) ; la substance du troisième vit désormais
/// dans la **bande des quatre domaines** au pied de la carte de niveau — le
/// « — » dit ce qui manque — plus la note discrète juste dessous. **Le Plan
/// garde sa section complète**, elle n'a pas bougé.
///
/// Trois choses de la maquette restent volontairement **non reprises** :
/// - aucune **barre ni pourcentage** de progression — le score de maîtrise
///   n'est exposé à aucun front, on rend des états et des statuts ;
/// - aucun **calendrier** (« Semaine 1 », jours) — le Plan n'a pas de notion de
///   temps, une étape est un ensemble de sujets ;
/// - aucun **emoji en texte brut** — les icônes viennent de `LucideIcons`.
class DiagnosticResultView extends ConsumerWidget {
  const DiagnosticResultView({
    super.key,
    required this.result,
    required this.hasTcfAccess,
    required this.variant,
    required this.onOpenPlan,
    required this.onOpenRecommended,
    required this.onSubscribe,
    this.objective,
  });

  final DiagnosticResult result;
  final String? objective;

  /// Ce que le candidat a choisi à l'entrée. **Rien n'est persisté** : la
  /// variante ne change ni le parcours joué, ni ce que le serveur a mesuré —
  /// elle décide seulement de ce que ce bilan **enchaîne** (cf.
  /// `diagnostic_variant.dart`).
  final DiagnosticVariant variant;

  /// Accès TCF réel du compte (`AuthUser.hasTcf`). Il ne décide que de ce qui
  /// est **flouté** : aucune règle de verrou n'est recalculée ici — celle de
  /// l'exercice recommandé vient de `PlanRecommendedExercise.locked`, posé par
  /// le serveur.
  final bool hasTcfAccess;

  final VoidCallback onOpenPlan;
  final ValueChanged<PlanRecommendedExercise> onOpenRecommended;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focus = _focusItems(result);
    final ranked = focus.isNotEmpty && focus.first.ranked;
    final solid = _solidSkills(result);
    final steps = _planSteps(result);

    // Le Plan n'est lu qu'**ici**, sur l'écran de résultat d'un compte
    // authentifié : c'est la seule source de l'état du profil (quels domaines
    // sont mesurés) et de ce qui reste à mesurer. Son absence — chargement,
    // réseau — est un cas NORMAL : les blocs concernés ne sont pas rendus, rien
    // n'est deviné et rien ne signale d'erreur.
    final plan = ref.watch(learningPlanProvider).valueOrNull;
    final pending = _comprehensionToAssess(plan);
    final domains = plan?.domaines ?? const <PlanDomain>[];

    // **Le compteur est calculé sur ce que le serveur a renvoyé**, jamais sur
    // une constante de maquette : `focus`, `solid` et `steps` sont les listes
    // entières, on n'en tranche que l'affichage. Moins d'éléments que le seuil
    // ⇒ `hidden == 0` ⇒ **le bloc verrouillé n'existe pas** et tout est en
    // clair — un compte gratuit avec deux priorités n'a rien de masqué à lui
    // vendre.
    final focusTotal = _focusTotal(result, focus);
    final visibleFocus =
        hasTcfAccess ? focus : focus.take(_kFreeFocusVisible).toList();
    final hiddenFocus = hasTcfAccess
        ? 0
        : _hiddenCount(total: focusTotal, visible: visibleFocus.length);

    // Les points forts, c'est ce que les deux productions ont montré SOLIDE.
    // Les phrases `strengths` ne sont qu'un **repli** : plafonnées à 3 à
    // l'écriture du résumé, elles ne peuvent porter aucun compteur.
    final strengthTexts = solid.isEmpty ? result.strengths : const <String>[];
    final visibleSolid =
        hasTcfAccess ? solid : solid.take(_kFreeSolidVisible).toList();
    final visibleTexts = hasTcfAccess
        ? strengthTexts
        : strengthTexts.take(_kFreeSolidVisible).toList();
    final hiddenSolid = hasTcfAccess
        ? 0
        : _hiddenCount(
            total: _strengthTotal(
              result,
              solid.isEmpty ? strengthTexts.length : solid.length,
            ),
            visible: solid.isEmpty ? visibleTexts.length : visibleSolid.length,
          );

    final visibleSteps =
        hasTcfAccess ? steps : steps.take(_kFreeStepsVisible).toList();
    // Ce que l'abonnement ouvre vraiment : le compte des priorités restantes,
    // jamais la longueur de l'aperçu (borné à 3 étapes).
    final hiddenSteps = hasTcfAccess ? 0 : hiddenFocus;

    return Stack(
      children: [
        ListView(
          // La réserve du bas laisse passer tout le contenu sous le CTA
          // collant : rien n'est jamais masqué par la barre.
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 132),
          children: [
            // 1 — une seule carte de niveau, la bande des quatre domaines à son
            // pied. C'est elle qui rend l'écran épuré : le profil TCF n'a plus
            // de section à lui.
            _LevelCard(
              cycle: plan?.cycle,
              objective: objective,
              domains: domains,
            ),
            if (_noComprehensionMeasured(domains)) ...[
              const SizedBox(height: 11),
              const PlanNote(kDiagnosticProfileIncompleteNote),
            ],

            // 2 — vos principales priorités
            if (visibleFocus.isNotEmpty) ...[
              const SizedBox(height: 24),
              _SectionTitle(
                title: ranked
                    ? kDiagnosticPrioritiesTitle
                    : kDiagnosticPrioritiesTitleUnranked,
                text: ranked
                    ? kDiagnosticPrioritiesText
                    : kDiagnosticPrioritiesTextUnranked,
              ),
              const SizedBox(height: 11),
              _PrioritiesCard(focus: visibleFocus),
              if (hiddenFocus > 0) ...[
                const SizedBox(height: 9),
                _LockedPreview(
                  lines: [
                    for (final item in focus.skip(visibleFocus.length).take(
                        hiddenFocus < _kBlurredSample
                            ? hiddenFocus
                            : _kBlurredSample))
                      _LockedLine(
                        title: item.title,
                        subtitle: item.section?.label,
                      ),
                  ],
                  // Le teaser parle la même langue que sa section : sans
                  // priorités mesurées, ce ne sont pas des « priorités » mais
                  // des points relevés — le repli ne doit pas les promouvoir.
                  label: ranked
                      ? '+ $hiddenFocus autre${_plural(hiddenFocus)} '
                          'priorité${_plural(hiddenFocus)} '
                          'détectée${_plural(hiddenFocus)}'
                      : '+ $hiddenFocus autre${_plural(hiddenFocus)} '
                          'point${_plural(hiddenFocus)} à travailler',
                  onSubscribe: onSubscribe,
                ),
              ],
            ],

            // 3 — vos points forts
            if (visibleSolid.isNotEmpty || visibleTexts.isNotEmpty) ...[
              const SizedBox(height: 24),
              const _SectionTitle(
                title: kDiagnosticStrengthsTitle,
                text: kDiagnosticStrengthsText,
              ),
              const SizedBox(height: 11),
              _StrengthsCard(skills: visibleSolid, texts: visibleTexts),
              if (hiddenSolid > 0) ...[
                const SizedBox(height: 9),
                _LockedPreview(
                  lines: _strengthTeaseLines(
                    solid: solid,
                    texts: strengthTexts,
                    from: _kFreeSolidVisible,
                    hidden: hiddenSolid,
                  ),
                  label: '+ $hiddenSolid autre${_plural(hiddenSolid)} '
                      'compétence${_plural(hiddenSolid)} déjà '
                      'solide${_plural(hiddenSolid)}',
                  onSubscribe: onSubscribe,
                ),
              ],
            ],

            // 4 — votre plan personnalisé est prêt
            if (visibleSteps.isNotEmpty) ...[
              const SizedBox(height: 24),
              const _SectionTitle(
                title: kDiagnosticPlanReadyTitle,
                text: kDiagnosticPlanReadyText,
              ),
              const SizedBox(height: 11),
              _PlanPreviewCard(
                priority: focus.isEmpty ? null : focus.first,
                steps: visibleSteps,
                hiddenSteps: hiddenSteps,
                exercise: result.nextAction,
                onOpenRecommended: onOpenRecommended,
                onSubscribe: onSubscribe,
              ),
            ],

            // 5 — l'offre ferme le rapport : le candidat a d'abord lu **son**
            // niveau, **ses** priorités et **ses** acquis.
            if (!hasTcfAccess) ...[
              const SizedBox(height: 24),
              _UnlockCard(onSubscribe: onSubscribe),
            ],
            const SizedBox(height: 14),
            const PlanNote(kDiagnosticEstimationNote),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _ResultActionBar(
            // Le complet enchaîne sur la première épreuve de compréhension que
            // le **serveur** désigne ; le rapide renvoie au Plan. Aucun ordre
            // n'est recalculé ici : `domainesAEvaluer` arrive déjà trié.
            next:
                variant.isComplet && pending.isNotEmpty ? pending.first : null,
            onOpenPlan: onOpenPlan,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Lecture des données
// ---------------------------------------------------------------------------

/// Les épreuves de **compréhension** qu'il reste à mesurer, dans l'ordre servi.
///
/// 🛑 Rien n'est trié, filtré par urgence ni complété ici : `domainesAEvaluer`
/// est **la seule** réponse à « comment compléter mon profil », et le serveur
/// l'a déjà ordonnée. On ne retient que CO et CE parce que le diagnostic vient
/// précisément de mesurer les deux expressions — une ligne EE/EO ici voudrait
/// dire que la production n'a pas été observée, ce que le Plan dira mieux.
///
/// **Vide = profil complet**, état visé et non anomalie.
List<PlanDomainAssessment> _comprehensionToAssess(LearningPlan? plan) {
  final assessments = plan?.domainesAEvaluer;
  if (assessments == null || assessments.isEmpty) {
    return const <PlanDomainAssessment>[];
  }
  return assessments
      .where(
        (assessment) =>
            assessment.epreuve == EpreuveType.tcfCo ||
            assessment.epreuve == EpreuveType.tcfCe,
      )
      .toList(growable: false);
}

/// Aucun domaine de compréhension n'a-t-il été mesuré ?
///
/// 🛑 C'est la **seule** condition d'affichage de la note discrète : le
/// diagnostic mesure les deux domaines d'**expression**, jamais la
/// compréhension — mais un candidat a pu passer un examen blanc CO ou CE avant.
/// Profil complet, ou un seul des deux manquant : la bande de quatre colonnes
/// dit déjà « — » et suffit. Miroir de `aucuneComprehension` côté web.
bool _noComprehensionMeasured(List<PlanDomain> domains) {
  final comprehension = domains.where(
    (domain) =>
        domain.epreuve == EpreuveType.tcfCo ||
        domain.epreuve == EpreuveType.tcfCe,
  );
  return comprehension.isNotEmpty &&
      comprehension.every((domain) => !domain.evaluated);
}

/// Une ligne de « Vos principales priorités ».
///
/// Elle porte **tout ce que le serveur publie** sur une priorité
/// (`DiagnosticSkillObservationDto`) et que le candidat a le droit de lire :
/// `explanation`, `evidence`, `status`, `section` et le code de la compétence.
/// `confidence` en est volontairement absente — elle n'est **jamais** montrée
/// au candidat.
class _FocusItem {
  const _FocusItem({
    required this.title,
    required this.ranked,
    this.code = '',
    this.detail,
    this.evidence,
    this.status,
    this.section,
  });

  final String title;
  final String code;
  final String? detail;
  final String? evidence;
  final LearningPlanSkillStatus? status;
  final SkillSection? section;

  /// Distingue les **priorités mesurées** par le serveur (numérotées) des
  /// replis : ces derniers ne portent pas de rang, parce qu'ils ne sont pas un
  /// classement.
  final bool ranked;

  /// Y a-t-il quelque chose à déplier ? Un repli tiré des `weaknesses` n'est
  /// qu'un titre : sa ligne reste alors **inerte**, sans chevron.
  bool get hasReport => detail != null || evidence != null;

  /// « Expression écrite · Tâche 2 ». Vide quand la ligne ne vient d'aucune
  /// compétence : on n'invente pas de domaine.
  String get meta => _skillMetaLine(section, code);

  /// Le repère d'une ligne **sans domaine** : elle reste nommée pour ce qu'elle
  /// est — une priorité mesurée, ou un simple point relevé.
  String get fallbackMeta =>
      ranked ? kDiagnosticPriorityRankLabel : kDiagnosticPointLabel;
}

/// Le repère d'une compétence : son domaine, et le numéro de tâche quand elle
/// en a un (l'expression seule). Vide quand la ligne ne vient d'aucune
/// compétence — on n'invente pas de domaine. Miroir de `skillMetaLine`
/// (`web_sejoufr/app/_components/diagnostic/DiagnosticView.tsx`).
String _skillMetaLine(SkillSection? section, String skillCode) {
  if (section == null) return '';
  final task = diagnosticSkillTaskNumber(skillCode);
  return task == null ? section.label : '${section.label} · Tâche $task';
}

/// Ce sur quoi le candidat doit travailler, dans l'ordre de repli suivant :
/// 1. les **priorités** servies par le serveur — le cas normal ;
/// 2. sinon, les compétences observées non solides des deux productions ;
/// 3. sinon, les `weaknesses` des deux productions, présentées comme ce que les
///    productions ont montré, **jamais comme des priorités mesurées**.
///
/// Rien de tout ça ⇒ liste vide ⇒ la carte n'est pas rendue.
///
/// 🛑 **La liste est rendue ENTIÈRE, jamais tronquée ici.** C'est elle qui
/// fait le compteur « + N autres priorités détectées » d'un compte sans accès :
/// une troncature à la source aurait fabriqué un compteur faux, et le dépôt
/// exige qu'il soit vrai. C'est l'appelant qui tranche ce qu'il affiche.
List<_FocusItem> _focusItems(DiagnosticResult result) {
  final fragile = _observedSkills(result)
      .where(
        (skill) =>
            skill.status == LearningPlanSkillStatus.priority ||
            skill.status == LearningPlanSkillStatus.toReinforce,
      )
      .toList(growable: false);

  if (result.priorities.isNotEmpty) {
    final ranked = result.priorities.indexed
        .map(
          (entry) => _FocusItem(
            title: entry.$2.skillTitle,
            code: entry.$2.skillCode,
            // La priorité n°1 a son explication dédiée
            // (`mainPriorityExplanation`), plus développée que l'explication de
            // l'observation. Même repli que le web (`DiagnosticView`).
            detail: (entry.$1 == 0 ? result.mainPriorityExplanation : null) ??
                entry.$2.explanation,
            evidence: entry.$2.evidence,
            status: entry.$2.status,
            section: entry.$2.section,
            ranked: true,
          ),
        )
        .toList();
    // `priorities` est plafonné à **3** côté serveur — règle produit. Sans ce
    // complément, un abonné n'aurait jamais vu ce que le compteur d'un compte
    // gratuit lui promet.
    final seen = result.priorities.map((item) => item.skillId).toSet();
    for (final skill in fragile) {
      if (!seen.add(skill.skillId)) continue;
      ranked.add(_focusOf(skill));
    }
    return List.unmodifiable(ranked);
  }

  final observed = fragile.map(_focusOf).toList(growable: false);
  if (observed.isNotEmpty) return List.unmodifiable(observed);

  final weaknesses = <_FocusItem>[];
  for (final production in [result.written, result.oral]) {
    for (final weakness in production?.weaknesses ?? const <String>[]) {
      weaknesses.add(_FocusItem(title: weakness, ranked: false));
    }
  }
  return List.unmodifiable(weaknesses);
}

/// Les compétences **réellement observées** sur les deux productions,
/// dédoublonnées par `skillId`. Une observation non effective n'y entre jamais :
/// « je n'ai pas pu observer » n'est pas « le candidat est faible ».
List<DiagnosticSkillObservation> _observedSkills(DiagnosticResult result) {
  final seen = <String>{};
  final observed = <DiagnosticSkillObservation>[];
  for (final production in [result.written, result.oral]) {
    for (final skill
        in production?.skills ?? const <DiagnosticSkillObservation>[]) {
      if (!skill.observed) continue;
      if (!seen.add(skill.skillId)) continue;
      observed.add(skill);
    }
  }
  return List.unmodifiable(observed);
}

_FocusItem _focusOf(DiagnosticSkillObservation skill) => _FocusItem(
      title: skill.skillTitle,
      code: skill.skillCode,
      detail: skill.explanation,
      evidence: skill.evidence,
      status: skill.status,
      section: skill.section,
      ranked: false,
    );

/// Les compétences que les deux productions ont montrées **solides**,
/// dédoublonnées par `skillId`. Rendue **entière** pour la même raison que
/// [_focusItems] : c'est l'appelant qui tranche ce qu'il affiche.
List<DiagnosticSkillObservation> _solidSkills(DiagnosticResult result) =>
    List.unmodifiable(
      _observedSkills(result)
          .where((skill) => skill.status == LearningPlanSkillStatus.solid),
    );

/// Les lignes **réelles** que le rideau des points forts laisse deviner : les
/// compétences solides, ou les phrases de repli quand il n'y en a aucune.
/// Bornées par ce qui reste vraiment — on ne floute jamais plus que ce qu'on
/// annonce.
List<_LockedLine> _strengthTeaseLines({
  required List<DiagnosticSkillObservation> solid,
  required List<String> texts,
  required int from,
  required int hidden,
}) {
  final sample = hidden < _kBlurredSample ? hidden : _kBlurredSample;
  if (solid.isNotEmpty) {
    return [
      for (final skill in solid.skip(from).take(sample))
        _LockedLine(title: skill.skillTitle, subtitle: skill.section.label),
    ];
  }
  return [
    for (final text in texts.skip(from).take(sample)) _LockedLine(title: text),
  ];
}

/// Le **total** annoncé par le compteur des priorités. 🛑 Il vient du serveur
/// (`fragileSkillCount`) : `priorities` est plafonné à 3, et deux dérivations
/// front finiraient par afficher deux nombres différents. Le `max` n'est qu'un
/// garde-fou — on n'annonce jamais moins que ce qu'on affiche.
int _focusTotal(DiagnosticResult result, List<_FocusItem> focus) =>
    result.fragileSkillCount > focus.length
        ? result.fragileSkillCount
        : focus.length;

/// Idem pour les points forts. ⚠️ `strengths` ne peut pas rendre ce service :
/// la liste est plafonnée à 3 **à l'écriture** du résumé côté serveur.
int _strengthTotal(DiagnosticResult result, int shown) =>
    result.solidSkillCount > shown ? result.solidSkillCount : shown;

/// Une ligne de la séance mise en aperçu.
class _PlanStep {
  const _PlanStep({
    required this.title,
    required this.subtitle,
    this.epreuve,
  });

  final String title;
  final String subtitle;
  final EpreuveType? epreuve;
}

/// Les trois lignes de l'aperçu : l'exercice recommandé, puis les priorités
/// suivantes, puis la vérification en situation si la place reste.
///
/// **Aucun titre n'est masqué** : le verrou porte sur l'accès, jamais sur
/// l'information — et il est reporté par le serveur
/// (`PlanRecommendedExercise.locked`), jamais recalculé ici.
List<_PlanStep> _planSteps(DiagnosticResult result) {
  final exercise = result.nextAction;
  final steps = <_PlanStep>[];

  if (exercise != null) {
    steps.add(
      _PlanStep(
        title: exercise.title,
        subtitle: exercise.kind == PlanExerciseKind.reassessment
            ? 'Vérification en situation · ${exercise.estimatedMinutes} min'
            : 'Exercice ciblé · ${exercise.estimatedMinutes} min',
        epreuve: planEpreuveOfSection(exercise.section),
      ),
    );
  } else if (result.priorities.isNotEmpty) {
    final first = result.priorities.first;
    steps.add(
      _PlanStep(
        title: first.skillTitle,
        subtitle: 'Exercice ciblé',
        epreuve: planEpreuveOfSection(first.section),
      ),
    );
  }

  for (final priority in result.priorities.skip(1).take(2)) {
    if (steps.length >= 3) break;
    steps.add(
      _PlanStep(
        title: priority.skillTitle,
        subtitle: 'Exercice ciblé',
        epreuve: planEpreuveOfSection(priority.section),
      ),
    );
  }
  // Pas de ligne de complement : un apercu de plan n'affiche que des etapes
  // reelles. En fabriquer une pour atteindre trois lignes montrerait au
  // candidat un entrainement que son plan ne lui proposera jamais -- et le web
  // n'en a pas non plus.
  return steps;
}

// ---------------------------------------------------------------------------
// 1 — la carte de niveau, bande des quatre domaines comprise
// ---------------------------------------------------------------------------

/// **Une seule carte** pour tout ce qui situe le candidat : son niveau estimé,
/// son objectif, le rail des paliers, et — à son pied — l'état des **quatre
/// domaines** du TCF.
///
/// 🛑 C'est ce regroupement qui rend l'écran épuré : le profil TCF n'a plus de
/// section à lui, et « Compléter mon profil » n'a plus lieu d'exister ici. Un
/// domaine non mesuré garde sa case, avec un **tiret** à la place du niveau —
/// *inconnu, jamais mauvais* : aucun niveau ne lui est prêté, aucune teinte
/// d'alerte, aucune pastille « à évaluer ». C'est la règle du Plan
/// (`kPlanNotEvaluatedNote`).
class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.cycle,
    required this.objective,
    required this.domains,
  });

  /// 🛑 **Le niveau global et le palier en construction viennent du SERVEUR**
  /// (`cycle.startingLevel` / `cycle.targetLevel`). Le plancher des quatre
  /// domaines est une règle serveur (`TcfProfileService`) : aucun front ne la
  /// rejoue à partir des deux estimations de production, sinon deux surfaces
  /// annonceraient deux paliers pour le même candidat. `null` tant que le Plan
  /// n'est pas chargé — on affiche « — », jamais un palier deviné.
  final PlanCycle? cycle;

  /// Le palier visé par le candidat, tel qu'il est déjà résolu pour l'écran
  /// (`TargetProcedure.niveauVise`, plancher de la démarche). `null` = pas
  /// encore choisi : on l'écrit, on n'invente pas de « B2 ».
  final String? objective;

  /// Les quatre domaines dans **l'ordre servi** — le serveur les trie par
  /// urgence, aucun front ne retrie. Vide tant que le Plan n'est pas chargé :
  /// la bande n'existe alors pas, ce n'est pas une anomalie à signaler.
  final List<PlanDomain> domains;

  @override
  Widget build(BuildContext context) {
    // Tant que le Plan n'est pas chargé, la bande n'existe pas : le héros se
    // suffit alors à lui-même, sans carte blanche autour — un liseré clair
    // ceinturant un dégradé plein n'aurait rien dit.
    final hero = GradientHero(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 17),
      borderRadius: domains.isEmpty
          ? null
          : const BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kDiagnosticLevelEyebrow.toUpperCase(),
            style: AppFonts.eyebrow(
              color: AppColors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 12),
          // IntrinsicHeight : le filet vertical doit courir sur toute la
          // hauteur du bloc, or un `stretch` dans une colonne scrollable n'a
          // pas de contrainte de hauteur.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Flexible(
                  child: Text(
                    cycle?.startingLevel?.displayName ?? '—',
                    style: AppFonts.display(
                      size: 44,
                      height: 1.05,
                      color: AppColors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  width: 1,
                  color: AppColors.white.withValues(alpha: 0.25),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kDiagnosticLevelObjective.toUpperCase(),
                      style: AppFonts.eyebrow(
                        color: AppColors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      objective ?? kDiagnosticLevelObjectiveUnknown,
                      style: AppFonts.display(
                        size: 34,
                        height: 1.2,
                        color: AppColors.white.withValues(alpha: 0.62),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            kDiagnosticLevelText,
            style: AppFonts.ui(
              size: 13.5,
              height: 1.55,
              color: AppColors.white.withValues(alpha: 0.92),
            ),
          ),
          if (cycle != null) ...[
            const SizedBox(height: 14),
            // Le rail du Plan, repris tel quel : le candidat doit retrouver
            // **la même** échelle d'un écran à l'autre, et le palier allumé est
            // celui que son cycle construit — pas une valeur redérivée ici.
            PlanLevelRail(current: cycle!.targetLevel, onDark: true),
          ],
        ],
      ),
    );

    if (domains.isEmpty) return hero;

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
          hero,
          // Les quatre cases ont la même hauteur quel que soit le domaine dont
          // l'abrégé passe à la ligne.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < domains.length; i++)
                  Expanded(
                    child: _DomainCell(domain: domains[i], first: i == 0),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Une case de la bande : le niveau estimé du domaine — ou un tiret — et son
/// abrégé. Elle ouvre la fiche du domaine, où vivent ses paliers et de quoi le
/// mesurer : c'est par là que se complète un profil, la section dédiée ayant
/// été retirée de cet écran.
class _DomainCell extends StatelessWidget {
  const _DomainCell({required this.domain, required this.first});

  final PlanDomain domain;
  final bool first;

  @override
  Widget build(BuildContext context) {
    // `evaluated == false` ⇔ `niveau == null` côté serveur ; on lit les deux
    // plutôt que d'en déduire l'autre.
    final measured = domain.evaluated && domain.niveau != null;
    return Semantics(
      button: true,
      label: measured
          ? '${planDomainLabel(domain.epreuve)} : niveau estimé '
              '${domain.niveau!.displayName}'
          : '${planDomainLabel(domain.epreuve)} : $kPlanDomainNotEvaluated',
      child: Material(
        color: AppColors.white,
        child: InkWell(
          onTap: () => openPlanDomain(context, domain.epreuve),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 11),
            decoration: BoxDecoration(
              border: Border(
                left: first
                    ? BorderSide.none
                    : const BorderSide(color: AppColors.lineSoft),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  measured ? domain.niveau!.shortName : '—',
                  style: AppFonts.display(
                    size: 16,
                    color: measured ? AppColors.ink : AppColors.inkFaint,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  planDomainShort(domain.epreuve),
                  textAlign: TextAlign.center,
                  style: AppFonts.ui(
                    size: 11,
                    weight: FontWeight.w600,
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
// Titres de section
// ---------------------------------------------------------------------------

/// Le titre d'une section — **une ligne, rien d'autre**. Les anciens en-têtes
/// à trois étages (eyebrow, titre-phrase, description) sont ce qui avait
/// alourdi cet écran passe après passe.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppFonts.display(size: 19, height: 1.15)),
            const SizedBox(height: 4),
            Text(
              text,
              style: AppFonts.ui(
                size: 12.5,
                height: 1.45,
                color: AppColors.inkSoft,
              ),
            ),
          ],
        ),
      );
}

// ---------------------------------------------------------------------------
// 2 — vos principales priorités
// ---------------------------------------------------------------------------

/// Les priorités du serveur, ou son repli : une carte, une ligne par
/// compétence, séparées d'un filet — la densité de la maquette.
class _PrioritiesCard extends StatelessWidget {
  const _PrioritiesCard({required this.focus});

  final List<_FocusItem> focus;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < focus.length; index++)
              _PriorityRow(item: focus[index], first: index == 0),
          ],
        ),
      );
}

/// Une priorité. Repliée, on lit la compétence, son domaine et le verdict porté
/// sur elle. Le dépliant rend le rapport **entier** du correcteur : **aucun
/// texte n'est ellipsé** — l'explication arrivait coupée en plein milieu
/// (« …est une er… »), c'est-à-dire au moment précis où elle devenait utile.
///
/// Sans rapport à déplier (repli tiré des `weaknesses`), la ligne reste inerte
/// et ne montre aucun chevron : elle n'annonce que ce qu'elle fait vraiment.
class _PriorityRow extends StatefulWidget {
  const _PriorityRow({required this.item, required this.first});

  final _FocusItem item;
  final bool first;

  @override
  State<_PriorityRow> createState() => _PriorityRowState();
}

class _PriorityRowState extends State<_PriorityRow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final detail = item.detail;
    final evidence = item.evidence;
    final expandable = item.hasReport;
    // Une ligne sans domaine reste nommée pour ce qu'elle est, plutôt que de
    // laisser un titre nu : c'est le repli du web (`PRIORITY_RANK_LABEL`).
    final meta = item.meta.isEmpty ? item.fallbackMeta : item.meta;
    final section = item.section;
    final status = item.status;

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
      child: Row(
        children: [
          PlanDomainTile(
            epreuve: section == null ? null : planEpreuveOfSection(section),
            size: 38,
            filled: widget.first,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppFonts.ui(
                    size: 14,
                    weight: FontWeight.w600,
                    height: 1.28,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  meta,
                  style: AppFonts.ui(
                    size: 12,
                    height: 1.35,
                    color: AppColors.inkFaint,
                  ),
                ),
              ],
            ),
          ),
          if (status != null) ...[
            const SizedBox(width: 8),
            AppTag(
              label: status.label,
              tone: tagToneForAccent(status.color),
              compact: true,
            ),
          ],
          if (expandable) ...[
            const SizedBox(width: 4),
            AnimatedRotation(
              turns: _open ? 0.5 : 0,
              duration: const Duration(milliseconds: 180),
              child: const Icon(
                LucideIcons.chevronDown,
                size: 17,
                color: AppColors.inkFaint,
              ),
            ),
          ],
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: widget.first
              ? BorderSide.none
              : const BorderSide(color: AppColors.lineSoft),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (expandable)
            Semantics(
              button: true,
              expanded: _open,
              label: '${item.title} · $meta',
              child: InkWell(
                onTap: () => setState(() => _open = !_open),
                child: header,
              ),
            )
          else
            header,
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: !_open
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(65, 0, 15, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (detail != null)
                          Text(
                            detail,
                            style: AppFonts.ui(
                              size: 12,
                              height: 1.45,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        // La citation est la phrase du candidat lui-même, et le
                        // dépliant est ouvert à sa demande : elle est rendue
                        // **entière**.
                        if (evidence != null) ...[
                          if (detail != null) const SizedBox(height: 7),
                          Text(
                            '« ${evidence.trim()} »',
                            style: AppFonts.ui(
                              size: 12,
                              height: 1.45,
                              color: AppColors.inkFaint,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3 — vos points forts
// ---------------------------------------------------------------------------

/// Ce que les deux productions ont montré **solide** : une coche, la
/// compétence, son domaine. Les phrases `strengths` ne sont qu'un **repli**
/// quand aucune compétence n'a été observée solide — les afficher côte à côte
/// aurait dit deux fois la même chose, et en clair ce que le rideau prétend
/// cacher.
class _StrengthsCard extends StatelessWidget {
  const _StrengthsCard({required this.skills, required this.texts});

  final List<DiagnosticSkillObservation> skills;
  final List<String> texts;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      for (final skill in skills)
        _StrengthRow(
          label: skill.skillTitle,
          trailing: _skillMetaLine(skill.section, skill.skillCode),
        ),
      if (skills.isEmpty)
        for (final text in texts) _StrengthRow(label: text),
    ];
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            if (index > 0) const SizedBox(height: 12),
            rows[index],
          ],
        ],
      ),
    );
  }
}

class _StrengthRow extends StatelessWidget {
  const _StrengthRow({required this.label, this.trailing});

  final String label;
  final String? trailing;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.greenLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.check,
              size: 13,
              color: AppColors.green,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                label,
                style: AppFonts.ui(size: 13.5, height: 1.35),
              ),
            ),
          ),
          if (trailing != null && trailing!.isNotEmpty) ...[
            const SizedBox(width: 10),
            // Le repère se replie avant le titre : c'est la compétence qu'on
            // vient lire, pas son domaine.
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  trailing!,
                  textAlign: TextAlign.end,
                  style: AppFonts.ui(
                    size: 12,
                    weight: FontWeight.w600,
                    color: AppColors.inkFaint,
                  ),
                ),
              ),
            ),
          ],
        ],
      );
}

// ---------------------------------------------------------------------------
// 4 — aperçu du plan
// ---------------------------------------------------------------------------

class _PlanPreviewCard extends StatelessWidget {
  const _PlanPreviewCard({
    required this.priority,
    required this.steps,
    required this.hiddenSteps,
    required this.exercise,
    required this.onOpenRecommended,
    required this.onSubscribe,
  });

  /// La priorité n°1 telle que le serveur l'a désignée. `null` sur un repli
  /// sans priorité : le bandeau de tête n'existe alors pas.
  final _FocusItem? priority;

  /// Ce qui est **affiché**. Un compte sans accès n'en voit qu'un.
  final List<_PlanStep> steps;

  /// Combien d'entraînements restent derrière le verrou. `0` pour un abonné, et
  /// **`0` aussi** quand la séance en compte moins que le seuil — la barre
  /// n'existe alors pas.
  final int hiddenSteps;
  final PlanRecommendedExercise? exercise;
  final ValueChanged<PlanRecommendedExercise> onOpenRecommended;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    final action = exercise;
    final head = priority;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.blue),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Le bandeau « Priorité actuelle » a ete retire le 2026-08-21 :
          // cette meme priorite est deja la premiere ligne de « Vos
          // principales priorites », deux sections plus haut. La redire ici
          // n'ajoutait rien et allongeait la carte. Ne pas la reintroduire.
          if (action != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              decoration: BoxDecoration(
                border: Border(
                  top: head == null
                      ? BorderSide.none
                      : const BorderSide(color: AppColors.lineSoft),
                ),
              ),
              child: Text(
                '$kDiagnosticPlanTodayLabel · ${action.estimatedMinutes} min',
                style: AppFonts.eyebrow(color: AppColors.inkFaint),
              ),
            ),
          for (final step in steps)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 11, 16, 0),
              child: _PlanStepRow(step: step),
            ),
          if (hiddenSteps > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: _LockedMoreBar(
                label: '+ $hiddenSteps autre${_plural(hiddenSteps)} '
                    'entraînement${_plural(hiddenSteps)} '
                    'personnalisé${_plural(hiddenSteps)}',
                onSubscribe: onSubscribe,
              ),
            ),
          if (action != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: AppButton(
                label: _exerciseCta(action),
                variant: action.locked
                    ? AppButtonVariant.outline
                    : AppButtonVariant.soft,
                height: 46,
                icon: action.locked ? LucideIcons.lock : null,
                onPressed: action.locked
                    ? onSubscribe
                    : () => onOpenRecommended(action),
              ),
            ),
          const SizedBox(height: 15),
        ],
      ),
    );
  }

  /// Mêmes libellés que le Plan (`plan_screen.dart`) : un candidat ne doit pas
  /// lire deux formulations pour la même action.
  static String _exerciseCta(PlanRecommendedExercise exercise) {
    if (exercise.locked) return 'Débloquer cet exercice';
    return exercise.kind == PlanExerciseKind.reassessment
        ? 'Vérifier ma progression'
        : 'Commencer';
  }
}

class _PlanStepRow extends StatelessWidget {
  const _PlanStepRow({required this.step});

  final _PlanStep step;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          PlanDomainTile(epreuve: step.epreuve, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: AppFonts.ui(
                    size: 13.5,
                    weight: FontWeight.w600,
                    height: 1.28,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  step.subtitle,
                  style: AppFonts.ui(size: 11.5, color: AppColors.inkFaint),
                ),
              ],
            ),
          ),
        ],
      );
}

// ---------------------------------------------------------------------------
// 5 — l'offre
// ---------------------------------------------------------------------------

/// Ce que l'abonnement ouvre, en cinq lignes. Aucun prix, aucun verbe d'achat
/// (guidelines Apple 3.1.1) : le libellé du bouton est celui, partagé, de
/// [kUnlockPlanCta].
class _UnlockCard extends StatelessWidget {
  const _UnlockCard({required this.onSubscribe});

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
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadii.xl),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kDiagnosticUnlockTitle,
                  style: AppFonts.display(
                    size: 21,
                    height: 1.12,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 13),
                const PremiumBenefitList(
                  benefits: kDiagnosticPremiumBenefits,
                  checkColor: AppColors.greenBright,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Semantics(
              button: true,
              label: kUnlockPlanCta,
              child: AppButton(
                label: kUnlockPlanCta,
                iconRight: LucideIcons.arrowRight,
                height: 48,
                onPressed: onSubscribe,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ce qu'un compte sans accès TCF ne lit pas encore
// ---------------------------------------------------------------------------

/// Ce qu'un compte **sans accès TCF** lit en clair avant le bloc verrouillé.
///
/// Ce sont des seuils d'**affichage**, jamais une règle serveur : le backend ne
/// verrouille pas la lecture d'un diagnostic, et `GET /api/me/plan` sert le Plan
/// en entier à un compte gratuit. Ils viennent de la maquette
/// (`MRapportGratuit`) et ne décident d'aucun accès — le verrou réel reste
/// `PlanRecommendedExercise.locked`, posé par le serveur.
///
/// 🛑 **Ce qui reste entier quel que soit l'abonnement** : le niveau estimé,
/// l'objectif, le rail, la bande des quatre domaines et la priorité n°1 avec
/// son rapport. Ce sont **ses** productions et **ses** mesures — on ne les lui
/// vend pas. ⚠️ Corollaire à ne jamais casser : **aucune surface de cet écran
/// ne doit nommer en clair ce que le rideau prétend cacher.** C'est exactement
/// pour ça que le détail des deux productions (qui listait « À travailler »)
/// n'y a plus sa place.
const int _kFreeFocusVisible = 1;
const int _kFreeSolidVisible = 1;
const int _kFreeStepsVisible = 1;

/// Combien de lignes **réelles** le bloc flouté laisse deviner. C'est un
/// échantillon, jamais le compte : le compte, lui, est exact et porte sur
/// **tout** ce qui est masqué. Miroir web : `TEASE_SAMPLE`.
const int _kBlurredSample = 2;

/// Ce qu'il reste à annoncer, à partir d'un total **servi par le serveur** et de
/// ce qui est affiché en clair.
///
/// 🛑 `0` ⇒ **aucun bloc** : une liste plus courte que le seuil s'affiche
/// entièrement en clair, on ne fabrique jamais de reste à vendre.
int _hiddenCount({required int total, required int visible}) =>
    total - visible < 0 ? 0 : total - visible;

String _plural(int count) => count > 1 ? 's' : '';

/// Une ligne du bloc verrouillé. Elle porte du **contenu réel** : le titre et
/// l'épreuve de ce que le serveur a effectivement observé.
class _LockedLine {
  const _LockedLine({required this.title, this.subtitle});

  final String title;
  final String? subtitle;
}

/// Le bloc « il y en a d'autres » : un échantillon **réel, flouté**, et le
/// compte exact de ce qui reste.
///
/// 🛑 **Rien n'est fabriqué derrière le flou.** Les lignes viennent des
/// observations du serveur ; on ne compose jamais de fausse priorité pour
/// remplir. Le flou est un rideau posé sur du vrai, pas un décor.
///
/// Il est `ExcludeSemantics` + `IgnorePointer` : ce qui est illisible à l'œil
/// doit l'être aussi au lecteur d'écran, sinon le verrou ne tient pas.
class _LockedPreview extends StatelessWidget {
  const _LockedPreview({
    required this.lines,
    required this.label,
    required this.onSubscribe,
  });

  final List<_LockedLine> lines;
  final String label;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Le rideau partagé du produit (`core/widgets/blurred_content.dart`) :
          // `ExcludeSemantics` + `IgnorePointer` + flou, déclarés à un seul
          // endroit.
          BlurredContent(
            sigma: 5,
            child: Column(
              children: [
                for (final line in lines)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
                    child: Row(
                      children: [
                        const PremiumLockPill(size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                line.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppFonts.ui(
                                  size: 14,
                                  weight: FontWeight.w600,
                                ),
                              ),
                              if (line.subtitle != null)
                                Text(
                                  line.subtitle!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppFonts.ui(
                                    size: 12,
                                    color: AppColors.inkFaint,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Material(
            color: AppColors.surface2,
            child: InkWell(
              // Le même parcours d'achat que partout ailleurs
              // (`showTcfLockPaywall`) : jamais un second chemin.
              onTap: onSubscribe,
              child: Container(
                padding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.lineSoft)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.lock,
                      size: 15,
                      color: AppColors.inkFaint,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        label,
                        style: AppFonts.ui(
                          size: 13.5,
                          weight: FontWeight.w700,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      kUnlockPlanCta,
                      style: AppFonts.ui(
                        size: 13.5,
                        weight: FontWeight.w700,
                        color: AppColors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// La variante **en pointillés** du même verrou, posée à l'intérieur d'une
/// carte : elle n'a pas de contenu à flouter, seulement un compte. C'est le cas
/// des entraînements de la séance, dont le premier tient déjà dans la carte
/// au-dessus.
class _LockedMoreBar extends StatelessWidget {
  const _LockedMoreBar({required this.label, required this.onSubscribe});

  final String label;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: Material(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: InkWell(
            onTap: onSubscribe,
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: CustomPaint(
              painter: const _DashedBorderPainter(),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.lock,
                      size: 15,
                      color: AppColors.inkFaint,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        label,
                        style: AppFonts.ui(
                          size: 13.5,
                          weight: FontWeight.w700,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

/// Le liseré **en pointillés** de [_LockedMoreBar]. Flutter n'a pas de
/// `BorderStyle.dashed` : le trait se peint, il ne se déclare pas. Il dit « il
/// y a de la place ici, elle n'est pas encore ouverte » — un trait plein aurait
/// dessiné un contenu, alors qu'il n'y en a pas derrière.
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter();

  static const double _dash = 5;
  static const double _gap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(AppRadii.md),
        ),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = distance + _dash;
        canvas.drawPath(
          metric.extractPath(
            distance,
            end < metric.length ? end : metric.length,
          ),
          paint,
        );
        distance = end + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// La barre collante
// ---------------------------------------------------------------------------

/// La barre d'action du bilan : **une seule action principale**, et laquelle
/// dépend de ce qu'il reste à faire.
///
/// - Il reste un domaine de **compréhension** à mesurer et le candidat a choisi
///   le diagnostic complet ⇒ l'action ouvre la fiche de ce domaine, où vit
///   déjà le geste qui lance son examen blanc. Le plan reste accessible juste
///   en dessous.
/// - Sinon ⇒ le plan personnalisé, fin naturelle du diagnostic.
///
/// 🛑 **Le choix du parcours à ouvrir n'est pas recopié ici.** Décider quoi
/// lancer selon `PlanDomainAssessmentKind` vivait en deux copies côté Plan ;
/// elles ont été fondues dans [openPlanAssessment], le point d'entrée public
/// que cette barre appelle comme la fiche d'un domaine. Trois copies auraient
/// fini par ouvrir trois écrans différents pour le même domaine. La légende dit
/// dès ici ce qu'il y a derrière ([planAssessmentMeta]) : « Examen blanc n°1 ·
/// ≈ 20 min », jamais une promesse plus vague que le geste.
class _ResultActionBar extends StatelessWidget {
  const _ResultActionBar({required this.next, required this.onOpenPlan});

  /// Le prochain domaine de compréhension à mesurer, **déjà désigné par le
  /// serveur**. `null` est le cas courant : profil complet, ou diagnostic
  /// rapide — ni l'un ni l'autre n'est une anomalie.
  final PlanDomainAssessment? next;

  final VoidCallback onOpenPlan;

  @override
  Widget build(BuildContext context) {
    final assessment = next;
    final label = assessment == null
        ? kDiagnosticCtaPlan
        : 'Mesurer ma ${planDomainLabel(assessment.epreuve).toLowerCase()}';
    final caption = assessment == null
        ? 'Basé sur vos réponses · vous pourrez commencer par un exercice'
        : planAssessmentMeta(assessment);
    return FixedActionBar(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: true,
            label: label,
            child: AppButton(
              label: label,
              iconRight: LucideIcons.arrowRight,
              onPressed: assessment == null
                  ? onOpenPlan
                  : () => openPlanAssessment(context, assessment),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            caption,
            textAlign: TextAlign.center,
            style: AppFonts.ui(
              size: 10.5,
              weight: FontWeight.w700,
              color: AppColors.inkFaint,
              height: 1.35,
            ),
          ),
          if (assessment != null) ...[
            const SizedBox(height: 4),
            AppButton(
              label: kDiagnosticCtaPlan,
              variant: AppButtonVariant.ghost,
              height: 44,
              onPressed: onOpenPlan,
            ),
          ],
        ],
      ),
    );
  }
}
