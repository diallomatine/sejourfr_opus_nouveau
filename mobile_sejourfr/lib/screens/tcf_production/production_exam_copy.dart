import '../../core/models/enums.dart';
import '../../core/models/production_models.dart';
import 'widgets/production_common.dart' show productionTaskConstraint;

// **La copie de l'examen blanc EE/EO** — la feuille d'information qui précède
// le démarrage, l'en-tête du runner et sa feuille « ⓘ ». Déclarée une fois
// pour toute l'app.
//
// ⚠️ **Miroir mot pour mot du web** : `web_sejoufr/lib/production-exam-copy.ts`.
// Une phrase qui bouge, ce sont les deux fichiers à changer dans la même
// passe.
//
// 🛑 **Aucune durée ni aucune borne de mots n'est écrite ici.** La durée
// d'épreuve arrive en paramètre (`epreuveDurationLabelFor`, miroir de
// `DureeEpreuve`) ; les bornes de mots et les temps de parole sont lus sur
// les sujets **servis** (`production_tasks.mots_min/mots_max/duree_max_sec`)
// via [productionTaskConstraint]. Seuls les mots éditoriaux vivent ici.
//
// Registre : **vouvoiement**, comme tout le parcours TCF hors module
// « Compétences ».

/* ------------------------------------------------ feuille d'information */

const String kProductionExamBriefingDeroule = 'Déroulé';
const String kProductionExamBriefingConseil = 'Conseil';
const String kProductionExamBriefingStart = 'Commencer maintenant';
const String kProductionExamBriefingCancel = 'Annuler';

/// « EXAMEN COMPLET EXPRESSION ÉCRITE » (mis en capitales par l'appelant).
String productionExamBriefingEyebrow(String epreuveLabel) =>
    'Examen complet $epreuveLabel';

String productionExamBriefingTitle(EpreuveType epreuve) =>
    epreuve == EpreuveType.tcfEo ? 'Prêt à parler ?' : 'Prêt à écrire ?';

/// Le paragraphe de la carte bleue. [durationLabel] (« 30 min ») est ignoré à
/// l'oral, qui n'a pas de chrono d'épreuve.
String productionExamBriefingIntro(EpreuveType epreuve, String durationLabel) =>
    epreuve == EpreuveType.tcfEo
        ? "Vous enchaînez 3 tâches orales, comme au vrai TCF. Vous lisez chaque consigne sans chrono, puis vous lancez la tâche quand vous êtes prêt : le temps de parole ne part qu'à cet instant. Chaque réponse est enregistrée puis notée par l'IA."
        : "Vous enchaînez 3 tâches écrites d'affilée, comme au vrai TCF. Le chrono de $durationLabel couvre les 3 tâches ensemble : à vous de répartir votre temps. Chaque réponse est corrigée par l'IA en fin de session.";

String productionExamBriefingConseil(EpreuveType epreuve) =>
    epreuve == EpreuveType.tcfEo
        ? "Exprimez vos idées clairement et utilisez des connecteurs (d'abord, ensuite, donc). L'IA corrige les mots transcrits : elle n'évalue ni la prononciation ni la fluidité."
        : 'Lisez bien la consigne, structurez votre réponse (introduction, développement, conclusion) et respectez le nombre de mots indiqué.';

/// Ce que demande chaque tâche, en quelques mots (éditorial).
String _taskDetail(EpreuveType epreuve, int tacheNumero) {
  if (epreuve == EpreuveType.tcfEo) {
    return switch (tacheNumero) {
      1 => 'Parler de soi, travail, loisirs',
      2 => 'Poser des questions et interagir',
      3 => 'Donner son avis et argumenter',
      _ => '',
    };
  }
  return switch (tacheNumero) {
    1 => 'Email, invitation, annulation',
    2 => 'Expérience personnelle',
    3 => 'Argumentation simple',
    _ => '',
  };
}

