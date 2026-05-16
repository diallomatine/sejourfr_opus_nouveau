-- ============================================================================
-- Questions officielles - Thématique 1 : Principes et valeurs de la République
-- Source : site du ministère de l'Intérieur (livret du citoyen)
-- ============================================================================
-- Thématique : 11111111-0000-0000-0000-000000000001 (CIV_PRINCIPES)
-- Répartition CSP/CR/NAT calibrée par difficulté
-- ============================================================================

-- ---------------------------------------------------------------------------
-- BLOC 1 : SYMBOLES & DEVISE (niveau CSP majoritairement)
-- ---------------------------------------------------------------------------

-- Q1 - À quoi correspond la date du 14 juillet ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000001', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CSP', 'CONNAISSANCE',
        'À quoi correspond la date du 14 juillet ?',
        'Le 14 juillet est la fête nationale française. Elle commémore la prise de la Bastille en 1789, événement majeur de la Révolution française, et la Fête de la Fédération de 1790.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000001', 'La fête nationale française', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000001', 'La fête du Travail', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000001', 'L''Armistice de 1918', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000001', 'La fête de la Victoire', FALSE, 3);

-- Q2 - Quel est l'un des symboles de la République française ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000002', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CSP', 'CONNAISSANCE',
        'Quel est l''un des symboles de la République française ?',
        'Marianne est l''un des symboles officiels de la République française, avec le drapeau tricolore, La Marseillaise, la devise et le coq.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000002', 'Marianne', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000002', 'La tour Eiffel', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000002', 'Le Mont-Saint-Michel', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000002', 'L''Arc de Triomphe', FALSE, 3);

-- Q3 - Lequel de ces symboles représente officiellement la République française ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000003', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CSP', 'CONNAISSANCE',
        'Lequel de ces symboles représente officiellement la République française ?',
        'Le drapeau tricolore bleu-blanc-rouge est l''emblème national de la France, inscrit dans l''article 2 de la Constitution.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000003', 'Le drapeau tricolore', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000003', 'La Tour Eiffel', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000003', 'Notre-Dame de Paris', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000003', 'Le Louvre', FALSE, 3);

-- Q4 - Quels sont des symboles officiels de la République française ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000004', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Quels sont des symboles officiels de la République française ?',
        'Les principaux symboles officiels sont : le drapeau tricolore, La Marseillaise, Marianne, la devise "Liberté, Égalité, Fraternité" et le coq gaulois.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000004', 'Le drapeau, La Marseillaise et Marianne',
        TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000004', 'La baguette, le béret et le vin', FALSE,
        1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000004',
        'Le président, le Premier ministre et les ministres', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000004', 'Paris, Lyon et Marseille', FALSE, 3);

-- Q5 - Quel symbole de la République française est tricolore ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000005', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CSP', 'CONNAISSANCE',
        'Quel symbole de la République française est tricolore ?',
        'Le drapeau français est tricolore : bleu, blanc et rouge. Ces couleurs ont été adoptées pendant la Révolution française.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000005', 'Le drapeau', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000005', 'La Marseillaise', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000005', 'Le coq', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000005', 'Marianne', FALSE, 3);

-- Q6 - Quelles sont les couleurs du drapeau français ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000006', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CSP', 'CONNAISSANCE',
        'Quelles sont les couleurs du drapeau français ?',
        'Le drapeau français est composé de trois bandes verticales : bleu, blanc et rouge, de gauche à droite quand on le regarde.',
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
        'Le coq gaulois est un emblème traditionnel de la France, hérité de l''époque gallo-romaine. On le retrouve notamment sur les maillots des équipes sportives nationales.',
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
        'Marianne est l''allégorie (la représentation symbolique) de la République française. Son buste est présent dans toutes les mairies de France.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000008', 'L''allégorie de la République française',
        TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000008', 'La première reine de France', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000008', 'L''épouse du président actuel', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000008', 'Une sainte catholique', FALSE, 3);

