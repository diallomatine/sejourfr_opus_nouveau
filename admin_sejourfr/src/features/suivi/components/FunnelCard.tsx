import type { AdminSuiviResponse, SuiviFunnelStep } from "../../../types/api";
import { DASH, int, money, pct } from "../format";
import { SCOPE_LABELS, STEP_LABELS } from "../labels";
import { unmeasuredNote } from "../measurement";
import styles from "../suivi.module.css";
import { Section, Unmeasured } from "./Section";

/**
 * Tunnel diagnostic (cohorte). Largeur de barre = `pctOfFirst`, colonne de
 * droite = `pctFromPrevious`, tous deux servis. Une etape `null` n'a PAS de
 * barre : un cadre pointille dit qu'elle n'est pas mesuree — une barre vide
 * se lirait « personne ».
 */
export function FunnelCard({ data }: { data: AdminSuiviResponse }) {
  const { funnel } = data;
  const allUnknown = funnel.steps.every((step) => step.count == null);

  const badges = (
    <>
      {funnel.ongoing && (
        <span
          className={`${styles.badge} ${styles.badgeOngoing}`}
          title={`La fenêtre de ${funnel.cohortWindowDays} jours n’est pas écoulée pour toute la cohorte : les chiffres peuvent encore monter.`}
        >
          en cours
        </span>
      )}
      <span className={styles.badge}>{SCOPE_LABELS[funnel.scope]}</span>
    </>
  );

  return (
    <Section
      title="Tunnel diagnostic"
      description={`Cohorte basée sur la première consultation du diagnostic. Fenêtre de conversion : ${funnel.cohortWindowDays} jours.`}
      badges={badges}
    >
      {allUnknown ? (
        <div className={styles.empty}>
          {capitalize(
            unmeasuredNote(data, funnel.steps[0]?.indicator ?? "DIAGNOSTIC_SUBJECT_VIEWED"),
          )}
          . Chaque étape s’affichera à partir de sa date de début de mesure, sans
          rattrapage des jours antérieurs.
        </div>
      ) : (
        <div className={styles.funnel}>
          {funnel.steps.map((step) => (
            <FunnelStepRow key={step.code} data={data} step={step} />
          ))}
        </div>
      )}
    </Section>
  );
}

function FunnelStepRow({ data, step }: { data: AdminSuiviResponse; step: SuiviFunnelStep }) {
  return (
    <>
      <div className={styles.funnelRow}>
        <div className={styles.funnelLabel}>{STEP_LABELS[step.code]}</div>
        <StepBar data={data} step={step} />
        <div className={styles.rate}>{pct(step.pctFromPrevious)}</div>
      </div>
      {step.code === "ACCOUNT_ATTACHED" && step.count != null && (
        <AttachedSubline data={data} />
      )}
      {step.code === "PURCHASED" && step.count != null && <CohortRevenueSubline data={data} />}
    </>
  );
}

function StepBar({ data, step }: { data: AdminSuiviResponse; step: SuiviFunnelStep }) {
  if (step.count == null) {
    return (
      <div className={`${styles.bar} ${styles.barUnmeasured}`}>
        <Unmeasured>{unmeasuredNote(data, step.indicator)}</Unmeasured>
      </div>
    );
  }
  if (step.count === 0 || !step.pctOfFirst) {
    return <div className={`${styles.bar} ${styles.barZero}`}>{int(step.count)}</div>;
  }
  return (
    <div className={styles.bar}>
      <div className={styles.fill} style={{ width: `${Math.min(100, step.pctOfFirst)}%` }}>
        {int(step.count)}
      </div>
    </div>
  );
}

function AttachedSubline({ data }: { data: AdminSuiviResponse }) {
  const { alreadyAuthenticated, signedUpAfter, loggedInAfter } = data.funnel.attached;
  return (
    <div className={styles.subline}>
      {int(signedUpAfter)} inscrits après diagnostic · {int(loggedInAfter)} connectés après
      diagnostic · {int(alreadyAuthenticated)} déjà connectés
    </div>
  );
}

function CohortRevenueSubline({ data }: { data: AdminSuiviResponse }) {
  const { cohortNetExVatCents, cohortPurchasesWithoutBreakdown, ongoing } = data.funnel;
  return (
    <div className={styles.subline}>
      CA net cohorte :{" "}
      {cohortNetExVatCents == null ? (
        <>
          {DASH} <Unmeasured>({unmeasuredNote(data, "REVENUE_BREAKDOWN")})</Unmeasured>
        </>
      ) : (
        <strong>{money(cohortNetExVatCents)}</strong>
      )}
      {cohortPurchasesWithoutBreakdown != null && cohortPurchasesWithoutBreakdown > 0 && (
        <> · {int(cohortPurchasesWithoutBreakdown)} sans décomposition, non comptés</>
      )}
      {ongoing && (
        <>
          {" "}
          · <span className={styles.ongoingMark}>en cours</span>
        </>
      )}
    </div>
  );
}

function capitalize(text: string): string {
  return text.charAt(0).toUpperCase() + text.slice(1);
}
