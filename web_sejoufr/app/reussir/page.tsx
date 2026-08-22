import type { Metadata } from "next";
import { ReussirView } from "@/app/_components/reussir/ReussirView";
import { billingApi } from "@/lib/api";
import { SITE } from "@/lib/site";
import type { PlanPublicResponse } from "@/lib/types";

export const metadata: Metadata = {
  title: "TCF IRN et examen civique — diagnostic gratuit | SejourFR",
  description:
    "Un plan de révision qui s'adapte à vous, pour les deux examens obligatoires : le TCF IRN (A2, B1, B2) et l'examen civique sur les 5 thèmes officiels. Diagnostic gratuit en 8 minutes, sans carte bancaire.",
  alternates: { canonical: "/reussir" },
  openGraph: {
    title: "TCF IRN et examen civique : un plan qui s'adapte à toi",
    description:
      "Un écrit, un oral, et SejourFR nomme ce qui te bloque. Examen civique inclus : 5 thèmes, séries de 20 questions, examens blancs.",
    type: "website",
    url: `${SITE.url}/reussir`,
  },
  twitter: {
    card: "summary_large_image",
    title: "TCF IRN et examen civique — SejourFR",
    description:
      "Diagnostic gratuit en 8 minutes, priorités nommées, et la préparation de l'examen civique au même endroit.",
  },
};

export const revalidate = 1800;

async function fetchPlans(): Promise<PlanPublicResponse[]> {
  try {
    return await billingApi.listPlans();
  } catch {
    // API injoignable au build : on rend la page sans la section tarifs plutôt
    // que de casser une landing dont le seul job est de convertir.
    return [];
  }
}

export default async function ReussirPage() {
  const plans = await fetchPlans();
  return <ReussirView plans={plans} />;
}
