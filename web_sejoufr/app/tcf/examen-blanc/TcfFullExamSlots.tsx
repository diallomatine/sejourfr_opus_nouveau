"use client";

import { ChevronRight, Lock, Plus } from "lucide-react";
import {
  niveauCecrlLabel,
  type FullTcfExamSummaryResponse,
} from "@/lib/types";
import s from "./tcfFullExam.module.css";

export const FULL_EXAM_TOTAL_SLOTS = 20;

export interface FullExamSlotData {
  number: number;
  exam: FullTcfExamSummaryResponse | null;
}

/** Remplit 1..20 slots à partir de l'historique (clé = slotNumber). */
export function buildFullExamSlots(
  exams: FullTcfExamSummaryResponse[],
): FullExamSlotData[] {
  const bySlot = new Map<number, FullTcfExamSummaryResponse>();
  for (const e of exams) {
    if (e.slotNumber != null) bySlot.set(e.slotNumber, e);
  }
  return Array.from({ length: FULL_EXAM_TOTAL_SLOTS }, (_, i) => ({
    number: i + 1,
    exam: bySlot.get(i + 1) ?? null,
  }));
}

/** Destination d'un slot DÉJÀ entamé (in progress → hub, terminé → bilan).
 *  Retourne null pour un slot disponible : c'est l'appelant qui décide
 *  (ouvrir le briefing inline, ou router vers le hub avec ?startSlot=N). */
export function fullExamStartedHref(
  exam: FullTcfExamSummaryResponse,
): string | null {
  if (exam.status === "IN_PROGRESS") return `/tcf/examen-blanc/${exam.id}`;
  if (exam.status === "COMPLETED" || exam.status === "PENDING_EVALUATIONS") {
    return `/tcf/examen-blanc/${exam.id}/bilan`;
  }
  return null;
}

/**
 * Grille des 20 examens blancs TCF complets. Partagée entre la page dédiée
 * (`/tcf/examen-blanc`, clic → briefing) et la carte TCF de `/examens-blancs`
 * (clic → hub via ?startSlot). Le gating premium (Intégral) est piloté par
 * `premium` : un slot disponible verrouillé déclenche `onLocked` (paywall).
 */
export function TcfFullExamSlots({
  exams,
  premium,
  onSlotClick,
  onLocked,
  lockedLabel = "Intégral",
}: {
  exams: FullTcfExamSummaryResponse[];
  premium: boolean;
  onSlotClick: (slot: FullExamSlotData) => void;
  onLocked: () => void;
  lockedLabel?: string;
}) {
  const slots = buildFullExamSlots(exams);
  return (
    <div className={s.slotsGrid}>
      {slots.map((slot) => (
        <SlotCard
          key={slot.number}
          slot={slot}
          premium={premium}
          lockedLabel={lockedLabel}
          onClick={() => {
            // Un slot disponible non-débloqué → paywall ; sinon flux normal.
            if (!slot.exam && !premium) {
              onLocked();
              return;
            }
            onSlotClick(slot);
          }}
        />
      ))}
    </div>
  );
}

function SlotCard({
  slot,
  premium,
  lockedLabel,
  onClick,
}: {
  slot: FullExamSlotData;
  premium: boolean;
  lockedLabel: string;
  onClick: () => void;
}) {
  const { exam, number } = slot;

  if (!exam) {
    const locked = !premium;
    return (
      <button
        type="button"
        className={`${s.slotCard} ${locked ? s.locked : ""}`}
        onClick={onClick}
        aria-label={`Examen blanc ${number}`}
      >
        <span className={s.slotNum}>Épreuve {number}</span>
        <span className={s.slotStatus}>{locked ? lockedLabel : "Disponible"}</span>
        {locked ? (
          <Lock size={16} className={s.slotIconMuted} />
        ) : (
          <Plus size={16} className={s.slotIconMuted} />
        )}
      </button>
    );
  }

  if (exam.status === "IN_PROGRESS") {
    return (
      <button type="button" className={`${s.slotCard} ${s.inProgress}`} onClick={onClick}>
        <span className={s.slotNum}>Épreuve {number}</span>
        <span className={`${s.slotStatus} ${s.slotStatusAmber}`}>En cours</span>
        <ChevronRight size={16} className={s.slotIconAmber} />
      </button>
    );
  }

  if (exam.status === "COMPLETED") {
    return (
      <button type="button" className={`${s.slotCard} ${s.completed}`} onClick={onClick}>
        <span className={s.slotNum}>Épreuve {number}</span>
        {exam.finalCecrlLevel ? (
          <span className={s.slotLevel}>{niveauCecrlLabel(exam.finalCecrlLevel)}</span>
        ) : (
          <span className={s.slotStatus}>Terminé</span>
        )}
        <ChevronRight size={16} className={s.slotIconGreen} />
      </button>
    );
  }

  // PENDING_EVALUATIONS
  return (
    <button type="button" className={`${s.slotCard} ${s.inProgress}`} onClick={onClick}>
      <span className={s.slotNum}>Épreuve {number}</span>
      <span className={`${s.slotStatus} ${s.slotStatusAmber}`}>Éval en cours…</span>
      <ChevronRight size={16} className={s.slotIconAmber} />
    </button>
  );
}
