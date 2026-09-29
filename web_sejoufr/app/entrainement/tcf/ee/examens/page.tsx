import {ProductionExams} from "@/app/_components/production/ProductionExams";
import {EE_CONFIG} from "@/app/_components/production/config";

export default function EeExamsPage() {
  return <ProductionExams config={EE_CONFIG} />;
}
