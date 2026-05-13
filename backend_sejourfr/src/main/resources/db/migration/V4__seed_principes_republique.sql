-- ============================================================================
-- Questions officielles - Thematique 1 : Principes et valeurs de la Republique
-- Source : site du ministere de l'Interieur (livret du citoyen)
-- ============================================================================
-- Thematique : 11111111-0000-0000-0000-000000000001 (CIV_PRINCIPES)
-- Repartition CSP/CR/NAT calibree par difficulte
-- ============================================================================

-- ---------------------------------------------------------------------------
-- BLOC 1 : SYMBOLES & DEVISE (niveau CSP majoritairement)
-- ---------------------------------------------------------------------------

-- Q1 - A quoi correspond la date du 14 juillet ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000001', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CSP', 'CONNAISSANCE',
        'A quoi correspond la date du 14 juillet ?',
        'Le 14 juillet est la fete nationale francaise. Elle commemore la prise de la Bastille en 1789, evenement majeur de la Revolution francaise, et la Fete de la Federation de 1790.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000001', 'La fete nationale francaise', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000001', 'La fete du Travail', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000001', 'L''Armistice de 1918', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000001', 'La fete de la Victoire', FALSE, 3);

-- Q2 - Quel est l'un des symboles de la Republique francaise ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000002', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CSP', 'CONNAISSANCE',
        'Quel est l''un des symboles de la Republique francaise ?',
        'Marianne est l''un des symboles officiels de la Republique francaise, avec le drapeau tricolore, La Marseillaise, la devise et le coq.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000002', 'Marianne', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000002', 'La tour Eiffel', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000002', 'Le Mont-Saint-Michel', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000002', 'L''Arc de Triomphe', FALSE, 3);

-- Q3 - Lequel de ces symboles represente officiellement la Republique francaise ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000003', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CSP', 'CONNAISSANCE',
        'Lequel de ces symboles represente officiellement la Republique francaise ?',
        'Le drapeau tricolore bleu-blanc-rouge est l''embleme national de la France, inscrit dans l''article 2 de la Constitution.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000003', 'Le drapeau tricolore', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000003', 'La Tour Eiffel', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000003', 'Notre-Dame de Paris', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000003', 'Le Louvre', FALSE, 3);

-- Q4 - Quels sont des symboles officiels de la Republique francaise ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000004', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Quels sont des symboles officiels de la Republique francaise ?',
        'Les principaux symboles officiels sont : le drapeau tricolore, La Marseillaise, Marianne, la devise "Liberte, Egalite, Fraternite" et le coq gaulois.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000004', 'Le drapeau, La Marseillaise et Marianne',
        TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000004', 'La baguette, le beret et le vin', FALSE,
        1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000004',
        'Le president, le Premier ministre et les ministres', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000004', 'Paris, Lyon et Marseille', FALSE, 3);

-- Q5 - Quel symbole de la Republique francaise est tricolore ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000005', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CSP', 'CONNAISSANCE',
        'Quel symbole de la Republique francaise est tricolore ?',
        'Le drapeau francais est tricolore : bleu, blanc et rouge. Ces couleurs ont ete adoptees pendant la Revolution francaise.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000005', 'Le drapeau', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000005', 'La Marseillaise', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000005', 'Le coq', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000005', 'Marianne', FALSE, 3);

-- Q6 - Quelles sont les couleurs du drapeau francais ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000006', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CSP', 'CONNAISSANCE',
        'Quelles sont les couleurs du drapeau francais ?',
        'Le drapeau francais est compose de trois bandes verticales : bleu, blanc et rouge, de gauche a droite quand on le regarde.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000006', 'Bleu, blanc, rouge', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000006', 'Rouge, blanc, vert', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000006', 'Bleu, jaune, rouge', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000006', 'Blanc, bleu, jaune', FALSE, 3);

-- Q7 - Quel animal est un symbole de la France ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000007', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CSP', 'CONNAISSANCE',
        'Quel animal est un symbole de la France ?',
        'Le coq gaulois est un embleme traditionnel de la France, herite de l''epoque gallo-romaine. On le retrouve notamment sur les maillots des equipes sportives nationales.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000007', 'Le coq', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000007', 'L''aigle', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000007', 'Le lion', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000007', 'Le loup', FALSE, 3);

