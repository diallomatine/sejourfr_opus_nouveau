import { useEffect } from "react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { useForm } from "react-hook-form";
import { skillsApi } from "../../api/skillsApi";
import { Button } from "../../components/ui/Button";
import { FormRow, Input, Select, Textarea } from "../../components/ui/Form";
import { Modal } from "../../components/ui/Modal";
import { useToast } from "../../components/ui/Toast";
import type {
  AdminSkillDto,
  SkillSection,
  SkillTargetLevel,
  SkillTaskCode,
} from "../../types/api";
import {
  SECTIONS,
  SECTION_LABEL,
  TARGET_LEVELS,
  TASK_TITLE,
  sectionOfTaskCode,
  taskCodesForSection,
} from "./skillHelpers";
import styles from "./SkillFormModal.module.css";

interface SkillFormValues {
  taskCode: SkillTaskCode;
  code: string;
  title: string;
  description: string;
  generalCriterion: string;
  targetLevel: SkillTargetLevel;
  displayOrder: number;
  active: boolean;
}

const DEFAULTS: SkillFormValues = {
  taskCode: "EE1",
  code: "",
  title: "",
  description: "",
  generalCriterion: "",
  targetLevel: "A2",
  displayOrder: 1,
  active: true,
};

export function SkillFormModal({
  open,
  skill,
  onClose,
  onCreated,
}: {
  open: boolean;
  /** `null` = création. En modification, `code`, `section` et `taskCode` sont figés. */
  skill: AdminSkillDto | null;
  onClose: () => void;
  onCreated?: (created: AdminSkillDto) => void;
}) {
  const toast = useToast();
  const queryClient = useQueryClient();
  const isEdit = skill !== null;

  const {
    register,
    handleSubmit,
    reset,
    watch,
    setValue,
    formState: { errors },
  } = useForm<SkillFormValues>({ defaultValues: DEFAULTS });

  useEffect(() => {
    if (!open) return;
    reset(
      skill
        ? {
            taskCode: skill.taskCode,
            code: skill.code,
            title: skill.title,
            description: skill.description,
            generalCriterion: skill.generalCriterion,
            targetLevel: skill.targetLevel,
            displayOrder: skill.displayOrder,
            active: skill.active,
          }
        : DEFAULTS,
    );
  }, [open, skill, reset]);

  const taskCode = watch("taskCode");
  const section: SkillSection = sectionOfTaskCode(taskCode ?? "EE1");

  const mutation = useMutation({
    mutationFn: (values: SkillFormValues) => {
      if (skill) {
        return skillsApi.update(skill.id, {
          title: values.title.trim(),
          description: values.description.trim(),
          generalCriterion: values.generalCriterion.trim(),
          targetLevel: values.targetLevel,
          displayOrder: values.displayOrder,
          active: values.active,
        });
      }
      return skillsApi.create({
        section: sectionOfTaskCode(values.taskCode),
        taskCode: values.taskCode,
        code: values.code.trim().toUpperCase(),
        title: values.title.trim(),
        description: values.description.trim(),
        generalCriterion: values.generalCriterion.trim(),
        targetLevel: values.targetLevel,
        displayOrder: values.displayOrder,
        active: values.active,
      });
    },
    onSuccess: (saved) => {
      queryClient.invalidateQueries({ queryKey: ["adminSkills"] });
      toast.show(isEdit ? "Compétence mise à jour" : "Compétence créée", "success");
      if (!isEdit && onCreated) onCreated(saved);
      else onClose();
    },
    onError: (err) => toast.show((err as Error).message, "error"),
  });

  return (
    <Modal
      open={open}
      onClose={onClose}
      title={isEdit ? `Modifier · ${skill.title}` : "Nouvelle compétence"}
      eyebrow={isEdit ? skill.code : "Contenu éditorial"}
      size="lg"
      footer={
        <>
          <Button variant="ghost" onClick={onClose} disabled={mutation.isPending}>
            Annuler
          </Button>
          <Button
            variant="red"
            type="submit"
            form="skill-form"
            disabled={mutation.isPending}
          >
            {mutation.isPending ? "Enregistrement..." : "Enregistrer"}
          </Button>
        </>
      }
    >
      <form id="skill-form" onSubmit={handleSubmit((v) => mutation.mutate(v))}>
        <FormRow twoCol>
          <FormRow label="Épreuve" htmlFor="skill-form-section">
            {isEdit ? (
              <div className={styles.frozen}>
                {SECTION_LABEL[skill.section]}
                <span className={styles.frozenHint}>non modifiable</span>
              </div>
            ) : (
              <Select
                id="skill-form-section"
                value={section}
                onChange={(e) => {
                  const next = e.target.value as SkillSection;
                  setValue("taskCode", taskCodesForSection(next)[0]);
                }}
              >
                {SECTIONS.map((s) => (
                  <option key={s} value={s}>
                    {SECTION_LABEL[s]}
                  </option>
                ))}
              </Select>
            )}
          </FormRow>

          <FormRow
            label="Tâche"
            htmlFor="skill-form-task"
            error={errors.taskCode?.message}
          >
            {isEdit ? (
              <div className={styles.frozen}>
                {skill.taskCode} · {TASK_TITLE[skill.taskCode]}
                <span className={styles.frozenHint}>non modifiable</span>
              </div>
            ) : (
              <Select
                id="skill-form-task"
                {...register("taskCode", { required: "Tâche requise" })}
              >
                {taskCodesForSection(section).map((code) => (
                  <option key={code} value={code}>
                    {code} · {TASK_TITLE[code]}
                  </option>
                ))}
              </Select>
            )}
          </FormRow>
        </FormRow>

        <FormRow
          label="Code de la compétence"
          htmlFor="skill-form-code"
          error={errors.code?.message}
        >
          {isEdit ? (
            <div className={styles.frozenCode}>
              <code>{skill.code}</code>
              <span className={styles.frozenHint}>
                immuable — les sujets et les seeds s&apos;appuient dessus
              </span>
            </div>
          ) : (
            <>
              <Input
                id="skill-form-code"
                placeholder={`${taskCode ?? "EE1"}-C1`}
                {...register("code", {
                  required: "Code requis",
                  maxLength: { value: 16, message: "16 caractères maximum" },
                  pattern: {
                    value: /^(EE|EO)[1-3]-C[1-8]$/,
                    message: "Format attendu : EE1-C1 (tâche + numéro de compétence)",
                  },
                })}
              />
              <p className={styles.help}>
                Unique et définitif : il ne pourra plus être modifié après création.
              </p>
            </>
          )}
        </FormRow>

        <FormRow label="Titre" htmlFor="skill-form-title" error={errors.title?.message}>
          <Input
            id="skill-form-title"
            placeholder="Adapter le message au destinataire"
            {...register("title", {
              required: "Titre requis",
              maxLength: { value: 160, message: "160 caractères maximum" },
            })}
          />
        </FormRow>

        <FormRow
          label="Description"
          htmlFor="skill-form-description"
          error={errors.description?.message}
        >
          <Textarea
            id="skill-form-description"
            rows={4}
            placeholder="Ce que la compétence apporte au candidat, en une ou deux phrases."
            {...register("description", { required: "Description requise" })}
          />
          <p className={styles.help}>
            Sert d&apos;encart « Pourquoi cet exercice ? » côté candidat : expliquer
            ce que le critère apporte au TCF, sans jargon.
          </p>
        </FormRow>

        <FormRow
          label="Critère général travaillé"
          htmlFor="skill-form-general-criterion"
          error={errors.generalCriterion?.message}
        >
          <Textarea
            id="skill-form-general-criterion"
            rows={3}
            placeholder="Savoir choisir une formule, un ton et un niveau de politesse adaptés : ami, voisin, collègue, administration, responsable."
            {...register("generalCriterion", {
              required: "Critère général requis",
            })}
          />
          <p className={styles.help}>
            Ce qui sera <strong>observé</strong> dans les 15 petits sujets de cette
            compétence, en une à deux phrases. À distinguer de la description
            ci-dessus, qui explique l&apos;intérêt de l&apos;exercice, et du critère
            unique de chaque sujet, qui ne vaut que pour lui.
          </p>
        </FormRow>

        <FormRow twoCol>
          <FormRow
            label="Niveau visé"
            htmlFor="skill-form-level"
            error={errors.targetLevel?.message}
          >
            <Select
              id="skill-form-level"
              {...register("targetLevel", { required: "Niveau requis" })}
            >
              {TARGET_LEVELS.map((level) => (
                <option key={level} value={level}>
                  {level}
                </option>
              ))}
            </Select>
          </FormRow>

          <FormRow
            label="Rang d'affichage (1 à 8)"
            htmlFor="skill-form-order"
            error={errors.displayOrder?.message}
          >
            <Input
              id="skill-form-order"
              type="number"
              min={1}
              max={8}
              {...register("displayOrder", {
                valueAsNumber: true,
                validate: (v) =>
                  (Number.isInteger(v) && v >= 1 && v <= 8) ||
                  "Un entier entre 1 et 8 (8 compétences par tâche)",
              })}
            />
          </FormRow>
        </FormRow>

        <FormRow>
          <label className={styles.checkboxRow}>
            <input type="checkbox" {...register("active")} />
            <span>Compétence active (visible dans les parcours candidat)</span>
          </label>
        </FormRow>
      </form>
    </Modal>
  );
}
