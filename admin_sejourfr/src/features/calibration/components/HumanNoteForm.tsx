import { useEffect } from "react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { useForm } from "react-hook-form";
import { calibrationApi } from "../../../api/calibrationApi";
import { Button } from "../../../components/ui/Button";
import { FormRow, Input, Select, Textarea } from "../../../components/ui/Form";
import { Spinner } from "../../../components/ui/Spinner";
import { useToast } from "../../../components/ui/Toast";
import type { HumanCalibrationNoteDto, NiveauCecrl } from "../../../types/api";
import {
  NIVEAU_LABEL,
  NIVEAU_ORDER,
  formatSigned,
  readGap,
} from "../calibrationHelpers";
import styles from "./HumanNoteForm.module.css";

/** La note reste une chaîne dans le formulaire : un champ vide vaut "", jamais NaN. */
interface HumanNoteFormValues {
  noteHumaineSurVingt: string;
  niveauCecrlHumain: NiveauCecrl | "";
  commentaires: string;
}

function parseNote(raw: string): number | null {
  const parsed = Number(raw.replace(",", "."));
  if (!Number.isFinite(parsed) || parsed < 0 || parsed > 20) return null;
  return parsed;
}

interface HumanNoteFormProps {
  submissionId: string;
  noteIa: number | null;
  seuilHorsCible: number;
  /** Dernière note humaine enregistrée pour cette soumission, ou `null` si jamais annotée. */
  existingNote: HumanCalibrationNoteDto | null;
  isLoadingNote: boolean;
}

export function HumanNoteForm({
  submissionId,
  noteIa,
  seuilHorsCible,
  existingNote,
  isLoadingNote,
}: HumanNoteFormProps) {
  const toast = useToast();
  const queryClient = useQueryClient();
  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<HumanNoteFormValues>({
    defaultValues: {
      noteHumaineSurVingt: "",
      niveauCecrlHumain: "",
      commentaires: "",
    },
  });

  useEffect(() => {
    if (isLoadingNote) return;
    reset({
      noteHumaineSurVingt:
        existingNote === null ? "" : String(existingNote.noteHumaineSurVingt),
      niveauCecrlHumain: existingNote?.niveauCecrlHumain ?? "",
      commentaires: existingNote?.commentaires ?? "",
    });
  }, [existingNote, isLoadingNote, reset]);

  const mutation = useMutation({
    mutationFn: (values: HumanNoteFormValues) => {
      const note = parseNote(values.noteHumaineSurVingt);
      if (note === null) throw new Error("Note humaine invalide.");
      return calibrationApi.saveHumanNote(submissionId, {
        submissionId,
        noteHumaineSurVingt: note,
        niveauCecrlHumain: values.niveauCecrlHumain as NiveauCecrl,
        commentaires: values.commentaires.trim() || null,
      });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["calibration"] });
      toast.show("Note humaine enregistrée", "success");
    },
    onError: (err) => toast.show((err as Error).message, "error"),
  });

  const displayedNote = mutation.data ?? existingNote;
  const gap =
    displayedNote && noteIa !== null
      ? displayedNote.noteHumaineSurVingt - noteIa
      : null;

  return (
    <section className={styles.wrap}>
      <h3 className={styles.title}>Votre correction</h3>

      {isLoadingNote && <Spinner label="Recherche d'une note précédente…" />}

      {existingNote && !mutation.data && (
        <p className={styles.warn}>
          Cette production a déjà été annotée — le formulaire ci-dessous
          reprend la note la plus récente. Enregistrer{" "}
          <strong>ajoute une nouvelle observation</strong> à l&apos;historique
          plutôt que de remplacer la précédente ; c&apos;est toujours la plus
          récente par soumission qui compte dans les statistiques.
        </p>
      )}

      {gap !== null && <GapBanner gap={gap} seuil={seuilHorsCible} />}

      <form
        className={styles.form}
        onSubmit={handleSubmit((values) => mutation.mutate(values))}
      >
        <FormRow twoCol>
          <FormRow
            label="Note humaine (/20)"
            htmlFor="noteHumaine"
            error={errors.noteHumaineSurVingt ? "Note requise, entre 0 et 20." : undefined}
          >
            <Input
              id="noteHumaine"
              type="number"
              step="0.5"
              min="0"
              max="20"
              placeholder="Ex. 12,5"
              {...register("noteHumaineSurVingt", {
                required: true,
                validate: (value) => parseNote(value) !== null,
              })}
            />
          </FormRow>

          <FormRow
            label="Niveau CECRL"
            htmlFor="niveauHumain"
            error={errors.niveauCecrlHumain ? "Niveau requis." : undefined}
          >
            <Select
              id="niveauHumain"
              {...register("niveauCecrlHumain", { required: true })}
            >
              <option value="">Choisir…</option>
              {NIVEAU_ORDER.map((niveau) => (
                <option key={niveau} value={niveau}>
                  {NIVEAU_LABEL[niveau]}
                </option>
              ))}
            </Select>
          </FormRow>
        </FormRow>

        <FormRow label="Commentaires (facultatif)" htmlFor="commentaires">
          <Textarea
            id="commentaires"
            rows={4}
            placeholder="Ce qui justifie l'écart avec l'IA, les points qu'elle a manqués ou surévalués…"
            {...register("commentaires")}
          />
        </FormRow>

        <div className={styles.actions}>
          <span className={styles.hint}>
            {noteIa === null
              ? "Aucune note IA sur cette soumission : l'écart ne sera pas calculable."
              : "L'écart est calculé côté serveur à l'enregistrement."}
          </span>
          <Button variant="red" type="submit" disabled={mutation.isPending}>
            {mutation.isPending ? "Enregistrement…" : "Enregistrer la note"}
          </Button>
        </div>
      </form>
    </section>
  );
}

function GapBanner({ gap, seuil }: { gap: number; seuil: number }) {
  const reading = readGap(gap, seuil);
  return (
    <div className={`${styles.gap} ${styles[reading.tone]}`}>
      <span className={styles.gapValue}>{formatSigned(gap)} pt</span>
      <span className={styles.gapText}>{reading.sentence}</span>
      <span className={styles.gapFormula}>écart = note humaine − note IA</span>
    </div>
  );
}
