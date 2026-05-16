"use client";

import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { Suspense, useEffect, useMemo, useState } from "react";
import { PaywallSheet } from "@/app/_components/PaywallSheet";
import { TargetPathBanner } from "@/app/_components/TargetPathBanner";
import { ApiException, attemptApi, statsApi, themeApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import {
  canAccessModule,
  type Module as ModuleEnum,
  type ThemeUserResponse,
  type UserStatsResponse,
} from "@/lib/types";

const DEMO_BATCH_SIZE = 20;
const PREMIUM_BATCH_SIZE = 30;

type Filter = "CIVIQUE" | "TCF";

export default function EntrainementPage() {
  return (
    <Suspense fallback={<EntrainementSkeleton />}>
      <EntrainementInner />
    </Suspense>
  );
}

function EntrainementInner() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { user, status } = useAuth();

  // Filter pré-rempli depuis le query string (?module=CIVIQUE|TCF) — utilisé
  // par les shortcuts du dashboard pour atterrir sur le bon module. Par
  // défaut Civique : on entraîne toujours un module à la fois, pas un mélange.
  const initialFilter: Filter = useMemo(() => {
    const m = searchParams?.get("module");
    if (m === "TCF") return "TCF";
    return "CIVIQUE";
  }, [searchParams]);

  const [filter, setFilter] = useState<Filter>(initialFilter);
  const [query, setQuery] = useState("");
  const [themes, setThemes] = useState<Record<ModuleEnum, ThemeUserResponse[]>>({
    CIVIQUE: [],
    TCF: [],
  });
  const [statsByModule, setStatsByModule] = useState<
    Partial<Record<ModuleEnum, UserStatsResponse | null>>
  >({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [startingThemeId, setStartingThemeId] = useState<string | null>(null);
  const [paywallModule, setPaywallModule] = useState<ModuleEnum | null>(null);

  // Charge thèmes + stats des modules accessibles ou en démo. On charge
  // toujours les deux pour pouvoir afficher la grille complète et basculer
  // sans re-fetch.
  useEffect(() => {
    if (status !== "authenticated" || !user) return;
    let cancelled = false;
    setLoading(true);
    Promise.allSettled([
      themeApi.list("CIVIQUE"),
      themeApi.list("TCF"),
      statsApi.get("CIVIQUE").catch(() => null),
      statsApi.get("TCF").catch(() => null),
    ]).then((results) => {
      if (cancelled) return;
      const [civT, tcfT, civS, tcfS] = results;
      setThemes({
        CIVIQUE: civT.status === "fulfilled" ? civT.value : [],
        TCF: tcfT.status === "fulfilled" ? tcfT.value : [],
      });
      setStatsByModule({
        CIVIQUE: civS.status === "fulfilled" ? civS.value : null,
        TCF: tcfS.status === "fulfilled" ? tcfS.value : null,
      });
      setLoading(false);
    });
    return () => {
      cancelled = true;
    };
  }, [status, user]);

  const isPremiumCivique = user !== null && canAccessModule(user, "CIVIQUE");
  const isPremiumTcf = user !== null && canAccessModule(user, "TCF");
  const showDemoBanner = user !== null && (!isPremiumCivique || !isPremiumTcf);

  // ========== STARTERS ==========
  async function startMixed(module: ModuleEnum) {
    const isPremium = module === "CIVIQUE" ? isPremiumCivique : isPremiumTcf;
    setError(null);
    setStartingThemeId(`__mixed_${module}`);
    try {
      const a = await attemptApi.start({
        type: "TRAINING",
        module,
        size: isPremium ? PREMIUM_BATCH_SIZE : DEMO_BATCH_SIZE,
      });
      router.push(`/sessions/${a.id}`);
    } catch (err) {
      setError(
        err instanceof ApiException
          ? err.message
          : "Impossible de démarrer l'entraînement.",
      );
      setStartingThemeId(null);
    }
  }

  async function startTheme(theme: ThemeUserResponse) {
    const isPremium =
      theme.module === "CIVIQUE" ? isPremiumCivique : isPremiumTcf;
    if (!isPremium) {
      setPaywallModule(theme.module);
      return;
    }
    setError(null);
    setStartingThemeId(theme.id);
    try {
      const a = await attemptApi.start({
        type: "TRAINING",
        module: theme.module,
        themeId: theme.id,
        size: PREMIUM_BATCH_SIZE,
      });
      router.push(`/sessions/${a.id}`);
    } catch (err) {
      setError(
        err instanceof ApiException
          ? err.message
          : "Impossible de démarrer l'entraînement.",
      );
      setStartingThemeId(null);
    }
  }

  // ========== DERIVED ==========
  const mastery = useMemo(
    () => buildMastery(statsByModule),
    [statsByModule],
  );

  const filteredThemes = useMemo(() => {
    const list = themes[filter] ?? [];
    const q = query.trim().toLowerCase();
    if (!q) return list;
    return list.filter(
      (t) =>
        t.name.toLowerCase().includes(q) ||
        t.code.toLowerCase().includes(q),
    );
  }, [filter, query, themes]);

  const visibleMixedModules: ModuleEnum[] = useMemo(
    () => (query.trim() ? [] : [filter]),
    [filter, query],
  );

  // ========== GUARDS ==========
  if (status === "loading") return <EntrainementSkeleton />;
  if (!user) {
    return (
      <main className="train-empty">
        <p>Connectez-vous pour vous entraîner.</p>
        <Link href="/connexion?next=/entrainement" className="train-empty-cta">
          Se connecter →
        </Link>
        <style>{emptyStyle}</style>
      </main>
    );
  }

  return (
    <main className="train">
      {/* ============ TOPBAR ============ */}
      <header className="topbar">
        <div>
          <div className="breadcrumb">
            ACCUEIL <span className="sep">/</span> ENTRAÎNEMENT
          </div>
          <h1>
            Choisissez une <em>thématique</em>.
          </h1>
        </div>
        <div className="topbar-actions">
          <Link href="/revision" className="btn-outline">
            Mes erreurs
          </Link>
        </div>
      </header>

      {/* parcours visé */}
      {user.targetProcedure && (
        <div className="train-target">
          <TargetPathBanner
            procedure={user.targetProcedure ?? null}
            level={user.targetLevel ?? null}
          />
        </div>
      )}

      {/* démo banner */}
      {showDemoBanner && (
        <DemoBanner
          isPremiumCivique={isPremiumCivique}
          isPremiumTcf={isPremiumTcf}
          onOpenPaywall={(m) => setPaywallModule(m)}
        />
      )}

      {/* ============ FILTERS ============ */}
      <div className="filters">
        <div className="filter-tabs" role="tablist" aria-label="Module">
          <button
            type="button"
            role="tab"
            aria-selected={filter === "CIVIQUE"}
            className={`tab tab-blue ${filter === "CIVIQUE" ? "is-active" : ""}`}
            onClick={() => setFilter("CIVIQUE")}
          >
            Civique
          </button>
          <button
            type="button"
            role="tab"
            aria-selected={filter === "TCF"}
            className={`tab tab-red ${filter === "TCF" ? "is-active" : ""}`}
            onClick={() => setFilter("TCF")}
          >
            TCF
          </button>
        </div>
        <div className="search-wrap">
          <svg
            width="14"
            height="14"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
            aria-hidden
          >
            <circle cx="11" cy="11" r="8" />
            <line x1="21" y1="21" x2="16.65" y2="16.65" />
          </svg>
          <input
            type="search"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Rechercher un thème…"
            aria-label="Rechercher une thématique"
          />
        </div>
      </div>

      {error && <div className="form-error train-error">{error}</div>}

      {/* ============ GRID ============ */}
      {loading ? (
        <ThemesGridSkeleton />
      ) : (
        <div className="theme-grid">
          {visibleMixedModules.map((m) => (
            <MixedCard
              key={`mixed-${m}`}
              module={m}
              isPremium={m === "CIVIQUE" ? isPremiumCivique : isPremiumTcf}
              onClick={() => startMixed(m)}
              starting={startingThemeId === `__mixed_${m}`}
            />
          ))}
          {filteredThemes.map((t) => (
            <ThemeTile
              key={t.id}
              theme={t}
              mastery={mastery.byTheme[t.id] ?? null}
              isPremium={
                t.module === "CIVIQUE" ? isPremiumCivique : isPremiumTcf
              }
              onClick={() => startTheme(t)}
              starting={startingThemeId === t.id}
            />
          ))}
          {filteredThemes.length === 0 && visibleMixedModules.length === 0 && (
            <div className="theme-empty">
              <p>Aucun thème ne correspond à votre recherche.</p>
              <button
                type="button"
                className="theme-empty-cta"
                onClick={() => setQuery("")}
              >
                Effacer la recherche
              </button>
            </div>
          )}
        </div>
      )}

      <PaywallSheet
        open={paywallModule !== null}
        onClose={() => setPaywallModule(null)}
        title={
          paywallModule === "TCF"
            ? "Débloquez tout le TCF IRN"
            : "Choisissez votre thématique"
        }
        message={
          paywallModule === "TCF"
            ? "Vous avez 20 questions de découverte et 1 examen blanc offerts en TCF. L'abonnement Intégral débloque l'entraînement illimité TCF + Civique, les examens blancs sans limite et la révision des erreurs."
            : "L'entraînement par thématique est réservé aux abonnés. Avec l'abonnement Civique, débloquez tous les thèmes et l'entraînement illimité."
        }
        plan={paywallModule === "TCF" ? "INTEGRAL_3MOIS" : "CIVIQUE_3MOIS"}
      />

      <style>{styles}</style>
    </main>
  );
}

// ============================================================================
// SUB-COMPONENTS
// ============================================================================

function DemoBanner({
  isPremiumCivique,
  isPremiumTcf,
  onOpenPaywall,
}: {
  isPremiumCivique: boolean;
  isPremiumTcf: boolean;
  onOpenPaywall: (m: ModuleEnum) => void;
}) {
  const locked: ModuleEnum[] = [];
  if (!isPremiumCivique) locked.push("CIVIQUE");
  if (!isPremiumTcf) locked.push("TCF");
  const lockedLabel = locked
    .map((m) => (m === "TCF" ? "TCF" : "Civique"))
    .join(" + ");
  const upsell: ModuleEnum = !isPremiumCivique ? "CIVIQUE" : "TCF";
  return (
    <button
      type="button"
      className="demo-banner"
      onClick={() => onOpenPaywall(upsell)}
    >
      <div className="demo-banner-icon" aria-hidden>
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
          <path d="M12 2l3 7h7l-5.5 4 2 7L12 16l-6.5 4 2-7L2 9h7z" />
        </svg>
      </div>
      <div className="demo-banner-content">
        <div className="demo-banner-title">
          Mode démo {lockedLabel} · {DEMO_BATCH_SIZE} questions par session
        </div>
        <div className="demo-banner-sub">
          Cliquez sur une thématique en démo pour déclencher la session mixte.
          Activez l&apos;abonnement pour débloquer l&apos;entraînement par thème
          et l&apos;illimité.
        </div>
      </div>
      <div className="demo-banner-arrow" aria-hidden>
        →
      </div>
    </button>
  );
}

function MixedCard({
  module,
  isPremium,
  onClick,
  starting,
}: {
  module: ModuleEnum;
  isPremium: boolean;
  onClick: () => void;
  starting: boolean;
}) {
  const isCivique = module === "CIVIQUE";
  const label = isCivique ? "Civique mixte" : "TCF mixte";
  const desc = isCivique
    ? "Toutes thématiques mélangées · l'entraînement le plus polyvalent."
    : "CO + CE + Structure mélangés · pour réviser large.";
  const tag = isCivique ? "CIVIQUE · TOUT" : "TCF · TOUT";
  const size = isPremium ? PREMIUM_BATCH_SIZE : DEMO_BATCH_SIZE;
  return (
    <button
      type="button"
      className={`theme-card mixed mixed-${isCivique ? "blue" : "red"}`}
      onClick={onClick}
      disabled={starting}
    >
      <div className="theme-card-head">
        <span className={`theme-tag ${isCivique ? "tag-civique" : "tag-tcf"}`}>
          {tag}
        </span>
        <span className="theme-mixed-icon" aria-hidden>
          {isCivique ? "⚜" : "✶"}
        </span>
      </div>
      <h4 className="theme-card-title">{label}</h4>
      <p className="theme-card-desc">{desc}</p>
      <div className="theme-card-foot">
        <span>
          {size} QUESTIONS{isPremium ? "" : " · DÉMO"}
        </span>
        <span className="theme-card-start">
          {starting ? "…" : "Démarrer →"}
        </span>
      </div>
    </button>
  );
}

function ThemeTile({
  theme,
  mastery,
  isPremium,
  onClick,
  starting,
}: {
  theme: ThemeUserResponse;
  mastery: { pct: number; answered: number; total: number } | null;
  isPremium: boolean;
  onClick: () => void;
  starting: boolean;
}) {
  const isCivique = theme.module === "CIVIQUE";
  const tone = mastery ? toneFor(mastery.pct) : null;
  const tagLabel = `${isCivique ? "CIVIQUE" : "TCF"} · ${theme.code}`;
  const desc = themeBlurb(theme.code);

  return (
    <button
      type="button"
      className={`theme-card ${!isPremium ? "is-locked" : ""} ${
        tone === "red" ? "border-red" : tone === "amber" ? "border-amber" : ""
      }`}
      onClick={onClick}
      disabled={starting}
    >
      {!isPremium && (
        <span className="theme-lock" aria-hidden>
          🔒
        </span>
      )}
      <div className="theme-card-head">
        <span className={`theme-tag ${isCivique ? "tag-civique" : "tag-tcf"}`}>
          {tagLabel}
        </span>
        {mastery && (
          <span className={`theme-mastery theme-mastery-${tone}`}>
            {mastery.pct}%
          </span>
        )}
      </div>
      <h4 className="theme-card-title">{theme.name}</h4>
      {desc && <p className="theme-card-desc">{desc}</p>}
      <div className="theme-bar">
        <div
          className={`theme-bar-fill theme-bar-${tone ?? "blue"}`}
          style={{ width: `${Math.max(2, mastery?.pct ?? 0)}%` }}
        />
      </div>
      <div className="theme-card-foot">
        <span>
          {mastery
            ? `${mastery.answered} / ${theme.questionCount ?? mastery.total} QUESTIONS`
            : `${theme.questionCount ?? "—"} QUESTIONS`}
        </span>
        <span className="theme-card-start">
          {starting ? "…" : isPremium ? "Démarrer →" : "Débloquer →"}
        </span>
      </div>
    </button>
  );
}

// ============================================================================
// HELPERS
// ============================================================================
function buildMastery(stats: Partial<Record<ModuleEnum, UserStatsResponse | null>>) {
  const byTheme: Record<string, { pct: number; answered: number; total: number }> = {};
  (["CIVIQUE", "TCF"] as ModuleEnum[]).forEach((m) => {
    const list = stats[m]?.byTheme ?? [];
    for (const t of list) {
      if (t.answered === 0) {
        byTheme[t.themeId] = { pct: 0, answered: 0, total: t.total };
        continue;
      }
      byTheme[t.themeId] = {
        pct: Math.round((t.correct / t.answered) * 100),
        answered: t.answered,
        total: t.total,
      };
    }
  });
  return { byTheme };
}

function toneFor(pct: number): "green" | "blue" | "amber" | "red" {
  if (pct >= 80) return "green";
  if (pct >= 65) return "blue";
  if (pct >= 45) return "amber";
  return "red";
}

/** Petite description éditoriale par thème (clé = code backend connu). Les
 *  codes inconnus retombent sur une chaîne vide → la card masque la ligne. */
function themeBlurb(code: string): string {
  const map: Record<string, string> = {
    PRINCIPES: "Devise, symboles, laïcité, République",
    INSTITUTIONS: "Président, gouvernement, parlement",
    DROITS_DEVOIRS: "Citoyenneté, libertés, obligations",
    HISTOIRE_GEO: "Révolution, République, géographie",
    SOCIETE: "Vie quotidienne, services, mises en situation",
    CO: "Audios, dialogues, exposés",
    CE: "SMS, e-mails, articles, annonces",
    STRUCTURE: "Grammaire, lexique, conjugaison",
  };
  return map[code] ?? "";
}

// ============================================================================
// SKELETONS
// ============================================================================
function EntrainementSkeleton() {
  return (
    <div className="train-loading">
      <style>{`
        .train-loading {
          min-height: calc(100vh - 80px);
          background: #F7F8FC;
        }
      `}</style>
    </div>
  );
}

function ThemesGridSkeleton() {
  return (
    <div className="theme-grid">
      {Array.from({ length: 6 }).map((_, i) => (
        <div key={i} className="theme-skel" />
      ))}
      <style>{`
        .theme-skel {
          height: 180px;
          background: #fff;
          border: 1px solid var(--color-line);
          border-radius: 16px;
          animation: theme-pulse 1.4s ease-in-out infinite;
        }
        @keyframes theme-pulse {
          0%, 100% { opacity: 0.55; }
          50% { opacity: 1; }
        }
      `}</style>
    </div>
  );
}

const emptyStyle = `
  .train-empty {
    min-height: 60vh;
    display: flex; flex-direction: column; align-items: center; justify-content: center;
    gap: 14px;
    color: var(--color-muted);
    padding: 36px;
  }
  .train-empty-cta {
    font-weight: 700; color: var(--color-blue);
    text-decoration: none;
  }
`;

// ============================================================================
// STYLES
// ============================================================================
const styles = `
  .train { padding: 24px 36px 64px; max-width: 1320px; }
  @media (max-width: 760px) { .train { padding: 20px 16px 56px; } }

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
    display: inline-flex; align-items: center; justify-content: center; gap: 8px;
    padding: 10px 16px; border-radius: 10px;
    font-size: 13px; font-weight: 600;
    text-decoration: none;
    border: 1px solid var(--color-line);
    background: #fff;
    color: var(--color-ink);
    transition: all 0.15s;
  }
  .btn-outline:hover { border-color: var(--color-blue); color: var(--color-blue); }

  .train-target { margin-bottom: 18px; }
  .train-error { margin-bottom: 18px; }

  /* ========== DEMO BANNER ========== */
  .demo-banner {
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
  .demo-banner:hover {
    background: linear-gradient(135deg, rgba(232, 163, 23, 0.14), rgba(232, 163, 23, 0.04));
    transform: translateY(-1px);
  }
  .demo-banner-icon {
    width: 40px; height: 40px;
    background: var(--color-amber);
    color: #fff;
    border-radius: 11px;
    display: flex; align-items: center; justify-content: center;
    flex-shrink: 0;
  }
  .demo-banner-content { flex: 1; min-width: 0; }
  .demo-banner-title {
    font-weight: 700; font-size: 14px;
    color: var(--color-ink);
    line-height: 1.25;
  }
  .demo-banner-sub {
    font-size: 12.5px; color: var(--color-muted);
    line-height: 1.4; margin-top: 4px;
  }
  .demo-banner-arrow {
    color: var(--color-amber);
    font-size: 18px; font-weight: 700;
    flex-shrink: 0;
  }

  /* ========== FILTERS ========== */
  .filters {
    display: flex; gap: 12px; align-items: center; flex-wrap: wrap;
    margin-bottom: 22px;
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
  .tab.tab-blue.is-active {
    background: var(--color-blue);
    color: #fff;
  }
  .tab.tab-red.is-active {
    background: var(--color-red);
    color: #fff;
  }

  .search-wrap {
    position: relative;
    margin-left: auto;
  }
  .search-wrap svg {
    position: absolute;
    left: 12px; top: 50%;
    transform: translateY(-50%);
    color: var(--color-muted);
  }
  .search-wrap input {
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 10px;
    padding: 9px 14px 9px 36px;
    font-family: inherit;
    font-size: 13px;
    width: 260px;
    color: var(--color-ink);
    transition: border-color 0.15s, box-shadow 0.15s;
  }
  .search-wrap input:focus {
    outline: none;
    border-color: var(--color-blue);
    box-shadow: 0 0 0 3px rgba(30, 58, 140, 0.12);
  }

  /* ========== GRID ========== */
  .theme-grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 16px;
  }
  .theme-card {
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 16px;
    padding: 18px;
    cursor: pointer;
    text-align: left;
    font-family: inherit;
    transition: all 0.15s;
    position: relative;
    display: flex;
    flex-direction: column;
    min-height: 180px;
  }
  .theme-card:hover:not(:disabled) {
    border-color: var(--color-blue);
    transform: translateY(-3px);
    box-shadow: 0 14px 30px -16px rgba(15, 24, 57, 0.18);
  }
  .theme-card:disabled { opacity: 0.6; cursor: progress; }
  .theme-card.border-amber { border-color: rgba(232, 163, 23, 0.6); }
  .theme-card.border-red { border-color: rgba(225, 55, 47, 0.6); }
  .theme-card.is-locked {
    background:
      repeating-linear-gradient(45deg, var(--color-paper) 0 6px, #fff 6px 14px);
  }
  .theme-lock {
    position: absolute; top: 18px; right: 18px;
    font-size: 13px;
    opacity: 0.5;
  }

  .theme-card-head {
    display: flex; justify-content: space-between; align-items: center;
    margin-bottom: 14px;
    gap: 10px;
  }
  .theme-tag {
    display: inline-block;
    font-family: var(--font-mono);
    font-size: 10px;
    letter-spacing: 0.1em;
    padding: 3px 8px;
    border-radius: 5px;
    font-weight: 700;
  }
  .tag-civique { background: var(--color-blue-light); color: var(--color-blue); }
  .tag-tcf { background: var(--color-red-light); color: var(--color-red); }

  .theme-mastery {
    font-family: var(--font-mono);
    font-size: 11px;
    font-weight: 700;
    color: var(--color-muted);
  }
  .theme-mastery-green { color: var(--color-green); }
  .theme-mastery-blue { color: var(--color-blue); }
  .theme-mastery-amber { color: var(--color-amber); }
  .theme-mastery-red { color: var(--color-red); }

  .theme-card-title {
    font-family: var(--font-display);
    font-size: 17px;
    margin: 0 0 6px;
    font-weight: 600;
    letter-spacing: -0.01em;
    color: var(--color-ink);
  }
  .theme-card-desc {
    color: var(--color-muted);
    font-size: 12.5px;
    margin: 0 0 14px;
    line-height: 1.45;
    flex: 1;
  }
  .theme-bar {
    height: 6px;
    background: var(--color-line-2);
    border-radius: 3px;
    overflow: hidden;
    margin-bottom: 12px;
  }
  .theme-bar-fill {
    height: 100%; border-radius: 3px;
    background: var(--color-blue);
    transition: width 0.3s;
  }
  .theme-bar-green { background: var(--color-green); }
  .theme-bar-blue { background: var(--color-blue); }
  .theme-bar-amber { background: var(--color-amber); }
  .theme-bar-red { background: var(--color-red); }

  .theme-card-foot {
    display: flex; justify-content: space-between; align-items: center;
    font-family: var(--font-mono);
    font-size: 11px;
    color: var(--color-muted);
    letter-spacing: 0.05em;
  }
  .theme-card-start {
    color: var(--color-blue);
    font-weight: 700;
    font-family: var(--font-sans);
    font-size: 12px;
    letter-spacing: 0;
  }
  .theme-card:hover .theme-card-start { text-decoration: underline; }

  /* Mixed cards : visuel renforcé pour aimanter l'œil */
  .theme-card.mixed {
    background:
      radial-gradient(at 100% 0%, rgba(30, 58, 140, 0.06) 0px, transparent 50%),
      #fff;
    border-width: 1.5px;
  }
  .theme-card.mixed.mixed-red {
    background:
      radial-gradient(at 100% 0%, rgba(225, 55, 47, 0.06) 0px, transparent 50%),
      #fff;
  }
  .theme-mixed-icon {
    color: var(--color-blue);
    font-size: 20px;
  }
  .mixed.mixed-red .theme-mixed-icon { color: var(--color-red); }

  /* Empty */
  .theme-empty {
    grid-column: 1 / -1;
    text-align: center;
    padding: 60px 20px;
    color: var(--color-muted);
  }
  .theme-empty p { margin: 0 0 12px; font-size: 14px; }
  .theme-empty-cta {
    background: none; border: none;
    color: var(--color-blue);
    font-family: inherit;
    font-weight: 700;
    font-size: 13px;
    cursor: pointer;
  }
  .theme-empty-cta:hover { text-decoration: underline; }

  /* ========== RESPONSIVE ========== */
  @media (max-width: 1100px) {
    .theme-grid { grid-template-columns: repeat(2, 1fr); }
  }
  @media (max-width: 680px) {
    .theme-grid { grid-template-columns: 1fr; }
    .search-wrap { margin-left: 0; width: 100%; }
    .search-wrap input { width: 100%; }
  }
`;
