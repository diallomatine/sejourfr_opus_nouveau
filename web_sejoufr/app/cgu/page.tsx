import type {Metadata} from "next";
import Link from "next/link";
import {LegalPageLayout} from "@/components/legal/LegalPageLayout";
import {LegalSection, LegalSubsection} from "@/components/legal/LegalSection";
import {LegalCallout} from "@/components/legal/LegalCallout";
import {Placeholder} from "@/components/legal/Placeholder";
import {LEGAL_INFO} from "@/content/legal/legal-info";
import {SITE} from "@/lib/site";

export const metadata: Metadata = {
    title: "Conditions générales d'utilisation | SejourFR",
    description:
        "CGU de SejourFR : modalités d'inscription, passes d'accès, droit de rétractation, médiation et engagements des utilisateurs.",
    alternates: {canonical: "/cgu"},
    openGraph: {
        title: "Conditions générales d'utilisation — SejourFR",
        description:
            "Inscription, passes d'accès, paiement, droit de rétractation 14 jours et règles d'utilisation de la plateforme.",
        type: "website",
        url: `${SITE.url}/cgu`,
    },
    robots: {index: true, follow: true},
};

const SECTIONS = [
    {id: "article-1", title: "Objet"},
    {id: "article-2", title: "Définitions"},
    {id: "article-3", title: "Inscription et compte"},
    {id: "article-4", title: "Description des services"},
    {id: "article-5", title: "Nature et limites du service"},
    {id: "article-6", title: "Tarifs et paiement"},
    {id: "article-7", title: "Droit de rétractation"},
    {id: "article-8", title: "Engagements de l'utilisateur"},
    {id: "article-9", title: "Disponibilité du service"},
    {id: "article-10", title: "Limitation de responsabilité"},
    {id: "article-11", title: "Propriété intellectuelle"},
    {id: "article-12", title: "Données personnelles"},
    {id: "article-13", title: "Modifications des CGU"},
    {id: "article-14", title: "Médiation et règlement des litiges"},
    {id: "article-15", title: "Loi applicable et juridiction"},
    {id: "article-16", title: "Contact"},
];

