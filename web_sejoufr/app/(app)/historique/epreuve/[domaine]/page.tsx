import type {Metadata} from "next";
import {EpreuveHistoriqueView} from "@/app/_components/progres/EpreuveHistoriqueView";

export const metadata: Metadata = {
  title: "Mes résultats par épreuve — SejourFR",
  description: "Les évaluations qui déterminent votre niveau sur cette épreuve.",
};

/**
 * **« D'où sort mon niveau ? »** — ouvert depuis une carte d'épreuve de
 * l'Accueil.
 *
 * 🛑 **Ce n'est pas une troisième page de progression.** `/statistiques` répond
 * à « où j'en suis », `/plan/progression` à « ce qu'il reste à faire »,
 * `/historique` liste **toutes** les sessions — entraînements compris. Celle-ci
 * ne montre que les **évaluations qualifiantes** de UNE épreuve, exactement
 * celles qui ont produit le palier affiché sur la carte. Aucune des trois
 * autres ne répond à « pourquoi ce niveau ? », d'où sa place **sous**
 * `/historique`, la surface des résultats.
 *
 * 🛑 Le préfixe `/historique` est déjà dans `APP_GROUP_PREFIXES`
 * (`lib/chrome-routes.ts`), qui teste un préfixe : rien à ajouter.
 */
export default function EpreuveHistoriquePage() {
  return <EpreuveHistoriqueView />;
}
