import {track, type AnalyticsDiagnosticType} from "./analytics";
import {diagnosticRunApi, tokenStorage} from "./api";
import {uuidV4} from "./client-context";
import {
  isDiagnosticRunUsable,
  readDiagnosticRun,
  writeDiagnosticRun,
  type DiagnosticRunRecord,
} from "./diagnostic-run-store";
import type {DiagnosticRunType} from "./types";

/**
 * **Le cycle de vie client d'une `diagnostic_run`** (chantier « Suivi », Q3,
 * D21 → D24) — le seul module qui appelle `diagnosticRunApi`. Miroir mobile :
 * `diagnostic_run_tracker.dart`.
 *
 * | Fait | Qui l'appelle |
 * |---|---|
 * | Sujet vu | `ensureDiagnosticRun`, à l'affichage de la **1ʳᵉ question** (les trois types) |
 * | Soumis | `submitQuickTcfRun`, au bouton final du TCF rapide ; serveur pour le civique et le complet |
 * | Session liée | à la création (`sessionId`), ou au handoff du rapide invité (`bindQuickTcfSession`) |
 * | Rattaché | `lib/api.ts` (`authApi`), dans la requête d'auth |
 *
 * 🛑 **Best-effort absolu** : aucune de ces fonctions ne lève ni ne retarde le
 * parcours. Un diagnostic sans trace est un chiffre inconnu, jamais un
 * diagnostic bloqué.
 */

/**
 * **Un passage** = une clé d'idempotence. On reprend la trace existante tant
 * qu'elle désigne le même passage :
 * - même session serveur ;
 * - ou une trace d'invité sans session, pas encore soumise — le candidat qui
 *   se connecte en cours de route continue le même passage, et la création
 *   avec `sessionId` lie la run à sa session.
 *
 * Sinon (autre session, ou passage d'invité déjà soumis), c'est un nouveau
 * passage : nouvelle clé.
 */
function samePassage(record: DiagnosticRunRecord, sessionId: string | null): boolean {
  if (record.sessionId === sessionId) return !(sessionId === null && record.submitted);
  return record.sessionId === null && !record.submitted;
}

const inFlight = new Map<DiagnosticRunType, Promise<DiagnosticRunRecord | null>>();

/**
 * « Sujet vu » : crée la run de ce passage, ou la reprend. Aucun appel quand
 * la trace est déjà complète pour cette session et son jeton encore valable —
 * un rejeu ferait tourner le jeton pour rien.
 */
export function ensureDiagnosticRun(
  diagnosticType: DiagnosticRunType,
  sessionId: string | null = null,
): Promise<DiagnosticRunRecord | null> {
  if (typeof window === "undefined") return Promise.resolve(null);
  const pending = inFlight.get(diagnosticType);
  if (pending) return pending;
  const job = (async () => {
    try {
      const stored = await readDiagnosticRun(diagnosticType);
      const current = stored && samePassage(stored, sessionId) ? stored : null;
      if (current && current.sessionId === sessionId && isDiagnosticRunUsable(current)) {
        return current;
      }
      const clientKey = current?.clientKey ?? uuidV4();
      const draft: DiagnosticRunRecord = current ?? {
        diagnosticType,
        clientKey,
        diagnosticRunId: null,
        claimToken: null,
        claimTokenExpiresAt: null,
        sessionId,
        createdAsGuest: !tokenStorage.getAccess(),
        submitted: false,
        touchedAt: Date.now(),
      };
      // La clé est écrite AVANT l'appel : une coupure réseau la rejouera au
      // prochain affichage, et le serveur rendra la même run.
      if (!current) await writeDiagnosticRun(draft);
      const created = await diagnosticRunApi.create({diagnosticType, clientKey, sessionId});
      const next: DiagnosticRunRecord = {
        ...draft,
        diagnosticRunId: created.diagnosticRunId,
        claimToken: created.claimToken,
        claimTokenExpiresAt: created.claimTokenExpiresAt,
        sessionId: sessionId ?? draft.sessionId,
      };
      await writeDiagnosticRun(next);
      return next;
    } catch {
      return null;
    } finally {
      inFlight.delete(diagnosticType);
    }
  })();
  inFlight.set(diagnosticType, job);
  return job;
}

