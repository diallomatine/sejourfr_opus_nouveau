import {CompetencesList} from "@/app/_components/competences/CompetencesList";
import {EO_CONFIG} from "@/app/_components/production/config";

export default function EOCompetencesPage() {
  return <CompetencesList config={EO_CONFIG} />;
}
