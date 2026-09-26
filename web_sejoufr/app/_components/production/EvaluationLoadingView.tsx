"use client";

import {useEffect, useMemo, useState} from "react";
import {Brain, Check, ClipboardCheck, CloudUpload, AudioLines, type LucideIcon} from "lucide-react";
import {
  EVALUATION_LOADING_LAST,
  EVALUATION_LOADING_LEAD,
  EVALUATION_LOADING_TITLE,
  evaluationLoadingSteps,
  type EvaluationLoadingStepKey,
} from "@/lib/production-exam-copy";
import styles from "./production.module.css";

const ICONS: Record<EvaluationLoadingStepKey, LucideIcon> = {
  upload: CloudUpload,
  transcription: AudioLines,
  analysis: Brain,
  report: ClipboardCheck,
};

/**
 * L'attente de l'analyse IA d'une production : cocarde, « Analyse en cours »,
 * étapes. **Miroir d'`EvaluationLoadingView`** (mobile), mêmes mots
 * (`lib/production-exam-copy.ts`), même cadence indicative : les étapes disent
 * ce qui se passe, elles ne mesurent pas l'avance du serveur — la dernière reste
 * active tant que l'appelant n'a pas basculé sur le résultat.
 */
export function EvaluationLoadingView({includeTranscription = false}: {includeTranscription?: boolean}) {
  const steps = useMemo(() => evaluationLoadingSteps(includeTranscription), [includeTranscription]);
  const [index, setIndex] = useState(0);

  useEffect(() => {
    if (index >= steps.length - 1) return;
    const id = setTimeout(() => setIndex((i) => i + 1), steps[index].seconds * 1000);
    return () => clearTimeout(id);
  }, [index, steps]);

  const last = index === steps.length - 1;
  return (
    <div className={styles.evalWait} role="status" aria-live="polite">
      <div className={styles.evalCocarde} aria-hidden />
      <p className={styles.evalTitle}>{EVALUATION_LOADING_TITLE}</p>
      <p className={styles.evalLead}>{last ? EVALUATION_LOADING_LAST : EVALUATION_LOADING_LEAD}</p>
      <ol className={styles.evalSteps}>
        {steps.map((step, i) => {
          const state = i < index ? "done" : i === index ? "active" : "pending";
          const Icon = ICONS[step.key];
          return (
            <li key={step.key} className={styles.evalStep} data-state={state}>
              <span className={styles.evalStepMark} aria-hidden>
                {state === "done" ? (
                  <Check size={18} strokeWidth={2.4} />
                ) : state === "active" ? (
                  <span className={styles.evalStepSpin} />
                ) : (
                  <Icon size={16} strokeWidth={2} />
                )}
              </span>
              {step.label}
            </li>
          );
        })}
      </ol>
    </div>
  );
}
