"use client";

import Link from "next/link";
import type {CSSProperties} from "react";
import {useMemo, useState} from "react";
import {ChevronRight, Lock} from "lucide-react";
import type {AttemptSummaryResponse} from "@/lib/types";
import styles from "./hub.module.css";

type Filter = "all" | "todo" | "done";

const ACCENT: Record<"blue" | "red", {accent: string; bg: string}> = {
  blue: {accent: "var(--color-blue)", bg: "var(--color-blue-light)"},
  red: {accent: "var(--color-red)", bg: "var(--color-red-light)"},
};

/**
 * Vue « Examens blancs » en grille de slots, calquée sur les écrans
 * `*_exams_screen.dart` mobiles : stats (Terminés / Score moyen / Meilleur) +
 * barre de progression + chips de filtre + N slots numérotés. Slot 1 gratuit,
 * 2+ premium (paramétrable via `freeSlots`). Les slots remplis pointent vers
 * la session finie ; les slots vides lancent un nouvel examen via `onStart`.
 */
export function ExamSlotsView({
  count,
  exams,
  premium,
  starting,
  accent = "blue",
  freeSlots = 1,
  onStart,
  onLocked,
}: {
  count: number;
  exams: AttemptSummaryResponse[];
  premium: boolean;
  starting: boolean;
  accent?: "blue" | "red";
  freeSlots?: number;
  onStart: () => void;
  onLocked: () => void;
}) {
  const [filter, setFilter] = useState<Filter>("all");
  const a = ACCENT[accent];
  const vars = {"--accent": a.accent, "--accent-bg": a.bg} as CSSProperties;

  const done = Math.min(exams.length, count);
  const stats = useMemo(() => {
    const scored = exams.slice(0, count).map((e) => e.score ?? 0);
    const avg = scored.length ? Math.round(scored.reduce((s, v) => s + v, 0) / scored.length) : 0;
    const best = scored.length ? Math.max(...scored) : 0;
    return {avg, best};
  }, [exams, count]);

  // Index du premier slot vide (= prochain à faire), pour le badge.
  const nextEmpty = done < count ? done : -1;

  const slots = Array.from({length: count}, (_, i) => ({slot: i + 1, exam: exams[i] ?? null}));
  const visible = slots.filter((s) =>
    filter === "all" ? true : filter === "done" ? s.exam != null : s.exam == null,
  );

  return (
    <div style={vars}>
      <div className={styles.examStats}>
        <div className={styles.statCell}>
          <div className={styles.statVal}>
            {done}/{count}
          </div>
          <div className={styles.statLabel}>Terminés</div>
        </div>
        <div className={styles.statCell}>
          <div className={styles.statVal}>{done > 0 ? stats.avg : "—"}</div>
          <div className={styles.statLabel}>Score moyen</div>
        </div>
        <div className={styles.statCell}>
          <div className={styles.statVal}>{done > 0 ? stats.best : "—"}</div>
          <div className={styles.statLabel}>Meilleur</div>
        </div>
      </div>

      <div className={styles.progressWrap} style={{marginTop: 14}}>
        <div className={styles.progressTop}>
          <span>Progression</span>
          <span>
            {done}/{count}
          </span>
        </div>
        <div className={styles.progressTrack}>
          <div className={styles.progressFill} style={{width: `${(done / count) * 100}%`}} />
        </div>
      </div>

      <div className={styles.chips} style={{marginTop: 16}}>
        {(
          [
            ["all", `Tous · ${count}`],
            ["todo", "À faire"],
            ["done", "Terminés"],
          ] as [Filter, string][]
        ).map(([key, label]) => (
          <button
            key={key}
            type="button"
            className={`${styles.chip} ${filter === key ? styles.chipActive : ""}`}
            onClick={() => setFilter(key)}
          >
            {label}
          </button>
        ))}
      </div>

      <div className={styles.list} style={{marginTop: 14}}>
        {visible.map(({slot, exam}) => {
          if (exam) {
            const total = exam.totalQuestions ?? 0;
            const score = exam.score ?? 0;
            const ok = exam.passThreshold != null && score >= exam.passThreshold;
            return (
              <Link key={exam.id} href={`/sessions/${exam.id}`} className={styles.slotCard}>
                <span className={styles.slotNum}>{slot}</span>
                <span className={styles.slotBody}>
                  <span className={styles.slotTitle}>Examen {slot}</span>
                  <span className={styles.slotSub}>{ok ? "Réussi" : "Sous le seuil"}</span>
                </span>
                <span
                  className={`${styles.scoreBadge} ${ok ? styles.scoreGood : styles.scoreLow}`}
                >
                  {score}/{total || "—"}
                </span>
              </Link>
            );
          }
          const locked = !premium && slot > freeSlots;
          const isNext = slot - 1 === nextEmpty;
          return (
            <button
              key={`slot-${slot}`}
              type="button"
              className={`${styles.slotCard} ${locked ? styles.slotLocked : ""}`}
              onClick={locked ? onLocked : onStart}
              disabled={locked ? false : starting}
            >
              <span className={styles.slotNum}>{slot}</span>
              <span className={styles.slotBody}>
                <span className={styles.slotTitle}>
                  Examen {slot}
                  {isNext && !locked && <span className={styles.nextChip}>À faire ensuite</span>}
                  {locked && <span className={styles.lockChip}>Premium</span>}
                </span>
                <span className={styles.slotSub}>
                  {locked ? "Réservé aux abonnés" : starting ? "Préparation…" : "À passer"}
                </span>
              </span>
              {locked ? (
                <Lock size={16} className={styles.rowChevron} />
              ) : (
                <ChevronRight size={20} className={styles.rowChevron} />
              )}
            </button>
          );
        })}
      </div>
    </div>
  );
}
