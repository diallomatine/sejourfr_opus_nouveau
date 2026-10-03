import { useMutation, useQueryClient } from "@tanstack/react-query";
import { httpErrorMessage } from "../../../api/http";
import { productionsApi } from "../../../api/productionsApi";
import { Button } from "../../../components/ui/Button";
import { Icon } from "../../../components/ui/Icon";
import { Tag } from "../../../components/ui/Tag";
import { useToast } from "../../../components/ui/Toast";
import { formatParisDateTime } from "../../../lib/dates";
import type { AdminActeurDto, AdminProductionFlagDto } from "../../../types/api";
import { SIGNALEMENT_TONE } from "../productionLabels";
import styles from "./FlagSection.module.css";

function acteur(a: AdminActeurDto | null): string {
  if (a === null) return "admin inconnu";
  return a.nom ?? a.email ?? "compte supprimé";
}

type FlagAction = "verify" | "remove";

function useFlagAction() {
  const toast = useToast();
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ flagId, action }: { flagId: string; action: FlagAction }) =>
      action === "verify" ? productionsApi.verifyFlag(flagId) : productionsApi.removeFlag(flagId),
    onSuccess: (_, { action }) => {
      queryClient.invalidateQueries({ queryKey: ["adminProductions"] });
      toast.show(action === "verify" ? "Signalement marqué vérifié" : "Signalement retiré", "success");
    },
    onError: (error) => toast.show("Action impossible", "error", httpErrorMessage(error)),
  });
}

/** Bandeau du signalement actif (au plus un) : qui, quand, motif, commentaire, actions. */
export function ActiveFlagBanner({ flag }: { flag: AdminProductionFlagDto }) {
  const action = useFlagAction();
  const verified = flag.etat === "VERIFIE";

  return (
    <div className={`${styles.banner} ${verified ? styles.bannerVerified : ""}`}>
      <div className={styles.bannerMain}>
        <span className={styles.bannerIcon} aria-hidden="true">
          <Icon name={verified ? "checkCircle" : "flag"} size={20} />
        </span>
        <div className={styles.bannerText}>
          <p className={styles.bannerTitle}>{verified ? "Évaluation vérifiée" : "Évaluation signalée"}</p>
          <p className={styles.bannerMeta}>
            Signalée le {formatParisDateTime(flag.createdAt)} par {acteur(flag.createdBy)}
            {verified && flag.verifiedAt && (
              <>
                {" "}· vérifiée le {formatParisDateTime(flag.verifiedAt)} par {acteur(flag.verifiedBy)}
              </>
            )}
          </p>
          <p className={styles.bannerBody}>
            <strong>{flag.motifLabel}</strong>
            {flag.commentaire ? ` — ${flag.commentaire}` : ""}
          </p>
        </div>
      </div>
      <div className={styles.bannerActions}>
        {!verified && (
          <Button
            size="sm"
            variant="default"
            disabled={action.isPending}
            onClick={() => action.mutate({ flagId: flag.id, action: "verify" })}
          >
            Marquer vérifié
          </Button>
        )}
        <Button
          size="sm"
          variant="ghost"
          disabled={action.isPending}
          onClick={() => action.mutate({ flagId: flag.id, action: "remove" })}
        >
          Retirer
        </Button>
      </div>
    </div>
  );
}

/** Tous les signalements, retirés compris, le plus récent d'abord (ordre servi). */
export function FlagHistory({ flags }: { flags: AdminProductionFlagDto[] }) {
  return (
    <ol className={styles.history}>
      {flags.map((flag) => (
        <li key={flag.id} className={styles.entry}>
          <div className={styles.entryHead}>
            <Tag tone={SIGNALEMENT_TONE[flag.etat]} dot>
              {flag.etatLabel}
            </Tag>
            <strong className={styles.entryMotif}>{flag.motifLabel}</strong>
          </div>
          {flag.commentaire && <p className={styles.entryComment}>{flag.commentaire}</p>}
          <p className={styles.entryMeta}>
            Signalé le {formatParisDateTime(flag.createdAt)} par {acteur(flag.createdBy)}
            {flag.verifiedAt && ` · vérifié le ${formatParisDateTime(flag.verifiedAt)} par ${acteur(flag.verifiedBy)}`}
            {flag.removedAt && ` · retiré le ${formatParisDateTime(flag.removedAt)} par ${acteur(flag.removedBy)}`}
          </p>
        </li>
      ))}
    </ol>
  );
}
