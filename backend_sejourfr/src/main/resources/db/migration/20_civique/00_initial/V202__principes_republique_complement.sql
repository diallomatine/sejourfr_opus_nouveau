-- ============================================================================
-- Questions complémentaires - Thématique 1 : Principes et valeurs de la République
-- Complément de V200 (37 questions) : 60 questions supplémentaires
-- Source : livret du citoyen + reformulations + corpus civique standard
-- ============================================================================
-- Thématique : 11111111-0000-0000-0000-000000000001 (CIV_PRINCIPES)
-- UUIDs : f0000001-0000-0000-0000-000000000101 à 00000000013c (60 questions)
-- ============================================================================

-- ---------------------------------------------------------------------------
-- BLOC 8 : HYMNE & MARSEILLAISE (approfondissement)
-- ---------------------------------------------------------------------------

-- Q38 - Qui a composé La Marseillaise ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000101', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Qui a composé La Marseillaise ?',
        'La Marseillaise a été composée par Rouget de Lisle en 1792 à Strasbourg. C''était à l''origine un chant de guerre pour l''armée du Rhin.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000101', 'Rouget de Lisle', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000101', 'Victor Hugo', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000101', 'Napoléon Bonaparte', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000101', 'Charles de Gaulle', FALSE, 3);

-- Q39 - En quelle année La Marseillaise a-t-elle été composée ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000102', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'NAT', 'CONNAISSANCE',
        'En quelle année La Marseillaise a-t-elle été composée ?',
        'La Marseillaise a été composée en 1792, pendant la Révolution française. Elle est devenue hymne national en 1795, puis définitivement en 1879.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000102', '1792', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000102', '1789', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000102', '1804', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000102', '1848', FALSE, 3);

-- Q40 - Dans quelle ville La Marseillaise a-t-elle été écrite ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000103', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'NAT', 'CONNAISSANCE',
        'Dans quelle ville Rouget de Lisle a-t-il écrit La Marseillaise ?',
        'La Marseillaise a été écrite à Strasbourg en avril 1792. Le titre vient des volontaires marseillais qui l''ont entonnée à leur entrée dans Paris.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000103', 'Strasbourg', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000103', 'Marseille', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000103', 'Paris', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000103', 'Lyon', FALSE, 3);

-- Q41 - Comment doit-on se comporter quand retentit La Marseillaise ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000104', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CSP', 'MISE_SITUATION',
        'Comment doit-on se comporter lorsque retentit La Marseillaise dans une cérémonie officielle ?',
        'Par respect pour l''hymne national, on se tient debout et en silence. Cette règle vaut aussi lors des événements sportifs internationaux.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000104', 'Se tenir debout et en silence', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000104', 'Continuer à parler normalement', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000104', 'S''asseoir et applaudir', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000104', 'Quitter la salle par respect', FALSE, 3);

-- Q42 - Quand chante-t-on La Marseillaise ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000105', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CSP', 'CONNAISSANCE',
        'Dans quelles occasions La Marseillaise est-elle chantée ?',
        'La Marseillaise est jouée lors des cérémonies officielles (commémorations, prises de fonction), des événements sportifs internationaux et de la fête nationale.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000105',
        'Cérémonies officielles et événements sportifs internationaux', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000105', 'Uniquement le 14 juillet', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000105', 'Uniquement dans les écoles', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000105', 'À la fin de chaque journal télévisé', FALSE, 3);

-- ---------------------------------------------------------------------------
-- BLOC 9 : MARIANNE & SYMBOLES (approfondissement)
-- ---------------------------------------------------------------------------

-- Q43 - Que porte Marianne sur la tête ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000106', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Que porte traditionnellement Marianne sur la tête ?',
        'Marianne porte un bonnet phrygien, coiffure rouge symbole de liberté héritée de l''Antiquité (les esclaves affranchis le portaient).',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000106', 'Un bonnet phrygien', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000106', 'Une couronne royale', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000106', 'Un casque militaire', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000106', 'Un voile blanc', FALSE, 3);

-- Q44 - Que symbolise le bonnet phrygien ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000107', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'NAT', 'CONNAISSANCE',
        'Que symbolise le bonnet phrygien porté par Marianne ?',
        'Le bonnet phrygien symbolise la liberté. Dans l''Antiquité, les esclaves affranchis le portaient. La Révolution française l''a repris comme emblème.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000107', 'La liberté', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000107', 'Le pouvoir militaire', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000107', 'La royauté', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000107', 'La religion catholique', FALSE, 3);

