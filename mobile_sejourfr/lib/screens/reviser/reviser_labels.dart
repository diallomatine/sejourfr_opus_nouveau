import '../../core/models/civic_plan_models.dart';
import '../../core/models/dashboard_models.dart';
import '../../core/models/diagnostic_models.dart';
import '../../core/models/enums.dart';
import '../../core/models/skill_models.dart';
import '../plan/plan_labels.dart';

/// **Les phrases de l'écran Réviser** — TCF et civique.
///
/// 🛑 **Miroir mot pour mot de `web_sejoufr/lib/reviser.ts`.** Un libellé qui
/// bouge, ce sont deux fichiers dans la même passe.
///
/// 🛑 **Rien n'est classé ici.** Chaque fonction ne fait que poser une phrase
/// sur des **faits servis** — le compteur de séries (`seriesDone` /
/// `seriesTotal`), la couverture d'une tâche (`taches[]`), le niveau d'un
/// domaine, l'état d'un thème, la cible en cours. Aucune ne dérive un état
/// pédagogique ni un niveau CECRL d'un pourcentage.
///
/// 🛑 **L'ordre des cas EST la règle**, et il se lit de haut en bas dans chaque
/// fonction : ce qui est **mesuré** passe devant ce qui est **compté**, et
/// « pas encore travaillé » n'est dit qu'en dernier — jamais comme un verdict.

/* ------------------------------------------------------------------ En-tête */

const String kReviserTitle = 'Réviser';

const String kReviserSubtitleTcf =
    'Le test linguistique exigé pour la résidence et la naturalisation.';

const String kReviserSubtitleCivique =
    'Les thèmes officiels de l\'Examen civique, travaillés notion par notion.';

String reviserSubtitle(AppModule module) => module == AppModule.tcf
    ? kReviserSubtitleTcf
    : kReviserSubtitleCivique;

/// « Les 5 épreuves » / « Les 5 thèmes » — le compte est **celui de la liste**.
String reviserSectionTitle(AppModule module, int count) =>
    module == AppModule.tcf ? 'Les $count épreuves' : 'Les $count thèmes';

/* ------------------------------- Reprendre là où vous vous êtes arrêté ----- */

const String kReviserResumeLabel = 'Reprendre là où vous vous êtes arrêté';
const String kReviserResumeCta = 'Continuer';

/// Ce que le Plan demande de faire **maintenant**, mis en mots.
class ReviserResume {
  const ReviserResume({
    required this.title,
    this.subtitle,
    this.section,
    this.item,
  });

  final String title;
  final String? subtitle;

  /// La section travaillée — c'est elle qui donne le pictogramme.
  final SkillSection? section;

  /// La ligne de séance à lancer, quand c'en est une. `null` quand la reprise
  /// retombe sur la priorité n°1, qui se lance par son propre exercice.
  final PlanSeanceItem? item;
}

/// La reprise TCF.
///
/// 🛑 **La source est le Plan, jamais un historique d'écran** : c'est la
/// première ligne de la séance du jour, sinon la priorité n°1. Les deux
/// viennent de la même autorité que l'écran Plan — Réviser ne peut donc pas
/// désigner autre chose que lui.
///
/// `null` quand il n'y a rien à reprendre : pas de plan, séance vide, ou action
/// **verrouillée** — un compte sans accès ne se voit pas proposer de reprendre
/// ce qu'il ne peut pas faire, il entre par la liste des épreuves (arbitrage du
/// propriétaire, 2026-09-12 : « on passe par Réviser pour voir ce qu'on peut
/// utiliser gratuitement »).
ReviserResume? reviserResumeTcf(LearningPlan? plan) {
  if (plan == null) return null;
  final items = plan.seance.items;
  if (items.isNotEmpty) {
    final item = items.first;
    if (item.locked) return null;
    final title = item.title ?? plan.currentPriority?.title;
    if (title == null) return null;
    return ReviserResume(
      title: title,
      subtitle: _resumeSubtitle(plan, item),
      section: item.section,
      item: item,
    );
  }
  final priority = plan.currentPriority;
  if (priority == null || priority.locked) return null;
  return ReviserResume(title: priority.title, section: priority.section);
}

/// « Expression écrite · Tâche 3 » — le domaine, puis son repère.
String? _resumeSubtitle(LearningPlan plan, PlanSeanceItem item) {
  final epreuve = sectionEpreuve(item.section);
  if (epreuve == null) return null;
  final domain = planDomainLabel(epreuve);
  final tache =
      item.exercise?.tacheNumero ?? domainOf(plan, epreuve)?.tacheCourante;
  if (tache != null) return '$domain · Tâche $tache';
  final level = item.level;
  return level == null ? domain : '$domain · Palier $level';
}

/// « Le Parlement » et « Institutions · notion à travailler ».
ReviserResume? reviserResumeCivique(CivicPlanCible? prochaine) {
  if (prochaine == null) return null;
  final grain = prochaine.grain == CivicPlanGrain.notion ? 'notion' : 'thème';
  return ReviserResume(
    title: prochaine.label,
    subtitle: '${prochaine.themeLabel} · $grain à travailler',
  );
}

/* ---------------------------------------------------- Une épreuve du TCF --- */

const String kReviserNotStarted = 'Pas encore travaillé';

/// L'épreuve d'une section de compétences. `null` hors des quatre domaines du
/// Plan — c'est la même table que `PLAN_DOMAIN_SECTION` côté web, lue à
/// l'envers.
EpreuveType? sectionEpreuve(SkillSection? section) => switch (section) {
      SkillSection.co => EpreuveType.tcfCo,
      SkillSection.ce => EpreuveType.tcfCe,
      SkillSection.ee => EpreuveType.tcfEe,
      SkillSection.eo => EpreuveType.tcfEo,
      _ => null,
    };

