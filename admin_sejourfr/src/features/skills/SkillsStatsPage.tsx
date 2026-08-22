import { useMemo, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { Link, useNavigate } from "react-router-dom";
import { skillsApi } from "../../api/skillsApi";
import { Select } from "../../components/ui/Form";
import { PageHeader } from "../../components/ui/PageHeader";
import { EmptyState, Panel } from "../../components/ui/Panel";
import { Spinner } from "../../components/ui/Spinner";
import { Tag } from "../../components/ui/Tag";
import type { AdminSkillStatsDto, SkillSection } from "../../types/api";
import {
  SECTIONS,
  SECTION_LABEL,
  SECTION_TONE,
  TASK_TITLE,
  truncate,
} from "./skillHelpers";
import tableStyles from "../../components/ui/DataTable.module.css";
import styles from "./SkillsStatsPage.module.css";

function formatRate(rate: number | null): string {
  if (rate === null) return "—";
  return `${Math.round(rate * 100)} %`;
}

/** Trie du plus bloquant au moins bloquant : taux de validation croissant, à volume égal. */
function sortByDifficulty(rows: AdminSkillStatsDto[]): AdminSkillStatsDto[] {
  return [...rows].sort((a, b) => {
    if (a.analysedCount === 0 && b.analysedCount === 0) {
      return b.attemptCount - a.attemptCount;
    }
    if (a.analysedCount === 0) return 1;
    if (b.analysedCount === 0) return -1;
    return (a.validatedRate ?? 1) - (b.validatedRate ?? 1);
  });
}

export function SkillsStatsPage() {
  const navigate = useNavigate();
  const [section, setSection] = useState<SkillSection | "">("");

  const statsQuery = useQuery({
    queryKey: ["adminSkills", "stats", section || null],
    queryFn: () => skillsApi.stats(section || undefined),
  });

  const rows = statsQuery.data ?? [];

  const totals = useMemo(() => {
    const attempts = rows.reduce((sum, r) => sum + r.attemptCount, 0);
    const analysed = rows.reduce((sum, r) => sum + r.analysedCount, 0);
    const prompts = rows.reduce((sum, r) => sum + r.promptCount, 0);
    return { attempts, analysed, prompts };
  }, [rows]);

  return (
    <>
      <div className={styles.breadcrumb}>
        <Link to="/skills" className={styles.breadcrumbLink}>
          ← Toutes les compétences
        </Link>
      </div>

      <PageHeader
        eyebrow="§ 07 — Compétences TCF"
        title="Statistiques "
        emphasis="d'usage"
        actions={
          <div className={styles.filterGroup}>
            <label className={styles.filterLabel} htmlFor="stats-section">
              Épreuve
            </label>
            <Select
              id="stats-section"
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
        }
      />

      {statsQuery.isLoading && <Spinner label="Chargement des statistiques..." />}

      {statsQuery.isError && (
        <Panel>
          <div className={styles.error}>
            Erreur : {(statsQuery.error as Error).message}
          </div>
        </Panel>
      )}

      {statsQuery.data && (
        <>
          <div className={styles.summary}>
            <SummaryCard label="Compétences" value={rows.length} />
            <SummaryCard label="Petits sujets" value={totals.prompts} />
            <SummaryCard label="Tentatives" value={totals.attempts} />
            <SummaryCard
              label="Analyses IA"
              value={totals.analysed}
              hint="Le taux de validation ne porte que sur celles-ci."
            />
          </div>

          <Panel
            title="Ce qui bloque les candidats"
            sub="Taux de validation croissant : en haut, les compétences les moins souvent validées."
            noPadding
          >
            {rows.length === 0 ? (
              <EmptyState
                title="Aucune statistique"
                description="Aucune compétence ne correspond à ce filtre, ou aucune tentative n'a encore été enregistrée."
              />
            ) : (
              <div className={tableStyles.tableWrap}>
                <table className={`${tableStyles.table} ${tableStyles.cardTable}`}>
                  <thead>
                    <tr>
                      <th>Compétence</th>
                      <th>Tâche</th>
                      <th>Sujets</th>
                      <th>Tentatives</th>
                      <th>Analyses</th>
                      <th>Taux de validation</th>
                      <th></th>
                    </tr>
                  </thead>
                  <tbody>
                    {sortByDifficulty(rows).map((row) => (
                      <tr
                        key={row.skillId}
                        className={styles.clickableRow}
                        onClick={() => navigate(`/skills/${row.skillId}`)}
                      >
                        <td data-label="Compétence">
                          <div className={styles.codeLine}>
                            <code>{row.code}</code>
                          </div>
                          <strong>{truncate(row.title, 80)}</strong>
                        </td>
                        <td data-label="Tâche">
                          {row.taskCode ? (
                            <>
                              <Tag tone={SECTION_TONE[row.section]}>{row.taskCode}</Tag>
                              <div className={styles.rowMeta}>
                                {TASK_TITLE[row.taskCode]}
                              </div>
                            </>
                          ) : (
                            <>
                              <Tag tone={SECTION_TONE[row.section]}>{row.section}</Tag>
                              <div className={styles.rowMeta}>
                                Compréhension — aucune tâche
                              </div>
                            </>
                          )}
                        </td>
                        <td data-label="Sujets">
                          <span className={styles.mono}>{row.promptCount}</span>
                        </td>
                        <td data-label="Tentatives">
                          <span className={styles.mono}>{row.attemptCount}</span>
                        </td>
                        <td data-label="Analyses">
                          <span className={styles.mono}>{row.analysedCount}</span>
                        </td>
                        <td data-label="Taux de validation">
                          <RateBar rate={row.validatedRate} />
                        </td>
                        <td data-label="Action">
                          <div className={tableStyles.rowActions}>
                            <button
                              type="button"
                              className={tableStyles.iconBtn}
                              onClick={(e) => {
                                e.stopPropagation();
                                navigate(`/skills/${row.skillId}`);
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
            )}
          </Panel>
        </>
      )}
    </>
  );
}

function SummaryCard({
  label,
  value,
  hint,
}: {
  label: string;
  value: number;
  hint?: string;
}) {
  return (
    <div className={styles.summaryCard}>
      <div className={styles.summaryLabel}>{label}</div>
      <div className={styles.summaryValue}>{value}</div>
      {hint && <div className={styles.summaryHint}>{hint}</div>}
    </div>
  );
}

function RateBar({ rate }: { rate: number | null }) {
  if (rate === null) {
    return <span className={styles.rateEmpty}>aucune analyse</span>;
  }
  const percent = Math.max(0, Math.min(100, Math.round(rate * 100)));
  const tone =
    percent >= 70 ? styles.rateHigh : percent >= 40 ? styles.rateMid : styles.rateLow;
  return (
    <div className={styles.rateCell}>
      <div className={styles.rateTrack}>
        <div className={`${styles.rateFill} ${tone}`} style={{ width: `${percent}%` }} />
      </div>
      <span className={styles.ratePercent}>{formatRate(rate)}</span>
    </div>
  );
}