-- Q8 - Qui est Marianne ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000008', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Qui est Marianne ?',
        'Marianne est l''allegorie (la representation symbolique) de la Republique francaise. Son buste est present dans toutes les mairies de France.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000008', 'L''allegorie de la Republique francaise',
        TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000008', 'La premiere reine de France', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000008', 'L''epouse du president actuel', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000008', 'Une sainte catholique', FALSE, 3);

-- Q9 - Quel est le nom de l'hymne national ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000009', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CSP', 'CONNAISSANCE',
        'Quel est le nom de l''hymne national ?',
        'La Marseillaise est l''hymne national de la France. Ecrite par Rouget de Lisle en 1792 a Strasbourg, elle est devenue hymne national en 1795.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000009', 'La Marseillaise', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000009', 'L''Internationale', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000009', 'Le chant des partisans', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000009', 'La Parisienne', FALSE, 3);

-- Q10 - Qu'est-ce que la Marseillaise ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-00000000000a', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CSP', 'CONNAISSANCE',
        'Qu''est-ce que la Marseillaise ?',
        'La Marseillaise est l''hymne national de la France. Elle est chantee lors des ceremonies officielles et des evenements sportifs internationaux.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000000a', 'L''hymne national francais', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000000a', 'Un quartier de Marseille', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000000a', 'Une recette de cuisine provencale', FALSE,
        2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000000a', 'Une danse traditionnelle', FALSE, 3);

-- ---------------------------------------------------------------------------
-- BLOC 2 : DEVISE & VALEURS REPUBLICAINES
-- ---------------------------------------------------------------------------

-- Q11 - Quelle est la devise de la Republique francaise ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-00000000000b', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CSP', 'CONNAISSANCE',
        'Quelle est la devise de la Republique francaise ?',
        'La devise "Liberte, Egalite, Fraternite" est inscrite a l''article 2 de la Constitution. Elle resume les valeurs fondamentales de la Republique.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000000b', 'Liberte, Egalite, Fraternite', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000000b', 'Liberte, Fraternite, Solidarite', FALSE,
        1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000000b', 'Liberte, Justice, Paix', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000000b', 'Unite, Travail, Patrie', FALSE, 3);

-- Q12 - Ou peut-on voir la devise de la Republique ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-00000000000c', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Ou peut-on voir la devise de la Republique ?',
        'La devise "Liberte, Egalite, Fraternite" est inscrite sur le fronton de tous les batiments publics : mairies, ecoles, prefectures, tribunaux.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000000c', 'Sur le fronton des batiments publics',
        TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000000c', 'Sur les pieces de 1 centime uniquement',
        FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000000c', 'Dans les eglises catholiques', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000000c', 'Sur les plaques d''immatriculation',
        FALSE, 3);

-- Q13 - "Liberte, egalite, fraternite", c'est :
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-00000000000d', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CSP', 'CONNAISSANCE',
        '"Liberte, egalite, fraternite", c''est :',
        '"Liberte, Egalite, Fraternite" est la devise officielle de la Republique francaise depuis 1880, reprise dans les Constitutions de 1946 et 1958.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000000d', 'La devise de la Republique francaise',
        TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000000d', 'Le titre de l''hymne national', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000000d', 'Une chanson populaire', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000000d', 'Une loi recente', FALSE, 3);

-- Q14 - Que signifie la liberte ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-00000000000e', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Que signifie la liberte ?',
        'La liberte est le droit de faire ce que les lois permettent, dans le respect des libertes des autres. Article 4 de la Declaration des droits de l''homme et du citoyen de 1789.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000000e',
        'Le droit de faire ce que la loi permet, dans le respect des autres', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000000e',
        'Le droit de faire absolument tout ce que l''on veut', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000000e', 'L''obligation d''obeir au gouvernement',
        FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000000e', 'Le droit reserve aux citoyens francais',
        FALSE, 3);

-- Q15 - Qu'est-ce que l'egalite ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-00000000000f', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Qu''est-ce que l''egalite ?',
        'L''egalite signifie que tous les citoyens sont egaux devant la loi, sans distinction d''origine, de race, de religion, de sexe ou d''opinion.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000000f',
        'Tous les citoyens sont egaux devant la loi', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000000f', 'Tout le monde gagne le meme salaire',
        FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000000f', 'Tout le monde a la meme apparence', FALSE,
        2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000000f',
        'Tout le monde doit avoir les memes opinions', FALSE, 3);

