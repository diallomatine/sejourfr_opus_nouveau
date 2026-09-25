import type { AdminSuiviResponse } from "../../../types/api";
import { money, pct } from "../format";
import { unmeasuredNote } from "../measurement";
import styles from "../suivi.module.css";
import { Section, Unmeasured } from "./Section";

/** Ratios de la cohorte du tunnel, servis. Bloc secondaire, sous le tunnel. */
export function RatiosCard({ data }: { data: AdminSuiviResponse }) {
  const { ratios } = data;
  const items: { label: string; hint: string; value: string }[] = [
    { label: "Sujet → soumission", hint: "2 / 1", value: pct(ratios.subjectToSubmissionPct) },
    {
      label: "Diagnostic → inscription",
      hint: "inscrits / soumis anonymes",
      value: pct(ratios.diagnosticToSignupPct),
    },
    { label: "Rapport vu", hint: "4 / 3", value: pct(ratios.reportViewedPct) },
    { label: "Plan consulté", hint: "5 / 4", value: pct(ratios.planViewedPct) },
    { label: "Intention de déblocage", hint: "6 / 5", value: pct(ratios.unlockIntentPct) },
    { label: "Conversion du clic", hint: "7 / 6", value: pct(ratios.clickConversionPct) },
    { label: "Conversion globale", hint: "7 / 2", value: pct(ratios.globalConversionPct) },
    {
      label: "Net par diagnostic soumis",
      hint: "CA net cohorte / 2",
      value: money(ratios.netPerSubmittedCents),
    },
  ];
  const tunnelUnknown = data.funnel.steps.every((step) => step.count == null);

  return (
    <Section
      className={styles.ratios}
      title="Ratios"
      description="Sur la cohorte du tunnel, mêmes filtres. Étapes numérotées de 1 (sujet vu) à 7 (achat)."
      badges={
        tunnelUnknown ? (
          <Unmeasured>{unmeasuredNote(data, "DIAGNOSTIC_SUBJECT_VIEWED")}</Unmeasured>
        ) : undefined
      }
    >
      <div className={styles.ratioGrid}>
        {items.map((item) => (
          <div key={item.label} className={styles.ratio}>
            <div className={styles.ratioLabel}>{item.label}</div>
            <div className={styles.ratioHint}>{item.hint}</div>
            <div className={styles.ratioValue}>{item.value}</div>
          </div>
        ))}
      </div>
    </Section>
  );
}
