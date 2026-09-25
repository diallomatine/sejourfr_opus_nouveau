import type { Metadata } from "next";
import { NotificationsView } from "../../../_components/compte/NotificationsView";

export const metadata: Metadata = { title: "Notifications par e-mail — SejourFR", robots: { index: false } };

export default function NotificationsPage() {
  return <NotificationsView />;
}
