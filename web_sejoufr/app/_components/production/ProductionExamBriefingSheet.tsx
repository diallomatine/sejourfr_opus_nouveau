"use client";

import {useEffect} from "react";
import {Lightbulb, Mic, PenLine, Play, Timer} from "lucide-react";
import type {ProductionTaskDto} from "@/lib/types";
import {productionTaskTitle} from "@/lib/types";
import {plannedEpreuveLabel} from "@/lib/exam-durations";
import {
  PRODUCTION_EXAM_BRIEFING_CANCEL,
  PRODUCTION_EXAM_BRIEFING_CONSEIL,
  PRODUCTION_EXAM_BRIEFING_DEROULE,
  PRODUCTION_EXAM_BRIEFING_START,
  PRODUCTION_EXAM_BRIEFING_STARTING,
  productionExamBriefingConseil,
  productionExamBriefingEyebrow,
  productionExamBriefingIntro,
  productionExamBriefingTitle,
  productionExamTaskConstraint,
  productionExamTaskDetail,
} from "@/lib/production-exam-copy";
import {EE_CONFIG, EO_CONFIG} from "./config";
import x from "./exam.module.css";

const TACHES = [1, 2, 3] as const;

/**
 * **La feuille d'information d'un examen blanc EE/EO**, avant tout démarrage.
 * Miroir de `ProductionExamBriefingSheet` (mobile), brique pour brique :
 * sur-titre + durée, carte bleue « Prêt à écrire ? », déroulé des 3 tâches,
 * conseil, « Commencer maintenant ».
 *
 * 🛑 **Rien n'est démarré tant qu'elle est ouverte** : l'attempt — donc son
 * `startedAt`, l'ancre du chrono servi — ne naît qu'au clic « Commencer ».
 *
 * La contrainte de chaque tâche (« 30-60 mots », « 3 min ») est lue sur les
 * sujets **servis** (`tasks`) ; tant qu'ils ne sont pas là, la ligne s'affiche
 * sans elle — jamais un chiffre de repli.
 */
export function ProductionExamBriefingSheet({
  open,
  epreuve,
  tasks,
  starting,
  error,
  onStart,
  onClose,
}: {
  open: boolean;
  epreuve: "TCF_EE" | "TCF_EO";
  tasks: readonly ProductionTaskDto[] | null;
  starting: boolean;
  error: string | null;
  onStart: () => void;
  onClose: () => void;
}) {
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape" && !starting) onClose();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [open, starting, onClose]);

  if (!open) return null;

  const config = epreuve === "TCF_EO" ? EO_CONFIG : EE_CONFIG;
  const oral = epreuve === "TCF_EO";
  const durationLabel = plannedEpreuveLabel(epreuve);
  const Icon = oral ? Mic : PenLine;

  return (
    <div className={x.overlay} onClick={() => !starting && onClose()} role="presentation">
      <div
        className={x.sheet}
        onClick={(e) => e.stopPropagation()}
        role="dialog"
        aria-modal="true"
        aria-labelledby="production-exam-briefing-title"
      >
        <div className={x.handle} aria-hidden />

        <div className={x.kickerRow}>
          <span className={x.kicker}>{productionExamBriefingEyebrow(config.label)}</span>
          <span className={x.durationBadge}>
            <Timer size={13} strokeWidth={2.4} aria-hidden />
            {durationLabel}
          </span>
        </div>

        <section className={x.hero}>
          <span className={x.heroIcon} aria-hidden>
            <Icon size={30} strokeWidth={2} />
          </span>
          <h2 id="production-exam-briefing-title" className={x.heroTitle}>
            {productionExamBriefingTitle(epreuve)}
          </h2>
          <p className={x.heroText}>{productionExamBriefingIntro(epreuve, durationLabel)}</p>
        </section>

        <section className={x.tasksCard}>
          <p className={x.sectionLabel}>{PRODUCTION_EXAM_BRIEFING_DEROULE}</p>
          <ol className={x.taskList}>
            {TACHES.map((n) => (
              <li key={n} className={x.taskRow}>
                <span className={x.taskNum} aria-hidden>
                  {n}
                </span>
                <span className={x.taskBody}>
                  <span className={x.taskTitle}>
                    Tâche {n} · {productionTaskTitle(epreuve, n)}
                  </span>
                  <span className={x.taskDetail}>
                    {productionExamTaskDetail(
                      epreuve,
                      n,
                      productionExamTaskConstraint(tasks, epreuve, n),
                    )}
                  </span>
                </span>
              </li>
            ))}
          </ol>
        </section>

        <section className={x.conseil}>
          <p className={x.conseilLabel}>
            <Lightbulb size={14} strokeWidth={2.2} aria-hidden />
            {PRODUCTION_EXAM_BRIEFING_CONSEIL}
          </p>
          <p className={x.conseilText}>{productionExamBriefingConseil(epreuve)}</p>
        </section>

        {error && <p className={x.error}>{error}</p>}

        <div className={x.actions}>
          <button
            type="button"
            className={`${x.btn} ${x.btnStart}`}
            onClick={onStart}
            disabled={starting}
          >
            <Play size={16} strokeWidth={2.4} aria-hidden />
            {starting ? PRODUCTION_EXAM_BRIEFING_STARTING : PRODUCTION_EXAM_BRIEFING_START}
          </button>
          <button
            type="button"
            className={`${x.btn} ${x.btnGhost}`}
            onClick={onClose}
            disabled={starting}
          >
            {PRODUCTION_EXAM_BRIEFING_CANCEL}
          </button>
        </div>
      </div>
    </div>
  );
}
