"use client";

import {useEffect, useRef, useState} from "react";
import {Clock, FileText} from "lucide-react";
import type {ProductionTaskDto} from "@/lib/types";
import styles from "./production.module.css";

/** Les 5 critères d'évaluation EE (affichés avant rédaction, parité mobile). */
const EE_CRITERIA = [
  "Pertinence et développement du contenu",
  "Organisation et cohérence du texte",
  "Richesse et précision du vocabulaire",
  "Correction grammaticale",
  "Orthographe et ponctuation",
];

const DRAFT_PREFIX = "sejourfr.ee.draft.";

/** Supprime le brouillon local après soumission réussie. */
export function clearEeDraft(taskId: string): void {
  if (typeof window === "undefined") return;
  localStorage.removeItem(DRAFT_PREFIX + taskId);
}

function countWords(s: string): number {
  const t = s.trim();
  return t ? t.split(/\s+/).length : 0;
}

/**
 * Zone de rédaction d'une tâche EE : consigne + contexte, critères, textarea
 * avec compteur de mots live et auto-save du brouillon (localStorage, debounce
 * ~0,8 s). Calqué sur `EeBriefingWritingScreen` mobile. La logique d'attempt /
 * navigation reste au parent via `onSubmit(texte)`.
 */
export function EeWritingForm({
  task,
  submitting,
  error,
  submitLabel = "Valider",
  onSubmit,
}: {
  task: ProductionTaskDto;
  submitting: boolean;
  error?: string | null;
  submitLabel?: string;
  onSubmit: (texte: string) => void;
}) {
  const [text, setText] = useState("");
  const [hydrated, setHydrated] = useState(false);
  const draftKey = DRAFT_PREFIX + task.id;
  const saveTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  // Charge le brouillon existant au montage / changement de tâche.
  useEffect(() => {
    if (typeof window === "undefined") return;
    const saved = localStorage.getItem(draftKey) ?? "";
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setText(saved);
    setHydrated(true);
  }, [draftKey]);

  // Auto-save (debounce).
  useEffect(() => {
    if (!hydrated || typeof window === "undefined") return;
    if (saveTimer.current) clearTimeout(saveTimer.current);
    saveTimer.current = setTimeout(() => {
      if (text.trim()) localStorage.setItem(draftKey, text);
      else localStorage.removeItem(draftKey);
    }, 800);
    return () => {
      if (saveTimer.current) clearTimeout(saveTimer.current);
    };
  }, [text, hydrated, draftKey]);

  const words = countWords(text);
  const min = task.motsMin;
  const max = task.motsMax;
  const inRange =
    (min == null || words >= min) && (max == null || words <= max);
  const wordClass = words === 0 ? "" : inRange ? styles.wordOk : styles.wordWarn;
  const rangeLabel =
    min != null && max != null ? `${min}–${max} mots` : min != null ? `≥ ${min} mots` : "";

  const canSubmit = words > 0 && !submitting;

  return (
    <>
      <div className={styles.card}>
        <p className={styles.cardLabel}>Consigne · {eeNumLabel(task.tacheNumero)}</p>
        <p className={styles.consigne}>{task.consigne}</p>
        {task.contexte && <div className={styles.contexte}>{task.contexte}</div>}
        <div className={styles.metaRow}>
          {rangeLabel && (
            <span className={styles.metaChip}>
              <FileText size={13} strokeWidth={2} />
              {rangeLabel}
            </span>
          )}
          <span className={styles.metaChip}>
            <Clock size={13} strokeWidth={2} />
            Niveau {task.niveauCible}
          </span>
        </div>
      </div>

      <div className={styles.card}>
        <p className={styles.cardLabel}>Vous serez évalué sur</p>
        <ul className={styles.criteriaList}>
          {EE_CRITERIA.map((c) => (
            <li key={c} className={styles.criteriaItem}>
              <span className={styles.criteriaDot} />
              {c}
            </li>
          ))}
        </ul>
      </div>

      <div className={styles.writeZone}>
        <div className={styles.writeHead}>
          <p className={styles.cardLabel} style={{margin: 0}}>
            Votre rédaction
          </p>
          <span className={`${styles.wordCount} ${wordClass}`}>
            {words} mot{words > 1 ? "s" : ""}
            {rangeLabel ? ` · ${rangeLabel}` : ""}
          </span>
        </div>
        <textarea
          className={styles.textarea}
          value={text}
          onChange={(e) => setText(e.target.value)}
          placeholder="Rédigez votre réponse ici…"
          disabled={submitting}
          spellCheck
        />
        <p className={styles.draftNote}>
          Brouillon enregistré automatiquement sur cet appareil.
        </p>
      </div>

      {error && <div className={styles.error}>{error}</div>}

      <div className={styles.submitRow}>
        <button
          type="button"
          className={`btn btn-blue btn-lg ${styles.grow}`}
          disabled={!canSubmit}
          onClick={() => onSubmit(text.trim())}
        >
          {submitting ? "Envoi en cours…" : submitLabel}
        </button>
      </div>
    </>
  );
}

function eeNumLabel(n: number): string {
  return `Tâche ${n}`;
}
