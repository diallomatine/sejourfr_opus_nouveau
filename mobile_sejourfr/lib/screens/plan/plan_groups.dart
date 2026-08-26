/// **Le regroupement « épreuve → tâche » du Plan.**
///
/// La séance et les priorités ne sont plus des listes plates : elles se lisent
/// par **épreuve**, puis par **tâche** — « où je travaille → quelle compétence
/// → quoi faire ». C'est une **vue**, dérivée ici, de ce que le serveur sert
/// déjà : on ne retrie **jamais** les lignes à l'intérieur d'un groupe, et
/// l'ordre des groupes est celui de leur première ligne. Le serveur reste seul
/// à décider de l'ordre du Plan.
///
/// 🛑 **Rien n'est recalculé.** Le verrou vient des `locked` servis, la coche de
/// `lastActivityAt` (`planSeanceItemDone`), la nature de `nature`, le palier des
/// domaines. Aucun rang de ligne n'entre dans une décision.
library;

import '../../core/models/diagnostic_models.dart';
import '../../core/models/enums.dart';
import '../../core/models/skill_models.dart';
import 'plan_labels.dart';
import 'plan_seance_state.dart';

/* ------------------------------------------------------------- la séance ---- */

/// Une ligne de séance, avec les deux faits que l'encart lui demande.
class PlanSeanceGroupRow {
  const PlanSeanceGroupRow({
    required this.item,
    required this.done,
    required this.locked,
    required this.minutes,
  });

  final PlanSeanceItem item;
  final bool done;
  final bool locked;
  final int minutes;
}

/// Un encart de séance : une épreuve, éventuellement une tâche, ses lignes.
class PlanSeanceGroup {
  const PlanSeanceGroup({
    required this.key,
    required this.epreuve,
    required this.task,
    required this.context,
    required this.rows,
  });

  final String key;

  /// `null` sur un jalon d'examen complet, qui ne relève d'aucune épreuve.
  final EpreuveType? epreuve;

  /// La tâche d'expression du groupe. `null` en compréhension, sur une mesure
  /// et sur un jalon — leur repère est [context].
  final SkillTaskCode? task;

  /// Le repère de l'encart quand il n'a pas de tâche (« Niveau B1 », « Jalon »,
  /// « Examen blanc n°1 »). `null` quand rien n'est servi pour le composer.
  final String? context;

  final List<PlanSeanceGroupRow> rows;

  int get minutes => rows.fold(0, (sum, row) => sum + row.minutes);

  int get doneCount => rows.where((row) => row.done).length;

  bool get done => rows.isNotEmpty && doneCount == rows.length;

  /// 🛑 **Un encart est verrouillé quand TOUTES ses lignes le sont**, jamais
  /// parce qu'il n'est pas le premier : c'est le serveur qui ouvre la première
  /// place du Plan, et il peut en ouvrir une autre. Un encart qui garde une
  /// ligne ouverte se déplie.
  bool get locked => rows.isNotEmpty && rows.every((row) => row.locked);
}

/// La séance, groupée. L'ordre des encarts suit l'ordre d'exécution servi.
List<PlanSeanceGroup> planSeanceGroups(PlanSeance seance) {
  final keys = <String>[];
  final rows = <String, List<PlanSeanceGroupRow>>{};
  final meta = <String, PlanSeanceGroup>{};

  for (final item in seance.items) {
    final section = item.section;
    final epreuve = item.milestone?.epreuve ??
        item.assessment?.epreuve ??
        (section == null ? null : planEpreuveOfSection(section));
    final task = section != null && section.isProduction
        ? SkillTaskCode.fromSkillCode(item.skillCode)
        : null;
    final context = task != null
        ? null
        : planGroupContextLabel(
            level: item.level,
            assessment: item.assessment,
            milestone: item.milestone,
          );
    final key = task?.wire ??
        '${epreuve?.wire ?? '-'}·${context ?? item.nature.wire}';

    if (!rows.containsKey(key)) {
      keys.add(key);
      rows[key] = <PlanSeanceGroupRow>[];
      meta[key] = PlanSeanceGroup(
        key: key,
        epreuve: epreuve,
        task: task,
        context: context,
        rows: const <PlanSeanceGroupRow>[],
      );
    }
    rows[key]!.add(
      PlanSeanceGroupRow(
        item: item,
        done: planSeanceItemDone(item),
        locked: planSeanceItemLocked(item),
        minutes: item.exercise?.estimatedMinutes ??
            item.milestone?.estimatedMinutes ??
            item.assessment?.estimatedMinutes ??
            0,
      ),
    );
  }

  return keys
      .map(
        (key) => PlanSeanceGroup(
          key: key,
          epreuve: meta[key]!.epreuve,
          task: meta[key]!.task,
          context: meta[key]!.context,
          rows: List<PlanSeanceGroupRow>.unmodifiable(rows[key]!),
        ),
      )
      .toList(growable: false);
}

