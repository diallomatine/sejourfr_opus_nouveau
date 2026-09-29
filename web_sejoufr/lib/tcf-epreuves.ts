/**
 * **Ce qui est une épreuve du TCF IRN, et ce qui ne l'est pas.**
 *
 * 🛑 Miroir mot pour mot de `mobile_sejourfr/lib/core/utils/tcf_epreuves.dart`.
 *
 * 🛑 **Le TCF IRN comporte QUATRE épreuves : CO, CE, EE, EO.**
 * « Structure de la langue » est un module d'entraînement **SejourFR**, hors
 * examen. Le backend le sait déjà partout où ça compte — elle est exclue de
 * l'examen blanc complet (`AttemptCompositionService`), du Plan
 * (`PlanDomainAssessmentResolver` rend `null` : « epreuve hors des quatre du
 * profil TCF IRN ») et du diagnostic 4 épreuves. Seul l'**affichage** la
 * rangeait au milieu des officielles, et l'offre payante annonçait même
 * « 5 épreuves » là où la page de vente du même produit en disait 4.
 *
 * Autorité unique pour les deux : la liste des quatre, et les phrases qui
 * situent le module complémentaire.
 */

/** Les quatre épreuves, dans l'ordre de l'examen. Codes du dashboard. */
export const TCF_EPREUVES_OFFICIELLES = ["TCF_CO", "TCF_CE", "TCF_EE", "TCF_EO"] as const;

/** Le module complémentaire, servi par le dashboard comme les autres. */
export const TCF_CODE_COMPLEMENTAIRE = "TCF_STRUCTURE";

/** L'eyebrow d'un écran de Structure de la langue. */
export const TCF_COMPLEMENTAIRE_EYEBROW = "Entraînement complémentaire";

/** Le titre de la section qui l'accueille sur Réviser. */
export const TCF_COMPLEMENTAIRE_SECTION_TITLE = "Renforcer mon français";

/** Le titre du bandeau d'information, sur Réviser comme sur le détail. */
export const TCF_COMPLEMENTAIRE_NOTE_TITLE = "Entraînement complémentaire";

/**
 * Le bandeau du **détail** du module — miroir mot pour mot de
 * `TcfQcmModule.structure.notice` côté mobile, que le web n'avait pas.
 */
export const TCF_COMPLEMENTAIRE_NOTE =
    "Module non évalué dans le TCF IRN officiel. Cet entraînement reste très " +
    "utile pour consolider votre grammaire et progresser sur les autres épreuves.";

/**
 * Le bandeau de **Réviser**, qui peut s'appuyer sur la liste juste au-dessus.
 */
export const TCF_COMPLEMENTAIRE_NOTE_REVISER =
    "Structure de la langue n'est pas une épreuve du TCF IRN — les quatre " +
    "épreuves officielles sont juste au-dessus. Le module reste très utile : " +
    "chaque point de grammaire consolidé se retrouve en compréhension écrite, " +
    "en expression écrite et à l'oral.";