/// La contrainte **servie** d'une tâche de l'examen (« 30-60 mots »,
/// « 3 min »), lue sur les sujets du catalogue de l'épreuve.
///
/// 🛑 `null` = inconnu : catalogue pas encore chargé, ou sujets d'une même
/// tâche qui ne s'accordent pas. On ne l'invente jamais et on ne choisit pas
/// entre deux valeurs — la ligne s'affiche alors sans contrainte.
String? productionExamTaskConstraint(
  List<ProductionTaskDto>? tasks,
  EpreuveType epreuve,
  int tacheNumero,
) {
  if (tasks == null) return null;
  final oral = epreuve == EpreuveType.tcfEo;
  final values = tasks
      .where((t) => t.tacheNumero == tacheNumero)
      .map((t) => productionTaskConstraint(t, isOral: oral))
      .toSet();
  if (values.length != 1) return null;
  return values.first;
}

/// « Email, invitation, annulation · 30-60 mots » — la contrainte seulement
/// si elle est connue.
String productionExamTaskDetail(
  EpreuveType epreuve,
  int tacheNumero,
  String? constraint,
) =>
    [_taskDetail(epreuve, tacheNumero), constraint]
        .whereType<String>()
        .where((part) => part.isNotEmpty)
        .join(' · ');

/* --------------------------------------------------------------- runner */

/// « Tâche 1 sur 3 ».
String productionExamStepLabel(int tacheNumero, int total) =>
    'Tâche $tacheNumero sur $total';

/// La contrainte de la tâche, **dite une seule fois** sur la carte de
/// consigne : « Longueur attendue : 30 à 60 mots » à l'écrit, « Temps de
/// parole : 3 min » à l'oral. Lue sur le sujet servi ; `null` quand il ne la
/// porte pas.
String? productionExamConstraintLine(ProductionTaskDto task) {
  if (task.epreuve == EpreuveType.tcfEo) {
    final duree = productionTaskConstraint(task, isOral: true);
    return duree == null ? null : 'Temps de parole : $duree';
  }
  final min = task.motsMin;
  final max = task.motsMax;
  if (min == null || max == null) return null;
  return 'Longueur attendue : $min à $max mots';
}

/// Le repère de rythme sous la consigne écrite. [advisedLabel] vient de
/// `eeTempsConseilleLabel` (« ≈ 7 min conseillées »).
String productionExamAdvisedTimeLine(String advisedLabel) =>
    '$advisedLabel sur cette tâche — un repère, pas une limite : le chrono affiché couvre les 3 tâches.';

/* ------------------------------------ oral : revue d'un enregistrement */

// La tâche orale se déroule en quatre temps : consigne (sans chrono) →
// enregistrement (décompte de la tâche en examen) → **revue** → envoi. La revue
// existe parce que l'arrêt n'envoyait rien de visible : l'écran se figeait le
// temps de la transcription, puis la tâche suivante tombait d'un coup.
//
// 🛑 La réécoute lit l'enregistrement **resté sur l'appareil** : rien n'est
// envoyé pour la permettre, rien n'est conservé après l'envoi
// (`docs/regles/audio-productions.md`).

const String kProductionExamReviewTitle = 'Enregistrement terminé';

/// Sous le titre de la revue. [timeUp] : l'arrêt est venu du décompte.
String productionExamReviewHint({required bool timeUp}) {
  final lead = timeUp
      ? "Le temps de parole est écoulé, l'enregistrement s'est arrêté. "
      : '';
  return '${lead}Réécoutez votre réponse, recommencez-la si besoin, puis envoyez-la.';
}

const String kProductionExamRedo = 'Recommencer';

/// Ce que coûte « Recommencer », dit avant le geste.
const String kProductionExamRedoNote =
    'Recommencer efface cet enregistrement ; le temps de parole de la tâche repart en entier.';

/// Le bouton principal de la revue, qui envoie la réponse.
String productionExamNextLabel({required bool isLast, required bool inFullExam}) {
  if (!isLast) return 'Tâche suivante';
  return inFullExam ? "Terminer l'épreuve" : "Terminer l'examen";
}

