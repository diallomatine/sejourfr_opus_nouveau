import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useNavigate } from "react-router-dom";
import { examsApi } from "../../api/examsApi";
import { Button } from "../../components/ui/Button";
import { PageHeader } from "../../components/ui/PageHeader";
import { EmptyState, Panel } from "../../components/ui/Panel";
import { Spinner } from "../../components/ui/Spinner";
import { Tag } from "../../components/ui/Tag";
import { useToast } from "../../components/ui/Toast";
import type { AdminExamTemplateDto } from "../../types/api";
import tableStyles from "../../components/ui/DataTable.module.css";
import styles from "./ExamsPage.module.css";

export function ExamsPage() {
  const navigate = useNavigate();

  const examsQuery = useQuery({
    queryKey: ["exams", "all"],
    queryFn: () => examsApi.list(),
  });

  const civique = examsQuery.data?.filter((e) => e.module === "CIVIQUE") ?? [];
  const tcf = examsQuery.data?.filter((e) => e.module === "TCF") ?? [];

  return (
    <>
      <PageHeader
        eyebrow="§ 05 — Vitrine produit"
        title="Examens"
        emphasis="blancs"
        actions={
          <Button variant="red" onClick={() => navigate("/exams/new")}>
            + Nouvel examen blanc
          </Button>
        }
      />

      {examsQuery.isLoading && <Spinner label="Chargement..." />}

      {examsQuery.isError && (
        <Panel>
          <div className={styles.error}>
            Erreur : {(examsQuery.error as Error).message}
          </div>
        </Panel>
      )}

      {examsQuery.data && (
        <>
          <Panel
            title="Module civique"
            sub={`${civique.length} examen${civique.length > 1 ? "s" : ""} · ${civique.filter((e) => e.published).length} publié${civique.filter((e) => e.published).length > 1 ? "s" : ""}`}
            noPadding
          >
            <ExamTable exams={civique} />
          </Panel>

          <Panel
            title="Module TCF"
            sub={`${tcf.length} examen${tcf.length > 1 ? "s" : ""} · ${tcf.filter((e) => e.published).length} publié${tcf.filter((e) => e.published).length > 1 ? "s" : ""}`}
            noPadding
          >
            <ExamTable exams={tcf} />
          </Panel>
        </>
      )}
    </>
  );
}

function ExamTable({ exams }: { exams: AdminExamTemplateDto[] }) {
  const navigate = useNavigate();
  const toast = useToast();
  const queryClient = useQueryClient();

  const deleteMutation = useMutation({
    mutationFn: (id: string) => examsApi.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["exams"] });
      toast.show("Examen supprimé", "success");
    },
    onError: (err) => toast.show((err as Error).message, "error"),
  });

  if (exams.length === 0) {
    return <EmptyState title="Aucun examen blanc" />;
  }

  const sorted = [...exams].sort((a, b) => a.position - b.position);

  return (
    <div className={tableStyles.tableWrap}>
      <table className={`${tableStyles.table} ${tableStyles.cardTable}`}>
        <thead>
          <tr>
            <th>Pos.</th>
            <th>Nom</th>
            <th>Slug</th>
            <th>Cible</th>
            <th>Composition</th>
            <th>État</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          {sorted.map((e) => (
            <tr key={e.id}>
              <td data-label="Pos.">
                <code className={styles.code}>
                  {String(e.position).padStart(2, "0")}
                </code>
              </td>
              <td data-label="Nom">
                <div>
                  <strong>{e.name}</strong>
                  {e.subtitle && (
                    <div className={styles.subtitle}>{e.subtitle}</div>
                  )}
                </div>
              </td>
              <td data-label="Slug">
                <code className={styles.code}>{e.slug}</code>
              </td>
              <td data-label="Cible">{renderTarget(e)}</td>
              <td data-label="Compo.">
                <span className={styles.composition}>
                  {e.totalQuestions} questions · {e.rules.length} règle
                  {e.rules.length > 1 ? "s" : ""}
                </span>
              </td>
              <td data-label="État">
                <div className={styles.badges}>
                  {e.free && <Tag tone="free">Gratuit</Tag>}
                  {e.published ? (
                    <Tag tone="active">Publié</Tag>
                  ) : (
                    <Tag tone="draft">Brouillon</Tag>
                  )}
                </div>
              </td>
              <td data-label="Actions">
                <div className={tableStyles.rowActions}>
                  <button
                    type="button"
                    className={tableStyles.iconBtn}
                    onClick={() => navigate(`/exams/${e.id}`)}
                  >
                    Éditer
                  </button>
                  <button
                    type="button"
                    className={`${tableStyles.iconBtn} ${tableStyles.danger}`}
                    onClick={() => {
                      if (window.confirm(`Supprimer l'examen "${e.name}" ?`)) {
                        deleteMutation.mutate(e.id);
                      }
                    }}
                  >
                    Supprimer
                  </button>
                </div>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function renderTarget(e: AdminExamTemplateDto): string {
  if (e.module === "CIVIQUE") {
    return e.targetProcedure ?? "Tous parcours";
  }
  return e.targetLevel ?? "Diagnostic";
}
