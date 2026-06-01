"use client";

import Link from "next/link";
import {Suspense, useEffect, useRef, useState} from "react";
import {useSearchParams} from "next/navigation";
import {useAuth} from "@/lib/auth-context";
import type {AuthenticatedUser} from "@/lib/types";

type SyncState = "syncing" | "ready" | "timeout";

export default function PaiementSuccesPage() {
    return (
        <Suspense fallback={<SuccesSkeleton/>}>
            <SuccesInner/>
        </Suspense>
    );
}

/**
 * Page de retour Stripe après checkout one-shot.
 *
 * Le webhook `checkout.session.completed` arrive en parallèle au backend, qui
 * met à jour `hasCivique`/`hasTcf` et `premiumEndsAt` sur l'utilisateur.
 * Côté front, on poll `refreshUser()` (1,5s × 8 = 12s max) tant que le
 * statut premium n'est pas détecté. Au-delà, message "ça arrive sous peu"
 * — l'utilisateur peut naviguer, son accès sera actif au prochain reload.
 */
function SuccesInner() {
    const sp = useSearchParams();
    const {user, status, refreshUser} = useAuth();
    const sessionId = sp.get("session_id");
    const planParam = sp.get("plan");

    const [timedOut, setTimedOut] = useState(false);
    const synced = isPremium(user);
    const syncState: SyncState = synced ? "ready" : timedOut ? "timeout" : "syncing";
    const attemptsRef = useRef(0);

    useEffect(() => {
        if (status !== "authenticated") return;
        if (synced) return;

        let stopped = false;
        const MAX_ATTEMPTS = 8;
        const INTERVAL_MS = 1500;

        const tick = async () => {
            if (stopped) return;
            attemptsRef.current += 1;
            try {
                await refreshUser();
            } catch {
                // ignore
            }
        };

        void tick();

        const id = window.setInterval(() => {
            if (attemptsRef.current >= MAX_ATTEMPTS) {
                window.clearInterval(id);
                if (!stopped) setTimedOut(true);
                return;
            }
            void tick();
        }, INTERVAL_MS);

        return () => {
            stopped = true;
            window.clearInterval(id);
        };
    }, [status, refreshUser, synced]);

    if (status === "loading") return <SuccesSkeleton/>;

    if (!user) {
        return (
            <main className="succes">
                <div className="succes-gate">
                    <h1>Votre paiement a été reçu.</h1>
                    <p>Connectez-vous pour finaliser l&apos;activation de votre abonnement.</p>
                    <Link href="/connexion?next=/paiement/succes" className="btn-primary">
                        Se connecter →
                    </Link>
                </div>
                <style>{styles}</style>
            </main>
        );
    }

    const planLabel = derivePlanLabel(user, planParam);

    return (
        <main className="succes">
            {/* ============ TOPBAR ============ */}
            <header className="topbar">
                <div className="breadcrumb">
                    ACCUEIL <span className="sep">/</span>{" "}
                    <Link href="/paiement" className="breadcrumb-link">
                        ABONNEMENT
                    </Link>{" "}
                    <span className="sep">/</span> SUCCÈS
                </div>
            </header>

            {/* ============ HERO CARD ============ */}
            <section className={`succes-hero succes-hero-${syncState}`}>
                <div className="succes-halo" aria-hidden/>

                <div className="succes-icon-wrap">
                    {syncState === "syncing" ? (
                        <div className="succes-spinner" aria-hidden/>
                    ) : (
                        <div className="succes-check" aria-hidden>
                            <svg viewBox="0 0 32 32" width="32" height="32">
                                <path
                                    d="M8 16l5 5 11-12"
                                    stroke="#fff"
                                    strokeWidth="3"
                                    strokeLinecap="round"
                                    strokeLinejoin="round"
                                    fill="none"
                                />
                            </svg>
                        </div>
                    )}
                </div>

                <div className="succes-eyebrow">
                    {syncState === "syncing" ? (
                        <>
                            <span className="dot dot-blue"/> ACTIVATION EN COURS
                        </>
                    ) : syncState === "timeout" ? (
                        <>
                            <span className="dot dot-amber"/> ACTIVATION EN ATTENTE
                        </>
                    ) : (
                        <>
                            <span className="dot dot-green"/> PAIEMENT CONFIRMÉ
                        </>
                    )}
                </div>

                <h1 className="succes-h1">
                    {syncState === "syncing" ? (
                        <>
                            Activation de votre <em>{planLabel}</em>…
                        </>
                    ) : syncState === "timeout" ? (
                        <>
                            Paiement reçu — <em>activation en cours</em>
                        </>
                    ) : (
                        <>
                            Bienvenue dans <em>{planLabel}</em>.
                        </>
                    )}
                </h1>

                <p className="succes-sub">
                    {syncState === "syncing"
                        ? "Stripe nous notifie l'activation, ça prend quelques secondes. Ne fermez pas cette page."
                        : syncState === "timeout"
                            ? "Votre paiement est validé côté Stripe. La synchronisation côté SejourFR peut prendre une ou deux minutes — votre accès s'ouvrira automatiquement. Vous pouvez naviguer ou revenir sur cette page plus tard."
                            : `${user.firstName ? `${user.firstName}, votre` : "Votre"} abonnement est actif. Vous avez maintenant accès à ${
                                user.hasTcf
                                    ? "tout le contenu : Civique + TCF IRN, examens blancs illimités, révision des erreurs"
                                    : "tout le contenu civique : la banque complète, examens blancs illimités, révision des erreurs"
                            }.`}
                </p>

                {syncState !== "syncing" && (
                    <div className="succes-actions">
                        <Link href="/entrainement" className="btn-primary-red">
                            Lancer un entraînement <span className="arrow">→</span>
                        </Link>
                        <Link href="/dashboard" className="btn-outline">
                            Tableau de bord
                        </Link>
                    </div>
                )}
            </section>

            {/* ============ NEXT STEPS ============ */}
            {syncState === "ready" && (
                <section className="next-section">
                    <h2 className="next-title">Et maintenant ?</h2>
                    <div className="next-grid">
                        <NextCard
                            num="01"
                            tone="blue"
                            title="Lancer un entraînement complet"
                            body="L'entraînement par thème est désormais illimité. Travaillez vos points faibles à votre rythme."
                            href="/entrainement"
                            ctaLabel="S'entraîner"
                        />
                        <NextCard
                            num="02"
                            tone="red"
                            title="Passer un examen blanc"
                            body="En conditions réelles : chronomètre, pas de correction live, score officiel à la fin."
                            href="/examens-blancs"
                            ctaLabel="Examens blancs"
                        />
                        <NextCard
                            num="03"
                            tone="green"
                            title="Suivre votre progression"
                            body="Statistiques par thématique, calendrier d'activité et révision ciblée de vos erreurs."
                            href="/statistiques"
                            ctaLabel="Mes stats"
                        />
                    </div>
                </section>
            )}

            {/* ============ REFERENCE ============ */}
            {sessionId && (
                <section className="succes-meta">
                    <span className="succes-meta-label">RÉFÉRENCE TRANSACTION</span>
                    <code className="succes-meta-value">{sessionId}</code>
                    <span className="succes-meta-foot">
            Conservez cette référence en cas de question sur votre paiement.
            Une question ? Écrivez à{" "}
                        <a href="mailto:support@sejourfr.fr">support@sejourfr.fr</a>.
          </span>
                </section>
            )}

            <style>{styles}</style>
        </main>
    );
}

