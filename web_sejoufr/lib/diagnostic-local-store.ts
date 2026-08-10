/**
 * Conservation **sur disque** des deux productions du diagnostic faites en
 * visiteur, avant qu'un compte existe.
 *
 * Règle produit n°1 : **on ne perd jamais une production**. Un candidat qui a
 * rédigé 120 mots puis enregistré deux minutes de parole ne doit pas les
 * refaire parce qu'il a rafraîchi, fermé l'onglet, ou été renvoyé sur la page
 * par un sign-in Google/Apple qui quitte le document.
 *
 * D'où **IndexedDB** et pas `localStorage` : le `localStorage` ne stocke que
 * des chaînes, or l'oral est un `Blob` audio. L'audio est écrit en
 * `ArrayBuffer` + type MIME (les très vieux moteurs refusent de sérialiser un
 * `Blob`), et rebâti en `Blob` à la lecture.
 *
 * Ce module ne **supprime** jamais rien de lui-même : l'effacement est décidé
 * par l'appelant, et seulement une fois que le serveur a accusé réception des
 * **deux** soumissions. Toutes les fonctions sont *best-effort* : navigation
 * privée, quota plein ou IndexedDB indisponible renvoient `null` / `false`
 * plutôt que de lever — la production reste alors en mémoire dans l'onglet,
 * qui est la première ligne de défense, le disque n'étant que le filet.
 */

const DB_NAME = "sejourfr-diagnostic";
const DB_VERSION = 1;
const STORE = "productions";

/** Une production locale, telle qu'elle est relue au chargement de la page. */
export interface LocalDiagnosticProductions {
  diagnosticCode: string;
  diagnosticVersion: number;
  /** Sujet EE pour lequel le texte a été écrit — un changement de version du
   *  contenu rendrait la réponse hors-sujet, on préfère le savoir. */
  writtenTaskId: string | null;
  writtenText: string | null;
  oralTaskId: string | null;
  oralAudio: Blob | null;
  oralDurationSec: number | null;
  /** Date de la dernière écriture, pour départager deux entrées résiduelles. */
  savedAt: number;
}

/** Forme réellement persistée : l'audio y est un buffer, jamais un Blob. */
interface StoredRecord {
  diagnosticCode: string;
  diagnosticVersion: number;
  writtenTaskId: string | null;
  writtenText: string | null;
  oralTaskId: string | null;
  oralAudioBuffer: ArrayBuffer | null;
  oralAudioType: string | null;
  oralDurationSec: number | null;
  savedAt: number;
}

function storeKey(diagnosticCode: string, diagnosticVersion: number): string {
  return `${diagnosticCode}/v${diagnosticVersion}`;
}

function openDb(): Promise<IDBDatabase | null> {
  if (typeof indexedDB === "undefined") return Promise.resolve(null);
  return new Promise((resolve) => {
    let request: IDBOpenDBRequest;
    try {
      request = indexedDB.open(DB_NAME, DB_VERSION);
    } catch {
      resolve(null);
      return;
    }
    request.onupgradeneeded = () => {
      const db = request.result;
      if (!db.objectStoreNames.contains(STORE)) db.createObjectStore(STORE);
    };
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => resolve(null);
    request.onblocked = () => resolve(null);
  });
}

function readRecord(db: IDBDatabase, key: string): Promise<StoredRecord | null> {
  return new Promise((resolve) => {
    try {
      const request = db.transaction(STORE, "readonly").objectStore(STORE).get(key);
      request.onsuccess = () => resolve((request.result as StoredRecord | undefined) ?? null);
      request.onerror = () => resolve(null);
    } catch {
      resolve(null);
    }
  });
}

function writeRecord(db: IDBDatabase, key: string, record: StoredRecord): Promise<boolean> {
  return new Promise((resolve) => {
    try {
      const tx = db.transaction(STORE, "readwrite");
      tx.objectStore(STORE).put(record, key);
      tx.oncomplete = () => resolve(true);
      tx.onerror = () => resolve(false);
      tx.onabort = () => resolve(false);
    } catch {
      resolve(false);
    }
  });
}

function toPublic(record: StoredRecord): LocalDiagnosticProductions {
  return {
    diagnosticCode: record.diagnosticCode,
    diagnosticVersion: record.diagnosticVersion,
    writtenTaskId: record.writtenTaskId,
    writtenText: record.writtenText,
    oralTaskId: record.oralTaskId,
    oralAudio:
      record.oralAudioBuffer && record.oralAudioBuffer.byteLength > 0
        ? new Blob([record.oralAudioBuffer], {
            type: record.oralAudioType || "audio/webm",
          })
        : null,
    oralDurationSec: record.oralDurationSec,
    savedAt: record.savedAt,
  };
}

