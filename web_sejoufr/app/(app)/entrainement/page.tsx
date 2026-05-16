"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useMemo, useState } from "react";
import { ModuleSwitch } from "@/app/_components/ModuleSwitch";
import { TargetPathBanner } from "@/app/_components/TargetPathBanner";
import { PaywallSheet } from "@/app/_components/PaywallSheet";
import { ThemeCard } from "@/app/_components/ThemeCard";
import { ApiException, attemptApi, themeApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import {
  canAccessModule,
  type AuthenticatedUser,
  type Module as ModuleEnum,
  type ThemeUserResponse,
} from "@/lib/types";

const DEMO_BATCH_SIZE = 20;
const PREMIUM_BATCH_SIZE = 30;

export default function EntrainementPage() {
  const router = useRouter();
  const { user, status } = useAuth();

  const [module, setModule] = useState<ModuleEnum>("CIVIQUE");
  const [themes, setThemes] = useState<ThemeUserResponse[]>([]);
  const [themesLoading, setThemesLoading] = useState(false);
  const [selectedThemeId, setSelectedThemeId] = useState<string | null>(null);
  const [starting, setStarting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showPaywall, setShowPaywall] = useState(false);

  // L'utilisateur a-t-il l'abonnement payant pour le MODULE actuellement sélectionné ?
  // CIVIQUE_3MOIS débloque civique seulement ; INTEGRAL_3MOIS débloque les deux.
  // Quand il n'a pas l'accès payant pour ce module : on tombe en mode démo
  // (20 questions par session, pas de choix de thème). Cette règle vaut pour
  // CIVIQUE comme pour TCF — l'app mobile suit la même logique.
  const isPremiumForModule = user !== null && canAccessModule(user, module);
  // Plan à pousser dans le paywall selon le module verrouillé.
  const upsellPlan = module === "TCF" ? "INTEGRAL_3MOIS" : "CIVIQUE_3MOIS";

  // Charge les thèmes du module sélectionné.
  useEffect(() => {
    if (status !== "authenticated") return;
    let cancelled = false;
    setThemes([]);
    setSelectedThemeId(null);
    setError(null);
    setThemesLoading(true);
    themeApi
      .list(module)
      .then((list) => {
        if (cancelled) return;
        setThemes(list);
      })
      .catch(() => {
        if (cancelled) return;
        setError("Impossible de charger les thèmes.");
      })
      .finally(() => {
        if (!cancelled) setThemesLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [module, status]);

  async function startSession() {
    setError(null);
    setStarting(true);
    try {
      const a = await attemptApi.start({
        type: "TRAINING",
        module,
        // En démo : pas de thème (mélange varié). En premium : sélection si définie.
        themeId: isPremiumForModule ? (selectedThemeId ?? undefined) : undefined,
        size: isPremiumForModule ? PREMIUM_BATCH_SIZE : DEMO_BATCH_SIZE,
      });
      // L'URL devient partageable, reload-friendly, et le runner gère lui-même
      // le préchargement des favoris. Route générique partagée avec les examens.
      router.push(`/sessions/${a.id}`);
    } catch (err) {
      setError(err instanceof ApiException ? err.message : "Impossible de démarrer l'entraînement.");
      setStarting(false);
    }
  }

  const helperText = useMemo(() => {
    if (!isPremiumForModule) {
      const label = module === "TCF" ? "TCF IRN" : "Civique";
      return `Mode démo ${label} · ${DEMO_BATCH_SIZE} questions offertes`;
    }
    if (selectedThemeId) {
      const t = themes.find((x) => x.id === selectedThemeId);
      return `${t?.name ?? "Thématique"} · entraînement illimité`;
    }
    return "Toutes thématiques · entraînement illimité";
  }, [isPremiumForModule, module, selectedThemeId, themes]);

  if (status === "loading") {
    return <div className="train-loading" />;
  }

  if (!user) {
    return (
      <main className="train-empty">
        <p>Connectez-vous pour vous entraîner.</p>
        <Link href="/connexion?next=/entrainement" className="btn btn-blue">Se connecter</Link>
      </main>
    );
  }

  return (
    <main className="train">
      <SetupView
        isPremiumForModule={isPremiumForModule}
        user={user}
        module={module}
        onModule={setModule}
        themes={themes}
        themesLoading={themesLoading}
        selectedThemeId={selectedThemeId}
        onSelectTheme={(id) => setSelectedThemeId(id)}
        helperText={helperText}
        starting={starting}
        error={error}
        onStart={startSession}
        onLockedThemeTap={() => setShowPaywall(true)}
      />

      <PaywallSheet
        open={showPaywall}
        onClose={() => setShowPaywall(false)}
        title={
          module === "TCF"
            ? "Débloquez tout le TCF IRN"
            : "Choisissez votre thématique"
        }
        message={
          module === "TCF"
            ? "Vous avez 20 questions de découverte et 1 examen blanc offerts en TCF. L'abonnement Intégral débloque l'entraînement illimité TCF + Civique, les examens blancs sans limite et la révision des erreurs."
            : "L'entraînement par thématique est réservé aux abonnés. Avec l'abonnement, débloquez tous les thèmes et l'entraînement illimité."
        }
        plan={upsellPlan}
      />

      <style>{trainStyles}</style>
    </main>
  );
}

// ============================================================================
// SETUP VIEW
// ============================================================================

interface SetupViewProps {
  isPremiumForModule: boolean;
  user: AuthenticatedUser;
  module: ModuleEnum;
  onModule: (m: ModuleEnum) => void;
  themes: ThemeUserResponse[];
  themesLoading: boolean;
  selectedThemeId: string | null;
  onSelectTheme: (id: string | null) => void;
  helperText: string;
  starting: boolean;
  error: string | null;
  onStart: () => void;
  onLockedThemeTap: () => void;
}

function SetupView({
  isPremiumForModule,
  user,
  module,
  onModule,
  themes,
  themesLoading,
  selectedThemeId,
  onSelectTheme,
  helperText,
  starting,
  error,
  onStart,
  onLockedThemeTap,
}: SetupViewProps) {
  const demoBannerLabel = module === "TCF" ? "TCF IRN" : "Civique";
  const demoBannerSub = module === "TCF"
    ? "Activez l'Intégral pour l'entraînement TCF illimité + Civique inclus."
    : "Activez l'abonnement pour l'entraînement illimité et tous les thèmes.";
  return (
    <section className="setup">
      <div className="setup-wrap">
        <header className="setup-head">
          <span className="eyebrow">Entraînement</span>
          <h1>
            Entraînement <em>libre</em>.
          </h1>
          <p>
            Enchaînez les questions sans limite, à votre rythme. Vous pouvez
            quitter quand vous voulez, votre progression est conservée.
          </p>
        </header>

        {(user.targetProcedure || user.targetLevel) && (
          <div className="setup-banner">
            <TargetPathBanner
              procedure={user.targetProcedure ?? null}
              level={user.targetLevel ?? null}
            />
          </div>
        )}

        <div className="setup-row">
          <label className="setup-label">Module</label>
          <ModuleSwitch value={module} onChange={onModule} />
        </div>

        {!isPremiumForModule && (
          <button
            type="button"
            className="demo-banner"
            onClick={onLockedThemeTap}
          >
            <div className="demo-banner-icon" aria-hidden>
              <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <path d="M12 2l3 7h7l-5.5 4 2 7L12 16l-6.5 4 2-7L2 9h7z" />
              </svg>
            </div>
            <div className="demo-banner-content">
              <div className="demo-banner-title">Mode démo {demoBannerLabel} · {DEMO_BATCH_SIZE} questions</div>
              <div className="demo-banner-sub">{demoBannerSub}</div>
            </div>
            <div className="demo-banner-arrow">→</div>
          </button>
        )}

        <div className="setup-row">
          <div className="setup-label-row">
            <label className="setup-label">Thématique</label>
            <span className="setup-label-hint">
              {isPremiumForModule ? "optionnel" : "réservé aux abonnés"}
            </span>
          </div>

          {themesLoading ? (
            <div className="themes-skeleton">
              {[0, 1, 2, 3].map((i) => (
                <div key={i} className="themes-skeleton-tile" />
              ))}
            </div>
          ) : (
            <div className="themes-list">
              <ThemeCard
                theme={null}
                selected={!isPremiumForModule || selectedThemeId === null}
                locked={false}
                onClick={() => onSelectTheme(null)}
              />
              {themes.map((t) => (
                <ThemeCard
                  key={t.id}
                  theme={t}
                  selected={isPremiumForModule && selectedThemeId === t.id}
                  locked={!isPremiumForModule}
                  onClick={() => {
                    if (!isPremiumForModule) {
                      onLockedThemeTap();
                      return;
                    }
                    onSelectTheme(selectedThemeId === t.id ? null : t.id);
                  }}
                />
              ))}
            </div>
          )}
        </div>

        {error && <div className="form-error">{error}</div>}

        <div className="setup-cta-wrap">
          <div className="setup-cta-helper">
            <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <circle cx="12" cy="12" r="10" />
              <path d="M12 16v-4M12 8h.01" />
            </svg>
            {helperText}
          </div>
          <button
            type="button"
            className="btn btn-red btn-lg setup-cta"
            onClick={onStart}
            disabled={starting}
          >
            {starting
              ? "Préparation…"
              : isPremiumForModule
                ? "Commencer l'entraînement →"
                : "Commencer la démo →"}
          </button>
        </div>
      </div>
    </section>
  );
}

// ============================================================================
// STYLES
// ============================================================================

const trainStyles = `
  .train { background: var(--color-paper); min-height: calc(100vh - 110px); }
  .train-loading { min-height: 60vh; }
  .train-empty {
    min-height: 60vh;
    display: flex; flex-direction: column; align-items: center; justify-content: center;
    gap: 14px;
    color: var(--color-muted);
  }

  .setup { padding: 32px 16px 64px; }
  .setup-wrap { max-width: 640px; margin: 0 auto; }

  .setup-head { text-align: center; margin: 0 auto 28px; }
  .setup-head h1 {
    font-family: var(--font-display); font-weight: 500;
    font-size: clamp(28px, 4vw, 40px);
    line-height: 1.05; letter-spacing: -0.025em;
    margin: 10px 0 12px;
  }
  .setup-head h1 em { font-style: italic; color: var(--color-red); }
  .setup-head p {
    color: var(--color-muted);
    font-size: 15px; line-height: 1.55;
    margin: 0 auto; max-width: 480px;
  }

  .setup-banner { margin-bottom: 22px; }
  .setup-row { margin-bottom: 24px; }
  .setup-label {
    display: block;
    font-family: var(--font-mono); font-size: 10px;
    letter-spacing: 0.14em; text-transform: uppercase;
    color: var(--color-muted);
    margin-bottom: 10px;
    font-weight: 600;
  }
  .setup-label-row {
    display: flex; align-items: baseline; gap: 10px;
    margin-bottom: 10px;
  }
  .setup-label-row .setup-label { margin-bottom: 0; }
  .setup-label-hint {
    font-size: 11.5px;
    color: var(--color-muted-2);
  }

  .demo-banner {
    display: flex; align-items: center; gap: 12px;
    width: 100%;
    background: rgba(232, 163, 23, 0.08);
    border: 1px solid rgba(232, 163, 23, 0.35);
    border-radius: 14px;
    padding: 12px 14px;
    margin-bottom: 22px;
    cursor: pointer;
    transition: background 0.15s;
    text-align: left;
    font-family: var(--font-sans);
  }
  .demo-banner:hover { background: rgba(232, 163, 23, 0.14); }
  .demo-banner-icon {
    width: 38px; height: 38px;
    background: rgba(232, 163, 23, 0.16);
    color: var(--color-amber);
    border-radius: 11px;
    display: flex; align-items: center; justify-content: center;
    flex-shrink: 0;
  }
  .demo-banner-content { flex: 1; min-width: 0; }
  .demo-banner-title {
    font-weight: 800; font-size: 13.5px;
    color: var(--color-ink);
    line-height: 1.2;
  }
  .demo-banner-sub {
    font-size: 12px; color: var(--color-muted);
    line-height: 1.4; margin-top: 3px;
  }
  .demo-banner-arrow {
    color: var(--color-amber);
    font-size: 16px;
    flex-shrink: 0;
  }

  .themes-list {
    display: flex; flex-direction: column; gap: 10px;
  }
  .themes-skeleton {
    display: flex; flex-direction: column; gap: 10px;
  }
  .themes-skeleton-tile {
    height: 72px;
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 14px;
    animation: themes-pulse 1.4s ease-in-out infinite;
  }
  @keyframes themes-pulse {
    0%, 100% { opacity: 0.55; }
    50% { opacity: 1; }
  }

  .setup-cta-wrap {
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 14px;
    padding: 16px;
    margin-top: 6px;
    box-shadow: 0 12px 28px -16px rgba(15, 24, 57, 0.18);
  }
  .setup-cta-helper {
    display: flex; align-items: center; gap: 8px;
    color: var(--color-muted);
    font-size: 12.5px;
    margin-bottom: 12px;
  }
  .setup-cta { width: 100%; }

  @media (max-width: 560px) {
    .setup { padding: 24px 12px 56px; }
    .setup-head h1 { font-size: 26px; }
  }
`;
