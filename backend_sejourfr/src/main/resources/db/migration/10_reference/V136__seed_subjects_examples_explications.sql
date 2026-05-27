-- ============================================================================
-- V136 : Sujets supplémentaires (production_tasks) + exemples avec explications
-- ============================================================================
-- Modèle simplifié (cf. V135) : production_tasks = sujets, production_examples =
-- modèles rattachés à la tâche + champ `explications`.
--
-- 1. EO Tâche 1 « se présenter » : ajoute des profils variés comme sujets
--    (mécanicien, étudiant, réfugié, etc.) — chacun est une ligne production_tasks.
-- 2. Re-seed des exemples-modèles avec `explications` (on vide d'abord le pilote
--    précédent pour éviter les doublons), rattachés à la tâche B1 de chaque
--    catégorie ; ils se listent ensuite par (epreuve, tache_numero).
-- ============================================================================

DO $$
DECLARE
    eo_grille JSONB := '{
      "criteres": [
        {"code": "pertinence",    "label": "Pertinence du contenu",    "poids": 0.30},
        {"code": "grammaire",     "label": "Correction grammaticale",  "poids": 0.25},
        {"code": "vocabulaire",   "label": "Richesse lexicale",        "poids": 0.20},
        {"code": "coherence",     "label": "Cohérence du discours",    "poids": 0.15},
        {"code": "prononciation", "label": "Prononciation",            "poids": 0.10}
      ],
      "niveau_attendu": "B1",
      "consignes_correcteur": "Le candidat doit se présenter clairement à partir du profil imposé. Vérifier la structure (identité, situation, projet), l''emploi du présent et du passé composé, et un vocabulaire adapté au profil."
    }'::jsonb;

    eo_t1 UUID;
    eo_t2 UUID;
    eo_t3 UUID;
    ee_t1 UUID;
    ee_t2 UUID;
    ee_t3 UUID;
