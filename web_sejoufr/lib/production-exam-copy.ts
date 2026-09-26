/**
 * **La copie de l'examen blanc EE/EO** — la feuille d'information qui précède le
 * démarrage, l'en-tête du runner et sa feuille « ⓘ ». Déclarée une fois pour
 * tout le web.
 *
 * ⚠️ **Miroir mot pour mot du mobile** :
 * `mobile_sejourfr/lib/screens/tcf_production/production_exam_copy.dart`. Une
 * phrase qui bouge, ce sont les deux fichiers à changer dans la même passe.
 *
 * 🛑 **Aucune durée ni aucune borne de mots n'est écrite ici.** La durée de
 * l'épreuve arrive en paramètre (table `lib/exam-durations.ts`, miroir de
 * `DureeEpreuve`) ; les bornes de mots et les temps de parole sont lus sur les
 * sujets **servis** (`production_tasks.mots_min/mots_max/duree_max_sec`), via
 * `productionTaskConstraint`. Seuls les mots éditoriaux vivent ici.
 *
 * Registre : **vouvoiement**, comme tout le parcours TCF hors module
 * « Compétences ».
 */
import {
    formatDurationSec,
    productionTaskConstraint,
    type ProductionTaskDto,
} from "./types";

type ProductionEpreuve = "TCF_EE" | "TCF_EO";

/* ------------------------------------------------ feuille d'information */

export const PRODUCTION_EXAM_BRIEFING_DEROULE = "Déroulé";
export const PRODUCTION_EXAM_BRIEFING_CONSEIL = "Conseil";
export const PRODUCTION_EXAM_BRIEFING_START = "Commencer maintenant";
export const PRODUCTION_EXAM_BRIEFING_STARTING = "Démarrage…";
export const PRODUCTION_EXAM_BRIEFING_CANCEL = "Annuler";

/** « EXAMEN COMPLET EXPRESSION ÉCRITE » (mis en capitales par l'appelant). */
export function productionExamBriefingEyebrow(epreuveLabel: string): string {
    return `Examen complet ${epreuveLabel}`;
}

export function productionExamBriefingTitle(epreuve: ProductionEpreuve): string {
    return epreuve === "TCF_EO" ? "Prêt à parler ?" : "Prêt à écrire ?";
}

/**
 * Le paragraphe de la carte bleue.
 *
 * @param durationLabel durée d'épreuve annoncée (« 30 min »), lue dans la table
 *                      de référence — ignorée à l'oral, qui n'a pas de chrono
 *                      d'épreuve.
 */
export function productionExamBriefingIntro(
    epreuve: ProductionEpreuve,
    durationLabel: string,
): string {
    return epreuve === "TCF_EO"
        ? "Vous enchaînez 3 tâches orales, comme au vrai TCF. Vous lisez chaque consigne sans chrono, puis vous lancez la tâche quand vous êtes prêt : le temps de parole ne part qu'à cet instant. Chaque réponse est enregistrée puis notée par l'IA."
        : `Vous enchaînez 3 tâches écrites d'affilée, comme au vrai TCF. Le chrono de ${durationLabel} couvre les 3 tâches ensemble : à vous de répartir votre temps. Chaque réponse est corrigée par l'IA en fin de session.`;
}

export function productionExamBriefingConseil(epreuve: ProductionEpreuve): string {
    return epreuve === "TCF_EO"
        ? "Exprimez vos idées clairement et utilisez des connecteurs (d'abord, ensuite, donc). L'IA corrige les mots transcrits : elle n'évalue ni la prononciation ni la fluidité."
        : "Lisez bien la consigne, structurez votre réponse (introduction, développement, conclusion) et respectez le nombre de mots indiqué.";
}

/** Ce que demande chaque tâche, en quelques mots (éditorial). */
const TASK_DETAIL: Record<ProductionEpreuve, Record<number, string>> = {
    TCF_EE: {
        1: "Email, invitation, annulation",
        2: "Expérience personnelle",
        3: "Argumentation simple",
    },
    TCF_EO: {
        1: "Parler de soi, travail, loisirs",
        2: "Poser des questions et interagir",
        3: "Donner son avis et argumenter",
    },
};

