import {CompetenceResult} from "@/app/_components/competences/CompetenceResult";
import {EO_CONFIG} from "@/app/_components/production/config";

export default function EOCompetenceResultPage() {
  return <CompetenceResult config={EO_CONFIG} />;
}
