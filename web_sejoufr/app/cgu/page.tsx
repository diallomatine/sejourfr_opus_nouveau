import type { Metadata } from "next";
import Link from "next/link";
import { LegalPageLayout } from "@/components/legal/LegalPageLayout";
import { LegalSection, LegalSubsection } from "@/components/legal/LegalSection";
import { LegalCallout } from "@/components/legal/LegalCallout";
import { Placeholder } from "@/components/legal/Placeholder";
import { LEGAL_INFO } from "@/content/legal/legal-info";
import { SITE } from "@/lib/site";

export const metadata: Metadata = {
  title: "Conditions générales d'utilisation | SéjourFR",
  description:
    "CGU de SéjourFR : modalités d'inscription, abonnement, droit de rétractation, médiation et engagements des utilisateurs.",
  alternates: { canonical: "/cgu" },
  openGraph: {
    title: "Conditions générales d'utilisation — SéjourFR",
    description:
      "Inscription, abonnement, paiement, droit de rétractation 14 jours et règles d'utilisation de la plateforme.",
    type: "website",
    url: `${SITE.url}/cgu`,
  },
  robots: { index: true, follow: true },
};

const SECTIONS = [
  { id: "article-1", title: "Objet" },
  { id: "article-2", title: "Définitions" },
  { id: "article-3", title: "Inscription et compte" },
  { id: "article-4", title: "Description des services" },
  { id: "article-5", title: "Tarifs et paiement" },
  { id: "article-6", title: "Droit de rétractation" },
  { id: "article-7", title: "Engagements de l'utilisateur" },
  { id: "article-8", title: "Disponibilité du service" },
  { id: "article-9", title: "Limitation de responsabilité" },
  { id: "article-10", title: "Données personnelles" },
  { id: "article-11", title: "Modifications des CGU" },
  { id: "article-12", title: "Médiation et règlement des litiges" },
  { id: "article-13", title: "Loi applicable et juridiction" },
  { id: "article-14", title: "Contact" },
];

