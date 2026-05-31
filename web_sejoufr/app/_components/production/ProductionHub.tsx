"use client";

import {useRouter} from "next/navigation";
import {useEffect, useMemo, useState} from "react";
import {ChevronRight} from "lucide-react";
import {productionApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {
  productionTaskSubtitle,
  productionTaskTitle,
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
import {SubmissionRow} from "./SubmissionRow";
import {type ProductionConfig} from "./config";
import hub from "@/app/_components/hub/hub.module.css";
import prod from "./production.module.css";

const TASKS = [1, 2, 3] as const;

/**
 * Hub générique d'une épreuve productive (EE/EO) — single-scroll : hero examen
 * blanc 3 tâches + entraînement par tâche (T1/T2/T3) + historique. L'input
 * (rédaction/enregistrement) et le paywall vivent dans les écrans enfants.
 */
export function ProductionHub({config}: {config: ProductionConfig}) {
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
      productionApi.lastPerTask(config.epreuve, level),
      productionApi.listMine({epreuve: config.epreuve, limit: 20}),
    ]).then(([lpt, hist]) => {
      if (cancelled) return;
      if (lpt.status === "fulfilled") {
        const m = new Map<number, ProductionSubmissionDto>();
        for (const s of lpt.value) if (s.tacheNumero != null) m.set(s.tacheNumero, s);
        setLastPerTask(m);
      }
      if (hist.status === "fulfilled") {
        setHistory(hist.value.slice().sort((a, b) => b.submittedAt.localeCompare(a.submittedAt)));
      }
      setLoading(false);
    });
    return () => {
      cancelled = true;
    };
  }, [status, level, config.epreuve]);

  const recent = useMemo(() => history.slice(0, 4), [history]);

  if (status === "loading") return <div className={ds.gate} />;
  if (!user) return <ModuleDetailGate next={config.base} />;

  return (
    <DualChromeShell>
      <main className={hub.hub}>
        <HubDetailHeader
          backHref="/entrainement?module=TCF"
          title={config.label}
          subtitle={`TCF IRN · ${config.shortLabel} · objectif ${level}`}
        />

        <ExamBlancHero
          eyebrow="Examen blanc · 3 tâches"
          title="Passer l'examen blanc"
          description={`Les 3 ${
            config.mode === "audio" ? "tâches orales enregistrées" : "productions écrites"
          }, évaluées par l'IA avec un niveau CECRL à la clé.`}
          ctaLabel="Voir l'examen blanc"
          accent={config.accent}
          onClick={() => router.push(`${config.base}/examens`)}
        />

        <SectionLabel label="S'entraîner par tâche" trailing={<SectionCounter text="3 tâches" />} />
        <div className={hub.list}>
          {TASKS.map((n) => {
            const last = lastPerTask.get(n);
            const note = last?.evaluation?.noteSurVingt;
            return (
              <button
                key={n}
                type="button"
                className={prod.row}
                onClick={() => router.push(`${config.base}/tache/${n}`)}
              >
                <span className={prod.rowChip}>T{n}</span>
                <span className={prod.rowBody}>
                  <span className={prod.rowTitle}>{productionTaskTitle(config.epreuve, n)}</span>
                  <span className={prod.rowSub}>{productionTaskSubtitle(config.epreuve, n)}</span>
                </span>
                {note != null ? (
                  <span
                    className={prod.rowScore}
                    style={{background: "var(--color-blue-soft)", color: "var(--color-blue)"}}
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
              <SectionLink label="Tout voir" onClick={() => router.push(`${config.base}/historique`)} />
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
                epreuve={config.epreuve}
                onClick={() => router.push(`${config.base}/resultats/${s.id}`)}
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
