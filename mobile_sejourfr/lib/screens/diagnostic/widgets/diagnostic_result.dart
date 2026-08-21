import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/diagnostic_models.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/skill_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/evidence_excerpt.dart';
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
import '../../plan/widgets/plan_profile_section.dart';
import '../../plan/widgets/plan_tokens.dart';
import '../../tcf_production/widgets/action_plan.dart';
import '../diagnostic_variant.dart';

/// L'appel à l'action du verrou de ce rapport. **Ce n'est pas un second chemin
/// d'achat** : il déclenche `onSubscribe`, donc `showTcfLockPaywall`, comme le
/// Plan et le module Compétences. Wording neutre (guidelines Apple 3.1.1) : ni
/// prix, ni verbe d'achat.
const String kUnlockPlanCta = 'Débloquer mon Plan';

/// L'eyebrow du rapport, selon que le compte a l'accès TCF ou non.
///
/// ⚠️ **Vouvoiement**, comme tout le diagnostic et tout le Plan (cf. CLAUDE.md
/// racine : « le Plan vouvoie, contrairement au module Compétences »). La
/// maquette tutoie parce qu'elle décrit un visiteur d'avant l'inscription ;
/// cet écran, lui, n'existe qu'une fois le compte créé.
const String kResultEyebrowFull = 'RAPPORT COMPLET';
const String kResultEyebrowFree = 'VOTRE RAPPORT DE DIAGNOSTIC';

