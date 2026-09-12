"use client";

import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { Suspense, useEffect, useState } from "react";
import { ApiException, userContentApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import { safeInternalPath } from "@/lib/security";
import { TCF_LEVEL_BY_PROCEDURE, type TargetLevel, type TargetProcedure } from "@/lib/types";

/**
 * Édition du parcours administratif visé. Sert aussi d'onboarding intégré :
 * un utilisateur qui n'a pas encore choisi peut atterrir ici depuis le
 * bandeau du dashboard.
 *
 * Le query param `?from=...` permet de revenir à la route appelante après le
 * save (sinon redirige vers /profil par défaut).
 */
export default function ParcoursPage() {
  return (
    <Suspense fallback={<ParcoursSkeleton />}>
      <ParcoursForm />
    </Suspense>
  );
}

interface PathInfo {
  code: TargetProcedure;
  title: string;
  pitch: string;
  bullets: string[];
  tone: "blue" | "ink" | "red";
}

/** Le palier exigé n'est PAS recopié ici : il vient du référentiel partagé
 *  (`TCF_LEVEL_BY_PROCEDURE`, miroir gelé de l'enum backend). Cet écran en a
 *  tenu sa propre copie, comme `/inscription` et `/profil` — trois tables à
 *  changer le jour où la loi bouge, donc trois occasions d'en oublier une. */
const tcfLevelOf = (code: TargetProcedure): TargetLevel =>
  TCF_LEVEL_BY_PROCEDURE[code];

const PATHS: PathInfo[] = [
  {
    code: "CSP",
    title: "Carte de séjour pluriannuelle",
    pitch: "Premier renouvellement après le visa long séjour. Le palier le plus accessible des trois parcours.",
    bullets: [
      "Renouvellement 2 à 4 ans",
      "Examen civique · mention CSP",
      "Démarches simplifiées",
    ],
    tone: "blue",
  },
  {
    code: "CR",
    title: "Carte de résident",
    pitch: "Stabilité longue durée : 10 ans de validité, droit au travail facilité, démarches administratives allégées.",
    bullets: [
      "Validité 10 ans",
      "Examen civique · mention CR",
      "Travail facilité, voyages plus souples",
    ],
    tone: "ink",
  },
  {
    code: "NAT",
    title: "Naturalisation française",
    pitch: "Devenir français. Le niveau d'exigence le plus élevé en civique comme en langue, mais aussi le plus complet.",
    bullets: [
      "Nationalité française",
      "Examen civique · mention Naturalisation",
      "Droits civiques + passeport",
    ],
    tone: "red",
  },
];

function ParcoursForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  // Chemin interne sûr uniquement (anti open-redirect via ?from=//evil.com).
  const fromParam = safeInternalPath(searchParams.get("from"), "/profil");
  const { user, status, refreshUser } = useAuth();

  const [selected, setSelected] = useState<TargetProcedure | null>(null);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (user?.targetProcedure) {
      // eslint-disable-next-line react-hooks/set-state-in-effect
      setSelected(user.targetProcedure);
    }
  }, [user?.targetProcedure]);

  async function submit() {
    if (!selected) return;
    setError(null);
    setSaving(true);
    try {
      await userContentApi.updateTargetPath(selected);
      await refreshUser();
      router.push(fromParam ?? "/profil");
    } catch (e) {
      setError(
        e instanceof ApiException ? e.message : "Impossible d'enregistrer.",
      );
      setSaving(false);
    }
  }

  if (status === "loading") return <ParcoursSkeleton />;
  if (!user) {
    return (
      <main className="pc-gate">
        <p>Connectez-vous pour définir votre parcours.</p>
        <Link href="/connexion?next=/parcours" className="pc-gate-cta">
          Se connecter →
        </Link>
        <style>{gateStyles}</style>
      </main>
    );
  }

  const isOnboarding = !user.targetProcedure;
  const backHref = fromParam ?? "/profil";
  const hasChange = selected !== null && selected !== user.targetProcedure;

  return (
    <main className="pc">
      {/* ============ TOPBAR ============ */}
      <header className="topbar">
        <div>
          <div className="breadcrumb">
            ACCUEIL <span className="sep">/</span>{" "}
            {!isOnboarding && (
              <>
                <Link href="/profil" className="breadcrumb-link">
                  PROFIL
                </Link>{" "}
                <span className="sep">/</span>{" "}
              </>
            )}
            PARCOURS
          </div>
          <h1>
            {isOnboarding ? (
              <>
                Quelle <em>démarche</em>{" "}
                préparez-vous&nbsp;?
              </>
            ) : (
              <>
                Votre <em>parcours</em> administratif.
              </>
            )}
          </h1>
          <p className="topbar-sub">
            {isOnboarding
              ? "On adapte votre entraînement civique en fonction de votre objectif. Le niveau de TCF requis dépend du parcours visé."
              : "Vous pouvez modifier ce choix à tout moment. L'adaptation prend effet immédiatement sur vos prochaines sessions."}
          </p>
        </div>
        {!isOnboarding && (
          <div className="topbar-actions">
            <Link href={backHref} className="btn-outline">
              ← Retour
            </Link>
          </div>
        )}
      </header>

      {/* ============ CARDS GRID ============ */}
      <section className="pc-grid">
        {PATHS.map((p) => {
          const active = selected === p.code;
          const isCurrent = user.targetProcedure === p.code;
          return (
            <PathCard
              key={p.code}
              info={p}
              active={active}
              isCurrent={isCurrent}
              onSelect={() => setSelected(p.code)}
            />
          );
        })}
      </section>

      {error && <div className="form-error pc-error">{error}</div>}

      {/* ============ ACTION BAR ============ */}
      <div className="pc-actionbar">
        <div className="pc-actionbar-info">
          {selected ? (
            <>
              <span className="pc-actionbar-label">SÉLECTION</span>
              <span className="pc-actionbar-value">
                {PATHS.find((p) => p.code === selected)?.title} ·{" "}
                <strong>{tcfLevelOf(selected)}</strong>
              </span>
            </>
          ) : (
            <span className="pc-actionbar-empty">
              Sélectionnez votre parcours pour continuer
            </span>
          )}
        </div>
        <div className="pc-actionbar-buttons">
          {!isOnboarding && (
            <Link href={backHref} className="btn-outline">
              Annuler
            </Link>
          )}
          <button
            type="button"
            className="btn-primary"
            onClick={submit}
            disabled={!selected || saving || (!isOnboarding && !hasChange)}
          >
            {saving
              ? "Enregistrement…"
              : isOnboarding
                ? "Commencer →"
                : hasChange
                  ? "Enregistrer →"
                  : "Aucun changement"}
          </button>
        </div>
      </div>

      {isOnboarding && (
        <p className="pc-skip">
          Vous pourrez modifier ce choix à tout moment depuis votre profil.
        </p>
      )}

      <style>{styles}</style>
    </main>
  );
}

