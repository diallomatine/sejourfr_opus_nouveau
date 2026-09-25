import {API_BASE_URL} from "./api";
import {
  anonymousRecord,
  APP_VERSION,
  CLIENT_PLATFORM,
  clientContextHeaders,
  markFirstTouchSent,
  readJson,
  uuidV4,
  visitSessionId,
  writeJson,
} from "./client-context";
import {trafficSourceFromRaw} from "./traffic-source";
import type {DiagnosticRunType, PlanExerciseKind} from "./types";

/**
 * Mesure d'audience SejourFR — le seul point d'émission du web.
 *
 * **Envoi en LOT** (chantier « Suivi », Q17) : chaque événement reçoit son
 * `eventId` **à sa création**, attend dans un tampon mémoire, et part avec les
 * autres vers `POST /api/public/analytics/events/batch`. Le serveur
 * dédoublonne sur l'`eventId` : un lot renvoyé après une coupure n'écrit rien
 * deux fois. L'endpoint unitaire n'est plus appelé par le web.
 *
 * L'identité (identifiant de mesure 13 mois, visite 30 min) et les en-têtes de
 * contexte vivent dans `lib/client-context.ts` — c'est **un traceur**, décrit à
 * l'article 8 de `/confidentialite` : toute information ajoutée ici doit être
 * décrite là-bas dans la même passe.
 *
 * 🛑 **Best-effort absolu** : aucune erreur n'est remontée, aucun état
 * d'attente n'est affiché. Une mesure perdue est sans conséquence ; une page
 * qui plante ne l'est pas.
 *
 * 🛑 **Le `claimToken` d'une run n'entre JAMAIS ici** : aucun type de ce
 * module ne le porte. Le `diagnosticRunId`, lui, est un identifiant et voyage
 * dans le contexte d'un événement.
 *
 * À ne pas confondre avec `lib/funnel-events.ts`, qui pose des étapes de funnel
 * **rattachées à un compte** (endpoint authentifié, idempotent serveur).
 */

// ============================================================================
// REGISTRE D'ÉVÉNEMENTS — miroir FERMÉ de `enums/AnalyticsEvent` côté backend
// ============================================================================

/** Où se trouvait le bouton cliqué. Miroir de `AnalyticsCtaLocation`. */
export type AnalyticsCtaLocation =
  | "DIAGNOSTIC_REPORT"
  | "LOCKED_PLAN"
  | "PRICING"
  | "AI_CORRECTION"
  | "MOCK_EXAM"
  | "HERO"
  | "MIDDLE"
  | "STICKY"
  | "FOOTER"
  | "OTHER";

/** Miroir de `AnalyticsDiagnosticType`. `UNKNOWN` quand le parcours ne le sait
 *  pas — on ne devine jamais une valeur. */
export type AnalyticsDiagnosticType = "RAPID" | "COMPLETE" | "UNKNOWN";

/** Miroir de `AnalyticsRegistrationContext`. */
export type AnalyticsRegistrationContext =
  | "LANDING"
  | "BEFORE_DIAGNOSTIC"
  | "DURING_DIAGNOSTIC"
  | "AFTER_DIAGNOSTIC"
  | "DIAGNOSTIC_REPORT"
  | "PRICING"
  | "MOBILE_APP"
  | "OTHER";

/**
 * Les propriétés admises par événement — allowlist fermée, miroir de celle que
 * le serveur oppose. L'endpoint d'ingestion est **public** : le client ne doit
 * jamais lui inventer de dimension, même par erreur.
 *
 * 🛑 **`CHECKOUT_STARTED` n'est volontairement PAS ici** : il est posé par le
 * serveur (`BillingService`) après création réelle de la Checkout Stripe.
 * Venant d'un client, ce serait une intention, pas un fait.
 *
 * 🛑 **`USER_REGISTERED`, `PAYMENT_SUCCEEDED` et `DIAGNOSTIC_COMPLETED` non
 * plus** : ils se lisent sur `users`, `user_subscriptions` et
 * `diagnostic_sessions`. Un événement n'existe que pour ce qui n'existe QUE
 * dans le navigateur.
 */
