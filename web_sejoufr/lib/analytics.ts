import {API_BASE_URL} from "./api";
import {trafficSourceFromRaw} from "./traffic-source";
import type {PlanExerciseKind} from "./types";

/**
 * Mesure d'audience SejourFR — le seul point d'émission du web.
 *
 * Remplace `lib/audience.ts` + `lib/audience-events.ts`, dont il reprend le
 * patron d'envoi (`sendBeacon`, repli `fetch keepalive`, best-effort absolu).
 *
 * ⚠️ **Ce module dépose désormais un identifiant sur l'appareil du visiteur**,
 * ce que l'ancien s'interdisait. C'est un arbitrage du propriétaire
 * (2026-08-21) : sans identifiant, on comptait des *vues* et jamais des
 * *visiteurs*, donc aucun parcours « landing → diagnostic → compte → paiement »
 * n'était reconstituable. L'identifiant est :
 *
 * - **first-party** : lu et écrit par ce seul domaine, jamais partagé, jamais
 *   utilisé pour suivre quelqu'un d'un site à l'autre ;
 * - **limité à la mesure d'audience**, sans profilage ni publicité ;
 * - **régénéré au-delà de 13 mois** — c'est la condition de l'exemption de
 *   consentement retenue, pas un détail d'implémentation. Ne pas allonger
 *   cette durée sans repasser sur `/confidentialite`.
 *
 * C'est ce qui permet à `/confidentialite` (art. 8.2 à 8.5) de continuer
 * d'affirmer qu'**aucun bandeau de consentement n'est requis**. Toute
 * information ajoutée ici doit être décrite là-bas dans la même passe.
 *
 * 🛑 **Chaque accès au stockage est enveloppé dans un `try/catch`** : en
 * navigation privée, stockage bloqué ou quota plein, on émet **sans identité**
 * plutôt que de casser la page. Une mesure perdue est sans conséquence ; une
 * page qui plante ne l'est pas.
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
  DIAGNOSTIC_REPORT_VIEWED: {diagnosticType: AnalyticsDiagnosticType};
  PREMIUM_CTA_CLICKED: {
    ctaLocation: AnalyticsCtaLocation;
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
  /** N'alimentent aucun bloc du dashboard : posés pour ne pas perdre une
   *  mesure qui existait avant la migration (`page_views`). */
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
};

export type AnalyticsEvent = keyof AnalyticsEventProperties;

/** Propriétés exigées par un événement donné. */
export type AnalyticsPropertiesFor<E extends AnalyticsEvent> = AnalyticsEventProperties[E];

// ============================================================================
// IDENTITÉ — localStorage (13 mois) + sessionStorage (30 min d'inactivité)
// ============================================================================

const ANONYMOUS_ID_KEY = "sejourfr.aid";
const SESSION_KEY = "sejourfr.sid";

/** Durée de vie de l'identifiant de mesure. **Condition de l'exemption de
 *  consentement** : annoncée telle quelle à l'article 8.3 de
 *  `/confidentialite`. */
const ANONYMOUS_ID_MAX_AGE_MS = 13 * 30 * 24 * 60 * 60 * 1000;

/** Une nouvelle visite commence après ce silence. */
const SESSION_IDLE_MS = 30 * 60 * 1000;

type AnonymousRecord = {
  /** UUID v4. */
  id: string;
  /** Date de pose, en millisecondes. C'est elle qui rend les 13 mois vérifiables. */
  createdAt: number;
  /** Le premier contact a déjà été transmis : on ne le réécrit jamais. */
  firstTouchSent?: boolean;
};

type SessionRecord = {id: string; lastSeenAt: number};

/** UUID v4. `crypto.randomUUID` n'existe pas partout (contextes non sécurisés,
 *  vieux Safari) : le repli reste un v4 valide, tiré de `getRandomValues`. */