export default function CguPage() {
    const {editor, subscription, mediator} = LEGAL_INFO;

    return (
        <LegalPageLayout
            title="Conditions générales d'utilisation"
            description="Les CGU encadrent la relation entre SejourFR et ses utilisateurs et incluent les conditions de vente des passes d'accès payants."
            sections={SECTIONS}
            currentPath="/cgu"
        >
            <LegalSection id="article-1" number={1} title="Objet">
                <p>
                    Les présentes Conditions Générales d'Utilisation et de Vente (ci-après
                    les « <strong>CGU</strong> ») ont pour objet de définir les modalités et
                    conditions dans lesquelles{" "}
                    <strong>
                        <Placeholder value={editor.legalName} label="Raison sociale"/>
                    </strong>{" "}
                    (ci-après « <strong>SejourFR</strong> » ou « nous ») met à disposition la
                    plateforme SejourFR, accessible via le site web{" "}
                    <a href={SITE.url}>
                        {SITE.url.replace(/^https?:\/\//, "")}
                    </a>{" "}
                    et les applications mobiles iOS et Android (ci-après la «{" "}
                    <strong>Plateforme</strong> »), et fournit ses services à
                    l'utilisateur (ci-après l'« <strong>Utilisateur</strong> » ou « vous »).
                </p>
                <p>
                    L'utilisation de la Plateforme implique l'acceptation pleine et entière
                    des présentes CGU. En créant un compte ou en achetant un pass d'accès,
                    vous reconnaissez avoir lu, compris et accepté l'intégralité des
                    présentes CGU.
                </p>
            </LegalSection>

            <LegalSection id="article-2" number={2} title="Définitions">
                <ul>
                    <li>
                        <strong>Plateforme</strong> : le site web accessible à l'adresse{" "}
                        {SITE.url} ainsi que les applications mobiles SejourFR distribuées
                        via l'App Store (Apple) et Google Play. Les présentes CGU
                        s'appliquent indifféremment à l'ensemble de ces supports.
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
                        <strong>Services</strong> : ensemble des fonctionnalités
                        d'entraînement proposées par la Plateforme, comprenant des questions
                        à choix multiples (QCM) inspirées du format de l'examen civique
                        officiel et du TCF, des examens blancs en conditions simulées, le
                        suivi de progression, ainsi que la possibilité de marquer des
                        questions en favori et de revoir les questions échouées.
                    </li>
                    <li>
                        <strong>Module</strong> : périmètre fonctionnel proposé par la
                        Plateforme. Deux modules sont disponibles : le module{" "}
                        <strong>Civique</strong> (entraînement à l'examen civique pour les
                        parcours CSP — titre de séjour, CR — résident, et NAT —
                        naturalisation) et le module <strong>TCF</strong> (entraînement
                        complémentaire aux compétences linguistiques évaluées par le Test de
                        Connaissance du Français pour les niveaux A2, B1 et B2).
                    </li>
                    <li>
                        <strong>Contenu Premium</strong> : ensemble des contenus accessibles
                        uniquement aux Utilisateurs ayant acheté un pass d'accès payant.
                    </li>
                    <li>
                        <strong>Examen civique</strong> : examen officiel exigé en France
                        pour certaines démarches administratives (titre de séjour,
                        naturalisation), tel que défini par la législation française en
                        vigueur. La Plateforme propose un entraînement à cet examen mais
                        n'est pas elle-même un centre d'examen agréé.
                    </li>
                    <li>
                        <strong>TCF</strong> : Test de Connaissance du Français, organisé
                        par France Éducation International. La Plateforme propose un
                        entraînement aux compétences linguistiques évaluées par le TCF mais
                        ne le fait pas passer.
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
                        l'Utilisateur s'engage à en informer SejourFR sans délai à l'adresse{" "}
                        <a href={`mailto:${editor.email}`}>{editor.email}</a>.
                    </p>
                </LegalSubsection>

                <LegalSubsection number="3.3" title="Suppression de compte">
                    <p>
                        L'Utilisateur peut <strong>supprimer son compte à tout moment</strong>,
                        directement depuis l'application mobile (Profil &gt; Supprimer mon
                        compte) ou en envoyant une demande à{" "}
                        <a href={`mailto:${editor.email}`}>{editor.email}</a>.
                    </p>
                    <p>
                        La suppression entraîne l'<strong>effacement des données
                        personnelles</strong> et des données de progression de l'Utilisateur
                        (progression, historique, favoris, etc.). Certaines données peuvent
                        être conservées de manière anonymisée lorsque la loi l'impose
                        (notamment les données de facturation, conservées pour la durée
                        légale applicable). La suppression met fin à l'accès aux Contenus
                        Premium dans les conditions de l'article 7.4, sans remboursement de
                        la période restant à courir.
                    </p>
                    <p>
                        Les passes achetés via l'App Store ou Google Play sont des accès à
                        durée déterminée sans renouvellement automatique ; aucune
                        résiliation auprès de la boutique n'est donc nécessaire.
                    </p>
                </LegalSubsection>
            </LegalSection>

            <LegalSection id="article-4" number={4} title="Description des services">
                <p>
                    SejourFR propose deux modules d'entraînement indépendants :
                </p>
                <ul>
                    <li>
                        <strong>Module Civique</strong> : entraînement à l'examen civique
                        officiel pour les trois parcours administratifs concernés (CSP —
                        titre de séjour, CR — résident, NAT — naturalisation).
                    </li>
                    <li>
                        <strong>Module TCF</strong> : entraînement complémentaire aux
                        compétences linguistiques évaluées par le Test de Connaissance du
                        Français (niveaux A2, B1 et B2).
                    </li>
                </ul>

                <LegalSubsection number="4.1" title="Accès gratuit">
                    <p>SejourFR propose un accès gratuit à la Plateforme comprenant, pour chaque module :</p>
                    <ul>
                        <li>
                            <strong>
                                {subscription.trialQuestionsPerModule} questions d'entraînement
                            </strong>{" "}
                            par module (Civique et TCF), avec correction immédiate ;
                        </li>
                        <li>
                            <strong>{subscription.trialSimulations} examen blanc</strong> en
                            conditions simulées (chronométré) par module, rejouable ;
                        </li>
                        <li>
                            L'accès au suivi de progression de base et aux explications
                            pédagogiques des questions consultées en mode entraînement.
                        </li>
                    </ul>
                </LegalSubsection>

                <LegalSubsection number="4.2" title="Accès Premium">
                    <p>Le pass Premium donne accès, pour le ou les modules concernés, à :</p>
                    <ul>
                        <li>
                            L'intégralité du catalogue de questions, organisées par thématique ;
                        </li>
                        <li>
                            Les examens blancs chronométrés en nombre illimité, en conditions
                            simulées ;
                        </li>
                        <li>
                            Le suivi détaillé de la progression par thématique et l'accès à
                            l'historique complet des sessions ;
                        </li>
                        <li>
                            Les explications pédagogiques pour chaque question, ainsi que les
                            fonctionnalités de révision (favoris et questions échouées).
                        </li>
                    </ul>
                    <p>
                        Les modalités précises de l'offre (passes disponibles, durée
                        d'accès, contenu de chaque pass) sont présentées sur la page{" "}
                        <Link href="/tarifs">Tarifs</Link> et confirmées au moment de
                        l'achat.
                    </p>
                </LegalSubsection>

                <LegalSubsection number="4.3" title="Évolution des services">
                    <p>
                        SejourFR se réserve le droit de modifier, faire évoluer, ajouter ou
                        supprimer des fonctionnalités à tout moment. Ces évolutions
                        prennent effet dès leur publication sur la Plateforme. La poursuite
                        de l'utilisation de la Plateforme après publication vaut
                        acceptation de ces évolutions.
                    </p>
                </LegalSubsection>
            </LegalSection>

            <LegalSection id="article-5" number={5} title="Nature et limites du service">
                <p>
                    SejourFR est un <strong>service d'entraînement aux examens</strong>.
                    La Plateforme propose des questions à choix multiples inspirées du
                    format de l'examen civique officiel et du TCF, ainsi que des examens
                    blancs en conditions simulées. Les contenus sont conçus à des fins
                    pédagogiques et <strong>ne reproduisent pas les questions officielles</strong>{" "}
                    de ces épreuves.
                </p>
                <p>
                    SejourFR n'est <strong>pas un organisme de formation agréé</strong>,
                    n'est pas un centre d'examen et ne délivre aucune attestation
                    officielle. La Plateforme n'accompagne pas l'Utilisateur dans ses
                    démarches administratives (constitution du dossier de titre de séjour,
                    ANEF, NATALI, dépôt en préfecture, demande de naturalisation, etc.) :
                    son objet est strictement limité à l'entraînement.
                </p>
                <p>
                    Si SejourFR vise à maximiser les chances de réussite par un
                    entraînement régulier, <strong>le service ne saurait garantir la
                    réussite aux épreuves officielles</strong> ni l'atteinte d'un niveau
                    TCF donné. La réussite dépend du candidat, de sa préparation globale
                    et des conditions de passage. La décision finale et la délivrance des
                    attestations relèvent exclusivement des organismes officiels
                    compétents — selon l'épreuve : les centres agréés (notamment ceux
                    opérés par France Éducation International et la Chambre de commerce
                    et d'industrie de Paris Île-de-France) et France Éducation
                    International pour l'examen civique selon le titre demandé, et France
                    Éducation International pour le TCF.
                </p>
                <p>
                    De même, l'obtention d'un titre de séjour, du statut de résident ou
                    de la nationalité française dépend de l'évaluation par les autorités
                    administratives compétentes (préfectures, Ministère de l'Intérieur),
                    selon des critères qui dépassent largement la seule réussite de
                    l'examen civique ou du TCF.
                </p>
            </LegalSection>

            <LegalSection id="article-6" number={6} title="Tarifs et paiement">
                <LegalSubsection number="6.1" title="Prix">
                    <p>
                        Les tarifs en vigueur sont indiqués sur la page{" "}
                        <Link href="/tarifs">Tarifs</Link> et rappelés au moment de
                        l'achat. Les prix sont indiqués en euros. SejourFR relève de la
                        franchise en base de TVA : TVA non applicable, art. 293 B du CGI.
                    </p>
                </LegalSubsection>

                <LegalSubsection number="6.2" title="Modalités de paiement">
                    <p>Le paiement s'effectue selon le canal utilisé :</p>
                    <ul>
                        <li>
                            sur le site web : en ligne par carte bancaire via notre
                            prestataire de paiement sécurisé{" "}
                            <strong>Stripe Payments Europe Ltd.</strong>, avec le protocole
                            3D-Secure ;
                        </li>
                        <li>
                            depuis les applications mobiles : via les systèmes de paiement
                            intégrés d'Apple (App Store) ou de Google (Google Play), selon
                            les modalités propres à ces boutiques.
                        </li>
                    </ul>
                    <p>
                        Aucune information bancaire n'est stockée sur les serveurs de
                        SejourFR, quel que soit le canal de paiement.
                    </p>
                </LegalSubsection>

                <LegalSubsection number="6.3" title="Passes d'accès à durée déterminée">
                    <p>
                        Les offres payantes prennent la forme de <strong>passes d'accès à
                        durée déterminée</strong>, réglés en un <strong>paiement
                        unique</strong>. Chaque pass ouvre l'accès aux Contenus Premium pour
                        la durée indiquée sur la page <Link href="/tarifs">Tarifs</Link>{" "}
                        (par exemple 7 jours, 2 mois ou 1 an), à compter de la validation
                        du paiement.
                    </p>
                    <p>
                        Les passes <strong>ne font l'objet d'aucune reconduction ni
                        renouvellement automatique</strong> : à l'expiration de la durée,
                        l'accès Premium prend fin et l'Utilisateur peut, s'il le souhaite,
                        acheter un nouveau pass. L'achat d'un nouveau pass avant l'expiration
                        du précédent proroge la durée d'accès, les durées se cumulant.
                    </p>
                    <p>
                        Lorsque l'achat est réalisé via une boutique d'application{" "}
                        (<strong>App Store d'Apple</strong> ou <strong>Google Play</strong>),
                        il est en outre soumis aux conditions de la boutique concernée, qui
                        agit comme intermédiaire de paiement.
                    </p>
                </LegalSubsection>

                <LegalSubsection number="6.4" title="Facturation">
                    <p>
                        Pour les achats réalisés sur le site web (paiement Stripe), une
                        facture est émise pour chaque paiement et envoyée par email à
                        l'adresse renseignée par l'Utilisateur. Pour les achats réalisés
                        via l'App Store ou Google Play, le justificatif d'achat est fourni
                        directement par Apple ou Google selon leurs modalités, SejourFR
                        n'émettant pas de facture pour ces transactions.
                    </p>
                </LegalSubsection>
            </LegalSection>

            <LegalSection id="article-7" number={7} title="Droit de rétractation">
                <p>
                    Conformément à l'article L221-18 du Code de la consommation, vous
                    disposez d'un délai de <strong>14 jours</strong> à compter de
                    l'achat pour exercer votre droit de rétractation, sans avoir à
                    justifier de motifs ni à payer de pénalités.
                </p>

                <LegalSubsection number="7.1" title="Modalités de rétractation">
                    <p>
                        Pour exercer ce droit, vous devez nous notifier votre décision par
                        une déclaration dénuée d'ambiguïté :
                    </p>
                    <ul>
                        <li>
                            Par email à :{" "}
                            <a href={`mailto:${editor.email}`}>{editor.email}</a>
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

                <LegalSubsection number="7.2" title="Effet de la rétractation">
                    <p>
                        En cas de rétractation, nous vous remboursons l'intégralité des
                        sommes versées dans un délai maximal de 14 jours à compter de la
                        réception de votre notification. Le remboursement s'effectue par le
                        même moyen de paiement que celui utilisé pour la transaction
                        initiale.
                    </p>
                </LegalSubsection>

                <LegalSubsection
                    number="7.3"
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

                <LegalSubsection
                    number="7.4"
                    title="Absence de remboursement après exécution"
                >
                    <p>
                        Sous réserve de l'exercice du droit de rétractation dans les
                        conditions de l'article 7.1 et hors renonciation prévue à l'article
                        7.3, le prix d'un pass d'accès est <strong>dû en totalité dès
                        l'achat</strong> et n'ouvre droit à <strong>aucun
                        remboursement</strong>, total ou partiel, une fois l'accès aux
                        Contenus Premium ouvert.
                    </p>
                    <p>
                        En particulier, <strong>aucune somme n'est remboursée</strong> au
                        prorata de la durée non utilisée si l'Utilisateur cesse d'utiliser le
                        service, demande la suppression de son compte (article 3) ou se voit
                        retirer l'accès pour un manquement à ses obligations (article 8),
                        avant le terme de son pass.
                    </p>
                    <LegalCallout
                        tone="warning"
                        title="Suppression de compte et accès payant"
                    >
                        <p>
                            La suppression du compte met fin <strong>immédiatement et
                            définitivement</strong> à l'accès aux Contenus Premium. La période
                            payée restant à courir est <strong>perdue et non
                            remboursable</strong>.
                        </p>
                    </LegalCallout>
                    <p>
                        Les achats effectués via l'App Store ou Google Play relèvent des
                        conditions de remboursement propres à ces boutiques : toute demande
                        de remboursement à ce titre doit être adressée{" "}
                        <strong>directement à Apple ou à Google</strong>, SejourFR n'ayant
                        pas la maîtrise de ces transactions.
                    </p>
                </LegalSubsection>
            </LegalSection>

            <LegalSection id="article-8" number={8} title="Engagements de l'Utilisateur">
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
                        SejourFR.
                    </li>
                </ul>
                <p>
                    Tout manquement à ces engagements peut entraîner la suspension ou la
                    suppression du compte, sans remboursement.
                </p>
            </LegalSection>

            <LegalSection id="article-9" number={9} title="Disponibilité du service">
                <p>
                    SejourFR met en œuvre tous les moyens raisonnables pour garantir une
                    disponibilité de la Plateforme 24h/24 et 7j/7. Toutefois, des
                    interruptions peuvent survenir pour des opérations de maintenance, des
                    défaillances techniques ou des cas de force majeure.
                </p>
                <p>
                    SejourFR ne saurait être tenue responsable de toute interruption ou
                    indisponibilité de la Plateforme. Aucun remboursement ne sera dû en
                    cas d'interruption ponctuelle.
                </p>
            </LegalSection>

            <LegalSection id="article-10" number={10} title="Limitation de responsabilité">
                <LegalSubsection number="10.1" title="Caractère indicatif des contenus">
                    <p>
                        Les contenus de la Plateforme sont fournis à titre informatif et
                        pédagogique, à des fins d'entraînement. Ils ne constituent en aucun
                        cas des conseils juridiques personnalisés ni un accompagnement aux
                        démarches administratives. Pour toute situation spécifique relative
                        au droit des étrangers ou à une démarche en cours, l'Utilisateur est
                        invité à consulter un professionnel compétent (avocat, juriste,
                        permanence associative habilitée).
                    </p>
                </LegalSubsection>

                <LegalSubsection number="10.2" title="Limitation">
                    <p>
                        SejourFR n'étant ni un organisme de formation agréé ni un centre
                        d'examen (cf. Article 5), elle ne saurait être tenue pour
                        responsable de l'échec d'un Utilisateur à l'examen civique, du
                        niveau atteint au TCF, ni du refus d'un titre de séjour ou de la
                        nationalité française par les autorités compétentes.
                    </p>
                    <p>
                        Dans toute la mesure permise par la loi, la responsabilité de
                        SejourFR est par ailleurs limitée au montant des passes d'accès
                        payés par l'Utilisateur sur les 12 derniers mois.
                    </p>
                </LegalSubsection>
            </LegalSection>

            <LegalSection id="article-11" number={11} title="Propriété intellectuelle">
                <p>
                    L'ensemble des contenus de la Plateforme (textes, questions, énoncés,
                    corrections, passages de compréhension écrite, illustrations, code
                    source, base de données, charte graphique) est protégé par le droit
                    d'auteur et le droit des marques. Les questions, leurs corrections et
                    les passages de compréhension écrite sont <strong>conçus par
                    l'équipe SejourFR à partir des référentiels et thématiques officiels
                    publiés</strong>, sans reproduction des questions officielles de
                    l'examen civique ou du TCF, lesquelles demeurent la propriété de
                    leurs ayants droit respectifs.
                </p>
                <p>
                    Toute reproduction, représentation, modification, publication,
                    extraction, totale ou partielle de la Plateforme ou de son contenu,
                    par quelque procédé que ce soit, est interdite sans l'autorisation
                    écrite et préalable de SejourFR, sous peine de poursuites civiles ou
                    pénales (article L.335-2 du Code de la propriété intellectuelle).
                </p>
            </LegalSection>

            <LegalSection id="article-12" number={12} title="Données personnelles">
                <p>
                    Le traitement de vos données personnelles est régi par notre{" "}
                    <Link href="/confidentialite">Politique de confidentialité</Link>,
                    conforme au Règlement Général sur la Protection des Données (RGPD)
                    et à la loi française Informatique et Libertés.
                </p>
            </LegalSection>

            <LegalSection id="article-13" number={13} title="Modifications des CGU">
                <p>
                    SejourFR se réserve le droit de modifier les présentes CGU à tout
                    moment. Les CGU modifiées entrent en vigueur dès leur publication sur
                    la Plateforme. La poursuite de l'utilisation de la Plateforme ou des
                    Services après cette publication vaut acceptation des CGU modifiées.
                    Il appartient à l'Utilisateur de consulter régulièrement la version en
                    vigueur, accessible à tout moment sur la Plateforme.
                </p>
            </LegalSection>

            <LegalSection id="article-14" number={14} title="Médiation et règlement des litiges">
                <p>
                    Conformément à l'article L612-1 du Code de la consommation, en cas de
                    litige non résolu après réclamation écrite auprès de SejourFR, vous
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

            <LegalSection id="article-15" number={15} title="Loi applicable et juridiction">
                <p>
                    Les présentes CGU sont régies par le droit français. À défaut de
                    résolution amiable, tout litige sera soumis aux tribunaux français
                    compétents.
                </p>
            </LegalSection>

            <LegalSection id="article-16" number={16} title="Contact">
                <ul>
                    <li>
                        Email :{" "}
                        <a href={`mailto:${editor.email}`}>{editor.email}</a>
                    </li>
                    <li>
                        <Link href="/contact">Formulaire de contact</Link>
                    </li>
                </ul>
            </LegalSection>
        </LegalPageLayout>
    );
}
