import type { Metadata } from "next";
import { AideView } from "../../_components/aide/AideView";

export const metadata: Metadata = {
  title: "Centre d'aide — SejourFR",
  description: "FAQ, contact, conditions d'utilisation et politique de confidentialité de SejourFR.",
  alternates: { canonical: "/aide" },
};

export default function AidePage() {
  return <AideView />;
}