const String kProductionExamSending = 'Envoi de votre réponse…';

const String kProductionExamSendError =
    "L'envoi n'a pas abouti. Votre enregistrement est toujours sur cet appareil : réessayez.";

const String kProductionExamRetry = 'Réessayer';

/* --------------------------------------------- attente de l'évaluation */

// L'écran d'attente de l'analyse IA (cocarde, « Analyse en cours », étapes),
// `EvaluationLoadingView`. Les étapes avancent au rythme indicatif ci-dessous,
// pas au rythme réel du serveur : elles disent ce qui se passe, elles ne le
// mesurent pas.

const String kEvaluationLoadingTitle = 'Analyse en cours';
const String kEvaluationLoadingLead = 'Votre évaluation arrive juste après.';
const String kEvaluationLoadingLast = 'Encore quelques secondes…';

enum EvaluationLoadingStepKey { upload, transcription, analysis, report }

/// Les étapes et leur durée indicative (secondes), transcription à l'oral.
List<({EvaluationLoadingStepKey key, String label, int seconds})>
    evaluationLoadingSteps({required bool includeTranscription}) => [
          (
            key: EvaluationLoadingStepKey.upload,
            label: 'Envoi de votre production',
            seconds: 2,
          ),
          if (includeTranscription)
            (
              key: EvaluationLoadingStepKey.transcription,
              label: 'Transcription audio',
              seconds: 6,
            ),
          (
            key: EvaluationLoadingStepKey.analysis,
            label: 'Analyse pédagogique',
            seconds: 6,
          ),
          (
            key: EvaluationLoadingStepKey.report,
            label: 'Préparation de votre bilan',
            seconds: 4,
          ),
        ];

/* ------------------------------------------------------ feuille « ⓘ » */

const String kProductionInfoTitle = 'Comment votre production est évaluée';
const String kProductionInfoCriteriaLabel = 'Vous serez évalué sur';
const String kProductionInfoClose = "J'ai compris";
const String kProductionInfoPrivacyLabel = 'Confidentialité';

/// Les QUATRE critères de **notre grille SejourFR**, à poids égaux,
/// identiques sur les six tâches — miroir strict de la grille serveur
/// (`prompts/production-rubrics-*.json`, `docs/notation-ia-eo-ee.md`).
///
/// ⚠️ Ne pas les présenter comme « les critères du TCF » : France Éducation
/// international publie les siens en trois familles et fait corriger par des
/// évaluateurs humains. Côté oral, ni l'aisance ni la prononciation n'y
/// figurent : l'évaluation part de la transcription.
const List<({String label, String hint})> kProductionCriteria = [
  (
    label: 'Communiquer',
    hint: 'accomplir ce que demande la consigne et enchaîner ses idées',
  ),
  (
    label: 'Interagir',
    hint: "s'adapter à la situation et à la personne à qui l'on s'adresse",
  ),
  (label: 'Lexique', hint: 'un vocabulaire approprié et précis'),
  (label: 'Morphosyntaxe', hint: 'la correction grammaticale'),
];

const String kProductionCriteriaFoot =
    "Les quatre critères de notre grille, qui comptent autant l'un que l'autre. Ils couvrent les dimensions évaluées au TCF — linguistique, pragmatique, sociolinguistique — sans reprendre la grille de correction officielle. Ce sont les attentes derrière chacun qui montent d'une tâche à la suivante.";

/// La confidentialité de la production.
String productionPrivacyText(EpreuveType epreuve) => epreuve == EpreuveType.tcfEo
    ? "Votre réponse est transcrite puis analysée par notre IA pour vous fournir un feedback détaillé. Le contenu n'est pas partagé avec des tiers, n'est pas utilisé pour entraîner nos modèles, et reste accessible uniquement depuis votre compte."
    : "Votre rédaction est confidentielle et sera analysée par notre IA pour vous fournir un feedback détaillé. Le contenu n'est pas partagé avec des tiers, n'est pas utilisé pour entraîner nos modèles, et reste accessible uniquement depuis votre compte.";
