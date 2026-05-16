import type { Metadata } from "next";
import Link from "next/link";
import { PricingHero } from "@/components/pricing/PricingHero";
import { PricingCards } from "@/components/pricing/PricingCards";
import { PricingComparison } from "@/components/pricing/PricingComparison";
import { PricingFAQ } from "@/components/pricing/PricingFAQ";
import { billingApi } from "@/lib/api";
import { SITE } from "@/lib/site";
import type { PlanPublicResponse } from "@/lib/types";

export const metadata: Metadata = {
  title: "Tarifs — Civique et Intégral 3 mois | SejourFR",
  description:
    "Préparez votre examen civique avec un paiement unique : Civique 3 mois ou Intégral 3 mois (Civique + TCF). Sans renouvellement automatique.",
  alternates: { canonical: "/tarifs" },
  openGraph: {
    title: "Tarifs SejourFR — examen civique et naturalisation",
    description:
      "Paiement unique, sans renouvellement automatique. Découverte gratuite, Civique 3 mois, Intégral (Civique + TCF) 3 mois.",
    type: "website",
    url: `${SITE.url}/tarifs`,
  },
};

export const revalidate = 1800;

const FALLBACK_PLANS: PlanPublicResponse[] = [
  {
    code: "FREE",
    name: "Découverte",
    billingCycle: "NONE",
    price: 0,
    originalPrice: null,
    moduleAccess: "NONE",
    durationDays: 0,
  },
  {
    code: "CIVIQUE_3MOIS",
    name: "Civique — 3 mois",
    billingCycle: "THREE_MONTHS",
    price: 5.99,
    originalPrice: 9.99,
    moduleAccess: "CIVIQUE",
    durationDays: 90,
  },
  {
    code: "INTEGRAL_3MOIS",
    name: "Intégral — 3 mois",
    billingCycle: "THREE_MONTHS",
    price: 14.99,
    originalPrice: 19.99,
    moduleAccess: "INTEGRAL",
    durationDays: 90,
  },
];

async function fetchPlans(): Promise<PlanPublicResponse[]> {
  try {
    const fetched = await billingApi.listPlans();
    return fetched.length > 0 ? fetched : FALLBACK_PLANS;
  } catch {
    // Si l'API est down au build, on retombe sur le fallback statique pour ne
    // pas casser la page tarifs (page critique pour la conversion).
    return FALLBACK_PLANS;
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
        <PricingCards plans={plans} />
        <PricingComparison />
        <PricingFAQ />

        <p className="tarifs-foot">
          Paiement sécurisé par <strong>Stripe</strong>. Une question avant
          achat ?{" "}
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
