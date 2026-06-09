import type { AttemptSummaryResponse } from "./types";

/**
 * Place les examens blancs finis dans une grille de `slots` cases, indexée par
 * `slotNumber` (1..slots). On garde le **plus récent** par slot : refaire
 * « l'examen N » crée un attempt avec le même `slotNumber=N` et met à jour la
 * case N au lieu d'ajouter une case N+1 (parité mobile, migration V110).
 *
 * Les attempts sans `slotNumber` (historique d'avant V110) sont ignorés —
 * ils restent consultables dans /historique.
 */
export function examSlotGrid(
  finished: AttemptSummaryResponse[],
  slots: number,
): {
  /** Tableau de longueur `slots` : case i = examen du slot i+1, ou null. */
  bySlot: (AttemptSummaryResponse | null)[];
  /** Examens retenus (un par slot rempli), pour les stats. */
  latest: AttemptSummaryResponse[];
  /** Nombre de slots remplis. */
  doneCount: number;
} {
  const map = new Map<number, AttemptSummaryResponse>();
  for (const a of finished) {
    const slot = a.slotNumber;
    if (slot == null || slot < 1 || slot > slots) continue;
    const prev = map.get(slot);
    if (!prev || a.startedAt.localeCompare(prev.startedAt) > 0) map.set(slot, a);
  }
  const bySlot = Array.from({ length: slots }, (_, i) => map.get(i + 1) ?? null);
  return { bySlot, latest: [...map.values()], doneCount: map.size };
}
