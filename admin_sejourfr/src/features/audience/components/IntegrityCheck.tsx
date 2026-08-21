import type { FunnelIntegrity } from "../../../types/api";
import { count, plural } from "../insights";
import panels from "./panels.module.css";
import styles from "./IntegrityCheck.module.css";

/**
 * Le diagnostic ne se passe qu'une fois. Ces trois nombres portent sur TOUTE la
 * base — ils ne suivent pas la période choisie en haut de l'écran.
 */
export function IntegrityCheck({ integrity }: { integrity: FunnelIntegrity }) {
  const duplicates = integrity.accountsWithMultipleDiagnosticSessions;
  const ok = duplicates === 0;

  return (
    <div className={`${styles.card} ${ok ? styles.ok : styles.alert}`}>
      <div className={styles.head}>
        <span className={styles.dot} />
        <h3 className={styles.title}>
          {ok
            ? "Un seul diagnostic par compte"
            : `${count(duplicates)} ${plural(duplicates, "compte a", "comptes ont")} plusieurs diagnostics`}
        </h3>
        <span className={styles.scope}>toute la base</span>
      </div>

      <ul className={styles.figures}>
        <li>
          <span>Comptes ayant un diagnostic</span>
          <strong>{count(integrity.accountsWithDiagnostic)}</strong>
        </li>
        <li>
          <span>Sessions de diagnostic</span>
          <strong>{count(integrity.diagnosticSessionsTotal)}</strong>
        </li>
        <li>
          <span>Comptes à plusieurs sessions</span>
          <strong>{count(duplicates)}</strong>
        </li>
      </ul>

      <p className={panels.note}>
        Les deux premiers nombres doivent rester égaux et le troisième valoir
        zéro. Une seconde session n&apos;est légitime que si une nouvelle version
        du diagnostic a été publiée — c&apos;est exactement ce que ce compteur
        surveille. Ces trois nombres portent sur <strong>toute la base</strong> :
        ils ne suivent pas la période choisie en haut de l&apos;écran.
      </p>
    </div>
  );
}
