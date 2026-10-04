"use client";

import {useEffect, type ReactNode} from "react";
import {Info, Lock, Target, Timer} from "lucide-react";
import {productionTaskTitle, type ProductionTaskDto} from "@/lib/types";
import {
  PRODUCTION_INFO_CLOSE,
  PRODUCTION_INFO_CRITERIA_LABEL,
  PRODUCTION_INFO_PRIVACY_LABEL,
  PRODUCTION_INFO_TITLE,
  productionExamConstraintLine,
  productionExamStepLabel,
  productionPrivacyText,
} from "@/lib/production-exam-copy";
import {ProductionCriteriaList} from "./ProductionCriteriaList";
import skill from "@/app/_components/skill-ui/skill.module.css";
import x from "./exam.module.css";

type ProductionEpreuve = "TCF_EE" | "TCF_EO";

/**
 * Les briques du **runner d'examen blanc EE/EO**, alignées sur l'app
 * (`ee_briefing_writing_screen` / `eo_briefing_screen`) : un en-tête compact,
 * une carte de consigne qui dit la contrainte une seule fois, une feuille « ⓘ »
 * pour ce qui ne sert pas à produire, et la mise en page à deux colonnes du
 * palier desktop.
 */

/**
 * « Tâche 1 sur 3 · Message simple » + chrono dans le même bloc, puis la barre
 * de progression. Miroir de `ProductionProgressStrip` (+ le chrono en
 * `trailing`, le bouton ⓘ de `ProductionAppHeader`).
 *
 * `chrono` est `null` à l'oral : son temps se compte tâche par tâche, dans
 * l'enregistreur, et ne part qu'au « Je suis prêt ».
 */
export function ExamRunnerHead({
  epreuve,
  tacheNumero,
  total,
  chrono,
  onInfo,
}: {
  epreuve: ProductionEpreuve;
  tacheNumero: number;
  total: number;
  chrono: {label: string; urgent: boolean} | null;
  onInfo: () => void;
}) {
  const percent = total > 0 ? Math.min(100, (tacheNumero / total) * 100) : 0;
  return (
    <div className={x.head}>
      <div className={x.headRow}>
        <p className={x.headLabel}>
          {productionExamStepLabel(tacheNumero, total)}
          <span className={x.headSub}> · {productionTaskTitle(epreuve, tacheNumero)}</span>
        </p>
        {chrono && (
          <span
            className={`${x.timer} ${chrono.urgent ? x.timerUrgent : ""}`}
            role="timer"
            aria-label={`Temps restant ${chrono.label}`}
          >
            <Timer size={14} strokeWidth={2.4} aria-hidden />
            {chrono.label}
          </span>
        )}
        <button
          type="button"
          className={x.infoBtn}
          onClick={onInfo}
          aria-label="Comment votre production est évaluée"
        >
          <Info size={17} strokeWidth={2.2} aria-hidden />
        </button>
      </div>
      <div
        className={x.bar}
        role="progressbar"
        aria-valuemin={0}
        aria-valuemax={total}
        aria-valuenow={tacheNumero}
      >
        <div className={x.barFill} style={{width: `${percent}%`}} />
      </div>
    </div>
  );
}

/**
 * La carte de consigne du runner : pastille « Consigne », intitulé de la tâche,
 * **la contrainte servie dite une seule fois** (« Longueur attendue : 30 à
 * 60 mots » / « Temps de parole : 3 min »), la consigne, le contexte. Miroir de
 * `ConsigneCard` (mobile). `children` : les repères posés dessous (temps
 * conseillé).
 */
export function ExamConsigneCard({
  task,
  epreuve,
  children,
}: {
  task: ProductionTaskDto;
  epreuve: ProductionEpreuve;
  children?: ReactNode;
}) {
  const constraint = productionExamConstraintLine(task, epreuve);
  return (
    <div>
      <section className={x.consigne}>
        <div className={skill.exerciseTop}>
          <span className={skill.criterionTag}>
            <Target size={12} strokeWidth={2.4} aria-hidden />
            Consigne
          </span>
        </div>
        <h2 className={x.consigneTitle}>{productionTaskTitle(epreuve, task.tacheNumero)}</h2>
        {constraint && <p className={x.consigneConstraint}>{constraint}</p>}
        <p className={x.consigneText}>{task.consigne}</p>
        {task.contexte && (
          <div className={skill.context}>
            <span className={skill.contextLabel}>Contexte</span>
            {task.contexte}
          </div>
        )}
      </section>
      {children}
    </div>
  );
}

/** Le repère de rythme, discret, sous la consigne (écrit seulement). */
export function ExamAdvisedTime({line}: {line: string}) {
  return (
    <p className={x.advised}>
      <Timer size={15} strokeWidth={2} aria-hidden />
      <span>{line}</span>
    </p>
  );
}

/**
 * Consigne à gauche, production à droite au palier desktop (≥ 1024 px) ; une
 * seule colonne en dessous, comme l'app. Sans `split`, rend les deux blocs à la
 * suite, sans conteneur.
 */
export function ProductionSplit({
  split,
  aside,
  children,
}: {
  split: boolean;
  aside: ReactNode;
  children: ReactNode;
}) {
  if (!split) {
    return (
      <>
        {aside}
        {children}
      </>
    );
  }
  return (
    <div className={x.split}>
      <div className={x.splitAside}>{aside}</div>
      <div className={x.splitMain}>{children}</div>
    </div>
  );
}

/**
 * La feuille « ⓘ » du runner : les critères de notre grille et la
 * confidentialité de la production. Miroir de `ProductionInfoSheet` (mobile).
 * Elle remplace le bloc « Vous serez évalué sur » que le runner déroulait entre
 * la consigne et la zone de production.
 */
export function ProductionInfoSheet({
  open,
  epreuve,
  onClose,
}: {
  open: boolean;
  epreuve: ProductionEpreuve;
  onClose: () => void;
}) {
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [open, onClose]);

  if (!open) return null;
  return (
    <div className={x.overlay} onClick={onClose} role="presentation">
      <div
        className={x.sheet}
        onClick={(e) => e.stopPropagation()}
        role="dialog"
        aria-modal="true"
        aria-labelledby="production-info-title"
      >
        <div className={x.handle} aria-hidden />
        <div className={x.infoHead}>
          <span className={x.infoIcon} aria-hidden>
            <Info size={18} strokeWidth={2.2} />
          </span>
          <h2 id="production-info-title" className={x.infoTitle}>
            {PRODUCTION_INFO_TITLE}
          </h2>
        </div>

        <div className={x.infoBlock}>
          <p className={x.sectionLabel}>{PRODUCTION_INFO_CRITERIA_LABEL}</p>
          <ProductionCriteriaList />
        </div>

        <div className={x.infoBlock}>
          <p className={x.sectionLabel}>
            <Lock size={11} strokeWidth={2.4} aria-hidden /> {PRODUCTION_INFO_PRIVACY_LABEL}
          </p>
          <p className={x.infoText}>{productionPrivacyText(epreuve)}</p>
        </div>

        <div className={x.actions}>
          <button type="button" className={`${x.btn} ${x.btnPrimary}`} onClick={onClose}>
            {PRODUCTION_INFO_CLOSE}
          </button>
        </div>
      </div>
    </div>
  );
}
