// Types miroirs des DTOs renvoyés par le backend Spring Boot.
// Garde-les synchronisés avec les records côté Java.

// ============ ENUMS ============
export type Module = "CIVIQUE" | "TCF";
export type TargetProcedure = "CSP" | "CR" | "NAT";
export type TargetLevel = "A2" | "B1" | "B2";
// Le back code la difficulté sous forme de niveau de cible (civique = CSP/CR/NAT, TCF = A2/B1/B2)
// et pas via une echelle facile/moyen/difficile. La valeur affichee en tag vient directement de la.
export type Difficulty = "CSP" | "CR" | "NAT" | "A2" | "B1" | "B2";
// Aligne sur com.sejourfr.app.enums.QuestionType.
export type QuestionType =
    | "CONNAISSANCE"
    | "MISE_SITUATION"
    | "CO"
    | "CO_IMAGE"
    | "CE"
    | "STRUCTURE";
export type AttemptType = "TRAINING" | "MOCK_EXAM" | "REVIEW";
/**
 * Granularite fine d'un attempt. CIVIQUE = examen civique. TCF_CO/CE/STRUCTURE
 * = QCM TCF. TCF_EO/TCF_EE/TCF_COMPLET = productions evaluees par IA — pas
 * disponibles cote web pour l'instant (mobile uniquement).
 */
export type EpreuveType =
    | "CIVIQUE"
    | "TCF_CO"
    | "TCF_CE"
    | "TCF_STRUCTURE"
    | "TCF_EO"
    | "TCF_EE"
    | "TCF_COMPLET";
export type MediaType = "AUDIO" | "IMAGE" | "VIDEO";
export type Role = "USER" | "ADMIN";
/**
 * Libelle francais d'un type de question, miroir du `displayLabel` cote mobile
 * (`mobile_sejourfr/lib/core/models/enums.dart`).
 */
export function questionTypeLabel(type: QuestionType): string {
    switch (type) {
        case "CONNAISSANCE":
            return "Connaissance";
        case "MISE_SITUATION":
            return "Mise en situation";
        case "CO":
        case "CO_IMAGE":
            return "Compréhension orale";
        case "CE":
            return "Compréhension écrite";
        case "STRUCTURE":
            return "Structure de la langue";
    }
}

// ============ AUTH ============
export type AuthProvider = "LOCAL" | "GOOGLE" | "APPLE";

export interface LoginRequest {
    email: string;
    password: string;
}

export interface RegisterRequest {
    email: string;
    password: string;
    firstName: string;
    lastName: string;
    targetProcedure?: TargetProcedure | null;
    /** Palier VISÉ, **dérivé serveur** : `max(exigé par la démarche, niveau
     *  déclaré)`. Le backend applique déjà le plancher (`TargetProcedure.niveauVise`),
     *  donc ce champ ne contredit jamais `targetProcedure`. */
    targetLevel?: TargetLevel | null;
}

/**
 * Payload envoye a POST /api/auth/google. Le `idToken` est obtenu via
 * Google Identity Services dans le navigateur (credential.credential).
 */
export interface GoogleSignInRequest {
    idToken: string;
}

export interface TokenResponse {
    accessToken: string;
    refreshToken: string;
    expiresInSeconds: number;
    tokenType: "Bearer";
}

export interface AuthenticatedUser {
    id: string;
    email: string;
    firstName: string;
    lastName: string;
    role: Role;
    targetProcedure?: TargetProcedure | null;
    /** Palier VISÉ, **dérivé serveur** : `max(exigé par la démarche, niveau
     *  déclaré)`. Le backend applique déjà le plancher (`TargetProcedure.niveauVise`),
     *  donc ce champ ne contredit jamais `targetProcedure`. */
    targetLevel?: TargetLevel | null;
    /** Jour de l'examen déclaré par le candidat, `YYYY-MM-DD`. `null` = pas de
     *  date, réponse pleine et la plus fréquente. On l'AFFICHE, on n'en dérive
     *  rien : le décompte en jours est servi par le serveur. */
    examDate?: string | null;
    /** Vrai si l'utilisateur a au moins un plan payant actif (CIVIQUE ou INTÉGRAL). */
    isPremium?: boolean;
    /** Accès au module Civique (vrai si un Plan donnant accès Civique ou Intégral est actif). */
    hasCivique?: boolean;
    /** Accès au module TCF (vrai si un Plan donnant accès Intégral est actif). */
    hasTcf?: boolean;
    /** Date d'expiration de l'accès payant (ISO 8601), null si pas de plan actif. */
    premiumEndsAt?: string | null;
    /** Moyen par lequel le compte a ete cree (mot de passe local vs social). */
    authProvider?: AuthProvider;
}

// ============ THEME ============
export interface ThemeUserResponse {
    id: string;
    module: Module;
    code: string;
    name: string;
    displayOrder: number;
    questionCount?: number;
}

// ============ MEDIA ============
export interface MediaResponse {
    id: string;
    type: MediaType;
    url?: string;
    durationSeconds?: number;
    transcript?: string;
    /**
     * Quand renseigné, le front rend ce SVG inline plutôt que de charger
     * url (utilisé pour les captures TCF compréhension écrite). Le SVG est
     * fourni par le backend (seed Flyway), donc considéré comme de confiance.
     */
    inlineSvg?: string | null;
}

// ============ QUESTION (vue user) ============
export interface ChoicePublicResponse {
    id: string;
    label: string;
    displayOrder: number;
    correct: boolean | null; // null tant que l'attempt n'est pas terminé
}

export interface QuestionPublicResponse {
    id: string;
    module: Module;
    themeId: string;
    themeName: string;
    difficulty: Difficulty;
    questionType: QuestionType;
    statement: string;
    /** Renvoyé uniquement quand l'attempt parent est finalisé (rapport post-examen). */
    explanation?: string | null;
    passageText?: string;
    media?: MediaResponse;
    /**
     * Audio joué sous l'image pour les questions CO_IMAGE (intro + 4 propositions
     * lues). Renseigné uniquement pour `questionType === "CO_IMAGE"` : `media`
     * porte alors l'image, `audioMedia` l'audio.
     */
    audioMedia?: MediaResponse;
    choices: ChoicePublicResponse[];
}

// ============ QUESTION (vue review : explication + correct résolu) ============
// Renvoyé par GET /api/me/questions/favorites, /api/me/questions/wrong,
// /api/me/questions/{id}/review. Le user a déjà tenté ou favori la question.
export interface ChoiceFullResponse {
    id: string;
    label: string;
    displayOrder: number;
    correct: boolean;
}

export interface QuestionReviewResponse {
    id: string;
    module: Module;
    themeId: string;
    themeName: string;
    difficulty: Difficulty;
    questionType: QuestionType;
    statement: string;
    passageText?: string;
    media?: MediaResponse;
    audioMedia?: MediaResponse;
    explanation?: string | null;
    choices: ChoiceFullResponse[];
}

// ============ EXAM TEMPLATE (vitrine publique) ============
export interface ExamTemplateSummary {
    id: string;
    slug: string;
    module: Module;
    targetProcedure: TargetProcedure | null;
    targetLevel: TargetLevel | null;
    name: string;
    subtitle: string | null;
    description: string | null;
    durationSeconds: number;
    totalQuestions: number;
    passingScore: number;
    free: boolean;
    position: number;
}

// ============ ATTEMPT ============
export interface StartAttemptRequest {
    type: AttemptType;
    module: Module;
    examTemplateId?: string;
    themeId?: string;
    difficulty?: Difficulty;
    questionType?: QuestionType;
    size?: number;
    /** TRAINING sur un lot précis (découpage déterministe). size est ignoré. */
    lotNumero?: number;
    /** MOCK_EXAM scopé à une épreuve TCF QCM (CO/CE/STRUCTURE). */
    moduleExamQuestionType?: QuestionType;
    /** Slot d'examen blanc visé dans la grille (1..N). MOCK_EXAM seulement :
     *  refaire « l'examen N » réutilise le même slotNumber, l'UI prend le plus
     *  récent par slot au lieu de créer un slot N+1 (cf. migration V110). */
    slotNumber?: number;
    /**
     * **Série ciblée** sur une compétence de COMPRÉHENSION (CO / CE), avec
     * `type: "TRAINING"` et `module: "TCF"`. Fournie, elle **l'emporte sur tous
     * les autres filtres** : épreuve, palier et taille se dérivent du
     * référentiel côté serveur.
     *
     * 🛑 **N'envoyer que le `skillId`.** Un couple (`questionType`,
     * `difficulty`) venu du client aurait pu contredire la compétence affichée
     * et faire progresser une autre compétence que celle travaillée.
     *
     * Erreurs : **403** compétence verrouillée · **422** compétence
     * d'expression (elle s'entraîne sur ses petits sujets) · **404** inconnue.
     */
    skillId?: string;
}

/** Lot = chunk déterministe de questions (cf. backend LotService / LotDto). */
export interface LotDto {
    numero: number;
    difficulty?: string | null;
    totalQuestions: number;
    /** Dernier score sur ce lot (null si jamais fait). */
    lastScore?: number | null;
    lastAttemptedAt?: string | null;
    /** Id du dernier attempt fini sur ce lot (null si jamais fait) — sert à
     *  ouvrir le bilan sans relancer. */
    lastAttemptId?: string | null;
}

export interface AttemptQuestionResponse {
    id: string;
    position: number;
    question: QuestionPublicResponse;
    answered: boolean;
    selectedChoiceIds: string[];
    correct: boolean | null;
}

export interface AttemptResponse {
    id: string;
    type: AttemptType;
    module: Module;
    examTemplateId: string | null;
    examTemplateSlug: string | null;
    examTemplateName: string | null;
    totalQuestions: number;
    /** Chrono de l'épreuve, en secondes. **Absent sur une session d'examen
     *  EO** : l'oral se chronomètre par tâche, au lancement de chaque tâche —
     *  l'épreuve elle-même n'a pas d'échéance. */
    timeLimitSeconds?: number;
    passThreshold?: number;
    startedAt: string;
    finishedAt?: string;
    score?: number;
    levelAchieved: TargetLevel | null;
    /** Non-null pour un examen module TCF (CO/CE/STRUCTURE). */
    moduleExamQuestionType?: QuestionType | null;
    /** Thème civique scopé (séries + examens thématiques) — sert au retour
     *  de session vers l'écran d'origine. */
    themeId?: string | null;
    /** Score calibré 100-499 + niveau CECRL estimé (examens module TCF). */
    calibratedScore?: number | null;
    cecrlLevel?: NiveauCecrl | null;
    /** Détail par épreuve d'un examen TCF stratifié fini — `cecrlLevel` est le
     *  plancher de ces niveaux (règle TCF IRN : il faut le niveau partout). */
    epreuveResults?: AttemptEpreuveResult[];
    questions: AttemptQuestionResponse[];
}

/** Résultat d'une épreuve au sein d'un examen TCF (CO_IMAGE regroupée sous CO). */
export interface AttemptEpreuveResult {
    epreuve: QuestionType;
    correct: number;
    total: number;
    calibratedScore: number;
    cecrlLevel: NiveauCecrl;
}

export interface SubmitAnswerRequest {
    attemptQuestionId: string;
    choiceIds: string[];
}

export interface AnswerResultResponse {
    recorded: boolean;
    correct: boolean | null;
    correctChoiceIds: string[] | null;
    explanation: string | null;
}

// ============ PLAN (vitrine publique) ============
export type BillingCycle = "NONE" | "MONTHLY" | "YEARLY" | "THREE_MONTHS" | "SIX_MONTHS";
/** Miroir strict de l'enum Java `ModuleAccess` : NONE < CIVIQUE < INTEGRAL.
 *  ⚠️ Pas de valeur "TCF" — le serveur ne l'a jamais eue, et la garder ici
 *  laissait croire qu'un plan pouvait vendre le TCF sans le civique. */
export type ModuleAccess = "NONE" | "CIVIQUE" | "INTEGRAL";

/** Nature commerciale d'un plan (lot 5). ONE_TIME = pass à durée fixe sans
 *  reconduction ; SUBSCRIPTION = abonnement récurrent (dormant). */
export type PlanPurchaseType = "SUBSCRIPTION" | "ONE_TIME";

export interface PlanPublicResponse {
    code: string;
    name: string;
    billingCycle: BillingCycle;
    /** Prix actuel (peut être prix de lancement). */
    price: number;
    /** Prix "normal" affiché barré (offre de lancement). Null si pas de réduction. */
    originalPrice: number | null;
    moduleAccess: ModuleAccess;
    /** Durée d'accès en jours. Source de vérité de la durée en mode ONE_TIME. */
    durationDays: number;
    /** Simulations orales en temps réel (examinateur vocal IA) ouvertes par ce
     *  pass. 0 = non éligible (Civique, Free) — à afficher comme tel, c'est une
     *  différence d'offre assumée entre Civique et Intégral. */
    realtimeEoSessions: number;
    /** ONE_TIME (pass) ou SUBSCRIPTION (abonnement). Le front rend une grille de
     *  passes pour ONE_TIME, le toggle de périodicité pour SUBSCRIPTION. */
    purchaseType: PlanPurchaseType;
    /** Product IDs store (SKU IAP) consommés par le mobile pour StoreKit / Play
     *  Billing. Inutilisés côté web (paiement Stripe). Null si non configurés. */
    appleProductId: string | null;
    googleProductId: string | null;
}

/**
 * Ce que le pass ouvre en **simulations orales en direct** (examinateur vocal),
 * la seule ressource dont le volume change d'un pass Intégral à l'autre : tout
 * le reste (catalogue, examens blancs, corrections IA) est identique, seule la
 * durée et ce quota progressent. Sans cette ligne, un candidat ne voyait aucune
 * différence entre deux passes à part le prix.
 *
 * `null` = rien à annoncer sur cette ligne (Civique, plan gratuit) — l'appelant
 * décide s'il affiche autre chose à la place.
 *
 * ⚠️ On ne dit **jamais** « sans simulation orale » pour un pass Intégral : un
 * backend antérieur à `realtimeEoSessions` renvoie le champ absent (donc falsy),
 * et l'affirmation serait fausse sur l'argument principal du produit.
 *
 * Miroir mot pour mot de `realtimeSessionsLabel` côté mobile
 * (`core/models/billing_models.dart`).
 */
export function realtimeSessionsLabel(plan: {
    realtimeEoSessions?: number | null;
    moduleAccess: ModuleAccess;
}): string | null {
    const sessions = plan.realtimeEoSessions;
    if (typeof sessions === "number" && sessions > 0) {
        return sessions === 1
            ? "1 simulation orale en direct"
            : `${sessions} simulations orales en direct`;
    }
    if (plan.moduleAccess === "INTEGRAL") return "Simulations orales en direct incluses";
    return null;
}

// ============ ATTEMPT SUMMARY (historique) ============
// Renvoyé par GET /api/me/attempts — version légère sans les questions.
export interface AttemptSummaryResponse {
    id: string;
    type: AttemptType;
    module: Module;
    /** Granularite fine. Distingue les attempts QCM (CIVIQUE, TCF_CO/CE/STRUCTURE)
     *  des productions EO/EE (TCF_EO/TCF_EE/TCF_COMPLET) qui n'ont ni
     *  totalQuestions ni score. */
    epreuve?: EpreuveType | null;
    /** Cohérence avec le backend Java : `difficulty` est utilisé indifféremment
     *  pour les niveaux TCF (A2/B1/B2) et les parcours civiques (CSP/CR/NAT). */
    difficulty?: Difficulty | TargetLevel | TargetProcedure | null;
    /** Null pour les attempts de production EO/EE (pas de QCM). */
    totalQuestions: number | null;
    passThreshold?: number | null;
    startedAt: string;
    finishedAt?: string | null;
    score?: number | null;
    /** Score calibré 100-499 d'un examen TCF stratifié (module ou template). */
    calibratedScore?: number | null;
    /** Niveau CECRL estimé sur un examen module TCF (null sinon). */
    cecrlLevel?: NiveauCecrl | null;
    /** Non-null pour un examen module TCF scopé à une épreuve (CO/CE/STRUCTURE). */
    moduleExamQuestionType?: QuestionType | null;
    /** Thème civique ciblé (lot ou examen thématique) — null pour un examen
     *  blanc complet 40 Q tous thèmes. */
    lotThemeId?: string | null;
    /** Template d'examen lié à cet attempt (null si entraînement libre).
     *  Sert à marquer "Fait" sur la liste des examens et à proposer "Voir détails / Refaire". */
    examTemplateId?: string | null;
    examTemplateSlug?: string | null;
    examTemplateName?: string | null;
    /** Slot dans la grille d'examens blancs (1..N). Non-null pour les MOCK_EXAM
     *  standalone : l'UI groupe par slot et garde le plus récent. Cf. V110. */
    slotNumber?: number | null;
}

/** True si l'attempt correspond a une production EO/EE. */
export function isProductionAttempt(a: { epreuve?: EpreuveType | null }): boolean {
    return (
        a.epreuve === "TCF_EO" ||
        a.epreuve === "TCF_EE" ||
        a.epreuve === "TCF_COMPLET"
    );
}

// ============================================================================
// PRODUCTION ÉCRITE / ORALE (TCF_EE / TCF_EO) — évaluation IA
// Miroirs de ProductionTaskDto / ProductionSubmissionDto / EvaluationResultDto /
// ProductionExampleDto côté Java + des enums SubmissionStatut / NiveauCecrl.
// ============================================================================

/** Cycle de vie d'une soumission (cf. enums.SubmissionStatut). EE saute
 *  TRANSCRIBING (pas de Whisper). En MVP synchrone on observe surtout
 *  SUBMITTED → EVALUATED (ou FAILED). */
export type SubmissionStatut =
    | "SUBMITTED"
    | "TRANSCRIBING"
    | "EVALUATING"
    | "EVALUATED"
    | "FAILED";

/** Niveau CECRL d'une éval IA. Le contrat TCF IRN actif s'arrête à B2 ;
 *  C1/C2 restent décodables uniquement pour les évaluations historiques. */
export type NiveauCecrl =
    | "A1_NON_ATTEINT"
    | "A1"
    | "A2"
    | "B1"
    | "B2"
    | "C1"
    | "C2";

/**
 * Où se situe une production **à l'intérieur de son propre palier**, en trois
 * crans (dérivé serveur, cf. l'enum Java `SituationDansNiveau`).
 *
 * C'est ce qui remplace, sur le résultat d'une TÂCHE, la note /20 qui n'y est
 * plus affichée : sans lui, un A2 à 2 et un A2 à 5 voyaient exactement le même
 * écran, et le candidat n'avait plus aucun signal de progression entre deux
 * tentatives.
 *
 * Null sur les évaluations antérieures, sur `A1_NON_ATTEINT` (bande d'une seule
 * valeur) et sur C1/C2 (hors profil TCF IRN).
 */
export type SituationDansNiveau = "ENTREE_DE_PALIER" | "PALIER_CONFIRME" | "PALIER_SOLIDE";

/** POST /api/attempts/production — crée un attempt vide pour EO/EE. */
export interface ProductionAttemptStartRequest {
    module: Module;
    epreuve: EpreuveType;
    parentAttemptId?: string | null;
    /**
     * True pour une session d'examen blanc production (3 tâches). Marque
     * l'attempt côté backend : ses soumissions bypassent le quota
     * d'entraînement, et les sessions d'examen comptent dans le budget
     * gratuit (1 examen offert, le 2ᵉ consomme les essais EE/EO restants).
     */
    exam?: boolean;
    /**
     * Slot UI (1..10) de l'examen blanc. La composition des 3 tâches est
     * déterministe par slot (1-3 = A2 facile, 4-6 = B1 moyen, 7-10 = B2
     * difficile). Refaire l'examen N réutilise le slot N (la grille prend le
     * plus récent). Ignoré hors examen (`exam=false`).
     */
    slotNumber?: number;
}

/** Tâche EE/EO. La grille d'évaluation n'est volontairement pas exposée. */
export interface ProductionTaskDto {
    id: string;
    epreuve: EpreuveType;
    tacheNumero: number;
    niveauCible: string; // "A2" | "B1" | "B2"
    /** Intitulé éditorial du sujet (V028). `null` = pas de titre → repli
     *  `productionSubjectTitle`. Aucun écran ne suppose qu'il est présent. */
    titre: string | null;
    consigne: string;
    contexte: string | null;
    dureeMaxSec: number | null; // EO uniquement
    dureeMinSec: number | null; // EO uniquement
    motsMin: number | null; // EE
    motsMax: number | null; // EE
}

/** Réponse-modèle d'une tâche (onglet « Exemples »). audioUrl = EO seulement. */
export interface ProductionExampleDto {
    id: string;
    titre: string;
    resume: string | null;
    contenu: string;
    explications: string | null;
    audioUrl: string | null;
    planPoints: string[];
    niveauIndicatif: string | null;
}

/** Degré de certitude d'une évaluation IA (schéma de sortie v2, notation v4).
 *  Null sur les évaluations antérieures — l'absence n'est pas une erreur. */
export type ConfianceEvaluation = "HAUTE" | "MOYENNE" | "FAIBLE";

/** Bande qualitative d'un critère, dérivée côté serveur de sa note /20. Les
 *  fronts affichent la BANDE et non le nombre : une IA ne distingue pas
 *  honnêtement un 13 d'un 14. La note globale /20, elle, reste affichée. */
export type BandeCritere =
    | "TRES_BONNE_MAITRISE"
    | "SATISFAISANT"
    | "EN_COURS_ACQUISITION"
    | "FRAGILE"
    | "NON_EVALUABLE";

