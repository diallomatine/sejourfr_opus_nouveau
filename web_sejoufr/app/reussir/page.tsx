import type { Metadata } from "next";
import { ReussirView } from "@/app/_components/reussir/ReussirView";
import { billingApi } from "@/lib/api";
import { SITE } from "@/lib/site";
import type { PlanPublicResponse } from "@/lib/types";

export const metadata: Metadata = {
  title: "Diagnostic TCF gratuit — découvrez vos priorités | SejourFR",
  description:
    "Faites un exercice écrit et un oral en 8 à 10 minutes. SejourFR estime votre niveau de production et construit votre plan de travail personnalisé.",
  alternates: { canonical: "/reussir" },
  openGraph: {
    title: "Tu prépares le TCF ? Découvre d'abord ce qui te bloque.",
    description:
      "Un écrit, un oral enregistré et une analyse personnalisée en 8 à 10 minutes, sans carte bancaire.",
    type: "website",
    url: `${SITE.url}/reussir`,
  },
  twitter: {
    card: "summary_large_image",
    title: "Diagnostic TCF gratuit — SejourFR",
    description:
      "Découvrez vos priorités à partir d'un exercice écrit et d'un oral enregistré.",
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
