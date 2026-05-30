"use client";

import Link from "next/link";
import { useMemo, useState } from "react";
import { Check, Sparkles } from "lucide-react";
import { periodicityFromCycle, type PlanModuleTarget, type PlanPeriodicity } from "@/lib/api";
import type { PlanPublicResponse } from "@/lib/types";

interface Props {
  plans: PlanPublicResponse[];
  /** Variante d'affichage : pleine page ou compacte pour la landing. */
  variant?: "full" | "compact";
  /** Pré-sélection de la périodicité (par défaut : trimestriel). */
  defaultPeriodicity?: PlanPeriodicity;
}

interface Preset {
  description: string;
  features: { label: string; strong?: boolean }[];
  badge?: { label: string; tone: "blue" | "red" } | null;
  featured?: boolean;
  cta: { label: string; variant: "primary" | "red" | "ghost" };
}

const PRESENTATIONS: { CIVIQUE: Preset; INTEGRAL: Preset; FREE: Preset } = {
  FREE: {
    description: "Pour découvrir la plateforme et passer un premier examen blanc.",
    features: [
      { label: "1 Lot d'entraînement gratuit par sous-module" },
      { label: "1 examen blanc gratuit par sous-module" },
      { label: "T1 d'EE/EO 1 fois pour découvrir l'évaluation IA" },
      { label: "Accès sans limite de durée" },
    ],
    cta: { label: "Commencer gratuitement", variant: "ghost" },
  },
  CIVIQUE: {
    description: "Pour réussir l'examen civique : CSP, CR ou naturalisation.",
    features: [
      { label: "Banque complète civique (CSP/CR/NAT)", strong: true },
      { label: "Examens blancs civiques illimités" },
      { label: "Statistiques par thématique + révision ciblée" },
      { label: "Explications pédagogiques après chaque question" },
    ],
    badge: { label: "Le plus populaire", tone: "blue" },
    featured: true,
    cta: { label: "Choisir Civique", variant: "primary" },
  },
  INTEGRAL: {
    description: "Civique + TCF IRN avec EE/EO évalués par IA. Le plus complet.",
    features: [
      { label: "Tout le Civique inclus", strong: true },
      { label: "Module TCF complet (CO + CE + Structure)", strong: true },
      { label: "Expression écrite + orale évaluée par IA" },
      { label: "Diagnostic CECRL (A2 / B1 / B2)" },
    ],
    badge: { label: "Intégral", tone: "red" },
    cta: { label: "Passer Intégral", variant: "red" },
  },
};

const PERIODICITIES: { value: PlanPeriodicity; label: string; sub: string }[] = [
  { value: "monthly", label: "Mensuel", sub: "facturé chaque mois" },
  { value: "quarterly", label: "Trimestriel", sub: "facturé tous les 3 mois" },
  { value: "yearly", label: "Annuel", sub: "facturé chaque année" },
];

const PERIOD_SUFFIX: Record<PlanPeriodicity, string> = {
  monthly: "/ mois",
  quarterly: "/ 3 mois",
  yearly: "/ an",
};

function formatPrice(value: number): string {
  if (value === 0) return "0";
  if (Number.isInteger(value)) return String(value);
  return value
    .toFixed(2)
    .replace(".", ",")
    .replace(/,?0+$/, (m) => (m.startsWith(",") ? "" : m));
}

function monthlyEquivalent(price: number, periodicity: PlanPeriodicity): number | null {
  if (price <= 0) return null;
  if (periodicity === "quarterly") return price / 3;
  if (periodicity === "yearly") return price / 12;
  return null;
}

/** Libellé de durée d'un pass one-time (« 6 semaines », « 3 mois », « 1 an »). */
function passDurationLabel(days: number): string {
  if (days <= 0) return "";
  if (days % 365 === 0) {
    const y = days / 365;
    return y === 1 ? "1 an" : `${y} ans`;
  }
  if (days >= 30 && days % 30 === 0) return `${days / 30} mois`;
  if (days % 7 === 0) return `${days / 7} semaines`;
  return `${days} jours`;
}