function uuidV4(): string {
  try {
    if (typeof crypto !== "undefined" && typeof crypto.randomUUID === "function") {
      return crypto.randomUUID();
    }
    if (typeof crypto !== "undefined" && typeof crypto.getRandomValues === "function") {
      const bytes = crypto.getRandomValues(new Uint8Array(16));
      bytes[6] = (bytes[6] & 0x0f) | 0x40;
      bytes[8] = (bytes[8] & 0x3f) | 0x80;
      const hex = Array.from(bytes, (b) => b.toString(16).padStart(2, "0")).join("");
      return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
    }
  } catch {
    // On tombe sur le repli ci-dessous.
  }
  // Dernier repli : sans source aléatoire cryptographique, la collision est
  // improbable et sans conséquence — c'est un compteur, pas une identité.
  const random = () => Math.floor(Math.random() * 0x10000).toString(16).padStart(4, "0");
  return `${random()}${random()}-${random()}-4${random().slice(1)}-a${random().slice(1)}-${random()}${random()}${random()}`;
}

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function readJson<T>(storage: Storage, key: string): T | null {
  try {
    const raw = storage.getItem(key);
    return raw ? (JSON.parse(raw) as T) : null;
  } catch {
    return null;
  }
}

function writeJson(storage: Storage, key: string, value: unknown): void {
  try {
    storage.setItem(key, JSON.stringify(value));
  } catch {
    // Navigation privée, stockage bloqué, quota plein : on continue sans.
  }
}

/**
 * Identifiant de mesure de ce visiteur, ou `null` si le navigateur refuse
 * d'écrire. `null` n'est **pas** une erreur : l'événement part sans identité,
 * la page ne casse pas.
 */
function anonymousRecord(): AnonymousRecord | null {
  if (typeof window === "undefined") return null;
  let storage: Storage;
  try {
    storage = window.localStorage;
    if (!storage) return null;
  } catch {
    return null;
  }

  const stored = readJson<Partial<AnonymousRecord>>(storage, ANONYMOUS_ID_KEY);
  const now = Date.now();
  const valid =
    typeof stored?.id === "string" &&
    UUID_RE.test(stored.id) &&
    typeof stored.createdAt === "number" &&
    Number.isFinite(stored.createdAt) &&
    // Une date de pose dans le futur est une horloge déréglée : on repart de
    // zéro plutôt que de garder un identifiant qui ne périmera jamais.
    stored.createdAt <= now &&
    now - stored.createdAt < ANONYMOUS_ID_MAX_AGE_MS;

  if (valid) return stored as AnonymousRecord;

  const fresh: AnonymousRecord = {id: uuidV4(), createdAt: now};
  writeJson(storage, ANONYMOUS_ID_KEY, fresh);
  // Relecture : si l'écriture a échoué en silence (quota, mode privé), on ne
  // prétend pas porter une identité stable.
  const confirmed = readJson<Partial<AnonymousRecord>>(storage, ANONYMOUS_ID_KEY);
  return confirmed?.id === fresh.id ? fresh : null;
}

function markFirstTouchSent(record: AnonymousRecord): void {
  if (typeof window === "undefined") return;
  try {
    writeJson(window.localStorage, ANONYMOUS_ID_KEY, {...record, firstTouchSent: true});
  } catch {
    // Sans marqueur, le premier contact repartira — le serveur l'ignore
    // (`ON CONFLICT DO NOTHING`), il n'écrase jamais l'attribution d'origine.
  }
}

