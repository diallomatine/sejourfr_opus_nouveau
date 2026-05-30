"use client";

import Link from "next/link";
import type {CSSProperties, ReactNode} from "react";
import {ChevronLeft, ChevronRight, Lock, Play, Rocket} from "lucide-react";
import type {AttemptSummaryResponse, LotDto} from "@/lib/types";
import styles from "./hub.module.css";

// ============================================================================
// Briques partagées des hubs Civique / TCF (miroir des widgets mobiles
// `hub_home_widgets.dart`). Accents pilotés par variables CSS inline.
// ============================================================================

export type HubTone = "blue" | "red" | "amber" | "green" | "slate";

/** Couleur d'accent + fond clair par tonalité (aligné sur AppColors mobile). */
const TONE: Record<HubTone, {accent: string; bg: string}> = {
  blue: {accent: "var(--color-blue)", bg: "var(--color-blue-light)"},
  red: {accent: "var(--color-red)", bg: "var(--color-red-light)"},
  amber: {accent: "#B87908", bg: "rgba(232, 163, 23, 0.16)"},
  green: {accent: "var(--color-green)", bg: "rgba(22, 143, 91, 0.12)"},
  slate: {accent: "var(--color-muted)", bg: "var(--color-paper-2)"},
};

// ---------- Header ----------

export function HubHeader({title, subtitle}: {title: string; subtitle: string}) {
  return (
    <div className={styles.header}>
      <div>
        <h1 className={styles.headerTitle}>{title}</h1>
        <p className={styles.headerSub}>{subtitle}</p>
      </div>
    </div>
  );
}

// ---------- Hero examen blanc ----------

export function ExamBlancHero({
  eyebrow,
  title,
  description,
  ctaLabel,
  accent = "blue",
  onClick,
}: {
  eyebrow: string;
  title: string;
  description: string;
  ctaLabel: string;
  accent?: "blue" | "red";
  onClick: () => void;
}) {
  const vars =
    accent === "red"
      ? {
          "--accent-start": "var(--color-red)",
          "--accent-end": "var(--color-red-dark)",
          "--accent-shadow": "rgba(225, 55, 47, 0.45)",
        }
      : {
          "--accent-start": "var(--color-blue)",
          "--accent-end": "var(--color-blue-dark)",
          "--accent-shadow": "rgba(30, 58, 140, 0.5)",
        };
  return (
    <button type="button" className={styles.hero} style={vars as CSSProperties} onClick={onClick}>
      <span className={styles.heroEyebrow}>
        <Rocket size={13} strokeWidth={2.2} />
        {eyebrow.toUpperCase()}
      </span>
      <span className={styles.heroTitle} style={{display: "block"}}>
        {title}
      </span>
      <span className={styles.heroDesc} style={{display: "block"}}>
        {description}
      </span>
      <span className={styles.heroCta}>
        <Play size={15} strokeWidth={2.4} fill="currentColor" />
        {ctaLabel}
      </span>
    </button>
  );
}

// ---------- Section label ----------

export function SectionLabel({label, trailing}: {label: string; trailing?: ReactNode}) {
  return (
    <div className={styles.sectionRow}>
      <p className={styles.sectionLabel}>{label}</p>
      {trailing}
    </div>
  );
}

export function SectionCounter({text}: {text: string}) {
  return <span className={styles.sectionCounter}>{text}</span>;
}

export function SectionLink({label, onClick}: {label: string; onClick: () => void}) {
  return (
    <button type="button" className={styles.sectionLink} onClick={onClick}>
      {label}
    </button>
  );
}

// ---------- Carte épreuve / thème ----------

export function EpreuveCard({
  icon,
  tone,
  title,
  subtitle,
  pill,
  progress,
  locked = false,
  onClick,
}: {
  icon: ReactNode;
  tone: HubTone;
  title: string;
  subtitle: string;
  pill?: string | null;
  /** 0..1 ; null = pas de barre. */
  progress?: number | null;
  locked?: boolean;
  onClick: () => void;
}) {
  const t = TONE[tone];
  const pct = progress == null ? null : Math.round(Math.min(1, Math.max(0, progress)) * 100);
  return (
    <button
      type="button"
      className={styles.epreuve}
      style={{"--accent": t.accent, "--accent-bg": t.bg} as CSSProperties}
      onClick={onClick}
    >
      <span className={styles.epreuveIcon}>{icon}</span>
      <span className={styles.epreuveBody}>
        <span className={styles.epreuveTitleRow}>
          <span className={styles.epreuveTitle}>{title}</span>
          {pill ? <span className={styles.epreuvePill}>{pill}</span> : null}
        </span>
        <span className={styles.epreuveSub}>{subtitle}</span>
        {pct != null && (
          <span className={styles.epreuveBarRow}>
            <span className={styles.epreuveTrack}>
              <span className={styles.epreuveFill} style={{width: `${pct}%`}} />
            </span>
            <span className={styles.epreuvePct}>{pct}%</span>
          </span>
        )}
      </span>
      {locked ? (
        <Lock size={16} className={styles.epreuveChevron} />
      ) : (
        <ChevronRight size={20} className={styles.epreuveChevron} />
      )}
    </button>
  );
}

