import type {Metadata} from "next";
import {PlanEtapeView} from "@/app/_components/plan/PlanEtapeView";

export const metadata: Metadata = {
  title: "Mon étape — SejourFR",
  description: "Ce que cette étape demande, et ses séries une par une.",
};

/**
 * **Le détail d'une étape de séries**, ouvert depuis le cycle du Plan.
 *
 * 🛑 **Il REMPLACE le lancement direct** : une étape d'entraînement de
 * compréhension (CO/CE) ou une étape civique n'ouvre plus une série depuis sa
 * ligne du cycle, elle ouvre cet écran. Les étapes d'**expression** (EE/EO) ne
 * changent pas.
 *
 * 🛑 Le préfixe `/plan` est déjà dans `APP_GROUP_PREFIXES`
 * (`lib/chrome-routes.ts`), qui teste un préfixe : rien à ajouter.
 */
export default function PlanEtapePage() {
  return <PlanEtapeView />;
}
