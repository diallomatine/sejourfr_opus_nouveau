"use client";

import Link from "next/link";
import {useRouter} from "next/navigation";
import {useEffect, useMemo, useState} from "react";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {ApiException, attemptApi, statsApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {
  type AttemptSummaryResponse,
  canAccessModule,
  type Module as ModuleEnum,
  type ThemeStatsResponse,
  type UserStatsResponse,
} from "@/lib/types";

export default function StatistiquesPage() {
    const router = useRouter();
    const {user, status} = useAuth();
    const [module, setModule] = useState<ModuleEnum>("CIVIQUE");

    const [stats, setStats] = useState<UserStatsResponse | null>(null);
    const [attempts, setAttempts] = useState<AttemptSummaryResponse[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);

    const [starting, setStarting] = useState<string | null>(null);
    const [paywallOpen, setPaywallOpen] = useState(false);

    const isPremiumForModule = user !== null && canAccessModule(user, module);
    const upsellModule: "CIVIQUE" | "INTEGRAL" = module === "TCF" ? "INTEGRAL" : "CIVIQUE";

    useEffect(() => {
        if (status !== "authenticated") return;
        let cancelled = false;
        // eslint-disable-next-line react-hooks/set-state-in-effect
        setLoading(true);
        Promise.all([
            statsApi.get(module).catch((e: unknown) => {
                if (e instanceof ApiException) throw e;
                throw new Error("Statistiques indisponibles.");
            }),
            attemptApi
                .listMine({module, limit: 100})
                .catch((): AttemptSummaryResponse[] => []),
        ])
            .then(([s, atts]) => {
                if (cancelled) return;
                setStats(s);
                setAttempts(atts);
                setError(null);
                setLoading(false);
            })
            .catch((e: Error) => {
                if (cancelled) return;
                setStats(null);
                setError(e.message);
                setLoading(false);
            });
        return () => {
            cancelled = true;
        };
    }, [module, status]);

    // ========== KPIs ==========
    const streak = useMemo(() => computeStreak(attempts), [attempts]);
    // Score global = maîtrise sur tout le module : questions distinctes réussies
    // / total des questions actives. Cohérent avec la maîtrise par thème ; un
    // seul examen blanc à 90% ne donne plus 90% global mais la part réelle du
    // pool qu'on a verrouillée.
    const globalMastery = useMemo(() => {
        if (!stats) return {pct: 0, correct: 0, total: 0};
        const correct = stats.byTheme.reduce((s, t) => s + t.correct, 0);
        const total = stats.byTheme.reduce((s, t) => s + t.total, 0);
        return {
            pct: total === 0 ? 0 : Math.round((correct / total) * 100),
            correct,
            total,
        };
    }, [stats]);

    const totalWrong = useMemo(() => {
        if (!stats) return 0;
        return stats.byTheme.reduce(
            (sum, t) => sum + Math.max(0, t.answered - t.correct),
            0,
        );
    }, [stats]);

    // ========== Themes sorted weak-first ==========
    // On classe par score de maîtrise croissant : un thème jamais touché ou plein
    // d'erreurs remonte en premier, c'est ce que l'utilisateur doit retravailler.
    const sortedThemes = useMemo(() => {
        if (!stats) return [];
        const started = stats.byTheme.filter((t) => t.answered > 0);
        const notStarted = stats.byTheme.filter((t) => t.answered === 0);
        started.sort((a, b) => mastery(a) - mastery(b));
        notStarted.sort((a, b) => b.total - a.total);
        return [...started, ...notStarted];
    }, [stats]);

    const weakest = useMemo(
        () =>
            sortedThemes
                .filter((t) => t.answered > 0)
                .slice(0, 4),
        [sortedThemes],
    );

    const errorDistribution = useMemo(() => {
        if (!stats || totalWrong === 0) return [];
        const items = stats.byTheme
            .map((t) => ({
                themeId: t.themeId,
                themeName: t.themeName,
                wrong: Math.max(0, t.answered - t.correct),
            }))
            .filter((x) => x.wrong > 0)
            .sort((a, b) => b.wrong - a.wrong);
        const top = items.slice(0, 3);
        const rest = items.slice(3);
        const result = top.map((it) => ({
            ...it,
            pct: Math.round((it.wrong / totalWrong) * 100),
        }));
        if (rest.length > 0) {
            const restWrong = rest.reduce((sum, r) => sum + r.wrong, 0);
            result.push({
                themeId: "__rest",
                themeName: "Autres",
                wrong: restWrong,
                pct: Math.round((restWrong / totalWrong) * 100),
            });
        }
        return result;
    }, [stats, totalWrong]);

    async function startThemeTraining(themeId: string) {
        if (!isPremiumForModule) {
            setPaywallOpen(true);
            return;
        }
        setStarting(themeId);
        try {
            const a = await attemptApi.start({
                type: "TRAINING",
                module,
                themeId,
                size: 30,
            });
            router.push(`/sessions/${a.id}`);
        } catch {
            setStarting(null);
        }
    }

    if (status === "loading") return <StatsSkeleton/>;
    if (!user) {
        return (
            <main className="st-gate">
                <p>Connectez-vous pour voir vos statistiques.</p>
                <Link href="/connexion?next=/statistiques" className="st-gate-cta">
                    Se connecter →
                </Link>
                <style>{gateStyles}</style>
            </main>
        );
    }

    const isEmpty = !loading && stats !== null && stats.questionsAnswered === 0;

    return (
        <main className="st">
            {/* ============ TOPBAR ============ */}
            <header className="st-hero">
                <div className="st-hero-main">
                    <div className="breadcrumb">
                        ACCUEIL <span className="sep">/</span> PROGRESSION
                    </div>
                    <h1>
                        Ma <em>progression</em>
                    </h1>
                    <p>
                        Suis ton évolution : maîtrise par thème, points faibles et
                        erreurs à retravailler, sur l&apos;examen civique et le TCF.
                    </p>
                    <div className="st-hero-actions">
                        <Link href="/examens-blancs" className="st-hero-btn">
                            Lancer un examen blanc
                        </Link>
                        <Link href="/revision" className="st-hero-btn st-hero-btn-ghost">
                            Refaire mes erreurs
                        </Link>
                    </div>
                </div>
                <div className="st-summary">
                    <div className="summary-box">
                        <strong>
                            {module === "TCF"
                                ? user?.targetProcedure === "NAT"
                                    ? "B2"
                                    : user?.targetProcedure === "CR"
                                        ? "B1"
                                        : user?.targetProcedure === "CSP"
                                            ? "A2"
                                            : "—"
                                : (user?.targetProcedure ?? "—")}
                        </strong>
                        <span>Objectif {module === "TCF" ? "TCF" : "civique"}</span>
                    </div>
                    <div className="summary-box">
                        <strong>{loading || !stats ? "—" : `${globalMastery.pct}%`}</strong>
                        <span>Maîtrise</span>
                    </div>
                    <div className="summary-box">
                        <strong>{loading || !stats ? "—" : String(stats.questionsAnswered)}</strong>
                        <span>Questions</span>
                    </div>
                    <div className="summary-box">
                        <strong>{loading || !stats ? "—" : String(totalWrong)}</strong>
                        <span>À revoir</span>
                    </div>
                </div>
            </header>

            {/* ============ MODULE TABS ============ */}
            <div className="filters">
                <div className="filter-tabs" role="tablist" aria-label="Module">
                    <button
                        type="button"
                        role="tab"
                        aria-selected={module === "CIVIQUE"}
                        className={`tab tab-blue ${module === "CIVIQUE" ? "is-active" : ""}`}
                        onClick={() => setModule("CIVIQUE")}
                    >
                        Civique
                    </button>
                    <button
                        type="button"
                        role="tab"
                        aria-selected={module === "TCF"}
                        className={`tab tab-red ${module === "TCF" ? "is-active" : ""}`}
                        onClick={() => setModule("TCF")}
                    >
                        TCF
                    </button>
                </div>
            </div>

            {!isPremiumForModule && (
                <button
                    type="button"
                    className="upsell"
                    onClick={() => setPaywallOpen(true)}
                >
                    <div className="upsell-icon" aria-hidden>
                        <svg
                            width="20"
                            height="20"
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            strokeWidth="2"
                            strokeLinecap="round"
                            strokeLinejoin="round"
                        >
                            <path d="M12 2l3 7h7l-5.5 4 2 7L12 16l-6.5 4 2-7L2 9h7z"/>
                        </svg>
                    </div>
                    <div className="upsell-content">
                        <div className="upsell-title">Statistiques en mode démo</div>
                        <div className="upsell-sub">
                            Activez l&apos;abonnement pour suivre toutes les thématiques sans
                            limite.
                        </div>
                    </div>
                    <div className="upsell-arrow">→</div>
                </button>
            )}

            {error && <div className="form-error st-error">{error}</div>}

            {/* ============ STATS GRID ============ */}
            <section className="stats-grid">
                <StatCard
                    tone="blue"
                    icon={<FlameIcon/>}
                    label="JOURS D'AFFILÉE"
                    value={loading ? "—" : String(streak)}
                    trend={streak > 0 ? "Série en cours" : "Pas de série active"}
                />
                <StatCard
                    tone="red"
                    icon={<AlertIcon/>}
                    label="ERREURS EN ATTENTE"
                    value={loading ? "—" : String(totalWrong)}
                    trend={totalWrong > 0 ? "À retravailler" : "Rien à corriger"}
                />
                <StatCard
                    tone="green"
                    icon={<TrendIcon/>}
                    label="SCORE DE MAÎTRISE"
                    value={
                        loading || !stats || stats.questionsAnswered === 0
                            ? "—"
                            : `${globalMastery.pct}%`
                    }
                    trend={
                        stats && stats.questionsAnswered > 0
                            ? `${globalMastery.correct} / ${globalMastery.total} maîtrisées`
                            : "À débloquer"
                    }
                />
                <StatCard
                    tone="amber"
                    icon={<LayersIcon/>}
                    label="SESSIONS"
                    value={loading ? "—" : String(stats?.attemptsTotal ?? 0)}
                    trend={
                        stats && stats.attemptsTotal > 0
                            ? `${stats.questionsAnswered} questions`
                            : "À jouer"
                    }
                />
            </section>

            {isEmpty && (
                <EmptyState
                    title="Aucune statistique pour l'instant"
                    body={
                        module === "TCF"
                            ? "Démarrez votre premier entraînement TCF pour commencer à mesurer votre progression."
                            : "Démarrez votre premier entraînement civique pour mesurer votre progression."
                    }
                    ctaHref="/entrainement"
                    ctaLabel="Lancer un entraînement →"
                />
            )}

            {!loading && stats && stats.questionsAnswered > 0 && (
                <>
                    {/* ============ ROW 2 COLS ============ */}
                    <section className="row-2">
                        {/* Weakest themes */}
                        <div className="card">
                            <div className="card-head">
                                <div>
                                    <h3>Compétences les plus faibles</h3>
                                    <p>Concentrez-vous sur ces points pour progresser vite.</p>
                                </div>
                            </div>
                            {weakest.length === 0 ? (
                                <p className="weakest-empty">
                                    Aucune zone faible détectée — continuez sur votre lancée.
                                </p>
                            ) : (
                                <div className="weak-list">
                                    {weakest.map((t) => {
                                        const pct = Math.round(mastery(t) * 100);
                                        const tone = toneFor(pct);
                                        return (
                                            <button
                                                key={t.themeId}
                                                type="button"
                                                className="weak-row"
                                                onClick={() => startThemeTraining(t.themeId)}
                                                disabled={starting === t.themeId}
                                            >
                        <span className={`weak-marker weak-marker-${tone}`} aria-hidden>
                          !
                        </span>
                                                <div className="weak-body">
                                                    <div className="weak-name">{t.themeName}</div>
                                                    <div className="weak-bar">
                                                        <div
                                                            className={`weak-bar-fill weak-bar-${tone}`}
                                                            style={{width: `${Math.max(2, pct)}%`}}
                                                        />
                                                    </div>
                                                </div>
                                                <span className={`weak-pct weak-pct-${tone}`}>
                          {pct}<span className="weak-pct-suf">%</span>
                        </span>
                                            </button>
                                        );
                                    })}
                                </div>
                            )}
                        </div>

                        {/* Error distribution donut */}
                        <div className="card">
                            <div className="card-head">
                                <div>
                                    <h3>Répartition des erreurs</h3>
                                    <p>
                                        {totalWrong > 0
                                            ? `${totalWrong} erreurs réparties par thème`
                                            : "Pas d'erreur à analyser"}
                                    </p>
                                </div>
                            </div>
                            {errorDistribution.length === 0 ? (
                                <p className="weakest-empty">
                                    Aucune erreur enregistrée — bravo !
                                </p>
                            ) : (
                                <div className="donut-row">
                                    <DonutChart segments={errorDistribution} total={totalWrong}/>
                                    <div className="donut-legend">
                                        {errorDistribution.map((it, i) => (
                                            <div key={it.themeId} className="donut-legend-item">
                        <span
                            className="donut-legend-dot"
                            style={{background: DONUT_COLORS[i]}}
                        />
                                                <span className="donut-legend-name">
                          {it.themeName}
                        </span>
                                                <span className="donut-legend-pct">{it.pct}%</span>
                                            </div>
                                        ))}
                                    </div>
                                </div>
                            )}
                        </div>
                    </section>

                    {/* ============ FULL THEME LIST ============ */}
                    <section>
                        <div className="themes-head">
                            <h3>Détail par thématique</h3>
                            <span className="themes-hint">
                Les plus faibles en haut, à retravailler en priorité
              </span>
                        </div>
                        <div className="theme-list">
                            {sortedThemes.map((t) => (
                                <ThemeStatCard
                                    key={t.themeId}
                                    theme={t}
                                    locked={!isPremiumForModule && t.answered === 0}
                                    starting={starting === t.themeId}
                                    onStart={() => startThemeTraining(t.themeId)}
                                    onLockedClick={() => setPaywallOpen(true)}
                                />
                            ))}
                        </div>
                    </section>
                </>
            )}

            <PaywallSheet
                open={paywallOpen}
                onClose={() => setPaywallOpen(false)}
                title={
                    module === "TCF"
                        ? "Suivi détaillé TCF avec l'Intégral"
                        : "Suivi détaillé avec l'abonnement"
                }
                message="L'abonnement débloque l'entraînement illimité, le choix du thème et le suivi de toutes vos thématiques."
                module={upsellModule}
            />

            <style>{styles}</style>
        </main>
    );
}

// ============================================================================
// STAT CARD
// ============================================================================
function StatCard({
                      tone,
                      icon,
                      label,
                      value,
                      trend,
                  }: {
    tone: "blue" | "red" | "green" | "amber";
    icon: React.ReactNode;
    label: string;
    value: string;
    trend?: string;
}) {
    return (
        <div className="stat-card">
            <div className={`stat-icon stat-icon-${tone}`}>{icon}</div>
            <div className="stat-label">{label}</div>
            <div className="stat-value">{value}</div>
            {trend && <div className="stat-trend">{trend}</div>}
        </div>
    );
}

// ============================================================================
// DONUT CHART
// ============================================================================
const DONUT_COLORS = [
    "#E1372F", // red
    "#E8A317", // amber
    "#1E3A8C", // blue
    "#9CA2BD", // muted-2 for "autres"
];

function DonutChart({
                        segments,
                        total,
                    }: {
    segments: { themeId: string; pct: number }[];
    total: number;
}) {
    const R = 40;
    const CIRC = 2 * Math.PI * R;
    // Offsets cumulés précalculés : on évite de réassigner une variable pendant
    // le rendu (règle React Compiler). `arcs` est une const, on ne fait que push.
    const arcs: { themeId: string; pct: number; len: number; offset: number }[] = [];
    for (const s of segments) {
        const len = (s.pct / 100) * CIRC;
        const last = arcs[arcs.length - 1];
        arcs.push({ themeId: s.themeId, pct: s.pct, len, offset: last ? last.offset + last.len : 0 });
    }
    return (
        <svg viewBox="0 0 100 100" className="donut-svg">
            <circle
                cx="50"
                cy="50"
                r={R}
                fill="none"
                stroke="var(--color-line-2)"
                strokeWidth="16"
            />
            {arcs.map((s, i) => (
                <circle
                    key={s.themeId}
                    cx="50"
                    cy="50"
                    r={R}
                    fill="none"
                    stroke={DONUT_COLORS[i] ?? "#9CA2BD"}
                    strokeWidth="16"
                    strokeDasharray={`${s.len} ${CIRC}`}
                    strokeDashoffset={-s.offset}
                    transform="rotate(-90 50 50)"
                />
            ))}
            <text
                x="50"
                y="48"
                textAnchor="middle"
                fontFamily="Fraunces"
                fontSize="18"
                fontWeight="600"
                fill="var(--color-ink)"
            >
                {total}
            </text>
            <text
                x="50"
                y="62"
                textAnchor="middle"
                fontFamily="JetBrains Mono"
                fontSize="6"
                fill="var(--color-muted)"
                letterSpacing="1"
            >
                ERREURS
            </text>
        </svg>
    );
}

// ============================================================================
// THEME STAT CARD
// ============================================================================
function ThemeStatCard({
                           theme,
                           locked,
                           starting,
                           onStart,
                           onLockedClick,
                       }: {
    theme: ThemeStatsResponse;
    locked: boolean;
    starting: boolean;
    onStart: () => void;
    onLockedClick: () => void;
}) {
    // Score de maîtrise : reflète à la fois la couverture du thème et la justesse.
    // 2 bonnes sur 50 questions disponibles = 4%, pas 100%.
    const rate = mastery(theme);
    const pct = Math.round(rate * 100);
    const tone = toneFor(pct);
    const status = labelFor(pct, theme.answered);

    if (locked) {
        return (
            <button
                type="button"
                className="theme-card theme-card-locked"
                onClick={onLockedClick}
            >
                <div className="theme-card-head">
                    <span className="theme-name">{theme.themeName}</span>
                    <span className="theme-locked-badge">
            <svg
                viewBox="0 0 24 24"
                width="12"
                height="12"
                fill="none"
                stroke="currentColor"
                strokeWidth="2.2"
                strokeLinecap="round"
                strokeLinejoin="round"
            >
              <rect x="3" y="11" width="18" height="11" rx="2"/>
              <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
            </svg>
            Abonnés
          </span>
                </div>
                <div className="theme-meta">{theme.total} questions disponibles</div>
            </button>
        );
    }

    return (
        <div className="theme-card">
            <div className="theme-card-head">
                <span className="theme-name">{theme.themeName}</span>
                {theme.answered > 0 ? (
                    <span className={`theme-pct theme-pct-${tone}`}>{pct}%</span>
                ) : (
                    <span className="theme-status">Pas commencé</span>
                )}
            </div>

            {theme.answered > 0 && (
                <div className="theme-bar">
                    <div
                        className={`theme-bar-fill theme-bar-${tone}`}
                        style={{width: `${pct}%`}}
                    />
                </div>
            )}

            <div className="theme-foot">
        <span className="theme-meta">
          {theme.answered > 0 ? (
              <>
                  <strong>{theme.correct}</strong> / {theme.total} maîtrisées ·{" "}
                  {theme.answered} tentée{theme.answered > 1 ? "s" : ""}
              </>
          ) : (
              <>{theme.total} questions disponibles</>
          )}
        </span>
                <button
                    type="button"
                    className="theme-cta"
                    onClick={onStart}
                    disabled={starting}
                >
                    {starting
                        ? "Préparation…"
                        : theme.answered > 0
                            ? "Continuer →"
                            : "Démarrer →"}
                </button>
            </div>

            {theme.answered > 0 && status && (
                <span className={`theme-tag theme-tag-${tone}`}>{status}</span>
            )}
        </div>
    );
}

// ============================================================================
// HELPERS
// ============================================================================
// Score de maîtrise par thème : questions distinctes réussies / questions
// disponibles dans le thème. Borné par 0..1 quoi qu'il arrive, c'est le seul
// indicateur cohérent d'une "progression" (taux de réussite brut sur 2/2
// questions donne 100% à tort).
function mastery(t: ThemeStatsResponse): number {
    return t.total === 0 ? 0 : t.correct / t.total;
}

function toneFor(pct: number): "green" | "amber" | "red" | "blue" {
    if (pct >= 80) return "green";
    if (pct >= 65) return "blue";
    if (pct >= 45) return "amber";
    return "red";
}

function labelFor(pct: number, answered: number): string {
    if (answered === 0) return "";
    if (pct >= 80) return "Bon niveau";
    if (pct >= 65) return "Stable";
    if (pct >= 45) return "À consolider";
    return "À retravailler";
}

function computeStreak(attempts: AttemptSummaryResponse[]): number {
    if (attempts.length === 0) return 0;
    const days = new Set<string>();
    for (const a of attempts) {
        days.add(new Date(a.startedAt).toISOString().slice(0, 10));
    }
    let streak = 0;
    const cursor = new Date();
    cursor.setHours(0, 0, 0, 0);
    const today = cursor.toISOString().slice(0, 10);
    if (!days.has(today)) cursor.setDate(cursor.getDate() - 1);
    while (days.has(cursor.toISOString().slice(0, 10))) {
        streak += 1;
        cursor.setDate(cursor.getDate() - 1);
    }
    return streak;
}

// ============================================================================
// EMPTY / SKELETON
// ============================================================================
function EmptyState({
                        title,
                        body,
                        ctaHref,
                        ctaLabel,
                    }: {
    title: string;
    body: string;
    ctaHref: string;
    ctaLabel: string;
}) {
    return (
        <div className="st-empty">
            <div className="st-empty-icon" aria-hidden>
                <svg
                    viewBox="0 0 24 24"
                    width="28"
                    height="28"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                >
                    <path d="M3 3v18h18"/>
                    <path d="M7 15l4-4 4 4 5-7"/>
                </svg>
            </div>
            <h3>{title}</h3>
            <p>{body}</p>
            <Link href={ctaHref} className="btn-primary">
                {ctaLabel}
            </Link>
        </div>
    );
}

function StatsSkeleton() {
    return (
        <div className="st-loading">
            <style>{`.st-loading { min-height: calc(100vh - 80px); background: #F7F8FC; }`}</style>
        </div>
    );
}

const gateStyles = `
  .st-gate {
    min-height: 60vh;
    display: flex; flex-direction: column; align-items: center; justify-content: center;
    gap: 14px;
    color: var(--color-muted);
    padding: 36px;
  }
  .st-gate-cta { color: var(--color-blue); font-weight: 700; text-decoration: none; }
`;

// ============================================================================
// ICONS
// ============================================================================
const I = (props: React.SVGProps<SVGSVGElement>) => (
    <svg
        width="18"
        height="18"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
        {...props}
    />
);
const FlameIcon = () => (
    <I>
        <polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/>
    </I>
);
const AlertIcon = () => (
    <I>
        <circle cx="12" cy="12" r="10"/>
        <line x1="12" y1="8" x2="12" y2="12"/>
        <line x1="12" y1="16" x2="12.01" y2="16"/>
    </I>
);
const TrendIcon = () => (
    <I>
        <polyline points="23 6 13.5 15.5 8.5 10.5 1 18"/>
        <polyline points="17 6 23 6 23 12"/>
    </I>
);
const LayersIcon = () => (
    <I>
        <polygon points="12 2 2 7 12 12 22 7 12 2"/>
        <polyline points="2 17 12 22 22 17"/>
        <polyline points="2 12 12 17 22 12"/>
    </I>
);

// ============================================================================
// STYLES
// ============================================================================
const styles = `
  .st { padding: 24px 36px 64px; max-width: 1320px; }
  @media (max-width: 760px) { .st { padding: 20px 16px 56px; } }

  /* ========== HERO PROGRESSION (façon template progression-page) ========== */
  .st-hero {
    display: grid;
    grid-template-columns: 1fr;
    gap: 22px;
    background: linear-gradient(135deg, #0E5B43 0%, var(--color-blue) 100%);
    color: #fff;
    border-radius: 20px;
    padding: 24px;
    margin-bottom: 22px;
  }
  .st-hero .breadcrumb { color: rgba(255, 255, 255, 0.7); }
  .st-hero-main h1 {
    font-family: var(--font-display);
    font-size: clamp(24px, 3.4vw, 32px);
    font-weight: 600;
    letter-spacing: -0.02em;
    line-height: 1.12;
    margin: 8px 0 0;
    color: #fff;
  }
  .st-hero-main h1 em { font-style: italic; font-weight: 500; opacity: 0.92; }
  .st-hero-main p {
    color: rgba(255, 255, 255, 0.82);
    font-size: 14.5px;
    line-height: 1.6;
    margin: 10px 0 0;
    max-width: 540px;
  }
  .st-hero-actions { display: flex; flex-wrap: wrap; gap: 12px; margin-top: 18px; }
  .st-hero-btn {
    display: inline-flex; align-items: center; justify-content: center;
    padding: 11px 20px; border-radius: 10px;
    font-family: var(--font-sans); font-size: 14px; font-weight: 700;
    background: #fff; color: var(--color-blue);
    text-decoration: none; border: 1px solid transparent;
    transition: transform 0.15s, background 0.15s;
  }
  .st-hero-btn:hover { transform: translateY(-1px); background: #F1F5F9; }
  .st-hero-btn-ghost {
    background: transparent; color: #fff;
    border-color: rgba(255, 255, 255, 0.4);
  }
  .st-hero-btn-ghost:hover { background: rgba(255, 255, 255, 0.12); }
  .st-summary { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; align-content: start; }
  .st-summary .summary-box {
    background: rgba(255, 255, 255, 0.1);
    border: 1px solid rgba(255, 255, 255, 0.18);
    border-radius: 14px;
    padding: 14px 16px;
    display: flex; flex-direction: column; gap: 4px;
  }
  .st-summary .summary-box strong {
    font-family: var(--font-display);
    font-weight: 600;
    font-size: 24px;
    line-height: 1;
    color: #fff;
    font-variant-numeric: tabular-nums;
  }
  .st-summary .summary-box span { font-size: 11.5px; color: rgba(255, 255, 255, 0.7); }
  @media (min-width: 900px) {
    .st-hero { grid-template-columns: 1.4fr 1fr; align-items: center; padding: 30px; }
  }

  /* ========== TOPBAR ========== */
  .topbar {
    display: flex; justify-content: space-between; align-items: flex-start;
    gap: 16px; flex-wrap: wrap;
    margin-bottom: 20px;
  }
  .breadcrumb {
    font-family: var(--font-mono);
    font-size: 11px;
    color: var(--color-muted);
    letter-spacing: 0.12em;
    text-transform: uppercase;
    margin-bottom: 6px;
  }
  .breadcrumb .sep { margin: 0 6px; opacity: 0.5; }
  .topbar h1 {
    font-family: var(--font-display);
    font-size: clamp(24px, 3.2vw, 32px);
    font-weight: 600;
    letter-spacing: -0.02em;
    margin: 0;
    line-height: 1.15;
  }
  .topbar h1 em {
    color: var(--color-blue);
    font-style: italic;
    font-weight: 500;
  }
  .topbar-actions { display: flex; gap: 10px; align-items: center; flex-wrap: wrap; }
  .btn-outline {
    display: inline-flex; align-items: center; justify-content: center; gap: 6px;
    padding: 10px 16px; border-radius: 10px;
    font-size: 13px; font-weight: 600;
    text-decoration: none;
    border: 1px solid var(--color-line);
    background: #fff;
    color: var(--color-ink);
    transition: all 0.15s;
    font-family: inherit;
  }
  .btn-outline:hover { border-color: var(--color-blue); color: var(--color-blue); }
  .btn-primary {
    display: inline-flex; align-items: center; justify-content: center; gap: 8px;
    padding: 10px 16px; border-radius: 10px;
    font-size: 13px; font-weight: 600;
    text-decoration: none;
    background: var(--color-blue); color: #fff;
    transition: all 0.15s;
    cursor: pointer;
    font-family: inherit;
    border: 1px solid transparent;
  }
  .btn-primary:hover { background: var(--color-blue-dark); }

  .st-error { margin-bottom: 18px; }

  /* ========== MODULE TABS ========== */
  .filters {
    display: flex; gap: 12px; align-items: center; flex-wrap: wrap;
    margin-bottom: 18px;
  }
  .filter-tabs {
    display: inline-flex;
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 12px;
    padding: 4px;
    gap: 2px;
  }
  .tab {
    padding: 8px 18px;
    background: transparent;
    border: none;
    border-radius: 8px;
    font-family: inherit;
    font-size: 13px;
    font-weight: 600;
    color: var(--color-muted);
    cursor: pointer;
    transition: all 0.15s;
  }
  .tab:hover { color: var(--color-ink); }
  .tab.tab-blue.is-active { background: var(--color-blue); color: #fff; }
  .tab.tab-red.is-active { background: var(--color-red); color: #fff; }

  /* ========== UPSELL ========== */
  .upsell {
    display: flex; align-items: center; gap: 14px;
    width: 100%;
    background: linear-gradient(135deg, rgba(232, 163, 23, 0.10), rgba(232, 163, 23, 0.02));
    border: 1px solid rgba(232, 163, 23, 0.35);
    border-radius: 14px;
    padding: 14px 18px;
    margin-bottom: 22px;
    cursor: pointer;
    text-align: left;
    font-family: var(--font-sans);
    transition: background 0.15s, transform 0.15s;
  }
  .upsell:hover {
    background: linear-gradient(135deg, rgba(232, 163, 23, 0.14), rgba(232, 163, 23, 0.04));
    transform: translateY(-1px);
  }
  .upsell-icon {
    width: 40px; height: 40px;
    background: var(--color-amber);
    color: #fff;
    border-radius: 11px;
    display: flex; align-items: center; justify-content: center;
    flex-shrink: 0;
  }
  .upsell-content { flex: 1; min-width: 0; }
  .upsell-title { font-weight: 700; font-size: 14px; color: var(--color-ink); line-height: 1.25; }
  .upsell-sub { font-size: 12.5px; color: var(--color-muted); line-height: 1.4; margin-top: 4px; }
  .upsell-arrow { color: var(--color-amber); font-size: 18px; font-weight: 700; }

  /* ========== STATS GRID ========== */
  .stats-grid {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 16px;
    margin-bottom: 26px;
  }
  .stat-card {
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 16px;
    padding: 18px;
  }
  .stat-icon {
    width: 36px; height: 36px;
    border-radius: 10px;
    display: flex; align-items: center; justify-content: center;
    margin-bottom: 14px;
  }
  .stat-icon-blue { background: var(--color-blue-light); color: var(--color-blue); }
  .stat-icon-red { background: var(--color-red-light); color: var(--color-red); }
  .stat-icon-green { background: rgba(22, 143, 91, 0.1); color: var(--color-green); }
  .stat-icon-amber { background: rgba(232, 163, 23, 0.12); color: var(--color-amber); }
  .stat-label {
    font-family: var(--font-mono);
    font-size: 10px;
    letter-spacing: 0.12em;
    text-transform: uppercase;
    color: var(--color-muted);
    margin-bottom: 6px;
    font-weight: 600;
  }
  .stat-value {
    font-family: var(--font-display);
    font-size: 30px;
    font-weight: 600;
    letter-spacing: -0.02em;
    line-height: 1.1;
    color: var(--color-ink);
  }
  .stat-trend { font-size: 12px; margin-top: 6px; color: var(--color-muted); }
  @media (max-width: 1100px) {
    .stats-grid { grid-template-columns: repeat(2, 1fr); }
  }
  @media (max-width: 480px) {
    .stats-grid { grid-template-columns: 1fr; }
  }

  /* ========== CARD ========== */
  .card {
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 18px;
    padding: 22px;
    margin-bottom: 22px;
  }
  .card-head {
    display: flex; justify-content: space-between; align-items: flex-start;
    margin-bottom: 18px;
    gap: 12px;
    flex-wrap: wrap;
  }
  .card-head h3 {
    font-family: var(--font-display);
    font-weight: 600;
    font-size: 19px;
    margin: 0 0 4px;
    letter-spacing: -0.01em;
  }
  .card-head p { margin: 0; color: var(--color-muted); font-size: 13px; }

  /* ========== ROW 2 COLS ========== */
  .row-2 {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 20px;
    margin-bottom: 22px;
  }
  @media (max-width: 980px) {
    .row-2 { grid-template-columns: 1fr; }
  }

  /* WEAK LIST */
  .weak-list { display: flex; flex-direction: column; gap: 14px; }
  .weak-row {
    display: grid;
    grid-template-columns: 24px 1fr 60px;
    gap: 12px;
    align-items: center;
    background: transparent;
    border: none;
    cursor: pointer;
    text-align: left;
    padding: 0;
    font-family: inherit;
    transition: opacity 0.15s;
    width: 100%;
  }
  .weak-row:hover { opacity: 0.85; }
  .weak-row:disabled { opacity: 0.5; cursor: not-allowed; }
  .weak-marker {
    width: 22px; height: 22px;
    border-radius: 6px;
    display: flex; align-items: center; justify-content: center;
    font-family: var(--font-mono);
    font-weight: 700;
    font-size: 13px;
  }
  .weak-marker-red { background: var(--color-red-light); color: var(--color-red); }
  .weak-marker-amber { background: rgba(232, 163, 23, 0.16); color: var(--color-amber); }
  .weak-marker-blue { background: var(--color-blue-light); color: var(--color-blue); }
  .weak-marker-green { background: rgba(22, 143, 91, 0.12); color: var(--color-green); }
  .weak-body { min-width: 0; }
  .weak-name {
    font-size: 13.5px;
    font-weight: 600;
    color: var(--color-ink);
    margin-bottom: 5px;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }
  .weak-bar {
    height: 6px;
    background: var(--color-line-2);
    border-radius: 3px;
    overflow: hidden;
  }
  .weak-bar-fill {
    height: 100%; border-radius: 3px;
  }
  .weak-bar-red { background: var(--color-red); }
  .weak-bar-amber { background: var(--color-amber); }
  .weak-bar-blue { background: var(--color-blue); }
  .weak-bar-green { background: var(--color-green); }
  .weak-pct {
    text-align: right;
    font-family: var(--font-mono);
    font-size: 12px;
    font-weight: 700;
  }
  .weak-pct-red { color: var(--color-red); }
  .weak-pct-amber { color: var(--color-amber); }
  .weak-pct-blue { color: var(--color-blue); }
  .weak-pct-green { color: var(--color-green); }
  .weak-pct-suf { color: var(--color-muted); font-weight: 500; }
  .weakest-empty {
    color: var(--color-muted);
    font-size: 13.5px;
    margin: 24px 8px;
    text-align: center;
  }

  /* DONUT */
  .donut-row {
    display: flex;
    align-items: center;
    gap: 22px;
  }
  .donut-svg {
    width: 140px;
    height: 140px;
    flex-shrink: 0;
  }
  .donut-legend {
    flex: 1;
    display: flex;
    flex-direction: column;
    gap: 10px;
    min-width: 0;
  }
  .donut-legend-item {
    display: flex;
    align-items: center;
    gap: 10px;
  }
  .donut-legend-dot {
    width: 12px;
    height: 12px;
    border-radius: 3px;
    flex-shrink: 0;
  }
  .donut-legend-name {
    font-size: 13px;
    color: var(--color-ink-2);
    flex: 1;
    min-width: 0;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }
  .donut-legend-pct {
    margin-left: auto;
    font-family: var(--font-mono);
    font-size: 12px;
    font-weight: 700;
    color: var(--color-ink);
  }
  @media (max-width: 480px) {
    .donut-row { flex-direction: column; }
  }

  /* ========== FULL THEME LIST ========== */
  .themes-head {
    display: flex; align-items: baseline; justify-content: space-between;
    gap: 12px;
    padding: 4px 0 14px;
  }
  .themes-head h3 {
    font-family: var(--font-display);
    font-weight: 600;
    font-size: 19px;
    margin: 0;
    letter-spacing: -0.01em;
  }
  .themes-hint {
    font-family: var(--font-mono);
    font-size: 10px;
    letter-spacing: 0.12em;
    color: var(--color-muted);
    text-transform: uppercase;
  }
  .theme-list { display: flex; flex-direction: column; gap: 10px; }

  .theme-card {
    position: relative;
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 14px;
    padding: 16px 18px;
  }
  .theme-card-locked {
    background: var(--color-paper);
    cursor: pointer;
    text-align: left;
    width: 100%;
    font-family: inherit;
    transition: background 0.15s;
  }
  .theme-card-locked:hover { background: var(--color-paper-2); }
  .theme-card-locked .theme-name { color: var(--color-muted); }
  .theme-card-head {
    display: flex; align-items: center; justify-content: space-between;
    gap: 12px;
    margin-bottom: 8px;
  }
  .theme-name {
    font-family: var(--font-sans);
    font-weight: 700;
    font-size: 14.5px;
    color: var(--color-ink);
  }
  .theme-pct {
    font-family: var(--font-mono);
    font-size: 16px;
    font-weight: 700;
  }
  .theme-pct-green { color: var(--color-green); }
  .theme-pct-blue { color: var(--color-blue); }
  .theme-pct-amber { color: var(--color-amber); }
  .theme-pct-red { color: var(--color-red); }
  .theme-status, .theme-locked-badge {
    font-family: var(--font-mono);
    font-size: 10px;
    letter-spacing: 0.12em;
    text-transform: uppercase;
    color: var(--color-muted);
    font-weight: 700;
  }
  .theme-locked-badge {
    display: inline-flex; align-items: center; gap: 4px;
    background: var(--color-paper-2);
    padding: 3px 8px; border-radius: 100px;
  }
  .theme-bar {
    height: 6px;
    background: var(--color-line-2);
    border-radius: 3px;
    overflow: hidden;
    margin-bottom: 10px;
  }
  .theme-bar-fill { height: 100%; border-radius: 3px; transition: width 0.4s ease-out; }
  .theme-bar-green { background: var(--color-green); }
  .theme-bar-blue { background: var(--color-blue); }
  .theme-bar-amber { background: var(--color-amber); }
  .theme-bar-red { background: var(--color-red); }
  .theme-foot {
    display: flex; align-items: center; justify-content: space-between;
    gap: 12px;
    flex-wrap: wrap;
  }
  .theme-meta { font-size: 12.5px; color: var(--color-muted); }
  .theme-meta strong { color: var(--color-ink); font-weight: 700; }
  .theme-cta {
    background: none; border: none;
    font-family: inherit;
    font-size: 13px;
    font-weight: 700;
    color: var(--color-blue);
    cursor: pointer;
    padding: 4px 0;
  }
  .theme-cta:disabled { opacity: 0.5; cursor: not-allowed; }
  .theme-tag {
    position: absolute;
    top: 16px; right: 64px;
    font-family: var(--font-mono);
    font-size: 9px;
    letter-spacing: 0.14em;
    text-transform: uppercase;
    padding: 3px 8px;
    border-radius: 100px;
    font-weight: 700;
    display: none;
  }
  @media (min-width: 760px) { .theme-tag { display: inline-block; } }
  .theme-tag-green { background: rgba(22, 143, 91, 0.12); color: var(--color-green); }
  .theme-tag-blue { background: var(--color-blue-light); color: var(--color-blue); }
  .theme-tag-amber { background: rgba(232, 163, 23, 0.16); color: var(--color-amber); }
  .theme-tag-red { background: var(--color-red-light); color: var(--color-red); }

  /* ========== EMPTY ========== */
  .st-empty {
    background: #fff;
    border: 1px dashed var(--color-line);
    border-radius: 16px;
    padding: 60px 32px;
    text-align: center;
    margin-top: 4px;
  }
  .st-empty-icon {
    width: 56px; height: 56px;
    margin: 0 auto 14px;
    background: var(--color-blue-light);
    color: var(--color-blue);
    border-radius: 50%;
    display: flex; align-items: center; justify-content: center;
  }
  .st-empty h3 {
    font-family: var(--font-display);
    font-weight: 600;
    font-size: 22px;
    color: var(--color-ink);
    margin: 0 0 8px;
    letter-spacing: -0.015em;
  }
  .st-empty p {
    color: var(--color-muted);
    font-size: 13.5px;
    line-height: 1.55;
    margin: 0 auto 18px;
    max-width: 380px;
  }
`;
