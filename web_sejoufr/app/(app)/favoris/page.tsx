import type { Metadata } from "next";
import { FavorisView } from "../../_components/favoris/FavorisView";

export const metadata: Metadata = { title: "Mes favoris — SejourFR", robots: { index: false } };

export default function FavorisPage() {
  return <FavorisView />;
}