-- Q45 - Où peut-on voir le buste de Marianne ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000108', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CSP', 'CONNAISSANCE',
        'Où peut-on voir le buste de Marianne ?',
        'Le buste de Marianne est présent dans toutes les mairies de France. Il est aussi reproduit sur les timbres et certaines pièces de monnaie.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000108', 'Dans toutes les mairies de France', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000108', 'Uniquement à Paris', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000108', 'Dans les églises', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000108', 'Dans les écoles privées', FALSE, 3);

-- Q46 - Sur quels objets voit-on Marianne ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000109', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Sur quels objets du quotidien apparaît Marianne ?',
        'Marianne apparaît sur les timbres-poste français et sur certaines pièces de monnaie en euros frappées en France. C''est l''image officielle de la République.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000109', 'Les timbres et les pièces de monnaie', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000109', 'Les billets de banque uniquement', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000109', 'Les permis de conduire', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000109', 'Les cartes de transport', FALSE, 3);

-- Q47 - Où voit-on souvent le coq gaulois ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-00000000010a', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CSP', 'CONNAISSANCE',
        'Sur quoi peut-on souvent voir le coq gaulois ?',
        'Le coq gaulois est l''emblème traditionnel de la France. On le voit notamment sur les maillots des équipes sportives nationales et sur certaines pièces de monnaie.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000010a',
        'Les maillots des équipes sportives nationales', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000010a', 'Le drapeau européen', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000010a', 'Les passeports étrangers', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000010a', 'Les uniformes scolaires', FALSE, 3);

-- ---------------------------------------------------------------------------
-- BLOC 10 : DRAPEAU TRICOLORE (approfondissement)
-- ---------------------------------------------------------------------------

-- Q48 - À quelle époque le drapeau tricolore a-t-il été créé ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-00000000010b', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'À quelle époque le drapeau tricolore a-t-il été créé ?',
        'Le drapeau tricolore est né pendant la Révolution française. Le bleu et le rouge sont les couleurs de Paris, le blanc celle de la royauté : réunir les trois symbolisait l''union.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000010b', 'Pendant la Révolution française', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000010b', 'Au Moyen Âge', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000010b', 'Après la Seconde Guerre mondiale', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000010b', 'Sous Napoléon III', FALSE, 3);

-- Q49 - Sur quels bâtiments le drapeau français est-il déployé ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-00000000010c', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CSP', 'CONNAISSANCE',
        'Sur quels bâtiments le drapeau français est-il obligatoirement déployé ?',
        'Le drapeau est arboré sur les bâtiments publics : mairies, préfectures, écoles, tribunaux, ministères, casernes. Il marque la présence de la République.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000010c', 'Les bâtiments publics', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000010c', 'Les commerces de centre-ville', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000010c', 'Les immeubles d''habitation', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000010c', 'Les gares et aéroports uniquement', FALSE, 3);

-- Q50 - Le drapeau européen est-il aussi affiché ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-00000000010d', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Le drapeau européen est-il aussi affiché sur les bâtiments officiels français ?',
        'Oui. La France étant membre de l''Union européenne, le drapeau européen (douze étoiles dorées sur fond bleu) est affiché aux côtés du drapeau français sur les bâtiments officiels.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000010d',
        'Oui, aux côtés du drapeau français sur les bâtiments officiels', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000010d', 'Non, jamais en France', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000010d', 'Oui, mais à la place du drapeau français', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000010d', 'Uniquement dans les ambassades', FALSE, 3);

-- ---------------------------------------------------------------------------
-- BLOC 11 : DEVISE & VALEURS (approfondissement)
-- ---------------------------------------------------------------------------

-- Q51 - Depuis quand la devise est-elle officielle ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-00000000010e', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'NAT', 'CONNAISSANCE',
        'Depuis quand "Liberté, Égalité, Fraternité" est-elle la devise officielle de la République ?',
        'La devise est officiellement adoptée sous la IIIe République, en 1880. Elle est ensuite inscrite dans les Constitutions de 1946 et 1958.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000010e', '1880, sous la IIIe République', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000010e', '1789, dès la Révolution', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000010e', '1958, avec la Ve République', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000010e', '2000, récemment', FALSE, 3);

-- Q52 - D'où vient la devise française ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-00000000010f', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'De quel événement historique vient la devise "Liberté, Égalité, Fraternité" ?',
        'La devise a été popularisée par la Révolution française de 1789. Les trois mots résument les idéaux des révolutionnaires.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000010f', 'La Révolution française de 1789', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000010f', 'La conquête de l''Algérie', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000010f', 'La fin de la Première Guerre mondiale', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000010f', 'Mai 1968', FALSE, 3);

