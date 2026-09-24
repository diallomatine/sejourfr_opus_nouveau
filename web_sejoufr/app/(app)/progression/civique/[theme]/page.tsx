import type {Metadata} from "next";
import {ProgressionThemeView} from "@/app/_components/progression/ProgressionThemeView";

export const metadata: Metadata = {
  title: "Ma progression par thème — SejourFR",
  description: "Vos examens blancs sur un thème de l'examen civique, face au seuil de réussite.",
};

/** Le segment est le slug du thème (`themeSlug(code)`) ; un UUID est accepté. */
export default function ProgressionThemePage() {
  return <ProgressionThemeView />;
}
