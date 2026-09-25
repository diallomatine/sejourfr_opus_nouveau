import {detectTrafficSource} from "./traffic-source";

/**
 * **Le contexte client du web** — l'autorité unique de ce que le site déclare
 * sur lui-même au serveur (arbitrage Q4 du chantier « Suivi ») :
 *
 * - `X-Sejourfr-Client: web` ;
 * - `X-Sejourfr-Anonymous-Id` : l'identifiant de mesure du visiteur ;
 * - `X-Sejourfr-App-Version` : la version du site ;
 * - `X-Sejourfr-Source` : la provenance, quand elle est connue.
 *
 * Posés sur **toutes** les requêtes par `lib/api.ts` (un seul point de
 * câblage), et recopiés dans le corps du lot d'analytics, parce qu'un
 * `sendBeacon` ne peut poser aucun en-tête. Miroir mobile :
 * `mobile_sejourfr/lib/core/analytics/` (même rôle, même nom d'en-têtes).
 *
 * Ce module **n'importe ni `api` ni `analytics`** : les deux en ont besoin, le
 * faire dépendre de l'un créerait un cycle d'import.
 *
 * ⚠️ **L'identifiant de mesure est un traceur** (arbitrage du propriétaire du
 * 2026-08-21) : first-party, limité à la mesure d'audience, **régénéré au-delà
 * de 13 mois** — c'est la condition de l'exemption de consentement décrite à
 * l'article 8 de `/confidentialite`. Ne pas allonger cette durée, ni rien
 * ajouter ici qui s'écrive sur l'appareil, sans repasser sur cette page.
 *
 * 🛑 **Chaque accès au stockage est enveloppé dans un `try/catch`** :
 * navigation privée, stockage bloqué ou quota plein rendent `null` plutôt que
 * de casser la page. Une mesure perdue est sans conséquence ; une page qui
 * plante ne l'est pas.
 */

export const CLIENT_PLATFORM = "web";

/**
 * Version du site, fixée au build (`next.config.ts` : `NEXT_PUBLIC_APP_VERSION`,
 * sinon la version de `package.json`). Vide ⇒ l'en-tête est omis : le serveur
 * lit alors « version inconnue », jamais une valeur inventée.
 */
export const APP_VERSION: string = process.env.NEXT_PUBLIC_APP_VERSION ?? "";

const ANONYMOUS_ID_KEY = "sejourfr.aid";
const SESSION_KEY = "sejourfr.sid";

/** Durée de vie de l'identifiant de mesure. **Condition de l'exemption de
 *  consentement** : annoncée telle quelle à l'article 8.3 de `/confidentialite`. */
const ANONYMOUS_ID_MAX_AGE_MS = 13 * 30 * 24 * 60 * 60 * 1000;

/** Une nouvelle visite commence après ce silence. */
const SESSION_IDLE_MS = 30 * 60 * 1000;

export type AnonymousRecord = {
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
export function uuidV4(): string {
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

export const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export function readJson<T>(storage: Storage, key: string): T | null {
  try {
    const raw = storage.getItem(key);
    return raw ? (JSON.parse(raw) as T) : null;
  } catch {
    return null;
  }
}

export function writeJson(storage: Storage, key: string, value: unknown): void {
  try {
    storage.setItem(key, JSON.stringify(value));
  } catch {
    // Navigation privée, stockage bloqué, quota plein : on continue sans.
  }
}

function storageOf(kind: "localStorage" | "sessionStorage"): Storage | null {
  if (typeof window === "undefined") return null;
  try {
    return window[kind] ?? null;
  } catch {
    return null;
  }
}

/**
 * Identifiant de mesure de ce visiteur, ou `null` si le navigateur refuse
 * d'écrire. `null` n'est **pas** une erreur : la requête part sans identité,
 * la page ne casse pas.
 */
export function anonymousRecord(): AnonymousRecord | null {
  const storage = storageOf("localStorage");
  if (!storage) return null;

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

export function anonymousId(): string | null {
  return anonymousRecord()?.id ?? null;
}

export function markFirstTouchSent(record: AnonymousRecord): void {
  const storage = storageOf("localStorage");
  if (!storage) return;
  // Sans marqueur, le premier contact repartira — le serveur ne réécrit jamais
  // l'attribution d'origine.
  writeJson(storage, ANONYMOUS_ID_KEY, {...record, firstTouchSent: true});
}

/** Repli de l'onglet quand le `sessionStorage` est refusé : la visite reste
 *  une visite, elle meurt simplement avec la page. */
let volatileSession: SessionRecord | null = null;

/** Identifiant de visite. Renouvelé après 30 min d'inactivité. */
export function visitSessionId(): string | null {
  if (typeof window === "undefined") return null;
  const now = Date.now();
  const storage = storageOf("sessionStorage");
  const stored = storage
    ? readJson<Partial<SessionRecord>>(storage, SESSION_KEY)
    : volatileSession;
  const alive =
    typeof stored?.id === "string" &&
    UUID_RE.test(stored.id) &&
    typeof stored.lastSeenAt === "number" &&
    Number.isFinite(stored.lastSeenAt) &&
    now - stored.lastSeenAt < SESSION_IDLE_MS;

  const record: SessionRecord = alive
    ? {id: stored!.id as string, lastSeenAt: now}
    : {id: uuidV4(), lastSeenAt: now};
  volatileSession = record;
  if (storage) writeJson(storage, SESSION_KEY, record);
  return record.id;
}

/**
 * Les en-têtes de contexte, pour **toutes** les requêtes vers l'API. En rendu
 * serveur, seul `X-Sejourfr-Client` est posé : ni identifiant ni provenance
 * n'existent hors du navigateur.
 */
export function clientContextHeaders(): Record<string, string> {
  const headers: Record<string, string> = {"X-Sejourfr-Client": CLIENT_PLATFORM};
  if (APP_VERSION) headers["X-Sejourfr-App-Version"] = APP_VERSION;
  const source = detectTrafficSource();
  if (source) headers["X-Sejourfr-Source"] = source;
  const aid = anonymousId();
  if (aid) headers["X-Sejourfr-Anonymous-Id"] = aid;
  return headers;
}
