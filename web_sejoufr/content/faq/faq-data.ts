/**
 * Données FAQ — 8 catégories, 38 questions/réponses.
 * Sources : Service-Public.fr, ministère de l'Intérieur, formation-civique.interieur.gouv.fr,
 * France Éducation International, Légifrance.
 *
 * Markdown léger supporté dans `answer` (rendu maison, pas de lib) :
 *   - **gras**
 *   - [texte](url)
 *   - listes commençant par "- " ou "1. "
 *   - paragraphes séparés par \n\n
 */

export type FAQCategoryColor = "blue" | "red" | "grey" | "amber" | "success";

export interface FAQItem {
  id: string;
  question: string;
  answer: string;
  tags?: string[];
}

export interface FAQCategory {
  id: string;
  name: string;
  /** Nom d'icône Lucide (ex: "FileText"). */
  icon: string;
  color: FAQCategoryColor;
  description?: string;
  items: FAQItem[];
}

export const FAQ_DATA: FAQCategory[] = [
  {
    id: "examen-generalites",
    name: "Examen civique : généralités",
    icon: "FileText",
    color: "blue",
    description:
      "Ce qu'est l'examen civique, pour qui il est obligatoire et ce qu'il évalue.",
    items: [
      {
        id: "q1-quest-ce-que-lexamen-civique",
        question: "Qu'est-ce que l'examen civique ?",
        answer:
          "L'examen civique est un test obligatoire mis en place par l'État français depuis le 1er janvier 2026. Il évalue la connaissance des principes et valeurs de la République, du fonctionnement des institutions, des droits et devoirs des citoyens, et de la société française. Il a été instauré par la loi du 26 janvier 2024 pour contrôler l'immigration et améliorer l'intégration.",
      },
      {
        id: "q2-pour-qui-obligatoire",
        question: "Pour qui l'examen civique est-il obligatoire ?",
        answer:
          "Depuis le 1er janvier 2026, l'examen civique est obligatoire pour :\n\n- Une première carte de séjour pluriannuelle (CSP) de 4 ans\n- Une première carte de résident (CR) de 10 ans\n- Une demande de naturalisation française par décret ou de réintégration dans la nationalité française\n\nL'attestation n'est **pas exigée** pour le renouvellement d'une CSP ou d'une CR déjà obtenue. Les procédures par déclaration (mariage avec un Français, ascendant ou frère/sœur d'un Français) ne sont pas concernées.",
      },
      {
        id: "q3-niveaux-examen",
        question: "Existe-t-il plusieurs niveaux d'examen civique ?",
        answer:
          "Oui, il existe trois niveaux selon le titre demandé :\n\n- **Mention CSP** (carte de séjour pluriannuelle) — niveau le plus accessible\n- **Mention CR** (carte de résident) — niveau intermédiaire\n- **Mention naturalisation** — niveau le plus exigeant\n\nLes questions portent sur les mêmes 5 thématiques officielles, mais avec une difficulté graduée.",
      },
      {
        id: "q4-thematiques-officielles",
        question: "Quelles sont les 5 thématiques officielles de l'examen ?",
        answer:
          "1. Principes et valeurs de la République\n2. Système institutionnel et politique\n3. Droits et devoirs\n4. Histoire, géographie et culture\n5. Vivre dans la société française",
      },
    ],
  },
  {
    id: "examen-format",
    name: "Format et déroulement",
    icon: "ClipboardList",
    color: "blue",
    description: "QCM, durée, seuil de réussite, résultats et validité.",
    items: [
      {
        id: "q5-questions-temps",
        question: "Combien de questions et combien de temps ?",
        answer:
          "L'examen comprend **40 questions à choix multiples (QCM)** en français. Vous disposez de **45 minutes maximum** pour y répondre. Chaque question propose 4 réponses, dont une seule est correcte.",
      },
      {
        id: "q6-types-questions",
        question: "Quels types de questions sont posées ?",
        answer:
          "L'examen contient deux types de questions :\n\n- **28 questions de connaissance** (faits historiques, institutions, dates clés, valeurs)\n- **12 questions de mises en situation** (cas pratiques de la vie quotidienne)",
      },
      {
        id: "q7-seuil-reussite",
        question: "Quel est le seuil de réussite ?",
        answer:
          "Vous devez obtenir au minimum **32 bonnes réponses sur 40, soit 80 %**.",
      },
      {
        id: "q8-deroulement",
        question: "Comment se déroule l'épreuve concrètement ?",
        answer:
          "L'examen se déroule sur **support numérique** (ordinateur ou tablette) dans un centre agréé. Le centre vous communique le règlement avant l'épreuve. En cas de non-respect du règlement, votre examen peut être annulé.",
      },
      {
        id: "q9-resultats",
        question: "Quand reçoit-on les résultats ?",
        answer:
          "Les résultats sont disponibles sur votre espace candidat dans un délai de **12 heures maximum** après le passage. En cas de réussite, vous obtenez votre attestation officielle directement téléchargeable.",
      },
      {
        id: "q10-validite-attestation",
        question: "L'attestation a-t-elle une durée de validité ?",
        answer:
          "Non. **L'attestation de réussite à l'examen civique a une validité illimitée** pour toutes les démarches administratives concernées.",
      },
    ],
  },
  {
    id: "inscription-couts",
    name: "Inscription et coûts",
    icon: "CreditCard",
    color: "amber",
    description: "Tarifs, centres agréés, démarches d'inscription, échec.",
    items: [
      {
        id: "q11-cout-examen",
        question: "Combien coûte l'examen civique ?",
        answer:
          "Les frais d'inscription sont fixés par chaque centre d'examen agréé. **Le coût est généralement compris entre 60 € et 100 €**, avec une moyenne autour de 70-90 €. Ces frais sont à la charge du candidat et **ne sont pas remboursables**, ni en cas d'échec, ni en cas d'absence.",
      },
      {
        id: "q12-ou-sinscrire",
        question: "Où s'inscrire à l'examen civique ?",
        answer:
          "Deux organismes sont agréés par le ministère de l'Intérieur pour organiser l'examen :\n\n- **CCI Paris Île-de-France (CCIP)** — Chambre de commerce et d'industrie\n- **France Éducation International (FEI)** — opérateur public du ministère de l'Éducation nationale\n\nChacun dispose de centres agréés répartis sur tout le territoire français. Vous choisissez le centre le plus proche selon votre domicile et le type de titre demandé.",
      },
      {
        id: "q13-inscription-pratique",
        question: "Comment se passe l'inscription en pratique ?",
        answer:
          "Vous devez :\n\n1. Créer un espace personnel sur le site du centre choisi (CCIP ou FEI)\n2. Renseigner vos informations et votre adresse mail\n3. Confirmer l'inscription via le mail reçu\n4. Réserver un créneau dans un centre proche\n5. Payer en ligne par carte bancaire",
      },
      {
        id: "q14-echec",
        question: "Que faire en cas d'échec ?",
        answer:
          "Vous pouvez **vous représenter autant de fois que nécessaire**. Il n'y a pas de délai d'attente obligatoire entre deux passages, mais comptez en pratique 2 à 4 semaines pour obtenir un nouveau créneau. **Chaque nouvelle tentative est facturée** au tarif plein, sans réduction.",
      },
      {
        id: "q15-preparation-gratuite",
        question: "La préparation à l'examen est-elle gratuite ?",
        answer:
          "La préparation peut être **totalement gratuite** grâce aux ressources officielles : le Livret du citoyen, la Charte des droits et devoirs du citoyen français, et la liste officielle des questions de connaissance, tous disponibles sur [formation-civique.interieur.gouv.fr](https://formation-civique.interieur.gouv.fr/). Des plateformes privées comme SéjourFR offrent en complément un entraînement structuré (QCM, examens blancs, suivi de progression).",
      },
      {
        id: "q16-aides-financieres",
        question: "Existe-t-il des aides financières pour passer l'examen ?",
        answer:
          "Les frais ne sont pas pris en charge par la Sécurité sociale ni par France Travail. Toutefois, certaines associations d'aide aux migrants et le CCAS (Centre Communal d'Action Sociale) de votre mairie peuvent vous orienter vers des dispositifs locaux d'accompagnement ou de financement.",
      },
    ],
  },
  {
    id: "amenagements",
    name: "Aménagements et dispenses",
    icon: "Accessibility",
    color: "amber",
    description: "Handicap, dispenses médicales, candidats à l'étranger.",
    items: [
      {
        id: "q17-amenagements-medicaux",
        question: "Peut-on bénéficier d'aménagements pour raison médicale ?",
        answer:
          "Oui. Si votre handicap ou votre état de santé le nécessite, vous pouvez demander un aménagement de l'épreuve (durée allongée, équipements adaptés, etc.). Vous devez fournir un **certificat médical** attestant de la nécessité et précisant les aménagements préconisés.",
      },
      {
        id: "q18-dispense-totale",
        question: "Peut-on être totalement dispensé de l'examen ?",
        answer:
          "Oui, dans des cas particuliers. Si votre handicap ou votre état de santé rend impossible l'évaluation de vos connaissances par un examen, vous pouvez en être dispensé sur présentation d'un certificat médical adapté. Le service instructeur peut demander une nouvelle expertise médicale.",
      },
      {
        id: "q19-residence-etranger",
        question: "Que se passe-t-il si l'on réside à l'étranger ?",
        answer:
          "Si vous résidez à l'étranger, vous devez vous adresser à un **institut français**, une **alliance française** ou aux **autorités consulaires** de votre pays de résidence pour connaître les modalités de passation.",
      },
    ],
  },
  {
    id: "entretien-naturalisation",
    name: "Entretien de naturalisation",
    icon: "MessagesSquare",
    color: "red",
    description:
      "Entretien d'assimilation, niveau de français B2, déroulement.",
    items: [
      {
        id: "q20-entretien-assimilation",
        question: "Qu'est-ce que l'entretien d'assimilation ?",
        answer:
          "L'entretien d'assimilation, également appelé entretien de naturalisation, est une **étape obligatoire** de la procédure de naturalisation par décret. Il se déroule en préfecture ou sous-préfecture, **après que votre dossier a été déclaré recevable**. Il est mené par un agent désigné par le préfet et dure généralement entre 20 et 40 minutes.",
      },
      {
        id: "q21-difference-examen-entretien",
        question:
          "Quelle est la différence entre l'examen civique et l'entretien ?",
        answer:
          "Ce sont **deux épreuves distinctes et complémentaires** :\n\n- **L'examen civique** : QCM standardisé qui évalue vos connaissances factuelles (histoire, institutions, valeurs). Format objectif, sur ordinateur, dans un centre agréé.\n- **L'entretien d'assimilation** : échange oral en préfecture qui évalue votre maîtrise du français à l'oral, votre adhésion aux valeurs républicaines et votre parcours d'intégration personnel.\n\nDepuis 2026, les **deux** sont obligatoires pour la naturalisation.",
      },
      {
        id: "q22-niveau-francais-naturalisation",
        question: "Quel niveau de français est exigé pour la naturalisation ?",
        answer:
          "Depuis le 1er janvier 2026, le **niveau B2** du Cadre européen commun de référence pour les langues (CECRL) est obligatoire (contre B1 auparavant). Vous devez fournir un certificat valide : **TCF IRN, DELF B2** ou diplôme équivalent.\n\n⚠️ **Le B2 doit être atteint dans les 4 épreuves** — compréhension orale, compréhension écrite, expression écrite, expression orale. L'attestation TCF IRN affiche un niveau **par épreuve** : il n'y a ni moyenne ni compensation. B2 partout sauf B1 en expression orale = **dossier refusé**, quels que soient les autres résultats.",
      },
      {
        id: "q23-niveaux-francais-titres",
        question: "Quels niveaux de français pour les autres titres ?",
        answer:
          "Depuis le 1er janvier 2026 :\n\n- Carte de séjour pluriannuelle (CSP) : **niveau A2**\n- Carte de résident (CR) : **niveau B1** (contre A2 auparavant)\n- Naturalisation : **niveau B2** (contre B1 auparavant)\n\nDans les trois cas, le niveau doit être atteint **dans les 4 épreuves** du test, sans moyenne ni compensation. Le TCF IRN n'évalue pas au-delà de B2.",
      },
      {
        id: "q24-deroulement-entretien",
        question: "Que se passe-t-il pendant l'entretien ?",
        answer:
          "L'agent peut vous interroger sur :\n\n- Votre **parcours personnel** (motivations, vie en France, intégration)\n- Les **valeurs républicaines** (laïcité, égalité, liberté)\n- Votre **maîtrise du français à l'oral**\n\nVous devez apporter les **originaux** des documents déposés sur l'ANEF. À la fin de l'entretien, vous **signez la Charte des droits et devoirs du citoyen français**.",
      },
      {
        id: "q25-echec-entretien",
        question: "Peut-on échouer à l'entretien d'assimilation ?",
        answer:
          "Oui. Le justificatif B2 prouve un niveau formel, mais l'agent évalue votre français en situation réelle. Un dossier solide sur le papier peut conduire à un avis défavorable si vous ne savez pas vous exprimer spontanément ou si vous ne connaissez pas les valeurs essentielles. Une bonne préparation est indispensable.",
      },
      {
        id: "q26-absence-entretien",
        question: "Que se passe-t-il si je ne me présente pas à l'entretien ?",
        answer:
          "Si vous ne vous présentez pas à l'entretien sans raison légitime, votre demande peut être **classée sans suite**, ce qui équivaut à un abandon de la procédure.",
      },
    ],
  },
  {
    id: "procedure-naturalisation",
    name: "Procédure de naturalisation",
    icon: "Landmark",
    color: "grey",
    description: "Conditions, dépôt sur ANEF, coûts, délais et suivi.",
    items: [
      {
        id: "q27-conditions-decret",
        question:
          "Quelles sont les conditions générales pour la naturalisation par décret ?",
        answer:
          "Vous devez :\n\n- Avoir **18 ans minimum** (dépôt possible dès 17 ans)\n- **Résider en France** depuis au moins 5 ans (réduction possible à 2 ans dans certains cas)\n- Avoir le **niveau B2 de français**\n- Avoir **réussi l'examen civique** (depuis 2026)\n- Justifier d'une **insertion stable** (ressources, emploi)\n- Avoir un **comportement respectueux** des valeurs républicaines (pas de condamnation grave, pas de fraude fiscale, etc.)",
      },
      {
        id: "q28-deposer-dossier",
        question: "Comment déposer son dossier ?",
        answer:
          "La demande de naturalisation se dépose en ligne sur la plateforme **ANEF** (Administration Numérique pour les Étrangers en France). Vous devez numériser ou photographier l'ensemble des pièces demandées. En cas de difficulté, vous pouvez vous rendre dans un Point d'accueil numérique en préfecture (sur rendez-vous) ou contacter le Centre de Contact Citoyens au **0 806 001 620** (gratuit).",
      },
      {
        id: "q29-cout-naturalisation",
        question: "Combien coûte une demande de naturalisation ?",
        answer:
          "La procédure est **gratuite** sauf pour le **timbre fiscal de 55 €** (27,50 € en Guyane), à acheter sur [timbres.impots.gouv.fr](https://timbres.impots.gouv.fr/) ou chez un buraliste. À cela s'ajoutent les **frais d'examen civique** (60-100 €) et les **frais de certification linguistique** (TCF IRN ou DELF B2, environ 100-200 € selon le centre).\n\n⚠️ Méfiez-vous des sites privés qui proposent des « services payants » pour la procédure : à part le timbre fiscal et l'examen civique, **la naturalisation est gratuite**.",
      },
      {
        id: "q30-delais-traitement",
        question: "Quels sont les délais de traitement ?",
        answer:
          "Le délai légal est de **18 mois** à partir du dépôt complet (ou **12 mois** si vous résidez régulièrement en France depuis au moins 10 ans), prolongeable une seule fois de 3 mois. En pratique, les délais varient entre **15 et 30 mois** selon la préfecture. La procédure se découpe en trois phases :\n\n1. Instruction préfectorale (3 à 9 mois)\n2. Contrôle central par la SDANF à Rezé (3 à 8 mois)\n3. Notification et cérémonie (1 à 3 mois)",
      },
      {
        id: "q31-procedure-traine",
        question: "Que faire si la procédure traîne ?",
        answer:
          "Si vous n'avez aucune nouvelle après **18 mois**, vous pouvez :\n\n- Envoyer un courrier recommandé à votre préfecture pour demander un point sur l'avancement\n- Saisir le **médiateur national de la naturalisation**\n- Suivre l'avancement en temps réel sur votre espace ANEF",
      },
      {
        id: "q32-decisions-prefet",
        question: "Quelles décisions peut prendre le préfet ?",
        answer:
          "À l'issue de l'instruction, le préfet peut :\n\n- **Proposer la naturalisation** (avis favorable transmis au ministère)\n- **Ajourner** votre demande (vous devrez attendre un délai avant de redéposer)\n- **Rejeter** votre demande (sur le fond)\n- **Déclarer la demande irrecevable** (sur la forme : conditions non remplies)",
      },
      {
        id: "q33-apres-avis-favorable",
        question: "Que se passe-t-il après l'avis favorable ?",
        answer:
          "Votre dossier est transmis à la **Sous-direction de l'accès à la nationalité française (SDANF)** située à Rezé. En cas de validation finale, votre nom est publié au **Journal Officiel** par décret. Vous êtes ensuite convoqué à une **cérémonie d'accueil dans la citoyenneté française**.",
      },
    ],
  },
  {
    id: "recours-refus",
    name: "Recours et refus",
    icon: "Scale",
    color: "grey",
    description: "Recours administratif, tribunal de Nantes, motifs de refus.",
    items: [
      {
        id: "q34-recours-refus",
        question: "Que faire en cas de refus de naturalisation ?",
        answer:
          "En cas d'ajournement ou de rejet, vous recevez un courrier motivé. Vous pouvez :\n\n- **Faire un recours administratif** dans un délai de **2 mois** auprès du ministre chargé des Naturalisations\n- Si ce recours est rejeté, **saisir le Tribunal administratif de Nantes** (compétent pour la nationalité)\n\nUn avocat spécialisé en droit des étrangers peut vous aider à monter le recours.",
      },
      {
        id: "q35-motifs-refus",
        question: "Quels sont les motifs fréquents de refus ?",
        answer:
          "Les principaux motifs sont :\n\n- Niveau de français insuffisant\n- Insertion professionnelle instable ou ressources insuffisantes\n- Condamnations pénales\n- Manquements aux obligations fiscales\n- Manque d'assimilation aux valeurs républicaines (apprécié à l'entretien)",
      },
    ],
  },
  {
    id: "preparation-sejourfr",
    name: "Préparation et SéjourFR",
    icon: "Sparkles",
    color: "success",
    description:
      "Comment SéjourFR vous accompagne, durée de préparation, avocat ou non.",
    items: [
      {
        id: "q36-sejourfr-aide",
        question: "Comment SéjourFR aide à préparer l'examen ?",
        answer:
          "SéjourFR propose une préparation complète :\n\n- **Plus de 350 questions officielles** organisées par catégorie (190 civique + 161 naturalisation), couvrant les 5 thématiques officielles\n- **20 examens blancs** par module (40 questions chronométrées chacune, conditions réelles)\n- **Suivi de progression** détaillé par thématique\n- **Explications pédagogiques** pour chaque question\n- **Mode entraînement** par catégorie et **mode examen blanc** chronométré\n\nVous pouvez commencer gratuitement avec **5 questions par catégorie** et **le 1er examen blanc de chaque module**, puis débloquer l'accès complet via l'abonnement.",
      },
      {
        id: "q37-temps-preparation",
        question: "Combien de temps faut-il pour se préparer ?",
        answer:
          "En moyenne, **4 semaines à raison de 30 minutes par jour** suffisent pour atteindre le niveau requis si vous partez de zéro. La régularité est plus efficace que les longues sessions ponctuelles. Si vous avez déjà une connaissance basique de la France, 2 à 3 semaines peuvent suffire.",
      },
      {
        id: "q38-avocat-procedure",
        question: "Faut-il payer un avocat pour la procédure ?",
        answer:
          "Non, ce n'est pas obligatoire. La procédure de naturalisation est conçue pour être accessible. Un avocat n'est nécessaire qu'**en cas de refus** (pour faire un recours) ou si votre dossier présente des **complexités juridiques particulières** (ancienne condamnation, statut administratif compliqué, etc.).",
      },
    ],
  },
];

/** Helper : aplatit toutes les questions (utile pour le JSON-LD et la recherche). */
export function getAllFaqItems(): Array<FAQItem & { categoryId: string }> {
  return FAQ_DATA.flatMap((cat) =>
    cat.items.map((it) => ({ ...it, categoryId: cat.id })),
  );
}

/**
 * Convertit une réponse markdown léger en texte brut pour le JSON-LD
 * (Google n'aime pas les balises markdown dans `acceptedAnswer.text`).
 */
export function answerToPlainText(md: string): string {
  return md
    .replace(/\*\*(.+?)\*\*/g, "$1") // gras
    .replace(/\[([^\]]+)\]\([^)]+\)/g, "$1") // liens [texte](url) → texte
    .replace(/\n+/g, " ")
    .replace(/\s{2,}/g, " ")
    .trim();
}
