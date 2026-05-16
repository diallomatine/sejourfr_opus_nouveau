-- ============================================================================
-- Flyway : niveau 3 (élargissement) - THÈME 2 INSTITUTIONS
-- Lot CSP : 50 questions (40 CONNAISSANCE + 10 MISE_SITUATION)
-- IDs : f2000002-0000-0000-0000-000000000001 à 000032
-- is_active = FALSE
-- ============================================================================

-- BLOC A : PRÉSIDENT & GOUVERNEMENT (E01-E15)
-- ----------------------------------------------------------------------------
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000001', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Comment appelle-t-on l''ensemble formé par le Premier ministre et les ministres ?',
 'Le Premier ministre et les ministres forment ensemble le gouvernement, qui dirige l''administration de l''État.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000001', 'Le gouvernement', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000001', 'Le Parlement', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000001', 'Le Sénat', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000001', 'La justice', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000002', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Où réside et travaille le Premier ministre français ?',
 'Le Premier ministre réside et travaille à l''hôtel Matignon, situé à Paris. C''est le siège officiel du chef du gouvernement.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000002', 'À l''hôtel Matignon', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000002', 'Au palais de l''Élysée', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000002', 'Au palais Bourbon', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000002', 'Au palais du Luxembourg', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000003', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Le président de la République est-il élu directement par les citoyens ?',
 'Oui. Depuis 1962, le président de la République est élu au suffrage universel direct, c''est-à-dire directement par tous les citoyens français majeurs.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000003', 'Oui, au suffrage universel direct', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000003', 'Non, il est élu par les députés', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000003', 'Non, il est nommé à vie', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000003', 'Non, il est désigné par tirage au sort', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000004', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Combien de tours comporte l''élection présidentielle française ?',
 'L''élection présidentielle comporte deux tours. Si aucun candidat n''obtient plus de 50% des voix au premier tour, les deux candidats arrivés en tête s''affrontent au second tour.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000004', 'Deux tours', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000004', 'Un seul tour', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000004', 'Trois tours', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000004', 'Aucun tour, c''est une nomination', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000005', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Le président de la République peut-il être réélu pour un nouveau mandat ?',
 'Oui, mais il ne peut exercer plus de deux mandats consécutifs depuis la révision constitutionnelle de 2008.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000005', 'Oui, mais deux mandats consécutifs au maximum', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000005', 'Non, jamais', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000005', 'Oui, sans aucune limite', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000005', 'Oui, mais une seule fois sur toute la vie', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000006', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Qui est le chef des armées françaises ?',
 'Le président de la République est le chef des armées. Il préside les conseils et comités supérieurs de la défense nationale (article 15 de la Constitution).', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000006', 'Le président de la République', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000006', 'Le ministre de la Défense', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000006', 'Le Premier ministre', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000006', 'Le général le plus âgé', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000007', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Le président peut-il demander aux citoyens de voter sur une question importante ?',
 'Oui. Le président peut organiser un référendum pour faire décider directement les Français sur un sujet d''intérêt national. Le Brexit britannique était par exemple un référendum.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000007', 'Oui, par un référendum', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000007', 'Non, seul le Parlement décide', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000007', 'Non, jamais', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000007', 'Uniquement avec accord de l''ONU', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000008', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Le président représente-t-il la France à l''étranger ?',
 'Oui. Le président de la République représente la France lors des déplacements officiels à l''étranger, des sommets internationaux et des rencontres avec les autres chefs d''État.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000008', 'Oui, c''est l''une de ses fonctions', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000008', 'Non, ce rôle revient au maire de Paris', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000008', 'Non, uniquement les ambassadeurs', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000008', 'Uniquement en cas de guerre', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000009', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Qui dirige la politique du gouvernement au quotidien ?',
 'Le Premier ministre dirige l''action du gouvernement (article 21 de la Constitution). Il coordonne le travail des ministres.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000009', 'Le Premier ministre', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000009', 'Le président du Sénat', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000009', 'Le président de l''Assemblée nationale', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000009', 'Le préfet de Paris', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000000a', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Que désigne le Conseil des ministres ?',
 'Le Conseil des ministres est la réunion hebdomadaire du président, du Premier ministre et des ministres, en général le mercredi matin à l''Élysée. C''est là qu''on prend les décisions politiques importantes.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000000a', 'La réunion hebdomadaire du président et des ministres', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000000a', 'Un tribunal spécial', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000000a', 'Une assemblée de citoyens', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000000a', 'Un service de la mairie', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000000b', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Que fait un ministre dans le gouvernement ?',
 'Chaque ministre dirige un domaine particulier (éducation, justice, santé, économie, etc.). Il propose et applique les politiques publiques de son secteur.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000000b', 'Il dirige un domaine d''action publique (santé, éducation...)', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000000b', 'Il juge les criminels', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000000b', 'Il vote les lois directement', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000000b', 'Il dirige une mairie', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000000c', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Le président peut-il renvoyer le Premier ministre ?',
 'Oui. Le président peut mettre fin aux fonctions du Premier ministre sur la présentation par celui-ci de la démission du gouvernement (article 8 de la Constitution).', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000000c', 'Oui, lorsque le Premier ministre présente la démission du gouvernement', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000000c', 'Non, jamais', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000000c', 'Oui, avec accord du pape', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000000c', 'Uniquement en cas de guerre', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000000d', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Le président de la République signe-t-il les lois votées par le Parlement ?',
 'Oui. Après le vote du Parlement, le président promulgue (signe officiellement) la loi, qui est ensuite publiée au Journal officiel pour entrer en vigueur.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000000d', 'Oui, il promulgue les lois après leur vote', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000000d', 'Non, c''est le pape', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000000d', 'Non, le préfet le fait', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000000d', 'Non, c''est automatique sans signature', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000000e', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Le président peut-il dissoudre l''Assemblée nationale ?',
 'Oui. Le président de la République peut dissoudre l''Assemblée nationale, ce qui déclenche de nouvelles élections législatives. Cette décision est prévue à l''article 12 de la Constitution.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000000e', 'Oui, en provoquant de nouvelles élections législatives', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000000e', 'Non, jamais', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000000e', 'Oui, mais le Sénat doit confirmer', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000000e', 'Oui, mais l''ONU doit valider', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000000f', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Comment appelle-t-on la résidence officielle du Premier ministre ?',
 'La résidence officielle du Premier ministre est l''hôtel Matignon. On parle souvent de "Matignon" pour désigner le Premier ministre et ses services.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000000f', 'Matignon', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000000f', 'L''Élysée', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000000f', 'Le Louvre', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000000f', 'Versailles', FALSE, 3);

