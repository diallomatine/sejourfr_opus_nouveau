import { useEffect } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useForm } from "react-hook-form";
import { skillsApi } from "../../api/skillsApi";
import { Button } from "../../components/ui/Button";
import { Textarea } from "../../components/ui/Form";
import { Modal } from "../../components/ui/Modal";
import { Spinner } from "../../components/ui/Spinner";
import { useToast } from "../../components/ui/Toast";
import type { SkillReferenceDto, SkillReferenceLevel } from "../../types/api";
import { REFERENCE_HELP, REFERENCE_LABEL, REFERENCE_LEVELS } from "./skillHelpers";
import styles from "./SkillReferencesModal.module.css";

interface ReferenceFields {
  text: string;
  pedagogicalNote: string;
}

type ReferencesFormValues = Record<SkillReferenceLevel, ReferenceFields>;

const EMPTY: ReferencesFormValues = {
  INSUFFICIENT: { text: "", pedagogicalNote: "" },
  EXPECTED: { text: "", pedagogicalNote: "" },
  EXCELLENT: { text: "", pedagogicalNote: "" },
};

function toFormValues(references: SkillReferenceDto[]): ReferencesFormValues {
  const values: ReferencesFormValues = {
    INSUFFICIENT: { ...EMPTY.INSUFFICIENT },
    EXPECTED: { ...EMPTY.EXPECTED },
    EXCELLENT: { ...EMPTY.EXCELLENT },
  };
  for (const level of REFERENCE_LEVELS) {
    const found = references.find((ref) => ref.level === level);
    if (found) {
      values[level] = { text: found.text, pedagogicalNote: found.pedagogicalNote };
    }
  }
  return values;
}

/**
 * Édition des 3 références d'un sujet. Le `PUT` est atomique côté serveur et
 * exige les 3 niveaux sans doublon : le formulaire n'expose donc ni ajout ni
 * suppression de niveau, et refuse de partir tant qu'un champ manque.
 */
export function SkillReferencesModal({
  open,
  promptId,
  promptCode,
  promptTitle,
  onClose,
}: {
  open: boolean;
  promptId: string | null;
  promptCode: string;
  promptTitle: string;
  onClose: () => void;
}) {
  const toast = useToast();
  const queryClient = useQueryClient();

  const promptQuery = useQuery({
    queryKey: ["adminSkillPrompts", "detail", promptId],
    queryFn: () => skillsApi.getPrompt(promptId as string),
    enabled: open && promptId !== null,
  });

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<ReferencesFormValues>({ defaultValues: EMPTY });

  useEffect(() => {
    if (!open) return;
    reset(promptQuery.data ? toFormValues(promptQuery.data.references) : EMPTY);
  }, [open, promptQuery.data, reset]);

  const mutation = useMutation({
    mutationFn: (values: ReferencesFormValues) => {
      if (!promptId) throw new Error("Aucun sujet sélectionné");
      const references: SkillReferenceDto[] = REFERENCE_LEVELS.map((level) => ({
        level,
        text: values[level].text.trim(),
        pedagogicalNote: values[level].pedagogicalNote.trim(),
      }));
      return skillsApi.replaceReferences(promptId, { references });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["adminSkills"] });
      queryClient.invalidateQueries({ queryKey: ["adminSkillPrompts"] });
      toast.show("Références remplacées", "success");
      onClose();
    },
    onError: (err) => toast.show((err as Error).message, "error"),
  });

  return (
    <Modal
      open={open}
      onClose={onClose}
      title="Références comparatives"
      eyebrow={`${promptCode} · ${promptTitle}`}
      size="lg"
      footer={
        <>
          <Button variant="ghost" onClick={onClose} disabled={mutation.isPending}>
            Annuler
          </Button>
          <Button
            variant="red"
            type="submit"
            form="skill-references-form"
            disabled={mutation.isPending || promptQuery.isLoading}
          >
            {mutation.isPending ? "Enregistrement..." : "Remplacer les 3 références"}
          </Button>
        </>
      }
    >
      {promptQuery.isLoading ? (
        <Spinner label="Chargement des références..." />
      ) : (
        <form
          id="skill-references-form"
          onSubmit={handleSubmit((v) => mutation.mutate(v))}
        >
          <p className={styles.intro}>
            Les trois niveaux partent ensemble : le serveur remplace le jeu complet.
            Elles montrent la cible, elles n&apos;imposent pas un modèle unique, et
            n&apos;apparaissent au candidat qu&apos;après sa production.
          </p>

          <div className={styles.grid}>
            {REFERENCE_LEVELS.map((level) => (
              <section key={level} className={`${styles.card} ${styles[level]}`}>
                <header className={styles.cardHeader}>
                  <span className={styles.cardLevel}>{REFERENCE_LABEL[level]}</span>
                  <code className={styles.cardCode}>{level}</code>
                </header>
                <p className={styles.cardHelp}>{REFERENCE_HELP[level]}</p>

                <label className={styles.fieldLabel} htmlFor={`ref-text-${level}`}>
                  Production de référence
                </label>
                <Textarea
                  id={`ref-text-${level}`}
                  rows={6}
                  {...register(`${level}.text` as const, {
                    required: "Texte requis",
                    validate: (v) => v.trim().length > 0 || "Texte requis",
                  })}
                />
                {errors[level]?.text && (
                  <div className={styles.fieldError}>{errors[level]?.text?.message}</div>
                )}

                <label className={styles.fieldLabel} htmlFor={`ref-note-${level}`}>
                  Note pédagogique
                </label>
                <Textarea
                  id={`ref-note-${level}`}
                  rows={3}
                  placeholder="Très court : pourquoi ce niveau, au regard du critère unique."
                  {...register(`${level}.pedagogicalNote` as const, {
                    required: "Note pédagogique requise",
                    validate: (v) => v.trim().length > 0 || "Note pédagogique requise",
                  })}
                />
                {errors[level]?.pedagogicalNote && (
                  <div className={styles.fieldError}>
                    {errors[level]?.pedagogicalNote?.message}
                  </div>
                )}
              </section>
            ))}
          </div>
        </form>
      )}
    </Modal>
  );
}
