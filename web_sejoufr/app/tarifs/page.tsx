import type { Metadata } from "next";
import Link from "next/link";
import { PricingHero } from "@/components/pricing/PricingHero";
import { PricingPlans } from "@/components/pricing/PricingPlans";
import { PricingComparison } from "@/components/pricing/PricingComparison";
import { PricingFAQ } from "@/components/pricing/PricingFAQ";
import { billingApi } from "@/lib/api";
import { SITE } from "@/lib/site";
import type { PlanPublicResponse } from "@/lib/types";

export const metadata: Metadata = {
  title: "Tarifs — Abonnements Civique et Intégral | SejourFR",
  description:
    "Préparez votre examen civique avec un abonnement mensuel, trimestriel ou annuel : Civique ou Intégral (Civique + TCF). Annulable à tout moment.",
  alternates: { canonical: "/tarifs" },
  openGraph: {
    title: "Tarifs SejourFR — examen civique et naturalisation",
    description:
      "Abonnements mensuel, trimestriel ou annuel. Découverte gratuite, Civique, Intégral (Civique + TCF). Annulable à tout moment.",
    type: "website",
    url: `${SITE.url}/tarifs`,
  },
};

export const revalidate = 1800;

async function fetchPlans(): Promise<PlanPublicResponse[]> {
  try {
    return await billingApi.listPlans();
  } catch {
    // Si l'API est down au build, on retombe sur un fallback vide — le
    // composant affichera juste la card Free. Mieux que de casser /tarifs.
    return [];
  }
}

export default async function TarifsPage() {
  const plans = await fetchPlans();

  // JSON-LD ItemList → rich snippets Google Shopping pour les plans payants.
  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "ItemList",
    itemListElement: plans
      .filter((p) => p.code !== "FREE")
      .map((p, i) => ({
        "@type": "ListItem",
        position: i + 1,
        item: {
          "@type": "Product",
          name: `SejourFR — ${p.name}`,
          offers: {
            "@type": "Offer",
            price: p.price.toFixed(2),
            priceCurrency: "EUR",
            availability: "https://schema.org/InStock",
            url: `${SITE.url}/tarifs`,
          },
        },
      })),
  };

  return (
    <>
      <main className="container-x tarifs-page">
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
        />
        <PricingHero />
        <PricingPlans plans={plans} />
        <PricingComparison />
        <PricingFAQ />

        <p className="tarifs-foot">
          Paiement sécurisé par <strong>Stripe</strong>. Annulable à tout moment.
          Une question avant achat ?{" "}
          <Link href="/contact" className="tarifs-foot-link">
            Contactez-nous
          </Link>
          .
        </p>

        <style>{`
          .tarifs-page {
            padding-top: 40px;
            padding-bottom: 64px;
          }
          .tarifs-foot {
            margin: 56px auto 0;
            max-width: 520px;
            text-align: center;
            font-size: 12.5px;
            color: var(--color-muted-2);
            line-height: 1.6;
          }
          .tarifs-foot strong { color: var(--color-ink-2); font-weight: 600; }
          .tarifs-foot-link {
            color: var(--color-blue);
            text-decoration: underline;
            text-decoration-color: rgba(30, 58, 140, 0.35);
            text-underline-offset: 2px;
          }
          .tarifs-foot-link:hover { text-decoration-color: var(--color-blue); }
          @media (min-width: 1024px) {
            .tarifs-page { padding-top: 56px; padding-bottom: 80px; }
          }
        `}</style>
      </main>
    </>
  );
}
