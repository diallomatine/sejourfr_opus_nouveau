import { useState } from "react";
import { useMutation } from "@tanstack/react-query";
import { HttpError } from "../../api/http";
import { mailingApi } from "../../api/mailingApi";
import { Button } from "../../components/ui/Button";
import { Panel } from "../../components/ui/Panel";
import type { LegacyCompensationMailingResponse } from "../../types/api";
import styles from "./AnciensAcheteursPanel.module.css";

/**
 * Envoi unique de l'annonce des nouveautés aux acheteurs de l'ancien catalogue
 * Intégral, compensés par la migration V038 (accès prolongé + plancher de
 * simulations orales).
 *
 * <p>Deux temps volontairement séparés : on compte d'abord (« Vérifier »,
 * `dryRun`), on envoie ensuite. Le bouton d'envoi n'apparaît qu'une fois le
 * comptage fait — on n'écrit pas à de vrais clients payants en un seul clic.
 *
 * <p>L'anti-doublon est côté serveur (`mailed_at` posé après un envoi réussi,
 * une seule compensation par compte) : recliquer ne reprend que les échecs.
 * L'écran n'a donc aucun état à protéger.
 */
export function AnciensAcheteursPanel() {
  const [rapport, setRapport] = useState<LegacyCompensationMailingResponse | null>(null);

  const mutation = useMutation({
    mutationFn: (dryRun: boolean) => mailingApi.anciensAcheteurs(dryRun),
    onSuccess: setRapport,
  });

  const compte = rapport !== null;
  const restants = rapport?.aEnvoyer ?? 0;
  const erreur = mutation.error as Error | HttpError | null;

  function envoyer() {
    const message =
      `Envoyer l'annonce à ${restants} personne(s) ?\n\n` +
      "Ce sont de vrais clients : l'e-mail part immédiatement et ne peut pas être rappelé.";
    if (!window.confirm(message)) return;
    mutation.mutate(false);
  }

  return (
    <Panel
      title="Anciens acheteurs — annonce des nouveautés"
      sub="Envoi unique aux clients de l'ancien catalogue Intégral (pass sprint 6 semaines et pass 3 mois), dont l'accès a été prolongé et le solde de simulations relevé par la migration V038."
    >
      {compte && (
        <div className={styles.stats}>
          <Stat label="Compensés" value={rapport.total} />
          <Stat label="Déjà prévenus" value={rapport.dejaEnvoyes} />
          <Stat label="Restent à prévenir" value={rapport.aEnvoyer} accent />
          {!rapport.dryRun && <Stat label="Envoyés à l'instant" value={rapport.envoyes} />}
          {!rapport.dryRun && rapport.echecs > 0 && (
            <Stat label="Échecs" value={rapport.echecs} accent />
          )}
        </div>
      )}

      <div className={styles.actions}>
        <Button
          variant="default"
          onClick={() => mutation.mutate(true)}
          disabled={mutation.isPending}
        >
          {mutation.isPending && mutation.variables === true
            ? "Comptage..."
            : "Vérifier les destinataires"}
        </Button>

        {compte && restants > 0 && (
          <Button variant="red" onClick={envoyer} disabled={mutation.isPending}>
            {mutation.isPending && mutation.variables === false
              ? "Envoi en cours..."
              : `Envoyer à ${restants} personne(s)`}
          </Button>
        )}
      </div>

      {erreur && <div className={styles.error}>Erreur : {erreur.message}</div>}

      {compte && rapport.dryRun && restants === 0 && (
        <div className={styles.note}>
          Personne à prévenir : tout le monde a déjà reçu l'annonce, ou aucun acheteur
          de l'ancien catalogue n'a été compensé sur cette base.
        </div>
      )}

      {compte && !rapport.dryRun && rapport.echecs > 0 && (
        <div className={styles.note}>
          Les {rapport.echecs} échec(s) restent à envoyer : recliquer sur « Envoyer »
          les reprendra sans réécrire à ceux qui ont déjà reçu.
        </div>
      )}
    </Panel>
  );
}

function Stat({
  label,
  value,
  accent,
}: {
  label: string;
  value: number;
  accent?: boolean;
}) {
  return (
    <div className={styles.stat}>
      <div className={styles.statLabel}>{label}</div>
      <div className={accent ? `${styles.statValue} ${styles.accent}` : styles.statValue}>
        {value}
      </div>
    </div>
  );
}