-- Q53 - L'égalité des chances : qu'est-ce ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000110', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Qu''est-ce que l''égalité des chances en France ?',
        'L''égalité des chances signifie que chacun, quelle que soit son origine sociale ou son milieu, doit pouvoir accéder aux mêmes opportunités (école, emploi, logement).',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000110',
        'Chacun doit pouvoir réussir, quelle que soit son origine sociale', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000110', 'Tout le monde gagne le même salaire', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000110', 'Tout le monde a le même métier', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000110', 'Tout le monde possède les mêmes biens', FALSE, 3);

-- Q54 - Le service civique est lié à quelle valeur ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000111', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'À quelle valeur de la République le bénévolat et le service civique sont-ils liés ?',
        'Le bénévolat et le service civique sont des engagements pour aider les autres : ils sont une expression concrète de la fraternité.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000111', 'La fraternité', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000111', 'La laïcité', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000111', 'La propriété privée', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000111', 'La liberté de la presse', FALSE, 3);

-- ---------------------------------------------------------------------------
-- BLOC 12 : RÉPUBLIQUE & DÉMOCRATIE
-- ---------------------------------------------------------------------------

-- Q55 - Qu'est-ce qu'une République ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000112', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Qu''est-ce qu''une République ?',
        'Une République est un régime politique dans lequel le pouvoir n''appartient ni à une famille royale ni à une personne unique, mais au peuple, qui l''exerce par ses représentants élus.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000112',
        'Un régime où le pouvoir appartient au peuple, pas à un roi', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000112', 'Une monarchie héréditaire', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000112', 'Un régime militaire', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000112', 'Un État religieux', FALSE, 3);

-- Q56 - Qu'est-ce que la démocratie ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000113', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Qu''est-ce que la démocratie ?',
        'La démocratie est un système politique où le peuple choisit ses représentants par des élections libres. Elle garantit aussi les libertés fondamentales et le respect des minorités.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000113',
        'Un système où le peuple choisit ses représentants par des élections', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000113',
        'Le gouvernement d''une seule personne', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000113',
        'Un régime sans loi écrite', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000113',
        'Un pays sans frontières', FALSE, 3);

-- Q57 - Qu'est-ce que le suffrage universel ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000114', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Qu''est-ce que le suffrage universel ?',
        'Le suffrage universel signifie que tous les citoyens majeurs ont le droit de vote, sans condition de fortune, de sexe ou de race. C''est un fondement de la démocratie.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000114',
        'Tous les citoyens majeurs ont le droit de vote', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000114', 'Seuls les hommes ont le droit de vote', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000114',
        'Seules les personnes payant des impôts votent', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000114', 'Le vote est réservé aux élus', FALSE, 3);

-- Q58 - Depuis quand les femmes votent en France ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000115', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Depuis quelle année les femmes ont-elles le droit de vote en France ?',
        'Les femmes ont obtenu le droit de vote en 1944, par une ordonnance du général de Gaulle. Elles ont voté pour la première fois en 1945.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000115', '1944', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000115', '1848', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000115', '1968', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000115', '1981', FALSE, 3);

-- Q59 - Depuis quand le suffrage universel masculin existe-t-il ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000116', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'NAT', 'CONNAISSANCE',
        'Depuis quand le suffrage universel masculin existe-t-il en France ?',
        'Le suffrage universel masculin a été instauré en 1848, sous la IIe République. Le suffrage universel complet (hommes et femmes) date de 1944.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000116', '1848', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000116', '1789', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000116', '1875', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000116', '1944', FALSE, 3);

-- Q60 - Qu'est-ce que la souveraineté nationale ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000117', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'NAT', 'CONNAISSANCE',
        'Qu''est-ce que la souveraineté nationale ?',
        'La souveraineté nationale signifie que le pouvoir politique appartient à la nation, c''est-à-dire au peuple. Il s''exerce par les représentants élus et par le référendum.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000117',
        'Le pouvoir politique appartient au peuple', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000117', 'Le pouvoir appartient au Président seul', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000117', 'Le pouvoir appartient à l''armée', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000117',
        'Le pouvoir appartient à une famille royale', FALSE, 3);

-- ---------------------------------------------------------------------------
-- BLOC 13 : HISTOIRE DE LA RÉPUBLIQUE
-- ---------------------------------------------------------------------------

