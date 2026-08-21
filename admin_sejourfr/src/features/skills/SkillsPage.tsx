import { useEffect, useMemo, useState } from "react";
import { keepPreviousData, useQuery } from "@tanstack/react-query";
import { useNavigate } from "react-router-dom";
import { skillsApi } from "../../api/skillsApi";
import { Button } from "../../components/ui/Button";
import { Input, Select } from "../../components/ui/Form";
import { PageHeader } from "../../components/ui/PageHeader";
import { EmptyState, Panel } from "../../components/ui/Panel";
import { Spinner } from "../../components/ui/Spinner";
import { Tag } from "../../components/ui/Tag";
import type {
  AdminSkillDto,
  AdminSkillFilters,
  SkillSection,
  SkillTaskCode,
} from "../../types/api";
import { SkillFormModal } from "./SkillFormModal";
import {
  SECTIONS,
  SECTION_LABEL,
  SECTION_TONE,
  TASK_CODES,
  TASK_TITLE,
  targetLevelTone,
  taskCodesForSection,
  truncate,
} from "./skillHelpers";
import tableStyles from "../../components/ui/DataTable.module.css";
import styles from "./SkillsPage.module.css";

const PAGE_SIZE = 25;

type ActiveFilter = "" | "true" | "false";

/**
 * Ordre promis à l'utilisateur : section puis tâche puis rang. Le backend
 * trie déjà, ce tri local ne réordonne que la page affichée — il ne change ni
 * le total ni la pagination, et garantit l'ordre si le serveur renvoie autre
 * chose. Une compétence de compréhension n'a pas de `taskCode` : elle se
 * classe sur sa section seule.
 */
function sortSkills(skills: AdminSkillDto[]): AdminSkillDto[] {
  return [...skills].sort((a, b) => {
    if (a.section !== b.section) return a.section.localeCompare(b.section);
    const taskCompare = (a.taskCode ?? "").localeCompare(b.taskCode ?? "");
    if (taskCompare !== 0) return taskCompare;
    return a.displayOrder - b.displayOrder;
  });
}

