-- ============================================================================
-- V130 : Seed des 18 tâches d'expression du TCF IRN (EO + EE) -- A2 / B1 / B2.
-- ============================================================================
-- Cf. PRODUCTION_TASKS_SPEC_V2.md sections 1 et 12 (données de test).
--
-- Structure : 9 EO (tâche 1/2/3 x A2/B1/B2) + 9 EE (idem).
-- Tous is_active = TRUE -> les seeds sont immédiatement servies par
-- /api/production-tasks. L'admin pourra désactiver/ajouter par la suite.
--
-- Durées EO :
--   tâche 1 (entretien dirigé) : 180 sec (3 min)
--   tâche 2 (jeu de rôle)      : 210 sec (3,5 min)
--   tâche 3 (point de vue)     : 210 sec (3,5 min)
--
-- Plages de mots EE :
--   tâche 1 (message simple)   : 60-120 mots
--   tâche 2 (récit personnel)  : 120-150 mots
--   tâche 3 (avis argumenté)   : 150-180 mots
-- ============================================================================

-- Helpers : on construit les grilles d'évaluation comme constantes JSON
-- pour éviter la duplication dans chaque INSERT.

-- ============================================================================
-- EO -- A2
-- ============================================================================

-- A2 / Tâche 1 : entretien dirigé
INSERT INTO production_tasks (
    id, epreuve, tache_numero, niveau_cible, consigne, contexte,
    duree_max_sec, mots_min, mots_max, criteres_evaluation, is_active
) VALUES (
    gen_random_uuid(), 'TCF_EO', 1, 'A2',
    'Présentez-vous : votre nom, votre âge, votre nationalité, votre profession ou vos études, et la ville où vous habitez. Parlez aussi de votre famille (parents, frères, sœurs, conjoint, enfants).',
    NULL,
    180, NULL, NULL,
    '{
      "criteres": [
        {"code": "pertinence",    "label": "Pertinence du contenu",    "poids": 0.30},
        {"code": "grammaire",     "label": "Correction grammaticale",  "poids": 0.25},
        {"code": "vocabulaire",   "label": "Richesse lexicale",        "poids": 0.20},
        {"code": "coherence",     "label": "Cohérence du discours",    "poids": 0.15},
        {"code": "prononciation", "label": "Prononciation",            "poids": 0.10}
      ],
      "niveau_attendu": "A2",
      "consignes_correcteur": "Le candidat doit pouvoir parler de lui-même avec des phrases simples. Tolérer les hésitations, les pauses, et les erreurs de conjugaison sur les temps autres que le présent. Valoriser un vocabulaire concret du quotidien."
    }'::jsonb,
    TRUE
);

-- A2 / Tâche 2 : jeu de rôle (situation pratique)
INSERT INTO production_tasks (
    id, epreuve, tache_numero, niveau_cible, consigne, contexte,
    duree_max_sec, mots_min, mots_max, criteres_evaluation, is_active
) VALUES (
    gen_random_uuid(), 'TCF_EO', 2, 'A2',
    'Vous êtes à la poste pour envoyer un colis à un ami en France. Demandez au guichetier le prix, le délai de livraison, et comment suivre le colis. Posez au moins 4 questions claires.',
    'Vous parlez avec l''examinateur qui joue le rôle du guichetier.',
    210, NULL, NULL,
    '{
      "criteres": [
        {"code": "pertinence",    "label": "Pertinence du contenu",    "poids": 0.30},
        {"code": "grammaire",     "label": "Correction grammaticale",  "poids": 0.25},
        {"code": "vocabulaire",   "label": "Richesse lexicale",        "poids": 0.20},
        {"code": "coherence",     "label": "Cohérence du discours",    "poids": 0.15},
        {"code": "prononciation", "label": "Prononciation",            "poids": 0.10}
      ],
      "niveau_attendu": "A2",
      "consignes_correcteur": "Le candidat doit poser des questions intelligibles. Vérifier qu''il sait formuler des questions directes (Est-ce que / Combien / Comment / Quand) avec un vocabulaire pratique."
    }'::jsonb,
    TRUE
);

