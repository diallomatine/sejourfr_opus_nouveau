"use client";

import Link from "next/link";
import { useState } from "react";
import {
  ArrowLeft,
  ArrowRight,
  Check,
  ChevronDown,
  ChevronUp,
  Lock,
  Play,
  RotateCw,
} from "lucide-react";
import type { LotDto } from "@/lib/types";
import { ProgressDonut } from "./ModuleHubParts";
import styles from "./detail.module.css";

/** Donnée minimale d'un examen fini pour la grille (AttemptSummaryResponse
 *  est compatible ; les sessions de production EE/EO construisent la leur). */
export interface ExamSlotData {
  id: string;
  score?: number | null;
  totalQuestions?: number | null;
  passThreshold?: number | null;
  /** Remplace l'affichage « Dernier : score/total » (ex: niveau CECRL d'un
   *  examen TCF complet, « Éval en cours… »). */
  metaOverride?: string | null;
  /** Examen réussi/terminé → check vert sur le numéro. Si omis, on dérive du
   *  seuil (`passThreshold`) ; un examen sans seuil ni métadonnée « en cours »
   *  compte comme réussi. */
  passed?: boolean | null;
}

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
const LEVEL_CHIP_TONES = {
  blue: "",
  green: styles.levelChipGreen,
  amber: styles.levelChipAmber,
  red: styles.levelChipRed,
} as const;

