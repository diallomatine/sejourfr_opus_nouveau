"use client";

import {Info} from "lucide-react";
import styles from "./production.module.css";

/**
 * Encart affiché avant l'enregistrement d'une production orale : l'IA n'évalue
 * que la transcription. Réduit à sa première phrase (2026-10-05, demande du
 * propriétaire). Miroir mobile : `SkillTranscriptNotice`.
 */
export function EoTranscriptNotice() {
  return (
    <div className={styles.notice}>
      <Info size={16} strokeWidth={2.2} className={styles.noticeIcon} />
      <span className={styles.noticeStrong}>Évaluation basée sur la transcription.</span>
    </div>
  );
}
