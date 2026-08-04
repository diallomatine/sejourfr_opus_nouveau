import { useEffect, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useForm } from "react-hook-form";
import { plansApi } from "../../api/plansApi";
import { Button } from "../../components/ui/Button";
import { FormRow, Input } from "../../components/ui/Form";
import { Modal } from "../../components/ui/Modal";
import { PageHeader } from "../../components/ui/PageHeader";
import { EmptyState, Panel } from "../../components/ui/Panel";
import { Spinner } from "../../components/ui/Spinner";
import { Tag } from "../../components/ui/Tag";
import { useToast } from "../../components/ui/Toast";
import type {
  AdminPlanDto,
  AdminPlanUpdateRequest,
  BillingCycle,
  ModuleAccess,
} from "../../types/api";
import tableStyles from "../../components/ui/DataTable.module.css";
import styles from "./PlansPage.module.css";

const BILLING_CYCLE_LABEL: Record<BillingCycle, string> = {
  NONE: "—",
  MONTHLY: "Mensuel",
  THREE_MONTHS: "Trimestriel",
  YEARLY: "Annuel",
};

const MODULE_ACCESS_LABEL: Record<ModuleAccess, string> = {
  NONE: "Aucun",
  CIVIQUE: "Civique",
  INTEGRAL: "Intégral",
};

const MODULE_ACCESS_TONE: Record<ModuleAccess, "csp" | "premium" | "muted"> = {
  NONE: "muted",
  CIVIQUE: "csp",
  INTEGRAL: "premium",
};

function formatPrice(n: number | null | undefined): string {
  if (n === null || n === undefined) return "—";
  return new Intl.NumberFormat("fr-FR", {
    style: "currency",
    currency: "EUR",
  }).format(n);
}

