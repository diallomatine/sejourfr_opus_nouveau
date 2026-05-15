import { redirect } from "next/navigation";

// Ancienne URL : on redirige vers la vitrine des 40 examens blancs (Lot 4).
// Les liens externes (emails, partages) continuent de fonctionner.
export default function LegacyExamenBlancPage() {
  redirect("/examens-blancs");
}
