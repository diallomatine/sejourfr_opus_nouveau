import {ProductionInputPage} from "@/app/_components/production/ProductionInputPage";
import {EE_CONFIG} from "@/app/_components/production/config";

export default function EeRedactionPage() {
  return <ProductionInputPage config={EE_CONFIG} />;
}
