"use client";

import Link from "next/link";
import { useId, type ReactNode, type Ref } from "react";
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
  /** Sous le prix, en petit (« soit 14,99 €/mois »). */
  valueSub?: string | null;
  /** Sous la ligne, pleine largeur (les simulations orales servies). */
  note?: string | null;
  /** Mis en avant : c'est la ligne que vise le CTA de la carte. */
  highlighted?: boolean;
  badge?: string | null;
  href?: string;
  onClick?: () => void;
  /**
   * Ligne **sélectionnable** (`/paiement`) : rendue en bouton radio, le CTA de
   * la carte agit sur la ligne choisie. Exclusif de `href`.
   */
  onSelect?: () => void;
  selected?: boolean;
  disabled?: boolean;
  /** Pour faire défiler l'écran jusqu'à la ligne visée (`?plan=`). */
  rowRef?: Ref<HTMLButtonElement>;
}

export interface PriceCardCta {
  label: string;
  tone: PriceCardTone;
  /** Lien de navigation ; absent ⇒ un bouton qui appelle `onClick`. */
  href?: string;
  onClick?: () => void;
  disabled?: boolean;
  /** Action en cours (redirection vers le paiement) : `aria-busy`. */
  busy?: boolean;
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
  /** Intitulé au-dessus des lignes (et nom accessible du groupe radio). */
  rowsLabel?: string | null;
  features: readonly string[];
  /** Bloc libre sous les puces (périmètre non inclus, pass déjà actif…). */
  extra?: ReactNode;
  /**
   * `rowsFirst` (vitrine) : prix → lignes → puces → CTA.
   * `featuresFirst` (`/paiement`) : puces → lignes → CTA, le bouton au contact
   * de la durée choisie.
   */
  layout?: "rowsFirst" | "featuresFirst";
  cta: PriceCardCta | null;
  featured?: boolean;
  ribbon?: string | null;
  ribbonTone?: "blue" | "green";
  footnote?: string | null;
  id?: string;
}

const CTA_TONE: Record<PriceCardTone, string> = {
  blue: styles.ctaBlue,
  red: styles.ctaRed,
  light: styles.ctaLight,
};

function RowBody({ row }: { row: PriceRow }) {
  return (
    <>
      <span className={styles.rowName}>
        {row.onSelect ? <span className={styles.radio} aria-hidden /> : null}
        {row.label}
        {row.badge ? <em className={styles.rowBadge}>{row.badge}</em> : null}
      </span>
      <span className={styles.rowPrice}>
        <strong className={styles.rowValue}>{row.value}</strong>
        {row.valueSub ? <span className={styles.rowValueSub}>{row.valueSub}</span> : null}
      </span>
      {row.note ? <span className={styles.rowNote}>{row.note}</span> : null}
    </>
  );
}

export function PriceCard({
  kicker,
  kickerAccent = false,
  title,
  description,
  price,
  rows,
  rowsLabel,
  features,
  extra,
  layout = "rowsFirst",
  cta,
  featured = false,
  ribbon,
  ribbonTone = "blue",
  footnote,
  id,
}: PriceCardProps) {
  const labelId = useId();
  const selectable = rows.some((row) => row.onSelect);

  const rowsBlock = rows.length === 0 ? null : (
    <div className={styles.rowsWrap}>
      {rowsLabel ? (
        <p id={labelId} className={styles.rowsLabel}>
          {rowsLabel}
        </p>
      ) : null}
      <div
        className={styles.rows}
        role={selectable ? "radiogroup" : undefined}
        aria-labelledby={selectable && rowsLabel ? labelId : undefined}
      >
        {rows.map((row) => {
          const className = [
            styles.row,
            row.highlighted ? styles.rowHighlighted : "",
            row.href || row.onSelect ? styles.rowLink : "",
            row.selected ? styles.rowSelected : "",
          ].join(" ");
          if (row.onSelect) {
            return (
              <button
                key={row.key}
                ref={row.rowRef}
                type="button"
                role="radio"
                aria-checked={row.selected ?? false}
                disabled={row.disabled}
                className={className}
                onClick={row.onSelect}
              >
                <RowBody row={row} />
              </button>
            );
          }
          return row.href ? (
            <Link key={row.key} href={row.href} className={className} onClick={row.onClick}>
              <RowBody row={row} />
            </Link>
          ) : (
            <div key={row.key} className={className}>
              <RowBody row={row} />
            </div>
          );
        })}
      </div>
    </div>
  );

  const featuresBlock = (
    <>
      <ul className={styles.features}>
        {features.map((f) => (
          <li key={f}>
            <Check size={15} strokeWidth={2.6} aria-hidden />
            {f}
          </li>
        ))}
      </ul>
      {extra}
    </>
  );

  const ctaNode = cta ? (
    cta.href ? (
      <Link href={cta.href} className={`${styles.cta} ${CTA_TONE[cta.tone]}`} onClick={cta.onClick}>
        {cta.label}
        <ArrowRight size={16} aria-hidden />
      </Link>
    ) : (
      <button
        type="button"
        className={`${styles.cta} ${CTA_TONE[cta.tone]}`}
        onClick={cta.onClick}
        disabled={cta.disabled}
        aria-busy={cta.busy || undefined}
      >
        {cta.busy ? <span className={styles.spinner} aria-hidden /> : null}
        {cta.label}
        {cta.busy ? null : <ArrowRight size={16} aria-hidden />}
      </button>
    )
  ) : null;

  return (
    <article
      id={id}
      className={`${styles.card} ${featured ? styles.featured : ""} ${ribbon ? styles.withRibbon : ""}`}
    >
      {ribbon ? (
        <span className={`${styles.ribbon} ${ribbonTone === "green" ? styles.ribbonGreen : ""}`}>
          {ribbon}
        </span>
      ) : null}
      <span className={`${styles.kicker} ${kickerAccent ? styles.kickerAccent : ""}`}>
        {kicker}
      </span>
      <h3 className={styles.title}>{title}</h3>
      <p className={`${styles.desc} ${layout === "featuresFirst" ? styles.descCompact : ""}`}>
        {description}
      </p>

      {price ? (
        <>
          <div className={styles.priceMain}>
            <strong>{price.amount}</strong>
          </div>
          <div className={styles.priceSub}>{price.sub}</div>
        </>
      ) : null}

      {layout === "featuresFirst" ? (
        <>
          <div className={styles.featuresTop}>{featuresBlock}</div>
          {rowsBlock}
        </>
      ) : (
        <>
          {rowsBlock}
          <div className={styles.divider} aria-hidden />
          {featuresBlock}
        </>
      )}

      {ctaNode}
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
