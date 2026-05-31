"use client";

import {useRouter} from "next/navigation";
import {useEffect, useMemo, useState} from "react";
import {ChevronRight} from "lucide-react";
import {productionApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {
  eeTaskSubtitle,
  eeTaskTitle,
  type ProductionSubmissionDto,
  resolveTcfLevel,
} from "@/lib/types";
import {DualChromeShell} from "@/app/_components/DualChromeShell";
import {ModuleDetailGate, moduleDetailStyles as ds} from "@/app/_components/module_detail/parts";
import {
  ExamBlancHero,
  HubDetailHeader,
  SectionCounter,
  SectionLabel,
  SectionLink,
} from "@/app/_components/hub/HubParts";
import {SubmissionRow} from "@/app/_components/production/SubmissionRow";
import hub from "@/app/_components/hub/hub.module.css";
import prod from "@/app/_components/production/production.module.css";

const TASKS = [1, 2, 3] as const;

/**
 * Hub Expression écrite (TCF_EE) — single-scroll calqué sur
 * `TcfExpressionScreen` mobile : hero examen blanc 3 tâches + entraînement par
 * tâche (T1/T2/T3) + historique. L'évaluation IA et le paywall (2 essais
 * gratuits puis Intégral) vivent dans les écrans enfants.
 */
export default function EeHubPage() {
  const router = useRouter();
  const {user, status} = useAuth();
  const level = resolveTcfLevel(user);

  const [lastPerTask, setLastPerTask] = useState<Map<number, ProductionSubmissionDto>>(new Map());
  const [history, setHistory] = useState<ProductionSubmissionDto[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (status !== "authenticated") return;
    let cancelled = false;
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setLoading(true);
    Promise.allSettled([
      productionApi.lastPerTask("TCF_EE", level),
      productionApi.listMine({epreuve: "TCF_EE", limit: 20}),
    ]).then(([lpt, hist]) => {
      if (cancelled) return;
      if (lpt.status === "fulfilled") {
        const m = new Map<number, ProductionSubmissionDto>();
        for (const s of lpt.value) if (s.tacheNumero != null) m.set(s.tacheNumero, s);
        setLastPerTask(m);
      }
      if (hist.status === "fulfilled") {
        setHistory(
          hist.value
            .slice()
            .sort((a, b) => b.submittedAt.localeCompare(a.submittedAt)),
        );
      }
      setLoading(false);
    });
    return () => {
      cancelled = true;
    };
  }, [status, level]);

  const recent = useMemo(() => history.slice(0, 4), [history]);

  if (status === "loading") return <div className={ds.gate} />;
  if (!user) return <ModuleDetailGate next="/entrainement/tcf/ee" />;

  return (
    <DualChromeShell>
      <main className={hub.hub}>
        <HubDetailHeader
          backHref="/entrainement?module=TCF"
          title="Expression écrite"
          subtitle={`TCF IRN · Écrit · objectif ${level}`}
        />

        <ExamBlancHero
          eyebrow="Examen blanc · 3 tâches"
          title="Passer l'examen blanc"
          description="Les 3 productions écrites enchaînées, évaluées par l'IA avec un niveau CECRL à la clé."
          ctaLabel="Voir l'examen blanc"
          accent="red"
          onClick={() => router.push("/entrainement/tcf/ee/examens")}
        />

        <SectionLabel
          label="S'entraîner par tâche"
          trailing={<SectionCounter text="3 tâches" />}
        />
        <div className={hub.list}>
          {TASKS.map((n) => {
            const last = lastPerTask.get(n);
            const note = last?.evaluation?.noteSurVingt;
            return (
              <button
                key={n}
                type="button"
                className={prod.row}
                onClick={() => router.push(`/entrainement/tcf/ee/tache/${n}`)}
              >
                <span className={prod.rowChip}>T{n}</span>
                <span className={prod.rowBody}>
                  <span className={prod.rowTitle}>{eeTaskTitle(n)}</span>
                  <span className={prod.rowSub}>{eeTaskSubtitle(n)}</span>
                </span>
                {note != null ? (
                  <span
                    className={prod.rowScore}
                    style={{
                      background: "var(--color-blue-soft)",
                      color: "var(--color-blue)",
                    }}
                  >
                    {formatNote(note)}/20
                  </span>
                ) : null}
                <ChevronRight size={20} className={prod.rowChevron} />
              </button>
            );
          })}
        </div>

        <SectionLabel
          label="Historique"
          trailing={
            history.length > 0 ? (
              <SectionLink
                label="Tout voir"
                onClick={() => router.push("/entrainement/tcf/ee/historique")}
              />
            ) : undefined
          }
        />
        {loading ? (
          <p className={prod.loading}>Chargement…</p>
        ) : recent.length === 0 ? (
          <p className={prod.empty}>
            Aucune production pour l&apos;instant. Lance une tâche pour recevoir un feedback IA.
          </p>
        ) : (
          <div className={hub.list}>
            {recent.map((s) => (
              <SubmissionRow
                key={s.id}
                submission={s}
                onClick={() => router.push(`/entrainement/tcf/ee/resultats/${s.id}`)}
              />
            ))}
          </div>
        )}
      </main>
    </DualChromeShell>
  );
}

function formatNote(n: number): string {
  return Number.isInteger(n) ? String(n) : n.toFixed(1).replace(".", ",");
}