-- A2 / Tâche 3 : point de vue (avis simple)
INSERT INTO production_tasks (
    id, epreuve, tache_numero, niveau_cible, consigne, contexte,
    duree_max_sec, mots_min, mots_max, criteres_evaluation, is_active
) VALUES (
    gen_random_uuid(), 'TCF_EO', 3, 'A2',
    'Quel est votre moyen de transport préféré pour vous déplacer dans une grande ville ? Donnez deux avantages et un inconvénient.',
    NULL,
    210, NULL, NULL,
    '{
      "criteres": [
        {"code": "pertinence",    "label": "Pertinence du contenu",    "poids": 0.30},
        {"code": "grammaire",     "label": "Correction grammaticale",  "poids": 0.25},
        {"code": "vocabulaire",   "label": "Richesse lexicale",        "poids": 0.20},
        {"code": "coherence",     "label": "Cohérence du discours",    "poids": 0.15},
        {"code": "prononciation", "label": "Prononciation",            "poids": 0.10}
      ],
      "niveau_attendu": "A2",
      "consignes_correcteur": "Avis simple attendu. Le candidat doit donner son opinion avec des connecteurs basiques (parce que, mais, aussi). Pas d''exigence d''argumentation poussée."
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
    'Présentez-vous en développant : votre parcours scolaire ou professionnel, vos centres d''intérêt, et ce qui vous a amené en France (ou ce qui vous y attire si vous êtes à l''étranger).',
    NULL,
    180, NULL, NULL,
    '{
      "criteres": [
        {"code": "pertinence",    "label": "Pertinence du contenu",    "poids": 0.30},
        {"code": "grammaire",     "label": "Correction grammaticale",  "poids": 0.25},
        {"code": "vocabulaire",   "label": "Richesse lexicale",        "poids": 0.20},
        {"code": "coherence",     "label": "Cohérence du discours",    "poids": 0.15},
        {"code": "prononciation", "label": "Prononciation",            "poids": 0.10}
      ],
      "niveau_attendu": "B1",
      "consignes_correcteur": "Le candidat doit construire un discours suivi sur des sujets familiers, utiliser le passé composé et l''imparfait correctement, et marquer la causalité (parce que, donc, alors)."
    }'::jsonb,
    TRUE
);

INSERT INTO production_tasks (
    id, epreuve, tache_numero, niveau_cible, consigne, contexte,
    duree_max_sec, mots_min, mots_max, criteres_evaluation, is_active
) VALUES (
    gen_random_uuid(), 'TCF_EO', 2, 'B1',
    'Vous avez acheté un appareil électronique qui ne fonctionne pas correctement depuis sa livraison. Vous appelez le service après-vente pour expliquer le problème, demander une réparation ou un remboursement, et négocier un délai. Soyez clair et courtois.',
    'L''examinateur joue le conseiller du service après-vente.',
    210, NULL, NULL,
    '{
      "criteres": [
        {"code": "pertinence",    "label": "Pertinence du contenu",    "poids": 0.30},
        {"code": "grammaire",     "label": "Correction grammaticale",  "poids": 0.25},
        {"code": "vocabulaire",   "label": "Richesse lexicale",        "poids": 0.20},
        {"code": "coherence",     "label": "Cohérence du discours",    "poids": 0.15},
        {"code": "prononciation", "label": "Prononciation",            "poids": 0.10}
      ],
      "niveau_attendu": "B1",
      "consignes_correcteur": "Le candidat doit exposer un problème, demander une action, et négocier. Vérifier l''emploi du conditionnel de politesse (je voudrais, pourriez-vous) et la capacité à reformuler."
    }'::jsonb,
    TRUE
);

INSERT INTO production_tasks (
    id, epreuve, tache_numero, niveau_cible, consigne, contexte,
    duree_max_sec, mots_min, mots_max, criteres_evaluation, is_active
) VALUES (
    gen_random_uuid(), 'TCF_EO', 3, 'B1',
    'Pensez-vous que les réseaux sociaux ont plus d''avantages ou plus d''inconvénients dans la vie quotidienne ? Donnez votre avis avec au moins deux arguments illustrés par des exemples.',
    NULL,
    210, NULL, NULL,
    '{
      "criteres": [
        {"code": "pertinence",    "label": "Pertinence du contenu",    "poids": 0.30},
        {"code": "grammaire",     "label": "Correction grammaticale",  "poids": 0.25},
        {"code": "vocabulaire",   "label": "Richesse lexicale",        "poids": 0.20},
        {"code": "coherence",     "label": "Cohérence du discours",    "poids": 0.15},
        {"code": "prononciation", "label": "Prononciation",            "poids": 0.10}
      ],
      "niveau_attendu": "B1",
      "consignes_correcteur": "Une opinion claire avec deux arguments illustrés. Connecteurs attendus : d''abord, ensuite, par exemple, en revanche. Le candidat doit être capable de nuancer (en général, parfois)."
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
    'Présentez-vous en mettant en avant un projet personnel ou professionnel qui vous tient particulièrement à cœur. Expliquez d''où il vient, ce qu''il représente pour vous, et ce que vous espérez en retirer.',
    NULL,
    180, NULL, NULL,
    '{
      "criteres": [
        {"code": "pertinence",    "label": "Pertinence du contenu",    "poids": 0.30},
        {"code": "grammaire",     "label": "Correction grammaticale",  "poids": 0.25},
        {"code": "vocabulaire",   "label": "Richesse lexicale",        "poids": 0.20},
        {"code": "coherence",     "label": "Cohérence du discours",    "poids": 0.15},
        {"code": "prononciation", "label": "Prononciation",            "poids": 0.10}
      ],
      "niveau_attendu": "B2",
      "consignes_correcteur": "Discours structuré et nuancé. Subordonnées variées, articulation logique explicite, vocabulaire précis. Le candidat doit pouvoir expliquer ses motivations sans tomber dans les généralités."
    }'::jsonb,
    TRUE
);

