-- ============================================================================
-- V130 : Seed des 18 taches d'expression du TCF IRN (EO + EE) -- A2 / B1 / B2.
-- ============================================================================
-- Cf. PRODUCTION_TASKS_SPEC_V2.md sections 1 et 12 (donnees de test).
--
-- Structure : 9 EO (tache 1/2/3 x A2/B1/B2) + 9 EE (idem).
-- Tous is_active = TRUE -> les seeds sont immediatement servies par
-- /api/production-tasks. L'admin pourra desactiver/ajouter par la suite.
--
-- Durees EO :
--   tache 1 (entretien dirige) : 180 sec (3 min)
--   tache 2 (jeu de role)      : 210 sec (3,5 min)
--   tache 3 (point de vue)     : 210 sec (3,5 min)
--
-- Plages de mots EE :
--   tache 1 (message simple)   : 60-120 mots
--   tache 2 (recit personnel)  : 120-150 mots
--   tache 3 (avis argumente)   : 150-180 mots
-- ============================================================================

-- Helpers : on construit les grilles d'evaluation comme constantes JSON
-- pour eviter la duplication dans chaque INSERT.

-- ============================================================================
-- EO -- A2
-- ============================================================================

-- A2 / Tache 1 : entretien dirige
INSERT INTO production_tasks (
    id, epreuve, tache_numero, niveau_cible, consigne, contexte,
    duree_max_sec, mots_min, mots_max, criteres_evaluation, is_active
) VALUES (
    gen_random_uuid(), 'TCF_EO', 1, 'A2',
    'Presentez-vous : votre nom, votre age, votre nationalite, votre profession ou vos etudes, et la ville ou vous habitez. Parlez aussi de votre famille (parents, freres, soeurs, conjoint, enfants).',
    NULL,
    180, NULL, NULL,
    '{
      "criteres": [
        {"code": "pertinence",    "label": "Pertinence du contenu",    "poids": 0.30},
        {"code": "grammaire",     "label": "Correction grammaticale",  "poids": 0.25},
        {"code": "vocabulaire",   "label": "Richesse lexicale",        "poids": 0.20},
        {"code": "coherence",     "label": "Coherence du discours",    "poids": 0.15},
        {"code": "prononciation", "label": "Prononciation",            "poids": 0.10}
      ],
      "niveau_attendu": "A2",
      "consignes_correcteur": "Le candidat doit pouvoir parler de lui-meme avec des phrases simples. Tolerer les hesitations, les pauses, et les erreurs de conjugaison sur les temps autres que le present. Valoriser un vocabulaire concret du quotidien."
    }'::jsonb,
    TRUE
);

-- A2 / Tache 2 : jeu de role (situation pratique)
INSERT INTO production_tasks (
    id, epreuve, tache_numero, niveau_cible, consigne, contexte,
    duree_max_sec, mots_min, mots_max, criteres_evaluation, is_active
) VALUES (
    gen_random_uuid(), 'TCF_EO', 2, 'A2',
    'Vous etes a la poste pour envoyer un colis a un ami en France. Demandez au guichetier le prix, le delai de livraison, et comment suivre le colis. Posez au moins 4 questions claires.',
    'Vous parlez avec l''examinateur qui joue le role du guichetier.',
    210, NULL, NULL,
    '{
      "criteres": [
        {"code": "pertinence",    "label": "Pertinence du contenu",    "poids": 0.30},
        {"code": "grammaire",     "label": "Correction grammaticale",  "poids": 0.25},
        {"code": "vocabulaire",   "label": "Richesse lexicale",        "poids": 0.20},
        {"code": "coherence",     "label": "Coherence du discours",    "poids": 0.15},
        {"code": "prononciation", "label": "Prononciation",            "poids": 0.10}
      ],
      "niveau_attendu": "A2",
      "consignes_correcteur": "Le candidat doit poser des questions intelligibles. Verifier qu''il sait formuler des questions directes (Est-ce que / Combien / Comment / Quand) avec un vocabulaire pratique."
    }'::jsonb,
    TRUE
);

