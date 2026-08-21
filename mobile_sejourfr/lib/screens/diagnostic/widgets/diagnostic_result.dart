import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/diagnostic_models.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/skill_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/evidence_excerpt.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_tag.dart';
import '../../../core/widgets/fixed_action_bar.dart';
import '../../../core/widgets/gradient_hero.dart';
import '../../../core/widgets/premium_lock.dart';
import '../../tcf_production/widgets/action_plan.dart';

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
class DiagnosticResultView extends StatelessWidget {
  const DiagnosticResultView({
    super.key,
    required this.result,
    required this.hasTcfAccess,
    required this.onOpenPlan,
    required this.onOpenRecommended,
    required this.onSubscribe,
    this.objective,
  });

  final DiagnosticResult result;
  final String? objective;

  /// Accès TCF réel du compte (`AuthUser.hasTcf`). Il ne sert qu'à **choisir la
  /// pastille** des étapes à venir et à décider si l'offre est présentée :
  /// aucune règle de verrou n'est recalculée ici — celle de l'exercice
  /// recommandé vient de `PlanRecommendedExercise.locked`, posé par le serveur.
  final bool hasTcfAccess;

  final VoidCallback onOpenPlan;
  final ValueChanged<PlanRecommendedExercise> onOpenRecommended;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    final focus = _focusItems(result);
    final solid = _solidSkills(result);
    final steps = _planSteps(result, hasTcfAccess: hasTcfAccess);
    final exemple = result.exempleCible;

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
              'BILAN PERSONNALISÉ · 2 PRODUCTIONS',
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
            const SizedBox(height: 18),
            _LevelsHero(
              written: result.written?.levelEstimate,
              oral: result.oral?.levelEstimate,
              objective: objective,
            ),
            const SizedBox(height: 10),
            const _EstimationNote(),
            if (focus.isNotEmpty) ...[
              const SizedBox(height: 14),
              _FocusCard(focus: focus),
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
            if (steps.isNotEmpty) ...[
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
                steps: steps,
                exercise: result.nextAction,
                onOpenRecommended: onOpenRecommended,
                onSubscribe: onSubscribe,
              ),
            ],
            if (!hasTcfAccess) ...[
              const SizedBox(height: 14),
              _ValueCard(onSubscribe: onSubscribe),
            ],
            if (solid.isNotEmpty || result.strengths.isNotEmpty) ...[
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
                if (solid.isNotEmpty) const SizedBox(height: 9),
              ],
              for (final skill in solid)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _AcquisRow(skill: skill),
                ),
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
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: FixedActionBar(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  button: true,
                  label: 'Voir mon plan personnalisé',
                  child: AppButton(
                    label: 'Voir mon plan personnalisé',
                    iconRight: LucideIcons.arrowRight,
                    onPressed: onOpenPlan,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Basé sur vos réponses · vous pourrez commencer par un '
                  'exercice',
                  textAlign: TextAlign.center,
                  style: AppFonts.ui(
                    size: 10.5,
                    weight: FontWeight.w700,
                    color: AppColors.inkFaint,
                    height: 1.35,
                  ),
                ),
              ],
            ),
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
List<_FocusItem> _focusItems(DiagnosticResult result) {
  if (result.priorities.isNotEmpty) {
    return result.priorities
        .take(3)
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
  if (observed.isNotEmpty) return observed.take(3).toList(growable: false);

  final weaknesses = <_FocusItem>[];
  for (final production in [result.written, result.oral]) {
    for (final weakness in production?.weaknesses ?? const <String>[]) {
      weaknesses.add(_FocusItem(title: weakness, ranked: false));
    }
  }
  return weaknesses.take(3).toList(growable: false);
}

/// Les compétences que les deux productions ont montrées **solides**,
/// dédoublonnées par `skillId`.
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
  return solid.take(4).toList(growable: false);
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
  });

  final NiveauCecrl? written;
  final NiveauCecrl? oral;
  final String? objective;

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
    required this.exercise,
    required this.onOpenRecommended,
    required this.onSubscribe,
  });

  final List<_PlanStep> steps;
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

  static const _arguments = <String>[
    'Plan personnalisé après votre diagnostic',
    'Corrections écrites et orales par IA',
    'Exercices courts sur vos faiblesses',
    'Réévaluation de vos compétences',
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
