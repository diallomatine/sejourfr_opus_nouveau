"use client";

import {useState} from "react";
import {Eye, Highlighter} from "lucide-react";
import {splitHighlight} from "@/lib/production-feedback";
import styles from "./production.module.css";

/**
 * Ce que le candidat a rendu — et rien d'autre.
 *
 * ⚠️ **La bascule « Voir la version améliorée » a été retirée (2026-08-08).**
 * `version_amelioree` réécrit la production au niveau **déjà constaté** : c'était
 * le texte le plus visible et le plus copiable du rapport, et il ne fait pas
 * monter d'un palier. Un candidat l'a recopié tel quel, l'a resoumis, et a
 * obtenu **exactement la même note et le même niveau**. Le seul texte modèle de
 * la page est désormais celui du plan d'action ({@link ProductionActionPlan},
 * `version_ciblee`), sous l'intertitre « Une version plus aboutie ».
 *
 * Le champ reste servi par l'API et typé dans `lib/types.ts` (aucun composant ne
 * le lit) : le retirer du contrat imposerait une nouvelle version de tool-schema
 * sur la grille de notation.
 *
 * Reste ici la seule chose qui aide à relire : le repérage de la phrase visée
 * par la priorité n° 1.
 */
export function ProductionTextCard({
  texte,
  motsCount,
  highlight,
}: {
  texte: string;
  motsCount?: number | null;
  /** Passage à surligner — la phrase que vise la priorité n° 1. Repérage sur la
   *  **première occurrence exacte** : rien plutôt qu'un repère faux. */
  highlight?: string | null;
}) {
  const [reperes, setReperes] = useState(true);

  const split = reperes ? splitHighlight(texte, highlight) : null;
  const hasHighlight = splitHighlight(texte, highlight) != null;

  return (
    <section className={styles.prodSection}>
      <p className={styles.sectionHead}>
        <span className={styles.sectionTitle}>Votre rédaction</span>
        <span className={styles.sectionHint}>
          {motsCount != null ? `${motsCount} mots` : ""}
        </span>
      </p>

      <div className={styles.prodCard}>
        <p className={styles.prodText}>
          {split ? (
            <>
              {split.before}
              <mark className={styles.prodMark}>{split.match}</mark>
              {split.after}
            </>
          ) : (
            texte
          )}
        </p>

        {hasHighlight && (
          <div className={styles.prodActions}>
            <button
              type="button"
              className={styles.prodBtnSoft}
              onClick={() => setReperes((v) => !v)}
            >
              {reperes ? <Highlighter size={15} strokeWidth={2.3} /> : <Eye size={15} strokeWidth={2.3} />}
              {reperes ? "Masquer les repères" : "Afficher les repères"}
            </button>
          </div>
        )}
      </div>
    </section>
  );
}
