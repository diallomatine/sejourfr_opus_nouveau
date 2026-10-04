import type { IconName } from "../ui/Icon";

/** Compteur affiché en pastille à côté d'une entrée (lu par `AppLayout`). */
export type NavBadge = "questionsCivique" | "questionsTcf" | "audioDrafts" | "exampleAudio" | "unreadConversations";

export interface NavEntry {
  to: string;
  label: string;
  icon: IconName;
  badge?: NavBadge;
  /** Libellé du dernier segment du fil d'Ariane sur une route plus profonde (`/users/:id`). */
  detailLabel?: string;
  /** Route conservée (URL directe, fil d'Ariane) mais absente du menu. */
  hidden?: boolean;
}

export interface NavSection {
  label: string;
  items: NavEntry[];
}

/** L'unique liste des entrées de la console : barre latérale, tiroir mobile et fil d'Ariane. */
export const NAVIGATION: readonly NavSection[] = [
  {
    label: "Pilotage",
    items: [
      { to: "/dashboard", label: "Suivi", icon: "dashboard" },
      { to: "/dashboard/activity", label: "Activité", icon: "activity" },
    ],
  },
  {
    label: "Support",
    items: [{ to: "/users", label: "Utilisateurs", icon: "users", detailLabel: "Fiche" }],
  },
  {
    label: "Contenu",
    items: [
      { to: "/questions/civique", label: "Questions · Civique", icon: "landmark", badge: "questionsCivique" },
      { to: "/questions/tcf", label: "Questions · TCF", icon: "language", badge: "questionsTcf" },
      { to: "/themes", label: "Thématiques", icon: "tag", hidden: true },
      { to: "/skills", label: "Compétences EE/EO", icon: "target", hidden: true },
      { to: "/production-titles", label: "Titres sujets EE/EO", icon: "heading", hidden: true },
      { to: "/exams", label: "Examens blancs", icon: "clipboard", hidden: true },
    ],
  },
  {
    label: "Génération IA",
    items: [
      { to: "/audio-questions/generate", label: "Générer un audio", icon: "mic" },
      { to: "/audio-questions/import-co-image", label: "Importer des CO image", icon: "upload" },
      { to: "/audio-questions/review", label: "Audio à valider", icon: "checkCircle", badge: "audioDrafts" },
      { to: "/audio-questions/logs", label: "Audit générations", icon: "history" },
      { to: "/example-audio/review", label: "Audios exemples EO", icon: "volume", badge: "exampleAudio" },
      { to: "/productions-ia", label: "Productions IA", icon: "sparkles", detailLabel: "Production" },
      { to: "/calibration", label: "Calibration notation", icon: "sliders", hidden: true },
      { to: "/couts-ia", label: "Coût de l'IA", icon: "coins", hidden: true },
      { to: "/notions-civiques", label: "Notions civiques", icon: "book", hidden: true },
    ],
  },
  {
    label: "Commerce",
    items: [
      { to: "/plans", label: "Plans & tarifs", icon: "price" },
      { to: "/subscriptions", label: "Abonnements", icon: "card" },
    ],
  },
  {
    label: "Échanges",
    items: [{ to: "/conversations", label: "Conversations", icon: "message", badge: "unreadConversations" }],
  },
  {
    label: "Compte",
    items: [{ to: "/profil", label: "Mon profil", icon: "user", hidden: true }],
  },
];

/** Entrée de navigation qui couvre `pathname` (préfixe le plus long), pour le fil d'Ariane. */
export function navEntryFor(pathname: string): NavEntry | null {
  let best: NavEntry | null = null;
  for (const section of NAVIGATION) {
    for (const item of section.items) {
      const covers = pathname === item.to || pathname.startsWith(`${item.to}/`);
      if (covers && (!best || item.to.length > best.to.length)) best = item;
    }
  }
  return best;
}

/** Vrai si une autre entrée vit sous `entry.to` (`/dashboard/activity` sous `/dashboard`) : son lien ne s'allume alors que sur sa route exacte. */
export function hasNestedEntry(entry: NavEntry): boolean {
  return NAVIGATION.some((section) =>
    section.items.some((item) => item.to.startsWith(`${entry.to}/`)),
  );
}
