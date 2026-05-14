import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { themesApi } from "../../api/themesApi";
import { Button } from "../../components/ui/Button";
import { FormRow, Input, Select, Textarea } from "../../components/ui/Form";
import { Modal } from "../../components/ui/Modal";
import { PageHeader } from "../../components/ui/PageHeader";
import { EmptyState, Panel } from "../../components/ui/Panel";
import { Spinner } from "../../components/ui/Spinner";
import { Tag } from "../../components/ui/Tag";
import { useToast } from "../../components/ui/Toast";
import type { ThemeDto, ThemeWriteRequest } from "../../types/api";
import { useForm } from "react-hook-form";
import tableStyles from "../../components/ui/DataTable.module.css";

export function ThemesPage() {
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<ThemeDto | null>(null);

  const themesQuery = useQuery({
    queryKey: ["themes", "all"],
    queryFn: () => themesApi.list(),
  });

  const civique = themesQuery.data?.filter((t) => t.module === "CIVIQUE") ?? [];
  const tcf = themesQuery.data?.filter((t) => t.module === "TCF") ?? [];

  const handleCreate = () => {
    setEditing(null);
    setModalOpen(true);
  };

  const handleEdit = (theme: ThemeDto) => {
    setEditing(theme);
    setModalOpen(true);
  };

  return (
    <>
      <PageHeader
        eyebrow="§ 03 — Organisation du contenu"
        title="Thé"
        emphasis="matiques"
        actions={
          <Button variant="red" onClick={handleCreate}>
            + Nouvelle thématique
          </Button>
        }
      />

      {themesQuery.isLoading && <Spinner label="Chargement..." />}

      {themesQuery.isError && (
        <Panel>
          <div style={{ padding: 24, color: "var(--red)" }}>
            Erreur : {(themesQuery.error as Error).message}
          </div>
        </Panel>
      )}

      {themesQuery.data && (
        <>
          <Panel
            title="Module civique"
            sub={`${civique.length} thématiques`}
            noPadding
          >
            <ThemeTable themes={civique} onEdit={handleEdit} />
          </Panel>

          <Panel title="Module TCF" sub={`${tcf.length} thématiques`} noPadding>
            <ThemeTable themes={tcf} onEdit={handleEdit} />
          </Panel>
        </>
      )}

      <ThemeFormModal
        open={modalOpen}
        onClose={() => setModalOpen(false)}
        theme={editing}
      />
    </>
  );
}