/**
 * La production rendue a-t-elle pu être **observée** ? Miroir de
 * `ProductionEvaluabilite` (backend), **jamais `null`** : toutes les
 * évaluations antérieures sortent `EVALUABLE`, rien n'a été migré.
 *
 * ⚠️ **Trois états, pas deux**, et c'est tout le sens du champ :
 * - `evaluation` **absente** ⇒ « pas encore évaluée » ;
 * - présente + `NON_EVALUABLE` ⇒ « rendue, mais il n'y avait rien à
 *   observer » : ni note, ni niveau, ni `scores_criteres` — le correcteur n'a
 *   même pas été appelé (production vide, langue non française, recopiage de
 *   la consigne). *null = inconnu, jamais mauvais* ;
 * - présente + `EVALUABLE` ⇒ le rapport normal.
 *
 * Le serveur n'expose ici qu'un **fait** : la phrase appartient aux fronts
 * (cf. `ProductionFeedbackView`).
 *
 * ⚠️ À ne pas confondre avec la valeur `"NON_EVALUABLE"` de
 * {@link BandeCritere}, qui qualifie **un critère** d'une évaluation, pas la
 * production entière.
 */
export type ProductionEvaluabilite = "EVALUABLE" | "NON_EVALUABLE";

/** Résultat IA. `feedback` est le JSONB brut (clés snake_case) — utiliser
 *  {@link parseEeFeedback} pour le normaliser avant affichage.
 *
 *  `niveauObserve` est la performance observée SUR CETTE TÂCHE : c'est tout ce
 *  qu'un écran affiche d'une tâche isolée (au TCF, une tâche reçoit un niveau,
 *  jamais une note), le niveau qui fait foi restant celui du bilan d'épreuve
 *  (cf. {@link ProductionBilanResponse}). Garde-fou produit : il n'est JAMAIS
 *  affiché sans `confiance` à côté — le backend ne le renseigne d'ailleurs pas
 *  quand la confiance est inconnue.
 *
 *  Les évaluations d'avant la notation v4 laissent `niveauObserve`,
 *  `confiance` et `avertissementNiveau` à null (et leur `feedback` n'a ni
 *  `bande`, ni `accomplissement`, ni `preuve`) : cas normal, pas une erreur. */
export interface EvaluationResultDto {
    /** **Jamais `null`** côté serveur. Un backend antérieur au champ ne le sert
     *  pas du tout : on ne traite donc comme inexploitable que la valeur
     *  `NON_EVALUABLE` **explicite** — jamais son absence, qui reste un
     *  rapport normal. */
    evaluabilite: ProductionEvaluabilite;
    noteSurVingt: number | null;
    niveauObserve: NiveauCecrl | null;
    confiance: ConfianceEvaluation | null;
    avertissementNiveau: string | null;
    /** Position dans la bande du niveau annoncé (3 crans). Null = rien à
     *  situer : évaluation ancienne, `A1_NON_ATTEINT`, ou C1/C2. */
    situationDansNiveau: SituationDansNiveau | null;
    /** Libellé composé prêt à afficher (« A2 solide »). Null exactement quand
     *  `situationDansNiveau` l'est. */
    situationDansNiveauLabel: string | null;
    feedback: Record<string, unknown> | null;
}

/** Fourchette de note officielle du TCF IRN correspondant à un niveau CECRL, sur
 *  les épreuves d'expression. Table officielle (0 → A1 non atteint, 1 → A1,
 *  2-5 → A2, 6-9 → B1, 10-20 → B2). Nos notes sont des ESTIMATIONS exprimées sur
 *  cette MÊME échelle : la fourchette se lit donc directement, sans conversion —
 *  ce qui est officiel ici, c'est l'échelle, pas la correction, qui reste la
 *  nôtre. N'accompagne que le bilan d'une épreuve entière — au TCF, une tâche
 *  isolée n'a pas de note. */
export interface CorrespondanceTcfDto {
    niveau: NiveauCecrl;
    scoreTcfMin: number;
    scoreTcfMax: number;
}

/** Bilan d'une épreuve productive (EE/EO) au niveau attempt. Le `niveauGlobal`
 *  n'est calculé (côté backend, moyenne des 3 tâches à poids égaux) qu'en session
 *  d'examen blanc (`exam=true`) et seulement quand les 3 tâches sont évaluées —
 *  null en entraînement libre ou éval incomplète. */
export interface ProductionBilanResponse {
    attemptId: string;
    epreuve: EpreuveType;
    exam: boolean;
    evaluatedCount: number;
    expectedCount: number;
    moyenneSur20: number | null;
    niveauGlobal: NiveauCecrl | null;
    /** Slot UI (1..10) de l'examen blanc — null pour un entraînement libre ou un
     *  examen d'avant V110. Sert à ranger la session dans la grille (parité mobile). */
    slotNumber: number | null;
    /** True quand l'attempt production est finalisé (`finishedAt` posé). Avec
     *  `niveauGlobal` calculé même si < 3 tâches évaluées (les manquantes = 0). */
    finished: boolean;
    /** Fourchette officielle TCF du `niveauGlobal`. Null exactement quand
     *  `niveauGlobal` l'est. */
    correspondanceTcf: CorrespondanceTcfDto | null;
}

export interface ProductionSubmissionDto {
    id: string;
    attemptId: string;
    productionTaskId: string;
    /** Numéro de tâche (1/2/3) — sert à regrouper par tâche dans les hubs. */
    tacheNumero: number | null;
    statut: SubmissionStatut;
    texteSoumis: string | null; // EE
    motsCount: number | null;
    /**
     * Durée de l'enregistrement (EO). Seule trace qui subsiste de l'audio :
     * il n'est pas conservé, donc aucune URL n'est servie — ce qui reste d'une
     * production orale, c'est `transcription`.
     */
    mediaDurationSec: number | null; // EO
    retryCount: number;
    erreurMessage: string | null;
    submittedAt: string;
    /** Null tant que statut != EVALUATED. */
    evaluation: EvaluationResultDto | null;
    transcription: string | null; // EO
    /**
     * Ce que cette production a changé dans le Plan — **une ligne, pas un
     * rapport**. `null` est un cas NORMAL : rien n'a bougé, ou les observations
     * (écrites après la correction) ne sont pas encore là. Servi seulement sur
     * le détail d'une soumission, jamais sur une liste d'historique.
     */
    planChange: PlanChangeDto | null;
}

/** De quoi nommer une compétence et y renvoyer, sans embarquer tout son état. */
export interface PlanSkillRefDto {
    skillId: string;
    skillCode: string;
    title: string;
    section: SkillSection;
}

/** Les deux moitiés sont **indépendamment nullables** : on n'affiche que celle
 *  qui existe, et rien du tout quand le bloc entier est `null`. */
export interface PlanChangeDto {
    confirmedSkill: PlanSkillRefDto | null;
    newPriority: PlanSkillRefDto | null;
}

/** Body JSON de POST /api/production-submissions (EE). */
export interface SubmitProductionTextRequest {
    productionTaskId: string;
    attemptId: string;
    texte: string;
    /** Clé d'idempotence tirée par le client (UUID v4). Renvoyer la même clé
     *  rend la MÊME soumission, sans seconde correction IA facturée ni second
     *  décompte de quota. À générer UNE fois par production, pas par requête —
     *  c'est tout l'intérêt sur un renvoi après coupure réseau. */
    clientSubmissionId?: string;
}

// ============================================================================
// DIAGNOSTIC TCF — 4 ÉPREUVES (L4)
// Miroir strict de TcfDiagnostic*Dto côté Java.
//
// 🛑 À NE PAS CONFONDRE avec le diagnostic INITIAL (une production écrite + une
// orale), plus bas dans ce fichier : ce sont deux objets produit distincts, et
// `10_` §4.1 interdit de les confondre — comme il interdit d'appeler celui-ci un
// examen blanc.
// ============================================================================

export type TcfDiagnosticStatus = "IN_PROGRESS" | "COMPLETED";

/** État d'une section, **dérivé serveur**. Le front ne le recalcule jamais. */
export type TcfDiagnosticSectionState = "A_FAIRE" | "EN_COURS" | "TERMINEE";

export interface TcfDiagnosticSectionDto {
    epreuve: EpreuveType;
    /** `null` = section absente du diagnostic (mode dégradé : pas de contenu). */
    attemptId: string | null;
    etat: TcfDiagnosticSectionState;
    /** Chrono de la section. `null` en EO, qui se chronomètre par tâche. */
    timeLimitSeconds: number | null;
    totalQuestions: number | null;
}

/**
 * L'écran d'accueil du diagnostic.
 *
 * 🛑 **Aucun niveau ici, et ce n'est pas un oubli** : `10_` §4.2 interdit tout
 * résultat partiel entre les sections — « le résultat est le moment de
 * conversion, il ne doit pas être dilué ».
 */
export interface TcfDiagnosticDto {
    sessionId: string;
    status: TcfDiagnosticStatus;
    startedAt: string;
    expiresAt: string;
    completedAt: string | null;
    /** Le délai de reprise est passé. **Rien n'est perdu** : les sections faites comptent. */
    repriseEcoulee: boolean;
    sections: TcfDiagnosticSectionDto[];
}

/** Une priorité du diagnostic. Le score de tri n'est **pas** exposé, volontairement. */
export interface TcfDiagnosticPriorityDto {
    rang: number;
    epreuve: EpreuveType;
    /** « EE1 »… « EO3 ». `null` en compréhension : la priorité porte sur l'épreuve. */
    taskCode: string | null;
    niveauTache: NiveauCecrl | null;
    niveauEpreuve: NiveauCecrl | null;
}

/** Le niveau d'une épreuve. `niveau: null` = **non évaluée**, jamais un A1. */
export interface TcfDiagnosticEpreuveNiveau {
    epreuve: EpreuveType;
    niveau: NiveauCecrl | null;
}

/**
 * L'écran de résultat (`10_` §4.5).
 *
 * 🛑 **Aucun `locked`** : le paywall porte sur le plan, jamais sur le constat.
 * 🛑 `niveauGlobal` peut être `null` (aucune épreuve évaluée) et une épreuve
 * peut avoir un `niveau` nul — c'est « non évaluée », et l'écran doit le
 * **nommer** au lieu d'afficher un palier inventé.
 */
export interface TcfDiagnosticResultDto {
    sessionId: string;
    niveauGlobal: NiveauCecrl | null;
    cible: NiveauCecrl | null;
    epreuves: TcfDiagnosticEpreuveNiveau[];
    priorites: TcfDiagnosticPriorityDto[];
    /** Épreuves déjà à la cible — le bloc « Déjà au niveau attendu ». */
    dejaAuNiveau: TcfDiagnosticEpreuveNiveau[];
    completedAt: string | null;
    /**
     * Ce qui a bougé depuis le diagnostic précédent (L7).
     *
     * 🛑 **`null` est le cas NORMAL** : c'est le premier diagnostic, il n'y a
     * rien à comparer. L'écran n'affiche alors aucun bloc de progression — il
     * n'en fabrique pas un vide.
     */
    progression: TcfDiagnosticProgressionDto | null;
    /**
     * Combien de tâches d'expression **mesurées** restent sous la cible.
     *
     * 🛑 **Non plafonné**, contrairement à `priorites` qui l'est à trois par
     * règle produit. C'est lui, et lui seul, qui fait le « N compétences
     * ciblées détectées » de l'écran : le lire sur une liste tronquée
     * afficherait « 3 » quel que soit le nombre réel.
     *
     * 🛑 `0` est un état **normal** — tout est à la cible. Aucune ligne alors.
     */
    tachesSousLaCible: number;
}

// ----------------------------------------------------------------------------
// L7 — LA BOUCLE DE RÉÉVALUATION
// Miroirs stricts de TcfReassessmentEligibilityDto et TcfDiagnosticProgressionDto.
// ----------------------------------------------------------------------------

/**
 * Le sens d'une variation de palier entre deux diagnostics.
 *
 * 🛑 **`INCONNUE` n'est pas `STABLE`.** Une épreuve non évaluée d'un côté ou de
 * l'autre n'a ni progressé ni régressé : elle n'est pas comparable. Afficher
 * « = » dessus laisserait croire qu'un niveau a été tenu alors que personne
 * n'a rien mesuré.
 */
export type NiveauEvolution = "HAUSSE" | "STABLE" | "BAISSE" | "INCONNUE";

/** L'évolution d'une épreuve. `avant` et `apres` sont nuls indépendamment. */
export interface TcfEpreuveEvolution {
    epreuve: EpreuveType;
    avant: NiveauCecrl | null;
    apres: NiveauCecrl | null;
    evolution: NiveauEvolution;
}

/**
 * La comparaison au diagnostic précédent (`10_` §4.6, `30_` §7 bloc 2).
 *
 * 🛑 **Le serveur dit d'où à où ; « Vous avez progressé ! » appartient à
 * l'écran.** Et rien ici ne se recalcule côté front.
 */
export interface TcfDiagnosticProgressionDto {
    previousSessionId: string;
    previousCompletedAt: string | null;
    previousNiveauGlobal: NiveauCecrl | null;
    niveauGlobal: NiveauEvolution;
    epreuves: TcfEpreuveEvolution[];
}

/** Ce qui empêche aujourd'hui de relancer un diagnostic. `null` = rien. */
export type TcfReassessmentBlocker = "PREMIUM_REQUIRED" | "INTERVAL_NOT_ELAPSED";

/**
 * **Peut-il relancer, et sinon pourquoi ?** — l'écran T11 (`30_` §5.6) et la
 * boucle de réévaluation (`10_` §4.6), servis.
 *
 * 🛑 **Le front ne recalcule rien d'ici** : ni les 14 jours, ni les jours
 * restants, ni « c'est le premier ». Le serveur sert ce DTO **et** garde
 * l'ouverture avec le même calcul — un bouton actif que l'API refuse est donc
 * impossible par construction.
 */
export interface TcfReassessmentEligibilityDto {
    canStart: boolean;
    blocker: TcfReassessmentBlocker | null;
    /**
     * Porte **commerciale** : l'écran ouvre le paywall. Strictement
     * `blocker === "PREMIUM_REQUIRED"` — un délai non écoulé n'est pas un
     * cadenas, payer ne l'ouvre pas.
     */
    locked: boolean;
    /** La phrase exacte à afficher. `null` quand rien ne bloque. */
    message: string | null;
    /** Aucun diagnostic à ce jour : c'est l'**initial**, offert. Pas une réévaluation. */
    first: boolean;
    /** Un diagnostic est ouvert : l'action est « Reprendre », pas « Relancer ». */
    inProgress: boolean;
    /** Le délai de la règle, pour pouvoir le **dire** sans le connaître. */
    intervalDays: number;
    availableAt: string | null;
    daysUntilAvailable: number | null;
    /**
     * Une priorité du Plan a été terminée depuis le dernier diagnostic :
     * `10_` §4.6 ouvre alors la réévaluation **sans attendre** le délai.
     */
    triggeredByPlan: boolean;
    lastSessionId: string | null;
    lastCompletedAt: string | null;
    /** 🛑 `null` = **non évalué**, jamais A1. */
    lastNiveauGlobal: NiveauCecrl | null;
}

// ============================================================================
// DIAGNOSTIC TCF + PLAN PERSONNALISÉ
// Miroirs stricts des records Diagnostic* / LearningPlan* côté Java. Le front
// affiche les décisions du serveur : il ne recalcule ni niveau ni priorité.
// ============================================================================

export type DiagnosticJourneyStatus =
    | "NOT_STARTED"
    | "IN_PROGRESS"
    | "ANALYZING"
    | "COMPLETED"
    | "FAILED";

export type DiagnosticStep = "PRESENTATION" | "WRITTEN" | "ORAL" | "ANALYSIS" | "RESULT";

export type DiagnosticTaskCompletion = "COMPLETED" | "PARTIAL" | "NOT_COMPLETED";
export type DiagnosticCommunicationStatus = "EFFECTIVE" | "PARTIAL" | "INEFFECTIVE";
export type LearningPlanState = "NEEDS_DIAGNOSTIC" | "DIAGNOSTIC_IN_PROGRESS" | "ACTIVE";
export type LearningPlanSkillStatus = "NOT_OBSERVED" | "PRIORITY" | "TO_REINFORCE" | "SOLID";

/**
 * D'où vient une observation du Plan.
 *
 * `TCF_CO` / `TCF_CE` sont **servis** depuis que les QCM de compréhension
 * alimentent le Plan : ce sont des comptages **déterministes** de bonnes
 * réponses ventilés par palier de question, jamais un verdict d'IA. Ils ne
 * s'écrivent que vers les six compétences de compréhension.
 *
 * La provenance n'est pas un libellé : c'est elle qui donne son poids à
 * l'observation dans le moteur de maîtrise.
 */
export type LearningPlanSourceType =
    | "DIAGNOSTIC_EE"
    | "DIAGNOSTIC_EO"
    | "PRODUCTION_EE"
    | "PRODUCTION_EO"
    | "MOCK_EXAM_EE"
    | "MOCK_EXAM_EO"
    | "SKILL_TRAINING"
    | "TCF_CO"
    | "TCF_CE";
export type ObservationConfidence = "LOW" | "MEDIUM" | "HIGH";

export interface DiagnosticExerciseDto {
    productionTaskId: string;
    attemptId: string;
    epreuve: Extract<EpreuveType, "TCF_EE" | "TCF_EO">;
    title: string;
    instruction: string;
    helperText: string | null;
    wordsMin: number | null;
    wordsMax: number | null;
    durationMinSeconds: number | null;
    durationMaxSeconds: number | null;
    instructionAudioUrl: string | null;
    submissionId: string | null;
    submissionStatus: SubmissionStatut | null;
}

/**
 * Sujets du diagnostic servis **sans authentification**
 * (`GET /api/public/diagnostics/current`) : de quoi produire son écrit et son
 * oral avant même d'avoir un compte.
 *
 * Ni `attemptId` ni `submissionId` : ils n'existent qu'une fois la session
 * créée côté serveur, donc **après** l'inscription. Le visiteur produit
 * d'abord, le serveur enregistre ensuite.
 */
export interface PublicDiagnosticExerciseDto {
    productionTaskId: string;
    epreuve: Extract<EpreuveType, "TCF_EE" | "TCF_EO">;
    title: string;
    instruction: string;
    helperText: string | null;
    wordsMin: number | null;
    wordsMax: number | null;
    durationMinSeconds: number | null;
    durationMaxSeconds: number | null;
    instructionAudioUrl: string | null;
}

export interface PublicDiagnosticResponse {
    diagnosticCode: string;
    diagnosticVersion: number;
    written: PublicDiagnosticExerciseDto;
    /**
     * 🛑 **`null` = ce diagnostic n'a PAS d'étape orale** (diagnostic rapide,
     * L3 / `50_` §3.2). Ce n'est pas une panne : un écran qui le traiterait
     * comme telle bloquerait tout le parcours invité.
     */
    oral: PublicDiagnosticExerciseDto | null;
}

/**
 * Verrou freemium d'une brique de production, **posé et imposé par le serveur**.
 *
 * `true` ⇒ ce candidat ne peut pas produire dessus : le web n'affiche qu'un
 * cadenas et renvoie vers `/paiement`. Aucun front ne recalcule la règle (quelle
 * compétence est ouverte, combien de sujets par compétence) — elle vit dans le
 * backend, qui répond 403 de toute façon. Un serveur qui ne servirait pas encore
 * le champ laisse donc tout **ouvert**, jamais tout fermé.
 */
interface SkillLockable {
    locked: boolean;
}

/**
 * Nature de l'action proposée par le Plan — **même carte, même emplacement,
 * action différente**. Les quatre ne mènent pas au même écran : le front lit
 * `kind`, il ne le devine jamais d'un `null`.
 *
 * Les deux derniers rangs sont des **jalons** : ils ne désignent aucun contenu
 * éditorial mais une session d'examen blanc **déjà existante**, par son épreuve
 * et son slot de grille.
 */
export type PlanExerciseKind =
    | "MICRO_TRAINING"
    | "REASSESSMENT"
    | "TARGETED_QCM_SERIES"
    | "EPREUVE_MOCK_EXAM"
    | "FULL_TCF_MOCK_EXAM";

/**
 * L'exercice d'une **étape** : un micro-sujet du module Compétences, ou une
 * vérification en situation sur une vraie tâche TCF. Tout le bloc compétence y
 * est renseigné — c'est ce qui distingue une étape d'un jalon.
 */
export interface PlanStepExerciseDto extends SkillLockable {
    kind: "MICRO_TRAINING" | "REASSESSMENT";
    /** Micro-exercice uniquement ; `null` sur une vérification. */
    skillPromptId: string | null;
    /** Vérification uniquement ; `null` sur un micro-exercice. */
    productionTaskId: string | null;
    skillId: string;
    skillCode: string;
    title: string;
    /** Toujours un domaine d'**expression** : petits sujets et tâches de
     *  production n'existent que là. La compréhension a sa propre nature
     *  (`PlanTargetedQcmExerciseDto`). */
    section: SkillProductionSection;
    /** Numéro de tâche (1, 2 ou 3) du sujet de production — vérification
     *  uniquement, `null` sur un micro-exercice. */
    tacheNumero: number | null;
    estimatedMinutes: number;
    epreuve: null;
    slotNumber: null;
    questionCount: null;
}

