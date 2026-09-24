import type {Metadata} from "next";
import {ProgressionTcfView} from "@/app/_components/progression/ProgressionTcfView";

export const metadata: Metadata = {
  title: "Ma progression TCF IRN — SejourFR",
  description: "Votre niveau global estimé, vos quatre épreuves et vos examens blancs complets.",
};

export default function ProgressionTcfPage() {
  return <ProgressionTcfView />;
}