-- Q61 - Quand la 1re République a-t-elle été proclamée ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000118', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'NAT', 'CONNAISSANCE',
        'En quelle année la première République française a-t-elle été proclamée ?',
        'La première République a été proclamée le 22 septembre 1792, après la chute de la monarchie. La France a ensuite connu plusieurs régimes avant la stabilité républicaine.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000118', '1792', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000118', '1789', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000118', '1848', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000118', '1870', FALSE, 3);

-- Q62 - Combien y a-t-il eu de Républiques en France ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000119', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Combien y a-t-il eu de Républiques en France depuis 1792 ?',
        'La France a connu cinq Républiques : Ire (1792), IIe (1848), IIIe (1870), IVe (1946) et Ve (1958, régime actuel).',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000119', 'Cinq', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000119', 'Trois', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000119', 'Quatre', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000119', 'Sept', FALSE, 3);

-- Q63 - Qui a fondé la Ve République ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-00000000011a', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Quel homme politique a fondé la Ve République ?',
        'La Ve République a été fondée en 1958 par le général Charles de Gaulle, qui en est aussi le premier Président (1959-1969).',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000011a', 'Charles de Gaulle', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000011a', 'François Mitterrand', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000011a', 'Georges Pompidou', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000011a', 'Léon Blum', FALSE, 3);

-- Q64 - Qu'est-ce que la Déclaration des droits de l'homme ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-00000000011b', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Qu''est-ce que la Déclaration des droits de l''homme et du citoyen ?',
        'Adoptée le 26 août 1789, c''est un texte fondateur de la Révolution qui proclame les droits naturels et l''égalité des hommes. Elle a aujourd''hui valeur constitutionnelle.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000011b',
        'Un texte de 1789 qui proclame les droits fondamentaux', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000011b', 'Une loi récente sur l''immigration', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000011b', 'Un traité militaire', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000011b', 'Un texte religieux', FALSE, 3);

-- ---------------------------------------------------------------------------
-- BLOC 14 : ÉGALITÉ HOMMES / FEMMES
-- ---------------------------------------------------------------------------

-- Q65 - Qu'est-ce que la parité ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-00000000011c', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Qu''est-ce que la parité en politique ?',
        'La parité est le principe d''égale représentation des hommes et des femmes, notamment sur les listes électorales. La loi impose la parité dans plusieurs scrutins depuis 2000.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000011c',
        'L''égale représentation des hommes et des femmes', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000011c', 'Le même salaire pour tous', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000011c', 'L''égalité entre les régions', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000011c', 'L''égalité entre les religions', FALSE, 3);

-- Q66 - Égalité salariale hommes/femmes : obligatoire ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-00000000011d', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'MISE_SITUATION',
        'Pour un même travail, une femme et un homme doivent-ils être payés pareil ?',
        'Oui. Le principe "à travail égal, salaire égal" est inscrit dans la loi depuis 1972. Toute discrimination salariale fondée sur le sexe est interdite et punie.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000011d',
        'Oui, c''est obligatoire (à travail égal, salaire égal)', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000011d', 'Non, l''employeur décide librement', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000011d', 'Non, les hommes gagnent plus par tradition', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000011d', 'Uniquement dans la fonction publique', FALSE, 3);

-- Q67 - Mariage entre personnes de même sexe : autorisé ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-00000000011e', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Le mariage entre deux personnes de même sexe est-il autorisé en France ?',
        'Oui. Depuis la loi du 17 mai 2013, deux personnes de même sexe peuvent se marier en France et adopter des enfants ensemble.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000011e', 'Oui, depuis 2013', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000011e', 'Non, c''est interdit', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000011e',
        'Oui, mais uniquement dans certaines communes', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000011e', 'Non, sauf autorisation religieuse', FALSE, 3);

-- Q68 - Que faire en cas de violences conjugales ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-00000000011f', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'MISE_SITUATION',
        'Quel numéro gratuit appeler en cas de violences conjugales ?',
        'Le 3919 est le numéro national d''écoute pour les femmes victimes de violences (anonyme, gratuit). En urgence, on appelle aussi le 17 (police) ou le 112.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000011f', 'Le 3919', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000011f', 'Le 15', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000011f', 'Le 18', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000011f', 'Le 3615', FALSE, 3);