export function LevelChoiceCard({
  chip,
  chipTone = "blue",
  title,
  desc,
  percent,
  done,
  total,
  footLabel,
  onClick,
}: {
  chip: string;
  /** Tonalité du chip (caractère par tâche : T1 bleu, T2 ambre, T3 rouge). */
  chipTone?: keyof typeof LEVEL_CHIP_TONES;
  title: string;
  desc: string;
  /** Moyenne des derniers scores sur les séries faites (0-100), null si aucune. */
  percent: number | null;
  done?: number;
  total?: number | null;
  /** Remplace le compteur "x/y séries faites" (ex: "Dernière note 14/20"). */
  footLabel?: string;
  onClick: () => void;
}) {
  return (
    <button type="button" className={styles.levelCard} onClick={onClick}>
      <div className={styles.levelTop}>
        <span className={`${styles.levelChip} ${LEVEL_CHIP_TONES[chipTone]}`}>{chip}</span>
        <ProgressDonut percent={percent} />
      </div>
      <div>
        <h3 className={styles.levelTitle}>{title}</h3>
        <p className={styles.levelDesc}>{desc}</p>
      </div>
      <div className={styles.levelFoot}>
        <span className={styles.levelCount}>
          {footLabel ??
            (total != null ? `${done ?? 0}/${total} séries faites` : "Séries en préparation")}
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
  lockedLabel = "Premium",
  disabled,
  onClick,
}: {
  lot: LotDto;
  locked: boolean;
  /** Texte du badge verrouillé — "Compte gratuit" en contexte guest. */
  lockedLabel?: string;
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
            <Lock size={11} aria-hidden /> {lockedLabel}
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
 * (freeSlots), au-delà premium → onLocked. `collapsedCount` replie la grille
 * à N cards avec un bouton "Voir tout" (jamais moins que les examens faits).
 */
export function ExamsGrid({
  count,
  exams,
  premium,
  freeSlots = 1,
  starting,
  itemLabel = "Examen",
  lockedLabel,
  collapsedCount,
  reportPath,
  onStart,
  onLocked,
}: {
  count: number;
  /** Examens finis. Soit une liste dense (case i = i-ᵉ examen), soit un
   *  tableau indexé par slot (case i = examen du slot i+1, trous à null). */
  exams: ReadonlyArray<ExamSlotData | null>;
  premium: boolean;
  freeSlots?: number;
  starting: boolean;
  itemLabel?: string;
  /** Texte des slots verrouillés — "Compte gratuit" en contexte guest. */
  lockedLabel?: string;
  collapsedCount?: number;
  /** Cible du bouton Rapport (défaut : /sessions/{id}). */
  reportPath?: (attemptId: string) => string;
  /** Reçoit le numéro de slot (1..count) — utile quand « Démarrer » doit cibler
   *  un slot précis (examen TCF complet). Les autres usages l'ignorent. */
  onStart: (slot: number) => void;
  onLocked: () => void;
}) {
  const [expanded, setExpanded] = useState(false);
  // Replié, on montre au moins toutes les cards déjà faites + la prochaine.
  const doneCount = exams.filter(Boolean).length;
  const visibleCount =
    collapsedCount && !expanded
      ? Math.min(count, Math.max(collapsedCount, Math.min(doneCount + 1, count)))
      : count;

  return (
    <>
      <div className={styles.examGrid}>
        {Array.from({ length: visibleCount }, (_, i) => {
          const slot = i + 1;
          const exam = exams[i] ?? null;
          const locked = !premium && slot > freeSlots;
          const passThresholdMet =
            exam && exam.passThreshold != null
              ? (exam.score ?? 0) >= exam.passThreshold
              : null;
          // Check vert : état explicite si fourni, sinon seuil franchi, sinon
          // examen sans seuil ni « en cours » = terminé (diagnostic, etc.).
          const passed =
            exam == null
              ? null
              : exam.passed != null
                ? exam.passed
                : passThresholdMet != null
                  ? passThresholdMet
                  : exam.metaOverride == null
                    ? true
                    : null;
          return (
            <ExamCard
              key={slot}
              slot={slot}
              itemLabel={itemLabel}
              exam={
                exam
                  ? {
                      id: exam.id,
                      score: exam.score ?? null,
                      total: exam.totalQuestions ?? null,
                      metaOverride: exam.metaOverride ?? null,
                    }
                  : null
              }
              reportHref={exam ? (reportPath?.(exam.id) ?? `/sessions/${exam.id}`) : undefined}
              locked={locked}
              lockedLabel={lockedLabel}
              starting={starting}
              passThresholdMet={passThresholdMet}
              passed={passed}
              onStart={onStart}
              onLocked={onLocked}
            />
          );
        })}
      </div>
      {collapsedCount != null && count > visibleCount && (
        <button
          type="button"
          className={styles.seeAll}
          onClick={() => setExpanded(true)}
        >
          Voir tout ({count}) <ChevronDown size={15} aria-hidden />
        </button>
      )}
      {collapsedCount != null && expanded && (
        <button
          type="button"
          className={styles.seeAll}
          onClick={() => setExpanded(false)}
        >
          Réduire <ChevronUp size={15} aria-hidden />
        </button>
      )}
    </>
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
  lockedLabel = "Premium",
  starting,
  passThresholdMet,
  passed = null,
  itemLabel = "Examen",
  reportHref,
  onStart,
  onLocked,
}: {
  slot: number;
  exam: {
    id: string;
    score: number | null;
    total: number | null;
    metaOverride?: string | null;
  } | null;
  locked: boolean;
  /** Texte du bouton verrouillé — "Compte gratuit" en contexte guest. */
  lockedLabel?: string;
  starting: boolean;
  passThresholdMet: boolean | null;
  /** Examen réussi/terminé → check vert sur le numéro. */
  passed?: boolean | null;
  itemLabel?: string;
  /** Cible du bouton Rapport (défaut : /sessions/{id}). */
  reportHref?: string;
  onStart: (slot: number) => void;
  onLocked: () => void;
}) {
  const done = exam !== null;
  return (
    <article className={`${styles.examCard} ${done ? styles.examCardDone : ""}`}>
      <span className={`${styles.examNum} ${done ? styles.examNumDone : ""}`}>
        {String(slot).padStart(2, "0")}
        {passed === true && (
          <span
            className={`${styles.examCheck} ${
              passThresholdMet === false ? styles.examCheckFail : ""
            }`}
            aria-label={passThresholdMet === false ? "Passé, non réussi" : "Réussi"}
          >
            <Check size={12} strokeWidth={3} aria-hidden />
          </span>
        )}
      </span>
      <span className={styles.examTitle}>
        {itemLabel} {slot}
      </span>
      {done ? (
        exam.metaOverride != null ? (
          <span className={styles.examMeta}>
            <span className={`${styles.examMetaScore} ${styles.examMetaGood}`}>
              {exam.metaOverride}
            </span>
          </span>
        ) : (
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
        )
      ) : (
        <span className={styles.examMeta}>Nouveau</span>
      )}
      <div className={styles.examBtns}>
        {done ? (
          <>
            <button
              type="button"
              className={styles.examBtn}
              onClick={locked ? onLocked : () => onStart(slot)}
              disabled={!locked && starting}
            >
              <RotateCw size={15} aria-hidden /> Refaire
            </button>
            <Link href={reportHref ?? `/sessions/${exam.id}`} className={styles.examBtn}>
              Rapport
            </Link>
          </>
        ) : locked ? (
          <button
            type="button"
            className={`${styles.examBtn} ${styles.examBtnLocked}`}
            onClick={onLocked}
          >
            <Lock size={14} aria-hidden /> {lockedLabel}
          </button>
        ) : (
          <button
            type="button"
            className={styles.examBtn}
            onClick={() => onStart(slot)}
            disabled={starting}
          >
            <Play size={15} aria-hidden /> Démarrer
          </button>
        )}
      </div>
    </article>
  );
}
