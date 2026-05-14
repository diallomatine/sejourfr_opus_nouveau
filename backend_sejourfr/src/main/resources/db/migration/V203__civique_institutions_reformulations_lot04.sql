-- ============================================================================
-- Flyway : reformulations questions officielles - THEME 2 INSTITUTIONS
-- Lot 4/4 : R37 a R46 (Parlement, regime, Union europeenne)
-- is_active = FALSE
-- ============================================================================

-- R37 (de f2000000-...025 / CR / CONNAISSANCE) - Role Parlement
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000025', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quelle est la mission principale du Parlement francais ?',
 'Le Parlement vote les lois et le budget de l''Etat, et controle l''action du gouvernement. Il est compose de l''Assemblee nationale et du Senat.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000025', 'Voter les lois et controler le gouvernement', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000025', 'Diriger l''armee', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000025', 'Nommer le president', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000025', 'Reviser la Constitution sans vote', FALSE, 3);

-- R38 (de f2000000-...026 / CR / CONNAISSANCE) - Regime politique actuel
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000026', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Comment qualifier le regime politique de la France aujourd''hui ?',
 'La France est une republique parlementaire et semi-presidentielle. Le president partage le pouvoir executif avec un gouvernement responsable devant l''Assemblee nationale.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000026', 'Une republique democratique semi-presidentielle', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000026', 'Une monarchie constitutionnelle', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000026', 'Un Etat federal', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000026', 'Une dictature militaire', FALSE, 3);

-- R39 (de f2000000-...027 / NAT / CONNAISSANCE) - Nombre Etats UE 2025
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000027', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Au 1er janvier 2025, combien d''Etats membres compte l''Union europeenne ?',
 'Au 1er janvier 2025, l''Union europeenne compte 27 Etats membres. Le Royaume-Uni en est sorti en 2020 (Brexit).', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000027', '27', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000027', '15', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000027', '50', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000027', '12', FALSE, 3);

-- R40 (de f2000000-...028 / CR / CONNAISSANCE) - Etat non membre UE
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000028', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Parmi ces pays, lequel ne fait pas partie de l''Union europeenne ?',
 'La Suisse n''est pas membre de l''Union europeenne, bien qu''elle entretienne des accords bilateraux etroits avec elle. Le Royaume-Uni en est sorti en 2020.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000028', 'La Suisse', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000028', 'L''Espagne', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000028', 'L''Italie', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000028', 'La Belgique', FALSE, 3);

-- R41 (de f2000000-...029 / NAT / CONNAISSANCE) - Condition vote europeen
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000029', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Quelle condition est exigee pour voter aux elections europeennes en France ?',
 'Pour voter aux elections europeennes en France, il faut etre citoyen de l''Union europeenne (Francais ou ressortissant d''un autre pays de l''UE), majeur, inscrit sur les listes electorales et jouir de ses droits civiques.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000029', 'Etre citoyen de l''Union europeenne, majeur, inscrit', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000029', 'Etre fonctionnaire europeen', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000029', 'Vivre depuis 20 ans dans le pays', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000029', 'Parler couramment l''anglais', FALSE, 3);

-- R42 (de f2000000-...02a / CR / CONNAISSANCE) - Frequence elections europeennes
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-00000000002a', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Tous les combien d''annees les elections europeennes ont-elles lieu ?',
 'Les elections europeennes ont lieu tous les 5 ans. Elles permettent d''elire les deputes du Parlement europeen.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000002a', 'Tous les 5 ans', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000002a', 'Tous les ans', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000002a', 'Tous les 10 ans', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000002a', 'Tous les 2 ans', FALSE, 3);

-- R43 (de f2000000-...02b / CR / CONNAISSANCE) - Pays fondateur UE
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-00000000002b', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Lequel de ces pays est l''un des fondateurs de la Communaute economique europeenne (futur UE) ?',
 'Les six pays fondateurs de la CEE en 1957 (Traite de Rome) sont : la France, l''Allemagne (RFA a l''epoque), l''Italie, la Belgique, les Pays-Bas et le Luxembourg.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000002b', 'La France', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000002b', 'Le Royaume-Uni', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000002b', 'L''Espagne', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000002b', 'La Pologne', FALSE, 3);

-- R44 (de f2000000-...02c / CSP / CONNAISSANCE) - Monnaie en France
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-00000000002c', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Quelle est la monnaie en circulation en France ?',
 'La France utilise l''euro depuis le 1er janvier 2002 (date de mise en circulation des pieces et billets). Avant, la monnaie etait le franc.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000002c', 'L''euro', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000002c', 'Le franc', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000002c', 'Le dollar', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000002c', 'La livre sterling', FALSE, 3);

-- R45 (de f2000000-...02d / CR / CONNAISSANCE) - Qui elit deputes europeens
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-00000000002d', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Comment sont elus les deputes au Parlement europeen ?',
 'Les deputes europeens sont elus directement par les citoyens europeens, au suffrage universel direct, dans chaque Etat membre.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000002d', 'Directement par les citoyens de l''Union europeenne', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000002d', 'Par les gouvernements nationaux uniquement', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000002d', 'Par la Commission europeenne', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000002d', 'Par tirage au sort', FALSE, 3);

-- R46 (de f2000000-...02e / NAT / CONNAISSANCE) - Date journee Europe
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-00000000002e', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'A quelle date est commemoree chaque annee la Journee de l''Europe ?',
 'La Journee de l''Europe est celebree le 9 mai, date anniversaire de la declaration Schuman (1950), qui a pose les fondations de la construction europeenne.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000002e', 'Le 9 mai', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000002e', 'Le 14 juillet', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000002e', 'Le 11 novembre', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000002e', 'Le 1er mai', FALSE, 3);

-- ============================================================================
-- Fin reformulations THEME 2 : 46 questions inserees
-- ============================================================================