-- Q69 - Le harcèlement sexuel est-il un délit ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000120', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'MISE_SITUATION',
        'Le harcèlement sexuel est-il un délit en France ?',
        'Oui. Le harcèlement sexuel est un délit puni de prison et d''amende. La loi protège toutes les personnes, dans le travail comme dans la vie courante.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000120', 'Oui, c''est un délit puni par la loi', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000120',
        'Non, ce n''est qu''une faute morale', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000120',
        'Uniquement entre adultes consentants', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000120',
        'Uniquement sur le lieu de travail', FALSE, 3);

-- ---------------------------------------------------------------------------
-- BLOC 15 : DISCRIMINATIONS
-- ---------------------------------------------------------------------------

-- Q70 - Qu'est-ce qu'une discrimination ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000121', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Qu''est-ce qu''une discrimination ?',
        'Une discrimination consiste à traiter une personne moins bien qu''une autre dans une situation comparable, sur la base d''un critère interdit par la loi (origine, sexe, religion, handicap, âge...).',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000121',
        'Traiter quelqu''un moins bien à cause d''un critère interdit', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000121',
        'Respecter les préférences de chacun', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000121',
        'Faire payer un impôt', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000121',
        'Inviter ses amis à une fête privée', FALSE, 3);

-- Q71 - Citez un critère de discrimination interdit
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000122', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Parmi ces critères, lequel ne peut PAS justifier un traitement défavorable selon la loi française ?',
        'La loi interdit toute discrimination fondée sur l''origine, le sexe, la religion, l''orientation sexuelle, l''âge, le handicap, l''état de santé, l''apparence... (plus de 20 critères).',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000122', 'L''origine de la personne', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000122', 'L''expérience professionnelle', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000122', 'Les diplômes obtenus', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000122', 'Les compétences techniques', FALSE, 3);

-- Q72 - Le racisme est-il puni par la loi ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000123', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Le racisme est-il puni par la loi en France ?',
        'Oui. Les propos et actes racistes sont des délits punis de prison et d''amende. La loi Pleven (1972) et la loi Gayssot (1990) renforcent ce dispositif.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000123', 'Oui, c''est un délit', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000123',
        'Non, c''est protégé par la liberté d''expression', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000123', 'Uniquement dans la rue', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000123', 'Uniquement contre les Français', FALSE, 3);

-- Q73 - Qui peut être saisi en cas de discrimination ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000124', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'NAT', 'CONNAISSANCE',
        'Quelle autorité peut être saisie gratuitement en cas de discrimination ?',
        'Le Défenseur des droits est une autorité indépendante qui défend les droits des citoyens. Sa saisine est gratuite et il peut agir en cas de discrimination, violence policière ou atteinte aux droits.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000124', 'Le Défenseur des droits', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000124',
        'Le Président de la République en personne', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000124', 'La gendarmerie nationale uniquement', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000124', 'Une association sportive', FALSE, 3);

-- Q74 - L'homophobie est-elle un délit ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000125', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'L''homophobie (propos ou actes haineux envers les personnes homosexuelles) est-elle un délit ?',
        'Oui. Depuis 2003, les propos et actes homophobes sont des délits punis comme les autres formes de discrimination, par la prison et l''amende.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000125', 'Oui, c''est un délit puni par la loi', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000125', 'Non, c''est une opinion personnelle', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000125',
        'Uniquement contre des personnes mariées', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000125', 'Uniquement dans le sport', FALSE, 3);

-- ---------------------------------------------------------------------------
-- BLOC 16 : LAÏCITÉ APPROFONDIE
-- ---------------------------------------------------------------------------

-- Q75 - Quand a été votée la loi sur les signes religieux à l'école ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000126', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'NAT', 'CONNAISSANCE',
        'En quelle année a été votée la loi interdisant les signes religieux ostensibles à l''école publique ?',
        'La loi du 15 mars 2004 interdit le port de signes religieux ostensibles (voile, kippa, grande croix...) dans les écoles, collèges et lycées publics.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000126', '2004', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000126', '1905', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000126', '1989', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000126', '2010', FALSE, 3);

-- Q76 - Que dit la loi de 2004 sur l'école ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000127', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Que dit la loi du 15 mars 2004 ?',
        'Elle interdit dans les écoles, collèges et lycées publics les signes religieux ostensibles. L''objectif est de protéger l''école comme espace neutre, conforme à la laïcité.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000127',
        'Elle interdit les signes religieux ostensibles à l''école publique', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000127',
        'Elle interdit toutes les religions en France', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000127',
        'Elle oblige les élèves à aller à la messe', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000127',
        'Elle réserve l''école aux Français', FALSE, 3);

