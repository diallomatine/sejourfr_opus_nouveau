"use client";

import {CircleAlert, CircleCheckBig, CircleX} from "lucide-react";
import {objectifPresentation} from "@/lib/production-feedback";
import type {ObjectifAccomplissement} from "@/lib/types";
import styles from "./production.module.css";

/**
 * Première chose que voit le candidat : **a-t-il fait ce qu'on lui demandait ?**
 * Cette question passe avant la note — une note ne se comprend qu'une fois
 * qu'on sait ce qu'on a réellement produit.
 *
 * Les trois verdicts ont trois traitements visuels distincts (vert / ambre /
 * rouge, trois icônes) pour être lisibles sans lire. La hiérarchie suit le
 * mobile : un eyebrow « OBJECTIF DE LA TÂCHE » puis le verdict seul en
 * display — noyé au fil d'une phrase, il ne se voyait pas en tête d'écran.
 *
 * Les évaluations déjà en base ne portent pas de verdict : le bandeau ne
 * s'affiche pas et l'écran commence directement par la note. C'est un cas
 * normal, jamais une erreur.
 */
export function ProductionObjectiveBanner({
  objectif,
  resume,
}: {
  objectif: ObjectifAccomplissement | null;
  resume: string | null;
}) {
  const presentation = objectifPresentation(objectif);
  if (!presentation) return null;

  const Icon =
    presentation.tone === "done"
      ? CircleCheckBig
      : presentation.tone === "partial"
        ? CircleAlert
        : CircleX;

  return (
    <div className={styles.objBanner} data-tone={presentation.tone}>
      <span className={styles.objIcon} aria-hidden>
        <Icon size={20} strokeWidth={2.3} />
      </span>
      <div className={styles.objBody}>
        <p className={styles.objEyebrow}>Objectif de la tâche</p>
        <p className={styles.objVerdict}>{presentation.label}</p>
        {resume && <p className={styles.objResume}>{resume}</p>}
      </div>
    </div>
  );
}
