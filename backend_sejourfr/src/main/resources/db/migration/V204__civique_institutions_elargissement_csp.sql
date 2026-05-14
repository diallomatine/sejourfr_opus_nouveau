-- ============================================================================
-- Flyway : niveau 3 (elargissement) - THEME 2 INSTITUTIONS
-- Lot CSP : 50 questions (40 CONNAISSANCE + 10 MISE_SITUATION)
-- IDs : f2000002-0000-0000-0000-000000000001 a 000032
-- is_active = FALSE
-- ============================================================================

-- BLOC A : PRESIDENT & GOUVERNEMENT (E01-E15)
-- ----------------------------------------------------------------------------
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000001', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Comment appelle-t-on l''ensemble forme par le Premier ministre et les ministres ?',
 'Le Premier ministre et les ministres forment ensemble le gouvernement, qui dirige l''administration de l''Etat.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000001', 'Le gouvernement', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000001', 'Le Parlement', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000001', 'Le Senat', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000001', 'La justice', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000002', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Ou reside et travaille le Premier ministre francais ?',
 'Le Premier ministre reside et travaille a l''hotel Matignon, situe a Paris. C''est le siege officiel du chef du gouvernement.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000002', 'A l''hotel Matignon', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000002', 'Au palais de l''Elysee', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000002', 'Au palais Bourbon', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000002', 'Au palais du Luxembourg', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000003', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Le president de la Republique est-il elu directement par les citoyens ?',
 'Oui. Depuis 1962, le president de la Republique est elu au suffrage universel direct, c''est-a-dire directement par tous les citoyens francais majeurs.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000003', 'Oui, au suffrage universel direct', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000003', 'Non, il est elu par les deputes', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000003', 'Non, il est nomme a vie', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000003', 'Non, il est designe par tirage au sort', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000004', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Combien de tours comporte l''election presidentielle francaise ?',
 'L''election presidentielle comporte deux tours. Si aucun candidat n''obtient plus de 50% des voix au premier tour, les deux candidats arrives en tete s''affrontent au second tour.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000004', 'Deux tours', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000004', 'Un seul tour', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000004', 'Trois tours', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000004', 'Aucun tour, c''est une nomination', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000005', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Le president de la Republique peut-il etre reelu pour un nouveau mandat ?',
 'Oui, mais il ne peut exercer plus de deux mandats consecutifs depuis la revision constitutionnelle de 2008.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000005', 'Oui, mais deux mandats consecutifs au maximum', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000005', 'Non, jamais', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000005', 'Oui, sans aucune limite', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000005', 'Oui, mais une seule fois sur toute la vie', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000006', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Qui est le chef des armees francaises ?',
 'Le president de la Republique est le chef des armees. Il preside les conseils et comites superieurs de la defense nationale (article 15 de la Constitution).', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000006', 'Le president de la Republique', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000006', 'Le ministre de la Defense', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000006', 'Le Premier ministre', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000006', 'Le general le plus age', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000007', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Le president peut-il demander aux citoyens de voter sur une question importante ?',
 'Oui. Le president peut organiser un referendum pour faire decider directement les Francais sur un sujet d''interet national. Le Brexit britannique etait par exemple un referendum.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000007', 'Oui, par un referendum', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000007', 'Non, seul le Parlement decide', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000007', 'Non, jamais', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000007', 'Uniquement avec accord de l''ONU', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000008', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Le president represente-t-il la France a l''etranger ?',
 'Oui. Le president de la Republique represente la France lors des deplacements officiels a l''etranger, des sommets internationaux et des rencontres avec les autres chefs d''Etat.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000008', 'Oui, c''est l''une de ses fonctions', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000008', 'Non, ce role revient au maire de Paris', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000008', 'Non, uniquement les ambassadeurs', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000008', 'Uniquement en cas de guerre', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000009', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Qui dirige la politique du gouvernement au quotidien ?',
 'Le Premier ministre dirige l''action du gouvernement (article 21 de la Constitution). Il coordonne le travail des ministres.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000009', 'Le Premier ministre', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000009', 'Le president du Senat', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000009', 'Le president de l''Assemblee nationale', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000009', 'Le prefet de Paris', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000000a', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Que designe le Conseil des ministres ?',
 'Le Conseil des ministres est la reunion hebdomadaire du president, du Premier ministre et des ministres, en general le mercredi matin a l''Elysee. C''est la qu''on prend les decisions politiques importantes.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000000a', 'La reunion hebdomadaire du president et des ministres', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000000a', 'Un tribunal special', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000000a', 'Une assemblee de citoyens', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000000a', 'Un service de la mairie', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000000b', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Que fait un ministre dans le gouvernement ?',
 'Chaque ministre dirige un domaine particulier (education, justice, sante, economie, etc.). Il propose et applique les politiques publiques de son secteur.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000000b', 'Il dirige un domaine d''action publique (sante, education...)', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000000b', 'Il juge les criminels', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000000b', 'Il vote les lois directement', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000000b', 'Il dirige une mairie', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000000c', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Le president peut-il renvoyer le Premier ministre ?',
 'Oui. Le president peut mettre fin aux fonctions du Premier ministre sur la presentation par celui-ci de la demission du gouvernement (article 8 de la Constitution).', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000000c', 'Oui, lorsque le Premier ministre presente la demission du gouvernement', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000000c', 'Non, jamais', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000000c', 'Oui, avec accord du pape', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000000c', 'Uniquement en cas de guerre', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000000d', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Le president de la Republique signe-t-il les lois votees par le Parlement ?',
 'Oui. Apres le vote du Parlement, le president promulgue (signe officiellement) la loi, qui est ensuite publiee au Journal officiel pour entrer en vigueur.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000000d', 'Oui, il promulgue les lois apres leur vote', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000000d', 'Non, c''est le pape', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000000d', 'Non, le prefet le fait', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000000d', 'Non, c''est automatique sans signature', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000000e', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Le president peut-il dissoudre l''Assemblee nationale ?',
 'Oui. Le president de la Republique peut dissoudre l''Assemblee nationale, ce qui declenche de nouvelles elections legislatives. Cette decision est prevue a l''article 12 de la Constitution.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000000e', 'Oui, en provoquant de nouvelles elections legislatives', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000000e', 'Non, jamais', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000000e', 'Oui, mais le Senat doit confirmer', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000000e', 'Oui, mais l''ONU doit valider', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000000f', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Comment appelle-t-on la residence officielle du Premier ministre ?',
 'La residence officielle du Premier ministre est l''hotel Matignon. On parle souvent de "Matignon" pour designer le Premier ministre et ses services.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000000f', 'Matignon', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000000f', 'L''Elysee', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000000f', 'Le Louvre', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000000f', 'Versailles', FALSE, 3);

