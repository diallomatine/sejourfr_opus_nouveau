import { useEffect, useState } from "react";
import { useFieldArray, useForm, useWatch } from "react-hook-form";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { questionsApi } from "../../api/questionsApi";
import { themesApi } from "../../api/themesApi";
import { HttpError } from "../../api/http";
import { Button } from "../../components/ui/Button";
import { FormRow, Input, Select, Textarea } from "../../components/ui/Form";
import { MediaPicker } from "../../components/ui/MediaPicker";
import { Modal } from "../../components/ui/Modal";
import { PassagePicker } from "../../components/ui/PassagePicker";
import { useToast } from "../../components/ui/Toast";
import type {
  ChoiceWriteRequest,
  Difficulty,
  MediaType,
  Module,
  QuestionDto,
  QuestionType,
  QuestionWriteRequest,
} from "../../types/api";
import {
  QUESTION_TYPE_LABELS,
  levelsForModule,
  typesForModule,
} from "./questionHelpers";
import styles from "./QuestionFormModal.module.css";

interface Props {
  open: boolean;
  onClose: () => void;
  module: Module;
  question: QuestionDto | null;
}

interface FormValues {
  themeId: string;
  difficulty: Difficulty;
  questionType: QuestionType;
  statement: string;
  explanation: string;
  active: boolean;
  mediaId: string | null;
  passageId: string | null;
  choices: ChoiceWriteRequest[];
}

function emptyChoices(): ChoiceWriteRequest[] {
  return [
    { label: "", correct: false, displayOrder: 0 },
    { label: "", correct: false, displayOrder: 1 },
    { label: "", correct: false, displayOrder: 2 },
    { label: "", correct: false, displayOrder: 3 },
  ];
}

