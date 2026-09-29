import type { MetadataRoute } from "next";
import { SITE } from "@/lib/site";

/** Espace connecté et parcours transactionnels : rien à indexer, et du budget de crawl épargné. */
const PRIVE = [
  "/dashboard",
  "/plan",
  "/parcours",
  "/progression",
  "/profil",
  "/favoris",
  "/aide",
  "/paiement",
  "/diagnostic-civique",
  "/entrainement",
  "/examen-blanc",
  "/sessions",
  "/completer-profil",
  "/continuer-sur-app",
  "/mot-de-passe-oublie",
  "/reinitialiser-mot-de-passe",
];

export default function robots(): MetadataRoute.Robots {
  return {
    rules: [{ userAgent: "*", allow: "/", disallow: PRIVE }],
    sitemap: `${SITE.url}/sitemap.xml`,
    host: SITE.url,
  };
}