-- Q9 - Quel est le nom de l'hymne national ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000009', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CSP', 'CONNAISSANCE',
        'Quel est le nom de l''hymne national ?',
        'La Marseillaise est l''hymne national de la France. Écrite par Rouget de Lisle en 1792 à Strasbourg, elle est devenue hymne national en 1795.',
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
        'La Marseillaise est l''hymne national de la France. Elle est chantée lors des cérémonies officielles et des événements sportifs internationaux.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000000a', 'L''hymne national français', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000000a', 'Un quartier de Marseille', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000000a', 'Une recette de cuisine provençale', FALSE,
        2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000000a', 'Une danse traditionnelle', FALSE, 3);

-- ---------------------------------------------------------------------------
-- BLOC 2 : DEVISE & VALEURS RÉPUBLICAINES
-- ---------------------------------------------------------------------------

-- Q11 - Quelle est la devise de la République française ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-00000000000b', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CSP', 'CONNAISSANCE',
        'Quelle est la devise de la République française ?',
        'La devise "Liberté, Égalité, Fraternité" est inscrite à l''article 2 de la Constitution. Elle résume les valeurs fondamentales de la République.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000000b', 'Liberté, Égalité, Fraternité', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000000b', 'Liberté, Fraternité, Solidarité', FALSE,
        1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000000b', 'Liberté, Justice, Paix', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000000b', 'Unité, Travail, Patrie', FALSE, 3);

-- Q12 - Où peut-on voir la devise de la République ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-00000000000c', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Où peut-on voir la devise de la République ?',
        'La devise "Liberté, Égalité, Fraternité" est inscrite sur le fronton de tous les bâtiments publics : mairies, écoles, préfectures, tribunaux.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000000c', 'Sur le fronton des bâtiments publics',
        TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000000c', 'Sur les pièces de 1 centime uniquement',
        FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000000c', 'Dans les églises catholiques', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000000c', 'Sur les plaques d''immatriculation',
        FALSE, 3);

-- Q13 - "Liberté, égalité, fraternité", c'est :
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-00000000000d', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CSP', 'CONNAISSANCE',
        '"Liberté, égalité, fraternité", c''est :',
        '"Liberté, Égalité, Fraternité" est la devise officielle de la République française depuis 1880, reprise dans les Constitutions de 1946 et 1958.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000000d', 'La devise de la République française',
        TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000000d', 'Le titre de l''hymne national', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000000d', 'Une chanson populaire', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000000d', 'Une loi récente', FALSE, 3);

-- Q14 - Que signifie la liberté ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-00000000000e', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Que signifie la liberté ?',
        'La liberté est le droit de faire ce que les lois permettent, dans le respect des libertés des autres. Article 4 de la Déclaration des droits de l''homme et du citoyen de 1789.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000000e',
        'Le droit de faire ce que la loi permet, dans le respect des autres', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000000e',
        'Le droit de faire absolument tout ce que l''on veut', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000000e', 'L''obligation d''obéir au gouvernement',
        FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000000e', 'Le droit réservé aux citoyens français',
        FALSE, 3);

-- Q15 - Qu'est-ce que l'égalité ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-00000000000f', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Qu''est-ce que l''égalité ?',
        'L''égalité signifie que tous les citoyens sont égaux devant la loi, sans distinction d''origine, de race, de religion, de sexe ou d''opinion.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000000f',
        'Tous les citoyens sont égaux devant la loi', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000000f', 'Tout le monde gagne le même salaire',
        FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000000f', 'Tout le monde a la même apparence', FALSE,
        2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000000f',
        'Tout le monde doit avoir les mêmes opinions', FALSE, 3);

-- Q16 - Le principe d'égalité signifie que :
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000010', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Le principe d''égalité signifie que :',
        'Le principe d''égalité garantit que la loi s''applique de la même manière à tous, sans discrimination liée à l''origine, au sexe, à la religion ou aux opinions.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000010',
        'La loi est la même pour tous, sans discrimination', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000010',
        'Tout le monde doit posséder les mêmes biens', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000010',
        'Les hommes et les femmes ont des rôles différents', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000010',
        'Les Français ont plus de droits que les étrangers', FALSE, 3);

