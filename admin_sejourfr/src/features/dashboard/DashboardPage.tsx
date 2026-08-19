import { useQuery } from "@tanstack/react-query";
import { dashboardApi } from "../../api/dashboardApi";
import { AnciensAcheteursPanel } from "./AnciensAcheteursPanel";
import { PageHeader } from "../../components/ui/PageHeader";
import { Panel } from "../../components/ui/Panel";
import { Spinner } from "../../components/ui/Spinner";
import styles from "./DashboardPage.module.css";

export function DashboardPage() {
  const { data, isLoading, isError, error } = useQuery({
    queryKey: ["dashboard"],
    queryFn: () => dashboardApi.get(),
  });

  return (
    <>
      <PageHeader
        eyebrow="§ 01 — Vue d'ensemble"
        title="Tableau de"
        emphasis="bord"
      />

      {isLoading && <Spinner label="Chargement..." />}

      {isError && (
        <Panel>
          <div className={styles.error}>
            Erreur : {(error as Error).message}
          </div>
        </Panel>
      )}

      {data && (
        <>
          <div className={styles.kpiGrid}>
            <Kpi
              accent="blue"
              label="Questions civique"
              value={data.questionsCivique}
              hint={`${data.questionsCiviqueActive} actives`}
            />
            <Kpi
              accent="white"
              label="Questions TCF"
              value={data.questionsTcf}
              hint={`${data.questionsTcfActive} actives`}
            />
            <Kpi
              accent="red"
              label="Utilisateurs"
              value={data.usersTotal}
              hint="comptes au total"
            />
            <Kpi
              accent="blue"
              label="Messages en attente"
              value={data.conversationsUnread}
              hint="non lus par l'admin"
            />
          </div>
        </>
      )}

      <AnciensAcheteursPanel />
    </>
  );
}

function Kpi({
  accent,
  label,
  value,
  hint,
}: {
  accent: "blue" | "red" | "white";
  label: string;
  value: number;
  hint?: string;
}) {
  return (
    <div className={`${styles.kpi} ${styles[accent]}`}>
      <div className={styles.label}>{label}</div>
      <div className={styles.value}>{value}</div>
      {hint && <div className={styles.hint}>{hint}</div>}
    </div>
  );
}
