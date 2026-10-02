const PARIS = "Europe/Paris";

/**
 * Affichage d'un instant SERVI en heure de Paris (le fuseau des règles métier
 * côté serveur). Mise en forme seulement : aucune borne, aucune date incluse
 * ni exclusive n'est déduite ici — celles-là arrivent servies.
 */
export function formatParisDate(iso: string | null | undefined): string {
  if (!iso) return "—";
  return new Date(iso).toLocaleDateString("fr-FR", {
    timeZone: PARIS,
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
  });
}

export function formatParisDateTime(iso: string | null | undefined): string {
  if (!iso) return "—";
  return new Date(iso).toLocaleString("fr-FR", {
    timeZone: PARIS,
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}