/** Indexe les Plans payants par (module, periodicity). */
function indexPaidPlans(
  plans: PlanPublicResponse[],
): Map<string, PlanPublicResponse> {
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

export function PricingPlans({ plans, variant = "full", defaultPeriodicity = "quarterly" }: Props) {
  const [periodicity, setPeriodicity] = useState<PlanPeriodicity>(defaultPeriodicity);
  const index = useMemo(() => indexPaidPlans(plans), [plans]);
  const freePlan = plans.find((p) => p.code === "FREE") ?? null;

  // Mode passes one-time (lot 5) : on ignore les plans non payables (FREE) dans
  // la détection, puis on rend une carte par module listant ses passes.
  const payablePlans = plans.filter((p) => p.moduleAccess !== "NONE" && p.price > 0);
  const oneTime =
    payablePlans.length > 0 && payablePlans.every((p) => p.purchaseType === "ONE_TIME");

  if (oneTime) {
    const passesFor = (mod: "CIVIQUE" | "INTEGRAL") =>
      payablePlans
        .filter((p) => p.moduleAccess === mod)
        .sort((a, b) => a.durationDays - b.durationDays);
    return (
      <div className={`pp pp-${variant}`}>
        <div className="pp-cards">
          {freePlan && (
            <PricingCard
              preset={PRESENTATIONS.FREE}
              name={freePlan.name}
              price={null}
              originalPrice={null}
              periodicity={periodicity}
              durationNote="Sans limite de durée"
              href="/inscription"
            />
          )}
          <PassModuleCard preset={PRESENTATIONS.CIVIQUE} name="Civique" module="CIVIQUE" passes={passesFor("CIVIQUE")} />
          <PassModuleCard preset={PRESENTATIONS.INTEGRAL} name="Intégral" module="INTEGRAL" passes={passesFor("INTEGRAL")} />
        </div>
        <style>{styles}</style>
      </div>
    );
  }

  const civique = index.get(`CIVIQUE:${periodicity}`);
  const integral = index.get(`INTEGRAL:${periodicity}`);

  return (
    <div className={`pp pp-${variant}`}>
      <div className="pp-toggle" role="tablist" aria-label="Périodicité de l'abonnement">
        {PERIODICITIES.map((p) => {
          const active = p.value === periodicity;
          return (
            <button
              key={p.value}
              type="button"
              role="tab"
              aria-selected={active}
              className={`pp-period ${active ? "is-active" : ""}`}
              onClick={() => setPeriodicity(p.value)}
            >
              <span className="pp-period-label">{p.label}</span>
              <span className="pp-period-sub">{p.sub}</span>
            </button>
          );
        })}
      </div>

      <div className="pp-cards">
        {freePlan && (
          <PricingCard
            preset={PRESENTATIONS.FREE}
            name={freePlan.name}
            price={null}
            originalPrice={null}
            periodicity={periodicity}
            durationNote="Sans limite de durée"
            href="/inscription"
          />
        )}
        {civique && (
          <PricingCard
            preset={PRESENTATIONS.CIVIQUE}
            name={civique.name}
            price={civique.price}
            originalPrice={civique.originalPrice}
            periodicity={periodicity}
            href={`/paiement?module=CIVIQUE&period=${periodicity}`}
          />
        )}
        {integral && (
          <PricingCard
            preset={PRESENTATIONS.INTEGRAL}
            name={integral.name}
            price={integral.price}
            originalPrice={integral.originalPrice}
            periodicity={periodicity}
            href={`/paiement?module=INTEGRAL&period=${periodicity}`}
          />
        )}
      </div>

      <style>{styles}</style>
    </div>
  );
}

function PricingCard({
  preset,
  name,
  price,
  originalPrice,
  periodicity,
  href,
  durationNote,
}: {
  preset: Preset;
  name: string;
  price: number | null;
  originalPrice: number | null;
  periodicity: PlanPeriodicity;
  href: string;
  durationNote?: string;
}) {
  const isFree = price === null || price === 0;
  const monthly = !isFree && price !== null ? monthlyEquivalent(price, periodicity) : null;
  const ctaClass =
    preset.cta.variant === "ghost"
      ? "btn btn-ghost pp-cta"
      : preset.cta.variant === "red"
        ? "btn btn-red pp-cta"
        : "btn pp-cta";

  return (
    <article className={`pp-card ${preset.featured ? "is-featured" : ""}`}>
      {preset.badge && (
        <span className={`pp-badge ${preset.badge.tone === "red" ? "is-red" : ""}`}>
          <Sparkles className="pp-badge-icon" />
          {preset.badge.label}
        </span>
      )}

      <header className="pp-head">
        <h3 className="pp-name">{name}</h3>
        <p className="pp-desc">{preset.description}</p>
      </header>

      <div className="pp-price">
        <div className="pp-price-row">
          {!isFree && originalPrice !== null && price !== null && originalPrice > price && (
            <span className="pp-price-old">{formatPrice(originalPrice)} €</span>
          )}
          <span className="pp-price-num">
            {isFree ? "0 €" : `${formatPrice(price ?? 0)} €`}
          </span>
          {!isFree && <span className="pp-price-per">{PERIOD_SUFFIX[periodicity]}</span>}
        </div>
        {monthly !== null && (
          <p className="pp-price-month">
            soit ≈ {formatPrice(Number(monthly.toFixed(2)))} € / mois
          </p>
        )}
        {durationNote && isFree && <p className="pp-price-month">{durationNote}</p>}
      </div>

      <ul className="pp-feats">
        {preset.features.map((f) => (
          <li key={f.label}>
            <Check className="pp-tick" />
            <span>{f.strong ? <strong>{f.label}</strong> : f.label}</span>
          </li>
        ))}
      </ul>

      <div className="pp-foot">
        <Link href={href} className={ctaClass}>
          {preset.cta.label}
        </Link>
      </div>
    </article>
  );
}

/** Carte marketing d'un module en mode passes : preset + liste des passes
 *  (durée + prix) + CTA vers /paiement pour choisir et payer. */
function PassModuleCard({
  preset,
  name,
  module,
  passes,
}: {
  preset: Preset;
  name: string;
  module: "CIVIQUE" | "INTEGRAL";
  passes: PlanPublicResponse[];
}) {
  if (passes.length === 0) return null;
  const ctaClass =
    preset.cta.variant === "red"
      ? "btn btn-red pp-cta"
      : preset.cta.variant === "ghost"
        ? "btn btn-ghost pp-cta"
        : "btn pp-cta";
  return (
    <article className={`pp-card ${preset.featured ? "is-featured" : ""}`}>
      {preset.badge && (
        <span className={`pp-badge ${preset.badge.tone === "red" ? "is-red" : ""}`}>
          <Sparkles className="pp-badge-icon" />
          {preset.badge.label}
        </span>
      )}
      <header className="pp-head">
        <h3 className="pp-name">{name}</h3>
        <p className="pp-desc">{preset.description}</p>
      </header>
      <div className="pp-passes">
        {passes.map((p) => (
          <div key={p.code} className="pp-pass">
            <span className="pp-pass-dur">{passDurationLabel(p.durationDays)}</span>
            <span className="pp-pass-price">{formatPrice(p.price)} €</span>
          </div>
        ))}
      </div>
      <ul className="pp-feats">
        {preset.features.map((f) => (
          <li key={f.label}>
            <Check className="pp-tick" />
            <span>{f.strong ? <strong>{f.label}</strong> : f.label}</span>
          </li>
        ))}
      </ul>
      <div className="pp-foot">
        <Link href={`/paiement?module=${module}`} className={ctaClass}>
          {preset.cta.label}
        </Link>
      </div>
    </article>
  );
}

const styles = `
  .pp { max-width: 1100px; margin: 0 auto; }
  .pp-passes {
    display: flex;
    flex-direction: column;
    gap: 8px;
    margin-bottom: 22px;
  }
  .pp-pass {
    display: flex;
    align-items: baseline;
    justify-content: space-between;
    gap: 12px;
    padding: 10px 14px;
    border: 1px solid var(--color-line);
    border-radius: 12px;
    background: var(--color-paper);
  }
  .pp-pass-dur {
    font-weight: 700;
    font-size: 14px;
    color: var(--color-ink);
  }
  .pp-pass-price {
    font-family: var(--font-display);
    font-size: 20px;
    font-weight: 700;
    color: var(--color-ink);
  }
  .pp-toggle {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 8px;
    background: var(--color-paper-2);
    border-radius: 16px;
    padding: 6px;
    max-width: 460px;
    margin: 0 auto 28px;
  }
  .pp-period {
    background: transparent;
    border: none;
    border-radius: 12px;
    padding: 10px 8px;
    font-family: inherit;
    color: var(--color-muted);
    cursor: pointer;
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 2px;
    transition: background 0.15s, color 0.15s, box-shadow 0.15s;
  }
  .pp-period:hover { color: var(--color-ink); }
  .pp-period.is-active {
    background: #fff;
    color: var(--color-ink);
    box-shadow: 0 2px 8px -2px rgba(15, 24, 57, 0.12);
  }
  .pp-period-label { font-weight: 700; font-size: 13.5px; }
  .pp-period-sub {
    font-family: var(--font-mono);
    font-size: 9.5px;
    letter-spacing: 0.08em;
    color: var(--color-muted);
    text-transform: uppercase;
  }
  @media (max-width: 560px) {
    .pp-period { padding: 8px 6px; }
    .pp-period-label { font-size: 12.5px; }
    .pp-period-sub { display: none; }
  }

  .pp-cards {
    display: grid;
    grid-template-columns: 1fr;
    gap: 20px;
  }
  @media (min-width: 720px) {
    .pp-cards { grid-template-columns: repeat(2, 1fr); }
  }
  @media (min-width: 1024px) {
    .pp-cards { grid-template-columns: repeat(3, 1fr); gap: 24px; }
  }

  .pp-card {
    position: relative;
    display: flex;
    flex-direction: column;
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 22px;
    padding: 28px 26px;
    transition: border-color 0.15s ease, transform 0.15s ease, box-shadow 0.15s ease;
  }
  .pp-card:hover { border-color: var(--color-line-2); }
  .pp-card.is-featured {
    border-width: 2px;
    border-color: var(--color-blue);
    box-shadow: 0 22px 48px -28px rgba(30, 58, 140, 0.35);
  }
  @media (min-width: 1024px) {
    .pp-card { padding: 36px 32px; }
    .pp-card.is-featured { transform: translateY(-6px); }
  }

  .pp-badge {
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
  .pp-badge.is-red { background: var(--color-red); }
  .pp-badge-icon { width: 11px; height: 11px; }

  .pp-head { margin-bottom: 20px; }
  .pp-name {
    margin: 0;
    font-family: var(--font-display);
    font-weight: 600;
    font-size: 24px;
    letter-spacing: -0.015em;
    color: var(--color-ink);
  }
  .pp-desc {
    margin: 6px 0 0;
    font-size: 13.5px;
    color: var(--color-muted);
    line-height: 1.5;
  }

  .pp-price { margin-bottom: 24px; }
  .pp-price-row {
    display: flex;
    align-items: baseline;
    gap: 8px;
    flex-wrap: wrap;
  }
  .pp-price-old {
    font-family: var(--font-display);
    font-size: 20px;
    color: var(--color-muted-2);
    text-decoration: line-through;
  }
  .pp-price-num {
    font-family: var(--font-display);
    font-size: 44px;
    font-weight: 700;
    letter-spacing: -0.025em;
    line-height: 1;
    color: var(--color-ink);
  }
  .pp-price-per {
    font-family: var(--font-mono);
    font-size: 11px;
    letter-spacing: 0.08em;
    text-transform: uppercase;
    color: var(--color-muted);
  }
  .pp-price-month {
    margin: 6px 0 0;
    font-size: 12px;
    color: var(--color-muted-2);
  }

  .pp-feats {
    list-style: none;
    margin: 0 0 24px;
    padding: 0;
    flex: 1;
    display: flex;
    flex-direction: column;
    gap: 10px;
  }
  .pp-feats li {
    display: flex;
    align-items: flex-start;
    gap: 10px;
    font-size: 14px;
    line-height: 1.5;
    color: var(--color-ink-2);
  }
  .pp-tick {
    width: 16px; height: 16px;
    color: var(--color-green);
    flex-shrink: 0;
    margin-top: 2px;
  }

  .pp-foot { margin-top: auto; }
  .pp-cta {
    width: 100%;
    min-height: 48px;
  }

  /* Variante compacte (landing) */
  .pp-compact .pp-card { padding: 28px 22px; }
  .pp-compact .pp-price-num { font-size: 38px; }
`;
