import {ProductionResults} from "@/app/_components/production/ProductionResults";
import {EE_CONFIG} from "@/app/_components/production/config";

export default function EeResultsPage() {
  return <ProductionResults config={EE_CONFIG} />;
}
