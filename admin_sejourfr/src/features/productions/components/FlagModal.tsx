import { useState } from "react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { HttpError, httpErrorMessage } from "../../../api/http";
import { productionsApi } from "../../../api/productionsApi";
import { Button } from "../../../components/ui/Button";
import { Textarea } from "../../../components/ui/Form";
import { Modal } from "../../../components/ui/Modal";
import { useToast } from "../../../components/ui/Toast";
import type { MotifSignalement } from "../../../types/api";
import { MOTIF_OPTIONS } from "../productionLabels";
import styles from "./FlagModal.module.css";

const COMMENTAIRE_MAX = 1000;

function flagErrorMessage(error: unknown): string {
  if (error instanceof HttpError) {
    if (error.status === 409) return "Un signalement est déjà actif sur cette évaluation : rechargez la fiche.";
    if (error.status === 422) return "Cette production n'a aucune évaluation à signaler.";
  }
  return httpErrorMessage(error);
}

/** Motif obligatoire, commentaire facultatif. Ne modifie jamais l'évaluation ni le résultat candidat. */
export function FlagModal({ productionId, onClose }: { productionId: string; onClose: () => void }) {
  const toast = useToast();
  const queryClient = useQueryClient();
  const [motif, setMotif] = useState<MotifSignalement | null>(null);
  const [commentaire, setCommentaire] = useState("");
  const [submitted, setSubmitted] = useState(false);

  const mutation = useMutation({
    mutationFn: (selected: MotifSignalement) =>
      productionsApi.flag(productionId, { motif: selected, commentaire: commentaire.trim() || null }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["adminProductions"] });
      toast.show("Évaluation signalée", "success");
      onClose();
    },
  });

  const submit = () => {
    setSubmitted(true);
    if (motif === null || commentaire.length > COMMENTAIRE_MAX) return;
    mutation.mutate(motif);
  };

  return (
    <Modal
      open
      onClose={onClose}
      title="Signaler l'évaluation"
      description="Le niveau, les scores et le feedback du candidat ne sont pas modifiés."
      footer={
        <>
          <Button variant="ghost" type="button" onClick={onClose}>
            Annuler
          </Button>
          <Button variant="primary" type="button" onClick={submit} disabled={mutation.isPending}>
            {mutation.isPending ? "Envoi…" : "Signaler l'évaluation"}
          </Button>
        </>
      }
    >
      <fieldset className={styles.reasons}>
        <legend className={styles.legend}>Motif (obligatoire)</legend>
        {MOTIF_OPTIONS.map((option) => (
          <label key={option.value} className={`${styles.reason} ${motif === option.value ? styles.reasonOn : ""}`}>
            <input
              type="radio"
              name="motif"
              value={option.value}
              checked={motif === option.value}
              onChange={() => setMotif(option.value)}
            />
            <span>{option.label}</span>
          </label>
        ))}
      </fieldset>
      {submitted && motif === null && (
        <p className={styles.error} role="alert">
          Choisissez un motif pour signaler l&apos;évaluation.
        </p>
      )}

      <label className={styles.legend} htmlFor="flag-commentaire">
        Commentaire (facultatif)
      </label>
      <Textarea
        id="flag-commentaire"
        rows={4}
        maxLength={COMMENTAIRE_MAX}
        value={commentaire}
        onChange={(e) => setCommentaire(e.target.value)}
        placeholder="Ce qui paraît incohérent : niveau, score d'un critère, feedback, transcription…"
      />
      <p className={styles.counter}>
        {commentaire.length} / {COMMENTAIRE_MAX}
      </p>

      {mutation.isError && (
        <p className={styles.error} role="alert">
          {flagErrorMessage(mutation.error)}
        </p>
      )}
    </Modal>
  );
}