-- BLOC B : PARLEMENT (E16-E25)
-- ----------------------------------------------------------------------------
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000010', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Où siègent les députés français ?',
 'Les députés siègent au Palais Bourbon, à Paris, qui est le lieu de réunion de l''Assemblée nationale.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000010', 'Au Palais Bourbon (Assemblée nationale)', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000010', 'Au palais du Luxembourg', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000010', 'À l''Élysée', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000010', 'Au Louvre', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000011', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Où siègent les sénateurs français ?',
 'Les sénateurs siègent au palais du Luxembourg, situé à Paris dans le 6e arrondissement. C''est le lieu de réunion du Sénat.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000011', 'Au palais du Luxembourg', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000011', 'Au Palais Bourbon', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000011', 'À l''Élysée', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000011', 'À Versailles', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000012', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Une loi votée par le Parlement s''applique-t-elle à toute la France ?',
 'Oui. Une loi votée par le Parlement et promulguée par le président s''applique sur tout le territoire national, sauf disposition spécifique pour l''outre-mer.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000012', 'Oui, sur tout le territoire national', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000012', 'Non, uniquement à Paris', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000012', 'Uniquement dans la commune où elle est votée', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000012', 'Uniquement la première année', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000013', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Que vote le Parlement en plus des lois ?',
 'Le Parlement vote également le budget de l''État (loi de finances) chaque année. Il fixe les recettes (impôts) et les dépenses publiques.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000013', 'Le budget annuel de l''État', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000013', 'Les émissions de télévision', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000013', 'Les décisions de justice', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000013', 'Les nominations religieuses', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000014', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Les députés représentent-ils les habitants de leur région uniquement ?',
 'Les députés représentent toute la nation, pas seulement leur circonscription. Cependant, ils sont élus dans une circonscription locale et y conservent un ancrage de terrain.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000014', 'Ils représentent la nation entière', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000014', 'Uniquement leur commune', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000014', 'Uniquement leur famille', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000014', 'Uniquement les électeurs ayant voté pour eux', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000015', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Un député peut-il poser des questions au gouvernement ?',
 'Oui. Les députés peuvent poser des questions au gouvernement, notamment lors des séances de "questions au gouvernement" diffusées à la télévision.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000015', 'Oui, lors des séances de questions au gouvernement', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000015', 'Non, le silence est obligatoire', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000015', 'Uniquement par écrit pendant la nuit', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000015', 'Uniquement avec autorisation du président', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000016', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Un citoyen peut-il visiter l''Assemblée nationale ?',
 'Oui. L''Assemblée nationale (Palais Bourbon) et le Sénat (palais du Luxembourg) sont ouverts au public lors de visites organisées, notamment pendant les Journées du patrimoine.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000016', 'Oui, lors des visites organisées', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000016', 'Non, l''accès est interdit à tous', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000016', 'Uniquement les ambassadeurs étrangers', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000016', 'Uniquement les militaires', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000017', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Le Sénat peut-il proposer des lois ?',
 'Oui. Le Sénat, comme l''Assemblée nationale, peut proposer et voter des lois. Une loi doit être adoptée dans les mêmes termes par les deux chambres pour être valable.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000017', 'Oui, au même titre que l''Assemblée nationale', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000017', 'Non, c''est interdit', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000017', 'Uniquement sur la fiscalité', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000017', 'Uniquement avec autorisation du Pape', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000018', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'L''Assemblée nationale et le Sénat sont-ils à Paris ?',
 'Oui, les deux assemblées du Parlement français siègent à Paris : l''Assemblée nationale au Palais Bourbon et le Sénat au palais du Luxembourg.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000018', 'Oui, les deux à Paris', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000018', 'Non, à Versailles uniquement', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000018', 'L''une à Marseille, l''autre à Lyon', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000018', 'Aucun siège fixe', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000019', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'L''Assemblée nationale peut-elle renverser le gouvernement ?',
 'Oui. L''Assemblée nationale peut voter une motion de censure pour forcer la démission du gouvernement. C''est l''un des contrôles du Parlement sur l''exécutif.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000019', 'Oui, par une motion de censure', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000019', 'Non, jamais', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000019', 'Uniquement avec accord du président', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000019', 'Uniquement en période de guerre', FALSE, 3);