/**
 * Une **série ciblée de QCM** sur une compétence de COMPRÉHENSION (CO / CE) : le
 * pendant du micro-exercice pour les deux domaines qui n'ont ni tâche ni petit
 * sujet.
 *
 * Elle se démarre par `POST /api/attempts` avec
 * `{type: "TRAINING", module: "TCF", skillId}` — **la compétence suffit**.
 * Domaine, palier et taille se dérivent du référentiel côté serveur ; un couple
 * (type de question, difficulté) envoyé par le client aurait pu contredire la
 * compétence affichée et faire progresser une autre compétence que celle
 * travaillée. D'où l'absence de tout identifiant supplémentaire ici.
 *
 * 🛑 **Une série ciblée est un `TRAINING` : elle ne rend JAMAIS un domaine
 * « évalué »** (`PlanDomainDto.evaluated`). Seul un examen blanc de module le
 * fait — c'est `LearningPlanDto.domainesAEvaluer` qui dit par quoi mesurer un
 * domaine manquant.
 */
export interface PlanTargetedQcmExerciseDto extends SkillLockable {
    kind: "TARGETED_QCM_SERIES";
    skillPromptId: null;
    productionTaskId: null;
    skillId: string;
    skillCode: string;
    title: string;
    section: SkillComprehensionSection;
    tacheNumero: null;
    estimatedMinutes: number;
    epreuve: null;
    slotNumber: null;
    /**
     * Nombre de questions **demandé** — la carte l'annonce (« Série ciblée de 20
     * questions ») et c'est le dénominateur du seuil de réussite. Une banque
     * trop mince peut en servir moins, ce que seule la session dira : ne jamais
     * l'écrire en dur côté front.
     */
    questionCount: number;
}

/**
 * Un **jalon** : une session d'examen blanc **déjà existante**, désignée par son
 * épreuve et son slot de grille. Aucun contenu n'est créé.
 *
 * ⚠️ **Tout le bloc compétence y est `null`** — `skillId`, `skillCode`, `title`
 * et `section` — et c'est voulu : un jalon ne désigne pas un contenu éditorial.
 * Sa phrase appartient aux fronts (`planMilestoneLabel`), le serveur n'expose
 * que des faits : quelle épreuve, quel slot, verrouillé ou non.
 */
export interface PlanMilestoneExerciseDto extends SkillLockable {
    kind: "EPREUVE_MOCK_EXAM" | "FULL_TCF_MOCK_EXAM";
    skillPromptId: null;
    productionTaskId: null;
    skillId: null;
    skillCode: null;
    title: null;
    section: null;
    tacheNumero: null;
    estimatedMinutes: number;
    /**
     * `TCF_EE` / `TCF_EO` pour un examen blanc d'épreuve, `TCF_COMPLET` pour
     * l'examen blanc complet — c'est **ce champ**, jamais `section`, qui dit
     * vers quel examen le front doit envoyer.
     */
    epreuve: Extract<EpreuveType, "TCF_EE" | "TCF_EO" | "TCF_COMPLET">;
    /**
     * Slot de la grille d'examens blancs à démarrer. Le serveur désigne le
     * premier slot non joué : le front le repasse tel quel au démarrage, il ne
     * le choisit pas.
     */
    slotNumber: number;
    questionCount: null;
}

/**
 * L'exercice d'une **compétence** : micro-sujet, vérification en situation, ou
 * série ciblée de compréhension. Tout le bloc compétence y est renseigné — c'est
 * ce qui le distingue d'un jalon.
 */
export type PlanSkillExerciseDto = PlanStepExerciseDto | PlanTargetedQcmExerciseDto;

/**
 * L'exercice que le Plan désigne — sur une compétence (une étape) ou, d'un cran
 * au-dessus, comme **jalon** du parcours. **Union discriminée par `kind`** : les
 * identifiants sont mutuellement exclusifs par nature, et c'est le type qui
 * l'impose plutôt qu'une convention à relire.
 */
export type PlanRecommendedExerciseDto = PlanSkillExerciseDto | PlanMilestoneExerciseDto;

export interface DiagnosticSkillObservationDto {
    skillId: string;
    skillCode: string;
    skillTitle: string;
    section: SkillSection;
    observed: boolean;
    status: LearningPlanSkillStatus;
    evidence: string | null;
    explanation: string | null;
    confidence: ObservationConfidence;
    priority: boolean;
}

export interface DiagnosticProductionResultDto {
    /**
     * **Trois états, pas deux.** Bloc `written` / `oral` absent = « pas encore
     * analysée » ; présent avec `NON_EVALUABLE` = « rendue, rien à observer » —
     * 4 s d'audio, quelques mots : le correcteur n'a **pas** été appelé, et
     * aucun niveau n'est affirmé. Une production inexploitable n'est pas une
     * production faible.
     *
     * **Jamais `null`** côté serveur ; un backend antérieur au champ ne le sert
     * pas du tout, donc seule la valeur `NON_EVALUABLE` **explicite** se lit
     * comme inexploitable — jamais son absence.
     */
    evaluabilite: ProductionEvaluabilite;
    levelEstimate: NiveauCecrl | null;
    taskCompletion: DiagnosticTaskCompletion;
    communicationStatus: DiagnosticCommunicationStatus;
    summary: string | null;
    strengths: string[];
    weaknesses: string[];
    skills: DiagnosticSkillObservationDto[];
}

/**
 * La phrase du candidat, puis la même idée écrite au niveau qu'il vise.
 *
 * Produit par un **second appel LLM best-effort**, comme `version_ciblee` sur une
 * production complète : son absence est un cas **NORMAL**, jamais une erreur —
 * aucun front n'affiche de message d'échec ni de spinner quand il manque.
 * **Production écrite seulement** : une transcription orale n'est jamais
 * réécrite (même règle que `ActionPlanReformulation`).
 *
 * `original` est une sous-chaîne exacte de la production, et chaque
 * `segments[].extrait` une sous-chaîne exacte de `texte` : on surligne par
 * simple recherche de chaîne, en nœuds React, **jamais** par
 * `dangerouslySetInnerHTML`. Introuvable ⇒ texte brut, sans surlignage inventé.
 */
export interface DiagnosticExempleCibleDto extends ActionPlanExempleCible {
    /** La phrase du candidat, telle qu'il l'a écrite. */
    original: string;
    niveauVise: NiveauCecrl;
}

export interface DiagnosticResultDto {
    written: DiagnosticProductionResultDto | null;
    oral: DiagnosticProductionResultDto | null;
    strengths: string[];
    priorities: DiagnosticSkillObservationDto[];
    mainPriorityExplanation: string | null;
    /** Toujours une compétence : le diagnostic désigne celle de la priorité
     *  n°1, jamais un jalon d'examen blanc. */
    nextAction: PlanSkillExerciseDto | null;
    /** Second appel best-effort : `null` (ou absent) est un cas normal. */
    exempleCible: DiagnosticExempleCibleDto | null;
    /**
     * Combien de compétences **distinctes** les deux productions ont réellement
     * montrées fragiles (observées, `PRIORITY` ou `TO_REINFORCE`).
     *
     * 🛑 **C'est la seule source du « + N autres » de l'écran de résultat.**
     * `priorities` est plafonné à 3 par règle produit : un compteur calculé
     * dessus ne dirait jamais mieux que « + 2 », un chiffre de plafond et non
     * une réalité. Le serveur fait foi — aucun front ne recompte, deux
     * dérivations finiraient par afficher deux nombres différents.
     *
     * `0` est un état normal : aucun bloc « + N autres » n'est rendu.
     */
    fragileSkillCount: number;
    /**
     * Le compte réel des points forts : compétences distinctes observées
     * `SOLID`. ⚠️ `strengths` ne peut pas rendre ce service — la liste est
     * plafonnée à 3 **à l'écriture** du résumé côté serveur.
     */
    solidSkillCount: number;
}

export interface DiagnosticResponse {
    sessionId: string | null;
    diagnosticCode: string | null;
    diagnosticVersion: number | null;
    status: DiagnosticJourneyStatus;
    nextStep: DiagnosticStep;
    written: DiagnosticExerciseDto | null;
    oral: DiagnosticExerciseDto | null;
    result: DiagnosticResultDto | null;
    startedAt: string | null;
    completedAt: string | null;
    errorMessage: string | null;
    canRetry: boolean;
}

/**
 * Compteurs de sujets d'une compétence, servis par le Plan **exactement** comme
 * `GET /api/skills` les sert au module Compétences — mêmes trois champs, mêmes
 * bornes. C'est ce qui permet au Plan de réutiliser `SkillRing` et
 * `competenceProgressLabel` sans recalculer quoi que ce soit : les deux écrans
 * parlent des mêmes compétences, ils doivent en dire la même chose.
 */
interface LearningPlanSkillCounters {
    /** Nombre de petits sujets publiés pour la compétence. */
    promptCount: number;
    /** Sujets déjà tentés par ce candidat. */
    attemptedCount: number;
    /** Sujets dont le critère a été validé. */
    validatedCount: number;
}

/**
 * **Ce que le Plan demande de faire** sur une entrée — la pastille d'une carte
 * « Aujourd'hui » et d'une ligne de « Mes priorités ».
 *
 * Le Plan n'est pas seulement un moteur de **remédiation** : c'est un moteur de
 * **progression vers le niveau visé**. Il savait réparer ce qui était fragile ;
 * il ne savait pas **enseigner** ce qui n'avait jamais été travaillé.
 *
 * > `NON OBSERVÉ ≠ FAIBLE`, mais aussi `NON FRAGILE ≠ PLUS RIEN À APPRENDRE`.
 *
 * 🛑 **`A_ACQUERIR` ne se dit JAMAIS « à renforcer ».** Renforcer suppose un
 * constat négatif ; sur une compétence jamais travaillée il n'y en a aucun.
 * C'est une distinction de fond, pas de vocabulaire — et c'est elle que les
 * écrans doivent rendre lisible.
 *
 * **L'ordre de déclaration EST l'ordre de choix** d'une séance : mesurer ce qui
 * manque, réparer ce qui est fragile, vérifier ce qui est prêt, apprendre ce qui
 * vient. Ne pas le réordonner.
 *
 * ⚠️ **Trois vocabulaires, trois grains — ils ne se remplacent pas.**
 * `LearningPlanSkillStatus` est le verdict d'**une production** (persisté, sans
 * libellé) · `SkillMasteryState` l'état **agrégé** d'une compétence (dérivé,
 * affiché sur sa fiche) · `PlanActionNature` **l'action à faire maintenant**
 * (dérivée, affichée sur la carte du Plan). `A_RENFORCER` et
 * `SkillMasteryState.TO_REINFORCE` portent **volontairement** le même libellé —
 * quand les deux s'appliquent ils disent la même chose, ils ne s'affichent
 * simplement pas au même endroit. Idem pour « À évaluer », partagé avec
 * `PlanDomainPriority.A_EVALUER`. Ce n'est **pas** une collision à corriger.
 */
export type PlanActionNature =
    /** Une mesure manque et elle est indispensable : le candidat a produit sur
     *  ce domaine et le correcteur n'a rien pu y observer. L'action n'est pas un
     *  exercice mais une **évaluation** (`PlanSeanceItemDto.assessment`). */
    | "A_EVALUER"
    /** Une fragilité **réellement observée** : c'est ce qui bloque maintenant. */
    | "A_RENFORCER"
    /** L'étape est terminée et assez travaillée en ciblé : le Plan demande une
     *  **vérification en situation** au lieu d'empiler des micro-sujets. */
    | "A_VERIFIER"
    /** **Une compétence du palier en construction, jamais travaillée.** Aucun
     *  constat négatif ne la désigne : elle est là parce qu'elle appartient au
     *  palier que le cycle construit. Elle n'est pas une observation — ni score,
     *  ni moyenne, ni fragilité — d'où `masteryState: null`. */
    | "A_ACQUERIR";

/** Libellés FR des natures d'action (**contrat gelé** par `SkillLabelsTest`
 *  côté backend, recopié à la main ici : un libellé qui bouge, ce sont quatre
 *  fichiers à changer dans la même passe). Ne jamais recopier ces chaînes dans
 *  un composant — c'est cette recopie qui avait fait diverger le web du mobile. */
export const PLAN_ACTION_NATURE_LABEL: Record<PlanActionNature, string> = {
    A_EVALUER: "À évaluer",
    A_RENFORCER: "À renforcer",
    A_VERIFIER: "À vérifier",
    A_ACQUERIR: "À acquérir",
};

/**
 * Une priorité du Plan, c'est-à-dire une **étape**.
 *
 * ⚠️ **Deux jeux de compteurs, à ne jamais confondre.** Ceux de
 * `LearningPlanSkillCounters` (`promptCount` / `attemptedCount` /
 * `validatedCount`) décrivent la **compétence entière** (15 sujets) et servent
 * aux cartes « compétences observées ». Les `step*` ci-dessous décrivent
 * l'**étape** : les 5 premiers sujets actifs de la compétence, et rien d'autre
 * — **c'est ce couple que l'anneau d'une étape affiche** (« 2/5 », pas
 * « 2/15 »). Les deux sont dérivés serveur, jamais recalculés ici.
 */
export interface LearningPlanPriorityDto extends LearningPlanSkillCounters, SkillLockable {
    skillId: string;
    skillCode: string;
    title: string;
    section: SkillSection;
    /**
     * **Ce que le Plan demande de faire** ici : `A_RENFORCER` (fragilité
     * observée), `A_VERIFIER` (étape terminée, vérification en situation) ou
     * `A_ACQUERIR` (compétence du palier en construction, **jamais
     * travaillée**). Une priorité ne porte jamais `A_EVALUER` : mesurer un
     * domaine n'est pas une étape de compétence, cela vit dans la séance et dans
     * « Compléter mon profil ».
     *
     * 🛑 **Les écrans lisent cette nature, jamais la nullité d'un autre champ**
     * — et une entrée `A_ACQUERIR` ne se présente **jamais** comme « à
     * renforcer ».
     */
    nature: PlanActionNature;
    /**
     * Le verdict de la dernière production. **`null` sur une compétence à
     * acquérir**, comme `explanation`, `evidence`, `confidence`, `observedAt` et
     * `masteryState` : ce n'est pas un trou de donnée, c'est le fait même — rien
     * n'a été constaté, donc rien n'a échoué. *null = inconnu, jamais mauvais.*
     */
    status: LearningPlanSkillStatus | null;
    explanation: string | null;
    evidence: string | null;
    confidence: ObservationConfidence | null;
    observedAt: string | null;
    /**
     * L'action courante de l'étape. Micro-sujet ou vérification en expression,
     * **série ciblée** sur une compétence de compréhension : le front lit
     * `kind`, il ne le devine jamais d'un identifiant nul.
     */
    recommendedExercise: PlanSkillExerciseDto | null;
    /** Sujets de l'étape : au plus les 5 premiers actifs, moins si la compétence en publie moins. */
    stepPromptCount: number;
    /** Sujets de l'étape déjà traités (tout sauf « À faire »). */
    stepAttemptedCount: number;
    /** Sujets de l'étape dont le critère a été validé. Toujours ≤ `stepAttemptedCount`. */
    stepValidatedCount: number;
    /**
     * `true` quand les sujets de l'étape ont **tous** été traités. Terminée ≠
     * tout validé, d'où `stepValidatedCount` à côté. Une étape terminée **reste
     * affichée** : les priorités ne changent qu'à la prochaine production.
     */
    stepCompleted: boolean;
    /**
     * **Le périmètre de l'étape** : les identifiants des sujets qui la
     * composent, dans l'ordre de l'étape (rang d'affichage croissant).
     * **Jamais `null`**, et `stepPromptIds.length === stepPromptCount` par
     * construction — ne rien recompter à partir de là.
     *
     * Il permet à l'écran d'une compétence ouverte **depuis le Plan** de rester
     * dans l'étape (les mêmes 5 sujets, « 2/5 ») au lieu de retomber sur la
     * fiche complète et son « 1/15 ». La règle « les 5 premiers sujets actifs »
     * vit côté serveur : elle ne se réimplémente nulle part.
     *
     * Liste **vide** quand la compétence n'a aucun sujet actif — cas normal ;
     * plus courte que 5 quand elle en publie moins.
     */
    stepPromptIds: string[];
    /** État agrégé de la compétence, identique à `SkillDto.masteryState` — à ne
     *  pas confondre avec `status`, verdict de la **dernière** production. */
    masteryState: SkillMasteryState | null;
    /** `true` quand la compétence a assez été travaillée en exercices ciblés
     *  sans preuve de transfert récente : l'étape devient une **vérification**
     *  (`recommendedExercise.kind === "REASSESSMENT"`). */
    readyForReassessment: boolean;
}

/**
 * Une **étape franchie** du parcours : une compétence dont le transfert est
 * prouvé, donc qui n'est plus une priorité.
 *
 * Jusqu'ici une compétence réussie sortait simplement des priorités et son
 * étape **disparaissait** du Plan — le candidat perdait la trace de ce qu'il
 * avait passé. Elles sont désormais servies pour être affichées **avant**
 * l'étape courante et les suivantes, dans le même parcours numéroté, et
 * **cochées**.
 *
 * ⚠️ **Ni `recommendedExercise`, ni `locked`** : il n'y a plus rien à y faire,
 * et une étape franchie n'est pas une porte commerciale. Ne pas en inventer.
 *
 * ⚠️ **`masteryState` n'est PAS toujours `SOLID`** : une preuve de transfert
 * récente suffit à franchir l'étape. **L'appartenance à cette liste EST la
 * coche** — ne jamais conditionner l'affichage à un état de maîtrise.
 */
export interface LearningPlanCompletedStepDto {
    skillId: string;
    skillCode: string;
    title: string;
    section: SkillSection;
    /** Dernière observation probante : c'est elle qui ordonne les étapes franchies. */
    observedAt: string;
    /** Sujets de l'étape : au plus les 5 premiers actifs, moins si la compétence en publie moins. */
    stepPromptCount: number;
    /** Sujets de l'étape déjà traités. Une étape franchie n'est pas forcément à 5/5. */
    stepAttemptedCount: number;
    /** Sujets de l'étape dont le critère a été validé. Toujours ≤ `stepAttemptedCount`. */
    stepValidatedCount: number;
    /** Périmètre de l'étape, dans l'ordre. **Jamais `null`**, éventuellement vide. */
    stepPromptIds: string[];
    masteryState: SkillMasteryState | null;
}

export interface LearningPlanSkillDto extends LearningPlanSkillCounters, SkillLockable {
    skillId: string;
    skillCode: string;
    title: string;
    section: SkillSection;
    status: LearningPlanSkillStatus;
    lastObservedAt: string;
    /** Même état agrégé que `SkillDto.masteryState`, issu du même moteur : un
     *  candidat ne doit pas lire deux états différents pour une compétence. */
    masteryState: SkillMasteryState | null;
}

/* ---------------------------------------------------------------- domaines
 *
 * Le Plan adaptatif raisonne **par domaine du TCF** (CO · CE · EO · EE) avant
 * de raisonner par compétence. Deux règles transverses, valables partout
 * ci-dessous, et qu'aucun écran ne doit contourner :
 *
 * 1. 🛑 **Une série ciblée (`TARGETED_QCM_SERIES`, un `TRAINING`) ne rend
 *    JAMAIS un domaine « évalué ».** Seul un examen blanc de module le fait —
 *    et pour l'expression, le diagnostic ou une production. S'entraîner n'est
 *    pas se mesurer : c'est `domainesAEvaluer` qui dit par quoi mesurer un
 *    domaine manquant.
 * 2. 🛑 **Le serveur trie déjà `domaines` par urgence** (`PlanDomainPriority`,
 *    ordre de déclaration, puis ordre des épreuves du TCF à égalité). **Aucun
 *    front ne retrie**, même doctrine que l'ordre des priorités : trois copies
 *    front auraient fini par peindre trois classements différents.
 */

/**
 * Ce que le Plan a décidé de faire d'un **domaine** — la pastille à droite de sa
 * ligne dans « Mon profil TCF ».
 *
 * **L'ordre de déclaration EST l'ordre d'urgence** : c'est lui qui trie les 4
 * lignes du profil côté serveur. Ne pas le réordonner.
 *
 * 🛑 **Aucune des cinq valeurs ne nomme une faiblesse.** `A_EVALUER` veut dire
 * « il manque des données », pas « ce domaine est mauvais » — transposition au
 * niveau du domaine du principe *null = inconnu, jamais mauvais*.
 */
export type PlanDomainPriority =
    | "FORTE"
    | "A_TRAVAILLER"
    | "ENTRETIEN"
    | "PAS_ENCORE_PRIORITAIRE"
    | "A_EVALUER";

/** Libellés FR des pastilles de domaine (**contrat gelé** par `SkillLabelsTest`
 *  côté backend, recopié à la main ici : un libellé qui bouge, ce sont quatre
 *  fichiers à changer dans la même passe). Ne jamais recopier ces chaînes dans
 *  un composant — c'est cette recopie qui avait fait diverger le web du mobile. */
export const PLAN_DOMAIN_PRIORITY_LABEL: Record<PlanDomainPriority, string> = {
    FORTE: "Priorité forte",
    A_TRAVAILLER: "À travailler",
    ENTRETIEN: "Entretien",
    PAS_ENCORE_PRIORITAIRE: "Pas encore prioritaire",
    A_EVALUER: "À évaluer",
};

/**
 * Un palier d'un domaine de **compréhension** : où en est le candidat sur
 * `CO-A2`, `CO-B1`, `CO-B2` (ou leurs jumelles CE).
 *
 * `masteryState: null` ⇒ **jamais observé** : on n'invente pas un état pour un
 * palier que personne n'a mesuré. Et **jamais un pourcentage** : le score
 * interne du moteur n'est exposé à aucun front.
 */