/// Écran de fin de diagnostic, refondu sur la maquette premium mobile.
///
/// Il s'adresse à un visiteur venu des réseaux qui vient de rendre ses deux
/// productions : il lui dit **où il en est**, **par où commencer**, lui montre
/// **une différence concrète sur sa propre phrase**, puis lui présente son plan
/// et l'offre. Rien n'y est décoratif — chaque bloc rend une donnée que le
/// serveur a réellement produite, et **un bloc sans donnée n'est pas rendu**
/// (jamais de squelette, jamais de « non disponible »).
///
/// Trois choses de la maquette sont volontairement **non reprises** :
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

  /// Accès TCF réel du compte (`AuthUser.hasTcf`). Il ne sert qu'à **choisir la
  /// pastille** des étapes à venir et à décider si l'offre est présentée :
  /// aucune règle de verrou n'est recalculée ici — celle de l'exercice
  /// recommandé vient de `PlanRecommendedExercise.locked`, posé par le serveur.
  final bool hasTcfAccess;

  final VoidCallback onOpenPlan;
  final ValueChanged<PlanRecommendedExercise> onOpenRecommended;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focus = _focusItems(result);
    final solid = _solidSkills(result);
    final steps = _planSteps(result, hasTcfAccess: hasTcfAccess);
    final exemple = result.exempleCible;

    // Le Plan n'est lu qu'**ici**, sur l'écran de résultat d'un compte
    // authentifié : c'est la seule source de l'état du profil (quels domaines
    // sont mesurés) et de ce qui reste à mesurer. Son absence — chargement,
    // réseau — est un cas NORMAL : les blocs concernés ne sont pas rendus, rien
    // n'est deviné et rien ne signale d'erreur.
    final plan = ref.watch(learningPlanProvider).valueOrNull;
    final pending = _comprehensionToAssess(plan);

    // **Le compteur est calculé sur ce que le serveur a renvoyé**, jamais sur
    // une constante de maquette : `focus`, `solid` et `steps` sont les listes
    // entières, on n'en tranche que l'affichage. Moins d'éléments que le seuil
    // ⇒ `hidden == 0` ⇒ **le bloc verrouillé n'existe pas** et tout est en
    // clair — un compte gratuit avec deux priorités n'a rien de masqué à lui
    // vendre.
    final visibleFocus =
        hasTcfAccess ? focus : focus.take(_kFreeFocusVisible).toList();
    final hiddenFocus = focus.length - visibleFocus.length;
    final visibleSolid =
        hasTcfAccess ? solid : solid.take(_kFreeSolidVisible).toList();
    final hiddenSolid = solid.length - visibleSolid.length;
    final visibleSteps =
        hasTcfAccess ? steps : steps.take(_kFreeStepsVisible).toList();
    final hiddenSteps = steps.length - visibleSteps.length;

    return Stack(
      children: [
        ListView(
          // La réserve du bas laisse passer tout le contenu sous le CTA
          // collant : rien n'est jamais masqué par la barre.
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 132),
          children: [
            const _DoneBadge(),
            const SizedBox(height: 14),
            Text(
              hasTcfAccess ? kResultEyebrowFull : kResultEyebrowFree,
              style: AppFonts.eyebrow(color: AppColors.blue),
            ),
            const SizedBox(height: 10),
            const _ResultTitle(),
            const SizedBox(height: 10),
            Text(
              _intro(focus.length),
              style: AppFonts.ui(
                size: 14.5,
                color: AppColors.inkSoft,
                height: 1.5,
              ),
            ),
            // Le geste d'abonnement est offert en tête **et** en fin : c'est
            // le même `onSubscribe`, donc la même feuille, jamais un second
            // parcours d'achat.
            if (!hasTcfAccess) ...[
              const SizedBox(height: 14),
              Semantics(
                button: true,
                label: kUnlockPlanCta,
                child: AppButton(
                  label: kUnlockPlanCta,
                  iconRight: LucideIcons.arrowRight,
                  height: 48,
                  onPressed: onSubscribe,
                ),
              ),
            ],
            const SizedBox(height: 18),
            _LevelsHero(
              written: result.written?.levelEstimate,
              oral: result.oral?.levelEstimate,
              objective: objective,
              railLevel: _railLevel(result),
            ),
            if (plan != null) ...[
              const SizedBox(height: 10),
              _ProfileStrip(plan: plan),
            ],
            const SizedBox(height: 10),
            const _EstimationNote(),
            // **Diagnostic complet** : la compréhension se mesure maintenant.
            // Le bloc est hissé juste sous le profil, avant même les priorités
            // — c'est ce que le candidat est venu chercher en le choisissant.
            if (variant.isComplet && pending.isNotEmpty) ...[
              const SizedBox(height: 22),
              const _SectionHead(
                kicker: 'IL RESTE DEUX ÉPREUVES À MESURER',
                title: 'Complétez votre profil TCF.',
                description:
                    'Vos deux productions sont analysées. La compréhension se '
                    'mesure par un examen blanc — elle n’était pas jouable '
                    'avant que votre compte existe.',
              ),
              const SizedBox(height: 13),
              PlanCompleteProfileSection(assessments: pending),
            ],
            if (visibleFocus.isNotEmpty) ...[
              const SizedBox(height: 14),
              _FocusCard(focus: visibleFocus),
              if (hiddenFocus > 0) ...[
                const SizedBox(height: 9),
                _LockedPreview(
                  lines: [
                    for (final item in focus
                        .skip(visibleFocus.length)
                        .take(_kBlurredSample))
                      _LockedLine(
                        title: item.title,
                        subtitle: item.section?.label,
                      ),
                  ],
                  label: '+ $hiddenFocus autre${_plural(hiddenFocus)} '
                      'priorité${_plural(hiddenFocus)} '
                      'détectée${_plural(hiddenFocus)}',
                  onSubscribe: onSubscribe,
                ),
              ],
            ],
            if (exemple != null) ...[
              const SizedBox(height: 26),
              const _SectionHead(
                kicker: 'EXEMPLE TIRÉ DE VOTRE PRODUCTION',
                title: 'Voyez ce qui vous sépare du niveau supérieur.',
                description:
                    'Une petite différence de formulation peut rendre votre '
                    'réponse beaucoup plus riche.',
              ),
              const SizedBox(height: 13),
              _BeforeAfter(exemple: exemple),
            ],
            if (visibleSteps.isNotEmpty) ...[
              const SizedBox(height: 26),
              const _SectionHead(
                kicker: 'VOTRE PLAN PERSONNALISÉ',
                title: 'L’application sait déjà quoi vous faire travailler.',
                description:
                    'Votre plan se réorganise ensuite selon vos nouvelles '
                    'productions.',
              ),
              const SizedBox(height: 13),
              _PlanPreviewCard(
                steps: visibleSteps,
                hiddenSteps: hiddenSteps,
                exercise: result.nextAction,
                onOpenRecommended: onOpenRecommended,
                onSubscribe: onSubscribe,
              ),
            ],
            if (visibleSolid.isNotEmpty || result.strengths.isNotEmpty) ...[
              const SizedBox(height: 26),
              const _SectionHead(
                kicker: 'VOS ACQUIS',
                title: 'Vous avez déjà de bonnes bases.',
                description:
                    'Le détail reste disponible, mais il ne prend plus toute '
                    'la place dans le bilan.',
              ),
              const SizedBox(height: 13),
              if (result.strengths.isNotEmpty) ...[
                _StrengthsCard(strengths: result.strengths.take(3).toList()),
                if (visibleSolid.isNotEmpty) const SizedBox(height: 9),
              ],
              for (final skill in visibleSolid)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _AcquisRow(skill: skill),
                ),
              if (hiddenSolid > 0)
                _LockedPreview(
                  lines: [
                    for (final skill in solid
                        .skip(visibleSolid.length)
                        .take(_kBlurredSample))
                      _LockedLine(
                        title: skill.skillTitle,
                        subtitle: skill.section.label,
                      ),
                  ],
                  label: '+ $hiddenSolid autre${_plural(hiddenSolid)} '
                      'compétence${_plural(hiddenSolid)} déjà '
                      'solide${_plural(hiddenSolid)}',
                  onSubscribe: onSubscribe,
                ),
            ],
            // **Diagnostic rapide** : la même proposition, mais à sa place —
            // en bas, comme une suite possible. Un domaine non mesuré n'est
            // jamais présenté comme une faiblesse : il manque des données.
            if (!variant.isComplet && pending.isNotEmpty) ...[
              const SizedBox(height: 26),
              const _SectionHead(
                kicker: 'QUAND VOUS VOULEZ',
                title: 'Complétez votre profil TCF.',
                description:
                    'La compréhension orale et écrite n’a pas encore été '
                    'mesurée. Ce n’est pas une faiblesse : il manque des '
                    'données, et un examen blanc suffit à les produire.',
              ),
              const SizedBox(height: 13),
              PlanCompleteProfileSection(assessments: pending),
            ],
            if (result.written != null || result.oral != null) ...[
              const SizedBox(height: 22),
              const _SectionHead(
                kicker: 'LE DÉTAIL',
                title: 'Vos deux productions',
                description: 'Ce que chaque production a montré.',
              ),
              const SizedBox(height: 13),
              if (result.written != null)
                _ProductionCard(
                  title: 'Expression écrite',
                  icon: LucideIcons.penLine,
                  accent: AppColors.blue,
                  accentSoft: AppColors.blueLight,
                  production: result.written!,
                ),
              if (result.written != null && result.oral != null)
                const SizedBox(height: 9),
              if (result.oral != null)
                _ProductionCard(
                  title: 'Expression orale',
                  icon: LucideIcons.mic,
                  accent: AppColors.red,
                  accentSoft: AppColors.redLight,
                  production: result.oral!,
                ),
            ],
            // L'offre ferme le rapport : le candidat a d'abord lu **ses**
            // niveaux, **ses** priorités et **ses** deux productions.
            if (!hasTcfAccess) ...[
              const SizedBox(height: 26),
              _ValueCard(onSubscribe: onSubscribe),
            ],
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
            next: variant.isComplet && pending.isNotEmpty ? pending.first : null,
            onOpenPlan: onOpenPlan,
          ),
        ),
      ],
    );
  }

  String _intro(int focusCount) {
    if (focusCount == 0) {
      return 'Pas besoin de tout revoir. Votre diagnostic montre par où '
          'commencer pour progresser plus vite.';
    }
    final priorites = focusCount > 1 ? 'priorités' : 'priorité';
    return 'Pas besoin de tout revoir. Votre diagnostic a identifié '
        '$focusCount $priorites pour progresser plus vite.';
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

/// Où placer le candidat sur le rail `A2 → B1 → B2`.
///
/// C'est le **plancher** des deux productions — la même règle que le niveau
/// d'un candidat côté serveur : une seule production réussie ne prouve pas le
/// palier. Sous le A2, le rail reste **éteint** plutôt que de faire commencer
/// tout le monde au premier barreau : `null` veut dire « pas encore sur cette
/// échelle », jamais « A2 ».
TargetLevel? _railLevel(DiagnosticResult result) {
  final written = result.written?.levelEstimate;
  final oral = result.oral?.levelEstimate;
  final levels = <NiveauCecrl>[
    if (written != null) written,
    if (oral != null) oral,
  ];
  if (levels.isEmpty) return null;
  var floor = levels.first;
  for (final level in levels) {
    if (level.tcfPalierIndex < floor.tcfPalierIndex) floor = level;
  }
  return switch (floor) {
    NiveauCecrl.a1NonAtteint || NiveauCecrl.a1 => null,
    NiveauCecrl.a2 => TargetLevel.a2,
    NiveauCecrl.b1 => TargetLevel.b1,
    NiveauCecrl.b2 || NiveauCecrl.c1 || NiveauCecrl.c2 => TargetLevel.b2,
  };
}

/// Une ligne de la carte « Votre progression se joue surtout ici ».
///
/// [ranked] distingue les **priorités mesurées** par le serveur (numérotées)
/// des replis : ces derniers ne portent pas de rang, parce qu'ils ne sont pas
/// un classement.
///
/// Elle porte **tout ce que le serveur publie** sur une priorité
/// (`DiagnosticSkillObservationDto`) et que le candidat a le droit de lire :
/// `explanation`, `evidence`, `status` et `section`. `confidence` en est
/// volontairement absente — elle n'est **jamais** montrée au candidat.
class _FocusItem {
  const _FocusItem({
    required this.title,
    required this.ranked,
    this.detail,
    this.evidence,
    this.status,
    this.section,
  });

  final String title;
  final String? detail;
  final String? evidence;
  final LearningPlanSkillStatus? status;
  final SkillSection? section;
  final bool ranked;

  /// Y a-t-il quelque chose à déplier ? Un repli tiré des `weaknesses` n'est
  /// qu'un titre : sa ligne reste alors **inerte**, sans chevron.
  bool get hasReport =>
      detail != null || evidence != null || status != null || section != null;
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
  if (result.priorities.isNotEmpty) {
    return result.priorities
        .indexed
        .map(
          (entry) => _FocusItem(
            title: entry.$2.skillTitle,
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
        .toList(growable: false);
  }

  final observed = <_FocusItem>[];
  final seen = <String>{};
  for (final production in [result.written, result.oral]) {
    for (final skill in production?.skills ?? const <DiagnosticSkillObservation>[]) {
      if (!skill.observed) continue;
      if (skill.status == LearningPlanSkillStatus.solid) continue;
      if (skill.status == LearningPlanSkillStatus.notObserved) continue;
      if (!seen.add(skill.skillId)) continue;
      observed.add(
        _FocusItem(
          title: skill.skillTitle,
          detail: skill.explanation,
          evidence: skill.evidence,
          status: skill.status,
          section: skill.section,
          ranked: false,
        ),
      );
    }
  }
  if (observed.isNotEmpty) return List.unmodifiable(observed);

  final weaknesses = <_FocusItem>[];
  for (final production in [result.written, result.oral]) {
    for (final weakness in production?.weaknesses ?? const <String>[]) {
      weaknesses.add(_FocusItem(title: weakness, ranked: false));
    }
  }
  return List.unmodifiable(weaknesses);
}

/// Les compétences que les deux productions ont montrées **solides**,
/// dédoublonnées par `skillId`. Rendue **entière** pour la même raison que
/// [_focusItems] : c'est elle qui fait le compteur.
List<DiagnosticSkillObservation> _solidSkills(DiagnosticResult result) {
  final seen = <String>{};
  final solid = <DiagnosticSkillObservation>[];
  for (final production in [result.written, result.oral]) {
    for (final skill in production?.skills ?? const <DiagnosticSkillObservation>[]) {
      if (!skill.observed) continue;
      if (skill.status != LearningPlanSkillStatus.solid) continue;
      if (!seen.add(skill.skillId)) continue;
      solid.add(skill);
    }
  }
  return List.unmodifiable(solid);
}

/// Une étape de l'aperçu du plan.
class _PlanStep {
  const _PlanStep({
    required this.title,
    required this.subtitle,
    required this.state,
  });

  final String title;
  final String subtitle;
  final _StepState state;
}

enum _StepState {
  /// L'étape que le candidat peut commencer tout de suite.
  open,

  /// L'étape est **entièrement lisible**, seul son accès demande un
  /// abonnement.
  locked,

  /// Étape suivante d'un compte qui a déjà l'accès.
  upcoming,
}

/// Les trois étapes de l'aperçu : l'exercice recommandé, puis les priorités
/// suivantes, puis la vérification en situation si la place reste.
///
/// **Aucun titre n'est masqué** : le cadenas porte sur l'accès, jamais sur
/// l'information.
List<_PlanStep> _planSteps(
  DiagnosticResult result, {
  required bool hasTcfAccess,
}) {
  final exercise = result.nextAction;
  final steps = <_PlanStep>[];

  if (exercise != null) {
    steps.add(
      _PlanStep(
        title: exercise.title,
        subtitle: exercise.kind == PlanExerciseKind.reassessment
            ? 'Vérification en situation · ${exercise.estimatedMinutes} min'
            : 'Exercice ciblé · ${exercise.estimatedMinutes} min',
        state: exercise.locked ? _StepState.locked : _StepState.open,
      ),
    );
  } else if (result.priorities.isNotEmpty) {
    steps.add(
      _PlanStep(
        title: result.priorities.first.skillTitle,
        subtitle: 'Exercice ciblé',
        state: hasTcfAccess ? _StepState.open : _StepState.locked,
      ),
    );
  }

  final nextState = hasTcfAccess ? _StepState.upcoming : _StepState.locked;
  for (final priority in result.priorities.skip(1).take(2)) {
    if (steps.length >= 3) break;
    steps.add(
      _PlanStep(
        title: priority.skillTitle,
        subtitle: 'Exercice ciblé',
        state: nextState,
      ),
    );
  }
  if (steps.isNotEmpty && steps.length < 3) {
    steps.add(
      _PlanStep(
        title: 'Nouvelle production évaluée par IA',
        subtitle: 'Vérifier votre progression',
        state: nextState,
      ),
    );
  }
  return steps;
}

// ---------------------------------------------------------------------------
// En-tête
// ---------------------------------------------------------------------------

class _DoneBadge extends StatelessWidget {
  const _DoneBadge();

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
          decoration: BoxDecoration(
            color: AppColors.greenLight,
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.check,
                  size: 12,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                'Diagnostic terminé',
                style: AppFonts.ui(
                  size: 11.5,
                  weight: FontWeight.w800,
                  color: AppColors.green,
                ),
              ),
            ],
          ),
        ),
      );
}

