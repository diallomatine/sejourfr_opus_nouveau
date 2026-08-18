/**
 * Toute la feature raisonne en jours ISO `yyyy-MM-dd` au fuseau Europe/Paris,
 * comme le backend. Une seule notion d'« aujourd'hui » : `parisToday()`.
 */

export function parisToday(): string {
  return new Intl.DateTimeFormat("fr-CA", { timeZone: "Europe/Paris" }).format(
    new Date(),
  );
}

export function addDays(day: string, delta: number): string {
  const [year, month, date] = day.split("-").map(Number);
  return new Date(Date.UTC(year, month - 1, date + delta))
    .toISOString()
    .slice(0, 10);
}

/** Lundi de la semaine du jour donné (semaine française). */
export function weekStart(day: string): string {
  const [year, month, date] = day.split("-").map(Number);
  const weekday = new Date(Date.UTC(year, month - 1, date)).getUTCDay();
  return addDays(day, -((weekday + 6) % 7));
}

/** Premier jour du mois du jour donné. */
export function monthStart(day: string): string {
  return `${day.slice(0, 7)}-01`;
}

/** Nombre de jours couverts par les deux bornes incluses. */
export function daysBetween(from: string, to: string): number {
  return Math.round((toUtc(to).getTime() - toUtc(from).getTime()) / 86_400_000) + 1;
}

/** « 18 août » — axe du graphe, où l'année est déjà donnée ailleurs. */
export function formatDay(day: string): string {
  return toUtc(day).toLocaleDateString("fr-FR", {
    day: "2-digit",
    month: "short",
    timeZone: "UTC",
  });
}

/** « 18 août 2026 », « 1er août 2026 ». */
export function formatDate(day: string): string {
  return `${dayOfMonth(day)} ${monthName(day)} ${day.slice(0, 4)}`;
}

/**
 * Période appliquée, en une phrase. Toujours construite depuis les bornes
 * renvoyées par le serveur : c'est ce qui rend l'écran vérifiable.
 */
export function formatRange(from: string, to: string): string {
  if (from === to) return `le ${formatDate(from)}`;

  const sameYear = from.slice(0, 4) === to.slice(0, 4);
  const sameMonth = sameYear && from.slice(5, 7) === to.slice(5, 7);

  if (sameMonth) return `du ${dayOfMonth(from)} au ${formatDate(to)}`;
  if (sameYear) {
    return `du ${dayOfMonth(from)} ${monthName(from)} au ${formatDate(to)}`;
  }
  return `du ${formatDate(from)} au ${formatDate(to)}`;
}

function dayOfMonth(day: string): string {
  const number = Number(day.slice(8, 10));
  return number === 1 ? "1er" : String(number);
}

function monthName(day: string): string {
  return toUtc(day).toLocaleDateString("fr-FR", {
    month: "long",
    timeZone: "UTC",
  });
}

/**
 * Rétablit une série continue entre deux bornes incluses. Sans les jours vides,
 * deux points espacés d'un mois seraient dessinés côte à côte et la largeur des
 * barres ne voudrait rien dire.
 */
export function fillDays<T extends { day: string }>(
  points: T[],
  from: string,
  to: string,
  empty: (day: string) => T,
): T[] {
  const byDay = new Map(points.map((p) => [p.day, p]));
  const observed = points.map((p) => p.day);
  const start = [from, ...observed].reduce((a, b) => (a < b ? a : b));
  const end = [to, ...observed].reduce((a, b) => (a > b ? a : b));

  const series: T[] = [];
  for (let day = start; day <= end && series.length < 400; day = addDays(day, 1)) {
    series.push(byDay.get(day) ?? empty(day));
  }
  return series;
}

function toUtc(day: string): Date {
  const [year, month, date] = day.split("-").map(Number);
  return new Date(Date.UTC(year, month - 1, date));
}
