import type { Metadata } from "next";
import Link from "next/link";
import { LegalPageLayout } from "@/components/legal/LegalPageLayout";
import { LegalSection, LegalSubsection } from "@/components/legal/LegalSection";
import { LegalCallout } from "@/components/legal/LegalCallout";
import { LegalTable } from "@/components/legal/LegalTable";
import { Placeholder } from "@/components/legal/Placeholder";
import { LEGAL_INFO } from "@/content/legal/legal-info";
import { SITE } from "@/lib/site";

export const metadata: Metadata = {
  title: "Politique de confidentialité | SéjourFR",
  description:
    "Comment SéjourFR collecte, utilise et protège vos données personnelles conformément au RGPD et à la loi Informatique et Libertés.",
  alternates: { canonical: "/confidentialite" },
  openGraph: {
    title: "Politique de confidentialité — SéjourFR",
    description:
      "Politique RGPD complète : données collectées, finalités, durées de conservation, sous-traitants, droits, CNIL.",
    type: "website",
    url: `${SITE.url}/confidentialite`,
  },
  robots: { index: true, follow: true },
};

const SECTIONS = [
  { id: "preambule", title: "Préambule" },
  { id: "article-1", title: "Responsable du traitement" },
  { id: "article-2", title: "Délégué à la Protection des Données" },
  { id: "article-3", title: "Données collectées" },
  { id: "article-4", title: "Finalités et bases légales" },
  { id: "article-5", title: "Durée de conservation" },
  { id: "article-6", title: "Destinataires de vos données" },
  { id: "article-7", title: "Transferts hors UE" },
  { id: "article-8", title: "Cookies et traceurs" },
  { id: "article-9", title: "Vos droits" },
  { id: "article-10", title: "Sécurité des données" },
  { id: "article-11", title: "Violation de données" },
  { id: "article-12", title: "Données des mineurs" },
  { id: "article-13", title: "Modifications de la politique" },
  { id: "article-14", title: "Contact" },
];