-- BLOC C : JUSTICE & ADMINISTRATION (E26-E35)
-- ----------------------------------------------------------------------------
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000001a', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Une personne accusée d''un délit a-t-elle le droit à un avocat ?',
 'Oui. Toute personne mise en cause a le droit d''être défendue par un avocat. Si elle n''a pas les moyens, elle peut bénéficier de l''aide juridictionnelle (avocat aux frais de l''État).', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000001a', 'Oui, et l''aide juridictionnelle existe pour les plus modestes', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000001a', 'Non, jamais', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000001a', 'Uniquement les hommes y ont droit', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000001a', 'Uniquement si le délit est léger', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000001b', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Toute personne accusée est-elle considérée comme coupable avant son jugement ?',
 'Non. La présomption d''innocence est un principe fondamental : toute personne est considérée comme innocente tant qu''elle n''a pas été jugée coupable.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000001b', 'Non, elle bénéficie de la présomption d''innocence', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000001b', 'Oui, automatiquement', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000001b', 'Cela dépend du juge', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000001b', 'Cela dépend de la commune', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000001c', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Que fait la police nationale ?',
 'La police nationale est chargée de maintenir l''ordre public, prévenir et constater les infractions, protéger les personnes et les biens. Elle agit dans les communes urbaines.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000001c', 'Elle assure la sécurité et constate les infractions', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000001c', 'Elle vote les lois', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000001c', 'Elle gère les écoles', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000001c', 'Elle distribue le courrier', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000001d', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Quel numéro d''urgence européen permet de joindre la police partout en Europe ?',
 'Le 112 est le numéro d''urgence européen, gratuit et accessible 24h/24 dans tous les pays de l''Union européenne. En France, le 17 reste le numéro spécifique de la police.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000001d', 'Le 112', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000001d', 'Le 911', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000001d', 'Le 333', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000001d', 'Le 100', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000001e', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Quel numéro permet de joindre la police en France (hors numéro européen) ?',
 'En France, le 17 est le numéro d''urgence dédié à la police et à la gendarmerie. Il est gratuit et accessible 24h/24.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000001e', 'Le 17', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000001e', 'Le 15', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000001e', 'Le 18', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000001e', 'Le 20', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000001f', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Comment s''appelle l''argent que l''État collecte auprès des citoyens et entreprises ?',
 'L''argent que l''État collecte est appelé "impôts". Les impôts financent les services publics (écoles, hôpitaux, police, routes...).', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000001f', 'Les impôts', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000001f', 'Les dons', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000001f', 'Les héritages', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000001f', 'Les pourboires', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000020', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Tout le monde paie-t-il des impôts en France ?',
 'Toute personne qui consomme paie au moins la TVA (incluse dans les prix). En revanche, l''impôt sur le revenu n''est payé que par les personnes dont les revenus dépassent un certain seuil.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000020', 'Tous paient au moins la TVA, mais pas l''impôt sur le revenu', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000020', 'Personne ne paie d''impôt', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000020', 'Uniquement les chefs d''entreprise', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000020', 'Uniquement les retraités', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000021', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Comment appelle-t-on les bâtiments où se réunissent les conseillers municipaux ?',
 'Les conseils municipaux se réunissent dans la mairie (ou hôtel de ville pour les grandes communes), siège officiel de la commune.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000021', 'La mairie (ou hôtel de ville)', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000021', 'La cathédrale', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000021', 'Le stade municipal', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000021', 'Le bureau de poste', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000022', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Le maire peut-il célébrer un mariage civil ?',
 'Oui. Le maire (ou un adjoint au maire) est officier d''état civil. Il célèbre les mariages civils à la mairie, en présence des futurs époux et de leurs témoins.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000022', 'Oui, c''est l''une de ses fonctions d''état civil', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000022', 'Non, seul un prêtre peut le faire', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000022', 'Non, c''est le préfet', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000022', 'Uniquement les couples français', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000023', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Si une commune a 5 000 habitants, combien aura-t-elle de maires ?',
 'Une commune n''a toujours qu''un seul maire, quelle que soit sa taille. Il peut être assisté de plusieurs adjoints au maire.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000023', 'Un seul maire (avec des adjoints)', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000023', 'Cinq maires', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000023', 'Un par quartier', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000023', 'Un par âge (jeune, adulte, aîné)', FALSE, 3);

