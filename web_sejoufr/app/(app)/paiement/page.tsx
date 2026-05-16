"use client";

import Link from "next/link";
import {usePathname, useRouter, useSearchParams} from "next/navigation";
import {Suspense, useEffect, useMemo, useState} from "react";
import {ApiException, billingApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import type {AuthenticatedUser, PlanPublicResponse} from "@/lib/types";

type PlanCode = "CIVIQUE_3MOIS" | "INTEGRAL_3MOIS";

/**
 * Métadonnées éditoriales par plan. Les chiffres (prix, durée) viennent de
 * billingApi.listPlans côté serveur.
 */
const PRESENTATION: Record<
    PlanCode,
    {
        name: string;
        tone: "blue" | "red";
        tag: string;
        pitch: string;
        features: { label: string; strong?: boolean }[];
    }
> = {
    CIVIQUE_3MOIS: {
        name: "Civique",
        tone: "blue",
        tag: "POUR CSP · CR · NAT",
        pitch: "L'accès complet au module civique pour préparer votre démarche.",
        features: [
            {label: "Banque complète civique", strong: true},
            {label: "Examens blancs civiques illimités"},
            {label: "Entraînement par thème"},
            {label: "Révision des erreurs et favoris"},
            {label: "Statistiques par thématique"},
        ],
    },
    INTEGRAL_3MOIS: {
        name: "Intégral",
        tone: "red",
        tag: "CIVIQUE + TCF",
        pitch: "Civique + TCF IRN. Le plus complet pour CR ou naturalisation.",
        features: [
            {label: "Tout le Civique inclus", strong: true},
            {label: "Module TCF complet (CO + CE + Structure)", strong: true},
            {label: "Diagnostic CECRL (A2 / B1 / B2)"},
            {label: "Examens blancs TCF illimités"},
            {label: "Révision + statistiques"},
        ],
    },
};

const FALLBACK_PLANS: PlanPublicResponse[] = [
    {
        code: "CIVIQUE_3MOIS",
        name: "Civique — 3 mois",
        billingCycle: "THREE_MONTHS",
        price: 5.99,
        originalPrice: 9.99,
        moduleAccess: "CIVIQUE",
        durationDays: 90
    },
    {
        code: "INTEGRAL_3MOIS",
        name: "Intégral (Civique + TCF) — 3 mois",
        billingCycle: "THREE_MONTHS",
        price: 14.99,
        originalPrice: 19.99,
        moduleAccess: "INTEGRAL",
        durationDays: 90
    },
];

type CurrentPlan = "FREE" | "CIVIQUE" | "INTEGRAL";

function deriveCurrentPlan(user: AuthenticatedUser | null): CurrentPlan {
    if (!user) return "FREE";
    if (user.hasTcf) return "INTEGRAL";
    if (user.hasCivique) return "CIVIQUE";
    return "FREE";
}

function daysLeft(iso: string | null | undefined): number | null {
    if (!iso) return null;
    const diff = Date.parse(iso) - Date.now();
    if (Number.isNaN(diff)) return null;
    return Math.max(0, Math.ceil(diff / 86_400_000));
}

function formatEndDate(iso: string): string {
    return new Date(iso).toLocaleDateString("fr-FR", {
        day: "2-digit",
        month: "long",
        year: "numeric",
    });
}

function formatPrice(n: number): string {
    if (Number.isInteger(n)) return String(n);
    return n.toFixed(2).replace(".", ",");
}

function durationLabel(days: number): string {
    if (days >= 365) return `${Math.round(days / 365)} an${days >= 730 ? "s" : ""} d'accès`;
    if (days >= 30) return `${Math.round(days / 30)} mois d'accès`;
    return `${days} jours d'accès`;
}

// ============================================================================
// PAGE
// ============================================================================
export default function PaiementPage() {
    return (
        <Suspense fallback={<PayingSkeleton/>}>
            <PaiementInner/>
        </Suspense>
    );
}

function PaiementInner() {
    const {user, status} = useAuth();
    const router = useRouter();
    const pathname = usePathname();
    const searchParams = useSearchParams();
    const currentPlan = deriveCurrentPlan(user);

    const canceledParam = searchParams.get("canceled");
    const [showCanceled, setShowCanceled] = useState<boolean>(
        canceledParam === "1" || canceledParam === "true",
    );

    const [plans, setPlans] = useState<PlanPublicResponse[]>(FALLBACK_PLANS);
    const [plansLoaded, setPlansLoaded] = useState(false);
    const [loadingPlan, setLoadingPlan] = useState<PlanCode | null>(null);
    const [error, setError] = useState<string | null>(null);

    function dismissCanceled() {
        setShowCanceled(false);
        // Nettoie l'URL pour éviter de réafficher la bannière au refresh / partage.
        router.replace(pathname);
    }

    useEffect(() => {
        let cancelled = false;
        billingApi
            .listPlans()
            .then((list) => {
                if (cancelled) return;
                const payable = list.filter(
                    (p) => p.code === "CIVIQUE_3MOIS" || p.code === "INTEGRAL_3MOIS",
                );
                setPlans(payable.length > 0 ? payable : FALLBACK_PLANS);
            })
            .catch(() => {
                // Backend HS : on garde le fallback statique.
            })
            .finally(() => {
                if (!cancelled) setPlansLoaded(true);
            });
        return () => {
            cancelled = true;
        };
    }, []);

    const visiblePlans = useMemo(() => {
        const byCode = new Map(plans.map((p) => [p.code, p]));
        if (currentPlan === "INTEGRAL") {
            const integral = byCode.get("INTEGRAL_3MOIS");
            return integral ? [integral] : [];
        }
        return ["CIVIQUE_3MOIS", "INTEGRAL_3MOIS"]
            .map((code) => byCode.get(code))
            .filter((p): p is PlanPublicResponse => p !== undefined);
    }, [plans, currentPlan]);

    async function handleSubscribe(plan: PlanCode) {
        setError(null);
        setLoadingPlan(plan);
        try {
            const {url} = await billingApi.getPaymentLink(plan);
            window.location.assign(url);
        } catch (err) {
            if (err instanceof ApiException) {
                if (err.status === 503) {
                    setError(
                        "Le paiement n'est pas encore activé côté serveur (clés Stripe à configurer). Réessayez plus tard.",
                    );
                } else if (err.status === 401) {
                    setError("Connexion expirée. Reconnectez-vous puis recommencez.");
                } else {
                    setError(err.message);
                }
            } else {
                setError(
                    "Impossible d'initier le paiement. Réessayez dans un instant.",
                );
            }
            setLoadingPlan(null);
        }
    }

    if (status === "loading" || !plansLoaded) return <PayingSkeleton/>;

    if (!user) {
        return (
            <main className="pay-gate">
                <p>Connectez-vous pour souscrire ou gérer votre abonnement.</p>
                <Link href="/connexion?next=/paiement" className="pay-gate-cta">
                    Se connecter →
                </Link>
                <style>{gateStyles}</style>
            </main>
        );
    }

    return (
        <main className="pay">
            {/* ============ TOPBAR ============ */}
            <header className="topbar">
                <div>
                    <div className="breadcrumb">
                        ACCUEIL <span className="sep">/</span>{" "}
                        <Link href="/profil" className="breadcrumb-link">
                            PROFIL
                        </Link>{" "}
                        <span className="sep">/</span> ABONNEMENT
                    </div>
                    <h1>{titleFor(currentPlan, user.firstName ?? null)}</h1>
                    <p className="topbar-sub">{leadFor(currentPlan)}</p>
                </div>
            </header>

            {showCanceled && (
                <CanceledBanner onDismiss={dismissCanceled}/>
            )}

            {currentPlan !== "FREE" && (
                <CurrentSubscriptionCard user={user} currentPlan={currentPlan}/>
            )}

            {/* ============ PLAN CARDS ============ */}
            <section className={`pay-cards ${visiblePlans.length === 1 ? "is-single" : ""}`}>
                {visiblePlans.map((plan) => {
                    const code = plan.code as PlanCode;
                    const intent = deriveIntent(currentPlan, code);
                    return (
                        <PlanCard
                            key={plan.code}
                            plan={plan}
                            intent={intent}
                            loading={loadingPlan === plan.code}
                            anyLoading={loadingPlan !== null}
                            onSubscribe={() => handleSubscribe(code)}
                        />
                    );
                })}
            </section>

            {error && (
                <div className="form-error pay-error" role="alert">
                    {error}
                </div>
            )}

            {/* ============ TRUST ============ */}
            <section className="trust">
                <div className="trust-row">
                    <TrustItem
                        icon={<LockIcon/>}
                        title="Paiement sécurisé"
                        body="Stripe — CB, Apple Pay, Google Pay."
                    />
                    <TrustItem
                        icon={<RefreshOffIcon/>}
                        title="Sans renouvellement"
                        body="Aucun prélèvement automatique. Vous rachetez si vous voulez."
                    />
                    <TrustItem
                        icon={<MailIcon/>}
                        title="Support direct"
                        body={
                            <>
                                <a href="mailto:support@sejourfr.fr">hello@sejourfr.fr</a> — on
                                répond.
                            </>
                        }
                    />
                </div>
                <p className="trust-foot">
                    À l&apos;expiration, votre accès s&apos;arrête simplement. Vos données
                    (favoris, erreurs, progression) restent sur votre compte au cas où
                    vous renouvellez plus tard.
                </p>
            </section>

            <style>{styles}</style>
        </main>
    );
}

// ============================================================================
// CANCELED BANNER (retour Stripe avec ?canceled=1)
// ============================================================================
function CanceledBanner({onDismiss}: { onDismiss: () => void }) {
    return (
        <div className="cancel-banner" role="status">
            <div className="cancel-icon" aria-hidden>
                <InfoIcon/>
            </div>
            <div className="cancel-body">
                <div className="cancel-row">
                    <span className="cancel-label">PAIEMENT ANNULÉ</span>
                    <span className="cancel-pill">Aucun débit</span>
                </div>
                <div className="cancel-title">
                    Vous êtes revenu sans valider votre achat.
                </div>
                <div className="cancel-meta">
                    Aucun montant n&apos;a été prélevé. Vous pouvez choisir un plan
                    et reprendre le paiement quand vous voulez — vos données
                    démo (favoris, erreurs, progression) restent intactes.
                </div>
            </div>
            <button
                type="button"
                className="cancel-dismiss"
                onClick={onDismiss}
                aria-label="Fermer cette information"
            >
                ✕
            </button>
        </div>
    );
}

function InfoIcon() {
    return (
        <svg
            width="18"
            height="18"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
        >
            <circle cx="12" cy="12" r="10"/>
            <line x1="12" y1="16" x2="12" y2="12"/>
            <line x1="12" y1="8" x2="12.01" y2="8"/>
        </svg>
    );
}

// ============================================================================
// CURRENT SUBSCRIPTION CARD
// ============================================================================
function CurrentSubscriptionCard({
                                     user,
                                     currentPlan,
                                 }: {
    user: AuthenticatedUser;
    currentPlan: CurrentPlan;
}) {
    const remaining = daysLeft(user.premiumEndsAt);
    const label =
        currentPlan === "INTEGRAL" ? "Intégral · Civique + TCF" : "Civique";
    const expiresSoon = remaining !== null && remaining <= 14;
    const tone: "green" | "amber" = expiresSoon ? "amber" : "green";

    return (
        <div className={`current-card current-card-${tone}`}>
            <div className={`current-icon current-icon-${tone}`}>
                {expiresSoon ? <AlertIcon/> : <CheckIcon/>}
            </div>
            <div className="current-body">
                <div className="current-row">
                    <span className="current-label">PLAN ACTUEL</span>
                    <span className={`current-tone-pill current-tone-pill-${tone}`}>
            {expiresSoon ? "Bientôt expiré" : "Actif"}
          </span>
                </div>
                <div className="current-title">{label}</div>
                <div className="current-meta">
                    {user.premiumEndsAt ? (
                        <>
                            Valide jusqu&apos;au{" "}
                            <strong>{formatEndDate(user.premiumEndsAt)}</strong>
                            {remaining !== null && (
                                <>
                                    {" "}·{" "}
                                    {remaining > 0 ? (
                                        <>
                                            il vous reste{" "}
                                            <strong>
                                                {remaining} jour{remaining > 1 ? "s" : ""}
                                            </strong>
                                        </>
                                    ) : (
                                        <strong>expire aujourd&apos;hui</strong>
                                    )}
                                </>
                            )}
                        </>
                    ) : (
                        <>Abonnement actif sans date d&apos;expiration.</>
                    )}
                </div>
            </div>
        </div>
    );
}

// ============================================================================
// PLAN CARD
// ============================================================================
type CardIntent = "subscribe" | "current" | "upgrade";

function deriveIntent(currentPlan: CurrentPlan, planCode: PlanCode): CardIntent {
    if (currentPlan === "INTEGRAL" && planCode === "INTEGRAL_3MOIS") return "current";
    if (currentPlan === "CIVIQUE" && planCode === "CIVIQUE_3MOIS") return "current";
    if (currentPlan === "CIVIQUE" && planCode === "INTEGRAL_3MOIS") return "upgrade";
    return "subscribe";
}

function PlanCard({
                      plan,
                      intent,
                      loading,
                      anyLoading,
                      onSubscribe,
                  }: {
    plan: PlanPublicResponse;
    intent: CardIntent;
    loading: boolean;
    anyLoading: boolean;
    onSubscribe: () => void;
}) {
    const code = plan.code as PlanCode;
    const preset = PRESENTATION[code];
    const tone = preset.tone;

    let ctaLabel: string;
    if (loading) {
        ctaLabel = "Redirection…";
    } else {
        switch (intent) {
            case "current":
                ctaLabel = `Renouveler ${preset.name} →`;
                break;
            case "upgrade":
                ctaLabel = "Passer à l'Intégral →";
                break;
            default:
                ctaLabel = `Choisir ${preset.name} →`;
        }
    }

    let ribbon: { label: string; tone: "current" | "upgrade" | "featured" } | null = null;
    if (intent === "current") ribbon = {label: "PLAN ACTUEL", tone: "current"};
    else if (intent === "upgrade") ribbon = {label: "RECOMMANDÉ", tone: "upgrade"};
    else if (code === "INTEGRAL_3MOIS") ribbon = {label: "LE PLUS COMPLET", tone: "featured"};

    return (
        <article className={`plan-card plan-card-${tone}`}>
            {ribbon && (
                <span className={`plan-ribbon plan-ribbon-${ribbon.tone}`}>
          {ribbon.label}
        </span>
            )}
            <span className={`plan-tag plan-tag-${tone}`}>{preset.tag}</span>
            <h2 className="plan-name">{preset.name}</h2>
            <p className="plan-pitch">{preset.pitch}</p>

            <div className="plan-price">
                {plan.originalPrice !== null && plan.originalPrice > plan.price && (
                    <span className="plan-price-old">{formatPrice(plan.originalPrice)}€</span>
                )}
                <span className="plan-price-now">{formatPrice(plan.price)}€</span>
                <span className="plan-price-period">paiement unique</span>
            </div>
            <div className="plan-duration">{durationLabel(plan.durationDays)}</div>

            <ul className="plan-features">
                {preset.features.map((f) => (
                    <li key={f.label}>
            <span className="plan-check" aria-hidden>
              ✓
            </span>
                        <span>{f.strong ? <strong>{f.label}</strong> : f.label}</span>
                    </li>
                ))}
            </ul>

            <button
                type="button"
                className={`plan-cta plan-cta-${tone} ${intent === "current" ? "is-renew" : ""}`}
                onClick={onSubscribe}
                disabled={anyLoading}
            >
                {ctaLabel}
            </button>
        </article>
    );
}

// ============================================================================
// TRUST
// ============================================================================
function TrustItem({
                       icon,
                       title,
                       body,
                   }: {
    icon: React.ReactNode;
    title: string;
    body: React.ReactNode;
}) {
    return (
        <div className="trust-item">
            <span className="trust-icon">{icon}</span>
            <div>
                <div className="trust-title">{title}</div>
                <div className="trust-body">{body}</div>
            </div>
        </div>
    );
}

// ============================================================================
// HEADER COPY HELPERS
// ============================================================================
function titleFor(plan: CurrentPlan, firstName: string | null): React.ReactNode {
    if (plan === "INTEGRAL") {
        return (
            <>
                Vous avez l&apos;<em>Intégral</em>.
            </>
        );
    }
    if (plan === "CIVIQUE") {
        return (
            <>
                Votre plan <em>Civique</em>.
            </>
        );
    }
    return (
        <>
            Bonjour {firstName ?? "à vous"}, choisissez votre <em>formule</em>.
        </>
    );
}

function leadFor(plan: CurrentPlan): string {
    if (plan === "INTEGRAL") {
        return "Accès complet à la plateforme. Vous pouvez prolonger 3 mois supplémentaires à tout moment — pas de renouvellement automatique.";
    }
    if (plan === "CIVIQUE") {
        return "Renouvelez votre Civique ou passez à l'Intégral pour débloquer aussi le TCF IRN.";
    }
    return "Un paiement unique, accès 3 mois. Pas de renouvellement automatique — vous renouvelez vous-même si vous le souhaitez.";
}

// ============================================================================
// SKELETONS / GATE
// ============================================================================
function PayingSkeleton() {
    return (
        <div className="pay-loading">
            <style>{`.pay-loading { min-height: calc(100vh - 80px); background: #F7F8FC; }`}</style>
        </div>
    );
}

const gateStyles = `
  .pay-gate {
    min-height: 60vh;
    display: flex; flex-direction: column; align-items: center; justify-content: center;
    gap: 14px;
    color: var(--color-muted);
    padding: 36px;
  }
  .pay-gate-cta { color: var(--color-blue); font-weight: 700; text-decoration: none; }
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
const CheckIcon = () => (
    <I>
        <polyline points="20 6 9 17 4 12"/>
    </I>
);
const AlertIcon = () => (
    <I>
        <circle cx="12" cy="12" r="10"/>
        <line x1="12" y1="8" x2="12" y2="12"/>
        <line x1="12" y1="16" x2="12.01" y2="16"/>
    </I>
);
const LockIcon = () => (
    <I>
        <rect x="3" y="11" width="18" height="11" rx="2"/>
        <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
    </I>
);
const RefreshOffIcon = () => (
    <I>
        <path d="M3 12a9 9 0 0 1 14.5-7.1"/>
        <polyline points="17 4 17 9 12 9"/>
        <line x1="2" y1="2" x2="22" y2="22"/>
    </I>
);
const MailIcon = () => (
    <I>
        <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/>
        <polyline points="22,6 12,13 2,6"/>
    </I>
);

// ============================================================================
// STYLES
// ============================================================================
const styles = `
  .pay { padding: 24px 36px 64px; max-width: 1100px; }
  @media (max-width: 760px) { .pay { padding: 20px 16px 56px; } }

  /* ========== TOPBAR ========== */
  .topbar { margin-bottom: 26px; }
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
    font-size: clamp(24px, 3.5vw, 36px);
    font-weight: 600;
    letter-spacing: -0.02em;
    margin: 0 0 10px;
    line-height: 1.12;
    max-width: 700px;
  }
  .topbar h1 em {
    color: var(--color-blue);
    font-style: italic;
    font-weight: 500;
  }
  .topbar-sub {
    margin: 0;
    color: var(--color-muted);
    font-size: 15.5px;
    line-height: 1.55;
    max-width: 620px;
  }

  /* ========== CANCELED BANNER ========== */
  .cancel-banner {
    display: flex; align-items: flex-start; gap: 14px;
    padding: 16px 18px;
    border-radius: 14px;
    margin-bottom: 22px;
    background: linear-gradient(135deg, rgba(232, 163, 23, 0.10), #fff);
    border: 1px solid rgba(232, 163, 23, 0.32);
    border-left: 3px solid var(--color-amber);
    animation: cancel-slide-in 0.28s ease-out;
  }
  @keyframes cancel-slide-in {
    from { opacity: 0; transform: translateY(-6px); }
    to { opacity: 1; transform: translateY(0); }
  }
  .cancel-icon {
    width: 36px; height: 36px;
    background: var(--color-amber);
    color: #fff;
    border-radius: 10px;
    display: flex; align-items: center; justify-content: center;
    flex-shrink: 0;
    margin-top: 1px;
  }
  .cancel-body { flex: 1; min-width: 0; }
  .cancel-row {
    display: flex; align-items: center; gap: 8px;
    margin-bottom: 4px;
    flex-wrap: wrap;
  }
  .cancel-label {
    font-family: var(--font-mono);
    font-size: 10px;
    letter-spacing: 0.14em;
    color: var(--color-amber);
    font-weight: 700;
  }
  .cancel-pill {
    font-family: var(--font-mono);
    font-size: 9.5px;
    letter-spacing: 0.1em;
    padding: 3px 7px;
    border-radius: 100px;
    background: rgba(22, 143, 91, 0.15);
    color: var(--color-green);
    font-weight: 700;
  }
  .cancel-title {
    font-family: var(--font-sans);
    font-weight: 700;
    font-size: 14px;
    color: var(--color-ink);
    line-height: 1.3;
    margin-bottom: 4px;
  }
  .cancel-meta {
    font-size: 13px;
    color: var(--color-muted);
    line-height: 1.5;
  }
  .cancel-dismiss {
    width: 30px; height: 30px;
    border-radius: 8px;
    background: rgba(255, 255, 255, 0.6);
    border: 1px solid rgba(232, 163, 23, 0.2);
    color: var(--color-muted);
    font-size: 13px;
    cursor: pointer;
    transition: all 0.15s;
    flex-shrink: 0;
    font-family: inherit;
  }
  .cancel-dismiss:hover {
    background: #fff;
    color: var(--color-ink);
    border-color: var(--color-amber);
  }

  /* ========== CURRENT SUBSCRIPTION ========== */
  .current-card {
    display: flex; align-items: center; gap: 16px;
    padding: 18px 22px;
    border-radius: 16px;
    margin-bottom: 26px;
    border: 1px solid;
  }
  .current-card-green {
    background: linear-gradient(135deg, rgba(22, 143, 91, 0.10), #fff);
    border-color: rgba(22, 143, 91, 0.25);
  }
  .current-card-amber {
    background: linear-gradient(135deg, rgba(232, 163, 23, 0.12), #fff);
    border-color: rgba(232, 163, 23, 0.35);
  }
  .current-icon {
    width: 44px; height: 44px;
    border-radius: 12px;
    display: flex; align-items: center; justify-content: center;
    color: #fff;
    flex-shrink: 0;
  }
  .current-icon-green { background: var(--color-green); }
  .current-icon-amber { background: var(--color-amber); }
  .current-body { flex: 1; min-width: 0; }
  .current-row {
    display: flex; align-items: center; gap: 10px;
    margin-bottom: 4px;
  }
  .current-label {
    font-family: var(--font-mono);
    font-size: 10px;
    letter-spacing: 0.14em;
    color: var(--color-muted);
    font-weight: 700;
  }
  .current-tone-pill {
    font-family: var(--font-mono);
    font-size: 10px;
    letter-spacing: 0.1em;
    padding: 3px 8px;
    border-radius: 100px;
    font-weight: 700;
  }
  .current-tone-pill-green {
    background: rgba(22, 143, 91, 0.15); color: var(--color-green);
  }
  .current-tone-pill-amber {
    background: rgba(232, 163, 23, 0.2); color: var(--color-amber);
  }
  .current-title {
    font-family: var(--font-display);
    font-weight: 600;
    font-size: 19px;
    color: var(--color-ink);
    letter-spacing: -0.015em;
    margin-bottom: 4px;
  }
  .current-meta {
    font-size: 13.5px;
    color: var(--color-muted);
    line-height: 1.5;
  }
  .current-meta strong { color: var(--color-ink); font-weight: 700; }

  /* ========== PLAN CARDS ========== */
  .pay-cards {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 22px;
    margin-bottom: 26px;
  }
  .pay-cards.is-single {
    grid-template-columns: 1fr;
    max-width: 640px;
  }
  @media (max-width: 820px) {
    .pay-cards { grid-template-columns: 1fr; }
  }

  .plan-card {
    position: relative;
    border: 1.5px solid var(--color-line);
    border-radius: 22px;
    padding: 32px;
    background: #fff;
    display: flex;
    flex-direction: column;
    overflow: hidden;
    transition: transform 0.2s, box-shadow 0.2s, border-color 0.2s;
  }
  .plan-card:hover {
    transform: translateY(-3px);
    box-shadow: 0 24px 40px -22px rgba(15, 24, 57, 0.20);
  }
  .plan-card-blue {
    background: linear-gradient(135deg, var(--color-blue-soft) 0%, #fff 100%);
    border-color: var(--color-blue-light);
  }
  .plan-card-red {
    background: linear-gradient(135deg, var(--color-red-light) 0%, #fff 100%);
    border-color: rgba(225, 55, 47, 0.2);
  }

  .plan-ribbon {
    position: absolute;
    top: -14px;
    left: 32px;
    color: #fff;
    font-family: var(--font-mono);
    font-size: 10px;
    font-weight: 700;
    letter-spacing: 0.12em;
    padding: 6px 12px;
    border-radius: 100px;
    white-space: nowrap;
  }
  .plan-ribbon-featured { background: var(--color-red); }
  .plan-ribbon-upgrade { background: var(--color-blue); }
  .plan-ribbon-current { background: var(--color-green); }

  .plan-tag {
    align-self: flex-start;
    font-family: var(--font-mono);
    font-size: 10px;
    letter-spacing: 0.14em;
    padding: 5px 10px;
    border-radius: 6px;
    color: #fff;
    font-weight: 600;
    margin-bottom: 16px;
  }
  .plan-tag-blue { background: var(--color-blue); }
  .plan-tag-red { background: var(--color-red); }

  .plan-name {
    font-family: var(--font-display);
    font-weight: 600;
    font-size: 28px;
    letter-spacing: -0.02em;
    margin: 0 0 10px;
    line-height: 1.1;
    color: var(--color-ink);
  }
  .plan-pitch {
    color: var(--color-muted);
    font-size: 14px;
    margin: 0 0 22px;
    line-height: 1.5;
    min-height: 42px;
  }

  .plan-price {
    display: flex;
    align-items: baseline;
    gap: 8px;
    margin-bottom: 4px;
    flex-wrap: wrap;
  }
  .plan-price-old {
    font-family: var(--font-display);
    font-size: 20px;
    color: var(--color-muted-2);
    text-decoration: line-through;
    align-self: center;
  }
  .plan-price-now {
    font-family: var(--font-display);
    font-size: 48px;
    font-weight: 600;
    color: var(--color-ink);
    letter-spacing: -0.03em;
    line-height: 1;
  }
  .plan-price-period {
    font-family: var(--font-mono);
    font-size: 11px;
    letter-spacing: 0.1em;
    text-transform: uppercase;
    color: var(--color-muted);
  }
  .plan-duration {
    font-size: 13px;
    color: var(--color-muted);
    margin-bottom: 20px;
  }

  .plan-features {
    list-style: none;
    padding: 0;
    margin: 0 0 22px;
    display: flex;
    flex-direction: column;
    gap: 11px;
    border-top: 1px solid var(--color-line-2);
    padding-top: 20px;
    flex: 1;
  }
  .plan-features li {
    display: flex;
    gap: 10px;
    align-items: flex-start;
    color: var(--color-ink-2);
    font-size: 14px;
    line-height: 1.45;
  }
  .plan-check {
    color: var(--color-green);
    font-weight: 700;
    flex-shrink: 0;
    margin-top: 1px;
  }

  .plan-cta {
    display: inline-flex; align-items: center; justify-content: center; gap: 8px;
    padding: 14px 20px;
    border-radius: 12px;
    font-family: inherit;
    font-size: 14.5px;
    font-weight: 700;
    color: #fff;
    border: 1px solid transparent;
    cursor: pointer;
    transition: filter 0.15s, transform 0.15s, background 0.15s;
  }
  .plan-cta-blue { background: var(--color-blue); }
  .plan-cta-red { background: var(--color-red); }
  .plan-cta:hover:not(:disabled) {
    filter: brightness(1.08);
    transform: translateY(-1px);
  }
  .plan-cta:disabled {
    opacity: 0.55;
    cursor: not-allowed;
  }
  .plan-cta.is-renew {
    background: #fff;
    border-color: var(--color-line);
    color: var(--color-ink);
  }
  .plan-cta.is-renew:hover {
    border-color: var(--color-ink);
    background: var(--color-paper);
    filter: none;
  }

  .pay-error { margin-bottom: 26px; }

  /* ========== TRUST ========== */
  .trust {
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 18px;
    padding: 24px 28px;
  }
  .trust-row {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 22px;
    margin-bottom: 18px;
    padding-bottom: 18px;
    border-bottom: 1px solid var(--color-line-2);
  }
  @media (max-width: 760px) {
    .trust-row { grid-template-columns: 1fr; gap: 16px; }
  }
  .trust-item { display: flex; gap: 12px; align-items: flex-start; }
  .trust-icon {
    width: 36px; height: 36px;
    border-radius: 10px;
    background: var(--color-blue-light);
    color: var(--color-blue);
    display: flex; align-items: center; justify-content: center;
    flex-shrink: 0;
  }
  .trust-title {
    font-weight: 700; font-size: 13.5px;
    color: var(--color-ink);
    line-height: 1.2;
  }
  .trust-body {
    font-size: 12.5px;
    color: var(--color-muted);
    margin-top: 3px;
    line-height: 1.5;
  }
  .trust-body a { color: var(--color-blue); text-decoration: none; }
  .trust-body a:hover { text-decoration: underline; }
  .trust-foot {
    font-size: 12.5px;
    color: var(--color-muted);
    line-height: 1.55;
    margin: 0;
  }
`;
