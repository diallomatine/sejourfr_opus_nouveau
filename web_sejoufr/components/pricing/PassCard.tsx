"use client";

import Link from "next/link";
import { ArrowRight, Check } from "lucide-react";
import { track } from "@/lib/analytics";
import {
  formatPassPrice,
  passCheckoutHref,
  passDurationLabel,
  passFromPrice,
  passSessionsLabel,
  popularPassCodeOf,
  POPULAR_PASS_CODE,
  type PassModule,
} from "@/lib/passes";
import type { TrafficSource } from "@/lib/traffic-source";
import type { PlanPublicResponse } from "@/lib/types";
import styles from "./PassCard.module.css";

/**
 * La carte de prix de la vitrine — **une seule** pour l'accueil `/` et pour
 * `/reussir` (elles en avaient chacune une copie, quasi identiques).
 *
 * `PriceCard` est la carte nue (le « Gratuit » de l'accueil s'en sert tel
 * quel) ; `PassCard` la remplit avec les passes d'un module : lignes de durée
 * cliquables, pass mis en avant, destinations d'achat et mesure. Tout ce qui
 * est une règle vient de `lib/passes.ts`, jamais d'ici.
 */

export type PriceCardTone = "blue" | "red" | "light";

export interface PriceRow {
  key: string;
  label: string;
  value: string;
  note?: string | null;
  /** Mis en avant : c'est la ligne que vise le CTA de la carte. */
  highlighted?: boolean;
  badge?: string | null;
  href?: string;
  onClick?: () => void;
}

export interface PriceCardProps {
  kicker: string;
  /** Kicker rouge (la carte mise en avant de `/reussir`). */
  kickerAccent?: boolean;
  title: string;
  description: string;
  /** Prix d'entrée en grand. Absent ⇒ aucune ligne de prix (jamais de repli). */
  price?: { amount: string; sub: string } | null;
  rows: PriceRow[];
  features: readonly string[];
  cta: { label: string; href: string; tone: PriceCardTone; onClick?: () => void };
  featured?: boolean;
  ribbon?: string | null;
  footnote?: string | null;
}

const CTA_TONE: Record<PriceCardTone, string> = {
  blue: styles.ctaBlue,
  red: styles.ctaRed,
  light: styles.ctaLight,
};

export function PriceCard({
  kicker,
  kickerAccent = false,
  title,
  description,
  price,
  rows,
  features,
  cta,
  featured = false,
  ribbon,
  footnote,
}: PriceCardProps) {
  return (
    <article
      className={`${styles.card} ${featured ? styles.featured : ""} ${ribbon ? styles.withRibbon : ""}`}
    >
      {ribbon ? <span className={styles.ribbon}>{ribbon}</span> : null}
      <span className={`${styles.kicker} ${kickerAccent ? styles.kickerAccent : ""}`}>
        {kicker}
      </span>
      <h3 className={styles.title}>{title}</h3>
      <p className={styles.desc}>{description}</p>

      {price ? (
        <>
          <div className={styles.priceMain}>
            <strong>{price.amount}</strong>
          </div>
          <div className={styles.priceSub}>{price.sub}</div>
        </>
      ) : null}

      <div className={styles.rows}>
        {rows.map((row) => {
          const className = `${styles.row} ${row.highlighted ? styles.rowHighlighted : ""} ${
            row.href ? styles.rowLink : ""
          }`;
          const body = (
            <>
              <span className={styles.rowLabel}>
                <span className={styles.rowName}>
                  {row.label}
                  {row.badge ? <em className={styles.rowBadge}>{row.badge}</em> : null}
                </span>
                {row.note ? <span className={styles.rowNote}>{row.note}</span> : null}
              </span>
              <strong className={styles.rowValue}>{row.value}</strong>
            </>
          );
          return row.href ? (
            <Link key={row.key} href={row.href} className={className} onClick={row.onClick}>
              {body}
            </Link>
          ) : (
            <div key={row.key} className={className}>
              {body}
            </div>
          );
        })}
      </div>

      <div className={styles.divider} aria-hidden />
      <ul className={styles.features}>
        {features.map((f) => (
          <li key={f}>
            <Check size={15} strokeWidth={2.6} aria-hidden />
            {f}
          </li>
        ))}
      </ul>

      <Link href={cta.href} className={`${styles.cta} ${CTA_TONE[cta.tone]}`} onClick={cta.onClick}>
        {cta.label}
        <ArrowRight size={16} aria-hidden />
      </Link>
      {footnote ? <p className={styles.footnote}>{footnote}</p> : null}
    </article>
  );
}

/**
 * Un pass choisi dit **deux** choses : « cet écran a déclenché une intention
 * d'achat » et « c'est ce pass-là qui a été choisi ». Les deux événements du
 * registre existent pour ça. `screen` nomme la surface (slug).
 */
export function trackPassChosen(planCode: string, screen: string): void {
  track("PREMIUM_CTA_CLICKED", { ctaLocation: "PRICING", planCode, screen });
  track("PRICING_CTA_CLICKED", { planCode });
}

export interface PassCardProps
  extends Omit<PriceCardProps, "price" | "rows" | "cta"> {
  module: PassModule;
  /** Passes du module, **triés par durée** (`oneTimePassesOf`), prix > 0. */
  passes: PlanPublicResponse[];
  /** `null` = auth en chargement : `passCheckoutHref` vise alors le récapitulatif. */
  authenticated: boolean | null;
  source: TrafficSource | null;
  /** Slug de mesure (`PREMIUM_CTA_CLICKED.screen`). */
  screen: string;
  ctaLabel: string;
  ctaTone: PriceCardTone;
  /** Grand prix « à partir de » (`passFromPrice`). */
  showFromPrice?: boolean;
  /** Badge « Populaire » sur `POPULAR_PASS_CODE`. */
  markPopular?: boolean;
  /** Sous-texte d'une ligne. Par défaut : les simulations orales servies. */
  rowNote?: (plan: PlanPublicResponse, index: number) => string | null;
}

export function PassCard({
  module,
  passes,
  authenticated,
  source,
  screen,
  ctaLabel,
  ctaTone,
  showFromPrice = false,
  markPopular = false,
  rowNote = passSessionsLabel,
  ...card
}: PassCardProps) {
  const highlightedCode = popularPassCodeOf(passes);
  const ctaPlan = passes.find((p) => p.code === highlightedCode) ?? passes[0];
  if (!ctaPlan) return null;
  const fromPrice = showFromPrice ? passFromPrice(passes, module) : null;

  return (
    <PriceCard
      {...card}
      price={
        fromPrice === null
          ? null
          : { amount: `${formatPassPrice(fromPrice)} €`, sub: "à partir de · paiement unique" }
      }
      rows={passes.map((plan, i) => ({
        key: plan.code,
        label: passDurationLabel(plan.durationDays),
        value: `${formatPassPrice(plan.price)} €`,
        note: rowNote(plan, i),
        highlighted: plan.code === highlightedCode,
        badge: markPopular && plan.code === POPULAR_PASS_CODE ? "Populaire" : null,
        href: passCheckoutHref(plan.code, authenticated, source),
        onClick: () => trackPassChosen(plan.code, screen),
      }))}
      cta={{
        label: ctaLabel,
        href: passCheckoutHref(ctaPlan.code, authenticated, source),
        tone: ctaTone,
        onClick: () => trackPassChosen(ctaPlan.code, screen),
      }}
    />
  );
}
