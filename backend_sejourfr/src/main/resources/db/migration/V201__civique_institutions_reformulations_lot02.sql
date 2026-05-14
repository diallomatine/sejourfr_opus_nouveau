-- ============================================================================
-- Flyway : reformulations questions officielles - THEME 2 INSTITUTIONS
-- Lot 2/4 : R13 a R24 (mandats, votes, suffrage)
-- is_active = FALSE
-- ============================================================================

-- R13 (de f2000000-...00d / NAT / CONNAISSANCE) - Election senateurs
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-00000000000d', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Comment sont elus les senateurs francais ?',
 'Les senateurs sont elus au suffrage universel indirect par un college de grands electeurs (deputes, conseillers regionaux, departementaux, municipaux). Le Senat est renouvele par moitie tous les trois ans.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000000d', 'Au suffrage universel indirect, par des grands electeurs', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000000d', 'Au suffrage universel direct des citoyens', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000000d', 'Par tirage au sort', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000000d', 'Par nomination du president', FALSE, 3);

-- R14 (de f2000000-...00e / CSP / CONNAISSANCE) - Elections municipales
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-00000000000e', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Qui les citoyens elisent-ils lors des elections municipales ?',
 'Les elections municipales permettent d''elire les conseillers municipaux qui, eux, elisent ensuite le maire et ses adjoints. Elles ont lieu tous les six ans.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000000e', 'Les conseillers municipaux', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000000e', 'Le president de la Republique', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000000e', 'Les senateurs', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000000e', 'Les juges du tribunal', FALSE, 3);

-- R15 (de f2000000-...00f / CSP / CONNAISSANCE) - Elections presidentielles
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-00000000000f', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Qui est elu lors d''une election presidentielle francaise ?',
 'L''election presidentielle permet d''elire le president de la Republique au suffrage universel direct, pour un mandat de cinq ans.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000000f', 'Le president de la Republique', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000000f', 'Le Premier ministre', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000000f', 'Les ministres', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000000f', 'Les prefets', FALSE, 3);

-- R16 (de f2000000-...010 / CSP / CONNAISSANCE) - Age vote
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000010', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'A partir de quel age peut-on voter en France ?',
 'En France, on peut voter a partir de 18 ans, sous reserve d''etre citoyen francais et inscrit sur les listes electorales.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000010', '18 ans', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000010', '16 ans', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000010', '21 ans', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000010', '25 ans', FALSE, 3);

-- R17 (de f2000000-...011 / CR / CONNAISSANCE) - Duree mandat president
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000011', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quelle est la duree d''un mandat presidentiel en France ?',
 'Le mandat presidentiel est de 5 ans (quinquennat) depuis la reforme constitutionnelle de 2000. Il etait auparavant de 7 ans (septennat).', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000011', '5 ans', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000011', '4 ans', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000011', '7 ans', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000011', '10 ans', FALSE, 3);

-- R18 (de f2000000-...012 / CR / CONNAISSANCE) - Duree mandat depute
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000012', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Combien de temps dure le mandat d''un depute francais ?',
 'Les deputes sont elus pour 5 ans a l''Assemblee nationale, sauf en cas de dissolution decidee par le president de la Republique.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000012', '5 ans', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000012', '3 ans', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000012', '6 ans', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000012', '10 ans', FALSE, 3);

-- R19 (de f2000000-...013 / CR / CONNAISSANCE) - Duree mandat senateur
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000013', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Pour quelle duree un senateur est-il elu ?',
 'Les senateurs sont elus pour 6 ans. Le Senat est renouvelable par moitie tous les 3 ans.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000013', '6 ans', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000013', '5 ans', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000013', '4 ans', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000013', '9 ans', FALSE, 3);

-- R20 (de f2000000-...014 / CR / CONNAISSANCE) - Qui detient l'executif
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000014', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Qui detient le pouvoir executif en France ?',
 'Le pouvoir executif est detenu par le president de la Republique et le gouvernement (Premier ministre et ministres).', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000014', 'Le president et le gouvernement', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000014', 'Le Parlement uniquement', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000014', 'Les juges', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000014', 'Le Conseil constitutionnel', FALSE, 3);

-- R21 (de f2000000-...015 / CR / CONNAISSANCE) - Condition pour voter
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000015', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quelle condition est requise pour pouvoir voter aux elections nationales en France ?',
 'Pour voter aux elections nationales (presidentielles, legislatives), il faut etre de nationalite francaise, majeur (18 ans), jouir de ses droits civiques et etre inscrit sur les listes electorales.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000015', 'Etre francais, majeur et inscrit sur les listes', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000015', 'Avoir le bac', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000015', 'Posseder un logement', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000015', 'Avoir fait son service militaire', FALSE, 3);

-- R22 (de f2000000-...016 / CR / CONNAISSANCE) - Qui peut voter France
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000016', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'En general, qui a le droit de voter aux elections nationales francaises ?',
 'Seuls les citoyens francais majeurs jouissant de leurs droits civiques peuvent voter aux elections nationales. Les ressortissants europeens peuvent voter aux municipales et europeennes.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000016', 'Les citoyens francais majeurs avec droits civiques', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000016', 'Tous les habitants, francais ou non', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000016', 'Uniquement les contribuables', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000016', 'Uniquement les hommes', FALSE, 3);

-- R23 (de f2000000-...017 / NAT / CONNAISSANCE) - Suffrage universel
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000017', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Que designe l''expression "suffrage universel" ?',
 'Le suffrage universel signifie que le droit de vote est ouvert a tous les citoyens majeurs, sans condition de richesse, de sexe ou de niveau d''education.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000017', 'Le droit de vote ouvert a tous les citoyens majeurs', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000017', 'Le vote reserve aux proprietaires', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000017', 'Le vote reserve aux hommes', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000017', 'Le vote des etrangers a toutes les elections', FALSE, 3);

-- R24 (de f2000000-...018 / CR / CONNAISSANCE) - Partis politiques
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000018', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quelle proposition decrit correctement le statut des partis politiques en France ?',
 'Les partis politiques sont libres : plusieurs partis peuvent exister, defendre des idees differentes et participer aux elections. C''est le principe du pluralisme politique.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000018', 'Plusieurs partis peuvent exister et concourir librement aux elections', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000018', 'Un seul parti unique est autorise', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000018', 'Les partis sont interdits par la Constitution', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000018', 'Seuls deux partis sont autorises', FALSE, 3);
