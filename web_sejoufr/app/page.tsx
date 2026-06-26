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
import { MobileAppSection } from "./_components/MobileAppPromo";
import { billingApi } from "@/lib/api";
import type { PlanPublicResponse } from "@/lib/types";

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
