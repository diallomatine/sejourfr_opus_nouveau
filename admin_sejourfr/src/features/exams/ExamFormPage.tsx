import { useEffect } from "react";
import {
  type UseFieldArrayRemove,
  useFieldArray,
  useForm,
  type UseFormRegister,
} from "react-hook-form";
import { useNavigate, useParams } from "react-router-dom";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { examsApi } from "../../api/examsApi";
import { themesApi } from "../../api/themesApi";
import { Button } from "../../components/ui/Button";
import { FormRow, Input, Select, Textarea } from "../../components/ui/Form";
import { PageHeader } from "../../components/ui/PageHeader";
import { Panel } from "../../components/ui/Panel";
import { Spinner } from "../../components/ui/Spinner";
import { useToast } from "../../components/ui/Toast";
import type {
  AdminExamTemplateWriteRequest,
  ThemeDto,
} from "../../types/api";
import tableStyles from "../../components/ui/DataTable.module.css";

// Form values : on stocke "" pour les nullables (HTML <select> impose des
// strings), puis on transforme "" → null au submit.
interface FormRule {
  themeId: string;
  questionType: string;
  difficulty: string;
  questionCount: number;
}

interface FormValues {
  slug: string;
  module: "CIVIQUE" | "TCF";
  targetLevel: string;
  targetProcedure: string;
  name: string;
  subtitle: string;
  description: string;
  durationSeconds: number;
  totalQuestions: number;
  passingScore: number;
  free: boolean;
  published: boolean;
  position: number;
  rules: FormRule[];
}

const EMPTY: FormValues = {
  slug: "",
  module: "CIVIQUE",
  targetLevel: "",
  targetProcedure: "",
  name: "",
  subtitle: "",
  description: "",
  durationSeconds: 2700,
  totalQuestions: 40,
  passingScore: 32,
  free: false,
  published: false,
  position: 99,
  rules: [],
};

function toWriteRequest(v: FormValues): AdminExamTemplateWriteRequest {
  return {
    slug: v.slug,
    module: v.module,
    targetLevel: (v.targetLevel || null) as AdminExamTemplateWriteRequest["targetLevel"],
    targetProcedure: (v.targetProcedure || null) as AdminExamTemplateWriteRequest["targetProcedure"],
    name: v.name,
    subtitle: v.subtitle || null,
    description: v.description || null,
    durationSeconds: v.durationSeconds,
    totalQuestions: v.totalQuestions,
    passingScore: v.passingScore,
    free: v.free,
    published: v.published,
    position: v.position,
    rules: v.rules.map((r) => ({
      themeId: r.themeId || null,
      questionType: (r.questionType || null) as AdminExamTemplateWriteRequest["rules"][number]["questionType"],
      difficulty: (r.difficulty || null) as AdminExamTemplateWriteRequest["rules"][number]["difficulty"],
      questionCount: r.questionCount,
    })),
  };
}

