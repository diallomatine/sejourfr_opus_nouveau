"use client";

import Link from "next/link";
import {usePathname, useRouter, useSearchParams} from "next/navigation";
import {Suspense, useEffect, useMemo, useState} from "react";
import {
    ApiException,
    billingApi,
    periodicityFromCycle,
    planCodeFor,
    type PlanModuleTarget,
    type PlanPeriodicity
} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import type {AuthenticatedUser, BillingCycle, PlanPublicResponse} from "@/lib/types";

// ============================================================================
// CONSTANTES DE PRÉSENTATION
// ============================================================================

const PRESENTATION: Record<
    PlanModuleTarget,
    {
        name: string;
        tone: "blue" | "red";
        tag: string;
        pitch: string;
        features: { label: string; strong?: boolean }[];
    }
> = {
    CIVIQUE: {
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
    INTEGRAL: {
        name: "Intégral",
        tone: "red",
        tag: "CIVIQUE + TCF",
        pitch: "Civique + TCF IRN avec EE/EO évalués par IA. Le plus complet pour CR ou naturalisation.",
        features: [
            {label: "Tout le Civique inclus", strong: true},
            {label: "Module TCF complet (CO + CE + Structure)", strong: true},
            {label: "Expression écrite + orale évaluée par IA"},
            {label: "Examens blancs TCF illimités"},
            {label: "Diagnostic CECRL (A2 / B1 / B2)"},
        ],
    },
};

const PERIODICITIES: { value: PlanPeriodicity; label: string; sub: string }[] = [
    {value: "monthly", label: "Mensuel", sub: "facturé chaque mois"},
    {value: "quarterly", label: "Trimestriel", sub: "facturé tous les 3 mois"},
    {value: "yearly", label: "Annuel", sub: "facturé chaque année"},
];

const PERIOD_SUFFIX: Record<PlanPeriodicity, string> = {
    monthly: "/ mois",
    quarterly: "/ 3 mois",
    yearly: "/ an",
};

// ============================================================================
// HELPERS
// ============================================================================

type CurrentPlan = "FREE" | "CIVIQUE" | "INTEGRAL";

function deriveCurrentPlan(user: AuthenticatedUser | null): CurrentPlan {
    if (!user) return "FREE";
    if (user.hasTcf) return "INTEGRAL";
    if (user.hasCivique) return "CIVIQUE";
    return "FREE";
}

function moduleFromParam(raw: string | null): PlanModuleTarget | null {
    if (raw === "CIVIQUE" || raw === "INTEGRAL") return raw;
    return null;
}

function periodicityFromParam(raw: string | null): PlanPeriodicity | null {
    if (raw === "monthly" || raw === "quarterly" || raw === "yearly") return raw;
    return null;
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

/** Libellé de durée d'un pass one-time (« 6 semaines », « 3 mois », « 1 an »). */
function durationLabel(days: number): string {
    if (days <= 0) return "";
    if (days % 365 === 0) {
        const y = days / 365;
        return y === 1 ? "1 an" : `${y} ans`;
    }
    if (days >= 30 && days % 30 === 0) return `${days / 30} mois`;
    if (days % 7 === 0) return `${days / 7} semaines`;
    return `${days} jours`;
}

/** Calcule l'équivalent mensuel d'un plan trimestriel/annuel. */
function monthlyEquivalent(price: number, cycle: BillingCycle): number | null {
    if (cycle === "THREE_MONTHS") return price / 3;
    if (cycle === "YEARLY") return price / 12;
    return null;
}

/**
 * Indexe les plans payants par (module, periodicity). Renvoie undefined si
 * la combinaison n'existe pas en DB ou si la périodicité n'est pas reconnue.
 */
function indexPlans(plans: PlanPublicResponse[]): Map<string, PlanPublicResponse> {
    const map = new Map<string, PlanPublicResponse>();
    for (const p of plans) {
        const periodicity = periodicityFromCycle(p.billingCycle);
        if (!periodicity) continue;
        let mod: PlanModuleTarget | null = null;
        if (p.moduleAccess === "CIVIQUE") mod = "CIVIQUE";
        else if (p.moduleAccess === "INTEGRAL") mod = "INTEGRAL";
        if (!mod) continue;
        map.set(`${mod}:${periodicity}`, p);
    }
    return map;
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
    const focusedModule = moduleFromParam(searchParams.get("module"));

    const canceledParam = searchParams.get("canceled");
    const [showCanceled, setShowCanceled] = useState<boolean>(
        canceledParam === "1" || canceledParam === "true",
    );

    const [plans, setPlans] = useState<PlanPublicResponse[]>([]);
    const [plansLoaded, setPlansLoaded] = useState(false);
    const [plansError, setPlansError] = useState<string | null>(null);
    const initialPeriodicity = periodicityFromParam(searchParams.get("period")) ?? "quarterly";
    const [periodicity, setPeriodicity] = useState<PlanPeriodicity>(initialPeriodicity);
    const [loadingCode, setLoadingCode] = useState<string | null>(null);
    const [error, setError] = useState<string | null>(null);

    function dismissCanceled() {
        setShowCanceled(false);
        router.replace(pathname);
    }

    useEffect(() => {
        let cancelled = false;
        billingApi
            .listPlans()
            .then((list) => {
                if (cancelled) return;
                setPlans(list);
            })
            .catch(() => {
                if (cancelled) return;
                setPlansError("Tarifs indisponibles pour le moment. Réessayez dans un instant.");
            })
            .finally(() => {
                if (!cancelled) setPlansLoaded(true);
            });
        return () => {
            cancelled = true;
        };
    }, []);

    const index = useMemo(() => indexPlans(plans), [plans]);

    // Mode passes one-time (lot 5) : pas de toggle de périodicité, grille de
    // passes par module. On ignore les plans non payables (FREE) dans la
    // détection — sinon le FREE (SUBSCRIPTION) casserait le `every`.
    const payablePlans = plans.filter(
        (p) => p.moduleAccess !== "NONE" && p.price > 0,
    );
    const oneTime =
        payablePlans.length > 0 &&
        payablePlans.every((p) => p.purchaseType === "ONE_TIME");

    /** Modules visibles : INTEGRAL seul si déjà INTEGRAL ; les 2 sinon ; focus si demandé. */
    const visibleModules = useMemo<PlanModuleTarget[]>(() => {
        if (currentPlan === "INTEGRAL") return ["INTEGRAL"];
        if (focusedModule) {
            // Toujours montrer INTEGRAL à côté pour permettre l'upgrade
            return focusedModule === "INTEGRAL" ? ["INTEGRAL"] : ["CIVIQUE", "INTEGRAL"];
        }
        return ["CIVIQUE", "INTEGRAL"];
    }, [currentPlan, focusedModule]);

    async function handleSubscribe(planCode: string) {
        setError(null);
        setLoadingCode(planCode);
        try {
            const {url} = await billingApi.getPaymentLink(planCode);
            window.location.assign(url);
        } catch (err) {
            if (err instanceof ApiException) {
                if (err.status === 503) {
                    setError("Le paiement n'est pas encore activé côté serveur (clés Stripe à configurer). Réessayez plus tard.");
                } else if (err.status === 404) {
                    setError("Ce plan n'est plus disponible. Rechargez la page pour voir les tarifs à jour.");
                } else if (err.status === 401) {
                    setError("Connexion expirée. Reconnectez-vous puis recommencez.");
                } else {
                    setError(err.message);
                }
            } else {
                setError("Impossible d'initier le paiement. Réessayez dans un instant.");
            }
            setLoadingCode(null);
        }
    }

    if (status === "loading" || !plansLoaded) return <PayingSkeleton/>;

    if (!user) {
        return (
            <main className="pay-gate">
                <p>Connectez-vous pour obtenir ou gérer votre accès.</p>
                <Link href="/connexion?next=/paiement" className="pay-gate-cta">
                    Se connecter →
                </Link>
                <style>{gateStyles}</style>
            </main>
        );
    }

    if (plansError) {
        return (
            <main className="pay-gate">
                <p>{plansError}</p>
                <button type="button" onClick={() => window.location.reload()} className="pay-gate-cta">
                    Réessayer
                </button>
                <style>{gateStyles}</style>
            </main>
        );
    }

    return (
        <main className="pay">
            <header className="pay-hero">
                <div className="breadcrumb">
                    ACCUEIL <span className="sep">/</span>{" "}
                    <Link href="/profil" className="breadcrumb-link">
                        PROFIL
                    </Link>{" "}
                    <span className="sep">/</span> ABONNEMENT
                </div>
                <h1>{titleFor(currentPlan, user.firstName ?? null)}</h1>
                <p className="pay-hero-sub">{leadFor(currentPlan)}</p>
                <div className="pay-hero-chips">
                    <span className="pay-hero-chip">
                        <LockIcon/> Paiement sécurisé Stripe
                    </span>
                    <span className="pay-hero-chip">
                        <CalendarIcon/> Sans renouvellement
                    </span>
                    <span className="pay-hero-chip">
                        <CheckIcon/> Sans engagement
                    </span>
                </div>
            </header>

            {showCanceled && <CanceledBanner onDismiss={dismissCanceled}/>}

            {currentPlan !== "FREE" && (
                <CurrentSubscriptionCard user={user} currentPlan={currentPlan}/>
            )}

            {oneTime ? (
                <OneTimePasses
                    plans={plans}
                    modules={visibleModules}
                    loadingCode={loadingCode}
                    onSubscribe={handleSubscribe}
                />
            ) : (
                <>
                    <PeriodicityToggle value={periodicity} onChange={setPeriodicity}/>

                    <section className={`pay-cards ${visibleModules.length === 1 ? "is-single" : ""}`}>
                        {visibleModules.map((module) => {
                            const plan = index.get(`${module}:${periodicity}`);
                            if (!plan) return null;
                            const intent = deriveIntent(currentPlan, module);
                            return (
                                <PlanCard
                                    key={module}
                                    module={module}
                                    plan={plan}
                                    periodicity={periodicity}
                                    intent={intent}
                                    loading={loadingCode === planCodeFor(module, periodicity)}
                                    anyLoading={loadingCode !== null}
                                    onSubscribe={() => handleSubscribe(planCodeFor(module, periodicity))}
                                />
                            );
                        })}
                    </section>
                </>
            )}

            {error && (
                <div className="form-error pay-error" role="alert">
                    {error}
                </div>
            )}

            <section className="trust">
                <div className="trust-row">
                    <TrustItem
                        icon={<LockIcon/>}
                        title="Paiement sécurisé"
                        body="Stripe — CB, Apple Pay, Google Pay."
                    />
                    <TrustItem
                        icon={<CalendarIcon/>}
                        title="Sans renouvellement"
                        body="Vous accédez à l'app pour toute la durée de votre pass."
                    />
                    <TrustItem
                        icon={<MailIcon/>}
                        title="Support direct"
                        body={
                            <>
                                <a href="mailto:support@sejourfr.fr">support@sejourfr.fr</a> — on
                                répond.
                            </>
                        }
                    />
                </div>
                <p className="trust-foot">
                    Vos données (favoris, erreurs, progression) restent sur votre compte
                    si vous reprenez un accès plus tard.
                </p>
            </section>

            <style>{styles}</style>
        </main>
    );
}

// ============================================================================
// PASSES ONE-TIME (lot 5) — grille de passes par module
// ============================================================================

/** Pass mis en avant comme « le plus populaire » (cohérent web + mobile). */
const POPULAR_PASS_CODE = "INTEGRAL_PASS_3M";

function OneTimePasses({
                           plans,
                           modules,
                           loadingCode,
                           onSubscribe,
                       }: {
    plans: PlanPublicResponse[];
    modules: PlanModuleTarget[];
    loadingCode: string | null;
    onSubscribe: (code: string) => void;
}) {
    return (
        <section className={`pay-cards ${modules.length === 1 ? "is-single" : ""}`}>
            {modules.map((module) => {
                const passes = plans
                    .filter((p) => p.purchaseType === "ONE_TIME" && p.moduleAccess === module)
                    .sort((a, b) => a.durationDays - b.durationDays);
                if (passes.length === 0) return null;
                const pres = PRESENTATION[module];
                return (
                    <article key={module} className={`otp-card otp-${pres.tone}`}>
                        <span className="otp-tag">{pres.tag}</span>
                        <h2 className="otp-name">{pres.name}</h2>
                        <p className="otp-pitch">{pres.pitch}</p>
                        <ul className="otp-features">
                            {pres.features.map((f) => (
                                <li key={f.label} className={f.strong ? "is-strong" : ""}>
                                    <CheckIcon/> {f.label}
                                </li>
                            ))}
                        </ul>
                        <div className="otp-passes">
                            {passes.map((p) => {
                                const popular = p.code === POPULAR_PASS_CODE;
                                return (
                                    <button
                                        key={p.code}
                                        type="button"
                                        className={`otp-pass ${popular ? "is-popular" : ""}`}
                                        disabled={loadingCode !== null}
                                        onClick={() => onSubscribe(p.code)}
                                    >
                                        {popular && <span className="otp-pop">Le plus populaire</span>}
                                        <span className="otp-pass-dur">{durationLabel(p.durationDays)}</span>
                                        <span className="otp-pass-price">{formatPrice(p.price)} €</span>
                                        <span className="otp-pass-cta">
                                            {loadingCode === p.code ? "…" : "Choisir →"}
                                        </span>
                                    </button>
                                );
                            })}
                        </div>
                    </article>
                );
            })}
            <style>{otpStyles}</style>
        </section>
    );
}

const otpStyles = `
.otp-card { border:1.5px solid var(--color-line); border-radius:22px; padding:28px; background:#fff; display:flex; flex-direction:column; }
.otp-blue { background:linear-gradient(135deg,var(--color-blue-soft) 0%,#fff 100%); border-color:var(--color-blue-light); }
.otp-red { background:linear-gradient(135deg,var(--color-red-light) 0%,#fff 100%); border-color:rgba(225,55,47,.2); }
.otp-tag { font-family:var(--font-mono); font-size:10px; letter-spacing:.12em; color:var(--color-muted); text-transform:uppercase; }
.otp-name { font-family:var(--font-display); font-size:30px; font-weight:600; color:var(--color-ink); margin:10px 0 4px; }
.otp-pitch { font-size:14px; color:var(--color-muted); line-height:1.55; margin:0 0 16px; }
.otp-features { list-style:none; padding:0; margin:0 0 18px; display:flex; flex-direction:column; gap:8px; }
.otp-features li { display:flex; align-items:flex-start; gap:8px; font-size:13.5px; color:var(--color-ink-2); line-height:1.4; }
.otp-features li.is-strong { font-weight:700; color:var(--color-ink); }
.otp-features svg { flex:0 0 auto; margin-top:2px; color:var(--color-green); }
.otp-passes { display:flex; flex-direction:column; gap:10px; margin-top:auto; }
.otp-pass { position:relative; display:flex; align-items:center; gap:12px; width:100%; text-align:left; padding:14px 16px; border-radius:12px; border:1.5px solid var(--color-line); background:#fff; cursor:pointer; transition:border-color .15s, transform .15s; }
.otp-pass:hover:not(:disabled) { border-color:var(--color-blue); transform:translateY(-1px); }
.otp-pass:disabled { opacity:.55; cursor:default; }
.otp-pass.is-popular { border-color:var(--color-red); background:var(--color-red-light); }
.otp-pop { position:absolute; top:-9px; left:14px; background:var(--color-red); color:#fff; font-family:var(--font-mono); font-size:9px; font-weight:700; letter-spacing:.1em; text-transform:uppercase; padding:2px 8px; border-radius:100px; }
.otp-pass-dur { font-weight:700; font-size:15px; color:var(--color-ink); flex:1; min-width:0; }
.otp-pass-price { font-family:var(--font-display); font-size:20px; font-weight:700; color:var(--color-ink); }
.otp-pass-cta { font-family:var(--font-mono); font-size:11px; font-weight:700; color:var(--color-blue); white-space:nowrap; }
`;

// ============================================================================
// PERIODICITY TOGGLE
// ============================================================================
function PeriodicityToggle({
                               value,
                               onChange,
                           }: {
    value: PlanPeriodicity;
    onChange: (v: PlanPeriodicity) => void;
}) {
    return (
        <div className="period-toggle" role="tablist" aria-label="Périodicité de l'abonnement">
            {PERIODICITIES.map((p) => {
                const active = p.value === value;
                return (
                    <button
                        key={p.value}
                        type="button"
                        role="tab"
                        aria-selected={active}
                        className={`period-btn ${active ? "is-active" : ""}`}
                        onClick={() => onChange(p.value)}
                    >
                        <span className="period-label">{p.label}</span>
                        <span className="period-sub">{p.sub}</span>
                    </button>
                );
            })}
        </div>
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
                    et reprendre le paiement quand vous voulez.
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
    const label = currentPlan === "INTEGRAL" ? "Intégral · Civique + TCF" : "Civique";
    const expiresSoon = remaining !== null && remaining <= 14;
    const tone: "green" | "amber" = expiresSoon ? "amber" : "green";

    return (
        <div className={`current-card current-card-${tone}`}>
            <div className={`current-icon current-icon-${tone}`}>
                {expiresSoon ? <AlertIcon/> : <CheckIcon/>}
            </div>
            <div className="current-body">
                <div className="current-row">
                    <span className="current-label">MON ACCÈS</span>
                    <span className={`current-tone-pill current-tone-pill-${tone}`}>
                        {expiresSoon ? "Bientôt terminé" : "Actif"}
                    </span>
                </div>
                <div className="current-title">{label}</div>
                <div className="current-meta">
                    {user.premiumEndsAt ? (
                        <>
                            Accès jusqu&apos;au{" "}
                            <strong>{formatEndDate(user.premiumEndsAt)}</strong>
                            {remaining !== null && (
                                <>
                                    {" "}·{" "}
                                    {remaining > 0 ? (
                                        <>
                                            encore <strong>{remaining} jour{remaining > 1 ? "s" : ""}</strong>
                                        </>
                                    ) : (
                                        <strong>se termine aujourd&apos;hui</strong>
                                    )}
                                </>
                            )}
                        </>
                    ) : (
                        <>Accès actif.</>
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

function deriveIntent(currentPlan: CurrentPlan, module: PlanModuleTarget): CardIntent {
    if (currentPlan === "INTEGRAL" && module === "INTEGRAL") return "current";
    if (currentPlan === "CIVIQUE" && module === "CIVIQUE") return "current";
    if (currentPlan === "CIVIQUE" && module === "INTEGRAL") return "upgrade";
    return "subscribe";
}

function PlanCard({
                      module,
                      plan,
                      periodicity,
                      intent,
                      loading,
                      anyLoading,
                      onSubscribe,
                  }: {
    module: PlanModuleTarget;
    plan: PlanPublicResponse;
    periodicity: PlanPeriodicity;
    intent: CardIntent;
    loading: boolean;
    anyLoading: boolean;
    onSubscribe: () => void;
}) {
    const preset = PRESENTATION[module];
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
    else if (module === "INTEGRAL") ribbon = {label: "LE PLUS COMPLET", tone: "featured"};

    const monthly = monthlyEquivalent(plan.price, plan.billingCycle);

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
                <span className="plan-price-period">{PERIOD_SUFFIX[periodicity]}</span>
            </div>
            {monthly !== null && (
                <div className="plan-equivalence">
                    soit {formatPrice(Number(monthly.toFixed(2)))}€/mois
                </div>
            )}

            <ul className="plan-features">
                {preset.features.map((f) => (
                    <li key={f.label}>
                        <span className="plan-check" aria-hidden>✓</span>
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
            <>Vous avez l&apos;<em>Intégral</em>.</>
        );
    }
    if (plan === "CIVIQUE") {
        return (
            <>Votre plan <em>Civique</em>.</>
        );
    }
    return (
        <>Bonjour {firstName ?? "à vous"}, choisissez votre <em>formule</em>.</>
    );
}

function leadFor(plan: CurrentPlan): string {
    if (plan === "INTEGRAL") {
        return "Accès complet à la plateforme. Prolongez quand vous le souhaitez — paiement unique, sans abonnement.";
    }
    if (plan === "CIVIQUE") {
        return "Prolongez votre Civique ou passez à l'Intégral pour débloquer aussi le TCF IRN.";
    }
    return "Choisissez la durée qui colle à votre échéance d'examen. Paiement unique, sans abonnement ni reconduction.";
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
    text-align: center;
  }
  .pay-gate-cta {
    color: var(--color-blue);
    font-weight: 700;
    text-decoration: none;
    background: none;
    border: 1px solid var(--color-blue);
    padding: 10px 18px;
    border-radius: 10px;
    font-family: inherit;
    cursor: pointer;
  }
  .pay-gate-cta:hover { background: var(--color-blue); color: #fff; }
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
const CalendarIcon = () => (
    <I>
        <rect x="3" y="4" width="18" height="18" rx="2" ry="2"/>
        <line x1="16" y1="2" x2="16" y2="6"/>
        <line x1="8" y1="2" x2="8" y2="6"/>
        <line x1="3" y1="10" x2="21" y2="10"/>
    </I>
);
const MailIcon = () => (
    <I>
        <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/>
        <polyline points="22,6 12,13 2,6"/>
    </I>
);
const InfoIcon = () => (
    <I>
        <circle cx="12" cy="12" r="10"/>
        <line x1="12" y1="16" x2="12" y2="12"/>
        <line x1="12" y1="8" x2="12.01" y2="8"/>
    </I>
);

// ============================================================================
// STYLES
// ============================================================================
const styles = `
  .pay { padding: 24px 36px 64px; max-width: 1100px; }
  @media (max-width: 760px) { .pay { padding: 20px 16px 56px; } }

  /* ========== HERO ========== */
  .pay-hero {
    background: linear-gradient(135deg, var(--color-blue) 0%, #3355B5 100%);
    color: #fff;
    border-radius: 20px;
    padding: 30px;
    margin-bottom: 26px;
  }
  @media (max-width: 760px) { .pay-hero { padding: 22px; } }
  .breadcrumb {
    font-family: var(--font-mono);
    font-size: 11px;
    color: rgba(255, 255, 255, 0.7);
    letter-spacing: 0.12em;
    text-transform: uppercase;
    margin-bottom: 8px;
  }
  .breadcrumb-link {
    color: rgba(255, 255, 255, 0.85);
    text-decoration: none;
    transition: color 0.15s;
  }
  .breadcrumb-link:hover { color: #fff; }
  .breadcrumb .sep { margin: 0 6px; opacity: 0.5; }
  .pay-hero h1 {
    font-family: var(--font-display);
    font-size: clamp(24px, 3.5vw, 34px);
    font-weight: 600;
    letter-spacing: -0.02em;
    margin: 0 0 10px;
    line-height: 1.12;
    max-width: 640px;
    color: #fff;
  }
  .pay-hero h1 em {
    font-style: italic;
    font-weight: 500;
    opacity: 0.92;
  }
  .pay-hero-sub {
    margin: 0;
    color: rgba(255, 255, 255, 0.82);
    font-size: 15px;
    line-height: 1.55;
    max-width: 600px;
  }
  .pay-hero-chips {
    display: flex; flex-wrap: wrap; gap: 10px;
    margin-top: 18px;
  }
  .pay-hero-chip {
    display: inline-flex; align-items: center; gap: 7px;
    font-size: 12.5px; font-weight: 600; color: #fff;
    background: rgba(255, 255, 255, 0.12);
    border: 1px solid rgba(255, 255, 255, 0.2);
    padding: 7px 12px; border-radius: 100px;
  }
  .pay-hero-chip svg { width: 15px; height: 15px; }

  /* ========== PERIODICITY TOGGLE ========== */
  .period-toggle {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 8px;
    background: var(--color-paper-2);
    border-radius: 16px;
    padding: 6px;
    margin-bottom: 26px;
  }
  .period-btn {
    background: transparent;
    border: none;
    border-radius: 12px;
    padding: 12px 10px;
    font-family: inherit;
    color: var(--color-muted);
    cursor: pointer;
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 2px;
    transition: background 0.15s, color 0.15s, box-shadow 0.15s;
  }
  .period-btn:hover { color: var(--color-ink); }
  .period-btn.is-active {
    background: #fff;
    color: var(--color-ink);
    box-shadow: 0 2px 8px -2px rgba(15, 24, 57, 0.12);
  }
  .period-label {
    font-weight: 700;
    font-size: 14px;
  }
  .period-sub {
    font-family: var(--font-mono);
    font-size: 10px;
    letter-spacing: 0.08em;
    color: var(--color-muted);
    text-transform: uppercase;
  }
  @media (max-width: 560px) {
    .period-btn { padding: 10px 6px; }
    .period-label { font-size: 13px; }
    .period-sub { display: none; }
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
    font-weight: 700; font-size: 14px;
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
    cursor: pointer;
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
    /* Laisse respirer le ruban des cartes (positionné en top: -14px). */
    margin: 14px 0 26px;
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
    margin-bottom: 2px;
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
  .plan-equivalence {
    font-family: var(--font-mono);
    font-size: 11px;
    letter-spacing: 0.08em;
    color: var(--color-muted);
    margin-bottom: 18px;
    text-transform: lowercase;
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
