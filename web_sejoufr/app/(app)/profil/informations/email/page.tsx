import type { Metadata } from "next";
import { EmailForm } from "../../../../_components/compte/EmailForm";

export const metadata: Metadata = { title: "Adresse e-mail — SejourFR", robots: { index: false } };

export default function EmailPage() {
  return <EmailForm />;
}
