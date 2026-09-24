import type { Metadata } from "next";
import { IdentiteForm } from "../../../../_components/compte/IdentiteForm";

export const metadata: Metadata = { title: "Nom et prénom — SejourFR", robots: { index: false } };

export default function IdentitePage() {
  return <IdentiteForm />;
}
