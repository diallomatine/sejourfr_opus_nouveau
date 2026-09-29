import { useMemo, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { audioQuestionsApi } from "../../api/audioQuestionsApi";
import { PageHeader } from "../../components/ui/PageHeader";
import { Panel, EmptyState } from "../../components/ui/Panel";
import { Button } from "../../components/ui/Button";
import { Spinner } from "../../components/ui/Spinner";
import { Tag } from "../../components/ui/Tag";
import { FormRow, Select } from "../../components/ui/Form";
import type { GenerationLogDto, GenerationStatus } from "../../types/api";
import {
  STATUS_LABELS,
  formatDuration,
  formatEur,
  statusTone,
} from "./audioHelpers";
import styles from "./AudioQuestionLogsPage.module.css";

const PAGE_SIZE = 20;
const STATUS_FILTERS: GenerationStatus[] = [
  "SUCCESS",
  "FAILED_VALIDATION",
  "FAILED_RATE_LIMIT",
  "FAILED_ANTHROPIC",
  "FAILED_ANTHROPIC_PARSE",
  "FAILED_CONTENT_VALIDATION",
  "FAILED_DUPLICATE",
  "FAILED_AZURE_SPEECH",
  "FAILED_R2_UPLOAD",
  "FAILED_DB",
  "FAILED_TIMEOUT",
];

export function AudioQuestionLogsPage() {
  const [page, setPage] = useState(0);
  const [statusFilter, setStatusFilter] = useState<GenerationStatus | "">("");

  const params = useMemo(
    () => ({
      page,
      size: PAGE_SIZE,
      sort: "createdAt,desc",
      ...(statusFilter ? { status: statusFilter } : {}),
    }),
    [page, statusFilter],
  );

  const query = useQuery({
    queryKey: ["audioQuestions", "logs", params],
    queryFn: () => audioQuestionsApi.listLogs(params),
  });

  return (
    <div className={styles.page}>
      <PageHeader
        eyebrow="TCF · Compréhension orale"
        title="Audit des générations"
        emphasis="audio"
      />

      <Panel
        title="Filtres"
        sub="Toutes les tentatives de génération sont tracées : succès, échecs API, doublons, rate-limit."
      >
        <div className={styles.filters}>
          <FormRow label="Statut">
            <Select
              value={statusFilter}
              onChange={(e) => {
                setStatusFilter((e.target.value as GenerationStatus) || "");
                setPage(0);
              }}
            >
              <option value="">Tous les statuts</option>
              {STATUS_FILTERS.map((s) => (
                <option key={s} value={s}>
                  {STATUS_LABELS[s]}
                </option>
              ))}
            </Select>
          </FormRow>
        </div>
      </Panel>

      <Panel
        title="Historique"
        sub={
          query.data
            ? `${query.data.totalElements} entrée${query.data.totalElements > 1 ? "s" : ""}`
            : undefined
        }
        noPadding
      >
        {query.isLoading && <Spinner label="Chargement…" />}
        {query.isError && (
          <EmptyState
            title="Impossible de charger les logs"
            description={(query.error as Error)?.message}
          />
        )}
        {query.data && query.data.content.length === 0 && (
          <EmptyState
            title="Aucune génération pour ce filtre"
            description="Lance une génération pour peupler l'audit."
          />
        )}
        {query.data && query.data.content.length > 0 && (
          <div className={styles.tableWrap}>
            <table className={styles.table}>
              <thead>
                <tr>
                  <th>Date</th>
                  <th>Statut</th>
                  <th>Niveau</th>
                  <th>Durée</th>
                  <th>Coût total</th>
                  <th>Détail</th>
                </tr>
              </thead>
              <tbody>
                {query.data.content.map((log) => (
                  <LogRow key={log.id} log={log} />
                ))}
              </tbody>
            </table>

            {query.data.totalPages > 1 && (
              <div className={styles.pagination}>
                <span className={styles.pageInfo}>
                  page {query.data.page + 1} / {query.data.totalPages}
                </span>
                <div className={styles.pageActions}>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => setPage((p) => Math.max(0, p - 1))}
                    disabled={query.data.first}
                  >
                    ← Précédent
                  </Button>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => setPage((p) => p + 1)}
                    disabled={query.data.last}
                  >
                    Suivant →
                  </Button>
                </div>
              </div>
            )}
          </div>
        )}
      </Panel>
    </div>
  );
}

function LogRow({ log }: { log: GenerationLogDto }) {
  const niveau = useMemo(() => {
    try {
      const parsed = JSON.parse(log.requestedParams) as { niveau?: string };
      return parsed.niveau ?? "—";
    } catch {
      return "—";
    }
  }, [log.requestedParams]);

  const totalCost =
    (log.anthropicCostEur ?? 0) + (log.azureCostEur ?? 0) || null;
  const date = new Date(log.createdAt).toLocaleString("fr-FR", {
    dateStyle: "short",
    timeStyle: "short",
  });

  return (
    <tr>
      <td className={styles.colDate}>{date}</td>
      <td>
        <Tag tone={statusTone(log.status)}>{STATUS_LABELS[log.status]}</Tag>
      </td>
      <td className={styles.colMono}>{niveau}</td>
      <td className={styles.colMono}>{formatDuration(log.durationMs)}</td>
      <td className={styles.colMono}>{formatEur(totalCost)}</td>
      <td className={styles.colDetail}>
        {log.errorMessage ? (
          <span className={styles.errorMsg} title={log.errorMessage}>
            {log.errorMessage}
          </span>
        ) : log.questionId ? (
          <span className={styles.questionLink}>question {log.questionId.slice(0, 8)}…</span>
        ) : (
          "—"
        )}
      </td>
    </tr>
  );
}
