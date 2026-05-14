-- ============================================================================
-- Flyway : reformulations questions officielles - THEME 2 INSTITUTIONS
-- Lot 1/4 : R01 a R12 (Premier ministre, Parlement, pouvoirs, lois, juges)
-- IDs : f2000001-... (preserve la difficulty + type des officielles f2000000-...)
-- is_active = FALSE
-- ============================================================================

-- R01 (de f2000000-...001 / CSP / CONNAISSANCE) - Qui nomme le PM
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000001', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Quelle autorite designe le Premier ministre en France ?',
 'Le Premier ministre est nomme par le president de la Republique, conformement a l''article 8 de la Constitution. Il dirige l''action du gouvernement.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000001', 'Le president de la Republique', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000001', 'Le president du Senat', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000001', 'Le maire de Paris', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000001', 'Le peuple par referendum', FALSE, 3);

-- R02 (de f2000000-...002 / CSP / CONNAISSANCE) - Composition Parlement
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000002', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Quelles sont les deux assemblees qui forment le Parlement francais ?',
 'Le Parlement francais est bicameral : il est compose de l''Assemblee nationale (deputes) et du Senat (senateurs).', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000002', 'L''Assemblee nationale et le Senat', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000002', 'Le gouvernement et le Conseil d''Etat', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000002', 'Le Conseil constitutionnel et le Senat', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000002', 'L''Elysee et Matignon', FALSE, 3);

-- R03 (de f2000000-...003 / CR / CONNAISSANCE) - Pouvoir executif role
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000003', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quelle est la mission principale du pouvoir executif ?',
 'Le pouvoir executif est charge de faire appliquer les lois et de conduire la politique de la nation. Il est exerce par le president de la Republique et le gouvernement.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000003', 'Faire appliquer les lois et diriger la politique de l''Etat', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000003', 'Voter les lois', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000003', 'Juger les delinquants', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000003', 'Reviser la Constitution', FALSE, 3);

-- R04 (de f2000000-...004 / CSP / CONNAISSANCE) - Dirigeants elus democratie
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000004', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Dans quel type de regime les dirigeants sont-ils choisis par les citoyens ?',
 'Dans une democratie, les dirigeants sont elus par les citoyens. C''est ce qui distingue ce regime des monarchies absolues, des dictatures ou des theocraties.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000004', 'Dans une democratie', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000004', 'Dans une dictature', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000004', 'Dans une theocratie', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000004', 'Dans une monarchie absolue', FALSE, 3);

-- R05 (de f2000000-...005 / CSP / MISE_SITUATION) - Respect de la loi
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000005', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'MISE_SITUATION',
 'Peut-on choisir de ne pas appliquer une loi parce qu''on est en desaccord avec elle ?',
 'Non. La loi s''impose a tous les citoyens. Le desaccord se manifeste par les voies legales : vote, debat, recours juridique. Ne pas respecter la loi expose a des sanctions.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000005', 'Non, la loi s''applique a tous, meme en cas de desaccord', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000005', 'Oui, c''est une liberte personnelle', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000005', 'Oui, en cas de croyance religieuse', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000005', 'Oui, le week-end', FALSE, 3);

-- R06 (de f2000000-...006 / CSP / CONNAISSANCE) - Qui doit respecter la loi
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000006', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'En France, qui est tenu de respecter la loi ?',
 'Tout le monde, sans exception : citoyens, residents, dirigeants politiques, agents publics. La loi s''applique de la meme maniere a tous.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000006', 'Toute personne presente sur le territoire', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000006', 'Uniquement les Francais', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000006', 'Uniquement les adultes', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000006', 'Uniquement les personnes condamnees', FALSE, 3);

-- R07 (de f2000000-...007 / CR / CONNAISSANCE) - Role autorite judiciaire
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000007', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Que fait l''autorite judiciaire en France ?',
 'L''autorite judiciaire applique la loi, juge les litiges et protege les libertes individuelles. Elle est independante des autres pouvoirs.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000007', 'Elle applique la loi et protege les libertes', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000007', 'Elle vote les lois', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000007', 'Elle nomme les ministres', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000007', 'Elle gere les ecoles publiques', FALSE, 3);

-- R08 (de f2000000-...008 / CR / CONNAISSANCE) - Pouvoir du juge
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000008', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quel type de pouvoir est exerce par un juge ?',
 'Le juge exerce le pouvoir judiciaire : il dit le droit, tranche les litiges et applique les sanctions prevues par la loi.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000008', 'Le pouvoir judiciaire', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000008', 'Le pouvoir executif', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000008', 'Le pouvoir legislatif', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000008', 'Le pouvoir constitutionnel', FALSE, 3);

-- R09 (de f2000000-...009 / CR / CONNAISSANCE) - Qui exerce le judiciaire
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000009', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'A qui revient l''exercice de l''autorite judiciaire en France ?',
 'L''autorite judiciaire est exercee par les magistrats (juges et procureurs), au sein des tribunaux et des cours.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000009', 'Les magistrats (juges et procureurs)', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000009', 'Les deputes', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000009', 'Les prefets', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000009', 'Le president de la Republique seul', FALSE, 3);

-- R10 (de f2000000-...00a / NAT / CONNAISSANCE) - Ministre ne respecte pas loi
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-00000000000a', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Un ministre commet une infraction. Echappe-t-il a la justice ?',
 'Non. Un ministre, comme tout citoyen, doit repondre de ses actes devant la justice. Pour les actes commis dans l''exercice de ses fonctions, il est juge par la Cour de justice de la Republique.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000000a', 'Non, il peut etre juge comme tout citoyen', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000000a', 'Oui, les ministres ont une immunite totale', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000000a', 'Oui, jusqu''a la fin de son mandat', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000000a', 'Oui, seul le president peut le juger', FALSE, 3);

-- R11 (de f2000000-...00b / CSP / CONNAISSANCE) - Elections legislatives
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-00000000000b', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Quels representants sont elus lors des elections legislatives ?',
 'Les elections legislatives permettent d''elire les deputes qui siegent a l''Assemblee nationale. Ils representent les circonscriptions.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000000b', 'Les deputes', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000000b', 'Les senateurs', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000000b', 'Le president de la Republique', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000000b', 'Les maires', FALSE, 3);

-- R12 (de f2000000-...00c / NAT / CONNAISSANCE) - Nombre deputes
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-00000000000c', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'De combien de deputes l''Assemblee nationale est-elle composee ?',
 'L''Assemblee nationale compte 577 deputes, elus pour cinq ans au suffrage universel direct dans 577 circonscriptions.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000000c', '577', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000000c', '348', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000000c', '1 000', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000000c', '200', FALSE, 3);