// ---------- En-tête de page détail (back + titre) ----------

export function HubDetailHeader({
  backHref,
  title,
  subtitle,
}: {
  backHref: string;
  title: string;
  subtitle: string;
}) {
  return (
    <div className={styles.detailHeader}>
      <Link href={backHref} className={styles.backBtn} aria-label="Retour">
        <ChevronLeft size={20} />
      </Link>
      <div>
        <h1 className={styles.headerTitle}>{title}</h1>
        <p className={styles.headerSub}>{subtitle}</p>
      </div>
    </div>
  );
}

// ---------- Ligne de lot (Civique thème / TCF niveau) ----------

/** Classe couleur d'un score en fonction du ratio. */
function scoreClass(score: number, total: number): string {
  if (total <= 0) return styles.scoreMid;
  const r = score / total;
  if (r >= 0.7) return styles.scoreGood;
  if (r >= 0.4) return styles.scoreMid;
  return styles.scoreLow;
}

export function LotRow({
  lot,
  tone,
  locked = false,
  disabled = false,
  onClick,
}: {
  lot: LotDto;
  tone: HubTone;
  locked?: boolean;
  disabled?: boolean;
  onClick: () => void;
}) {
  const t = TONE[tone];
  const done = lot.lastScore != null;
  return (
    <button
      type="button"
      className={styles.lotRow}
      style={{"--accent": t.accent, "--accent-bg": t.bg} as CSSProperties}
      onClick={onClick}
      disabled={disabled}
    >
      <span className={styles.lotNum}>{lot.numero}</span>
      <span className={styles.lotBody}>
        <span className={styles.lotTitle}>Lot {lot.numero}</span>
        <span className={styles.lotSub}>
          {lot.totalQuestions} questions
          {done ? " · déjà fait" : ""}
        </span>
      </span>
      {locked ? (
        <Lock size={16} className={styles.rowChevron} />
      ) : done ? (
        <span className={`${styles.scoreBadge} ${scoreClass(lot.lastScore!, lot.totalQuestions)}`}>
          {lot.lastScore}/{lot.totalQuestions}
        </span>
      ) : (
        <ChevronRight size={20} className={styles.rowChevron} />
      )}
    </button>
  );
}

// ---------- Historique compact d'examens ----------

export function ExamHistoryList({items}: {items: AttemptSummaryResponse[]}) {
  if (items.length === 0) {
    return <p className={styles.empty}>Aucun examen passé pour l&apos;instant.</p>;
  }
  return (
    <div className={styles.histList}>
      {items.map((a) => {
        const total = a.totalQuestions ?? 0;
        const score = a.score ?? 0;
        return (
          <Link key={a.id} href={`/sessions/${a.id}`} className={styles.histRow}>
            <span className={styles.histDate}>{formatDay(a.startedAt)}</span>
            {total > 0 && (
              <span className={`${styles.scoreBadge} ${scoreClass(score, total)}`}>
                {score}/{total}
              </span>
            )}
            <ChevronRight size={18} className={styles.rowChevron} />
          </Link>
        );
      })}
    </div>
  );
}

export function SeeMoreButton({label, onClick}: {label: string; onClick: () => void}) {
  return (
    <button type="button" className={styles.seeMore} onClick={onClick}>
      {label}
    </button>
  );
}

function formatDay(iso: string): string {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "—";
  return d.toLocaleDateString("fr-FR", {day: "2-digit", month: "short", year: "numeric"});
}

// ---------- Carte maîtrise (Civique) ----------

export function CiviqueMasteryCard({
  answered,
  correct,
  total,
}: {
  answered: number;
  correct: number;
  total: number;
}) {
  const pct = answered > 0 ? Math.round((correct / answered) * 100) : 0;
  const coverage = total > 0 ? Math.min(1, answered / total) : 0;
  return (
    <div className={styles.mastery}>
      <div className={styles.masteryTop}>
        <span className={styles.masteryPct}>{answered > 0 ? `${pct}%` : "—"}</span>
        <span className={styles.masteryPctLabel}>de bonnes réponses</span>
      </div>
      <div className={styles.masteryCoverage}>
        <span>Couverture de la banque</span>
        <span className={styles.masteryCoverageVal}>
          {answered}/{total} questions
        </span>
      </div>
      <div className={styles.masteryTrack}>
        <div className={styles.masteryFill} style={{width: `${Math.round(coverage * 100)}%`}} />
      </div>
    </div>
  );
}
