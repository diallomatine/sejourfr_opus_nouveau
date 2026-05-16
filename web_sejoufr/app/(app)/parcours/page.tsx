"use client";

import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { Suspense, useEffect, useState } from "react";
import { ApiException, userContentApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import type { TargetProcedure } from "@/lib/types";

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
    <Suspense fallback={<div className="pc-loading" />}>
      <ParcoursForm />
    </Suspense>
  );
}

interface PathInfo {
  code: TargetProcedure;
  title: string;
  desc: string;
  tcfLevel: string;
}

const PATHS: PathInfo[] = [
  {
    code: "CSP",
    title: "Titre de séjour pluriannuel",
    desc: "Premier renouvellement après le visa long séjour. Le plus accessible des trois parcours.",
    tcfLevel: "A2",
  },
  {
    code: "CR",
    title: "Carte de résident (10 ans)",
    desc: "Stabilité longue durée, droit au travail facilité, démarches administratives allégées.",
    tcfLevel: "B1",
  },
  {
    code: "NAT",
    title: "Naturalisation française",
    desc: "Nationalité française. Niveau d'exigence le plus élevé en civique et en langue.",
    tcfLevel: "B2",
  },
];

function ParcoursForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const fromParam = searchParams.get("from");
  const { user, status, refreshUser } = useAuth();

  const [selected, setSelected] = useState<TargetProcedure | null>(null);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Pré-remplit la sélection avec la valeur courante du user (lecture async via
  // /api/auth/me). Pattern "sync prop → local state" : le useState seul ne
  // suffit pas car user peut arriver après le premier render.
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
      setError(e instanceof ApiException ? e.message : "Impossible d'enregistrer.");
      setSaving(false);
    }
  }

  if (status === "loading") return <div className="pc-loading" />;
  if (!user) {
    return (
      <main className="pc-gate">
        <p>Connectez-vous pour définir votre parcours.</p>
        <Link href="/connexion?next=/parcours" className="btn btn-blue">
          Se connecter
        </Link>
      </main>
    );
  }

  const isOnboarding = !user.targetProcedure;
  const backHref = fromParam ?? "/profil";

  return (
    <main className="pc">
      <div className="pc-wrap">
        {!isOnboarding && (
          <Link href={backHref} className="pc-back">
            ← Retour
          </Link>
        )}

        <header className="pc-head">
          <span className="eyebrow">{isOnboarding ? "Onboarding · Parcours" : "Modifier mon parcours"}</span>
          <h1>
            {isOnboarding ? (
              <>Quelle <em>démarche</em> préparez-vous ?</>
            ) : (
              <>Votre <em>parcours</em> actuel.</>
            )}
          </h1>
          <p>
            Nous adapterons votre entraînement civique en fonction de votre
            objectif. Le niveau de TCF requis dépend du parcours visé.
            {!isOnboarding && " Vous pouvez modifier ce choix à tout moment."}
          </p>
        </header>

        <div className="pc-list">
          {PATHS.map((p) => {
            const active = selected === p.code;
            return (
              <button
                key={p.code}
                type="button"
                className={`pc-card ${active ? "is-active" : ""}`}
                onClick={() => setSelected(p.code)}
                aria-pressed={active}
              >
                <span className="pc-card-badge">{p.code}</span>
                <span className="pc-card-body">
                  <span className="pc-card-title">{p.title}</span>
                  <span className="pc-card-desc">{p.desc}</span>
                </span>
                <span className="pc-card-meta">
                  <span className="pc-card-tcf-label">TCF requis</span>
                  <span className="pc-card-tcf-value">{p.tcfLevel}</span>
                </span>
                <span className={`pc-card-radio ${active ? "is-on" : ""}`} aria-hidden>
                  {active && (
                    <svg viewBox="0 0 16 16" width="12" height="12">
                      <path d="M3.5 8l3 3 6-7" stroke="#fff" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" fill="none" />
                    </svg>
                  )}
                </span>
              </button>
            );
          })}
        </div>

        {error && <div className="form-error">{error}</div>}

        <div className="pc-actions">
          <button
            type="button"
            className="btn btn-red btn-lg pc-cta"
            onClick={submit}
            disabled={!selected || saving}
          >
            {saving
              ? "Enregistrement…"
              : isOnboarding
                ? "Commencer →"
                : selected === user.targetProcedure
                  ? "Aucun changement"
                  : "Enregistrer →"}
          </button>
          {!isOnboarding && (
            <Link href={backHref} className="btn btn-ghost">
              Annuler
            </Link>
          )}
        </div>

        {isOnboarding && (
          <p className="pc-skip">
            Vous pourrez modifier ce choix à tout moment depuis votre profil.
          </p>
        )}
      </div>
      <style>{styles}</style>
    </main>
  );
}