// ============================================================================
// PATH CARD
// ============================================================================
function PathCard({
  info,
  active,
  isCurrent,
  onSelect,
}: {
  info: PathInfo;
  active: boolean;
  isCurrent: boolean;
  onSelect: () => void;
}) {
  return (
    <button
      type="button"
      role="radio"
      aria-checked={active}
      className={`path-card path-card-${info.tone} ${active ? "is-active" : ""}`}
      onClick={onSelect}
    >
      {isCurrent && (
        <span className="path-current-pill" aria-label="Parcours actuel">
          Actuel
        </span>
      )}
      <div className="path-halo" aria-hidden />
      <div className="path-head">
        <span className={`path-badge path-badge-${info.tone}`}>{info.code}</span>
        <span className={`path-radio ${active ? "is-on" : ""}`} aria-hidden>
          {active && (
            <svg viewBox="0 0 16 16" width="12" height="12">
              <path
                d="M3.5 8l3 3 6-7"
                stroke="#fff"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
                fill="none"
              />
            </svg>
          )}
        </span>
      </div>
      <h2 className="path-title">{info.title}</h2>
      <p className="path-pitch">{info.pitch}</p>
      <div className="path-tcf">
        <span className="path-tcf-label">NIVEAU DE FRANÇAIS</span>
        <span className={`path-tcf-value path-tcf-value-${info.tone}`}>
          {tcfLevelOf(info.code)}
        </span>
      </div>
      <ul className="path-bullets">
        {info.bullets.map((b) => (
          <li key={b}>
            <span className="path-bullet-dot" aria-hidden />
            {b}
          </li>
        ))}
      </ul>
      <div className={`path-state path-state-${info.tone}`}>
        {active ? (
          <>
            <span className="path-check-icon" aria-hidden>
              ✓
            </span>
            Sélectionné
          </>
        ) : (
          <>Choisir ce parcours →</>
        )}
      </div>
    </button>
  );
}