/** Identifiant de visite. Renouvelé après 30 min d'inactivité. */
function sessionId(): string | null {
  if (typeof window === "undefined") return null;
  let storage: Storage;
  try {
    storage = window.sessionStorage;
    if (!storage) return null;
  } catch {
    return null;
  }

  const now = Date.now();
  const stored = readJson<Partial<SessionRecord>>(storage, SESSION_KEY);
  const alive =
    typeof stored?.id === "string" &&
    UUID_RE.test(stored.id) &&
    typeof stored.lastSeenAt === "number" &&
    Number.isFinite(stored.lastSeenAt) &&
    now - stored.lastSeenAt < SESSION_IDLE_MS;

  const record: SessionRecord = alive
    ? {id: stored!.id as string, lastSeenAt: now}
    : {id: uuidV4(), lastSeenAt: now};
  writeJson(storage, SESSION_KEY, record);
  const confirmed = readJson<Partial<SessionRecord>>(storage, SESSION_KEY);
  return confirmed?.id === record.id ? record.id : null;
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

function firstTouch(): FirstTouch {
  let params: URLSearchParams;
  try {
    params = new URLSearchParams(window.location.search);
  } catch {
    params = new URLSearchParams();
  }
  const utmSource = trimmed(params.get("utm_source"), 40);
  const src = trimmed(params.get("src"), 40);
  const referrer = referrerHost();
  // On envoie la valeur brute quand elle existe : le serveur est l'autorité de
  // normalisation (`util/TrafficSource`). La réduire ici perdrait « google » ou
  // « newsletter », que la liste fermée du web ne connaît pas.
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
    landingPath: trimmed(window.location.pathname, 160),
    referrerHost: referrer,
  };
}

// ============================================================================
// ÉMISSION
// ============================================================================

const ENDPOINT = "/api/public/analytics/events";

/** Déduplication par onglet uniquement — rien de plus n'est écrit sur
 *  l'appareil pour ça. */
const sentOnce = new Set<string>();

type EventBody = {
  anonymousId: string | null;
  sessionId: string | null;
  event: AnalyticsEvent;
  path: string | null;
  occurredAt: string;
  properties: Record<string, string>;
  firstTouch?: FirstTouch;
};

function post(body: EventBody): void {
  const payload = JSON.stringify(body);
  const url = `${API_BASE_URL}${ENDPOINT}`;

  // `sendBeacon` survit à la navigation : indispensable sur un clic de CTA, où
  // la page est déjà en train d'être quittée quand la requête part. Repli
  // `fetch keepalive` pour les navigateurs qui refusent le beacon.
  try {
    const blob = new Blob([payload], {type: "application/json"});
    if (navigator.sendBeacon?.(url, blob)) return;
  } catch {
    // On tombe sur le repli ci-dessous.
  }

  void fetch(url, {
    method: "POST",
    headers: {"Content-Type": "application/json"},
    body: payload,
    keepalive: true,
  }).catch(() => {
    // La mesure d'audience ne doit jamais casser la page ni remonter d'erreur
    // à l'utilisateur : un compteur perdu est sans conséquence.
  });
}

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
 * Émet un événement de mesure. **Best-effort et jamais bloquant** : aucune
 * erreur n'est remontée, aucun état d'attente n'est affiché.
 *
 * `once` déduplique pendant la vie de l'onglet seulement.
 */
export function track<E extends AnalyticsEvent>(
  event: E,
  properties: AnalyticsPropertiesFor<E>,
  options: {once?: boolean} = {},
): void {
  if (typeof window === "undefined") return;

  const normalized = normalizeProperties(properties as Record<string, unknown>);

  if (options.once) {
    const key = `${event}:${JSON.stringify(normalized)}`;
    if (sentOnce.has(key)) return;
    sentOnce.add(key);
  }

  const record = anonymousRecord();
  const body: EventBody = {
    anonymousId: record?.id ?? null,
    sessionId: sessionId(),
    event,
    path: safePathname(),
    occurredAt: new Date().toISOString(),
    properties: normalized,
  };

  // Premier contact : une seule fois par visiteur, jamais réécrit ensuite.
  if (record && !record.firstTouchSent) {
    body.firstTouch = firstTouch();
    markFirstTouchSent(record);
  }

  post(body);
}

function safePathname(): string | null {
  try {
    return window.location.pathname.slice(0, 160);
  } catch {
    return null;
  }
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
