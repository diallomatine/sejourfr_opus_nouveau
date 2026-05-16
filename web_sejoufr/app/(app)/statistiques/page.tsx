"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useMemo, useState } from "react";
import { ModuleSwitch } from "@/app/_components/ModuleSwitch";
import { PaywallSheet } from "@/app/_components/PaywallSheet";
import { ApiException, attemptApi, statsApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import {
  canAccessModule,
  type Module as ModuleEnum,
  type ThemeStatsResponse,
  type UserStatsResponse,
} from "@/lib/types";

export default function StatistiquesPage() {
  const router = useRouter();
  const { user, status } = useAuth();
  const [module, setModule] = useState<ModuleEnum>("CIVIQUE");
  const [data, setData] = useState<{
    loading: boolean;
    stats: UserStatsResponse | null;
    error: string | null;
    loadedFor: ModuleEnum | null;
  }>({ loading: true, stats: null, error: null, loadedFor: null });
  const [starting, setStarting] = useState<string | null>(null);
  const [showPaywall, setShowPaywall] = useState(false);

  const isPremiumForModule = user !== null && canAccessModule(user, module);
  const upsellPlan = module === "TCF" ? "INTEGRAL_3MOIS" : "CIVIQUE_3MOIS";

  useEffect(() => {
    let cancelled = false;
    statsApi
      .get(module)
      .then((s) => {
        if (cancelled) return;
        setData({ loading: false, stats: s, error: null, loadedFor: module });
      })
      .catch((e) => {
        if (cancelled) return;
        setData({
          loading: false,
          stats: null,
          error: e instanceof ApiException ? e.message : "Statistiques indisponibles.",
          loadedFor: module,
        });
      });
    return () => {
      cancelled = true;
    };
  }, [module]);

  async function startThemeTraining(themeId: string) {
    if (!isPremiumForModule) {
      setShowPaywall(true);
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

  const stats = data.loadedFor === module ? data.stats : null;
  const loading = data.loading || data.loadedFor !== module;
  const error = data.loadedFor === module ? data.error : null;

  // Tri : faibles d'abord, puis non commencés (par total décroissant pour voir
  // les plus gros pools en premier).
  const sortedThemes = useMemo(() => {
    if (!stats) return [];
    const started = stats.byTheme.filter((t) => t.answered > 0);
    const notStarted = stats.byTheme.filter((t) => t.answered === 0);
    started.sort((a, b) => successRate(a) - successRate(b));
    notStarted.sort((a, b) => b.total - a.total);
    return [...started, ...notStarted];
  }, [stats]);

  if (status === "loading") return <div className="st-loading" />;
  if (!user) {
    return (
      <main className="st-gate">
        <p>Connectez-vous pour voir vos statistiques.</p>
        <Link href="/connexion?next=/statistiques" className="btn btn-blue">
          Se connecter
        </Link>
      </main>
    );
  }

  const globalSuccessPct = stats ? Math.round(stats.successRate * 100) : 0;
  const isEmpty = !loading && stats !== null && stats.questionsAnswered === 0;

  return (
    <main className="st">
      <section className="st-head">
        <div className="st-wrap">
          <span className="eyebrow">Progression</span>
          <h1>
            Vos <em>forces</em> et axes de travail.
          </h1>
          <p>
            Suivez votre réussite par thématique pour cibler ce qu&apos;il reste à
            retravailler avant le jour J.
          </p>
          <div className="st-module">
            <ModuleSwitch value={module} onChange={setModule} />
          </div>
        </div>
      </section>

      <section className="st-body">
        <div className="st-wrap">
          {!isPremiumForModule && (
            <button
              type="button"
              className="st-upsell"
              onClick={() => setShowPaywall(true)}
            >
              <div className="st-upsell-icon" aria-hidden>
                <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M12 2l3 7h7l-5.5 4 2 7L12 16l-6.5 4 2-7L2 9h7z" />
                </svg>
              </div>
              <div className="st-upsell-content">
                <div className="st-upsell-title">Statistiques détaillées en démo</div>
                <div className="st-upsell-sub">
                  L&apos;abonnement débloque toutes les thématiques et le suivi
                  illimité de votre progression.
                </div>
              </div>
              <div className="st-upsell-arrow">→</div>
            </button>
          )}

          {loading && <StatsLoading />}
          {error && !loading && <div className="form-error">{error}</div>}

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
              {/* Carte de stats globales */}
              <div className="st-global">
                <div className="st-global-main">
                  <span className="st-global-pct" data-tone={toneFor(globalSuccessPct)}>
                    {globalSuccessPct}%
                  </span>
                  <span className="st-global-label">Taux global de réussite</span>
                </div>
                <div className="st-global-grid">
                  <div className="st-global-stat">
                    <span className="l">Sessions</span>
                    <span className="v">{stats.attemptsTotal}</span>
                  </div>
                  <div className="st-global-stat">
                    <span className="l">Questions répondues</span>
                    <span className="v">{stats.questionsAnswered}</span>
                  </div>
                  <div className="st-global-stat">
                    <span className="l">Bonnes réponses</span>
                    <span className="v">{stats.questionsCorrect}</span>
                  </div>
                </div>
              </div>

              {/* Liste des thématiques */}
              <div className="st-themes-head">
                <span className="st-themes-title">Détail par thématique</span>
                <span className="st-themes-hint">
                  Les plus faibles en haut, à retravailler en priorité
                </span>
              </div>

              <div className="st-themes-list">
                {sortedThemes.map((t) => (
                  <ThemeStatCard
                    key={t.themeId}
                    theme={t}
                    locked={!isPremiumForModule && t.answered === 0}
                    starting={starting === t.themeId}
                    onStart={() => startThemeTraining(t.themeId)}
                    onLockedClick={() => setShowPaywall(true)}
                  />
                ))}
              </div>
            </>
          )}
        </div>
      </section>

      <PaywallSheet
        open={showPaywall}
        onClose={() => setShowPaywall(false)}
        title={
          module === "TCF"
            ? "Suivi détaillé TCF avec l'Intégral"
            : "Suivi détaillé avec l'abonnement"
        }
        message="L'abonnement débloque l'entraînement illimité, le choix du thème et le suivi de toutes vos thématiques."
        plan={upsellPlan}
      />

      <style>{styles}</style>
    </main>
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
  const rate = successRate(theme);
  const pct = Math.round(rate * 100);
  const progressPct = theme.total > 0 ? (theme.answered / theme.total) * 100 : 0;
  const tone = toneFor(pct);
  const status = labelFor(pct, theme.answered);

  if (locked) {
    return (
      <button type="button" className="st-theme st-theme-locked" onClick={onLockedClick}>
        <div className="st-theme-head">
          <span className="st-theme-name">{theme.themeName}</span>
          <span className="st-theme-locked-badge">
            <svg viewBox="0 0 24 24" width="12" height="12" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
              <rect x="3" y="11" width="18" height="11" rx="2" />
              <path d="M7 11V7a5 5 0 0 1 10 0v4" />
            </svg>
            Abonnés
          </span>
        </div>
        <div className="st-theme-meta">{theme.total} questions disponibles</div>
      </button>
    );
  }

  return (
    <div className="st-theme">
      <div className="st-theme-head">
        <span className="st-theme-name">{theme.themeName}</span>
        {theme.answered > 0 ? (
          <span className="st-theme-pct" data-tone={tone}>
            {pct}%
          </span>
        ) : (
          <span className="st-theme-status">Pas commencé</span>
        )}
      </div>

      {theme.answered > 0 && (
        <div className="st-theme-bar">
          <div
            className="st-theme-bar-fill"
            data-tone={tone}
            style={{ width: `${pct}%` }}
          />
        </div>
      )}

      <div className="st-theme-foot">
        <span className="st-theme-meta">
          {theme.answered > 0 ? (
            <>
              <strong>{theme.correct}</strong> / {theme.answered} bonnes ·{" "}
              <strong>{Math.round(progressPct)}%</strong> du pool exploré
            </>
          ) : (
            <>{theme.total} questions disponibles</>
          )}
        </span>
        <button
          type="button"
          className="st-theme-cta"
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

      {theme.answered > 0 && <span className="st-theme-tag" data-tone={tone}>{status}</span>}
    </div>
  );
}

// ============================================================================
// HELPERS
// ============================================================================
function successRate(t: ThemeStatsResponse): number {
  return t.answered === 0 ? 0 : t.correct / t.answered;
}

function toneFor(pct: number): "green" | "amber" | "red" {
  if (pct >= 75) return "green";
  if (pct >= 50) return "amber";
  return "red";
}

function labelFor(pct: number, answered: number): string {
  if (answered === 0) return "";
  if (pct >= 75) return "Bon niveau";
  if (pct >= 50) return "À consolider";
  return "À retravailler";
}

// ============================================================================
// SUB-COMPONENTS
// ============================================================================
function StatsLoading() {
  return (
    <div className="st-themes-list">
      {[0, 1, 2, 3, 4].map((i) => (
        <div key={i} className="st-theme st-theme-skeleton" />
      ))}
    </div>
  );
}

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
        <svg viewBox="0 0 24 24" width="32" height="32" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
          <path d="M3 3v18h18" />
          <path d="M7 15l4-4 4 4 5-7" />
        </svg>
      </div>
      <h2>{title}</h2>
      <p>{body}</p>
      <Link href={ctaHref} className="btn btn-blue">{ctaLabel}</Link>
    </div>
  );
}

