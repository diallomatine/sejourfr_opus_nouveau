-- ============================================================================
-- Flyway : niveau 3 (élargissement) - THÈME 2 INSTITUTIONS
-- Lot CR : 50 questions (40 CONNAISSANCE + 10 MISE_SITUATION)
-- IDs : f2000002-0000-0000-0000-000000000033 à 000068
-- is_active = FALSE
-- ============================================================================

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000033', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quel article de la Constitution définit le rôle du président comme garant des institutions ?',
 'L''article 5 dispose que le président veille au respect de la Constitution, assure le fonctionnement régulier des pouvoirs publics et garantit l''indépendance nationale.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000033', 'L''article 5', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000033', 'L''article 89', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000033', 'L''article 1er', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000033', 'L''article 49', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000034', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quel article permet au gouvernement d''engager sa responsabilité sur un texte de loi ?',
 'L''article 49 alinéa 3 de la Constitution permet au gouvernement de faire adopter un texte sans vote, sauf si une motion de censure est adoptée.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000034', 'L''article 49 alinéa 3', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000034', 'L''article 1er', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000034', 'L''article 12', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000034', 'L''article 89', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000035', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quel est l''âge minimum pour être candidat à la présidence de la République ?',
 'Depuis 2011, il faut avoir 18 ans pour être candidat à l''élection présidentielle. Auparavant, il fallait 23 ans.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000035', '18 ans', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000035', '23 ans', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000035', '25 ans', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000035', '35 ans', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000036', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Combien faut-il de parrainages d''élus pour être candidat à la présidentielle ?',
 'Il faut 500 parrainages d''élus (maires, députés, sénateurs, conseillers régionaux/départementaux) d''au moins 30 départements différents.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000036', '500 parrainages d''élus', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000036', '100 parrainages', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000036', '5 000 parrainages', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000036', 'Aucun parrainage requis', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000037', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quelle institution est consultée avant l''adoption de tout projet de loi ?',
 'Le Conseil d''État est consulté sur les projets de loi avant leur examen en Conseil des ministres. Il donne un avis juridique au gouvernement.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000037', 'Le Conseil d''État', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000037', 'La Cour de cassation', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000037', 'Le Conseil constitutionnel uniquement', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000037', 'L''Académie française', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000038', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quelle est la plus haute juridiction de l''ordre administratif ?',
 'Le Conseil d''État est la plus haute juridiction administrative. Il juge les litiges entre particuliers et administration.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000038', 'Le Conseil d''État', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000038', 'La Cour de cassation', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000038', 'Le Conseil constitutionnel', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000038', 'L''Assemblée nationale', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000039', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quelle est la plus haute juridiction de l''ordre judiciaire ?',
 'La Cour de cassation est la juridiction suprême judiciaire. Elle vérifie la bonne application de la loi par les tribunaux.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000039', 'La Cour de cassation', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000039', 'Le Conseil d''État', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000039', 'Le Sénat', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000039', 'Le tribunal de police', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000003a', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quelle juridiction juge les contraventions ?',
 'Les contraventions (infractions les moins graves) sont jugées par le tribunal de police. Les délits relèvent du tribunal correctionnel, les crimes de la cour d''assises.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000003a', 'Le tribunal de police', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000003a', 'La cour d''assises', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000003a', 'Le Conseil constitutionnel', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000003a', 'Le Conseil d''État', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000003b', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quelle juridiction juge les crimes les plus graves (meurtre, viol) ?',
 'Les crimes sont jugés par la cour d''assises, composée de magistrats professionnels et de jurés tirés au sort parmi les citoyens.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000003b', 'La cour d''assises', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000003b', 'Le tribunal de police', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000003b', 'Le Sénat', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000003b', 'Le Parlement', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000003c', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quel échelon territorial constitue la base de l''organisation administrative française ?',
 'La commune est la collectivité territoriale de base. Au-dessus : département, région, État.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000003c', 'La commune (échelon de base)', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000003c', 'L''échelon le plus élevé', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000003c', 'Au-dessus de la région', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000003c', 'Un découpage uniquement religieux', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000003d', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Combien de régions compte la France métropolitaine depuis 2016 ?',
 'Depuis 2016, la France métropolitaine compte 13 régions (contre 22 auparavant), suite à la réforme territoriale.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000003d', '13 régions', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000003d', '22 régions', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000003d', '5 régions', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000003d', '95 régions', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000003e', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Qui dirige une région en France ?',
 'Une région est dirigée par le président du conseil régional, élu par les conseillers régionaux après les élections régionales.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000003e', 'Le président du conseil régional', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000003e', 'Le préfet de région', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000003e', 'Le maire de la plus grande ville', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000003e', 'Le président de la République', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000003f', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quelle est une compétence importante des régions en France ?',
 'Les régions gèrent notamment le développement économique, la formation professionnelle, les lycées et les transports ferroviaires régionaux (TER).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000003f', 'La gestion des lycées et des TER', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000003f', 'La défense nationale', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000003f', 'La politique étrangère', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000003f', 'La monnaie', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000040', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'À quel échelon administratif sont rattachés les collèges ?',
 'Les collèges relèvent des départements. Les lycées relèvent des régions. Les écoles primaires relèvent des communes.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000040', 'Le département', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000040', 'La commune', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000040', 'La région', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000040', 'L''État directement', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000041', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Qui dirige un conseil départemental ?',
 'Le conseil départemental est présidé par son président, élu par les conseillers départementaux. Le préfet représente lui l''État dans le département.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000041', 'Le président du conseil départemental', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000041', 'Le préfet', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000041', 'Le ministre de l''Intérieur', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000041', 'Le maire du chef-lieu', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000042', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Le vote est-il obligatoire en France ?',
 'Non. Voter est un droit et un devoir civique mais pas une obligation légale en France (contrairement à la Belgique). S''abstenir n''est pas sanctionné.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000042', 'Non, c''est un droit mais pas une obligation', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000042', 'Oui, sous peine d''amende', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000042', 'Oui, sous peine de prison', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000042', 'Uniquement pour les fonctionnaires', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000043', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Combien de types d''élections principales un citoyen peut-il voter en France ?',
 'Un citoyen peut voter aux présidentielles, législatives, régionales, départementales, municipales et européennes : six types directs (plus le référendum).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000043', 'Au moins six types différents', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000043', 'Une seule élection', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000043', 'Aucune', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000043', 'Uniquement la présidentielle', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000044', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quelle est la durée du mandat des conseillers municipaux ?',
 'Les conseillers municipaux sont élus pour 6 ans. Le maire qu''ils élisent a la même durée de mandat.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000044', '6 ans', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000044', '5 ans', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000044', '4 ans', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000044', '3 ans', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000045', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quelle est la durée du mandat des conseillers régionaux ?',
 'Comme les conseillers départementaux et municipaux, les conseillers régionaux sont élus pour 6 ans.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000045', '6 ans', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000045', '5 ans', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000045', '7 ans', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000045', '9 ans', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000046', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Les citoyens européens résidant en France peuvent-ils être candidats aux municipales ?',
 'Oui, sauf au poste de maire ou d''adjoint. Ils peuvent aussi voter aux municipales et européennes en France.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000046', 'Oui, mais pas comme maire ou adjoint', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000046', 'Non, c''est interdit', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000046', 'Oui, à toutes les fonctions', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000046', 'Uniquement après 30 ans', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000047', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Combien d''eurodéputés la France envoie-t-elle au Parlement européen ?',
 'La France élit 81 députés européens (depuis le Brexit). Le nombre dépend de la population de chaque pays membre.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000047', '81 députés européens', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000047', '577 députés européens', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000047', '12 députés européens', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000047', 'Aucun', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000048', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quelle institution européenne vote les lois européennes ?',
 'Le Parlement européen, élu par les citoyens, vote les lois européennes conjointement avec le Conseil de l''UE.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000048', 'Le Parlement européen', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000048', 'L''Assemblée nationale française', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000048', 'L''ONU', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000048', 'L''OTAN', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000049', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Où se situent les sièges du Parlement européen ?',
 'Le Parlement européen siège à Strasbourg (sessions plénières officielles) et à Bruxelles (sessions supplémentaires et commissions).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000049', 'À Strasbourg et à Bruxelles', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000049', 'Uniquement à Paris', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000049', 'À Londres', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000049', 'À New York', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000004a', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quel traité a fondé la Communauté économique européenne en 1957 ?',
 'Le traité de Rome (25 mars 1957), signé par 6 pays fondateurs, a créé la CEE, ancêtre de l''Union européenne.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000004a', 'Le traité de Rome', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000004a', 'Le traité de Versailles', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000004a', 'Le traité de Lisbonne', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000004a', 'Le traité de Maastricht', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000004b', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quel traité a créé l''Union européenne sous sa forme actuelle ?',
 'Le traité de Maastricht (7 février 1992) a fondé l''UE. Il a aussi préparé la monnaie unique (euro) et la citoyenneté européenne.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000004b', 'Le traité de Maastricht', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000004b', 'Le traité de Rome', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000004b', 'Le traité de Schengen', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000004b', 'Le traité de Berlin', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000004c', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Que prévoit l''espace Schengen ?',
 'L''espace Schengen permet la libre circulation des personnes en supprimant les contrôles aux frontières entre pays signataires.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000004c', 'La libre circulation sans contrôle aux frontières internes', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000004c', 'Une monnaie unique', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000004c', 'L''interdiction de voyager', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000004c', 'L''abolition des passeports mondiaux', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000004d', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Que confère la citoyenneté européenne ?',
 'Elle donne le droit de circuler, de travailler dans tout pays de l''UE, de voter aux municipales et européennes dans son pays de résidence.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000004d', 'Droit de circuler, travailler et voter dans toute l''Union', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000004d', 'L''abandon de sa nationalité', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000004d', 'Le droit de voter à la présidentielle française', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000004d', 'Aucun droit particulier', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000004e', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Combien y a-t-il de sénateurs en France ?',
 'Le Sénat français compte 348 sénateurs, élus pour 6 ans au suffrage universel indirect.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000004e', '348 sénateurs', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000004e', '577 sénateurs', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000004e', '100 sénateurs', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000004e', '50 sénateurs', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000004f', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'En cas de désaccord persistant entre Assemblée nationale et Sénat, qui tranche ?',
 'L''Assemblée nationale a le dernier mot en cas de désaccord persistant. Cette procédure est prévue par la Constitution.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000004f', 'L''Assemblée nationale', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000004f', 'Le Sénat', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000004f', 'Le président seul', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000004f', 'Le Conseil constitutionnel', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000050', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Qu''est-ce qu''une ordonnance en droit français ?',
 'Une ordonnance est un texte pris par le gouvernement dans un domaine relevant normalement de la loi, après autorisation du Parlement.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000050', 'Un texte du gouvernement dans un domaine normalement législatif', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000050', 'Une décision médicale obligatoire', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000050', 'Un décret religieux', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000050', 'Une convocation au tribunal', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000051', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Que peut faire un citoyen face à un mauvais fonctionnement d''un service public ?',
 'Il peut saisir le Défenseur des droits, autorité administrative indépendante qui défend les droits des usagers face aux administrations.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000051', 'Saisir le Défenseur des droits', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000051', 'Devenir lui-même ministre', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000051', 'Demander à la presse de menacer le service', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000051', 'Rien, il n''y a aucun recours', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000052', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Qu''est-ce que la Question prioritaire de constitutionnalité (QPC) ?',
 'Instaurée en 2008, la QPC permet à tout citoyen de contester devant le Conseil constitutionnel la conformité d''une loi aux droits constitutionnels.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000052', 'Recours du citoyen pour contester une loi devant le Conseil constitutionnel', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000052', 'Une question posée au président', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000052', 'Un sondage parlementaire', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000052', 'Une émission télévisée', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000053', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Comment appelle-t-on les regroupements de communes pour gérer ensemble certains services ?',
 'Les intercommunalités (communautés de communes, d''agglomération, urbaines, métropoles) mutualisent des services (transports, déchets, urbanisme).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000053', 'Les intercommunalités', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000053', 'Les paroisses', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000053', 'Les cantons', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000053', 'Les districts religieux', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000054', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quelle assemblée élit le maire d''une commune ?',
 'Le maire est élu par le conseil municipal (les conseillers municipaux) lors de la première réunion qui suit les élections municipales.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000054', 'Le conseil municipal', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000054', 'Le président de la République', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000054', 'Le préfet', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000054', 'Les habitants au suffrage direct', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000055', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quel est le rôle d''un député européen ?',
 'Un député européen vote les lois européennes au Parlement de Strasbourg, contrôle la Commission européenne et adopte le budget de l''UE.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000055', 'Voter les lois européennes et contrôler la Commission', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000055', 'Diriger un ministère national', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000055', 'Commander l''armée européenne', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000055', 'Nommer le pape', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000056', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quelle institution propose les lois européennes ?',
 'La Commission européenne, basée à Bruxelles, est la seule à pouvoir proposer des lois européennes. Le Parlement et le Conseil les votent.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000056', 'La Commission européenne', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000056', 'Le Parlement européen seul', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000056', 'L''ONU', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000056', 'Le Vatican', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000005a', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quelle indépendance est essentielle pour les juges ?',
 'L''indépendance de la justice signifie que les juges décident en toute liberté, sans pression du pouvoir politique. C''est garanti par la Constitution.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000005a', 'L''indépendance vis-à-vis du pouvoir politique', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000005a', 'La dépendance au président', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000005a', 'L''allégeance à un parti', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000005a', 'La soumission au préfet', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000005b', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quel pouvoir public contrôle le pouvoir exécutif au quotidien ?',
 'Le Parlement (Assemblée + Sénat) contrôle le gouvernement par des questions, des commissions d''enquête, des débats et le vote du budget.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000005b', 'Le Parlement', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000005b', 'L''armée', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000005b', 'Le pape', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000005b', 'Le maire de Paris', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000005c', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Que sont les commissions parlementaires ?',
 'Les commissions parlementaires sont des groupes de députés ou sénateurs spécialisés dans un domaine (lois, finances, défense...) qui préparent les travaux des assemblées.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000005c', 'Des groupes de parlementaires spécialisés par domaine', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000005c', 'Des tribunaux spéciaux', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000005c', 'Des associations de citoyens', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000005c', 'Des émissions de télévision', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000005d', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Un parlementaire peut-il être arrêté sans condition ?',
 'Non. Les parlementaires bénéficient d''une immunité parlementaire pour protéger leur fonction. Elle n''empêche pas la justice de les poursuivre, mais protège la liberté d''expression dans leur fonction.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000005d', 'Non, ils ont une immunité parlementaire', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000005d', 'Oui, sans aucune restriction', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000005d', 'Non, jamais sous aucune condition', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000005d', 'Uniquement les ministres', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000005e', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Le président de la République peut-il être poursuivi pénalement pendant son mandat ?',
 'Le président bénéficie d''une immunité pendant son mandat pour les actes accomplis en cette qualité. Il peut être poursuivi après la fin de son mandat ou destitué par le Parlement réuni en Haute Cour.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000005e', 'Il est protégé pendant le mandat, sauf destitution par la Haute Cour', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000005e', 'Oui, comme tout citoyen', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000005e', 'Non, jamais à vie', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000005e', 'Oui, par le pape', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000005f', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'MISE_SITUATION',
 'Mon employeur veut me licencier sans motif valable. Quel recours s''offre à moi ?',
 'Vous pouvez saisir le conseil des prud''hommes, juridiction spécialisée dans les conflits du travail entre salariés et employeurs.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000005f', 'Saisir le conseil des prud''hommes', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000005f', 'Saisir le Conseil constitutionnel', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000005f', 'Demander au pape', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000005f', 'Aucun recours possible', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000061', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'MISE_SITUATION',
 'Une loi votée me paraît contraire à un de mes droits fondamentaux. Que faire ?',
 'Au cours d''un procès, vous pouvez demander à votre juge de transmettre une Question prioritaire de constitutionnalité (QPC) au Conseil constitutionnel pour faire annuler la loi.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000061', 'Soulever une Question prioritaire de constitutionnalité (QPC)', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000061', 'Réécrire moi-même la Constitution', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000061', 'Saisir une église', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000061', 'Aucune action possible', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000062', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'MISE_SITUATION',
 'Je veux participer à la vie démocratique sans être élu. Quelles possibilités existent ?',
 'On peut s''engager dans un parti politique, dans une association, participer à des consultations publiques, lancer une pétition, ou intervenir lors d''enquêtes publiques.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000062', 'Adhérer à un parti, une association, participer à des consultations', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000062', 'Forcer la porte de l''Élysée', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000062', 'Acheter un mandat de député', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000062', 'Rien hors du vote n''est possible', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000063', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'MISE_SITUATION',
 'Un agent de mairie refuse de me délivrer un document auquel j''ai droit. Que faire ?',
 'Demandez d''abord par écrit pour conserver une trace. En cas de refus persistant, saisissez le Défenseur des droits ou le tribunal administratif.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000063', 'Saisir le Défenseur des droits ou le tribunal administratif', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000063', 'Forcer l''accès avec un huissier', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000063', 'Renoncer immédiatement', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000063', 'Écrire au pape', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000064', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'MISE_SITUATION',
 'Je veux participer à une commission d''enquête parlementaire pour témoigner. Est-ce possible ?',
 'Les commissions d''enquête parlementaires peuvent auditionner des témoins. Le témoignage peut être obligatoire et le faux témoignage est puni pénalement.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000064', 'Oui, on peut être cité comme témoin par une commission d''enquête', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000064', 'Non, c''est strictement réservé aux députés', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000064', 'Uniquement les retraités', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000064', 'Uniquement avec accord de l''Église', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000065', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'MISE_SITUATION',
 'Je conteste un PV de stationnement. À quelle juridiction m''adresser ?',
 'Pour contester un PV de stationnement (forfait post-stationnement), il faut saisir la Commission du contentieux du stationnement payant, juridiction administrative spécialisée.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000065', 'La Commission du contentieux du stationnement payant', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000065', 'La cour d''assises', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000065', 'Le Conseil constitutionnel', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000065', 'Le tribunal de commerce', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000066', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'MISE_SITUATION',
 'Mon député défend un projet contraire à mes idées. Que puis-je faire ?',
 'On peut lui écrire pour exprimer son désaccord, participer à une manifestation légale, soutenir un autre candidat aux prochaines élections, ou militer dans un parti.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000066', 'Écrire, manifester légalement, voter différemment au scrutin suivant', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000066', 'Le faire arrêter', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000066', 'Refuser de payer mes impôts', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000066', 'Quitter la France', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000067', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'MISE_SITUATION',
 'Je suis convoqué comme juré de cour d''assises. Puis-je refuser ?',
 'Être juré est une obligation civique. Seuls certains motifs (âge, incapacité, profession incompatible) permettent d''être dispensé. Refuser sans raison expose à une amende.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000067', 'C''est une obligation civique, refuser sans motif est sanctionné', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000067', 'Oui, c''est facultatif', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000067', 'Uniquement les femmes y sont obligées', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000067', 'Uniquement les fonctionnaires', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000068', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'MISE_SITUATION',
 'Mon voisin n''a pas respecté une règle d''urbanisme. À quelle autorité signaler ?',
 'Les règles d''urbanisme sont contrôlées par la mairie. Vous pouvez signaler l''infraction au maire, qui peut diligenter un contrôle et éventuellement prendre un arrêté.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000068', 'Au maire de la commune', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000068', 'Au président de la République', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000068', 'Au pape', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000068', 'À l''OTAN', FALSE, 3);