type AnalyticsEventProperties = {
  LANDING_VIEWED: {landingPath: string; landingVariant?: string};
  DIAGNOSTIC_CTA_CLICKED: {
    ctaLocation: AnalyticsCtaLocation;
    diagnosticType: AnalyticsDiagnosticType;
  };
  PRICING_VIEWED: Record<string, never>;
  PRICING_CTA_CLICKED: {planCode: string};
  SIGNUP_CTA_CLICKED: {ctaLocation: AnalyticsCtaLocation};
  LOGIN_CLICKED: Record<string, never>;
  SIGNUP_STARTED: {registrationContext: AnalyticsRegistrationContext};
  DIAGNOSTIC_STARTED: {diagnosticType: AnalyticsDiagnosticType};
  DIAGNOSTIC_EE_STARTED: {diagnosticType: AnalyticsDiagnosticType};
  DIAGNOSTIC_EE_COMPLETED: {diagnosticType: AnalyticsDiagnosticType};
  DIAGNOSTIC_EO_STARTED: {diagnosticType: AnalyticsDiagnosticType};
  DIAGNOSTIC_EO_COMPLETED: {diagnosticType: AnalyticsDiagnosticType};
  DIAGNOSTIC_CO_STARTED: {diagnosticType: AnalyticsDiagnosticType};
  DIAGNOSTIC_CO_COMPLETED: {diagnosticType: AnalyticsDiagnosticType};
  DIAGNOSTIC_CE_STARTED: {diagnosticType: AnalyticsDiagnosticType};
  DIAGNOSTIC_CE_COMPLETED: {diagnosticType: AnalyticsDiagnosticType};
  /** Étape 4 du tunnel « Suivi » quand il porte la run (contexte). Émis quand
   *  le rapport s'affiche **avec ses données**. `diagnosticType` n'a de sens
   *  que pour le TCF (rapide / complet) : le civique n'en porte pas. */
  DIAGNOSTIC_REPORT_VIEWED: {diagnosticType?: AnalyticsDiagnosticType};
  PREMIUM_CTA_CLICKED: {
    /** Absent quand l'écran ne connaît pas son origine (contrôle F) : jamais
     *  un `OTHER` fabriqué. */
    ctaLocation?: AnalyticsCtaLocation;
    planCode?: string;
    screen?: string;
  };
  /** `/reussir` a DEUX portes d'entrée, comptées séparément — cf. le CLAUDE.md
   *  racine. Ne JAMAIS réutiliser `DIAGNOSTIC_CTA_CLICKED` ici : le civique n'a
   *  ni production, ni niveau CECRL, ni diagnostic, et confondre les deux
   *  gonflerait la mesure du diagnostic avec des clics qui n'y mènent pas. */
  CIVIQUE_CTA_CLICKED: {ctaLocation: AnalyticsCtaLocation};
  /** LA mesure de conversion du parcours invité du diagnostic : l'instant où
   *  l'on demande un compte, les deux productions déjà faites. Distinct de
   *  `DIAGNOSTIC_EO_COMPLETED` — entre les deux se joue la décision même de
   *  créer un compte. */
  DIAGNOSTIC_ACCOUNT_REQUIRED: {diagnosticType: AnalyticsDiagnosticType};
  /** Étape 5 du tunnel « Suivi » : le Plan affiché, avec son `journeyId`
   *  (contexte). */
  PLAN_OPENED: Record<string, never>;
  PLAN_EXERCISE_STARTED: {exerciseKind: PlanExerciseKind};
  /**
   * 🛑 **Le rideau freemium se mesure en TROIS gestes distincts** — affiché,
   * déplié, offre vue — et les fondre effacerait exactement ce qu'on veut
   * savoir. `PLAN_PAYWALL_VIEWED` n'est **pas** `PREMIUM_CTA_CLICKED` : une vue
   * n'est pas une intention, et c'est l'écart entre les deux qui dit si le
   * rideau donne envie ou décourage.
   *
   * Posés avant le déploiement de la « progression par épreuve » (2026-08-26),
   * qui fait passer le rideau de « 1 sur 5 » à « 1 sur 9 ou 12 » : mesurés
   * après coup, ils n'auraient plus de point de comparaison.
   */
  PLAN_CURTAIN_SHOWN: {
    ctaLocation: AnalyticsCtaLocation;
    epreuve: string;
    visibleCount: number;
    totalCount: number;
  };
  PLAN_CURTAIN_EXPANDED: {ctaLocation: AnalyticsCtaLocation; epreuve: string};
  PLAN_PAYWALL_VIEWED: {ctaLocation: AnalyticsCtaLocation};
  /**
   * Étape 6 du tunnel « Suivi » : le tap sur « Débloquer mon plan » de l'écran
   * de déblocage. 🛑 Distinct de `PREMIUM_CTA_CLICKED` et de
   * `PLAN_PAYWALL_VIEWED`. `planCode` / `displayedPriceCents` disent ce que le
   * candidat avait sous les yeux (absents si le catalogue n'a pas répondu),
   * jamais ce qu'il a payé.
   */
  PLAN_UNLOCK_CLICKED: {
    ctaLocation: AnalyticsCtaLocation;
    planCode?: string;
    displayedPriceCents?: number;
  };
};