// ============================================================================
// STYLES
// ============================================================================
const styles = `
  .st { background: var(--color-paper); min-height: calc(100vh - 110px); }
  .st-loading { min-height: 60vh; }
  .st-gate {
    min-height: 60vh;
    display: flex; flex-direction: column; align-items: center; justify-content: center;
    gap: 14px; color: var(--color-muted);
  }
  .st-wrap { max-width: 760px; margin: 0 auto; }

  .st-head { padding: 40px 16px 24px; text-align: center; }
  .st-head h1 {
    font-family: var(--font-display); font-weight: 500;
    font-size: clamp(28px, 4vw, 40px); line-height: 1.05; letter-spacing: -0.025em;
    margin: 10px 0 12px;
  }
  .st-head h1 em { font-style: italic; color: var(--color-red); }
  .st-head p {
    color: var(--color-muted); font-size: 15px; line-height: 1.55;
    margin: 0 auto 22px; max-width: 540px;
  }
  .st-module { max-width: 460px; margin: 0 auto; }

  .st-body { padding: 8px 16px 80px; }

  .st-upsell {
    display: flex; align-items: center; gap: 12px;
    width: 100%;
    background: rgba(232, 163, 23, 0.08);
    border: 1px solid rgba(232, 163, 23, 0.35);
    border-radius: 14px;
    padding: 12px 14px;
    margin: 18px 0 22px;
    cursor: pointer;
    text-align: left;
    font-family: var(--font-sans);
    transition: background 0.15s;
  }
  .st-upsell:hover { background: rgba(232, 163, 23, 0.14); }
  .st-upsell-icon {
    width: 38px; height: 38px;
    background: rgba(232, 163, 23, 0.16);
    color: var(--color-amber);
    border-radius: 11px;
    display: flex; align-items: center; justify-content: center;
    flex-shrink: 0;
  }
  .st-upsell-content { flex: 1; min-width: 0; }
  .st-upsell-title {
    font-weight: 800; font-size: 13.5px; color: var(--color-ink); line-height: 1.2;
  }
  .st-upsell-sub {
    font-size: 12px; color: var(--color-muted); line-height: 1.4; margin-top: 3px;
  }
  .st-upsell-arrow { color: var(--color-amber); font-size: 16px; flex-shrink: 0; }

  .st-empty {
    background: #fff;
    border: 1px dashed var(--color-line);
    border-radius: 16px;
    padding: 48px 32px;
    text-align: center;
    margin-top: 22px;
  }
  .st-empty-icon {
    width: 56px; height: 56px;
    margin: 0 auto 14px;
    background: var(--color-blue-light); color: var(--color-blue);
    border-radius: 50%;
    display: flex; align-items: center; justify-content: center;
  }
  .st-empty h2 {
    font-family: var(--font-display); font-weight: 500; font-size: 22px;
    color: var(--color-ink); margin: 0 0 8px;
    letter-spacing: -0.015em;
  }
  .st-empty p {
    color: var(--color-muted); font-size: 13.5px; line-height: 1.55;
    margin: 0 auto 18px; max-width: 360px;
  }

  /* ----- Carte stats globales ----- */
  .st-global {
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 16px;
    padding: 22px 26px;
    margin: 18px 0 28px;
    display: grid;
    grid-template-columns: minmax(140px, 200px) 1fr;
    gap: 28px;
    align-items: center;
  }
  .st-global-main {
    display: flex; flex-direction: column; align-items: flex-start; gap: 4px;
    padding-right: 28px;
    border-right: 1px solid var(--color-line-2);
  }
  .st-global-pct {
    font-family: var(--font-display); font-weight: 500;
    font-size: 56px; line-height: 1; letter-spacing: -0.04em;
  }
  .st-global-pct[data-tone="green"] { color: var(--color-green); }
  .st-global-pct[data-tone="amber"] { color: var(--color-amber); }
  .st-global-pct[data-tone="red"] { color: var(--color-red); }
  .st-global-label {
    font-family: var(--font-mono); font-size: 10px;
    letter-spacing: 0.14em; text-transform: uppercase;
    color: var(--color-muted); font-weight: 600;
  }
  .st-global-grid {
    display: grid; grid-template-columns: repeat(3, 1fr); gap: 18px;
  }
  .st-global-stat { display: flex; flex-direction: column; gap: 4px; }
  .st-global-stat .l {
    font-family: var(--font-mono); font-size: 9.5px;
    letter-spacing: 0.14em; text-transform: uppercase;
    color: var(--color-muted); font-weight: 600;
  }
  .st-global-stat .v {
    font-family: var(--font-display); font-weight: 500;
    font-size: 24px; line-height: 1;
    color: var(--color-ink);
  }
  @media (max-width: 560px) {
    .st-global { grid-template-columns: 1fr; gap: 18px; padding: 18px; }
    .st-global-main {
      padding-right: 0; padding-bottom: 16px;
      border-right: none; border-bottom: 1px solid var(--color-line-2);
    }
    .st-global-grid { grid-template-columns: repeat(3, 1fr); gap: 12px; }
    .st-global-stat .v { font-size: 18px; }
  }

  /* ----- Themes ----- */
  .st-themes-head {
    display: flex; align-items: baseline; justify-content: space-between;
    gap: 12px; padding: 22px 0 14px;
  }
  .st-themes-title {
    font-family: var(--font-sans); font-weight: 800; font-size: 15px;
    color: var(--color-ink);
  }
  .st-themes-hint {
    font-family: var(--font-mono); font-size: 10px; letter-spacing: 0.12em;
    color: var(--color-muted-2); text-transform: uppercase;
  }
  .st-themes-list { display: flex; flex-direction: column; gap: 10px; }

  .st-theme {
    position: relative;
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 14px;
    padding: 16px 18px;
    text-align: left;
    width: 100%;
  }
  .st-theme-skeleton {
    height: 96px;
    animation: st-pulse 1.4s ease-in-out infinite;
  }
  @keyframes st-pulse {
    0%, 100% { opacity: 0.55; }
    50% { opacity: 1; }
  }
  .st-theme-locked {
    background: var(--color-paper);
    cursor: pointer;
    transition: background 0.15s;
  }
  .st-theme-locked:hover { background: var(--color-paper-2); }
  .st-theme-locked .st-theme-name { color: var(--color-muted); }

  .st-theme-head {
    display: flex; align-items: center; justify-content: space-between;
    gap: 12px; margin-bottom: 8px;
  }
  .st-theme-name {
    font-family: var(--font-sans); font-weight: 700; font-size: 14.5px;
    color: var(--color-ink);
  }
  .st-theme-pct {
    font-family: var(--font-mono); font-size: 16px; font-weight: 700;
  }
  .st-theme-pct[data-tone="green"] { color: var(--color-green); }
  .st-theme-pct[data-tone="amber"] { color: var(--color-amber); }
  .st-theme-pct[data-tone="red"] { color: var(--color-red); }
  .st-theme-status, .st-theme-locked-badge {
    font-family: var(--font-mono); font-size: 10px;
    letter-spacing: 0.12em; text-transform: uppercase;
    color: var(--color-muted); font-weight: 700;
  }
  .st-theme-locked-badge {
    display: inline-flex; align-items: center; gap: 4px;
    background: var(--color-paper-2);
    padding: 3px 8px; border-radius: 100px;
  }

  .st-theme-bar {
    height: 6px;
    background: var(--color-line-2);
    border-radius: 100px;
    overflow: hidden;
    margin-bottom: 10px;
  }
  .st-theme-bar-fill {
    height: 100%; border-radius: 100px;
    transition: width 0.4s ease-out;
  }
  .st-theme-bar-fill[data-tone="green"] { background: var(--color-green); }
  .st-theme-bar-fill[data-tone="amber"] { background: var(--color-amber); }
  .st-theme-bar-fill[data-tone="red"] { background: var(--color-red); }

  .st-theme-foot {
    display: flex; align-items: center; justify-content: space-between;
    gap: 12px; flex-wrap: wrap;
  }
  .st-theme-meta {
    font-size: 12.5px; color: var(--color-muted);
  }
  .st-theme-meta strong { color: var(--color-ink); font-weight: 700; }
  .st-theme-cta {
    background: none; border: none;
    font-family: var(--font-sans); font-size: 13px; font-weight: 700;
    color: var(--color-blue);
    cursor: pointer; padding: 4px 0;
  }
  .st-theme-cta:disabled { opacity: 0.5; cursor: not-allowed; }

  .st-theme-tag {
    position: absolute; top: 16px; right: 56px;
    font-family: var(--font-mono); font-size: 9px;
    letter-spacing: 0.14em; text-transform: uppercase;
    padding: 2px 8px; border-radius: 100px;
    font-weight: 700;
    display: none;
  }
  @media (min-width: 720px) { .st-theme-tag { display: inline-block; } }
  .st-theme-tag[data-tone="green"] {
    background: rgba(22, 143, 91, 0.12); color: var(--color-green);
  }
  .st-theme-tag[data-tone="amber"] {
    background: rgba(232, 163, 23, 0.16); color: var(--color-amber);
  }
  .st-theme-tag[data-tone="red"] {
    background: var(--color-red-light); color: var(--color-red);
  }
`;
