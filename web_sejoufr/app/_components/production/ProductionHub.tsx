"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useMemo, useState } from "react";
import { Mic, PenLine, Target } from "lucide-react";
import { productionApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import {
  productionTaskSubtitle,
  productionTaskTitle,
  type ProductionSubmissionDto,
  resolveTcfLevel,
} from "@/lib/types";
import { DualChromeShell } from "@/app/_components/DualChromeShell";
import { ModuleDetailGate, moduleDetailStyles as ds } from "@/app/_components/module_detail/parts";
import { DetailShell, LevelChoiceCard } from "@/app/_components/hub/DetailParts";
import { type ProductionConfig } from "./config";
import detail from "@/app/_components/hub/detail.module.css";
import hub from "@/app/_components/hub/hub.module.css";
import { SubmissionRow } from "./SubmissionRow";

const TASKS = [1, 2, 3] as const;

/**
 * Page d'entraînement d'une épreuve productive (EE/EO), maquette
 * sejour_fr.html : « Choisissez votre tâche » — 3 cards T1/T2/T3 (donut =
 * dernière note /20 ramenée sur 100) + historique récent. Les examens blancs
 * vivent sur la page dédiée (bouton en header), comme pour CO/CE.
 */
export function ProductionHub({ config }: { config: ProductionConfig }) {
  const router = useRouter();
  const { user, status } = useAuth();
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
      productionApi.listMine({ epreuve: config.epreuve, limit: 20 }),
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
      <DetailShell
        backHref="/entrainement?module=TCF"
        backLabel="TCF IRN"
        eyebrowIcon={
          config.mode === "audio" ? (
            <Mic size={18} strokeWidth={2} />
          ) : (
            <PenLine size={18} strokeWidth={2} />
          )
        }
        eyebrow={config.label}
        title="Choisissez votre tâche"
        subtitle={`Trois tâches progressives, ${
          config.mode === "audio" ? "enregistrées au micro" : "rédigées en ligne"
        } et évaluées par l'IA avec une note /20 et un niveau CECRL. Commencez par la tâche 1, puis montez en exigence.`}
        action={
          <Link href={`${config.base}/examens`} className={detail.headBtn}>
            <Target size={17} strokeWidth={1.7} aria-hidden />
            Examens blancs
          </Link>
        }
      >
        <div className={detail.levelGrid}>
          {TASKS.map((n) => {
            const note = lastPerTask.get(n)?.evaluation?.noteSurVingt ?? null;
            return (
              <LevelChoiceCard
                key={n}
                chip={`T${n}`}
                title={productionTaskTitle(config.epreuve, n)}
                desc={productionTaskSubtitle(config.epreuve, n)}
                percent={note != null ? Math.round(note * 5) : null}
                footLabel={
                  note != null
                    ? `Dernière note ${formatNote(note)}/20`
                    : "Pas encore travaillée"
                }
                onClick={() => router.push(`${config.base}/tache/${n}`)}
              />
            );
          })}
        </div>

        <section className={detail.historyCard}>
          <header className={detail.historyHead}>
            <h2>Historique</h2>
            {history.length > 0 && (
              <Link href={`${config.base}/historique`} className={detail.historyLink}>
                Tout voir →
              </Link>
            )}
          </header>
          {loading ? (
            <p className={detail.historyEmpty}>Chargement…</p>
          ) : recent.length === 0 ? (
            <p className={detail.historyEmpty}>
              Aucune production pour l&apos;instant. Lancez une tâche pour recevoir un
              feedback IA.
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
        </section>
      </DetailShell>
    </DualChromeShell>
  );
}

function formatNote(n: number): string {
  return Number.isInteger(n) ? String(n) : n.toFixed(1).replace(".", ",");
}