/**
 * La contrainte **servie** d'une tâche de l'examen (« 30-60 mots », « 3 min »),
 * lue sur les sujets du catalogue de l'épreuve.
 *
 * 🛑 `null` = inconnu : catalogue pas encore chargé, ou sujets d'une même tâche
 * qui ne s'accordent pas. On ne l'invente jamais et on ne choisit pas entre deux
 * valeurs — la ligne s'affiche alors sans contrainte.
 */
export function productionExamTaskConstraint(
    tasks: readonly ProductionTaskDto[] | null | undefined,
    epreuve: ProductionEpreuve,
    tacheNumero: number,
): string | null {
    if (!tasks) return null;
    const oral = epreuve === "TCF_EO";
    const values = new Set(
        tasks
            .filter((t) => t.tacheNumero === tacheNumero)
            .map((t) => productionTaskConstraint(t, oral)),
    );
    if (values.size !== 1) return null;
    const [only] = values;
    return only ?? null;
}

/** « Email, invitation, annulation · 30-60 mots » — la contrainte seulement si
 *  elle est connue. */
export function productionExamTaskDetail(
    epreuve: ProductionEpreuve,
    tacheNumero: number,
    constraint: string | null,
): string {
    const detail = TASK_DETAIL[epreuve][tacheNumero] ?? "";
    return [detail, constraint].filter(Boolean).join(" · ");
}

/* --------------------------------------------------------------- runner */

/** « Tâche 1 sur 3 ». */
export function productionExamStepLabel(tacheNumero: number, total: number): string {
    return `Tâche ${tacheNumero} sur ${total}`;
}

/**
 * La contrainte de la tâche, **dite une seule fois** sur la carte de consigne :
 * « Longueur attendue : 30 à 60 mots » à l'écrit, « Temps de parole : 3 min » à
 * l'oral. Lue sur le sujet servi ; `null` quand il ne la porte pas.
 */
export function productionExamConstraintLine(
    task: Pick<ProductionTaskDto, "motsMin" | "motsMax" | "dureeMaxSec">,
    epreuve: ProductionEpreuve,
): string | null {
    if (epreuve === "TCF_EO") {
        return task.dureeMaxSec ? `Temps de parole : ${formatDurationSec(task.dureeMaxSec)}` : null;
    }
    if (task.motsMin == null || task.motsMax == null) return null;
    return `Longueur attendue : ${task.motsMin} à ${task.motsMax} mots`;
}

/** Le repère de rythme sous la consigne écrite. `advisedLabel` vient de
 *  `eeAdvisedMinutesLabel` (« ≈ 7 min conseillées »). */
export function productionExamAdvisedTimeLine(advisedLabel: string): string {
    return `${advisedLabel} sur cette tâche — un repère, pas une limite : le chrono affiché couvre les 3 tâches.`;
}

/* ------------------------------------ oral : revue d'un enregistrement */

/*
 * La tâche orale d'un examen blanc se déroule en quatre temps : consigne (sans
 * chrono) → enregistrement (décompte de la tâche) → **revue** → envoi. La revue
 * existe parce que l'arrêt n'envoyait rien de visible : l'écran se figeait le
 * temps de la transcription, puis la tâche suivante tombait d'un coup.
 *
 * 🛑 La réécoute lit l'enregistrement **resté sur l'appareil** : rien n'est
 * envoyé pour la permettre, rien n'est conservé après l'envoi
 * (`docs/regles/audio-productions.md`).
 */

export const PRODUCTION_EXAM_REVIEW_TITLE = "Enregistrement terminé";

/** Sous le titre de la revue. `timeUp` : l'arrêt est venu du décompte. */
export function productionExamReviewHint(timeUp: boolean): string {
    const lead = timeUp
        ? "Le temps de parole est écoulé, l'enregistrement s'est arrêté. "
        : "";
    return `${lead}Réécoutez votre réponse, recommencez-la si besoin, puis envoyez-la.`;
}

export const PRODUCTION_EXAM_REDO = "Recommencer";

/** Ce que coûte « Recommencer », dit avant le geste. */
export const PRODUCTION_EXAM_REDO_NOTE =
    "Recommencer efface cet enregistrement ; le temps de parole de la tâche repart en entier.";

/** Le bouton principal de la revue, qui envoie la réponse. */
export function productionExamNextLabel(isLast: boolean, inFullExam: boolean): string {
    if (!isLast) return "Tâche suivante";
    return inFullExam ? "Terminer l'épreuve" : "Terminer l'examen";
}