const styles = `
  .pc { background: var(--color-paper); min-height: calc(100vh - 110px); padding: 32px 16px 64px; }
  .pc-loading { min-height: 60vh; }
  .pc-gate {
    min-height: 60vh;
    display: flex; flex-direction: column; align-items: center; justify-content: center;
    gap: 14px; color: var(--color-muted);
  }
  .pc-wrap { max-width: 640px; margin: 0 auto; }

  .pc-back {
    display: inline-block;
    color: var(--color-muted);
    text-decoration: none;
    font-size: 13px;
    margin-bottom: 16px;
    transition: color 0.15s;
  }
  .pc-back:hover { color: var(--color-blue); }

  .pc-head { text-align: center; margin: 0 0 28px; }
  .pc-head h1 {
    font-family: var(--font-display); font-weight: 500;
    font-size: clamp(26px, 4vw, 36px); line-height: 1.1; letter-spacing: -0.025em;
    margin: 10px 0 12px;
  }
  .pc-head h1 em { font-style: italic; color: var(--color-red); }
  .pc-head p {
    color: var(--color-muted); font-size: 14.5px; line-height: 1.55;
    margin: 0 auto; max-width: 480px;
  }

  .pc-list { display: flex; flex-direction: column; gap: 12px; margin: 0 0 22px; }

  .pc-card {
    display: grid;
    grid-template-columns: 52px 1fr auto 24px;
    align-items: center; gap: 16px;
    width: 100%;
    background: #fff;
    border: 1.5px solid var(--color-line);
    border-radius: 14px;
    padding: 16px 18px;
    text-align: left;
    cursor: pointer;
    transition: all 0.18s ease-out;
    font-family: var(--font-sans);
    box-shadow: 0 2px 10px -4px rgba(30, 58, 140, 0.04);
  }
  .pc-card:hover { border-color: var(--color-blue); background: var(--color-blue-soft); }
  .pc-card.is-active {
    border-color: var(--color-blue);
    background: var(--color-blue-soft);
    box-shadow: 0 8px 24px -10px rgba(30, 58, 140, 0.22);
  }

  .pc-card-badge {
    font-family: var(--font-mono);
    background: var(--color-blue-light);
    color: var(--color-blue);
    padding: 4px 0;
    border-radius: 8px;
    font-size: 13px; font-weight: 700; letter-spacing: 0.08em;
    text-align: center;
  }
  .pc-card.is-active .pc-card-badge {
    background: var(--color-blue);
    color: #fff;
  }

  .pc-card-body { min-width: 0; }
  .pc-card-title {
    display: block;
    font-weight: 700; font-size: 14.5px;
    color: var(--color-ink);
    line-height: 1.25;
  }
  .pc-card-desc {
    display: block;
    font-size: 12.5px; color: var(--color-muted);
    margin-top: 4px; line-height: 1.45;
  }

  .pc-card-meta {
    display: flex; flex-direction: column; align-items: center;
    gap: 2px;
    padding: 8px 12px;
    background: var(--color-paper);
    border-radius: 8px;
  }
  .pc-card-tcf-label {
    font-family: var(--font-mono); font-size: 8.5px;
    letter-spacing: 0.14em; text-transform: uppercase;
    color: var(--color-muted); font-weight: 700;
  }
  .pc-card-tcf-value {
    font-family: var(--font-mono);
    font-size: 14px; font-weight: 700;
    color: var(--color-red);
    letter-spacing: 0.04em;
  }

  .pc-card-radio {
    width: 22px; height: 22px;
    border: 2px solid var(--color-line);
    border-radius: 50%;
    display: flex; align-items: center; justify-content: center;
    transition: all 0.18s;
    flex-shrink: 0;
  }
  .pc-card-radio.is-on {
    border-color: var(--color-blue);
    background: var(--color-blue);
  }

  @media (max-width: 540px) {
    .pc-card {
      grid-template-columns: 44px 1fr 24px;
      gap: 12px;
    }
    .pc-card-meta { display: none; }
  }

  .pc-actions {
    display: flex; align-items: center; gap: 10px; flex-wrap: wrap;
    margin-bottom: 12px;
  }
  .pc-cta { flex: 1; min-width: 240px; }

  .pc-skip {
    margin-top: 18px; text-align: center;
    font-size: 12.5px; color: var(--color-muted);
  }
`;