-- Q77 - Un fonctionnaire peut-il porter un signe religieux au travail ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000128', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'MISE_SITUATION',
        'Un fonctionnaire (agent public) peut-il porter un signe religieux visible pendant son service ?',
        'Non. Le principe de neutralité impose à tous les agents publics (enseignants, policiers, employés de mairie...) de ne pas manifester leurs opinions religieuses dans le cadre de leurs fonctions.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000128',
        'Non, il a un devoir de neutralité', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000128',
        'Oui, c''est sa liberté religieuse', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000128',
        'Oui, mais uniquement le vendredi', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000128',
        'Uniquement avec autorisation écrite', FALSE, 3);

-- Q78 - Que dit la charte de la laïcité à l'école ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000129', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'NAT', 'CONNAISSANCE',
        'Que prévoit la Charte de la laïcité à l''école, adoptée en 2013 ?',
        'La Charte de la laïcité à l''école rappelle les principes de neutralité et de laïcité à l''école publique : respect des différences, liberté de conscience, refus du prosélytisme.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000129',
        'Les règles de laïcité à l''école pour élèves et personnels', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000129',
        'L''interdiction des religions dans la société', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000129',
        'L''obligation de pratiquer une religion', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000129',
        'Les horaires des cours d''éducation religieuse', FALSE, 3);

-- Q79 - Existe-t-il un régime particulier en Alsace-Moselle ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-00000000012a', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'NAT', 'CONNAISSANCE',
        'Existe-t-il une exception au régime de laïcité français dans certaines régions ?',
        'Oui. En Alsace et en Moselle, le Concordat de 1801 est toujours en vigueur : l''État rémunère certains ministres du culte (catholique, protestant, israélite). Ces départements n''étaient pas français en 1905.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000012a',
        'Oui, en Alsace et Moselle (Concordat de 1801 toujours en vigueur)', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000012a',
        'Non, la laïcité s''applique partout de la même manière', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000012a',
        'Oui, en Corse uniquement', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000012a',
        'Oui, dans les départements d''outre-mer', FALSE, 3);

-- Q80 - Une mère voilée peut-elle accompagner une sortie scolaire ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-00000000012b', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'NAT', 'MISE_SITUATION',
        'Une mère portant un voile religieux peut-elle accompagner une sortie scolaire ?',
        'Oui. Les parents accompagnateurs ne sont pas des agents publics : ils ne sont pas tenus à la neutralité religieuse, sauf s''ils troublent l''ordre ou se livrent au prosélytisme.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000012b',
        'Oui, sauf trouble à l''ordre ou prosélytisme', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000012b',
        'Non, c''est interdit en toutes circonstances', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000012b',
        'Oui, mais uniquement les mères françaises', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000012b',
        'Non, sauf accord du préfet', FALSE, 3);

-- ---------------------------------------------------------------------------
-- BLOC 17 : LIBERTÉS FONDAMENTALES
-- ---------------------------------------------------------------------------

-- Q81 - Qu'est-ce que la liberté de réunion ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-00000000012c', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Qu''est-ce que la liberté de réunion ?',
        'C''est le droit de se rassembler pacifiquement (manifestations, réunions publiques ou privées), sous réserve du respect de l''ordre public.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000012c',
        'Le droit de se rassembler pacifiquement', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000012c',
        'L''obligation de participer aux fêtes officielles', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000012c',
        'Le droit de bloquer une rue sans déclaration', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000012c',
        'Le droit de créer une milice privée', FALSE, 3);

-- Q82 - Qu'est-ce que la liberté de la presse ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-00000000012d', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Qu''est-ce que la liberté de la presse ?',
        'C''est le droit pour les journalistes et les médias d''informer librement, sans censure préalable. La loi de 1881 protège cette liberté fondamentale, avec des limites (diffamation, vie privée).',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000012d',
        'Le droit pour les médias d''informer librement', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000012d',
        'Le droit de mentir publiquement', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000012d',
        'Le monopole de l''État sur les journaux', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000012d',
        'L''obligation de lire la presse chaque jour', FALSE, 3);

-- Q83 - Qu'est-ce que la liberté de circulation ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-00000000012e', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Qu''est-ce que la liberté d''aller et venir ?',
        'C''est le droit de circuler librement sur le territoire français, de choisir son lieu de résidence et, pour les citoyens, de quitter et de revenir dans le pays.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000012e',
        'Le droit de circuler librement et de choisir son domicile', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000012e',
        'L''obligation de demander un visa pour changer de ville', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000012e',
        'Le droit réservé aux fonctionnaires', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000012e',
        'Le droit de conduire sans permis', FALSE, 3);

