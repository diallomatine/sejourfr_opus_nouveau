/**
 * Tout l'ecran raisonne en jours ISO `yyyy-MM-dd` au fuseau Europe/Paris, comme
 * le backend. Une seule notion d'« aujourd'hui » : `parisToday()`.
 *
 * Absorbe de l'ancienne feature `audience/`, ou ce fichier tenait deja ce role.
 */

export function parisToday(): string {
  return new Intl.DateTimeFormat("fr-CA", { timeZone: "Europe/Paris" }).format(
    new Date(),
  );
}

/** « 18 aout » — axe d'un graphe, ou l'annee est deja donnee ailleurs. */
export function formatDay(day: string): string {
  return toUtc(day).toLocaleDateString("fr-FR", {
    day: "numeric",
    month: "short",
    timeZone: "UTC",
  });
}

/** « 18 aout 2026 », « 1er aout 2026 ». */
export function formatDate(day: string): string {
  return `${dayOfMonth(day)} ${monthName(day)} ${day.slice(0, 4)}`;
}

/**
 * Periode appliquee, en une phrase. Toujours construite depuis les bornes
 * renvoyees par le serveur : c'est ce qui rend l'ecran verifiable.
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

/** Forme courte pour la mention « compare au … », sans l'annee. */
export function formatShortRange(from: string, to: string): string {
  if (from === to) return formatDay(from);
  return `${formatDay(from)} → ${formatDay(to)}`;
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

function toUtc(day: string): Date {
  const [year, month, date] = day.split("-").map(Number);
  return new Date(Date.UTC(year, month - 1, date));
}
