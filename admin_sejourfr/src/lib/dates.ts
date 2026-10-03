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

/** Jour ISO `yyyy-MM-dd` à Paris, comme le backend : l'unique notion d'« aujourd'hui ». */
export function parisToday(): string {
  return new Intl.DateTimeFormat("fr-CA", { timeZone: PARIS }).format(new Date());
}

export function formatParisTime(iso: string | null | undefined): string {
  if (!iso) return "—";
  return new Date(iso).toLocaleTimeString("fr-FR", {
    timeZone: PARIS,
    hour: "2-digit",
    minute: "2-digit",
  });
}

/** Jour ISO `yyyy-MM-dd` à Paris d'un instant servi. */
export function parisDay(iso: string): string {
  return new Intl.DateTimeFormat("fr-CA", { timeZone: PARIS }).format(new Date(iso));
}

/** « 21/08 » — jour servi `yyyy-MM-dd`, sans conversion de fuseau. */
export function dayMonth(day: string): string {
  return `${day.slice(8, 10)}/${day.slice(5, 7)}`;
}

/** Période appliquée, toujours construite depuis les bornes SERVIES (`yyyy-MM-dd`). */
export function formatRange(from: string, to: string): string {
  if (from === to) return `Le ${longDate(from)}`;
  const sameYear = from.slice(0, 4) === to.slice(0, 4);
  const sameMonth = sameYear && from.slice(5, 7) === to.slice(5, 7);
  if (sameMonth) return `Du ${dayOfMonth(from)} au ${longDate(to)}`;
  if (sameYear) return `Du ${dayOfMonth(from)} ${monthName(from)} au ${longDate(to)}`;
  return `Du ${longDate(from)} au ${longDate(to)}`;
}

function longDate(day: string): string {
  return `${dayOfMonth(day)} ${monthName(day)} ${day.slice(0, 4)}`;
}

function dayOfMonth(day: string): string {
  const number = Number(day.slice(8, 10));
  return number === 1 ? "1er" : String(number);
}

function monthName(day: string): string {
  const [year, month, date] = day.split("-").map(Number);
  return new Date(Date.UTC(year, month - 1, date)).toLocaleDateString("fr-FR", {
    month: "long",
    timeZone: "UTC",
  });
}
