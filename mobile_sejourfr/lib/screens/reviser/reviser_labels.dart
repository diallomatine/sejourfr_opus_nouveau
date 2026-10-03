/// **Les phrases de l'écran Réviser** — TCF et civique.
///
/// 🛑 **Miroir mot pour mot de `web_sejoufr/lib/reviser.ts`.** Un libellé qui
/// bouge, ce sont deux fichiers dans la même passe.
///
/// 🛑 **Rien n'est classé ici.** Chaque fonction ne fait que poser une phrase
/// sur des **faits servis** — le compteur de séries (`seriesDone` /
/// `seriesTotal`), celui des sujets d'expression (`subjectsDone` /
/// `subjectsTotal`), la tâche courante (`taches[]`), le **niveau actuel
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

/// « Les 4 épreuves » / « Les 5 thèmes » — le compte est **celui de la liste**.
String reviserSectionTitle(AppModule module, int count) =>
    module == AppModule.tcf ? 'Les $count épreuves' : 'Les $count thèmes';

/* --------------------------------------- Recommandé par votre plan ----- */

/// **Le sur-titre de la carte de recommandation du Plan** (`PlanEpreuveReco`).
///
/// 🛑 Il **nomme le Plan** (demande du propriétaire, 2026-09-20) : ce que la
/// carte annonce est **désigné par le Plan**, pas par un historique d'écran.
/// La carte de reprise en tête de l'écran Entraînement est **retirée**
/// (2026-10-03, « on a le plan juste à côté ») ; le libellé ne sert plus
/// qu'au Plan.
const String kReviserResumeLabel = 'Recommandé par votre plan';

/* ---------------------------------------------------- Une épreuve du TCF --- */

const String kReviserNotStarted = 'Pas encore travaillé';

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

/// « 2/10 séries » · « 3/40 sujets ». `null` quand il n'y a rien à compter.
///
/// 🛑 **Sert aussi les 5 thèmes civiques** (demande du propriétaire,
/// 2026-09-26) : même carte, même « N/M séries », même anneau que CO/CE — le
/// décompte `seriesDone` / `seriesTotal` du thème, servi par `/api/me/dashboard`.
///
/// Une épreuve d'expression compte ses **sujets servis** (`subjectsDone` /
/// `subjectsTotal`, ses 3 tâches confondues) — jamais un décompte refait ici.
/// Le pluriel suit le total : « 1/40 sujets ». Miroir mot pour mot du web
/// (`epreuveMeta`, `lib/reviser.ts`).
String? epreuveMeta(DashboardCategoryStat stat) {
  if (isProductionCode(stat.code)) {
    if (stat.subjectsTotal <= 0) return null;
    return '${stat.subjectsDone}/${stat.subjectsTotal} sujets';
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

/// **L'avancement du parcours civique, en séries** — la fonction UNIQUE du
/// mobile (Navigation v2, brief §6). Miroir exact côté web :
/// `avancementSeriesCivique` (`web_sejoufr/lib/reviser.ts`).
///
/// `pourcentage = floor(Σ seriesDone / Σ seriesTotal × 100)`, sur les thèmes
/// servis par `GET /api/me/dashboard` (`DashboardSummary.civique`).
///
/// - Une série **terminée** = au moins un passage fini, quel que soit le score
///   (`LotService`, D5-A amendé) ; le total compte **toutes** les séries du
///   thème, verrouillées comprises, toutes mentions confondues (X4 : les lots
///   civiques ne sont pas filtrés par mention côté serveur).
/// - `floor` : jamais 100 % tant qu'il reste une série. Total nul ⇒ 0 %.
///
/// 🛑 **Ce n'est pas une note ni un état** : c'est une couverture. Aucun écran ne la classe en niveau ni en ton.
/// Restreinte à un thème, passer `[stat]`.
({int pourcentage, int terminees, int total}) avancementSeriesCivique(
  Iterable<DashboardCategoryStat> themes,
) {
  var terminees = 0;
  var total = 0;
  for (final theme in themes) {
    terminees += theme.seriesDone < 0 ? 0 : theme.seriesDone;
    total += theme.seriesTotal < 0 ? 0 : theme.seriesTotal;
  }
  if (total <= 0) return (pourcentage: 0, terminees: terminees, total: 0);
  final faites = terminees > total ? total : terminees;
  return (
    pourcentage: (faites * 100) ~/ total,
    terminees: faites,
    total: total,
  );
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