export interface PlanDomainLevelDto {
    niveau: TargetLevel;
    /** La compétence du palier — c'est elle qui ouvre la série ciblée. */
    skillId: string;
    /** `CO-B1`, `CE-A2`... */
    skillCode: string;
    masteryState: SkillMasteryState | null;
    /** Ce palier est le **premier** non consolidé du domaine : c'est lui qui
     *  empêche de compter les paliers supérieurs. Règle serveur, jamais
     *  recopiée ici. */
    blocking: boolean;
}

/**
 * Une tâche d'un domaine d'**expression** (EE1..EO3) vue depuis le Plan :
 * combien de ses compétences ont déjà été observées.
 *
 * « 3 / 8 observées » **n'est pas une note** : une compétence non observée n'est
 * pas une compétence ratée, c'est une compétence que le candidat n'a pas encore
 * eu l'occasion de montrer. Le dénominateur est lu en base — ne jamais écrire 8
 * en dur.
 */
export interface PlanDomainTaskDto {
    taskCode: SkillTaskCode;
    /** 1, 2 ou 3 — ce que les écrans de production attendent. */
    tacheNumero: number;
    observedSkills: number;
    totalSkills: number;
}

/**
 * Un des quatre domaines du TCF **vu par le Plan** : son niveau estimé, ce que
 * le Plan a décidé d'en faire, et de quoi ouvrir sa fiche de détail.
 *
 * **À ne pas confondre avec `TcfDomainDto`** (dashboard) : celui-là répond à
 * « quel est mon niveau ? », celui-ci à « qu'est-ce que j'en fais maintenant ? ».
 * Le **niveau est le même**, il vient de la même autorité serveur.
 *
 * `evaluated === false` ⇔ `niveau === null` : jamais mesuré, donc **inconnu**,
 * jamais mauvais. Sa priorité vaut alors `A_EVALUER`.
 *
 * **Les deux blocs de détail s'excluent**, parce que les deux familles ne se
 * travaillent pas pareil :
 * - **compréhension** (CO / CE) : `paliers` porte les trois compétences de
 *   palier, `blockingLevel` celle qui bloque ; `taches` est **vide** ;
 * - **expression** (EO / EE) : `taches` porte les trois tâches et leur
 *   couverture ; `paliers` est **vide**, et `consolidatedLevel` /
 *   `blockingLevel` valent `null` — la notion de palier consolidé n'existe que
 *   là où la progression est séquentielle.
 *
 * Les deux listes sont **toujours présentes**, jamais `null`.
 */
export interface PlanDomainDto {
    epreuve: Extract<EpreuveType, "TCF_CO" | "TCF_CE" | "TCF_EO" | "TCF_EE">;
    evaluated: boolean;
    niveau: NiveauCecrl | null;
    priority: PlanDomainPriority;
    /** Compréhension : plus haut palier consolidé, prérequis compris. `null` si
     *  rien ne l'est, et **toujours `null` en expression**. */
    consolidatedLevel: TargetLevel | null;
    /** Compréhension : premier palier non consolidé. `null` quand les trois le
     *  sont, et **toujours `null` en expression**. */
    blockingLevel: TargetLevel | null;
    /** Compréhension : A2, B1, B2 dans cet ordre. **Vide** en expression. */
    paliers: PlanDomainLevelDto[];
    /** Expression : tâches 1, 2, 3 dans cet ordre. **Vide** en compréhension. */
    taches: PlanDomainTaskDto[];
    /**
     * **Toutes** les compétences actives du domaine, dans l'ordre du serveur :
     * les 24 des trois tâches en expression, les 3 paliers en compréhension.
     *
     * Contrairement à `paliers` / `taches`, cette liste est **uniforme sur les
     * quatre domaines** — c'est ce qui permet à l'écran « Mon diagnostic » de
     * n'avoir qu'**une** façon de rendre une carte d'épreuve. **Jamais `null`**
     * (un backend antérieur au champ ne le sert pas : replier sur `[]`).
     *
     * 🛑 **L'ordre est décidé par le serveur, aucun front ne retrie** : deux
     * copies de la règle désigneraient deux ordres.
     */
    skills: PlanDomainSkillDto[];
    /** Compétences observées `PRIORITY` ou `TO_REINFORCE`. */
    fragileSkillCount: number;
    /** Compétences observées `SOLID`. */
    solidSkillCount: number;
    /**
     * Compétences **jamais observées** — ce n'est pas une faiblesse, c'est une
     * absence de mesure.
     *
     * 🛑 Les trois compteurs sont **dérivés de `skills` côté serveur** et leur
     * somme vaut toujours `skills.length` : c'est ce qui rend un « + N autres »
     * vrai. Ne jamais les recompter ici — deux dérivations finiraient par
     * afficher deux nombres différents pour la même épreuve.
     */
    notObservedSkillCount: number;
    /**
     * Le palier que **ce domaine** construit. `null` quand il n'y a rien à
     * construire : domaine jamais mesuré, ou **déjà à l'objectif** — il
     * s'entretient alors, il ne redescend pas.
     *
     * 🛑 **Servi, jamais recalculé.** Ce front en tenait une copie (`nextLevel`,
     * `DiagnosticReport.tsx`) qui ignorait l'objectif du candidat : un candidat
     * B1 visant le B1 lisait « prochain palier B2 ». Supprimée le 2026-08-26.
     */
    nextTargetLevel: TargetLevel | null;
    /**
     * Compétences **à acquérir** sur ce domaine (`nature === "A_ACQUERIR"`).
     * Sous-ensemble de `notObservedSkillCount`, et **uniquement des compétences
     * exécutables** : le compte ne promet jamais un contenu qui n'existe pas.
     */
    acquireCount: number;
    /** Compétences **prêtes à être vérifiées** (`nature === "A_VERIFIER"`). */
    readyForValidationCount: number;
    /**
     * Compétences jamais observées **sur lesquelles le Plan ne demande rien** —
     * le vrai « pas encore assez de données pour se prononcer ».
     *
     * 🛑 **Ne jamais le recalculer** en soustrayant les acquisitions d'une liste
     * affichée : le mobile le faisait, et les deux nombres divergeaient du
     * serveur dès qu'une acquisition existait.
     */
    notObservedWithoutActionCount: number;
}

/**
 * Une compétence du référentiel d'une **épreuve**, vue depuis le Plan : où en
 * est le candidat dessus, et peut-il la travailler.
 *
 * **Trois nullités, trois faits différents.**
 * - `status` vaut `NOT_OBSERVED` quand rien n'a jamais été observé — **jamais
 *   `null`** : une compétence est toujours dans un des quatre états, et « non
 *   observée » est un état, pas une absence de donnée ;
 * - `masteryState` et `observedAt` valent `null` dans ce même cas : *null =
 *   inconnu, jamais mauvais* ;
 * - `nature` vaut `null` dès que le Plan ne demande **rien** dessus — le cas de
 *   l'immense majorité des compétences. Une compétence `SOLID`, ou non observée
 *   hors du palier que le cycle construit, **n'est pas une action** : ne pas
 *   fabriquer une pastille pour remplir la colonne.
 */
export interface PlanDomainSkillDto {
    skillId: string;
    /** `EE1-C3`, `CO-B1`... */
    skillCode: string;
    title: string;
    /** C'est **lui** qui dit le domaine, jamais la tâche. */
    section: SkillSection;
    /** `null` en compréhension : CO/CE n'ont aucune tâche. */
    taskCode: SkillTaskCode | null;
    /** 1, 2 ou 3 ; `null` en compréhension. */
    tacheNumero: number | null;
    /** Le palier porté par le référentiel ; `null` s'il descend sous `A2`. */
    targetLevel: TargetLevel | null;
    status: LearningPlanSkillStatus;
    masteryState: SkillMasteryState | null;
    nature: PlanActionNature | null;
    observedAt: string | null;
    /** Verrou freemium, décidé par le serveur (`SkillAccessService`). */
    locked: boolean;
}

/* ------------------------------------------------------------------- cycle */

/** Où en est le **cycle de palier** courant. Dérivé à la lecture, jamais
 *  persisté : aucune table, aucune migration. */
export type PlanCycleState =
    /** Au moins un des quatre domaines n'a jamais été mesuré. Le Plan met
     *  « Compléter mon profil » en avant et **ne déclenche aucun examen de
     *  palier** — un gate sur trois domaines confirmerait un palier non mesuré. */
    | "BUILDING_BASELINE"
    /** Profil complet, travail en cours sur les priorités du palier visé. */
    | "TRAINING"
    /** Tout le travail du palier est fait : le Plan réclame l'examen blanc
     *  complet qui le confirmera (servi sur `LearningPlanDto.milestone`). */
    | "READY_FOR_GATE_MOCK"
    /** Objectif atteint sur les domaines mesurés : plus de palier à construire,
     *  on entretient et on remesure. */
    | "TARGET_STABILIZATION";

/** Nature d'une étape du chemin vers l'objectif. Le serveur expose des faits ;
 *  « Construire votre B1 » est une formulation, pas une donnée. */
export type PlanPathStepKind =
    /** Mesurer les quatre domaines. Toujours la première étape. */
    | "COMPLETE_PROFILE"
    /** Construire un palier CECRL ; le palier vit sur `level`. */
    | "BUILD_LEVEL"
    /** Objectif atteint : tenir le niveau en conditions d'examen. Toujours la
     *  dernière. */
    | "STABILIZE";

/** Où se situe une étape du chemin. Un enum plutôt que deux booléens : « faite »
 *  et « en cours » ne peuvent pas être vraies ensemble. */
export type PlanPathStepStatus = "DONE" | "CURRENT" | "UPCOMING";

/** Une étape du chemin vers l'objectif, telle que le Plan la sert. */
export interface PlanPathStepDto {
    kind: PlanPathStepKind;
    /** Palier concerné — renseigné **uniquement** sur `BUILD_LEVEL`, `null`
     *  ailleurs. */
    level: TargetLevel | null;
    status: PlanPathStepStatus;
}

/**
 * Le **cycle de palier** en cours : d'où part le candidat, quel palier le Plan
 * construit maintenant, son objectif, et où il en est sur le chemin.
 *
 * **`targetLevel` est le cran AU-DESSUS de `startingLevel`, jamais l'objectif
 * directement** : un candidat A2 qui vise le B2 travaille d'abord le B1. Il est
 * plafonné par l'objectif — on ne fait jamais viser plus haut que nécessaire.
 *
 * 🛑 **`objectiveLevel` n'est pas « B2 » en dur** : c'est le palier de la
 * démarche (CSP→A2, CR→B1, NAT→B2), avec plancher. **`null` quand le candidat
 * n'a déclaré ni démarche ni palier** — on ne devine jamais à sa place.
 */
export interface PlanCycleDto {
    /** Niveau global mesuré d'où part le cycle. `null` tant que rien n'est
     *  mesuré. Exprimé en `NiveauCecrl` parce qu'il peut valoir `A1` ou moins,
     *  ce que `TargetLevel` ne sait pas dire. */
    startingLevel: NiveauCecrl | null;
    /** Palier construit par ce cycle, dans `A2..B2`. */
    targetLevel: TargetLevel;
    /** Palier visé par le candidat. **`null` si inconnu**. */
    objectiveLevel: TargetLevel | null;
    state: PlanCycleState;
    /** Domaines réellement mesurés (0..4). **C'est ici que se lit le compte**
     *  « 2/4 », pas dans la longueur de `domainesAEvaluer`. */
    domainsEvaluated: number;
    /** 4, toujours. */
    domainsExpected: number;
    profileComplete: boolean;
    /** Le chemin, de la première étape à la dernière. Jamais `null` ; une seule
     *  étape y est `CURRENT`. */
    path: PlanPathStepDto[];
}

/* ----------------------------------------------------- compléter le profil */

/** Par quoi un domaine encore **non mesuré** se fait mesurer. 🛑 Aucune de ces
 *  natures ne crée de contenu : chacune désigne un parcours **déjà existant**. */
export type PlanDomainAssessmentKind =
    /** Le diagnostic (`POST /api/diagnostics`) : une production écrite puis une
     *  orale. Il mesure **les deux domaines d'expression à la fois** — il peut
     *  donc être désigné sur `TCF_EE` **et** sur `TCF_EO` dans la même réponse.
     *  Ce n'est pas un doublon : deux domaines pointent vers la même porte. */
    | "DIAGNOSTIC"
    /** Un examen blanc de module QCM sur l'épreuve du domaine
     *  (`POST /api/attempts`, `type: "MOCK_EXAM"`, `moduleExamQuestionType`).
     *  Correction 100 % déterministe — aucune IA n'y touche. */
    | "MODULE_MOCK_EXAM"
    /** Une production EE ou EO du catalogue standard. Repli du domaine
     *  d'expression dont le diagnostic est **déjà terminé** sans que le domaine
     *  ait un niveau — on ne rejoue jamais le diagnostic. */
    | "PRODUCTION";

/**
 * Ce qu'il faut lancer pour mesurer un domaine **jamais** évalué : l'épreuve,
 * la nature du parcours, et les paramètres exacts du démarrage.
 *
 * **Des faits, jamais une phrase** — « Évaluer ma compréhension orale » et
 * « Pas encore évaluée » appartiennent aux fronts.
 *
 * Ce qui est renseigné selon `kind` :
 * | `kind` | renseigné | `null` |
 * |---|---|---|
 * | `DIAGNOSTIC` | `epreuve` | les trois autres |
 * | `MODULE_MOCK_EXAM` | tout | — |
 * | `PRODUCTION` | `epreuve` | les trois autres |
 */
export interface PlanDomainAssessmentDto {
    epreuve: Extract<EpreuveType, "TCF_CO" | "TCF_CE" | "TCF_EO" | "TCF_EE">;
    kind: PlanDomainAssessmentKind;
    /** Ce que `StartAttemptRequest` attend pour composer l'examen d'épreuve :
     *  `CO` ou `CE`, **jamais `CO_IMAGE`** (un filtre `CO` l'inclut déjà). */
    moduleExamQuestionType: QuestionType | null;
    /** Slot de la grille d'examens blancs à démarrer. */
    slotNumber: number | null;
    /** Durée de l'épreuve, lue chez le serveur et **jamais écrite en dur**.
     *  `null` quand la durée n'est pas une donnée d'examen (le diagnostic et une
     *  production ne sont pas chronométrés par épreuve). */
    estimatedMinutes: number | null;
}

/* ------------------------------------------------------------------ séance */

/**
 * Les faits communs à toute ligne de séance — ceux qui décrivent la compétence
 * travaillée et où le candidat en est.
 *
 * 🛑 **Aucune phrase.** Le serveur expose des faits — combien de sujets traités
 * sur combien, si la compétence attend une vérification, quel palier elle
 * travaille — et les fronts composent « Pourquoi cette séance ? ».
 *
 * **Le bloc compétence est vide sur un jalon comme sur une mesure** (`skillId`,
 * `skillCode`, `title`, `section` à `null`) : un examen blanc ne travaille pas
 * une compétence, il les vérifie toutes ; une mesure porte sur une **épreuve
 * entière**. Les écrans lisent `nature`, **jamais** la nullité d'un champ.
 */
interface PlanSeanceItemBase {
    /** **Ce que le Plan demande de faire** ici. Jamais `null`, et c'est le seul
     *  champ à lire pour le savoir. */
    nature: PlanActionNature;
    skillId: string | null;
    skillCode: string | null;
    title: string | null;
    section: SkillSection | null;
    /** Palier travaillé (`"A1"`..`"B2"`), renseigné en compréhension ; `null` en
     *  expression, sur un jalon et sur une mesure. **Chaîne** et non
     *  `TargetLevel` : le référentiel des compétences descend jusqu'à `A1`. */
    level: string | null;
    /** État agrégé, `null` sur un jalon, sur une mesure et sur une compétence
     *  **jamais observée** (à acquérir). */
    masteryState: SkillMasteryState | null;
    /** Sujets de l'étape ; **`0` en compréhension**, qui n'a pas d'étape à cinq
     *  sujets, et sur une mesure comme sur un jalon. */
    stepPromptCount: number;
    stepAttemptedCount: number;
    stepValidatedCount: number;
    stepCompleted: boolean;
    readyForReassessment: boolean;
    /** Ce candidat ne peut pas lancer cette action. Elle reste **désignée et
     *  visible** : savoir quoi travailler est ce que le Plan apporte. */
    locked: boolean;
    /**
     * **Date de la dernière activité sur cette compétence** (ISO), `null`
     * quand elle n'a jamais été observée, sur un jalon et sur une mesure.
     *
     * C'est un **fait**, pas un verdict : le serveur ne dit jamais « fait
     * aujourd'hui » — il n'a pas d'horloge dans la construction de la séance.
     * C'est le front qui compare cette date à sa journée courante
     * (**Europe/Paris**, `planSeanceItemDone`). La coche vit donc dans le
     * compte : elle survit à un rechargement, et elle est la même sur le web et
     * sur le mobile.
     *
     * ⚠️ Lue sur **toutes** les observations, `NOT_OBSERVED` comprise — le
     * correcteur n'a rien pu observer, mais le candidat a bien travaillé. À ne
     * pas confondre avec `LearningPlanPriorityDto.observedAt`, qui est la
     * dernière observation **probante**.
     */
    lastActivityAt: string | null;
}

/**
 * Un **entraînement** de la séance : petit sujet ciblé, vérification en
 * situation, série ciblée de compréhension ou jalon d'examen blanc.
 */
export interface PlanSeanceExerciseItemDto extends PlanSeanceItemBase {
    nature: "A_RENFORCER" | "A_VERIFIER" | "A_ACQUERIR";
    /** L'entraînement à lancer, **jamais `null`** sur cette variante. */
    exercise: PlanRecommendedExerciseDto;
    assessment: null;
}

/**
 * Une **mesure de domaine** : le seul item de séance qui n'est pas un exercice.
 *
 * Le candidat a produit sur ce domaine et le correcteur n'a **rien pu y
 * observer** ; lui proposer un micro-exercice de plus le ferait avancer à
 * l'aveugle. La séance commence donc par « votre oral n'a pas pu être analysé,
 * refaites-en un » — et cette ligne ne porte **aucune compétence** : c'est une
 * épreuve entière qu'on vient mesurer.
 *
 * ⚠️ À distinguer d'un domaine **jamais** mesuré, qui vit dans
 * `LearningPlanDto.domainesAEvaluer` (« Compléter mon profil »). Les deux
 * ouvrent le même genre de parcours, mais ne disent pas la même chose : ici le
 * candidat a déjà travaillé, c'est notre mesure qui a échoué.
 */
export interface PlanSeanceAssessmentItemDto extends PlanSeanceItemBase {
    nature: "A_EVALUER";
    exercise: null;
    /** La mesure à lancer — le même contrat que « Compléter mon profil », donc
     *  le même lanceur côté front (`usePlanAssessment`), jamais un second. */
    assessment: PlanDomainAssessmentDto;
}

/**
 * Une ligne de la séance. **Union discriminée par `nature`** : `exercise` et
 * `assessment` sont **mutuellement exclusifs**, et c'est le type qui l'impose
 * plutôt qu'une convention à relire — un écran qui oublierait la mesure ne
 * compile pas.
 */
export type PlanSeanceItemDto = PlanSeanceExerciseItemDto | PlanSeanceAssessmentItemDto;

/**
 * **La séance du jour** : au plus trois entraînements, dans l'ordre, et leur
 * durée totale.
 *
 * C'est une **vue** des priorités et du jalon, pas une seconde source de
 * vérité : chaque item reprend un exercice déjà désigné.
 *
 * 🛑 **Aucune date n'intervient nulle part.** « Aujourd'hui » est une
 * présentation ; une compétence entrée dans la séance y reste tant qu'elle n'est
 * pas réussie. Rien ici ne lit l'horloge — un changement de jour ne peut pas
 * faire oublier une compétence.
 */
export interface PlanSeanceDto {
    /** Dans l'ordre d'exécution. **Jamais `null`**, vide quand le Plan n'a rien
     *  à proposer. */
    items: PlanSeanceItemDto[];
    /** Somme **recalculée** des durées des items ; `0` sur une séance vide. */
    estimatedMinutes: number;
}

/* ------------------------------------------------------- ce qui a changé */

/**
 * Fenêtre sur laquelle le Plan raconte « ce qui a changé ». **C'est le serveur
 * qui la choisit** — la plus courte qui contienne quelque chose de réel.
 * L'écran affiche la période d'après le serveur, jamais d'après ce qu'il croit
 * avoir demandé.
 */
export type PlanRecentChangesWindow = "CETTE_SEMAINE" | "DEUX_SEMAINES" | "CE_MOIS";

/** Libellés FR des fenêtres (**contrat gelé** par `SkillLabelsTest` côté
 *  backend, recopié à la main ici). Ne jamais recopier ces chaînes dans un
 *  composant. */
export const PLAN_RECENT_CHANGES_WINDOW_LABEL: Record<PlanRecentChangesWindow, string> = {
    CETTE_SEMAINE: "Cette semaine",
    DEUX_SEMAINES: "Ces deux dernières semaines",
    CE_MOIS: "Ce mois-ci",
};

/**
 * Une **vraie transition** du moteur de maîtrise sur une compétence :
 * « À renforcer → Solide », « Priorité → En consolidation ».
 *
 * Elle n'est **jamais fabriquée** : elle se mesure en rejouant le moteur sur le
 * même historique, arrêté au début de la fenêtre puis complet.
 *
 * **Une première observation n'est pas une transition** : `before` n'est jamais
 * `null`. Découvrir un niveau est une mesure initiale, pas un changement.
 *
 * 🛑 **Aucun libellé** : les deux états portent déjà les leurs
 * (`SKILL_MASTERY_STATE_LABEL`), le sens de la marche est donné par `progress`,
 * et la phrase appartient aux fronts.
 */
