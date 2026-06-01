"use client";

import {Info} from "lucide-react";
import styles from "./production.module.css";

/**
 * Encart de transparence affiché avant l'enregistrement et sous le résultat
 * d'une production orale : l'IA n'évalue que la transcription (contenu + langue),
 * pas la prononciation/intonation — celles-ci comptent le jour de l'examen.
 */
export function EoTranscriptNotice() {
  return (
    <div className={styles.notice}>
      <Info size={16} strokeWidth={2.2} className={styles.noticeIcon} />
      <span>
        <span className={styles.noticeStrong}>Évaluation basée sur la transcription.</span> La note
        porte sur le <strong>contenu</strong> et la <strong>langue</strong> (organisation,
        vocabulaire, grammaire) de ce que vous dites. La <strong>prononciation</strong> et l&apos;
        <strong>intonation</strong> ne sont pas évaluées ici — elles compteront le jour de l&apos;examen,
        face à un examinateur.
      </span>
    </div>
  );
}
