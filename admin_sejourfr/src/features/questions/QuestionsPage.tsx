import { useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useNavigate, useParams } from "react-router-dom";
import { questionsApi } from "../../api/questionsApi";
import { themesApi } from "../../api/themesApi";
import { Button } from "../../components/ui/Button";
import { EmptyState, Panel } from "../../components/ui/Panel";
import { PageHeader } from "../../components/ui/PageHeader";
import { RowMenu } from "../../components/ui/RowMenu";
import { Spinner } from "../../components/ui/Spinner";
import { Tag } from "../../components/ui/Tag";
import { useToast } from "../../components/ui/Toast";
import { useDebouncedValue } from "../../hooks/useDebouncedValue";
import type {
  Difficulty,
  MediaType,
  Module,
  QuestionDto,
  QuestionType,
} from "../../types/api";
import { QuestionFormModal } from "./QuestionFormModal";
import {
  levelsForModule,
  QUESTION_TYPE_SHORT,
  tagToneForLevel,
  tagToneForType,
  typesForModule,
} from "./questionHelpers";
import tableStyles from "../../components/ui/DataTable.module.css";
import styles from "./QuestionsPage.module.css";

interface Filters {
  themeId: string;
  difficulty: string;
  type: string;
  active: string;
  media: string;
  search: string;
}

const EMPTY_FILTERS: Filters = {
  themeId: "",
  difficulty: "",
  type: "",
  active: "",
  media: "",
  search: "",
};

const PAGE_SIZE = 20;

const MEDIA_ICON: Record<MediaType, string> = {
  AUDIO: "♪",
  IMAGE: "▣",
  VIDEO: "▶",
};

const MEDIA_LABEL: Record<MediaType, string> = {
  AUDIO: "Audio",
  IMAGE: "Image",
  VIDEO: "Vidéo",
};

export function QuestionsPage() {
  const params = useParams<{ module: string }>();
  const module: Module = params.module === "tcf" ? "TCF" : "CIVIQUE";
  return <QuestionsPageContent key={module} module={module} />;
}

interface QuestionsPageContentProps {
  module: Module;
}

