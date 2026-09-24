"use client";

import { CircleHelp, Headset, Info, Mail, Scale, Shield } from "lucide-react";
import type { ReactNode } from "react";
import { useAuth } from "@/lib/auth-context";
import { AIDE_HERO_TEXT, AIDE_HERO_TITLE, AIDE_SECTIONS, AIDE_TITLE } from "@/lib/aide";
import type { AideEntryKey } from "@/lib/aide";
import { COMPTE_BACK_PROFIL, COMPTE_PROFIL_HREF } from "@/lib/compte";
import { CompteCard, CompteHero, CompteRow, CompteShell } from "../compte/CompteParts";

const ICONS: Record<AideEntryKey, ReactNode> = {
  faq: <CircleHelp size={20} />,
  contact: <Mail size={20} />,
  cgu: <Scale size={20} />,
  confidentialite: <Shield size={20} />,
  "a-propos": <Info size={20} />,
};

/**
 * Le centre d'aide (`/aide`), miroir de `HelpCenterScreen` côté mobile :
 * accroche, « Ressources » (FAQ, contact) et « Documents légaux » (CGU,
 * confidentialité, à propos). Ouvert aux visiteurs : seul le retour vers le
 * Profil suppose un compte.
 */
export function AideView() {
  const { status } = useAuth();
  const connected = status === "authenticated";
  return (
    <CompteShell
      backHref={connected ? COMPTE_PROFIL_HREF : null}
      backLabel={COMPTE_BACK_PROFIL}
      title={AIDE_TITLE}
    >
      <CompteHero icon={<Headset size={22} />} title={AIDE_HERO_TITLE} text={AIDE_HERO_TEXT} />
      {AIDE_SECTIONS.map((section) => (
        <CompteCard key={section.title} title={section.title}>
          {section.entries.map((entry) => (
            <CompteRow
              key={entry.key}
              href={entry.href}
              icon={ICONS[entry.key]}
              tone={entry.tone}
              title={entry.title}
              sub={entry.sub}
            />
          ))}
        </CompteCard>
      ))}
    </CompteShell>
  );
}