-- Q17 - Que signifie le mot "fraternité" dans la devise française ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000011', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Que signifie le mot "fraternité" dans la devise française ?',
        'La fraternité représente la solidarité et l''entraide entre les citoyens. Elle implique le respect, la tolérance et le devoir d''aider les autres.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000011',
        'La solidarité et l''entraide entre les citoyens', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000011',
        'Le lien familial entre frères et sœurs uniquement', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000011', 'L''appartenance à la même religion',
        FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000011', 'Le service militaire obligatoire', FALSE,
        3);

-- Q18 - Quel est l'un des rôles des associations ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000012', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Quel est l''un des rôles des associations ?',
        'Les associations contribuent à la solidarité et à la vie sociale (aide aux personnes en difficulté, sport, culture, éducation...). Elles sont une expression de la fraternité.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000012',
        'Aider les personnes et contribuer à la vie sociale', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000012', 'Remplacer le gouvernement', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000012', 'Imposer des taxes aux citoyens', FALSE,
        2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000012',
        'Réserver leurs services aux Français uniquement', FALSE, 3);

-- ---------------------------------------------------------------------------
-- BLOC 3 : CONSTITUTION & RÉGIME POLITIQUE
-- ---------------------------------------------------------------------------

-- Q19 - De quand date la Constitution de la Ve République ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000013', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'De quand date la Constitution de la Ve République ?',
        'La Constitution de la Ve République a été adoptée le 4 octobre 1958, sous l''impulsion du général de Gaulle. Elle est toujours en vigueur aujourd''hui.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000013', '1958', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000013', '1789', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000013', '1945', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000013', '1981', FALSE, 3);

-- Q20 - Le régime de la France est :
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000014', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Le régime de la France est :',
        'La France est une république démocratique. L''article 1er de la Constitution précise : "La France est une République indivisible, laïque, démocratique et sociale."',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000014', 'Une république démocratique', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000014', 'Une monarchie constitutionnelle', FALSE,
        1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000014', 'Une dictature militaire', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000014', 'Une théocratie', FALSE, 3);

-- Q21 - "La France est une République indivisible, ..., démocratique et sociale". Completez :
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000015', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'NAT', 'CONNAISSANCE',
        '"La France est une République indivisible, ..., démocratique et sociale". Completez cette phrase extraite de l''article 1er de la Constitution :',
        'L''article 1er de la Constitution définit la France comme une République "indivisible, laïque, démocratique et sociale". La laïcité est l''un des quatre principes fondamentaux.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000015', 'laïque', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000015', 'religieuse', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000015', 'monarchique', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000015', 'fédérale', FALSE, 3);

-- ---------------------------------------------------------------------------
-- BLOC 4 : FÊTE NATIONALE
-- ---------------------------------------------------------------------------

-- Q22 - Quelle est la date de la fête nationale française ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000016', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CSP', 'CONNAISSANCE',
        'Quelle est la date de la fête nationale française ?',
        'La fête nationale française est le 14 juillet. Elle commémore la prise de la Bastille en 1789 et la Fête de la Fédération de 1790.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000016', 'Le 14 juillet', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000016', 'Le 1er mai', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000016', 'Le 11 novembre', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000016', 'Le 8 mai', FALSE, 3);

-- Q23 - Qu'est-ce qui est traditionnellement organisé sur les Champs-Élysées le 14 juillet ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000017', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CSP', 'CONNAISSANCE',
        'Qu''est-ce qui est traditionnellement organisé sur les Champs-Élysées le 14 juillet pour célébrer la fête nationale ?',
        'Un défilé militaire est organisé chaque année sur les Champs-Élysées à Paris, en présence du président de la République. C''est la plus ancienne et la plus grande parade militaire d''Europe.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000017', 'Un défilé militaire', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000017', 'Un marché de Noël', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000017', 'Une course cycliste', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000017', 'Un concert de musique classique', FALSE,
        3);

-- ---------------------------------------------------------------------------
-- BLOC 5 : LANGUE FRANÇAISE
-- ---------------------------------------------------------------------------

-- Q24 - Quelle est la langue officielle de la République française ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000018', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CSP', 'CONNAISSANCE',
        'Quelle est la langue officielle de la République française ?',
        'Le français est la langue officielle de la République, inscrit dans l''article 2 de la Constitution depuis 1992.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000018', 'Le français', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000018', 'L''anglais', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000018', 'Le français et l''anglais', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000018', 'Aucune langue officielle n''est définie',
        FALSE, 3);

