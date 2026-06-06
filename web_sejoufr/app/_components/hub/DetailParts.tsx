"use client";

import Link from "next/link";
import { ArrowLeft, ArrowRight, Check, Lock, Play, RotateCw } from "lucide-react";
import type { AttemptSummaryResponse, LotDto } from "@/lib/types";
import { ProgressDonut } from "./ModuleHubParts";
import styles from "./detail.module.css";

/**
 * Briques des pages détail d'entraînement (maquette sejour_fr.html) :
 * shell back + eyebrow + titre, cards de niveau TCF, carte de progression +
 * cards de série (ex-lots), stat cards et grille d'examens blancs.
 */

export function DetailShell({
  backHref,
  backLabel,
  eyebrowIcon,
  eyebrow,
  title,
  subtitle,
  action,
  children,
}: {
  backHref: string;
  backLabel: string;
  eyebrowIcon: React.ReactNode;
  eyebrow: string;
  title: string;
  subtitle: string;
  action?: React.ReactNode;
  children: React.ReactNode;
}) {
  return (
    <main className={styles.wrap}>
      <Link href={backHref} className={styles.back}>
        <ArrowLeft size={16} aria-hidden />
        {backLabel}
      </Link>
      <header className={styles.head}>
        <div className={styles.headText}>
          <div className={styles.eyebrow}>
            <span aria-hidden>{eyebrowIcon}</span>
            <span className={styles.eyebrowLabel}>{eyebrow}</span>
          </div>
          <h1 className={styles.title}>{title}</h1>
          <p className={styles.subtitle}>{subtitle}</p>
        </div>
        {action && <div className={styles.headActions}>{action}</div>}
      </header>
      {children}
    </main>
  );
}

// ---------- Choix de niveau (TCF) ----------

/**
 * Card de niveau CECRL : chip A2/B1/B2 + donut (moyenne des séries faites),
 * libellé, description et compteur "x/y séries faites".
 */
export function LevelChoiceCard({
  chip,
  title,
  desc,
  percent,
  done,
  total,
  onClick,
}: {
  chip: string;
  title: string;
  desc: string;
  /** Moyenne des derniers scores sur les séries faites (0-100), null si aucune. */
  percent: number | null;
  done: number;
  total: number | null;
  onClick: () => void;
}) {
  return (
    <button type="button" className={styles.levelCard} onClick={onClick}>
      <div className={styles.levelTop}>
        <span className={styles.levelChip}>{chip}</span>
        <ProgressDonut percent={percent} />
      </div>
      <div>
        <h3 className={styles.levelTitle}>{title}</h3>
        <p className={styles.levelDesc}>{desc}</p>
      </div>
      <div className={styles.levelFoot}>
        <span className={styles.levelCount}>
          {total !== null ? `${done}/${total} séries faites` : "Séries en préparation"}
        </span>
        <ArrowRight size={18} className={styles.levelArrow} aria-hidden />
      </div>
    </button>
  );
}

// ---------- Séries ----------

/** Carte de progression "N séries sur M faites" avec donut + barre. */
export function SeriesProgressCard({ done, total }: { done: number; total: number }) {
  const percent = total > 0 ? Math.round((done / total) * 100) : 0;
  return (
    <div className={styles.progressCard}>
      <ProgressDonut percent={percent} />
      <div className={styles.progressBody}>
        <div className={styles.progressLabel}>
          {done} série{done > 1 ? "s" : ""} sur {total} faite{done > 1 ? "s" : ""}
        </div>
        <div className={styles.progressTrack}>
          <span className={styles.progressFill} style={{ width: `${percent}%` }} />
        </div>
      </div>
    </div>
  );
}

/**
 * Card de série (ex-lot) : numéro (vert + check quand faite), "Série N ·
 * 20 questions", badge Meilleur X/Y / Pas encore commencé / Premium, icône
 * refaire / lancer / cadenas.
 */
export function SerieCard({
  lot,
  locked,
  disabled,
  onClick,
}: {
  lot: LotDto;
  locked: boolean;
  disabled: boolean;
  onClick: () => void;
}) {
  const done = lot.lastScore != null;
  return (
    <button
      type="button"
      className={styles.serieCard}
      onClick={onClick}
      disabled={disabled}
    >
      <span className={`${styles.serieNum} ${done ? styles.serieNumDone : ""}`}>
        {lot.numero}
        {done && (
          <span className={styles.serieCheck} aria-hidden>
            <Check size={11} strokeWidth={3} />
          </span>
        )}
      </span>
      <span className={styles.serieBody}>
        <span className={styles.serieTitle}>Série {lot.numero}</span>
        <span className={styles.serieSub}>{lot.totalQuestions} questions</span>
        {locked ? (
          <span className={`${styles.serieBadge} ${styles.serieBadgeLock}`}>
            <Lock size={11} aria-hidden /> Premium
          </span>
        ) : done ? (
          <span className={`${styles.serieBadge} ${styles.serieBadgeDone}`}>
            <Check size={12} aria-hidden /> Meilleur {lot.lastScore}/{lot.totalQuestions}
          </span>
        ) : (
          <span className={`${styles.serieBadge} ${styles.serieBadgeTodo}`}>
            Pas encore commencée
          </span>
        )}
      </span>
      <span className={styles.serieAction} aria-hidden>
        {locked ? (
          <Lock size={17} />
        ) : done ? (
          <RotateCw size={18} />
        ) : (
          <Play size={18} />
        )}
      </span>
    </button>
  );
}