export type AnalyticsEvent = keyof AnalyticsEventProperties;

/** Propriétés exigées par un événement donné. */
export type AnalyticsPropertiesFor<E extends AnalyticsEvent> = AnalyticsEventProperties[E];


// ============================================================================
// CHEMINS SUIVIS — miroir FERMÉ de `util/AnalyticsPaths.KNOWN`
// ============================================================================

/**
 * Les écrans qu'un événement peut nommer. Le serveur **refuse** un chemin hors
 * liste (l'événement est rejeté, et un `landingPath` de premier contact hors
 * liste rejette **tout le lot**) : un écran non déclaré part donc avec
 * `path: null`, jamais avec son adresse brute. Ajouter un écran suivi = une
 * ligne ici ET une dans `AnalyticsPaths.KNOWN`, dans la même passe.
 *
 * Les routes mobiles de la liste serveur (`/home`, `/target-path`, `/paywall`)
 * n'ont rien à faire ici.
 */
const TRACKED_PATHS: ReadonlySet<string> = new Set([
  "/",
  "/reussir",
  "/diagnostic",
  "/diagnostic/resultat",
  "/diagnostic-civique",
  "/diagnostic-civique/resultat",
  "/plan",
  "/plan/debloquer",
  "/tarifs",
  "/paiement",
  "/connexion",
  "/inscription",
  "/dashboard",
  "/entrainement",
  "/examens-blancs",
  "/competences",
  "/profil",
]);

/** Routes web à segment dynamique, ramenées à l'écran qu'elles sont. Un
 *  identifiant de session n'a rien à faire dans une mesure d'audience. */
const DYNAMIC_PATHS: ReadonlyArray<[RegExp, string]> = [
  [/^\/diagnostic-civique\/[^/]+\/resultat$/, "/diagnostic-civique/resultat"],
];

