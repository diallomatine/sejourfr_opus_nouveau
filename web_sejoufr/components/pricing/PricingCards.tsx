import Link from "next/link";
import { Check, Sparkles } from "lucide-react";
import type { PlanPublicResponse } from "@/lib/types";

interface Props {
  plans: PlanPublicResponse[];
}

const PLAN_ORDER = ["FREE", "CIVIQUE_3MOIS", "INTEGRAL_3MOIS"];

interface Preset {
  badge?: { label: string; tone: "blue" | "red" } | null;
  featured?: boolean;
  description: string;
  features: { label: string; strong?: boolean }[];
  cta: { label: string; href: string; variant: "primary" | "red" | "ghost" };
}

const PRESENTATION: Record<string, Preset> = {
  FREE: {
    description: "Pour découvrir la plateforme et passer un premier examen blanc.",
    features: [
      { label: "20 questions par module (Civique + TCF)" },
      { label: "1 examen blanc gratuit par module" },
      { label: "Accès sans limite de durée" },
      { label: "Compte personnel + suivi simple" },
    ],
    cta: { label: "Commencer gratuitement", href: "/inscription", variant: "ghost" },
  },
  CIVIQUE_3MOIS: {
    badge: { label: "Le plus populaire", tone: "blue" },
    featured: true,
    description: "Pour réussir l'examen civique dans les 3 mois.",
    features: [
      { label: "Toutes les questions du module Civique (CSP/CR/NAT)", strong: true },
      { label: "Examens blancs illimités en conditions réelles" },
      { label: "Statistiques par thème + révision ciblée" },
      { label: "Explications pédagogiques après chaque question" },
      { label: "3 mois d'accès (90 jours)" },
    ],
    cta: { label: "S'abonner", href: "/paiement?plan=CIVIQUE_3MOIS", variant: "primary" },
  },
  INTEGRAL_3MOIS: {
    badge: { label: "Intégral", tone: "red" },
    description: "Pour préparer Civique + TCF IRN dans la foulée.",
    features: [
      { label: "Tout le Civique inclus", strong: true },
      { label: "Module TCF complet : CO + CE + Structure" },
      { label: "Diagnostic CECRL (A2 / B1 / B2)" },
      { label: "Examens blancs TCF illimités" },
      { label: "3 mois d'accès (90 jours)" },
    ],
    cta: { label: "Passer Intégral", href: "/paiement?plan=INTEGRAL_3MOIS", variant: "red" },
  },
};

function formatPrice(value: number): string {
  if (value === 0) return "0";
  if (Number.isInteger(value)) return String(value);
  return value
    .toFixed(2)
    .replace(".", ",")
    .replace(/,?0+$/, (m) => (m.startsWith(",") ? "" : m));
}

function durationLabel(plan: PlanPublicResponse): string {
  if (plan.code === "FREE") return "pour toujours";
  if (plan.durationDays >= 30) {
    const months = Math.round(plan.durationDays / 30);
    return `pour ${months} mois`;
  }
  return `pour ${plan.durationDays} jours`;
}

function monthlyEquivalent(plan: PlanPublicResponse): string | null {
  if (plan.price <= 0 || plan.durationDays < 30) return null;
  const months = plan.durationDays / 30;
  const perMonth = plan.price / months;
  return formatPrice(Number(perMonth.toFixed(2))) + " €";
}

