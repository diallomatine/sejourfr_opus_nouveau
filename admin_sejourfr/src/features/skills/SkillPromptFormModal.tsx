import { useEffect, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useFieldArray, useForm } from "react-hook-form";
import { skillsApi } from "../../api/skillsApi";
import { Button } from "../../components/ui/Button";
import { FormRow, Input, Select, Textarea } from "../../components/ui/Form";
import { Modal } from "../../components/ui/Modal";
import { Spinner } from "../../components/ui/Spinner";
import { useToast } from "../../components/ui/Toast";
import type {
  AdminSkillPromptCreateRequest,
  SkillConstraintIcon,
  SkillConstraintTagInput,
  SkillDifficultyLevel,
  SkillSection,
} from "../../types/api";
import { ConstraintIcon } from "./ConstraintIcon";
import {
  ANSWER_STARTER_MAX_WORDS,
  ANSWER_STARTER_MIN_WORDS,
  CHECKLIST_ITEM_MAX_WORDS,
  CHECKLIST_MAX,
  CHECKLIST_MIN,
  CONSTRAINT_ICONS,
  CONSTRAINT_ICON_HELP,
  CONSTRAINT_ICON_LABEL,
  CONSTRAINT_LABEL_MAX_WORDS,
  CONSTRAINT_TAGS_MAX,
  CONSTRAINT_TAGS_MIN,
  DIFFICULTY_LABEL,
  DIFFICULTY_LEVELS,
  SECTION_LABEL,
  TIP_MAX_WORDS,
  countWords,
  normalizeAnswerStarter,
  startsWithAstucePrefix,
} from "./skillHelpers";
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
  /**
   * Guidage de l'écran de saisie. La check-list passe par un tableau d'objets :
   * `useFieldArray` a besoin d'une clé stable par ligne, et un `string[]` brut
   * remonterait le focus à chaque frappe.
   */
  checklist: { value: string }[];
  constraintTags: { label: string; icon: SkillConstraintIcon }[];
  answerStarter: string;
  tip: string;
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
    checklist: [],
    constraintTags: [],
    answerStarter: "",
    tip: "",
  };
}

/**
 * Règles de comptage que le serveur applique (2 à 4 gestes, 1 à 3 étiquettes) —
 * elles sont transversales aux lignes, donc hors de portée d'un `validate` de
 * champ. On les vérifie ici pour rendre le 422 improbable, avec le même
 * vocabulaire que le message serveur.
 */
function guidanceCountError(values: PromptFormValues): string | null {
  const actions = values.checklist.filter((item) => item.value.trim().length > 0);
  if (actions.length > 0 && (actions.length < CHECKLIST_MIN || actions.length > CHECKLIST_MAX)) {
    return `La check-list doit compter entre ${CHECKLIST_MIN} et ${CHECKLIST_MAX} gestes (${actions.length} pour l'instant). Videz-la entièrement pour publier le sujet sans check-list.`;
  }
  const tags = values.constraintTags.filter((tag) => tag.label.trim().length > 0);
  if (tags.length > CONSTRAINT_TAGS_MAX) {
    return `Les étiquettes de contrainte sont ${CONSTRAINT_TAGS_MIN} à ${CONSTRAINT_TAGS_MAX} (${tags.length} pour l'instant).`;
  }
  return null;
}

