-- ============================================================================
-- V133 : Seed pilote des situations (SUJETS) + exemples (MODÈLES) — EO T1/T2, EE T1
-- ============================================================================
-- Sémantique (cf. V108) :
--   * production_situations = les SUJETS que le candidat traite (carrousel).
--   * production_examples   = les MODÈLES de la TÂCHE (task_id), consultés pour
--     s'inspirer, indépendants du sujet choisi.
--
-- Situations rattachées à la tâche B1 de chaque (épreuve, tâche) ; l'écran
-- agrège les situations de tous les niveaux. Les exemples sont posés sur la
-- même tâche B1. Les UUID des tâches sont résolus par lookup (V130).
-- ============================================================================

DO $$
DECLARE
    eo_t1 UUID;
    eo_t2 UUID;
    ee_t1 UUID;
    sit_logement UUID;
BEGIN
    SELECT id INTO eo_t1 FROM production_tasks
        WHERE epreuve = 'TCF_EO' AND tache_numero = 1 AND niveau_cible = 'B1' LIMIT 1;
    SELECT id INTO eo_t2 FROM production_tasks
        WHERE epreuve = 'TCF_EO' AND tache_numero = 2 AND niveau_cible = 'B1' LIMIT 1;
    SELECT id INTO ee_t1 FROM production_tasks
        WHERE epreuve = 'TCF_EE' AND tache_numero = 1 AND niveau_cible = 'B1' LIMIT 1;

    -- ------------------------------------------------------------------------
    -- EO Tâche 1 — se présenter : SUJETS
    -- ------------------------------------------------------------------------
    INSERT INTO production_situations (
        task_id, titre, contexte, consigne, objectif, etapes, niveau_indicatif, display_order
    ) VALUES
    (eo_t1,
     'Premier jour de formation',
     'Vous participez à une formation en France. Le formateur vous demande de vous présenter au groupe.',
     'Présentez-vous au groupe : identité, origine, travail ou études, loisirs et projets.',
     'Vous faire connaître en 2-3 minutes de façon naturelle.',
     '[
       {"icon": "person", "titre": "Présentez-vous", "aide": "Prénom, origine, ville actuelle."},
       {"icon": "work", "titre": "Parlez de votre quotidien", "aide": "Travail, études, famille ou activités."},
       {"icon": "target", "titre": "Terminez avec votre projet", "aide": "Expliquez pourquoi vous passez le TCF."}
     ]'::jsonb,
     'B1', 0),
    (eo_t1,
     'Nouveau voisin',
     'Vous rencontrez une personne dans votre immeuble pour la première fois.',
     'Présentez-vous brièvement et engagez la conversation avec votre nouveau voisin.',
     'Établir un premier contact poli et chaleureux.',
     '[
       {"icon": "wave", "titre": "Saluez et présentez-vous", "aide": "Bonjour, votre prénom, où vous habitez."},
       {"icon": "chat", "titre": "Donnez un détail sur vous", "aide": "Depuis quand vous êtes là, ce que vous faites."},
       {"icon": "handshake", "titre": "Ouvrez l''échange", "aide": "Posez une question simple au voisin."}
     ]'::jsonb,
     'B1', 1),
    (eo_t1,
     'Rendez-vous à la mairie',
     'Un agent de la mairie vous reçoit et vous demande de parler de vous.',
     'Présentez-vous à l''agent : identité, situation, et la raison de votre venue.',
     'Donner une présentation claire dans un contexte administratif.',
     '[
       {"icon": "id", "titre": "Identité", "aide": "Nom, prénom, nationalité, date d''arrivée en France."},
       {"icon": "home", "titre": "Situation actuelle", "aide": "Logement, travail, famille."},
       {"icon": "doc", "titre": "Raison de la venue", "aide": "Quelle démarche vous faites."}
     ]'::jsonb,
     'B1', 2);

    -- EO Tâche 1 — MODÈLES (sujets variés : illustrent "se présenter")
    INSERT INTO production_examples (task_id, titre, resume, contenu, plan_points, niveau_indicatif, display_order) VALUES
    (eo_t1, 'Une aide à domicile se présente',
     'Une réponse simple et naturelle, idéale pour commencer.',
     'Bonjour, je m''appelle Mariam. Je viens du Mali et j''habite à Lyon depuis quatre ans. Je travaille comme aide à domicile. J''aime beaucoup ce métier parce que j''aide les personnes âgées. Pendant mon temps libre, j''aime cuisiner, marcher et regarder des films. Je passe le TCF pour avancer dans mes démarches en France.',
     '["Bonjour + prénom + origine", "Ville actuelle + depuis combien de temps", "Travail ou études", "Loisirs + objectif en France"]'::jsonb,
     'B1', 0),
    (eo_t1, 'Un technicien se présente',
     'Une réponse plus détaillée sur le parcours et le projet.',
     'Bonjour à tous. Je m''appelle Ahmed, j''ai 32 ans et je suis originaire du Maroc. Je vis à Toulouse depuis trois ans avec ma femme et mes deux enfants. J''ai d''abord travaillé dans la restauration, puis je me suis formé et aujourd''hui je suis technicien de maintenance. Le week-end, j''aime faire du vélo et bricoler. Je passe le TCF parce que je prépare une demande de naturalisation.',
     '["Salutation + prénom + âge + origine", "Ville + famille", "Parcours professionnel", "Loisirs", "Projet et motivation"]'::jsonb,
     'B1', 1);

    -- ------------------------------------------------------------------------
    -- EO Tâche 2 — jeu de rôle logement : SUJET + supports
    -- ------------------------------------------------------------------------
    INSERT INTO production_situations (
        task_id, titre, contexte, consigne, role_candidat, role_examinateur, objectif, etapes, niveau_indicatif, display_order
    ) VALUES (
        eo_t2,
        'Louer un appartement',
        'Vous cherchez un logement et vous appelez une agence immobilière. Trois biens vous intéressent (voir les supports).',
        'Appelez l''agence : posez des questions sur le prix, la surface, le quartier, les documents demandés et la date de visite.',
        'Vous êtes la personne intéressée par le logement.',
        'L''app joue l''agent immobilier qui répond à vos questions.',
        'Obtenir assez d''informations pour décider quel logement visiter.',
        '[
          {"icon": "question", "titre": "Posez des questions", "aide": "Prix, adresse, surface, charges, documents."},
          {"icon": "chat", "titre": "Réagissez simplement", "aide": "D''accord, très bien, c''est possible quand ?"},
          {"icon": "calendar", "titre": "Terminez l''échange", "aide": "Proposez une visite ou demandez la suite."}
        ]'::jsonb,
        'B1', 0
    ) RETURNING id INTO sit_logement;

    INSERT INTO production_situation_medias (situation_id, type, inline_svg, legende, alt_text, display_order) VALUES
    (sit_logement, 'SVG',
     '<svg viewBox="0 0 200 140" xmlns="http://www.w3.org/2000/svg"><rect width="200" height="140" rx="10" fill="#E8ECF8"/><rect x="30" y="50" width="140" height="70" fill="#1E3A8C"/><polygon points="30,50 100,18 170,50" fill="#15296B"/><rect x="58" y="74" width="24" height="24" fill="#E8ECF8"/><rect x="118" y="74" width="24" height="24" fill="#E8ECF8"/><rect x="88" y="92" width="24" height="28" fill="#E1372F"/></svg>',
     'Studio 22 m2, centre-ville, meublé - 620 EUR/mois',
     'Illustration d''un studio en centre-ville', 0),
    (sit_logement, 'SVG',
     '<svg viewBox="0 0 200 140" xmlns="http://www.w3.org/2000/svg"><rect width="200" height="140" rx="10" fill="#E8ECF8"/><rect x="24" y="44" width="152" height="76" fill="#168F5B"/><polygon points="24,44 100,14 176,44" fill="#0F6E45"/><rect x="44" y="66" width="22" height="22" fill="#E8ECF8"/><rect x="90" y="66" width="22" height="22" fill="#E8ECF8"/><rect x="136" y="66" width="22" height="22" fill="#E8ECF8"/><rect x="86" y="94" width="28" height="26" fill="#0F1839"/></svg>',
     'Appartement 2 pièces 45 m2, quartier calme - 780 EUR/mois',
     'Illustration d''un appartement deux pièces', 1),
    (sit_logement, 'SVG',
     '<svg viewBox="0 0 200 140" xmlns="http://www.w3.org/2000/svg"><rect width="200" height="140" rx="10" fill="#E8ECF8"/><rect x="20" y="40" width="160" height="80" fill="#E8A317"/><polygon points="20,40 100,10 180,40" fill="#B5780F"/><rect x="40" y="60" width="20" height="20" fill="#E8ECF8"/><rect x="78" y="60" width="20" height="20" fill="#E8ECF8"/><rect x="116" y="60" width="20" height="20" fill="#E8ECF8"/><rect x="150" y="60" width="14" height="20" fill="#E8ECF8"/><rect x="86" y="88" width="28" height="32" fill="#0F1839"/></svg>',
     'Maison 4 pièces 90 m2, avec jardin, périphérie - 1100 EUR/mois',
     'Illustration d''une maison avec jardin', 2);

    -- EO Tâche 2 — MODÈLES
    INSERT INTO production_examples (task_id, titre, resume, contenu, plan_points, niveau_indicatif, display_order) VALUES
    (eo_t2, 'Questions essentielles',
     'Les questions à poser pour réussir un jeu de rôle d''information.',
     'Bonjour, je vous appelle au sujet de l''appartement. Est-ce qu''il est toujours disponible ? Quel est le prix du loyer avec les charges ? Quelle est la surface du logement ? Est-ce qu''il est proche des transports ? Quels documents faut-il préparer pour le dossier ? Est-ce que je peux le visiter cette semaine ?',
     '["Bonjour + raison de l''appel", "Questions sur le logement (prix, surface, charges)", "Questions sur le quartier", "Questions sur le dossier", "Demander une visite"]'::jsonb,
     'B1', 0),
    (eo_t2, 'Dialogue naturel',
     'Un échange complet entre candidat et interlocuteur.',
     'Bonjour Madame, je vous contacte pour l''annonce du deux-pièces. Il est encore libre ? Parfait. Pouvez-vous me dire le montant des charges en plus du loyer ? Et le quartier, est-il bien desservi par les bus ? D''accord, très bien. Pour le dossier, vous avez besoin de mes trois derniers bulletins de salaire ? Est-ce qu''une visite serait possible samedi matin ? Je vous remercie beaucoup.',
     '["Salutation + référence annonce", "Disponibilité", "Charges + transports", "Documents du dossier", "Proposer un créneau + remercier"]'::jsonb,
     'B1', 1);

    -- ------------------------------------------------------------------------
    -- EE Tâche 1 — message à un ami : SUJETS avec déclencheur
    -- ------------------------------------------------------------------------
    INSERT INTO production_situations (
        task_id, titre, contexte, consigne, declencheur, etapes, niveau_indicatif, display_order
    ) VALUES
    (ee_t1,
     'Répondre à Jenny',
     'Votre amie Jenny vous a envoyé un message. Répondez-lui par écrit.',
     'Répondez au message de Jenny : acceptez ou refusez son invitation, proposez un jour, et posez-lui une question.',
     '{"expediteur": "Jenny", "avatar": "J", "texte": "Coucou ! Ça te dirait de venir dîner à la maison ce week-end ? J''ai envie de tester une nouvelle recette. Dis-moi si tu es libre et ce que tu aimes manger !"}'::jsonb,
     '[
       {"icon": "reply", "titre": "Répondez à l''invitation", "aide": "Acceptez ou refusez poliment."},
       {"icon": "calendar", "titre": "Proposez un moment", "aide": "Samedi soir ? Dimanche midi ?"},
       {"icon": "question", "titre": "Posez une question", "aide": "Qu''est-ce que vous apportez ? À quelle heure ?"}
     ]'::jsonb,
     'B1', 0),
    (ee_t1,
     'Répondre à Élise',
     'Votre collègue Élise vous écrit pour organiser un cadeau commun.',
     'Répondez à Élise : donnez votre accord, proposez une idée de cadeau, et indiquez combien vous pouvez participer.',
     '{"expediteur": "Élise", "avatar": "E", "texte": "Bonjour ! Tu sais que c''est bientôt le départ de Marc. On voudrait lui offrir un cadeau de la part de toute l''équipe. Tu es partant pour participer ? Tu as une idée de ce qui lui ferait plaisir ?"}'::jsonb,
     '[
       {"icon": "check", "titre": "Donnez votre accord", "aide": "Oui, avec plaisir / Bonne idée."},
       {"icon": "gift", "titre": "Proposez une idée", "aide": "Un objet, une expérience, un bon cadeau."},
       {"icon": "euro", "titre": "Indiquez votre participation", "aide": "Combien vous pouvez mettre."}
     ]'::jsonb,
     'B1', 1);

    -- EE Tâche 1 — MODÈLES
    INSERT INTO production_examples (task_id, titre, resume, contenu, plan_points, niveau_indicatif, display_order) VALUES
    (ee_t1, 'Modèle : répondre à une invitation',
     'Une réponse positive, naturelle et complète.',
     'Coucou Jenny ! Merci pour ton invitation, ça me fait super plaisir. Oui, je suis libre ce week-end. Samedi soir, ce serait parfait pour moi. J''adore à peu près tout, mais j''ai un petit faible pour les plats épicés ! Tu veux que j''apporte le dessert ou une bouteille ? À quelle heure tu veux qu''on se retrouve ? Hâte de goûter ta nouvelle recette ! Bises.',
     '["Salutation + remerciement", "Réponse à l''invitation", "Proposition de moment", "Question pratique", "Formule finale"]'::jsonb,
     'B1', 0),
    (ee_t1, 'Modèle : organiser à plusieurs',
     'Une réponse claire qui répond aux trois points demandés.',
     'Bonjour Élise ! Oui, bien sûr, je participe avec plaisir. C''est une très belle idée d''offrir quelque chose de la part de l''équipe. Comme Marc adore la randonnée, on pourrait peut-être lui prendre un bon pour du matériel de sport. De mon côté, je peux mettre 20 euros. Dis-moi qui s''occupe de la collecte et je te donne ma part. Merci de l''organiser !',
     '["Accord", "Idée de cadeau", "Participation (montant)", "Question d''organisation", "Remerciement"]'::jsonb,
     'B1', 1);

END $$;