-- Q16 - Le principe d'egalite signifie que :
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000010', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Le principe d''egalite signifie que :',
        'Le principe d''egalite garantit que la loi s''applique de la meme maniere a tous, sans discrimination liee a l''origine, au sexe, a la religion ou aux opinions.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000010',
        'La loi est la meme pour tous, sans discrimination', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000010',
        'Tout le monde doit posseder les memes biens', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000010',
        'Les hommes et les femmes ont des roles differents', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000010',
        'Les Francais ont plus de droits que les etrangers', FALSE, 3);

-- Q17 - Que signifie le mot "fraternite" dans la devise francaise ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000011', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Que signifie le mot "fraternite" dans la devise francaise ?',
        'La fraternite represente la solidarite et l''entraide entre les citoyens. Elle implique le respect, la tolerance et le devoir d''aider les autres.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000011',
        'La solidarite et l''entraide entre les citoyens', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000011',
        'Le lien familial entre freres et soeurs uniquement', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000011', 'L''appartenance a la meme religion',
        FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000011', 'Le service militaire obligatoire', FALSE,
        3);

-- Q18 - Quel est l'un des roles des associations ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000012', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Quel est l''un des roles des associations ?',
        'Les associations contribuent a la solidarite et a la vie sociale (aide aux personnes en difficulte, sport, culture, education...). Elles sont une expression de la fraternite.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000012',
        'Aider les personnes et contribuer a la vie sociale', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000012', 'Remplacer le gouvernement', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000012', 'Imposer des taxes aux citoyens', FALSE,
        2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000012',
        'Reserver leurs services aux Francais uniquement', FALSE, 3);

-- ---------------------------------------------------------------------------
-- BLOC 3 : CONSTITUTION & REGIME POLITIQUE
-- ---------------------------------------------------------------------------

-- Q19 - De quand date la Constitution de la Ve Republique ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000013', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'De quand date la Constitution de la Ve Republique ?',
        'La Constitution de la Ve Republique a ete adoptee le 4 octobre 1958, sous l''impulsion du general de Gaulle. Elle est toujours en vigueur aujourd''hui.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000013', '1958', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000013', '1789', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000013', '1945', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000013', '1981', FALSE, 3);

-- Q20 - Le regime de la France est :
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000014', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Le regime de la France est :',
        'La France est une republique democratique. L''article 1er de la Constitution precise : "La France est une Republique indivisible, laique, democratique et sociale."',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000014', 'Une republique democratique', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000014', 'Une monarchie constitutionnelle', FALSE,
        1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000014', 'Une dictature militaire', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000014', 'Une theocratie', FALSE, 3);

-- Q21 - "La France est une Republique indivisible, ..., democratique et sociale". Completez :
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000015', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'NAT', 'CONNAISSANCE',
        '"La France est une Republique indivisible, ..., democratique et sociale". Completez cette phrase extraite de l''article 1er de la Constitution :',
        'L''article 1er de la Constitution definit la France comme une Republique "indivisible, laique, democratique et sociale". La laicite est l''un des quatre principes fondamentaux.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000015', 'laique', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000015', 'religieuse', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000015', 'monarchique', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000015', 'federale', FALSE, 3);

-- ---------------------------------------------------------------------------
-- BLOC 4 : FETE NATIONALE
-- ---------------------------------------------------------------------------

-- Q22 - Quelle est la date de la fete nationale francaise ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000016', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CSP', 'CONNAISSANCE',
        'Quelle est la date de la fete nationale francaise ?',
        'La fete nationale francaise est le 14 juillet. Elle commemore la prise de la Bastille en 1789 et la Fete de la Federation de 1790.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000016', 'Le 14 juillet', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000016', 'Le 1er mai', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000016', 'Le 11 novembre', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000016', 'Le 8 mai', FALSE, 3);

-- Q23 - Qu'est-ce qui est traditionnellement organise sur les Champs-Elysees le 14 juillet ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000017', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CSP', 'CONNAISSANCE',
        'Qu''est-ce qui est traditionnellement organise sur les Champs-Elysees le 14 juillet pour celebrer la fete nationale ?',
        'Un defile militaire est organise chaque annee sur les Champs-Elysees a Paris, en presence du president de la Republique. C''est la plus ancienne et la plus grande parade militaire d''Europe.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000017', 'Un defile militaire', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000017', 'Un marche de Noel', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000017', 'Une course cycliste', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000017', 'Un concert de musique classique', FALSE,
        3);

