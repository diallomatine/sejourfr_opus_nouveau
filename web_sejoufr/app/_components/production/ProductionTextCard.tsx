"use client";

import {useState} from "react";
import {Eye, EyeOff, FileCheck, Highlighter} from "lucide-react";
import {splitHighlight} from "@/lib/production-feedback";
import styles from "./production.module.css";

/**
 * Ce que le candidat a rendu, et — d'un bouton — la même chose réécrite.
 *
 * Les deux vivaient dans deux cartes éloignées : le texte soumis dans l'accusé
 * de traitement tout en haut, la version améliorée bien plus bas. Or c'est une
 * **comparaison** qu'on demande au candidat de faire ; il faut donc que les deux
 * soient au même endroit, et qu'une seule s'affiche à la fois.
 *
 * La version améliorée n'existe qu'en expression ÉCRITE (absente en EO par
 * contrat, pas par bug) : sans elle, la carte se réduit au texte rendu, sans
 * bouton mort.
 */
export function ProductionTextCard({
  texte,
  motsCount,
  versionAmelioree,
  highlight,
}: {
  texte: string;
  motsCount?: number | null;
  versionAmelioree?: string | null;
  /** Passage à surligner — la phrase que vise la priorité n° 1. Repérage sur la
   *  **première occurrence exacte** : rien plutôt qu'un repère faux. */
  highlight?: string | null;
}) {
  const [improved, setImproved] = useState(false);
  const [reperes, setReperes] = useState(true);

  const split = reperes ? splitHighlight(texte, highlight) : null;
  const hasHighlight = splitHighlight(texte, highlight) != null;
  const hasVersion = Boolean(versionAmelioree);

  return (
    <section className={styles.prodSection}>
      <p className={styles.sectionHead}>
        <span className={styles.sectionTitle}>Votre rédaction</span>
        <span className={styles.sectionHint}>
          {hasVersion
            ? "Comparez en 10 secondes"
            : motsCount != null
              ? `${motsCount} mots`
              : ""}
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

        {(hasVersion || hasHighlight) && (
          <div className={styles.prodActions}>
            {hasVersion && (
              <button
                type="button"
                className={styles.prodBtn}
                onClick={() => setImproved((v) => !v)}
              >
                {improved ? <EyeOff size={15} strokeWidth={2.3} /> : <FileCheck size={15} strokeWidth={2.3} />}
                {improved ? "Masquer la version améliorée" : "Voir la version améliorée"}
              </button>
            )}
            {hasHighlight && (
              <button
                type="button"
                className={styles.prodBtnSoft}
                onClick={() => setReperes((v) => !v)}
              >
                {reperes ? <Highlighter size={15} strokeWidth={2.3} /> : <Eye size={15} strokeWidth={2.3} />}
                {reperes ? "Masquer les repères" : "Afficher les repères"}
              </button>
            )}
          </div>
        )}

        {hasVersion && improved && (
          <div className={styles.prodImproved}>
            <p className={styles.prodImprovedLabel}>Version améliorée</p>
            <p className={styles.prodImprovedHint}>
              Vos idées, réécrites : les mêmes, dites autrement.
            </p>
            <p className={styles.prodImprovedText}>{versionAmelioree}</p>
          </div>
        )}
      </div>
    </section>
  );
}
