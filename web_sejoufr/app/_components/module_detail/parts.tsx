"use client";

import Link from "next/link";
import type { ReactNode } from "react";
import type {
  AttemptSummaryResponse,
  LotDto,
  QuestionReviewResponse,
} from "@/lib/types";
import { DualChromeShell } from "@/app/_components/DualChromeShell";
import styles from "./ModuleDetail.module.css";

/** Conteneur racine d'une page détail (sidebar + accent bleu/rouge). */
export function ModuleDetailShell({
  accent,
  children,
}: {
  accent: "blue" | "red";
  children: ReactNode;
}) {
  return (
    <DualChromeShell>
      <main className={styles.root} data-accent={accent}>
        {children}
      </main>
    </DualChromeShell>
  );
}

/** Écran d'invite à la connexion (visiteur non authentifié). */
export function ModuleDetailGate({ next }: { next: string }) {
  return (
    <main className={styles.gate}>
      <p>Connectez-vous pour accéder à cette page.</p>
      <Link href={`/connexion?next=${encodeURIComponent(next)}`} className={styles.gateCta}>
        Se connecter →
      </Link>
    </main>
  );
}

export function ModuleHero({
  eyebrow,
  title,
  description,
}: {
  eyebrow: string;
  title: string;
  description: string;
}) {
  return (
    <header className={styles.hero}>
      <span className={styles.eyebrow}>{eyebrow}</span>
      <h1>{title}</h1>
      <p>{description}</p>
    </header>
  );
}

export interface TabDef<K extends string> {
  key: K;
  label: string;
}

export function ModuleTabs<K extends string>({
  tabs,
  active,
  onChange,
}: {
  tabs: TabDef<K>[];
  active: K;
  onChange: (key: K) => void;
}) {
  return (
    <div className={styles.tabs} role="tablist">
      {tabs.map((t) => (
        <button
          key={t.key}
          type="button"
          role="tab"
          aria-selected={active === t.key}
          className={`${styles.tab} ${active === t.key ? styles.tabActive : ""}`}
          onClick={() => onChange(t.key)}
        >
          {t.label}
        </button>
      ))}
    </div>
  );
}

export function SkeletonGrid() {
  return (
    <div className={styles.grid}>
      {[0, 1, 2, 3, 4, 5].map((i) => (
        <div key={i} className={styles.skel} />
      ))}
    </div>
  );
}

/** Grille de lots (numéro, nb questions, dernier score). */
export function LotsGrid({
  lots,
  starting,
  onStart,
}: {
  lots: LotDto[];
  starting: boolean;
  onStart: (lot: LotDto) => void;
}) {
  return (
    <section className={styles.grid}>
      {lots.map((lot) => (
        <button
          type="button"
          key={lot.numero}
          className={`${styles.lot} ${lot.lastScore != null ? styles.lotDone : ""}`}
          onClick={() => onStart(lot)}
          disabled={starting}
        >
          <div className={styles.cardHead}>
            <span className={styles.cardNum}>Lot {lot.numero}</span>
            {lot.lastScore != null && (
              <span className={styles.lotScore}>
                {lot.lastScore}/{lot.totalQuestions}
              </span>
            )}
          </div>
          <p className={styles.cardMeta}>{lot.totalQuestions} questions</p>
          <span className={styles.cardCta}>
            {starting ? "…" : lot.lastScore != null ? "Refaire →" : "Commencer →"}
          </span>
        </button>
      ))}
    </section>
  );
}

/**
 * Grille de slots d'examen. Parité mobile : un abonné peut lancer n'importe
 * quel slot vide ; en gratuit seul le slot 1 est ouvert (2+ → paywall).
 */
export function ExamSlots({
  count,
  exams,
  premium,
  starting,
  onStart,
  onLocked,
}: {
  count: number;
  exams: AttemptSummaryResponse[];
  premium: boolean;
  starting: boolean;
  onStart: () => void;
  onLocked: () => void;
}) {
  const slots = Array.from({ length: count }, (_, i) => exams[i] ?? null);
  return (
    <div className={styles.grid}>
      {slots.map((ex, i) => {
        const slot = i + 1;
        if (ex) {
          const ok =
            ex.passThreshold != null && (ex.score ?? 0) >= ex.passThreshold;
          return (
            <Link
              key={ex.id}
              href={`/sessions/${ex.id}`}
              className={`${styles.exam} ${styles.examDone}`}
            >
              <div className={styles.cardHead}>
                <span className={styles.cardNum}>Examen {slot}</span>
                <span
                  className={`${styles.examBadge} ${ok ? styles.badgeOk : styles.badgeKo}`}
                >
                  {ex.score ?? 0}/{ex.totalQuestions ?? "—"}
                </span>
              </div>
              <p className={styles.cardMeta}>{ok ? "Réussi" : "Sous le seuil"}</p>
              <span className={styles.cardCta}>Voir →</span>
            </Link>
          );
        }
        const locked = !premium && slot > 1;
        return (
          <button
            type="button"
            key={`slot-${slot}`}
            className={`${styles.exam} ${locked ? styles.examLocked : styles.examNext}`}
            onClick={locked ? onLocked : onStart}
            disabled={locked ? false : starting}
          >
            <div className={styles.cardHead}>
              <span className={styles.cardNum}>Examen {slot}</span>
              {locked && <span className={styles.lockChip}>Premium</span>}
            </div>
            <p className={styles.cardMeta}>
              {locked ? "Réservé aux abonnés" : "À passer"}
            </p>
            <span className={styles.cardCta}>
              {locked ? "Débloquer →" : starting ? "…" : "Commencer →"}
            </span>
          </button>
        );
      })}
    </div>
  );
}

/** Liste des questions ratées (tap → détail via QuestionDetailModal). */
export function ErrorsList({
  errors,
  onSelect,
}: {
  errors: QuestionReviewResponse[];
  onSelect: (q: QuestionReviewResponse) => void;
}) {
  return (
    <section className={styles.errlist}>
      {errors.map((q) => (
        <button
          type="button"
          key={q.id}
          className={styles.err}
          onClick={() => onSelect(q)}
        >
          <span className={styles.errChip}>{q.difficulty}</span>
          <p>{q.statement}</p>
          <span className={styles.errArrow} aria-hidden>
            ›
          </span>
        </button>
      ))}
      <Link href="/revision?tab=erreurs" className={styles.errCta}>
        Retravailler mes erreurs →
      </Link>
    </section>
  );
}

export { styles as moduleDetailStyles };