INSERT INTO production_tasks (
    id, epreuve, tache_numero, niveau_cible, consigne, contexte,
    duree_max_sec, mots_min, mots_max, criteres_evaluation, is_active
) VALUES (
    gen_random_uuid(), 'TCF_EO', 2, 'B2',
    'Vous postulez pour un emploi qui vous intéresse beaucoup mais pour lequel vous êtes un peu sous-qualifié sur un critère précis. Lors d''un entretien téléphonique, vous devez expliquer pourquoi vous restez un bon candidat, donner des exemples concrets de vos compétences, et proposer une voie de progression.',
    'L''examinateur joue le recruteur, plutôt réservé.',
    210, NULL, NULL,
    '{
      "criteres": [
        {"code": "pertinence",    "label": "Pertinence du contenu",    "poids": 0.30},
        {"code": "grammaire",     "label": "Correction grammaticale",  "poids": 0.25},
        {"code": "vocabulaire",   "label": "Richesse lexicale",        "poids": 0.20},
        {"code": "coherence",     "label": "Cohérence du discours",    "poids": 0.15},
        {"code": "prononciation", "label": "Prononciation",            "poids": 0.10}
      ],
      "niveau_attendu": "B2",
      "consignes_correcteur": "Le candidat doit savoir argumenter sous contrainte, reformuler en réponse à une objection, et utiliser un registre soutenu. Vérifier l''aisance dans la gestion d''un tour de parole adverse."
    }'::jsonb,
    TRUE
);

INSERT INTO production_tasks (
    id, epreuve, tache_numero, niveau_cible, consigne, contexte,
    duree_max_sec, mots_min, mots_max, criteres_evaluation, is_active
) VALUES (
    gen_random_uuid(), 'TCF_EO', 3, 'B2',
    'Certaines entreprises imposent le retour au bureau cinq jours par semaine, d''autres laissent la liberté totale aux salariés. Quelle organisation du travail vous semble la plus juste et la plus efficace ? Défendez votre position en envisageant au moins une objection que pourrait formuler quelqu''un en désaccord avec vous.',
    NULL,
    210, NULL, NULL,
    '{
      "criteres": [
        {"code": "pertinence",    "label": "Pertinence du contenu",    "poids": 0.30},
        {"code": "grammaire",     "label": "Correction grammaticale",  "poids": 0.25},
        {"code": "vocabulaire",   "label": "Richesse lexicale",        "poids": 0.20},
        {"code": "coherence",     "label": "Cohérence du discours",    "poids": 0.15},
        {"code": "prononciation", "label": "Prononciation",            "poids": 0.10}
      ],
      "niveau_attendu": "B2",
      "consignes_correcteur": "Argumentation à deux temps : thèse + anticipation d''une objection. Vérifier l''emploi du subjonctif (bien que, à moins que), des connecteurs concessifs, et la précision lexicale (organisation, productivité, autonomie)."
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
    'Vous venez d''emménager dans un nouveau quartier. Écrivez un message à un ami pour lui annoncer la nouvelle, lui décrire brièvement votre nouveau logement, et l''inviter à venir vous voir un week-end.',
    NULL,
    NULL, 60, 120,
    '{
      "criteres": [
        {"code": "pertinence",  "label": "Pertinence du contenu",   "poids": 0.30},
        {"code": "grammaire",   "label": "Correction grammaticale", "poids": 0.30},
        {"code": "vocabulaire", "label": "Richesse lexicale",       "poids": 0.20},
        {"code": "coherence",   "label": "Cohérence du discours",   "poids": 0.20}
      ],
      "niveau_attendu": "A2",
      "consignes_correcteur": "Message court et clair. Vérifier que les trois éléments demandés sont présents. Tolérer les fautes de conjugaison basiques mais signaler les structures essentielles fausses (être/avoir au présent)."
    }'::jsonb,
    TRUE
);

