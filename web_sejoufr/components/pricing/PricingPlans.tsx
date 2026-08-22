"use client";

import Link from "next/link";
import { useEffect, useMemo, useState } from "react";
import { ArrowRight, CalendarOff, Check, Sparkles } from "lucide-react";
import { periodicityFromCycle, type PlanModuleTarget, type PlanPeriodicity } from "@/lib/api";
import { track } from "@/lib/analytics";
import { withTrafficSource, type TrafficSource } from "@/lib/traffic-source";
import { useAuth } from "@/lib/auth-context";
import { useTrafficSource } from "@/lib/use-traffic-source";
import {
  formatPassPrice,
  isOneTimeCatalog,
  oneTimePassesOf,
  passCheckoutHref,
  passDurationLabel,
  passMonthlyLabel,
  passSessionsLabel,
  POPULAR_PASS_CODE,
} from "@/lib/passes";
import type { PlanPublicResponse } from "@/lib/types";

interface Props {
  plans: PlanPublicResponse[];
  /** Variante d'affichage : pleine page ou compacte pour la landing. */
  variant?: "full" | "compact";
  /** Pré-sélection de la périodicité (par défaut : trimestriel). */
  defaultPeriodicity?: PlanPeriodicity;
  /**
   * Grille réellement mesurée. Vrai **seulement** sur `/tarifs` : ce composant
   * sert aussi des sections d'offre embarquées, qui ne doivent pas gonfler le
   * compteur de la page des prix. Absent ⇒ aucune mesure.
   *
   * ⚠️ Le **chemin** ne se passe plus en prop : il voyage avec chaque
   * événement (`lib/analytics.ts`), donc deux surfaces ne peuvent plus se
   * déclarer sous le même chemin par erreur.
   */
  measured?: boolean;
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

export function PricingPlans({
  plans,
  variant = "full",
  defaultPeriodicity = "quarterly",
  measured = false,
}: Props) {
  const [periodicity, setPeriodicity] = useState<PlanPeriodicity>(defaultPeriodicity);
  const { status } = useAuth();
  // La provenance suit le visiteur jusqu'aux portes du compte et du paiement.
  const source = useTrafficSource();
  const index = useMemo(() => indexPaidPlans(plans), [plans]);
  const freePlan = plans.find((p) => p.code === "FREE") ?? null;

  // Vue de la page des prix : elle répond à la seule question qu'aucune table
  // ne peut trancher — combien de visiteurs regardent les tarifs sans jamais
  // créer de compte.
  useEffect(() => {
    if (!measured) return;
    track("PRICING_VIEWED", {}, { once: true });
  }, [measured]);

  /**
   * Un pass choisi dit **deux** choses : « cet écran a déclenché une intention
   * d'achat » (table « Quel écran déclenche l'achat ? ») et « c'est ce pass-là
   * qui a été choisi ». Les deux événements du registre existent pour ça.
   */
  const onCta = (planCode: string) => {
    if (!measured) return;
    track("PREMIUM_CTA_CLICKED", { ctaLocation: "PRICING", planCode, screen: "pricing" });
    track("PRICING_CTA_CLICKED", { planCode });
  };

  /** Le compte gratuit n'est pas un achat : c'est une porte d'inscription. */
  const onFreeCta = () => {
    if (!measured) return;
    track("SIGNUP_CTA_CLICKED", { ctaLocation: "PRICING" });
  };

  // Mode passes one-time (lot 5) : une carte par module, chaque durée étant une
  // ligne cliquable qui emmène droit au récapitulatif du pass choisi.
  if (isOneTimeCatalog(plans)) {
    // `loading` → null : on vise le récapitulatif et le middleware tranche.
    const authenticated = status === "loading" ? null : status === "authenticated";
    return (
      <div className={`pp pp-${variant}`}>
        <p className="pp-lead">
          Un pass se paie <strong>une seule fois</strong>. Choisissez la durée qui
          couvre votre échéance — aucune reconduction, et les durées se cumulent
          si vous prolongez.
        </p>
        <div className="pp-cards">
          <PassModuleCard
            preset={PRESENTATIONS.CIVIQUE}
            name="Civique"
            passes={oneTimePassesOf(plans, "CIVIQUE")}
            featured={false}
            authenticated={authenticated}
            source={source}
            onCta={onCta}
          />
          <PassModuleCard
            preset={PRESENTATIONS.INTEGRAL}
            name="Intégral"
            passes={oneTimePassesOf(plans, "INTEGRAL")}
            featured
            authenticated={authenticated}
            source={source}
            onCta={onCta}
          />
          {freePlan && (
            <PricingCard
              preset={PRESENTATIONS.FREE}
              name={freePlan.name}
              price={null}
              originalPrice={null}
              periodicity={periodicity}
              durationNote="Sans limite de durée"
              href={withTrafficSource("/inscription", source)}
              onCta={onFreeCta}
            />
          )}
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
            href={withTrafficSource("/inscription", source)}
            onCta={onFreeCta}
          />
        )}
        {civique && (
          <PricingCard
            preset={PRESENTATIONS.CIVIQUE}
            name={civique.name}
            price={civique.price}
            originalPrice={civique.originalPrice}
            periodicity={periodicity}
            href={withTrafficSource(`/paiement?module=CIVIQUE&period=${periodicity}`, source)}
            onCta={() => onCta(civique.code)}
          />
        )}
        {integral && (
          <PricingCard
            preset={PRESENTATIONS.INTEGRAL}
            name={integral.name}
            price={integral.price}
            originalPrice={integral.originalPrice}
            periodicity={periodicity}
            href={withTrafficSource(`/paiement?module=INTEGRAL&period=${periodicity}`, source)}
            onCta={() => onCta(integral.code)}
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
  onCta,
}: {
  preset: Preset;
  name: string;
  price: number | null;
  originalPrice: number | null;
  periodicity: PlanPeriodicity;
  href: string;
  durationNote?: string;
  onCta?: () => void;
}) {
  const isFree = price === null || price === 0;
  // On met en avant le prix /mois ; le total réellement débité passe en
  // sous-texte. Le barré suit la même unité que le gros prix.
  const monthly = !isFree && price !== null ? monthlyEquivalent(price, periodicity) : null;
  const mainPrice = monthly ?? (price ?? 0);
  const oldMain = monthly !== null
    ? (originalPrice !== null ? monthlyEquivalent(originalPrice, periodicity) : null)
    : originalPrice;
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
          {!isFree && oldMain !== null && oldMain > mainPrice && (
            <span className="pp-price-old">{formatPrice(Number(oldMain.toFixed(2)))} €</span>
          )}
          <span className="pp-price-num">
            {isFree ? "0 €" : `${formatPrice(Number(mainPrice.toFixed(2)))} €`}
          </span>
          {!isFree && <span className="pp-price-per">/ mois</span>}
        </div>
        {monthly !== null && (
          <p className="pp-price-month">
            soit {formatPrice(price ?? 0)} € {PERIOD_SUFFIX[periodicity]}
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
        <Link href={href} className={ctaClass} onClick={onCta}>
          {preset.cta.label}
        </Link>
      </div>
    </article>
  );
}

/**
 * Carte d'un module en mode passes : **chaque durée est un prix cliquable**
 * qui mène au récapitulatif du pass choisi. Il n'y a plus de CTA générique en
 * pied — il renvoyait vers une grille où il fallait re-choisir, alors que le
 * candidat vient précisément de choisir.
 *
 * Hiérarchie imposée par le CLAUDE.md racine : le **montant réellement débité**
 * domine, l'équivalent mensuel reste en sous-texte.
 */
function PassModuleCard({
  preset,
  name,
  passes,
  featured,
  authenticated,
  source,
  onCta,
}: {
  preset: Preset;
  name: string;
  passes: PlanPublicResponse[];
  featured: boolean;
  authenticated: boolean | null;
  source: TrafficSource | null;
  onCta?: (planCode: string) => void;
}) {
  if (passes.length === 0) return null;
  return (
    <article className={`pp-card ${featured ? "is-featured" : ""}`}>
      <header className="pp-head">
        <h3 className="pp-name">{name}</h3>
        <p className="pp-desc">{preset.description}</p>
      </header>

      <ul className="pp-passes">
        {passes.map((p) => {
          const popular = p.code === POPULAR_PASS_CODE;
          const monthly = passMonthlyLabel(p);
          // Ce qui distingue vraiment deux passes Intégral, à part la durée.
          const sessions = passSessionsLabel(p);
          return (
            <li key={p.code}>
              <Link
                href={passCheckoutHref(p.code, authenticated, source)}
                className={`pp-pass ${popular ? "is-popular" : ""}`}
                onClick={() => onCta?.(p.code)}
              >
                {popular && (
                  <span className="pp-pop">
                    <Sparkles className="pp-badge-icon" />
                    Le plus populaire
                  </span>
                )}
                <span className="pp-pass-top">
                  <span className="pp-pass-dur">{passDurationLabel(p.durationDays)}</span>
                  <span className="pp-pass-prices">
                    <span className="pp-pass-main">{formatPassPrice(p.price)} €</span>
                    {monthly !== null && <span className="pp-pass-sub">{monthly}</span>}
                  </span>
                  <ArrowRight className="pp-pass-go" aria-hidden />
                </span>
                {sessions !== null && <span className="pp-pass-sessions">{sessions}</span>}
              </Link>
            </li>
          );
        })}
      </ul>

      <p className="pp-norenew">
        <CalendarOff className="pp-norenew-icon" />
        Paiement unique — aucun renouvellement automatique.
      </p>

      <p className="pp-feats-label">Ce que ce pass ouvre</p>
      <ul className="pp-feats">
        {preset.features.map((f) => (
          <li key={f.label}>
            <Check className="pp-tick" />
            <span>{f.strong ? <strong>{f.label}</strong> : f.label}</span>
          </li>
        ))}
      </ul>
    </article>
  );
}

const styles = `
  .pp { max-width: 1100px; margin: 0 auto; }
  .pp-lead {
    max-width: 620px;
    margin: 0 auto 28px;
    text-align: center;
    font-size: 14px;
    line-height: 1.6;
    color: var(--color-muted);
  }
  .pp-lead strong { color: var(--color-ink); font-weight: 700; }

  .pp-passes {
    list-style: none;
    display: flex;
    flex-direction: column;
    gap: 10px;
    margin: 0 0 12px;
    padding: 0;
  }
  .pp-pass {
    position: relative;
    display: flex;
    flex-direction: column;
    gap: 4px;
    padding: 13px 14px;
    border: 1.5px solid var(--color-line);
    border-radius: 14px;
    background: white;
    text-decoration: none;
    transition: border-color 0.15s ease, transform 0.15s ease, box-shadow 0.15s ease;
  }
  .pp-pass:hover,
  .pp-pass:focus-visible {
    border-color: var(--color-blue);
    transform: translateY(-1px);
    box-shadow: 0 12px 24px -18px color-mix(in srgb, var(--color-ink) 45%, transparent);
  }
  .pp-pass:focus-visible { outline: 2px solid var(--color-blue); outline-offset: 2px; }
  .pp-pass.is-popular {
    border-color: var(--color-red);
    background: var(--color-red-light);
  }
  .pp-pass-go {
    width: 16px;
    height: 16px;
    flex: 0 0 auto;
    color: var(--color-blue);
  }
  .pp-pass.is-popular .pp-pass-go { color: var(--color-red); }
  .pp-feats-label {
    margin: 0 0 10px;
    font-family: var(--font-mono);
    font-size: 10px;
    letter-spacing: 0.12em;
    text-transform: uppercase;
    color: var(--color-muted-2);
  }
  .pp-pop {
    position: absolute;
    top: -10px;
    left: 12px;
    display: inline-flex;
    align-items: center;
    gap: 4px;
    padding: 2px 9px;
    border-radius: 999px;
    background: var(--color-red);
    color: #fff;
    font-family: var(--font-mono);
    font-size: 9px;
    font-weight: 700;
    letter-spacing: 0.1em;
    text-transform: uppercase;
  }
  /* Ligne 1 : durée à gauche, prix débité à droite. Ligne 2 (pleine largeur) :
     ce que le pass ouvre en simulations orales — sur 360 px, la coincer dans
     une colonne de gauche la faisait courir sur trois lignes. */
  .pp-pass-top {
    display: flex;
    align-items: center;
    gap: 12px;
  }
  .pp-pass-dur {
    flex: 1;
    min-width: 0;
    font-weight: 700;
    font-size: 15px;
    color: var(--color-ink);
  }
  .pp-pass-sessions {
    font-size: 11.5px;
    color: var(--color-muted);
    line-height: 1.3;
  }
  .pp-pass-prices {
    display: flex;
    flex-direction: column;
    align-items: flex-end;
    gap: 1px;
    min-width: 0;
  }
  /* Le montant réellement débité domine ; l'équivalent mensuel reste dessous. */
  .pp-pass-main {
    font-family: var(--font-display);
    font-size: 24px;
    font-weight: 700;
    color: var(--color-ink);
    line-height: 1.05;
    white-space: nowrap;
  }
  .pp-pass-sub {
    font-family: var(--font-mono);
    font-size: 10.5px;
    letter-spacing: 0.04em;
    color: var(--color-muted);
    white-space: nowrap;
  }
  @media (max-width: 400px) {
    .pp-pass { padding: 12px; gap: 10px; }
    .pp-pass-main { font-size: 21px; }
    .pp-pass-sessions { font-size: 11px; }
  }
  .pp-norenew {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 6px;
    margin: 0 0 20px;
    font-size: 12px;
    font-weight: 600;
    color: var(--color-green);
    line-height: 1.4;
    text-align: center;
  }
  .pp-norenew-icon { width: 14px; height: 14px; flex: 0 0 auto; }
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