// ============================================================================
// NEXT CARD
// ============================================================================
function NextCard({
                      num,
                      tone,
                      title,
                      body,
                      href,
                      ctaLabel,
                  }: {
    num: string;
    tone: "blue" | "red" | "green";
    title: string;
    body: string;
    href: string;
    ctaLabel: string;
}) {
    return (
        <Link href={href} className={`next-card next-card-${tone}`}>
            <span className={`next-num next-num-${tone}`}>{num}</span>
            <h3 className="next-card-title">{title}</h3>
            <p className="next-card-body">{body}</p>
            <span className={`next-card-cta next-card-cta-${tone}`}>
        {ctaLabel} <span className="arrow">→</span>
      </span>
        </Link>
    );
}

// ============================================================================
// HELPERS
// ============================================================================
function isPremium(user: AuthenticatedUser | null): boolean {
    if (!user) return false;
    return Boolean(user.hasCivique || user.hasTcf);
}

function derivePlanLabel(user: AuthenticatedUser, planParam: string | null): string {
    if (planParam) {
        if (planParam.startsWith("INTEGRAL")) return "Intégral";
        if (planParam.startsWith("CIVIQUE")) return "Civique";
    }
    if (user.hasTcf) return "Intégral";
    if (user.hasCivique) return "Civique";
    return "Premium";
}