-- Q25 - Quelle est la place de la langue française dans la République ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000019', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Quelle est la place de la langue française dans la République ?',
        'Le français est la langue officielle et de l''administration. Sa connaissance est un élément essentiel d''intégration et est exigée pour la naturalisation.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000019',
        'C''est la langue officielle et le lien commun entre les citoyens', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000019',
        'C''est une langue parmi d''autres, sans statut particulier', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000019', 'C''est une langue réservée à l''écrit',
        FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000019',
        'Elle n''est pas obligatoire pour les services publics', FALSE, 3);

-- ---------------------------------------------------------------------------
-- BLOC 6 : LIBERTÉ D'EXPRESSION & DROITS
-- ---------------------------------------------------------------------------

-- Q26 - Quelle liberté permet à chacun d'exprimer ses idées ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-00000000001a', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Quelle liberté permet à chacun d''exprimer ses idées ?',
        'La liberté d''expression permet à chacun d''exprimer ses opinions, par la parole, l''écrit, l''image. Elle est garantie par la Déclaration des droits de l''homme et du citoyen de 1789.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000001a', 'La liberté d''expression', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000001a', 'La liberté de circulation', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000001a', 'La liberté du commerce', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000001a', 'La liberté de propriété', FALSE, 3);

-- Q27 - Quelle proposition est correcte ? La liberté d'expression :
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-00000000001b', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'NAT', 'CONNAISSANCE',
        'Quelle proposition est correcte ? La liberté d''expression :',
        'La liberté d''expression n''est pas absolue : elle est encadrée par la loi. L''injure, la diffamation, l''incitation à la haine ou à la violence sont interdites.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000001b',
        'À des limites fixées par la loi (injure, diffamation, incitation à la haine)', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000001b', 'Est totale et sans aucune limite', FALSE,
        1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000001b', 'N''existe pas en France', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000001b', 'Est réservée aux journalistes', FALSE, 3);

-- Q28 - A-t-on le droit d'insulter publiquement quelqu'un parce qu'il est différent ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-00000000001c', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'MISE_SITUATION',
        'A-t-on le droit d''insulter publiquement quelqu''un parce qu''il est différent (handicap, apparence physique, sexe...) ?',
        'Non. Les injures et discriminations sont interdites par la loi et punies pénalement. Le respect de la dignité de chacun est un principe fondamental.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000001c', 'Non, c''est interdit et puni par la loi',
        TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000001c', 'Oui, c''est la liberté d''expression',
        FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000001c', 'Oui, mais seulement sur Internet', FALSE,
        2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000001c', 'Oui, si c''est dit avec humour', FALSE,
        3);

-- Q29 - Certains métiers peuvent-ils être réservés aux hommes ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-00000000001d', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'MISE_SITUATION',
        'Certains métiers peuvent-ils être réservés aux hommes ?',
        'Non. L''égalité entre les hommes et les femmes est un principe constitutionnel. Tous les métiers sont accessibles aux deux sexes sans distinction.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000001d',
        'Non, l''égalité hommes-femmes interdit toute discrimination', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000001d', 'Oui, certains métiers physiques', FALSE,
        1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000001d', 'Oui, les métiers militaires', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000001d', 'Oui, si l''employeur le décide', FALSE,
        3);

-- ---------------------------------------------------------------------------
-- BLOC 7 : LAÏCITÉ (NIVEAU CR/NAT)
-- ---------------------------------------------------------------------------

-- Q30 - Qu'est-ce que la laïcité ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-00000000001e', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Qu''est-ce que la laïcité ?',
        'La laïcité est la séparation entre l''État et les religions. L''État est neutre, ne reconnaît aucun culte et garantit la liberté de conscience de chacun.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000001e',
        'La séparation entre l''État et les religions', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000001e', 'L''interdiction de toutes les religions',
        FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000001e', 'L''obligation de pratiquer une religion',
        FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000001e', 'Le respect d''une religion d''État',
        FALSE, 3);

