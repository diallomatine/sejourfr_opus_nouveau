import type { AdminSuiviResponse } from "../../../types/api";
import { count, int } from "../format";
import { SCOPE_LABELS } from "../labels";
import { unmeasuredNote } from "../measurement";
import styles from "../suivi.module.css";
import { Section, StatItem, Unmeasured } from "./Section";

/** Colonnes TCF / Civique du tunnel (etapes 1, 2, 7). Ignore le filtre type. */
export function ByTypeCard({ data }: { data: AdminSuiviResponse }) {
  return (
    <Section title="Diagnostic par type" description="Comparer rapidement TCF et Civique.">
      <div className={styles.statList}>
        {data.byType.map((row) => (
          <StatItem
            key={row.type}
            name={SCOPE_LABELS[row.type]}
            meta={
              row.subjectViewed == null && row.submitted == null ? (
                <Unmeasured>{unmeasuredNote(data, "DIAGNOSTIC_SUBJECT_VIEWED")}</Unmeasured>
              ) : (
                `${int(row.subjectViewed)} sujets vus · ${int(row.submitted)} soumis`
              )
            }
            number={count(row.purchases, "achat", "achats")}
          />
        ))}
      </div>
      {data.filters.type !== "ALL" && (
        <p className={styles.footnote}>Comparatif : ce bloc ignore le filtre de type.</p>
      )}
    </Section>
  );
}
