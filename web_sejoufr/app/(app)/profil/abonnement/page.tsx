"use client";

import Link from "next/link";
import {useCallback, useEffect, useState} from "react";
import {useAuth} from "@/lib/auth-context";
import {ApiException, billingApi} from "@/lib/api";
import type {
    PlanPublicResponse,
    SubscriptionSource,
    SubscriptionStatusResponse,
} from "@/lib/types";

/**
 * Page « Mon pass » — parité avec l'écran mobile `manage_subscription_screen.dart`.
 * Les passes (lot 5, achat unique) n'ont AUCUNE résiliation : un pass est payé
 * une fois, il n'y a rien à annuler. On affiche le détail du pass en cours
 * (carte gradient + jours restants), ses inclusions, et la prolongation /
 * l'upgrade via `/paiement`.
 */
export default function MonPassPage() {
    const {user, status: authStatus} = useAuth();

    const [status, setStatus] = useState<SubscriptionStatusResponse | null>(null);
    const [plans, setPlans] = useState<PlanPublicResponse[]>([]);
    const [loading, setLoading] = useState(true);
    const [loadError, setLoadError] = useState<string | null>(null);

    const loadOnce = useCallback(
        () =>
            Promise.all([
                billingApi.getSubscriptionStatus(),
                billingApi.listPlans().catch(() => [] as PlanPublicResponse[]),
            ]),
        [],
    );

    // Bouton « Réessayer » (event handler → setState synchrone autorisé).
    const fetchStatus = useCallback(async () => {
        setLoading(true);
        setLoadError(null);
        try {
            const [s, p] = await loadOnce();
            setStatus(s);
            setPlans(p);
        } catch (e) {
            setLoadError(
                e instanceof ApiException ? e.message : "Impossible de charger votre pass.",
            );
        } finally {
            setLoading(false);
        }
    }, [loadOnce]);

    useEffect(() => {
        if (authStatus !== "authenticated") return;
        let active = true;
        // setState uniquement après l'await (pas de setState synchrone en effet).
        loadOnce()
            .then(([s, p]) => {
                if (!active) return;
                setStatus(s);
                setPlans(p);
                setLoading(false);
            })
            .catch((e) => {
                if (!active) return;
                setLoadError(
                    e instanceof ApiException ? e.message : "Impossible de charger votre pass.",
                );
                setLoading(false);
            });
        return () => {
            active = false;
        };
    }, [authStatus, loadOnce]);

    if (authStatus === "loading") return <PageSkeleton/>;
    if (!user) {
        return (
            <main className="ab-gate">
                <p>Connectez-vous pour voir votre pass.</p>
                <Link href="/connexion?next=/profil/abonnement" className="ab-gate-cta">
                    Se connecter →
                </Link>
                <style>{gateStyles}</style>
            </main>
        );
    }

    return (
        <main className="ab">
            <div className="ab-breadcrumb">
                <Link href="/profil">← Mon profil</Link>
            </div>

            <header className="ab-head">
                <h1 className="ab-title">Mon <em>pass</em></h1>
                <p className="ab-sub">Paiement unique · sans renouvellement automatique</p>
            </header>

            {loading && <PageSkeleton inline/>}
            {!loading && loadError && (
                <div className="ab-error">
                    <p>{loadError}</p>
                    <button type="button" className="btn btn-ghost" onClick={fetchStatus}>
                        Réessayer
                    </button>
                </div>
            )}

            {!loading && !loadError && status && !status.isPremium && <NotPremiumView/>}
            {!loading && !loadError && status?.isPremium && (
                <PremiumView status={status} plan={planFor(status, plans)}/>
            )}

            <style>{styles}</style>
        </main>
    );
}

// ============================================================================
// Vue premium : carte pass + détails + inclusions + actions
// ============================================================================

const CIVIQUE_FEATURES = [
    "Les 5 catégories civiques",
    "Séries d'entraînement illimitées",
    "Examens blancs par thème",
    "Examens blancs complets",
    "Suivi, rapports & recommandations",
];

const INTEGRAL_FEATURES = [
    "Tout le Pass Civique inclus",
    "Les 5 épreuves du TCF IRN",
    "Compréhension orale & écrite, structure",
    "Expression écrite & orale + analyse IA",
    "Examens blancs complets des deux parcours",
    "Niveau CECRL estimé & plan de révision",
];