-- Q31 - En quelle année la loi de séparation des Églises et de l'État a-t-elle été votée ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-00000000001f', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'NAT', 'CONNAISSANCE',
        'En quelle année la loi de séparation des Églises et de l''État a-t-elle été votée ?',
        'La loi de séparation des Églises et de l''État a été votée le 9 décembre 1905. Elle a posé les bases de la laïcité française.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000001f', '1905', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000001f', '1789', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000001f', '1958', FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-00000000001f', '1881', FALSE, 3);

-- Q32 - Que permet le principe de laïcité ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000020', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Que permet le principe de laïcité ?',
        'La laïcité garantit la liberté de conscience : chacun peut croire, ne pas croire ou changer de religion, dans le respect des autres et de la loi.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000020', 'La liberté de croire ou de ne pas croire',
        TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000020', 'D''interdire toutes les religions', FALSE,
        1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000020', 'De favoriser une religion en particulier',
        FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000020',
        'D''obliger les citoyens à suivre une religion', FALSE, 3);

-- Q33 - Quel droit est garanti par la laïcité ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000021', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Quel droit est garanti par la laïcité ?',
        'La laïcité garantit la liberté de conscience et de religion : chacun peut pratiquer la religion de son choix ou n''en pratiquer aucune.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000021', 'La liberté de conscience et de religion',
        TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000021', 'Le droit à la propriété privée', FALSE,
        1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000021', 'Le droit de vote des étrangers', FALSE,
        2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000021', 'Le droit à la sécurité sociale', FALSE,
        3);

-- Q34 - Pourquoi le principe de laïcité doit-il être respecté à l'école ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000022', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'NAT', 'CONNAISSANCE',
        'Pourquoi le principe de laïcité doit-il être respecté à l''école ?',
        'L''école publique est laïque pour garantir l''égalité de tous les élèves, leur permettre de se former librement et éviter toute pression religieuse.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000022',
        'Pour garantir l''égalité entre les élèves et la liberté de conscience', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000022', 'Parce que les religions sont interdites',
        FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000022', 'Pour favoriser la religion catholique',
        FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000022',
        'Parce que les enseignants choisissent la religion des élèves', FALSE, 3);

-- Q35 - Un enfant peut-il refuser d'aller à l'école pour une raison religieuse ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000023', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'MISE_SITUATION',
        'Un enfant peut-il refuser d''aller à l''école pour une raison religieuse ?',
        'Non. L''instruction est obligatoire pour tous les enfants de 3 à 16 ans. Aucun motif religieux ne peut justifier l''absence ou refuser certains enseignements.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000023',
        'Non, l''instruction est obligatoire de 3 à 16 ans', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000023', 'Oui, la religion passe avant la loi',
        FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000023', 'Oui, si les parents le décident', FALSE,
        2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000023', 'Oui, certains jours de l''année', FALSE,
        3);

-- Q36 - Une personne a-t-elle le droit de ne pas croire en une religion ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000024', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'MISE_SITUATION',
        'Une personne a-t-elle le droit de ne pas croire en une religion ?',
        'Oui. La liberté de conscience, garantie par la laïcité, comprend le droit de ne pas croire (athée, agnostique). Personne ne peut être forcé à adhérer à une religion.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000024',
        'Oui, la liberté de conscience est garantie', TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000024',
        'Non, il faut obligatoirement avoir une religion', FALSE, 1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000024', 'Oui, mais seulement les Français', FALSE,
        2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000024', 'Non, c''est interdit par la Constitution',
        FALSE, 3);

-- Q37 - Une personne peut-elle changer librement de religion ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f0000001-0000-0000-0000-000000000025', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'MISE_SITUATION',
        'Une personne peut-elle changer librement de religion ?',
        'Oui. La liberté de conscience inclut le droit de choisir, changer ou abandonner une religion sans aucune contrainte. Nul ne peut être forcé de rester dans une religion.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000025', 'Oui, c''est une liberté fondamentale',
        TRUE, 0),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000025', 'Non, c''est strictement interdit', FALSE,
        1),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000025', 'Oui, mais avec autorisation de l''État',
        FALSE, 2),
       (gen_random_uuid(), 'f0000001-0000-0000-0000-000000000025', 'Oui, mais seulement une fois dans sa vie',
        FALSE, 3);