/**
 * « Soumis » du TCF rapide (D23), au bouton qui lance l'analyse. Une seule
 * fois : le serveur ne redate rien, et la trace locale le retient. La run
 * d'un autre passage (autre session) n'est jamais soumise à sa place.
 */
export async function submitQuickTcfRun(sessionId: string | null = null): Promise<void> {
  try {
    const record = await (inFlight.get("QUICK_TCF") ?? readDiagnosticRun("QUICK_TCF"));
    if (!record?.diagnosticRunId || record.submitted) return;
    if (sessionId !== null && record.sessionId !== null && record.sessionId !== sessionId) return;
    await diagnosticRunApi.submit(record.diagnosticRunId, record.claimToken);
    await writeDiagnosticRun({...record, submitted: true});
  } catch {
    // Un « soumis » perdu est un chiffre inconnu, jamais une analyse bloquée.
  }
}

/** La run du passage d'invité à transmettre au handoff (`POST /api/diagnostics`). */
export async function quickTcfRunForHandoff(): Promise<string | null> {
  const record = await readDiagnosticRun("QUICK_TCF").catch(() => null);
  return record?.diagnosticRunId && record.sessionId === null ? record.diagnosticRunId : null;
}

/**
 * Le handoff a ouvert la session du compte : la trace locale la retient, pour
 * que le rapport de CETTE session retrouve sa run. Le serveur, lui, a déjà lié
 * (ou refusé de lier) de son côté.
 */
export async function bindQuickTcfSession(
  diagnosticRunId: string,
  sessionId: string,
): Promise<void> {
  try {
    const record = await readDiagnosticRun("QUICK_TCF");
    if (record?.diagnosticRunId !== diagnosticRunId || record.sessionId !== null) return;
    await writeDiagnosticRun({...record, sessionId});
  } catch {
    // Sans liaison locale, le rapport part sans run : inconnu, pas faux.
  }
}

/**
 * Le contexte « run » d'un événement portant sur **cette** session — jamais la
 * run d'une autre session, jamais une run devinée. `null` = inconnu (rapport
 * ouvert sur un autre appareil, trace perdue).
 */
export async function diagnosticRunContextFor(
  diagnosticType: DiagnosticRunType,
  sessionId: string,
): Promise<{diagnosticRunId: string; diagnosticType: DiagnosticRunType} | null> {
  const record = await readDiagnosticRun(diagnosticType).catch(() => null);
  if (!record?.diagnosticRunId || record.sessionId !== sessionId) return null;
  return {diagnosticRunId: record.diagnosticRunId, diagnosticType};
}

/** Le format TCF d'un rapport, tel que la propriété `diagnosticType` le
 *  nomme. Le civique n'en a pas : la propriété est omise, jamais `UNKNOWN`. */
const REPORT_FORMAT: Record<DiagnosticRunType, AnalyticsDiagnosticType | null> = {
  QUICK_TCF: "RAPID",
  FULL_TCF: "COMPLETE",
  CIVIQUE: null,
};

/**
 * `DIAGNOSTIC_REPORT_VIEWED` — étape 4 du tunnel. À appeler quand le rapport
 * s'affiche **avec ses données**, jamais sur un squelette ou un écran de
 * compte. Une fois par onglet et par session.
 */
export function trackDiagnosticReportViewed(
  diagnosticType: DiagnosticRunType,
  sessionId: string,
): void {
  void diagnosticRunContextFor(diagnosticType, sessionId).then((context) => {
    const format = REPORT_FORMAT[diagnosticType];
    track("DIAGNOSTIC_REPORT_VIEWED", format ? {diagnosticType: format} : {}, {
      once: true,
      context: context ?? {diagnosticType},
    });
  });
}
