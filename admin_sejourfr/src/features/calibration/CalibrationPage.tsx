import { useMemo, useState } from "react";
import { useQueries, useQuery } from "@tanstack/react-query";
import { calibrationApi } from "../../api/calibrationApi";
import { productionTasksApi } from "../../api/productionTasksApi";
import { PageHeader } from "../../components/ui/PageHeader";
import { EmptyState, Panel } from "../../components/ui/Panel";
import { Spinner } from "../../components/ui/Spinner";
import { Tag } from "../../components/ui/Tag";
import type {
  CalibrationSubmissionDto,
  NiveauCecrl,
  ProductionSubmissionDto,
  ProductionTaskDto,
} from "../../types/api";
import { CalibrationHealth } from "./components/CalibrationHealth";
import { SubmissionDetailModal } from "./components/SubmissionDetailModal";
import {
  CONFIANCE_LABEL,
  EPREUVES_PRODUCTION,
  EPREUVE_LABEL,
  NIVEAU_LABEL,
  formatDateTime,
  formatNote,
} from "./calibrationHelpers";
import tableStyles from "../../components/ui/DataTable.module.css";
import styles from "./CalibrationPage.module.css";

const LIMITS = [25, 50, 100, 200] as const;

/** Repli quand /stats n'a pas encore répondu : le seuil réel vient du serveur. */
const SEUIL_PAR_DEFAUT = 3;

/** Reprend les couleurs de niveau déjà utilisées ailleurs dans la console. */
const NIVEAU_TONE: Record<
  NiveauCecrl,
  "muted" | "a2" | "b1" | "b2" | "active"
> = {
  A1_NON_ATTEINT: "muted",
  A1: "muted",
  A2: "a2",
  B1: "b1",
  B2: "b2",
  C1: "active",
  C2: "active",
};

type Onglet = "pending" | "annotated";

interface SubmissionRow {
  entry: CalibrationSubmissionDto;
  submission: ProductionSubmissionDto;
  task?: ProductionTaskDto;
  epreuve: string;
  tache: string;
}

