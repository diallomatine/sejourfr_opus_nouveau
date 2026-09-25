import type { AdminSuiviResponse } from "../../../types/api";
import { int } from "../format";
import { unmeasuredNote } from "../measurement";
import styles from "../suivi.module.css";
import { Section, StatItem, Unmeasured } from "./Section";

/**
 * Inscriptions de la periode. Le filtre type ne s'y applique pas : une
 * inscription directe n'a pas de type. Les lignes legacy (mobile non ventile,
 * non declare, contexte inconnu) s'affichent en clair des qu'elles existent.
 */
export function SignupsCard({ data }: { data: AdminSuiviResponse }) {
  const { signups } = data;
  const { afterDiagnostic, byPlatform } = signups;
  const contextNote = unmeasuredNote(data, "SIGNUP_CONTEXT");
  const legacyPlatforms = [
    byPlatform.mobileUnspecified != null && byPlatform.mobileUnspecified > 0
      ? `${int(byPlatform.mobileUnspecified)} mobile non ventilé (app ancienne)`
      : null,
    byPlatform.unknown != null && byPlatform.unknown > 0
      ? `${int(byPlatform.unknown)} plateforme non déclarée`
      : null,
  ].filter((part): part is string => part != null);

  return (
    <Section title="Inscriptions" description="Origine de la création du compte.">
      <div className={styles.statList}>
        <StatItem
          name="Après diagnostic"
          meta={
            afterDiagnostic.total == null ? (
              <Unmeasured>{contextNote}</Unmeasured>
            ) : (
              `TCF ${int(afterDiagnostic.tcf)} · Civique ${int(afterDiagnostic.civique)}`
            )
          }
          number={int(afterDiagnostic.total)}
        />
        <StatItem
          name="Hors diagnostic"
          meta="Inscription directe"
          number={int(signups.outsideDiagnostic)}
        />
        {signups.contextUnknown != null && signups.contextUnknown > 0 && (
          <StatItem
            name="Origine inconnue"
            meta="Comptes créés avant la mesure du contexte"
            number={int(signups.contextUnknown)}
          />
        )}
      </div>

      <div className={styles.platformGrid}>
        <div className={styles.platform}>
          <span>Web</span>
          <strong>{int(byPlatform.web)}</strong>
        </div>
        <div className={styles.platform}>
          <span>Android</span>
          <strong>{int(byPlatform.android)}</strong>
        </div>
        <div className={styles.platform}>
          <span>iOS</span>
          <strong>{int(byPlatform.ios)}</strong>
        </div>
      </div>

      {byPlatform.ios == null && byPlatform.android == null && (
        <p className={styles.footnote}>
          iOS / Android : <Unmeasured>{unmeasuredNote(data, "SIGNUP_PLATFORM_DETAIL")}</Unmeasured>
        </p>
      )}
      {legacyPlatforms.length > 0 && (
        <p className={styles.footnote}>Dont {legacyPlatforms.join(" · ")}.</p>
      )}
      {signups.loggedInAfterDiagnostic != null && signups.loggedInAfterDiagnostic > 0 && (
        <p className={styles.footnote}>
          {int(signups.loggedInAfterDiagnostic)} connexions à un compte existant après
          diagnostic, non comptées comme inscriptions.
        </p>
      )}
      {data.filters.type !== "ALL" && !signups.typeFilterApplied && (
        <p className={styles.footnote}>Le filtre de type ne s’applique pas aux inscriptions.</p>
      )}
    </Section>
  );
}
