import {CompetencesList} from "@/app/_components/competences/CompetencesList";
import {EO_CONFIG, PRODUCTION_TASK_PARAMS} from "@/app/_components/production/config";

export default function EOCompetencesPage() {
  return <CompetencesList config={EO_CONFIG} />;
}

/** Les 3 tâches sont prérendues : changer de mode ne redemande pas la page au
 *  serveur (cf. `PRODUCTION_TASK_PARAMS`). */
export function generateStaticParams() {
  return [...PRODUCTION_TASK_PARAMS];
}
