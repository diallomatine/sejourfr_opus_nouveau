"use client";

import { useMemo } from "react";
import { PassCard, PriceCard } from "@/components/pricing/PassCard";
import { track } from "@/lib/analytics";
import { useAuth } from "@/lib/auth-context";
import {
  FREE_OFFER_FEATURES,
  isOneTimeCatalog,
  oneTimePassesOf,
  PASS_MODULE_CARD_TITLE,
  PASS_MODULE_NAME,
  PASS_FEATURES,
  PASS_MODULES_IN_ORDER,
  PASS_PITCH,
  type PassModule,
} from "@/lib/passes";
import { withTrafficSource } from "@/lib/traffic-source";
import type { PlanPublicResponse } from "@/lib/types";
import { useTrafficSource } from "@/lib/use-traffic-source";
import styles from "./landing.module.css";

/**
 * Tarifs de l'accueil. 🛑 Aucun prix, aucune durée, aucun nombre de
 * simulations n'est écrit ici : les cartes viennent des passes ACTIFS servis
 * par `GET /api/billing/plans` (ISR de la page). L'ordre est
 * `PASS_MODULES_IN_ORDER` (Intégral d'abord), puis la carte Gratuit.
 * Catalogue injoignable ⇒ seule la carte Gratuit reste, jamais un prix de repli.
 */

/** Ce qui est propre à la vitrine. Pitch et puces : `PASS_PITCH` / `PASS_FEATURES`. */
const PASS_COPY: Record<PassModule, { kicker: string; featured: boolean }> = {
  INTEGRAL: { kicker: "TCF IRN + Examen civique", featured: true },
  CIVIQUE: { kicker: "Pass Civique", featured: false },
};

export function LandingPricing({ plans }: { plans: PlanPublicResponse[] }) {
  const { status } = useAuth();
  // Auth en chargement ⇒ null : `passCheckoutHref` vise le récapitulatif.
  const authenticated = status === "loading" ? null : status === "authenticated";
  const source = useTrafficSource();

  const passesByModule = useMemo(
    () =>
      Object.fromEntries(
        PASS_MODULES_IN_ORDER.map((m) => [m, oneTimePassesOf(plans, m).filter((p) => p.price > 0)]),
      ) as Record<PassModule, PlanPublicResponse[]>,
    [plans],
  );
  const oneTime = isOneTimeCatalog(plans);

  return (
    <section id="tarifs" className={styles.section}>
      <div className={styles.wrap}>
        <div className={styles.pricingHead}>
          <span className={styles.kicker}>Tarifs</span>
          <h2 className={styles.sectionTitle}>
            Commencez gratuitement. Débloquez seulement ce dont vous avez besoin.
          </h2>
          {oneTime ? (
            <p className={styles.sectionSub}>
              Des accès simples, en paiement unique. Aucun renouvellement automatique.
            </p>
          ) : null}
        </div>

        <div className={styles.pricingGrid}>
          {/* 🛑 L'ordre vient de `PASS_MODULES_IN_ORDER` : l'Intégral d'abord. */}
          {PASS_MODULES_IN_ORDER.map((module) => {
            const passes = passesByModule[module];
            if (passes.length === 0) return null;
            const copy = PASS_COPY[module];
            return (
              <PassCard
                key={module}
                module={module}
                passes={passes}
                authenticated={authenticated}
                source={source}
                screen="accueil_offres"
                kicker={copy.kicker}
                title={PASS_MODULE_CARD_TITLE[module]}
                description={PASS_PITCH[module]}
                features={PASS_FEATURES[module]}
                featured={copy.featured}
                ribbon={copy.featured ? "Le plus complet" : null}
                showFromPrice
                markPopular
                ctaLabel={`Choisir ${PASS_MODULE_NAME[module]}`}
                ctaTone={copy.featured ? "blue" : "light"}
              />
            );
          })}

          <PriceCard
            kicker="Découvrir"
            title="Gratuit"
            description="Pour tester SejourFR, découvrir les entraînements et passer vos premiers essais."
            price={{ amount: "0 €", sub: "Sans limite de durée" }}
            rows={[{ key: "free", label: "Accès", value: "Gratuit" }]}
            features={FREE_OFFER_FEATURES}
            cta={{
              label: "Commencer gratuitement",
              href: withTrafficSource("/inscription", source),
              tone: "light",
              onClick: () => track("SIGNUP_CTA_CLICKED", { ctaLocation: "PRICING" }),
            }}
          />
        </div>

        {oneTime ? (
          <p className={styles.paymentNote}>
            <b>Paiement unique</b> · aucun renouvellement automatique.
          </p>
        ) : null}
      </div>
    </section>
  );
}