/* ---------------------------------------------------------- les priorités ---- */

/// **Combien de lignes un encart déplié montre** avant de renvoyer au reste.
///
/// C'est un **plafond d'affichage**, jamais un filtre : le résumé de l'encart et
/// le compteur « + N autres » portent sur **tout** le groupe. Une tâche
/// d'expression compte 8 compétences ; les dérouler toutes sous chaque encart
/// repousserait la priorité n°1 hors de l'écran.
const int kPlanPriorityGroupVisibleRows = 6;

/// **Une ligne d'encart de priorités.**
///
/// 🛑 **Deux sources, une seule ligne.** Une compétence entre ici parce que le
/// Plan demande une **action** dessus (`currentPriority` / `nextPriorities`),
/// **ou** parce qu'elle a été **observée** — les solides comprises. C'est ce
/// second cas qui a fait disparaître la section « Mes compétences observées » :
/// ce que les productions ont montré se lit désormais **à côté** de ce qu'il
/// reste à faire, sur la même tâche, au lieu d'une seconde liste plus bas qui
/// réénumérait les mêmes compétences dans un autre ordre.
///
/// 🛑 Une compétence **jamais observée et sans nature** n'est **pas** une
/// ligne : elle n'est ni un acquis ni une action, et l'inscrire ici la ferait
/// lire comme une faiblesse. Elle ne se compte pas non plus dans le résumé.
class PlanPriorityGroupRow {
  const PlanPriorityGroupRow({
    required this.skillId,
    required this.skillCode,
    required this.title,
    required this.section,
    required this.status,
    required this.locked,
    this.level,
    this.priority,
  });

  final String skillId;
  final String skillCode;
  final String title;
  final SkillSection section;

  final PlanRowStatus status;

  /// Le palier travaillé : celui de la compétence en compréhension, celui que
  /// le cycle construit sinon. `null` quand aucun n'est servi.
  final TargetLevel? level;

  /// Le verrou **servi**. Une compétence **solide** n'en porte jamais à
  /// l'affichage : elle est déjà acquise, et *on floute l'action pas encore
  /// accessible, jamais le résultat mesuré*.
  final bool locked;

  /// La priorité servie quand cette ligne en est une ; `null` sur une ligne
  /// **seulement observée**. Elle n'a alors ni exercice recommandé ni compteurs
  /// d'étape — on n'en invente pas.
  final LearningPlanPriority? priority;

  bool get comprehension => section.isComprehension;
}

/// Un encart de priorités.
class PlanPriorityGroup {
  const PlanPriorityGroup({
    required this.key,
    required this.epreuve,
    required this.task,
    required this.context,
    required this.rows,
  });

  final String key;
  final EpreuveType? epreuve;
  final SkillTaskCode? task;
  final String? context;

  /// **Toutes** les compétences du groupe : les priorités d'abord, dans l'ordre
  /// servi, puis celles qui ont seulement été observées, dans l'ordre du
  /// référentiel. C'est cette liste entière que résume l'en-tête.
  final List<PlanPriorityGroupRow> rows;

  /// Même règle que la séance : verrouillé seulement si **tout** l'est. Un
  /// groupe qui porte une compétence solide n'est donc jamais fermé — ses
  /// résultats mesurés restent lisibles.
  bool get locked => rows.isNotEmpty && rows.every((row) => row.locked);

  /// Les lignes réellement déroulées, plafonnées.
  List<PlanPriorityGroupRow> get visibleRows =>
      rows.length <= kPlanPriorityGroupVisibleRows
          ? rows
          : rows.take(kPlanPriorityGroupVisibleRows).toList(growable: false);