export interface PlanMasteryTransitionDto {
    skillId: string;
    skillCode: string;
    title: string;
    section: SkillSection;
    /** État au début de la fenêtre, **jamais `null`**. */
    before: SkillMasteryState;
    /** État maintenant, jamais `null` et **toujours différent** de `before`. */
    after: SkillMasteryState;
    /** `true` si la compétence a monté dans l'échelle. **Calculé serveur** pour
     *  qu'aucun front n'ait à coder l'ordre des quatre états — trois copies
     *  auraient fini par peindre trois flèches différentes. */
    progress: boolean;
    /** Dernière observation de la compétence, celle qui date le changement. */
    observedAt: string;
}

/**
 * **Ce qui a changé récemment** dans le Plan de ce candidat.
 *
 * 🛑 **Son absence est le cas NORMAL** : quand rien n'a bougé, le bloc vaut
 * `null` et l'écran n'affiche rien. Aucune ligne n'est fabriquée pour remplir,
 * aucun message générique n'existe côté serveur.
 *
 * **À ne pas confondre avec `PlanChangeDto`** : celui-là dit ce qu'**une
 * soumission** a changé (sur le détail d'une production, au grain du verdict
 * d'une observation), celui-ci ce qui a bougé **récemment** (sur le Plan, au
 * grain de l'**état agrégé**). Ils ne peuvent pas se contredire : ils ne parlent
 * pas de la même grandeur.
 */
export interface PlanRecentChangesDto {
    window: PlanRecentChangesWindow;
    /** Borne basse de la fenêtre réellement appliquée. */
    since: string;
    /** De la plus récente à la plus ancienne, bornées. **Jamais `null`**,
     *  éventuellement vide quand seule une nouvelle priorité a été désignée. */
    transitions: PlanMasteryTransitionDto[];
    /** La compétence devenue priorité n°1 **dans cette fenêtre**, ou `null` —
     *  cas fréquent, l'étape n°1 ne change pas à chaque production. */
    newPriority: PlanSkillRefDto | null;
}

export interface LearningPlanDto {
    state: LearningPlanState;
    diagnosticSessionId: string | null;
    diagnosticCompletedAt: string | null;
    /**
     * Les étapes **déjà franchies**, de la plus ancienne à la plus récente :
     * elles se lisent **avant** `currentPriority` et `nextPriorities`, dans le
     * même parcours numéroté.
     *
     * **Jamais `null`** ; **vide** tant qu'aucune compétence n'a prouvé son
     * transfert — cas normal, y compris dans les états `NEEDS_DIAGNOSTIC` et
     * `DIAGNOSTIC_IN_PROGRESS`. Déjà **bornée par le serveur** aux plus
     * récentes : ne rien reborner ici.
     */
    completedSteps: LearningPlanCompletedStepDto[];
    currentPriority: LearningPlanPriorityDto | null;
    nextPriorities: LearningPlanPriorityDto[];
    observedSkills: LearningPlanSkillDto[];
    observedSkillCount: number;
    activitiesThisWeek: number;
    progressionAvailable: boolean;
    /**
     * Le **jalon** du parcours, un cran au-dessus des étapes : un examen blanc
     * d'épreuve puis l'examen blanc TCF complet. Il vit **à côté** des
     * priorités, il ne les remplace pas — chaque étape garde son propre
     * `recommendedExercise`.
     *
     * **`null` est le cas NORMAL** (comme `planChange` ou `versionCiblee`) :
     * rien ne s'affiche, aucun indicateur, aucun message d'erreur. Verrouillé,
     * le jalon reste **désigné** avec son `locked` — le Plan reste
     * intégralement visible, seuls les accès sont fermés.
     */
    milestone: PlanMilestoneExerciseDto | null;
    /**
     * Les **quatre domaines** du TCF — **toujours les quatre**, y compris ceux
     * qui n'ont jamais été mesurés (`evaluated: false`). **Jamais `null`**.
     *
     * 🛑 **L'ordre est décidé par le SERVEUR** : par urgence
     * (`PlanDomainPriority`), et à égalité par l'ordre des épreuves du TCF.
     * **Aucun front ne réordonne, aucun front ne complète les trous** — une
     * liste trouée ferait disparaître de l'écran exactement ce que « Compléter
     * mon profil » doit montrer.
     */
    domaines: PlanDomainDto[];
    /**
     * Le **cycle de palier** en cours : d'où part le candidat, quel palier le
     * Plan construit maintenant, son objectif, et son chemin. Entièrement
     * dérivé, jamais persisté.
     */
    cycle: PlanCycleDto;
    /**
     * **Ce qu'il reste à mesurer, et par quoi** : un item par domaine jamais
     * évalué, avec les paramètres exacts du parcours **déjà existant** à ouvrir.
     * C'est ce qui rend le diagnostic **progressif** — un profil vit à 0, 1, 2,
     * 3 ou 4 domaines mesurés.
     *
     * **Jamais `null`** ; **vide** quand `cycle.profileComplete` — c'est l'état
     * visé, pas une anomalie. Le **compte** (2/4) se lit sur `cycle`, l'état de
     * chaque domaine sur `domaines` : trois surfaces qui compteraient chacune de
     * leur côté auraient fini par se contredire.
     */
    domainesAEvaluer: PlanDomainAssessmentDto[];
    /**
     * **La séance du jour** : au plus trois entraînements, dans l'ordre.
     * **Jamais `null`** ; `items` est vide quand le Plan n'a rien à proposer.
     * C'est une **vue** des priorités et du jalon, jamais une seconde source.
     */
    seance: PlanSeanceDto;
    /**
     * **Ce qui a changé récemment.** 🛑 **`null` est le cas NORMAL** — rien n'a
     * bougé, l'écran n'affiche rien. Aucune ligne n'est fabriquée pour remplir
     * le bloc.
     */
    recentChanges: PlanRecentChangesDto | null;
}

// ============================================================================
// COMPÉTENCES TCF (EE/EO) — micro-exercices ciblés sur UN critère
//
// Voie PARALLÈLE aux productions complètes ci-dessus, et volontairement plus
// pauvre : un petit sujet n'a NI note /20 NI niveau CECRL (interdit par la spec
// §9 — une phrase de 15 mots ne situe pas un candidat sur l'échelle du TCF).
// Le seul verdict est `SkillCriterionStatus`, qui porte sur le critère unique
// du sujet. Miroirs de Skill* côté Java.
// ============================================================================

/**
 * Domaine d'appartenance d'une compétence. Pendant « court » d'`EpreuveType`.
 *
 * **Deux familles, un seul référentiel.** `EE` / `EO` sont les épreuves
 * d'**expression** : une compétence y appartient à l'une des 6 tâches
 * officielles (`SkillTaskCode`) et s'entraîne sur des petits sujets. `CO` / `CE`
 * sont les domaines de **compréhension** : une compétence par palier (`CO-A2`,
 * `CO-B1`, `CO-B2` et leurs jumelles CE), **sans aucune tâche et sans aucun
 * petit sujet** — l'entraînement y est une série ciblée de QCM.
 *
 * C'est cette asymétrie que porte `SkillDto.taskCode`, nullable : le domaine se
 * lit **ici**, le palier sur `targetLevel`, et jamais l'un déduit de l'autre.
 */
export type SkillSection = "EE" | "EO" | "CO" | "CE";

/** Les deux domaines où le candidat **produit** : tâches, petits sujets, IA. */
export type SkillProductionSection = Extract<SkillSection, "EE" | "EO">;

/** Les deux domaines où le candidat **comprend** : ni tâche, ni petit sujet —
 *  une série ciblée de QCM, corrigée de façon déterministe. */
export type SkillComprehensionSection = Extract<SkillSection, "CO" | "CE">;

/** Libellés FR des quatre domaines, miroir de `SkillSection.getLabel()`. */
export const SKILL_SECTION_LABEL: Record<SkillSection, string> = {
    EE: "Expression écrite",
    EO: "Expression orale",
    CO: "Compréhension orale",
    CE: "Compréhension écrite",
};

/** Tâche TCF porteuse des compétences (3 par épreuve). **Expression seule** :
 *  on n'y ajoute jamais de valeur CO/CE, le référentiel des 6 tâches est figé. */
export type SkillTaskCode = "EE1" | "EE2" | "EE3" | "EO1" | "EO2" | "EO3";

/** Les 3 productions de référence livrées avec chaque petit sujet. */
export type SkillReferenceLevel = "INSUFFICIENT" | "EXPECTED" | "EXCELLENT";

/** Ressenti déclaré par le candidat avant validation. Facultatif, et sans
 *  aucune influence sur le verdict IA — c'est un miroir, pas une note. */
export type SkillSelfEvaluation = "REUSSI" | "INCERTAIN" | "DIFFICILE";

/** Verdict de l'IA sur le critère unique du sujet (spec §8). */
export type SkillCriterionStatus = "VALIDATED" | "PARTIAL" | "NOT_VALIDATED";

/** Libellés FR du verdict (contrat gelé — à ne pas reformuler, et à ne pas
 *  recopier dans un composant : c'est cette recopie qui avait fait diverger le
 *  web du mobile). Miroir de l'enum backend `SkillCriterionStatus` et de
 *  `SkillCriterionStatus` côté Flutter ; figé par `lib/skill-labels.test.ts`.
 *
 *  `NOT_VALIDATED` se dit « Critère non atteint » et non « à retravailler » :
 *  cette dernière formulation était quasi synonyme du statut de sujet
 *  `TO_REINFORCE` (« À renforcer ») et mélangeait le verdict d'UNE tentative
 *  avec l'état d'UN sujet. */
export const SKILL_CRITERION_STATUS_LABEL: Record<SkillCriterionStatus, string> = {
    VALIDATED: "Critère validé",
    PARTIAL: "Critère partiellement atteint",
    NOT_VALIDATED: "Critère non atteint",
};

/** Miroir du vrai `enums.Difficulty` Java (EASY/MEDIUM/HARD). Le `Difficulty`
 *  historique de ce fichier ne l'est PAS : il encode un niveau de cible
 *  (CSP/CR/NAT/A2/B1/B2) pour les tags de QCM. Les deux ne se mélangent pas. */
export type SkillDifficulty = "EASY" | "MEDIUM" | "HARD";

/** Libellés FR de la difficulté d'un petit sujet (contrat gelé). « Accessible »
 *  décrit le sujet sans juger celui qui le traite — un sujet annoncé « facile »
 *  puis raté humilie le candidat. */
export const SKILL_DIFFICULTY_LABEL: Record<SkillDifficulty, string> = {
    EASY: "Accessible",
    MEDIUM: "Intermédiaire",
    HARD: "Exigeant",
};

/** Statut d'un petit sujet pour l'utilisateur courant. **Dérivé côté backend**,
 *  jamais recalculé par les fronts. `TREATED` couvre le cas freemium : produit
 *  sans analyse IA, donc sans verdict de critère — « Validé » comme
 *  « À renforcer » y seraient tous les deux faux. */
export type SkillPromptStatus = "TODO" | "TREATED" | "VALIDATED" | "TO_REINFORCE";

/** Cycle de vie d'une tentative. `RECORDED` est un état FINAL : production
 *  enregistrée sans analyse demandée (ou plus autorisée). */
export type SkillAttemptStatut =
    | "RECORDED"
    | "SUBMITTED"
    | "TRANSCRIBING"
    | "EVALUATING"
    | "EVALUATED"
    | "FAILED";

/** Libellés FR des statuts de sujet (contrat gelé — à ne pas reformuler). */
export const SKILL_PROMPT_STATUS_LABEL: Record<SkillPromptStatus, string> = {
    TODO: "À faire",
    TREATED: "Fait",
    VALIDATED: "Validé",
    TO_REINFORCE: "À renforcer",
};

/**
 * Où en est le candidat sur UNE compétence, tout son historique confondu.
 *
 * À ne pas confondre avec `LearningPlanSkillStatus`, qui est le verdict d'**une
 * production**. Celui-ci est l'état **agrégé**, dérivé serveur à la lecture et
 * jamais recalculé ici. `null` quand aucune observation n'existe : on n'invente
 * pas un état pour une compétence que le serveur n'a jamais vue.
 */
export type SkillMasteryState = "PRIORITY" | "TO_REINFORCE" | "CONSOLIDATING" | "SOLID";

/** Libellés FR de l'état de maîtrise (contrat gelé — à ne pas reformuler, et à
 *  recopier au caractère près côté mobile). */
export const SKILL_MASTERY_STATE_LABEL: Record<SkillMasteryState, string> = {
    PRIORITY: "Priorité",
    TO_REINFORCE: "À renforcer",
    CONSOLIDATING: "En consolidation",
    SOLID: "Solide",
};

/** Libellés FR de l'auto-évaluation (contrat gelé — à ne pas reformuler). */
export const SKILL_SELF_EVALUATION_LABEL: Record<SkillSelfEvaluation, string> = {
    REUSSI: "Je pense avoir réussi",
    INCERTAIN: "Je ne suis pas sûr",
    DIFFICILE: "J'ai eu du mal",
};

/** Ordre d'affichage + libellés des onglets de références. */
export const SKILL_REFERENCE_LEVELS: readonly SkillReferenceLevel[] = [
    "INSUFFICIENT",
    "EXPECTED",
    "EXCELLENT",
];

export const SKILL_REFERENCE_LEVEL_LABEL: Record<SkillReferenceLevel, string> = {
    INSUFFICIENT: "Insuffisant",
    EXPECTED: "Attendu",
    EXCELLENT: "Très réussi",
};

/** Où en est le candidat **par rapport au palier qu'il vise**, après une
 *  micro-production. Dérivé serveur (`SkillLevelProgressResolver`) : aucun front
 *  ne déduit la situation d'un niveau et d'un objectif — cette table de
 *  correspondance a déjà existé en six copies divergentes dans le dépôt.
 *
 *  À ne pas confondre avec `SituationDansNiveau`, qui situe une production
 *  **à l'intérieur** de son propre palier (« A2 solide »). */
export type SituationNiveauVise = "OBJECTIF_ATTEINT" | "PROCHE" | "EN_CHEMIN";

/** Libellés FR de la situation (contrat gelé — à ne pas reformuler). Le serveur
 *  envoie déjà `situationLabel` **prêt à afficher** : c'est lui qu'on rend, et
 *  cette table ne sert qu'à garder la copie web alignée sur `SkillLabelsTest`.
 *
 *  Aucun ne nomme un manque : « Encore du chemin » décrit une distance, pas un
 *  échec — le dépôt a retiré le vocabulaire de déficit des cartes de résultat. */
export const SKILL_SITUATION_NIVEAU_VISE_LABEL: Record<SituationNiveauVise, string> = {
    OBJECTIF_ATTEINT: "Tu as atteint ton objectif",
    PROCHE: "Tu es proche du niveau visé",
    EN_CHEMIN: "Encore du chemin vers ton objectif",
};

/** GET /api/skills/progress?section= — une entrée par tâche (EE1→EE3). */
export interface SkillTaskProgressDto {
    taskCode: SkillTaskCode;
    section: SkillSection;
    title: string;
    targetLevel: string;
    skillCount: number;
    promptCount: number;
    /** Sujets ayant au moins une tentative. */
    attemptedCount: number;
    validatedCount: number;
    toReinforceCount: number;
}

/** Une compétence (8 par tâche) + la progression du user courant. */
export interface SkillDto extends SkillLockable {
    id: string;
    section: SkillSection;
    /**
     * Tâche d'appartenance — **`null` sur une compétence de COMPRÉHENSION**
     * (`section` `CO` / `CE`) : celles-ci n'appartiennent à aucune des 6 tâches
     * officielles. Le domaine se lit sur `section`, le palier sur `targetLevel`,
     * **jamais** déduits l'un de l'autre depuis la tâche.
     */
    taskCode: string | null;
    code: string; // "EE1-C1" ou "CO-B1"
    title: string;
    /** Courte explication de ce que l'exercice apporte — encart « Pourquoi cet
     *  exercice ? ». À ne pas rendre au même endroit que `generalCriterion`. */
    description: string;
    /** Critère général travaillé par la compétence — encart « Critère travaillé ».
     *  Distinct de `SkillPromptDto.uniqueCriterion`, qui vise UN petit sujet. */
    generalCriterion: string;
    targetLevel: string;
    displayOrder: number;
    promptCount: number;
    attemptedCount: number;
    validatedCount: number;
    toReinforceCount: number;
    /** Ce que la carte de compétence affiche **à la place** du compteur de
     *  sujets traités : un nombre dit ce qui a été fait, cet état dit ce qui est
     *  maîtrisé. `null` (aucune observation) ⇒ le compteur reprend sa place. */
    masteryState: SkillMasteryState | null;
}

/** Un petit sujet dans la liste d'une compétence. Porte le même `locked` que
 *  `SkillPromptDto` : c'est cette forme-là que sert `GET /api/skills/{id}`,
 *  donc c'est elle qui décide du cadenas dans la liste des 15 sujets. */
export interface SkillPromptSummaryDto extends SkillLockable {
    id: string;
    code: string; // "EE1-C1-S1"
    title: string;
    uniqueCriterion: string;
    difficultyLevel: SkillDifficulty;
    displayOrder: number;
    /** EE — indicatifs, JAMAIS bloquants (spec §8 règle 15). */
    recommendedMinWords: number | null;
    recommendedMaxWords: number | null;
    /** EO — indicatif, jamais bloquant. */
    recommendedDurationSeconds: number | null;
    status: SkillPromptStatus;
    attemptCount: number;
    lastAttemptAt: string | null;
    /**
     * Dernière production du candidat sur ce sujet — l'identifiant qui ouvre son
     * écran de résultat. Même source que `SkillPromptDto.lastAttemptId` : la
     * tentative dont le serveur a déjà dérivé `status`, donc **aucun appel
     * réseau de plus**.
     *
     * `null` quand le sujet n'a jamais été traité — et parfois sur un sujet
     * pourtant marqué traité (ligne héritée) : on retombe alors sur l'entrée
     * directe en production, jamais sur un bouton mort.
     */
    lastAttemptId: string | null;
}

/** Familles d'icônes des étiquettes de contrainte. **Liste fermée**, partagée
 *  telle quelle par le backend, le web, le mobile et l'admin : chaque front la
 *  mappe sur son propre jeu d'icônes.
 *
 *  TONE = registre / politesse · PERSON = destinataire, vouvoiement ·
 *  TIME = moment ou durée · PLACE = lieu · NUMBER = quantité ·
 *  TENSE = temps du récit · STRUCTURE = enchaînement · EXAMPLE = illustration. */
export type SkillConstraintIcon =
    | "TONE"
    | "PERSON"
    | "TIME"
    | "PLACE"
    | "NUMBER"
    | "TENSE"
    | "STRUCTURE"
    | "EXAMPLE";

/** Une contrainte de production, lisible d'un coup d'œil : 1 à 3 mots + son
 *  icône. Dit **comment** produire, jamais **quoi** — et **jamais la longueur**,
 *  qui est dérivée des bornes par le front (`lengthChipLabel`). */
export interface SkillConstraintTagDto {
    label: string;
    icon: SkillConstraintIcon;
}

/** GET /api/skills/{skillId}. */
export interface SkillDetailDto {
    skill: SkillDto;
    prompts: SkillPromptSummaryDto[];
}

/** GET /api/skill-prompts/{promptId} — écran de production. Ne porte JAMAIS
 *  les références : elles n'apparaissent qu'après une tentative (§13.2). */
export interface SkillPromptDto extends SkillLockable {
    id: string;
    skillId: string;
    skillCode: string;
    skillTitle: string;
    /** Nombre de sujets de la compétence — dénominateur du « Sujet i/5 ». Évite
     *  d'appeler `GET /api/skills/{skillId}` juste pour compter. */
    skillPromptCount: number;
    /** `SkillDto.description` recopiée : encart « Pourquoi cet exercice ? ». */
    skillDescription: string;
    /** `SkillDto.generalCriterion` recopié : le critère général de la compétence,
     *  à ne pas confondre avec `uniqueCriterion` (celui de CE sujet). */
    skillGeneralCriterion: string;
    /** Palier CECRL de la compétence (`A1`..`B2`), exigé sur l'écran d'un petit
     *  sujet (spec §3 niveau 5) — porté ici pour ne pas rouvrir un appel à
     *  `GET /api/skills/{skillId}` rien que pour lui. */
    skillTargetLevel: string;
    section: SkillSection;
    taskCode: string;
    taskTitle: string;
    code: string;
    title: string;
    context: string;
    instruction: string;
    uniqueCriterion: string;
    recommendedMinWords: number | null;
    recommendedMaxWords: number | null;
    recommendedDurationSeconds: number | null;
    difficultyLevel: SkillDifficulty;
    displayOrder: number;
    /* ------------------------------------------------------------ guidage
       Les quatre champs ci-dessous sont **tous nullables** : un sujet créé
       depuis la console d'administration peut naître sans guidage, et les
       colonnes DB (V026) sont nullables sur les 240 lignes existantes. Les
       fronts se dégradent — jamais de carte vide, jamais de « null » à
       l'écran. Règles de lecture : `lib/skill-guidance.ts`. */
    /** 2 à 4 gestes à l'impératif, dans l'ordre où les accomplir. */
    checklist: string[] | null;
    /** 1 à 3 contraintes de forme. La longueur n'y figure jamais. */
    constraintTags: SkillConstraintTagDto[] | null;
    /** Amorce de réponse (4-8 mots) : texte grisé du champ à l'écrit,
     *  suggestion de démarrage à l'oral. */
    answerStarter: string | null;
    /** Le geste le plus souvent oublié, en une phrase. Le mot « Astuce : »
     *  n'est **pas** dans la valeur — c'est le front qui l'ajoute. */
    tip: string | null;
    status: SkillPromptStatus;
    attemptCount: number;
    lastAttemptAt: string | null;
    /** Dernière tentative, pour relire / reprendre une ancienne production. */
    lastAttemptId: string | null;
    /** Premier sujet TODO de la MÊME compétence — null s'il n'en reste aucun.
     *  Alimente « Sujet suivant à travailler », qui se désactive alors. */
    nextPromptId: string | null;
}