export function PlansPage() {
  const [editing, setEditing] = useState<AdminPlanDto | null>(null);

  const plansQuery = useQuery({
    queryKey: ["adminPlans"],
    queryFn: plansApi.list,
  });

  return (
    <>
      <PageHeader
        eyebrow="§ 06 — Commerce"
        title="Plans &amp; "
        emphasis="tarifs"
      />

      {plansQuery.isLoading && <Spinner label="Chargement..." />}

      {plansQuery.isError && (
        <Panel>
          <div className={styles.error}>
            Erreur : {(plansQuery.error as Error).message}
          </div>
        </Panel>
      )}

      {plansQuery.data && (
        <Panel
          title="Catalogue"
          sub={`${plansQuery.data.length} plans en base · trié par module et prix`}
          noPadding
        >
          {plansQuery.data.length === 0 ? (
            <EmptyState title="Aucun plan en base" />
          ) : (
            <div className={tableStyles.tableWrap}>
              <table className={`${tableStyles.table} ${tableStyles.cardTable}`}>
                <thead>
                  <tr>
                    <th>Plan</th>
                    <th>Module</th>
                    <th>Type / durée</th>
                    <th>Prix</th>
                    <th>Statut</th>
                    <th>SKUs stores</th>
                    <th></th>
                  </tr>
                </thead>
                <tbody>
                  {plansQuery.data.map((p) => (
                    <tr key={p.id}>
                      <td data-label="Plan">
                        <div>
                          <strong>{p.name}</strong>
                          <div className={styles.codeLine}>
                            <code>{p.code}</code>
                          </div>
                        </div>
                      </td>
                      <td data-label="Module">
                        <Tag tone={MODULE_ACCESS_TONE[p.moduleAccess]}>
                          {MODULE_ACCESS_LABEL[p.moduleAccess]}
                        </Tag>
                      </td>
                      <td data-label="Type">
                        {p.purchaseType === "ONE_TIME"
                          ? `Pass · ${p.durationDays} j`
                          : BILLING_CYCLE_LABEL[p.billingCycle]}
                      </td>
                      <td data-label="Prix">
                        <div className={styles.priceCell}>
                          <strong>{formatPrice(p.price)}</strong>
                          {p.originalPrice !== null && p.originalPrice > p.price && (
                            <span className={styles.priceOld}>
                              {formatPrice(p.originalPrice)}
                            </span>
                          )}
                        </div>
                      </td>
                      <td data-label="Statut">
                        {p.active ? (
                          <Tag tone="active">Actif</Tag>
                        ) : (
                          <Tag tone="muted">Inactif</Tag>
                        )}
                      </td>
                      <td data-label="SKUs">
                        <StoreSkusCell plan={p} />
                      </td>
                      <td data-label="Action">
                        <div className={tableStyles.rowActions}>
                          <button
                            type="button"
                            className={tableStyles.iconBtn}
                            onClick={() => setEditing(p)}
                          >
                            Modifier
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </Panel>
      )}

      <PlanEditModal
        open={editing !== null}
        onClose={() => setEditing(null)}
        plan={editing}
      />
    </>
  );
}

function StoreSkusCell({ plan }: { plan: AdminPlanDto }) {
  const skus = [
    { label: "S", title: "Stripe Price ID", value: plan.stripePriceId },
    { label: "A", title: "Apple Product ID", value: plan.appleProductId },
    { label: "G", title: "Google Product ID", value: plan.googleProductId },
  ];
  return (
    <div className={styles.skusCell}>
      {skus.map((s) => (
        <span
          key={s.label}
          className={`${styles.skuBadge} ${s.value ? styles.skuBadgeOk : styles.skuBadgeMissing}`}
          title={s.value ? `${s.title}: ${s.value}` : `${s.title} non renseigné`}
        >
          {s.label}
        </span>
      ))}
    </div>
  );
}

// ============================================================================
// MODAL D'ÉDITION
// ============================================================================

// `valueAsNumber` renvoie NaN quand l'utilisateur vide un champ nombre : on le
// traite explicitement, sinon JSON.stringify le sérialise en `null` et le
// backend comprend « champ non touché » au lieu de « efface le prix barré ».
interface PlanFormValues {
  price: number;
  originalPrice: number;
  active: boolean;
  stripePriceId: string;
  appleProductId: string;
  googleProductId: string;
}

function PlanEditModal({
  open,
  onClose,
  plan,
}: {
  open: boolean;
  onClose: () => void;
  plan: AdminPlanDto | null;
}) {
  const toast = useToast();
  const queryClient = useQueryClient();
  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<PlanFormValues>();

  useEffect(() => {
    if (!open || !plan) return;
    reset({
      price: plan.price,
      originalPrice: plan.originalPrice ?? 0,
      active: plan.active,
      stripePriceId: plan.stripePriceId ?? "",
      appleProductId: plan.appleProductId ?? "",
      googleProductId: plan.googleProductId ?? "",
    });
  }, [open, plan, reset]);

  const mutation = useMutation({
    mutationFn: (values: PlanFormValues) => {
      if (!plan) throw new Error("Pas de plan sélectionné");
      const req: AdminPlanUpdateRequest = {
        price: values.price,
        originalPrice: Number.isFinite(values.originalPrice)
          ? values.originalPrice
          : 0,
        active: values.active,
        stripePriceId: values.stripePriceId,
        appleProductId: values.appleProductId,
        googleProductId: values.googleProductId,
      };
      return plansApi.update(plan.id, req);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["adminPlans"] });
      toast.show("Plan mis à jour", "success");
      onClose();
    },
    onError: (err) => toast.show((err as Error).message, "error"),
  });

  if (!plan) return null;

  return (
    <Modal
      open={open}
      onClose={onClose}
      title={`Modifier · ${plan.name}`}
      eyebrow={plan.code}
      footer={
        <>
          <Button variant="ghost" onClick={onClose} disabled={mutation.isPending}>
            Annuler
          </Button>
          <Button
            variant="red"
            type="submit"
            form="plan-form"
            disabled={mutation.isPending}
          >
            {mutation.isPending ? "Enregistrement..." : "Enregistrer"}
          </Button>
        </>
      }
    >
      <form id="plan-form" onSubmit={handleSubmit((v) => mutation.mutate(v))}>
        <p className={styles.modalMeta}>
          {MODULE_ACCESS_LABEL[plan.moduleAccess]} ·{" "}
          {BILLING_CYCLE_LABEL[plan.billingCycle]} ·{" "}
          {plan.durationDays} jours d&apos;accès
        </p>

        <FormRow twoCol>
          <FormRow label="Prix (€)" htmlFor="price" error={errors.price?.message}>
            <Input
              id="price"
              type="number"
              step="0.01"
              min="0"
              {...register("price", {
                valueAsNumber: true,
                validate: (v) =>
                  (Number.isFinite(v) && v >= 0) || "Prix requis (0 ou plus)",
              })}
            />
          </FormRow>
          <FormRow
            label="Prix barré (€, vide ou 0 = aucun)"
            htmlFor="originalPrice"
            error={errors.originalPrice?.message}
          >
            <Input
              id="originalPrice"
              type="number"
              step="0.01"
              min="0"
              {...register("originalPrice", {
                valueAsNumber: true,
                validate: (v) =>
                  !Number.isFinite(v) || v >= 0 || "Doit être positif",
              })}
            />
          </FormRow>
        </FormRow>

        <FormRow>
          <label className={styles.checkboxRow}>
            <input type="checkbox" {...register("active")} />
            <span>Plan actif (affiché aux utilisateurs)</span>
          </label>
        </FormRow>

        <div className={styles.skuSection}>
          <h4 className={styles.skuTitle}>SKUs stores</h4>
          <p className={styles.skuHelp}>
            Au moins un SKU est requis pour qu&apos;un plan payant actif soit
            vendable. Laisser vide pour effacer.
          </p>

          <FormRow label="Stripe Price ID" htmlFor="stripePriceId">
            <Input
              id="stripePriceId"
              placeholder="price_xxx"
              {...register("stripePriceId")}
            />
          </FormRow>

          <FormRow label="Apple Product ID" htmlFor="appleProductId">
            <Input
              id="appleProductId"
              placeholder="com.sejourfr.integral.monthly"
              {...register("appleProductId")}
            />
          </FormRow>

          <FormRow label="Google Product ID" htmlFor="googleProductId">
            <Input
              id="googleProductId"
              placeholder="integral_monthly"
              {...register("googleProductId")}
            />
          </FormRow>
        </div>
      </form>
    </Modal>
  );
}
