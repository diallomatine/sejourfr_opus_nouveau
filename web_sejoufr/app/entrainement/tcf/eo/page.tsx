import {ProductionTasks} from "@/app/_components/production/ProductionTasks";
import {EO_CONFIG} from "@/app/_components/production/config";

export default function EoEntryPage() {
  return <ProductionTasks config={EO_CONFIG} />;
}