-- BLOC D : UE & VOTE (E36-E40)
-- ----------------------------------------------------------------------------
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000024', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Quel symbole de l''Union européenne est composé d''étoiles dorées sur fond bleu ?',
 'Le drapeau européen est constitué d''un cercle de douze étoiles dorées sur fond bleu. Les douze étoiles ne représentent pas les pays mais l''harmonie et l''unité.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000024', 'Le drapeau européen', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000024', 'Le drapeau de l''ONU', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000024', 'Le drapeau de l''OTAN', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000024', 'Le drapeau de l''UNESCO', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000025', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Combien d''étoiles compte le drapeau de l''Union européenne ?',
 'Le drapeau européen comporte douze étoiles dorées, disposées en cercle. Ce nombre est fixé et ne change pas en fonction du nombre d''États membres.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000025', '12 étoiles', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000025', '27 étoiles', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000025', '50 étoiles', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000025', '6 étoiles', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000026', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Comment se nomme l''hymne officiel de l''Union européenne ?',
 'L''hymne européen est "L''Ode à la joie", extrait de la 9e symphonie de Beethoven. Il a été adopté par le Conseil de l''Europe en 1972, puis par l''Union européenne en 1985.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000026', 'L''Ode à la joie de Beethoven', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000026', 'La Marseillaise', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000026', 'Imagine de John Lennon', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000026', 'Aucun hymne n''est défini', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000027', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'L''euro est-il utilisé par tous les pays de l''Union européenne ?',
 'Non. L''euro est utilisé par 20 pays de l''Union européenne (zone euro). Certains pays comme la Pologne ou la Suède ont conservé leur monnaie nationale.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000027', 'Non, seulement par les pays de la zone euro', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000027', 'Oui, tous les 27 pays utilisent l''euro', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000027', 'Non, seule la France utilise l''euro', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000027', 'Oui, ainsi qu''en Russie et en Chine', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000028', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Avec une carte d''identité française, peut-on voyager librement dans l''Union européenne ?',
 'Oui. La libre circulation dans l''espace Schengen et l''Union européenne permet aux citoyens français de voyager avec une simple carte d''identité dans la plupart des pays européens.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000028', 'Oui, dans la majorité des pays européens', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000028', 'Non, il faut toujours un passeport', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000028', 'Uniquement le visa diplomatique', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000028', 'Uniquement avec un guide officiel', FALSE, 3);