function QuestionsPageContent({ module }: QuestionsPageContentProps) {
  const navigate = useNavigate();
  const supportsMedia = module === "TCF";
  const [filters, setFilters] = useState<Filters>(EMPTY_FILTERS);
  const [page, setPage] = useState(0);
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<QuestionDto | null>(null);

  const toast = useToast();
  const queryClient = useQueryClient();

  const debouncedSearch = useDebouncedValue(filters.search, 350);

  const themesQuery = useQuery({
    queryKey: ["themes", module],
    queryFn: () => themesApi.list(module),
  });

  const queryParams = useMemo(
    () => ({
      module,
      themeId: filters.themeId || undefined,
      difficulty: (filters.difficulty as Difficulty) || undefined,
      type: (filters.type as QuestionType) || undefined,
      active: filters.active === "" ? undefined : filters.active === "true",
      search: debouncedSearch || undefined,
      page,
      size: PAGE_SIZE,
    }),
    [module, filters.themeId, filters.difficulty, filters.type, filters.active, debouncedSearch, page],
  );

  const questionsQuery = useQuery({
    queryKey: ["questions", queryParams],
    queryFn: () => questionsApi.search(queryParams),
    placeholderData: (prev) => prev,
  });

  const toggleMutation = useMutation({
    mutationFn: ({ id, active }: { id: string; active: boolean }) =>
      questionsApi.setActive(id, active),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["questions"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard"] });
      toast.show("Statut mis à jour", "success");
    },
    onError: (err) => toast.show((err as Error).message, "error"),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => questionsApi.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["questions"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard"] });
      toast.show("Question supprimée", "success");
    },
    onError: (err) => toast.show((err as Error).message, "error"),
  });

  const updateFilter = (key: keyof Filters, value: string) => {
    setFilters((f) => ({ ...f, [key]: value }));
    setPage(0);
  };

  const resetFilters = () => {
    setFilters(EMPTY_FILTERS);
    setPage(0);
  };

  const handleEdit = (q: QuestionDto) => {
    setEditing(q);
    setModalOpen(true);
  };

  const handleCreate = () => {
    setEditing(null);
    setModalOpen(true);
  };

  const handleDelete = (q: QuestionDto) => {
    if (
      window.confirm(
        `Supprimer la question ?\n\n"${q.statement.slice(0, 120)}${q.statement.length > 120 ? "..." : ""}"`,
      )
    ) {
      deleteMutation.mutate(q.id);
    }
  };

  const handleRowClick = (q: QuestionDto) => {
    navigate(`/questions/${module.toLowerCase()}/${q.id}`);
  };

  const moduleLabel = module === "CIVIQUE" ? "Examen civique" : "TCF";
  const levels = levelsForModule(module);
  const types = typesForModule(module);

  const data = questionsQuery.data;
  const isInitialLoading = questionsQuery.isLoading;
  const isError = questionsQuery.isError;

  const visibleRows = useMemo(() => {
    if (!data) return [];
    if (!supportsMedia || !filters.media) return data.content;
    if (filters.media === "none") return data.content.filter((q) => !q.mediaId);
    return data.content.filter((q) => q.mediaType === filters.media);
  }, [data, filters.media, supportsMedia]);

  const activeFiltersCount = [
    filters.themeId,
    filters.difficulty,
    filters.type,
    filters.active,
    supportsMedia ? filters.media : "",
    filters.search,
  ].filter(Boolean).length;

  return (
    <>
      <PageHeader
        eyebrow="§ 02 — Catalogue de questions"
        title="Questions ·"
        emphasis={moduleLabel}
        actions={
          <Button variant="red" onClick={handleCreate}>
            + Nouvelle question
          </Button>
        }
      />

      <Panel noPadding>
        <div className={styles.filterBar}>
          <div className={styles.searchBox}>
            <input
              type="text"
              placeholder="Rechercher dans l'énoncé…"
              value={filters.search}
              onChange={(e) => updateFilter("search", e.target.value)}
            />
            {filters.search && (
              <button
                type="button"
                className={styles.clearSearch}
                onClick={() => updateFilter("search", "")}
                aria-label="Effacer la recherche"
              >
                ×
              </button>
            )}
          </div>

          <div className={styles.filtersGroup}>
            <FilterSelect
              label="Thématique"
              value={filters.themeId}
              onChange={(v) => updateFilter("themeId", v)}
              placeholder="Toutes"
            >
              {themesQuery.data?.map((t) => (
                <option key={t.id} value={t.id}>
                  {t.name}
                </option>
              ))}
            </FilterSelect>

            <FilterSelect
              label={module === "CIVIQUE" ? "Mention" : "Niveau"}
              value={filters.difficulty}
              onChange={(v) => updateFilter("difficulty", v)}
              placeholder="Tous"
            >
              {levels.map((l) => (
                <option key={l} value={l}>
                  {l}
                </option>
              ))}
            </FilterSelect>

            <FilterSelect
              label="Type"
              value={filters.type}
              onChange={(v) => updateFilter("type", v)}
              placeholder="Tous"
            >
              {types.map((t) => (
                <option key={t} value={t}>
                  {QUESTION_TYPE_SHORT[t]}
                </option>
              ))}
            </FilterSelect>

            <FilterSelect
              label="Statut"
              value={filters.active}
              onChange={(v) => updateFilter("active", v)}
              placeholder="Tous"
            >
              <option value="true">Actives</option>
              <option value="false">Inactives</option>
            </FilterSelect>

            {supportsMedia && (
              <FilterSelect
                label="Média"
                value={filters.media}
                onChange={(v) => updateFilter("media", v)}
                placeholder="Tous"
              >
                <option value="AUDIO">Audio</option>
                <option value="IMAGE">Image</option>
                <option value="VIDEO">Vidéo</option>
                <option value="none">Sans média</option>
              </FilterSelect>
            )}

            {activeFiltersCount > 0 && (
              <button
                type="button"
                className={styles.resetBtn}
                onClick={resetFilters}
              >
                Réinitialiser ({activeFiltersCount})
              </button>
            )}
          </div>
        </div>

        {isInitialLoading && (
          <div className={styles.center}>
            <Spinner label="Chargement..." />
          </div>
        )}

        {isError && (
          <div className={styles.error}>
            Erreur : {(questionsQuery.error as Error).message}
          </div>
        )}

        {data && visibleRows.length === 0 && (
          <EmptyState
            title="Aucune question"
            description="Aucune question ne correspond aux filtres sélectionnés."
          />
        )}

        {data && visibleRows.length > 0 && (
          <table className={tableStyles.table}>
            <thead>
              <tr>
                <th style={{ width: "40%" }}>Énoncé</th>
                <th>Thématique</th>
                <th>{module === "CIVIQUE" ? "Mention" : "Niveau"}</th>
                <th>Type</th>
                {supportsMedia && <th>Média</th>}
                <th>Statut</th>
                <th style={{ width: 56 }}></th>
              </tr>
            </thead>
            <tbody>
              {visibleRows.map((q) => (
                <tr
                  key={q.id}
                  className={styles.rowClickable}
                  onClick={() => handleRowClick(q)}
                >
                  <td>
                    <div className={tableStyles.statement}>
                      {q.statement}
                      <span className={tableStyles.statementMeta}>
                        {q.choices.length} choix · {q.choices.filter((c) => c.correct).length} correct
                        {q.choices.filter((c) => c.correct).length > 1 ? "s" : ""}
                      </span>
                    </div>
                  </td>
                  <td>{q.themeName}</td>
                  <td>
                    <Tag tone={tagToneForLevel(q.difficulty)}>{q.difficulty}</Tag>
                  </td>
                  <td>
                    <Tag tone={tagToneForType(q.questionType)}>
                      {QUESTION_TYPE_SHORT[q.questionType]}
                    </Tag>
                  </td>
                  {supportsMedia && (
                    <td>
                      {q.mediaType ? (
                        <span
                          className={styles.mediaCell}
                          title={MEDIA_LABEL[q.mediaType]}
                        >
                          <span className={styles.mediaIcon}>
                            {MEDIA_ICON[q.mediaType]}
                          </span>
                          <span className={styles.mediaLabel}>
                            {MEDIA_LABEL[q.mediaType]}
                          </span>
                        </span>
                      ) : (
                        <span className={styles.mediaNone}>—</span>
                      )}
                    </td>
                  )}
                  <td>
                    <Tag tone={q.active ? "active" : "draft"}>
                      {q.active ? "Active" : "Inactive"}
                    </Tag>
                  </td>
                  <td onClick={(e) => e.stopPropagation()}>
                    <RowMenu
                      items={[
                        { label: "Voir le détail", onClick: () => handleRowClick(q) },
                        { label: "Modifier", onClick: () => handleEdit(q) },
                        {
                          label: q.active ? "Désactiver" : "Activer",
                          onClick: () =>
                            toggleMutation.mutate({ id: q.id, active: !q.active }),
                          disabled: toggleMutation.isPending,
                        },
                        {
                          label: "Supprimer",
                          onClick: () => handleDelete(q),
                          danger: true,
                        },
                      ]}
                    />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}

        {data && data.totalPages > 1 && (
          <div className={styles.pagination}>
            <span className={styles.pageInfo}>
              {data.totalElements} questions · page {data.page + 1} / {data.totalPages}
            </span>
            <div className={styles.pageActions}>
              <Button
                variant="ghost"
                size="sm"
                onClick={() => setPage((p) => Math.max(0, p - 1))}
                disabled={data.first}
              >
                ← Précédent
              </Button>
              <Button
                variant="ghost"
                size="sm"
                onClick={() => setPage((p) => p + 1)}
                disabled={data.last}
              >
                Suivant →
              </Button>
            </div>
          </div>
        )}
      </Panel>

      <QuestionFormModal
        open={modalOpen}
        onClose={() => setModalOpen(false)}
        module={module}
        question={editing}
      />
    </>
  );
}

interface FilterSelectProps {
  label: string;
  value: string;
  onChange: (v: string) => void;
  placeholder: string;
  children: React.ReactNode;
}

function FilterSelect({ label, value, onChange, placeholder, children }: FilterSelectProps) {
  return (
    <label className={`${styles.filter} ${value ? styles.filterActive : ""}`}>
      <span className={styles.filterLabel}>{label}</span>
      <select value={value} onChange={(e) => onChange(e.target.value)}>
        <option value="">{placeholder}</option>
        {children}
      </select>
    </label>
  );
}