export default function ConfidentialitePage() {
  const { editor, dpo, subProcessors } = LEGAL_INFO;

  // Tous nos sous-traitants actuels sont en UE → on affiche la version
  // "pas de transfert hors UE". À adapter si on ajoute un outil non-UE.
  const allInEu = subProcessors.every((sp) => sp.country.includes("UE"));

  return (
    <LegalPageLayout
      title="Politique de confidentialité"
      description="Comment nous collectons, utilisons, conservons et protégeons vos données personnelles, conformément au RGPD."
      sections={SECTIONS}
      currentPath="/confidentialite"
    >
      <section id="preambule" className="legal-section">
        <h2 className="legal-section-title">
          <span className="legal-section-num">Préambule</span>
        </h2>
        <div className="legal-section-body">
          <p>
            La présente Politique de confidentialité décrit comment{" "}
            <strong>
              <Placeholder value={editor.legalName} label="Raison sociale" />
            </strong>{" "}
            (ci-après « <strong>SéjourFR</strong> » ou « nous ») collecte,
            utilise, conserve et protège vos données personnelles dans le cadre
            de votre utilisation de la plateforme accessible à l'adresse{" "}
            <a href={SITE.url}>{SITE.url.replace(/^https?:\/\//, "")}</a>{" "}
            (ci-après la « <strong>Plateforme</strong> »).
          </p>
          <p>
            Nous nous engageons à protéger votre vie privée conformément au{" "}
            <strong>Règlement (UE) 2016/679 du 27 avril 2016</strong> (« RGPD »)
            et à la <strong>loi française n° 78-17 du 6 janvier 1978 modifiée</strong>{" "}
            relative à l'informatique, aux fichiers et aux libertés.
          </p>
          <p>
            Cette politique a vocation à être claire et accessible. Si une
            formulation vous semble obscure, n'hésitez pas à{" "}
            <Link href="/contact">nous contacter</Link>.
          </p>
        </div>
      </section>

      <LegalSection id="article-1" number={1} title="Responsable du traitement">
        <p>Le responsable du traitement de vos données personnelles est :</p>
        <ul>
          <li>
            <strong>
              <Placeholder value={editor.legalName} label="Raison sociale" />
            </strong>
          </li>
          <li>
            <Placeholder value={editor.address} label="Adresse" />
          </li>
          <li>
            SIRET : <Placeholder value={editor.siret} label="SIRET" />
          </li>
          <li>
            Email :{" "}
            <a href="mailto:support@sejourfr.fr">support@sejourfr.fr</a>
          </li>
        </ul>
      </LegalSection>

      <LegalSection id="article-2" number={2} title="Délégué à la Protection des Données (DPO)">
        {dpo.designated ? (
          <>
            <p>
              Conformément au RGPD, nous avons désigné un Délégué à la
              Protection des Données (DPO) que vous pouvez contacter pour toute
              question relative à vos données personnelles :
            </p>
            <ul>
              {dpo.name && (
                <li>
                  <strong>Nom :</strong> {dpo.name}
                </li>
              )}
              <li>
                <strong>Email :</strong>{" "}
                <a href={`mailto:${dpo.email}`}>{dpo.email}</a>
              </li>
            </ul>
          </>
        ) : (
          <p>
            Bien que la désignation d'un DPO ne soit pas obligatoire pour notre
            structure (entreprise individuelle, traitements ne relevant pas des
            catégories rendant le DPO obligatoire au sens de l'article 37 RGPD),
            vous pouvez nous contacter pour toute question relative à vos
            données personnelles à l'adresse{" "}
            <a href={`mailto:${dpo.email}`}>{dpo.email}</a>.
          </p>
        )}
      </LegalSection>

      <LegalSection id="article-3" number={3} title="Données collectées">
        <LegalSubsection number="3.1" title="Données fournies directement par vous">
          <p>
            Lors de la création de votre compte et de votre utilisation de la
            Plateforme, nous collectons :
          </p>
          <LegalTable
            columns={["Donnée", "Caractère", "Finalité"]}
            rows={[
              [
                "Nom et prénom",
                "Obligatoire",
                "Identification, communications",
              ],
              [
                "Adresse email",
                "Obligatoire",
                "Identification, support, notifications",
              ],
              [
                "Mot de passe",
                "Obligatoire (hashé en base via BCrypt)",
                "Authentification",
              ],
              [
                "Données de paiement",
                "Obligatoire pour Premium",
                "Traitement des paiements (via Stripe)",
              ],
              [
                "Adresse postale",
                "Facultative",
                "Facturation Premium si demandée",
              ],
            ]}
          />
        </LegalSubsection>

        <LegalSubsection number="3.2" title="Données collectées automatiquement">
          <p>
            Lors de votre utilisation de la Plateforme, nous collectons
            automatiquement :
          </p>
          <ul>
            <li>
              <strong>Données de connexion</strong> : adresse IP, type et
              version du navigateur, système d'exploitation, langue, fuseau
              horaire, dates et heures de connexion ;
            </li>
            <li>
              <strong>Données de navigation</strong> : pages visitées, durée de
              visite, parcours sur la Plateforme ;
            </li>
            <li>
              <strong>Données d'utilisation des Services</strong> : questions
              consultées, résultats aux examens blancs passés,
              progression par catégorie, score moyen, historique d'activité.
            </li>
          </ul>
        </LegalSubsection>

        <LegalSubsection number="3.3" title="Cookies">
          <p>
            Nous utilisons des cookies dans les conditions décrites à
            l'Article 8 ci-dessous.
          </p>
        </LegalSubsection>
      </LegalSection>

      <LegalSection id="article-4" number={4} title="Finalités et bases légales du traitement">
        <p>
          Conformément à l'article 6 du RGPD, chaque traitement de vos données
          repose sur une <strong>base légale</strong> précise :
        </p>
        <LegalTable
          columns={["Finalité du traitement", "Base légale"]}
          rows={[
            ["Création et gestion de votre compte", "Exécution du contrat (art. 6.1.b)"],
            ["Fourniture des services payants", "Exécution du contrat (art. 6.1.b)"],
            ["Traitement des paiements", "Exécution du contrat (art. 6.1.b)"],
            [
              "Envoi d'emails transactionnels (confirmation, accusé de réception)",
              "Exécution du contrat (art. 6.1.b)",
            ],
            [
              "Suivi statistique anonymisé de la fréquentation",
              "Intérêt légitime (art. 6.1.f)",
            ],
            ["Envoi de newsletters et actualités", "Consentement (art. 6.1.a)"],
            [
              "Réponse à vos demandes (formulaire de contact)",
              "Intérêt légitime (art. 6.1.f)",
            ],
            ["Conservation des factures", "Obligation légale (art. 6.1.c)"],
            ["Lutte contre la fraude et la sécurité", "Intérêt légitime (art. 6.1.f)"],
          ]}
        />
      </LegalSection>

      <LegalSection id="article-5" number={5} title="Durée de conservation des données">
        <p>
          Conformément au principe de <strong>limitation de la conservation</strong>{" "}
          posé par le RGPD :
        </p>
        <LegalTable
          columns={["Type de données", "Durée de conservation"]}
          rows={[
            [
              "Données de compte (actif)",
              "Durée de l'inscription + 3 ans après dernière activité",
            ],
            [
              "Données de progression et résultats",
              "Durée de l'inscription + 3 ans après dernière activité",
            ],
            [
              "Données de facturation",
              "10 ans (obligation comptable et fiscale)",
            ],
            ["Logs de connexion", "12 mois"],
            ["Cookies", "Selon catégorie (voir Article 8)"],
            ["Messages de contact", "3 ans après dernier échange"],
            ["Newsletters", "Jusqu'au retrait du consentement, puis 3 ans"],
          ]}
        />
        <p>
          À l'issue de ces délais, vos données sont{" "}
          <strong>supprimées définitivement</strong> ou{" "}
          <strong>anonymisées</strong> de manière irréversible.
        </p>
      </LegalSection>

      <LegalSection id="article-6" number={6} title="Destinataires de vos données">
        <p>
          Vos données sont accessibles aux seules personnes habilitées de
          SéjourFR ayant besoin d'y accéder dans le cadre de leurs missions.
        </p>
        <p>
          Nous faisons appel à des <strong>sous-traitants</strong> au sens du
          RGPD pour certaines opérations. Ces sous-traitants sont liés à
          SéjourFR par des accords de traitement (DPA) conformes à l'article 28
          du RGPD :
        </p>
        <LegalTable
          columns={["Sous-traitant", "Finalité", "Pays"]}
          rows={subProcessors.map((sp) => [sp.name, sp.purpose, sp.country])}
        />
        <p className="legal-note-italic">
          Aucune de vos données n'est vendue à des tiers à des fins
          commerciales.
        </p>
      </LegalSection>

      <LegalSection id="article-7" number={7} title="Transferts hors Union européenne">
        {allInEu ? (
          <p>
            Vos données sont traitées exclusivement au sein de l'Union
            européenne. Aucun transfert hors UE n'est effectué.
          </p>
        ) : (
          <>
            <p>
              Certains de nos sous-traitants peuvent être amenés à traiter vos
              données en dehors de l'Union européenne. Dans ce cas, des
              garanties appropriées sont mises en place conformément aux
              articles 44 et suivants du RGPD :
            </p>
            <ul>
              <li>
                <strong>Clauses contractuelles types</strong> approuvées par la
                Commission européenne ;
              </li>
              <li>
                <strong>Décision d'adéquation</strong> de la Commission
                européenne pour les pays jugés offrant un niveau de protection
                adéquat ;
              </li>
              <li>
                <strong>Mesures techniques complémentaires</strong>{" "}
                (chiffrement, pseudonymisation).
              </li>
            </ul>
          </>
        )}
      </LegalSection>

      <LegalSection id="article-8" number={8} title="Cookies et traceurs">
        <LegalSubsection number="8.1" title="Qu'est-ce qu'un cookie ?">
          <p>
            Un cookie est un petit fichier déposé sur votre terminal
            (ordinateur, tablette, smartphone) lors de la consultation d'un site
            web. Il permet de mémoriser des informations sur votre visite.
          </p>
        </LegalSubsection>

        <LegalSubsection number="8.2" title="Cookies utilisés sur la Plateforme">
          <LegalTable
            columns={["Type", "Finalité", "Consentement", "Durée"]}
            rows={[
              [
                "Strictement nécessaires",
                "Connexion, sécurité",
                "Non (exempt)",
                "Session ou 13 mois",
              ],
              [
                "Préférences",
                "Choix de langue, thème (clair/sombre)",
                "Non (exempt)",
                "13 mois",
              ],
              [
                "Mesure d'audience",
                "Statistiques anonymisées",
                "Oui",
                "13 mois",
              ],
              [
                "Analyse comportementale",
                "Compréhension du parcours utilisateur",
                "Oui",
                "13 mois",
              ],
              ["Publicité", "Aucun cookie publicitaire utilisé", "—", "—"],
            ]}
          />
        </LegalSubsection>

        <LegalSubsection number="8.3" title="Gestion de vos préférences">
          <p>
            Lors de votre première visite, un bandeau vous permet d'accepter ou
            refuser les cookies non essentiels. Vous pouvez modifier vos
            préférences à tout moment :
          </p>
          <ul>
            <li>
              Via le lien <em>« Gérer mes cookies »</em> en bas de chaque page ;
            </li>
            <li>Via les paramètres de votre navigateur.</li>
          </ul>
          <LegalCallout tone="warning" title="Plateforme de gestion du consentement (CMP) en cours d'intégration">
            Le bandeau et le module de gestion des cookies seront déployés
            prochainement. En attendant, seuls les cookies strictement
            nécessaires (authentification, sécurité, préférence d'interface)
            sont déposés sur votre terminal — exempts de consentement préalable
            au sens des recommandations CNIL 2026.
          </LegalCallout>
        </LegalSubsection>
      </LegalSection>

      <LegalSection id="article-9" number={9} title="Vos droits">
        <LegalSubsection number="9.1" title="Liste des droits">
          <p>
            Conformément au RGPD et à la loi Informatique et Libertés, vous
            disposez des droits suivants sur vos données personnelles :
          </p>
          <ul>
            <li>
              <strong>Droit d'accès</strong> (art. 15 RGPD) : obtenir une copie
              de toutes les données que nous détenons sur vous.
            </li>
            <li>
              <strong>Droit de rectification</strong> (art. 16 RGPD) : faire
              corriger les données inexactes ou incomplètes.
            </li>
            <li>
              <strong>Droit à l'effacement (« droit à l'oubli »)</strong> (art.
              17 RGPD) : demander la suppression de vos données dans les cas
              prévus par la loi.
            </li>
            <li>
              <strong>Droit à la limitation du traitement</strong> (art. 18
              RGPD) : demander la suspension temporaire du traitement.
            </li>
            <li>
              <strong>Droit à la portabilité</strong> (art. 20 RGPD) : recevoir
              vos données dans un format structuré, couramment utilisé et
              lisible par machine.
            </li>
            <li>
              <strong>Droit d'opposition</strong> (art. 21 RGPD) : vous opposer
              au traitement de vos données pour des raisons tenant à votre
              situation particulière.
            </li>
            <li>
              <strong>Droit de retirer votre consentement</strong> : à tout
              moment, sans que cela n'affecte la licéité du traitement effectué
              avant ce retrait.
            </li>
            <li>
              <strong>Droit de définir des directives post-mortem</strong> :
              indiquer le sort de vos données après votre décès.
            </li>
          </ul>
        </LegalSubsection>

        <LegalSubsection number="9.2" title="Comment exercer vos droits ?">
          <p>Pour exercer vos droits, contactez-nous :</p>
          <ul>
            <li>
              Par email à{" "}
              <a href="mailto:support@sejourfr.fr?subject=Exercice%20des%20droits%20RGPD">
                support@sejourfr.fr
              </a>{" "}
              (objet : <em>« Exercice des droits RGPD »</em>) ;
            </li>
            <li>
              Via notre <Link href="/contact">formulaire de contact</Link>
              {" "};
            </li>
            <li>
              Par courrier postal à :{" "}
              <Placeholder value={editor.address} label="Adresse postale" />.
            </li>
          </ul>
          <p>
            Nous nous engageons à vous répondre dans un{" "}
            <strong>délai maximum d'un mois</strong> à compter de la réception
            de votre demande, conformément à l'article 12 du RGPD. Ce délai peut
            être prolongé de deux mois en cas de demande complexe.
          </p>
          <p>
            Pour des raisons de sécurité, nous pouvons vous demander de
            justifier votre identité avant de répondre.
          </p>
        </LegalSubsection>

        <LegalSubsection number="9.3" title="Réclamation auprès de la CNIL">
          <p>
            Si vous estimez, après nous avoir contactés, que vos droits ne sont
            pas respectés, vous pouvez introduire une réclamation auprès de la
            Commission Nationale de l'Informatique et des Libertés (CNIL) :
          </p>
          <ul>
            <li>
              <strong>En ligne :</strong>{" "}
              <a
                href="https://www.cnil.fr/fr/plaintes"
                target="_blank"
                rel="noopener noreferrer"
              >
                www.cnil.fr/fr/plaintes
              </a>
            </li>
            <li>
              <strong>Par courrier :</strong> CNIL — 3 Place de Fontenoy — TSA
              80715 — 75334 PARIS CEDEX 07
            </li>
            <li>
              <strong>Par téléphone :</strong> 01 53 73 22 22
            </li>
          </ul>
        </LegalSubsection>
      </LegalSection>

      <LegalSection id="article-10" number={10} title="Sécurité des données">
        <p>
          Nous mettons en œuvre des mesures techniques et organisationnelles
          appropriées pour garantir un niveau de sécurité adapté au risque,
          notamment :
        </p>
        <ul>
          <li>
            <strong>Chiffrement</strong> des données en transit (HTTPS / TLS 1.3
            minimum) ;
          </li>
          <li>
            <strong>Hashage</strong> des mots de passe avec un algorithme
            robuste (BCrypt) ;
          </li>
          <li>
            <strong>Authentification</strong> sécurisée par token JWT avec
            rotation automatique ;
          </li>
          <li><strong>Sauvegardes</strong> régulières et chiffrées ;</li>
          <li>
            <strong>Contrôle d'accès</strong> strict aux données : seuls les
            membres habilités y ont accès ;
          </li>
          <li>
            <strong>Journalisation</strong> des accès aux données sensibles ;
          </li>
          <li>
            <strong>Mises à jour de sécurité</strong> régulières des systèmes ;
          </li>
          <li>
            <strong>Sensibilisation</strong> aux bonnes pratiques RGPD.
          </li>
        </ul>
      </LegalSection>

      <LegalSection id="article-11" number={11} title="Violation de données">
        <p>
          En cas de violation de données personnelles susceptible d'engendrer un
          risque pour vos droits et libertés, nous nous engageons à :
        </p>
        <ul>
          <li>
            Notifier la CNIL dans les <strong>72 heures</strong> suivant la
            connaissance de la violation (art. 33 RGPD) ;
          </li>
          <li>
            Vous informer dans les meilleurs délais si la violation est
            susceptible d'engendrer un risque élevé (art. 34 RGPD).
          </li>
        </ul>
      </LegalSection>

      <LegalSection id="article-12" number={12} title="Données des mineurs">
        <p>
          La Plateforme s'adresse aux personnes âgées d'au moins{" "}
          <strong>16 ans</strong>. Nous ne collectons pas sciemment de données
          concernant des enfants de moins de 16 ans. Si vous pensez qu'un enfant
          nous a transmis ses données sans autorisation parentale, contactez-nous
          immédiatement à{" "}
          <a href="mailto:support@sejourfr.fr">support@sejourfr.fr</a>
          {" "}— nous procéderons à la suppression dans les plus brefs délais.
        </p>
      </LegalSection>

      <LegalSection id="article-13" number={13} title="Modifications de la politique">
        <p>
          Nous pouvons être amenés à modifier la présente Politique de
          confidentialité pour refléter des évolutions légales ou techniques.
          La date de dernière mise à jour est indiquée en haut du document. En
          cas de modification substantielle, nous vous en informerons par email.
        </p>
      </LegalSection>

      <LegalSection id="article-14" number={14} title="Contact">
        <p>Pour toute question relative à la protection de vos données :</p>
        <ul>
          <li>
            <strong>Email :</strong>{" "}
            <a href="mailto:support@sejourfr.fr">support@sejourfr.fr</a>
          </li>
          <li>
            <strong>Courrier :</strong>{" "}
            <Placeholder value={editor.address} label="Adresse postale" />
          </li>
          <li>
            <strong>Formulaire :</strong>{" "}
            <Link href="/contact">/contact</Link>
          </li>
        </ul>
      </LegalSection>

      <style>{`
        .legal-note-italic {
          font-size: 14px;
          font-style: italic;
          color: var(--color-muted);
        }
      `}</style>
    </LegalPageLayout>
  );
}