-- A2 / Tache 3 : point de vue (avis simple)
INSERT INTO production_tasks (
    id, epreuve, tache_numero, niveau_cible, consigne, contexte,
    duree_max_sec, mots_min, mots_max, criteres_evaluation, is_active
) VALUES (
    gen_random_uuid(), 'TCF_EO', 3, 'A2',
    'Quel est votre moyen de transport prefere pour vous deplacer dans une grande ville ? Donnez deux avantages et un inconvenient.',
    NULL,
    210, NULL, NULL,
    '{
      "criteres": [
        {"code": "pertinence",    "label": "Pertinence du contenu",    "poids": 0.30},
        {"code": "grammaire",     "label": "Correction grammaticale",  "poids": 0.25},
        {"code": "vocabulaire",   "label": "Richesse lexicale",        "poids": 0.20},
        {"code": "coherence",     "label": "Coherence du discours",    "poids": 0.15},
        {"code": "prononciation", "label": "Prononciation",            "poids": 0.10}
      ],
      "niveau_attendu": "A2",
      "consignes_correcteur": "Avis simple attendu. Le candidat doit donner son opinion avec des connecteurs basiques (parce que, mais, aussi). Pas d''exigence d''argumentation poussee."
    }'::jsonb,
    TRUE
);

-- ============================================================================
-- EO -- B1
-- ============================================================================

INSERT INTO production_tasks (
    id, epreuve, tache_numero, niveau_cible, consigne, contexte,
    duree_max_sec, mots_min, mots_max, criteres_evaluation, is_active
) VALUES (
    gen_random_uuid(), 'TCF_EO', 1, 'B1',
    'Presentez-vous en developpant : votre parcours scolaire ou professionnel, vos centres d''interet, et ce qui vous a amene en France (ou ce qui vous y attire si vous etes a l''etranger).',
    NULL,
    180, NULL, NULL,
    '{
      "criteres": [
        {"code": "pertinence",    "label": "Pertinence du contenu",    "poids": 0.30},
        {"code": "grammaire",     "label": "Correction grammaticale",  "poids": 0.25},
        {"code": "vocabulaire",   "label": "Richesse lexicale",        "poids": 0.20},
        {"code": "coherence",     "label": "Coherence du discours",    "poids": 0.15},
        {"code": "prononciation", "label": "Prononciation",            "poids": 0.10}
      ],
      "niveau_attendu": "B1",
      "consignes_correcteur": "Le candidat doit construire un discours suivi sur des sujets familiers, utiliser le passe compose et l''imparfait correctement, et marquer la causalite (parce que, donc, alors)."
    }'::jsonb,
    TRUE
);

INSERT INTO production_tasks (
    id, epreuve, tache_numero, niveau_cible, consigne, contexte,
    duree_max_sec, mots_min, mots_max, criteres_evaluation, is_active
) VALUES (
    gen_random_uuid(), 'TCF_EO', 2, 'B1',
    'Vous avez achete un appareil electronique qui ne fonctionne pas correctement depuis sa livraison. Vous appelez le service apres-vente pour expliquer le probleme, demander une reparation ou un remboursement, et negocier un delai. Soyez clair et courtois.',
    'L''examinateur joue le conseiller du service apres-vente.',
    210, NULL, NULL,
    '{
      "criteres": [
        {"code": "pertinence",    "label": "Pertinence du contenu",    "poids": 0.30},
        {"code": "grammaire",     "label": "Correction grammaticale",  "poids": 0.25},
        {"code": "vocabulaire",   "label": "Richesse lexicale",        "poids": 0.20},
        {"code": "coherence",     "label": "Coherence du discours",    "poids": 0.15},
        {"code": "prononciation", "label": "Prononciation",            "poids": 0.10}
      ],
      "niveau_attendu": "B1",
      "consignes_correcteur": "Le candidat doit exposer un probleme, demander une action, et negocier. Verifier l''emploi du conditionnel de politesse (je voudrais, pourriez-vous) et la capacite a reformuler."
    }'::jsonb,
    TRUE
);

