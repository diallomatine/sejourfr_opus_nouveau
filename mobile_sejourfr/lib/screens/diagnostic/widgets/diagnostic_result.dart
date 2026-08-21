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

/// Écran de fin de diagnostic — le bilan **in-app** d'un candidat connecté.
///
/// 🛑 **Sa maquette de référence est `MDiag`, étape `result`**, et **jamais**
/// `MRapportGratuit`, qui est l'écran du **visiteur non connecté**. Les deux se
/// ressemblent, et c'est exactement pour ça qu'une passe précédente a refondu
/// celui-ci sur celle-là : le profil TCF y avait alors disparu au profit d'une
/// bande de quatre colonnes qui n'appartient qu'au rapport visiteur. Vérifier
/// la maquette **avant** de retoucher l'ordre des blocs.
///
/// Ordre servi, calqué sur `MDiag` : héros (niveau · objectif · rail) → **Mon
/// profil TCF** → compléter son profil → **points forts** → **priorités** →
/// aperçu du plan → offre → barre d'action.
///
/// Rien n'y est décoratif : chaque bloc rend une donnée que le serveur a
/// réellement produite, et **un bloc sans donnée n'est pas rendu** (jamais de
/// squelette, jamais de « non disponible »).
///
/// 🛑 **Ce que la maquette N'A PAS, et qui reste hors de cet écran** : le
/// « avant / après » (`exempleCible`) et le détail des deux productions. Le
/// premier est servi par le contrat et affiché par les rapports EE/EO et le
/// résultat de compétence (`ActionPlanExempleCard`, intacte).
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


    return Stack(
      children: [
        ListView(
          // La réserve du bas laisse passer tout le contenu sous le CTA
          // collant : rien n'est jamais masqué par la barre.
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 132),
          children: [
            // 1 — le héros : niveau estimé, objectif sur la même ligne, rail.
            // 🛑 **Aucune bande de quatre colonnes ici** : elle appartient au
            // rapport du visiteur (`MRapportGratuit`). Le profil du candidat
            // connecté a sa propre section, juste dessous.
            _LevelCard(cycle: plan?.cycle, objective: objective),

            // 2 — mon profil TCF : les quatre domaines, dans l'ordre servi.
            if (domains.isNotEmpty) ...[
              const SizedBox(height: 24),
              const _SectionTitle(title: kPlanProfileTitle),
              const SizedBox(height: 11),
              _ProfileSection(cycle: plan?.cycle, domains: domains),
            ],

            // 3 — ce qu'il reste à mesurer, et de quoi le mesurer tout de
            // suite. Vide = profil complet : la carte n'existe pas.
            if (pending.isNotEmpty) ...[
              const SizedBox(height: 11),
              _CompleteProfileCard(assessments: pending),
            ],

            // 4 — vos points forts
            if (visibleSolid.isNotEmpty || visibleTexts.isNotEmpty) ...[
              const SizedBox(height: 24),
              _SectionTitle(
                title: kDiagnosticStrengthsTitle,
                text: diagnosticStrengthsSub(
                  _strengthTotal(
                    result,
                    solid.isEmpty ? strengthTexts.length : solid.length,
                  ),
                ),
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

            // 5 — vos priorités
            if (visibleFocus.isNotEmpty) ...[
              const SizedBox(height: 24),
              _SectionTitle(
                title: ranked
                    ? kDiagnosticPrioritiesTitle
                    : kDiagnosticPrioritiesTitleUnranked,
                // Un abonné les voit toutes : il n'y a rien à lui compter. Le
                // repli non classé, lui, garde sa phrase — on ne promeut pas
                // des points relevés en priorités mesurées.
                text: ranked
                    ? (hasTcfAccess ? null : diagnosticPrioritiesSub(focusTotal))
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

            // La section « Votre plan personnalisé est prêt » a ete retiree le
            // 2026-08-21 : le rapport dit ce qui a ete mesure, le Plan dit quoi
            // faire, et le bouton du bas y mene deja. Ne pas la reintroduire.

            // 7 — l'offre ferme le rapport : le candidat a d'abord lu **son**
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

/// La durée réelle de « Compléter maintenant · N min ».
///
/// 🛑 **Rien n'est écrit en dur.** `estimatedMinutes` est posé par le serveur
/// depuis `DureeEpreuve` ; on n'en fait que la somme. Le « 14 min » de la
/// maquette n'est la durée d'aucune de nos épreuves — le recopier aurait
/// promis au candidat un quart d'heure pour 55 minutes d'examens blancs.
///
/// `null` quand aucune mesure ne porte de durée (le libellé se rend alors sans
/// chiffre) : une mesure sans durée n'en reçoit **jamais** une inventée.
int? _assessmentsMinutes(List<PlanDomainAssessment> assessments) {
  var total = 0;
  for (final assessment in assessments) {
    total += assessment.estimatedMinutes ?? 0;
  }
  return total > 0 ? total : null;
}

/// Une ligne de « Vos priorités ».
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
    this.skillId,
    this.code = '',
    this.detail,
    this.evidence,
    this.status,
    this.section,
  });

  final String title;

  /// La compétence désignée. `null` sur un repli tiré des `weaknesses` : cette
  /// ligne n'ouvre alors **rien**, elle ne renvoie pas vers une fiche devinée.
  final String? skillId;
  final String code;
  final String? detail;
  final String? evidence;
  final LearningPlanSkillStatus? status;
  final SkillSection? section;

  /// Distingue les **priorités mesurées** par le serveur (numérotées) des
  /// replis : ces derniers ne portent pas de rang, parce qu'ils ne sont pas un
  /// classement.
  final bool ranked;

  /// La ligne ouvre-t-elle la fiche de sa compétence ? Un repli tiré des
  /// `weaknesses` n'est qu'un titre : sa ligne reste alors **inerte**, sans
  /// chevron.
  bool get opensSkill => skillId != null && section != null;

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
            skillId: entry.$2.skillId,
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
      skillId: skill.skillId,
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

// ---------------------------------------------------------------------------
// 1 — le héros : niveau estimé, objectif, rail des paliers
// ---------------------------------------------------------------------------

/// Le bandeau qui situe le candidat : son **niveau estimé** en très grand, son
/// **objectif sur la même ligne**, une phrase, puis le rail des paliers.
///
/// 🛑 **Aucune bande de quatre colonnes ici.** Elle appartient au rapport du
/// **visiteur** (`MRapportGratuit`) ; le candidat connecté a une vraie section
/// « Mon profil TCF », avec une ligne cliquable par domaine. Les avoir
/// confondues avait fait disparaître cette section.
class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.cycle, required this.objective});

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

  @override
  Widget build(BuildContext context) {
    return GradientHero(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kDiagnosticLevelEyebrow.toUpperCase(),
            style: AppFonts.eyebrow(
              color: AppColors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 6),
          // Niveau et objectif sur **une seule ligne**, alignés par le bas :
          // c'est la lecture de la maquette — « où j'en suis, où je vais » se
          // lit d'un seul mouvement.
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
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
            const SizedBox(height: 16),
            // Le rail du Plan, repris tel quel : le candidat doit retrouver
            // **la même** échelle d'un écran à l'autre, et le palier allumé est
            // celui que son cycle construit — pas une valeur redérivée ici.
            PlanLevelRail(current: cycle!.targetLevel, onDark: true),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2 — mon profil TCF
// ---------------------------------------------------------------------------

/// **Mon profil TCF** : combien de domaines sont mesurés, et une ligne par
/// domaine — icône, libellé, ce qu'on en sait, et la pilule de sa priorité.
///
/// 🛑 **Les quatre domaines arrivent triés par urgence côté serveur ; aucun
/// front ne retrie.** Un domaine jamais mesuré garde sa ligne et sa pilule
/// « À évaluer » : il est **inconnu, jamais mauvais**, et aucun niveau ne lui
/// est prêté.
///
/// 🛑 **Chaque ligne ouvre la fiche de son domaine** ([openPlanDomain], le
/// lanceur partagé) — c'est le `nav.push("compdetail")` de la maquette. Le même
/// domaine ne peut pas mener à deux écrans selon l'endroit où on le touche.
///
/// ⚠️ Volontairement **distinct** de `PlanProfileSection` : même structure,
/// mais les sous-titres ne disent pas la même chose (le Plan explique par quoi
/// mesurer, le bilan dit où en est le profil). Les deux écrans lisent en
/// revanche le **même** compteur (`planProfileCoverage`) et la **même** pilule.
class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.cycle, required this.domains});

  final PlanCycle? cycle;
  final List<PlanDomain> domains;

  @override
  Widget build(BuildContext context) {
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
          Container(
            padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.lineSoft)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    planProfileCoverage(cycle, domains.length),
                    style: AppFonts.ui(
                      size: 13,
                      weight: FontWeight.w700,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ),
                // Une pastille par domaine, pleine quand il est mesuré : le
                // compteur ci-contre et ces points disent la même chose, l'un
                // en mots, l'autre d'un coup d'œil.
                for (final domain in domains) ...[
                  const SizedBox(width: 5),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: domain.evaluated
                          ? AppColors.blue
                          : AppColors.surface3,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.line),
                    ),
                  ),
                ],
              ],
            ),
          ),
          for (var i = 0; i < domains.length; i++)
            _ProfileRow(domain: domains[i], first: i == 0),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.domain, required this.first});

  final PlanDomain domain;
  final bool first;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: '${planDomainLabel(domain.epreuve)} · '
            '${diagnosticDomainSubtitle(domain)}',
        child: Material(
          color: AppColors.white,
          child: InkWell(
            onTap: () => openPlanDomain(context, domain.epreuve),
            child: Container(
              padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
              decoration: BoxDecoration(
                border: first
                    ? null
                    : const Border(top: BorderSide(color: AppColors.lineSoft)),
              ),
              child: Row(
                children: [
                  PlanDomainTile(
                    epreuve: domain.epreuve,
                    filled: domain.priority == PlanDomainPriority.forte,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          planDomainLabel(domain.epreuve),
                          style: AppFonts.ui(
                            size: 14.5,
                            weight: FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          diagnosticDomainSubtitle(domain),
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
                  PlanDomainPriorityTag(priority: domain.priority),
                ],
              ),
            ),
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// 3 — compléter son profil
// ---------------------------------------------------------------------------

/// Ce qu'il reste à mesurer, et de quoi le mesurer **tout de suite**.
///
/// 🛑 Le geste ne crée aucun parcours : il passe par [openPlanAssessment],
/// l'autorité unique qui traduit une `PlanDomainAssessmentKind` en écran — la
/// même que la fiche d'un domaine et que la barre d'action de ce bilan.
///
/// ⚠️ **La durée est calculée** ([_assessmentsMinutes]), jamais recopiée de la
/// maquette : ce sont les `estimatedMinutes` que le serveur lit chez
/// `DureeEpreuve`. Sans aucune durée servie, le bouton n'en annonce pas.
class _CompleteProfileCard extends StatelessWidget {
  const _CompleteProfileCard({required this.assessments});

  /// Déjà filtrées et **déjà ordonnées** par le serveur. Jamais vides ici :
  /// l'appelant ne construit pas la carte quand le profil est complet.
  final List<PlanDomainAssessment> assessments;

  @override
  Widget build(BuildContext context) {
    final minutes = _assessmentsMinutes(assessments);
    final label = minutes == null
        ? kDiagnosticCompleteProfileCta
        : '$kDiagnosticCompleteProfileCta · $minutes min';
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface2,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            kDiagnosticCompleteProfileText,
            style: AppFonts.ui(
              size: 13.5,
              height: 1.55,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 13),
          AppButton(
            label: label,
            variant: AppButtonVariant.outline,
            height: 46,
            icon: LucideIcons.play,
            onPressed: () => openPlanAssessment(context, assessments.first),
          ),
        ],
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
  const _SectionTitle({required this.title, this.text});

  final String title;

  /// `null` = le titre se suffit. C'est le cas de « Mon profil TCF », et celui
  /// des priorités d'un **abonné** : le sous-titre n'existe que pour compter ce
  /// que le rideau cache, il n'a rien à dire à qui voit tout.
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

// ---------------------------------------------------------------------------
// 4 — vos points forts
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
          meta: _skillMetaLine(skill.section, skill.skillCode),
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

/// Une ligne de point fort : la coche, la compétence, et **sous elle** son
/// repère (« Expression écrite · Tâche 2 ») — la disposition de la maquette.
/// Le repère à droite du titre, qu'on avait, se repliait avant lui sur un
/// téléphone étroit.
class _StrengthRow extends StatelessWidget {
  const _StrengthRow({required this.label, this.meta});

  final String label;

  /// Vide ou `null` sur une phrase de repli : il n'y a alors aucun domaine à
  /// nommer, et on n'en invente pas.
  final String? meta;

  @override
  Widget build(BuildContext context) {
    final sub = meta;
    return Row(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppFonts.ui(size: 13.5, height: 1.35)),
              if (sub != null && sub.isNotEmpty) ...[
                const SizedBox(height: 1),
                Text(
                  sub,
                  style: AppFonts.ui(size: 12, color: AppColors.inkFaint),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 5 — vos priorités
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
              _PriorityRow(item: focus[index], rank: index + 1),
          ],
        ),
      );
}

/// Une priorité : son rang, la compétence, son repère et le verdict porté sur
/// elle.
///
/// 🛑 **La ligne OUVRE LA FICHE DE LA COMPÉTENCE** — `nav.push("skill")` de la
/// maquette, ici [openPlanSkill], le **lanceur partagé** du Plan. La même
/// compétence ne peut pas mener à deux écrans selon l'endroit où on la touche,
/// et c'est là que le candidat trouve ses sujets. Elle ne déplie donc plus le
/// rapport du correcteur en place : `explanation` et `evidence` vivent sur la
/// fiche et sur le rapport de la production.
///
/// Sans compétence à ouvrir (repli tiré des `weaknesses`), la ligne reste
/// **inerte** et ne montre aucun chevron : elle n'annonce que ce qu'elle fait.
class _PriorityRow extends StatelessWidget {
  const _PriorityRow({required this.item, required this.rank});

  final _FocusItem item;

  /// 1-based, comme la maquette. Le premier rang est teinté — un seul élément
  /// de la liste attire l'œil.
  final int rank;

  @override
  Widget build(BuildContext context) {
    // Une ligne sans domaine reste nommée pour ce qu'elle est, plutôt que de
    // laisser un titre nu : c'est le repli du web (`PRIORITY_RANK_LABEL`).
    final meta = item.meta.isEmpty ? item.fallbackMeta : item.meta;
    final status = item.status;
    final skillId = item.skillId;
    final section = item.section;
    final opens = item.opensSkill;

    final row = Container(
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
      decoration: BoxDecoration(
        border: Border(
          top: rank == 1
              ? BorderSide.none
              : const BorderSide(color: AppColors.lineSoft),
        ),
      ),
      child: Row(
        children: [
          // Un rang numéroté, comme la maquette — et non la pastille de
          // domaine : « Vos priorités » est un **classement**, le domaine se
          // lit sur la ligne du dessous.
          PlanRankBadge(
            rank: rank,
            tone: rank == 1 ? AppColors.red : AppColors.inkFaint,
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
          if (opens) ...[
            const SizedBox(width: 4),
            const Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: AppColors.inkFaint,
            ),
          ],
        ],
      ),
    );

    if (!opens) return row;
    return Semantics(
      button: true,
      label: '${item.title} · $meta',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => openPlanSkill(context, skillId!, section!),
          child: row,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4 — aperçu du plan
// ---------------------------------------------------------------------------

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
/// en entier à un compte gratuit. Ils viennent de la maquette (`MDiag`, étape
/// `result` — `forces.slice(0, 2)` et `priorites.slice(0, 1)`) et ne décident
/// d'aucun accès : le verrou réel reste `PlanRecommendedExercise.locked`, posé
/// par le serveur.
///
/// 🛑 **Ce qui reste entier quel que soit l'abonnement** : le niveau estimé,
/// l'objectif, le rail, **les quatre domaines de « Mon profil TCF »**, ce qu'il
/// reste à mesurer, et la priorité n°1. Ce sont **ses** productions et **ses**
/// mesures — on ne les lui vend pas. ⚠️ Corollaire à ne jamais casser :
/// **aucune surface de cet écran ne doit nommer en clair ce que le rideau
/// prétend cacher.** C'est exactement pour ça que le détail des deux
/// productions (qui listait « À travailler ») n'y a plus sa place.
const int _kFreeFocusVisible = 1;
const int _kFreeSolidVisible = 2;

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
