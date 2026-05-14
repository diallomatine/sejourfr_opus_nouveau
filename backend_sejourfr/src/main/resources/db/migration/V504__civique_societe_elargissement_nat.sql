-- Flyway: niveau 3 theme 5 SOCIETE - 50 NAT (40 CONN + 10 MS) - is_active=FALSE

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000005d', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Quels sont les criteres pour obtenir la nationalite francaise par naturalisation ?',
 'Pour la naturalisation : etre majeur, justifier d''un sejour regulier en France (5 ans en general), maitriser le francais (niveau B2), connaitre l''histoire/culture/societe francaise, avoir des ressources, ne pas avoir de condamnation grave, adherer aux valeurs republicaines.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005d', 'Sejour, langue B2, connaissance societe, ressources, integrite', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005d', 'Etre ne en France', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005d', 'Avoir un parent francais uniquement', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005d', 'Aucun critere requis', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000005e', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que designe le ''droit du sol'' en droit francais ?',
 'Le droit du sol attribue automatiquement la nationalite francaise a un enfant ne en France de parents etrangers, sous certaines conditions de residence en France a sa majorite.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005e', 'L''acquisition de la nationalite par naissance en France (sous conditions)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005e', 'Le droit de proprete immobiliere', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005e', 'Le droit a l''agriculture', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005e', 'Le droit au logement', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000005f', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que designe le ''droit du sang'' en droit francais ?',
 'Le droit du sang attribue la nationalite francaise a un enfant si l''un de ses parents (au moins) est francais, quel que soit le lieu de naissance.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005f', 'Acquisition par filiation (parent francais)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005f', 'Une transfusion sanguine', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005f', 'Le droit a la chasse', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005f', 'Le droit du commerce', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000060', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Quelle ceremonie marque l''obtention de la nationalite francaise par naturalisation ?',
 'Une ceremonie d''accueil dans la citoyennete francaise est organisee en prefecture. Les nouveaux Francais y recoivent leur decret de naturalisation et la Charte des droits et devoirs du citoyen francais.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000060', 'Une ceremonie d''accueil en prefecture', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000060', 'Une visite a l''Elysee', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000060', 'Une fete au village d''origine', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000060', 'Aucune ceremonie', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000061', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que designe la ''declaration de nationalite francaise'' apres un mariage ?',
 'Un etranger marie a un Francais peut acquerir la nationalite francaise par declaration apres 4 ans de mariage (5 si la communaute de vie n''a pas commence en France ou si l''epoux ne reside pas en France).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000061', 'Acquisition de la nationalite apres mariage avec un Francais (4 ans en general)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000061', 'Une declaration au consulat', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000061', 'Un divorce', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000061', 'Aucune procedure', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000062', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que designe la ''double nationalite'' en droit francais ?',
 'La France autorise la double (ou multiple) nationalite : un Francais peut conserver ou acquerir une autre nationalite. Tous les pays ne l''autorisent pas (certains exigent de renoncer a la nationalite d''origine).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000062', 'Posseder la nationalite francaise et une autre nationalite', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000062', 'Etre marie deux fois', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000062', 'Avoir deux passeports d''un meme pays', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000062', 'Etre apatride', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000063', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Comment un mineur etranger ne en France acquiert-il la nationalite francaise ?',
 'L''enfant ne en France de parents etrangers acquiert automatiquement la nationalite francaise a sa majorite, s''il reside en France depuis l''age de 11 ans (au moins 5 ans). Peut etre anticipe des 13 ans.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000063', 'Automatiquement a 18 ans sous condition de residence', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000063', 'A la naissance automatiquement', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000063', 'Jamais', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000063', 'A 25 ans uniquement', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000064', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que designe l''OFPRA ?',
 'L''Office francais de protection des refugies et apatrides examine les demandes d''asile et accorde le statut de refugie ou la protection subsidiaire en France.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000064', 'L''organisme qui examine les demandes d''asile', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000064', 'Un syndicat', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000064', 'Un parti politique', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000064', 'Une banque', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000065', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Quelle est la difference entre ''statut de refugie'' et ''protection subsidiaire'' ?',
 'Le statut de refugie est accorde aux personnes persecutees pour leurs convictions (Convention de Geneve, 1951). La protection subsidiaire concerne ceux exposes a un risque grave (peine de mort, torture, conflit arme) sans rentrer dans la Convention de Geneve.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000065', 'Refugie = persecutions ; subsidiaire = risque grave sans persecution', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000065', 'Aucune difference', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000065', 'Refugie est temporaire, subsidiaire definitif', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000065', 'Les deux sont identiques', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000066', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Quelle institution europeenne assure les politiques migratoires communes ?',
 'L''agence europeenne Frontex coordonne la gestion des frontieres exterieures de l''UE. L''EASO (devenue EUAA) coordonne les politiques d''asile entre Etats membres.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000066', 'Frontex (frontieres) et EUAA (asile)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000066', 'L''OTAN', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000066', 'L''ONU uniquement', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000066', 'Le pape', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000067', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que prevoit le reglement Dublin pour les demandeurs d''asile en Europe ?',
 'Le reglement Dublin determine quel Etat membre est responsable de l''examen d''une demande d''asile (generalement le premier pays d''entree). Vise a eviter les demandes multiples et le ''asylum shopping''.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000067', 'Designation de l''Etat responsable de la demande d''asile', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000067', 'Un commerce europeen', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000067', 'Un permis de conduire europeen', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000067', 'Un programme touristique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000068', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que designe la ''CMU-C'' devenue ''C2S'' ?',
 'La Couverture maladie universelle complementaire (CMU-C), devenue Complementaire sante solidaire (C2S) en 2019, est une mutuelle gratuite ou peu chere pour les personnes a faibles revenus.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000068', 'Une mutuelle solidaire pour personnes a faibles revenus', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000068', 'Une assurance auto', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000068', 'Un syndicat', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000068', 'Une bourse etudiante', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000069', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que designe l''AME (Aide medicale d''Etat) ?',
 'L''AME permet aux etrangers en situation irreguliere residant en France depuis 3 mois et a faibles revenus de beneficier d''une prise en charge des frais de sante.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000069', 'Une aide medicale pour etrangers en situation irreguliere', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000069', 'Une assurance pour pilotes', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000069', 'Un syndicat de medecins', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000069', 'Une bourse universitaire', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000006a', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que designe le RSA-Jeunes en France ?',
 'Le RSA-Jeunes est une variante du RSA pour les 18-24 ans, accessible sous des conditions strictes (avoir travaille 2 ans sur les 3 dernieres annees). Le contrat d''engagement jeune (CEJ) le complete.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006a', 'Une variante du RSA pour les 18-24 ans tres restrictive', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006a', 'Un service militaire', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006a', 'Un programme touristique', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006a', 'Un permis de chasse', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000006b', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que designe l''allocation aux adultes handicapes (AAH) ?',
 'L''AAH est versee aux personnes handicapees (taux >= 80% ou 50-79% avec restriction d''emploi) dont les revenus sont en dessous d''un plafond. Elle compense les difficultes liees au handicap.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006b', 'Une allocation pour les personnes en situation de handicap', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006b', 'Une assurance vie', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006b', 'Une retraite', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006b', 'Un syndicat', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000006c', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que designe la MDPH ?',
 'La Maison departementale des personnes handicapees (MDPH) est le guichet unique departemental pour toutes les demandes des personnes handicapees : allocations, cartes, orientation, scolarisation.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006c', 'Le guichet unique pour les personnes handicapees', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006c', 'Un syndicat', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006c', 'Un parti politique', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006c', 'Une mutuelle', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000006d', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Quel sigle designe l''organisme qui certifie le niveau de francais des candidats a la nationalite ?',
 'Le TCF (Test de connaissance du francais) et le DELF/DALF sont des tests reconnus pour evaluer le niveau de francais. Le TCF Integration, Resident, Naturalite (IRN) est specifiquement adapte.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006d', 'Le TCF (Test de connaissance du francais) IRN', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006d', 'Le permis de conduire', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006d', 'L''INSEE', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006d', 'L''ENA', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000006e', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que designe l''examen civique obligatoire pour la naturalisation depuis 2026 ?',
 'Depuis le 1er janvier 2026, les candidats au CSP, CR ou a la naturalisation doivent reussir un examen civique (QCM de 40 questions, 32 bonnes reponses minimum) sur la France et ses valeurs.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006e', 'Un QCM de 40 questions a passer avec au moins 32/40', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006e', 'Un examen militaire', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006e', 'Un test medical', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006e', 'Un sport', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000006f', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Quels sont les valeurs republicaines auxquelles le nouveau Francais doit adherer ?',
 'Les valeurs republicaines : Liberte, Egalite, Fraternite, Laicite, Democratie, Etat de droit, respect des autres, separation des pouvoirs, egalite femmes-hommes, refus des violences et discriminations.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006f', 'Liberte, Egalite, Fraternite, Laicite, Democratie, egalite F/H', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006f', 'L''obeissance absolue', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006f', 'La soumission a une religion', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006f', 'Aucune valeur', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000070', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que designe la ''Charte des droits et devoirs du citoyen francais'' ?',
 'Document remis aux nouveaux Francais lors de la ceremonie de naturalisation, il rappelle les valeurs, droits et devoirs essentiels du citoyen francais. Signe par le candidat.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000070', 'Document remis aux naturalises rappelant valeurs/droits/devoirs', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000070', 'Un permis de conduire', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000070', 'Un contrat de travail', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000070', 'Un livre religieux', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000071', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Le mariage en France implique-t-il les memes droits pour les deux conjoints ?',
 'Oui. Depuis 1970 (puis renforcements ulterieurs), les conjoints sont egaux en droits et devoirs. Plus aucune notion de ''chef de famille''.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000071', 'Oui, egalite entre conjoints depuis 1970', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000071', 'Non, le mari decide tout', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000071', 'Non, la femme decide tout', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000071', 'Cela depend de la religion', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000072', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Quel evenement marque l''inscription de l''IVG dans la Constitution ?',
 'Le 8 mars 2024 (Journee internationale des droits des femmes), la France est devenue le premier pays au monde a inscrire la liberte de recourir a l''IVG dans sa Constitution.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000072', 'Inscription de l''IVG dans la Constitution (8 mars 2024)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000072', 'Interdiction de l''IVG', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000072', 'Levee du secret medical', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000072', 'Reforme du divorce', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000073', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Quel est le delai legal pour l''IVG en France ?',
 'L''IVG est legale jusqu''a 14 semaines de grossesse (16 semaines d''amenorrhee), suite a la loi du 2 mars 2022 qui a allonge le delai de 12 a 14 semaines.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000073', '14 semaines de grossesse (depuis 2022)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000073', '5 semaines uniquement', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000073', 'Aucun delai', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000073', '20 semaines', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000074', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Quel principe encadre la gestation pour autrui (GPA) en France ?',
 'La GPA (gestation pour autrui, c''est-a-dire les meres porteuses) est interdite en France au nom du principe d''indisponibilite du corps humain. Une convention GPA est nulle.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000074', 'La GPA est interdite en France', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000074', 'La GPA est libre', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000074', 'La GPA est subventionnee', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000074', 'La GPA est obligatoire', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000075', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'La PMA (procreation medicalement assistee) est-elle ouverte a toutes les femmes en France ?',
 'Depuis la loi de bioethique du 2 aout 2021, la PMA est ouverte aux couples de femmes et aux femmes seules, en plus des couples heterosexuels. Elle est prise en charge par la Securite sociale.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000075', 'Oui, depuis la loi de 2021, y compris pour les femmes seules et couples de femmes', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000075', 'Non, uniquement les couples maries heterosexuels', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000075', 'Uniquement les femmes etrangeres', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000075', 'Interdite en France', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000076', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Quel age impose le mariage civil en France ?',
 'L''age minimum pour se marier est de 18 ans. Une dispense exceptionnelle peut etre accordee par le procureur pour motifs graves (rare en pratique). Le mariage de mineur est tres encadre.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000076', '18 ans (dispense exceptionnelle possible)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000076', '15 ans', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000076', '21 ans', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000076', 'Pas d''age minimum', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000077', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Quel principe regit le partage des biens dans le mariage par defaut en France ?',
 'Par defaut, les epoux sont sous le regime de la communaute reduite aux acquets : les biens acquis pendant le mariage sont communs, les biens d''avant et les heritages sont propres. D''autres regimes existent (separation, communaute universelle).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000077', 'La communaute reduite aux acquets par defaut', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000077', 'La communaute universelle automatique', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000077', 'La separation totale automatique', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000077', 'Aucun regime defini', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000078', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que designe la ''reserve hereditaire'' en droit francais ?',
 'La reserve hereditaire est la part du patrimoine reservee aux heritiers reservataires (enfants principalement). On ne peut pas les desheriter completement par testament.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000078', 'La part minimale due aux heritiers reservataires', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000078', 'Une amende', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000078', 'Une reserve militaire', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000078', 'Une assurance vie', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000079', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Quel age permet d''etre electeur en France ?',
 'Il faut avoir 18 ans (majorite civique) pour pouvoir voter en France, sous condition d''etre francais (sauf elections europeennes/municipales pour les ressortissants UE) et inscrit sur les listes electorales.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000079', '18 ans (avec conditions de nationalite et d''inscription)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000079', '16 ans', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000079', '21 ans', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000079', '25 ans', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000007a', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que designe le ''permis de conduire a points'' francais ?',
 'Le permis de conduire francais est dote de 12 points (6 pour les nouveaux conducteurs pendant 3 ans). Les infractions retirent des points. La perte totale entraine l''invalidation.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007a', 'Un systeme de 12 points retires en cas d''infraction', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007a', 'Un examen oral', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007a', 'Un permis a vie sans limite', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007a', 'Un permis europeen unique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000007b', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que designe l''AGS (Association pour la gestion du regime de garantie des salaires) ?',
 'L''AGS garantit le paiement des salaires des employes en cas de faillite de leur employeur. Elle est financee par une cotisation patronale obligatoire.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007b', 'Garantie de paiement des salaires en cas de faillite employeur', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007b', 'Un syndicat', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007b', 'Une assurance auto', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007b', 'Un parti politique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000007c', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que designe le ''CSE'' depuis 2017 ?',
 'Le Comite social et economique (CSE) a remplace les anciennes instances representatives du personnel (DP, CE, CHSCT) depuis 2017 (entree en vigueur progressive jusqu''en 2020). Une seule instance unique.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007c', 'Comite social et economique (instance unique des salaries)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007c', 'Un syndicat patronal', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007c', 'Une administration fiscale', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007c', 'Un parti politique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-0000000000f1', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Quelle distinction fait le droit francais entre les syndicats representatifs et les autres ?',
 'Un syndicat est representatif au niveau national/professionnel s''il remplit 7 criteres : independance, transparence financiere, anciennete, audience aux elections, etc. Cela lui donne le droit de negocier les conventions collectives.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f1', 'Representativite a 7 criteres dont l''audience aux elections', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f1', 'Aucune distinction', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f1', 'Uniquement les syndicats patronaux', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f1', 'Une simple inscription suffit', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-0000000000f2', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que designe le ''travail dissimule'' en droit penal ?',
 'Le travail dissimule (article L. 8221-1 du Code du travail) est le fait d''occuper un salarie sans declaration prealable, sans bulletin de paie ou en sous-declarant les heures effectuees. C''est un delit puni de 3 ans de prison.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f2', 'Travail non declare, delit puni de 3 ans de prison', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f2', 'Travail benevole legal', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f2', 'Travail de nuit autorise', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f2', 'Service civique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-0000000000f3', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que designe le ''plan d''epargne entreprise'' (PEE) ?',
 'Le PEE permet aux salaries de se constituer une epargne avec l''aide de l''employeur (abondement). Les sommes sont bloquees 5 ans (sauf cas de deblocage anticipe). Avantages fiscaux a la sortie.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f3', 'Une epargne salariale avec abondement de l''employeur', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f3', 'Une assurance auto', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f3', 'Un syndicat', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f3', 'Une mutuelle', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-0000000000f4', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que designe la ''participation aux benefices'' obligatoire en entreprise ?',
 'La participation aux benefices, obligatoire dans les entreprises de 50 salaries ou plus, redistribue une partie des benefices aux salaries (formule legale). Les sommes peuvent etre versees au PEE ou directement.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f4', 'Redistribution legale des benefices aux salaries (50+ salaries)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f4', 'Une amende', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f4', 'Un syndicat patronal', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f4', 'Une assurance', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-0000000000f5', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que designe le ''mandat de protection future'' ?',
 'Le mandat de protection future permet a une personne de designer a l''avance la personne qui s''occupera de ses biens et/ou de sa personne le jour ou elle ne pourra plus le faire elle-meme (vieillissement, maladie).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f5', 'Designation anticipee de qui gerera nos affaires en cas d''incapacite', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f5', 'Un testament', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f5', 'Un contrat de travail', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f5', 'Un permis', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-0000000000f6', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que designe le ''pacte civil de solidarite'' (PACS) sur le plan juridique ?',
 'Le PACS, cree en 1999, est un contrat entre 2 personnes majeures pour organiser leur vie commune. Il offre des droits proches du mariage (fiscalite, prestations) mais avec moins de formalites de dissolution.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f6', 'Contrat civil entre 2 majeurs pour organiser la vie commune', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f6', 'Une assurance vie', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f6', 'Un testament', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f6', 'Un permis', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-0000000000f7', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que designe la ''protection sociale'' au sens large en France ?',
 'La protection sociale couvre l''ensemble des dispositifs (Securite sociale, assurance chomage, retraite, aide sociale, allocations familiales) qui protegent les individus contre les risques de la vie : maladie, vieillesse, chomage, famille, pauvrete.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f7', 'Ensemble des dispositifs protegeant contre les risques de la vie', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f7', 'Uniquement la police', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f7', 'Une assurance privee', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f7', 'Un syndicat unique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-0000000000f8', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que designe l''expression ''Etat-providence'' ?',
 'L''Etat-providence designe le modele social ou l''Etat assure la protection sociale et redistribue les richesses pour reduire les inegalites (sante, retraites, allocations, services publics gratuits ou subventionnes).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f8', 'Modele social ou l''Etat assure protection et redistribution', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f8', 'Un parti politique', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f8', 'Une religion', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f8', 'Un syndicat', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000007d', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'MISE_SITUATION',
 'Je veux deposer une demande de naturalisation francaise. Quelles sont les principales etapes ?',
 '1. Verifier l''eligibilite (5 ans de residence reguliere, niveau B2, integration). 2. Reunir le dossier (etat civil, fiches d''imposition, justificatifs). 3. Deposer en ligne. 4. Examen civique. 5. Entretien d''assimilation. 6. Decret de naturalisation et ceremonie.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007d', 'Eligibilite, dossier, examen civique, entretien, decret', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007d', 'Aucune demarche specifique', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007d', 'Demander au pape', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007d', 'Verser une caution', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000007e', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'MISE_SITUATION',
 'Je passe l''examen civique pour ma naturalisation. Quel score minimum ?',
 'Il faut obtenir au moins 32 reponses correctes sur 40 (80%) pour reussir l''examen civique introduit par le decret du 1er janvier 2026.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007e', '32/40 minimum (80%)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007e', '20/40', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007e', '10/40', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007e', 'Aucun minimum', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000007f', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'MISE_SITUATION',
 'Je veux preparer la ceremonie d''accueil dans la citoyennete francaise. A quoi m''attendre ?',
 'Reception officielle en prefecture en presence du prefet ou du maire. Remise du decret de naturalisation et de la Charte des droits et devoirs. Souvent moment d''emotion et de solennite, avec Marseillaise et symboles republicains.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007f', 'Reception officielle en prefecture avec remise du decret', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007f', 'Une fete privee', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007f', 'Aucune ceremonie', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007f', 'Une messe religieuse', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000080', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'MISE_SITUATION',
 'Je decouvre que je peux perdre la nationalite francaise. Dans quels cas ?',
 'La nationalite francaise peut etre retiree en cas de fraude lors de l''acquisition (dans les 2 ans). La decheance (rare) frappe ceux condamnes pour terrorisme/crimes graves contre la nation, et binationaux ayant acquis la nationalite francaise.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000080', 'Fraude a l''acquisition ou decheance pour terrorisme grave', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000080', 'Aucune perte possible', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000080', 'Sur simple decision administrative', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000080', 'A 65 ans automatiquement', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000081', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'MISE_SITUATION',
 'Je veux comprendre l''impact d''un casier judiciaire sur ma demande de nationalite. Quels reperes ?',
 'Toute condamnation a au moins 6 mois de prison ferme rend en principe la naturalisation impossible (sauf rehabilitation). Une condamnation pour terrorisme ou crime contre les interets de la nation est un obstacle absolu.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000081', 'Condamnation a 6 mois ferme = en principe rejet', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000081', 'Aucune incidence', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000081', 'Avantage pour la demande', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000081', 'Cela accelere la procedure', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000082', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'MISE_SITUATION',
 'Je veux faire reconnaitre mes diplomes etrangers en France. A qui m''adresser ?',
 'Le Centre ENIC-NARIC (au sein de France Education international) delivre une attestation de comparabilite des diplomes etrangers. Cela facilite l''inscription a une formation ou un emploi.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000082', 'Au centre ENIC-NARIC', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000082', 'Au commissariat', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000082', 'A la mairie uniquement', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000082', 'Au pape', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000083', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'MISE_SITUATION',
 'Je veux comprendre la difference entre nationalite et citoyennete. Quelle distinction ?',
 'La nationalite est le lien juridique d''une personne avec un Etat. La citoyennete est le statut conferant des droits politiques (vote, eligibilite). En France, citoyennete et nationalite sont generalement liees pour les Francais.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000083', 'Nationalite = lien juridique ; Citoyennete = droits politiques', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000083', 'Aucune difference', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000083', 'La nationalite est temporaire', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000083', 'La citoyennete est privee', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000084', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'MISE_SITUATION',
 'Je viens d''obtenir la nationalite francaise. Quels droits nouveaux ?',
 'Le droit de vote a toutes les elections (presidentielle, legislatives, etc.), l''eligibilite a tous les mandats electifs, l''acces aux emplois publics reserves aux Francais, la protection consulaire francaise a l''etranger.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000084', 'Vote toutes elections, eligibilite, emplois publics, protection consulaire', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000084', 'Aucun nouveau droit', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000084', 'Uniquement le droit de port d''arme', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000084', 'Uniquement le droit a la sante', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000085', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'MISE_SITUATION',
 'Je veux comprendre ce qu''implique ''l''assimilation a la communaute francaise'' lors de l''examen pour la nationalite.',
 'L''entretien d''assimilation evalue : connaissance de l''histoire/culture francaise, adhesion aux valeurs republicaines (laicite, egalite F/H), maitrise de la langue, integration sociale et professionnelle, absence de polygamie.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000085', 'Evaluation langue, valeurs, integration, connaissance societe', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000085', 'Test religieux', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000085', 'Examen militaire', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000085', 'Examen sportif', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000086', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'MISE_SITUATION',
 'Je veux comprendre pourquoi la laicite est si centrale en France. Quels reperes ?',
 'La laicite est issue de la loi de 1905 (separation des Eglises et de l''Etat) et est inscrite dans la Constitution (article 1er). Elle garantit la liberte de conscience, la neutralite religieuse de l''Etat, et l''egalite des citoyens.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000086', 'Loi de 1905, principe constitutionnel, liberte de conscience', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000086', 'Une coutume folklorique', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000086', 'Une obligation religieuse', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000086', 'Un decret recent', FALSE, 3);