export function ExamFormPage() {
  const { id } = useParams<{ id: string }>();
  const isEdit = !!id;
  const navigate = useNavigate();
  const toast = useToast();
  const queryClient = useQueryClient();

  const existingQuery = useQuery({
    queryKey: ["exams", id],
    queryFn: () => examsApi.getById(id!),
    enabled: isEdit,
  });

  const {
    register,
    handleSubmit,
    reset,
    watch,
    control,
    formState: { errors, isSubmitting },
  } = useForm<FormValues>({ defaultValues: EMPTY });

  const { fields, append, remove, replace } = useFieldArray({
    control,
    name: "rules",
  });

  const watchedModule = watch("module");

  const themesQuery = useQuery({
    queryKey: ["themes", watchedModule],
    queryFn: () => themesApi.list(watchedModule),
  });

  // Reset du form quand l'édition arrive
  useEffect(() => {
    if (existingQuery.data) {
      const t = existingQuery.data;
      reset({
        slug: t.slug,
        module: t.module,
        targetLevel: t.targetLevel ?? "",
        targetProcedure: t.targetProcedure ?? "",
        name: t.name,
        subtitle: t.subtitle ?? "",
        description: t.description ?? "",
        durationSeconds: t.durationSeconds,
        totalQuestions: t.totalQuestions,
        passingScore: t.passingScore,
        free: t.free,
        published: t.published,
        position: t.position,
        rules: t.rules.map((r) => ({
          themeId: r.themeId ?? "",
          questionType: r.questionType ?? "",
          difficulty: r.difficulty ?? "",
          questionCount: r.questionCount,
        })),
      });
    }
  }, [existingQuery.data, reset]);

  const mutation = useMutation({
    mutationFn: (values: FormValues) =>
      isEdit
        ? examsApi.update(id!, toWriteRequest(values))
        : examsApi.create(toWriteRequest(values)),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["exams"] });
      toast.show(isEdit ? "Examen mis à jour" : "Examen créé", "success");
      navigate("/exams");
    },
    onError: (err) => toast.show((err as Error).message, "error"),
  });

  const suggestMutation = useMutation({
    mutationFn: () =>
      examsApi.suggestComposition({
        module: watch("module"),
        targetProcedure: (watch("targetProcedure") || undefined) as
          | "CSP"
          | "CR"
          | "NAT"
          | undefined,
        targetLevel: (watch("targetLevel") || undefined) as
          | "A2"
          | "B1"
          | "B2"
          | undefined,
        totalQuestions: watch("totalQuestions"),
      }),
    onSuccess: (data) => {
      replace(
        data.rules.map((r) => ({
          themeId: r.themeId ?? "",
          questionType: "",
          difficulty: r.difficulty ?? "",
          questionCount: r.questionCount,
        })),
      );
      toast.show(
        data.warning ?? "Composition suggérée",
        data.warning ? "error" : "success",
      );
    },
    onError: (err) => toast.show((err as Error).message, "error"),
  });

  const onSuggest = () => {
    if (fields.length > 0 && !window.confirm("Remplacer la composition actuelle ?")) return;
    suggestMutation.mutate();
  };

  if (isEdit && existingQuery.isLoading) {
    return <Spinner label="Chargement..." />;
  }

  const themes: ThemeDto[] = themesQuery.data ?? [];

  return (
    <>
      <PageHeader
        eyebrow={isEdit ? "Édition" : "Création"}
        title="Examen"
        emphasis="blanc"
        actions={
          <>
            <Button variant="ghost" onClick={() => navigate("/exams")}>
              Annuler
            </Button>
            <Button
              variant="red"
              type="submit"
              form="exam-form"
              disabled={isSubmitting || mutation.isPending}
            >
              {mutation.isPending
                ? "Enregistrement..."
                : isEdit
                  ? "Enregistrer"
                  : "Créer"}
            </Button>
          </>
        }
      />

      <form id="exam-form" onSubmit={handleSubmit((v) => mutation.mutate(v))}>
        <Panel title="Identité">
          <FormRow label="Slug (unique, kebab-case)" htmlFor="slug" error={errors.slug?.message}>
            <Input
              id="slug"
              placeholder="civique-csp-mix-01"
              {...register("slug", {
                required: "Slug requis",
                pattern: {
                  value: /^[a-z0-9]+(-[a-z0-9]+)*$/,
                  message: "Lettres minuscules, chiffres, tirets uniquement",
                },
              })}
            />
          </FormRow>

          <FormRow label="Nom" htmlFor="name" error={errors.name?.message}>
            <Input
              id="name"
              placeholder="Examen civique CSP — Mix complet"
              {...register("name", { required: "Nom requis" })}
            />
          </FormRow>

          <FormRow label="Sous-titre (carte vitrine)" htmlFor="subtitle">
            <Input
              id="subtitle"
              placeholder="40 questions · 45 min · CSP"
              {...register("subtitle")}
            />
          </FormRow>

          <FormRow label="Description" htmlFor="description">
            <Textarea id="description" rows={3} {...register("description")} />
          </FormRow>
        </Panel>

        <Panel title="Configuration">
          <FormRow twoCol>
            <FormRow label="Module" htmlFor="module">
              <Select id="module" {...register("module")}>
                <option value="CIVIQUE">Civique</option>
                <option value="TCF">TCF</option>
              </Select>
            </FormRow>
            <FormRow label="Position d'affichage" htmlFor="position">
              <Input
                id="position"
                type="number"
                {...register("position", { valueAsNumber: true })}
              />
            </FormRow>
          </FormRow>

          <FormRow twoCol>
            <FormRow label="Procédure cible (civique)" htmlFor="targetProcedure">
              <Select id="targetProcedure" {...register("targetProcedure")}>
                <option value="">— Tous parcours —</option>
                <option value="CSP">CSP</option>
                <option value="CR">CR</option>
                <option value="NAT">NAT</option>
              </Select>
            </FormRow>
            <FormRow label="Niveau cible (TCF)" htmlFor="targetLevel">
              <Select id="targetLevel" {...register("targetLevel")}>
                <option value="">— Diagnostic —</option>
                <option value="A2">A2</option>
                <option value="B1">B1</option>
                <option value="B2">B2</option>
              </Select>
            </FormRow>
          </FormRow>

          <FormRow twoCol>
            <FormRow label="Durée (secondes)" htmlFor="durationSeconds">
              <Input
                id="durationSeconds"
                type="number"
                {...register("durationSeconds", { valueAsNumber: true })}
              />
            </FormRow>
            <FormRow label="Total questions" htmlFor="totalQuestions">
              <Input
                id="totalQuestions"
                type="number"
                {...register("totalQuestions", { valueAsNumber: true })}
              />
            </FormRow>
          </FormRow>

          <FormRow label="Score requis (passingScore)" htmlFor="passingScore">
            <Input
              id="passingScore"
              type="number"
              {...register("passingScore", { valueAsNumber: true })}
            />
          </FormRow>

          <FormRow twoCol>
            <label
              style={{
                display: "flex",
                alignItems: "center",
                gap: 8,
                paddingTop: 26,
              }}
            >
              <input type="checkbox" {...register("free")} />
              Gratuit (visible sans abonnement)
            </label>
            <label
              style={{
                display: "flex",
                alignItems: "center",
                gap: 8,
                paddingTop: 26,
              }}
            >
              <input type="checkbox" {...register("published")} />
              Publié (visible côté public)
            </label>
          </FormRow>
        </Panel>

        <Panel
          title="Composition"
          sub="Règles ordonnées : chaque règle tire un nombre de questions selon thème / difficulté / type"
          actions={
            <div style={{ display: "flex", gap: 8 }}>
              <Button
                type="button"
                variant="ghost"
                onClick={() =>
                  append({
                    themeId: "",
                    questionType: "",
                    difficulty: "",
                    questionCount: 10,
                  })
                }
              >
                + Règle
              </Button>
              <Button
                type="button"
                variant="primary"
                onClick={onSuggest}
                disabled={suggestMutation.isPending}
              >
                {suggestMutation.isPending ? "..." : "Suggérer une composition"}
              </Button>
            </div>
          }
          noPadding
        >
          {fields.length === 0 ? (
            <div
              style={{
                padding: 24,
                color: "var(--muted)",
                textAlign: "center",
              }}
            >
              Aucune règle. Ajoutez-en manuellement ou cliquez « Suggérer une
              composition ».
            </div>
          ) : (
            <RuleTable
              fields={fields}
              themes={themes}
              module={watchedModule}
              register={register}
              remove={remove}
            />
          )}
        </Panel>
      </form>
    </>
  );
}

