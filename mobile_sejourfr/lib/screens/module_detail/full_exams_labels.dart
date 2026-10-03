import '../../core/models/billing_models.dart';
import '../../core/models/enums.dart';
import '../../core/utils/tcf_epreuves.dart';
import '../progression/progression_labels.dart';

/// **Les phrases des segments « Examens » des deux modules** (Navigation v2,
/// phase 4b — maquettes `docs/redesign/sejourfr-navigation-{mobile,web}.html`,
/// `#tcf-examens` / `#civique-examens`). Textes éditoriaux repris tels quels
/// (R8) ; chaque valeur (nombre d'épreuves, de questions, de thèmes, seuil,
/// durée, créneaux) est **lue** — miroirs gelés `tcf_epreuves.dart`,
/// `civique_examen.dart`, `epreuve_duration.dart`, ou données servies —,
/// jamais écrite ici (R7).

/* ------------------------------------------------------------------ TCF */

const String kTcfExamsHeroLabel = 'Simulation réelle';
const String kTcfExamsHeroTitle = 'Examen blanc complet';
const String kTcfExamsSectionTitle = 'Mes examens';

/// « CO · CE · EE · EO » — les épreuves officielles, depuis le miroir.
String tcfExamsEpreuvesLabel() => [
      for (final code in kTcfEpreuvesOfficielles)
        tcfEpreuveMark(EpreuveType.fromWire(code)),
    ].join(' · ');

/// « CO · CE · EE · EO · environ 95 min, avec niveau estimé et analyse IA à
/// la clé. » — miroir `EXAMENS_TCF_HERO_SUB` ; la durée, quand elle est connue.
String tcfExamsHeroSub(String? duree) => duree == null
    ? tcfExamsEpreuvesLabel()
    : '${tcfExamsEpreuvesLabel()} · environ $duree, avec niveau estimé et '
        'analyse IA à la clé.';

/// Les puces de conditions, miroir des `tips` du web.
const String kExamsChipConditions = 'Conditions réelles';
const String kTcfExamsChipCecrl = 'Niveau CECRL';

/// La puce « 4 épreuves » des repères de l'examen.
String tcfExamsEpreuvesChip() => '${kTcfEpreuvesOfficielles.length} épreuves';

String tcfExamsStartCta(int slot) => "Commencer l'examen $slot";
String tcfExamsResumeCta(int slot) => "Reprendre l'examen $slot";
String tcfExamsRowTitle(int slot) => 'Examen $slot';

/* -------------------------------------------------------------- civique */

const String kCiviqueExamsHeroLabel = 'Conditions réelles';
const String kCiviqueExamsHeroTitle = 'Examen blanc civique';
const String kCiviqueExamsCta = 'Lancer un examen blanc';

/// Créneaux libres tous verrouillés : le hero ouvre l'offre (miroir
/// `EXAMENS_CIVIQUE_HERO_PASS`).
final String kCiviqueExamsHeroPass =
    'Voir le pass ${PlanModuleTarget.civique.label}';
const String kCiviqueExamsSectionTitle = 'Historique';
const String kCiviqueExamsQuestionsStat = 'questions';

/// « 40 questions · les 5 thèmes · objectif de réussite : 32/40. » — format
/// légal (miroir `CivicExamFormat`) et nombre de thèmes servi ; thèmes
/// inconnus (tableau de bord pas encore lu) ⇒ la mention disparaît.
String civiqueExamsHeroSub({
  required int questions,
  required int seuil,
  int? themes,
}) {
  final parts = [
    '$questions questions',
    if (themes != null && themes > 0) 'les $themes thèmes',
    'objectif de réussite : $seuil/$questions',
  ];
  return '${parts.join(' · ')}.';
}

String civiqueExamsRowTitle(int slot) => 'Examen blanc $slot';

/* --------------------------------------------------------------- communs */

const String kExamsStatusDone = 'Fait';

/* Méta d'un créneau — miroir mot pour mot de `EXAMENS_META_*` / `examensMeta*`
   (web `lib/examens-blancs.ts`). 🛑 Un créneau ouvert se dit « Disponible » :
   l'examen offert se lit sur le verrou SERVI, jamais sur le rang 1. */
const String kExamsMetaOpen = 'Disponible';
const String kExamsMetaInProgress = 'En cours';
const String kExamsMetaPending = 'Évaluation en cours…';

/// « Inclus dans le pass Intégral » — le nom court du pass vient de
/// [PlanModuleTargetX.label] (miroir `PASS_MODULE_NAME`), jamais écrit ici.
String examsMetaLocked({required bool integral}) =>
    'Inclus dans le pass ${(integral ? PlanModuleTarget.integral : PlanModuleTarget.civique).label}';

/// « Terminé · niveau estimé B1 » (+ « · partiel »), sur le palier servi.
String examsMetaTcfTermine(String niveau, {required bool partiel}) =>
    'Terminé · niveau estimé $niveau${partiel ? ' · partiel' : ''}';

/// « 29/40 · terminé » — score brut servi, aucun verdict de seuil.
String examsMetaCiviqueTermine(String score) => '$score · terminé';

/// La feuille d'un examen déjà passé (miroir `EXAMENS_DONE_*`).
const String kExamsDoneDetail = 'Voir le rapport';
const String kExamsDoneResume = "Refaire l'examen";

/// La grille repliée : 8 créneaux, jamais moins que les examens passés + le
/// suivant. Plafond d'AFFICHAGE seulement. Miroir `examensVisibles`.
const int kExamsReplies = 8;
int examsVisibles(int total, int passes, {required bool deplie}) {
  if (deplie) return total;
  final mini = passes + 1 < total ? passes + 1 : total;
  final n = kExamsReplies > mini ? kExamsReplies : mini;
  return n < total ? n : total;
}
const String kExamsStatusStart = 'Commencer';
const String kExamsStatusResume = 'Reprendre';
const String kExamsStatusPending = 'En cours';
const String kExamsStatusLocked = 'Verrouillé';

/// La tuile « Terminés » : créneaux faits sur créneaux **servis**
/// (`slots.length`, jamais 20 écrit ici). Grille pas encore lue ⇒ le
/// compteur seul.
String examsDoneValue(int faits, int? total) =>
    total == null ? '$faits' : '$faits/$total';

const String kExamsDoneLabel = 'Terminés';

/// « Voir les examens 8 à 20 » — bornes lues sur la grille servie.
String examsShowMoreLabel(int from, int to) => 'Voir les examens $from à $to';

const String kExamsBlockError = "Vos examens n'ont pas pu être chargés.";
const String kExamsRetry = 'Réessayer';