-- Q84 - La liberté syndicale existe-t-elle ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-00000000012f', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'La liberté syndicale est-elle reconnue en France ?',
        'Oui. Tout salarié peut adhérer librement à un syndicat, en créer un ou ne pas s''affilier. La loi protège les représentants syndicaux dans l''entreprise.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000012f',
        'Oui, chacun peut adhérer ou non à un syndicat', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000012f',
        'Non, les syndicats sont interdits', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000012f',
        'Oui, mais uniquement dans le public', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000012f',
        'Non, sauf pour les cadres', FALSE, 3);

-- Q85 - Le droit de grève est-il reconnu ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000130', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Le droit de grève est-il reconnu en France ?',
        'Oui. Le droit de grève a valeur constitutionnelle (Préambule de 1946). Il est encadré par la loi, notamment dans les services publics (préavis, service minimum).',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000130',
        'Oui, c''est un droit constitutionnel encadré par la loi', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000130',
        'Non, c''est interdit en France', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000130',
        'Oui, mais uniquement les samedis', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000130',
        'Non, sauf pour les agriculteurs', FALSE, 3);

-- ---------------------------------------------------------------------------
-- BLOC 18 : MISES EN SITUATION (vie quotidienne et principes)
-- ---------------------------------------------------------------------------

-- Q86 - Un employeur peut-il refuser une femme enceinte ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000131', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'MISE_SITUATION',
        'Un employeur peut-il refuser d''embaucher une femme parce qu''elle est enceinte ?',
        'Non. C''est une discrimination interdite par le Code du travail, punie de prison et d''amende. La grossesse ne peut être un motif de refus d''embauche ni de licenciement.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000131',
        'Non, c''est une discrimination interdite', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000131', 'Oui, c''est son droit', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000131', 'Oui, pour protéger la santé de la femme', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000131', 'Oui, dans les petites entreprises', FALSE, 3);

-- Q87 - Un propriétaire peut-il refuser pour l'origine ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000132', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'MISE_SITUATION',
        'Un propriétaire peut-il refuser de louer un appartement à cause de l''origine du candidat locataire ?',
        'Non. C''est une discrimination raciale interdite par la loi, qui peut être signalée au Défenseur des droits. Le propriétaire peut refuser pour des motifs objectifs (revenus, garanties) mais pas pour l''origine.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000132',
        'Non, c''est une discrimination interdite', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000132',
        'Oui, le propriétaire choisit son locataire librement', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000132',
        'Oui, sauf en HLM', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000132',
        'Uniquement dans les grandes villes', FALSE, 3);

-- Q88 - Une mairie peut-elle refuser un mariage pour motif religieux ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000133', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'NAT', 'MISE_SITUATION',
        'Un maire peut-il refuser de marier deux personnes parce qu''elles sont de religions différentes ?',
        'Non. Le mariage civil est un acte républicain laïque. Le maire, en sa qualité d''officier d''état civil, ne peut refuser un mariage pour des motifs religieux ou personnels.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000133',
        'Non, le mariage civil est laïque et obligatoire pour le maire', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000133',
        'Oui, si la religion du maire l''interdit', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000133',
        'Oui, si l''un des conjoints n''est pas baptisé', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000133',
        'Oui, avec accord du conseil municipal', FALSE, 3);

-- Q89 - Un médecin peut-il refuser un patient pour l'origine ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000134', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'MISE_SITUATION',
        'Un médecin peut-il refuser un patient à cause de son origine ou de sa nationalité ?',
        'Non. Le Code de la santé publique et le code de déontologie médicale interdisent toute discrimination. Le serment d''Hippocrate engage le médecin à soigner sans distinction.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000134',
        'Non, c''est une discrimination interdite', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000134',
        'Oui, c''est sa clientèle privée', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000134',
        'Oui, sauf urgence vitale', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000134',
        'Uniquement dans le secteur privé', FALSE, 3);

-- Q90 - Un homme peut-il refuser d'être soigné par une femme ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000135', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'MISE_SITUATION',
        'À l''hôpital public, un patient peut-il refuser d''être soigné par une femme médecin ?',
        'Non. L''égalité hommes-femmes et la neutralité du service public s''imposent : le patient ne choisit pas son soignant en fonction de son sexe. Refuser un soin pour ce motif n''est pas un droit.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000135',
        'Non, l''égalité et le service public s''imposent', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000135',
        'Oui, c''est son droit personnel', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000135',
        'Oui, si sa religion l''impose', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000135',
        'Uniquement avec l''accord du chef de service', FALSE, 3);

