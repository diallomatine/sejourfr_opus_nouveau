import {
  Competences,
  Examens,
  FinalCta,
  Hero,
  Niveau,
  Parcours,
  Simulation,
  Tarifs,
  Temoignages,
} from "./_components/landing/Landing";
import type { Metadata } from "next";
import { MobileAppSection } from "./_components/MobileAppPromo";
import { billingApi } from "@/lib/api";
import type { PlanPublicResponse } from "@/lib/types";
import { SITE } from "@/lib/site";

const APP_STORE_URL = "https://apps.apple.com/fr/app/sejourfr/id6771509569";
const PLAY_STORE_URL =
  "https://play.google.com/store/apps/details?id=com.sejourfr.app&hl=fr";

export const metadata: Metadata = {
  title: "SejourFR — Préparation TCF IRN & Examen civique",
  description:
    "Préparez le TCF IRN et l'examen civique avec des examens blancs, la correction IA de l'oral et de l'écrit, et une estimation de niveau A2, B1 ou B2.",
  alternates: { canonical: "/" },
  openGraph: {
    url: SITE.url,
    title: "SejourFR — Préparation TCF IRN & Examen civique",
    description:
      "Entraînez-vous au TCF IRN et à l'examen civique : examens blancs, correction IA et estimation de niveau.",
  },
};

// JSON-LD : dit à Google que « SejourFR » est la marque officielle (Organization)
// et déclare le site (WebSite). Les variantes orthographiques passent en
// alternateName pour capter les requêtes « Séjour FR », « Sejour FR », etc.
const jsonLd = [
  {
    "@context": "https://schema.org",
    "@type": "Organization",
    name: SITE.name,
    alternateName: ["SéjourFR", "Sejour FR", "Séjour FR", "SejourFR app"],
    url: SITE.url,
    logo: `${SITE.url}/logo_sejourFR.png`,
    sameAs: [APP_STORE_URL, PLAY_STORE_URL],
  },
  {
    "@context": "https://schema.org",
    "@type": "WebSite",
    name: SITE.name,
    alternateName: ["SéjourFR", "Sejour FR"],
    url: SITE.url,
    inLanguage: "fr-FR",
  },
];

// Plans actifs récupérés côté serveur (ISR 30 min, comme /tarifs) pour la
// section Tarifs de la landing. Fallback vide si l'API est down au build →
// PricingPlans n'affiche que la carte Free, plutôt que de casser la page.
export const revalidate = 1800;

async function fetchPlans(): Promise<PlanPublicResponse[]> {
  try {
    return await billingApi.listPlans();
  } catch {
    return [];
  }
}

export default async function HomePage() {
  const plans = await fetchPlans();

  return (
    <main>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{
          __html: JSON.stringify(jsonLd).replace(/</g, "\\u003c"),
        }}
      />
      <Hero />
      <Parcours />
      <Examens />
      <Competences />
      <Simulation />
      <Niveau />
      <Temoignages />
      <Tarifs plans={plans} />
      <MobileAppSection />
      <FinalCta />
    </main>
  );
}