function RuleTable({
  fields,
  themes,
  module,
  register,
  remove,
}: {
  fields: { id: string }[];
  themes: ThemeDto[];
  module: "CIVIQUE" | "TCF";
  register: UseFormRegister<FormValues>;
  remove: UseFieldArrayRemove;
}) {
  const isTcf = module === "TCF";
  return (
    <table className={tableStyles.table}>
      <thead>
        <tr>
          <th>#</th>
          <th>Thème (optionnel)</th>
          <th>Difficulté</th>
          <th>Type de question</th>
          <th>Nb questions</th>
          <th></th>
        </tr>
      </thead>
      <tbody>
        {fields.map((field, index) => (
          <tr key={field.id}>
            <td>
              <code style={{ fontSize: 11, color: "var(--muted)" }}>
                {String(index + 1).padStart(2, "0")}
              </code>
            </td>
            <td>
              <Select {...register(`rules.${index}.themeId`)}>
                <option value="">— Tous thèmes —</option>
                {themes.map((th) => (
                  <option key={th.id} value={th.id}>
                    {th.name}
                  </option>
                ))}
              </Select>
            </td>
            <td>
              {isTcf ? (
                <Select
                  {...register(`rules.${index}.difficulty`)}
                  disabled
                  title="Le TCF est un test unique pour tous, sans filtre A2/B1/B2."
                  value=""
                >
                  <option value="">— Niveau ignoré (TCF) —</option>
                </Select>
              ) : (
                <Select {...register(`rules.${index}.difficulty`)}>
                  <option value="">— Toutes —</option>
                  <option value="CSP">CSP</option>
                  <option value="CR">CR</option>
                  <option value="NAT">NAT</option>
                </Select>
              )}
            </td>
            <td>
              <Select {...register(`rules.${index}.questionType`)}>
                <option value="">— Tous —</option>
                <option value="CONNAISSANCE">Connaissance</option>
                <option value="MISE_SITUATION">Mise en situation</option>
                <option value="CO">CO</option>
                <option value="CE">CE</option>
                <option value="STRUCTURE">Structure</option>
              </Select>
            </td>
            <td style={{ width: 100 }}>
              <Input
                type="number"
                min={1}
                {...register(`rules.${index}.questionCount`, {
                  valueAsNumber: true,
                })}
              />
            </td>
            <td>
              <button
                type="button"
                className={`${tableStyles.iconBtn} ${tableStyles.danger}`}
                onClick={() => remove(index)}
              >
                Retirer
              </button>
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