function ThemeTable({
  themes,
  onEdit,
}: {
  themes: ThemeDto[];
  onEdit: (t: ThemeDto) => void;
}) {
  const toast = useToast();
  const queryClient = useQueryClient();

  const deleteMutation = useMutation({
    mutationFn: (id: string) => themesApi.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["themes"] });
      toast.show("Thématique supprimée", "success");
    },
    onError: (err) => toast.show((err as Error).message, "error"),
  });

  if (themes.length === 0) {
    return <EmptyState title="Aucune thématique" />;
  }

  return (
    <table className={tableStyles.table}>
      <thead>
        <tr>
          <th>Nom</th>
          <th>Code</th>
          <th>Description</th>
          <th>Questions</th>
          <th>Ordre</th>
          <th></th>
        </tr>
      </thead>
      <tbody>
        {themes.map((t) => (
          <tr key={t.id}>
            <td>
              <strong>{t.name}</strong>
            </td>
            <td>
              <code style={{ fontSize: 11, color: "var(--muted)" }}>{t.code}</code>
            </td>
            <td style={{ color: "var(--muted)", maxWidth: 380 }}>
              {t.description}
            </td>
            <td>
              <Tag tone="muted">{t.questionCount}</Tag>
            </td>
            <td>{t.displayOrder}</td>
            <td>
              <div className={tableStyles.rowActions}>
                <button
                  type="button"
                  className={tableStyles.iconBtn}
                  onClick={() => onEdit(t)}
                >
                  Modifier
                </button>
                <button
                  type="button"
                  className={`${tableStyles.iconBtn} ${tableStyles.danger}`}
                  onClick={() => {
                    if (
                      window.confirm(`Supprimer la thématique "${t.name}" ?`)
                    ) {
                      deleteMutation.mutate(t.id);
                    }
                  }}
                  disabled={t.questionCount > 0}
                  title={
                    t.questionCount > 0
                      ? "Impossible : des questions sont rattachées"
                      : "Supprimer"
                  }
                >
                  Supprimer
                </button>
              </div>
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}

interface FormValues extends ThemeWriteRequest {}

function ThemeFormModal({
  open,
  onClose,
  theme,
}: {
  open: boolean;
  onClose: () => void;
  theme: ThemeDto | null;
}) {
  const toast = useToast();
  const queryClient = useQueryClient();

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors, isSubmitting },
  } = useForm<FormValues>({
    defaultValues: {
      module: "CIVIQUE",
      code: "",
      name: "",
      description: "",
      displayOrder: 0,
    },
  });

  // Reset des valeurs quand on ouvre / change de theme
  useEffectOnOpen(open, () => {
    if (theme) {
      reset({
        module: theme.module,
        code: theme.code,
        name: theme.name,
        description: theme.description ?? "",
        displayOrder: theme.displayOrder,
      });
    } else {
      reset({
        module: "CIVIQUE",
        code: "",
        name: "",
        description: "",
        displayOrder: 0,
      });
    }
  });

  const mutation = useMutation({
    mutationFn: (values: FormValues) =>
      theme ? themesApi.update(theme.id, values) : themesApi.create(values),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["themes"] });
      toast.show(theme ? "Thématique mise à jour" : "Thématique créée", "success");
      onClose();
    },
    onError: (err) => toast.show((err as Error).message, "error"),
  });

  return (
    <Modal
      open={open}
      onClose={onClose}
      title={theme ? "Modifier la thématique" : "Nouvelle thématique"}
      eyebrow="Thématiques"
      footer={
        <>
          <Button variant="ghost" onClick={onClose} disabled={isSubmitting}>
            Annuler
          </Button>
          <Button
            variant="red"
            type="submit"
            form="theme-form"
            disabled={isSubmitting}
          >
            {isSubmitting ? "Enregistrement..." : theme ? "Enregistrer" : "Créer"}
          </Button>
        </>
      }
    >
      <form id="theme-form" onSubmit={handleSubmit((v) => mutation.mutate(v))}>
        <FormRow twoCol>
          <FormRow label="Module" htmlFor="module">
            <Select id="module" {...register("module")}>
              <option value="CIVIQUE">Civique</option>
              <option value="TCF">TCF</option>
            </Select>
          </FormRow>
          <FormRow label="Ordre d'affichage" htmlFor="displayOrder">
            <Input
              id="displayOrder"
              type="number"
              {...register("displayOrder", { valueAsNumber: true })}
            />
          </FormRow>
        </FormRow>

        <FormRow label="Code (unique)" htmlFor="code" error={errors.code?.message}>
          <Input
            id="code"
            placeholder="CIV_PRINCIPES"
            {...register("code", { required: "Code requis" })}
          />
        </FormRow>

        <FormRow label="Nom" htmlFor="name" error={errors.name?.message}>
          <Input
            id="name"
            placeholder="Principes et valeurs de la République"
            {...register("name", { required: "Nom requis" })}
          />
        </FormRow>

        <FormRow label="Description" htmlFor="description">
          <Textarea id="description" rows={3} {...register("description")} />
        </FormRow>
      </form>
    </Modal>
  );
}

// petit helper pour reset le form chaque fois que la modale s'ouvre
import { useEffect } from "react";
function useEffectOnOpen(open: boolean, fn: () => void) {
  useEffect(() => {
    if (open) fn();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open]);
}
