-- ============================================================================
-- Flyway : reformulations questions officielles - THÈME 2 INSTITUTIONS
-- Lot 2/4 : R13 à R24 (mandats, votes, suffrage)
-- is_active = FALSE
-- ============================================================================

-- R13 (de f2000000-...00d / NAT / CONNAISSANCE) - Élection sénateurs
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-00000000000d', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Comment sont élus les sénateurs français ?',
 'Les sénateurs sont élus au suffrage universel indirect par un collège de grands électeurs (députés, conseillers régionaux, départementaux, municipaux). Le Sénat est renouvelé par moitie tous les trois ans.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000000d', 'Au suffrage universel indirect, par des grands électeurs', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000000d', 'Au suffrage universel direct des citoyens', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000000d', 'Par tirage au sort', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000000d', 'Par nomination du président', FALSE, 3);

-- R14 (de f2000000-...00e / CSP / CONNAISSANCE) - Élections municipales
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-00000000000e', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Qui les citoyens elisent-ils lors des élections municipales ?',
 'Les élections municipales permettent d''élire les conseillers municipaux qui, eux, elisent ensuite le maire et ses adjoints. Elles ont lieu tous les six ans.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000000e', 'Les conseillers municipaux', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000000e', 'Le président de la République', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000000e', 'Les sénateurs', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000000e', 'Les juges du tribunal', FALSE, 3);

-- R15 (de f2000000-...00f / CSP / CONNAISSANCE) - Élections présidentielles
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-00000000000f', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Qui est élu lors d''une élection présidentielle française ?',
 'L''élection présidentielle permet d''élire le président de la République au suffrage universel direct, pour un mandat de cinq ans.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000000f', 'Le président de la République', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000000f', 'Le Premier ministre', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000000f', 'Les ministres', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000000f', 'Les préfets', FALSE, 3);

-- R16 (de f2000000-...010 / CSP / CONNAISSANCE) - Âge vote
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000010', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'À partir de quel âge peut-on voter en France ?',
 'En France, on peut voter à partir de 18 ans, sous réserve d''être citoyen français et inscrit sur les listes électorales.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000010', '18 ans', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000010', '16 ans', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000010', '21 ans', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000010', '25 ans', FALSE, 3);

-- R17 (de f2000000-...011 / CR / CONNAISSANCE) - Durée mandat président
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000011', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quelle est la durée d''un mandat présidentiel en France ?',
 'Le mandat présidentiel est de 5 ans (quinquennat) depuis la réforme constitutionnelle de 2000. Il était auparavant de 7 ans (septennat).', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000011', '5 ans', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000011', '4 ans', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000011', '7 ans', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000011', '10 ans', FALSE, 3);

-- R18 (de f2000000-...012 / CR / CONNAISSANCE) - Durée mandat député
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000012', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Combien de temps dure le mandat d''un député français ?',
 'Les députés sont élus pour 5 ans à l''Assemblée nationale, sauf en cas de dissolution décidée par le président de la République.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000012', '5 ans', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000012', '3 ans', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000012', '6 ans', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000012', '10 ans', FALSE, 3);

-- R19 (de f2000000-...013 / CR / CONNAISSANCE) - Durée mandat sénateur
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000013', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Pour quelle durée un sénateur est-il élu ?',
 'Les sénateurs sont élus pour 6 ans. Le Sénat est renouvelable par moitie tous les 3 ans.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000013', '6 ans', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000013', '5 ans', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000013', '4 ans', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000013', '9 ans', FALSE, 3);

-- R20 (de f2000000-...014 / CR / CONNAISSANCE) - Qui detient l'exécutif
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000014', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Qui detient le pouvoir exécutif en France ?',
 'Le pouvoir exécutif est détenu par le président de la République et le gouvernement (Premier ministre et ministres).', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000014', 'Le président et le gouvernement', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000014', 'Le Parlement uniquement', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000014', 'Les juges', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000014', 'Le Conseil constitutionnel', FALSE, 3);

-- R21 (de f2000000-...015 / CR / CONNAISSANCE) - Condition pour voter
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000015', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quelle condition est requise pour pouvoir voter aux élections nationales en France ?',
 'Pour voter aux élections nationales (présidentielles, législatives), il faut être de nationalité française, majeur (18 ans), jouir de ses droits civiques et être inscrit sur les listes électorales.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000015', 'Être français, majeur et inscrit sur les listes', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000015', 'Avoir le bac', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000015', 'Posseder un logement', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000015', 'Avoir fait son service militaire', FALSE, 3);

-- R22 (de f2000000-...016 / CR / CONNAISSANCE) - Qui peut voter France
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000016', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'En général, qui à le droit de voter aux élections nationales françaises ?',
 'Seuls les citoyens français majeurs jouissant de leurs droits civiques peuvent voter aux élections nationales. Les ressortissants européens peuvent voter aux municipales et européennes.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000016', 'Les citoyens français majeurs avec droits civiques', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000016', 'Tous les habitants, français ou non', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000016', 'Uniquement les contribuables', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000016', 'Uniquement les hommes', FALSE, 3);

-- R23 (de f2000000-...017 / NAT / CONNAISSANCE) - Suffrage universel
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000017', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Que designe l''expression "suffrage universel" ?',
 'Le suffrage universel signifie que le droit de vote est ouvert à tous les citoyens majeurs, sans condition de richesse, de sexe ou de niveau d''éducation.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000017', 'Le droit de vote ouvert à tous les citoyens majeurs', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000017', 'Le vote réserve aux propriétaires', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000017', 'Le vote réserve aux hommes', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000017', 'Le vote des étrangers à toutes les élections', FALSE, 3);

-- R24 (de f2000000-...018 / CR / CONNAISSANCE) - Partis politiques
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000018', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quelle proposition décrit correctement le statut des partis politiques en France ?',
 'Les partis politiques sont libres : plusieurs partis peuvent exister, défendre des idées différentes et participer aux élections. C''est le principe du pluralisme politique.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000018', 'Plusieurs partis peuvent exister et concourir librement aux élections', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000018', 'Un seul parti unique est autorisé', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000018', 'Les partis sont interdités par la Constitution', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000018', 'Seuls deux partis sont autorisés', FALSE, 3);
