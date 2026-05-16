-- ============================================================================
-- Flyway : reformulations questions officielles - THÈME 2 INSTITUTIONS
-- Lot 4/4 : R37 à R46 (Parlement, régime, Union européenne)
-- is_active = FALSE
-- ============================================================================

-- R37 (de f2000000-...025 / CR / CONNAISSANCE) - Rôle Parlement
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000025', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quelle est la mission principale du Parlement français ?',
 'Le Parlement vote les lois et le budget de l''État, et contrôle l''action du gouvernement. Il est composé de l''Assemblée nationale et du Sénat.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000025', 'Voter les lois et contrôler le gouvernement', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000025', 'Diriger l''armée', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000025', 'Nommer le président', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000025', 'Réviser la Constitution sans vote', FALSE, 3);

-- R38 (de f2000000-...026 / CR / CONNAISSANCE) - Régime politique actuel
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000026', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Comment qualifier le régime politique de la France aujourd''hui ?',
 'La France est une république parlementaire et semi-présidentielle. Le président partage le pouvoir exécutif avec un gouvernement responsable devant l''Assemblée nationale.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000026', 'Une république démocratique semi-présidentielle', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000026', 'Une monarchie constitutionnelle', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000026', 'Un État fédéral', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000026', 'Une dictature militaire', FALSE, 3);

-- R39 (de f2000000-...027 / NAT / CONNAISSANCE) - Nombre États UE 2025
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000027', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Au 1er janvier 2025, combien d''États membres compte l''Union européenne ?',
 'Au 1er janvier 2025, l''Union européenne compte 27 États membres. Le Royaume-Uni en est sorti en 2020 (Brexit).', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000027', '27', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000027', '15', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000027', '50', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000027', '12', FALSE, 3);

-- R40 (de f2000000-...028 / CR / CONNAISSANCE) - État non membre UE
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000028', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Parmi ces pays, lequel ne fait pas partie de l''Union européenne ?',
 'La Suisse n''est pas membre de l''Union européenne, bien qu''elle entretienne des accords bilatéraux étroits avec elle. Le Royaume-Uni en est sorti en 2020.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000028', 'La Suisse', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000028', 'L''Espagne', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000028', 'L''Italie', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000028', 'La Belgique', FALSE, 3);

-- R41 (de f2000000-...029 / NAT / CONNAISSANCE) - Condition vote européen
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000029', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Quelle condition est exigée pour voter aux élections européennes en France ?',
 'Pour voter aux élections européennes en France, il faut être citoyen de l''Union européenne (Français ou ressortissant d''un autre pays de l''UE), majeur, inscrit sur les listes électorales et jouir de ses droits civiques.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000029', 'Être citoyen de l''Union européenne, majeur, inscrit', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000029', 'Être fonctionnaire européen', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000029', 'Vivre depuis 20 ans dans le pays', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000029', 'Parler couramment l''anglais', FALSE, 3);

-- R42 (de f2000000-...02a / CR / CONNAISSANCE) - Fréquence élections européennes
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-00000000002a', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Tous les combien d''années les élections européennes ont-elles lieu ?',
 'Les élections européennes ont lieu tous les 5 ans. Elles permettent d''élire les députés du Parlement européen.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000002a', 'Tous les 5 ans', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000002a', 'Tous les ans', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000002a', 'Tous les 10 ans', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000002a', 'Tous les 2 ans', FALSE, 3);

-- R43 (de f2000000-...02b / CR / CONNAISSANCE) - Pays fondateur UE
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-00000000002b', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Lequel de ces pays est l''un des fondateurs de la Communauté économique européenne (futur UE) ?',
 'Les six pays fondateurs de la CEE en 1957 (Traité de Rome) sont : la France, l''Allemagne (RFA à l''époque), l''Italie, la Belgique, les Pays-Bas et le Luxembourg.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000002b', 'La France', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000002b', 'Le Royaume-Uni', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000002b', 'L''Espagne', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000002b', 'La Pologne', FALSE, 3);

-- R44 (de f2000000-...02c / CSP / CONNAISSANCE) - Monnaie en France
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-00000000002c', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Quelle est la monnaie en circulation en France ?',
 'La France utilise l''euro depuis le 1er janvier 2002 (date de mise en circulation des pièces et billets). Avant, la monnaie était le franc.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000002c', 'L''euro', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000002c', 'Le franc', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000002c', 'Le dollar', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000002c', 'La livre sterling', FALSE, 3);

-- R45 (de f2000000-...02d / CR / CONNAISSANCE) - Qui élit députés européens
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-00000000002d', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Comment sont élus les députés au Parlement européen ?',
 'Les députés européens sont élus directement par les citoyens européens, au suffrage universel direct, dans chaque État membre.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000002d', 'Directement par les citoyens de l''Union européenne', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000002d', 'Par les gouvernements nationaux uniquement', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000002d', 'Par la Commission européenne', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000002d', 'Par tirage au sort', FALSE, 3);

-- R46 (de f2000000-...02e / NAT / CONNAISSANCE) - Date journée Europe
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-00000000002e', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'À quelle date est commémorée chaque année la Journée de l''Europe ?',
 'La Journée de l''Europe est célébrée le 9 mai, date anniversaire de la déclaration Schuman (1950), qui a posé les fondations de la construction européenne.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000002e', 'Le 9 mai', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000002e', 'Le 14 juillet', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000002e', 'Le 11 novembre', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000002e', 'Le 1er mai', FALSE, 3);

-- ============================================================================
-- Fin reformulations THÈME 2 : 46 questions insérées
-- ============================================================================