/** GET /api/skill-prompts/{promptId}/references — 403 tant qu'aucune tentative. */
export interface SkillReferenceDto {
    level: SkillReferenceLevel;
    text: string;
    pedagogicalNote: string;
}

/** Où en est cette production par rapport à l'objectif du candidat.
 *
 *  **Tout est dérivé serveur** : la situation, son libellé, l'échelle de la
 *  jauge et la position du curseur. Un front n'a rien à calculer et surtout rien
 *  à supposer — ni l'ordre des paliers, ni la règle « la démarche fait
 *  plancher ». `scale` porte toujours **3** crans, le dernier étant
 *  `targetLevel` ; `cursorIndex` est toujours dans `0..2`. */
export interface SkillLevelProgressDto {
    /** Niveau démontré par CETTE production. Jamais C1/C2 (profil TCF IRN). */
    levelReached: NiveauCecrl;
    targetLevel: TargetLevel;
    situation: SituationNiveauVise;
    /** Libellé FR prêt à afficher, gelé côté serveur. **À rendre tel quel** :
     *  ne jamais le recomposer depuis `situation`. */
    situationLabel: string;
    scale: NiveauCecrl[];
    cursorIndex: number;
}

/* ---------------------------------------------------------------------------
 * Plan d'action « pour viser X » — briques PARTAGÉES
 *
 * Exactement les mêmes formes des deux côtés : le micro-exercice de compétence
 * ({@link SkillNiveauViseDto}) et la production complète ({@link EeVersionCiblee})
 * sortent du même second appel LLM et rendent le même plan. Deux jeux de types
 * jumeaux auraient divergé au premier champ ajouté — et les composants qui les
 * affichent sont eux aussi partagés (`skill-ui/ActionPlan.tsx`).
 * ------------------------------------------------------------------------- */

/** Un levier : ce qu'on fait, et avec quels mots. */
export interface ActionPlanLevier {
    /** 6 mots maximum, à l'impératif. */
    action: string;
    /** 5 mots maximum, un bout de langue recopiable tel quel. */
    exemple: string;
}

/** Un passage à mettre en évidence dans `ActionPlanExempleCible.texte`.
 *
 *  `extrait` est **garanti sous-chaîne exacte** du texte par le serveur (qui
 *  refuse le bloc entier sinon) : un front peut donc surligner par simple
 *  recherche de chaîne, sans normalisation ni approximation. Introuvable malgré
 *  tout ⇒ on rend le texte brut, jamais d'erreur. */
export interface ActionPlanSegment {
    extrait: string;
    /** Ce qu'il apporte, 3 mots maximum. */
    apport: string;
}

/** La réponse réécrite au niveau visé, et les endroits où se joue la
 *  différence (2 à 3 segments). **Production ÉCRITE seulement.** */
export interface ActionPlanExempleCible {
    texte: string;
    segments: ActionPlanSegment[];
}

/**
 * Un passage de la production **orale**, redit au niveau visé.
 *
 * L'oral n'a **jamais** de texte modèle complet : ce que lit le correcteur est
 * une transcription automatique, en refaire un beau texte tromperait le candidat
 * sur ce qu'il a réellement dit. `original` est le passage exact du candidat,
 * résolu serveur depuis un numéro de segment — aucun entier ne traverse ce
 * contrat.
 */
export interface ActionPlanReformulation {
    original: string;
    reformule: string;
    /** Ce que la reformulation apporte, 3 mots maximum. */
    apport: string;
}

/** La tournure à emporter ailleurs. */
export interface ActionPlanMemo {
    /** 8 mots maximum, écrite comme un patron. */
    formule: string;
    /** 14 mots maximum, quand et pourquoi elle sert. */
    explication: string | null;
}

/** Le plan d'action « pour viser X », produit par un **second appel LLM**
 *  séparé de l'analyse.
 *
 *  Son absence est un **cas NORMAL, jamais une erreur** : objectif déjà atteint,
 *  palier visé inconnu, fournisseur muet, sortie refusée. Aucun front n'affiche
 *  de message d'échec, de spinner ni d'encart d'excuse quand il manque. */
export interface SkillNiveauViseDto {
    /** ⚠️ Le **palier CIBLE** de cet exercice — la marche suivante
     *  (`niveauConstate + 1`, plafonnée à l'objectif de la démarche) —, **pas**
     *  l'objectif lointain du candidat. C'est ce que le texte modèle démontre
     *  réellement, donc ce que l'intertitre nomme (`pourPasserAuTitle`). Le
     *  contrat v2 le rend exigible : longueur bornée par le sujet, et marqueurs
     *  de palier recopiés du texte, vérifiés serveur.
     *
     *  L'objectif du candidat, lui, reste dit par `SkillLevelProgressDto`. */
    niveauVise: TargetLevel;
    niveauConstate: NiveauCecrl | null;
    /** 2 à 3 leviers, du plus rentable au moins rentable. */
    leviers: ActionPlanLevier[] | null;
    /** **Nullable** : la section tombe seule quand son texte est inexploitable,
     *  le reste du bloc restant servi. */
    exempleCible: ActionPlanExempleCible | null;
    /** **Nullable**, même raison. */
    aRetenir: ActionPlanMemo | null;
}

/**
 * Sortie IA d'un micro-exercice. **Aucune note /20**, ici comme avant.
 *
 * **Deux générations de champs, aucune migration** : les analyses persistées
 * sous les contrats v1/v2 portent `successPoint` / `improvementPriority` /
 * `improvedVersion` ; celles produites sous v3 portent `strengthTag` /
 * `focusTag` / `levelProgress` / `niveauVise`. Les deux jeux cohabitent, **tous
 * nullables** : afficher ce qu'on trouve, ne jamais supposer qu'un champ est là.
 */
export interface SkillAnalysisDto {
    status: SkillCriterionStatus;
    verdict: string;
    /** v3 : ce qui est réussi, en 3 mots. Une étiquette, pas une phrase. */
    strengthTag?: string | null;
    /** v3 : l'axe de progrès, en 3 mots. */
    focusTag?: string | null;
    levelProgress?: SkillLevelProgressDto | null;
    niveauVise?: SkillNiveauViseDto | null;
    /** legacy v1/v2 — null sur une analyse v3. */
    successPoint?: string | null;
    /** legacy v1/v2 — null sur une analyse v3. */
    improvementPriority?: string | null;
    /** legacy v1/v2 — null sur une analyse v3. */
    improvedVersion?: string | null;
}

export interface SkillAttemptDto {
    id: string;
    skillPromptId: string;
    skillPromptCode: string;
    statut: SkillAttemptStatut;
    analysisRequested: boolean;
    writtenProduction: string | null;
    /**
     * Durée de l'enregistrement (EO). Seule trace qui subsiste de l'audio : il
     * n'est pas conservé, donc aucune URL n'est servie.
     */
    audioDurationSec: number | null;
    /** Transcription Whisper — LA production orale conservée. */
    transcript: string | null;
    wordsCount: number | null;
    selfEvaluation: SkillSelfEvaluation | null;
    criterionStatus: SkillCriterionStatus | null;
    analysis: SkillAnalysisDto | null;
    errorMessage: string | null;
    createdAt: string;
}

/** Body JSON de POST /api/skill-attempts (section EE). */
export interface SubmitSkillTextRequest {
    skillPromptId: string;
    texte: string;
    selfEvaluation?: SkillSelfEvaluation | null;
    /** False = production enregistrée sans passer par l'IA (statut RECORDED). */
    requestAnalysis: boolean;
    /** Clé d'idempotence tirée par le client (UUID v4). Même règle que pour les
     *  productions complètes : une clé par production, pas par requête. */
    clientSubmissionId?: string;
}

/** GET /api/skills/analysis-quota. `remaining === -1` signifie **illimité** :
 *  aucune surface ne doit afficher cette valeur telle quelle. */
export interface SkillAnalysisQuotaDto {
    premium: boolean;
    unlimited: boolean;
    freeAnalysesTotal: number;
    freeAnalysesUsed: number;
    remaining: number;
}

/** True tant que l'analyse est en vol (le résultat doit être re-poll). */
export function isSkillAttemptPending(a: {statut: SkillAttemptStatut}): boolean {
    return (
        a.statut === "SUBMITTED" ||
        a.statut === "TRANSCRIBING" ||
        a.statut === "EVALUATING"
    );
}

/** Section « compétences » d'une épreuve productive. Rend un domaine
 *  d'**expression** : la compréhension n'a pas d'écran de tâches. */
export function skillSectionOf(epreuve: EpreuveType): SkillProductionSection {
    return epreuve === "TCF_EO" ? "EO" : "EE";
}

/** Code de tâche à partir de la section et du numéro de tâche (1..3).
 *  **Expression uniquement** : une compétence CO/CE n'appartient à aucune tâche. */
export function skillTaskCodeOf(
    section: SkillProductionSection,
    tacheNumero: number,
): SkillTaskCode {
    return `${section}${tacheNumero}` as SkillTaskCode;
}

// ============================================================================
// Expression orale TEMPS RÉEL (examinateur IA, Tâches 1 & 2). Le mode s'ajoute
// au pipeline async : la notation réutilise le même flux (submission + bilan).
// Schéma de connexion (A) : le backend émet un token éphémère, le client ouvre
// lui-même le WebSocket vers le fournisseur (persona verrouillée côté serveur).
// ============================================================================

/** Locuteur d'un fragment de transcript relayé au backend. */
export type RealtimeSpeaker = "CANDIDATE" | "EXAMINER";

/** Mode renvoyé au démarrage : temps réel possible, ou repli enregistrement. */
export type RealtimeMode = "REALTIME" | "ASYNC_FALLBACK";

/** Body de POST /api/realtime/eo/sessions. */
export interface StartRealtimeSessionRequest {
    productionTaskId: string;
    attemptId?: string | null;
}

/** Réponse de POST /api/realtime/eo/sessions. En `ASYNC_FALLBACK`, les champs
 *  de connexion sont absents → le client bascule en enregistrement classique. */
export interface RealtimeSessionDescriptor {
    mode: RealtimeMode;
    sessionId?: string | null;
    provider?: string | null;
    model?: string | null;
    wsEndpoint?: string | null;
    ephemeralToken?: string | null;
    inputAudioMimeType?: string | null;
    inputSampleRate?: number | null;
    outputSampleRate?: number | null;
    voice?: string | null;
    tacheNumero: number;
    targetDurationSec?: number | null;
    sessionsRemaining: number;
    /** La reprise après coupure est armée côté serveur : le client DOIT
     *  mémoriser le dernier handle reçu du fournisseur et le renvoyer (avec ses
     *  fragments de transcript, puis à la reprise) pour rouvrir la MÊME
     *  conversation. Toujours `false` en `ASYNC_FALLBACK`. */
    resumable: boolean;
    /** Reprises encore accordées (`0` = plus de reprise possible). ⚠️ ABSENT du
     *  JSON quand nul (`@JsonInclude(NON_NULL)` côté backend), donc optionnel. */
    resumptionsRemaining?: number | null;
    /** Secondes pendant lesquelles ce token peut encore ouvrir une connexion ;
     *  au-delà, il faut redemander une reprise. ⚠️ Absent du JSON quand nul. */
    connectWindowSec?: number | null;
}

/** Body de POST /api/realtime/eo/sessions/{id}/resume (corps entier facultatif). */
export interface ResumeRealtimeSessionRequest {
    resumptionHandle?: string | null;
}

/** Réponse de GET /api/realtime/eo/quota. */
export interface RealtimeQuotaResponse {
    remaining: number;
    cap: number;
}

/** Réponse de POST /api/realtime/eo/sessions/{id}/finish. */
export interface RealtimeSessionStateResponse {
    sessionId: string;
    status: string;
    tacheNumero: number;
    sessionsRemaining: number;
    /** Vrai si le candidat a parlé → une submission a été créée (résultat à afficher).
     *  Faux si seul l'examinateur a parlé (accueil sans réponse) → rien à évaluer. */
    evaluated: boolean;
}

/** Vrai tant que l'évaluation IA n'a pas abouti. */
export function isSubmissionPending(s: { statut: SubmissionStatut }): boolean {
    return s.statut !== "EVALUATED" && s.statut !== "FAILED";
}

/** Titre éditorial d'une tâche EE (parité `displayTitle` mobile). */
export function eeTaskTitle(tacheNumero: number): string {
    switch (tacheNumero) {
        case 1:
            return "Message simple";
        case 2:
            return "Récit d'expérience";
        case 3:
            return "Point de vue argumenté";
        default:
            return `Tâche ${tacheNumero}`;
    }
}

/** Sous-titre d'une tâche EE. */
export function eeTaskSubtitle(tacheNumero: number): string {
    switch (tacheNumero) {
        case 1:
            return "Rédiger un message court et cohérent";
        case 2:
            return "Raconter une expérience avec clarté";
        case 3:
            return "Justifier une opinion avec des arguments";
        default:
            return "";
    }
}

/** Titre éditorial d'une tâche EO (parité `displayTitle` mobile).
 *  L'ordre suit les tâches réellement servies par le backend
 *  (`production-rubrics` EO_T2 = conduite de l'échange, EO_T3 = point de vue). */
export function eoTaskTitle(tacheNumero: number): string {
    switch (tacheNumero) {
        case 1:
            return "Entretien dirigé";
        case 2:
            return "Jeu de rôle";
        case 3:
            return "Point de vue";
        default:
            return `Tâche ${tacheNumero}`;
    }
}

/** Sous-titre d'une tâche EO. */
export function eoTaskSubtitle(tacheNumero: number): string {
    switch (tacheNumero) {
        case 1:
            return "Se présenter et répondre à des questions";
        case 2:
            return "Interagir et obtenir des informations";
        case 3:
            return "Donner et défendre son opinion";
        default:
            return "";
    }
}

/** Titre d'une tâche selon l'épreuve productive (EE / EO). */
export function productionTaskTitle(epreuve: EpreuveType, tacheNumero: number): string {
    return epreuve === "TCF_EO" ? eoTaskTitle(tacheNumero) : eeTaskTitle(tacheNumero);
}

/**
 * Intitulé d'une tâche **précédé de son rang** — « Tâche 1 : Message simple ».
 *
 * Le rang est un repère du candidat : les consignes, les corrigés et l'examen
 * lui-même parlent de « tâche 1 », « tâche 2 », « tâche 3 ». La pastille
 * numérotée de la carte ne suffit pas à le dire à voix haute.
 *
 * ⚠️ **Miroir mot pour mot du mobile** (`productionTaskLabeledTitle`,
 * `widgets/production_common.dart`) : la forme du préfixe se change des deux
 * côtés dans la même passe.
 */
export function productionTaskLabeledTitle(epreuve: EpreuveType, tacheNumero: number): string {
    return `Tâche ${tacheNumero} : ${productionTaskTitle(epreuve, tacheNumero)}`;
}

/** Sous-titre d'une tâche selon l'épreuve productive (EE / EO). */
export function productionTaskSubtitle(epreuve: EpreuveType, tacheNumero: number): string {
    return epreuve === "TCF_EO" ? eoTaskSubtitle(tacheNumero) : eeTaskSubtitle(tacheNumero);
}

/**
 * Titre affiché en tête d'une **carte de sujet**.
 *
 * Le backend sert un intitulé éditorial (`production_tasks.titre`, V028) —
 * « Message à un ami », « Invitation à un pique-nique » — parce que toutes les
 * consignes d'une même tâche commencent pareil : sans lui, vingt sujets se
 * ressemblent dans la liste.
 *
 * **Le titre peut manquer** (contenu antérieur à V028, sujet créé en console
 * sans titre) : on retombe alors sur l'affichage historique « Sujet N », jamais
 * sur un titre vide ni sur un texte de remplacement. Un titre blanc est traité
 * comme absent — la base l'interdit, mais le repli ne coûte rien.
 *
 * ⚠️ **Libellé gelé**, miroir mot pour mot du mobile (`productionSubjectTitle`,
 * `widgets/production_common.dart`) : un libellé qui bouge, ce sont deux
 * fichiers à changer dans la même passe, et deux tests.
 */
export function productionSubjectTitle(
    titre: string | null | undefined,
    ordre: number,
): string {
    const propre = titre?.trim();
    return propre ? propre : `Sujet ${ordre}`;
}

/**
 * Contrainte **réelle** d'un sujet, telle que servie par l'API : la longueur à
 * l'écrit (`30-60 mots`), la durée à l'oral (`3 min`).
 *
 * `null` quand le champ est absent — **on n'invente jamais une borne** : les
 * bornes EE vivent dans `production_tasks.mots_min/mots_max` côté serveur, et
 * une valeur écrite en dur ici contredirait la consigne donnée au correcteur.
 * Miroir de `productionTaskConstraint` (mobile).
 */
export function productionTaskConstraint(
    task: Pick<ProductionTaskDto, "motsMin" | "motsMax" | "dureeMaxSec">,
    isOral: boolean,
): string | null {
    if (isOral) {
        return task.dureeMaxSec ? formatDurationSec(task.dureeMaxSec) || null : null;
    }
    if (task.motsMin == null || task.motsMax == null) return null;
    return `${task.motsMin}-${task.motsMax} mots`;
}

/** Durée lisible « 1 min 30 » / « 2 min » à partir de secondes. */
export function formatDurationSec(sec: number | null | undefined): string {
    if (sec == null || sec <= 0) return "";
    const m = Math.floor(sec / 60);
    const s = sec % 60;
    if (m === 0) return `${s} s`;
    return s === 0 ? `${m} min` : `${m} min ${s}`;
}

/** Libellé affichable d'un niveau CECRL. */
export function niveauCecrlLabel(n: NiveauCecrl | null | undefined): string {
    if (!n) return "—";
    return n === "A1_NON_ATTEINT" ? "A1 non atteint" : n;
}

/**
 * Forme courte d'un niveau, pour les pastilles et les barres étroites.
 *
 * `A1_NON_ATTEINT` se rend **« <A1 »** : le tronquer en « A1 » annoncerait au
 * candidat un niveau qu'il n'a justement pas atteint. Miroir de
 * `NiveauCecrl.shortName` côté mobile.
 */
export function niveauCecrlShort(n: NiveauCecrl | null | undefined): string {
    if (!n) return "—";
    return n === "A1_NON_ATTEINT" ? "<A1" : n;
}

/** Phrase de correspondance officielle, à afficher au bilan d'une épreuve
 *  entière uniquement. Null quand le backend n'a pas de niveau exploitable. */
export function correspondanceTcfPhrase(
    c: CorrespondanceTcfDto | null | undefined,
): string | null {
    if (!c) return null;
    const plage =
        c.scoreTcfMin === c.scoreTcfMax
            ? `la note de ${c.scoreTcfMin} sur 20`
            : `une note de ${c.scoreTcfMin} à ${c.scoreTcfMax} sur 20`;
    return `Au TCF, le niveau ${niveauCecrlLabel(c.niveau)} correspond à ${plage}.`;
}

/** Position sur l'échelle TCF IRN affichée [A1, A2, B1, B2].
 *  A1_NON_ATTEINT → -1 ; les anciennes valeurs C1/C2 sont plafonnées à B2. */
export function cecrlIndex(n: NiveauCecrl | null | undefined): number {
    switch (n) {
        case "A1_NON_ATTEINT":
            return -1;
        case "A1":
            return 0;
        case "A2":
            return 1;
        case "B1":
            return 2;
        case "B2":
            return 3;
        case "C1":
        case "C2":
            return 3;
        default:
            return -1;
    }
}

// ---- Feedback IA normalisé (le backend renvoie des clés snake_case) ----

export interface EeCriterion {
    code: string;
    label: string;
    noteSurVingt: number;
    /** Null sur une évaluation d'avant la notation v4 : on retombe alors sur
     *  l'affichage chiffré historique plutôt que d'inventer une bande. */
    bande: BandeCritere | null;
    commentaire: string | null;
    /** Citation littérale de la production qui justifie le jugement. */
    preuve: string | null;
}

/** Point de la consigne, traité ou non. `obligatoire: false` = simple piste
 *  suggérée par le sujet : ne pas la traiter n'enlève aucun point. */
export interface EeAccomplishmentPoint {
    libelle: string;
    obligatoire: boolean;
}

/** Verdict d'ensemble sur la tâche (rubriques v8 / tool-schema v5) : ce que le
 *  candidat cherche en premier, avant même sa note. Null sur les évaluations
 *  déjà en base — cas normal, le bandeau n'est alors pas rendu. */
export type ObjectifAccomplissement = "ATTEINT" | "PARTIELLEMENT_ATTEINT" | "NON_ATTEINT";

