"use client";

import {useRouter} from "next/navigation";
import {useEffect, useMemo, useState} from "react";
import {FileStack} from "lucide-react";
import {productionApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {type ProductionSubmissionDto} from "@/lib/types";
import {DualChromeShell} from "@/app/_components/DualChromeShell";
import {ModuleDetailGate, moduleDetailStyles as ds} from "@/app/_components/module_detail/parts";
import {
  SectionHead,
  SkillBadge,
  SkillHero,
  SkillRowCard,
  SkillShell,
} from "@/app/_components/skill-ui/SkillLayout";
import s from "@/app/_components/skill-ui/skill.module.css";
import {SubmissionRow} from "./SubmissionRow";
import {type ProductionConfig, TCF_HUB_HREF, TCF_HUB_LABEL} from "./config";

interface Session {
  attemptId: string;
  items: ProductionSubmissionDto[];
  date: string;
}

/**
 * Historique d'une épreuve productive : sessions d'examen blanc (≥ 2 tâches
 * partageant un attempt) et entraînements libres (1 tâche). Mêmes cartes et
 * mêmes badges que le reste du parcours — un historique qui ne ressemble pas
 * aux écrans dont il vient n'aide pas à s'y retrouver.
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
    for (const sub of subs) {
      const arr = byAttempt.get(sub.attemptId) ?? [];
      arr.push(sub);
      byAttempt.set(sub.attemptId, arr);
    }
    const found: Session[] = [];
    const alone: ProductionSubmissionDto[] = [];
    for (const [attemptId, items] of byAttempt) {
      if (items.length >= 2) {
        const date = items.map((i) => i.submittedAt).sort((a, b) => b.localeCompare(a))[0];
        found.push({attemptId, items, date});
      } else {
        alone.push(items[0]);
      }
    }
    found.sort((a, b) => b.date.localeCompare(a.date));
    alone.sort((a, b) => b.submittedAt.localeCompare(a.submittedAt));
    return {sessions: found, singles: alone};
  }, [subs]);

  if (status === "loading") return <div className={ds.gate} />;
  if (!user) return <ModuleDetailGate next={`${config.base}/historique`} />;

  const empty = !loading && sessions.length === 0 && singles.length === 0;
  const total = sessions.length + singles.length;

  return (
    <DualChromeShell>
      <SkillShell config={config} backHref={TCF_HUB_HREF} backLabel={TCF_HUB_LABEL}>
        <SkillHero
          eyebrow={`${config.label} · Historique`}
          title="Vos productions"
          text="Examens blancs et entraînements libres, du plus récent au plus ancien."
          level={null}
          attempted={total}
          total={0}
          percent={0}
        />

        {loading ? (
          <p className={s.empty}>Chargement…</p>
        ) : empty ? (
          <p className={s.empty}>Aucune production pour l&apos;instant.</p>
        ) : (
          <>
            {sessions.length > 0 && (
              <>
                <SectionHead
                  title="Examens blancs"
                  text="Trois tâches enchaînées, avec un niveau global."
                />
                <div className={s.list}>
                  {sessions.map((sess) => (
                    <SkillRowCard
                      key={sess.attemptId}
                      tile={<FileStack size={20} strokeWidth={2.2} aria-hidden />}
                      title={`Examen blanc ${config.shortLabel}`}
                      text={formatDay(sess.date)}
                      meta={
                        <SkillBadge tone="treated">
                          {sess.items.length} tâche{sess.items.length > 1 ? "s" : ""}
                        </SkillBadge>
                      }
                      onClick={() =>
                        router.push(`${config.base}/session/${sess.attemptId}`)
                      }
                    />
                  ))}
                </div>
              </>
            )}

            {singles.length > 0 && (
              <>
                <SectionHead
                  title="Entraînements libres"
                  text="Une tâche à la fois, hors conditions d'examen."
                />
                <div className={s.list}>
                  {singles.map((sub) => (
                    <SubmissionRow
                      key={sub.id}
                      submission={sub}
                      epreuve={config.epreuve}
                      onClick={() =>
                        router.push(
                          `${config.base}/resultats/${sub.id}?back=${encodeURIComponent(
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
      </SkillShell>
    </DualChromeShell>
  );
}

function formatDay(iso: string): string {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "—";
  return d.toLocaleDateString("fr-FR", {day: "2-digit", month: "short", year: "numeric"});
}
