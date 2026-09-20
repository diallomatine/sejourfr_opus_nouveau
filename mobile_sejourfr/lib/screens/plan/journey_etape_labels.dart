/// **Les phrases de l'écran d'une étape de séries** — le détail qui s'ouvre
/// quand on touche une étape d'entraînement de compréhension (CO/CE) ou une
/// étape civique dans le cycle du Plan.
///
/// 🛑 **Miroir mot pour mot de `web_sejoufr/lib/journey-etape.ts`.** Un libellé
/// qui bouge, ce sont deux fichiers dans la même passe.
///
/// 🛑 **Aucune de ces phrases n'est servie**, et aucune ne classe un nombre.
/// L'état d'une série se lit sur les deux faits **servis** `locked` et
/// `validee` ; `dernierScore` ne sert qu'à être **affiché**, jamais comparé à
/// `seuilReussite`. Un front qui comparerait un nombre à un seuil deviendrait
/// une seconde autorité sur « cette série est-elle réussie ? ».
library;

import '../../core/models/journey_models.dart';
import '../../core/models/skill_models.dart';
import '../../core/widgets/sejour/sejour_kit.dart';

/* --------------------------------------------------------------- En-tête */

/// Le sous-titre de l'en-tête : « Plan B2 », « Plan — Naturalisation ».
///
/// 🛑 **Le libellé est SERVI** (`objectif.label`), jamais composé d'un `code`
/// ni d'une table de mentions recopiée ici. Seule la **tournure** se choisit sur
/// `kind` — un palier se colle au mot « Plan », une démarche se détache —
/// exactement comme [journeyTitle], et **jamais** sur le module.
///
/// `null` quand aucun objectif n'est déclaré : on n'écrit pas « Plan » seul.
String? journeyEtapeObjectif(JourneyObjectifRef? objectif) {
  if (objectif == null) return null;
  return objectif.kind == JourneyObjectifKind.niveau
      ? 'Plan ${objectif.label}'
      : 'Plan — ${objectif.label}';
}

/// La pastille de gauche : « CO · B2 ».
///
/// 🛑 **Elle ne dit que ce qui est servi** — le domaine, et le **libellé** de
/// l'objectif. Sans section (une étape civique n'en a pas) il n'y a pas de
/// domaine à nommer, donc pas de pastille ; sans objectif la pastille se réduit
/// au domaine. On ne comble ni l'un ni l'autre.
String? journeyEtapeSectionPill(
    SkillSection? section, JourneyObjectifRef? objectif) {
  if (section == null) return null;
  return objectif == null
      ? section.wire
      : '${section.wire} · ${objectif.label}';
}

/// La pastille de droite, quand l'étape est prioritaire. **`priorite` est servi.**
const kJourneyEtapePriorite = 'Priorité';

/* ----------------------------------------------------------- Progression */

/// Le compteur en gros : « 0/2 séries ».
///
/// 🛑 **[validees] et [quota] sont SERVIS**, tous les deux : l'écran ne recompte
/// rien — c'est le compteur du moteur, celui qui décide de clore l'étape.
String journeyEtapeCompteur(int validees, int quota) =>
    '$validees/$quota série${quota > 1 ? 's' : ''}';

/// Le repère de droite : « 16/20 minimum ». **`seuil` et `questions` sont servis.**
String journeyEtapeSeuil(int seuil, int questions) =>
    '$seuil/$questions minimum';

/// Ce qui se lit sous le repère.
const kJourneyEtapeSeuilSub = 'sur chacune';

/* ------------------------------------------------------------- Les séries */

/// L'intertitre de la liste.
const kJourneyEtapeListTitle = 'À FAIRE';

/// « Série 1 » — l'index est **servi**.
String journeyEtapeSerieTitle(int index) => 'Série $index';

/// Le repère carré de la carte.
String journeyEtapeSerieMark(int index) => '$index';

/// « 16 min ». `null` quand la durée n'est pas servie — on n'en invente pas.
String? journeyEtapeDuree(int? minutes) =>
    minutes == null ? null : '$minutes min';

