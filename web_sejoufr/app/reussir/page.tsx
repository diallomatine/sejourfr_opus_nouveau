import type { Metadata } from "next";
import { ReussirView } from "@/app/_components/reussir/ReussirView";
import { billingApi } from "@/lib/api";
import { SITE } from "@/lib/site";
import type { PlanPublicResponse } from "@/lib/types";

export const metadata: Metadata = {
  title: "SejourFR — TCF IRN et examen civique préparés pour de vrai",
  description:
    "Le lien de la bio : entraînez-vous au TCF IRN (A2, B1, B2) et à l'examen civique dans les conditions du jour J, avec un examinateur IA qui vous fait passer l'oral.",
  alternates: { canonical: "/reussir" },
  openGraph: {
    title: "SejourFR — préparez votre TCF IRN et votre examen civique",
    description:
      "Un examinateur IA qui vous parle, vous note sur 20 et vous dit quoi corriger. Série offerte, sans inscription.",
    type: "website",
    url: `${SITE.url}/reussir`,
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
