"use client";

import type {EePriority} from "@/lib/types";
import styles from "./production.module.css";

/**
 * Une priorité de travail, rendue **dans** le bandeau « À corriger en priorité » :
 * un constat, une technique, une réécriture. Pas de carte propre ni d'étiquette
 * — le bandeau qui l'ouvre les porte déjà, et une carte dans une carte avec un
 * titre répété deux fois est exactement la redite que ce rapport corrige.
 *
 * Ce que le correcteur écrit dans `comment` est utile mais long — jusqu'à huit
 * lignes de consignes imbriquées. Affiché à plat, ce pavé était le plus gros
 * bloc de texte du rapport et chassait hors écran la seule chose vraiment
 * actionnable juste en dessous : la phrase réécrite. Il est donc **replié**,
 * avec un geste pour le lire en entier. Rien n'est retiré.
 *
 * Une évaluation antérieure ne porte qu'une chaîne : le bloc se réduit alors au
 * constat, sans encadré vide ni bouton mort.
 */
export function PriorityBody({
  priority: p,
  rank,
  total,
}: {
  priority: EePriority;
  rank: number;
  total: number;
}) {
  return (
    <div className={styles.prioBlock}>
      {total > 1 && <p className={styles.prioRankTag}>Priorité {rank}</p>}
      <p className={styles.prioTitle}>{p.constat}</p>

      {p.comment && (
        <details className={styles.prioHowBox}>
          <summary className={styles.prioHowSummary}>
            <span className={styles.critWhyClosed}>Comment faire</span>
            <span className={styles.critWhyOpen}>Réduire</span>
          </summary>
          <p className={styles.prioHowText}>{p.comment}</p>
        </details>
      )}

      {/* La démonstration ne se replie JAMAIS : c'est le bloc le plus court du
          rapport et le plus actionnable. L'ancienne phrase barrée, la nouvelle
          en vert — la rature dit « avant » mieux que le mot « avant ». */}
      {p.exemple && (
        <div className={styles.rewrite}>
          <p className={styles.rewriteLabel}>Avant → Après</p>
          <p className={styles.rewriteBad}>{p.exemple.avant}</p>
          <p className={styles.rewriteGood}>{p.exemple.apres}</p>
        </div>
      )}
    </div>
  );
}
