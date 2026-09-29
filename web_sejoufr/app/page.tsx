import type { Metadata } from "next";
import {
  AiValue,
  CiviqueThemes,
  Diagnostic,
  Exams,
  FinalCta,
  Hero,
  MobileApp,
  PromiseStrip,
  Reason,
  TcfDetail,
} from "./_components/landing/LandingSections";
import { LandingPricing } from "./_components/landing/LandingPricing";
import { LandingViewTracker } from "./_components/landing/LandingTracking";
import styles from "./_components/landing/landing.module.css";
import { billingApi } from "@/lib/api";
import type { PlanPublicResponse } from "@/lib/types";
import { SITE, STORE_LINKS } from "@/lib/site";

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
    sameAs: [STORE_LINKS.ios, STORE_LINKS.android],
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
// section Tarifs. Fallback vide si l'API est down au build → seule la carte
// Gratuit reste, plutôt que de casser la page.
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
    <main className={styles.page}>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{
          __html: JSON.stringify(jsonLd).replace(/</g, "\\u003c"),
        }}
      />
      <LandingViewTracker />
      <Hero />
      <PromiseStrip />
      <Reason />
      <Exams />
      <TcfDetail />
      <CiviqueThemes />
      <AiValue />
      <MobileApp />
      <Diagnostic />
      <LandingPricing plans={plans} />
      <FinalCta />
    </main>
  );
}
