/// **Les phrases de l'écran Réviser** — TCF et civique.
///
/// 🛑 **Miroir mot pour mot de `web_sejoufr/lib/reviser.ts`.** Un libellé qui
/// bouge, ce sont deux fichiers dans la même passe.
///
/// 🛑 **Rien n'est classé ici.** Chaque fonction ne fait que poser une phrase
/// sur des **faits servis** — le compteur de séries (`seriesDone` /
/// `seriesTotal`), la couverture d'une tâche (`taches[]`), le **niveau actuel
/// d'une épreuve** (`tcfDomainProfile`, l'autorité d'affichage), l'état d'un
/// thème, la cible en cours. Aucune ne dérive un état pédagogique ni un niveau
/// CECRL d'un pourcentage.
///
/// 🛑 **L'ordre des cas EST la règle**, et il se lit de haut en bas dans chaque
/// fonction : ce qui est **mesuré** passe devant ce qui est **compté**, et
/// « pas encore travaillé » n'est dit qu'en dernier — jamais comme un verdict.
library;

import '../../core/models/civic_plan_models.dart';
import '../../core/models/dashboard_models.dart';
import '../../core/models/diagnostic_models.dart';
import '../../core/models/enums.dart';
import '../../core/models/skill_models.dart';
import '../../core/models/journey_models.dart';
import '../plan/plan_now_card.dart';
import '../progres/progres_labels.dart' show niveauActuelEpreuve;

/* --------------------------------- Structure de la langue, hors examen ---- */

/// 🛑 **Le TCF IRN comporte QUATRE épreuves.** La liste et les phrases du
/// module complémentaire vivent dans `core/utils/tcf_epreuves.dart` — elles
/// servent aussi l'écran de détail du module, donc elles ne sont pas propres à
/// Réviser. Réexportées ici pour que l'écran n'ait qu'un import.
export '../../core/utils/tcf_epreuves.dart'
    show
        kTcfCodeComplementaire,
        kTcfComplementaireNote,
        kTcfComplementaireNoteReviser,
        kTcfComplementaireNoteTitle,
        kTcfComplementaireSectionTitle,
        kTcfEpreuvesOfficielles;

/* ------------------------------------------------------------------ En-tête */

const String kReviserTitle = 'Réviser';

const String kReviserSubtitleTcf =
    'Le test linguistique exigé pour la résidence et la naturalisation.';

const String kReviserSubtitleCivique =
    'Les thèmes officiels de l\'Examen civique, travaillés notion par notion.';

String reviserSubtitle(AppModule module) => module == AppModule.tcf
    ? kReviserSubtitleTcf
    : kReviserSubtitleCivique;

/// « Les 4 épreuves » / « Les 5 thèmes » — le compte est **celui de la liste**.
String reviserSectionTitle(AppModule module, int count) =>
    module == AppModule.tcf ? 'Les $count épreuves' : 'Les $count thèmes';

/* ------------------------------- Reprendre là où vous vous êtes arrêté ----- */

const String kReviserResumeLabel = 'Reprendre là où vous vous êtes arrêté';
const String kReviserResumeCta = 'Continuer';

/// **Le sur-titre de la carte de tête quand il n'y a RIEN à reprendre** — parce
/// que le diagnostic n'a pas encore été fait.
///
/// 🛑 **La carte ne disparaît plus** (demande du propriétaire, 2026-09-13) :
/// « si le diagnostic n'est pas fait, dans la section Reprendre où vous vous
/// êtes arrêté, plutôt proposer de faire le diagnostic ». L'écran ouvrait sur sa
/// liste d'épreuves sans jamais nommer le geste qui débloque tout le reste.
///
/// 🛑 **Aucune phrase de porte n'est écrite ici** : le titre, le texte, le
/// libellé du bouton et sa destination viennent de [planIndisponible]
/// (`core/models/preparation_labels.dart`), la **même autorité** que l'Accueil
/// et que l'écran Plan. C'est ce qui garantit que les trois écrans proposent le
/// même geste — « Faire mon diagnostic » côté TCF, « Faire mon diagnostic
/// civique » côté civique — et qu'un diagnostic **commencé** s'y reprend au lieu
/// de se refaire.
const String kReviserDepartLabel = 'Votre point de départ';

/// Ce que le Plan demande de faire **maintenant**, mis en mots.
class ReviserResume {
  const ReviserResume({
    required this.title,
    this.subtitle,
    this.section,
    this.carte,
  });

  final String title;
  final String? subtitle;

  /// La section travaillée — c'est elle qui donne le pictogramme.
  final SkillSection? section;

  /// **Ce que le bouton lance**, tel que le Plan l'a désigné. `null` en
  /// civique, dont la reprise est une cible et se lance par `startCivicSerie`.
  final PlanNowCard? carte;
}

/// La reprise TCF.
///
/// 🛑 **La source est le Plan, jamais un historique d'écran** — et c'est
/// [planNowCard] qui la décide, la **même autorité** que la carte « À faire
/// maintenant » du Plan et de l'Accueil, des deux côtés. Réviser lisait
/// `plan.seance.items.first` puis retombait sur `currentPriority` : une
/// **mesure de domaine** qui n'ouvrait pas la séance lui échappait, et l'écran
/// annonçait la priorité pédagogique pendant que le Plan, au même instant,
/// demandait de compléter une mesure.
///
/// `null` quand il n'y a rien à reprendre : pas de plan, aucune priorité
/// servie, rien à lancer, ou action **verrouillée** — un compte sans accès ne
/// se voit pas proposer de reprendre ce qu'il ne peut pas faire, il entre par
/// la liste des épreuves (arbitrage du propriétaire, 2026-09-12 : « on passe
/// par Réviser pour voir ce qu'on peut utiliser gratuitement »).
ReviserResume? reviserResumeTcf(LearningPlan? plan, {Journey? journey}) {
  if (plan == null) return null;
  // 🛑 **Le parcours est passé jusqu'ici** : sans lui, Réviser retomberait sur
  // la règle du Plan pendant que le Plan suivrait le parcours — la même
  // contradiction, à un troisième écran.
  final carte = planNowCard(plan, journey: journey);
  if (carte == null || carte.locked) return null;
  // Rien à lancer — ni mesure, ni exercice : on ne propose pas un bouton mort.
  if (carte.mesure == null && carte.exercise == null) return null;
  return ReviserResume(
    title: carte.title,
    subtitle: carte.subtitle,
    section: carte.section,
    carte: carte,
  );
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
///
/// 🛑 **Le niveau vient de [niveauActuelEpreuve], l'autorité d'AFFICHAGE** —
/// jamais de `PlanDomain.niveau` (la lecture du Plan, qui voit les
/// entraînements) ni de `DashboardCategoryStat.level` (une troisième autorité,
/// encore plus large). `domain` ne sert plus qu'à ce que Réviser **compte** :
/// la tâche courante et les compétences acquises.
String epreuveStatus(
  DashboardCategoryStat stat,
  PlanDomain? domain,
  TcfDomainProfile? profil,
) {
  final niveau = niveauActuelEpreuve(profil, stat.code);
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
    if (niveau != null) return 'Niveau estimé : ${niveau.displayName}';
    return kReviserNotStarted;
  }
  if (niveau != null) {
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
