import type { Metadata } from "next";
import Link from "next/link";
import { LegalPageLayout } from "@/components/legal/LegalPageLayout";
import { LegalSection } from "@/components/legal/LegalSection";
import { Placeholder } from "@/components/legal/Placeholder";
import { LEGAL_INFO, isCompany } from "@/content/legal/legal-info";
import { SITE } from "@/lib/site";

export const metadata: Metadata = {
  title: "Mentions légales | SejourFR",
  description:
    "Mentions légales du site SejourFR : éditeur, hébergeur, propriété intellectuelle, responsabilité.",
  alternates: { canonical: "/mentions-legales" },
  openGraph: {
    title: "Mentions légales — SejourFR",
    description:
      "Mentions légales conformes à la LCEN : éditeur, directeur de publication, hébergeur.",
    type: "website",
    url: `${SITE.url}/mentions-legales`,
  },
  robots: { index: true, follow: true },
};

const SECTIONS = [
  { id: "article-1", title: "Éditeur du site" },
  { id: "article-2", title: "Directeur de la publication" },
  { id: "article-3", title: "Hébergeur" },
  { id: "article-4", title: "Propriété intellectuelle" },
  { id: "article-5", title: "Liens hypertextes" },
  { id: "article-6", title: "Responsabilité" },
  { id: "article-7", title: "Loi applicable et juridiction" },
  { id: "article-8", title: "Contact" },
];

