-- Flyway: niveau 3 thème 5 SOCIÉTÉ - 50 NAT (40 CONN + 10 MS) - is_active=FALSE

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000005d', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Quels sont les criteres pour obtenir la nationalité française par naturalisation ?',
 'Pour la naturalisation : être majeur, justifier d''un sejour régulier en France (5 ans en général), maîtriser le français (niveau B2), connaitre l''histoire/culture/société française, avoir des ressources, ne pas avoir de condamnation grave, adherer aux valeurs républicaines.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005d', 'Sejour, langue B2, connaissance société, ressources, integrite', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005d', 'Être ne en France', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005d', 'Avoir un parent français uniquement', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005d', 'Aucun critere requis', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000005e', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que désigne le ''droit du sol'' en droit français ?',
 'Le droit du sol attribue automatiquement la nationalité française à un enfant ne en France de parents étrangers, sous certaines conditions de résidence en France à sa majorité.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005e', 'L''acquisition de la nationalité par naissance en France (sous conditions)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005e', 'Le droit de proprete immobiliere', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005e', 'Le droit à l''agriculture', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005e', 'Le droit au logement', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000005f', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que désigne le ''droit du sang'' en droit français ?',
 'Le droit du sang attribue la nationalité française à un enfant si l''un de ses parents (au moins) est français, quel que soit le lieu de naissance.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005f', 'Acquisition par filiation (parent français)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005f', 'Une transfusion sanguine', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005f', 'Le droit à la chasse', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005f', 'Le droit du commerce', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000060', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Quelle cérémonie marque l''obtention de la nationalité française par naturalisation ?',
 'Une cérémonie d''accueil dans la citoyenneté française est organisée en préfecture. Les nouveaux Français y recoivent leur décret de naturalisation et la Charte des droits et devoirs du citoyen français.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000060', 'Une cérémonie d''accueil en préfecture', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000060', 'Une visite à l''Élysée', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000060', 'Une fête au village d''origine', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000060', 'Aucune cérémonie', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000061', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que désigne la ''déclaration de nationalité française'' après un mariage ?',
 'Un étranger marie à un Français peut acquerir la nationalité française par déclaration après 4 ans de mariage (5 si la communauté de vie n''a pas commence en France ou si l''epoux ne réside pas en France).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000061', 'Acquisition de la nationalité après mariage avec un Français (4 ans en général)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000061', 'Une déclaration au consulat', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000061', 'Un divorce', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000061', 'Aucune procedure', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000062', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que désigne la ''double nationalité'' en droit français ?',
 'La France autorisé la double (ou multiple) nationalité : un Français peut conserver ou acquerir une autre nationalité. Tous les pays ne l''autorisent pas (certains exigent de renoncer à la nationalité d''origine).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000062', 'Posseder la nationalité française et une autre nationalité', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000062', 'Être marie deux fois', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000062', 'Avoir deux passeports d''un même pays', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000062', 'Être apatride', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000063', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Comment un mineur étranger ne en France acquiert-il la nationalité française ?',
 'L''enfant ne en France de parents étrangers acquiert automatiquement la nationalité française à sa majorité, s''il réside en France depuis l''âge de 11 ans (au moins 5 ans). Peut être anticipe des 13 ans.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000063', 'Automatiquement à 18 ans sous condition de résidence', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000063', 'À la naissance automatiquement', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000063', 'Jamais', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000063', 'À 25 ans uniquement', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000064', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que designe l''OFPRA ?',
 'L''Office français de protection des refugies et apatrides examine les demandes d''asile et accordé le statut de refugie ou la protection subsidiaire en France.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000064', 'L''organisme qui examine les demandes d''asile', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000064', 'Un syndicat', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000064', 'Un parti politique', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000064', 'Une banque', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000065', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Quelle est la différence entre ''statut de refugie'' et ''protection subsidiaire'' ?',
 'Le statut de refugie est accordé aux personnes persecutees pour leurs convictions (Convention de Genève, 1951). La protection subsidiaire concerne ceux exposes à un risque grave (peine de mort, torture, conflit arme) sans rentrer dans la Convention de Genève.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000065', 'Refugie = persecutions ; subsidiaire = risque grave sans persecution', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000065', 'Aucune différence', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000065', 'Refugie est temporaire, subsidiaire definitif', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000065', 'Les deux sont identiques', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000066', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Quelle institution européenne assure les politiques migratoires communes ?',
 'L''agence européenne Frontex coordonne la gestion des frontières extérieures de l''UE. L''EASO (devenue EUAA) coordonne les politiques d''asile entre États membres.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000066', 'Frontex (frontières) et EUAA (asile)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000066', 'L''OTAN', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000066', 'L''ONU uniquement', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000066', 'Le pape', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000067', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que prévoit le règlement Dublin pour les demandeurs d''asile en Europe ?',
 'Le règlement Dublin détermine quel État membre est responsable de l''examen d''une demande d''asile (généralement le premier pays d''entrée). Vise a éviter les demandes multiples et le ''asylum shopping''.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000067', 'Designation de l''État responsable de la demande d''asile', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000067', 'Un commerce européen', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000067', 'Un permis de conduire européen', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000067', 'Un programme touristique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000068', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que désigne la ''CMU-C'' devenue ''C2S'' ?',
 'La Couverture maladie universelle complementaire (CMU-C), devenue Complementaire sante solidaire (C2S) en 2019, est une mutuelle gratuite ou peu chere pour les personnes a faibles revenus.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000068', 'Une mutuelle solidaire pour personnes a faibles revenus', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000068', 'Une assurance auto', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000068', 'Un syndicat', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000068', 'Une bourse étudiante', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000069', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que designe l''ÂME (Aide médicale d''État) ?',
 'L''ÂME permet aux étrangers en situation irreguliere résidant en France depuis 3 mois et a faibles revenus de bénéficier d''une prise en charge des frais de sante.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000069', 'Une aide médicale pour étrangers en situation irreguliere', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000069', 'Une assurance pour pilotes', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000069', 'Un syndicat de médecins', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000069', 'Une bourse universitaire', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000006a', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que désigne le RSA-Jeunes en France ?',
 'Le RSA-Jeunes est une variante du RSA pour les 18-24 ans, accessible sous des conditions strictes (avoir travaille 2 ans sur les 3 dernieres années). Le contrat d''engagement jeune (CEJ) le complète.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006a', 'Une variante du RSA pour les 18-24 ans très restrictive', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006a', 'Un service militaire', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006a', 'Un programme touristique', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006a', 'Un permis de chasse', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000006b', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que designe l''allocation aux adultes handicapes (AAH) ?',
 'L''AAH est versée aux personnes handicapees (taux >= 80% ou 50-79% avec restriction d''emploi) dont les revenus sont en dessous d''un plafond. Elle compense les difficultés liees au handicap.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006b', 'Une allocation pour les personnes en situation de handicap', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006b', 'Une assurance vie', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006b', 'Une retraite', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006b', 'Un syndicat', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000006c', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que désigne la MDPH ?',
 'La Maison départementale des personnes handicapees (MDPH) est le guichet unique départemental pour toutes les demandes des personnes handicapees : allocations, cartes, orientation, scolarisation.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006c', 'Le guichet unique pour les personnes handicapees', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006c', 'Un syndicat', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006c', 'Un parti politique', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006c', 'Une mutuelle', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000006d', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Quel sigle designe l''organisme qui certifie le niveau de français des candidats à la nationalité ?',
 'Le TCF (Test de connaissance du français) et le DELF/DALF sont des tests reconnus pour evaluer le niveau de français. Le TCF Intégration, Résident, Naturalite (IRN) est spécifiquement adapte.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006d', 'Le TCF (Test de connaissance du français) IRN', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006d', 'Le permis de conduire', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006d', 'L''INSEE', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006d', 'L''ENA', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000006e', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que designe l''examen civique obligatoire pour la naturalisation depuis 2026 ?',
 'Depuis le 1er janvier 2026, les candidats au CSP, CR ou à la naturalisation doivent reussir un examen civique (QCM de 40 questions, 32 bonnes réponses minimum) sur la France et ses valeurs.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006e', 'Un QCM de 40 questions a passer avec au moins 32/40', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006e', 'Un examen militaire', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006e', 'Un test médical', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006e', 'Un sport', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000006f', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Quels sont les valeurs républicaines auxquelles le nouveau Français doit adherer ?',
 'Les valeurs républicaines : Liberté, Égalité, Fraternité, Laïcité, Démocratie, État de droit, respect des autres, separation des pouvoirs, égalité femmes-hommes, refus des violences et discriminations.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006f', 'Liberté, Égalité, Fraternité, Laïcité, Démocratie, égalité F/H', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006f', 'L''obeissance absolue', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006f', 'La soumission à une religion', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006f', 'Aucune valeur', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000070', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que désigne la ''Charte des droits et devoirs du citoyen français'' ?',
 'Document remis aux nouveaux Français lors de la cérémonie de naturalisation, il rappelle les valeurs, droits et devoirs essentiels du citoyen français. Signe par le candidat.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000070', 'Document remis aux naturalises rappelant valeurs/droits/devoirs', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000070', 'Un permis de conduire', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000070', 'Un contrat de travail', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000070', 'Un livre religieux', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000071', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Le mariage en France implique-t-il les mêmes droits pour les deux conjoints ?',
 'Oui. Depuis 1970 (puis renforcements ulterieurs), les conjoints sont égaux en droits et devoirs. Plus aucune notion de ''chef de famille''.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000071', 'Oui, égalité entre conjoints depuis 1970', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000071', 'Non, le mari décide tout', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000071', 'Non, la femme décide tout', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000071', 'Cela dépend de la religion', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000072', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Quel événement marque l''inscription de l''IVG dans la Constitution ?',
 'Le 8 mars 2024 (Journee internationale des droits des femmes), la France est devenue le premier pays au monde a inscrire la liberté de recourir à l''IVG dans sa Constitution.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000072', 'Inscription de l''IVG dans la Constitution (8 mars 2024)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000072', 'Interdiction de l''IVG', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000072', 'Levee du secret médical', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000072', 'Réforme du divorce', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000073', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Quel est le delai légal pour l''IVG en France ?',
 'L''IVG est légale jusqu''à 14 semaines de grossesse (16 semaines d''amenorrhee), suite à la loi du 2 mars 2022 qui a allonge le delai de 12 à 14 semaines.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000073', '14 semaines de grossesse (depuis 2022)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000073', '5 semaines uniquement', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000073', 'Aucun delai', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000073', '20 semaines', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000074', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Quel principe encadre la gestation pour autrui (GPA) en France ?',
 'La GPA (gestation pour autrui, c''est-à-dire les mères porteuses) est interditée en France au nom du principe d''indisponibilite du corps humain. Une convention GPA est nulle.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000074', 'La GPA est interditée en France', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000074', 'La GPA est libre', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000074', 'La GPA est subventionnee', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000074', 'La GPA est obligatoire', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000075', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'La PMA (procreation medicalement assistee) est-elle ouverte à toutes les femmes en France ?',
 'Depuis la loi de bioethique du 2 août 2021, la PMA est ouverte aux couples de femmes et aux femmes seules, en plus des couples heterosexuels. Elle est prise en chargé par la Sécurité sociale.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000075', 'Oui, depuis la loi de 2021, y compris pour les femmes seules et couples de femmes', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000075', 'Non, uniquement les couples maries heterosexuels', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000075', 'Uniquement les femmes étrangères', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000075', 'Interdite en France', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000076', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Quel âge impose le mariage civil en France ?',
 'L''âge minimum pour se marier est de 18 ans. Une dispense exceptionnelle peut être accordée par le procureur pour motifs graves (rare en pratique). Le mariage de mineur est très encadre.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000076', '18 ans (dispense exceptionnelle possible)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000076', '15 ans', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000076', '21 ans', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000076', 'Pas d''âge minimum', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000077', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Quel principe regit le partage des biens dans le mariage par defaut en France ?',
 'Par defaut, les epoux sont sous le régime de la communauté reduite aux acquets : les biens acquis pendant le mariage sont communs, les biens d''avant et les héritages sont propres. D''autres régimes existent (separation, communauté universelle).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000077', 'La communauté reduite aux acquets par defaut', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000077', 'La communauté universelle automatique', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000077', 'La separation totale automatique', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000077', 'Aucun régime defini', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000078', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que désigne la ''réserve hereditaire'' en droit français ?',
 'La réserve hereditaire est la part du patrimoine reservée aux héritiers reservataires (enfants principalement). On ne peut pas les desheriter complètement par testament.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000078', 'La part minimale due aux héritiers reservataires', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000078', 'Une amende', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000078', 'Une réserve militaire', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000078', 'Une assurance vie', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000079', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Quel âge permet d''être électeur en France ?',
 'Il faut avoir 18 ans (majorité civique) pour pouvoir voter en France, sous condition d''être français (sauf élections européennes/municipales pour les ressortissants UE) et inscrit sur les listes électorales.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000079', '18 ans (avec conditions de nationalité et d''inscription)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000079', '16 ans', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000079', '21 ans', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000079', '25 ans', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000007a', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que désigne le ''permis de conduire a points'' français ?',
 'Le permis de conduire français est dote de 12 points (6 pour les nouveaux conducteurs pendant 3 ans). Les infractions retirent des points. La perte totale entraine l''invalidation.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007a', 'Un système de 12 points retires en cas d''infraction', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007a', 'Un examen oral', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007a', 'Un permis à vie sans limite', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007a', 'Un permis européen unique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000007b', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que designe l''AGS (Association pour la gestion du régime de garantie des salaires) ?',
 'L''AGS garantit le paiement des salaires des employes en cas de faillite de leur employeur. Elle est financée par une cotisation patronale obligatoire.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007b', 'Garantie de paiement des salaires en cas de faillite employeur', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007b', 'Un syndicat', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007b', 'Une assurance auto', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007b', 'Un parti politique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000007c', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que désigne le ''CSE'' depuis 2017 ?',
 'Le Comite social et économique (CSE) a remplace les anciennes instances représentatives du personnel (DP, CE, CHSCT) depuis 2017 (entrée en vigueur progressive jusqu''en 2020). Une seule instance unique.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007c', 'Comite social et économique (instance unique des salariés)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007c', 'Un syndicat patronal', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007c', 'Une administration fiscale', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007c', 'Un parti politique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-0000000000f1', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Quelle distinction fait le droit français entre les syndicats représentatifs et les autres ?',
 'Un syndicat est représentatif au niveau national/professionnel s''il remplit 7 criteres : indépendance, transparence financiere, anciennete, audience aux élections, etc. Cela lui donne le droit de négocier les conventions collectives.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f1', 'Representativite à 7 criteres dont l''audience aux élections', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f1', 'Aucune distinction', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f1', 'Uniquement les syndicats patronaux', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f1', 'Une simple inscription suffit', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-0000000000f2', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que désigne le ''travail dissimule'' en droit pénal ?',
 'Le travail dissimule (article L. 8221-1 du Code du travail) est le fait d''occuper un salarié sans déclaration préalable, sans bulletin de paie ou en sous-declarant les heures effectuees. C''est un delit puni de 3 ans de prison.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f2', 'Travail non declare, delit puni de 3 ans de prison', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f2', 'Travail benevole légal', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f2', 'Travail de nuit autorisé', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f2', 'Service civique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-0000000000f3', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que désigne le ''plan d''epargne entreprise'' (PEE) ?',
 'Le PEE permet aux salariés de se constituer une epargne avec l''aide de l''employeur (abondement). Les sommes sont bloquees 5 ans (sauf cas de deblocage anticipe). Avantages fiscaux à la sortie.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f3', 'Une epargne salariale avec abondement de l''employeur', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f3', 'Une assurance auto', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f3', 'Un syndicat', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f3', 'Une mutuelle', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-0000000000f4', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que désigne la ''participation aux bénéfices'' obligatoire en entreprise ?',
 'La participation aux bénéfices, obligatoire dans les entreprises de 50 salariés ou plus, redistribue une partie des bénéfices aux salariés (formule légale). Les sommes peuvent être versées au PEE ou directement.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f4', 'Redistribution légale des bénéfices aux salariés (50+ salariés)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f4', 'Une amende', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f4', 'Un syndicat patronal', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f4', 'Une assurance', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-0000000000f5', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que désigne le ''mandat de protection future'' ?',
 'Le mandat de protection future permet à une personne de désigner à l''avance la personne qui s''occupera de ses biens et/ou de sa personne le jour ou elle ne pourra plus le faire elle-même (vieillissement, maladie).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f5', 'Designation anticipee de qui gerera nos affaires en cas d''incapacite', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f5', 'Un testament', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f5', 'Un contrat de travail', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f5', 'Un permis', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-0000000000f6', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que désigne le ''pacte civil de solidarité'' (PACS) sur le plan juridique ?',
 'Le PACS, créé en 1999, est un contrat entre 2 personnes majeures pour organiser leur vie commune. Il offre des droits proches du mariage (fiscalite, prestations) mais avec moins de formalites de dissolution.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f6', 'Contrat civil entre 2 majeurs pour organiser la vie commune', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f6', 'Une assurance vie', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f6', 'Un testament', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f6', 'Un permis', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-0000000000f7', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que désigne la ''protection sociale'' au sens large en France ?',
 'La protection sociale couvre l''ensemble des dispositifs (Sécurité sociale, assurance chomage, retraite, aide sociale, allocations familiales) qui protegent les individus contre les risques de la vie : maladie, vieillesse, chomage, famille, pauvrete.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f7', 'Ensemble des dispositifs protegeant contre les risques de la vie', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f7', 'Uniquement la police', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f7', 'Une assurance privée', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f7', 'Un syndicat unique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-0000000000f8', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que designe l''expression ''État-providence'' ?',
 'L''État-providence désigne le modèle social ou l''État assure la protection sociale et redistribue les richesses pour reduire les inégalités (sante, retraites, allocations, services publics gratuits ou subventionnes).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f8', 'Modèle social ou l''État assure protection et redistribution', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f8', 'Un parti politique', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f8', 'Une religion', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f8', 'Un syndicat', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000007d', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'MISE_SITUATION',
 'Je veux déposer une demande de naturalisation française. Quelles sont les principales étapes ?',
 '1. Vérifier l''éligibilité (5 ans de résidence reguliere, niveau B2, intégration). 2. Réunir le dossier (état civil, fiches d''imposition, justificatifs). 3. Déposer en ligne. 4. Examen civique. 5. Entretien d''assimilation. 6. Décret de naturalisation et cérémonie.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007d', 'Éligibilité, dossier, examen civique, entretien, décret', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007d', 'Aucune demarche spécifique', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007d', 'Demander au pape', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007d', 'Verser une caution', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000007e', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'MISE_SITUATION',
 'Je passe l''examen civique pour ma naturalisation. Quel score minimum ?',
 'Il faut obtenir au moins 32 réponses correctes sur 40 (80%) pour reussir l''examen civique introduit par le décret du 1er janvier 2026.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007e', '32/40 minimum (80%)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007e', '20/40', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007e', '10/40', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007e', 'Aucun minimum', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000007f', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'MISE_SITUATION',
 'Je veux preparer la cérémonie d''accueil dans la citoyenneté française. À quoi m''attendre ?',
 'Réception officielle en préfecture en presence du préfet ou du maire. Remise du décret de naturalisation et de la Charte des droits et devoirs. Souvent moment d''emotion et de solennite, avec Marseillaise et symboles républicains.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007f', 'Réception officielle en préfecture avec remise du décret', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007f', 'Une fête privée', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007f', 'Aucune cérémonie', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007f', 'Une messe religieuse', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000080', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'MISE_SITUATION',
 'Je decouvre que je peux perdre la nationalité française. Dans quels cas ?',
 'La nationalité française peut être retirée en cas de fraude lors de l''acquisition (dans les 2 ans). La decheance (rare) frappe ceux condamnés pour terrorisme/crimes graves contre la nation, et binationaux ayant acquis la nationalité française.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000080', 'Fraude à l''acquisition ou decheance pour terrorisme grave', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000080', 'Aucune perte possible', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000080', 'Sur simple décision administrative', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000080', 'A 65 ans automatiquement', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000081', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'MISE_SITUATION',
 'Je veux comprendre l''impact d''un casier judiciaire sur ma demande de nationalité. Quels reperes ?',
 'Toute condamnation a au moins 6 mois de prison ferme rend en principe la naturalisation impossible (sauf rehabilitation). Une condamnation pour terrorisme ou crime contre les intérêts de la nation est un obstacle absolu.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000081', 'Condamnation à 6 mois ferme = en principe rejet', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000081', 'Aucune incidence', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000081', 'Avantage pour la demande', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000081', 'Cela accéléré la procedure', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000082', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'MISE_SITUATION',
 'Je veux faire reconnaitre mes diplômes étrangers en France. À qui m''adresser ?',
 'Le Centre ENIC-NARIC (au sein de France Éducation international) delivre une attestation de comparabilite des diplômes étrangers. Cela facilite l''inscription à une formation ou un emploi.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000082', 'Au centre ENIC-NARIC', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000082', 'Au commissariat', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000082', 'À la mairie uniquement', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000082', 'Au pape', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000083', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'MISE_SITUATION',
 'Je veux comprendre la différence entre nationalité et citoyenneté. Quelle distinction ?',
 'La nationalité est le lien juridique d''une personne avec un État. La citoyenneté est le statut conférant des droits politiques (vote, éligibilité). En France, citoyenneté et nationalité sont généralement liees pour les Français.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000083', 'Nationalité = lien juridique ; Citoyenneté = droits politiques', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000083', 'Aucune différence', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000083', 'La nationalité est temporaire', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000083', 'La citoyenneté est privée', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000084', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'MISE_SITUATION',
 'Je viens d''obtenir la nationalité française. Quels droits nouveaux ?',
 'Le droit de vote à toutes les élections (présidentielle, législatives, etc.), l''éligibilité à tous les mandats électifs, l''accès aux emplois publics réserves aux Français, la protection consulaire française à l''étranger.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000084', 'Vote toutes élections, éligibilité, emplois publics, protection consulaire', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000084', 'Aucun nouveau droit', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000084', 'Uniquement le droit de port d''arme', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000084', 'Uniquement le droit à la sante', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000085', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'MISE_SITUATION',
 'Je veux comprendre ce qu''implique ''l''assimilation à la communauté française'' lors de l''examen pour la nationalité.',
 'L''entretien d''assimilation evalue : connaissance de l''histoire/culture française, adhesion aux valeurs républicaines (laïcité, égalité F/H), maîtrise de la langue, intégration sociale et professionnelle, absence de polygamie.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000085', 'Evaluation langue, valeurs, intégration, connaissance société', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000085', 'Test religieux', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000085', 'Examen militaire', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000085', 'Examen sportif', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000086', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'MISE_SITUATION',
 'Je veux comprendre pourquoi la laïcité est si centrale en France. Quels reperes ?',
 'La laïcité est issue de la loi de 1905 (separation des Églises et de l''État) et est inscrite dans la Constitution (article 1er). Elle garantit la liberté de conscience, la neutralite religieuse de l''État, et l''égalité des citoyens.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000086', 'Loi de 1905, principe constitutionnel, liberté de conscience', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000086', 'Une coutume folklorique', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000086', 'Une obligation religieuse', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000086', 'Un décret récent', FALSE, 3);
