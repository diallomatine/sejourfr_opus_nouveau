import { useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { HttpError, httpErrorMessage } from "../../../api/http";
import { usersApi } from "../../../api/usersApi";
import { Button } from "../../../components/ui/Button";
import { FormRow, Input, Select, Textarea } from "../../../components/ui/Form";
import { Modal } from "../../../components/ui/Modal";
import { Spinner } from "../../../components/ui/Spinner";
import { useToast } from "../../../components/ui/Toast";
import { useDebouncedValue } from "../../../hooks/useDebouncedValue";
import type {
  AdminAccessOperationRequest,
  AdminAccessOperationType,
  AdminAccessProductDto,
  AdminUserAccessDto,
  ModuleAccess,
} from "../../../types/api";
import styles from "./AccessOperationModal.module.css";

/** Ce que le bouton cliqué demande : l'opération, le produit de la carte, son libellé servi. */
export interface AccessOperationIntent {
  operation: AdminAccessOperationType;
  /** Produit de la carte ; `null` pour « Donner un accès » global (produit à choisir). */
  product: ModuleAccess | null;
  label: string;
}

interface AccessOperationModalProps {
  userId: string;
  userLabel: string;
  /** `accessVersion` de la fiche À L'OUVERTURE : renvoyée en `expectedVersion`. */
  accessVersion: string;
  accesses: AdminUserAccessDto[];
  intent: AccessOperationIntent;
  onClose: () => void;
}

const REASON_MIN = 3;
const REASON_MAX = 500;

/** Champs que l'API lit selon l'opération (contrat de `AdminAccessOperationRequest`). */
const READS_START: readonly AdminAccessOperationType[] = ["GRANT", "REACTIVATE"];
const PREFILLS_END: readonly AdminAccessOperationType[] = ["EXTEND", "SHORTEN", "CORRECT_PRODUCT"];

/**
 * La modale UNIQUE des actions d'accès (spec §6). Rien n'y est décidé : les
 * produits viennent de `/api/admin/access-products`, l'aperçu et la phrase de
 * confirmation sont la réponse `dryRun: true` du serveur, la seconde étape
 * n'apparaît que si `confirmationRequired` est servi. L'écriture renvoie
 * l'`accessVersion` lue à l'ouverture : 409 si l'accès a changé depuis.
 */
export function AccessOperationModal({
  userId,
  userLabel,
  accessVersion,
  accesses,
  intent,
  onClose,
}: AccessOperationModalProps) {
  const queryClient = useQueryClient();
  const toast = useToast();
  const { operation } = intent;
  const isCorrection = operation === "CORRECT_PRODUCT";
  const readsStart = READS_START.includes(operation);
  const readsEnd = operation !== "END";

  const [expectedVersion] = useState(accessVersion);
  const sourceAccess = accesses.find((a) => a.product === intent.product) ?? null;

  const productsQuery = useQuery({
    queryKey: ["adminAccessProducts"],
    queryFn: () => usersApi.products(),
    staleTime: 5 * 60_000,
  });
  const products = productsQuery.data ?? [];
  const choosableProducts: AdminAccessProductDto[] = isCorrection
    ? products.filter((p) => p.code !== intent.product)
    : products;

  const [chosenProduct, setChosenProduct] = useState<ModuleAccess | "">("");
  const [startDate, setStartDate] = useState("");
  const [endDate, setEndDate] = useState(
    PREFILLS_END.includes(operation) ? (sourceAccess?.defaultEndDateInclusive ?? "") : "",
  );
  const [reason, setReason] = useState("");
  const [step, setStep] = useState<"form" | "confirm">("form");

  const needsProductChoice = isCorrection || intent.product === null;
  const product: ModuleAccess | "" = needsProductChoice
    ? chosenProduct || choosableProducts[0]?.code || ""
    : (intent.product ?? "");

  const trimmedReason = reason.trim();
  const reasonValid = trimmedReason.length >= REASON_MIN && trimmedReason.length <= REASON_MAX;
  const complete = product !== "" && reasonValid && (!readsEnd || endDate !== "");

  const request = useMemo<AdminAccessOperationRequest | null>(() => {
    if (!complete) return null;
    return {
      operation,
      product,
      fromProduct: isCorrection && intent.product ? intent.product : undefined,
      startDate: readsStart && startDate ? startDate : undefined,
      endDateInclusive: readsEnd ? endDate : undefined,
      reason: trimmedReason,
      dryRun: true,
      expectedVersion,
    };
  }, [
    complete,
    product,
    operation,
    isCorrection,
    intent.product,
    readsStart,
    startDate,
    readsEnd,
    endDate,
    trimmedReason,
    expectedVersion,
  ]);

  const requestKey = request ? JSON.stringify(request) : null;
  const debouncedKey = useDebouncedValue(requestKey, 400);

  const previewQuery = useQuery({
    queryKey: ["adminUserAccessPreview", userId, debouncedKey],
    queryFn: () => usersApi.accessOperation(userId, JSON.parse(debouncedKey!) as AdminAccessOperationRequest),
    enabled: debouncedKey !== null && debouncedKey === requestKey,
    retry: false,
    staleTime: 0,
    gcTime: 0,
  });

  const previewIsCurrent = debouncedKey !== null && debouncedKey === requestKey;
  const preview = previewIsCurrent && previewQuery.isSuccess ? previewQuery.data : null;
  const previewError = previewIsCurrent && previewQuery.isError ? previewQuery.error : null;

  const mutation = useMutation({
    mutationFn: (req: AdminAccessOperationRequest) =>
      usersApi.accessOperation(userId, { ...req, dryRun: false }),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: ["adminUsers"] });
      toast.show(`${intent.label} : action enregistrée.`, "success");
      onClose();
    },
  });

  const conflict =
    (mutation.error instanceof HttpError && mutation.error.status === 409) ||
    (previewError instanceof HttpError && previewError.status === 409);

  const reloadAndClose = () => {
    void queryClient.invalidateQueries({ queryKey: ["adminUsers"] });
    onClose();
  };

  const submit = () => {
    if (!request || !preview) return;
    if (step === "form" && preview.confirmationRequired) {
      setStep("confirm");
      return;
    }
    mutation.mutate(request);
  };

  const busy = mutation.isPending;
  const footer =
    step === "confirm" ? (
      <>
        <Button variant="ghost" onClick={() => setStep("form")} disabled={busy}>
          Annuler
        </Button>
        <Button variant="red" onClick={submit} disabled={busy || !preview}>
          {busy ? "Enregistrement…" : "Confirmer"}
        </Button>
      </>
    ) : (
      <>
        <Button variant="ghost" onClick={onClose} disabled={busy}>
          Annuler
        </Button>
        <Button variant="primary" onClick={submit} disabled={busy || !preview}>
          {busy ? "Enregistrement…" : preview?.confirmationRequired ? "Continuer" : "Enregistrer"}
        </Button>
      </>
    );

  return (
    <Modal open onClose={busy ? () => undefined : onClose} title={intent.label} eyebrow={userLabel} footer={footer}>
      {step === "confirm" && preview ? (
        <div className={styles.confirm}>
          <div className={styles.confirmTitle}>Confirmation</div>
          <p className={styles.confirmText}>{preview.preview}</p>
          {preview.changes.length > 0 && (
            <ul className={styles.changes}>
              {preview.changes.map((c) => (
                <li key={c}>{c}</li>
              ))}
            </ul>
          )}
          <p className={styles.motif}>Motif : {trimmedReason}</p>
        </div>
      ) : (
        <>
          {sourceAccess && (
            <div className={styles.current}>
              <span className={styles.currentLabel}>
                {isCorrection ? "Produit à corriger" : "Produit"} · {sourceAccess.productLabel}
              </span>
              <span>{sourceAccess.summary}</span>
            </div>
          )}

          {needsProductChoice && (
            <FormRow label={isCorrection ? "Nouveau produit" : "Produit"} htmlFor="access-product">
              {productsQuery.isPending ? (
                <Spinner label="Chargement des produits..." />
              ) : productsQuery.isError ? (
                <div className={styles.error}>{httpErrorMessage(productsQuery.error)}</div>
              ) : (
                <Select
                  id="access-product"
                  value={product}
                  onChange={(e) => setChosenProduct(e.target.value as ModuleAccess)}
                >
                  {choosableProducts.map((p) => (
                    <option key={p.code} value={p.code}>
                      {p.label} — modules : {p.modulesLabel}
                    </option>
                  ))}
                </Select>
              )}
            </FormRow>
          )}

          {(readsStart || readsEnd) && (
            <div className={styles.dates}>
              {readsStart && (
                <FormRow label="Début" htmlFor="access-start">
                  <Input
                    id="access-start"
                    type="date"
                    value={startDate}
                    onChange={(e) => setStartDate(e.target.value)}
                  />
                  <span className={styles.hint}>Vide : dès maintenant. Une date future programme l'accès.</span>
                </FormRow>
              )}
              {readsEnd && (
                <FormRow label="Fin (incluse)" htmlFor="access-end">
                  <Input
                    id="access-end"
                    type="date"
                    value={endDate}
                    onChange={(e) => setEndDate(e.target.value)}
                    required
                  />
                  <span className={styles.hint}>Dernier jour d'accès, heure de Paris.</span>
                </FormRow>
              )}
            </div>
          )}

          <FormRow label="Motif" htmlFor="access-reason">
            <Textarea
              id="access-reason"
              value={reason}
              maxLength={REASON_MAX}
              placeholder="Ex. erreur de produit lors de l'achat, geste commercial…"
              onChange={(e) => setReason(e.target.value)}
            />
            <span className={styles.hint}>
              {trimmedReason.length} / {REASON_MAX} — au moins {REASON_MIN} caractères, sans donnée
              personnelle inutile.
            </span>
          </FormRow>

          <div className={styles.preview} aria-live="polite">
            <div className={styles.previewTitle}>Aperçu</div>
            {!request ? (
              <p className={styles.previewMuted}>
                Renseignez {readsEnd ? "la date de fin et " : ""}le motif pour obtenir l'aperçu calculé par le serveur.
              </p>
            ) : !previewIsCurrent || previewQuery.isFetching ? (
              <p className={styles.previewMuted}>Calcul de l'aperçu…</p>
            ) : previewError ? (
              <p className={styles.error}>{httpErrorMessage(previewError)}</p>
            ) : preview ? (
              <>
                <p className={styles.previewText}>{preview.preview}</p>
                {preview.changes.length > 0 && (
                  <ul className={styles.changes}>
                    {preview.changes.map((c) => (
                      <li key={c}>{c}</li>
                    ))}
                  </ul>
                )}
                <p className={styles.previewMuted}>
                  Après l'action : produit effectif {preview.effectiveAccess.effectiveProductLabel} · modules
                  ouverts : {preview.effectiveAccess.openModulesLabel}
                </p>
              </>
            ) : null}
          </div>

          <p className={styles.helper}>
            L'achat d'origine reste intact : aucune transaction, aucun paiement, aucun montant n'est modifié.
          </p>
        </>
      )}

      {mutation.isError && (
        <div className={styles.errorBox} role="alert">
          {conflict
            ? "L'état de cet utilisateur a changé depuis l'ouverture de la fenêtre. Rechargez la fiche avant de recommencer."
            : httpErrorMessage(mutation.error)}
        </div>
      )}
      {conflict && (
        <div className={styles.reload}>
          <Button variant="ghost" size="sm" onClick={reloadAndClose}>
            Recharger la fiche
          </Button>
        </div>
      )}
    </Modal>
  );
}
