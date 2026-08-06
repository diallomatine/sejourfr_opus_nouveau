import {CompetencePrompt} from "@/app/_components/competences/CompetencePrompt";
import {EE_CONFIG} from "@/app/_components/production/config";

export default function EECompetencePromptPage() {
  return <CompetencePrompt config={EE_CONFIG} />;
}
