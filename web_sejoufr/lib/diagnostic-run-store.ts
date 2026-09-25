import {DIAGNOSTIC_RUNS_STORE, openDiagnosticDb} from "./diagnostic-local-store";
import type {DiagnosticRunType} from "./types";

/**
 * **La trace du passage dans le tunnel diagnostic, gardée sur l'appareil** —
 * l'autorité unique du stockage de `diagnosticRunId` + `claimToken` côté web
 * (chantier « Suivi », Q3). Miroir mobile : `diagnostic_run_store.dart`
 * (SharedPreferences).
 *
 * Rangée **avec le brouillon du diagnostic**, dans la même base IndexedDB
 * (`sejourfr-diagnostic`, magasin `runs`), une entrée **par type** : le
 * dernier passage de chaque diagnostic. Un nouveau passage remplace l'ancien.
 *
 * 🛑 **Le `claimToken` est un secret.** Il ne sort d'ici que vers deux routes :
 * `POST /api/public/diagnostic-runs/{id}/submit` et les requêtes d'auth. Il ne
 * part **jamais** dans un événement d'analytics — `lib/analytics.ts` ne
 * l'importe pas et ne le peut pas : aucun de ses types ne le porte.
 *
 * Ce module **n'importe pas `api`** : `lib/api.ts` le lit au moment d'une
 * authentification (le claim), l'inverse créerait un cycle.
 *
 * Best-effort de bout en bout : IndexedDB indisponible ⇒ la trace vit en
 * mémoire le temps de l'onglet. Rien ne lève.
 */

export interface DiagnosticRunRecord {
  diagnosticType: DiagnosticRunType;
  /** Clé d'idempotence du passage, tirée **une fois** : un rejeu de la
   *  création avec la même clé rend la même run. */
  clientKey: string;
  /** `null` tant que la création n'a pas abouti (réseau coupé) : la clé est
   *  alors rejouée à l'affichage suivant. */
  diagnosticRunId: string | null;
  /** Toujours le **dernier** rendu par le serveur : un rejeu tue l'ancien. */
  claimToken: string | null;
  claimTokenExpiresAt: string | null;
  /** La session serveur que la run trace. `null` = TCF rapide invité, dont
   *  la session n'existe qu'au handoff. */
  sessionId: string | null;
  /** Créée sans compte : seule une run d'invité a un claim à faire. */
  createdAsGuest: boolean;
  /** « Soumis » déjà posé (TCF rapide seulement, D23). */
  submitted: boolean;
  /** Dernière écriture — départage deux runs d'invité au moment du claim. */
  touchedAt: number;
}

const memory = new Map<DiagnosticRunType, DiagnosticRunRecord>();

export async function readDiagnosticRun(
  type: DiagnosticRunType,
): Promise<DiagnosticRunRecord | null> {
  const db = await openDiagnosticDb();
  if (!db) return memory.get(type) ?? null;
  const record = await new Promise<DiagnosticRunRecord | null>((resolve) => {
    try {
      const request = db
        .transaction(DIAGNOSTIC_RUNS_STORE, "readonly")
        .objectStore(DIAGNOSTIC_RUNS_STORE)
        .get(type);
      request.onsuccess = () =>
        resolve((request.result as DiagnosticRunRecord | undefined) ?? null);
      request.onerror = () => resolve(null);
    } catch {
      resolve(null);
    }
  });
  db.close();
  return record ?? memory.get(type) ?? null;
}

export async function writeDiagnosticRun(record: DiagnosticRunRecord): Promise<void> {
  const stamped = {...record, touchedAt: Date.now()};
  memory.set(record.diagnosticType, stamped);
  const db = await openDiagnosticDb();
  if (!db) return;
  await new Promise<void>((resolve) => {
    try {
      const tx = db.transaction(DIAGNOSTIC_RUNS_STORE, "readwrite");
      tx.objectStore(DIAGNOSTIC_RUNS_STORE).put(stamped, record.diagnosticType);
      tx.oncomplete = () => resolve();
      tx.onerror = () => resolve();
      tx.onabort = () => resolve();
    } catch {
      resolve();
    }
  });
  db.close();
}

function tokenAlive(record: DiagnosticRunRecord): boolean {
  if (!record.claimToken || !record.claimTokenExpiresAt) return false;
  const expires = Date.parse(record.claimTokenExpiresAt);
  return Number.isFinite(expires) && expires > Date.now();
}

/** La run a été créée et son jeton est encore valable. */
export function isDiagnosticRunUsable(
  record: DiagnosticRunRecord | null,
): record is DiagnosticRunRecord & {diagnosticRunId: string; claimToken: string} {
  return record !== null && record.diagnosticRunId !== null && tokenAlive(record);
}

/**
 * **Ce qu'une authentification transmet pour rattacher le diagnostic** : la
 * run d'invité la plus récente de cet appareil, jeton encore valable.
 *
 * Aucune heuristique côté serveur (Q3) : sans jeton, pas de claim. Une run
 * déjà claimée, ou d'un autre compte, est ignorée par le serveur sans erreur —
 * la renvoyer ne coûte rien. `null` quand l'appareil n'a rien à rattacher.
 */
export async function diagnosticRunToClaim(): Promise<
  {diagnosticRunId: string; claimToken: string} | null
> {
  const types: DiagnosticRunType[] = ["QUICK_TCF", "CIVIQUE"];
  const candidates: (DiagnosticRunRecord & {diagnosticRunId: string; claimToken: string})[] = [];
  for (const type of types) {
    const record = await readDiagnosticRun(type).catch(() => null);
    if (record?.createdAsGuest && isDiagnosticRunUsable(record)) candidates.push(record);
  }
  const latest = candidates.sort((a, b) => b.touchedAt - a.touchedAt)[0];
  return latest
    ? {diagnosticRunId: latest.diagnosticRunId, claimToken: latest.claimToken}
    : null;
}