export const PRODUCTION_EXAM_SENDING = "Envoi de votre réponse…";

export const PRODUCTION_EXAM_SEND_ERROR =
    "L'envoi n'a pas abouti. Votre enregistrement est toujours sur cet appareil : réessayez.";

export const PRODUCTION_EXAM_RETRY = "Réessayer";

/* --------------------------------------------- attente de l'évaluation */

/*
 * L'écran d'attente de l'analyse IA (cocarde, « Analyse en cours », étapes).
 * Mêmes mots que le mobile (`EvaluationLoadingView`). Les étapes avancent au
 * rythme indicatif ci-dessous, pas au rythme réel du serveur : elles disent ce
 * qui se passe, elles ne le mesurent pas.
 */

export const EVALUATION_LOADING_TITLE = "Analyse en cours";
export const EVALUATION_LOADING_LEAD = "Votre évaluation arrive juste après.";
export const EVALUATION_LOADING_LAST = "Encore quelques secondes…";

export type EvaluationLoadingStepKey = "upload" | "transcription" | "analysis" | "report";

/** Les étapes et leur durée indicative (secondes), transcription à l'oral. */
export function evaluationLoadingSteps(
    includeTranscription: boolean,
): readonly {key: EvaluationLoadingStepKey; label: string; seconds: number}[] {
    return [
        {key: "upload", label: "Envoi de votre production", seconds: 2},
        ...(includeTranscription
            ? [{key: "transcription" as const, label: "Transcription audio", seconds: 6}]
            : []),
        {key: "analysis", label: "Analyse pédagogique", seconds: 6},
        {key: "report", label: "Préparation de votre bilan", seconds: 4},
    ];
}

/* ------------------------------------------------------ feuille « ⓘ » */

export const PRODUCTION_INFO_TITLE = "Comment votre production est évaluée";
export const PRODUCTION_INFO_CRITERIA_LABEL = "Vous serez évalué sur";
export const PRODUCTION_INFO_CLOSE = "J'ai compris";
export const PRODUCTION_INFO_PRIVACY_LABEL = "Confidentialité";

/**
 * Les QUATRE critères de **notre grille SejourFR**, à poids égaux, identiques
 * sur les six tâches — miroir strict de la grille serveur
 * (`prompts/production-rubrics-*.json`, `docs/notation-ia-eo-ee.md`).
 *
 * ⚠️ Ne pas les présenter comme « les critères du TCF » : France Éducation
 * international publie les siens en trois familles et fait corriger par des
 * évaluateurs humains. Côté oral, ni l'aisance ni la prononciation n'y
 * figurent : l'évaluation part de la transcription.
 */
export const PRODUCTION_CRITERIA: readonly {label: string; hint: string}[] = [
    {label: "Communiquer", hint: "accomplir ce que demande la consigne et enchaîner ses idées"},
    {label: "Interagir", hint: "s'adapter à la situation et à la personne à qui l'on s'adresse"},
    {label: "Lexique", hint: "un vocabulaire approprié et précis"},
    {label: "Morphosyntaxe", hint: "la correction grammaticale"},
];

export const PRODUCTION_CRITERIA_FOOT =
    "Les quatre critères de notre grille, qui comptent autant l'un que l'autre. Ils couvrent les dimensions évaluées au TCF — linguistique, pragmatique, sociolinguistique — sans reprendre la grille de correction officielle. Ce sont les attentes derrière chacun qui montent d'une tâche à la suivante.";

/** La confidentialité de la production. À l'oral, le sort de l'enregistrement
 *  est déjà dit sous l'enregistreur (`EoTranscriptNotice`) : on n'en parle ici
 *  que pour le texte transcrit. */
export function productionPrivacyText(epreuve: ProductionEpreuve): string {
    return epreuve === "TCF_EO"
        ? "Votre réponse est transcrite puis analysée par notre IA pour vous fournir un feedback détaillé. Le contenu n'est pas partagé avec des tiers, n'est pas utilisé pour entraîner nos modèles, et reste accessible uniquement depuis votre compte."
        : "Votre rédaction est confidentielle et sera analysée par notre IA pour vous fournir un feedback détaillé. Le contenu n'est pas partagé avec des tiers, n'est pas utilisé pour entraîner nos modèles, et reste accessible uniquement depuis votre compte.";
}
