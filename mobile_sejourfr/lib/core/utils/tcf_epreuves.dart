/// **Ce qui est une épreuve du TCF IRN, et ce qui ne l'est pas.**
///
/// 🛑 Miroir mot pour mot de `web_sejoufr/lib/tcf-epreuves.ts`.
///
/// 🛑 **Le TCF IRN comporte QUATRE épreuves : CO, CE, EE, EO.**
/// « Structure de la langue » est un module d'entraînement **SejourFR**, hors
/// examen. Le backend le sait déjà partout où ça compte — elle est exclue de
/// l'examen blanc complet, du Plan (« epreuve hors des quatre du profil TCF
/// IRN ») et du diagnostic 4 épreuves. Seul l'**affichage** la rangeait au
/// milieu des officielles, et l'offre payante annonçait même « 5 épreuves ».
library;

/// Les quatre épreuves, dans l'ordre de l'examen. Codes du dashboard.
const List<String> kTcfEpreuvesOfficielles = [
  'TCF_CO',
  'TCF_CE',
  'TCF_EE',
  'TCF_EO',
];

/// Le module complémentaire, servi par le dashboard comme les autres.
const String kTcfCodeComplementaire = 'TCF_STRUCTURE';

/// L'eyebrow d'un écran de Structure de la langue.
const String kTcfComplementaireEyebrow = 'Entraînement complémentaire';

/// Le titre de la section qui l'accueille sur Réviser.
const String kTcfComplementaireSectionTitle = 'Renforcer mon français';

/// Le titre du bandeau d'information, sur Réviser comme sur le détail.
const String kTcfComplementaireNoteTitle = 'Entraînement complémentaire';

/// Le bandeau du **détail** du module.
const String kTcfComplementaireNote =
    'Module non évalué dans le TCF IRN officiel. Cet entraînement reste très '
    'utile pour consolider ta grammaire et progresser sur les autres épreuves.';

/// Le bandeau de **Réviser**, qui peut s'appuyer sur la liste juste au-dessus.
const String kTcfComplementaireNoteReviser =
    'Structure de la langue n\'est pas une épreuve du TCF IRN — les quatre '
    'épreuves officielles sont juste au-dessus. Le module reste très utile : '
    'chaque point de grammaire consolidé se retrouve en compréhension écrite, '
    'en expression écrite et à l\'oral.';