  /// 🛑 **Un vrai nombre**, calculé sur ce que le groupe contient réellement —
  /// jamais une constante. `0` ⇒ aucun lien n'est affiché.
  int get hiddenCount => rows.length - visibleRows.length;

  /// La ligne que vise le bouton de bas d'encart : la **première qui appelle
  /// une action**, c'est-à-dire la première qui n'est pas déjà solide.
  ///
  /// `null` quand le groupe est entièrement solide — il n'y a alors rien à
  /// proposer, et le bouton disparaît au lieu de renvoyer vers un acquis.
  PlanPriorityGroupRow? get action {
    for (final row in rows) {
      if (row.status.isActionable) return row;
    }
    return null;
  }
}

/// **Le statut d'affichage d'une priorité** — une vue de deux faits servis.
///
/// La nature dit ce qu'il y a à faire ; l'état agrégé dit où en est la
/// compétence. Une fragilité observée qui vaut déjà `SOLID` se dit « solide »,
/// celle que le moteur tient pour la plus bloquante se dit « priorité » : c'est
/// ce qui permet à un encart fermé de résumer ses lignes sans les déplier.
///
/// 🛑 **Aucune des deux sources n'est réinterprétée** : une acquisition n'a
/// rien d'observé et reste « à acquérir » quoi qu'il arrive, une mesure reste
/// « à évaluer », une vérification reste « à vérifier ».
PlanRowStatus planRowStatus(LearningPlanPriority priority) =>
    switch (priority.nature) {
      PlanActionNature.aEvaluer => PlanRowStatus.aEvaluer,
      PlanActionNature.aAcquerir => PlanRowStatus.aAcquerir,
      PlanActionNature.aVerifier => PlanRowStatus.aVerifier,
      PlanActionNature.aRenforcer => switch (priority.masteryState) {
          SkillMasteryState.solid => PlanRowStatus.solide,
          SkillMasteryState.priority => PlanRowStatus.priorite,
          _ => priority.status == LearningPlanSkillStatus.priority
              ? PlanRowStatus.priorite
              : PlanRowStatus.aRenforcer,
        },
    };

/// **Le statut d'affichage d'une compétence du référentiel**, quand le Plan ne
/// demande rien dessus : c'est son **état agrégé** qui parle, à défaut le
/// verdict de sa dernière production.
///
/// ⚠️ `observedAt != null` implique un statut probant côté serveur
/// (`latestObservedBySkill` écarte les `NOT_OBSERVED`) : cette fonction n'est
/// donc jamais appelée sur une compétence sans mesure. Le repli sur `status`
/// couvre le seul cas résiduel — un état de maîtrise absent malgré une
/// observation.
PlanRowStatus planObservedRowStatus(PlanDomainSkill skill) {
  final nature = skill.nature;
  if (nature != null && nature != PlanActionNature.aRenforcer) {
    return switch (nature) {
      PlanActionNature.aEvaluer => PlanRowStatus.aEvaluer,
      PlanActionNature.aAcquerir => PlanRowStatus.aAcquerir,
      PlanActionNature.aVerifier => PlanRowStatus.aVerifier,
      PlanActionNature.aRenforcer => PlanRowStatus.aRenforcer,
    };
  }
  return switch (skill.masteryState) {
    SkillMasteryState.solid => PlanRowStatus.solide,
    SkillMasteryState.priority => PlanRowStatus.priorite,
    _ => switch (skill.status) {
        LearningPlanSkillStatus.solid => PlanRowStatus.solide,
        LearningPlanSkillStatus.priority => PlanRowStatus.priorite,
        _ => PlanRowStatus.aRenforcer,
      },
  };
}

/// L'identité d'un encart, calculée **de la même façon** pour les deux sources
/// de lignes : sans ça, une priorité et une compétence observée de la même
/// tâche atterriraient dans deux encarts différents.
class _GroupMeta {
  const _GroupMeta({
    required this.key,
    required this.epreuve,
    required this.task,
    required this.context,
  });

  final String key;
  final EpreuveType? epreuve;
  final SkillTaskCode? task;
  final String? context;
}