export default function CguPage() {
  const { editor, subscription, mediator } = LEGAL_INFO;

  return (
    <LegalPageLayout
      title="Conditions générales d'utilisation"
      description="Les CGU encadrent la relation entre SéjourFR et ses utilisateurs et incluent les conditions de vente des abonnements payants."
      sections={SECTIONS}
      currentPath="/cgu"
    >
      <LegalSection id="article-1" number={1} title="Objet">
        <p>
          Les présentes Conditions Générales d'Utilisation et de Vente (ci-après
          les « <strong>CGU</strong> ») ont pour objet de définir les modalités et
          conditions dans lesquelles{" "}
          <strong>
            <Placeholder value={editor.legalName} label="Raison sociale" />
          </strong>{" "}
          (ci-après « <strong>SéjourFR</strong> » ou « nous ») met à disposition la
          plateforme accessible à l'adresse{" "}
          <a href={SITE.url}>
            {SITE.url.replace(/^https?:\/\//, "")}
          </a>{" "}
          (ci-après la « <strong>Plateforme</strong> »), et fournit ses services à
          l'utilisateur (ci-après l'« <strong>Utilisateur</strong> » ou « vous »).
        </p>
        <p>
          L'utilisation de la Plateforme implique l'acceptation pleine et entière
          des présentes CGU. En créant un compte ou en souscrivant un abonnement,
          vous reconnaissez avoir lu, compris et accepté l'intégralité des
          présentes CGU.
        </p>
      </LegalSection>

      <LegalSection id="article-2" number={2} title="Définitions">
        <ul>
          <li>
            <strong>Plateforme</strong> : le site web et les services accessibles
            à l'adresse {SITE.url}.
          </li>
          <li>
            <strong>Utilisateur</strong> : toute personne, physique ou morale, qui
            utilise la Plateforme.
          </li>
          <li>
            <strong>Compte</strong> : espace personnel créé par l'Utilisateur pour
            accéder aux services.
          </li>
          <li>
            <strong>Services</strong> : ensemble des fonctionnalités offertes par
            la Plateforme (questions de QCM, examens blancs chronométrés, suivi de
            progression, etc.).
          </li>
          <li>
            <strong>Contenu Premium</strong> : ensemble des contenus accessibles
            uniquement aux Utilisateurs ayant souscrit un abonnement payant.
          </li>
          <li>
            <strong>Examen civique</strong> : test officiel exigé en France pour
            certaines démarches administratives (titre de séjour, naturalisation),
            tel que défini par la législation française en vigueur.
          </li>
        </ul>
      </LegalSection>

      <LegalSection id="article-3" number={3} title="Inscription et compte utilisateur">
        <LegalSubsection number="3.1" title="Conditions d'inscription">
          <p>
            L'inscription sur la Plateforme est ouverte à toute personne physique
            âgée d'au moins <strong>16 ans</strong>. Les Utilisateurs mineurs
            doivent obtenir l'autorisation préalable d'un titulaire de l'autorité
            parentale.
          </p>
        </LegalSubsection>

        <LegalSubsection number="3.2" title="Création de compte">
          <p>
            Pour créer un compte, l'Utilisateur s'engage à fournir des
            informations exactes, complètes et à jour. L'Utilisateur est seul
            responsable de la confidentialité de ses identifiants de connexion.
            Toute utilisation de son compte est réputée effectuée par lui-même.
          </p>
          <p>
            En cas d'utilisation frauduleuse ou non autorisée de son compte,
            l'Utilisateur s'engage à en informer SéjourFR sans délai à l'adresse{" "}
            <a href="mailto:support@sejourfr.fr">support@sejourfr.fr</a>.
          </p>
        </LegalSubsection>

        <LegalSubsection number="3.3" title="Suppression de compte">
          <p>
            L'Utilisateur peut supprimer son compte à tout moment depuis son
            espace personnel ou en envoyant une demande à support@sejourfr.fr.
            La suppression entraîne la perte définitive des données associées au
            compte (progression, historique, etc.), sous réserve des obligations
            légales de conservation.
          </p>
        </LegalSubsection>
      </LegalSection>

      <LegalSection id="article-4" number={4} title="Description des services">
        <LegalSubsection number="4.1" title="Accès gratuit">
          <p>SéjourFR propose un accès gratuit à la Plateforme comprenant :</p>
          <ul>
            <li>
              <strong>{subscription.trialQuestionsPerCategory} questions par catégorie</strong> en mode entraînement, sur les 5 thématiques officielles ;
            </li>
            <li>
              <strong>Le 1er examen blanc</strong> de chaque module (Civique et Naturalisation), rejouable sans limite ;
            </li>
            <li>Des contenus pédagogiques de base.</li>
          </ul>
        </LegalSubsection>

        <LegalSubsection number="4.2" title="Abonnement Premium">
          <p>L'abonnement Premium donne accès à :</p>
          <ul>
            <li>
              L'intégralité des questions disponibles sur la Plateforme, organisées par catégorie officielle ;
            </li>
            <li>
              <strong>20 examens blancs chronométrés</strong> de 40 questions par module, en conditions réelles ;
            </li>
            <li>Le suivi détaillé de progression par catégorie ;</li>
            <li>Les explications pédagogiques pour chaque question ;</li>
            <li>
              Les fonctionnalités avancées (mode examen chronométré, statistiques, badges, recommandations personnalisées).
            </li>
          </ul>
        </LegalSubsection>

        <LegalSubsection number="4.3" title="Évolution des services">
          <p>
            SéjourFR se réserve le droit de modifier, faire évoluer, ajouter ou
            supprimer des fonctionnalités à tout moment. Toute modification
            substantielle sera notifiée à l'Utilisateur par email ou via la
            Plateforme.
          </p>
        </LegalSubsection>
      </LegalSection>

      <LegalSection id="article-5" number={5} title="Tarifs et paiement">
        <LegalSubsection number="5.1" title="Prix">
          <p>
            L'abonnement Premium est proposé au prix de{" "}
            <strong>{subscription.annualPriceTTC} TTC par an</strong> (TVA
            française à {subscription.vatRate} incluse, le cas échéant). Les prix
            sont indiqués en euros, toutes taxes comprises.
          </p>
        </LegalSubsection>

        <LegalSubsection number="5.2" title="Modalités de paiement">
          <p>
            Le paiement s'effectue exclusivement en ligne par carte bancaire via
            notre prestataire de paiement sécurisé{" "}
            <strong>Stripe Payments Europe Ltd.</strong> Aucune information
            bancaire n'est stockée sur les serveurs de SéjourFR. Les paiements
            sont effectués en toute sécurité grâce au protocole 3D-Secure.
          </p>
        </LegalSubsection>

        <LegalSubsection number="5.3" title="Reconduction">
          <p>
            Sauf indication contraire, l'abonnement annuel est{" "}
            <strong>non reconductible automatiquement</strong> : il prend fin à
            l'issue de la période souscrite et ne sera pas renouvelé sans action
            de votre part.
          </p>
        </LegalSubsection>

        <LegalSubsection number="5.4" title="Facturation">
          <p>
            Une facture est émise pour chaque paiement et envoyée par email à
            l'adresse renseignée par l'Utilisateur. Elle est également
            téléchargeable depuis l'espace personnel.
          </p>
        </LegalSubsection>
      </LegalSection>

      <LegalSection id="article-6" number={6} title="Droit de rétractation">
        <p>
          Conformément à l'article L221-18 du Code de la consommation, vous
          disposez d'un délai de <strong>14 jours</strong> à compter de la
          souscription pour exercer votre droit de rétractation, sans avoir à
          justifier de motifs ni à payer de pénalités.
        </p>

        <LegalSubsection number="6.1" title="Modalités de rétractation">
          <p>
            Pour exercer ce droit, vous devez nous notifier votre décision par
            une déclaration dénuée d'ambiguïté :
          </p>
          <ul>
            <li>
              Par email à :{" "}
              <a href="mailto:support@sejourfr.fr">support@sejourfr.fr</a>
            </li>
            <li>
              Via notre{" "}
              <Link href="/contact">formulaire de contact</Link>.
            </li>
          </ul>
          <p>
            Vous pouvez utiliser le modèle de formulaire de rétractation prévu
            par le Code de la consommation, mais ce n'est pas obligatoire.
          </p>
        </LegalSubsection>

        <LegalSubsection number="6.2" title="Effet de la rétractation">
          <p>
            En cas de rétractation, nous vous remboursons l'intégralité des
            sommes versées dans un délai maximal de 14 jours à compter de la
            réception de votre notification. Le remboursement s'effectue par le
            même moyen de paiement que celui utilisé pour la transaction
            initiale.
          </p>
        </LegalSubsection>

        <LegalSubsection
          number="6.3"
          title="Renonciation au droit de rétractation"
        >
          <p>
            Conformément à l'article L221-28 du Code de la consommation, le
            droit de rétractation <strong>ne peut être exercé</strong> pour les
            contenus numériques fournis sur un support immatériel dont
            l'exécution a commencé avec l'accord préalable exprès du
            consommateur, qui a renoncé à son droit de rétractation. Lorsque
            vous accédez immédiatement aux Contenus Premium après votre
            paiement, vous reconnaissez expressément renoncer à votre droit de
            rétractation.
          </p>
        </LegalSubsection>
      </LegalSection>

      <LegalSection id="article-7" number={7} title="Engagements de l'Utilisateur">
        <p>L'Utilisateur s'engage à :</p>
        <ul>
          <li>
            Utiliser la Plateforme conformément à sa destination et de manière
            loyale ;
          </li>
          <li>
            Ne pas reproduire, copier, vendre ou exploiter à des fins
            commerciales tout ou partie des contenus de la Plateforme ;
          </li>
          <li>
            Ne pas tenter d'accéder de manière non autorisée à la Plateforme ou
            à des comptes tiers ;
          </li>
          <li>
            Ne pas perturber le fonctionnement de la Plateforme (déni de
            service, scraping massif, etc.) ;
          </li>
          <li>Ne pas partager ses identifiants de connexion avec un tiers ;</li>
          <li>
            Respecter les autres Utilisateurs et la propriété intellectuelle de
            SéjourFR.
          </li>
        </ul>
        <p>
          Tout manquement à ces engagements peut entraîner la suspension ou la
          suppression du compte, sans remboursement.
        </p>
      </LegalSection>

      <LegalSection id="article-8" number={8} title="Disponibilité du service">
        <p>
          SéjourFR met en œuvre tous les moyens raisonnables pour garantir une
          disponibilité de la Plateforme 24h/24 et 7j/7. Toutefois, des
          interruptions peuvent survenir pour des opérations de maintenance, des
          défaillances techniques ou des cas de force majeure.
        </p>
        <p>
          SéjourFR ne saurait être tenue responsable de toute interruption ou
          indisponibilité de la Plateforme. Aucun remboursement ne sera dû en
          cas d'interruption ponctuelle.
        </p>
      </LegalSection>

      <LegalSection id="article-9" number={9} title="Limitation de responsabilité">
        <LegalSubsection number="9.1" title="Aucune garantie de réussite">
          <p>
            SéjourFR est une plateforme de{" "}
            <strong>
              préparation à l'examen civique et à l'entretien de naturalisation
            </strong>
            . Elle ne peut en aucun cas garantir la réussite de l'Utilisateur à
            ces épreuves, ni l'obtention d'un titre de séjour ou de la
            nationalité française.
          </p>
          <p>
            L'obtention d'un titre administratif dépend de l'évaluation par les
            autorités compétentes (centres d'examen agréés, préfectures,
            Ministère de l'Intérieur) et de critères qui dépassent largement la
            seule préparation à l'examen.
          </p>
        </LegalSubsection>

        <LegalSubsection number="9.2" title="Caractère indicatif des contenus">
          <p>
            Les contenus de la Plateforme sont fournis à titre informatif et
            pédagogique. Ils ne constituent en aucun cas des conseils juridiques
            personnalisés. Pour toute situation spécifique, l'Utilisateur est
            invité à consulter un avocat ou un conseiller spécialisé en droit
            des étrangers.
          </p>
        </LegalSubsection>

        <LegalSubsection number="9.3" title="Limitation">
          <p>
            La responsabilité de SéjourFR est limitée au montant de l'abonnement
            payé par l'Utilisateur sur les 12 derniers mois, dans toute la
            mesure permise par la loi.
          </p>
        </LegalSubsection>
      </LegalSection>

      <LegalSection id="article-10" number={10} title="Données personnelles">
        <p>
          Le traitement de vos données personnelles est régi par notre{" "}
          <Link href="/confidentialite">Politique de confidentialité</Link>,
          conforme au Règlement Général sur la Protection des Données (RGPD)
          et à la loi française Informatique et Libertés.
        </p>
      </LegalSection>

      <LegalSection id="article-11" number={11} title="Modifications des CGU">
        <p>
          SéjourFR se réserve le droit de modifier les présentes CGU à tout
          moment. Toute modification substantielle sera notifiée à l'Utilisateur
          par email au moins <strong>30 jours</strong> avant son entrée en
          vigueur. La poursuite de l'utilisation de la Plateforme après ce délai
          vaut acceptation des nouvelles CGU.
        </p>
      </LegalSection>

      <LegalSection id="article-12" number={12} title="Médiation et règlement des litiges">
        <p>
          Conformément à l'article L612-1 du Code de la consommation, en cas de
          litige non résolu après réclamation écrite auprès de SéjourFR, vous
          pouvez recourir gratuitement à un médiateur de la consommation.
        </p>
        {mediator.name ? (
          <p>
            Le médiateur compétent est : <strong>{mediator.name}</strong>
            {mediator.address ? `, ${mediator.address}` : ""}
            {mediator.website ? (
              <>
                {" "}—{" "}
                <a
                  href={mediator.website}
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  {mediator.website.replace(/^https?:\/\//, "")}
                </a>
              </>
            ) : null}
            .
          </p>
        ) : (
          <LegalCallout tone="warning" title="Médiateur à désigner">
            La désignation d'un médiateur agréé est obligatoire dès qu'une
            plateforme vend à des consommateurs. Les médiateurs courants
            incluent <em>SAS Médiation Solution</em> (sasmediationsolution-conso.fr)
            ou <em>MEDICYS</em>. Cette section sera complétée dès la
            désignation effective.
          </LegalCallout>
        )}
        <p>
          Vous pouvez également utiliser la plateforme européenne de Règlement
          en Ligne des Litiges (RLL) :{" "}
          <a
            href="https://ec.europa.eu/consumers/odr"
            target="_blank"
            rel="noopener noreferrer"
          >
            ec.europa.eu/consumers/odr
          </a>
          .
        </p>
      </LegalSection>

      <LegalSection id="article-13" number={13} title="Loi applicable et juridiction">
        <p>
          Les présentes CGU sont régies par le droit français. À défaut de
          résolution amiable, tout litige sera soumis aux tribunaux français
          compétents.
        </p>
      </LegalSection>

      <LegalSection id="article-14" number={14} title="Contact">
        <ul>
          <li>
            Email :{" "}
            <a href="mailto:support@sejourfr.fr">support@sejourfr.fr</a>
          </li>
          <li>
            <Link href="/contact">Formulaire de contact</Link>
          </li>
        </ul>
      </LegalSection>
    </LegalPageLayout>
  );
}
