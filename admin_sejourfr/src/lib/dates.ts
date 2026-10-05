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

/** Mois civil courant à Paris, au format `yyyy-MM`. */
export function parisCurrentMonth(): string {
  return new Intl.DateTimeFormat("en-CA", { timeZone: PARIS, year: "numeric", month: "2-digit" })
    .format(new Date())
    .slice(0, 7);
}

export const MONTH_PATTERN = /^\d{4}-(0[1-9]|1[0-2])$/;

/**
 * Les `count` derniers mois civils (Paris), le plus récent en tête, au format
 * `yyyy-MM`. Un mois plus ancien arrivé par l'URL reste sélectionné : il est
 * ajouté en fin de liste plutôt qu'ignoré.
 */
export function monthOptions(selected: string | undefined, count = 24): { value: string; label: string }[] {
  const [y, m] = parisCurrentMonth().split("-").map(Number);
  const values: string[] = [];
  for (let i = 0; i < count; i++) {
    const d = new Date(Date.UTC(y, m - 1 - i, 1));
    values.push(`${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, "0")}`);
  }
  if (selected && !values.includes(selected)) values.push(selected);
  return values.map((value) => {
    const [vy, vm] = value.split("-").map(Number);
    const label = new Date(Date.UTC(vy, vm - 1, 1)).toLocaleDateString("fr-FR", {
      timeZone: "UTC",
      month: "long",
      year: "numeric",
    });
    return { value, label };
  });
}

/** Premier et dernier jour (`yyyy-MM-dd`) d'un mois `yyyy-MM`. */
export function monthBounds(month: string): { from: string; to: string } {
  const [y, m] = month.split("-").map(Number);
  const last = new Date(Date.UTC(y, m, 0)).getUTCDate();
  return { from: `${month}-01`, to: `${month}-${String(last).padStart(2, "0")}` };
}
