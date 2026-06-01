import {ProductionHistory} from "@/app/_components/production/ProductionHistory";
import {EE_CONFIG} from "@/app/_components/production/config";

export default function EeHistoryPage() {
  return <ProductionHistory config={EE_CONFIG} />;
}