/// « 20 questions ».
String journeyEtapeQuestions(int questions) =>
    '$questions question${questions > 1 ? 's' : ''}';

/// **Le badge d'état d'une série.**
///
/// 🛑 **Il se lit sur `locked` et `validee`, dans cet ordre, et sur rien
/// d'autre.** « À refaire » n'est pas un jugement du score : c'est « jouée, pas
/// encore validée », deux faits servis. Le score n'entre jamais dans ce choix.
///
/// 🛑 **« Réussie » est DÉFINITIF** : une série refaite et ratée garde ce badge,
/// parce que `validee` reste vrai côté serveur.
({String label, SfBarTone tone}) journeyEtapeSerieState(JourneySerie serie) {
  if (serie.locked) return (label: 'Verrouillée', tone: SfBarTone.muted);
  if (serie.validee) return (label: 'Réussie', tone: SfBarTone.ok);
  if (serie.dernierAttemptId != null) {
    return (label: 'À refaire', tone: SfBarTone.warn);
  }
  return (label: 'À faire', tone: SfBarTone.hot);
}

/// **Le bouton de la carte.**
///
/// [precedente] est l'index de la série **servie** juste avant celle-ci —
/// jamais `index - 1` calculé ici : c'est la liste servie qui dit ce qui
/// précède. `null` (aucune précédente) laisse la phrase générique.
String journeyEtapeSerieCta(JourneySerie serie, int? precedente) {
  if (serie.locked) {
    return precedente == null ? 'Verrouillée' : 'Après la série $precedente';
  }
  return serie.dernierAttemptId != null ? 'Refaire la série' : 'Commencer';
}

/// Le second accès d'une série déjà jouée : son corrigé.
const kJourneyEtapeSerieResult = 'Voir mon résultat';

/// « Dernier score : 17/20 ». 🛑 **Affiché, jamais comparé.**
String? journeyEtapeDernierScore(int? score, int questions) =>
    score == null ? null : 'Dernier score : $score/$questions';

/* ----------------------------------------------------- Pied de l'écran */

/// Ce qui ouvre l'encart de validation.
const kJourneyEtapeValidationLead = 'Validation :';

/// « 2 séries réussies à 16/20 minimum. »
String journeyEtapeValidation(int quota, int seuil, int questions) =>
    ' $quota série${quota > 1 ? 's' : ''}'
    ' réussie${quota > 1 ? 's' : ''}'
    ' à $seuil/$questions minimum.';

/// La note de pied, **en compréhension ORALE seulement**.
///
/// 🛑 **C'est une condition de passation, pas une déduction de route** : elle ne
/// s'écrit que sur `section == SkillSection.co`, le fait servi.
const kJourneyEtapeCoFoot =
    'Audio écouté une seule fois • conditions proches du TCF';

/// `null` partout ailleurs qu'en compréhension orale.
String? journeyEtapeFoot(SkillSection? section) =>
    section == SkillSection.co ? kJourneyEtapeCoFoot : null;

/* --------------------------------------------------------------- États */

const kJourneyEtapeLoading = "Chargement de l'étape…";

const kJourneyEtapeError = 'Impossible de charger cette étape.';

const kJourneyEtapeRetry = 'Réessayer';

const kJourneyEtapeStartError = "La série n'a pas pu démarrer. Réessayez.";

/// Le titre de l'écran quand rien n'est encore chargé — l'en-tête ne clignote pas.
const kJourneyEtapeTitleFallback = 'Votre étape';

/// **Le verrou freemium de l'étape** : l'écran reste entier et lisible, seul le
/// geste est fermé (D-18, « on floute l'ACTION jamais le RÉSULTAT »).
const kJourneyEtapeLockedNote =
    'Cette étape fait partie du parcours complet.';

/// Ce qu'un titre d'écran dit d'une étape dont le détail n'a pas encore répondu.
String journeyEtapeTitle(JourneyStepDetail? detail) =>
    detail?.bloc.label ?? kJourneyEtapeTitleFallback;
