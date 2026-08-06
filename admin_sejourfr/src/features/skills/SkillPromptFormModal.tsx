import { useEffect } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useForm } from "react-hook-form";
import { skillsApi } from "../../api/skillsApi";
import { Button } from "../../components/ui/Button";
import { FormRow, Input, Select, Textarea } from "../../components/ui/Form";
import { Modal } from "../../components/ui/Modal";
import { Spinner } from "../../components/ui/Spinner";
import { useToast } from "../../components/ui/Toast";
import type {
  AdminSkillPromptCreateRequest,
  SkillDifficultyLevel,
  SkillSection,
} from "../../types/api";
import { DIFFICULTY_LABEL, DIFFICULTY_LEVELS, SECTION_LABEL } from "./skillHelpers";
import styles from "./SkillPromptFormModal.module.css";

interface PromptFormValues {
  code: string;
  title: string;
  context: string;
  instruction: string;
  uniqueCriterion: string;
  difficultyLevel: SkillDifficultyLevel;
  displayOrder: number;
  active: boolean;
  /** Section EE uniquement. */
  recommendedMinWords: number;
  recommendedMaxWords: number;
  /** Section EO uniquement. */
  recommendedDurationSeconds: number;
}

function defaults(section: SkillSection, order: number): PromptFormValues {
  return {
    code: "",
    title: "",
    context: "",
    instruction: "",
    uniqueCriterion: "",
    difficultyLevel: "EASY",
    displayOrder: order,
    active: true,
    recommendedMinWords: section === "EE" ? 15 : 0,
    recommendedMaxWords: section === "EE" ? 50 : 0,
    recommendedDurationSeconds: section === "EO" ? 45 : 0,
  };
}