// ---------- Examens blancs ----------

/** Stat card compacte de la page examens (icône teintée + valeur + libellés). */
export function DetailStatCard({
  icon,
  tone,
  value,
  label,
  sub,
}: {
  icon: React.ReactNode;
  tone: "blue" | "red" | "green";
  value: string;
  label: string;
  sub: string;
}) {
  const toneClass =
    tone === "red"
      ? styles.statIconRed
      : tone === "green"
        ? styles.statIconGreen
        : styles.statIconBlue;
  return (
    <div className={styles.statCard}>
      <span className={`${styles.statIcon} ${toneClass}`} aria-hidden>
        {icon}
      </span>
      <div className={styles.statBody}>
        <div className={styles.statValue}>{value}</div>
        <div className={styles.statLabel}>{label}</div>
        <div className={styles.statSub}>{sub}</div>
      </div>
    </div>
  );
}

/**
 * Grille de 1..count examens : les examens finis remplissent les premières
 * cards (ordre chronologique), les suivantes sont à passer. Examen 1 gratuit
 * (freeSlots), au-delà premium → onLocked.
 */
export function ExamsGrid({
  count,
  exams,
  premium,
  freeSlots = 1,
  starting,
  onStart,
  onLocked,
}: {
  count: number;
  /** Examens finis, triés du plus ancien au plus récent. */
  exams: AttemptSummaryResponse[];
  premium: boolean;
  freeSlots?: number;
  starting: boolean;
  onStart: () => void;
  onLocked: () => void;
}) {
  return (
    <div className={styles.examGrid}>
      {Array.from({ length: count }, (_, i) => {
        const slot = i + 1;
        const exam = exams[i] ?? null;
        const locked = !premium && slot > freeSlots;
        return (
          <ExamCard
            key={slot}
            slot={slot}
            exam={
              exam
                ? { id: exam.id, score: exam.score ?? null, total: exam.totalQuestions }
                : null
            }
            locked={locked}
            starting={starting}
            passThresholdMet={
              exam && exam.passThreshold != null
                ? (exam.score ?? 0) >= exam.passThreshold
                : null
            }
            onStart={onStart}
            onLocked={onLocked}
          />
        );
      })}
    </div>
  );
}

/**
 * Card d'examen blanc : numéro 01..20, dernier score ou "Nouveau", CTAs
 * Refaire + Rapport (fait) / Démarrer (à passer) / Premium (verrouillé).
 */
export function ExamCard({
  slot,
  exam,
  locked,
  starting,
  passThresholdMet,
  onStart,
  onLocked,
}: {
  slot: number;
  exam: { id: string; score: number | null; total: number | null } | null;
  locked: boolean;
  starting: boolean;
  passThresholdMet: boolean | null;
  onStart: () => void;
  onLocked: () => void;
}) {
  const done = exam !== null;
  return (
    <article className={`${styles.examCard} ${done ? styles.examCardDone : ""}`}>
      <span className={`${styles.examNum} ${done ? styles.examNumDone : ""}`}>
        {String(slot).padStart(2, "0")}
      </span>
      <span className={styles.examTitle}>Examen {slot}</span>
      {done ? (
        <span className={styles.examMeta}>
          Dernier :{" "}
          <span
            className={`${styles.examMetaScore} ${
              passThresholdMet === false ? styles.examMetaLow : styles.examMetaGood
            }`}
          >
            {exam.score ?? 0}/{exam.total ?? "—"}
          </span>
        </span>
      ) : (
        <span className={styles.examMeta}>Nouveau</span>
      )}
      <div className={styles.examBtns}>
        {done ? (
          <>
            <button
              type="button"
              className={styles.examBtn}
              onClick={locked ? onLocked : onStart}
              disabled={!locked && starting}
            >
              <RotateCw size={15} aria-hidden /> Refaire
            </button>
            <Link href={`/sessions/${exam.id}`} className={styles.examBtn}>
              Rapport
            </Link>
          </>
        ) : locked ? (
          <button
            type="button"
            className={`${styles.examBtn} ${styles.examBtnLocked}`}
            onClick={onLocked}
          >
            <Lock size={14} aria-hidden /> Premium
          </button>
        ) : (
          <button
            type="button"
            className={styles.examBtn}
            onClick={onStart}
            disabled={starting}
          >
            <Play size={15} aria-hidden /> Démarrer
          </button>
        )}
      </div>
    </article>
  );
}
