"use client";

import { KeyRound, Mail, UserRound } from "lucide-react";
import {
  COMPTE_BACK_PROFIL,
  COMPTE_EMAIL_HREF,
  COMPTE_IDENTITE_HREF,
  COMPTE_IDENTITY_EMPTY,
  COMPTE_INFO_LEAD,
  COMPTE_INFO_TITLE,
  COMPTE_INFORMATIONS_HREF,
  COMPTE_MOT_DE_PASSE_HREF,
  COMPTE_PASSWORD_MASK,
  COMPTE_PROFIL_HREF,
  COMPTE_ROW_EMAIL,
  COMPTE_ROW_IDENTITY,
  COMPTE_ROW_PASSWORD,
  compteEmailProviderNote,
  compteIsLocal,
  comptePasswordProviderNote,
  compteProviderManaged,
} from "@/lib/compte";
import { CompteAuth, CompteCard, CompteFootnote, CompteRow, CompteShell } from "./CompteParts";

/**
 * « Mes informations » (`/profil/informations`) : les trois données du compte,
 * chacune ouvrant sa page d'édition. Un compte Google / Apple garde son nom
 * modifiable ; e-mail et mot de passe y sont en lecture, avec la raison.
 * Miroir mobile : `PersonalInfoScreen`.
 */
export function InformationsView() {
  return (
    <CompteAuth next={COMPTE_INFORMATIONS_HREF}>
      {(user) => {
        const isLocal = compteIsLocal(user.authProvider);
        const fullName = [user.firstName, user.lastName].filter(Boolean).join(" ").trim();
        return (
          <CompteShell
            backHref={COMPTE_PROFIL_HREF}
            backLabel={COMPTE_BACK_PROFIL}
            title={COMPTE_INFO_TITLE}
            lead={COMPTE_INFO_LEAD}
          >
            <CompteCard>
              <CompteRow
                href={COMPTE_IDENTITE_HREF}
                icon={<UserRound size={20} />}
                title={COMPTE_ROW_IDENTITY}
                sub={fullName || COMPTE_IDENTITY_EMPTY}
              />
              <CompteRow
                href={isLocal ? COMPTE_EMAIL_HREF : undefined}
                icon={<Mail size={20} />}
                tone={isLocal ? "blue" : "muted"}
                title={COMPTE_ROW_EMAIL}
                sub={user.email}
              />
              <CompteRow
                href={isLocal ? COMPTE_MOT_DE_PASSE_HREF : undefined}
                icon={<KeyRound size={20} />}
                tone={isLocal ? "blue" : "muted"}
                title={COMPTE_ROW_PASSWORD}
                sub={isLocal ? COMPTE_PASSWORD_MASK : compteProviderManaged(user.authProvider)}
              />
            </CompteCard>
            {!isLocal ? (
              <CompteFootnote>
                {compteEmailProviderNote(user.authProvider)}
                <br />
                {comptePasswordProviderNote(user.authProvider)}
              </CompteFootnote>
            ) : null}
          </CompteShell>
        );
      }}
    </CompteAuth>
  );
}