function SuccesSkeleton() {
    return (
        <div className="succes-loading">
            <style>{`.succes-loading { min-height: calc(100vh - 80px); background: #F7F8FC; }`}</style>
        </div>
    );
}

// ============================================================================
// STYLES
// ============================================================================
const styles = `
  .succes { padding: 24px 36px 64px; max-width: 1100px; }
  @media (max-width: 760px) { .succes { padding: 20px 16px 56px; } }

  /* ========== TOPBAR ========== */
  .topbar { margin-bottom: 22px; }
  .breadcrumb {
    font-family: var(--font-mono);
    font-size: 11px;
    color: var(--color-muted);
    letter-spacing: 0.12em;
    text-transform: uppercase;
  }
  .breadcrumb-link {
    color: var(--color-muted);
    text-decoration: none;
    transition: color 0.15s;
  }
  .breadcrumb-link:hover { color: var(--color-blue); }
  .breadcrumb .sep { margin: 0 6px; opacity: 0.5; }

  /* ========== HERO CARD ========== */
  .succes-hero {
    position: relative;
    text-align: center;
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 24px;
    padding: 56px 40px 44px;
    overflow: hidden;
    margin-bottom: 32px;
  }
  .succes-halo {
    position: absolute;
    top: -120px; left: 50%;
    transform: translateX(-50%);
    width: 600px; height: 360px;
    pointer-events: none;
    border-radius: 50%;
    filter: blur(50px);
    opacity: 0.5;
  }
  .succes-hero-ready .succes-halo {
    background: radial-gradient(circle, rgba(22, 143, 91, 0.25) 0%, transparent 70%);
  }
  .succes-hero-syncing .succes-halo {
    background: radial-gradient(circle, rgba(30, 58, 140, 0.18) 0%, transparent 70%);
  }
  .succes-hero-timeout .succes-halo {
    background: radial-gradient(circle, rgba(232, 163, 23, 0.22) 0%, transparent 70%);
  }

  .succes-icon-wrap {
    position: relative;
    z-index: 1;
    margin-bottom: 22px;
    display: flex; justify-content: center;
  }
  .succes-check {
    width: 80px; height: 80px;
    border-radius: 50%;
    background: linear-gradient(135deg, var(--color-green) 0%, #128050 100%);
    color: #fff;
    display: flex; align-items: center; justify-content: center;
    box-shadow:
      0 0 0 10px rgba(22, 143, 91, 0.12),
      0 16px 32px -10px rgba(22, 143, 91, 0.5);
    animation: succes-pop 0.45s cubic-bezier(0.34, 1.56, 0.64, 1) both;
  }
  .succes-hero-timeout .succes-check {
    background: linear-gradient(135deg, var(--color-amber) 0%, #c08510 100%);
    box-shadow:
      0 0 0 10px rgba(232, 163, 23, 0.14),
      0 16px 32px -10px rgba(232, 163, 23, 0.5);
  }
  @keyframes succes-pop {
    0% { transform: scale(0.3); opacity: 0; }
    100% { transform: scale(1); opacity: 1; }
  }
  .succes-spinner {
    width: 72px; height: 72px;
    border: 4px solid rgba(30, 58, 140, 0.16);
    border-top-color: var(--color-blue);
    border-radius: 50%;
    animation: succes-spin 0.9s linear infinite;
  }
  @keyframes succes-spin { to { transform: rotate(360deg); } }

  .succes-eyebrow {
    position: relative; z-index: 1;
    display: inline-flex;
    align-items: center;
    gap: 8px;
    font-family: var(--font-mono);
    font-size: 10.5px;
    letter-spacing: 0.15em;
    font-weight: 700;
    color: var(--color-muted);
    margin-bottom: 14px;
  }
  .succes-eyebrow .dot {
    width: 7px; height: 7px;
    border-radius: 50%;
  }
  .dot-green {
    background: var(--color-green);
    box-shadow: 0 0 0 3px rgba(22, 143, 91, 0.2);
  }
  .dot-blue {
    background: var(--color-blue);
    box-shadow: 0 0 0 3px rgba(30, 58, 140, 0.2);
    animation: succes-pulse 1.4s ease-in-out infinite;
  }
  .dot-amber {
    background: var(--color-amber);
    box-shadow: 0 0 0 3px rgba(232, 163, 23, 0.2);
  }
  @keyframes succes-pulse {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.5; }
  }

  .succes-h1 {
    position: relative; z-index: 1;
    font-family: var(--font-display);
    font-weight: 600;
    font-size: clamp(28px, 4vw, 42px);
    line-height: 1.08;
    letter-spacing: -0.025em;
    color: var(--color-ink);
    margin: 0 0 16px;
    max-width: 640px;
    margin-left: auto;
    margin-right: auto;
  }
  .succes-h1 em {
    font-style: italic;
    font-weight: 500;
  }
  .succes-hero-ready .succes-h1 em { color: var(--color-blue); }
  .succes-hero-syncing .succes-h1 em { color: var(--color-blue); }
  .succes-hero-timeout .succes-h1 em { color: var(--color-amber); }

  .succes-sub {
    position: relative; z-index: 1;
    color: var(--color-muted);
    font-size: 16px;
    line-height: 1.55;
    margin: 0 auto 30px;
    max-width: 600px;
  }

  .succes-actions {
    position: relative; z-index: 1;
    display: flex;
    gap: 12px;
    justify-content: center;
    flex-wrap: wrap;
  }
  .btn-primary, .btn-primary-red, .btn-outline {
    display: inline-flex; align-items: center; justify-content: center; gap: 8px;
    padding: 13px 22px; border-radius: 12px;
    font-family: inherit;
    font-size: 14px;
    font-weight: 700;
    text-decoration: none;
    border: 1px solid transparent;
    cursor: pointer;
    transition: all 0.15s;
  }
  .btn-primary { background: var(--color-blue); color: #fff; }
  .btn-primary:hover { background: var(--color-blue-dark); transform: translateY(-1px); }
  .btn-primary-red {
    background: var(--color-red);
    color: #fff;
    box-shadow: 0 10px 24px -10px rgba(225, 55, 47, 0.5);
  }
  .btn-primary-red:hover {
    background: var(--color-red-dark);
    transform: translateY(-2px);
    box-shadow: 0 14px 28px -10px rgba(225, 55, 47, 0.6);
  }
  .btn-outline {
    background: #fff;
    color: var(--color-ink);
    border-color: var(--color-line);
  }
  .btn-outline:hover {
    border-color: var(--color-blue);
    color: var(--color-blue);
  }
  .arrow { transition: transform 0.15s; }
  .btn-primary-red:hover .arrow,
  .btn-primary:hover .arrow { transform: translateX(3px); }

  /* ========== NEXT STEPS ========== */
  .next-section { margin-bottom: 32px; }
  .next-title {
    font-family: var(--font-display);
    font-weight: 600;
    font-size: 22px;
    letter-spacing: -0.015em;
    color: var(--color-ink);
    margin: 0 0 16px;
  }
  .next-grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 16px;
  }
  @media (max-width: 980px) {
    .next-grid { grid-template-columns: 1fr; }
  }

  .next-card {
    position: relative;
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 18px;
    padding: 24px;
    text-decoration: none;
    color: inherit;
    transition: all 0.18s;
    display: flex;
    flex-direction: column;
    overflow: hidden;
  }
  .next-card::before {
    content: '';
    position: absolute;
    top: 0; left: 0; right: 0;
    height: 3px;
  }
  .next-card-blue::before { background: var(--color-blue); }
  .next-card-red::before { background: var(--color-red); }
  .next-card-green::before { background: var(--color-green); }
  .next-card:hover {
    transform: translateY(-3px);
    box-shadow: 0 14px 30px -16px rgba(15, 24, 57, 0.20);
  }
  .next-card-blue:hover { border-color: var(--color-blue); }
  .next-card-red:hover { border-color: var(--color-red); }
  .next-card-green:hover { border-color: var(--color-green); }

  .next-num {
    font-family: var(--font-mono);
    font-size: 11px;
    letter-spacing: 0.14em;
    font-weight: 700;
    margin-bottom: 10px;
  }
  .next-num-blue { color: var(--color-blue); }
  .next-num-red { color: var(--color-red); }
  .next-num-green { color: var(--color-green); }

  .next-card-title {
    font-family: var(--font-display);
    font-weight: 600;
    font-size: 17px;
    letter-spacing: -0.01em;
    margin: 0 0 8px;
    color: var(--color-ink);
    line-height: 1.25;
  }
  .next-card-body {
    color: var(--color-muted);
    font-size: 13.5px;
    line-height: 1.5;
    margin: 0 0 16px;
    flex: 1;
  }
  .next-card-cta {
    font-size: 13px;
    font-weight: 700;
    display: inline-flex;
    align-items: center;
    gap: 6px;
  }
  .next-card-cta-blue { color: var(--color-blue); }
  .next-card-cta-red { color: var(--color-red); }
  .next-card-cta-green { color: var(--color-green); }
  .next-card:hover .next-card-cta .arrow { transform: translateX(3px); }

  /* ========== META ========== */
  .succes-meta {
    background: var(--color-paper);
    border: 1px solid var(--color-line);
    border-radius: 14px;
    padding: 18px 22px;
    display: flex;
    flex-direction: column;
    gap: 6px;
  }
  .succes-meta-label {
    font-family: var(--font-mono);
    font-size: 10px;
    letter-spacing: 0.14em;
    color: var(--color-muted);
    font-weight: 700;
  }
  .succes-meta-value {
    font-family: var(--font-mono);
    font-size: 12px;
    color: var(--color-ink-2);
    background: #fff;
    padding: 8px 12px;
    border: 1px solid var(--color-line);
    border-radius: 8px;
    word-break: break-all;
    display: inline-block;
  }
  .succes-meta-foot {
    font-size: 12.5px;
    color: var(--color-muted);
    line-height: 1.5;
    margin-top: 4px;
  }
  .succes-meta-foot a {
    color: var(--color-blue);
    text-decoration: none;
    font-weight: 600;
  }
  .succes-meta-foot a:hover { text-decoration: underline; }

  /* ========== GATE ========== */
  .succes-gate {
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 22px;
    padding: 48px 40px;
    text-align: center;
    max-width: 480px;
    margin: 48px auto 0;
  }
  .succes-gate h1 {
    font-family: var(--font-display);
    font-weight: 600;
    font-size: 28px;
    color: var(--color-ink);
    margin: 0 0 12px;
    letter-spacing: -0.02em;
  }
  .succes-gate p {
    color: var(--color-muted);
    font-size: 14.5px;
    margin: 0 0 24px;
  }
`;