export function SkillPromptFormModal({
  open,
  skillId,
  skillCode,
  section,
  promptId,
  suggestedOrder,
  onClose,
}: {
  open: boolean;
  skillId: string;
  skillCode: string;
  /** Section de la compétence parente : c'est elle qui décide des bornes autorisées. */
  section: SkillSection;
  /** `null` = création. En modification, `code` est figé. */
  promptId: string | null;
  suggestedOrder: number;
  onClose: () => void;
}) {
  const toast = useToast();
  const queryClient = useQueryClient();
  const isEdit = promptId !== null;

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
  } = useForm<PromptFormValues>({ defaultValues: defaults(section, suggestedOrder) });

  useEffect(() => {
    if (!open) return;
    if (!isEdit) {
      reset(defaults(section, suggestedOrder));
      return;
    }
    const prompt = promptQuery.data;
    if (!prompt) return;
    reset({
      code: prompt.code,
      title: prompt.title,
      context: prompt.context,
      instruction: prompt.instruction,
      uniqueCriterion: prompt.uniqueCriterion,
      difficultyLevel: prompt.difficultyLevel,
      displayOrder: prompt.displayOrder,
      active: prompt.active,
      recommendedMinWords: prompt.recommendedMinWords ?? 0,
      recommendedMaxWords: prompt.recommendedMaxWords ?? 0,
      recommendedDurationSeconds: prompt.recommendedDurationSeconds ?? 0,
    });
  }, [open, isEdit, promptQuery.data, reset, section, suggestedOrder]);

  const mutation = useMutation({
    mutationFn: (values: PromptFormValues) => {
      // La base porte un CHECK : EE exige les deux bornes en mots et interdit la
      // durée, EO exige la durée et interdit les mots. On construit donc la
      // charge utile depuis la section, jamais depuis ce que le formulaire a
      // pu conserver d'un état précédent.
      const bounds =
        section === "EE"
          ? {
              recommendedMinWords: values.recommendedMinWords,
              recommendedMaxWords: values.recommendedMaxWords,
              recommendedDurationSeconds: null,
            }
          : {
              recommendedMinWords: null,
              recommendedMaxWords: null,
              recommendedDurationSeconds: values.recommendedDurationSeconds,
            };

      const common = {
        title: values.title.trim(),
        context: values.context.trim(),
        instruction: values.instruction.trim(),
        uniqueCriterion: values.uniqueCriterion.trim(),
        difficultyLevel: values.difficultyLevel,
        displayOrder: values.displayOrder,
        active: values.active,
        ...bounds,
      };

      if (promptId) return skillsApi.updatePrompt(promptId, common);

      const created: AdminSkillPromptCreateRequest = {
        skillId,
        code: values.code.trim().toUpperCase(),
        ...common,
      };
      return skillsApi.createPrompt(created);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["adminSkills"] });
      queryClient.invalidateQueries({ queryKey: ["adminSkillPrompts"] });
      toast.show(isEdit ? "Sujet mis à jour" : "Sujet créé", "success");
      onClose();
    },
    onError: (err) => toast.show((err as Error).message, "error"),
  });

  const loading = isEdit && promptQuery.isLoading;

  return (
    <Modal
      open={open}
      onClose={onClose}
      title={isEdit ? "Modifier le petit sujet" : "Nouveau petit sujet"}
      eyebrow={`${skillCode} · ${SECTION_LABEL[section]}`}
      size="lg"
      footer={
        <>
          <Button variant="ghost" onClick={onClose} disabled={mutation.isPending}>
            Annuler
          </Button>
          <Button
            variant="red"
            type="submit"
            form="skill-prompt-form"
            disabled={mutation.isPending || loading}
          >
            {mutation.isPending ? "Enregistrement..." : "Enregistrer"}
          </Button>
        </>
      }
    >
      {loading ? (
        <Spinner label="Chargement du sujet..." />
      ) : (
        <form
          id="skill-prompt-form"
          onSubmit={handleSubmit((v) => mutation.mutate(v))}
        >
          <FormRow
            label="Code du sujet"
            htmlFor="prompt-code"
            error={errors.code?.message}
          >
            {isEdit ? (
              <div className={styles.frozenCode}>
                <code>{promptQuery.data?.code ?? "—"}</code>
                <span className={styles.frozenHint}>
                  immuable — les seeds s&apos;appuient dessus
                </span>
              </div>
            ) : (
              <Input
                id="prompt-code"
                placeholder={`${skillCode}-S1`}
                {...register("code", {
                  required: "Code requis",
                  maxLength: { value: 24, message: "24 caractères maximum" },
                })}
              />
            )}
          </FormRow>

          <FormRow label="Titre" htmlFor="prompt-title" error={errors.title?.message}>
            <Input
              id="prompt-title"
              placeholder="Signaler un problème au propriétaire"
              {...register("title", {
                required: "Titre requis",
                maxLength: { value: 160, message: "160 caractères maximum" },
              })}
            />
          </FormRow>

          <FormRow
            label="Contexte"
            htmlFor="prompt-context"
            error={errors.context?.message}
          >
            <Textarea
              id="prompt-context"
              rows={3}
              placeholder="La situation dans laquelle le candidat se trouve."
              {...register("context", { required: "Contexte requis" })}
            />
            <p className={styles.help}>
              Une situation plausible au TCF, dans un vocabulaire accessible au
              niveau visé.
            </p>
          </FormRow>

          <FormRow
            label="Consigne"
            htmlFor="prompt-instruction"
            error={errors.instruction?.message}
          >
            <Textarea
              id="prompt-instruction"
              rows={3}
              placeholder="Ce que le candidat doit produire."
              {...register("instruction", { required: "Consigne requise" })}
            />
            <p className={styles.help}>
              Elle doit déclencher une production ouverte : jamais une formulation
              unique attendue, jamais un piège grammatical.
            </p>
          </FormRow>

          <div className={styles.criterionBlock}>
            <div className={styles.criterionEyebrow}>Critère unique</div>
            <h4 className={styles.criterionTitle}>Le cœur du petit sujet</h4>
            <p className={styles.criterionIntro}>
              C&apos;est la <strong>seule</strong> chose que l&apos;IA évaluera, et
              la seule annoncée au candidat avant qu&apos;il produise. Un critère,
              une compétence, une phrase — pas une liste d&apos;attentes.
            </p>
            <Textarea
              id="prompt-criterion"
              rows={3}
              className={styles.criterionInput}
              placeholder="Le message emploie une formule de politesse adaptée à un propriétaire."
              {...register("uniqueCriterion", { required: "Critère unique requis" })}
            />
            {errors.uniqueCriterion && (
              <div className={styles.criterionError}>
                {errors.uniqueCriterion.message}
              </div>
            )}
          </div>

          <div className={styles.boundsBlock}>
            <div className={styles.boundsHeader}>
              <h4 className={styles.boundsTitle}>
                {section === "EE" ? "Longueur conseillée" : "Durée conseillée"}
              </h4>
              <span className={styles.boundsBadge}>{SECTION_LABEL[section]}</span>
            </div>
            <p className={styles.help}>
              {section === "EE"
                ? "Un sujet écrit se borne en mots — la durée est interdite en EE et n'est donc pas proposée. Ces bornes sont indicatives : elles ne bloquent jamais le candidat."
                : "Un sujet oral se borne en secondes — les bornes en mots sont interdites en EO et ne sont donc pas proposées. Cette durée est indicative : elle ne bloque jamais le candidat."}
            </p>

            {section === "EE" ? (
              <FormRow twoCol>
                <FormRow
                  label="Minimum (mots)"
                  htmlFor="prompt-min-words"
                  error={errors.recommendedMinWords?.message}
                >
                  <Input
                    id="prompt-min-words"
                    type="number"
                    min={1}
                    {...register("recommendedMinWords", {
                      valueAsNumber: true,
                      validate: (v) =>
                        (Number.isInteger(v) && v >= 1) ||
                        "Minimum requis (entier ≥ 1)",
                    })}
                  />
                </FormRow>
                <FormRow
                  label="Maximum (mots)"
                  htmlFor="prompt-max-words"
                  error={errors.recommendedMaxWords?.message}
                >
                  <Input
                    id="prompt-max-words"
                    type="number"
                    min={2}
                    {...register("recommendedMaxWords", {
                      valueAsNumber: true,
                      validate: (v, values) => {
                        if (!Number.isInteger(v) || v < 1)
                          return "Maximum requis (entier ≥ 1)";
                        if (v <= values.recommendedMinWords)
                          return "Le maximum doit être strictement supérieur au minimum";
                        return true;
                      },
                    })}
                  />
                </FormRow>
              </FormRow>
            ) : (
              <FormRow
                label="Durée (secondes)"
                htmlFor="prompt-duration"
                error={errors.recommendedDurationSeconds?.message}
              >
                <Input
                  id="prompt-duration"
                  type="number"
                  min={10}
                  max={180}
                  {...register("recommendedDurationSeconds", {
                    valueAsNumber: true,
                    validate: (v) =>
                      (Number.isInteger(v) && v >= 10 && v <= 180) ||
                      "Entre 10 et 180 secondes (plafond d'enregistrement du candidat)",
                  })}
                />
              </FormRow>
            )}
          </div>

          <FormRow twoCol>
            <FormRow
              label="Difficulté"
              htmlFor="prompt-difficulty"
              error={errors.difficultyLevel?.message}
            >
              <Select
                id="prompt-difficulty"
                {...register("difficultyLevel", { required: "Difficulté requise" })}
              >
                {DIFFICULTY_LEVELS.map((level) => (
                  <option key={level} value={level}>
                    {DIFFICULTY_LABEL[level]}
                  </option>
                ))}
              </Select>
            </FormRow>

            <FormRow
              label="Rang d'affichage (1 à 20)"
              htmlFor="prompt-order"
              error={errors.displayOrder?.message}
            >
              <Input
                id="prompt-order"
                type="number"
                min={1}
                max={20}
                {...register("displayOrder", {
                  valueAsNumber: true,
                  validate: (v) =>
                    (Number.isInteger(v) && v >= 1 && v <= 20) ||
                    "Un entier entre 1 et 20, unique dans la compétence",
                })}
              />
            </FormRow>
          </FormRow>

          <FormRow>
            <label className={styles.checkboxRow}>
              <input type="checkbox" {...register("active")} />
              <span>Sujet actif (proposé aux candidats)</span>
            </label>
          </FormRow>
        </form>
      )}
    </Modal>
  );
}
