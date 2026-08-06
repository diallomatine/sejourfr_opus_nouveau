import {CompetenceResult} from "@/app/_components/competences/CompetenceResult";
import {EE_CONFIG} from "@/app/_components/production/config";

export default function EECompetenceResultPage() {
  return <CompetenceResult config={EE_CONFIG} />;
}
