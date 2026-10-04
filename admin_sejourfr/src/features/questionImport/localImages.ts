import { NB } from "../../lib/format";

/** Image choisie par l'admin, avec l'URL d'objet de sa vignette (révoquée au retrait). */
export interface LocalImage {
  name: string;
  file: File;
  url: string;
}

export function formatBytes(bytes: number): string {
  if (bytes < 1024) return `${bytes}${NB}o`;
  if (bytes < 1024 * 1024) return `${Math.round(bytes / 1024)}${NB}Ko`;
  return `${(bytes / (1024 * 1024)).toLocaleString("fr-FR", { maximumFractionDigits: 1 })}${NB}Mo`;
}
