import {ProductionSubjects} from "@/app/_components/production/ProductionSubjects";
import {EO_CONFIG, PRODUCTION_TASK_PARAMS} from "@/app/_components/production/config";

export default function EoTaskPage() {
  return <ProductionSubjects config={EO_CONFIG} />;
}

/** Les 3 tâches sont prérendues : changer de mode ne redemande pas la page au
 *  serveur (cf. `PRODUCTION_TASK_PARAMS`). */
export function generateStaticParams() {
  return [...PRODUCTION_TASK_PARAMS];
}
