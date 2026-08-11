"use client";

import {Info} from "lucide-react";
import styles from "./production.module.css";

/**
 * « À savoir sur cette évaluation » — la note de transparence du rapport,
 * posée **juste sous le bandeau de résultat**.
 *
 * ⚠️ Ce texte n'est PAS produit par le correcteur : c'est le **serveur** qui
 * l'écrit. Il porte la limite assumée de l'évaluation orale et le signalement
 * des purges automatiques. C'est pour ça qu'il a survécu au retrait de « Voir
 * l'analyse complète » (contrat v15/v9, qui supprime `exemples_corriges` et
 * `suggestions`) : lui ne dépend d'aucun champ du LLM.
 *
 * **Une note, pas une carte** : pas d'encadré plein, pas d'accordéon — elle se
 * lit au passage et ne dispute pas la première lecture au verdict. Liste vide ⇒
 * rien du tout, jamais un titre orphelin.
 *
 * Miroir mobile : `widgets/evaluation_notice.dart`.
 */
export function EvaluationNotice({avertissements}: {avertissements: string[]}) {
  if (avertissements.length === 0) return null;

  return (
    <aside className={styles.evalNotice}>
      <Info className={styles.evalNoticeIcon} size={15} strokeWidth={2.2} aria-hidden />
      <div className={styles.evalNoticeBody}>
        <p className={styles.evalNoticeTitle}>À savoir sur cette évaluation</p>
        {avertissements.map((a, i) => (
          <p key={i} className={styles.evalNoticeText}>
            {a}
          </p>
        ))}
      </div>
    </aside>
  );
}
