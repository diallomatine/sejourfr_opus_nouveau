import type { Metadata } from "next";
import Link from "next/link";
import { PricingHero } from "@/components/pricing/PricingHero";
import { PricingPlans } from "@/components/pricing/PricingPlans";
import { PricingComparison } from "@/components/pricing/PricingComparison";
import { PricingFAQ } from "@/components/pricing/PricingFAQ";
import { billingApi } from "@/lib/api";
import { SITE } from "@/lib/site";
import { safeJsonLd } from "@/lib/security";
import type { PlanPublicResponse } from "@/lib/types";

export const metadata: Metadata = {
  title: "Tarifs — Pass Civique et Intégral | SejourFR",
  description:
    "Préparez votre examen civique avec un pass à durée fixe : Civique (3 mois, 1 an) ou Intégral (Civique + TCF). Paiement unique, sans abonnement.",
  alternates: { canonical: "/tarifs" },
  openGraph: {
    title: "Tarifs SejourFR — examen civique et naturalisation",
    description:
      "Pass d'accès à durée fixe : découverte gratuite, Civique, Intégral (Civique + TCF). Paiement unique, sans renouvellement automatique.",
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

  // JSON-LD : un Product représentatif "Accès Intégral" + AggregateOffer
  // couvrant la fourchette de prix des passes (tirés du catalogue dynamique).
  // Renseigne image/description/brand/sku + politique de retour → lève le
  // critique (image) et les avertissements "Fiches de marchand". Pas de
  // shippingDetails (produit numérique, rien n'est expédié) ni de
  // aggregateRating/review (aucun avis utilisateur réel noté affiché).
  const paidPlans = plans.filter((p) => p.code !== "FREE");
  const prices = paidPlans.map((p) => p.price);
  const jsonLd =
    paidPlans.length > 0
      ? {
          "@context": "https://schema.org",
          "@type": "Product",
          name: "SejourFR — Accès Intégral (Civique + TCF IRN)",
          description:
            "Préparation complète à l'examen civique et au TCF IRN : QCM type examen, examens blancs en conditions réelles, corrections expliquées et suivi de progression.",
          image: `${SITE.url}/tarifs/opengraph-image`,
          brand: { "@type": "Brand", name: "SejourFR" },
          sku: "SEJFR-INTEGRAL",
          offers: {
            "@type": "AggregateOffer",
            priceCurrency: "EUR",
            lowPrice: Math.min(...prices).toFixed(2),
            highPrice: Math.max(...prices).toFixed(2),
            offerCount: String(paidPlans.length),
            url: `${SITE.url}/tarifs`,
            hasMerchantReturnPolicy: {
              "@type": "MerchantReturnPolicy",
              applicableCountry: "FR",
              returnPolicyCategory:
                "https://schema.org/MerchantReturnNotPermitted",
            },
          },
        }
      : null;

  return (
    <>
      <main className="container-x tarifs-page">
        {jsonLd && (
          <script
            type="application/ld+json"
            dangerouslySetInnerHTML={{ __html: safeJsonLd(jsonLd) }}
          />
        )}
        <PricingHero />
        <PricingPlans plans={plans} measured />
        <PricingComparison />
        <PricingFAQ />

        <p className="tarifs-foot">
          Paiement sécurisé par <strong>Stripe</strong>. Paiement unique, sans
          abonnement. Une question avant achat ?{" "}
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