function PremiumView({
                         status,
                         plan,
                     }: {
    status: SubscriptionStatusResponse;
    plan: PlanPublicResponse | null;
}) {
    const isIntegral = status.moduleAccess === "INTEGRAL";
    const name = isIntegral ? "Pass Intégral" : "Pass Civique";
    const features = isIntegral ? INTEGRAL_FEATURES : CIVIQUE_FEATURES;

    const ends = status.expiresAt;
    const remaining = ends ? daysUntil(ends) : null;
    const totalDays = plan?.durationDays ?? null;
    const fraction =
        remaining != null && totalDays != null && totalDays > 0
            ? Math.min(1, Math.max(0, remaining / totalDays))
            : null;

    return (
        <>
            <section className="pass-hero">
                <span className="pass-stripe" aria-hidden/>
                <div className="pass-hero-head">
                    <span className="pass-eyebrow">SEJOURFR · PASS ACTIF</span>
                    <span className="pass-badge"><span className="pass-dot"/>Actif</span>
                </div>
                <h2 className="pass-name">{name}</h2>
                <p className="pass-formula">
                    {plan?.name ? `Formule ${plan.name} · payé une fois` : "Payé une fois, sans abonnement"}
                </p>

                {fraction != null && (
                    <div className="pass-track">
                        <span className="pass-track-fill" style={{width: `${fraction * 100}%`}}/>
                    </div>
                )}
                <div className="pass-hero-foot">
                    <span>
                        {remaining != null && remaining >= 0
                            ? `${remaining} jour${remaining > 1 ? "s" : ""} restant${remaining > 1 ? "s" : ""}`
                            : "Accès actif"}
                    </span>
                    {ends && <span className="pass-foot-date">Expire le {formatLong(ends)}</span>}
                </div>
            </section>

            <div className="pass-actions">
                {isIntegral ? (
                    <Link href="/paiement?module=INTEGRAL" className="pass-btn pass-btn-primary">
                        Prolonger mon pass
                    </Link>
                ) : (
                    <>
                        <Link href="/paiement?module=CIVIQUE" className="pass-btn pass-btn-primary">
                            Prolonger mon Pass Civique
                        </Link>
                        <Link href="/paiement?module=INTEGRAL" className="pass-btn pass-btn-accent">
                            Passer au Pass Intégral
                        </Link>
                    </>
                )}
            </div>

            <section className="ab-details">
                <dl>
                    <DetailRow label="Formule" value={plan?.name ?? "—"}/>
                    <DetailRow
                        label="Périmètre"
                        value={isIntegral ? "Accès complet à tout SejourFR" : "Accès complet au parcours Civique"}
                    />
                    <DetailRow label="Géré par" value={sourceLabel(status.source)}/>
                    <DetailRow label="Expire le" value={ends ? formatLong(ends) : "—"}/>
                </dl>
            </section>

            <section className="pass-incl">
                <h3 className="ab-section-title">Inclus dans votre pass</h3>
                <ul>
                    {features.map((f) => (
                        <li key={f}>
                            <span className="pass-check" aria-hidden>✓</span>
                            {f}
                        </li>
                    ))}
                </ul>
            </section>

            <section className="ab-note">
                Un pass s&apos;achète une seule fois, sans renouvellement automatique. Prolongez-le
                quand vous le souhaitez — les durées se cumulent.
            </section>
        </>
    );
}

function NotPremiumView() {
    return (
        <section className="ab-empty">
            <span className="ab-empty-icon" aria-hidden>🔒</span>
            <h2>Aucun pass actif</h2>
            <p>
                Vous êtes sur le plan gratuit. Débloquez l&apos;accès complet avec un pass à durée
                fixe, payé une seule fois.
            </p>
            <Link href="/paiement" className="btn btn-red">
                Découvrir les pass
            </Link>
        </section>
    );
}

function DetailRow({label, value}: {label: string; value: string}) {
    return (
        <div className="ab-row">
            <dt>{label}</dt>
            <dd>{value}</dd>
        </div>
    );
}