-- ---------------------------------------------------------------------------
-- BLOC 5 : LANGUE FRANCAISE
-- ---------------------------------------------------------------------------

-- Q24 - Quelle est la langue officielle de la Republique francaise ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000018', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CSP', 'CONNAISSANCE',
        'Quelle est la langue officielle de la Republique francaise ?',
        'Le francais est la langue officielle de la Republique, inscrit dans l''article 2 de la Constitution depuis 1992.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000018', 'Le francais', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000018', 'L''anglais', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000018', 'Le francais et l''anglais', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000018', 'Aucune langue officielle n''est definie',
        FALSE, 3);

-- Q25 - Quelle est la place de la langue francaise dans la Republique ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000019', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Quelle est la place de la langue francaise dans la Republique ?',
        'Le francais est la langue officielle et de l''administration. Sa connaissance est un element essentiel d''integration et est exigee pour la naturalisation.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000019',
        'C''est la langue officielle et le lien commun entre les citoyens', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000019',
        'C''est une langue parmi d''autres, sans statut particulier', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000019', 'C''est une langue reservee a l''ecrit',
        FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000019',
        'Elle n''est pas obligatoire pour les services publics', FALSE, 3);

-- ---------------------------------------------------------------------------
-- BLOC 6 : LIBERTE D'EXPRESSION & DROITS
-- ---------------------------------------------------------------------------

-- Q26 - Quelle liberte permet a chacun d'exprimer ses idees ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-00000000001a', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Quelle liberte permet a chacun d''exprimer ses idees ?',
        'La liberte d''expression permet a chacun d''exprimer ses opinions, par la parole, l''ecrit, l''image. Elle est garantie par la Declaration des droits de l''homme et du citoyen de 1789.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000001a', 'La liberte d''expression', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000001a', 'La liberte de circulation', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000001a', 'La liberte du commerce', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000001a', 'La liberte de propriete', FALSE, 3);

-- Q27 - Quelle proposition est correcte ? La liberte d'expression :
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-00000000001b', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'NAT', 'CONNAISSANCE',
        'Quelle proposition est correcte ? La liberte d''expression :',
        'La liberte d''expression n''est pas absolue : elle est encadree par la loi. L''injure, la diffamation, l''incitation a la haine ou a la violence sont interdites.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000001b',
        'A des limites fixees par la loi (injure, diffamation, incitation a la haine)', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000001b', 'Est totale et sans aucune limite', FALSE,
        1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000001b', 'N''existe pas en France', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000001b', 'Est reservee aux journalistes', FALSE, 3);

-- Q28 - A-t-on le droit d'insulter publiquement quelqu'un parce qu'il est different ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-00000000001c', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'MISE_SITUATION',
        'A-t-on le droit d''insulter publiquement quelqu''un parce qu''il est different (handicap, apparence physique, sexe...) ?',
        'Non. Les injures et discriminations sont interdites par la loi et punies penalement. Le respect de la dignite de chacun est un principe fondamental.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000001c', 'Non, c''est interdit et puni par la loi',
        TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000001c', 'Oui, c''est la liberte d''expression',
        FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000001c', 'Oui, mais seulement sur Internet', FALSE,
        2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000001c', 'Oui, si c''est dit avec humour', FALSE,
        3);

-- Q29 - Certains metiers peuvent-ils etre reserves aux hommes ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-00000000001d', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'MISE_SITUATION',
        'Certains metiers peuvent-ils etre reserves aux hommes ?',
        'Non. L''egalite entre les hommes et les femmes est un principe constitutionnel. Tous les metiers sont accessibles aux deux sexes sans distinction.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000001d',
        'Non, l''egalite hommes-femmes interdit toute discrimination', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000001d', 'Oui, certains metiers physiques', FALSE,
        1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000001d', 'Oui, les metiers militaires', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000001d', 'Oui, si l''employeur le decide', FALSE,
        3);

-- ---------------------------------------------------------------------------
-- BLOC 7 : LAICITE (NIVEAU CR/NAT)
-- ---------------------------------------------------------------------------

-- Q30 - Qu'est-ce que la laicite ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-00000000001e', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Qu''est-ce que la laicite ?',
        'La laicite est la separation entre l''Etat et les religions. L''Etat est neutre, ne reconnait aucun culte et garantit la liberte de conscience de chacun.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000001e',
        'La separation entre l''Etat et les religions', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000001e', 'L''interdiction de toutes les religions',
        FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000001e', 'L''obligation de pratiquer une religion',
        FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000001e', 'Le respect d''une religion d''Etat',
        FALSE, 3);