export function QuestionFormModal({ open, onClose, module, question }: Props) {
  const toast = useToast();
  const queryClient = useQueryClient();
  const [globalError, setGlobalError] = useState<string | null>(null);
  const [initialMediaSnapshot, setInitialMediaSnapshot] = useState<{
    id: string;
    url: string;
    type: MediaType;
  } | null>(null);
  const [mediaPanelOpen, setMediaPanelOpen] = useState(false);
  const [passagePanelOpen, setPassagePanelOpen] = useState(false);

  const supportsMedia = module === "TCF";
  const supportsPassage = module === "TCF";

  const themesQuery = useQuery({
    queryKey: ["themes", module],
    queryFn: () => themesApi.list(module),
    enabled: open,
  });

  const levels = levelsForModule(module);
  const types = typesForModule(module);

  const {
    control,
    register,
    handleSubmit,
    reset,
    setValue,
    getValues,
    formState: { errors },
  } = useForm<FormValues>({
    defaultValues: {
      themeId: "",
      difficulty: levels[0],
      questionType: types[0],
      statement: "",
      explanation: "",
      active: true,
      mediaId: null,
      passageId: null,
      choices: emptyChoices(),
    },
  });

  const { fields, append, remove } = useFieldArray({ control, name: "choices" });
  const watchedChoices = useWatch({ control, name: "choices" }) ?? [];
  const watchedMediaId = useWatch({ control, name: "mediaId" });
  const watchedPassageId = useWatch({ control, name: "passageId" });
  const watchedThemeId = useWatch({ control, name: "themeId" });

  const markCorrect = (idx: number) => {
    fields.forEach((_, i) => {
      setValue(`choices.${i}.correct`, i === idx, { shouldDirty: true });
    });
  };

  useEffect(() => {
    if (!open) return;
    setGlobalError(null);
    if (question) {
      reset({
        themeId: question.themeId,
        difficulty: question.difficulty,
        questionType: question.questionType,
        statement: question.statement,
        explanation: question.explanation ?? "",
        active: question.active,
        mediaId: question.mediaId,
        passageId: question.passageId,
        choices: question.choices.map((c) => ({
          label: c.label,
          correct: c.correct,
          displayOrder: c.displayOrder,
        })),
      });
      if (question.mediaId && question.mediaUrl && question.mediaType) {
        setInitialMediaSnapshot({
          id: question.mediaId,
          url: question.mediaUrl,
          type: question.mediaType,
        });
        setMediaPanelOpen(true);
      } else {
        setInitialMediaSnapshot(null);
        setMediaPanelOpen(false);
      }
      setPassagePanelOpen(Boolean(question.passageId));
    } else {
      reset({
        themeId: "",
        difficulty: levels[0],
        questionType: types[0],
        statement: "",
        explanation: "",
        active: true,
        mediaId: null,
        passageId: null,
        choices: emptyChoices(),
      });
      setInitialMediaSnapshot(null);
      setMediaPanelOpen(true);
      setPassagePanelOpen(false);
    }
  }, [open, question, reset, levels, types]);

  const firstThemeId = themesQuery.data?.[0]?.id ?? "";

  useEffect(() => {
    if (!open || question || !firstThemeId) return;
    if (getValues("themeId")) return;
    setValue("themeId", firstThemeId);
  }, [open, question, firstThemeId, getValues, setValue]);

  const mutation = useMutation({
    mutationFn: async (values: FormValues) => {
      const payload: QuestionWriteRequest = {
        module,
        themeId: values.themeId,
        mediaId: values.mediaId ?? undefined,
        passageId: values.passageId ?? undefined,
        difficulty: values.difficulty,
        questionType: values.questionType,
        statement: values.statement,
        explanation: values.explanation || undefined,
        active: values.active,
        choices: values.choices.map((c, idx) => ({
          label: c.label,
          correct: c.correct,
          displayOrder: idx,
        })),
      };
      return question
        ? questionsApi.update(question.id, payload)
        : questionsApi.create(payload);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["questions"] });
      queryClient.invalidateQueries({ queryKey: ["themes"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard"] });
      toast.show(
        question ? "Question mise à jour" : "Question créée",
        "success",
      );
      onClose();
    },
    onError: (err) => {
      if (err instanceof HttpError) {
        setGlobalError(err.payload?.message ?? err.message);
      } else if (err instanceof Error) {
        setGlobalError(err.message);
      } else {
        setGlobalError("Erreur inconnue");
      }
    },
  });

  const onSubmit = (values: FormValues) => {
    setGlobalError(null);
    const correctCount = values.choices.filter((c) => c.correct).length;
    if (correctCount !== 1) {
      setGlobalError("Vous devez désigner exactement un choix correct.");
      return;
    }
    mutation.mutate(values);
  };

  const snapshotMatches =
    initialMediaSnapshot && initialMediaSnapshot.id === watchedMediaId;

  return (
    <Modal
      open={open}
      onClose={onClose}
      title={question ? "Modifier la question" : "Nouvelle question"}
      eyebrow={module === "CIVIQUE" ? "Module civique" : "Module TCF"}
      size="lg"
      footer={
        <>
          <Button
            variant="ghost"
            type="button"
            onClick={onClose}
            disabled={mutation.isPending}
          >
            Annuler
          </Button>
          <Button
            variant="red"
            type="submit"
            form="question-form"
            disabled={mutation.isPending}
          >
            {mutation.isPending
              ? "Enregistrement..."
              : question
                ? "Enregistrer"
                : "Créer"}
          </Button>
        </>
      }
    >
      <form id="question-form" onSubmit={handleSubmit(onSubmit)}>
        <FormRow twoCol>
          <FormRow label="Thématique" htmlFor="themeId" error={errors.themeId?.message}>
            <Select
              id="themeId"
              {...register("themeId", { required: "Thématique requise" })}
            >
              <option value="">— Choisir —</option>
              {themesQuery.data?.map((t) => (
                <option key={t.id} value={t.id}>
                  {t.name}
                </option>
              ))}
            </Select>
          </FormRow>

          <FormRow
            label={module === "CIVIQUE" ? "Mention" : "Niveau"}
            htmlFor="difficulty"
          >
            <Select id="difficulty" {...register("difficulty")}>
              {levels.map((l) => (
                <option key={l} value={l}>
                  {l}
                </option>
              ))}
            </Select>
          </FormRow>
        </FormRow>

        <FormRow twoCol>
          <FormRow label="Type" htmlFor="questionType">
            <Select id="questionType" {...register("questionType")}>
              {types.map((t) => (
                <option key={t} value={t}>
                  {QUESTION_TYPE_LABELS[t]}
                </option>
              ))}
            </Select>
          </FormRow>

          <FormRow label="Statut">
            <label className={styles.checkboxLabel}>
              <input type="checkbox" {...register("active")} />
              <span>Question active (visible côté utilisateur)</span>
            </label>
          </FormRow>
        </FormRow>

        <FormRow label="Énoncé" htmlFor="statement" error={errors.statement?.message}>
          <Textarea
            id="statement"
            rows={3}
            {...register("statement", { required: "L'énoncé est requis" })}
          />
        </FormRow>

        {supportsPassage && passagePanelOpen && (
          <FormRow label="Passage rattaché (CE / CO partagé entre plusieurs questions)">
            <PassagePicker
              value={watchedPassageId ?? null}
              themeId={watchedThemeId || null}
              onChange={(id) =>
                setValue("passageId", id, { shouldDirty: true })
              }
            />
          </FormRow>
        )}

        {supportsPassage && !passagePanelOpen && (
          <FormRow>
            <button
              type="button"
              className={styles.attachBtn}
              onClick={() => setPassagePanelOpen(true)}
            >
              + Rattacher cette question à un passage (CE / CO)
            </button>
          </FormRow>
        )}

        {supportsMedia && mediaPanelOpen && (
          <FormRow label="Média associé (audio, image ou vidéo)">
            <MediaPicker
              value={watchedMediaId ?? null}
              initialType={snapshotMatches ? initialMediaSnapshot?.type : null}
              initialUrl={snapshotMatches ? initialMediaSnapshot?.url : null}
              onChange={(id) =>
                setValue("mediaId", id, { shouldDirty: true })
              }
            />
          </FormRow>
        )}

        {supportsMedia && !mediaPanelOpen && (
          <FormRow>
            <button
              type="button"
              className={styles.attachBtn}
              onClick={() => setMediaPanelOpen(true)}
            >
              + Ajouter un média (audio, image, vidéo)
            </button>
          </FormRow>
        )}

        <FormRow
          label="Choix de réponse (un seul correct)"
          error={errors.choices?.find?.((c) => c?.label)?.label?.message}
        >
          <div className={styles.choices}>
            {fields.map((field, idx) => (
              <div key={field.id} className={styles.choiceRow}>
                <label className={styles.choiceCheck}>
                  <input
                    type="radio"
                    name="correctChoice"
                    checked={Boolean(watchedChoices[idx]?.correct)}
                    onChange={() => markCorrect(idx)}
                  />
                  <span className={styles.checkLabel}>Correct</span>
                </label>
                <Input
                  placeholder={`Choix ${idx + 1}`}
                  {...register(`choices.${idx}.label` as const, {
                    required: "Libellé requis",
                  })}
                />
                {fields.length > 2 && (
                  <button
                    type="button"
                    className={styles.removeBtn}
                    onClick={() => remove(idx)}
                    aria-label="Supprimer"
                  >
                    ×
                  </button>
                )}
              </div>
            ))}
            {fields.length < 6 && (
              <button
                type="button"
                className={styles.addBtn}
                onClick={() =>
                  append({ label: "", correct: false, displayOrder: fields.length })
                }
              >
                + Ajouter un choix
              </button>
            )}
          </div>
        </FormRow>

        <FormRow
          label="Explication (visible après réponse)"
          htmlFor="explanation"
          error={errors.explanation?.message}
        >
          <Textarea
            id="explanation"
            rows={2}
            {...register("explanation", { required: "L'explication est requise" })}
          />
        </FormRow>

        {globalError && <div className={styles.globalError}>{globalError}</div>}
      </form>
    </Modal>
  );
}
