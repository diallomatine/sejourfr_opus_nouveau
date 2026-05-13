import {useMemo, useState} from "react";
import {useMutation, useQuery, useQueryClient} from "@tanstack/react-query";
import {useParams} from "react-router-dom";
import {questionsApi} from "../../api/questionsApi";
import {themesApi} from "../../api/themesApi";
import {Button} from "../../components/ui/Button";
import {EmptyState, Panel} from "../../components/ui/Panel";
import {PageHeader} from "../../components/ui/PageHeader";
import {Spinner} from "../../components/ui/Spinner";
import {Tag} from "../../components/ui/Tag";
import {useToast} from "../../components/ui/Toast";
import type {Difficulty, Module, QuestionDto, QuestionType,} from "../../types/api";
import {QuestionFormModal} from "./QuestionFormModal";
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
    search: string;
}

const PAGE_SIZE = 20;

export function QuestionsPage() {
    const params = useParams<{ module: string }>();
    const module: Module = params.module === "tcf" ? "TCF" : "CIVIQUE";

    return <QuestionsPageContent key={module} module={module}/>;
}

interface QuestionsPageContentProps {
    module: Module;
}

function QuestionsPageContent({module}: QuestionsPageContentProps) {
    const [filters, setFilters] = useState<Filters>({
        themeId: "",
        difficulty: "",
        type: "",
        active: "",
        search: "",
    });
    const [page, setPage] = useState(0);
    const [modalOpen, setModalOpen] = useState(false);
    const [editing, setEditing] = useState<QuestionDto | null>(null);

    const toast = useToast();
    const queryClient = useQueryClient();

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
            search: filters.search || undefined,
            page,
            size: PAGE_SIZE,
        }),
        [module, filters, page],
    );

    const questionsQuery = useQuery({
        queryKey: ["questions", queryParams],
        queryFn: () => questionsApi.search(queryParams),
        placeholderData: (prev) => prev,
    });

    const toggleMutation = useMutation({
        mutationFn: ({id, active}: { id: string; active: boolean }) =>
            questionsApi.setActive(id, active),
        onSuccess: () => {
            queryClient.invalidateQueries({queryKey: ["questions"]});
            queryClient.invalidateQueries({queryKey: ["dashboard"]});
            toast.show("Statut mis a jour", "success");
        },
        onError: (err) => toast.show((err as Error).message, "error"),
    });

    const deleteMutation = useMutation({
        mutationFn: (id: string) => questionsApi.delete(id),
        onSuccess: () => {
            queryClient.invalidateQueries({queryKey: ["questions"]});
            queryClient.invalidateQueries({queryKey: ["dashboard"]});
            toast.show("Question supprimee", "success");
        },
        onError: (err) => toast.show((err as Error).message, "error"),
    });

    const updateFilter = (key: keyof Filters, value: string) => {
        setFilters((f) => ({...f, [key]: value}));
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

    const moduleLabel = module === "CIVIQUE" ? "Examen civique" : "TCF";
    const levels = levelsForModule(module);
    const types = typesForModule(module);

    const data = questionsQuery.data;
    const isInitialLoading = questionsQuery.isLoading;
    const isError = questionsQuery.isError;

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
                <div className={styles.filters}>
                    <div className={styles.filter}>
                        <span className={styles.filterLabel}>Thématique</span>
                        <select
                            value={filters.themeId}
                            onChange={(e) => updateFilter("themeId", e.target.value)}
                        >
                            <option value="">Toutes</option>
                            {themesQuery.data?.map((t) => (
                                <option key={t.id} value={t.id}>
                                    {t.name}
                                </option>
                            ))}
                        </select>
                    </div>
                    <div className={styles.filter}>
            <span className={styles.filterLabel}>
              {module === "CIVIQUE" ? "Mention" : "Niveau"}
            </span>
                        <select
                            value={filters.difficulty}
                            onChange={(e) => updateFilter("difficulty", e.target.value)}
                        >
                            <option value="">Tous</option>
                            {levels.map((l) => (
                                <option key={l} value={l}>
                                    {l}
                                </option>
                            ))}
                        </select>
                    </div>
                    <div className={styles.filter}>
                        <span className={styles.filterLabel}>Type</span>
                        <select
                            value={filters.type}
                            onChange={(e) => updateFilter("type", e.target.value)}
                        >
                            <option value="">Tous</option>
                            {types.map((t) => (
                                <option key={t} value={t}>
                                    {QUESTION_TYPE_SHORT[t]}
                                </option>
                            ))}
                        </select>
                    </div>
                    <div className={styles.filter}>
                        <span className={styles.filterLabel}>Statut</span>
                        <select
                            value={filters.active}
                            onChange={(e) => updateFilter("active", e.target.value)}
                        >
                            <option value="">Tous</option>
                            <option value="true">Actives</option>
                            <option value="false">Inactives</option>
                        </select>
                    </div>
                    <div className={styles.searchBox}>
                        <input
                            type="text"
                            placeholder="Rechercher dans l'énoncé…"
                            value={filters.search}
                            onChange={(e) => updateFilter("search", e.target.value)}
                        />
                    </div>
                </div>

                {isInitialLoading && (
                    <div className={styles.center}>
                        <Spinner label="Chargement..."/>
                    </div>
                )}

                {isError && (
                    <div className={styles.error}>
                        Erreur : {(questionsQuery.error as Error).message}
                    </div>
                )}

                {data && data.content.length === 0 && (
                    <EmptyState
                        title="Aucune question"
                        description="Aucune question ne correspond aux filtres sélectionnés."
                    />
                )}

                {data && data.content.length > 0 && (
                    <table className={tableStyles.table}>
                        <thead>
                        <tr>
                            <th style={{width: "40%"}}>Énoncé</th>
                            <th>Thématique</th>
                            <th>{module === "CIVIQUE" ? "Mention" : "Niveau"}</th>
                            <th>Type</th>
                            <th>Statut</th>
                            <th></th>
                        </tr>
                        </thead>
                        <tbody>
                        {data.content.map((q) => (
                            <tr key={q.id}>
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
                                <td>
                                    <Tag tone={q.active ? "active" : "draft"}>
                                        {q.active ? "Active" : "Inactive"}
                                    </Tag>
                                </td>
                                <td>
                                    <div className={tableStyles.rowActions}>
                                        <button
                                            type="button"
                                            className={tableStyles.iconBtn}
                                            onClick={() => handleEdit(q)}
                                        >
                                            Modifier
                                        </button>
                                        <button
                                            type="button"
                                            className={tableStyles.iconBtn}
                                            onClick={() =>
                                                toggleMutation.mutate({id: q.id, active: !q.active})
                                            }
                                            disabled={toggleMutation.isPending}
                                        >
                                            {q.active ? "Désactiver" : "Activer"}
                                        </button>
                                        <button
                                            type="button"
                                            className={`${tableStyles.iconBtn} ${tableStyles.danger}`}
                                            onClick={() => handleDelete(q)}
                                        >
                                            Supprimer
                                        </button>
                                    </div>
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
