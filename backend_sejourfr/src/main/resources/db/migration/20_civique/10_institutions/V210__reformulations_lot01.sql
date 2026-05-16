-- ============================================================================
-- Flyway : reformulations questions officielles - THÈME 2 INSTITUTIONS
-- Lot 1/4 : R01 à R12 (Premier ministre, Parlement, pouvoirs, lois, juges)
-- IDs : f2000001-... (préservé la difficulty + type des officielles f2000000-...)
-- is_active = FALSE
-- ============================================================================

-- R01 (de f2000000-...001 / CSP / CONNAISSANCE) - Qui nomme le PM
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000001', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Quelle autorité désigne le Premier ministre en France ?',
 'Le Premier ministre est nommé par le président de la République, conformément à l''article 8 de la Constitution. Il dirige l''action du gouvernement.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000001', 'Le président de la République', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000001', 'Le président du Sénat', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000001', 'Le maire de Paris', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000001', 'Le peuple par référendum', FALSE, 3);

-- R02 (de f2000000-...002 / CSP / CONNAISSANCE) - Composition Parlement
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000002', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Quelles sont les deux assemblées qui forment le Parlement français ?',
 'Le Parlement français est bicaméral : il est composé de l''Assemblée nationale (députés) et du Sénat (sénateurs).', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000002', 'L''Assemblée nationale et le Sénat', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000002', 'Le gouvernement et le Conseil d''État', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000002', 'Le Conseil constitutionnel et le Sénat', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000002', 'L''Élysée et Matignon', FALSE, 3);

-- R03 (de f2000000-...003 / CR / CONNAISSANCE) - Pouvoir exécutif rôle
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000003', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quelle est la mission principale du pouvoir exécutif ?',
 'Le pouvoir exécutif est chargé de faire appliquer les lois et de conduire la politique de la nation. Il est exercé par le président de la République et le gouvernement.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000003', 'Faire appliquer les lois et diriger la politique de l''État', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000003', 'Voter les lois', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000003', 'Juger les délinquants', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000003', 'Réviser la Constitution', FALSE, 3);

-- R04 (de f2000000-...004 / CSP / CONNAISSANCE) - Dirigeants élus démocratie
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000004', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Dans quel type de régime les dirigeants sont-ils choisis par les citoyens ?',
 'Dans une démocratie, les dirigeants sont élus par les citoyens. C''est ce qui distingue ce régime des monarchies absolues, des dictatures ou des théocraties.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000004', 'Dans une démocratie', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000004', 'Dans une dictature', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000004', 'Dans une théocratie', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000004', 'Dans une monarchie absolue', FALSE, 3);

-- R05 (de f2000000-...005 / CSP / MISE_SITUATION) - Respect de la loi
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000005', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'MISE_SITUATION',
 'Peut-on choisir de ne pas appliquer une loi parce qu''on est en désaccord avec elle ?',
 'Non. La loi s''impose à tous les citoyens. Le désaccord se manifeste par les voies légales : vote, débat, recours juridique. Ne pas respecter la loi expose à des sanctions.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000005', 'Non, la loi s''applique à tous, même en cas de désaccord', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000005', 'Oui, c''est une liberté personnelle', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000005', 'Oui, en cas de croyance religieuse', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000005', 'Oui, le week-end', FALSE, 3);

-- R06 (de f2000000-...006 / CSP / CONNAISSANCE) - Qui doit respecter la loi
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000006', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'En France, qui est tenu de respecter la loi ?',
 'Tout le monde, sans exception : citoyens, résidents, dirigeants politiques, agents publics. La loi s''applique de la même manière à tous.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000006', 'Toute personne présente sur le territoire', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000006', 'Uniquement les Français', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000006', 'Uniquement les adultes', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000006', 'Uniquement les personnes condamnées', FALSE, 3);

-- R07 (de f2000000-...007 / CR / CONNAISSANCE) - Rôle autorité judiciaire
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000007', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Que fait l''autorité judiciaire en France ?',
 'L''autorité judiciaire applique la loi, juge les litiges et protège les libertés individuelles. Elle est indépendante des autres pouvoirs.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000007', 'Elle applique la loi et protège les libertés', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000007', 'Elle vote les lois', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000007', 'Elle nomme les ministres', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000007', 'Elle gère les écoles publiques', FALSE, 3);

-- R08 (de f2000000-...008 / CR / CONNAISSANCE) - Pouvoir du juge
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000008', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quel type de pouvoir est exercé par un juge ?',
 'Le juge exerce le pouvoir judiciaire : il dit le droit, tranche les litiges et applique les sanctions prévues par la loi.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000008', 'Le pouvoir judiciaire', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000008', 'Le pouvoir exécutif', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000008', 'Le pouvoir législatif', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000008', 'Le pouvoir constitutionnel', FALSE, 3);

-- R09 (de f2000000-...009 / CR / CONNAISSANCE) - Qui exerce le judiciaire
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000009', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'À qui revient l''exercice de l''autorité judiciaire en France ?',
 'L''autorité judiciaire est exercée par les magistrats (juges et procureurs), au sein des tribunaux et des cours.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000009', 'Les magistrats (juges et procureurs)', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000009', 'Les députés', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000009', 'Les préfets', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000009', 'Le président de la République seul', FALSE, 3);

-- R10 (de f2000000-...00a / NAT / CONNAISSANCE) - Ministre ne respecte pas loi
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-00000000000a', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Un ministre commet une infraction. Échappe-t-il à la justice ?',
 'Non. Un ministre, comme tout citoyen, doit répondre de ses actes devant la justice. Pour les actes commis dans l''exercice de ses fonctions, il est jugé par la Cour de justice de la République.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000000a', 'Non, il peut être jugé comme tout citoyen', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000000a', 'Oui, les ministres ont une immunité totale', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000000a', 'Oui, jusqu''à la fin de son mandat', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000000a', 'Oui, seul le président peut le juger', FALSE, 3);

-- R11 (de f2000000-...00b / CSP / CONNAISSANCE) - Élections législatives
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-00000000000b', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Quels représentants sont élus lors des élections législatives ?',
 'Les élections législatives permettent d''élire les députés qui siègent à l''Assemblée nationale. Ils représentent les circonscriptions.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000000b', 'Les députés', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000000b', 'Les sénateurs', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000000b', 'Le président de la République', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000000b', 'Les maires', FALSE, 3);

-- R12 (de f2000000-...00c / NAT / CONNAISSANCE) - Nombre députés
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-00000000000c', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'De combien de députés l''Assemblée nationale est-elle composée ?',
 'L''Assemblée nationale compte 577 députés, élus pour cinq ans au suffrage universel direct dans 577 circonscriptions.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000000c', '577', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000000c', '348', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000000c', '1 000', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000000c', '200', FALSE, 3);