_GroupMeta _groupMeta(SkillSection section, String skillCode, TargetLevel? level) {
  final epreuve = planEpreuveOfSection(section);
  final task = section.isProduction ? SkillTaskCode.fromSkillCode(skillCode) : null;
  final context =
      task != null ? null : planGroupContextLabel(level: level?.wire);
  final key = task?.wire ?? '${epreuve?.wire ?? '-'}·${context ?? section.wire}';
  return _GroupMeta(key: key, epreuve: epreuve, task: task, context: context);
}

/// **Les priorités du Plan, groupées** — et, dans chaque encart, **toutes** les
/// compétences de sa tâche que le candidat a déjà rencontrées.
///
/// Deux passes, dans cet ordre, et l'ordre **est** la règle :
/// 1. les priorités servies créent les encarts et ouvrent leur liste, dans
///    l'ordre du serveur — la priorité n°1 reste la première ligne du premier
///    encart ;
/// 2. les compétences **observées** de `domaines[].skills[]` complètent ces
///    mêmes encarts, dans l'ordre du référentiel (tâche puis rang d'affichage).
///
/// 🛑 **Aucun encart n'est créé par la seconde passe.** Ce bloc s'appelle « Mes
/// priorités » : une tâche sur laquelle le Plan ne demande rien n'y ouvre pas
/// de carte. Ce qu'elle contient se relit sur la fiche de son domaine, où mène
/// le « + N autres » de l'encart voisin.
///
/// 🛑 **La liste complète vient de `domaines[].skills[]`, jamais de
/// `observedSkills`** : ce dernier est **plafonné serveur à 8 toutes épreuves
/// confondues**, donc une épreuve entière pourrait en sortir vide.
List<PlanPriorityGroup> planPriorityGroups(LearningPlan plan) {
  final keys = <String>[];
  final rows = <String, List<PlanPriorityGroupRow>>{};
  final meta = <String, _GroupMeta>{};
  final seen = <String>{};

  // Le palier travaillé par une compétence est **servi** par les domaines, dans
  // les deux familles : le palier de la compétence en compréhension, celui du
  // référentiel en expression. Jamais dérivé d'un code, jamais inventé — et
  // surtout plus replié sur le palier GLOBAL du cycle, qui n'a plus de sens
  // depuis que chaque domaine construit le sien.
  TargetLevel? levelOf(String skillId) => planSkillTargetLevel(plan, skillId);

  for (final priority in <LearningPlanPriority>[
    if (plan.currentPriority != null) plan.currentPriority!,
    ...plan.nextPriorities,
  ]) {
    if (!seen.add(priority.skillId)) continue;
    final level = levelOf(priority.skillId);
    final group = _groupMeta(priority.section, priority.skillCode, level);
    if (!rows.containsKey(group.key)) {
      keys.add(group.key);
      rows[group.key] = <PlanPriorityGroupRow>[];
      meta[group.key] = group;
    }
    rows[group.key]!.add(
      PlanPriorityGroupRow(
        skillId: priority.skillId,
        skillCode: priority.skillCode,
        title: priority.title,
        section: priority.section,
        status: planRowStatus(priority),
        locked: priority.locked,
        level: level,
        priority: priority,
      ),
    );
  }

  for (final domain in plan.domaines) {
    final domainSection = planDomainSection(domain.epreuve);
    if (domainSection == null) continue;
    for (final skill in domain.skills) {
      // Observée **ou** actionnable, jamais autre chose.
      if (skill.observedAt == null && skill.nature == null) continue;
      if (!seen.add(skill.skillId)) continue;
      final section = skill.section ?? domainSection;
      final level = levelOf(skill.skillId);
      final group = _groupMeta(section, skill.skillCode, level);
      final list = rows[group.key];
      if (list == null) continue;
      final status = planObservedRowStatus(skill);
      list.add(
        PlanPriorityGroupRow(
          skillId: skill.skillId,
          skillCode: skill.skillCode,
          title: skill.title,
          section: section,
          status: status,
          locked: status == PlanRowStatus.solide ? false : skill.locked,
          level: level,
        ),
      );
    }
  }

  return keys
      .map(
        (key) => PlanPriorityGroup(
          key: key,
          epreuve: meta[key]!.epreuve,
          task: meta[key]!.task,
          context: meta[key]!.context,
          rows: List<PlanPriorityGroupRow>.unmodifiable(rows[key]!),
        ),
      )
      .toList(growable: false);
}