export function SkillsPage() {
  const navigate = useNavigate();
  const [section, setSection] = useState<SkillSection | "">("");
  const [taskCode, setTaskCode] = useState<SkillTaskCode | "">("");
  const [active, setActive] = useState<ActiveFilter>("");
  const [searchInput, setSearchInput] = useState("");
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(0);
  const [creating, setCreating] = useState(false);

  useEffect(() => {
    const timer = setTimeout(() => {
      setSearch(searchInput.trim());
      setPage(0);
    }, 300);
    return () => clearTimeout(timer);
  }, [searchInput]);

  useEffect(() => {
    setPage(0);
  }, [section, taskCode, active]);

  // Une tâche appartient à une section : changer de section invalide la tâche.
  useEffect(() => {
    if (section && taskCode && !taskCode.startsWith(section)) setTaskCode("");
  }, [section, taskCode]);

  const filters = useMemo<AdminSkillFilters>(
    () => ({
      section: section || undefined,
      taskCode: taskCode || undefined,
      active: active === "" ? undefined : active === "true",
      q: search || undefined,
      page,
      size: PAGE_SIZE,
    }),
    [section, taskCode, active, search, page],
  );

  const skillsQuery = useQuery({
    queryKey: ["adminSkills", filters],
    queryFn: () => skillsApi.list(filters),
    placeholderData: keepPreviousData,
  });

  const data = skillsQuery.data;
  const totalPages = data ? Math.max(1, data.totalPages) : 1;
  const taskOptions = section ? taskCodesForSection(section) : TASK_CODES;

  return (
    <>
      <PageHeader
        eyebrow="§ 07 — Compétences TCF"
        title="Compé"
        emphasis="tences"
        actions={
          <div className={styles.headerActions}>
            <Button variant="ghost" onClick={() => navigate("/skills/stats")}>
              Statistiques d&apos;usage
            </Button>
            <Button variant="red" onClick={() => setCreating(true)}>
              Nouvelle compétence
            </Button>
          </div>
        }
      />

      <Panel noPadding>
        <div className={styles.filtersBar}>
          <div className={styles.filterGroup}>
            <label className={styles.filterLabel} htmlFor="skill-section">
              Épreuve
            </label>
            <Select
              id="skill-section"
              value={section}
              onChange={(e) => setSection(e.target.value as SkillSection | "")}
            >
              <option value="">Toutes</option>
              {SECTIONS.map((s) => (
                <option key={s} value={s}>
                  {SECTION_LABEL[s]}
                </option>
              ))}
            </Select>
          </div>

          <div className={styles.filterGroup}>
            <label className={styles.filterLabel} htmlFor="skill-task">
              Tâche
            </label>
            <Select
              id="skill-task"
              value={taskCode}
              onChange={(e) => setTaskCode(e.target.value as SkillTaskCode | "")}
            >
              <option value="">Toutes</option>
              {taskOptions.map((code) => (
                <option key={code} value={code}>
                  {code} · {TASK_TITLE[code]}
                </option>
              ))}
            </Select>
          </div>

          <div className={styles.filterGroup}>
            <label className={styles.filterLabel} htmlFor="skill-active">
              Statut
            </label>
            <Select
              id="skill-active"
              value={active}
              onChange={(e) => setActive(e.target.value as ActiveFilter)}
            >
              <option value="">Tous</option>
              <option value="true">Actives</option>
              <option value="false">Inactives</option>
            </Select>
          </div>

          <div className={styles.filterGroup}>
            <label className={styles.filterLabel} htmlFor="skill-search">
              Recherche
            </label>
            <Input
              id="skill-search"
              placeholder="Code, titre, description…"
              value={searchInput}
              onChange={(e) => setSearchInput(e.target.value)}
            />
          </div>
        </div>
      </Panel>

      {skillsQuery.isLoading && <Spinner label="Chargement des compétences..." />}

      {skillsQuery.isError && (
        <Panel>
          <div className={styles.error}>
            Erreur : {(skillsQuery.error as Error).message}
          </div>
        </Panel>
      )}

      {data && (
        <Panel
          title="Catalogue"
          sub={`${data.totalElements} compétence(s) · triées par tâche puis rang d'affichage`}
          noPadding
        >
          {data.content.length === 0 ? (
            <EmptyState
              title="Aucune compétence"
              description="Aucun résultat pour ces filtres. Élargissez la recherche ou créez une compétence."
            />
          ) : (
            <>
              <div className={tableStyles.tableWrap}>
                <table className={`${tableStyles.table} ${tableStyles.cardTable}`}>
                  <thead>
                    <tr>
                      <th>Compétence</th>
                      <th>Tâche</th>
                      <th>Niveau</th>
                      <th>Rang</th>
                      <th>Sujets</th>
                      <th>Statut</th>
                      <th></th>
                    </tr>
                  </thead>
                  <tbody>
                    {sortSkills(data.content).map((skill) => (
                      <tr
                        key={skill.id}
                        className={styles.clickableRow}
                        onClick={() => navigate(`/skills/${skill.id}`)}
                      >
                        <td data-label="Compétence">
                          <div className={styles.codeLine}>
                            <code>{skill.code}</code>
                          </div>
                          <strong>{skill.title}</strong>
                          <div className={styles.rowDesc}>
                            {truncate(skill.description, 110)}
                          </div>
                        </td>
                        <td data-label="Tâche">
                          {skill.taskCode ? (
                            <>
                              <Tag tone={SECTION_TONE[skill.section]}>
                                {skill.taskCode}
                              </Tag>
                              <div className={styles.rowMeta}>
                                {TASK_TITLE[skill.taskCode]}
                              </div>
                            </>
                          ) : (
                            <>
                              <Tag tone={SECTION_TONE[skill.section]}>
                                {skill.section}
                              </Tag>
                              <div className={styles.rowMeta}>
                                Compréhension — aucune tâche
                              </div>
                            </>
                          )}
                        </td>
                        <td data-label="Niveau">
                          <Tag tone={targetLevelTone(skill.targetLevel)}>
                            {skill.targetLevel}
                          </Tag>
                        </td>
                        <td data-label="Rang">
                          <span className={styles.mono}>{skill.displayOrder}</span>
                        </td>
                        <td data-label="Sujets">
                          <span className={styles.mono}>{skill.promptCount}</span>
                        </td>
                        <td data-label="Statut">
                          {skill.active ? (
                            <Tag tone="active">Active</Tag>
                          ) : (
                            <Tag tone="muted">Inactive</Tag>
                          )}
                        </td>
                        <td data-label="Action">
                          <div className={tableStyles.rowActions}>
                            <button
                              type="button"
                              className={tableStyles.iconBtn}
                              onClick={(e) => {
                                e.stopPropagation();
                                navigate(`/skills/${skill.id}`);
                              }}
                            >
                              Ouvrir
                            </button>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              <div className={styles.pagination}>
                <Button
                  variant="ghost"
                  size="sm"
                  disabled={page === 0 || skillsQuery.isFetching}
                  onClick={() => setPage((p) => Math.max(0, p - 1))}
                >
                  ← Précédent
                </Button>
                <span className={styles.paginationInfo}>
                  Page {page + 1} / {totalPages}
                </span>
                <Button
                  variant="ghost"
                  size="sm"
                  disabled={page + 1 >= totalPages || skillsQuery.isFetching}
                  onClick={() => setPage((p) => p + 1)}
                >
                  Suivant →
                </Button>
              </div>
            </>
          )}
        </Panel>
      )}

      <SkillFormModal
        open={creating}
        skill={null}
        onClose={() => setCreating(false)}
        onCreated={(created) => {
          setCreating(false);
          navigate(`/skills/${created.id}`);
        }}
      />
    </>
  );
}
