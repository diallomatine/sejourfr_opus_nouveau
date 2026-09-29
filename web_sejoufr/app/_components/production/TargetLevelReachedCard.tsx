"use client";

import {CircleCheck} from "lucide-react";
import {
  NIVEAU_VISE_ATTEINT_EYEBROW,
  NIVEAU_VISE_ATTEINT_INTRO,
  niveauViseAtteintTitle,
} from "@/lib/production-feedback";
import type {EeNiveauViseAtteint} from "@/lib/types";
import styles from "./production.module.css";

/**
 * **Objectif atteint** : ce qui prend la place de « la marche au-dessus » quand
 * le candidat tient déjà le palier qu'il vise.
 *
 * Avant, il n'y avait rien du tout à cet endroit — la section disparaissait en
 * silence. Depuis le retrait de `version_amelioree`, c'était le seul texte
 * modèle de la page : le candidat qui **réussit** se retrouvait avec un rapport
 * plus vide que celui qui échoue, sans la moindre explication. Sa réussite avait
 * exactement la même tête qu'une panne.
 *
 * Le front ne **déduit** rien : il ne saurait pas distinguer « objectif
 * atteint » d'un second appel LLM en échec. C'est le serveur qui pose
 * `niveau_vise_atteint` (exclusif de {@link ProductionActionPlan}).
 *
 * Miroir mobile : `target_level_reached_card.dart`.
 */
export function TargetLevelReachedCard({atteint}: {atteint: EeNiveauViseAtteint | null}) {
  if (!atteint) return null;

  return (
    <section className={styles.targetSection}>
      <p className={styles.sectionHead}>
        <span className={styles.sectionTitle}>{niveauViseAtteintTitle(atteint.niveauVise)}</span>
      </p>

      <div className={styles.reachedCard}>
        <p className={styles.reachedEyebrow}>
          <CircleCheck size={13} strokeWidth={2.6} aria-hidden />
          {NIVEAU_VISE_ATTEINT_EYEBROW}
        </p>
        <p className={styles.reachedIntro}>{NIVEAU_VISE_ATTEINT_INTRO}</p>
      </div>
    </section>
  );
}
