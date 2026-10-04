import {ProductionExamples} from "@/app/_components/production/ProductionExamples";
import {EE_CONFIG} from "@/app/_components/production/config";

export default function EeTaskExamplesPage() {
  return <ProductionExamples config={EE_CONFIG} />;
}
