/** Élément plaçable dans une grille d'examens blancs : il porte un slot UI et
 *  une date de début (pour départager deux essais d'un même slot). */
interface SlottedExam {
  slotNumber?: number | null;
  startedAt: string;
}

/**
 * Place les examens blancs finis dans une grille de `slots` cases, indexée par
 * `slotNumber` (1..slots). On garde le **plus récent** par slot : refaire
 * « l'examen N » crée un attempt avec le même `slotNumber=N` et met à jour la
 * case N au lieu d'ajouter une case N+1 (parité mobile, migration V110).
 *
 * Les attempts sans `slotNumber` (historique d'avant V110) sont ignorés —
 * ils restent consultables dans /historique. Générique : marche pour les
 * `AttemptSummaryResponse` (QCM) comme pour les `FullTcfExamSummaryResponse`.
 */
export function examSlotGrid<T extends SlottedExam>(
  finished: T[],
  slots: number,
): {
  /** Tableau de longueur `slots` : case i = examen du slot i+1, ou null. */
  bySlot: (T | null)[];
  /** Examens retenus (un par slot rempli), pour les stats. */
  latest: T[];
  /** Nombre de slots remplis. */
  doneCount: number;
} {
  const map = new Map<number, T>();
  for (const a of finished) {
    const slot = a.slotNumber;
    if (slot == null || slot < 1 || slot > slots) continue;
    const prev = map.get(slot);
    if (!prev || a.startedAt.localeCompare(prev.startedAt) > 0) map.set(slot, a);
  }
  const bySlot = Array.from({ length: slots }, (_, i) => map.get(i + 1) ?? null);
  return { bySlot, latest: [...map.values()], doneCount: map.size };
}
