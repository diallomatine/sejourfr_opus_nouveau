/**
 * Jours ISO `yyyy-MM-dd` au fuseau Europe/Paris, comme le backend. Une seule
 * notion d'« aujourd'hui » : `parisToday()`.
 */

export function parisToday(): string {
  return new Intl.DateTimeFormat("fr-CA", { timeZone: "Europe/Paris" }).format(
    new Date(),
  );
}

/** « 21/08 » — mention « mesuré depuis le … ». */
export function dayMonth(day: string): string {
  return `${day.slice(8, 10)}/${day.slice(5, 7)}`;
}

/** « 25 septembre 2026 », « 1er septembre 2026 ». */
function longDate(day: string): string {
  return `${dayOfMonth(day)} ${monthName(day)} ${day.slice(0, 4)}`;
}

/** Periode appliquee, toujours construite depuis les bornes SERVIES. */
export function formatRange(from: string, to: string): string {
  if (from === to) return `Le ${longDate(from)}`;
  const sameYear = from.slice(0, 4) === to.slice(0, 4);
  const sameMonth = sameYear && from.slice(5, 7) === to.slice(5, 7);
  if (sameMonth) return `Du ${dayOfMonth(from)} au ${longDate(to)}`;
  if (sameYear) return `Du ${dayOfMonth(from)} ${monthName(from)} au ${longDate(to)}`;
  return `Du ${longDate(from)} au ${longDate(to)}`;
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