function emptyRecord(diagnosticCode: string, diagnosticVersion: number): StoredRecord {
  return {
    diagnosticCode,
    diagnosticVersion,
    writtenTaskId: null,
    writtenText: null,
    oralTaskId: null,
    oralAudioBuffer: null,
    oralAudioType: null,
    oralDurationSec: null,
    savedAt: Date.now(),
  };
}

/** Relit la production locale d'une version de diagnostic donnée. */
export async function readLocalDiagnostic(
  diagnosticCode: string,
  diagnosticVersion: number,
): Promise<LocalDiagnosticProductions | null> {
  const db = await openDb();
  if (!db) return null;
  const record = await readRecord(db, storeKey(diagnosticCode, diagnosticVersion));
  db.close();
  return record ? toPublic(record) : null;
}

/**
 * Relit la production locale la plus récente, **quelle que soit** la version.
 *
 * C'est ce que lit l'écran connecté : au retour d'une inscription il ne sait
 * pas encore quel code de diagnostic le serveur va lui servir, et il doit
 * pouvoir dire honnêtement « ces réponses portent sur une autre version du
 * sujet » plutôt que de faire disparaître le travail en silence.
 */
export async function readLatestLocalDiagnostic(): Promise<LocalDiagnosticProductions | null> {
  const db = await openDb();
  if (!db) return null;
  const records = await new Promise<StoredRecord[]>((resolve) => {
    try {
      const request = db.transaction(STORE, "readonly").objectStore(STORE).getAll();
      request.onsuccess = () => resolve((request.result as StoredRecord[] | undefined) ?? []);
      request.onerror = () => resolve([]);
    } catch {
      resolve([]);
    }
  });
  db.close();
  const latest = records
    .filter((record) => record?.writtenText || record?.oralAudioBuffer)
    .sort((a, b) => (b.savedAt ?? 0) - (a.savedAt ?? 0))[0];
  return latest ? toPublic(latest) : null;
}

/** Écrit le texte de l'écrit. Ne touche pas à l'oral déjà enregistré. */
export async function saveLocalWritten(
  diagnosticCode: string,
  diagnosticVersion: number,
  productionTaskId: string,
  text: string,
): Promise<boolean> {
  const db = await openDb();
  if (!db) return false;
  const key = storeKey(diagnosticCode, diagnosticVersion);
  const current = (await readRecord(db, key)) ?? emptyRecord(diagnosticCode, diagnosticVersion);
  const ok = await writeRecord(db, key, {
    ...current,
    writtenTaskId: productionTaskId,
    writtenText: text,
    savedAt: Date.now(),
  });
  db.close();
  return ok;
}

/** Écrit l'audio de l'oral. Ne touche pas au texte déjà enregistré. */
export async function saveLocalOral(
  diagnosticCode: string,
  diagnosticVersion: number,
  productionTaskId: string,
  audio: Blob,
  durationSec: number | null,
): Promise<boolean> {
  const db = await openDb();
  if (!db) return false;
  const key = storeKey(diagnosticCode, diagnosticVersion);
  const current = (await readRecord(db, key)) ?? emptyRecord(diagnosticCode, diagnosticVersion);
  let buffer: ArrayBuffer;
  try {
    buffer = await audio.arrayBuffer();
  } catch {
    db.close();
    return false;
  }
  const ok = await writeRecord(db, key, {
    ...current,
    oralTaskId: productionTaskId,
    oralAudioBuffer: buffer,
    oralAudioType: audio.type || "audio/webm",
    oralDurationSec: durationSec,
    savedAt: Date.now(),
  });
  db.close();
  return ok;
}

/**
 * Efface la production locale. À n'appeler **qu'après** que le serveur a
 * accusé réception des deux soumissions, ou sur une suppression explicitement
 * demandée par le candidat.
 */
export async function clearLocalDiagnostic(
  diagnosticCode: string,
  diagnosticVersion: number,
): Promise<void> {
  const db = await openDb();
  if (!db) return;
  await new Promise<void>((resolve) => {
    try {
      const tx = db.transaction(STORE, "readwrite");
      tx.objectStore(STORE).delete(storeKey(diagnosticCode, diagnosticVersion));
      tx.oncomplete = () => resolve();
      tx.onerror = () => resolve();
      tx.onabort = () => resolve();
    } catch {
      resolve();
    }
  });
  db.close();
}

/** Les deux productions sont là : il ne manque plus que le compte. */
export function isLocalDiagnosticComplete(
  local: LocalDiagnosticProductions | null | undefined,
): local is LocalDiagnosticProductions {
  return Boolean(local?.writtenText?.trim() && local?.oralAudio && local.oralAudio.size > 0);
}
