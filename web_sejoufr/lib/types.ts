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
export type AudioMode = "WRITTEN_QUESTION" | "FULL_AUDIO";

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
    audioMode?: AudioMode | null;
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

const SINGLE_LETTER = /^[A-Za-z]$/;

/**
 * Questions TCF CO FULL_AUDIO : tous les labels se réduisent à une seule lettre
 * (A/B/C/D), qui est la clé de réponse citée par l'audio et l'explication. On
 * trie alors les choix par label pour qu'ils s'affichent dans l'ordre A→D (et
 * que la pastille colle à l'explication). Les questions normales gardent leur
 * ordre d'origine. Générique sur `{ label }` pour couvrir les Choice*Response.
 */
export function orderedChoices<T extends { label: string }>(choices: T[]): T[] {
    const allLetters =
        choices.length > 0 && choices.every((c) => SINGLE_LETTER.test(c.label.trim()));
    if (!allLetters) return choices;
    return [...choices].sort((a, b) =>
        a.label.trim().toUpperCase().localeCompare(b.label.trim().toUpperCase()),
    );
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
    audioMode?: AudioMode | null;
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
export type ModuleAccess = "NONE" | "CIVIQUE" | "TCF" | "INTEGRAL";

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
    mediaUrl: string | null; // EO
    texteSoumis: string | null; // EE
    motsCount: number | null;
    mediaDurationSec: number | null; // EO
    retryCount: number;
    erreurMessage: string | null;
    submittedAt: string;
    /** Null tant que statut != EVALUATED. */
    evaluation: EvaluationResultDto | null;
    transcription: string | null; // EO
}

/** Body JSON de POST /api/production-submissions (EE). */
export interface SubmitProductionTextRequest {
    productionTaskId: string;
    attemptId: string;
    texte: string;
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

/** Épreuve productive d'une compétence. Pendant « court » d'`EpreuveType`. */
export type SkillSection = "EE" | "EO";

/** Tâche TCF porteuse des compétences (3 par épreuve). */
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
export interface SkillDto {
    id: string;
    section: SkillSection;
    taskCode: string;
    code: string; // "EE1-C1"
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
}

/** Un petit sujet dans la liste d'une compétence. */
export interface SkillPromptSummaryDto {
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
export interface SkillPromptDto {
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

/** Sortie IA d'un micro-exercice : 5 champs courts, et rien d'autre. */
export interface SkillAnalysisDto {
    status: SkillCriterionStatus;
    verdict: string;
    successPoint: string;
    improvementPriority: string;
    improvedVersion: string;
}

export interface SkillAttemptDto {
    id: string;
    skillPromptId: string;
    skillPromptCode: string;
    statut: SkillAttemptStatut;
    analysisRequested: boolean;
    writtenProduction: string | null;
    /** URL R2 présignée (15 min) — jamais la clé brute. EO uniquement. */
    audioUrl: string | null;
    audioDurationSec: number | null;
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

/** Section « compétences » d'une épreuve productive. */
export function skillSectionOf(epreuve: EpreuveType): SkillSection {
    return epreuve === "TCF_EO" ? "EO" : "EE";
}

/** Code de tâche à partir de la section et du numéro de tâche (1..3). */
export function skillTaskCodeOf(section: SkillSection, tacheNumero: number): SkillTaskCode {
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

/** Sous-titre d'une tâche selon l'épreuve productive (EE / EO). */
export function productionTaskSubtitle(epreuve: EpreuveType, tacheNumero: number): string {
    return epreuve === "TCF_EO" ? eoTaskSubtitle(tacheNumero) : eeTaskSubtitle(tacheNumero);
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
 * La réponse du candidat **réécrite au palier qu'il vise**, plus ce qui l'en
 * sépare. Produite par un SECOND appel LLM, totalement séparé de la correction
 * (le correcteur n'apprend jamais quel niveau vise le candidat — sinon il
 * alignerait sa note dessus).
 *
 * **EE uniquement**, et absente dans tous ces cas parfaitement normaux : à
 * l'oral, sur les évaluations antérieures, et quand le second appel a échoué.
 * Rien ne s'affiche alors — ni squelette, ni « non disponible ».
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
    /** Le modèle rédigé au niveau visé. **Jamais la production du candidat.** */
    texte: string;
    /** 2 à 3 leviers, **dans l'ordre du backend** (du plus rentable au moins
     *  rentable) : ne jamais retrier côté front. */
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

/**
 * Bloc `version_ciblee`, ou `null` dès qu'il manque de quoi l'afficher
 * honnêtement : sans palier visé on ne saurait pas au nom de quoi ce texte est
 * montré, et sans texte il n'y a rien à montrer. L'ordre de `ce_qui_manque` est
 * **préservé** — le backend le trie du plus rentable au moins rentable.
 */
function asVersionCiblee(v: unknown): EeVersionCiblee | null {
    const r = asRecord(v);
    if (!r) return null;
    const niveauVise = asTargetLevel(r.niveau_vise);
    const texte = asString(r.texte);
    if (!niveauVise || !texte) return null;
    return {
        niveauVise,
        niveauConstate: asNiveauCecrl(r.niveau_constate),
        texte,
        ceQuiManque: asStringList(r.ce_qui_manque),
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
    civique: DashboardCategoryStat[];
    tcf: DashboardCategoryStat[];
}

// ============ HELPERS ============

/** Niveau TCF visé dérivé du parcours civique (CSP→A2, CR→B1, NAT→B2). */
export function tcfLevelFromProcedure(
    p: TargetProcedure | null | undefined,
): TargetLevel | null {
    return p === "NAT" ? "B2" : p === "CR" ? "B1" : p === "CSP" ? "A2" : null;
}

/** Niveau TCF effectif d'un utilisateur : targetLevel explicite, sinon dérivé
 *  du parcours, sinon B1 par défaut. Utilisé pour piocher les tâches EO/EE. */
export function resolveTcfLevel(
    user: Pick<AuthenticatedUser, "targetLevel" | "targetProcedure"> | null,
): TargetLevel {
    return user?.targetLevel ?? tcfLevelFromProcedure(user?.targetProcedure) ?? "B1";
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
    score: number | null;
    maxScore: number | null;
    submissionsCount: number | null;
    failedSubmissionIds: string[];
    locked: boolean;
}

export interface FullTcfExamResponse {
    id: string;
    startedAt: string;
    /** Lancement réel de la 1re épreuve (CO) — ancre du chrono 90 min. Null
     *  tant que le candidat n'a pas commencé (hub de progression). */
    timerStartedAt: string | null;
    finishedAt: string | null;
    finalCecrlLevel: NiveauCecrl | null;
    status: FullTcfExamStatus;
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
}

/** Durée totale de l'examen complet (90 min). Constante backend
 *  `FullTcfExamService.FULL_EXAM_TOTAL_SECONDS`, non exposée dans le DTO. */
export const FULL_TCF_EXAM_DURATION_SEC = 90 * 60;

/** Ordre canonique des 4 épreuves de l'examen complet. */
export const FULL_TCF_EXAM_EPREUVES = [
    "TCF_CO",
    "TCF_CE",
    "TCF_EE",
    "TCF_EO",
] as const;