INSERT INTO production_tasks (
    id, epreuve, tache_numero, niveau_cible, consigne, contexte,
    duree_max_sec, mots_min, mots_max, criteres_evaluation, is_active
) VALUES (
    gen_random_uuid(), 'TCF_EO', 3, 'B1',
    'Pensez-vous que les reseaux sociaux ont plus d''avantages ou plus d''inconvenients dans la vie quotidienne ? Donnez votre avis avec au moins deux arguments illustres par des exemples.',
    NULL,
    210, NULL, NULL,
    '{
      "criteres": [
        {"code": "pertinence",    "label": "Pertinence du contenu",    "poids": 0.30},
        {"code": "grammaire",     "label": "Correction grammaticale",  "poids": 0.25},
        {"code": "vocabulaire",   "label": "Richesse lexicale",        "poids": 0.20},
        {"code": "coherence",     "label": "Coherence du discours",    "poids": 0.15},
        {"code": "prononciation", "label": "Prononciation",            "poids": 0.10}
      ],
      "niveau_attendu": "B1",
      "consignes_correcteur": "Une opinion claire avec deux arguments illustres. Connecteurs attendus : d''abord, ensuite, par exemple, en revanche. Le candidat doit etre capable de nuancer (en general, parfois)."
    }'::jsonb,
    TRUE
);

-- ============================================================================
-- EO -- B2
-- ============================================================================

INSERT INTO production_tasks (
    id, epreuve, tache_numero, niveau_cible, consigne, contexte,
    duree_max_sec, mots_min, mots_max, criteres_evaluation, is_active
) VALUES (
    gen_random_uuid(), 'TCF_EO', 1, 'B2',
    'Presentez-vous en mettant en avant un projet personnel ou professionnel qui vous tient particulierement a coeur. Expliquez d''ou il vient, ce qu''il represente pour vous, et ce que vous esperez en retirer.',
    NULL,
    180, NULL, NULL,
    '{
      "criteres": [
        {"code": "pertinence",    "label": "Pertinence du contenu",    "poids": 0.30},
        {"code": "grammaire",     "label": "Correction grammaticale",  "poids": 0.25},
        {"code": "vocabulaire",   "label": "Richesse lexicale",        "poids": 0.20},
        {"code": "coherence",     "label": "Coherence du discours",    "poids": 0.15},
        {"code": "prononciation", "label": "Prononciation",            "poids": 0.10}
      ],
      "niveau_attendu": "B2",
      "consignes_correcteur": "Discours structure et nuance. Subordonnees variees, articulation logique explicite, vocabulaire precis. Le candidat doit pouvoir expliquer ses motivations sans tomber dans les generalites."
    }'::jsonb,
    TRUE
);

INSERT INTO production_tasks (
    id, epreuve, tache_numero, niveau_cible, consigne, contexte,
    duree_max_sec, mots_min, mots_max, criteres_evaluation, is_active
) VALUES (
    gen_random_uuid(), 'TCF_EO', 2, 'B2',
    'Vous postulez pour un emploi qui vous interesse beaucoup mais pour lequel vous etes un peu sous-qualifie sur un critere precis. Lors d''un entretien telephonique, vous devez expliquer pourquoi vous restez un bon candidat, donner des exemples concrets de vos competences, et proposer une voie de progression.',
    'L''examinateur joue le recruteur, plutot reserve.',
    210, NULL, NULL,
    '{
      "criteres": [
        {"code": "pertinence",    "label": "Pertinence du contenu",    "poids": 0.30},
        {"code": "grammaire",     "label": "Correction grammaticale",  "poids": 0.25},
        {"code": "vocabulaire",   "label": "Richesse lexicale",        "poids": 0.20},
        {"code": "coherence",     "label": "Coherence du discours",    "poids": 0.15},
        {"code": "prononciation", "label": "Prononciation",            "poids": 0.10}
      ],
      "niveau_attendu": "B2",
      "consignes_correcteur": "Le candidat doit savoir argumenter sous contrainte, reformuler en reponse a une objection, et utiliser un registre soutenu. Verifier l''aisance dans la gestion d''un tour de parole adverse."
    }'::jsonb,
    TRUE
);

