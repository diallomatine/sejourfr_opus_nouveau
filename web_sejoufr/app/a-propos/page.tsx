import type {Metadata} from "next";
import {LegalPageLayout} from "@/components/legal/LegalPageLayout";
import {LegalSection} from "@/components/legal/LegalSection";
import {LegalCallout} from "@/components/legal/LegalCallout";
import {SITE} from "@/lib/site";

export const metadata: Metadata = {
    title: "À propos | SejourFR",
    description:
        "SejourFR est un outil d'entraînement indépendant aux examens civique et TCF IRN, non affilié au gouvernement français. Liens vers les sources officielles.",
    alternates: {canonical: "/a-propos"},
    openGraph: {
        title: "À propos — SejourFR",
        description:
            "Outil d'entraînement indépendant, non affilié à l'État français. Sources officielles : service-public.fr, immigration.interieur.gouv.fr, France Éducation International, OFII.",
        type: "website",
        url: `${SITE.url}/a-propos`,
    },
    robots: {index: true, follow: true},
};

const SECTIONS = [
    {id: "section-1", title: "Qu'est-ce que SejourFR ?"},
    {id: "section-2", title: "Indépendance et non-affiliation"},
    {id: "section-3", title: "Sources officielles"},
];

const OFFICIAL_LINKS = [
    {
        label: "Démarches séjour / naturalisation",
        host: "service-public.fr",
        url: "https://www.service-public.fr",
    },
    {
        label: "Examen civique — ministère de l'Intérieur",
        host: "immigration.interieur.gouv.fr",
        url: "https://www.immigration.interieur.gouv.fr",
    },
    {
        label: "TCF — France Éducation International",
        host: "france-education-international.fr",
        url: "https://www.france-education-international.fr",
    },
    {
        label: "OFII — Office français de l'immigration et de l'intégration",
        host: "ofii.fr",
        url: "https://www.ofii.fr",
    },
];

export default function AProposPage() {
    return (
        <LegalPageLayout
            title="À propos de SejourFR"
            description="Qui nous sommes, ce que la plateforme fait — et surtout ce qu'elle n'est pas."
            sections={SECTIONS}
            currentPath="/a-propos"
        >
            <LegalSection id="section-1" number={1} title="Qu'est-ce que SejourFR ?">
                <p>
                    SejourFR est une plateforme d'<strong>entraînement en ligne</strong>{" "}
                    aux examens exigés pour les démarches de séjour en France : l'examen{" "}
                    <strong>civique</strong> (carte de séjour pluriannuelle, carte de
                    résident, naturalisation) et le <strong>TCF IRN</strong> (niveaux A2,
                    B1, B2). Elle propose des QCM corrigés, des examens blancs en
                    conditions réelles et des productions écrites et orales évaluées.
                </p>
                <p>
                    Les questions et passages proposés sont conçus par l'équipe SejourFR
                    à partir des référentiels et thématiques officiels publiés, sans
                    reproduction des questions officielles de ces épreuves.
                </p>
            </LegalSection>

            <LegalSection id="section-2" number={2} title="Indépendance et non-affiliation">
                <LegalCallout tone="info" title="Outil indépendant">
                    <p>
                        SejourFR est un outil d'entraînement indépendant. Cette
                        plateforme n'est affiliée ni au gouvernement français, ni à
                        l'OFII, ni au ministère de l'Intérieur, ni à France Éducation
                        International. Elle ne garantit pas la réussite aux examens.
                    </p>
                </LegalCallout>
                <p>
                    Concrètement : SejourFR ne fait passer aucune épreuve officielle et
                    ne délivre aucune attestation. L'inscription aux examens (civique ou
                    TCF) se fait exclusivement auprès des organismes et centres agréés
                    par l'État. Pour toute démarche administrative, référez-vous aux
                    sources officielles listées ci-dessous.
                </p>
            </LegalSection>

            <LegalSection id="section-3" number={3} title="Sources officielles">
                <p>
                    Les informations gouvernementales de référence (procédures,
                    inscription aux épreuves, textes en vigueur) sont publiées sur les
                    sites officiels suivants :
                </p>
                <ul className="official-links">
                    {OFFICIAL_LINKS.map((l) => (
                        <li key={l.url}>
                            <a href={l.url} target="_blank" rel="noopener noreferrer">
                                {l.label}
                            </a>{" "}
                            <span className="official-links-host">{l.host}</span>
                        </li>
                    ))}
                </ul>
            </LegalSection>

            <style>{`
        .official-links {
          list-style: none !important;
          padding-left: 0 !important;
          gap: 12px !important;
        }
        .official-links li::marker {
          content: none;
        }
        .official-links-host {
          display: inline-block;
          margin-left: 4px;
          font-family: var(--font-mono);
          font-size: 12px;
          color: var(--color-muted);
          letter-spacing: 0.02em;
        }
      `}</style>
        </LegalPageLayout>
    );
}