/// Le domaine servi pour ce code de catégorie, ou `null` (Structure, civique).
PlanDomain? domainForCode(LearningPlan? plan, String code) => switch (code) {
      'TCF_CO' => domainOf(plan, EpreuveType.tcfCo),
      'TCF_CE' => domainOf(plan, EpreuveType.tcfCe),
      'TCF_EE' => domainOf(plan, EpreuveType.tcfEe),
      'TCF_EO' => domainOf(plan, EpreuveType.tcfEo),
      _ => null,
    };

PlanDomain? domainOf(LearningPlan? plan, EpreuveType epreuve) {
  if (plan == null) return null;
  for (final domain in plan.domaines) {
    if (domain.epreuve == epreuve) return domain;
  }
  return null;
}

bool isProductionCode(String code) => code == 'TCF_EE' || code == 'TCF_EO';

/// La tâche **servie** comme courante sur ce domaine. `null` en compréhension,
/// et `null` quand le serveur ne la nomme pas — on n'en choisit jamais une.
PlanDomainTask? currentTache(PlanDomain? domain) {
  final numero = domain?.tacheCourante;
  if (domain == null || numero == null) return null;
  for (final tache in domain.taches) {
    if (tache.tacheNumero == numero) return tache;
  }
  return null;
}

/// « 2/10 séries » · « 3/8 compétences ». `null` quand il n'y a rien à compter.
String? epreuveMeta(DashboardCategoryStat stat, PlanDomain? domain) {
  if (isProductionCode(stat.code)) {
    final tache = currentTache(domain);
    if (tache == null || tache.totalSkills <= 0) return null;
    return '${tache.observedSkills}/${tache.totalSkills} compétences';
  }
  if (stat.seriesTotal <= 0) return null;
  return '${stat.seriesDone}/${stat.seriesTotal} séries';
}

/// La ligne d'état d'une épreuve.
///
/// Ordre des cas, et c'est la règle : une **production** annonce l'étape que le
/// Plan construit, sinon ce qui est acquis, sinon son niveau ; une épreuve de
/// **compréhension** annonce son niveau mesuré, sinon ses séries faites.
String epreuveStatus(DashboardCategoryStat stat, PlanDomain? domain) {
  if (isProductionCode(stat.code)) {
    final tache = currentTache(domain);
    if (tache != null && tache.observedSkills < tache.totalSkills) {
      return 'Prochaine étape : Tâche ${tache.tacheNumero}';
    }
    final acquises = domain?.solidSkillCount ?? 0;
    if (acquises > 0) {
      final s = acquises > 1 ? 's' : '';
      return '$acquises compétence$s acquise$s';
    }
    final niveau = domain?.niveau ?? stat.level;
    if (niveau != null) return 'Niveau estimé : ${niveau.displayName}';
    return kReviserNotStarted;
  }
  final niveau = domain?.niveau;
  if (domain != null && domain.evaluated && niveau != null) {
    return 'Niveau estimé : ${niveau.displayName}';
  }
  if (stat.seriesDone > 0) {
    final s = stat.seriesDone > 1 ? 's' : '';
    return '${stat.seriesDone} série$s terminée$s';
  }
  return kReviserNotStarted;
}

/// La part remplie de l'anneau, entre 0 et 1.
///
/// 🛑 **Ce n'est pas une note.** C'est une couverture — des séries parcourues,
/// des compétences observées —, et un anneau vide veut dire « pas encore
/// commencé », jamais « mauvais ».
double epreuveRatio(DashboardCategoryStat stat, PlanDomain? domain) {
  if (isProductionCode(stat.code)) {
    final tache = currentTache(domain);
    if (tache == null || tache.totalSkills <= 0) return 0;
    return _clamp01(tache.observedSkills / tache.totalSkills);
  }
  if (stat.seriesTotal <= 0) return 0;
  return _clamp01(stat.seriesDone / stat.seriesTotal);
}

double _clamp01(double value) {
  if (value.isNaN || value.isInfinite) return 0;
  return value.clamp(0, 1).toDouble();
}

/* -------------------------------------------------- Un thème du civique --- */

/// La ligne d'état d'un thème civique.
///
/// 🛑 **Tout est lu sur la ligne servie** (`CivicPlan.themes`), jamais compté
/// dans `priorites` / `aRevoir` / `solides`, qui sont plafonnées à l'affichage.
/// Sans ligne servie — aucun diagnostic terminé — il n'y a rien à dire d'autre
/// que « pas encore travaillé ».
String themeStatus(CivicPlanThemeLigne? ligne, DashboardCategoryStat stat) {
  final enCours = ligne?.enCours;
  if (enCours != null) return 'En cours · ${enCours.label}';
  if (ligne != null && ligne.maitrisees > 0) {
    final nom = ligne.grain == CivicPlanGrain.notion ? 'notion' : 'thème';
    final s = ligne.maitrisees > 1 ? 's' : '';
    return '${ligne.maitrisees} $nom$s maîtrisée$s';
  }
  if ((ligne?.travaillees ?? 0) > 0 || stat.seriesDone > 0) {
    return 'À travailler';
  }
  return kReviserNotStarted;
}

/// La ligne servie pour ce thème, cherchée par son id.
CivicPlanThemeLigne? themeLigneFor(
  List<CivicPlanThemeLigne> themes,
  String? themeId,
) {
  if (themeId == null) return null;
  for (final ligne in themes) {
    if (ligne.themeId == themeId) return ligne;
  }
  return null;
}