INSERT INTO production_tasks (
    id, epreuve, tache_numero, niveau_cible, consigne, contexte,
    duree_max_sec, mots_min, mots_max, criteres_evaluation, is_active
) VALUES (
    gen_random_uuid(), 'TCF_EO', 3, 'B2',
    'Certaines entreprises imposent le retour au bureau cinq jours par semaine, d''autres laissent la liberte totale aux salaries. Quelle organisation du travail vous semble la plus juste et la plus efficace ? Defendez votre position en envisageant au moins une objection que pourrait formuler quelqu''un en desaccord avec vous.',
    NULL,
    210, NULL, NULL,
    '{
      "criteres": [
        {"code": "pertinence",    "label": "Pertinence du contenu",    "poids": 0.30},
        {"code": "grammaire",     "label": "Correction grammaticale",  "poids": 0.25},
        {"code": "vocabulaire",   "label": "Richesse lexicale",        "poids": 0.20},
        {"code": "coherence",     "label": "Coherence du discours",    "poids": 0.15},
        {"code": "prononciation", "label": "Prononciation",            "poids": 0.10}
      ],
      "niveau_attendu": "B2",
      "consignes_correcteur": "Argumentation a deux temps : these + anticipation d''une objection. Verifier l''emploi du subjonctif (bien que, a moins que), des connecteurs concessifs, et la precision lexicale (organisation, productivite, autonomie)."
    }'::jsonb,
    TRUE
);

-- ============================================================================
-- EE -- A2
-- ============================================================================

INSERT INTO production_tasks (
    id, epreuve, tache_numero, niveau_cible, consigne, contexte,
    duree_max_sec, mots_min, mots_max, criteres_evaluation, is_active
) VALUES (
    gen_random_uuid(), 'TCF_EE', 1, 'A2',
    'Vous venez d''emmenager dans un nouveau quartier. Ecrivez un message a un ami pour lui annoncer la nouvelle, lui decrire brievement votre nouveau logement, et l''inviter a venir vous voir un week-end.',
    NULL,
    NULL, 60, 120,
    '{
      "criteres": [
        {"code": "pertinence",  "label": "Pertinence du contenu",   "poids": 0.30},
        {"code": "grammaire",   "label": "Correction grammaticale", "poids": 0.30},
        {"code": "vocabulaire", "label": "Richesse lexicale",       "poids": 0.20},
        {"code": "coherence",   "label": "Coherence du discours",   "poids": 0.20}
      ],
      "niveau_attendu": "A2",
      "consignes_correcteur": "Message court et clair. Verifier que les trois elements demandes sont presents. Tolerer les fautes de conjugaison basiques mais signaler les structures essentielles fausses (etre/avoir au present)."
    }'::jsonb,
    TRUE
);

INSERT INTO production_tasks (
    id, epreuve, tache_numero, niveau_cible, consigne, contexte,
    duree_max_sec, mots_min, mots_max, criteres_evaluation, is_active
) VALUES (
    gen_random_uuid(), 'TCF_EE', 2, 'A2',
    'Racontez la derniere fois que vous etes alle au restaurant ou a une fete : quand cetait, avec qui, ce que vous avez mange ou fait, et si vous avez aime ou non.',
    NULL,
    NULL, 120, 150,
    '{
      "criteres": [
        {"code": "pertinence",  "label": "Pertinence du contenu",   "poids": 0.30},
        {"code": "grammaire",   "label": "Correction grammaticale", "poids": 0.30},
        {"code": "vocabulaire", "label": "Richesse lexicale",       "poids": 0.20},
        {"code": "coherence",   "label": "Coherence du discours",   "poids": 0.20}
      ],
      "niveau_attendu": "A2",
      "consignes_correcteur": "Recit court au passe. Verifier l''emploi du passe compose, les expressions de temps (hier, le week-end dernier, apres). Tolerer les erreurs d''accord du participe passe."
    }'::jsonb,
    TRUE
);

