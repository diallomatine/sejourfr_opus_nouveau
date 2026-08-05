"use client";

import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { Check, Lock, Mic, PenLine, Play, RotateCcw, Target } from "lucide-react";
import { ApiException, productionApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import { tcfNoteTone, type TcfNoteTone } from "@/lib/production-feedback";
import {
  canAccessModule,
  formatNoteSur20,
  productionTaskSubtitle,
  productionTaskTitle,
  type ProductionExampleDto,
  type ProductionSubmissionDto,
  type ProductionTaskDto,
} from "@/lib/types";
import { DualChromeShell } from "@/app/_components/DualChromeShell";
import { ModuleDetailGate, moduleDetailStyles as ds } from "@/app/_components/module_detail/parts";
import { PaywallSheet } from "@/app/_components/PaywallSheet";
import { DetailShell } from "@/app/_components/hub/DetailParts";
import { type ProductionConfig } from "./config";
import detail from "@/app/_components/hub/detail.module.css";
import prod from "./production.module.css";

type Tab = "sujets" | "exemples";
type SubjectFilter = "all" | "todo" | "done";

/** Un sujet fait se teinte par son PALIER TCF (cf. `tcfNoteTone`) : la note
 *  n'est pas une note scolaire sur 20, et aucun palier ne se peint en rouge.
 *  `neutral` = fait mais pas encore évalué → le traitement « terminé ». */
const NUM_TONE_CLASS: Record<TcfNoteTone, string> = {
  neutral: detail.serieNumDone,
  amber: detail.serieNumAmber,
  blue: detail.serieNumBlue,
  green: detail.serieNumDone,
};

const BADGE_TONE_CLASS: Record<TcfNoteTone, string> = {
  neutral: detail.serieBadgeDone,
  amber: detail.serieBadgeAmber,
  blue: detail.serieBadgeBlue,
  green: detail.serieBadgeDone,
};

/**
 * Une tâche productive (T1/T2/T3) — maquette sejour_fr.html : onglet
 * « Sujets » (cards par niveau cible → écran d'input) + onglet « Exemples »
 * (réponses-modèles, lecteur audio pour l'EO).
 */
export function ProductionSubjects({ config }: { config: ProductionConfig }) {
  const params = useParams<{ n: string }>();
  const n = Number(params?.n ?? "0");
  const valid = n >= 1 && n <= 3;
  const router = useRouter();
  const { user, status } = useAuth();

  const [tab, setTab] = useState<Tab>("sujets");
  const [filter, setFilter] = useState<SubjectFilter>("all");
  const [tasks, setTasks] = useState<ProductionTaskDto[]>([]);
  // Dernière soumission par sujet (productionTaskId) → distinction fait/à faire.
  const [doneByTask, setDoneByTask] = useState<Record<string, ProductionSubmissionDto>>({});
  const [examples, setExamples] = useState<ProductionExampleDto[]>([]);
  const [loading, setLoading] = useState(true);
  const [examplesLoaded, setExamplesLoaded] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [paywallOpen, setPaywallOpen] = useState(false);

  // EE/EO sont des épreuves TCF → accès gouverné par l'abonnement Intégral.
  // Non-abonné : seuls le 1er sujet + le 1er exemple sont ouverts, le reste est
  // cadenassé (parité avec les séries CO/CE/Structure et l'app mobile).
  const isPremium = user ? canAccessModule(user, "TCF") : false;

  useEffect(() => {
    if (status !== "authenticated" || !valid) return;
    let cancelled = false;
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setLoading(true);
    productionApi
      .listTasks({ epreuve: config.epreuve, tacheNumero: n })
      .then((list) => {
        if (!cancelled) {
          // Filtre défensif : certains backends ignorent `tacheNumero` sans niveau.
          setTasks(
            list
              .filter((t) => t.tacheNumero === n)
              .sort((a, b) => a.niveauCible.localeCompare(b.niveauCible)),
          );
        }
      })
      .catch((e) => {
        if (!cancelled)
          setError(e instanceof ApiException ? e.message : "Impossible de charger les sujets.");
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [status, valid, n, config.epreuve]);

  useEffect(() => {
    if (status !== "authenticated" || !valid) return;
    let cancelled = false;
    productionApi
      .listMine({ epreuve: config.epreuve })
      .then((subs) => {
        if (cancelled) return;
        // On garde la soumission la plus récente par sujet (submittedAt desc).
        const map: Record<string, ProductionSubmissionDto> = {};
        for (const s of subs) {
          const prev = map[s.productionTaskId];
          if (!prev || s.submittedAt > prev.submittedAt) map[s.productionTaskId] = s;
        }
        setDoneByTask(map);
      })
      .catch(() => undefined);
    return () => {
      cancelled = true;
    };
  }, [status, valid, config.epreuve]);

  useEffect(() => {
    if (tab !== "exemples" || examplesLoaded || !valid) return;
    let cancelled = false;
    productionApi
      .listExamples(config.epreuve, n)
      .then((list) => {
        if (!cancelled) setExamples(list);
      })
      .catch(() => undefined)
      .finally(() => {
        if (!cancelled) setExamplesLoaded(true);
      });
    return () => {
      cancelled = true;
    };
  }, [tab, examplesLoaded, valid, n, config.epreuve]);

  if (status === "loading") return <div className={ds.gate} />;
  if (!user) return <ModuleDetailGate next={`${config.base}/tache/${n}`} />;
  if (!valid) {
    return (
      <DualChromeShell>
        <main className={detail.wrap}>
          <p className={detail.empty}>Tâche inconnue.</p>
          <Link href={config.base} className={detail.back}>
            ← Retour à l&apos;épreuve
          </Link>
        </main>
      </DualChromeShell>
    );
  }

  return (
    <DualChromeShell>
      <DetailShell
        backHref={config.base}
        backLabel={config.label}
        eyebrowIcon={
          config.mode === "audio" ? (
            <Mic size={18} strokeWidth={2} />
          ) : (
            <PenLine size={18} strokeWidth={2} />
          )
        }
        eyebrow={`${config.label} · Tâche ${n}`}
        title={productionTaskTitle(config.epreuve, n)}
        subtitle={productionTaskSubtitle(config.epreuve, n)}
        action={
          <Link href={`${config.base}/examens`} className={detail.headBtn}>
            <Target size={17} strokeWidth={1.7} aria-hidden />
            Examens blancs
          </Link>
        }
      >
        <div className={detail.tabs} role="tablist">
          <button
            type="button"
            role="tab"
            aria-selected={tab === "sujets"}
            className={`${detail.tab} ${tab === "sujets" ? detail.tabActive : ""}`}
            onClick={() => setTab("sujets")}
          >
            Sujets
          </button>
          <button
            type="button"
            role="tab"
            aria-selected={tab === "exemples"}
            className={`${detail.tab} ${tab === "exemples" ? detail.tabActive : ""}`}
            onClick={() => setTab("exemples")}
          >
            Exemples
          </button>
        </div>

        {error && <div className={detail.error}>{error}</div>}

        {tab === "sujets" ? (
          loading ? (
            <div className={detail.loading}>Chargement des sujets…</div>
          ) : tasks.length === 0 ? (
            <p className={detail.empty}>Aucun sujet disponible pour cette tâche.</p>
          ) : (
            (() => {
              // Index d'origine conservé pour le verrou freemium (1er sujet
              // offert) + filtre Tout / À faire / Fait.
              const rows = tasks.map((t, i) => ({ task: t, index: i, sub: doneByTask[t.id] }));
              const doneCount = rows.filter((r) => r.sub).length;
              const todoCount = rows.length - doneCount;
              const shown = rows.filter((r) =>
                filter === "all" ? true : filter === "done" ? !!r.sub : !r.sub,
              );
              const chips: [SubjectFilter, string, number][] = [
                ["all", "Tout", rows.length],
                ["todo", "À faire", todoCount],
                ["done", "Fait", doneCount],
              ];
              return (
                <>
                  <div className={detail.filterRow} role="tablist">
                    {chips.map(([key, label, count]) => (
                      <button
                        key={key}
                        type="button"
                        role="tab"
                        aria-selected={filter === key}
                        className={`${detail.filterChip} ${filter === key ? detail.filterChipOn : ""}`}
                        onClick={() => setFilter(key)}
                      >
                        {label} <span className={detail.filterCount}>{count}</span>
                      </button>
                    ))}
                  </div>
                  {shown.length === 0 ? (
                    <p className={detail.empty}>
                      {filter === "done"
                        ? "Aucun sujet terminé pour l'instant."
                        : "Tous les sujets sont terminés. Bravo !"}
                    </p>
                  ) : (
                    <div className={detail.serieGrid}>
                      {shown.map(({ task: t, index: i, sub }) => {
                        const locked = !isPremium && i > 0;
                        const done = !!sub;
                        const note = sub?.evaluation?.noteSurVingt ?? null;
                        // Palier TCF, pas seuil « sur 20 » : 12/20 est un B2, le
                        // niveau le plus haut de l'examen. « neutral » tant que
                        // la production n'est pas évaluée → traitée comme
                        // terminée, jamais comme un échec.
                        const tone = tcfNoteTone(note);
                        const accentNum =
                          config.mode === "audio" ? detail.serieNumRed : detail.serieNumBlue;
                        const numClass = locked ? "" : done ? NUM_TONE_CLASS[tone] : accentNum;
                        return (
                          <button
                            key={t.id}
                            type="button"
                            className={detail.serieCard}
                            onClick={() =>
                              locked
                                ? setPaywallOpen(true)
                                : router.push(`${config.base}/${config.inputSegment}/${t.id}`)
                            }
                          >
                            <span className={`${detail.serieNum} ${numClass}`}>
                              {locked ? (
                                <Lock size={18} aria-hidden />
                              ) : done ? (
                                <Check size={20} strokeWidth={2.4} aria-hidden />
                              ) : config.mode === "audio" ? (
                                <Mic size={18} aria-hidden />
                              ) : (
                                <PenLine size={18} aria-hidden />
                              )}
                            </span>
                            <span className={detail.serieBody}>
                              <span className={detail.serieTitle}>Sujet {i + 1}</span>
                              <span className={detail.serieSub}>{t.consigne}</span>
                              {done ? (
                                <span
                                  className={`${detail.serieBadge} ${BADGE_TONE_CLASS[tone]}`}
                                >
                                  <Check size={12} aria-hidden />{" "}
                                  {note != null ? `${formatNoteSur20(note)}/20` : "Terminé"}
                                </span>
                              ) : locked ? (
                                <span className={`${detail.serieBadge} ${detail.serieBadgeLock}`}>
                                  <Lock size={11} aria-hidden /> Premium
                                </span>
                              ) : (
                                <span className={`${detail.serieBadge} ${detail.serieBadgeTodo}`}>
                                  À faire
                                </span>
                              )}
                            </span>
                            <span className={detail.serieAction} aria-hidden>
                              {locked ? (
                                <Lock size={17} />
                              ) : done ? (
                                <RotateCcw size={17} />
                              ) : (
                                <Play size={18} />
                              )}
                            </span>
                          </button>
                        );
                      })}
                    </div>
                  )}
                </>
              );
            })()
          )
        ) : !examplesLoaded ? (
          <div className={detail.loading}>Chargement des exemples…</div>
        ) : examples.length === 0 ? (
          <p className={detail.empty}>
            Aucun exemple-modèle pour cette tâche pour l&apos;instant.
          </p>
        ) : (
          <div className={detail.exampleList}>
            {examples.map((ex, i) => (
              <ExampleCard
                key={ex.id}
                example={ex}
                hideText={config.mode === "audio"}
                locked={!isPremium && i > 0}
                onLocked={() => setPaywallOpen(true)}
              />
            ))}
          </div>
        )}
        <PaywallSheet
          open={paywallOpen}
          onClose={() => setPaywallOpen(false)}
          module="INTEGRAL"
          message="Le 1er sujet et le 1er exemple sont offerts pour découvrir l'épreuve. Passez à l'abonnement Intégral pour débloquer tous les sujets et exemples corrigés."
        />
      </DetailShell>
    </DualChromeShell>
  );
}

function ExampleCard({
  example: ex,
  hideText,
  locked,
  onLocked,
}: {
  example: ProductionExampleDto;
  hideText: boolean;
  locked: boolean;
  onLocked: () => void;
}) {
  // Exemple cadenassé (non-abonné, au-delà du 1er) : on masque audio + corrigé
  // et on n'expose qu'une barre verrouillée qui ouvre le paywall.
  if (locked) {
    return (
      <button type="button" className={prod.exampleLocked} onClick={onLocked}>
        <span className={prod.exampleLockedIcon} aria-hidden>
          <Lock size={16} />
        </span>
        <span className={prod.exampleLockedBody}>
          <span className={prod.exampleTitle}>{ex.titre}</span>
          <span className={prod.exampleLockedHint}>
            {hideText
              ? "Écoute réservée à l'abonnement Intégral"
              : "Corrigé réservé à l'abonnement Intégral"}
          </span>
        </span>
      </button>
    );
  }
  return (
    <div className={prod.example}>
      <h3 className={prod.exampleTitle}>{ex.titre}</h3>
      {ex.resume && <p className={prod.exampleResume}>{ex.resume}</p>}
      {ex.audioUrl && (
        <div className={prod.player} style={{ maxWidth: "none", marginBottom: 12 }}>
          <audio src={ex.audioUrl} controls preload="none" />
        </div>
      )}
      {!hideText && ex.contenu && <p className={prod.exampleBody}>{ex.contenu}</p>}
      {ex.planPoints.length > 0 && (
        <ol className={prod.planList}>
          {ex.planPoints.map((p, i) => (
            <li key={i} className={prod.planItem}>
              <span className={prod.planNum}>{i + 1}.</span>
              {p}
            </li>
          ))}
        </ol>
      )}
      {ex.explications && <p className={prod.exampleExpl}>{ex.explications}</p>}
    </div>
  );
}