-- BLOC B : PARLEMENT (E16-E25)
-- ----------------------------------------------------------------------------
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000010', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Ou siegent les deputes francais ?',
 'Les deputes siegent au Palais Bourbon, a Paris, qui est le lieu de reunion de l''Assemblee nationale.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000010', 'Au Palais Bourbon (Assemblee nationale)', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000010', 'Au palais du Luxembourg', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000010', 'A l''Elysee', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000010', 'Au Louvre', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000011', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Ou siegent les senateurs francais ?',
 'Les senateurs siegent au palais du Luxembourg, situe a Paris dans le 6e arrondissement. C''est le lieu de reunion du Senat.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000011', 'Au palais du Luxembourg', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000011', 'Au Palais Bourbon', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000011', 'A l''Elysee', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000011', 'A Versailles', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000012', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Une loi votee par le Parlement s''applique-t-elle a toute la France ?',
 'Oui. Une loi votee par le Parlement et promulguee par le president s''applique sur tout le territoire national, sauf disposition specifique pour l''outre-mer.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000012', 'Oui, sur tout le territoire national', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000012', 'Non, uniquement a Paris', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000012', 'Uniquement dans la commune ou elle est votee', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000012', 'Uniquement la premiere annee', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000013', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Que vote le Parlement en plus des lois ?',
 'Le Parlement vote egalement le budget de l''Etat (loi de finances) chaque annee. Il fixe les recettes (impots) et les depenses publiques.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000013', 'Le budget annuel de l''Etat', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000013', 'Les emissions de television', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000013', 'Les decisions de justice', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000013', 'Les nominations religieuses', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000014', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Les deputes representent-ils les habitants de leur region uniquement ?',
 'Les deputes representent toute la nation, pas seulement leur circonscription. Cependant, ils sont elus dans une circonscription locale et y conservent un ancrage de terrain.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000014', 'Ils representent la nation entiere', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000014', 'Uniquement leur commune', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000014', 'Uniquement leur famille', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000014', 'Uniquement les electeurs ayant vote pour eux', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000015', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Un depute peut-il poser des questions au gouvernement ?',
 'Oui. Les deputes peuvent poser des questions au gouvernement, notamment lors des seances de "questions au gouvernement" diffusees a la television.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000015', 'Oui, lors des seances de questions au gouvernement', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000015', 'Non, le silence est obligatoire', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000015', 'Uniquement par ecrit pendant la nuit', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000015', 'Uniquement avec autorisation du president', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000016', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Un citoyen peut-il visiter l''Assemblee nationale ?',
 'Oui. L''Assemblee nationale (Palais Bourbon) et le Senat (palais du Luxembourg) sont ouverts au public lors de visites organisees, notamment pendant les Journees du patrimoine.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000016', 'Oui, lors des visites organisees', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000016', 'Non, l''acces est interdit a tous', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000016', 'Uniquement les ambassadeurs etrangers', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000016', 'Uniquement les militaires', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000017', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Le Senat peut-il proposer des lois ?',
 'Oui. Le Senat, comme l''Assemblee nationale, peut proposer et voter des lois. Une loi doit etre adoptee dans les memes termes par les deux chambres pour etre valable.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000017', 'Oui, au meme titre que l''Assemblee nationale', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000017', 'Non, c''est interdit', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000017', 'Uniquement sur la fiscalite', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000017', 'Uniquement avec autorisation du Pape', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000018', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'L''Assemblee nationale et le Senat sont-ils a Paris ?',
 'Oui, les deux assemblees du Parlement francais siegent a Paris : l''Assemblee nationale au Palais Bourbon et le Senat au palais du Luxembourg.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000018', 'Oui, les deux a Paris', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000018', 'Non, a Versailles uniquement', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000018', 'L''une a Marseille, l''autre a Lyon', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000018', 'Aucun siege fixe', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000019', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'L''Assemblee nationale peut-elle renverser le gouvernement ?',
 'Oui. L''Assemblee nationale peut voter une motion de censure pour forcer la demission du gouvernement. C''est l''un des controles du Parlement sur l''executif.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000019', 'Oui, par une motion de censure', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000019', 'Non, jamais', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000019', 'Uniquement avec accord du president', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000019', 'Uniquement en periode de guerre', FALSE, 3);

