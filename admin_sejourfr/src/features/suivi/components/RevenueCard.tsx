import type { AdminSuiviResponse } from "../../../types/api";
import { DASH, count, deduction, int, money } from "../format";
import { PROVIDER_LABELS } from "../labels";
import { unmeasuredNote } from "../measurement";
import styles from "../suivi.module.css";
import { Unmeasured } from "./Section";

/**
 * Revenus de la periode : brut → TVA → frais → remboursements → net reel
 * estime. Le net affiche en tete est `netExVatAfterRefundsCents`, le meme que
 * le KPI ; aucune ligne n'est recalculee ici.
 */
export function RevenueCard({ data }: { data: AdminSuiviResponse }) {
  const { revenue } = data;
  const { refunds } = revenue;
  const title = data.window.preset === "TODAY" ? "Revenus du jour" : "Revenus de la période";

  return (
    <div className={`${styles.card} ${styles.money}`}>
      <div className={styles.sectionHead}>
        <div>
          <h2>{title}</h2>
          <p>Achats confirmés uniquement.</p>
        </div>
      </div>

      <div className={styles.moneyMain}>
        <div className={styles.moneySmall}>NET RÉEL ESTIMÉ</div>
        <div className={styles.moneyBig}>{money(revenue.netExVatAfterRefundsCents)}</div>
        {revenue.netExVatAfterRefundsCents == null && (
          <div className={styles.note}>
            <Unmeasured>{unmeasuredNote(data, "REVENUE_BREAKDOWN")}</Unmeasured>
          </div>
        )}
      </div>

      <div className={styles.moneyRow}>
        <span>Brut payé</span>
        <strong>{money(revenue.grossCents)}</strong>
      </div>
      <div className={styles.moneyRow}>
        <span>TVA retirée</span>
        <strong>{deduction(revenue.vatCents)}</strong>
      </div>
      <div className={styles.moneyRow}>
        <span>Frais plateformes</span>
        <strong>{deduction(revenue.providerFeeCents)}</strong>
      </div>
      <div className={styles.moneyRow}>
        <span>
          Remboursements
          {refunds.count == null ? "" : ` · ${int(refunds.count)}`}
          {refunds.amountCents != null && refunds.amountCents > 0
            ? ` (${money(refunds.amountCents)} rendus)`
            : ""}
        </span>
        <strong>
          {refunds.netExVatDeltaCents == null ? (
            refunds.count == null ? (
              <Unmeasured>{unmeasuredNote(data, "REFUNDS")}</Unmeasured>
            ) : (
              DASH
            )
          ) : (
            money(refunds.netExVatDeltaCents)
          )}
        </strong>
      </div>
      {revenue.byProvider.map((row) => (
        <div key={row.provider} className={styles.moneyRow}>
          <span>{PROVIDER_LABELS[row.provider]}</span>
          <strong>{count(row.purchases, "achat", "achats")}</strong>
        </div>
      ))}

      {revenue.purchasesWithoutBreakdown != null && revenue.purchasesWithoutBreakdown > 0 && (
        <p className={styles.footnote}>
          {count(revenue.purchasesWithoutBreakdown, "achat", "achats")} sans décomposition
          TVA / frais : non comptés dans le net.
        </p>
      )}
      {revenue.estimatedFeePurchases != null && revenue.estimatedFeePurchases > 0 && (
        <p className={styles.footnote}>
          Frais estimés par formule pour{" "}
          {count(revenue.estimatedFeePurchases, "achat", "achats")}.
        </p>
      )}
    </div>
  );
}