INSERT INTO production_tasks (
    id, epreuve, tache_numero, niveau_cible, consigne, contexte,
    duree_max_sec, mots_min, mots_max, criteres_evaluation, is_active
) VALUES (
    gen_random_uuid(), 'TCF_EE', 2, 'A2',
    'Racontez la dernière fois que vous êtes allé au restaurant ou à une fête : quand c''était, avec qui, ce que vous avez mangé ou fait, et si vous avez aimé ou non.',
    NULL,
    NULL, 120, 150,
    '{
      "criteres": [
        {"code": "pertinence",  "label": "Pertinence du contenu",   "poids": 0.30},
        {"code": "grammaire",   "label": "Correction grammaticale", "poids": 0.30},
        {"code": "vocabulaire", "label": "Richesse lexicale",       "poids": 0.20},
        {"code": "coherence",   "label": "Cohérence du discours",   "poids": 0.20}
      ],
      "niveau_attendu": "A2",
      "consignes_correcteur": "Récit court au passé. Vérifier l''emploi du passé composé, les expressions de temps (hier, le week-end dernier, après). Tolérer les erreurs d''accord du participe passé."
    }'::jsonb,
    TRUE
);

INSERT INTO production_tasks (
    id, epreuve, tache_numero, niveau_cible, consigne, contexte,
    duree_max_sec, mots_min, mots_max, criteres_evaluation, is_active
) VALUES (
    gen_random_uuid(), 'TCF_EE', 3, 'A2',
    'Préférez-vous vivre en ville ou à la campagne ? Donnez votre opinion et expliquez deux raisons.',
    NULL,
    NULL, 150, 180,
    '{
      "criteres": [
        {"code": "pertinence",  "label": "Pertinence du contenu",   "poids": 0.30},
        {"code": "grammaire",   "label": "Correction grammaticale", "poids": 0.30},
        {"code": "vocabulaire", "label": "Richesse lexicale",       "poids": 0.20},
        {"code": "coherence",   "label": "Cohérence du discours",   "poids": 0.20}
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
    'Vous avez assisté à un événement marquant dans votre quartier (panne d''électricité, embouteillage exceptionnel, fête locale...). Écrivez un message à un proche pour lui raconter ce qui s''est passé et expliquer comment vous avez vécu la situation.',
    NULL,
    NULL, 60, 120,
    '{
      "criteres": [
        {"code": "pertinence",  "label": "Pertinence du contenu",   "poids": 0.30},
        {"code": "grammaire",   "label": "Correction grammaticale", "poids": 0.30},
        {"code": "vocabulaire", "label": "Richesse lexicale",       "poids": 0.20},
        {"code": "coherence",   "label": "Cohérence du discours",   "poids": 0.20}
      ],
      "niveau_attendu": "B1",
      "consignes_correcteur": "Récit court avec une dimension subjective. Vérifier l''alternance passé composé / imparfait pour distinguer événement et contexte."
    }'::jsonb,
    TRUE
);

INSERT INTO production_tasks (
    id, epreuve, tache_numero, niveau_cible, consigne, contexte,
    duree_max_sec, mots_min, mots_max, criteres_evaluation, is_active
) VALUES (
    gen_random_uuid(), 'TCF_EE', 2, 'B1',
    'Racontez une expérience qui vous a appris quelque chose d''important sur vous-même (un voyage, une rencontre, un travail, un échec...). Décrivez le contexte, ce qui s''est passé, et ce que vous en avez retenu.',
    NULL,
    NULL, 120, 150,
    '{
      "criteres": [
        {"code": "pertinence",  "label": "Pertinence du contenu",   "poids": 0.30},
        {"code": "grammaire",   "label": "Correction grammaticale", "poids": 0.30},
        {"code": "vocabulaire", "label": "Richesse lexicale",       "poids": 0.20},
        {"code": "coherence",   "label": "Cohérence du discours",   "poids": 0.20}
      ],
      "niveau_attendu": "B1",
      "consignes_correcteur": "Récit structuré en trois temps. Vérifier la progression contextuelle (au départ, ensuite, finalement) et la présence d''une analyse personnelle."
    }'::jsonb,
    TRUE
);

