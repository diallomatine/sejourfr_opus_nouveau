import {ProductionHub} from "@/app/_components/production/ProductionHub";
import {EO_CONFIG} from "@/app/_components/production/config";

export default function EoHubPage() {
  return <ProductionHub config={EO_CONFIG} />;
}
