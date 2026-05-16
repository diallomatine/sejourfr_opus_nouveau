"use client";

import Link from "next/link";
import { Suspense, useState } from "react";
import { ApiException, billingApi } from "@/lib/api";

type PlanCode = "CIVIQUE_3MOIS" | "INTEGRAL_3MOIS";

interface PlanCard {
  code: PlanCode;
  name: string;
  tag: string;
  originalPrice: number; // prix « normal », affiché barré
  price: number; // prix de lancement
  duration: string;
  features: string[];
  cta: string;
  highlighted?: boolean;
}

const PLANS: PlanCard[] = [
  {
    code: "CIVIQUE_3MOIS",
    name: "Civique",
    tag: "Pour CSP · CR · NAT",
    originalPrice: 9.99,
    price: 5.99,
    duration: "3 mois",
    features: [
      "Accès illimité à toutes les questions civique (CSP, CR, NAT)",
      "Examens blancs civique à volonté",
      "Suivi de progression par thème",
      "Mode entraînement et révision des erreurs",
    ],
    cta: "Souscrire à Civique",
  },
  {
    code: "INTEGRAL_3MOIS",
    name: "Intégral",
    tag: "Civique + TCF",
    originalPrice: 19.99,
    price: 14.99,
    duration: "3 mois",
    features: [
      "Tout ce que contient Civique",
      "Accès complet au TCF (A2, B1, B2)",
      "Examens blancs TCF",
      "Compréhension écrite, orale et structure de la langue",
    ],
    cta: "Souscrire à Intégral",
    highlighted: true,
  },
];

export default function PaiementPage() {
  return (
    <Suspense fallback={null}>
      <PaiementInner />
    </Suspense>
  );
}

function PaiementInner() {
  const [loadingPlan, setLoadingPlan] = useState<PlanCode | null>(null);
  const [error, setError] = useState<string | null>(null);

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

  return (
    <div className="pay-page">
      <div className="container-x">
        <header className="pay-header">
          <span className="eyebrow">Offre de lancement</span>
          <h1 className="editorial">
            Choisissez votre <em>formule</em>.
          </h1>
          <p className="lead">
            Un paiement unique, accès 3 mois.<br />
            <strong>Pas de renouvellement automatique</strong> — vous renouvellerez vous-même si vous le souhaitez.
          </p>
        </header>

        <div className="pay-cards">
          {PLANS.map((plan) => (
            <article
              key={plan.code}
              className={`pay-card ${plan.highlighted ? "is-featured" : ""}`}
            >
              {plan.highlighted && (
                <span className="ribbon">Le plus complet</span>
              )}
              <header className="pay-card-head">
                <span className="eyebrow">{plan.tag}</span>
                <h2>{plan.name}</h2>
                <p className="muted">{plan.duration} d'accès</p>
              </header>

              <div className="pay-price">
                <span className="price-strike" aria-label="Prix normal barré">
                  {plan.originalPrice.toFixed(2).replace(".", ",")} €
                </span>
                <span className="price-now">
                  {plan.price.toFixed(2).replace(".", ",")}
                  <span className="cents"> €</span>
                </span>
                <span className="price-period">paiement unique</span>
              </div>

              <ul className="pay-features">
                {plan.features.map((f) => (
                  <li key={f}>
                    <span className="check" aria-hidden>✓</span>
                    {f}
                  </li>
                ))}
              </ul>

              <button
                type="button"
                className={`btn btn-lg ${plan.highlighted ? "btn-red" : ""}`}
                onClick={() => handleSubscribe(plan.code)}
                disabled={loadingPlan !== null}
              >
                {loadingPlan === plan.code ? "Redirection…" : plan.cta}
              </button>
            </article>
          ))}
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
            Vous gardez le contrôle total : à l'expiration, vous pouvez racheter
            quand vous voulez.
          </p>
          <p className="muted small">
            Une question ?{" "}
            <Link href="/contact" className="btn-link-soft">Contactez-nous</Link>.
          </p>
        </div>
      </div>

      <style jsx>{`
        .pay-page {
          padding: 48px 0 80px;
          background: var(--color-paper);
          min-height: calc(100vh - 64px);
        }
        .pay-header {
          text-align: center;
          max-width: 720px;
          margin: 0 auto 48px;
        }
        .pay-header h1 {
          font-size: clamp(2rem, 4vw, 3rem);
          margin: 12px 0 16px;
          color: var(--color-ink);
        }
        .lead {
          font-size: 1.0625rem;
          color: var(--color-muted);
          line-height: 1.6;
        }
        .lead strong {
          color: var(--color-ink);
        }

        .pay-cards {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 24px;
          max-width: 920px;
          margin: 0 auto;
        }
        @media (max-width: 720px) {
          .pay-cards {
            grid-template-columns: 1fr;
          }
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
        @media (max-width: 720px) {
          .pay-card.is-featured {
            transform: none;
          }
        }
        .ribbon {
          position: absolute;
          top: -14px;
          left: 50%;
          transform: translateX(-50%);
          background: var(--color-red);
          color: #fff;
          font-family: var(--font-mono);
          font-size: 0.7rem;
          font-weight: 700;
          letter-spacing: 0.08em;
          text-transform: uppercase;
          padding: 6px 14px;
          border-radius: 999px;
        }
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
        .small {
          font-size: 0.875rem;
        }

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
        .cents {
          font-size: 1.5rem;
          font-weight: 600;
        }
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
        }
        .pay-trust p {
          margin: 0 0 8px;
        }
      `}</style>
    </div>
  );
}