-- BLOC E : MISES EN SITUATION CSP (E41-E50)
-- ----------------------------------------------------------------------------
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000029', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'MISE_SITUATION',
 'Je viens d''avoir 18 ans et je suis français. Que dois-je faire pour pouvoir voter ?',
 'Pour voter, il faut s''inscrire sur les listes électorales de sa commune. Depuis 2019, cette inscription est en général automatique à 18 ans, mais il faut vérifier qu''elle a bien été faite.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000029', 'M''inscrire (ou vérifier mon inscription) sur les listes électorales', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000029', 'Demander une autorisation au préfet', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000029', 'Passer un examen civique payé', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000029', 'Rien, le président m''envoie une convocation', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000002a', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'MISE_SITUATION',
 'Le jour des élections, je suis malade et ne peux pas me déplacer. Puis-je donner mon vote à quelqu''un ?',
 'Oui. Vous pouvez donner procuration à un autre électeur (mandataire) pour qu''il vote à votre place. La demande se fait dans un commissariat, une gendarmerie ou en ligne.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000002a', 'Oui, en établissant une procuration de vote', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000002a', 'Non, le vote est strictement personnel', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000002a', 'Uniquement si la personne est de ma famille', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000002a', 'Uniquement avec accord médical', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000002b', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'MISE_SITUATION',
 'Je veux contester un arrêté pris par le maire de ma commune. Quels sont mes recours ?',
 'Vous pouvez faire un recours administratif auprès du maire ou saisir le tribunal administratif. Ce dernier peut annuler un arrêté illégal.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000002b', 'Saisir le tribunal administratif', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000002b', 'Aucun recours possible', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000002b', 'Demander au préfet de battre le maire', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000002b', 'Quitter la commune', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000002c', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'MISE_SITUATION',
 'On me propose d''acheter mon vote contre de l''argent. Que faire ?',
 'Acheter un vote ou se faire payer pour voter est un délit pénal grave (corruption électorale). Vous devez refuser et pouvez signaler les faits à la police ou au procureur.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000002c', 'Refuser et signaler les faits à la police', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000002c', 'Accepter, c''est légal', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000002c', 'Négocier un meilleur prix', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000002c', 'Faire payer plusieurs personnes', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000002d', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'MISE_SITUATION',
 'Au bureau de vote, l''isoloir est-il obligatoire pour glisser mon bulletin dans l''enveloppe ?',
 'Oui. L''isoloir garantit le secret du vote. Tout électeur doit y passer pour mettre son bulletin dans l''enveloppe, sans être vu.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000002d', 'Oui, c''est obligatoire pour préserver le secret', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000002d', 'Non, je peux le faire au comptoir', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000002d', 'Uniquement si je suis adulte', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000002d', 'Uniquement le jour de l''élection', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000002e', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'MISE_SITUATION',
 'Je veux poser une question au député de ma circonscription. Est-ce possible ?',
 'Oui. Les députés reçoivent les habitants de leur circonscription dans leur permanence parlementaire. On peut prendre rendez-vous ou écrire pour exposer un problème.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000002e', 'Oui, dans leur permanence parlementaire', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000002e', 'Non, c''est strictement interdit', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000002e', 'Uniquement par voie d''huissier', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000002e', 'Uniquement en présence d''un avocat', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000002f', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'MISE_SITUATION',
 'Je veux demander un acte de naissance. À quelle administration dois-je m''adresser ?',
 'Pour obtenir un acte de naissance, il faut s''adresser à la mairie de la commune où la personne est née. La demande peut souvent se faire en ligne.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000002f', 'À la mairie de la commune de naissance', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000002f', 'Au Parlement', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000002f', 'À l''Élysée', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000002f', 'À l''église du quartier', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000030', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'MISE_SITUATION',
 'Quelqu''un me dit que je ne dois pas voter parce que je suis une femme. Est-ce vrai ?',
 'Non. Toutes les femmes françaises majeures ont le droit de vote depuis 1944, exactement comme les hommes. Vouloir les en empêcher constitue une discrimination interdite.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000030', 'Non, les femmes ont le droit de vote depuis 1944', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000030', 'Oui, c''est une règle ancienne', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000030', 'Uniquement les femmes mariées votent', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000030', 'Uniquement les femmes de plus de 35 ans', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000031', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'MISE_SITUATION',
 'Je suis victime d''un vol dans la rue. Que dois-je faire pour le signaler officiellement ?',
 'Vous devez déposer plainte au commissariat de police ou à la gendarmerie. Vous pouvez aussi appeler le 17 (police) en cas d''urgence ou faire une pré-plainte en ligne.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000031', 'Déposer plainte au commissariat ou à la gendarmerie', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000031', 'Demander à un voisin de gérer', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000031', 'Écrire un message à l''Élysée', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000031', 'Faire justice moi-même', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000032', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'MISE_SITUATION',
 'Je viens d''emménager dans une nouvelle commune. Dois-je changer mon inscription électorale ?',
 'Oui. Pour voter dans votre nouvelle commune, vous devez vous inscrire sur ses listes électorales (en mairie ou en ligne). Sinon vous resterez inscrit dans votre ancienne commune.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000032', 'Oui, m''inscrire sur les listes de ma nouvelle commune', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000032', 'Non, l''inscription se fait automatiquement par GPS', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000032', 'Non, j''ai 10 ans pour le faire', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000032', 'Non, je vote dans toutes les communes', FALSE, 3);

-- ============================================================================
-- Fin lot CSP élargissement THÈME 2 : 50 questions (40 CONN + 10 MS)
-- ============================================================================
