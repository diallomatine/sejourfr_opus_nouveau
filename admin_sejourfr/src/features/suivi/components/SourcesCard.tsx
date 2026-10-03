import type { AdminSuiviResponse } from "../../../types/api";
import { int } from "../../../lib/format";
import { sourceLabel } from "../labels";
import { measuredSinceNote, unmeasuredNote } from "../measurement";
import styles from "../suivi.module.css";
import { Section, Unmeasured } from "./Section";

/**
 * Visiteurs de la periode par groupe first-touch, dans l'ordre servi. La
 * longueur de barre est une ECHELLE visuelle rapportee au plus gros groupe,
 * comme dans le template ; aucun pourcentage n'est affiche.
 */
export function SourcesCard({ data }: { data: AdminSuiviResponse }) {
  const unknown = data.unknownSourceVisitors;
  const max = Math.max(0, unknown ?? 0, ...data.sources.map((row) => row.visitors ?? 0));
  const allUnknown = data.sources.every((row) => row.visitors == null);
  const since = allUnknown ? null : measuredSinceNote(data, "ACQUISITION_SOURCES");

  return (
    <Section
      title="Sources d’acquisition"
      description="Attribution first-touch conservée jusqu’au compte."
    >
      {allUnknown ? (
        <div className={styles.empty}>
          <Unmeasured>{unmeasuredNote(data, "ACQUISITION_SOURCES")}</Unmeasured>
        </div>
      ) : (
        <div className={styles.sourceBars}>
          {data.sources.map((row) => (
            <div key={row.group} className={styles.sourceRow}>
              <div>{sourceLabel(row.group)}</div>
              <div className={styles.sourceTrack}>
                {row.visitors != null && max > 0 && row.visitors > 0 && (
                  <span style={{ width: `${(row.visitors / max) * 100}%` }} />
                )}
              </div>
              <strong>{int(row.visitors)}</strong>
            </div>
          ))}
          {unknown != null && unknown > 0 && (
            <div className={styles.sourceRow}>
              <div title="Application sans provenance déclarée : ni lien de campagne, ni référent. Jamais rangée dans « Autre ».">
                Inconnue
              </div>
              <div className={styles.sourceTrack}>
                {max > 0 && <span style={{ width: `${(unknown / max) * 100}%` }} />}
              </div>
              <strong>{int(unknown)}</strong>
            </div>
          )}
        </div>
      )}
      {unknown != null && unknown > 0 && (
        <p className={styles.footnote}>
          « Inconnue » : visiteurs de l’application, qui ne transmet aucune provenance.
        </p>
      )}

      {since && (
        <p className={styles.footnote}>
          Visiteurs <Unmeasured>{since}</Unmeasured>.
        </p>
      )}
      <p className={styles.footnote}>
        Exemple : <strong>?utm_source=instagram</strong> est conservé du premier passage
        jusqu’à l’inscription et à l’achat.
      </p>
    </Section>
  );
}