/** Une étiquette qui redit la longueur ou la durée finit par diverger des bornes. */
function mentionsLengthOrDuration(label: string): boolean {
  return (
    /\d/.test(label) ||
    /\b(mots?|secondes?|sec|minutes?|min)\b/i.test(label)
  );
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
  const [guidanceError, setGuidanceError] = useState<string | null>(null);

  const promptQuery = useQuery({
    queryKey: ["adminSkillPrompts", "detail", promptId],
    queryFn: () => skillsApi.getPrompt(promptId as string),
    enabled: open && promptId !== null,
  });

  const {
    control,
    register,
    handleSubmit,
    reset,
    setValue,
    watch,
    formState: { errors },
  } = useForm<PromptFormValues>({ defaultValues: defaults(section, suggestedOrder) });

  const checklistArray = useFieldArray({ control, name: "checklist" });
  const tagsArray = useFieldArray({ control, name: "constraintTags" });

  const checklistValues = watch("checklist");
  const tagValues = watch("constraintTags");
  const answerStarterValue = watch("answerStarter");
  const tipValue = watch("tip");

  useEffect(() => {
    if (!open) return;
    setGuidanceError(null);
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
      checklist: (prompt.checklist ?? []).map((value) => ({ value })),
      constraintTags: (prompt.constraintTags ?? []).map((tag) => ({
        label: tag.label,
        icon: tag.icon,
      })),
      answerStarter: prompt.answerStarter ?? "",
      tip: prompt.tip ?? "",
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

      // Les quatre champs de guidage ont une sémantique de REMPLACEMENT : un
      // `null` efface. On envoie donc `null` — et non une liste vide ou une
      // chaîne vide — dès qu'un champ a été vidé, c'est la seule façon de
      // retirer un guidage posé par erreur.
      const checklist = values.checklist
        .map((item) => item.value.trim())
        .filter((item) => item.length > 0);
      const constraintTags: SkillConstraintTagInput[] = values.constraintTags
        .filter((tag) => tag.label.trim().length > 0)
        .map((tag) => ({ label: tag.label.trim(), icon: tag.icon }));
      const answerStarter = normalizeAnswerStarter(values.answerStarter);
      const tip = values.tip.trim();

      const common = {
        title: values.title.trim(),
        context: values.context.trim(),
        instruction: values.instruction.trim(),
        uniqueCriterion: values.uniqueCriterion.trim(),
        checklist: checklist.length > 0 ? checklist : null,
        constraintTags: constraintTags.length > 0 ? constraintTags : null,
        answerStarter: answerStarter.length > 0 ? answerStarter : null,
        tip: tip.length > 0 ? tip : null,
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

  const submit = (values: PromptFormValues) => {
    const countError = guidanceCountError(values);
    setGuidanceError(countError);
    if (countError) {
      toast.show(countError, "error");
      return;
    }
    mutation.mutate(values);
  };

  const loading = isEdit && promptQuery.isLoading;

  const filledActions = checklistValues.filter((i) => i.value.trim().length > 0).length;
  const filledTags = tagValues.filter((t) => t.label.trim().length > 0).length;
  const starterWords = countWords(answerStarterValue);
  const tipWords = countWords(tipValue);
  const guidanceFilled =
    (filledActions > 0 ? 1 : 0) +
    (filledTags > 0 ? 1 : 0) +
    (answerStarterValue.trim().length > 0 ? 1 : 0) +
    (tipValue.trim().length > 0 ? 1 : 0);

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
        <form id="skill-prompt-form" onSubmit={handleSubmit(submit)}>
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
              niveau visé. Elle s&apos;affiche telle quelle dans la carte
              «&nbsp;Situation&nbsp;» de l&apos;écran de saisie.
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
              unique attendue, jamais un piège grammatical. C&apos;est aussi le
              repli des fronts quand la check-list est absente.
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

          {/* ===== Guidage de l'écran de saisie ===== */}
          <div className={styles.guidanceBlock}>
            <div className={styles.guidanceHeader}>
              <div>
                <div className={styles.guidanceEyebrow}>Guidage de l&apos;écran de saisie</div>
                <h4 className={styles.guidanceTitle}>
                  Ce que le candidat voit avant d&apos;écrire
                </h4>
              </div>
              <span
                className={`${styles.guidanceBadge} ${
                  guidanceFilled === 4
                    ? styles.badgeComplete
                    : guidanceFilled === 0
                      ? styles.badgeAbsent
                      : styles.badgePartial
                }`}
              >
                {guidanceFilled === 4
                  ? "Guidage complet"
                  : guidanceFilled === 0
                    ? "Sans guidage — sujet incomplet"
                    : `Guidage partiel · ${guidanceFilled} / 4`}
              </span>
            </div>
            <p className={styles.guidanceIntro}>
              Ces quatre champs <strong>font faire</strong> l&apos;exercice là où le
              critère se contente de le décrire. Ils sont facultatifs — un sujet
              sans guidage reste publiable, les fronts retombent alors sur la
              consigne — mais il est <strong>incomplet</strong>. À
              l&apos;enregistrement, <strong>un champ vidé efface la valeur</strong>&nbsp;:
              c&apos;est ainsi qu&apos;on retire un guidage posé par erreur.
            </p>

            {/* --- Check-list --- */}
            <section className={styles.guidanceSection}>
              <div className={styles.sectionHead}>
                <h5 className={styles.sectionTitle}>Ce qu&apos;il faut faire</h5>
                <span className={styles.counter}>
                  {filledActions} / {CHECKLIST_MAX} gestes
                </span>
              </div>
              <p className={styles.help}>
                {CHECKLIST_MIN} à {CHECKLIST_MAX} gestes, <strong>à
                l&apos;impératif</strong>, {CHECKLIST_ITEM_MAX_WORDS} mots maximum
                chacun, dans l&apos;ordre où le candidat doit les accomplir. Elle{" "}
                <strong>découpe la consigne, elle ne l&apos;enrichit pas</strong> :
                n&apos;y ajoutez rien que la consigne n&apos;exige. Le dernier geste
                porte souvent le format («&nbsp;Écrivez deux phrases&nbsp;»,
                «&nbsp;Terminez par une question&nbsp;»).
              </p>

              {checklistArray.fields.length === 0 ? (
                <p className={styles.emptyRow}>
                  Aucun geste : la carte «&nbsp;Ce qu&apos;il faut faire&nbsp;»
                  retombera sur la consigne.
                </p>
              ) : (
                <ul className={styles.rowList}>
                  {checklistArray.fields.map((field, index) => {
                    const words = countWords(checklistValues[index]?.value ?? "");
                    const itemError = errors.checklist?.[index]?.value?.message;
                    return (
                      <li key={field.id} className={styles.row}>
                        <span className={styles.rowIndex}>{index + 1}</span>
                        <div className={styles.rowMain}>
                          <Input
                            aria-label={`Geste ${index + 1}`}
                            placeholder="Saluez votre voisine"
                            {...register(`checklist.${index}.value` as const, {
                              validate: (value) => {
                                const clean = value.trim();
                                if (clean.length === 0)
                                  return "Un geste vide ne s'enregistre pas — retirez la ligne.";
                                if (countWords(clean) > CHECKLIST_ITEM_MAX_WORDS)
                                  return `${CHECKLIST_ITEM_MAX_WORDS} mots maximum (${countWords(clean)} actuellement).`;
                                return true;
                              },
                            })}
                          />
                          <div className={styles.rowFoot}>
                            <span
                              className={`${styles.counter} ${
                                words > CHECKLIST_ITEM_MAX_WORDS ? styles.counterOver : ""
                              }`}
                            >
                              {words} / {CHECKLIST_ITEM_MAX_WORDS} mots
                            </span>
                            {itemError && (
                              <span className={styles.rowError}>{itemError}</span>
                            )}
                          </div>
                        </div>
                        <div className={styles.rowActions}>
                          <button
                            type="button"
                            className={styles.iconBtn}
                            title="Monter"
                            aria-label={`Monter le geste ${index + 1}`}
                            disabled={index === 0}
                            onClick={() => checklistArray.move(index, index - 1)}
                          >
                            ↑
                          </button>
                          <button
                            type="button"
                            className={styles.iconBtn}
                            title="Descendre"
                            aria-label={`Descendre le geste ${index + 1}`}
                            disabled={index === checklistArray.fields.length - 1}
                            onClick={() => checklistArray.move(index, index + 1)}
                          >
                            ↓
                          </button>
                          <button
                            type="button"
                            className={`${styles.iconBtn} ${styles.iconBtnDanger}`}
                            title="Retirer"
                            aria-label={`Retirer le geste ${index + 1}`}
                            onClick={() => checklistArray.remove(index)}
                          >
                            ✕
                          </button>
                        </div>
                      </li>
                    );
                  })}
                </ul>
              )}

              <button
                type="button"
                className={styles.addBtn}
                disabled={checklistArray.fields.length >= CHECKLIST_MAX}
                onClick={() => checklistArray.append({ value: "" })}
              >
                + Ajouter un geste
              </button>
              {checklistArray.fields.length >= CHECKLIST_MAX && (
                <span className={styles.addHint}>
                  {CHECKLIST_MAX} gestes : au-delà, la carte ne tient plus au-dessus
                  du champ sur un téléphone.
                </span>
              )}
            </section>

            {/* --- Étiquettes de contrainte --- */}
            <section className={styles.guidanceSection}>
              <div className={styles.sectionHead}>
                <h5 className={styles.sectionTitle}>Étiquettes de contrainte</h5>
                <span className={styles.counter}>
                  {filledTags} / {CONSTRAINT_TAGS_MAX} étiquettes
                </span>
              </div>
              <p className={styles.help}>
                {CONSTRAINT_TAGS_MIN} à {CONSTRAINT_TAGS_MAX} étiquettes de{" "}
                {CONSTRAINT_LABEL_MAX_WORDS} mots maximum, qui disent{" "}
                <strong>comment</strong> produire, jamais <strong>quoi</strong> :
                «&nbsp;Vouvoiement&nbsp;», «&nbsp;Ton poli&nbsp;»,
                «&nbsp;Passé composé&nbsp;», «&nbsp;Un exemple concret&nbsp;».
              </p>
              <p className={styles.warn}>
                ⚠ N&apos;y mettez <strong>jamais la longueur ni la durée</strong>{" "}
                («&nbsp;15 à 35 mots&nbsp;», «&nbsp;30 secondes&nbsp;») : les fronts
                rendent déjà cette puce depuis les bornes du sujet. La saisir ici,
                c&apos;est se garantir de la voir diverger.
              </p>

              {tagsArray.fields.length === 0 ? (
                <p className={styles.emptyRow}>
                  Aucune étiquette : le candidat ne verra que la puce de{" "}
                  {section === "EE" ? "longueur" : "durée"}.
                </p>
              ) : (
                <ul className={styles.rowList}>
                  {tagsArray.fields.map((field, index) => {
                    const label = tagValues[index]?.label ?? "";
                    const icon = tagValues[index]?.icon ?? "TONE";
                    const words = countWords(label);
                    const labelError = errors.constraintTags?.[index]?.label?.message;
                    return (
                      <li key={field.id} className={styles.tagRow}>
                        <div className={styles.tagMain}>
                          <div className={styles.tagLabelLine}>
                            <Input
                              aria-label={`Libellé de l'étiquette ${index + 1}`}
                              placeholder="Vouvoiement"
                              {...register(`constraintTags.${index}.label` as const, {
                                validate: (value) => {
                                  const clean = value.trim();
                                  if (clean.length === 0)
                                    return "Une étiquette sans libellé ne s'enregistre pas — retirez la ligne.";
                                  if (countWords(clean) > CONSTRAINT_LABEL_MAX_WORDS)
                                    return `${CONSTRAINT_LABEL_MAX_WORDS} mots maximum (${countWords(clean)} actuellement).`;
                                  if (mentionsLengthOrDuration(clean))
                                    return "Ni longueur ni durée dans une étiquette : les fronts les rendent depuis les bornes du sujet.";
                                  return true;
                                },
                              })}
                            />
                            <span
                              className={`${styles.counter} ${
                                words > CONSTRAINT_LABEL_MAX_WORDS ? styles.counterOver : ""
                              }`}
                            >
                              {words} / {CONSTRAINT_LABEL_MAX_WORDS} mots
                            </span>
                          </div>

                          <div className={styles.iconPicker} role="group" aria-label="Icône">
                            {/*
                              L'icône se choisit au clic, mais le champ reste
                              enregistré : sans lui, une valeur posée par
                              `setValue` seul pourrait ne pas atteindre la
                              charge utile, et le serveur refuserait une
                              étiquette sans icône.
                            */}
                            <input
                              type="hidden"
                              {...register(`constraintTags.${index}.icon` as const)}
                            />
                            {CONSTRAINT_ICONS.map((candidate) => (
                              <button
                                key={candidate}
                                type="button"
                                className={`${styles.iconChoice} ${
                                  icon === candidate ? styles.iconChoiceOn : ""
                                }`}
                                aria-pressed={icon === candidate}
                                title={`${CONSTRAINT_ICON_LABEL[candidate]} — ${CONSTRAINT_ICON_HELP[candidate]}`}
                                onClick={() =>
                                  setValue(`constraintTags.${index}.icon`, candidate, {
                                    shouldDirty: true,
                                  })
                                }
                              >
                                <ConstraintIcon icon={candidate} />
                                <span>{CONSTRAINT_ICON_LABEL[candidate]}</span>
                              </button>
                            ))}
                          </div>

                          <div className={styles.rowFoot}>
                            <span className={styles.previewChip}>
                              <ConstraintIcon icon={icon} size={14} />
                              {label.trim() || "Aperçu de la puce"}
                            </span>
                            <span className={styles.iconHint}>
                              {CONSTRAINT_ICON_LABEL[icon]} · {CONSTRAINT_ICON_HELP[icon]}
                            </span>
                          </div>
                          {labelError && (
                            <div className={styles.rowError}>{labelError}</div>
                          )}
                        </div>
                        <div className={styles.rowActions}>
                          <button
                            type="button"
                            className={styles.iconBtn}
                            title="Monter"
                            aria-label={`Monter l'étiquette ${index + 1}`}
                            disabled={index === 0}
                            onClick={() => tagsArray.move(index, index - 1)}
                          >
                            ↑
                          </button>
                          <button
                            type="button"
                            className={styles.iconBtn}
                            title="Descendre"
                            aria-label={`Descendre l'étiquette ${index + 1}`}
                            disabled={index === tagsArray.fields.length - 1}
                            onClick={() => tagsArray.move(index, index + 1)}
                          >
                            ↓
                          </button>
                          <button
                            type="button"
                            className={`${styles.iconBtn} ${styles.iconBtnDanger}`}
                            title="Retirer"
                            aria-label={`Retirer l'étiquette ${index + 1}`}
                            onClick={() => tagsArray.remove(index)}
                          >
                            ✕
                          </button>
                        </div>
                      </li>
                    );
                  })}
                </ul>
              )}

              <button
                type="button"
                className={styles.addBtn}
                disabled={tagsArray.fields.length >= CONSTRAINT_TAGS_MAX}
                onClick={() => tagsArray.append({ label: "", icon: "TONE" })}
              >
                + Ajouter une étiquette
              </button>
              {tagsArray.fields.length >= CONSTRAINT_TAGS_MAX && (
                <span className={styles.addHint}>
                  {CONSTRAINT_TAGS_MAX} étiquettes : au-delà, la rangée déborde de
                  l&apos;écran.
                </span>
              )}
            </section>

            {/* --- Amorce --- */}
            <section className={styles.guidanceSection}>
              <div className={styles.sectionHead}>
                <h5 className={styles.sectionTitle}>Amorce de réponse</h5>
                <span
                  className={`${styles.counter} ${
                    answerStarterValue.trim().length > 0 &&
                    (starterWords < ANSWER_STARTER_MIN_WORDS ||
                      starterWords > ANSWER_STARTER_MAX_WORDS)
                      ? styles.counterWarn
                      : ""
                  }`}
                >
                  {starterWords} mots · visez {ANSWER_STARTER_MIN_WORDS} à{" "}
                  {ANSWER_STARTER_MAX_WORDS}
                </span>
              </div>
              <Input
                id="prompt-answer-starter"
                placeholder="Bonjour Madame, je suis votre voisin du…"
                {...register("answerStarter", {
                  validate: (value) => {
                    const clean = normalizeAnswerStarter(value);
                    if (clean.length === 0) return true;
                    if (!clean.endsWith("…"))
                      return "L'amorce doit se terminer par « … » — c'est ce qui la donne à lire comme un début, pas comme une réponse.";
                    return true;
                  },
                })}
              />
              {errors.answerStarter && (
                <div className={styles.rowError}>{errors.answerStarter.message}</div>
              )}
              <p className={styles.help}>
                Une seule ligne, affichée <strong>en gris dans le champ</strong> (EE)
                ou en suggestion de démarrage (EO). Les trois points saisis au
                clavier sont convertis en «&nbsp;…&nbsp;» à l&apos;enregistrement.
              </p>
              <p className={styles.warn}>
                ⚠ Elle ne doit <strong>jamais satisfaire à elle seule le critère</strong>{" "}
                du sujet : elle donne l&apos;élan, pas la réponse. Si le candidat
                n&apos;a plus qu&apos;à valider, l&apos;amorce est trop longue.
              </p>
            </section>

            {/* --- Astuce --- */}
            <section className={styles.guidanceSection}>
              <div className={styles.sectionHead}>
                <h5 className={styles.sectionTitle}>Astuce</h5>
                <span
                  className={`${styles.counter} ${
                    tipWords > TIP_MAX_WORDS ? styles.counterOver : ""
                  }`}
                >
                  {tipWords} / {TIP_MAX_WORDS} mots
                </span>
              </div>
              <Input
                id="prompt-tip"
                placeholder="commencez par bonjour, puis présentez-vous"
                {...register("tip", {
                  validate: (value) => {
                    const clean = value.trim();
                    if (clean.length === 0) return true;
                    if (countWords(clean) > TIP_MAX_WORDS)
                      return `${TIP_MAX_WORDS} mots maximum (${countWords(clean)} actuellement).`;
                    if (startsWithAstucePrefix(clean))
                      return "N'écrivez pas « Astuce : » — les fronts l'ajoutent devant votre phrase.";
                    return true;
                  },
                })}
              />
              {errors.tip && <div className={styles.rowError}>{errors.tip.message}</div>}
              <p className={styles.help}>
                Une phrase, sous la zone de production, qui rappelle{" "}
                <strong>le geste le plus souvent oublié</strong> sur ce sujet. Ton
                encourageant, jamais culpabilisant — et sans le préfixe
                «&nbsp;Astuce&nbsp;:&nbsp;», ajouté par les fronts.
              </p>
            </section>

            {guidanceError && <div className={styles.guidanceError}>{guidanceError}</div>}
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
                : "Un sujet oral se borne en secondes — les bornes en mots sont interdites en EO et ne sont donc pas proposées. Cette durée est indicative : elle ne bloque jamais le candidat."}{" "}
              C&apos;est d&apos;ici que les fronts fabriquent la puce affichée au
              candidat : ne la redites pas dans une étiquette de contrainte.
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
