import {CompetencePrompt} from "@/app/_components/competences/CompetencePrompt";
import {EO_CONFIG} from "@/app/_components/production/config";

export default function EOCompetencePromptPage() {
  return <CompetencePrompt config={EO_CONFIG} />;
}