-- BLOC C : JUSTICE & ADMINISTRATION (E26-E35)
-- ----------------------------------------------------------------------------
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000001a', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Une personne accusee d''un delit a-t-elle le droit a un avocat ?',
 'Oui. Toute personne mise en cause a le droit d''etre defendue par un avocat. Si elle n''a pas les moyens, elle peut beneficier de l''aide juridictionnelle (avocat aux frais de l''Etat).', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000001a', 'Oui, et l''aide juridictionnelle existe pour les plus modestes', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000001a', 'Non, jamais', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000001a', 'Uniquement les hommes y ont droit', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000001a', 'Uniquement si le delit est leger', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000001b', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Toute personne accusee est-elle consideree comme coupable avant son jugement ?',
 'Non. La presomption d''innocence est un principe fondamental : toute personne est consideree comme innocente tant qu''elle n''a pas ete jugee coupable.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000001b', 'Non, elle beneficie de la presomption d''innocence', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000001b', 'Oui, automatiquement', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000001b', 'Cela depend du juge', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000001b', 'Cela depend de la commune', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000001c', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Que fait la police nationale ?',
 'La police nationale est chargee de maintenir l''ordre public, prevenir et constater les infractions, proteger les personnes et les biens. Elle agit dans les communes urbaines.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000001c', 'Elle assure la securite et constate les infractions', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000001c', 'Elle vote les lois', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000001c', 'Elle gere les ecoles', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000001c', 'Elle distribue le courrier', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000001d', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Quel numero d''urgence europeen permet de joindre la police partout en Europe ?',
 'Le 112 est le numero d''urgence europeen, gratuit et accessible 24h/24 dans tous les pays de l''Union europeenne. En France, le 17 reste le numero specifique de la police.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000001d', 'Le 112', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000001d', 'Le 911', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000001d', 'Le 333', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000001d', 'Le 100', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000001e', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Quel numero permet de joindre la police en France (hors numero europeen) ?',
 'En France, le 17 est le numero d''urgence dedie a la police et a la gendarmerie. Il est gratuit et accessible 24h/24.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000001e', 'Le 17', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000001e', 'Le 15', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000001e', 'Le 18', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000001e', 'Le 20', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000001f', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Comment s''appelle l''argent que l''Etat collecte aupres des citoyens et entreprises ?',
 'L''argent que l''Etat collecte est appele "impots". Les impots financent les services publics (ecoles, hopitaux, police, routes...).', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000001f', 'Les impots', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000001f', 'Les dons', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000001f', 'Les heritages', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000001f', 'Les pourboires', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000020', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Tout le monde paie-t-il des impots en France ?',
 'Toute personne qui consomme paie au moins la TVA (incluse dans les prix). En revanche, l''impot sur le revenu n''est paye que par les personnes dont les revenus depassent un certain seuil.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000020', 'Tous paient au moins la TVA, mais pas l''impot sur le revenu', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000020', 'Personne ne paie d''impot', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000020', 'Uniquement les chefs d''entreprise', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000020', 'Uniquement les retraites', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000021', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Comment appelle-t-on les batiments ou se reunissent les conseillers municipaux ?',
 'Les conseils municipaux se reunissent dans la mairie (ou hotel de ville pour les grandes communes), siege officiel de la commune.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000021', 'La mairie (ou hotel de ville)', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000021', 'La cathedrale', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000021', 'Le stade municipal', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000021', 'Le bureau de poste', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000022', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Le maire peut-il celebrer un mariage civil ?',
 'Oui. Le maire (ou un adjoint au maire) est officier d''etat civil. Il celebre les mariages civils a la mairie, en presence des futurs epoux et de leurs temoins.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000022', 'Oui, c''est l''une de ses fonctions d''etat civil', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000022', 'Non, seul un pretre peut le faire', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000022', 'Non, c''est le prefet', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000022', 'Uniquement les couples francais', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000023', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Si une commune a 5 000 habitants, combien aura-t-elle de maires ?',
 'Une commune n''a toujours qu''un seul maire, quelle que soit sa taille. Il peut etre assiste de plusieurs adjoints au maire.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000023', 'Un seul maire (avec des adjoints)', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000023', 'Cinq maires', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000023', 'Un par quartier', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000023', 'Un par age (jeune, adulte, ainee)', FALSE, 3);

