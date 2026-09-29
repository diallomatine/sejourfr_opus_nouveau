import type { Metadata } from "next";
import { MotDePasseForm } from "../../../../_components/compte/MotDePasseForm";

export const metadata: Metadata = { title: "Mot de passe — SejourFR", robots: { index: false } };

export default function MotDePassePage() {
  return <MotDePasseForm />;
}
