import type { Metadata } from "next";
import Link from "next/link";
import { LegalPageLayout } from "@/components/legal/LegalPageLayout";
import { LegalSection, LegalSubsection } from "@/components/legal/LegalSection";
import { LegalTable } from "@/components/legal/LegalTable";
import { Placeholder } from "@/components/legal/Placeholder";
import { LEGAL_INFO } from "@/content/legal/legal-info";
import { SITE } from "@/lib/site";

export const metadata: Metadata = {
  title: "Politique de confidentialité | SejourFR",
  description:
    "Comment SejourFR collecte, utilise et protège vos données personnelles conformément au RGPD et à la loi Informatique et Libertés.",
  alternates: { canonical: "/confidentialite" },
  openGraph: {
    title: "Politique de confidentialité — SejourFR",
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
  { id: "article-8", title: "Cookies, stockage local et mesure d'audience" },
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
            (ci-après « <strong>SejourFR</strong> » ou « nous ») collecte,
            utilise, conserve et protège vos données personnelles dans le cadre
            de votre utilisation de la plateforme d&apos;entraînement aux examens
            civique et TCF, accessible via le site web{" "}
            <a href={SITE.url}>{SITE.url.replace(/^https?:\/\//, "")}</a> et les
            applications mobiles SejourFR (iOS et Android) (ci-après la «{" "}
            <strong>Plateforme</strong> »).
          </p>
          <p>
            Nous nous engageons à protéger votre vie privée conformément au{" "}
            <strong>Règlement (UE) 2016/679 du 27 avril 2016</strong> (« RGPD »)
            et à la <strong>loi française n° 78-17 du 6 janvier 1978 modifiée</strong>{" "}
            relative à l&apos;informatique, aux fichiers et aux libertés.
          </p>
          <p>
            Cette politique a vocation à être claire et accessible. Si une
            formulation vous semble obscure, n&apos;hésitez pas à{" "}
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
            <a href={`mailto:${editor.email}`}>{editor.email}</a>
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
            Bien que la désignation d&apos;un DPO ne soit pas obligatoire pour notre
            structure (entreprise individuelle, traitements ne relevant pas des
            catégories rendant le DPO obligatoire au sens de l&apos;article 37 RGPD),
            vous pouvez nous contacter pour toute question relative à vos
            données personnelles à l&apos;adresse{" "}
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
                "Parcours visé (CSP / CR / NAT) et niveau TCF cible (A2 / B1 / B2)",
                "Facultatif",
                "Personnaliser l'entraînement et le gating des contenus",
              ],
              [
                "Données de paiement",
                "Obligatoire pour les achats sur le web",
                "Traitement des paiements via Stripe. Pour les achats in-app, le paiement est traité par Apple ou Google ; SejourFR ne collecte pas ces données bancaires.",
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
              version du navigateur, système d&apos;exploitation, langue, fuseau
              horaire, dates et heures de connexion ;
            </li>
            <li>
              <strong>Données d&apos;utilisation des Services</strong> : sessions
              d&apos;entraînement et d&apos;examens blancs (module, thématiques abordées,
              réponses données, score, durée), progression par thématique pour
              chaque module (civique et TCF), historique des tentatives,
              questions marquées en favori et questions échouées consultées en
              révision ;
            </li>
            <li>
              <strong>Données d&apos;acquisition et de parcours</strong> : lors de la
              création de votre compte, la <strong>provenance</strong> (le
              réseau social ou le lien depuis lequel vous êtes arrivé sur la
              Plateforme) et le <strong>type d&apos;appareil</strong> utilisé (site
              web ou application mobile). Pour un compte connecté, nous
              enregistrons également le <strong>premier</strong> affichage de
              l&apos;écran d&apos;abonnement et le <strong>premier</strong> clic sur un
              bouton d&apos;abonnement. Ces informations sont rattachées à votre
              compte et <strong>supprimées avec lui</strong>.
            </li>
            <li>
              <strong>Données de mesure d&apos;audience</strong> : pour savoir
              combien de personnes visitent la Plateforme et où elles
              s&apos;arrêtent, nous enregistrons des <strong>étapes de parcours</strong>{" "}
              (page consultée, diagnostic commencé, exercice terminé, écran
              d&apos;abonnement affiché…), rattachées à un{" "}
              <strong>identifiant de mesure</strong> déposé sur votre terminal
              et décrit à l&apos;Article 8. Nous y ajoutons le{" "}
              <strong>pays</strong>, déduit de votre adresse IP{" "}
              <strong>sans que celle-ci soit conservée</strong>, et le{" "}
              <strong>type d&apos;appareil</strong>, déduit des informations
              transmises par votre navigateur. Cette mesure ne comporte{" "}
              <strong>ni votre nom, ni votre adresse email, ni le contenu de
              vos productions</strong>, et ne sert qu&apos;à comprendre l&apos;usage de la
              Plateforme.
            </li>
          </ul>
        </LegalSubsection>

        <LegalSubsection number="3.3" title="Cookies et stockage sur votre terminal">
          <p>
            Nous utilisons un cookie de session et un stockage local dans les
            conditions décrites à l&apos;Article 8 ci-dessous. Nous n&apos;utilisons{" "}
            <strong>aucun outil d&apos;analyse tiers</strong> et{" "}
            <strong>aucun cookie publicitaire</strong>.
          </p>
        </LegalSubsection>
      </LegalSection>

      <LegalSection id="article-4" number={4} title="Finalités et bases légales du traitement">
        <p>
          Conformément à l&apos;article 6 du RGPD, chaque traitement de vos données
          repose sur une <strong>base légale</strong> précise :
        </p>
        <LegalTable
          columns={["Finalité du traitement", "Base légale"]}
          rows={[
            ["Création et gestion de votre compte", "Exécution du contrat (art. 6.1.b)"],
            [
              "Fourniture des services d'entraînement (modules civique et TCF) : sessions, examens blancs, favoris, révision des erreurs",
              "Exécution du contrat (art. 6.1.b)",
            ],
            [
              "Calcul et restitution de votre progression par module et par thématique",
              "Exécution du contrat (art. 6.1.b)",
            ],
            [
              "Gestion des pass Premium et traitement des paiements",
              "Exécution du contrat (art. 6.1.b)",
            ],
            [
              "Envoi d'emails transactionnels (confirmation d'inscription, réinitialisation de mot de passe, accusé de paiement)",
              "Exécution du contrat (art. 6.1.b)",
            ],
            ["Envoi de newsletters et actualités", "Consentement (art. 6.1.a)"],
            [
              "Mesure de l'efficacité de nos campagnes et amélioration de la Plateforme (provenance à l'inscription, type d'appareil, premières étapes du parcours d'abonnement)",
              "Intérêt légitime (art. 6.1.f)",
            ],
            [
              "Mesure d'audience de la Plateforme : nombre de visiteurs, provenance, étapes du parcours, pays et type d'appareil (voir Article 8)",
              "Intérêt légitime (art. 6.1.f)",
            ],
            [
              "Réponse à vos demandes (formulaire de contact)",
              "Intérêt légitime (art. 6.1.f)",
            ],
            ["Conservation des factures", "Obligation légale (art. 6.1.c)"],
            ["Lutte contre la fraude et la sécurité de la Plateforme", "Intérêt légitime (art. 6.1.f)"],
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
            [
              "Données d'acquisition et de parcours (provenance, type d'appareil, étapes du parcours d'abonnement)",
              "Durée de vie du compte : supprimées avec lui",
            ],
            [
              "Données de mesure d'audience (identifiant de mesure et étapes de parcours associées)",
              "13 mois, puis suppression ; l'identifiant est renouvelé au-delà de 13 mois",
            ],
            ["Logs de connexion", "12 mois"],
            ["Cookie de session et stockage local", "Voir Article 8"],
            ["Messages de contact", "3 ans après dernier échange"],
            ["Newsletters", "Jusqu'au retrait du consentement, puis 3 ans"],
          ]}
        />
        <p>
          À l&apos;issue de ces délais, vos données sont{" "}
          <strong>supprimées définitivement</strong> ou{" "}
          <strong>anonymisées</strong> de manière irréversible.
        </p>
      </LegalSection>

      <LegalSection id="article-6" number={6} title="Destinataires de vos données">
        <p>
          Vos données sont accessibles aux seules personnes habilitées de
          SejourFR ayant besoin d&apos;y accéder dans le cadre de leurs missions.
        </p>
        <p>
          Nous faisons appel à des <strong>sous-traitants</strong> au sens du
          RGPD pour certaines opérations. Ces sous-traitants sont liés à
          SejourFR par des accords de traitement (DPA) conformes à l&apos;article 28
          du RGPD :
        </p>
        <LegalTable
          columns={["Sous-traitant", "Finalité", "Pays"]}
          rows={subProcessors.map((sp) => [sp.name, sp.purpose, sp.country])}
        />
        <p>
          Lorsqu&apos;un achat est réalisé via l&apos;App Store ou Google Play, le
          paiement est traité par Apple ou Google, agissant comme responsables
          de traitement indépendants pour ces transactions. SejourFR ne reçoit
          pas vos données bancaires dans ce cas. Le traitement de vos données
          par ces sociétés est régi par leurs propres politiques de
          confidentialité.
        </p>
        <p className="legal-note-italic">
          Aucune de vos données n&apos;est vendue à des tiers à des fins
          commerciales.
        </p>
      </LegalSection>

      <LegalSection id="article-7" number={7} title="Transferts hors Union européenne">
        {allInEu ? (
          <p>
            Vos données sont traitées exclusivement au sein de l&apos;Union
            européenne. Aucun transfert hors UE n&apos;est effectué.
          </p>
        ) : (
          <>
            <p>
              Certains de nos sous-traitants peuvent être amenés à traiter vos
              données en dehors de l&apos;Union européenne. Dans ce cas, des
              garanties appropriées sont mises en place conformément aux
              articles 44 et suivants du RGPD :
            </p>
            <ul>
              <li>
                <strong>Clauses contractuelles types</strong> approuvées par la
                Commission européenne ;
              </li>
              <li>
                <strong>Décision d&apos;adéquation</strong> de la Commission
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

      <LegalSection id="article-8" number={8} title="Cookies, stockage local et mesure d’audience">
        <LegalSubsection number="8.1" title="Cookie, stockage local : de quoi parle-t-on ?">
          <p>
            Un <strong>cookie</strong> est un petit fichier déposé sur votre
            terminal (ordinateur, tablette, smartphone) lors de la consultation
            d&apos;un site web. Le <strong>stockage local</strong> (et le stockage
            d&apos;onglet) est un mécanisme voisin : le site y range une information
            que votre navigateur conserve pour lui, sans l&apos;envoyer
            automatiquement à chaque page.
          </p>
          <p>
            Les deux reviennent à écrire quelque chose sur votre terminal, et
            les mêmes règles s&apos;y appliquent. Nous les traitons donc ensemble
            ci-dessous.
          </p>
        </LegalSubsection>

        <LegalSubsection number="8.2" title="Ce qui est déposé sur votre terminal">
          <p>
            La Plateforme dépose <strong>trois choses</strong>, et rien d&apos;autre.
            Aucune n&apos;est un cookie publicitaire, aucune n&apos;est fournie par un
            outil tiers, et aucune ne permet de vous suivre sur d&apos;autres sites.
          </p>
          <LegalTable
            columns={["Nom", "Où", "À quoi ça sert", "Durée"]}
            rows={[
              [
                "sejourfr.accessToken et sejourfr.refreshToken",
                "Cookie (accessToken) + stockage local du navigateur",
                "Vous garder connecté d'une page à l'autre. Sans lui, il faudrait ressaisir votre mot de passe en permanence.",
                "Durée de la session de connexion (le stockage local est effacé à la déconnexion)",
              ],
              [
                "sejourfr.aid",
                "Stockage local du navigateur",
                "Identifiant de mesure d'audience : un numéro tiré au hasard, qui ne contient ni votre nom, ni votre email, ni rien qui vienne de vous. Il sert uniquement à ne pas compter dix fois la même personne.",
                "13 mois, puis un nouveau numéro est tiré",
              ],
              [
                "sejourfr.sid et sejourfr.dgx",
                "Stockage de l'onglet (sessionStorage)",
                "Distinguer une visite d'une autre, et relier le début et la fin d'un même exercice. Effacés dès que vous fermez l'onglet.",
                "Le temps de l'onglet",
              ],
            ]}
          />
          <p>
            <strong>Aucun cookie de mesure d&apos;audience tiers</strong> (Google
            Analytics, Plausible, Matomo, etc.), aucun cookie publicitaire et
            aucun traceur d&apos;analyse comportementale ne sont déposés par
            SejourFR.
          </p>
        </LegalSubsection>

        <LegalSubsection number="8.3" title="Notre mesure d'audience">
          <p>
            Nous avons besoin de savoir combien de personnes visitent la
            Plateforme, d&apos;où elles viennent, et à quel endroit du parcours elles
            s&apos;arrêtent — sinon nous améliorons le produit à l&apos;aveugle. Cette
            mesure est réalisée <strong>par nos propres serveurs</strong>, sans
            aucun outil extérieur.
          </p>
          <p>
            <strong>Ce que nous enregistrons</strong> : l&apos;identifiant de mesure
            décrit ci-dessus, la page consultée, les étapes franchies (diagnostic
            commencé, exercice terminé, écran d&apos;abonnement affiché, bouton
            d&apos;abonnement cliqué…), la date et l&apos;heure, le lien ou la campagne par
            lesquels vous êtes arrivé, votre <strong>pays</strong> et votre{" "}
            <strong>type d&apos;appareil</strong>.
          </p>
          <p>
            <strong>Ce que nous n&apos;enregistrons pas</strong> : votre{" "}
            <strong>adresse IP</strong> — elle sert à déduire le pays{" "}
            <em>au moment de la requête</em> puis elle est aussitôt oubliée, elle
            n&apos;est jamais écrite dans nos bases —, le texte de vos productions
            écrites, la transcription de vos enregistrements, votre email, votre
            mot de passe ou vos coordonnées bancaires. La liste des informations
            acceptées par notre serveur est <strong>fermée</strong> : tout ce qui
            n&apos;y figure pas est refusé.
          </p>
          <p>
            <strong>Ce que nous ne faisons pas</strong> : nous ne partageons ces
            données avec <strong>personne</strong>, nous ne les vendons pas, nous
            ne les croisons avec aucun fichier extérieur, nous ne vous suivons
            pas sur d&apos;autres sites, nous ne faisons aucune publicité ciblée et
            nous n&apos;établissons aucun profil pour prendre une décision
            automatisée à votre sujet.
          </p>
          <p>
            Si vous créez un compte, votre parcours antérieur peut être rattaché
            à ce compte, afin que nous sachions quel chemin mène réellement à une
            inscription. Ces informations sont alors{" "}
            <strong>supprimées avec votre compte</strong>, et vous disposez à
            leur égard des droits décrits à l&apos;Article 9, notamment le droit
            d&apos;opposition.
          </p>
        </LegalSubsection>

        <LegalSubsection number="8.4" title="Pourquoi il n'y a pas de bandeau de consentement">
          <p>
            Déposer une information sur votre terminal suppose en principe votre
            accord. La CNIL prévoit toutefois une{" "}
            <strong>exemption pour la seule mesure d&apos;audience</strong>, à
            condition qu&apos;elle reste strictement limitée à cette finalité. Nous
            nous tenons à ces conditions :
          </p>
          <ul>
            <li>
              la mesure sert <strong>uniquement</strong> à produire des
              statistiques d&apos;usage anonymes, jamais à de la publicité ni à du
              ciblage ;
            </li>
            <li>
              l&apos;identifiant est <strong>propre à SejourFR</strong> : il n&apos;est
              transmis à aucun tiers et ne permet pas de vous suivre d&apos;un site à
              l&apos;autre ;
            </li>
            <li>
              les données ne sont <strong>recoupées avec aucun autre
              traitement</strong> ni avec aucun fichier extérieur ;
            </li>
            <li>
              l&apos;identifiant est <strong>renouvelé au bout de 13 mois</strong> et
              les données de mesure ne sont pas conservées au-delà.
            </li>
          </ul>
          <p>
            Pour cette raison, <strong>aucun bandeau de consentement n&apos;est
            affiché</strong>. Si, à l&apos;avenir, SejourFR venait à intégrer un
            traceur non essentiel — un outil de mesure d&apos;audience tiers ou un
            cookie publicitaire, par exemple —{" "}
            <strong>un bandeau de consentement serait alors mis en place</strong>{" "}
            et la présente section mise à jour en conséquence.
          </p>
        </LegalSubsection>

        <LegalSubsection number="8.5" title="Comment vous y opposer">
          <p>Vous pouvez à tout moment :</p>
          <ul>
            <li>
              <strong>effacer les données de site de SejourFR</strong> depuis les
              réglages de votre navigateur : l&apos;identifiant de mesure disparaît, et
              un nouveau ne sera tiré qu&apos;à votre prochaine visite ;
            </li>
            <li>
              <strong>bloquer le stockage local</strong> pour ce site, ou
              naviguer en fenêtre privée : la Plateforme continue de fonctionner
              normalement, et la mesure se fait alors{" "}
              <strong>sans aucun identifiant</strong> ;
            </li>
            <li>
              <strong>nous demander de ne plus vous mesurer</strong>, en écrivant
              à notre délégué à la protection des données (Article 2) : nous
              donnons suite à toute opposition, sans avoir à en discuter le
              motif ;
            </li>
            <li>
              <strong>vous déconnecter</strong> depuis votre espace personnel, ce
              qui supprime le cookie et le jeton de session.
            </li>
          </ul>
          <p>
            Vous pouvez également configurer votre navigateur pour bloquer tous
            les cookies — auquel cas vous ne pourrez plus accéder aux pages
            réservées aux utilisateurs connectés, le cookie de session étant
            strictement nécessaire à l&apos;authentification.
          </p>
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
              <strong>Droit d&apos;accès</strong> (art. 15 RGPD) : obtenir une copie
              de toutes les données que nous détenons sur vous.
            </li>
            <li>
              <strong>Droit de rectification</strong> (art. 16 RGPD) : faire
              corriger les données inexactes ou incomplètes.
            </li>
            <li>
              <strong>Droit à l&apos;effacement (« droit à l&apos;oubli »)</strong> (art.
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
              <strong>Droit d&apos;opposition</strong> (art. 21 RGPD) : vous opposer
              au traitement de vos données pour des raisons tenant à votre
              situation particulière.
            </li>
            <li>
              <strong>Droit de retirer votre consentement</strong> : à tout
              moment, sans que cela n&apos;affecte la licéité du traitement effectué
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
              <a href={`mailto:${editor.email}?subject=Exercice%20des%20droits%20RGPD`}>
                {editor.email}
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
            <strong>délai maximum d&apos;un mois</strong> à compter de la réception
            de votre demande, conformément à l&apos;article 12 du RGPD. Ce délai peut
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
            Commission Nationale de l&apos;Informatique et des Libertés (CNIL) :
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
            <strong>Authentification</strong> sécurisée par token JWT
            (access token court + refresh token avec rotation côté serveur) ;
          </li>
          <li><strong>Sauvegardes</strong> régulières et chiffrées ;</li>
          <li>
            <strong>Contrôle d&apos;accès</strong> strict aux données : seuls les
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
          En cas de violation de données personnelles susceptible d&apos;engendrer un
          risque pour vos droits et libertés, nous nous engageons à :
        </p>
        <ul>
          <li>
            Notifier la CNIL dans les <strong>72 heures</strong> suivant la
            connaissance de la violation (art. 33 RGPD) ;
          </li>
          <li>
            Vous informer dans les meilleurs délais si la violation est
            susceptible d&apos;engendrer un risque élevé (art. 34 RGPD).
          </li>
        </ul>
      </LegalSection>

      <LegalSection id="article-12" number={12} title="Données des mineurs">
        <p>
          La Plateforme s&apos;adresse aux personnes âgées d&apos;au moins{" "}
          <strong>16 ans</strong>. Nous ne collectons pas sciemment de données
          concernant des enfants de moins de 16 ans. Si vous pensez qu&apos;un enfant
          nous a transmis ses données sans autorisation parentale, contactez-nous
          immédiatement à{" "}
          <a href={`mailto:${editor.email}`}>{editor.email}</a>
          {" "}— nous procéderons à la suppression dans les plus brefs délais.
        </p>
      </LegalSection>

      <LegalSection id="article-13" number={13} title="Modifications de la politique">
        <p>
          Nous pouvons être amenés à modifier la présente Politique de
          confidentialité pour refléter des évolutions légales ou techniques.
          Toute modification prend effet dès sa publication sur la Plateforme ;
          la date de dernière mise à jour, indiquée en haut du document, en
          reflète la version en vigueur. Nous vous invitons à la consulter
          régulièrement.
        </p>
      </LegalSection>

      <LegalSection id="article-14" number={14} title="Contact">
        <p>Pour toute question relative à la protection de vos données :</p>
        <ul>
          <li>
            <strong>Email :</strong>{" "}
            <a href={`mailto:${editor.email}`}>{editor.email}</a>
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
