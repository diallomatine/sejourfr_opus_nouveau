import {ProductionSubjects} from "@/app/_components/production/ProductionSubjects";
import {EO_CONFIG} from "@/app/_components/production/config";

export default function EoTaskPage() {
  return <ProductionSubjects config={EO_CONFIG} />;
}
