import type { Metadata } from "next";
import { InformationsView } from "../../../_components/compte/InformationsView";

export const metadata: Metadata = { title: "Mes informations — SejourFR", robots: { index: false } };

export default function InformationsPage() {
  return <InformationsView />;
}
