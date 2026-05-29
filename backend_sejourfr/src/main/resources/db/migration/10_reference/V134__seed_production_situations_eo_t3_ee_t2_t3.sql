-- ============================================================================
-- V134 : Suite du seed pilote — EO Tâche 3, EE Tâche 2 & 3
-- ============================================================================
-- Complète V133. Sémantique (cf. V108) :
--   * production_situations = SUJETS que le candidat traite (carrousel).
--   * production_examples   = MODÈLES de la TÂCHE (task_id), consultés.
-- ============================================================================

DO $$
DECLARE
    eo_t3 UUID;
    ee_t2 UUID;
    ee_t3 UUID;
BEGIN
    SELECT id INTO eo_t3 FROM production_tasks
        WHERE epreuve = 'TCF_EO' AND tache_numero = 3 AND niveau_cible = 'B1' LIMIT 1;
    SELECT id INTO ee_t2 FROM production_tasks
        WHERE epreuve = 'TCF_EE' AND tache_numero = 2 AND niveau_cible = 'B1' LIMIT 1;
    SELECT id INTO ee_t3 FROM production_tasks
        WHERE epreuve = 'TCF_EE' AND tache_numero = 3 AND niveau_cible = 'B1' LIMIT 1;

    -- ------------------------------------------------------------------------
    -- EO Tâche 3 — donner son avis : SUJETS
    -- ------------------------------------------------------------------------
    INSERT INTO production_situations (
        task_id, titre, contexte, consigne, objectif, etapes, niveau_indicatif, display_order
    ) VALUES
    (eo_t3,
     'Le temps passé devant les écrans',
     'On vous demande votre opinion sur la place des écrans dans la vie de tous les jours.',
     'Pensez-vous que nous passons trop de temps devant les écrans ? Donnez votre avis avec deux arguments illustrés d''exemples.',
     'Exprimer une opinion claire et la défendre avec des exemples concrets.',
     '[
       {"icon": "chat", "titre": "Annoncez votre position", "aide": "À mon avis, je pense que, selon moi."},
       {"icon": "doc", "titre": "Donnez deux arguments", "aide": "D''abord… ensuite… avec un exemple pour chacun."},
       {"icon": "check", "titre": "Concluez en nuançant", "aide": "En revanche, cependant, pour finir."}
     ]'::jsonb,
     'B1', 0),
    (eo_t3,
     'Voyager ou rester chez soi',
     'L''examinateur vous interroge sur votre façon de passer vos vacances.',
     'Préférez-vous voyager à l''étranger ou passer vos vacances près de chez vous ? Justifiez votre choix avec au moins deux raisons.',
     'Faire un choix et l''argumenter avec des raisons personnelles.',
     '[
       {"icon": "chat", "titre": "Annoncez votre préférence", "aide": "Je préfère… parce que…"},
       {"icon": "doc", "titre": "Donnez vos raisons", "aide": "Deux raisons avec des exemples vécus."},
       {"icon": "check", "titre": "Terminez votre idée", "aide": "En résumé, finalement, voilà pourquoi."}
     ]'::jsonb,
     'B1', 1),
    (eo_t3,
     'La place du sport',
     'On vous demande votre point de vue sur l''importance du sport au quotidien.',
     'Pensez-vous que faire du sport régulièrement est indispensable ? Donnez votre avis avec deux arguments et un exemple.',
     'Défendre un point de vue sur un sujet de santé / mode de vie.',
     '[
       {"icon": "chat", "titre": "Donnez votre avis", "aide": "Je trouve que, il me semble que."},
       {"icon": "doc", "titre": "Appuyez avec des arguments", "aide": "Santé, moral, lien social…"},
       {"icon": "check", "titre": "Concluez", "aide": "Pour toutes ces raisons, en conclusion."}
     ]'::jsonb,
     'B1', 2);

    -- EO Tâche 3 — MODÈLES (sujets variés)
    INSERT INTO production_examples (task_id, titre, resume, contenu, plan_points, niveau_indicatif, display_order) VALUES
    (eo_t3, 'Modèle : avis nuancé',
     'Comment donner un avis équilibré (un pour, un contre).',
     'À mon avis, nous passons effectivement trop de temps devant les écrans. D''abord, beaucoup de gens regardent leur téléphone dès le réveil, ce qui fatigue les yeux et perturbe le sommeil. Par exemple, moi-même, je dormais mal quand je consultais mon portable le soir. Ensuite, les écrans nous isolent un peu : on discute moins en famille. Cependant, je reconnais qu''ils sont aussi très utiles pour travailler et garder le contact. Pour finir, je pense qu''il faut surtout mieux gérer ce temps plutôt que tout supprimer.',
     '["Position claire", "Argument 1 + exemple", "Argument 2", "Nuance (côté positif)", "Conclusion équilibrée"]'::jsonb,
     'B1', 0),
    (eo_t3, 'Modèle : avis tranché',
     'Comment défendre fermement une position (autre sujet).',
     'Personnellement, je préfère nettement voyager à l''étranger. Premièrement, j''adore découvrir de nouvelles cultures : la cuisine, les langues, les paysages. L''an dernier, en Espagne, j''ai appris énormément en quelques jours. Deuxièmement, voyager me permet de couper vraiment avec le travail. Bien sûr, cela coûte plus cher que de rester chez soi, mais pour moi ces souvenirs n''ont pas de prix. C''est pourquoi, dès que je le peux, je pars découvrir un nouveau pays.',
     '["Préférence affirmée", "Argument 1 + exemple", "Argument 2", "Concession (coût)", "Conclusion engagée"]'::jsonb,
     'B1', 1);

    -- ------------------------------------------------------------------------
    -- EE Tâche 2 — récit d'expérience : SUJETS avec déclencheur
    -- ------------------------------------------------------------------------
    INSERT INTO production_situations (
        task_id, titre, contexte, consigne, declencheur, etapes, niveau_indicatif, display_order
    ) VALUES
    (ee_t2,
     'Un souvenir de voyage',
     'Un ami vous écrit pour avoir des nouvelles et vous demande de lui raconter un voyage qui vous a marqué.',
     'Répondez à votre ami en racontant un voyage marquant : où, quand, avec qui, ce qui s''est passé, et ce que vous en avez retenu.',
     '{"expediteur": "Yacine", "avatar": "Y", "texte": "Salut ! Ça fait longtemps. Raconte-moi un peu : quel est le voyage qui t''a le plus marqué ces dernières années ? J''ai besoin d''idées pour mes prochaines vacances !"}'::jsonb,
     '[
       {"icon": "calendar", "titre": "Plantez le décor", "aide": "Quand, où, avec qui."},
       {"icon": "chat", "titre": "Racontez le déroulement", "aide": "Ce qui s''est passé (passé composé / imparfait)."},
       {"icon": "check", "titre": "Concluez sur le bilan", "aide": "Ce que vous avez ressenti ou appris."}
     ]'::jsonb,
     'B1', 0),
    (ee_t2,
     'Une rencontre importante',
     'Un site communautaire propose à ses membres de partager un récit personnel.',
     'Rédigez un texte qui raconte une rencontre qui a compté pour vous : le contexte, comment ça s''est passé, et ce que cette rencontre a changé pour vous.',
     '{"expediteur": "Mémoires partagées", "avatar": "M", "texte": "Cette semaine, notre thème est : « Une rencontre qui a changé votre vie ». Partagez votre histoire avec la communauté en quelques lignes."}'::jsonb,
     '[
       {"icon": "calendar", "titre": "Présentez le contexte", "aide": "Quand et comment vous vous êtes rencontrés."},
       {"icon": "chat", "titre": "Racontez la rencontre", "aide": "Les détails marquants."},
       {"icon": "check", "titre": "Expliquez ce que ça a changé", "aide": "L''impact sur votre vie aujourd''hui."}
     ]'::jsonb,
     'B1', 1);

    -- EE Tâche 2 — MODÈLES (récits, sujets variés)
    INSERT INTO production_examples (task_id, titre, resume, contenu, plan_points, niveau_indicatif, display_order) VALUES
    (ee_t2, 'Modèle : récit d''un voyage',
     'Un récit chaleureux suivant le plan décor / déroulement / bilan.',
     'Salut Yacine ! Le voyage qui m''a le plus marquée, c''était il y a deux ans, en Italie, avec ma sœur. Nous avons passé une semaine à Rome au mois de mai. Le premier jour, nous nous sommes perdues dans les petites rues, mais c''est ainsi que nous avons découvert un marché magnifique. Nous avons goûté plein de spécialités et rencontré des gens adorables. Ce que j''en ai retenu, c''est qu''il faut parfois se perdre pour vraiment découvrir un endroit. Je te le conseille vraiment ! Bises.',
     '["Salutation + réponse", "Décor : où, quand, avec qui", "Déroulement + anecdote", "Bilan personnel", "Formule finale"]'::jsonb,
     'B1', 0),
    (ee_t2, 'Modèle : récit d''une rencontre',
     'Un récit structuré autour d''une rencontre marquante.',
     'Je voudrais vous parler de Sarah, que j''ai rencontrée à mon arrivée en France, il y a cinq ans. À l''époque, je ne connaissais personne et je parlais très mal français. Un jour, dans un cours du soir, elle est venue s''asseoir à côté de moi et m''a proposé son aide. Petit à petit, nous sommes devenues de vraies amies : elle me corrigeait et m''emmenait découvrir la ville. Grâce à elle, j''ai pris confiance et je me suis sentie moins seule. Aujourd''hui encore, elle est comme une sœur pour moi.',
     '["Présentation de la personne", "Contexte", "Déroulement", "Ce que ça a changé", "Aujourd''hui"]'::jsonb,
     'B1', 1);

    -- ------------------------------------------------------------------------
    -- EE Tâche 3 — avis argumenté (forum) : SUJETS avec déclencheur forum
    -- ------------------------------------------------------------------------
    INSERT INTO production_situations (
        task_id, titre, contexte, consigne, declencheur, etapes, niveau_indicatif, display_order
    ) VALUES
    (ee_t3,
     'Forum : les transports en commun gratuits',
     'Vous réagissez à un message publié sur un forum de discussion citoyen.',
     'Donnez votre avis sur ce sujet de forum : défendez votre position avec deux arguments concrets et au moins un exemple.',
     '{"expediteur": "Forum Ma Ville", "avatar": "F", "texte": "Sujet du mois : faut-il rendre les transports en commun gratuits pour tous ? Donnez votre avis et argumentez !"}'::jsonb,
     '[
       {"icon": "doc", "titre": "Reformulez le sujet", "aide": "Rappelez brièvement la question."},
       {"icon": "chat", "titre": "Donnez votre position", "aide": "Je suis pour / contre, parce que…"},
       {"icon": "target", "titre": "Argumentez", "aide": "Deux arguments + un exemple."},
       {"icon": "check", "titre": "Concluez", "aide": "Une phrase de synthèse."}
     ]'::jsonb,
     'B1', 0),
    (ee_t3,
     'Forum : le télétravail généralisé',
     'Vous participez à un débat en ligne sur l''organisation du travail.',
     'Réagissez à ce sujet de débat : prenez position sur le télétravail, défendez-la avec deux arguments et envisagez une objection.',
     '{"expediteur": "Débat Pro", "avatar": "D", "texte": "Et vous, pensez-vous que le télétravail devrait devenir la norme pour tous les emplois qui le permettent ? Partagez votre point de vue."}'::jsonb,
     '[
       {"icon": "doc", "titre": "Reformulez le sujet", "aide": "De quoi parle-t-on."},
       {"icon": "chat", "titre": "Affirmez votre thèse", "aide": "Selon moi, je pense que…"},
       {"icon": "target", "titre": "Deux arguments", "aide": "Avec un exemple concret."},
       {"icon": "check", "titre": "Traitez une objection", "aide": "Certes… toutefois…"}
     ]'::jsonb,
     'B1', 1);

    -- EE Tâche 3 — MODÈLES (avis argumentés, sujets variés)
    INSERT INTO production_examples (task_id, titre, resume, contenu, plan_points, niveau_indicatif, display_order) VALUES
    (ee_t3, 'Modèle : avis favorable',
     'Comment défendre une position « pour » avec une objection traitée.',
     'Bonjour à tous. Je suis tout à fait favorable à la gratuité des transports en commun. D''abord, cela encouragerait beaucoup de gens à laisser leur voiture, ce qui réduirait la pollution. Par exemple, dans certaines villes qui ont testé la gratuité, le nombre de voitures a clairement diminué. Ensuite, ce serait une vraie aide pour les personnes aux faibles revenus, qui pourraient se déplacer plus facilement. Bien sûr, il faudrait financer ce système, mais je pense que les bénéfices pour la société en valent la peine.',
     '["Position claire", "Argument 1 + exemple", "Argument 2", "Objection (financement)", "Conclusion"]'::jsonb,
     'B1', 0),
    (ee_t3, 'Modèle : avis réservé',
     'Comment défendre une position plus prudente (autre sujet).',
     'Bonjour. Pour ma part, je ne pense pas que le télétravail doive devenir la norme partout. D''une part, travailler toujours chez soi peut isoler les gens : on perd le contact humain entre collègues. D''autre part, tout le monde n''a pas un logement adapté pour bien travailler à la maison. Certes, le télétravail offre plus de souplesse, je ne le nie pas. Toutefois, je crois qu''il faut le proposer comme une possibilité, et non l''imposer à tous les métiers.',
     '["Thèse réservée", "Argument 1 (isolement)", "Argument 2 (logement)", "Concession", "Conclusion mesurée"]'::jsonb,
     'B1', 1);

END $$;