INSERT INTO production_tasks (
    id, epreuve, tache_numero, niveau_cible, consigne, contexte,
    duree_max_sec, mots_min, mots_max, criteres_evaluation, is_active
) VALUES (
    gen_random_uuid(), 'TCF_EE', 3, 'B1',
    'Faut-il limiter le temps d''écran des enfants ? Donnez votre avis en défendant votre position avec deux arguments concrets et au moins un exemple personnel ou observé.',
    NULL,
    NULL, 150, 180,
    '{
      "criteres": [
        {"code": "pertinence",  "label": "Pertinence du contenu",   "poids": 0.30},
        {"code": "grammaire",   "label": "Correction grammaticale", "poids": 0.30},
        {"code": "vocabulaire", "label": "Richesse lexicale",       "poids": 0.20},
        {"code": "coherence",   "label": "Cohérence du discours",   "poids": 0.20}
      ],
      "niveau_attendu": "B1",
      "consignes_correcteur": "Argumentation en deux temps avec illustration. Vérifier les connecteurs (en effet, par exemple, d''ailleurs) et le maintien d''un point de vue clair du début à la fin."
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
    'Vous avez reçu un service de mauvaise qualité (restaurant, hôtel, service en ligne...). Écrivez un message courtois mais ferme au prestataire pour décrire ce qui ne vous a pas convenu, demander une compensation, et indiquer ce que vous attendez en retour.',
    NULL,
    NULL, 60, 120,
    '{
      "criteres": [
        {"code": "pertinence",  "label": "Pertinence du contenu",   "poids": 0.30},
        {"code": "grammaire",   "label": "Correction grammaticale", "poids": 0.30},
        {"code": "vocabulaire", "label": "Richesse lexicale",       "poids": 0.20},
        {"code": "coherence",   "label": "Cohérence du discours",   "poids": 0.20}
      ],
      "niveau_attendu": "B2",
      "consignes_correcteur": "Registre formel mais ferme. Vérifier les formules d''appel et de clôture, le conditionnel de politesse, et la précision du vocabulaire commercial (prestation, dédommagement, geste commercial)."
    }'::jsonb,
    TRUE
);

INSERT INTO production_tasks (
    id, epreuve, tache_numero, niveau_cible, consigne, contexte,
    duree_max_sec, mots_min, mots_max, criteres_evaluation, is_active
) VALUES (
    gen_random_uuid(), 'TCF_EE', 2, 'B2',
    'Racontez une situation où vous avez dû prendre une décision difficile dont vous mesurez aujourd''hui les conséquences (un choix de carrière, une rupture, un déménagement, un engagement...). Décrivez le contexte, votre cheminement, et le regard que vous portez aujourd''hui sur ce choix.',
    NULL,
    NULL, 120, 150,
    '{
      "criteres": [
        {"code": "pertinence",  "label": "Pertinence du contenu",   "poids": 0.30},
        {"code": "grammaire",   "label": "Correction grammaticale", "poids": 0.30},
        {"code": "vocabulaire", "label": "Richesse lexicale",       "poids": 0.20},
        {"code": "coherence",   "label": "Cohérence du discours",   "poids": 0.20}
      ],
      "niveau_attendu": "B2",
      "consignes_correcteur": "Récit réflexif. Vérifier l''emploi du plus-que-parfait (action antérieure), du conditionnel passé (regret/projection), et la capacité à prendre du recul sur l''expérience."
    }'::jsonb,
    TRUE
);

INSERT INTO production_tasks (
    id, epreuve, tache_numero, niveau_cible, consigne, contexte,
    duree_max_sec, mots_min, mots_max, criteres_evaluation, is_active
) VALUES (
    gen_random_uuid(), 'TCF_EE', 3, 'B2',
    'L''intelligence artificielle va-t-elle améliorer ou dégrader la qualité de l''éducation dans les années à venir ? Défendez une position nuancée : exposez votre thèse, étayez-la avec au moins deux arguments, et envisagez explicitement une objection que vous discutez.',
    NULL,
    NULL, 150, 180,
    '{
      "criteres": [
        {"code": "pertinence",  "label": "Pertinence du contenu",   "poids": 0.30},
        {"code": "grammaire",   "label": "Correction grammaticale", "poids": 0.30},
        {"code": "vocabulaire", "label": "Richesse lexicale",       "poids": 0.20},
        {"code": "coherence",   "label": "Cohérence du discours",   "poids": 0.20}
      ],
      "niveau_attendu": "B2",
      "consignes_correcteur": "Argumentation en trois temps (thèse + arguments + objection traitée). Vérifier les connecteurs concessifs (certes... toutefois, bien que, néanmoins) et la précision conceptuelle (apprentissage personnalisé, automatisation, biais)."
    }'::jsonb,
    TRUE
);
