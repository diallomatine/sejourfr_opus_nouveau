"use client";

import {useRouter} from "next/navigation";
import {useEffect, useState} from "react";
import {ChevronRight, Clock, FileStack, Lock, Sparkles} from "lucide-react";
import {ApiException, productionApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {canAccessModule, type ProductionSubmissionDto, resolveTcfLevel} from "@/lib/types";
import {DualChromeShell} from "@/app/_components/DualChromeShell";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {ModuleDetailGate, moduleDetailStyles as ds} from "@/app/_components/module_detail/parts";
import {HubDetailHeader, SectionLabel} from "@/app/_components/hub/HubParts";
import {type ProductionConfig} from "./config";
import hub from "@/app/_components/hub/hub.module.css";
import prod from "./production.module.css";

interface PastSession {
  attemptId: string;
  count: number;
  date: string;
}

/**
 * Entrée de l'examen blanc d'une épreuve productive (3 tâches enchaînées,
 * évaluation IA + CECRL plancher). Réservé aux abonnés Intégral : une session =
 * 3 soumissions, au-delà du quota gratuit (2 essais) → paywall à l'entrée.
 */
export function ProductionExams({config}: {config: ProductionConfig}) {
  const router = useRouter();
  const {user, status} = useAuth();
  const isPremium = user ? canAccessModule(user, "TCF") : false;
  const level = resolveTcfLevel(user);

  const [past, setPast] = useState<PastSession[]>([]);
  const [loading, setLoading] = useState(true);
  const [starting, setStarting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [paywallOpen, setPaywallOpen] = useState(false);

  useEffect(() => {
    if (status !== "authenticated") return;
    let cancelled = false;
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setLoading(true);
    productionApi
      .listMine({epreuve: config.epreuve, limit: 100})
      .then((list) => {
        if (cancelled) return;
        const byAttempt = new Map<string, ProductionSubmissionDto[]>();
        for (const s of list) {
          const arr = byAttempt.get(s.attemptId) ?? [];
          arr.push(s);
          byAttempt.set(s.attemptId, arr);
        }
        const sessions: PastSession[] = [];
        for (const [attemptId, items] of byAttempt) {
          if (items.length >= 2) {
            const date = items.map((i) => i.submittedAt).sort((a, b) => b.localeCompare(a))[0];
            sessions.push({attemptId, count: items.length, date});
          }
        }
        sessions.sort((a, b) => b.date.localeCompare(a.date));
        setPast(sessions);
      })
      .catch(() => undefined)
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [status, config.epreuve]);

  async function start() {
    if (starting) return;
    if (!isPremium) {
      setPaywallOpen(true);
      return;
    }
    setError(null);
    setStarting(true);
    try {
      const attempt = await productionApi.startAttempt({module: "TCF", epreuve: config.epreuve});
      router.push(`${config.base}/session/${attempt.id}`);
    } catch (e) {
      if (e instanceof ApiException && e.status === 403) setPaywallOpen(true);
      else setError(e instanceof ApiException ? e.message : "Impossible de démarrer l'examen.");
      setStarting(false);
    }
  }

  if (status === "loading") return <div className={ds.gate} />;
  if (!user) return <ModuleDetailGate next={`${config.base}/examens`} />;

  const btnClass = config.accent === "red" ? "btn btn-red btn-lg" : "btn btn-blue btn-lg";

  return (
    <DualChromeShell>
      <main className={hub.hub}>
        <HubDetailHeader
          backHref={config.base}
          title={`Examen blanc · ${config.label}`}
          subtitle={`3 tâches enchaînées · niveau ${level} · évaluation IA`}
        />

        {error && <div className={prod.error}>{error}</div>}

        <div className={prod.card}>
          <p className={prod.cardLabel}>Format de l&apos;examen</p>
          <p className={prod.consigne} style={{fontSize: 14}}>
            {config.examIntro}
          </p>
          <div className={prod.metaRow}>
            <span className={prod.metaChip}>
              <FileStack size={13} strokeWidth={2} />3 tâches
            </span>
            <span className={prod.metaChip}>
              <Clock size={13} strokeWidth={2} />
              {config.examMinutes}
            </span>
            <span className={prod.metaChip}>
              <Sparkles size={13} strokeWidth={2} />Note /20 + CECRL
            </span>
          </div>
          <div className={prod.actions} style={{justifyContent: "flex-start", marginTop: 16}}>
            <button type="button" className={btnClass} disabled={starting} onClick={start}>
              {!isPremium && <Lock size={15} strokeWidth={2.4} style={{marginRight: 6}} />}
              {starting
                ? "Préparation…"
                : isPremium
                  ? "Commencer l'examen blanc"
                  : "Débloquer l'examen blanc"}
            </button>
          </div>
          {!isPremium && (
            <p className={prod.draftNote} style={{marginTop: 10}}>
              L&apos;examen blanc complet est réservé aux abonnés Intégral. Vous pouvez tester
              gratuitement via « S&apos;entraîner par tâche » (2 essais offerts).
            </p>
          )}
        </div>

        {!loading && past.length > 0 && (
          <>
            <SectionLabel label="Sessions passées" />
            <div className={hub.list}>
              {past.map((s) => (
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
                      {s.count} tâche{s.count > 1 ? "s" : ""} · {formatDay(s.date)}
                    </span>
                  </span>
                  <ChevronRight size={20} className={prod.rowChevron} />
                </button>
              ))}
            </div>
          </>
        )}

        <PaywallSheet
          open={paywallOpen}
          onClose={() => setPaywallOpen(false)}
          module="INTEGRAL"
          title={`Débloquez l'examen blanc ${config.shortLabel}`}
          message="L'examen blanc complet (3 tâches + évaluation IA) est réservé aux abonnés Intégral, qui débloque aussi tout le TCF, le civique et les examens blancs illimités."
        />
      </main>
    </DualChromeShell>
  );
}

function formatDay(iso: string): string {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "—";
  return d.toLocaleDateString("fr-FR", {day: "2-digit", month: "short", year: "numeric"});
}
