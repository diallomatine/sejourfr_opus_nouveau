import {ProductionInputPage} from "@/app/_components/production/ProductionInputPage";
import {EO_CONFIG} from "@/app/_components/production/config";

export default function EoRecordingPage() {
  return <ProductionInputPage config={EO_CONFIG} />;
}