INSERT INTO production_tasks (
    id, epreuve, tache_numero, niveau_cible, consigne, contexte,
    duree_max_sec, mots_min, mots_max, criteres_evaluation, is_active
) VALUES (
    gen_random_uuid(), 'TCF_EE', 3, 'A2',
    'Preferez-vous vivre en ville ou a la campagne ? Donnez votre opinion et expliquez deux raisons.',
    NULL,
    NULL, 150, 180,
    '{
      "criteres": [
        {"code": "pertinence",  "label": "Pertinence du contenu",   "poids": 0.30},
        {"code": "grammaire",   "label": "Correction grammaticale", "poids": 0.30},
        {"code": "vocabulaire", "label": "Richesse lexicale",       "poids": 0.20},
        {"code": "coherence",   "label": "Coherence du discours",   "poids": 0.20}
      ],
      "niveau_attendu": "A2",
      "consignes_correcteur": "Opinion simple + deux raisons. Le candidat doit savoir introduire son avis (je pense que, pour moi) et justifier (parce que, c''est pourquoi)."
    }'::jsonb,
    TRUE
);

-- ============================================================================
-- EE -- B1
-- ============================================================================

INSERT INTO production_tasks (
    id, epreuve, tache_numero, niveau_cible, consigne, contexte,
    duree_max_sec, mots_min, mots_max, criteres_evaluation, is_active
) VALUES (
    gen_random_uuid(), 'TCF_EE', 1, 'B1',
    'Vous avez assiste a un evenement marquant dans votre quartier (panne d''electricite, embouteillage exceptionnel, fete locale...). Ecrivez un message a un proche pour lui raconter ce qui s''est passe et expliquer comment vous avez vecu la situation.',
    NULL,
    NULL, 60, 120,
    '{
      "criteres": [
        {"code": "pertinence",  "label": "Pertinence du contenu",   "poids": 0.30},
        {"code": "grammaire",   "label": "Correction grammaticale", "poids": 0.30},
        {"code": "vocabulaire", "label": "Richesse lexicale",       "poids": 0.20},
        {"code": "coherence",   "label": "Coherence du discours",   "poids": 0.20}
      ],
      "niveau_attendu": "B1",
      "consignes_correcteur": "Recit court avec une dimension subjective. Verifier l''alternance passe compose / imparfait pour distinguer evenement et contexte."
    }'::jsonb,
    TRUE
);

INSERT INTO production_tasks (
    id, epreuve, tache_numero, niveau_cible, consigne, contexte,
    duree_max_sec, mots_min, mots_max, criteres_evaluation, is_active
) VALUES (
    gen_random_uuid(), 'TCF_EE', 2, 'B1',
    'Racontez une experience qui vous a appris quelque chose d''important sur vous-meme (un voyage, une rencontre, un travail, un echec...). Decrivez le contexte, ce qui s''est passe, et ce que vous en avez retenu.',
    NULL,
    NULL, 120, 150,
    '{
      "criteres": [
        {"code": "pertinence",  "label": "Pertinence du contenu",   "poids": 0.30},
        {"code": "grammaire",   "label": "Correction grammaticale", "poids": 0.30},
        {"code": "vocabulaire", "label": "Richesse lexicale",       "poids": 0.20},
        {"code": "coherence",   "label": "Coherence du discours",   "poids": 0.20}
      ],
      "niveau_attendu": "B1",
      "consignes_correcteur": "Recit structure en trois temps. Verifier la progression contextuelle (au depart, ensuite, finalement) et la presence d''une analyse personnelle."
    }'::jsonb,
    TRUE
);

INSERT INTO production_tasks (
    id, epreuve, tache_numero, niveau_cible, consigne, contexte,
    duree_max_sec, mots_min, mots_max, criteres_evaluation, is_active
) VALUES (
    gen_random_uuid(), 'TCF_EE', 3, 'B1',
    'Faut-il limiter le temps d''ecran des enfants ? Donnez votre avis en defendant votre position avec deux arguments concrets et au moins un exemple personnel ou observe.',
    NULL,
    NULL, 150, 180,
    '{
      "criteres": [
        {"code": "pertinence",  "label": "Pertinence du contenu",   "poids": 0.30},
        {"code": "grammaire",   "label": "Correction grammaticale", "poids": 0.30},
        {"code": "vocabulaire", "label": "Richesse lexicale",       "poids": 0.20},
        {"code": "coherence",   "label": "Coherence du discours",   "poids": 0.20}
      ],
      "niveau_attendu": "B1",
      "consignes_correcteur": "Argumentation en deux temps avec illustration. Verifier les connecteurs (en effet, par exemple, d''ailleurs) et le maintien d''un point de vue clair du debut a la fin."
    }'::jsonb,
    TRUE
);