class _ResultTitle extends StatelessWidget {
  const _ResultTitle();

  @override
  Widget build(BuildContext context) {
    final base = AppFonts.display(size: 30, height: 1.05);
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          const TextSpan(text: 'On sait maintenant '),
          TextSpan(
            text: 'quoi travailler.',
            style: base.copyWith(color: AppColors.blue),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Niveaux estimés
// ---------------------------------------------------------------------------

class _LevelsHero extends StatelessWidget {
  const _LevelsHero({
    required this.written,
    required this.oral,
    required this.objective,
    required this.railLevel,
  });

  final NiveauCecrl? written;
  final NiveauCecrl? oral;
  final String? objective;

  /// Le barreau allumé du rail `A2 → B1 → B2`. `null` = pas encore sur cette
  /// échelle : aucun point n'est allumé, on ne place personne par défaut.
  final TargetLevel? railLevel;

  @override
  Widget build(BuildContext context) {
    return GradientHero(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VOTRE NIVEAU ESTIMÉ AUJOURD’HUI',
            style: AppFonts.label(
              color: AppColors.white.withValues(alpha: 0.76),
            ),
          ),
          const SizedBox(height: 12),
          // IntrinsicHeight : les deux blocs de niveau doivent avoir la même
          // hauteur, or un `stretch` dans une colonne scrollable n'a pas de
          // contrainte de hauteur.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _LevelBlock(
                    icon: LucideIcons.penLine,
                    label: 'Expression écrite',
                    level: written,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _LevelBlock(
                    icon: LucideIcons.mic,
                    label: 'Expression orale',
                    level: oral,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          // Le rail du Plan, repris tel quel : le candidat doit retrouver
          // **la même** échelle d'un écran à l'autre.
          PlanLevelRail(current: railLevel, onDark: true),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.only(top: 13),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppColors.white.withValues(alpha: 0.16),
                ),
              ),
            ),
            child: Row(
              children: [
                if (objective != null) ...[
                  Icon(
                    LucideIcons.target,
                    size: 14,
                    color: AppColors.white.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Objectif : $objective',
                      style: AppFonts.ui(
                        size: 12,
                        color: AppColors.white,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                const Spacer(),
                Text(
                  'Estimation pédagogique',
                  style: AppFonts.ui(
                    size: 11.5,
                    color: AppColors.white.withValues(alpha: 0.72),
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

class _LevelBlock extends StatelessWidget {
  const _LevelBlock({
    required this.icon,
    required this.label,
    required this.level,
  });

  final IconData icon;
  final String label;
  final NiveauCecrl? level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: AppColors.white.withValues(alpha: 0.8)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  style: AppFonts.ui(
                    size: 11.5,
                    weight: FontWeight.w600,
                    color: AppColors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            level?.shortName ?? '—',
            style: AppFonts.display(size: 36, color: AppColors.white),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Où en est le profil TCF
// ---------------------------------------------------------------------------

/// L'état des **quatre domaines** du TCF, juste sous les deux niveaux que le
/// diagnostic vient d'estimer : « 2 domaines sur 4 évalués », puis une case par
/// domaine.
///
/// 🛑 **Un domaine non mesuré n'est pas une faiblesse : il est inconnu.** Il
/// garde donc sa case, un tiret à la place du niveau, et **aucun niveau ne lui
/// est prêté** — pas plus qu'une teinte d'alerte ou une pastille « à évaluer ».
/// C'est la règle du Plan (`kPlanNotEvaluatedNote`), et c'est ce qui rend la
/// proposition de compléter le profil lisible comme une suite possible, jamais
/// comme un reproche.
///
/// L'ordre est **celui servi** : le serveur trie les domaines par urgence,
/// aucun front ne retrie. Le décompte vient de [planProfileCoverage], la
/// formule déjà employée par « Mon profil TCF » — un même fait se dit de la
/// même façon des deux côtés.
class _ProfileStrip extends StatelessWidget {
  const _ProfileStrip({required this.plan});

  final LearningPlan plan;

  @override
  Widget build(BuildContext context) {
    final domains = plan.domaines;
    // Un plan sans domaine servi n'est pas une anomalie à signaler : la bande
    // n'existe simplement pas.
    if (domains.isEmpty) return const SizedBox.shrink();
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 12, 15, 11),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.layoutGrid,
                  size: 14,
                  color: AppColors.blue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    planProfileCoverage(plan.cycle, domains.length),
                    style: AppFonts.ui(
                      size: 13,
                      weight: FontWeight.w700,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Les quatre cases ont la même hauteur quel que soit le domaine dont
          // le nom court passe à la ligne.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < domains.length; i++)
                  Expanded(
                    child: _ProfileCell(domain: domains[i], first: i == 0),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Une case de la bande : l'icône du domaine, son niveau estimé — ou un tiret —
/// et son abrégé. Elle ouvre la fiche du domaine, où vivent ses paliers et de
/// quoi le mesurer.
class _ProfileCell extends StatelessWidget {
  const _ProfileCell({required this.domain, required this.first});

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
                top: const BorderSide(color: AppColors.lineSoft),
                left: first
                    ? BorderSide.none
                    : const BorderSide(color: AppColors.lineSoft),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  planDomainIcon(domain.epreuve),
                  size: 14,
                  color: measured ? AppColors.blue : AppColors.inkFaint,
                ),
                const SizedBox(height: 5),
                Text(
                  measured ? domain.niveau!.shortName : '—',
                  style: AppFonts.display(
                    size: 17,
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

class _EstimationNote extends StatelessWidget {
  const _EstimationNote();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(LucideIcons.info, size: 14, color: AppColors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Cette estimation est pédagogique : elle ne remplace pas un '
                'résultat officiel du TCF.',
                style: AppFonts.ui(
                  size: 11.5,
                  height: 1.4,
                  color: AppColors.inkFaint,
                ),
              ),
            ),
          ],
        ),
      );
}

// ---------------------------------------------------------------------------
// Sections
// ---------------------------------------------------------------------------

class _SectionHead extends StatelessWidget {
  const _SectionHead({required this.title, this.kicker, this.description});

  final String title;
  final String? kicker;
  final String? description;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (kicker != null) ...[
              Text(kicker!, style: AppFonts.eyebrow(color: AppColors.blue)),
              const SizedBox(height: 6),
            ],
            Text(title, style: AppFonts.display(size: 22, height: 1.1)),
            if (description != null) ...[
              const SizedBox(height: 5),
              Text(
                description!,
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

/// « Votre progression se joue surtout ici » : les priorités du serveur, ou son
/// repli. Teinte **ambre**, jamais rouge : on nomme un levier, pas un manque.
class _FocusCard extends StatelessWidget {
  const _FocusCard({required this.focus});

  final List<_FocusItem> focus;

  @override
  Widget build(BuildContext context) {
    final ranked = focus.first.ranked;
    return AppCard(
      padding: const EdgeInsets.all(18),
      boxShadow: AppShadows.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 39,
                height: 39,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.amberLight,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  LucideIcons.trendingUp,
                  size: 19,
                  color: AppColors.amberDark,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ranked
                          ? 'Votre progression se joue surtout ici.'
                          : 'Ce que vos productions ont montré.',
                      style: AppFonts.display(size: 20, height: 1.12),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      ranked
                          ? 'Les compétences qui vous feront gagner le plus '
                              'rapidement en niveau.'
                          : 'Les éléments qui reviennent dans vos deux '
                              'réponses.',
                      style: AppFonts.ui(
                        size: 12.5,
                        height: 1.45,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          for (var index = 0; index < focus.length; index++) ...[
            if (index > 0) const SizedBox(height: 8),
            _FocusRow(item: focus[index], rank: index + 1),
          ],
        ],
      ),
    );
  }
}

/// Une priorité, **repliée par défaut**, qui s'ouvre sur le rapport **entier**
/// du correcteur — même idiome que [_AcquisRow] (chevron qui pivote,
/// [AnimatedSize], `Semantics.expanded`), pas une seconde mécanique.
///
/// Replié, on lit le rang, la compétence et l'épreuve d'où vient l'observation.
/// **Aucun texte ellipsé** : l'explication du correcteur arrivait coupée en
/// plein milieu (« …est une er… »), c'est-à-dire au moment précis où elle
/// devenait utile. Elle vit maintenant dans le dépliant, en entier.
///
/// La flèche ↗ d'avant était purement décorative — elle n'ouvrait rien. Le
/// chevron la remplace : il annonce ce que le tap fait vraiment.
class _FocusRow extends StatefulWidget {
  const _FocusRow({required this.item, required this.rank});

  final _FocusItem item;
  final int rank;

  @override
  State<_FocusRow> createState() => _FocusRowState();
}

class _FocusRowState extends State<_FocusRow> {
  bool _open = false;

  /// L'intensité de l'ambre **décroît du rang 1 au rang 3** : la teinte dit le
  /// rang au lieu de décorer trois pastilles identiques. Dérivée de
  /// [AppColors.amber] vers le blanc — aucun token de plus, et le rang 2 retombe
  /// par construction sur `amberLight`.
  static Color _rankFill(int rank) {
    const alphas = <double>[0.28, 0.17, 0.09];
    final alpha = alphas[(rank - 1).clamp(0, alphas.length - 1)];
    return Color.alphaBlend(
      AppColors.amber.withValues(alpha: alpha),
      AppColors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final rank = widget.rank;
    final detail = item.detail;
    final evidence = item.evidence;
    final expandable = item.hasReport;

    // L'épreuve d'où vient l'observation, et le verdict porté sur elle : deux
    // faits courts, qui remplacent au repos la phrase tronquée d'avant.
    final meta = <String>[
      if (item.section != null) item.section!.label,
      if (item.status != null) item.status!.label,
    ].join(' · ');

    final header = Padding(
      padding: const EdgeInsets.all(11),
      child: Row(
        children: [
          Container(
            width: 27,
            height: 27,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: item.ranked ? _rankFill(rank) : AppColors.amberLight,
              borderRadius: BorderRadius.circular(9),
            ),
            child: item.ranked
                ? Text(
                    '$rank',
                    style: AppFonts.display(
                      size: 12,
                      color: AppColors.amberDark,
                    ),
                  )
                : const Icon(
                    LucideIcons.dot,
                    size: 18,
                    color: AppColors.amberDark,
                  ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppFonts.ui(
                    size: 13,
                    weight: FontWeight.w700,
                    height: 1.28,
                  ),
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    meta,
                    style: AppFonts.ui(
                      size: 11,
                      height: 1.35,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (expandable) ...[
            const SizedBox(width: 8),
            AnimatedRotation(
              turns: _open ? 0.5 : 0,
              duration: const Duration(milliseconds: 180),
              child: const Icon(
                LucideIcons.chevronDown,
                size: 17,
                color: AppColors.amberDark,
              ),
            ),
          ],
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.line2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (expandable)
            Semantics(
              button: true,
              expanded: _open,
              label: meta.isEmpty ? item.title : '${item.title} · $meta',
              child: InkWell(
                onTap: () => setState(() => _open = !_open),
                borderRadius: BorderRadius.circular(15),
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
                    padding: const EdgeInsets.fromLTRB(49, 0, 11, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (detail != null)
                          Text(
                            detail,
                            style: AppFonts.ui(
                              size: 11.5,
                              height: 1.45,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        // La citation est la phrase du candidat lui-même, et le
                        // dépliant est ouvert à sa demande : elle est rendue
                        // **entière**, sans l'`evidenceExcerpt` qui borne les
                        // surfaces repliées (carte d'étape du Plan, acquis).
                        if (evidence != null) ...[
                          if (detail != null) const SizedBox(height: 7),
                          Text(
                            '« ${evidence.trim()} »',
                            style: AppFonts.ui(
                              size: 11.5,
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
// Avant / après
// ---------------------------------------------------------------------------

/// La phrase du candidat, puis la même réécrite au niveau visé.
///
/// La seconde carte est **`ActionPlanExempleCard`**, la brique déjà employée
/// par le rapport d'une production et par le résultat d'un micro-exercice :
/// même surlignage par recherche de sous-chaîne, mêmes lignes « extrait →
/// apport », aucune seconde mécanique. Un extrait introuvable est ignoré, le
/// texte reste lisible.
class _BeforeAfter extends StatelessWidget {
  const _BeforeAfter({required this.exemple});

  final DiagnosticExempleCible exemple;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VOTRE FORMULATION',
                style: AppFonts.label(size: 10, color: AppColors.inkFaint),
              ),
              const SizedBox(height: 7),
              Text(
                '« ${exemple.original} »',
                style: AppFonts.ui(
                  size: 13,
                  height: 1.55,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 9),
        Center(
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.blueLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.arrowDown,
              size: 16,
              color: AppColors.blue,
            ),
          ),
        ),
        const SizedBox(height: 9),
        ActionPlanExempleCard(
          exemple: exemple.asActionPlanExemple,
          label: 'VERSION PLUS RICHE',
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Aperçu du plan
// ---------------------------------------------------------------------------

class _PlanPreviewCard extends StatelessWidget {
  const _PlanPreviewCard({
    required this.steps,
    required this.hiddenSteps,
    required this.exercise,
    required this.onOpenRecommended,
    required this.onSubscribe,
  });

  /// Ce qui est **affiché**. Un compte sans accès n'en voit qu'un.
  final List<_PlanStep> steps;

  /// Combien d'entraînements de la séance restent derrière le verrou. `0` pour
  /// un abonné, et **`0` aussi** quand la séance en compte moins que le seuil —
  /// la barre n'existe alors pas.
  final int hiddenSteps;
  final PlanRecommendedExercise? exercise;
  final ValueChanged<PlanRecommendedExercise> onOpenRecommended;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    final action = exercise;
    return AppCard(
      padding: const EdgeInsets.all(16),
      boxShadow: AppShadows.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Plan de progression',
                  style: AppFonts.display(size: 19),
                ),
              ),
              const SizedBox(width: 10),
              const AppTag(
                label: 'Adapté par IA',
                icon: LucideIcons.sparkles,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (var index = 0; index < steps.length; index++) ...[
            if (index > 0) const SizedBox(height: 9),
            _PlanStepRow(step: steps[index], number: index + 1),
          ],
          if (hiddenSteps > 0) ...[
            const SizedBox(height: 9),
            _LockedMoreBar(
              label: '+ $hiddenSteps autre${_plural(hiddenSteps)} '
                  'entraînement${_plural(hiddenSteps)} '
                  'personnalisé${_plural(hiddenSteps)}',
              onSubscribe: onSubscribe,
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: 14),
            AppButton(
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
          ],
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
  const _PlanStepRow({required this.step, required this.number});

  final _PlanStep step;
  final int number;

  @override
  Widget build(BuildContext context) {
    final row = _row();
    if (step.state != _StepState.locked) return row;
    // Le voile de la maquette (`.step.locked:after`) : l'étape reste
    // **entièrement lisible**, elle recule d'un plan. Il couvre la ligne
    // entière, pastille comprise, comme le `inset:0` du HTML.
    return Stack(
      children: [
        row,
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.bg.withValues(alpha: 0.46),
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _row() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.line2),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.blueLight,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Text(
              number.toString().padLeft(2, '0'),
              style: AppFonts.display(size: 13, color: AppColors.blue),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: AppFonts.ui(
                    size: 12.5,
                    weight: FontWeight.w700,
                    height: 1.28,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  step.subtitle,
                  style: AppFonts.ui(size: 10.5, color: AppColors.inkSoft),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          switch (step.state) {
            _StepState.open => const AppTag(
                label: 'À faire',
                tone: TagTone.success,
                compact: true,
              ),
            _StepState.locked => const PremiumLockTag(),
            _StepState.upcoming => const AppTag(
                label: 'À VENIR',
                tone: TagTone.neutral,
                compact: true,
              ),
          },
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Offre
// ---------------------------------------------------------------------------

/// Ce que l'abonnement change, en quatre phrases. Aucun prix, aucun verbe
/// d'achat (guidelines Apple 3.1.1) : le libellé du bouton est celui, partagé,
/// de [kPremiumLockCta].
class _ValueCard extends StatelessWidget {
  const _ValueCard({required this.onSubscribe});

  final VoidCallback onSubscribe;

  /// Les cinq avantages de la maquette (`MRapportGratuit`), **distincts** de
  /// ceux du Plan : ils décrivent ce que le rapport vient de laisser entrevoir,
  /// dans son ordre — priorités, petits sujets, corrections, plan vivant,
  /// moment de l'examen blanc.
  ///
  /// ⚠️ La maquette les tutoie ; ils sont ici au **vouvoiement**, comme le
  /// reste de la carte (« vos erreurs »), de l'écran et du Plan. Un seul bloc
  /// tutoyé au milieu d'un écran qui vouvoie se lit comme une faute.
  static const _arguments = <String>[
    'Toutes vos priorités détectées',
    'Les petits sujets ciblés, compétence par compétence',
    'Les corrections IA et la version au niveau supérieur',
    'Votre Plan qui évolue automatiquement',
    'Le moment où vous êtes prêt pour un examen blanc',
  ];

  @override
  Widget build(BuildContext context) {
    return GradientHero(
      // Encre → bleu **foncé** : la maquette garde ce bloc plus sombre que le
      // héros de niveau, pour que les deux dégradés ne se confondent pas.
      from: AppColors.ink,
      to: AppColors.blueDark,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ne vous entraînez plus au hasard.',
            style: AppFonts.display(
              size: 21,
              height: 1.12,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'SejourFR transforme vos erreurs en exercices ciblés, puis vérifie '
            'si vous les avez réellement corrigées.',
            style: AppFonts.ui(
              size: 12.5,
              height: 1.5,
              color: AppColors.white.withValues(alpha: 0.78),
            ),
          ),
          const SizedBox(height: 14),
          for (final argument in _arguments)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      LucideIcons.check,
                      size: 14,
                      color: AppColors.greenBright,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      argument,
                      style: AppFonts.ui(
                        size: 12.5,
                        height: 1.4,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 6),
          Semantics(
            button: true,
            label: kPremiumLockCta,
            child: AppButton(
              label: kPremiumLockCta,
              variant: AppButtonVariant.soft,
              height: 48,
              onPressed: onSubscribe,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Vos acquis
// ---------------------------------------------------------------------------

class _StrengthsCard extends StatelessWidget {
  const _StrengthsCard({required this.strengths});

  final List<String> strengths;

  @override
  Widget build(BuildContext context) => AppCard(
        color: AppColors.greenLight,
        border: Border.all(color: AppColors.green.withValues(alpha: 0.18)),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ce qui fonctionne déjà',
              style: AppFonts.ui(
                size: 12.5,
                weight: FontWeight.w800,
                color: AppColors.green,
              ),
            ),
            const SizedBox(height: 7),
            for (final strength in strengths)
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        LucideIcons.check,
                        size: 14,
                        color: AppColors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        strength,
                        style: AppFonts.ui(size: 12.5, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
}

/// Une compétence déjà solide, **repliée par défaut** — l'équivalent du
/// `<details>` de la maquette. Le verdict se lit d'un coup d'œil, l'explication
/// et l'extrait ne s'ouvrent que si le candidat le demande.
class _AcquisRow extends StatefulWidget {
  const _AcquisRow({required this.skill});

  final DiagnosticSkillObservation skill;

  @override
  State<_AcquisRow> createState() => _AcquisRowState();
}

class _AcquisRowState extends State<_AcquisRow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final skill = widget.skill;
    final detail = skill.explanation;
    final evidence = skill.evidence;
    final expandable = detail != null || evidence != null;
    // La teinte d'un statut d'observation vient d'un seul endroit
    // (`LearningPlanSkillStatus.color`), partagé Plan ⇄ Diagnostic ⇄
    // Compétences : la coche et la pilule la dérivent au lieu de refixer du
    // vert à la main.
    final tone = skill.status.color;

    final header = Padding(
      padding: const EdgeInsets.all(13),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(LucideIcons.check, size: 15, color: tone),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              skill.skillTitle,
              style: AppFonts.ui(size: 12.5, weight: FontWeight.w800, height: 1.3),
            ),
          ),
          const SizedBox(width: 8),
          AppTag(
            label: skill.status.label,
            tone: tagToneForAccent(tone),
            compact: true,
          ),
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

    return AppCard(
      padding: EdgeInsets.zero,
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (expandable)
            Semantics(
              button: true,
              expanded: _open,
              label: '${skill.skillTitle} · ${skill.status.label}',
              child: InkWell(
                onTap: () => setState(() => _open = !_open),
                borderRadius: BorderRadius.circular(16),
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
                    padding: const EdgeInsets.fromLTRB(51, 0, 13, 13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (detail != null)
                          Text(
                            detail,
                            style: AppFonts.ui(
                              size: 11.5,
                              height: 1.45,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        if (evidence != null) ...[
                          if (detail != null) const SizedBox(height: 7),
                          Text(
                            '« ${evidenceExcerpt(evidence)} »',
                            style: AppFonts.ui(
                              size: 11.5,
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
// Le détail des deux productions
// ---------------------------------------------------------------------------

/// Le bilan d'une production, **replié par défaut** : le candidat lit l'épreuve
/// et son niveau estimé, et n'ouvre que celle qui l'intéresse. Il porte ce que
/// le contrat serveur publie et que rien d'autre n'affiche : `summary`,
/// `taskCompletion`, `communicationStatus` et `weaknesses`.
class _ProductionCard extends StatefulWidget {
  const _ProductionCard({
    required this.title,
    required this.icon,
    required this.accent,
    required this.accentSoft,
    required this.production,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final Color accentSoft;
  final DiagnosticProductionResult production;

  @override
  State<_ProductionCard> createState() => _ProductionCardState();
}

class _ProductionCardState extends State<_ProductionCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final production = widget.production;
    final accent = widget.accent;
    final weaknesses = production.weaknesses.take(2).toList(growable: false);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            expanded: _open,
            label:
                '${widget.title} · niveau estimé ${production.levelEstimate.shortName}',
            child: InkWell(
              onTap: () => setState(() => _open = !_open),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: widget.accentSoft,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                      child: Icon(widget.icon, size: 18, color: accent),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: AppFonts.ui(size: 14.5, weight: FontWeight.w800),
                      ),
                    ),
                    AppTag(
                      label: production.levelEstimate.shortName,
                      tone: production.levelEstimate.tagTone,
                      compact: true,
                    ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: _open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: const Icon(
                        LucideIcons.chevronDown,
                        size: 18,
                        color: AppColors.inkFaint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: !_open
                ? const SizedBox(width: double.infinity)
                : _ProductionDetail(
                    production: production,
                    weaknesses: weaknesses,
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProductionDetail extends StatelessWidget {
  const _ProductionDetail({
    required this.production,
    required this.weaknesses,
  });

  final DiagnosticProductionResult production;
  final List<String> weaknesses;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (production.summary != null) ...[
            Text(
              production.summary!,
              style: AppFonts.ui(
                size: 13,
                height: 1.45,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 11),
          ],
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _StateChip(
                icon: LucideIcons.listChecks,
                label: production.taskCompletion.label,
                tone: _completionTone(production.taskCompletion),
              ),
              _StateChip(
                icon: LucideIcons.messagesSquare,
                label: production.communicationStatus.label,
                tone: _communicationTone(production.communicationStatus),
              ),
            ],
          ),
          if (weaknesses.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(11),
              // « À travailler » se dit en **ambre**, comme les priorités du
              // haut de l'écran : un gris neutre effaçait le seul signal que
              // porte ce bloc, et l'accent du module (bleu en EE, rouge en EO)
              // n'y disait rien de la nature du contenu.
              decoration: BoxDecoration(
                color: AppColors.amberLight,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'À TRAVAILLER',
                    style: AppFonts.label(size: 10, color: AppColors.amberDark),
                  ),
                  const SizedBox(height: 6),
                  for (final weakness in weaknesses)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            margin: const EdgeInsets.only(top: 6, right: 8),
                            decoration: const BoxDecoration(
                              color: AppColors.amberDark,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              weakness,
                              style: AppFonts.ui(size: 12.5, height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({
    required this.icon,
    required this.label,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: tone.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: tone),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppFonts.ui(
                size: 11,
                weight: FontWeight.w700,
                color: tone,
              ),
            ),
          ],
        ),
      );
}

Color _completionTone(DiagnosticTaskCompletion completion) =>
    switch (completion) {
      DiagnosticTaskCompletion.completed => AppColors.green,
      DiagnosticTaskCompletion.partial => AppColors.amberDark,
      DiagnosticTaskCompletion.notCompleted => AppColors.red,
    };

Color _communicationTone(DiagnosticCommunicationStatus status) =>
    switch (status) {
      DiagnosticCommunicationStatus.effective => AppColors.green,
      DiagnosticCommunicationStatus.partial => AppColors.amberDark,
      DiagnosticCommunicationStatus.ineffective => AppColors.red,
    };

// ---------------------------------------------------------------------------
// Ce qu'un compte sans accès TCF ne lit pas encore
// ---------------------------------------------------------------------------

/// Ce qu'un compte **sans accès TCF** lit en clair avant le bloc verrouillé.
///
/// Ce sont des seuils d'**affichage**, jamais une règle serveur : le backend ne
/// verrouille pas la lecture d'un diagnostic, et `GET /api/me/plan` sert le Plan
/// en entier à un compte gratuit. Ils viennent de la maquette
/// (`MVisiteur.jsx` · `MRapportGratuit`) et ne décident d'aucun accès — le
/// verrou réel reste `PlanRecommendedExercise.locked`, posé par le serveur.
///
/// 🛑 **Ce qui reste entier quel que soit l'abonnement** : les deux niveaux
/// estimés, l'objectif, le rail, le résumé, le « avant / après », le détail des
/// deux productions et la bande des quatre domaines. Ce sont **ses**
/// productions et **ses** mesures — on ne les lui vend pas.
const int _kFreeFocusVisible = 2;
const int _kFreeSolidVisible = 2;
const int _kFreeStepsVisible = 1;

/// Combien de lignes **réelles** le bloc flouté laisse deviner. C'est un
/// échantillon, jamais le compte : le compte, lui, est exact et porte sur
/// **tout** ce qui est masqué.
const int _kBlurredSample = 2;

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
          // endroit. Cet écran en tenait une copie manuelle, au même réglage.
          BlurredContent(
            sigma: 5,
            child: Column(
              children: [
                for (final line in lines)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: AppColors.surface3,
                            shape: BoxShape.circle,
                          ),
                        ),
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
                                  size: 14.5,
                                  weight: FontWeight.w600,
                                ),
                              ),
                              if (line.subtitle != null)
                                Text(
                                  line.subtitle!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppFonts.ui(
                                    size: 12.5,
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
/// des entraînements de la séance, dont les titres tiennent déjà dans la carte
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

const String _kPlanCta = 'Voir mon plan personnalisé';

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
/// que cette barre appelle comme la liste « Compléter mon profil » et la fiche
/// d'un domaine. Trois copies auraient fini par ouvrir trois écrans différents
/// pour le même domaine. La légende dit dès ici ce qu'il y a derrière
/// ([planAssessmentMeta]) : « Examen blanc n°1 · ≈ 20 min », jamais une
/// promesse plus vague que le geste.
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
        ? _kPlanCta
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
              label: _kPlanCta,
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