export function PricingCards({ plans }: Props) {
  const sorted = [...plans]
    .sort((a, b) => {
      const ai = PLAN_ORDER.indexOf(a.code);
      const bi = PLAN_ORDER.indexOf(b.code);
      return (ai === -1 ? 99 : ai) - (bi === -1 ? 99 : bi);
    })
    .slice(0, 3);

  return (
    <div className="pcards">
      {sorted.map((plan) => {
        const preset = PRESENTATION[plan.code];
        if (!preset) return null;
        const isFree = plan.code === "FREE";
        const monthly = monthlyEquivalent(plan);
        const btnClass =
          preset.cta.variant === "ghost"
            ? "btn btn-ghost pcard-cta"
            : preset.cta.variant === "red"
              ? "btn btn-red pcard-cta"
              : "btn pcard-cta";
        return (
          <article
            key={plan.code}
            className={`pcard ${preset.featured ? "is-featured" : ""}`}
          >
            {preset.badge && (
              <span
                className={`pcard-badge ${preset.badge.tone === "red" ? "is-red" : ""}`}
              >
                <Sparkles className="pcard-badge-icon" />
                {preset.badge.label}
              </span>
            )}

            <header className="pcard-head">
              <h3 className="pcard-name">{plan.name}</h3>
              <p className="pcard-desc">{preset.description}</p>
            </header>

            <div className="pcard-price">
              <div className="pcard-price-row">
                {plan.originalPrice !== null &&
                  plan.originalPrice > plan.price && (
                    <span className="pcard-price-old">
                      {formatPrice(plan.originalPrice)} €
                    </span>
                  )}
                <span className="pcard-price-num">
                  {isFree ? "0 €" : `${formatPrice(plan.price)} €`}
                </span>
                {!isFree && (
                  <span className="pcard-price-per">
                    · {durationLabel(plan)}
                  </span>
                )}
              </div>
              {monthly && (
                <p className="pcard-price-month">soit ≈ {monthly} / mois</p>
              )}
              {isFree && (
                <p className="pcard-price-month">Sans limite de durée</p>
              )}
            </div>

            <ul className="pcard-feats">
              {preset.features.map((f) => (
                <li key={f.label}>
                  <Check className="pcard-tick" />
                  <span>{f.strong ? <strong>{f.label}</strong> : f.label}</span>
                </li>
              ))}
            </ul>

            <div className="pcard-foot">
              <Link href={preset.cta.href} className={btnClass}>
                {preset.cta.label}
              </Link>
            </div>
          </article>
        );
      })}

      <style>{`
        .pcards {
          display: grid;
          grid-template-columns: 1fr;
          gap: 20px;
          max-width: 1080px;
          margin: 0 auto;
        }
        .pcard {
          position: relative;
          display: flex;
          flex-direction: column;
          background: #fff;
          border: 1px solid var(--color-line);
          border-radius: 22px;
          padding: 28px 26px;
          transition: border-color 0.15s ease, transform 0.15s ease, box-shadow 0.15s ease;
        }
        .pcard:hover {
          border-color: var(--color-line-2);
        }
        .pcard.is-featured {
          border-width: 2px;
          border-color: var(--color-blue);
          box-shadow: 0 22px 48px -28px rgba(30, 58, 140, 0.35);
        }
        .pcard-badge {
          position: absolute;
          top: -14px;
          left: 50%;
          transform: translateX(-50%);
          display: inline-flex;
          align-items: center;
          gap: 5px;
          padding: 5px 12px;
          border-radius: 999px;
          background: var(--color-blue);
          color: #fff;
          font-family: var(--font-mono);
          font-size: 10.5px;
          font-weight: 600;
          letter-spacing: 0.14em;
          text-transform: uppercase;
          white-space: nowrap;
        }
        .pcard-badge.is-red { background: var(--color-red); }
        .pcard-badge-icon { width: 11px; height: 11px; }
        .pcard-head { margin-bottom: 20px; }
        .pcard-name {
          margin: 0;
          font-family: var(--font-display);
          font-weight: 600;
          font-size: 24px;
          letter-spacing: -0.015em;
          color: var(--color-ink);
        }
        .pcard-desc {
          margin: 6px 0 0;
          font-size: 13.5px;
          color: var(--color-muted);
          line-height: 1.5;
        }
        .pcard-price { margin-bottom: 24px; }
        .pcard-price-row {
          display: flex;
          align-items: baseline;
          gap: 8px;
          flex-wrap: wrap;
        }
        .pcard-price-old {
          font-family: var(--font-display);
          font-size: 20px;
          color: var(--color-muted-2);
          text-decoration: line-through;
        }
        .pcard-price-num {
          font-family: var(--font-display);
          font-size: 44px;
          font-weight: 700;
          letter-spacing: -0.025em;
          line-height: 1;
          color: var(--color-ink);
        }
        .pcard-price-per {
          font-size: 13.5px;
          color: var(--color-muted);
        }
        .pcard-price-month {
          margin: 6px 0 0;
          font-size: 12px;
          color: var(--color-muted-2);
        }
        .pcard-feats {
          list-style: none;
          margin: 0 0 24px;
          padding: 0;
          flex: 1;
          display: flex;
          flex-direction: column;
          gap: 10px;
        }
        .pcard-feats li {
          display: flex;
          align-items: flex-start;
          gap: 10px;
          font-size: 14px;
          line-height: 1.5;
          color: var(--color-ink-2);
        }
        .pcard-tick {
          width: 16px; height: 16px;
          color: var(--color-green);
          flex-shrink: 0;
          margin-top: 2px;
        }
        .pcard-foot { margin-top: auto; }
        .pcard-cta {
          width: 100%;
          min-height: 48px;
        }
        @media (min-width: 720px) {
          .pcards { grid-template-columns: repeat(2, 1fr); }
        }
        @media (min-width: 1024px) {
          .pcards { grid-template-columns: repeat(3, 1fr); gap: 24px; }
          .pcard { padding: 36px 32px; }
          .pcard.is-featured { transform: translateY(-6px); }
        }
      `}</style>
    </div>
  );
}
