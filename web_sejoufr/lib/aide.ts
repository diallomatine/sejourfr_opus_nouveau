/**
 * Le centre d'aide (`/aide`).
 *
 * 🛑 **Miroir mot pour mot** de
 * `mobile_sejourfr/lib/screens/help/help_center_labels.dart` : mêmes
 * sections, mêmes entrées, dans le même ordre, avec les mêmes textes. Le
 * mobile ouvre FAQ / CGU / confidentialité dans une WebView sur ces mêmes
 * pages web, et le contact dans un écran natif : la destination change de
 * forme, jamais de contenu.
 */

export const AIDE_HREF = "/aide";

export const AIDE_TITLE = "Centre d'aide";
export const AIDE_HERO_TITLE = "Une question ?";
export const AIDE_HERO_TEXT = "L'équipe SejourFR vous répond sous 24 h ouvrées.";

export type AideEntryKey = "faq" | "contact" | "cgu" | "confidentialite" | "a-propos";
export type AideTone = "blue" | "red" | "muted";

export type AideEntry = {
  key: AideEntryKey;
  title: string;
  sub: string;
  href: string;
  tone: AideTone;
};

export type AideSection = { title: string; entries: AideEntry[] };

export const AIDE_SECTIONS: AideSection[] = [
  {
    title: "Ressources",
    entries: [
      {
        key: "faq",
        title: "Aide & FAQ",
        sub: "Réponses aux questions fréquentes sur l'examen et la procédure.",
        href: "/faq",
        tone: "blue",
      },
      {
        key: "contact",
        title: "Nous contacter",
        sub: "Un message à l'équipe — réponse sous 24 h ouvrées.",
        href: "/contact",
        tone: "red",
      },
    ],
  },
  {
    title: "Documents légaux",
    entries: [
      {
        key: "cgu",
        title: "Conditions d'utilisation",
        sub: "Les règles d'usage du service.",
        href: "/cgu",
        tone: "muted",
      },
      {
        key: "confidentialite",
        title: "Politique de confidentialité",
        sub: "Ce qu'on collecte, pourquoi et comment.",
        href: "/confidentialite",
        tone: "muted",
      },
      {
        key: "a-propos",
        title: "À propos de SejourFR",
        sub: "Outil indépendant, non affilié à l'État. Sources officielles.",
        href: "/a-propos",
        tone: "blue",
      },
    ],
  },
];