export function CalibrationPage() {
  const [onglet, setOnglet] = useState<Onglet>("pending");
  const [limit, setLimit] = useState<number>(50);
  // La soumission ouverte est mémorisée telle quelle : l'enregistrement d'une
  // note la fait basculer de « à annoter » vers « déjà annotées », et elle peut
  // sortir de la fenêtre chargée — la retrouver dans les listes ferait
  // disparaître la fiche sous les yeux du correcteur au moment où il valide.
  const [selected, setSelected] = useState<CalibrationSubmissionDto | null>(null);
  const selectedId = selected?.submission.id ?? null;

  const statsQuery = useQuery({
    queryKey: ["calibration", "stats"],
    queryFn: () => calibrationApi.stats(),
  });

  const niveauStatsQuery = useQuery({
    queryKey: ["calibration", "stats", "niveau"],
    queryFn: () => calibrationApi.niveauStats(),
  });

  const pendingQuery = useQuery({
    queryKey: ["calibration", "submissions", { hasHumanNote: false, limit }],
    queryFn: () => calibrationApi.submissions(false, limit),
  });

  const annotatedQuery = useQuery({
    queryKey: ["calibration", "submissions", { hasHumanNote: true, limit }],
    queryFn: () => calibrationApi.submissions(true, limit),
  });

  const humanNoteQuery = useQuery({
    queryKey: ["calibration", "humanNote", selectedId],
    queryFn: () => calibrationApi.humanNote(selectedId as string),
    enabled: selectedId !== null,
  });

  // Le DTO d'une soumission ne porte pas son épreuve : on la retrouve via le
  // catalogue des sujets, qui fournit au passage la consigne montrée au correcteur.
  const tasksById = useQueries({
    queries: EPREUVES_PRODUCTION.map((epreuve) => ({
      queryKey: ["productionTasks", epreuve],
      queryFn: () => productionTasksApi.list(epreuve),
      staleTime: 10 * 60_000,
    })),
    combine: (results) => {
      const map = new Map<string, ProductionTaskDto>();
      for (const result of results) {
        for (const task of result.data ?? []) map.set(task.id, task);
      }
      return map;
    },
  });

  const pending = useMemo(() => pendingQuery.data ?? [], [pendingQuery.data]);
  const annotated = useMemo(
    () => annotatedQuery.data ?? [],
    [annotatedQuery.data],
  );

  const rows = useMemo<SubmissionRow[]>(() => {
    const source = onglet === "pending" ? pending : annotated;
    return source.map((entry) => {
      const submission = entry.submission;
      const task = submission.productionTaskId
        ? tasksById.get(submission.productionTaskId)
        : undefined;
      const tacheNumero = submission.tacheNumero ?? task?.tacheNumero;
      return {
        entry,
        submission,
        task,
        epreuve: task ? EPREUVE_LABEL[task.epreuve] : "—",
        tache: tacheNumero ? `Tâche ${tacheNumero}` : "—",
      };
    });
  }, [onglet, pending, annotated, tasksById]);

  const isLoading = pendingQuery.isLoading || annotatedQuery.isLoading;
  const listeEnErreur = Boolean(
    onglet === "pending" ? pendingQuery.error : annotatedQuery.error,
  );
  const error = statsQuery.error ?? pendingQuery.error ?? annotatedQuery.error;
  const seuil = statsQuery.data?.seuilHorsCible ?? SEUIL_PAR_DEFAUT;

  return (
    <>
      <PageHeader
        eyebrow="§ 07 — Notation IA"
        title="Calibration de la"
        emphasis="notation"
      />

      <p className={styles.intro}>
        Comparer, production par production, la note de l&apos;IA avec celle
        d&apos;un correcteur humain. C&apos;est la seule façon de savoir si la
        notation tombe juste — et, à la longue, de constituer un corpus de
        référence fait de vraies copies plutôt que d&apos;exemples fabriqués.
      </p>

      {statsQuery.data && (
        <CalibrationHealth
          stats={statsQuery.data}
          niveau={niveauStatsQuery.data}
        />
      )}

      {error && (
        <Panel>
          <div className={styles.error}>Erreur : {(error as Error).message}</div>
        </Panel>
      )}

      <Panel
        title="Productions évaluées"
        sub={`${rows.length} sur cette vue · ${pending.length} à annoter`}
        noPadding
        actions={
          <div className={styles.limitPicker}>
            <span className={styles.limitLabel}>Charger</span>
            <select
              className={styles.limitSelect}
              value={limit}
              onChange={(e) => setLimit(Number(e.target.value))}
              aria-label="Nombre de productions chargées"
            >
              {LIMITS.map((value) => (
                <option key={value} value={value}>
                  {value}
                </option>
              ))}
            </select>
          </div>
        }
      >
        <div className={styles.tabs} role="tablist">
          <Tab
            active={onglet === "pending"}
            count={pending.length}
            onClick={() => setOnglet("pending")}
          >
            À annoter
          </Tab>
          <Tab
            active={onglet === "annotated"}
            count={annotated.length}
            onClick={() => setOnglet("annotated")}
          >
            Déjà annotées
          </Tab>
        </div>

        {isLoading && <Spinner label="Chargement des productions…" />}

        {!isLoading && rows.length === 0 && listeEnErreur && (
          <EmptyState
            title="Liste indisponible"
            description="Les productions évaluées n'ont pas pu être chargées : la liste ci-dessous est vide parce que la requête a échoué, pas parce qu'il n'y a rien à annoter."
          />
        )}

        {!isLoading && rows.length === 0 && !listeEnErreur && (
          <EmptyState
            title={
              onglet === "pending"
                ? "Rien à annoter"
                : "Aucune production annotée"
            }
            description={
              onglet === "pending"
                ? "Toutes les productions évaluées de cette fenêtre portent déjà une note humaine."
                : "Annotez une production dans l'onglet précédent pour la voir apparaître ici."
            }
          />
        )}

        {!isLoading && rows.length > 0 && (
          <>
            <table className={`${tableStyles.table} ${styles.table}`}>
              <thead>
                <tr>
                  <th>Épreuve</th>
                  <th>Tâche</th>
                  <th>Soumise le</th>
                  <th>Note IA</th>
                  <th>Niveau observé</th>
                  <th>Confiance</th>
                  <th />
                </tr>
              </thead>
              <tbody>
                {rows.map((row) => (
                  <tr key={row.submission.id}>
                    <td>{row.epreuve}</td>
                    <td>{row.tache}</td>
                    <td className={styles.dateCell}>
                      {formatDateTime(row.submission.submittedAt)}
                    </td>
                    <td className={styles.noteCell}>
                      {formatNote(row.submission.evaluation?.noteSurVingt)}
                    </td>
                    <td>
                      <NiveauCell submission={row.submission} />
                    </td>
                    <td>
                      <ConfianceCell submission={row.submission} />
                    </td>
                    <td>
                      <div className={tableStyles.rowActions}>
                        <button
                          type="button"
                          className={tableStyles.iconBtn}
                          onClick={() => setSelected(row.entry)}
                        >
                          {onglet === "pending" ? "Annoter" : "Revoir"}
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>

            <ul className={styles.cards}>
              {rows.map((row) => (
                <li key={row.submission.id}>
                  <button
                    type="button"
                    className={styles.card}
                    onClick={() => setSelected(row.entry)}
                  >
                    <span className={styles.cardTop}>
                      <span className={styles.cardTitle}>{row.epreuve}</span>
                      <span className={styles.cardNote}>
                        {formatNote(row.submission.evaluation?.noteSurVingt)}
                      </span>
                    </span>
                    <span className={styles.cardMeta}>
                      {row.tache} · {formatDateTime(row.submission.submittedAt)}
                    </span>
                    <span className={styles.cardTags}>
                      <NiveauCell submission={row.submission} />
                      <ConfianceCell submission={row.submission} />
                    </span>
                  </button>
                </li>
              ))}
            </ul>
          </>
        )}
      </Panel>

      <SubmissionDetailModal
        entry={selected}
        task={
          selected?.submission.productionTaskId
            ? tasksById.get(selected.submission.productionTaskId)
            : undefined
        }
        seuilHorsCible={seuil}
        existingNote={humanNoteQuery.data ?? null}
        isLoadingNote={humanNoteQuery.isLoading}
        onClose={() => setSelected(null)}
      />
    </>
  );
}

function NiveauCell({ submission }: { submission: ProductionSubmissionDto }) {
  const niveau = submission.evaluation?.niveauObserve;
  if (!niveau) return <span className={styles.absent}>non renseigné</span>;
  return <Tag tone={NIVEAU_TONE[niveau]}>{NIVEAU_LABEL[niveau]}</Tag>;
}

function ConfianceCell({ submission }: { submission: ProductionSubmissionDto }) {
  const confiance = submission.evaluation?.confiance;
  if (!confiance) return <span className={styles.absent}>non renseignée</span>;
  return <Tag tone="muted">{CONFIANCE_LABEL[confiance]}</Tag>;
}

function Tab({
  active,
  count,
  onClick,
  children,
}: {
  active: boolean;
  count: number;
  onClick: () => void;
  children: string;
}) {
  return (
    <button
      type="button"
      role="tab"
      aria-selected={active}
      className={`${styles.tab} ${active ? styles.tabActive : ""}`}
      onClick={onClick}
    >
      {children}
      <span className={styles.tabCount}>{count}</span>
    </button>
  );
}
