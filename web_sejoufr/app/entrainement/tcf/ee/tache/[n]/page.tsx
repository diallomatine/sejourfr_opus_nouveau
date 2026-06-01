import {ProductionSubjects} from "@/app/_components/production/ProductionSubjects";
import {EE_CONFIG} from "@/app/_components/production/config";

export default function EeTaskPage() {
  return <ProductionSubjects config={EE_CONFIG} />;
}
