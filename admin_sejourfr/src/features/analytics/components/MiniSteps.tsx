import type { AnalyticsDiagChainStep } from "../../../types/api";
import { barWidth, int, pct } from "../format";
import styles from "../analytics.module.css";

interface MiniStepsProps {
  rows: AnalyticsDiagChainStep[];
  /** Couleur de la barre — par defaut le bleu SejourFR (`--blue`, cf. CSS). */
  tone?: string;
}

/**
 * Chaine d'etapes empilees montrant la progression REELLE d'un format de
 * diagnostic (maquette : composant `MiniSteps`). Contrairement a la
 * maquette, aucun ratio n'est ecrit en dur ni recalcule ici : `value` et
 * `conv` (conversion depuis le maillon precedent) viennent tels quels du
 * serveur.
 *
 * Un maillon sans donnee (`value == null` — les evenements CO/CE du format
 * complet ne sont pas encore emis par les fronts) est retire de l'affichage
 * plutot que rendu a zero, qui se lirait comme « tout le monde abandonne
 * ici ». Une chaine entierement vide ne rend aucun bloc.
 */
export function MiniSteps({ rows, tone }: MiniStepsProps) {
  const visible = rows.filter(
    (row): row is AnalyticsDiagChainStep & { value: number } => row.value != null,
  );
  if (visible.length === 0) return null;

  const max = visible[0].value || 1;

  return (
    <div className={styles.miniSteps}>
      {visible.map((row, index) => (
        <div className={styles.miniRow} key={row.k}>
          <span className={styles.miniRowLabel}>{row.label}</span>
          <span className={`${styles.mono} ${styles.miniRowValue}`}>
            {int(row.value)}
            {index > 0 && row.conv != null && (
              <span className={styles.miniStepConv}> · {pct(row.conv, 0)}</span>
            )}
          </span>
          <div className={`${styles.barTrack} ${styles.miniRowBar}`}>
            <i
              style={{
                width: barWidth(row.value, max),
                ...(tone ? { background: tone } : {}),
              }}
            />
          </div>
        </div>
      ))}
    </div>
  );
}