export interface EeAccomplishment {
    /** Null sur les évaluations antérieures à la grille v8. */
    objectif: ObjectifAccomplissement | null;
    /** Phrase courte adressée au candidat, qui dit ce qu'il a fait. */
    objectifResume: string | null;
    pointsTraites: EeAccomplishmentPoint[];
    pointsOublies: EeAccomplishmentPoint[];
}

export interface EeCorrection {
    original: string;
    corrige: string;
    explication: string | null;
    /** Ce que la reformulation démontre de plus (« emploie une subordonnée
     *  relative, marqueur attendu au B1 »). Absent des évaluations antérieures
     *  à la grille TCF : la correction s'affiche alors sans. */
    gain: string | null;
}

/** Démonstration d'une technique sur la production du candidat. */
export interface EePriorityExample {
    avant: string;
    apres: string;
}

/**
 * Une priorité de progression. Le rapport doit ENSEIGNER : `constat` dit ce qui
 * ne va pas, `comment` la technique réutilisable à appliquer, `exemple` la
 * démontre sur une phrase du candidat.
 *
 * Le serveur normalise cette forme à l'écriture, mais les évaluations déjà en
 * base portent de simples chaînes : elles arrivent ici en `constat` seul, sans
 * `comment` ni `exemple`. Les deux formes sont acceptées à la lecture.
 */
export interface EePriority {
    constat: string;
    comment: string | null;
    exemple: EePriorityExample | null;
}

/**
 * Le **plan d'action** du candidat vers le palier qu'il vise. Produit par un
 * SECOND appel LLM, totalement séparé de la correction (le correcteur n'apprend
 * jamais quel niveau vise le candidat — sinon il alignerait sa note dessus).
 *
 * **EE et EO.** Absent dans tous ces cas parfaitement normaux : évaluations
 * antérieures, second appel en échec, et — à l'oral — transcription trop abîmée
 * pour reformuler quoi que ce soit. Rien ne s'affiche alors : ni squelette, ni
 * « non disponible ».
 *
 * **Trois formes, une seule clé** — on distingue l'écrit de l'oral à la présence
 * de `exempleCible` ou de `reformulations` :
 * - **v2, écrit** : `leviers` + `exempleCible` + `aRetenir` ;
 * - **v2, oral** : `leviers` + `reformulations` + `aRetenir`. **Aucun texte
 *   modèle complet** — la production orale n'est jamais réécrite en entier ;
 * - **v1** (une centaine d'évaluations déjà en base) : `texte` +
 *   `ceQuiManque`, écrit seulement.
 *
 * Quand le palier visé est **déjà atteint**, ce n'est pas ce bloc qui manque :
 * c'est {@link EeNiveauViseAtteint} qui prend sa place. Les deux sont exclusifs.
 */
export interface EeVersionCiblee {
    /** Palier visé : `max(exigé par la démarche, targetLevel déclaré)`, à défaut
     *  celui du sujet. Posé par le serveur (cf. `TargetProcedure.niveauVise`). */
    niveauVise: TargetLevel;
    /** Palier réellement observé sur cette tâche. Absent si inconnu. */
    niveauConstate: NiveauCecrl | null;
    /** v2 : 2 à 3 leviers, **dans l'ordre du backend** (du plus rentable au
     *  moins rentable) : ne jamais retrier côté front. */
    leviers: ActionPlanLevier[];
    /** v2, ÉCRIT : la réponse réécrite au niveau visé, segments surlignables. */
    exempleCible: ActionPlanExempleCible | null;
    /** v2, ORAL : 2 à 3 passages redits au niveau visé. Exclusif du précédent. */
    reformulations: ActionPlanReformulation[];
    /** v2 : la tournure à emporter ailleurs. */
    aRetenir: ActionPlanMemo | null;
    /** v1 (legacy) : le modèle rédigé au niveau visé. **Jamais la production du
     *  candidat.** Null sous le contrat v2. */
    texte: string | null;
    /** v1 (legacy) : les leviers en texte libre, ordre du backend préservé. */
    ceQuiManque: string[];
}

/**
 * **Le palier visé est atteint** — un signal serveur, pas une déduction.
 *
 * Sans lui, un front ne pouvait pas distinguer « objectif atteint » (une
 * victoire, à annoncer) de « le second appel LLM a échoué » (un incident, à
 * taire) : la section modèle disparaissait en silence dans les deux cas, et
 * depuis le retrait de `version_amelioree` le candidat se retrouvait sans aucun
 * texte modèle ni la moindre explication.
 *
 * Exclusif de {@link EeVersionCiblee}. Absent en EO et sur toutes les
 * évaluations antérieures.
 */
export interface EeNiveauViseAtteint {
    /** Le palier que la production atteint (ou dépasse). */
    niveauVise: TargetLevel;
    /** Palier réellement observé sur cette tâche. Absent si inconnu. */
    niveauConstate: NiveauCecrl | null;
}

export interface EeFeedback {
    /** Note /20 à UNE décimale (12,5 et non 13) : c'est la moyenne des quatre
     *  critères, recalculée serveur. */
    noteGlobale: number | null;
    /** Ce que le candidat a traité / oublié de la consigne. Null (et non pas
     *  listes vides) quand l'évaluation ne porte pas l'information. */
    accomplissement: EeAccomplishment | null;
    /** Exactement 4 critères depuis notre grille SejourFR (`communiquer`, `interagir`,
     *  `lexique`, `morphosyntaxe`) — les évaluations plus anciennes en portent
     *  5 aux codes propres à chaque tâche. */
    criteres: EeCriterion[];
    confiance: ConfianceEvaluation | null;
    confianceRaisons: string[];
    /** Limité à 2 côté backend. */
    pointsForts: string[];
    /** Limité à 2 côté backend : ce sont des priorités, pas un inventaire. */
    pointsAAmeliorer: EePriority[];
    suggestions: string[];
    /** Limité à 3 côté backend. */
    exemplesCorriges: EeCorrection[];
    avertissements: string[];
    /** Production réécrite au niveau **déjà constaté**. ⚠️ **N'est plus affichée
     *  nulle part depuis le 2026-08-08** : recopiée puis resoumise, elle rendait
     *  la même note et le même niveau, alors qu'elle était le texte le plus
     *  copiable du rapport. Le champ reste typé parce que l'API le sert encore
     *  (le retirer imposerait une version de tool-schema). Ne pas le rebrancher
     *  dans un composant : le seul modèle affiché est `versionCiblee`. */
    versionAmelioree: string | null;
    /** La même réponse écrite **au palier au-dessus**, celui que le candidat
     *  vise — le seul texte modèle rendu au candidat. */
    versionCiblee: EeVersionCiblee | null;
    /** Exclusif du précédent : le palier visé est **déjà atteint**, et le serveur
     *  le dit pour qu'on l'annonce au lieu de laisser un trou. */
    niveauViseAtteint: EeNiveauViseAtteint | null;
}

function asRecord(v: unknown): Record<string, unknown> | null {
    return v && typeof v === "object" && !Array.isArray(v)
        ? (v as Record<string, unknown>)
        : null;
}

function asStringList(v: unknown): string[] {
    if (!Array.isArray(v)) return [];
    return v.filter((x): x is string => typeof x === "string" && x.trim().length > 0);
}

function asNumber(v: unknown): number | null {
    if (typeof v === "number" && Number.isFinite(v)) return v;
    if (typeof v === "string" && v.trim() !== "" && !Number.isNaN(Number(v))) {
        return Number(v);
    }
    return null;
}

function asString(v: unknown): string | null {
    return typeof v === "string" && v.trim().length > 0 ? v : null;
}

const BANDES: readonly string[] = [
    "TRES_BONNE_MAITRISE",
    "SATISFAISANT",
    "EN_COURS_ACQUISITION",
    "FRAGILE",
    "NON_EVALUABLE",
];

function asBande(v: unknown): BandeCritere | null {
    const s = asString(v)?.toUpperCase();
    return s && BANDES.includes(s) ? (s as BandeCritere) : null;
}

function asConfiance(v: unknown): ConfianceEvaluation | null {
    const s = asString(v)?.toUpperCase();
    return s === "HAUTE" || s === "MOYENNE" || s === "FAIBLE" ? s : null;
}

function asTargetLevel(v: unknown): TargetLevel | null {
    const s = asString(v)?.toUpperCase();
    return s === "A2" || s === "B1" || s === "B2" ? s : null;
}

const NIVEAUX_CECRL: readonly string[] = [
    "A1_NON_ATTEINT",
    "A1",
    "A2",
    "B1",
    "B2",
    "C1",
    "C2",
];

function asNiveauCecrl(v: unknown): NiveauCecrl | null {
    const s = asString(v)?.toUpperCase();
    return s && NIVEAUX_CECRL.includes(s) ? (s as NiveauCecrl) : null;
}

/** Un levier v2 : les deux champs sont exigés, un demi-levier ne s'applique pas. */
function asActionLeviers(v: unknown): ActionPlanLevier[] {
    if (!Array.isArray(v)) return [];
    return v.flatMap((item) => {
        const r = asRecord(item);
        const action = asString(r?.action);
        const exemple = asString(r?.exemple);
        return action && exemple ? [{action, exemple}] : [];
    });
}

function asActionSegments(v: unknown): ActionPlanSegment[] {
    if (!Array.isArray(v)) return [];
    return v.flatMap((item) => {
        const r = asRecord(item);
        const extrait = asString(r?.extrait);
        const apport = asString(r?.apport);
        return extrait && apport ? [{extrait, apport}] : [];
    });
}

/** Bloc `exemple_cible` (contrat v2, ÉCRIT). Sans texte, il n'y a rien à
 *  montrer ; les segments, eux, ne sont qu'un surlignage — leur absence dégrade
 *  sans rien casser. */
function asActionExempleCible(v: unknown): ActionPlanExempleCible | null {
    const r = asRecord(v);
    const texte = asString(r?.texte);
    if (!texte) return null;
    return {texte, segments: asActionSegments(r?.segments)};
}

/** Bloc `reformulations` (contrat v2, ORAL). `original` est posé par le SERVEUR
 *  (numéro de segment déjà résolu en texte) : aucun entier n'arrive ici. */
function asActionReformulations(v: unknown): ActionPlanReformulation[] {
    if (!Array.isArray(v)) return [];
    return v.flatMap((item) => {
        const r = asRecord(item);
        const original = asString(r?.original);
        const reformule = asString(r?.reformule);
        const apport = asString(r?.apport);
        return original && reformule && apport ? [{original, reformule, apport}] : [];
    });
}

/** Bloc `a_retenir` (contrat v2). La formule seule suffit : l'explication est
 *  un complément, elle ne conditionne pas l'affichage. */
function asActionMemo(v: unknown): ActionPlanMemo | null {
    const r = asRecord(v);
    const formule = asString(r?.formule);
    if (!formule) return null;
    return {formule, explication: asString(r?.explication)};
}

/**
 * Bloc `version_ciblee`, ou `null` dès qu'il manque de quoi l'afficher
 * honnêtement : sans palier visé on ne saurait pas au nom de quoi ce plan est
 * montré, et sans la moindre section il n'y a rien à montrer.
 *
 * Les trois formes du contrat sont lues ici (v2 écrit, v2 oral, v1) : les
 * évaluations déjà en base gardent la forme qu'elles avaient, rien n'est migré.
 * L'ordre des leviers est **préservé** — le backend les trie du plus rentable au
 * moins rentable.
 */
function asVersionCiblee(v: unknown): EeVersionCiblee | null {
    const r = asRecord(v);
    if (!r) return null;
    const niveauVise = asTargetLevel(r.niveau_vise);
    if (!niveauVise) return null;

    const leviers = asActionLeviers(r.leviers);
    const exempleCible = asActionExempleCible(r.exemple_cible);
    const reformulations = asActionReformulations(r.reformulations);
    const aRetenir = asActionMemo(r.a_retenir);
    const texte = asString(r.texte);
    const ceQuiManque = asStringList(r.ce_qui_manque);

    const vide =
        leviers.length === 0 &&
        !exempleCible &&
        reformulations.length === 0 &&
        !aRetenir &&
        !texte &&
        ceQuiManque.length === 0;
    if (vide) return null;

    return {
        niveauVise,
        niveauConstate: asNiveauCecrl(r.niveau_constate),
        leviers,
        exempleCible,
        reformulations,
        aRetenir,
        texte,
        ceQuiManque,
    };
}

/** Bloc `niveau_vise_atteint`. Sans palier visé, il n'y a rien à féliciter :
 *  `null`, et la section n'est pas rendue. */
function asNiveauViseAtteint(v: unknown): EeNiveauViseAtteint | null {
    const r = asRecord(v);
    if (!r) return null;
    const niveauVise = asTargetLevel(r.niveau_vise);
    if (!niveauVise) return null;
    return {niveauVise, niveauConstate: asNiveauCecrl(r.niveau_constate)};
}

function asObjectif(v: unknown): ObjectifAccomplissement | null {
    const s = asString(v)?.toUpperCase();
    return s === "ATTEINT" || s === "PARTIELLEMENT_ATTEINT" || s === "NON_ATTEINT" ? s : null;
}

/** `obligatoire` manquant → point traité comme exigé : on ne minimise jamais
 *  un manque, alors qu'une piste est explicitement marquée `false`. */
function asAccomplishmentPoints(v: unknown): EeAccomplishmentPoint[] {
    if (!Array.isArray(v)) return [];
    return v
        .map((item): EeAccomplishmentPoint | null => {
            const r = asRecord(item);
            const libelle = r ? asString(r.libelle) : null;
            if (!r || !libelle) return null;
            return {libelle, obligatoire: r.obligatoire !== false};
        })
        .filter((p): p is EeAccomplishmentPoint => p !== null);
}

/**
 * Accepte les DEUX formes de `points_a_ameliorer` : l'objet
 * `{constat, comment, exemple}` de la grille TCF, et la simple chaîne des
 * évaluations déjà en base (qui devient un `constat` seul). Le serveur
 * normalise à l'écriture — on ne le présume pas à la lecture d'un ancien
 * enregistrement.
 */
function asPriorities(v: unknown): EePriority[] {
    if (!Array.isArray(v)) return [];
    return v
        .map((item): EePriority | null => {
            if (typeof item === "string") {
                const constat = item.trim();
                return constat ? {constat, comment: null, exemple: null} : null;
            }
            const r = asRecord(item);
            if (!r) return null;
            const constat = asString(r.constat) ?? asString(r.libelle) ?? asString(r.texte);
            if (!constat) return null;
            const ex = asRecord(r.exemple);
            const avant = ex ? asString(ex.avant) : null;
            const apres = ex ? asString(ex.apres) : null;
            return {
                constat,
                comment: asString(r.comment),
                exemple: avant && apres ? {avant, apres} : null,
            };
        })
        .filter((p): p is EePriority => p !== null);
}

/**
 * Normalise le `feedback` JSONB d'une {@link EvaluationResultDto} en structure
 * typée prête à l'affichage. Tolérant aux variations de clés (`justification`
 * vs `commentaire`, valeurs manquantes) pour rester robuste aux versions de
 * prompt IA.
 */
export function parseEeFeedback(
    evaluation: EvaluationResultDto | null | undefined,
): EeFeedback {
    const empty: EeFeedback = {
        noteGlobale: evaluation?.noteSurVingt ?? null,
        accomplissement: null,
        criteres: [],
        confiance: evaluation?.confiance ?? null,
        confianceRaisons: [],
        pointsForts: [],
        pointsAAmeliorer: [],
        suggestions: [],
        exemplesCorriges: [],
        avertissements: [],
        versionAmelioree: null,
        versionCiblee: null,
        niveauViseAtteint: null,
    };
    const fb = asRecord(evaluation?.feedback);
    if (!fb) return empty;

    const criteresRaw = Array.isArray(fb.scores_criteres) ? fb.scores_criteres : [];
    const criteres: EeCriterion[] = criteresRaw
        .map((c): EeCriterion | null => {
            const r = asRecord(c);
            if (!r) return null;
            const code = asString(r.code) ?? "";
            const note = asNumber(r.note_sur_20);
            return {
                code,
                label: asString(r.label) ?? eeCriterionLabel(code),
                noteSurVingt: note ?? 0,
                bande: asBande(r.bande),
                commentaire: asString(r.justification) ?? asString(r.commentaire),
                preuve: asString(r.preuve),
            };
        })
        .filter((c): c is EeCriterion => c !== null);

    const accRaw = asRecord(fb.accomplissement);
    const accomplissement: EeAccomplishment | null = accRaw
        ? {
              objectif: asObjectif(accRaw.objectif),
              objectifResume: asString(accRaw.objectif_resume),
              pointsTraites: asAccomplishmentPoints(accRaw.points_traites),
              pointsOublies: asAccomplishmentPoints(accRaw.points_oublies),
          }
        : null;

    const correctionsRaw = Array.isArray(fb.exemples_corriges) ? fb.exemples_corriges : [];
    const exemplesCorriges: EeCorrection[] = correctionsRaw
        .map((e): EeCorrection | null => {
            const r = asRecord(e);
            if (!r) return null;
            const original = asString(r.original);
            const corrige = asString(r.corrige);
            if (!original && !corrige) return null;
            return {
                original: original ?? "",
                corrige: corrige ?? "",
                explication: asString(r.explication),
                gain: asString(r.gain),
            };
        })
        .filter((e): e is EeCorrection => e !== null);

    return {
        noteGlobale: asNumber(fb.note_globale) ?? empty.noteGlobale,
        accomplissement,
        criteres,
        confiance: empty.confiance ?? asConfiance(fb.confiance),
        confianceRaisons: asStringList(fb.confiance_raisons),
        pointsForts: asStringList(fb.points_forts),
        pointsAAmeliorer: asPriorities(fb.points_a_ameliorer),
        suggestions: asStringList(fb.suggestions),
        exemplesCorriges,
        avertissements: asStringList(fb.avertissements),
        versionAmelioree: asString(fb.version_amelioree),
        versionCiblee: asVersionCiblee(fb.version_ciblee),
        niveauViseAtteint: asNiveauViseAtteint(fb.niveau_vise_atteint),
    };
}

/** Libellé de repli pour un critère EE/EO si le backend n'a pas fourni `label`
 *  (il le fournit depuis la rubrique de la tâche : cette table n'est qu'un
 *  filet, jamais la source). Les quatre premiers codes sont ceux de notre grille
 *  SejourFR, identiques sur les six tâches ; tous les suivants restent portés par
 *  les évaluations déjà en base. */
export function eeCriterionLabel(code: string): string {
    switch (code) {
        // --- notre grille : les 4 critères équipondérés des six tâches ---
        case "communiquer":
            return "Communiquer : accomplir la tâche et enchaîner les idées";
        case "interagir":
            return "Interagir : adaptation à la situation et au destinataire";
        case "lexique":
            return "Lexique : vocabulaire approprié";
        case "morphosyntaxe":
            return "Morphosyntaxe : correction grammaticale";
        // --- codes par tâche, portés par les évaluations antérieures ---
        case "realisation_consigne":
            return "Réalisation de la consigne";
        case "adequation_destinataire":
            return "Adéquation au destinataire et au registre";
        case "chronologie_recit":
            return "Chronologie et repères temporels";
        case "prise_position":
            return "Prise de position claire";
        case "argumentation":
            return "Justification et développement des arguments";
        case "conduite_echange":
            return "Conduite de l'échange";
        case "developpement_reponses":
            return "Développement des réponses";
        case "vocabulaire":
            return "Étendue et maîtrise du lexique";
        case "coherence":
        case "organisation":
            return "Cohérence et organisation";
        // --- codes hérités (évaluations antérieures) ---
        case "pertinence":
            return "Pertinence et développement du contenu";
        case "grammaire":
            return "Correction grammaticale";
        case "orthographe":
            return "Orthographe et ponctuation";
        case "clarte_ecrite":
            return "Clarté de l'expression écrite";
        default:
            return code ? code.charAt(0).toUpperCase() + code.slice(1).replace(/_/g, " ") : "Critère";
    }
}

/**
 * Libellé affichable d'une bande de critère : **le palier atteint, pas un
 * déficit**.
 *
 * Les bornes des bandes (10 / 6 / 2) sont exactement celles des paliers du TCF.
 * Conséquence structurelle du vocabulaire précédent (« En cours d'acquisition »,
 * « Fragile ») : la bande d'un candidat A2 était son niveau CECRL renommé en
 * échec, et **aucune production ne pouvait lui faire afficher autre chose**. On
 * nomme donc la bande par ce qu'elle est.
 *
 * ⚠️ Contrat gelé, écrit à la main sur les deux fronts (le réseau ne transporte
 * que l'enum) : miroir mot pour mot de `BandeCritere.displayName`
 * (`mobile_sejourfr/lib/core/models/enums.dart`), verrouillé des deux côtés par
 * test. Un libellé qui bouge, ce sont deux fichiers + deux tests dans la même
 * passe.
 */
export function bandeCritereLabel(b: BandeCritere): string {
    switch (b) {
        case "TRES_BONNE_MAITRISE":
            return "Niveau B2";
        case "SATISFAISANT":
            return "Niveau B1";
        case "EN_COURS_ACQUISITION":
            return "Niveau A2";
        case "FRAGILE":
            return "Niveau A1";
        case "NON_EVALUABLE":
            return "Non évaluable";
    }
}

/** Note /20 telle qu'on l'affiche partout : les notes portent UNE décimale
 *  (12,5), rendue à la française et masquée quand elle est nulle (13, pas
 *  13,0). Un arrondi à l'entier changerait la note affichée. */
export function formatNoteSur20(n: number): string {
    return Number.isInteger(n) ? String(n) : n.toFixed(1).replace(".", ",");
}