-- BLOC D : UE & VOTE (E36-E40)
-- ----------------------------------------------------------------------------
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000024', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Quel symbole de l''Union europeenne est compose d''etoiles dorees sur fond bleu ?',
 'Le drapeau europeen est constitue d''un cercle de douze etoiles dorees sur fond bleu. Les douze etoiles ne representent pas les pays mais l''harmonie et l''unite.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000024', 'Le drapeau europeen', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000024', 'Le drapeau de l''ONU', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000024', 'Le drapeau de l''OTAN', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000024', 'Le drapeau de l''UNESCO', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000025', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Combien d''etoiles compte le drapeau de l''Union europeenne ?',
 'Le drapeau europeen comporte douze etoiles dorees, disposees en cercle. Ce nombre est fixe et ne change pas en fonction du nombre d''Etats membres.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000025', '12 etoiles', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000025', '27 etoiles', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000025', '50 etoiles', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000025', '6 etoiles', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000026', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Comment se nomme l''hymne officiel de l''Union europeenne ?',
 'L''hymne europeen est "L''Ode a la joie", extrait de la 9e symphonie de Beethoven. Il a ete adopte par le Conseil de l''Europe en 1972, puis par l''Union europeenne en 1985.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000026', 'L''Ode a la joie de Beethoven', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000026', 'La Marseillaise', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000026', 'Imagine de John Lennon', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000026', 'Aucun hymne n''est defini', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000027', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'L''euro est-il utilise par tous les pays de l''Union europeenne ?',
 'Non. L''euro est utilise par 20 pays de l''Union europeenne (zone euro). Certains pays comme la Pologne ou la Suede ont conserve leur monnaie nationale.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000027', 'Non, seulement par les pays de la zone euro', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000027', 'Oui, tous les 27 pays utilisent l''euro', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000027', 'Non, seule la France utilise l''euro', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000027', 'Oui, ainsi qu''en Russie et en Chine', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000028', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Avec une carte d''identite francaise, peut-on voyager librement dans l''Union europeenne ?',
 'Oui. La libre circulation dans l''espace Schengen et l''Union europeenne permet aux citoyens francais de voyager avec une simple carte d''identite dans la plupart des pays europeens.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000028', 'Oui, dans la majorite des pays europeens', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000028', 'Non, il faut toujours un passeport', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000028', 'Uniquement le visa diplomatique', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000028', 'Uniquement avec un guide officiel', FALSE, 3);