BEGIN
    -- ------------------------------------------------------------------------
    -- 1. EO Tâche 1 — profils variés (sujets)
    -- ------------------------------------------------------------------------
    INSERT INTO production_tasks (
        id, epreuve, tache_numero, niveau_cible, consigne, contexte,
        duree_max_sec, mots_min, mots_max, criteres_evaluation, is_active
    ) VALUES
    (gen_random_uuid(), 'TCF_EO', 1, 'B1',
     'Vous êtes mécanicien et vous souhaitez obtenir la nationalité française. Présentez-vous : identité, parcours, travail et raisons de votre démarche.',
     NULL, 180, NULL, NULL, eo_grille, TRUE),
    (gen_random_uuid(), 'TCF_EO', 1, 'B1',
     'Vous êtes étudiant étranger inscrit à l''université en France. Présentez-vous : origine, études, projet et ce qui vous a amené ici.',
     NULL, 180, NULL, NULL, eo_grille, TRUE),
    (gen_random_uuid(), 'TCF_EO', 1, 'B1',
     'Vous êtes infirmier(ère) et vous travaillez dans un hôpital en France. Présentez-vous : parcours, métier, quotidien et projets.',
     NULL, 180, NULL, NULL, eo_grille, TRUE),
    (gen_random_uuid(), 'TCF_EO', 1, 'B1',
     'Vous êtes réfugié(e) et vous reconstruisez votre vie en France. Présentez-vous avec dignité : origine, situation actuelle et espoirs.',
     NULL, 180, NULL, NULL, eo_grille, TRUE),
    (gen_random_uuid(), 'TCF_EO', 1, 'B1',
     'Vous êtes commerçant(e) et vous tenez une petite boutique. Présentez-vous : votre activité, votre journée type et vos projets.',
     NULL, 180, NULL, NULL, eo_grille, TRUE),
    (gen_random_uuid(), 'TCF_EO', 1, 'B1',
     'Vous êtes parent au foyer et vous reprenez une formation. Présentez-vous : votre famille, votre quotidien et votre projet de reconversion.',
     NULL, 180, NULL, NULL, eo_grille, TRUE);

    -- Tâches cibles (B1) pour rattacher les exemples par catégorie.
    SELECT id INTO eo_t1 FROM production_tasks WHERE epreuve='TCF_EO' AND tache_numero=1 AND niveau_cible='B1' ORDER BY created_at ASC LIMIT 1;
    SELECT id INTO eo_t2 FROM production_tasks WHERE epreuve='TCF_EO' AND tache_numero=2 AND niveau_cible='B1' ORDER BY created_at ASC LIMIT 1;
    SELECT id INTO eo_t3 FROM production_tasks WHERE epreuve='TCF_EO' AND tache_numero=3 AND niveau_cible='B1' ORDER BY created_at ASC LIMIT 1;
    SELECT id INTO ee_t1 FROM production_tasks WHERE epreuve='TCF_EE' AND tache_numero=1 AND niveau_cible='B1' ORDER BY created_at ASC LIMIT 1;
    SELECT id INTO ee_t2 FROM production_tasks WHERE epreuve='TCF_EE' AND tache_numero=2 AND niveau_cible='B1' ORDER BY created_at ASC LIMIT 1;
    SELECT id INTO ee_t3 FROM production_tasks WHERE epreuve='TCF_EE' AND tache_numero=3 AND niveau_cible='B1' ORDER BY created_at ASC LIMIT 1;

    -- ------------------------------------------------------------------------
    -- 2. Exemples-modèles avec explications (re-seed propre)
    -- ------------------------------------------------------------------------
    DELETE FROM production_examples;

    INSERT INTO production_examples (task_id, titre, resume, contenu, explications, plan_points, niveau_indicatif, display_order) VALUES
    -- EO T1
    (eo_t1, 'Une aide à domicile se présente',
     'Réponse simple et naturelle, idéale pour commencer.',
     'Bonjour, je m''appelle Mariam. Je viens du Mali et j''habite à Lyon depuis quatre ans. Je travaille comme aide à domicile. J''aime beaucoup ce métier parce que j''aide les personnes âgées. Pendant mon temps libre, j''aime cuisiner et marcher. Je passe le TCF pour avancer dans mes démarches.',
     'Remarquez la structure très claire : salutation, origine, ville, métier, loisirs, objectif. Les phrases sont courtes et au présent — c''est suffisant pour réussir la tâche au niveau visé.',
     '["Bonjour + prénom + origine", "Ville + durée", "Travail", "Loisirs + objectif"]'::jsonb, 'B1', 0),
    (eo_t1, 'Un technicien se présente',
     'Réponse plus détaillée sur le parcours.',
     'Bonjour à tous. Je m''appelle Ahmed, j''ai 32 ans et je suis originaire du Maroc. Je vis à Toulouse depuis trois ans avec ma femme et mes deux enfants. J''ai d''abord travaillé dans la restauration, puis je me suis formé et aujourd''hui je suis technicien de maintenance. Je passe le TCF pour ma demande de naturalisation.',
     'Ici le candidat enrichit avec un parcours (« j''ai d''abord… puis… aujourd''hui »). L''alternance présent / passé composé montre un niveau B1 solide. Inspirez-vous de cette progression chronologique.',
     '["Salutation + âge + origine", "Famille + ville", "Parcours pro", "Objectif"]'::jsonb, 'B1', 1),
    -- EO T2
    (eo_t2, 'Questions essentielles (jeu de rôle)',
     'Les questions clés pour réussir une demande d''information.',
     'Bonjour, je vous appelle au sujet de l''appartement. Est-ce qu''il est toujours disponible ? Quel est le prix du loyer avec les charges ? Quelle est la surface ? Est-ce qu''il est proche des transports ? Quels documents faut-il pour le dossier ? Est-ce que je peux le visiter cette semaine ?',
     'L''essentiel en jeu de rôle, c''est de POSER des questions claires et variées. Comptez-en au moins quatre, sur des aspects différents (prix, surface, quartier, dossier).',
     '["Bonjour + raison", "Prix / surface / charges", "Quartier", "Dossier", "Visite"]'::jsonb, 'B1', 0),
    (eo_t2, 'Dialogue naturel',
     'Un échange complet et poli.',
     'Bonjour Madame, je vous contacte pour l''annonce du deux-pièces. Il est encore libre ? Parfait. Pouvez-vous me dire le montant des charges ? Et le quartier, est-il bien desservi ? D''accord, très bien. Pour le dossier, vous avez besoin de mes bulletins de salaire ? Une visite serait-elle possible samedi ? Je vous remercie beaucoup.',
     'Remarquez les réactions (« Parfait », « D''accord, très bien ») et la politesse (vouvoiement, remerciement). Réagir à l''interlocuteur rend l''échange vivant et naturel.',
     '["Salutation + référence", "Charges + transports", "Dossier", "Visite + remerciement"]'::jsonb, 'B1', 1),
    -- EO T3
    (eo_t3, 'Modèle : avis nuancé',
     'Comment donner un avis équilibré (un pour, un contre).',
     'À mon avis, nous passons trop de temps devant les écrans. D''abord, beaucoup regardent leur téléphone dès le réveil, ce qui fatigue et perturbe le sommeil. Ensuite, les écrans nous isolent un peu. Cependant, ils sont aussi très utiles pour travailler et garder le contact. Pour finir, je pense qu''il faut surtout mieux gérer ce temps.',
     'Structure modèle pour donner son avis : position → deux arguments (« d''abord… ensuite… ») → nuance (« cependant… ») → conclusion. Les connecteurs sont la clé de cette tâche.',
     '["Position", "Argument 1 + exemple", "Argument 2", "Nuance", "Conclusion"]'::jsonb, 'B1', 0),
    (eo_t3, 'Modèle : avis tranché',
     'Comment défendre fermement une position.',
     'Personnellement, je préfère nettement voyager à l''étranger. Premièrement, j''adore découvrir de nouvelles cultures. L''an dernier, en Espagne, j''ai beaucoup appris. Deuxièmement, voyager me permet de couper avec le travail. Bien sûr, cela coûte plus cher, mais pour moi ces souvenirs n''ont pas de prix.',
     'Ici la position est affirmée et les arguments numérotés (« Premièrement… Deuxièmement… »). La petite concession (« Bien sûr… mais… ») montre de la nuance sans changer d''avis.',
     '["Position affirmée", "Argument 1 + exemple", "Argument 2", "Concession", "Conclusion"]'::jsonb, 'B1', 1),
    -- EE T1
    (ee_t1, 'Modèle : répondre à une invitation',
     'Réponse positive, naturelle et complète.',
     'Coucou Jenny ! Merci pour ton invitation, ça me fait super plaisir. Oui, je suis libre ce week-end, samedi soir serait parfait. J''adore à peu près tout, mais j''ai un faible pour les plats épicés ! Tu veux que j''apporte le dessert ? À quelle heure on se retrouve ? Hâte de goûter ta recette ! Bises.',
     'Le message répond aux trois points attendus : réponse à l''invitation, proposition d''un moment, et une question. Le ton amical (« Coucou », « Bises ») est adapté à un message à un ami.',
     '["Salutation + remerciement", "Réponse + moment", "Question", "Formule finale"]'::jsonb, 'B1', 0),
    (ee_t1, 'Modèle : organiser à plusieurs',
     'Réponse claire qui couvre les trois points.',
     'Bonjour Élise ! Oui, bien sûr, je participe avec plaisir. C''est une belle idée d''offrir un cadeau de la part de l''équipe. Comme Marc adore la randonnée, on pourrait lui prendre un bon pour du matériel de sport. De mon côté, je peux mettre 20 euros. Dis-moi qui s''occupe de la collecte. Merci de l''organiser !',
     'Le candidat donne son accord, propose une idée concrète, et indique sa participation : les trois éléments demandés sont présents et faciles à repérer. C''est ce que l''examinateur vérifie.',
     '["Accord", "Idée de cadeau", "Participation", "Question d''organisation"]'::jsonb, 'B1', 1),
    -- EE T2
    (ee_t2, 'Modèle : récit d''un voyage',
     'Récit chaleureux décor / déroulement / bilan.',
     'Salut Yacine ! Le voyage qui m''a le plus marquée, c''était il y a deux ans, en Italie, avec ma sœur. Nous avons passé une semaine à Rome en mai. Le premier jour, nous nous sommes perdues, mais c''est ainsi que nous avons découvert un marché magnifique. Ce que j''en ai retenu, c''est qu''il faut parfois se perdre pour découvrir un endroit. Je te le conseille !',
     'Un bon récit suit trois temps : le décor (quand, où, avec qui), le déroulement (au passé composé), et le bilan personnel. Une anecdote concrète rend le récit vivant.',
     '["Décor : où, quand, qui", "Déroulement + anecdote", "Bilan", "Conseil"]'::jsonb, 'B1', 0),
    (ee_t2, 'Modèle : récit d''une rencontre',
     'Récit structuré autour d''une rencontre marquante.',
     'Je voudrais vous parler de Sarah, rencontrée à mon arrivée en France il y a cinq ans. À l''époque, je ne connaissais personne et je parlais mal français. Un jour, en cours du soir, elle m''a proposé son aide. Petit à petit, nous sommes devenues amies. Grâce à elle, j''ai pris confiance. Aujourd''hui encore, elle est comme une sœur.',
     'Notez la progression dans le temps (« À l''époque… Un jour… Petit à petit… Aujourd''hui ») et la dimension personnelle (ce que la rencontre a changé). C''est ce qui distingue un récit B1.',
     '["Contexte", "La rencontre", "Évolution", "Ce que ça a changé"]'::jsonb, 'B1', 1),
    -- EE T3
    (ee_t3, 'Modèle : avis favorable',
     'Défendre une position « pour » avec une objection traitée.',
     'Bonjour à tous. Je suis tout à fait favorable à la gratuité des transports. D''abord, cela encouragerait à laisser la voiture, ce qui réduirait la pollution. Par exemple, des villes qui l''ont testée ont vu moins de voitures. Ensuite, c''est une aide pour les faibles revenus. Bien sûr, il faut financer ce système, mais les bénéfices en valent la peine.',
     'Sur un forum, on reformule, on prend position, on argumente avec un exemple, et on répond à une objection (« Bien sûr, il faut financer… mais… »). Cette anticipation renforce l''argumentation.',
     '["Position", "Argument 1 + exemple", "Argument 2", "Objection traitée"]'::jsonb, 'B1', 0),
    (ee_t3, 'Modèle : avis réservé',
     'Défendre une position plus prudente, également argumentée.',
     'Bonjour. Pour ma part, je ne pense pas que le télétravail doive devenir la norme partout. D''une part, travailler toujours chez soi peut isoler les gens. D''autre part, tout le monde n''a pas un logement adapté. Certes, le télétravail offre de la souplesse, je ne le nie pas. Toutefois, je crois qu''il faut le proposer, pas l''imposer.',
     'Un avis « contre » reste nuancé : la concession (« Certes… je ne le nie pas ») puis le retour à la thèse (« Toutefois… ») montrent une vraie maîtrise des connecteurs concessifs, attendue à ce niveau.',
     '["Thèse", "Argument 1", "Argument 2", "Concession + retour à la thèse"]'::jsonb, 'B1', 1);

END $$;
