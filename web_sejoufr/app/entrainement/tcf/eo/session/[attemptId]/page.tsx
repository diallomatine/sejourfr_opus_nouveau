import {ProductionSession} from "@/app/_components/production/ProductionSession";
import {EO_CONFIG} from "@/app/_components/production/config";

export default function EoSessionPage() {
  return <ProductionSession config={EO_CONFIG} />;
}
