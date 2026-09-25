import type { AdminSuiviResponse } from "../../../types/api";
import { int } from "../format";
import { unmeasuredNote } from "../measurement";
import styles from "../suivi.module.css";
import { Section, StatItem, Unmeasured } from "./Section";

/** Activite de la periode, sans cohorte. */
export function ActivityCard({ data }: { data: AdminSuiviResponse }) {
  const { activity } = data;
  const origin = activity.purchasesByOrigin;
  const originUnknown =
    origin.diagnosticPlan == null && origin.otherCta == null && origin.unknown == null;

  return (
    <Section title="Activité" description="Ce qui s’est passé dans la période, hors cohorte.">
      <div className={styles.statList}>
        <StatItem
          name="Diagnostics soumis (bruts)"
          meta={
            activity.submittedRaw == null ? (
              <Unmeasured>{unmeasuredNote(data, "DIAGNOSTIC_SUBMITTED")}</Unmeasured>
            ) : (
              `dont ${int(activity.submittedFirst)} en 1ʳᵉ tentative · refaites comprises`
            )
          }
          number={int(activity.submittedRaw)}
        />
        <StatItem
          name="Achats par origine"
          meta={
            originUnknown ? (
              <Unmeasured>{unmeasuredNote(data, "PURCHASE_ORIGIN")}</Unmeasured>
            ) : (
              `Plan du diagnostic ${int(origin.diagnosticPlan)} · Autre CTA ${int(
                origin.otherCta,
              )} · Origine inconnue ${int(origin.unknown)}`
            )
          }
          number={int(data.kpis.purchases.value)}
        />
        <StatItem
          name="Soumis anonymes jamais rattachés"
          meta={
            activity.anonymousSubmittedNeverAttached == null ? (
              <Unmeasured>{unmeasuredNote(data, "ACCOUNT_ATTACHED")}</Unmeasured>
            ) : (
              <>
                Sans compte {data.window.cohortWindowDays} jours après la soumission
                {activity.anonymousNeverAttachedOngoing && (
                  <>
                    {" "}
                    · <span className={styles.ongoingMark}>en cours</span>
                  </>
                )}
              </>
            )
          }
          number={int(activity.anonymousSubmittedNeverAttached)}
        />
      </div>
    </Section>
  );
}
