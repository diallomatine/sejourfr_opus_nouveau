"use client";

import {Info} from "lucide-react";
import {type ProductionVoice} from "./config";
import styles from "./production.module.css";

/**
 * Encart de transparence affiché avant l'enregistrement et sous le résultat
 * d'une production orale : l'IA n'évalue que la transcription (contenu + langue),
 * pas la prononciation/intonation — celles-ci comptent le jour de l'examen.
 *
 * <p>Il dit aussi ce que devient l'enregistrement : il sert à produire la
 * transcription, puis il n'est pas conservé. C'est l'endroit exact où le
 * candidat décide de parler — le lui apprendre ailleurs serait le lui apprendre
 * trop tard. Miroir mobile : `SkillTranscriptNotice`.
 *
 * `voice` suit le formulaire qui le rend : tutoiement dans le module
 * « Compétences », vouvoiement par défaut sur les écrans de production TCF.
 */
export function EoTranscriptNotice({voice = "vouvoiement"}: {voice?: ProductionVoice}) {
  return (
    <div className={styles.notice}>
      <Info size={16} strokeWidth={2.2} className={styles.noticeIcon} />
      <span>
        <span className={styles.noticeStrong}>Évaluation basée sur la transcription.</span> La note
        porte sur le <strong>contenu</strong> et la <strong>langue</strong> (organisation,
        vocabulaire, grammaire) de ce que {voice === "tutoiement" ? "tu dis" : "vous dites"}. La{" "}
        <strong>prononciation</strong> et l&apos;<strong>intonation</strong>{" "}
        ne sont pas évaluées ici — elles compteront le jour de l&apos;examen,
        face à un examinateur.{" "}
        <strong>
          {voice === "tutoiement" ? "Ton enregistrement" : "Votre enregistrement"} n&apos;est pas
          conservé
        </strong>{" "}
        : il sert à produire la transcription, puis il est supprimé.
      </span>
    </div>
  );
}
