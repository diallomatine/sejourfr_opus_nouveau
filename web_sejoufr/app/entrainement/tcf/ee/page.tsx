import {ProductionHub} from "@/app/_components/production/ProductionHub";
import {EE_CONFIG} from "@/app/_components/production/config";

export default function EeHubPage() {
  return <ProductionHub config={EE_CONFIG} />;
}
