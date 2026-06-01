import {ProductionHistory} from "@/app/_components/production/ProductionHistory";
import {EO_CONFIG} from "@/app/_components/production/config";

export default function EoHistoryPage() {
  return <ProductionHistory config={EO_CONFIG} />;
}
