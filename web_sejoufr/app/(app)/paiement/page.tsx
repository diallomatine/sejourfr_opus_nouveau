"use client";

import Link from "next/link";
import { Suspense, useEffect, useMemo, useState } from "react";
import { ApiException, billingApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import type { AuthenticatedUser, PlanPublicResponse } from "@/lib/types";

type PlanCode = "CIVIQUE_3MOIS" | "INTEGRAL_3MOIS";

/**
 * Métadonnées éditoriales des plans, indexées par code backend. Le prix et la
 * durée viennent de l'API (billingApi.listPlans), pas d'ici.
 */
const PRESENTATION: Record<PlanCode, { name: string; tag: string; features: string[] }> = {
  CIVIQUE_3MOIS: {
    name: "Civique",
    tag: "Pour CSP · CR · NAT",
    features: [
      "Accès illimité à toutes les questions civique (CSP, CR, NAT)",
      "Examens blancs civique à volonté",
      "Suivi de progression par thème",
      "Mode entraînement et révision des erreurs",
    ],
  },
  INTEGRAL_3MOIS: {
    name: "Intégral",
    tag: "Civique + TCF",
    features: [
      "Tout ce que contient Civique",
      "Accès complet au TCF (A2, B1, B2)",
      "Examens blancs TCF",
      "Compréhension écrite, orale et structure de la langue",
    ],
  },
};

const FALLBACK_PLANS: PlanPublicResponse[] = [
  { code: "CIVIQUE_3MOIS", name: "Civique — 3 mois", billingCycle: "THREE_MONTHS", price: 5.99, originalPrice: 9.99, moduleAccess: "CIVIQUE", durationDays: 90 },
  { code: "INTEGRAL_3MOIS", name: "Intégral (Civique + TCF) — 3 mois", billingCycle: "THREE_MONTHS", price: 14.99, originalPrice: 19.99, moduleAccess: "INTEGRAL", durationDays: 90 },
];

type CurrentPlan = "FREE" | "CIVIQUE" | "INTEGRAL";

/**
 * Calcule le plan dont l'utilisateur dispose actuellement. INTEGRAL prime sur
 * CIVIQUE (hasTcf implique hasCivique en pratique : Intégral débloque tout).
 */
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

export default function PaiementPage() {
  return (
    <Suspense fallback={null}>
      <PaiementInner />
    </Suspense>
  );
}

function PaiementInner() {
  const { user, status } = useAuth();
  const currentPlan = deriveCurrentPlan(user);

  const [plans, setPlans] = useState<PlanPublicResponse[]>(FALLBACK_PLANS);
  const [plansLoaded, setPlansLoaded] = useState(false);
  const [loadingPlan, setLoadingPlan] = useState<PlanCode | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    billingApi
      .listPlans()
      .then((list) => {
        if (cancelled) return;
        // On garde seulement les 2 plans payants pour cette page (FREE n'a
        // pas de checkout). Si le backend ne renvoie qu'un sous-ensemble, on
        // s'aligne dessus.
        const payable = list.filter((p) => p.code === "CIVIQUE_3MOIS" || p.code === "INTEGRAL_3MOIS");
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

  // Quel(s) plan(s) afficher selon le statut user :
  //  - FREE     : les deux plans à acheter
  //  - CIVIQUE  : les deux, Civique en "renouveler", Intégral en "upgrader"
  //  - INTEGRAL : juste Intégral en "renouveler" (pas de downgrade)
  const visiblePlans = useMemo(() => {
    const byCode = new Map(plans.map((p) => [p.code, p]));
    if (currentPlan === "INTEGRAL") {
      const integral = byCode.get("INTEGRAL_3MOIS");
      return integral ? [integral] : [];
    }
    // FREE ou CIVIQUE : on affiche les deux dans l'ordre Civique puis Intégral.
    return ["CIVIQUE_3MOIS", "INTEGRAL_3MOIS"]
      .map((code) => byCode.get(code))
      .filter((p): p is PlanPublicResponse => p !== undefined);
  }, [plans, currentPlan]);

  async function handleSubscribe(plan: PlanCode) {
    setError(null);
    setLoadingPlan(plan);
    try {
      const { url } = await billingApi.getPaymentLink(plan);
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
        setError("Impossible d'initier le paiement. Réessayez dans un instant.");
      }
      setLoadingPlan(null);
    }
  }

  if (status === "loading" || !plansLoaded) {
    return <div className="pay-loading" />;
  }

  if (!user) {
    return (
      <div className="pay-page">
        <div className="container-x" style={{ textAlign: "center", padding: "80px 20px" }}>
          <p>Connectez-vous pour souscrire ou gérer votre abonnement.</p>
          <Link href="/connexion?next=/paiement" className="btn btn-blue">
            Se connecter
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="pay-page">
      <div className="container-x">
        <Header currentPlan={currentPlan} user={user} />

        {currentPlan !== "FREE" && (
          <CurrentSubscriptionBanner user={user} currentPlan={currentPlan} />
        )}

        <div
          className={`pay-cards ${visiblePlans.length === 1 ? "pay-cards-single" : ""}`}
        >
          {visiblePlans.map((plan) => {
            const intent = deriveIntent(currentPlan, plan.code as PlanCode);
            return (
              <PlanCard
                key={plan.code}
                plan={plan}
                intent={intent}
                loading={loadingPlan === plan.code}
                anyLoading={loadingPlan !== null}
                onSubscribe={() => handleSubscribe(plan.code as PlanCode)}
              />
            );
          })}
        </div>

        {error && (
          <div className="pay-error" role="alert">
            {error}
          </div>
        )}

        <div className="pay-trust">
          <p>
            <strong>Paiement 100 % sécurisé Stripe</strong> · CB, Apple Pay, Google Pay
          </p>
          <p className="muted small">
            Aucun renouvellement automatique. Aucun prélèvement après les 3 mois.
            Vous gardez le contrôle total&nbsp;: à l&apos;expiration, vous pouvez
            racheter quand vous voulez.
          </p>
          <p className="muted small">
            Une question ?{" "}
            <Link href="mailto:hello@sejourfr.fr" className="btn-link-soft">
              hello@sejourfr.fr
            </Link>
          </p>
        </div>
      </div>

      <style>{styles}</style>
    </div>
  );
}

// ============================================================================
// HEADER (dépend du statut)
// ============================================================================
function Header({ currentPlan, user }: { currentPlan: CurrentPlan; user: AuthenticatedUser }) {
  if (currentPlan === "INTEGRAL") {
    return (
      <header className="pay-header">
        <span className="eyebrow">Votre abonnement</span>
        <h1 className="editorial">
          Vous avez l&apos;<em>Intégral</em>.
        </h1>
        <p className="lead">
          Accès complet à la plateforme. Vous pouvez prolonger 3 mois
          supplémentaires à tout moment&nbsp;— pas de renouvellement automatique.
        </p>
      </header>
    );
  }
  if (currentPlan === "CIVIQUE") {
    return (
      <header className="pay-header">
        <span className="eyebrow">Votre abonnement</span>
        <h1 className="editorial">
          Vous avez le plan <em>Civique</em>.
        </h1>
        <p className="lead">
          Vous pouvez renouveler votre Civique ou passer à l&apos;Intégral pour
          débloquer aussi le TCF IRN.
        </p>
      </header>
    );
  }
  return (
    <header className="pay-header">
      <span className="eyebrow">Offre de lancement</span>
      <h1 className="editorial">
        Bonjour <em>{user.firstName ?? "à vous"}</em>, choisissez votre formule.
      </h1>
      <p className="lead">
        Un paiement unique, accès 3 mois.<br />
        <strong>Pas de renouvellement automatique</strong>&nbsp;— vous renouvellerez
        vous-même si vous le souhaitez.
      </p>
    </header>
  );
}

// ============================================================================
// BANDEAU "PLAN ACTUEL"
// ============================================================================
function CurrentSubscriptionBanner({
  user,
  currentPlan,
}: {
  user: AuthenticatedUser;
  currentPlan: CurrentPlan;
}) {
  const remaining = daysLeft(user.premiumEndsAt);
  const label = currentPlan === "INTEGRAL" ? "Intégral (Civique + TCF)" : "Civique 3 mois";
  const expiresSoon = remaining !== null && remaining <= 14;

  return (
    <div className={`pay-current ${expiresSoon ? "expires-soon" : ""}`}>
      <div className="pay-current-icon" aria-hidden>
        <svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <path d="M12 2l3 7h7l-5.5 4 2 7L12 16l-6.5 4 2-7L2 9h7z" />
        </svg>
      </div>
      <div className="pay-current-body">
        <div className="pay-current-title">
          Plan actuel&nbsp;: <strong>{label}</strong>
        </div>
        <div className="pay-current-meta">
          {user.premiumEndsAt ? (
            <>
              Valide jusqu&apos;au <strong>{formatEndDate(user.premiumEndsAt)}</strong>
              {remaining !== null && (
                <>
                  {" "}· {remaining > 0
                    ? <>il vous reste <strong>{remaining} jour{remaining > 1 ? "s" : ""}</strong></>
                    : <strong>expire aujourd&apos;hui</strong>}
                </>
              )}
            </>
          ) : (
            <>Abonnement actif sans date d&apos;expiration.</>
          )}
        </div>
      </div>
      {expiresSoon && (
        <span className="pay-current-warn" title="Pensez à renouveler">!</span>
      )}
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
  const isIntegral = code === "INTEGRAL_3MOIS";

  // Libellé du CTA selon le contexte.
  let ctaLabel: string;
  if (loading) {
    ctaLabel = "Redirection…";
  } else {
    switch (intent) {
      case "current":
        ctaLabel = `Renouveler ${preset.name}`;
        break;
      case "upgrade":
        ctaLabel = "Passer à l'Intégral";
        break;
      default:
        ctaLabel = `Souscrire à ${preset.name}`;
    }
  }

  // Badge en haut de carte.
  let ribbon: { label: string; tone: "current" | "upgrade" | "featured" } | null = null;
  if (intent === "current") {
    ribbon = { label: "Plan actuel", tone: "current" };
  } else if (intent === "upgrade") {
    ribbon = { label: "Recommandé", tone: "upgrade" };
  } else if (isIntegral) {
    ribbon = { label: "Le plus complet", tone: "featured" };
  }

  // Styles selon intent
  const cardClass = [
    "pay-card",
    isIntegral ? "is-featured" : "",
    intent === "current" ? "is-current" : "",
  ]
    .filter(Boolean)
    .join(" ");

  // Le CTA reste actif même pour "current" (= renouveler).
  return (
    <article className={cardClass}>
      {ribbon && (
        <span className={`ribbon ribbon-${ribbon.tone}`}>{ribbon.label}</span>
      )}
      <header className="pay-card-head">
        <span className="eyebrow">{preset.tag}</span>
        <h2>{preset.name}</h2>
        <p className="muted">{durationLabel(plan.durationDays)}</p>
      </header>

      <div className="pay-price">
        {plan.originalPrice !== null && plan.originalPrice > plan.price && (
          <span className="price-strike" aria-label="Prix normal barré">
            {formatPrice(plan.originalPrice)} €
          </span>
        )}
        <span className="price-now">
          {formatPrice(plan.price)}
          <span className="cents"> €</span>
        </span>
        <span className="price-period">
          {intent === "current" ? "pour 3 mois supplémentaires" : "paiement unique"}
        </span>
      </div>

      <ul className="pay-features">
        {preset.features.map((f) => (
          <li key={f}>
            <span className="check" aria-hidden>✓</span>
            {f}
          </li>
        ))}
      </ul>

      <button
        type="button"
        className={`btn btn-lg ${intent === "current" ? "btn-ghost" : isIntegral ? "btn-red" : ""}`}
        onClick={onSubscribe}
        disabled={anyLoading}
      >
        {ctaLabel}
      </button>
    </article>
  );
}

function durationLabel(days: number): string {
  if (days >= 365) return `${Math.round(days / 365)} an${days >= 730 ? "s" : ""} d'accès`;
  if (days >= 30) return `${Math.round(days / 30)} mois d'accès`;
  return `${days} jours d'accès`;
}

// ============================================================================
// STYLES
// ============================================================================
const styles = `
  .pay-page {
    padding: 48px 0 80px;
    background: var(--color-paper);
    min-height: calc(100vh - 64px);
  }
  .pay-loading { min-height: 60vh; }

  .pay-header {
    text-align: center;
    max-width: 720px;
    margin: 0 auto 32px;
    padding: 0 20px;
  }
  .pay-header h1 {
    font-size: clamp(1.875rem, 4vw, 2.75rem);
    margin: 12px 0 14px;
    color: var(--color-ink);
  }
  .lead {
    font-size: 1rem;
    color: var(--color-muted);
    line-height: 1.6;
  }
  .lead strong { color: var(--color-ink); }

  /* BANDEAU PLAN ACTUEL */
  .pay-current {
    display: flex; align-items: center; gap: 14px;
    max-width: 920px;
    margin: 0 auto 32px;
    padding: 14px 18px;
    background: linear-gradient(135deg, rgba(22, 143, 91, 0.10) 0%, #fff 100%);
    border: 1px solid rgba(22, 143, 91, 0.25);
    border-left: 4px solid var(--color-green);
    border-radius: 14px;
  }
  .pay-current.expires-soon {
    background: linear-gradient(135deg, rgba(232, 163, 23, 0.12) 0%, #fff 100%);
    border-color: rgba(232, 163, 23, 0.35);
    border-left-color: var(--color-amber);
  }
  .pay-current-icon {
    width: 40px; height: 40px;
    background: var(--color-green); color: #fff;
    border-radius: 11px;
    display: flex; align-items: center; justify-content: center;
    flex-shrink: 0;
  }
  .pay-current.expires-soon .pay-current-icon { background: var(--color-amber); }
  .pay-current-body { flex: 1; min-width: 0; }
  .pay-current-title {
    font-family: var(--font-sans); font-weight: 700; font-size: 14.5px;
    color: var(--color-ink); line-height: 1.2;
  }
  .pay-current-meta {
    font-size: 12.5px; color: var(--color-muted); margin-top: 3px; line-height: 1.4;
  }
  .pay-current-meta strong { color: var(--color-ink); font-weight: 600; }
  .pay-current-warn {
    background: var(--color-amber); color: #fff;
    width: 28px; height: 28px;
    border-radius: 50%;
    display: flex; align-items: center; justify-content: center;
    font-family: var(--font-display); font-weight: 700; font-size: 18px;
    flex-shrink: 0;
  }

  /* CARDS */
  .pay-cards {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 24px;
    max-width: 920px;
    margin: 0 auto;
    padding: 0 20px;
  }
  .pay-cards-single {
    grid-template-columns: 1fr;
    max-width: 560px;
  }
  @media (max-width: 720px) {
    .pay-cards { grid-template-columns: 1fr; }
  }

  .pay-card {
    position: relative;
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 16px;
    padding: 32px 28px;
    display: flex;
    flex-direction: column;
    gap: 24px;
  }
  .pay-card.is-featured {
    border-color: var(--color-blue);
    box-shadow: 0 24px 40px -28px rgba(30, 58, 140, 0.45);
    transform: scale(1.02);
  }
  .pay-card.is-current {
    border-color: var(--color-green);
    background: linear-gradient(180deg, rgba(22, 143, 91, 0.04) 0%, #fff 60%);
    box-shadow: 0 24px 40px -28px rgba(22, 143, 91, 0.30);
  }
  /* Si la carte est à la fois featured et current (= Intégral chez un user Intégral),
     on garde le vert qui prime visuellement. */
  .pay-card.is-current.is-featured {
    border-color: var(--color-green);
  }
  @media (max-width: 720px) {
    .pay-card.is-featured { transform: none; }
  }

  .ribbon {
    position: absolute;
    top: -14px;
    left: 50%;
    transform: translateX(-50%);
    color: #fff;
    font-family: var(--font-mono);
    font-size: 0.7rem;
    font-weight: 700;
    letter-spacing: 0.08em;
    text-transform: uppercase;
    padding: 6px 14px;
    border-radius: 999px;
    white-space: nowrap;
  }
  .ribbon-featured { background: var(--color-red); }
  .ribbon-upgrade { background: var(--color-blue); }
  .ribbon-current { background: var(--color-green); }

  .pay-card-head h2 {
    font-family: var(--font-display);
    font-size: 1.75rem;
    color: var(--color-ink);
    margin: 6px 0 4px;
  }
  .muted {
    color: var(--color-muted);
    font-size: 0.9375rem;
  }
  .small { font-size: 0.875rem; }

  .pay-price {
    display: flex;
    flex-direction: column;
    gap: 4px;
    padding-bottom: 16px;
    border-bottom: 1px solid var(--color-line-2);
  }
  .price-strike {
    font-family: var(--font-mono);
    color: var(--color-muted-2);
    text-decoration: line-through;
    font-size: 0.95rem;
  }
  .price-now {
    font-family: var(--font-display);
    font-size: 3rem;
    font-weight: 700;
    color: var(--color-ink);
    line-height: 1;
  }
  .cents { font-size: 1.5rem; font-weight: 600; }
  .price-period {
    font-family: var(--font-mono);
    font-size: 0.75rem;
    letter-spacing: 0.06em;
    text-transform: uppercase;
    color: var(--color-muted);
    margin-top: 4px;
  }

  .pay-features {
    list-style: none;
    padding: 0;
    margin: 0;
    display: flex;
    flex-direction: column;
    gap: 12px;
    flex: 1;
  }
  .pay-features li {
    display: flex;
    gap: 10px;
    align-items: flex-start;
    color: var(--color-ink-2);
    font-size: 0.9375rem;
    line-height: 1.5;
  }
  .check {
    color: var(--color-green);
    font-weight: 700;
    flex-shrink: 0;
  }

  .pay-error {
    max-width: 920px;
    margin: 24px auto 0;
    padding: 16px 20px;
    background: var(--color-red-light);
    color: var(--color-red-dark);
    border: 1px solid var(--color-red);
    border-radius: 12px;
    font-size: 0.9375rem;
  }

  .pay-trust {
    max-width: 720px;
    margin: 48px auto 0;
    text-align: center;
    padding: 0 20px;
  }
  .pay-trust p { margin: 0 0 8px; }
`;
