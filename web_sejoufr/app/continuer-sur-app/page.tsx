import type {Metadata} from "next";
import {ContinueOnAppFallback} from "./ContinueOnAppFallback";

/**
 * **Page de repli du lien « Continuer sur l'application »** (lot 3b). Elle ne
 * s'affiche que si l'app n'a pas intercepté l'adresse : app absente, lien
 * ouvert hors téléphone, ou iPhone quand le lien vise le même domaine (D83).
 * Jamais indexée : ce n'est pas une page d'arrivée.
 */
export const metadata: Metadata = {
  title: "Continuer sur l'application | SejourFR",
  robots: {index: false, follow: false},
};

export default function ContinuerSurAppPage() {
  return <ContinueOnAppFallback />;
}
