import {CompetenceDetail} from "@/app/_components/competences/CompetenceDetail";
import {EE_CONFIG} from "@/app/_components/production/config";

export default function EECompetenceDetailPage() {
  return <CompetenceDetail config={EE_CONFIG} />;
}
