import type {Metadata} from "next";
import {ThemeHistoriqueView} from "@/app/_components/progres/ThemeHistoriqueView";

export const metadata: Metadata = {
  title: "Mes résultats par thème — SejourFR",
  description: "Vos examens blancs sur ce thème de l'examen civique, et votre score face au seuil de réussite.",
};

/**
 * **« Où j'en suis sur ce thème ? »** — ouvert depuis une ligne de thème
 * civique de l'Accueil.
 *
 * 🛑 **Ce n'est pas la grille des examens blancs du thème**
 * (`/entrainement/civique/[theme]/examens`), qui est là où l'on **passe** un
 * examen : celle-ci est là où l'on **lit** ses résultats. C'est le pendant
 * civique de `/historique/epreuve/[domaine]`, d'où sa place sous
 * `/historique`, la surface des résultats.
 *
 * 🛑 Le segment est le **slug du thème**, celui que `civicThemeExamsHref`
 * emploie déjà (`themeSlug(code)`) ; un UUID hérité résout aussi, comme sur les
 * autres routes de thème.
 *
 * 🛑 Le préfixe `/historique` est déjà dans `APP_GROUP_PREFIXES`
 * (`lib/chrome-routes.ts`), qui teste un préfixe : rien à ajouter.
 */
export default function ThemeHistoriquePage() {
  return <ThemeHistoriqueView />;
}
