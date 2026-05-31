import {ProductionSession} from "@/app/_components/production/ProductionSession";
import {EE_CONFIG} from "@/app/_components/production/config";

export default function EeSessionPage() {
  return <ProductionSession config={EE_CONFIG} />;
}