export default function MentionsLegalesPage() {
  const { editor, host } = LEGAL_INFO;
  const company = isCompany(editor.legalForm);

  return (
    <LegalPageLayout
      title="Mentions légales"
      description="Informations légales obligatoires en vertu de l'article 6 III-1 de la loi LCEN du 21 juin 2004."
      sections={SECTIONS}
      currentPath="/mentions-legales"
    >
      <LegalSection id="article-1" number={1} title="Éditeur du site">
        {company ? (
          <p>
            Le site SejourFR, accessible à l'adresse{" "}
            <a href={SITE.url}>{SITE.url.replace(/^https?:\/\//, "")}</a>{" "}
            (ci-après le « Site »), est édité par{" "}
            <strong>
              <Placeholder value={editor.legalName} label="Raison sociale" />
            </strong>
            , {editor.legalForm} au capital social de{" "}
            <Placeholder value={editor.capital} label="Capital" />, immatriculée au{" "}
            <Placeholder value={editor.rcs} label="RCS" />, dont le siège social est
            situé au <Placeholder value={editor.address} label="Adresse" />.
          </p>
        ) : (
          <p>
            Le site SejourFR, accessible à l'adresse{" "}
            <a href={SITE.url}>{SITE.url.replace(/^https?:\/\//, "")}</a>{" "}
            (ci-après le « Site »), est édité par{" "}
            <strong>
              <Placeholder value={editor.legalName} label="Prénom + Nom" />
            </strong>
            , exerçant en tant qu'<strong>Entrepreneur Individuel (EI)</strong>,
            domicilié(e) au{" "}
            <Placeholder value={editor.address} label="Adresse" />.
          </p>
        )}
        <p>
          SejourFR édite un service d'entraînement en ligne aux examens. La
          Plateforme propose deux modules : un module <strong>Civique</strong>{" "}
          (préparation à l'examen civique pour les parcours CSP, CR et NAT) et
          un module <strong>TCF</strong> (préparation aux compétences
          linguistiques évaluées par le Test de Connaissance du Français,
          niveaux A2 à B2). SejourFR <strong>ne se substitue pas aux
          organismes officiels habilités</strong> à faire passer ces épreuves
          ou à délivrer les attestations correspondantes.
        </p>

        <ul className="legal-list-plain">
          <li>
            <strong>SIRET :</strong>{" "}
            <Placeholder value={editor.siret} label="14 chiffres" />
          </li>
          <li>
            <strong>SIREN :</strong>{" "}
            <Placeholder value={editor.siren} label="9 chiffres" />
          </li>
          {(company || editor.vatNumber) && (
            <li>
              <strong>N° de TVA intracommunautaire :</strong>{" "}
              {editor.vatNumber ? (
                editor.vatNumber
              ) : (
                <span className="legal-italic-muted">
                  non assujetti (franchise en base de TVA)
                </span>
              )}
            </li>
          )}
          <li>
            <strong>Email :</strong>{" "}
            <a href={`mailto:${editor.email}`}>{editor.email}</a>
          </li>
          <li>
            <strong>Téléphone :</strong>{" "}
            <Placeholder value={editor.phone} label="Téléphone" />
          </li>
        </ul>
      </LegalSection>

      <LegalSection id="article-2" number={2} title="Directeur de la publication">
        <p>
          Le directeur de la publication est{" "}
          <strong>
            <Placeholder
              value={editor.publicationDirector}
              label="Nom du directeur"
            />
          </strong>
          , agissant en qualité de représentant légal de l'éditeur.
        </p>
      </LegalSection>

      <LegalSection id="article-3" number={3} title="Hébergeur">
        <p>
          Le Site est hébergé par <strong>{host.name}</strong>, dont le siège est
          situé au {host.address}.
        </p>
        <ul className="legal-list-plain">
          <li>
            <strong>Téléphone :</strong>{" "}
            <Placeholder value={host.phone} label="Téléphone hébergeur" />
          </li>
          <li>
            <strong>Site web :</strong>{" "}
            <a href={host.website} target="_blank" rel="noopener noreferrer">
              {host.website.replace(/^https?:\/\//, "")}
            </a>
          </li>
        </ul>
      </LegalSection>

      <LegalSection id="article-4" number={4} title="Propriété intellectuelle">
        <p>
          L'ensemble des contenus présents sur le Site (textes, images, logos,
          vidéos, illustrations, icônes, sons, marques, charte graphique, code
          source, base de données, structure du site) est la propriété exclusive
          de SejourFR ou de ses partenaires, et est protégé par le droit d'auteur
          et le droit des marques en vertu des articles L.111-1 et suivants du
          Code de la propriété intellectuelle.
        </p>
        <p>
          Toute reproduction, représentation, modification, publication,
          transmission, dénaturation, totale ou partielle du Site ou de son
          contenu, par quelque procédé que ce soit, et sur quelque support que
          ce soit, est interdite sans l'autorisation écrite et préalable de
          SejourFR. Toute exploitation non autorisée du Site ou de son contenu
          pourra faire l'objet de poursuites civiles ou pénales (article L.335-2
          du Code de la propriété intellectuelle).
        </p>
        <p>
          Les questions, énoncés, corrections et passages de compréhension
          écrite proposés sur le Site sont <strong>conçus par l'équipe
          SejourFR à partir des référentiels et thématiques officiels
          publiés</strong> par les organismes compétents (Ministère de
          l'Intérieur pour l'examen civique, France Éducation International
          pour le TCF), <strong>sans reproduction des questions officielles</strong>{" "}
          de ces épreuves. Les questions officielles demeurent la propriété de
          leurs ayants droit respectifs.
        </p>
      </LegalSection>

      <LegalSection id="article-5" number={5} title="Liens hypertextes">
        <p>
          Le Site peut contenir des liens vers d'autres sites internet. SejourFR
          n'exerce aucun contrôle sur ces sites et n'assume aucune responsabilité
          quant à leur contenu, leurs politiques de confidentialité ou leurs
          pratiques.
        </p>
        <p>
          La création de liens hypertextes vers le Site est autorisée à condition :
        </p>
        <ul>
          <li>
            de ne pas utiliser la technique du <em>framing</em> ou du{" "}
            <em>deep linking</em> sans autorisation,
          </li>
          <li>de mentionner explicitement la source,</li>
          <li>
            de ne pas porter atteinte à l'image ni à la réputation de SejourFR.
          </li>
        </ul>
      </LegalSection>

      <LegalSection id="article-6" number={6} title="Responsabilité">
        <p>
          Les informations publiées sur le Site sont fournies à titre indicatif
          et à des fins d'entraînement. SejourFR s'efforce d'assurer
          l'exactitude et la mise à jour des contenus diffusés, notamment ceux
          relatifs à l'examen civique et au TCF, mais ne peut garantir leur
          exhaustivité ni leur conformité aux dernières évolutions légales ou
          aux référentiels officiels en vigueur.
        </p>
        <p>
          <strong>SejourFR est une plateforme d'entraînement indépendante.</strong>{" "}
          Elle n'est pas affiliée au Ministère de l'Intérieur, à France
          Éducation International, ni à aucun autre organisme officiel agréé
          pour faire passer l'examen civique ou le TCF. Concrètement : pour
          l'<strong>examen civique</strong>, les épreuves sont organisées par
          les centres agréés (notamment ceux opérés par France Éducation
          International et la Chambre de commerce et d'industrie de Paris
          Île-de-France) selon le titre demandé ; pour le <strong>TCF</strong>,
          par France Éducation International et son réseau de centres agréés.
          SejourFR ne se substitue à aucun de ces organismes.
        </p>
        <p>
          L'utilisateur est invité à consulter les sources officielles{" "}
          (<a href="https://www.service-public.fr" target="_blank" rel="noopener noreferrer">service-public.fr</a>,{" "}
          <a href="https://www.immigration.interieur.gouv.fr" target="_blank" rel="noopener noreferrer">immigration.interieur.gouv.fr</a>,{" "}
          <a href="https://www.france-education-international.fr" target="_blank" rel="noopener noreferrer">france-education-international.fr</a>)
          pour toute démarche administrative officielle et pour l'inscription
          aux épreuves.
        </p>
      </LegalSection>

      <LegalSection id="article-7" number={7} title="Loi applicable et juridiction compétente">
        <p>
          Les présentes mentions légales sont régies par le droit français. En cas
          de litige et après échec de toute tentative de recherche d'une solution
          amiable, les tribunaux français seront seuls compétents.
        </p>
      </LegalSection>

      <LegalSection id="article-8" number={8} title="Contact">
        <p>
          Pour toute question relative aux présentes mentions légales, vous pouvez
          nous contacter :
        </p>
        <ul>
          <li>
            Par email :{" "}
            <a href={`mailto:${editor.email}`}>{editor.email}</a>
          </li>
          <li>
            Via notre <Link href="/contact">formulaire de contact</Link>.
          </li>
        </ul>
      </LegalSection>

      <style>{`
        .legal-list-plain {
          list-style: none !important;
          padding-left: 0 !important;
          gap: 8px !important;
        }
        .legal-list-plain li::marker {
          content: none;
        }
        .legal-italic-muted {
          color: var(--color-muted);
          font-style: italic;
        }
      `}</style>
    </LegalPageLayout>
  );
}
