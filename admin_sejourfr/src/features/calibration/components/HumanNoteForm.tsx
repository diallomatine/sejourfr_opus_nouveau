import { useEffect } from "react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { useForm } from "react-hook-form";
import { calibrationApi } from "../../../api/calibrationApi";
import { Button } from "../../../components/ui/Button";
import { FormRow, Input, Select, Textarea } from "../../../components/ui/Form";
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
  /** Note saisie pendant cette session — l'API n'expose pas les notes passées. */
  sessionNote: HumanCalibrationNoteDto | null;
  /** La soumission portait déjà une note humaine avant cette session. */
  previouslyAnnotated: boolean;
  onSaved: (note: HumanCalibrationNoteDto) => void;
}

export function HumanNoteForm({
  submissionId,
  noteIa,
  seuilHorsCible,
  sessionNote,
  previouslyAnnotated,
  onSaved,
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
    reset({
      noteHumaineSurVingt:
        sessionNote === null ? "" : String(sessionNote.noteHumaineSurVingt),
      niveauCecrlHumain: sessionNote?.niveauCecrlHumain ?? "",
      commentaires: sessionNote?.commentaires ?? "",
    });
  }, [submissionId, sessionNote, reset]);

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
    onSuccess: (note) => {
      queryClient.invalidateQueries({ queryKey: ["calibration"] });
      toast.show("Note humaine enregistrée", "success");
      onSaved(note);
    },
    onError: (err) => toast.show((err as Error).message, "error"),
  });

  const gap =
    sessionNote && noteIa !== null
      ? sessionNote.noteHumaineSurVingt - noteIa
      : null;

  return (
    <section className={styles.wrap}>
      <h3 className={styles.title}>Votre correction</h3>

      {previouslyAnnotated && !sessionNote && (
        <p className={styles.warn}>
          Cette production a déjà été annotée. L&apos;API n&apos;expose pas le
          détail des notes enregistrées : le formulaire repart donc vide.
          Enregistrer ajoutera une <strong>observation supplémentaire</strong>,
          sans remplacer la précédente.
        </p>
      )}

      {gap !== null && sessionNote && <GapBanner gap={gap} seuil={seuilHorsCible} />}

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