-- Q91 - Une commune peut-elle financer une église ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000136', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'NAT', 'CONNAISSANCE',
        'Une commune peut-elle financer la construction d''un nouveau lieu de culte ?',
        'Non. La loi de 1905 interdit à l''État et aux collectivités de subventionner les cultes. Elles peuvent en revanche entretenir les édifices religieux construits avant 1905 (propriétés publiques).',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000136',
        'Non, la loi de 1905 l''interdit', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000136',
        'Oui, librement', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000136',
        'Oui, pour la religion majoritaire seulement', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000136',
        'Oui, avec accord du préfet', FALSE, 3);

-- Q92 - Un syndicat peut-il refuser pour la religion ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000137', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'MISE_SITUATION',
        'Un syndicat peut-il refuser l''adhésion d''un salarié à cause de sa religion ?',
        'Non. La discrimination religieuse est interdite, y compris dans les associations et syndicats. La liberté syndicale s''accompagne du respect de la non-discrimination.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000137',
        'Non, c''est une discrimination interdite', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000137',
        'Oui, le syndicat choisit ses adhérents', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000137',
        'Oui, si le syndicat est confessionnel', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000137',
        'Uniquement avec accord de l''entreprise', FALSE, 3);

-- Q93 - Peut-on critiquer une religion publiquement ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000138', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'NAT', 'MISE_SITUATION',
        'A-t-on le droit de critiquer publiquement une religion en France ?',
        'Oui. La critique d''idées, de dogmes ou de pratiques religieuses est autorisée au nom de la liberté d''expression. En revanche, attaquer les personnes (insultes, incitation à la haine) reste interdit.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000138',
        'Oui, on peut critiquer une religion ; pas attaquer les personnes', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000138',
        'Non, le blasphème est puni par la loi', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000138',
        'Oui, sans aucune limite', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000138',
        'Non, c''est interdit par la Constitution', FALSE, 3);

-- Q94 - Une entreprise privée peut-elle imposer une tenue neutre ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000139', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'NAT', 'MISE_SITUATION',
        'Une entreprise privée peut-elle imposer à ses salariés une tenue de travail neutre, sans signes religieux ?',
        'Oui, sous conditions. Le règlement intérieur peut limiter le port de signes religieux s''il s''agit d''une exigence professionnelle objective et proportionnée (sécurité, neutralité face aux clients).',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000139',
        'Oui, si c''est justifié et proportionné', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000139',
        'Non, jamais dans le privé', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000139',
        'Oui, sans aucune justification', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000139',
        'Uniquement pour les femmes', FALSE, 3);

-- Q95 - L'instruction est-elle obligatoire pour les enfants ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-00000000013a', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'À partir de quel âge l''instruction est-elle obligatoire en France ?',
        'L''instruction est obligatoire de 3 à 16 ans (depuis 2019, auparavant à partir de 6 ans). Elle peut être suivie à l''école publique, privée, ou à domicile sous conditions.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000013a', 'De 3 à 16 ans', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000013a', 'De 6 à 18 ans', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000013a', 'De 7 à 14 ans', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000013a', 'L''instruction n''est pas obligatoire', FALSE, 3);

-- Q96 - L'école publique est-elle gratuite ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-00000000013b', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CSP', 'CONNAISSANCE',
        'L''école publique en France est-elle gratuite ?',
        'Oui. L''école publique est gratuite, laïque et obligatoire depuis les lois Jules Ferry (1881-1882). C''est un fondement de la République.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000013b', 'Oui, gratuite et laïque', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000013b', 'Non, il faut payer chaque année', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000013b',
        'Oui, mais uniquement pour les Français', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000013b',
        'Uniquement de la maternelle au CM2', FALSE, 3);

-- Q97 - Que faire si l'on est témoin d'un acte raciste ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-00000000013c', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'MISE_SITUATION',
        'Que peut-on faire si on est témoin d''un acte ou de propos racistes ?',
        'On peut alerter la police (17 ou 112), porter plainte, ou saisir gratuitement le Défenseur des droits. Des associations comme SOS Racisme ou la LICRA accompagnent les victimes.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000013c',
        'Alerter la police, porter plainte ou saisir le Défenseur des droits', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000013c',
        'Ne rien faire, ce n''est pas son problème', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000013c',
        'Insulter la personne raciste en retour', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000013c',
        'Attendre que la situation se reproduise', FALSE, 3);