-- BLOC E : MISES EN SITUATION CSP (E41-E50)
-- ----------------------------------------------------------------------------
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000029', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'MISE_SITUATION',
 'Je viens d''avoir 18 ans et je suis francais. Que dois-je faire pour pouvoir voter ?',
 'Pour voter, il faut s''inscrire sur les listes electorales de sa commune. Depuis 2019, cette inscription est en general automatique a 18 ans, mais il faut verifier qu''elle a bien ete faite.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000029', 'M''inscrire (ou verifier mon inscription) sur les listes electorales', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000029', 'Demander une autorisation au prefet', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000029', 'Passer un examen civique paye', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000029', 'Rien, le president m''envoie une convocation', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000002a', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'MISE_SITUATION',
 'Le jour des elections, je suis malade et ne peux pas me deplacer. Puis-je donner mon vote a quelqu''un ?',
 'Oui. Vous pouvez donner procuration a un autre electeur (mandataire) pour qu''il vote a votre place. La demande se fait dans un commissariat, une gendarmerie ou en ligne.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000002a', 'Oui, en etablissant une procuration de vote', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000002a', 'Non, le vote est strictement personnel', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000002a', 'Uniquement si la personne est de ma famille', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000002a', 'Uniquement avec accord medical', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000002b', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'MISE_SITUATION',
 'Je veux contester un arrete pris par le maire de ma commune. Quels sont mes recours ?',
 'Vous pouvez faire un recours administratif aupres du maire ou saisir le tribunal administratif. Ce dernier peut annuler un arrete illegal.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000002b', 'Saisir le tribunal administratif', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000002b', 'Aucun recours possible', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000002b', 'Demander au prefet de battre le maire', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000002b', 'Quitter la commune', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000002c', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'MISE_SITUATION',
 'On me propose d''acheter mon vote contre de l''argent. Que faire ?',
 'Acheter un vote ou se faire payer pour voter est un delit penal grave (corruption electorale). Vous devez refuser et pouvez signaler les faits a la police ou au procureur.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000002c', 'Refuser et signaler les faits a la police', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000002c', 'Accepter, c''est legal', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000002c', 'Negocier un meilleur prix', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000002c', 'Faire payer plusieurs personnes', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000002d', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'MISE_SITUATION',
 'Au bureau de vote, l''isoloir est-il obligatoire pour glisser mon bulletin dans l''enveloppe ?',
 'Oui. L''isoloir garantit le secret du vote. Tout electeur doit y passer pour mettre son bulletin dans l''enveloppe, sans etre vu.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000002d', 'Oui, c''est obligatoire pour preserver le secret', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000002d', 'Non, je peux le faire au comptoir', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000002d', 'Uniquement si je suis adulte', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000002d', 'Uniquement le jour de l''election', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000002e', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'MISE_SITUATION',
 'Je veux poser une question au depute de ma circonscription. Est-ce possible ?',
 'Oui. Les deputes recoivent les habitants de leur circonscription dans leur permanence parlementaire. On peut prendre rendez-vous ou ecrire pour exposer un probleme.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000002e', 'Oui, dans leur permanence parlementaire', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000002e', 'Non, c''est strictement interdit', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000002e', 'Uniquement par voie d''huissier', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000002e', 'Uniquement en presence d''un avocat', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000002f', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'MISE_SITUATION',
 'Je veux demander un acte de naissance. A quelle administration dois-je m''adresser ?',
 'Pour obtenir un acte de naissance, il faut s''adresser a la mairie de la commune ou la personne est nee. La demande peut souvent se faire en ligne.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000002f', 'A la mairie de la commune de naissance', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000002f', 'Au Parlement', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000002f', 'A l''Elysee', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000002f', 'A l''eglise du quartier', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000030', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'MISE_SITUATION',
 'Quelqu''un me dit que je ne dois pas voter parce que je suis une femme. Est-ce vrai ?',
 'Non. Toutes les femmes francaises majeures ont le droit de vote depuis 1944, exactement comme les hommes. Vouloir les en empecher constitue une discrimination interdite.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000030', 'Non, les femmes ont le droit de vote depuis 1944', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000030', 'Oui, c''est une regle ancienne', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000030', 'Uniquement les femmes mariees votent', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000030', 'Uniquement les femmes de plus de 35 ans', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000031', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'MISE_SITUATION',
 'Je suis victime d''un vol dans la rue. Que dois-je faire pour le signaler officiellement ?',
 'Vous devez deposer plainte au commissariat de police ou a la gendarmerie. Vous pouvez aussi appeler le 17 (police) en cas d''urgence ou faire une pre-plainte en ligne.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000031', 'Deposer plainte au commissariat ou a la gendarmerie', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000031', 'Demander a un voisin de gerer', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000031', 'Ecrire un message a l''Elysee', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000031', 'Faire justice moi-meme', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000032', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'MISE_SITUATION',
 'Je viens d''emmenager dans une nouvelle commune. Dois-je changer mon inscription electorale ?',
 'Oui. Pour voter dans votre nouvelle commune, vous devez vous inscrire sur ses listes electorales (en mairie ou en ligne). Sinon vous resterez inscrit dans votre ancienne commune.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000032', 'Oui, m''inscrire sur les listes de ma nouvelle commune', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000032', 'Non, l''inscription se fait automatiquement par GPS', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000032', 'Non, j''ai 10 ans pour le faire', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000032', 'Non, je vote dans toutes les communes', FALSE, 3);

-- ============================================================================
-- Fin lot CSP elargissement THEME 2 : 50 questions (40 CONN + 10 MS)
-- ============================================================================
