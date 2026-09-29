import {ProductionExams} from "@/app/_components/production/ProductionExams";
import {EO_CONFIG} from "@/app/_components/production/config";

export default function EoExamsPage() {
  return <ProductionExams config={EO_CONFIG} />;
}
