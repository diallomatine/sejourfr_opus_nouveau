"use client";

import {useRouter} from "next/navigation";
import {useEffect, useMemo, useState} from "react";
import {ChevronRight, FileStack} from "lucide-react";
import {productionApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {type ProductionSubmissionDto} from "@/lib/types";
import {DualChromeShell} from "@/app/_components/DualChromeShell";
import {ModuleDetailGate, moduleDetailStyles as ds} from "@/app/_components/module_detail/parts";
import {HubDetailHeader, SectionLabel} from "@/app/_components/hub/HubParts";
import {SubmissionRow} from "./SubmissionRow";
import {type ProductionConfig} from "./config";
import hub from "@/app/_components/hub/hub.module.css";
import prod from "./production.module.css";

interface Session {
  attemptId: string;
  items: ProductionSubmissionDto[];
  date: string;
}

/**
 * Historique d'une épreuve productive : sessions d'examen blanc (≥ 2 tâches
 * partageant un attempt) et entraînements libres (1 tâche).
 */
export function ProductionHistory({config}: {config: ProductionConfig}) {
  const router = useRouter();
  const {user, status} = useAuth();

  const [subs, setSubs] = useState<ProductionSubmissionDto[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (status !== "authenticated") return;
    let cancelled = false;
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setLoading(true);
    productionApi
      .listMine({epreuve: config.epreuve, limit: 100})
      .then((list) => {
        if (!cancelled) setSubs(list);
      })
      .catch(() => undefined)
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [status, config.epreuve]);

  const {sessions, singles} = useMemo(() => {
    const byAttempt = new Map<string, ProductionSubmissionDto[]>();
    for (const s of subs) {
      const arr = byAttempt.get(s.attemptId) ?? [];
      arr.push(s);
      byAttempt.set(s.attemptId, arr);
    }
    const sessions: Session[] = [];
    const singles: ProductionSubmissionDto[] = [];
    for (const [attemptId, items] of byAttempt) {
      if (items.length >= 2) {
        const date = items.map((i) => i.submittedAt).sort((a, b) => b.localeCompare(a))[0];
        sessions.push({attemptId, items, date});
      } else {
        singles.push(items[0]);
      }
    }
    sessions.sort((a, b) => b.date.localeCompare(a.date));
    singles.sort((a, b) => b.submittedAt.localeCompare(a.submittedAt));
    return {sessions, singles};
  }, [subs]);

  if (status === "loading") return <div className={ds.gate} />;
  if (!user) return <ModuleDetailGate next={`${config.base}/historique`} />;

  const empty = !loading && sessions.length === 0 && singles.length === 0;

  return (
    <DualChromeShell>
      <main className={hub.hub}>
        <HubDetailHeader
          backHref={config.base}
          title="Historique"
          subtitle={`${config.label} · examens et entraînements`}
        />

        {loading ? (
          <p className={prod.loading}>Chargement…</p>
        ) : empty ? (
          <p className={prod.empty}>Aucune production pour l&apos;instant.</p>
        ) : (
          <>
            {sessions.length > 0 && (
              <>
                <SectionLabel label="Examens blancs" />
                <div className={hub.list}>
                  {sessions.map((s) => (
                    <button
                      key={s.attemptId}
                      type="button"
                      className={prod.row}
                      onClick={() => router.push(`${config.base}/session/${s.attemptId}`)}
                    >
                      <span className={prod.rowChip}>
                        <FileStack size={14} strokeWidth={2.2} />
                      </span>
                      <span className={prod.rowBody}>
                        <span className={prod.rowTitle}>Examen blanc {config.shortLabel}</span>
                        <span className={prod.rowSub}>
                          {s.items.length} tâche{s.items.length > 1 ? "s" : ""} · {formatDay(s.date)}
                        </span>
                      </span>
                      <ChevronRight size={20} className={prod.rowChevron} />
                    </button>
                  ))}
                </div>
              </>
            )}

            {singles.length > 0 && (
              <>
                <SectionLabel label="Entraînements libres" />
                <div className={hub.list}>
                  {singles.map((s) => (
                    <SubmissionRow
                      key={s.id}
                      submission={s}
                      epreuve={config.epreuve}
                      onClick={() =>
                        router.push(
                          `${config.base}/resultats/${s.id}?back=${encodeURIComponent(
                            `${config.base}/historique`,
                          )}`,
                        )
                      }
                    />
                  ))}
                </div>
              </>
            )}
          </>
        )}
      </main>
    </DualChromeShell>
  );
}

function formatDay(iso: string): string {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "—";
  return d.toLocaleDateString("fr-FR", {day: "2-digit", month: "short", year: "numeric"});
}