/** Chemin suivi de cette adresse, ou `null` — jamais une valeur hors liste. */
export function trackedPath(raw: string | null | undefined): string | null {
  if (!raw) return null;
  let path = raw.split(/[?#]/)[0].trim().toLowerCase();
  if (path.length > 1 && path.endsWith("/")) path = path.slice(0, -1);
  if (!path) path = "/";
  if (TRACKED_PATHS.has(path)) return path;
  for (const [pattern, normalized] of DYNAMIC_PATHS) {
    if (pattern.test(path)) return normalized;
  }
  return null;
}

function currentPath(): string | null {
  try {
    return trackedPath(window.location.pathname);
  } catch {
    return null;
  }
}

// ============================================================================
// PREMIER CONTACT — envoyé une seule fois, jamais réécrit
// ============================================================================

type FirstTouch = {
  source: string;
  medium?: string;
  campaign?: string;
  content?: string;
  term?: string;
  /** Écran d'arrivée, **dans la liste suivie** — sinon absent (le serveur
   *  rejetterait tout le lot). */
  landingPath?: string;
  /** **Hôte seul**, jamais l'URL complète : elle pourrait porter un chemin ou
   *  un paramètre personnels venant d'un site tiers. */
  referrerHost?: string;
};

/** Bornes défensives : le serveur tronque, mais on ne lui envoie pas des
 *  kilo-octets d'URL forgée. */
function trimmed(value: string | null | undefined, max: number): string | undefined {
  const cleaned = value?.trim();
  if (!cleaned) return undefined;
  return cleaned.slice(0, max);
}

function referrerHost(): string | undefined {
  try {
    if (!document.referrer) return undefined;
    const host = new URL(document.referrer).host;
    // Une navigation interne n'est pas une provenance.
    return host && host !== window.location.host ? trimmed(host, 120) : undefined;
  } catch {
    return undefined;
  }
}

/**
 * Le premier contact, **capté au premier événement** de la page d'arrivée
 * (l'URL porte encore ses UTM). La source déclarée part **brute** : le
 * serveur la garde telle quelle (`ft_source_raw`, D11) et la normalise à
 * part — la réduire ici perdrait « ig », « google » ou « newsletter ».
 */
function captureFirstTouch(): FirstTouch {
  let params: URLSearchParams;
  try {
    params = new URLSearchParams(window.location.search);
  } catch {
    params = new URLSearchParams();
  }
  const utmSource = trimmed(params.get("utm_source"), 40);
  const src = trimmed(params.get("src"), 40);
  const referrer = referrerHost();
  const source =
    utmSource?.toLowerCase() ??
    src?.toLowerCase() ??
    trafficSourceFromRaw(referrer) ??
    referrer?.toLowerCase() ??
    "direct";

  return {
    source,
    medium: trimmed(params.get("utm_medium"), 40),
    campaign: trimmed(params.get("utm_campaign"), 120),
    content: trimmed(params.get("utm_content"), 120),
    term: trimmed(params.get("utm_term"), 120),
    landingPath: currentPath() ?? undefined,
    referrerHost: referrer,
  };
}

/** Capté au premier chargement, envoyé avec le premier lot. */
let pendingFirstTouch: FirstTouch | null = null;

/**
 * **Le premier contact se capte au PREMIER HIT**, pas au premier événement :
 * une page d'arrivée qui n'émet rien (l'accueil, un article) perdrait ses
 * UTM à la première navigation. Appelé par `FirstTouchCapture`, monté dans le
 * layout racine ; il n'envoie rien, le premier lot emportera l'attribution.
 */
export function captureFirstTouchOnLanding(): void {
  if (typeof window === "undefined" || pendingFirstTouch !== null) return;
  const record = anonymousRecord();
  if (record && !record.firstTouchSent) pendingFirstTouch = captureFirstTouch();
}

// ============================================================================
// CONTEXTE D'UN ÉVÉNEMENT — colonnes serveur, pas des propriétés
// ============================================================================

/**
 * Les identifiants qu'un événement peut porter **en colonne**
 * (`AnalyticsEvent.Contexte`) : ils se joignent aux runs et aux parcours. Le
 * serveur rejette un événement qui en porte un qu'il n'admet pas.
 */
export type AnalyticsContext = {
  diagnosticRunId?: string | null;
  diagnosticType?: DiagnosticRunType | null;
  journeyId?: string | null;
};

// ============================================================================
// FILE D'ENVOI — tampon mémoire, envoi par lots
// ============================================================================

const BATCH_ENDPOINT = "/api/public/analytics/events/batch";
/** `ingestion.maxBatchSize` côté serveur. */
const MAX_BATCH = 50;
/** Au-delà, les plus anciens tombent : un onglet hors ligne pendant des heures
 *  ne doit pas gonfler la mémoire. */
const MAX_QUEUE = 200;
const FLUSH_DELAY_MS = 4_000;
const RETRY_DELAY_MS = 30_000;

type QueuedEvent = {
  eventId: string;
  event: AnalyticsEvent;
  occurredAt: string;
  path: string | null;
  properties: Record<string, string>;
  diagnosticRunId?: string;
  diagnosticType?: DiagnosticRunType;
  journeyId?: string;
};

type BatchBody = {
  anonymousId: string;
  sessionId: string;
  client: string;
  appVersion?: string;
  firstTouch?: FirstTouch;
  events: QueuedEvent[];
};

/** Réponse 202 du lot (seuls les compteurs servent ici). */
type BatchReport = {received: number; accepted: number; duplicates: number};

let queue: QueuedEvent[] = [];
let timer: ReturnType<typeof setTimeout> | null = null;
let sending = false;
let listening = false;

function schedule(delay: number): void {
  if (timer !== null) return;
  timer = setTimeout(() => {
    timer = null;
    void flush();
  }, delay);
}

/**
 * La page se cache ou se ferme : ce qui reste part par `sendBeacon`, le seul
 * envoi qui survit à la navigation (un clic de CTA quitte déjà la page).
 */
function listenForPageExit(): void {
  if (listening) return;
  listening = true;
  try {
    document.addEventListener("visibilitychange", () => {
      if (document.visibilityState === "hidden") flushOnExit();
    });
    window.addEventListener("pagehide", flushOnExit);
  } catch {
    // Sans écouteur, le tampon part au prochain délai : au pire, un lot perdu.
  }
}

/** L'enveloppe d'un lot, ou `null` sans identité de mesure : le serveur exige
 *  `anonymousId` et `sessionId`, et un visiteur sans stockage n'en a pas. */
function envelope(events: QueuedEvent[]): BatchBody | null {
  const record = anonymousRecord();
  const session = visitSessionId();
  if (!record || !session) return null;
  const body: BatchBody = {
    anonymousId: record.id,
    sessionId: session,
    client: CLIENT_PLATFORM,
    events,
  };
  if (APP_VERSION) body.appVersion = APP_VERSION;
  if (!record.firstTouchSent) {
    body.firstTouch = pendingFirstTouch ?? captureFirstTouch();
  }
  return body;
}

/** Le premier contact est parti : on ne le renverra plus. */
function firstTouchDelivered(body: BatchBody): void {
  if (!body.firstTouch) return;
  const record = anonymousRecord();
  if (record) markFirstTouchSent(record);
  pendingFirstTouch = null;
}

/**
 * Envoi normal, en-têtes compris. **202** : le lot est purgé, rejets
 * compris (un rejet est définitif, le renvoyer serait rejeté de nouveau, D5).
 * **400** : l'enveloppe est refusée telle quelle — la renvoyer à l'identique
 * échouerait toujours, le lot est abandonné. **429, 5xx, réseau** : le lot
 * revient en tête de file et repart plus tard, sous le même `eventId`.
 */
async function flush(): Promise<void> {
  if (sending || queue.length === 0 || typeof window === "undefined") return;
  const batch = queue.slice(0, MAX_BATCH);
  const body = envelope(batch);
  if (!body) {
    queue = [];
    return;
  }
  queue = queue.slice(batch.length);
  sending = true;
  try {
    const res = await fetch(`${API_BASE_URL}${BATCH_ENDPOINT}`, {
      method: "POST",
      headers: {...clientContextHeaders(), "Content-Type": "application/json"},
      body: JSON.stringify(body),
      keepalive: true,
    });
    if (res.ok) {
      // Le serveur ne pose l'attribution qu'avec au moins un événement
      // retenu : un lot entièrement rejeté la garde pour le suivant.
      const report = (await res.json().catch(() => null)) as BatchReport | null;
      if (report && report.accepted + report.duplicates > 0) firstTouchDelivered(body);
    } else if (res.status !== 400) {
      queue = [...batch, ...queue].slice(-MAX_QUEUE);
      schedule(RETRY_DELAY_MS);
      return;
    }
  } catch {
    queue = [...batch, ...queue].slice(-MAX_QUEUE);
    schedule(RETRY_DELAY_MS);
    return;
  } finally {
    sending = false;
  }
  if (queue.length > 0) schedule(0);
}

/**
 * Type du corps de la balise. ⚠️ `application/json` **cross-origin** déclenche
 * une pré-vérification CORS que `sendBeacon` ne sait pas faire (la balise peut
 * être refusée) ; `text/plain` l'éviterait, mais l'endpoint en lot ne le lit pas
 * encore (415). À basculer quand le serveur l'accepte (contrôle N7).
 */
const BEACON_CONTENT_TYPE = "application/json";

/** Vidage de sortie : `sendBeacon` (sans en-têtes — `client` et `appVersion`
 *  voyagent dans le corps), repli `fetch keepalive`. */
function flushOnExit(): void {
  if (timer !== null) {
    clearTimeout(timer);
    timer = null;
  }
  while (queue.length > 0) {
    const batch = queue.slice(0, MAX_BATCH);
    queue = queue.slice(batch.length);
    const body = envelope(batch);
    if (!body) {
      queue = [];
      return;
    }
    const payload = JSON.stringify(body);
    const url = `${API_BASE_URL}${BATCH_ENDPOINT}`;
    let sent = false;
    try {
      sent = navigator.sendBeacon?.(url, new Blob([payload], {type: BEACON_CONTENT_TYPE})) ?? false;
    } catch {
      sent = false;
    }
    /* 🛑 **Le premier contact n'est « envoyé » que s'il est réellement parti**
       (contrôle N7) : balise acceptée par le navigateur, ou réponse du serveur
       qui retient au moins un événement — la règle de `flush`. Sinon il reste
       en attente et repart avec le lot suivant, au lieu d'être perdu. */
    if (sent) {
      firstTouchDelivered(body);
      continue;
    }
    void fetch(url, {
      method: "POST",
      headers: {"Content-Type": "application/json"},
      body: payload,
      keepalive: true,
    })
      .then(async (res) => {
        if (!res.ok) return;
        const report = (await res.json().catch(() => null)) as BatchReport | null;
        if (report && report.accepted + report.duplicates > 0) firstTouchDelivered(body);
      })
      .catch(() => undefined);
  }
}

// ============================================================================
// ÉMISSION
// ============================================================================

/** Déduplication par onglet uniquement — rien de plus n'est écrit sur
 *  l'appareil pour ça. */
const sentOnce = new Set<string>();

/** N'envoie que des chaînes, et jamais une clé vide : le serveur oppose une
 *  allowlist, on ne lui donne pas de quoi la contourner par accident. */
function normalizeProperties(properties: Record<string, unknown>): Record<string, string> {
  const out: Record<string, string> = {};
  for (const [key, value] of Object.entries(properties)) {
    if (value === undefined || value === null) continue;
    const text = String(value).trim();
    if (text) out[key] = text.slice(0, 160);
  }
  return out;
}

/**
 * Émet un événement de mesure. **Best-effort et jamais bloquant** : il entre
 * dans la file, avec son `eventId` et son horodate de geste, et part avec le
 * lot suivant.
 *
 * `once` déduplique pendant la vie de l'onglet seulement (contexte compris).
 */
export function track<E extends AnalyticsEvent>(
  event: E,
  properties: AnalyticsPropertiesFor<E>,
  options: {once?: boolean; context?: AnalyticsContext} = {},
): void {
  if (typeof window === "undefined") return;

  const normalized = normalizeProperties(properties as Record<string, unknown>);
  const context = options.context ?? {};

  if (options.once) {
    const key = `${event}:${JSON.stringify(normalized)}:${context.diagnosticRunId ?? ""}:${context.journeyId ?? ""}`;
    if (sentOnce.has(key)) return;
    sentOnce.add(key);
  }

  captureFirstTouchOnLanding();

  const queued: QueuedEvent = {
    eventId: uuidV4(),
    event,
    occurredAt: new Date().toISOString(),
    path: currentPath(),
    properties: normalized,
  };
  if (context.diagnosticRunId) queued.diagnosticRunId = context.diagnosticRunId;
  if (context.diagnosticType) queued.diagnosticType = context.diagnosticType;
  if (context.journeyId) queued.journeyId = context.journeyId;

  queue.push(queued);
  if (queue.length > MAX_QUEUE) queue = queue.slice(-MAX_QUEUE);
  listenForPageExit();
  if (queue.length >= MAX_BATCH) void flush();
  else schedule(FLUSH_DELAY_MS);
}

// ============================================================================
// VARIANTE DE DIAGNOSTIC — mémoire de l'onglet, jamais une valeur devinée
// ============================================================================

/**
 * Le format choisi à l'entrée du diagnostic (« rapide » / « complet ») n'est
 * **persisté nulle part** : c'est une décision produit, le profil réel se lit
 * sur les domaines mesurés. Il vit donc en mémoire, exactement comme l'état
 * `parcours` de `DiagnosticView` — dont ce registre est le miroir.
 *
 * Tant que le candidat n'a pas choisi, la valeur reste `UNKNOWN` : on ne
 * devine pas, et un rechargement de page repart légitimement d'`UNKNOWN`.
 */
let currentDiagnosticType: AnalyticsDiagnosticType = "UNKNOWN";

export function rememberDiagnosticType(type: AnalyticsDiagnosticType): void {
  currentDiagnosticType = type;
}

/** Événements de diagnostic : tous portent le format, lu au même endroit. */
type DiagnosticEvent = {
  [E in AnalyticsEvent]: AnalyticsPropertiesFor<E> extends {diagnosticType: AnalyticsDiagnosticType}
    ? E
    : never;
}[AnalyticsEvent];

/**
 * Raccourci des événements de diagnostic — le format vient du registre
 * ci-dessus, jamais d'un appelant qui le recopierait.
 */
export function trackDiagnostic(
  event: Exclude<DiagnosticEvent, "DIAGNOSTIC_CTA_CLICKED">,
  options: {once?: boolean} = {},
): void {
  track(event, {diagnosticType: currentDiagnosticType}, options);
}

// ============================================================================
// COMPRÉHENSION DU DIAGNOSTIC — la mesure CO/CE, commencée puis terminée
// ============================================================================

/**
 * Les deux domaines de compréhension du diagnostic complet se mesurent par une
 * **série d'examen blanc de module** : ils n'ont pas d'écran à eux, et le
 * runner QCM ne sait pas pourquoi il a été ouvert.
 *
 * On note donc, **le temps d'un onglet**, quelle tentative a été lancée pour
 * compléter le profil ; l'écran de résultat la reconnaît et émet le
 * « terminé » correspondant. Rien n'est deviné : sans marque, aucun événement
 * n'est émis — un examen blanc CO joué pour lui-même n'est pas un diagnostic.
 */
const ASSESSMENT_KEY = "sejourfr.dgx";

type AssessmentDomain = "CO" | "CE";

function readAssessments(): Record<string, AssessmentDomain> {
  if (typeof window === "undefined") return {};
  try {
    return readJson<Record<string, AssessmentDomain>>(window.sessionStorage, ASSESSMENT_KEY) ?? {};
  } catch {
    return {};
  }
}

/** Marque la tentative comme mesure de compréhension du diagnostic, et émet
 *  le « commencé ». */
export function trackDiagnosticAssessmentStarted(
  attemptId: string,
  domain: AssessmentDomain,
): void {
  if (typeof window === "undefined") return;
  try {
    writeJson(window.sessionStorage, ASSESSMENT_KEY, {
      ...readAssessments(),
      [attemptId]: domain,
    });
  } catch {
    // Sans marque, seul le « commencé » sera mesuré : une moitié de paire vaut
    // mieux qu'un « terminé » attribué au hasard.
  }
  track(domain === "CO" ? "DIAGNOSTIC_CO_STARTED" : "DIAGNOSTIC_CE_STARTED", {
    diagnosticType: currentDiagnosticType,
  });
}

/** Émet le « terminé » si — et seulement si — cette tentative avait été lancée
 *  pour compléter le profil. La marque est consommée. */
export function trackDiagnosticAssessmentCompleted(attemptId: string): void {
  if (typeof window === "undefined") return;
  const known = readAssessments();
  const domain = known[attemptId];
  if (!domain) return;
  delete known[attemptId];
  try {
    writeJson(window.sessionStorage, ASSESSMENT_KEY, known);
  } catch {
    // Au pire, l'événement est ré-émis au rechargement de l'écran de résultat.
  }
  track(domain === "CO" ? "DIAGNOSTIC_CO_COMPLETED" : "DIAGNOSTIC_CE_COMPLETED", {
    diagnosticType: currentDiagnosticType,
  });
}