/** Libellé affichable d'un degré de confiance. */
export function confianceLabel(c: ConfianceEvaluation): string {
    switch (c) {
        case "HAUTE":
            return "confiance haute";
        case "MOYENNE":
            return "confiance moyenne";
        case "FAIBLE":
            return "confiance faible";
    }
}

// ============ STATS ============
export interface ThemeStatsResponse {
    themeId: string;
    themeName: string;
    answered: number;
    correct: number;
    total: number;
}

export interface UserStatsResponse {
    attemptsTotal: number;
    questionsAnswered: number;
    questionsCorrect: number;
    successRate: number; // 0..1
    byTheme: ThemeStatsResponse[];
}

/** Une catégorie du dashboard (GET /api/me/dashboard). */
export interface DashboardCategoryStat {
    /** Null pour les entrées synthétiques EE/EO. */
    themeId: string | null;
    /** Code stable : theme.code (CIV_PRINCIPES, TCF_CO…) ou TCF_EE / TCF_EO. */
    code: string;
    label: string;
    /** Progression 0-100 = réussite × confiance (confiance = min(1,
     *  répondues / min(40, pool)) ; EE/EO : moyenne des 3 dernières notes /20
     *  ×5 × min(1, n/3)). Null si jamais travaillé. */
    percent: number | null;
    answered: number;
    /** Pool de questions actives — 0 pour EE/EO. */
    total: number;
    /** Examens blancs finis scopés à la catégorie (0 pour EE/EO). */
    mockExams: number;
    /** Record / dernier / avant-dernier score brut sur les examens de la
     *  catégorie (page Progression). Null si pas assez d'examens. */
    bestMockScore: number | null;
    lastMockScore: number | null;
    prevMockScore: number | null;
    /** Dernier niveau CECRL évalué — EE/EO uniquement. */
    level: NiveauCecrl | null;
}

/**
 * Un domaine du profil TCF d'un candidat : l'épreuve, le fait qu'elle ait été
 * évaluée, et le niveau estimé quand elle l'a été.
 *
 * `evaluated === false` ⇔ `niveau === null` : le domaine n'a jamais été
 * réellement passé, donc son niveau est **inconnu** — jamais `A1_NON_ATTEINT`.
 * Les fronts affichent « Pas encore évaluée » et **ne dérivent aucun niveau** :
 * il est calculé serveur.
 */
export interface TcfDomainDto {
    epreuve: Extract<EpreuveType, "TCF_CO" | "TCF_CE" | "TCF_EO" | "TCF_EE">;
    evaluated: boolean;
    niveau: NiveauCecrl | null;
}

/**
 * Profil TCF **domaine par domaine** : ce que « Mon profil TCF » affiche, et ce
 * dont « Compléter mon profil » déduit les domaines manquants.
 *
 * C'est la **publication** du même niveau que les trois scalaires
 * `estimatedTcfLevel*` ci-dessous, pas un second calcul : ils disent la même
 * chose en plus court et restent servis à côté.
 *
 * 🛑 **L'ordre des domaines est FIGÉ CÔTÉ SERVEUR** — CO · CE · EO · EE, l'ordre
 * des épreuves du TCF — et la liste en porte **toujours 4**, un domaine jamais
 * passé étant présent avec `evaluated: false`. **Aucun front ne réordonne,
 * aucun front ne complète les trous.**
 */
export interface TcfDomainProfileDto {
    /** Les 4 domaines, ordre figé CO · CE · EO · EE. */
    domaines: TcfDomainDto[];
    /** Plancher des domaines évalués, `null` si aucun. */
    globalLevel: NiveauCecrl | null;
    /** Nombre de domaines évalués (0..4). */
    evaluated: number;
    /** 4, toujours. */
    expected: number;
    /** Niveau global établi sur une partie seulement des domaines. */
    partial: boolean;
}

/** GET /api/me/dashboard — agrégat unique du tableau de bord web. */
export interface DashboardSummaryResponse {
    currentStreakDays: number;
    recordStreakDays: number;
    activeToday: boolean;
    mockExamsTotal: number;
    /** Totaux par module (TCF : sous-attempts d'examen complet exclus). */
    civiqueMockExams: number;
    tcfMockExams: number;
    /** Progression globale = moyenne des progressions des catégories renseignées. */
    globalSuccessPercent: number | null;
    /**
     * Niveau TCF **estimé** du candidat : plancher des 4 épreuves (CO/CE/EE/EO),
     * chacune retenant son **meilleur** résultat, une épreuve abandonnée sans
     * rien rendre (0 réponse / 0 soumission) étant **exclue**. Null tant
     * qu'aucune épreuve n'a été réellement passée — null = inconnu, jamais
     * mauvais. Dérivé serveur (`TcfProfileService`) : ne jamais le recalculer
     * côté front.
     */
    estimatedTcfLevel: NiveauCecrl | null;
    /**
     * **Périmètre** de `estimatedTcfLevel` : combien d'épreuves ont réellement
     * pesé (0..4), sur combien, et si ça n'en fait pas le tour.
     *
     * Même contrat que `epreuvesCountedInFinalLevel` / `epreuvesExpected` /
     * `finalLevelPartial` d'un examen blanc complet, et même raison : un
     * candidat qui n'a passé que l'expression écrite lisait « Niveau TCF
     * estimé : B1 » sur la foi d'**une** épreuve sur quatre. Dérivé serveur —
     * **ne jamais recompter** côté front.
     */
    estimatedTcfLevelEpreuvesCounted: number;
    estimatedTcfLevelEpreuvesExpected: number;
    /** Au moins une épreuve comptée, mais pas les quatre. À zéro épreuve le
     *  niveau vaut déjà `null` (« — ») : il n'y a rien à annoter. */
    estimatedTcfLevelPartial: boolean;
    /**
     * Le **même** niveau, publié **domaine par domaine** (CO · CE · EO · EE)
     * pour l'écran « Mon profil TCF » et le bloc « Compléter mon profil ». Les
     * trois scalaires ci-dessus en sont le résumé — pas une seconde source.
     * Liste **toujours de 4**, **ordre figé côté serveur**.
     */
    tcfDomainProfile: TcfDomainProfileDto;
    civique: DashboardCategoryStat[];
    tcf: DashboardCategoryStat[];
}

/**
 * Ce qu'on écrit **sous** un niveau TCF estimé qui ne porte pas sur les quatre
 * épreuves.
 *
 * Une seule chaîne, courte, la même sur toutes les surfaces (dashboard, profil,
 * statistiques, hub TCF, examens blancs) et **au caractère près** identique au
 * mobile (`estimatedTcfLevelScopeLabel`, `core/models/dashboard_models.dart`).
 * Elle tient dans la légende d'une carte de statistique à 360 px, ce qui est la
 * vraie contrainte : une phrase longue n'aurait pas pu être la même partout, et
 * deux formulations auraient divergé au premier retouche.
 *
 * ⚠️ Règle de ton : elle **constate un périmètre**, elle ne reproche pas un
 * inachèvement. « D'après 1 épreuve sur 4 » dit ce qu'on sait ; « il vous manque
 * 3 épreuves » dirait au candidat qu'il est en retard. Et **aucun chiffre de
 * barème** n'y apparaît — un décompte d'épreuves n'en est pas un.
 *
 * `null` quand il n'y a rien à annoter : niveau complet (4/4) ou inconnu (0/4,
 * l'écran affiche déjà « — »).
 */
export function estimatedTcfLevelScopeLabel(
    summary: Pick<
        DashboardSummaryResponse,
        "estimatedTcfLevelPartial" | "estimatedTcfLevelEpreuvesCounted" | "estimatedTcfLevelEpreuvesExpected"
    > | null | undefined,
): string | null {
    if (!summary?.estimatedTcfLevelPartial) return null;
    const counted = summary.estimatedTcfLevelEpreuvesCounted;
    const expected = summary.estimatedTcfLevelEpreuvesExpected;
    if (counted <= 0 || expected <= 0) return null;
    return `D'après ${counted} épreuve${counted > 1 ? "s" : ""} sur ${expected}`;
}

// ============ HELPERS ============

/**
 * **La correspondance démarche → palier de français, une seule fois.**
 *
 * Seuils en vigueur au 1ᵉʳ janvier 2026 (loi n° 2024-42, décrets 2025-647 et
 * 2025-648, arrêté du 22 décembre 2025). Donnée légale de trois lignes, pas un
 * réglage : c'est un **miroir gelé par test** (`lib/target-level.test.ts`) de l'enum
 * `TargetProcedure` côté backend, comme `skill-labels` l'est des libellés
 * Compétences.
 *
 * ⚠️ **Ne jamais réécrire cette table dans un écran.** Elle a vécu en trois
 * copies web (`/parcours`, `/inscription`, `/profil`), et le jour où la loi
 * bougera, ces copies ne bougeront pas.
 */
export const TCF_LEVEL_BY_PROCEDURE: Readonly<Record<TargetProcedure, TargetLevel>> = {
    CSP: "A2",
    CR: "B1",
    NAT: "B2",
};

/** Le palier que la démarche **exige**. `null` si la démarche n'est pas choisie —
 *  on ne devine jamais un parcours à la place du candidat. */
export function tcfLevelFromProcedure(
    p: TargetProcedure | null | undefined,
): TargetLevel | null {
    return p ? TCF_LEVEL_BY_PROCEDURE[p] : null;
}

/** Rang CECRL d'un palier visé : c'est lui qu'on compare, jamais l'ordre
 *  alphabétique (juste par chance aujourd'hui, faux dès qu'un palier s'ajoute). */
const TARGET_LEVEL_RANK: Readonly<Record<TargetLevel, number>> = {A2: 0, B1: 1, B2: 2};

/**
 * **Le palier réellement VISÉ** : le plus haut entre ce que la démarche exige et
 * ce que le candidat a déclaré viser. Miroir de `TargetProcedure.niveauVise`
 * côté backend, gelé par test.
 *
 * La démarche fait **plancher**, jamais plafond :
 * - `NAT` + `B1` déclaré ⇒ **B2** (la naturalisation en demande un de plus : le
 *   féliciter d'avoir « atteint son objectif » à B1 ne le tirerait jamais vers
 *   le niveau dont il a besoin) ;
 * - `CSP` + `B2` déclaré ⇒ **B2** (viser plus haut est un choix légitime) ;
 * - démarche absente ⇒ le niveau déclaré seul ; les deux absents ⇒ `null`.
 *
 * Le backend sert déjà `targetLevel` corrigé sur `/api/auth/me` : ce helper est
 * la ceinture qui va avec les bretelles, et il sert aux écrans où la démarche
 * n'est **pas encore enregistrée** (sélection sur `/parcours`, `/inscription`).
 */
export function niveauViseTcf(
    user: Pick<AuthenticatedUser, "targetLevel" | "targetProcedure"> | null | undefined,
): TargetLevel | null {
    const exige = tcfLevelFromProcedure(user?.targetProcedure);
    const declare = user?.targetLevel ?? null;
    if (!exige) return declare;
    if (!declare) return exige;
    return TARGET_LEVEL_RANK[declare] > TARGET_LEVEL_RANK[exige] ? declare : exige;
}

/** Niveau TCF effectif d'un utilisateur, **avec repli B1** : sert à piocher les
 *  tâches EO/EE, jamais à écrire une phrase au candidat (un objectif deviné n'a
 *  rien à faire dans un message qui lui dit ce qu'il joue). */
export function resolveTcfLevel(
    user: Pick<AuthenticatedUser, "targetLevel" | "targetProcedure"> | null,
): TargetLevel {
    return niveauViseTcf(user) ?? "B1";
}

export function canAccessModule(
    user: Pick<AuthenticatedUser, "hasCivique" | "hasTcf"> | null,
    module: Module,
): boolean {
    if (!user) return false;
    if (module === "CIVIQUE") return user.hasCivique ?? false;
    return user.hasTcf ?? false;
}

// ============ ERREURS API ============
export interface ApiError {
    status: number;
    error: string;
    message: string;
    path?: string;
    timestamp?: string;
    fieldErrors?: Record<string, string>;
}

// ============================================================================
// Billing : statut Premium + résiliation
// ============================================================================

export type SubscriptionSource = "STRIPE" | "APPLE" | "GOOGLE";

export type SubscriptionStatus =
    | "ACTIVE"
    | "TRIAL"
    | "IN_GRACE"
    | "PENDING"
    | "CANCELED"
    | "EXPIRED"
    | "REFUNDED";

/** Statut Premium agrégé toutes sources (Stripe + Apple + Google). Renvoyé
 * par `GET /api/billing/subscription-status`. Source de vérité unique côté
 * backend — le client NE décide PAS du Premium. */
export interface SubscriptionStatusResponse {
    isPremium: boolean;
    source: SubscriptionSource | null;
    productId: string | null;
    expiresAt: string | null;
    status: SubscriptionStatus | null;
    moduleAccess: ModuleAccess;
    autoRenew: boolean;
    /** True si l'accès vient d'un pass one-time (lot 5) : « Mon accès » sans
     *  résiliation. Absent (undefined) sur les anciens backends → traiter false. */
    oneTime?: boolean;
    /** Sessions d'expression orale TEMPS RÉEL restantes sur le pass courant
     *  (examinateur IA, T1/T2). Null/absent si non concerné (compte gratuit ou
     *  pass sans accès TCF). Le quota est configuré côté backend. */
    realtimeSessionsRemaining?: number | null;
}

/** Réponse de `POST /api/billing/cancel`. Deux variantes :
 * - `DONE` : Stripe a enregistré la résiliation côté serveur (Premium reste
 *   ouvert jusqu'à `expiresAt`).
 * - `REDIRECT` : Apple/Google n'autorisent pas l'annulation serveur ; le
 *   `redirectUrl` pointe vers la page de gestion d'abonnement du store. */
export interface CancelSubscriptionResponse {
    action: "DONE" | "REDIRECT";
    message: string;
    redirectUrl: string | null;
}

/** Réponse de `DELETE /api/account` (suppression de compte).
 * La suppression aboutit toujours (`deleted=true`, anonymisation côté serveur) ;
 * `manualActionMessage` n'est rempli que si un abonnement Apple/Google reste à
 * résilier manuellement dans le store. */
export interface AccountDeletionResponse {
    deleted: boolean;
    hasActiveSubscription: boolean;
    subscriptionProvider: string | null;
    manualActionMessage: string | null;
}

// ============================================================================
// EXAMEN BLANC TCF COMPLET (TCF_COMPLET) — orchestration CO → CE → EE → EO
// Miroirs de FullTcfExamResponse / FullTcfExamSummaryResponse côté Java
// (controller FullTcfExamController). Le parent TCF_COMPLET porte 4
// sous-attempts, l'évaluation IA des productions EE/EO tourne en arrière-plan.
// ============================================================================

/** Statut agrégé d'un examen complet (cf. FullTcfExamResponse.FullTcfExamStatus).
 *  IN_PROGRESS : au moins une épreuve pas terminée. PENDING_EVALUATIONS : les 4
 *  terminées mais l'IA EE/EO n'a pas fini. COMPLETED : tout évalué,
 *  `finalCecrlLevel` posé (plancher des 4 épreuves). */
export type FullTcfExamStatus = "IN_PROGRESS" | "PENDING_EVALUATIONS" | "COMPLETED";

/** Une sous-épreuve de l'examen complet. `finishedAt` non nul = terminée. Pour
 *  CO/CE : `score`/`maxScore` (QCM). Pour EE/EO : `submissionsCount` (tâches
 *  EVALUATED sur 3) + `failedSubmissionIds` (à relancer). `cecrlLevel` apparaît
 *  une fois l'épreuve évaluée. `locked` (EE/EO seulement) : épreuve verrouillée
 *  pour un compte gratuit ayant déjà utilisé l'EE/EO offerte une fois — pré-
 *  terminée, comptée A1_NON_ATTEINT ; afficher un cadenas + invitation à
 *  l'abonnement plutôt qu'un état « non passé ». */
export interface FullTcfExamSubAttempt {
    attemptId: string;
    epreuve: EpreuveType;
    finishedAt: string | null;
    cecrlLevel: NiveauCecrl | null;
    /** Score **pondéré interne** (A2=1, B1=2, B2=3) et sa borne. Conservés
     *  comme repli — ce n'est pas ce qu'on affiche à un candidat, « 23/50 » ne
     *  correspond à rien sur son relevé. */
    score: number | null;
    maxScore: number | null;
    /** CO/CE : score calibré **100-499**, l'échelle du relevé TCF. Dérivé
     *  serveur (`TcfLevelEstimatorService`, correction du hasard comprise) :
     *  ne jamais le recalculer depuis `score`/`maxScore`. **C'est ce que les
     *  écrans affichent.** Null pour EE/EO, pour une épreuve verrouillée et
     *  tant que le score pondéré n'est pas posé — on retombe alors sur
     *  `score`/`maxScore`, jamais sur un `/499` inventé. */
    calibratedScore: number | null;
    submissionsCount: number | null;
    failedSubmissionIds: string[];
    locked: boolean;
    /** Chrono PROPRE de l'épreuve, en secondes : 1200 CO, 2100 CE, 1800 EE.
     *  **Null en EO** (l'oral se chronomètre par tâche, au lancement de chaque
     *  tâche) et null sur une épreuve verrouillée. Le temps d'une épreuve ne se
     *  transfère jamais à la suivante — il n'y a plus de chrono global. */
    timeLimitSeconds: number | null;
    /** Lancement réel de l'épreuve (`POST /begin`). Null tant qu'elle n'a pas
     *  été lancée : l'épreuve n'a alors AUCUNE échéance. */
    timerStartedAt: string | null;
    /** `timerStartedAt + timeLimitSeconds`. **Unique source du compte à
     *  rebours**, y compris au retour dans l'app : quitter ne suspend rien, le
     *  temps a couru pendant l'absence. Ne jamais recalculer une échéance côté
     *  client. */
    deadlineAt: string | null;
}

/** Comment l'examen a été mené : d'une traite, ou repris en plusieurs fois.
 *  L'abandon/reprise entre épreuves est officiellement supporté — ce champ dit
 *  seulement ce qui s'est passé, il ne disqualifie rien. */
export type FullTcfExamContinuite = "SESSION_UNIQUE" | "PLUSIEURS_SESSIONS";

/** Libellés gelés côté backend (miroir mot pour mot du mobile). Déclarés ici et
 *  nulle part ailleurs : aucune de ces chaînes ne se recopie dans un composant. */
export const FULL_TCF_EXAM_CONTINUITE_LABEL: Record<FullTcfExamContinuite, string> = {
    SESSION_UNIQUE: "Simulation complète — conditions examen",
    PLUSIEURS_SESSIONS: "Simulation complétée en plusieurs sessions",
};

/** `null` tant que l'examen n'est pas terminé : rien à afficher, cas normal. */
export function fullTcfExamContinuiteLabel(
    continuite: FullTcfExamContinuite | null | undefined,
): string | null {
    return continuite == null ? null : FULL_TCF_EXAM_CONTINUITE_LABEL[continuite];
}

export interface FullTcfExamResponse {
    id: string;
    startedAt: string;
    /** Lancement réel de la 1re épreuve — **trace du début réel de l'examen**,
     *  plus l'ancre d'un décompte : chaque épreuve porte son propre chrono
     *  (`FullTcfExamSubAttempt.deadlineAt`). Null tant que le candidat n'a pas
     *  commencé (hub de progression). */
    timerStartedAt: string | null;
    finishedAt: string | null;
    finalCecrlLevel: NiveauCecrl | null;
    status: FullTcfExamStatus;
    /** Null tant que l'examen n'est pas terminé. */
    continuite: FullTcfExamContinuite | null;
    subAttempts: FullTcfExamSubAttempt[];
    /** Périmètre réel du plancher `finalCecrlLevel` : nombre d'épreuves qui
     *  portent un niveau et y entrent vraiment. Une épreuve verrouillée
     *  (freemium) ou dont les évaluations ont échoué n'en fait pas partie —
     *  c'est ce qui interdit d'affirmer « le plus bas de tes 4 épreuves » en
     *  dur. Lu par `floorScope()` (lib/exam-levels.ts). */
    epreuvesCountedInFinalLevel: number;
    /** Épreuves attendues dans un examen complet (4 : CO/CE/EE/EO), publié pour
     *  que les fronts ne codent pas la constante en dur. */
    epreuvesExpected: number;
    /** `epreuvesCountedInFinalLevel < epreuvesExpected` : bilan **partiel**, à
     *  ne pas présenter comme un résultat d'examen complet. */
    finalLevelPartial: boolean;
}

export interface FullTcfExamSummaryResponse {
    id: string;
    startedAt: string;
    finishedAt: string | null;
    finalCecrlLevel: NiveauCecrl | null;
    status: FullTcfExamStatus;
    slotNumber: number | null;
    /** `finalCecrlLevel` ne porte pas sur les 4 épreuves (EE/EO verrouillée,
     *  évaluations échouées) : à écarter des stats « meilleur niveau » /
     *  « dernier examen » et à annoter dans la grille des slots — un examen
     *  amputé n'est pas un résultat d'examen complet (`isCompleteExamResult`). */
    finalLevelPartial: boolean;
    /** Null tant que l'examen n'est pas terminé. */
    continuite: FullTcfExamContinuite | null;
}

/** Ordre canonique des 4 épreuves de l'examen complet. */
export const FULL_TCF_EXAM_EPREUVES = [
    "TCF_CO",
    "TCF_CE",
    "TCF_EE",
    "TCF_EO",
] as const;