// ============================================================================
// Helpers
// ============================================================================

/** Retrouve le plan correspondant au pass courant via son productId
 *  (Stripe : Plan.code ; mobile : apple/googleProductId). */
function planFor(
    s: SubscriptionStatusResponse,
    plans: PlanPublicResponse[],
): PlanPublicResponse | null {
    const id = s.productId;
    if (!id) return null;
    return (
        plans.find((p) => p.code === id || p.appleProductId === id || p.googleProductId === id) ??
        null
    );
}

function daysUntil(iso: string): number {
    const ms = new Date(iso).getTime() - Date.now();
    return Math.ceil(ms / 86_400_000);
}

function sourceLabel(s: SubscriptionSource | null): string {
    switch (s) {
        case "STRIPE":
            return "Carte bancaire (Stripe)";
        case "APPLE":
            return "App Store (Apple)";
        case "GOOGLE":
            return "Google Play";
        default:
            return "—";
    }
}

function formatLong(iso: string): string {
    return new Date(iso).toLocaleDateString("fr-FR", {
        day: "numeric",
        month: "long",
        year: "numeric",
    });
}

function PageSkeleton({inline = false}: {inline?: boolean}) {
    return (
        <div className={inline ? "ab-skel-inline" : "ab-skel"}>
            <style>{`.ab-skel { min-height: 60vh; background: var(--color-paper); }
.ab-skel-inline { height: 200px; border-radius: 18px; background: var(--color-line-2); animation: pulse 1.2s ease-in-out infinite; }
@keyframes pulse { 0%,100% { opacity: .55; } 50% { opacity: 1; } }`}</style>
        </div>
    );
}

// ============================================================================
// Styles
// ============================================================================

const gateStyles = `
.ab-gate { min-height: 60vh; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 14px; color: var(--color-muted); padding: 36px; }
.ab-gate-cta { color: var(--color-blue); font-weight: 700; text-decoration: none; }
`;

