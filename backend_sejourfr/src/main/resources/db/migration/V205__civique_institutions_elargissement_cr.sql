-- ============================================================================
-- Flyway : niveau 3 (elargissement) - THEME 2 INSTITUTIONS
-- Lot CR : 50 questions (40 CONNAISSANCE + 10 MISE_SITUATION)
-- IDs : f2000002-0000-0000-0000-000000000033 a 000068
-- is_active = FALSE
-- ============================================================================

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000033', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quel article de la Constitution definit le role du president comme garant des institutions ?',
 'L''article 5 dispose que le president veille au respect de la Constitution, assure le fonctionnement regulier des pouvoirs publics et garantit l''independance nationale.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000033', 'L''article 5', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000033', 'L''article 89', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000033', 'L''article 1er', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000033', 'L''article 49', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000034', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quel article permet au gouvernement d''engager sa responsabilite sur un texte de loi ?',
 'L''article 49 alinea 3 de la Constitution permet au gouvernement de faire adopter un texte sans vote, sauf si une motion de censure est adoptee.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000034', 'L''article 49 alinea 3', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000034', 'L''article 1er', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000034', 'L''article 12', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000034', 'L''article 89', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000035', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quel est l''age minimum pour etre candidat a la presidence de la Republique ?',
 'Depuis 2011, il faut avoir 18 ans pour etre candidat a l''election presidentielle. Auparavant, il fallait 23 ans.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000035', '18 ans', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000035', '23 ans', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000035', '25 ans', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000035', '35 ans', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000036', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Combien faut-il de parrainages d''elus pour etre candidat a la presidentielle ?',
 'Il faut 500 parrainages d''elus (maires, deputes, senateurs, conseillers regionaux/departementaux) d''au moins 30 departements differents.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000036', '500 parrainages d''elus', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000036', '100 parrainages', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000036', '5 000 parrainages', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000036', 'Aucun parrainage requis', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000037', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quelle institution est consultee avant l''adoption de tout projet de loi ?',
 'Le Conseil d''Etat est consulte sur les projets de loi avant leur examen en Conseil des ministres. Il donne un avis juridique au gouvernement.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000037', 'Le Conseil d''Etat', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000037', 'La Cour de cassation', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000037', 'Le Conseil constitutionnel uniquement', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000037', 'L''Academie francaise', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000038', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quelle est la plus haute juridiction de l''ordre administratif ?',
 'Le Conseil d''Etat est la plus haute juridiction administrative. Il juge les litiges entre particuliers et administration.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000038', 'Le Conseil d''Etat', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000038', 'La Cour de cassation', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000038', 'Le Conseil constitutionnel', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000038', 'L''Assemblee nationale', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000039', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quelle est la plus haute juridiction de l''ordre judiciaire ?',
 'La Cour de cassation est la juridiction supreme judiciaire. Elle verifie la bonne application de la loi par les tribunaux.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000039', 'La Cour de cassation', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000039', 'Le Conseil d''Etat', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000039', 'Le Senat', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000039', 'Le tribunal de police', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000003a', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quelle juridiction juge les contraventions ?',
 'Les contraventions (infractions les moins graves) sont jugees par le tribunal de police. Les delits relevent du tribunal correctionnel, les crimes de la cour d''assises.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000003a', 'Le tribunal de police', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000003a', 'La cour d''assises', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000003a', 'Le Conseil constitutionnel', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000003a', 'Le Conseil d''Etat', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000003b', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quelle juridiction juge les crimes les plus graves (meurtre, viol) ?',
 'Les crimes sont juges par la cour d''assises, composee de magistrats professionnels et de jures tires au sort parmi les citoyens.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000003b', 'La cour d''assises', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000003b', 'Le tribunal de police', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000003b', 'Le Senat', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000003b', 'Le Parlement', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000003c', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quel echelon territorial constitue la base de l''organisation administrative francaise ?',
 'La commune est la collectivite territoriale de base. Au-dessus : departement, region, Etat.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000003c', 'La commune (echelon de base)', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000003c', 'L''echelon le plus eleve', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000003c', 'Au-dessus de la region', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000003c', 'Un decoupage uniquement religieux', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000003d', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Combien de regions compte la France metropolitaine depuis 2016 ?',
 'Depuis 2016, la France metropolitaine compte 13 regions (contre 22 auparavant), suite a la reforme territoriale.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000003d', '13 regions', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000003d', '22 regions', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000003d', '5 regions', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000003d', '95 regions', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000003e', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Qui dirige une region en France ?',
 'Une region est dirigee par le president du conseil regional, elu par les conseillers regionaux apres les elections regionales.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000003e', 'Le president du conseil regional', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000003e', 'Le prefet de region', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000003e', 'Le maire de la plus grande ville', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000003e', 'Le president de la Republique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000003f', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quelle est une competence importante des regions en France ?',
 'Les regions gerent notamment le developpement economique, la formation professionnelle, les lycees et les transports ferroviaires regionaux (TER).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000003f', 'La gestion des lycees et des TER', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000003f', 'La defense nationale', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000003f', 'La politique etrangere', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000003f', 'La monnaie', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000040', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'A quel echelon administratif sont rattaches les colleges ?',
 'Les colleges relevent des departements. Les lycees relevent des regions. Les ecoles primaires relevent des communes.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000040', 'Le departement', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000040', 'La commune', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000040', 'La region', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000040', 'L''Etat directement', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000041', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Qui dirige un conseil departemental ?',
 'Le conseil departemental est preside par son president, elu par les conseillers departementaux. Le prefet represente lui l''Etat dans le departement.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000041', 'Le president du conseil departemental', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000041', 'Le prefet', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000041', 'Le ministre de l''Interieur', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000041', 'Le maire du chef-lieu', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000042', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Le vote est-il obligatoire en France ?',
 'Non. Voter est un droit et un devoir civique mais pas une obligation legale en France (contrairement a la Belgique). S''abstenir n''est pas sanctionne.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000042', 'Non, c''est un droit mais pas une obligation', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000042', 'Oui, sous peine d''amende', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000042', 'Oui, sous peine de prison', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000042', 'Uniquement pour les fonctionnaires', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000043', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Combien de types d''elections principales un citoyen peut-il voter en France ?',
 'Un citoyen peut voter aux presidentielles, legislatives, regionales, departementales, municipales et europeennes : six types directs (plus le referendum).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000043', 'Au moins six types differents', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000043', 'Une seule election', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000043', 'Aucune', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000043', 'Uniquement la presidentielle', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000044', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quelle est la duree du mandat des conseillers municipaux ?',
 'Les conseillers municipaux sont elus pour 6 ans. Le maire qu''ils elisent a la meme duree de mandat.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000044', '6 ans', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000044', '5 ans', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000044', '4 ans', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000044', '3 ans', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000045', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quelle est la duree du mandat des conseillers regionaux ?',
 'Comme les conseillers departementaux et municipaux, les conseillers regionaux sont elus pour 6 ans.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000045', '6 ans', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000045', '5 ans', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000045', '7 ans', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000045', '9 ans', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000046', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Les citoyens europeens residant en France peuvent-ils etre candidats aux municipales ?',
 'Oui, sauf au poste de maire ou d''adjoint. Ils peuvent aussi voter aux municipales et europeennes en France.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000046', 'Oui, mais pas comme maire ou adjoint', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000046', 'Non, c''est interdit', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000046', 'Oui, a toutes les fonctions', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000046', 'Uniquement apres 30 ans', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000047', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Combien d''eurodeputes la France envoie-t-elle au Parlement europeen ?',
 'La France elit 81 deputes europeens (depuis le Brexit). Le nombre depend de la population de chaque pays membre.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000047', '81 deputes europeens', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000047', '577 deputes europeens', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000047', '12 deputes europeens', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000047', 'Aucun', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000048', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quelle institution europeenne vote les lois europeennes ?',
 'Le Parlement europeen, elu par les citoyens, vote les lois europeennes conjointement avec le Conseil de l''UE.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000048', 'Le Parlement europeen', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000048', 'L''Assemblee nationale francaise', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000048', 'L''ONU', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000048', 'L''OTAN', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000049', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Ou se situent les sieges du Parlement europeen ?',
 'Le Parlement europeen siege a Strasbourg (sessions plenieres officielles) et a Bruxelles (sessions supplementaires et commissions).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000049', 'A Strasbourg et a Bruxelles', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000049', 'Uniquement a Paris', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000049', 'A Londres', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000049', 'A New York', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000004a', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quel traite a fonde la Communaute economique europeenne en 1957 ?',
 'Le traite de Rome (25 mars 1957), signe par 6 pays fondateurs, a cree la CEE, ancetre de l''Union europeenne.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000004a', 'Le traite de Rome', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000004a', 'Le traite de Versailles', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000004a', 'Le traite de Lisbonne', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000004a', 'Le traite de Maastricht', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000004b', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quel traite a cree l''Union europeenne sous sa forme actuelle ?',
 'Le traite de Maastricht (7 fevrier 1992) a fonde l''UE. Il a aussi prepare la monnaie unique (euro) et la citoyennete europeenne.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000004b', 'Le traite de Maastricht', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000004b', 'Le traite de Rome', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000004b', 'Le traite de Schengen', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000004b', 'Le traite de Berlin', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000004c', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Que prevoit l''espace Schengen ?',
 'L''espace Schengen permet la libre circulation des personnes en supprimant les controles aux frontieres entre pays signataires.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000004c', 'La libre circulation sans controle aux frontieres internes', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000004c', 'Une monnaie unique', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000004c', 'L''interdiction de voyager', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000004c', 'L''abolition des passeports mondiaux', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000004d', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Que confere la citoyennete europeenne ?',
 'Elle donne le droit de circuler, de travailler dans tout pays de l''UE, de voter aux municipales et europeennes dans son pays de residence.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000004d', 'Droit de circuler, travailler et voter dans toute l''Union', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000004d', 'L''abandon de sa nationalite', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000004d', 'Le droit de voter a la presidentielle francaise', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000004d', 'Aucun droit particulier', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000004e', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Combien y a-t-il de senateurs en France ?',
 'Le Senat francais compte 348 senateurs, elus pour 6 ans au suffrage universel indirect.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000004e', '348 senateurs', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000004e', '577 senateurs', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000004e', '100 senateurs', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000004e', '50 senateurs', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000004f', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'En cas de desaccord persistant entre Assemblee nationale et Senat, qui tranche ?',
 'L''Assemblee nationale a le dernier mot en cas de desaccord persistant. Cette procedure est prevue par la Constitution.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000004f', 'L''Assemblee nationale', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000004f', 'Le Senat', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000004f', 'Le president seul', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000004f', 'Le Conseil constitutionnel', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000050', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Qu''est-ce qu''une ordonnance en droit francais ?',
 'Une ordonnance est un texte pris par le gouvernement dans un domaine relevant normalement de la loi, apres autorisation du Parlement.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000050', 'Un texte du gouvernement dans un domaine normalement legislatif', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000050', 'Une decision medicale obligatoire', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000050', 'Un decret religieux', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000050', 'Une convocation au tribunal', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000051', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Que peut faire un citoyen face a un mauvais fonctionnement d''un service public ?',
 'Il peut saisir le Defenseur des droits, autorite administrative independante qui defend les droits des usagers face aux administrations.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000051', 'Saisir le Defenseur des droits', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000051', 'Devenir lui-meme ministre', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000051', 'Demander a la presse de menacer le service', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000051', 'Rien, il n''y a aucun recours', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000052', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Qu''est-ce que la Question prioritaire de constitutionnalite (QPC) ?',
 'Instauree en 2008, la QPC permet a tout citoyen de contester devant le Conseil constitutionnel la conformite d''une loi aux droits constitutionnels.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000052', 'Recours du citoyen pour contester une loi devant le Conseil constitutionnel', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000052', 'Une question posee au president', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000052', 'Un sondage parlementaire', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000052', 'Une emission televisee', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000053', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Comment appelle-t-on les regroupements de communes pour gerer ensemble certains services ?',
 'Les intercommunalites (communautes de communes, d''agglomeration, urbaines, metropoles) mutualisent des services (transports, dechets, urbanisme).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000053', 'Les intercommunalites', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000053', 'Les paroisses', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000053', 'Les cantons', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000053', 'Les districts religieux', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000054', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quelle assemblee elit le maire d''une commune ?',
 'Le maire est elu par le conseil municipal (les conseillers municipaux) lors de la premiere reunion qui suit les elections municipales.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000054', 'Le conseil municipal', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000054', 'Le president de la Republique', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000054', 'Le prefet', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000054', 'Les habitants au suffrage direct', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000055', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quel est le role d''un depute europeen ?',
 'Un depute europeen vote les lois europeennes au Parlement de Strasbourg, controle la Commission europeenne et adopte le budget de l''UE.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000055', 'Voter les lois europeennes et controler la Commission', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000055', 'Diriger un ministere national', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000055', 'Commander l''armee europeenne', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000055', 'Nommer le pape', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000056', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quelle institution propose les lois europeennes ?',
 'La Commission europeenne, basee a Bruxelles, est la seule a pouvoir proposer des lois europeennes. Le Parlement et le Conseil les votent.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000056', 'La Commission europeenne', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000056', 'Le Parlement europeen seul', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000056', 'L''ONU', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000056', 'Le Vatican', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000005a', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quelle independance est essentielle pour les juges ?',
 'L''independance de la justice signifie que les juges decident en toute liberte, sans pression du pouvoir politique. C''est garanti par la Constitution.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000005a', 'L''independance vis-a-vis du pouvoir politique', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000005a', 'La dependance au president', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000005a', 'L''allegeance a un parti', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000005a', 'La soumission au prefet', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000005b', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quel pouvoir public controle le pouvoir executif au quotidien ?',
 'Le Parlement (Assemblee + Senat) controle le gouvernement par des questions, des commissions d''enquete, des debats et le vote du budget.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000005b', 'Le Parlement', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000005b', 'L''armee', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000005b', 'Le pape', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000005b', 'Le maire de Paris', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000005c', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Que sont les commissions parlementaires ?',
 'Les commissions parlementaires sont des groupes de deputes ou senateurs specialises dans un domaine (lois, finances, defense...) qui preparent les travaux des assemblees.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000005c', 'Des groupes de parlementaires specialises par domaine', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000005c', 'Des tribunaux speciaux', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000005c', 'Des associations de citoyens', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000005c', 'Des emissions de television', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000005d', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Un parlementaire peut-il etre arrete sans condition ?',
 'Non. Les parlementaires beneficient d''une immunite parlementaire pour proteger leur fonction. Elle n''empeche pas la justice de les poursuivre, mais protege la liberte d''expression dans leur fonction.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000005d', 'Non, ils ont une immunite parlementaire', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000005d', 'Oui, sans aucune restriction', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000005d', 'Non, jamais sous aucune condition', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000005d', 'Uniquement les ministres', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000005e', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Le president de la Republique peut-il etre poursuivi penalement pendant son mandat ?',
 'Le president beneficie d''une immunite pendant son mandat pour les actes accomplis en cette qualite. Il peut etre poursuivi apres la fin de son mandat ou destitue par le Parlement reuni en Haute Cour.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000005e', 'Il est protege pendant le mandat, sauf destitution par la Haute Cour', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000005e', 'Oui, comme tout citoyen', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000005e', 'Non, jamais a vie', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000005e', 'Oui, par le pape', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000005f', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'MISE_SITUATION',
 'Mon employeur veut me licencier sans motif valable. Quel recours s''offre a moi ?',
 'Vous pouvez saisir le conseil des prud''hommes, juridiction specialisee dans les conflits du travail entre salaries et employeurs.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000005f', 'Saisir le conseil des prud''hommes', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000005f', 'Saisir le Conseil constitutionnel', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000005f', 'Demander au pape', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000005f', 'Aucun recours possible', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000061', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'MISE_SITUATION',
 'Une loi votee me parait contraire a un de mes droits fondamentaux. Que faire ?',
 'Au cours d''un proces, vous pouvez demander a votre juge de transmettre une Question prioritaire de constitutionnalite (QPC) au Conseil constitutionnel pour faire annuler la loi.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000061', 'Soulever une Question prioritaire de constitutionnalite (QPC)', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000061', 'Reecrire moi-meme la Constitution', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000061', 'Saisir une eglise', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000061', 'Aucune action possible', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000062', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'MISE_SITUATION',
 'Je veux participer a la vie democratique sans etre elu. Quelles possibilites existent ?',
 'On peut s''engager dans un parti politique, dans une association, participer a des consultations publiques, lancer une petition, ou intervenir lors d''enquetes publiques.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000062', 'Adherer a un parti, une association, participer a des consultations', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000062', 'Forcer la porte de l''Elysee', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000062', 'Acheter un mandat de depute', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000062', 'Rien hors du vote n''est possible', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000063', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'MISE_SITUATION',
 'Un agent de mairie refuse de me delivrer un document auquel j''ai droit. Que faire ?',
 'Demandez d''abord par ecrit pour conserver une trace. En cas de refus persistant, saisissez le Defenseur des droits ou le tribunal administratif.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000063', 'Saisir le Defenseur des droits ou le tribunal administratif', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000063', 'Forcer l''acces avec un huissier', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000063', 'Renoncer immediatement', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000063', 'Ecrire au pape', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000064', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'MISE_SITUATION',
 'Je veux participer a une commission d''enquete parlementaire pour temoigner. Est-ce possible ?',
 'Les commissions d''enquete parlementaires peuvent auditionner des temoins. Le temoignage peut etre obligatoire et le faux temoignage est puni penalement.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000064', 'Oui, on peut etre cite comme temoin par une commission d''enquete', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000064', 'Non, c''est strictement reserve aux deputes', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000064', 'Uniquement les retraites', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000064', 'Uniquement avec accord de l''Eglise', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000065', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'MISE_SITUATION',
 'Je conteste un PV de stationnement. A quelle juridiction m''adresser ?',
 'Pour contester un PV de stationnement (forfait post-stationnement), il faut saisir la Commission du contentieux du stationnement payant, juridiction administrative specialisee.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000065', 'La Commission du contentieux du stationnement payant', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000065', 'La cour d''assises', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000065', 'Le Conseil constitutionnel', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000065', 'Le tribunal de commerce', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000066', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'MISE_SITUATION',
 'Mon depute defend un projet contraire a mes idees. Que puis-je faire ?',
 'On peut lui ecrire pour exprimer son desaccord, participer a une manifestation legale, soutenir un autre candidat aux prochaines elections, ou militer dans un parti.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000066', 'Ecrire, manifester legalement, voter differemment au scrutin suivant', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000066', 'Le faire arreter', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000066', 'Refuser de payer mes impots', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000066', 'Quitter la France', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000067', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'MISE_SITUATION',
 'Je suis convoque comme jure de cour d''assises. Puis-je refuser ?',
 'Etre jure est une obligation civique. Seuls certains motifs (age, incapacite, profession incompatible) permettent d''etre dispense. Refuser sans raison expose a une amende.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000067', 'C''est une obligation civique, refuser sans motif est sanctionne', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000067', 'Oui, c''est facultatif', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000067', 'Uniquement les femmes y sont obligees', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000067', 'Uniquement les fonctionnaires', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000068', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'MISE_SITUATION',
 'Mon voisin n''a pas respecte une regle d''urbanisme. A quelle autorite signaler ?',
 'Les regles d''urbanisme sont controlees par la mairie. Vous pouvez signaler l''infraction au maire, qui peut diligenter un controle et eventuellement prendre un arrete.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000068', 'Au maire de la commune', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000068', 'Au president de la Republique', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000068', 'Au pape', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000068', 'A l''OTAN', FALSE, 3);
