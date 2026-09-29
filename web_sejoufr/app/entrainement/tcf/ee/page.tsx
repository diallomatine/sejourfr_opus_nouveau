import {ProductionTasks} from "@/app/_components/production/ProductionTasks";
import {EE_CONFIG} from "@/app/_components/production/config";

export default function EeEntryPage() {
  return <ProductionTasks config={EE_CONFIG} />;
}