-- Q31 - En quelle annee la loi de separation des Eglises et de l'Etat a-t-elle ete votee ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-00000000001f', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'NAT', 'CONNAISSANCE',
        'En quelle annee la loi de separation des Eglises et de l''Etat a-t-elle ete votee ?',
        'La loi de separation des Eglises et de l''Etat a ete votee le 9 decembre 1905. Elle pose les bases de la laicite francaise.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000001f', '1905', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000001f', '1789', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000001f', '1958', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000001f', '1881', FALSE, 3);

-- Q32 - Que permet le principe de laicite ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000020', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Que permet le principe de laicite ?',
        'La laicite garantit la liberte de conscience : chacun peut croire, ne pas croire ou changer de religion, dans le respect des autres et de la loi.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000020', 'La liberte de croire ou de ne pas croire',
        TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000020', 'D''interdire toutes les religions', FALSE,
        1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000020', 'De favoriser une religion en particulier',
        FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000020',
        'D''obliger les citoyens a suivre une religion', FALSE, 3);

-- Q33 - Quel droit est garanti par la laicite ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000021', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Quel droit est garanti par la laicite ?',
        'La laicite garantit la liberte de conscience et de religion : chacun peut pratiquer la religion de son choix ou n''en pratiquer aucune.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000021', 'La liberte de conscience et de religion',
        TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000021', 'Le droit a la propriete privee', FALSE,
        1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000021', 'Le droit de vote des etrangers', FALSE,
        2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000021', 'Le droit a la securite sociale', FALSE,
        3);

-- Q34 - Pourquoi le principe de laicite doit-il etre respecte a l'ecole ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000022', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'NAT', 'CONNAISSANCE',
        'Pourquoi le principe de laicite doit-il etre respecte a l''ecole ?',
        'L''ecole publique est laique pour garantir l''egalite de tous les eleves, leur permettre de se former librement et eviter toute pression religieuse.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000022',
        'Pour garantir l''egalite entre les eleves et la liberte de conscience', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000022', 'Parce que les religions sont interdites',
        FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000022', 'Pour favoriser la religion catholique',
        FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000022',
        'Parce que les enseignants choisissent la religion des eleves', FALSE, 3);

-- Q35 - Un enfant peut-il refuser d'aller a l'ecole pour une raison religieuse ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000023', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'MISE_SITUATION',
        'Un enfant peut-il refuser d''aller a l''ecole pour une raison religieuse ?',
        'Non. L''instruction est obligatoire pour tous les enfants de 3 a 16 ans. Aucun motif religieux ne peut justifier l''absence ou refuser certains enseignements.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000023',
        'Non, l''instruction est obligatoire de 3 a 16 ans', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000023', 'Oui, la religion passe avant la loi',
        FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000023', 'Oui, si les parents le decident', FALSE,
        2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000023', 'Oui, certains jours de l''annee', FALSE,
        3);

-- Q36 - Une personne a-t-elle le droit de ne pas croire en une religion ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000024', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'MISE_SITUATION',
        'Une personne a-t-elle le droit de ne pas croire en une religion ?',
        'Oui. La liberte de conscience, garantie par la laicite, comprend le droit de ne pas croire (athe, agnostique). Personne ne peut etre force a adherer a une religion.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000024',
        'Oui, la liberte de conscience est garantie', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000024',
        'Non, il faut obligatoirement avoir une religion', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000024', 'Oui, mais seulement les Francais', FALSE,
        2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000024', 'Non, c''est interdit par la Constitution',
        FALSE, 3);

-- Q37 - Une personne peut-elle changer librement de religion ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000025', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'MISE_SITUATION',
        'Une personne peut-elle changer librement de religion ?',
        'Oui. La liberte de conscience inclut le droit de choisir, changer ou abandonner une religion sans aucune contrainte. Nul ne peut etre force de rester dans une religion.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000025', 'Oui, c''est une liberte fondamentale',
        TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000025', 'Non, c''est strictement interdit', FALSE,
        1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000025', 'Oui, mais avec autorisation de l''Etat',
        FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000025', 'Oui, mais seulement une fois dans sa vie',
        FALSE, 3);