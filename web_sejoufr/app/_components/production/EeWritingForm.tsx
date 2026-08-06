"use client";

import {useEffect, useRef, useState, type ReactNode} from "react";
import {FileText, Target} from "lucide-react";
import type {ProductionTaskDto} from "@/lib/types";
import {SkillAccent} from "@/app/_components/skill-ui/SkillLayout";
import s from "@/app/_components/skill-ui/skill.module.css";
import {ProductionCriteriaCard} from "./ProductionCriteriaCard";

const DRAFT_PREFIX = "sejourfr.ee.draft.";

/** Supprime le brouillon local après soumission réussie. */
export function clearEeDraft(taskId: string): void {
  if (typeof window === "undefined") return;
  localStorage.removeItem(DRAFT_PREFIX + taskId);
}

/** Écrit un brouillon local. Sert à « reprendre ma réponse » côté Compétences :
 *  le texte de la tentative précédente devient le brouillon, puis le parent
 *  remonte le formulaire (`key`) pour qu'il le relise. */
export function setEeDraft(taskId: string, texte: string): void {
  if (typeof window === "undefined") return;
  if (texte.trim()) localStorage.setItem(DRAFT_PREFIX + taskId, texte);
  else localStorage.removeItem(DRAFT_PREFIX + taskId);
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
  consigneLabel,
  exerciseTitle,
  headerSlot,
  criteriaSlot,
  footerSlot,
  lengthAdvisory = false,
  clearLabel,
  autoSubmitSignal = 0,
  onAutoSubmit,
  onSubmit,
}: {
  task: ProductionTaskDto;
  submitting: boolean;
  error?: string | null;
  submitLabel?: string;
  /** Remplace « Tâche N » sur le badge de contrainte (micro-exercices :
   *  « Petit sujet · 2/5 »). */
  consigneLabel?: string;
  /** Titre d'intention affiché **dans** la carte d'exercice, au-dessus de la
   *  consigne. Absent par défaut : les micro-exercices portent déjà le leur
   *  dans `headerSlot`, l'écrire deux fois serait une redite. */
  exerciseTitle?: ReactNode;
  /** Inséré tout en haut, **avant** la carte de consigne : intention de
   *  l'exercice et critère travaillé. Rien par défaut. */
  headerSlot?: ReactNode;
  /** Remplace la carte des 4 critères du TCF. `null` la retire — les
   *  micro-exercices « Compétences » n'évaluent QU'UN critère et affichent le
   *  leur ici, juste au-dessus de la zone de saisie. */
  criteriaSlot?: ReactNode;
  /** Inséré juste au-dessus du bouton de validation (auto-évaluation, options
   *  de soumission). Rien par défaut. */
  footerSlot?: ReactNode;
  /** Bornes **conseillées et non bloquantes** : la fourchette s'affiche et
   *  l'écart s'annonce, mais la soumission reste ouverte. C'est le régime des
   *  micro-exercices « Compétences » (spec §8 règle 15) ; les tâches TCF, elles,
   *  gardent des bornes strictes et ce drapeau à `false`. */
  lengthAdvisory?: boolean;
  /** Ajoute un bouton secondaire qui vide la zone de saisie (et son brouillon).
   *  Absent par défaut : sur une tâche d'examen, effacer n'a pas de sens. */
  clearLabel?: string;
  /** Incrémenté par le parent (chrono examen à 0:00) pour déclencher une
   *  auto-soumission du texte courant si recevable. */
  autoSubmitSignal?: number;
  /** Reçoit le texte courant + s'il est recevable (mots ∈ [motsMin, motsMax]).
   *  Au parent de décider quoi en faire (soumettre ou finir à vide). */
  onAutoSubmit?: (texte: string, recevable: boolean) => void;
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
  const submittable =
    words > 0 &&
    (lengthAdvisory || ((min == null || words >= min) && (max == null || words <= max)));
  const rangeLabel =
    min != null && max != null ? `${min}–${max} mots` : min != null ? `≥ ${min} mots` : "";
  // Hors bornes, on AVERTIT toujours ; on ne bloque que quand les bornes sont
  // strictes. Un avertissement muet laisserait croire que la longueur n'a
  // aucune importance, un blocage contredirait la règle 15 de la spec.
  const lengthHint =
    words === 0 || inRange
      ? null
      : lengthAdvisory
        ? `Longueur conseillée : ${rangeLabel}. Votre réponse en compte ${words} — vous pouvez valider quand même.`
        : min != null && words < min
          ? `Encore ${min - words} mot${min - words > 1 ? "s" : ""} avant de pouvoir soumettre (${min} minimum).`
          : `Texte trop long de ${words - (max ?? words)} mot${
              words - (max ?? words) > 1 ? "s" : ""
            } : raccourcissez-le pour pouvoir soumettre (${max} mots attendus).`;

  // Auto-soumission examen (chrono à 0:00). Les bornes TCF IRN sont strictes.
  const lastSignalRef = useRef(0);
  useEffect(() => {
    if (autoSubmitSignal <= 0 || autoSubmitSignal === lastSignalRef.current) return;
    lastSignalRef.current = autoSubmitSignal;
    const recevable =
      (min == null || words >= min) &&
      (max == null || words <= max);
    onAutoSubmit?.(text.trim(), recevable);
  }, [autoSubmitSignal, words, min, max, text, onAutoSubmit]);
  const counterClass = words === 0 ? "" : inRange ? s.counterOk : s.counterWarn;

  const canSubmit = submittable && !submitting;

  return (
    <SkillAccent accent="blue">
      {headerSlot}

      {/* Carte d'exercice de la maquette : badge de contrainte + repère de
          position, titre d'intention, consigne, contexte, chips de format. */}
      <section className={s.exercise}>
        <div className={s.exerciseTop}>
          <span className={s.criterionTag}>
            <Target size={12} strokeWidth={2.4} aria-hidden />
            {consigneLabel ?? `Tâche ${task.tacheNumero}`}
          </span>
          <span className={s.stepTag}>Niveau {task.niveauCible}</span>
        </div>

        {exerciseTitle && <h2 className={s.exerciseTitle}>{exerciseTitle}</h2>}
        <p className={s.exerciseIntro}>{task.consigne}</p>

        {task.contexte && (
          <div className={s.context}>
            <span className={s.contextLabel}>Contexte</span>
            {task.contexte}
          </div>
        )}

        {rangeLabel && (
          <div className={s.requirements}>
            <span className={s.requirement}>
              <FileText size={11} strokeWidth={2.4} aria-hidden />
              {rangeLabel}
            </span>
          </div>
        )}
      </section>

      {criteriaSlot === undefined ? <ProductionCriteriaCard /> : criteriaSlot}

      <div>
        <div className={s.editorHead}>
          <p className={s.editorHeadTitle}>Votre rédaction</p>
          {rangeLabel && <span className={s.editorHeadHint}>{rangeLabel}</span>}
        </div>
        <div className={s.editor}>
          <textarea
            className={s.textarea}
            value={text}
            onChange={(e) => setText(e.target.value)}
            placeholder="Rédigez votre réponse ici…"
            disabled={submitting}
            spellCheck
          />
          <span className={`${s.counter} ${counterClass}`} aria-live="polite">
            {words} mot{words > 1 ? "s" : ""}
          </span>
        </div>
        <p className={s.liveStats}>Brouillon enregistré automatiquement sur cet appareil.</p>
      </div>

      {lengthHint && (
        <p className={s.tipline}>
          <b>Longueur :</b>
          <span>{lengthHint}</span>
        </p>
      )}

      {error && <div className={s.error}>{error}</div>}

      {footerSlot}

      <div className={s.actionRow}>
        <button
          type="button"
          className={s.primary}
          disabled={!canSubmit}
          onClick={() => onSubmit(text.trim())}
        >
          {submitting ? "Envoi en cours…" : submitLabel}
        </button>
        {clearLabel && (
          <button
            type="button"
            className={s.secondary}
            disabled={submitting || words === 0}
            onClick={() => {
              setText("");
              if (typeof window !== "undefined") localStorage.removeItem(draftKey);
            }}
          >
            {clearLabel}
          </button>
        )}
      </div>
    </SkillAccent>
  );
}
