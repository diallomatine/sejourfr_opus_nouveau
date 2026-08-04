"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useMemo, useState } from "react";
import { Mic, PenLine, Target } from "lucide-react";
import { productionApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import {
  canAccessModule,
  formatNoteSur20,
  productionTaskSubtitle,
  productionTaskTitle,
  type ProductionSubmissionDto,
  resolveTcfLevel,
} from "@/lib/types";
import { DualChromeShell } from "@/app/_components/DualChromeShell";
import { ModuleDetailGate, moduleDetailStyles as ds } from "@/app/_components/module_detail/parts";
import { DetailShell, LevelChoiceCard } from "@/app/_components/hub/DetailParts";
import { ConfirmSheet } from "@/app/_components/hub/ConfirmSheet";
import { type ProductionConfig } from "./config";
import detail from "@/app/_components/hub/detail.module.css";
import hub from "@/app/_components/hub/hub.module.css";
import { SubmissionRow } from "./SubmissionRow";

const TASKS = [1, 2, 3] as const;

/** Tonalité par tâche : la difficulté monte, la couleur chauffe. */
const TASK_TONES = { 1: "blue", 2: "amber", 3: "red" } as const;

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
  const [quotaInfoOpen, setQuotaInfoOpen] = useState(false);

  // Info one-time pour les comptes gratuits : 1 essai d'entraînement offert
  // par épreuve (EE et EO), évalué par l'IA. Mémorisée en localStorage.
  const quotaInfoKey = `sejourfr.prodQuotaInfo.${config.epreuve}`;
  useEffect(() => {
    if (status !== "authenticated" || !user || canAccessModule(user, "TCF")) return;
    if (typeof window === "undefined") return;
    if (window.localStorage.getItem(quotaInfoKey)) return;
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setQuotaInfoOpen(true);
  }, [status, user, quotaInfoKey]);

  function dismissQuotaInfo() {
    setQuotaInfoOpen(false);
    try {
      window.localStorage.setItem(quotaInfoKey, "1");
    } catch {
      // stockage indisponible (navigation privée) : la modale reviendra.
    }
  }

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

  /**
   * Dernière note connue par tâche. `lastPerTask` est borné au niveau visé par
   * le candidat : quand il a travaillé la tâche à un autre niveau, la réponse
   * est vide et la card annonçait « Pas encore travaillée » juste au-dessus
   * d'un historique qui affiche ses notes sur cette même tâche. On repart donc
   * de l'historique (déjà chargé, trié du plus récent au plus ancien) et on ne
   * garde `lastPerTask` que pour les tâches sorties de la fenêtre d'historique.
   */
  const lastNoteByTask = useMemo(() => {
    const m = new Map<number, number>();
    const seen = new Set<number>();
    for (const [n, s] of lastPerTask) {
      const note = s.evaluation?.noteSurVingt;
      if (note != null) m.set(n, note);
    }
    // `history` est trié du plus récent au plus ancien : la première occurrence
    // d'une tâche est sa dernière note, tous niveaux confondus.
    for (const s of history) {
      const n = s.tacheNumero;
      const note = s.evaluation?.noteSurVingt;
      if (n == null || note == null || seen.has(n)) continue;
      seen.add(n);
      m.set(n, note);
    }
    return m;
  }, [history, lastPerTask]);

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
            const note = lastNoteByTask.get(n) ?? null;
            return (
              <LevelChoiceCard
                key={n}
                chip={`T${n}`}
                chipTone={TASK_TONES[n]}
                title={productionTaskTitle(config.epreuve, n)}
                desc={productionTaskSubtitle(config.epreuve, n)}
                percent={note != null ? Math.round(note * 5) : null}
                footLabel={
                  note != null
                    ? `Dernière note ${formatNoteSur20(note)}/20`
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

        <ConfirmSheet
          open={quotaInfoOpen}
          tone="info"
          title="Un essai gratuit par épreuve"
          message={`Vous disposez d'un essai d'entraînement gratuit en ${config.shortLabel}, évalué par l'IA (note /20 + niveau CECRL), ainsi qu'un examen blanc complet offert. Pour vous entraîner sans limite, passez à l'abonnement Intégral.`}
          onClose={dismissQuotaInfo}
        />
      </DetailShell>
    </DualChromeShell>
  );
}

