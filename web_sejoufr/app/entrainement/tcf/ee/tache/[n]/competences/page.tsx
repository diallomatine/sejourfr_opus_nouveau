import {CompetencesList} from "@/app/_components/competences/CompetencesList";
import {EE_CONFIG} from "@/app/_components/production/config";

export default function EECompetencesPage() {
  return <CompetencesList config={EE_CONFIG} />;
}