-- ============================================================================
-- EE -- B2
-- ============================================================================

INSERT INTO production_tasks (
    id, epreuve, tache_numero, niveau_cible, consigne, contexte,
    duree_max_sec, mots_min, mots_max, criteres_evaluation, is_active
) VALUES (
    gen_random_uuid(), 'TCF_EE', 1, 'B2',
    'Vous avez recu un service de mauvaise qualite (restaurant, hotel, service en ligne...). Ecrivez un message courtois mais ferme au prestataire pour decrire ce qui ne vous a pas convenu, demander une compensation, et indiquer ce que vous attendez en retour.',
    NULL,
    NULL, 60, 120,
    '{
      "criteres": [
        {"code": "pertinence",  "label": "Pertinence du contenu",   "poids": 0.30},
        {"code": "grammaire",   "label": "Correction grammaticale", "poids": 0.30},
        {"code": "vocabulaire", "label": "Richesse lexicale",       "poids": 0.20},
        {"code": "coherence",   "label": "Coherence du discours",   "poids": 0.20}
      ],
      "niveau_attendu": "B2",
      "consignes_correcteur": "Registre formel mais ferme. Verifier les formules d''appel et de cloture, le conditionnel de politesse, et la precision du vocabulaire commercial (prestation, dedommagement, geste commercial)."
    }'::jsonb,
    TRUE
);

INSERT INTO production_tasks (
    id, epreuve, tache_numero, niveau_cible, consigne, contexte,
    duree_max_sec, mots_min, mots_max, criteres_evaluation, is_active
) VALUES (
    gen_random_uuid(), 'TCF_EE', 2, 'B2',
    'Racontez une situation ou vous avez du prendre une decision difficile dont vous mesurez aujourd''hui les consequences (un choix de carriere, une rupture, un demenagement, un engagement...). Decrivez le contexte, votre cheminement, et le regard que vous portez aujourd''hui sur ce choix.',
    NULL,
    NULL, 120, 150,
    '{
      "criteres": [
        {"code": "pertinence",  "label": "Pertinence du contenu",   "poids": 0.30},
        {"code": "grammaire",   "label": "Correction grammaticale", "poids": 0.30},
        {"code": "vocabulaire", "label": "Richesse lexicale",       "poids": 0.20},
        {"code": "coherence",   "label": "Coherence du discours",   "poids": 0.20}
      ],
      "niveau_attendu": "B2",
      "consignes_correcteur": "Recit reflexif. Verifier l''emploi du plus-que-parfait (action anterieure), du conditionnel passe (regret/projection), et la capacite a prendre du recul sur l''experience."
    }'::jsonb,
    TRUE
);

INSERT INTO production_tasks (
    id, epreuve, tache_numero, niveau_cible, consigne, contexte,
    duree_max_sec, mots_min, mots_max, criteres_evaluation, is_active
) VALUES (
    gen_random_uuid(), 'TCF_EE', 3, 'B2',
    'L''intelligence artificielle va-t-elle ameliorer ou degrader la qualite de l''education dans les annees a venir ? Defendez une position nuancee : exposez votre these, etayez-la avec au moins deux arguments, et envisagez explicitement une objection que vous discutez.',
    NULL,
    NULL, 150, 180,
    '{
      "criteres": [
        {"code": "pertinence",  "label": "Pertinence du contenu",   "poids": 0.30},
        {"code": "grammaire",   "label": "Correction grammaticale", "poids": 0.30},
        {"code": "vocabulaire", "label": "Richesse lexicale",       "poids": 0.20},
        {"code": "coherence",   "label": "Coherence du discours",   "poids": 0.20}
      ],
      "niveau_attendu": "B2",
      "consignes_correcteur": "Argumentation en trois temps (these + arguments + objection traitee). Verifier les connecteurs concessifs (certes... toutefois, bien que, neanmoins) et la precision conceptuelle (apprentissage personnalise, automatisation, biais)."
    }'::jsonb,
    TRUE
);
