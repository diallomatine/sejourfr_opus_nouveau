import type { AuthenticatedUser } from "@/lib/types";
import type { PassModule } from "@/lib/passes";

/** L'accès du compte, lu sur les droits SERVIS (`hasTcf` / `hasCivique`). */
export type CurrentPlan = "FREE" | "CIVIQUE" | "INTEGRAL";

export function deriveCurrentPlan(user: AuthenticatedUser | null): CurrentPlan {
  if (!user) return "FREE";
  if (user.hasTcf) return "INTEGRAL";
  if (user.hasCivique) return "CIVIQUE";
  return "FREE";
}

/**
 * Ce que la carte d'un module propose à CE compte :
 *  · `current`  — son pass en cours : on le prolonge ;
 *  · `upgrade`  — Civique en cours, carte Intégral (Stripe crédite le reste) ;
 *  · `included` — Intégral en cours, carte Civique : déjà couvert, achat laissé possible ;
 *  · `subscribe` — sinon.
 */
export type CardIntent = "subscribe" | "current" | "upgrade" | "included";

export function deriveIntent(currentPlan: CurrentPlan, module: PassModule): CardIntent {
  if (currentPlan === module) return "current";
  if (currentPlan === "CIVIQUE" && module === "INTEGRAL") return "upgrade";
  if (currentPlan === "INTEGRAL" && module === "CIVIQUE") return "included";
  return "subscribe";
}

export function daysLeft(iso: string | null | undefined): number | null {
  if (!iso) return null;
  const diff = Date.parse(iso) - Date.now();
  if (Number.isNaN(diff)) return null;
  return Math.max(0, Math.ceil(diff / 86_400_000));
}

export function formatEndDate(iso: string): string {
  return new Date(iso).toLocaleDateString("fr-FR", {
    day: "2-digit",
    month: "long",
    year: "numeric",
  });
}
