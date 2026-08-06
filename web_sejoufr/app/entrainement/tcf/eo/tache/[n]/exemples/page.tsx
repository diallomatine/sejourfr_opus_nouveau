import {ProductionExamples} from "@/app/_components/production/ProductionExamples";
import {EO_CONFIG} from "@/app/_components/production/config";

export default function EoTaskExamplesPage() {
  return <ProductionExamples config={EO_CONFIG} />;
}