const styles = `
.ab { max-width: 720px; margin: 0 auto; padding: 24px 24px 64px; display: flex; flex-direction: column; gap: 18px; }
@media (max-width: 600px) { .ab { padding: 20px 16px 56px; gap: 16px; } }

.ab-breadcrumb { font-family: var(--font-mono); font-size: 11.5px; letter-spacing: 0.1em; text-transform: uppercase; color: var(--color-muted); }
.ab-breadcrumb a { color: var(--color-muted); text-decoration: none; }
.ab-breadcrumb a:hover { color: var(--color-blue); }

.ab-head { display: flex; flex-direction: column; gap: 4px; }
.ab-title { font-family: var(--font-display); font-weight: 600; font-size: clamp(26px, 4vw, 34px); letter-spacing: -0.02em; line-height: 1.1; color: var(--color-ink); margin: 0; }
.ab-title em { font-style: italic; color: var(--color-red); font-weight: 500; }
.ab-sub { font-family: var(--font-mono); font-size: 11.5px; letter-spacing: 0.04em; text-transform: uppercase; color: var(--color-muted); margin: 0; }

/* ---- Carte pass (gradient) ---- */
.pass-hero {
  position: relative; overflow: hidden; border-radius: 20px; padding: 24px 26px 22px; color: #fff;
  background: linear-gradient(135deg, var(--color-blue) 0%, var(--color-blue-dark) 100%);
  box-shadow: 0 18px 40px -22px rgba(30,58,140,0.45);
}
.pass-stripe { position: absolute; top: 0; right: 0; bottom: 0; width: 8px;
  background: linear-gradient(to bottom, rgba(255,255,255,0.85) 0 33.3%, rgba(255,255,255,0.3) 33.3% 66.6%, var(--color-red) 66.6% 100%); }
.pass-hero-head { display: flex; align-items: center; justify-content: space-between; gap: 12px; }
.pass-eyebrow { font-family: var(--font-sans); font-size: 11.5px; font-weight: 700; letter-spacing: 0.08em; color: rgba(255,255,255,0.85); }
.pass-badge { display: inline-flex; align-items: center; gap: 6px; background: rgba(255,255,255,0.2); border-radius: 99px; padding: 4px 11px; font-size: 11.5px; font-weight: 700; }
.pass-dot { width: 7px; height: 7px; border-radius: 50%; background: #fff; }
.pass-name { font-family: var(--font-display); font-weight: 600; font-size: clamp(24px, 4vw, 28px); letter-spacing: -0.02em; margin: 16px 0 2px; }
.pass-formula { font-size: 13px; color: rgba(255,255,255,0.9); margin: 0; }
.pass-track { height: 7px; border-radius: 99px; background: rgba(255,255,255,0.25); margin: 20px 0 8px; overflow: hidden; }
.pass-track-fill { display: block; height: 100%; background: #fff; border-radius: 99px; transition: width 0.4s ease; }
.pass-hero-foot { display: flex; align-items: center; justify-content: space-between; gap: 12px; font-size: 12px; font-weight: 600; margin-top: 10px; }
.pass-foot-date { color: rgba(255,255,255,0.8); font-weight: 500; }

/* ---- Actions ---- */
.pass-actions { display: flex; flex-direction: column; gap: 10px; }
.pass-btn { display: inline-flex; align-items: center; justify-content: center; padding: 13px 20px; border-radius: 12px; font-family: var(--font-sans); font-weight: 700; font-size: 14px; text-decoration: none; cursor: pointer; transition: all 0.15s; }
.pass-btn-primary { background: var(--color-blue); color: #fff; }
.pass-btn-primary:hover { background: var(--color-blue-dark); }
.pass-btn-accent { background: var(--color-red); color: #fff; }
.pass-btn-accent:hover { background: var(--color-red-dark); }

/* ---- Détails ---- */
.ab-details { background: #fff; border: 1px solid var(--color-line); border-radius: 16px; padding: 6px 18px; }
.ab-details dl { margin: 0; }
.ab-row { display: flex; align-items: center; justify-content: space-between; gap: 14px; padding: 13px 0; border-bottom: 1px solid var(--color-line-2); }
.ab-row:last-child { border-bottom: none; }
.ab-row dt { font-size: 13px; font-weight: 600; color: var(--color-muted); margin: 0; }
.ab-row dd { font-size: 13.5px; font-weight: 700; color: var(--color-ink); margin: 0; text-align: right; word-break: break-word; }

/* ---- Inclusions ---- */
.pass-incl { background: #fff; border: 1px solid var(--color-line); border-radius: 16px; padding: 18px 20px; }
.ab-section-title { font-family: var(--font-mono); font-size: 11px; letter-spacing: 0.14em; text-transform: uppercase; color: var(--color-muted); font-weight: 700; margin: 0 0 14px; }
.pass-incl ul { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 12px; }
.pass-incl li { display: flex; align-items: flex-start; gap: 10px; font-size: 13.5px; color: var(--color-ink); line-height: 1.4; }
.pass-check { flex-shrink: 0; width: 22px; height: 22px; border-radius: 50%; background: var(--color-blue); color: #fff; display: inline-flex; align-items: center; justify-content: center; font-size: 12px; font-weight: 700; }

/* ---- Note ---- */
.ab-note { background: var(--color-paper); border: 1px solid var(--color-line-2); border-radius: 14px; padding: 14px 16px; font-size: 12.5px; line-height: 1.55; color: var(--color-muted); }

/* ---- États vides / erreur ---- */
.ab-error { background: var(--color-red-light); border: 1px solid color-mix(in srgb, var(--color-red) 25%, transparent); border-radius: 14px; padding: 18px; display: flex; flex-direction: column; gap: 12px; align-items: flex-start; color: var(--color-red); }
.ab-empty { background: #fff; border: 1px solid var(--color-line); border-radius: 18px; padding: 30px 26px; text-align: center; display: flex; flex-direction: column; gap: 12px; align-items: center; }
.ab-empty-icon { width: 54px; height: 54px; border-radius: 14px; background: var(--color-paper-2); display: inline-flex; align-items: center; justify-content: center; font-size: 24px; }
.ab-empty h2 { font-family: var(--font-display); font-weight: 600; font-size: 20px; margin: 0; color: var(--color-ink); }
.ab-empty p { font-size: 13.5px; color: var(--color-muted); margin: 0; max-width: 380px; line-height: 1.5; }
`;