// ============================================================================
// SKELETON
// ============================================================================
function ParcoursSkeleton() {
  return (
    <div className="pc-loading">
      <style>{`.pc-loading { min-height: calc(100vh - 80px); background: #F7F8FC; }`}</style>
    </div>
  );
}

const gateStyles = `
  .pc-gate {
    min-height: 60vh;
    display: flex; flex-direction: column; align-items: center; justify-content: center;
    gap: 14px;
    color: var(--color-muted);
    padding: 36px;
  }
  .pc-gate-cta { color: var(--color-blue); font-weight: 700; text-decoration: none; }
`;

// ============================================================================
// STYLES
// ============================================================================
const styles = `
  .pc {
    padding: 24px 36px 64px;
    max-width: 1320px;
    padding-bottom: 140px; /* place pour la sticky action bar */
  }
  @media (max-width: 760px) { .pc { padding: 20px 16px 140px; } }

  /* ========== TOPBAR ========== */
  .topbar {
    display: flex; justify-content: space-between; align-items: flex-start;
    gap: 16px; flex-wrap: wrap;
    margin-bottom: 30px;
  }
  .breadcrumb {
    font-family: var(--font-mono);
    font-size: 11px;
    color: var(--color-muted);
    letter-spacing: 0.12em;
    text-transform: uppercase;
    margin-bottom: 6px;
  }
  .breadcrumb-link {
    color: var(--color-muted);
    text-decoration: none;
    transition: color 0.15s;
  }
  .breadcrumb-link:hover { color: var(--color-blue); }
  .breadcrumb .sep { margin: 0 6px; opacity: 0.5; }
  .topbar h1 {
    font-family: var(--font-display);
    font-size: clamp(26px, 3.5vw, 38px);
    font-weight: 600;
    letter-spacing: -0.02em;
    margin: 0 0 10px;
    line-height: 1.12;
    max-width: 720px;
  }
  .topbar h1 em {
    color: var(--color-blue);
    font-style: italic;
    font-weight: 500;
  }
  .topbar-sub {
    margin: 0;
    color: var(--color-muted);
    font-size: 15px;
    line-height: 1.55;
    max-width: 600px;
  }
  .topbar-actions { display: flex; gap: 10px; align-items: center; flex-shrink: 0; }
  .btn-outline {
    display: inline-flex; align-items: center; justify-content: center; gap: 6px;
    padding: 10px 16px; border-radius: 10px;
    font-size: 13px; font-weight: 600;
    text-decoration: none;
    border: 1px solid var(--color-line);
    background: #fff;
    color: var(--color-ink);
    transition: all 0.15s;
    cursor: pointer;
    font-family: inherit;
  }
  .btn-outline:hover { border-color: var(--color-blue); color: var(--color-blue); }
  .btn-primary {
    display: inline-flex; align-items: center; justify-content: center; gap: 8px;
    padding: 12px 22px; border-radius: 12px;
    font-size: 14px; font-weight: 700;
    border: 1px solid transparent;
    background: var(--color-blue); color: #fff;
    transition: all 0.15s;
    cursor: pointer;
    font-family: inherit;
  }
  .btn-primary:hover:not(:disabled) {
    background: var(--color-blue-dark);
    transform: translateY(-1px);
  }
  .btn-primary:disabled { opacity: 0.5; cursor: not-allowed; }

  /* ========== GRID ========== */
  .pc-grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 20px;
    margin-bottom: 24px;
  }
  @media (max-width: 1080px) {
    .pc-grid { grid-template-columns: repeat(2, 1fr); }
  }
  @media (max-width: 720px) {
    .pc-grid { grid-template-columns: 1fr; }
  }

  /* ========== PATH CARD ========== */
  .path-card {
    position: relative;
    background: #fff;
    border: 2px solid var(--color-line);
    border-radius: 20px;
    padding: 26px;
    text-align: left;
    cursor: pointer;
    font-family: inherit;
    transition: all 0.2s;
    overflow: hidden;
    display: flex;
    flex-direction: column;
    min-height: 380px;
  }
  .path-card:hover:not(.is-active) {
    transform: translateY(-3px);
    box-shadow: 0 20px 40px -22px rgba(15, 24, 57, 0.18);
  }
  .path-card.is-active {
    transform: translateY(-3px);
    box-shadow: 0 20px 40px -18px rgba(15, 24, 57, 0.25);
  }
  .path-card-blue.is-active { border-color: var(--color-blue); }
  .path-card-ink.is-active { border-color: var(--color-ink); }
  .path-card-red.is-active { border-color: var(--color-red); }

  /* halo en haut à droite */
  .path-halo {
    position: absolute;
    top: -80px; right: -80px;
    width: 240px; height: 240px;
    border-radius: 50%;
    pointer-events: none;
    opacity: 0.45;
    transition: opacity 0.2s, transform 0.4s;
  }
  .path-card:hover .path-halo,
  .path-card.is-active .path-halo {
    opacity: 0.75;
    transform: scale(1.05);
  }
  .path-card-blue .path-halo {
    background: radial-gradient(circle, var(--color-blue-light) 0%, transparent 70%);
  }
  .path-card-ink .path-halo {
    background: radial-gradient(circle, rgba(15, 24, 57, 0.08) 0%, transparent 70%);
  }
  .path-card-red .path-halo {
    background: radial-gradient(circle, var(--color-red-light) 0%, transparent 70%);
  }

  /* pill "actuel" */
  .path-current-pill {
    position: absolute;
    top: 14px; right: 14px;
    font-family: var(--font-mono);
    font-size: 9.5px;
    letter-spacing: 0.14em;
    padding: 4px 9px;
    border-radius: 100px;
    background: rgba(22, 143, 91, 0.14);
    color: var(--color-green);
    font-weight: 700;
    text-transform: uppercase;
    z-index: 2;
  }

  /* head : badge + radio */
  .path-head {
    display: flex; align-items: center; justify-content: space-between;
    margin-bottom: 18px;
    position: relative; z-index: 1;
  }
  .path-badge {
    font-family: var(--font-display);
    font-weight: 600;
    font-size: 26px;
    letter-spacing: -0.02em;
    padding: 8px 14px;
    border-radius: 12px;
    line-height: 1;
    color: #fff;
  }
  .path-badge-blue { background: var(--color-blue); }
  .path-badge-ink { background: var(--color-ink); }
  .path-badge-red { background: var(--color-red); }

  .path-radio {
    width: 26px; height: 26px;
    border: 2px solid var(--color-line);
    border-radius: 50%;
    display: flex; align-items: center; justify-content: center;
    transition: all 0.2s;
    flex-shrink: 0;
    background: #fff;
  }
  .path-card-blue.is-active .path-radio,
  .path-card-blue .path-radio.is-on {
    border-color: var(--color-blue);
    background: var(--color-blue);
  }
  .path-card-ink.is-active .path-radio,
  .path-card-ink .path-radio.is-on {
    border-color: var(--color-ink);
    background: var(--color-ink);
  }
  .path-card-red.is-active .path-radio,
  .path-card-red .path-radio.is-on {
    border-color: var(--color-red);
    background: var(--color-red);
  }

  .path-title {
    font-family: var(--font-display);
    font-weight: 600;
    font-size: 20px;
    letter-spacing: -0.015em;
    margin: 0 0 8px;
    color: var(--color-ink);
    line-height: 1.2;
    position: relative; z-index: 1;
  }
  .path-pitch {
    color: var(--color-muted);
    font-size: 13.5px;
    line-height: 1.5;
    margin: 0 0 18px;
    position: relative; z-index: 1;
  }

  .path-tcf {
    display: flex; align-items: center; justify-content: space-between;
    padding: 12px 14px;
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 12px;
    margin-bottom: 16px;
    position: relative; z-index: 1;
  }
  .path-tcf-label {
    font-family: var(--font-mono);
    font-size: 10px;
    letter-spacing: 0.14em;
    color: var(--color-muted);
    font-weight: 700;
  }
  .path-tcf-value {
    font-family: var(--font-display);
    font-size: 22px;
    font-weight: 600;
    letter-spacing: -0.02em;
    line-height: 1;
  }
  .path-tcf-value-blue { color: var(--color-blue); }
  .path-tcf-value-ink { color: var(--color-ink); }
  .path-tcf-value-red { color: var(--color-red); }

  .path-bullets {
    list-style: none;
    padding: 0;
    margin: 0 0 20px;
    display: flex; flex-direction: column;
    gap: 8px;
    flex: 1;
    position: relative; z-index: 1;
  }
  .path-bullets li {
    display: flex; align-items: flex-start; gap: 10px;
    font-size: 13px;
    color: var(--color-ink-2);
    line-height: 1.45;
  }
  .path-bullet-dot {
    width: 6px; height: 6px;
    border-radius: 50%;
    background: var(--color-muted-2);
    margin-top: 7px;
    flex-shrink: 0;
  }
  .path-card-blue.is-active .path-bullet-dot { background: var(--color-blue); }
  .path-card-ink.is-active .path-bullet-dot { background: var(--color-ink); }
  .path-card-red.is-active .path-bullet-dot { background: var(--color-red); }

  /* footer state */
  .path-state {
    display: inline-flex; align-items: center; gap: 8px;
    font-family: inherit;
    font-size: 13.5px;
    font-weight: 700;
    color: var(--color-muted);
    transition: color 0.15s;
    position: relative; z-index: 1;
  }
  .path-card-blue.is-active .path-state { color: var(--color-blue); }
  .path-card-ink.is-active .path-state { color: var(--color-ink); }
  .path-card-red.is-active .path-state { color: var(--color-red); }
  .path-card:hover:not(.is-active) .path-state-blue { color: var(--color-blue); }
  .path-card:hover:not(.is-active) .path-state-ink { color: var(--color-ink); }
  .path-card:hover:not(.is-active) .path-state-red { color: var(--color-red); }
  .path-check-icon {
    width: 18px; height: 18px;
    border-radius: 50%;
    background: currentColor;
    color: #fff;
    display: inline-flex; align-items: center; justify-content: center;
    font-size: 11px;
    font-weight: 700;
  }
  .path-card-blue.is-active .path-check-icon { background: var(--color-blue); color: #fff; }
  .path-card-ink.is-active .path-check-icon { background: var(--color-ink); color: #fff; }
  .path-card-red.is-active .path-check-icon { background: var(--color-red); color: #fff; }

  /* ========== RÈGLE DES 4 ÉPREUVES ========== */

  /* ========== ACTION BAR (sticky bottom) ========== */
  .pc-error { margin-bottom: 18px; }
  .pc-actionbar {
    position: sticky;
    bottom: 20px;
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 16px;
    padding: 16px 22px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 16px;
    flex-wrap: wrap;
    box-shadow: 0 20px 40px -16px rgba(15, 24, 57, 0.22);
    margin-bottom: 18px;
    z-index: 5;
  }
  .pc-actionbar-info {
    display: flex; flex-direction: column; gap: 2px;
    min-width: 0;
    flex: 1;
  }
  .pc-actionbar-label {
    font-family: var(--font-mono);
    font-size: 10px;
    letter-spacing: 0.14em;
    color: var(--color-muted);
    font-weight: 700;
  }
  .pc-actionbar-value {
    font-size: 14px;
    color: var(--color-ink);
    font-weight: 600;
    line-height: 1.3;
  }
  .pc-actionbar-value strong { color: var(--color-red); font-weight: 700; }
  .pc-actionbar-empty {
    font-size: 13.5px;
    color: var(--color-muted);
    font-style: italic;
  }
  .pc-actionbar-buttons {
    display: flex;
    gap: 10px;
    align-items: center;
    flex-shrink: 0;
  }

  @media (max-width: 560px) {
    .pc-actionbar {
      flex-direction: column;
      align-items: stretch;
      gap: 12px;
      padding: 14px;
    }
    .pc-actionbar-buttons { width: 100%; }
    .pc-actionbar-buttons .btn-primary,
    .pc-actionbar-buttons .btn-outline { flex: 1; justify-content: center; }
  }

  .pc-skip {
    text-align: center;
    font-size: 12.5px;
    color: var(--color-muted);
    margin: 14px 0 0;
  }
`;
