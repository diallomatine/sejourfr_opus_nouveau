-- Flyway: niveau 3 thème 5 SOCIÉTÉ - 50 NAT (40 CONN + 10 MS) - is_active=FALSE

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000005d', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Quels sont les critères pour obtenir la nationalité française par naturalisation ?',
 'Pour la naturalisation : être majeur, justifier d''un séjour régulier en France (5 ans en général), maîtriser le français (niveau B2), connaître l''histoire/culture/société française, avoir des ressources, ne pas avoir de condamnation grave, adhérer aux valeurs républicaines.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005d', 'Séjour, langue B2, connaissance société, ressources, intégrité', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005d', 'Être né en France', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005d', 'Avoir un parent français uniquement', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005d', 'Aucun critère requis', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000005e', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que désigne le ''droit du sol'' en droit français ?',
 'Le droit du sol attribue automatiquement la nationalité française à un enfant né en France de parents étrangers, sous certaines conditions de résidence en France à sa majorité.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005e', 'L''acquisition de la nationalité par naissance en France (sous conditions)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005e', 'Le droit de propriété immobilière', FALSE, 1),
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
 'Une cérémonie d''accueil dans la citoyenneté française est organisée en préfecture. Les nouveaux Français y reçoivent leur décret de naturalisation et la Charte des droits et devoirs du citoyen français.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000060', 'Une cérémonie d''accueil en préfecture', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000060', 'Une visite à l''Élysée', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000060', 'Une fête au village d''origine', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000060', 'Aucune cérémonie', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000061', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que désigne la ''déclaration de nationalité française'' après un mariage ?',
 'Un étranger marié à un Français peut acquérir la nationalité française par déclaration après 4 ans de mariage (5 si la communauté de vie n''a pas commencé en France ou si l''époux ne réside pas en France).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000061', 'Acquisition de la nationalité après mariage avec un Français (4 ans en général)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000061', 'Une déclaration au consulat', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000061', 'Un divorce', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000061', 'Aucune procédure', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000062', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que désigne la ''double nationalité'' en droit français ?',
 'La France autorise la double (ou multiple) nationalité : un Français peut conserver ou acquérir une autre nationalité. Tous les pays ne l''autorisent pas (certains exigent de renoncer à la nationalité d''origine).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000062', 'Posséder la nationalité française et une autre nationalité', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000062', 'Être marié deux fois', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000062', 'Avoir deux passeports d''un même pays', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000062', 'Être apatride', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000063', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Comment un mineur étranger né en France acquiert-il la nationalité française ?',
 'L''enfant né en France de parents étrangers acquiert automatiquement la nationalité française à sa majorité, s''il réside en France depuis l''âge de 11 ans (au moins 5 ans). Peut être anticipée dès 13 ans.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000063', 'Automatiquement à 18 ans sous condition de résidence', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000063', 'À la naissance automatiquement', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000063', 'Jamais', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000063', 'À 25 ans uniquement', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000064', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que désigne l''OFPRA ?',
 'L''Office français de protection des réfugiés et apatrides examine les demandes d''asile et accorde le statut de réfugié ou la protection subsidiaire en France.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000064', 'L''organisme qui examine les demandes d''asile', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000064', 'Un syndicat', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000064', 'Un parti politique', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000064', 'Une banque', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000065', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Quelle est la différence entre ''statut de réfugié'' et ''protection subsidiaire'' ?',
 'Le statut de réfugié est accordé aux personnes persécutées pour leurs convictions (Convention de Genève, 1951). La protection subsidiaire concerne ceux exposés à un risque grave (peine de mort, torture, conflit armé) sans rentrer dans la Convention de Genève.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000065', 'Réfugié = persécutions ; subsidiaire = risque grave sans persécution', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000065', 'Aucune différence', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000065', 'Réfugié est temporaire, subsidiaire définitif', FALSE, 2),
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
 'Le règlement Dublin détermine quel État membre est responsable de l''examen d''une demande d''asile (généralement le premier pays d''entrée). Vise à éviter les demandes multiples et l''''asylum shopping''.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000067', 'Désignation de l''État responsable de la demande d''asile', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000067', 'Un commerce européen', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000067', 'Un permis de conduire européen', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000067', 'Un programme touristique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000068', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que désigne la ''CMU-C'' devenue ''C2S'' ?',
 'La Couverture maladie universelle complémentaire (CMU-C), devenue Complémentaire santé solidaire (C2S) en 2019, est une mutuelle gratuite ou peu chère pour les personnes à faibles revenus.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000068', 'Une mutuelle solidaire pour personnes à faibles revenus', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000068', 'Une assurance auto', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000068', 'Un syndicat', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000068', 'Une bourse étudiante', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000069', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que désigne l''AME (Aide médicale d''État) ?',
 'L''AME permet aux étrangers en situation irrégulière résidant en France depuis 3 mois et à faibles revenus de bénéficier d''une prise en charge des frais de santé.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000069', 'Une aide médicale pour étrangers en situation irrégulière', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000069', 'Une assurance pour pilotes', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000069', 'Un syndicat de médecins', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000069', 'Une bourse universitaire', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000006a', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que désigne le RSA-Jeunes en France ?',
 'Le RSA-Jeunes est une variante du RSA pour les 18-24 ans, accessible sous des conditions strictes (avoir travaillé 2 ans sur les 3 dernières années). Le contrat d''engagement jeune (CEJ) le complète.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006a', 'Une variante du RSA pour les 18-24 ans très restrictive', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006a', 'Un service militaire', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006a', 'Un programme touristique', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006a', 'Un permis de chasse', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000006b', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que désigne l''allocation aux adultes handicapés (AAH) ?',
 'L''AAH est versée aux personnes handicapées (taux >= 80% ou 50-79% avec restriction d''emploi) dont les revenus sont en dessous d''un plafond. Elle compense les difficultés liées au handicap.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006b', 'Une allocation pour les personnes en situation de handicap', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006b', 'Une assurance vie', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006b', 'Une retraite', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006b', 'Un syndicat', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000006c', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que désigne la MDPH ?',
 'La Maison départementale des personnes handicapées (MDPH) est le guichet unique départemental pour toutes les demandes des personnes handicapées : allocations, cartes, orientation, scolarisation.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006c', 'Le guichet unique pour les personnes handicapées', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006c', 'Un syndicat', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006c', 'Un parti politique', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006c', 'Une mutuelle', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000006d', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Quel sigle désigne l''organisme qui certifie le niveau de français des candidats à la nationalité ?',
 'Le TCF (Test de connaissance du français) et le DELF/DALF sont des tests reconnus pour évaluer le niveau de français. Le TCF Intégration, Résident, Naturalité (IRN) est spécifiquement adapté.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006d', 'Le TCF (Test de connaissance du français) IRN', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006d', 'Le permis de conduire', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006d', 'L''INSEE', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006d', 'L''ENA', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000006e', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que désigne l''examen civique obligatoire pour la naturalisation depuis 2026 ?',
 'Depuis le 1er janvier 2026, les candidats au CSP, CR ou à la naturalisation doivent réussir un examen civique (QCM de 40 questions, 32 bonnes réponses minimum) sur la France et ses valeurs.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006e', 'Un QCM de 40 questions à passer avec au moins 32/40', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006e', 'Un examen militaire', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006e', 'Un test médical', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006e', 'Un sport', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000006f', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Quelles sont les valeurs républicaines auxquelles le nouveau Français doit adhérer ?',
 'Les valeurs républicaines : Liberté, Égalité, Fraternité, Laïcité, Démocratie, État de droit, respect des autres, séparation des pouvoirs, égalité femmes-hommes, refus des violences et discriminations.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006f', 'Liberté, Égalité, Fraternité, Laïcité, Démocratie, égalité F/H', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006f', 'L''obéissance absolue', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006f', 'La soumission à une religion', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000006f', 'Aucune valeur', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000070', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que désigne la ''Charte des droits et devoirs du citoyen français'' ?',
 'Document remis aux nouveaux Français lors de la cérémonie de naturalisation, il rappelle les valeurs, droits et devoirs essentiels du citoyen français. Signé par le candidat.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000070', 'Document remis aux naturalisés rappelant valeurs/droits/devoirs', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000070', 'Un permis de conduire', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000070', 'Un contrat de travail', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000070', 'Un livre religieux', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000071', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Le mariage en France implique-t-il les mêmes droits pour les deux conjoints ?',
 'Oui. Depuis 1970 (puis renforcements ultérieurs), les conjoints sont égaux en droits et devoirs. Plus aucune notion de ''chef de famille''.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000071', 'Oui, égalité entre conjoints depuis 1970', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000071', 'Non, le mari décide tout', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000071', 'Non, la femme décide tout', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000071', 'Cela dépend de la religion', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000072', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Quel événement marque l''inscription de l''IVG dans la Constitution ?',
 'Le 8 mars 2024 (Journée internationale des droits des femmes), la France est devenue le premier pays au monde à inscrire la liberté de recourir à l''IVG dans sa Constitution.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000072', 'Inscription de l''IVG dans la Constitution (8 mars 2024)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000072', 'Interdiction de l''IVG', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000072', 'Levée du secret médical', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000072', 'Réforme du divorce', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000073', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Quel est le délai légal pour l''IVG en France ?',
 'L''IVG est légale jusqu''à 14 semaines de grossesse (16 semaines d''aménorrhée), suite à la loi du 2 mars 2022 qui a allongé le délai de 12 à 14 semaines.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000073', '14 semaines de grossesse (depuis 2022)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000073', '5 semaines uniquement', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000073', 'Aucun délai', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000073', '20 semaines', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000074', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Quel principe encadre la gestation pour autrui (GPA) en France ?',
 'La GPA (gestation pour autrui, c''est-à-dire les mères porteuses) est interdite en France au nom du principe d''indisponibilité du corps humain. Une convention GPA est nulle.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000074', 'La GPA est interdite en France', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000074', 'La GPA est libre', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000074', 'La GPA est subventionnée', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000074', 'La GPA est obligatoire', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000075', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'La PMA (procréation médicalement assistée) est-elle ouverte à toutes les femmes en France ?',
 'Depuis la loi de bioéthique du 2 août 2021, la PMA est ouverte aux couples de femmes et aux femmes seules, en plus des couples hétérosexuels. Elle est prise en charge par la Sécurité sociale.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000075', 'Oui, depuis la loi de 2021, y compris pour les femmes seules et couples de femmes', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000075', 'Non, uniquement les couples mariés hétérosexuels', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000075', 'Uniquement les femmes étrangères', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000075', 'Interdite en France', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000076', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Quel âge impose le mariage civil en France ?',
 'L''âge minimum pour se marier est de 18 ans. Une dispense exceptionnelle peut être accordée par le procureur pour motifs graves (rare en pratique). Le mariage de mineur est très encadré.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000076', '18 ans (dispense exceptionnelle possible)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000076', '15 ans', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000076', '21 ans', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000076', 'Pas d''âge minimum', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000077', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Quel principe régit le partage des biens dans le mariage par défaut en France ?',
 'Par défaut, les époux sont sous le régime de la communauté réduite aux acquêts : les biens acquis pendant le mariage sont communs, les biens d''avant et les héritages sont propres. D''autres régimes existent (séparation, communauté universelle).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000077', 'La communauté réduite aux acquêts par défaut', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000077', 'La communauté universelle automatique', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000077', 'La séparation totale automatique', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000077', 'Aucun régime défini', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000078', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que désigne la ''réserve héréditaire'' en droit français ?',
 'La réserve héréditaire est la part du patrimoine réservée aux héritiers réservataires (enfants principalement). On ne peut pas les déshériter complètement par testament.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000078', 'La part minimale due aux héritiers réservataires', TRUE, 0),
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
 'Que désigne le ''permis de conduire à points'' français ?',
 'Le permis de conduire français est doté de 12 points (6 pour les nouveaux conducteurs pendant 3 ans). Les infractions retirent des points. La perte totale entraîne l''invalidation.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007a', 'Un système de 12 points retirés en cas d''infraction', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007a', 'Un examen oral', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007a', 'Un permis à vie sans limite', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007a', 'Un permis européen unique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000007b', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que désigne l''AGS (Association pour la gestion du régime de garantie des salaires) ?',
 'L''AGS garantit le paiement des salaires des employés en cas de faillite de leur employeur. Elle est financée par une cotisation patronale obligatoire.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007b', 'Garantie de paiement des salaires en cas de faillite employeur', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007b', 'Un syndicat', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007b', 'Une assurance auto', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007b', 'Un parti politique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000007c', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que désigne le ''CSE'' depuis 2017 ?',
 'Le Comité social et économique (CSE) a remplacé les anciennes instances représentatives du personnel (DP, CE, CHSCT) depuis 2017 (entrée en vigueur progressive jusqu''en 2020). Une seule instance unique.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007c', 'Comité social et économique (instance unique des salariés)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007c', 'Un syndicat patronal', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007c', 'Une administration fiscale', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007c', 'Un parti politique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-0000000000f1', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Quelle distinction fait le droit français entre les syndicats représentatifs et les autres ?',
 'Un syndicat est représentatif au niveau national/professionnel s''il remplit 7 critères : indépendance, transparence financière, ancienneté, audience aux élections, etc. Cela lui donne le droit de négocier les conventions collectives.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f1', 'Représentativité à 7 critères dont l''audience aux élections', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f1', 'Aucune distinction', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f1', 'Uniquement les syndicats patronaux', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f1', 'Une simple inscription suffit', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-0000000000f2', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que désigne le ''travail dissimulé'' en droit pénal ?',
 'Le travail dissimulé (article L. 8221-1 du Code du travail) est le fait d''occuper un salarié sans déclaration préalable, sans bulletin de paie ou en sous-déclarant les heures effectuées. C''est un délit puni de 3 ans de prison.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f2', 'Travail non déclaré, délit puni de 3 ans de prison', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f2', 'Travail bénévole légal', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f2', 'Travail de nuit autorisé', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f2', 'Service civique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-0000000000f3', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que désigne le ''plan d''épargne entreprise'' (PEE) ?',
 'Le PEE permet aux salariés de se constituer une épargne avec l''aide de l''employeur (abondement). Les sommes sont bloquées 5 ans (sauf cas de déblocage anticipé). Avantages fiscaux à la sortie.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f3', 'Une épargne salariale avec abondement de l''employeur', TRUE, 0),
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
 'Le mandat de protection future permet à une personne de désigner à l''avance la personne qui s''occupera de ses biens et/ou de sa personne le jour où elle ne pourra plus le faire elle-même (vieillissement, maladie).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f5', 'Désignation anticipée de qui gérera nos affaires en cas d''incapacité', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f5', 'Un testament', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f5', 'Un contrat de travail', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f5', 'Un permis', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-0000000000f6', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que désigne le ''pacte civil de solidarité'' (PACS) sur le plan juridique ?',
 'Le PACS, créé en 1999, est un contrat entre 2 personnes majeures pour organiser leur vie commune. Il offre des droits proches du mariage (fiscalité, prestations) mais avec moins de formalités de dissolution.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f6', 'Contrat civil entre 2 majeurs pour organiser la vie commune', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f6', 'Une assurance vie', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f6', 'Un testament', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f6', 'Un permis', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-0000000000f7', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que désigne la ''protection sociale'' au sens large en France ?',
 'La protection sociale couvre l''ensemble des dispositifs (Sécurité sociale, assurance chômage, retraite, aide sociale, allocations familiales) qui protègent les individus contre les risques de la vie : maladie, vieillesse, chômage, famille, pauvreté.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f7', 'Ensemble des dispositifs protégeant contre les risques de la vie', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f7', 'Uniquement la police', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f7', 'Une assurance privée', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f7', 'Un syndicat unique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-0000000000f8', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'CONNAISSANCE',
 'Que désigne l''expression ''État-providence'' ?',
 'L''État-providence désigne le modèle social où l''État assure la protection sociale et redistribue les richesses pour réduire les inégalités (santé, retraites, allocations, services publics gratuits ou subventionnés).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f8', 'Modèle social où l''État assure protection et redistribution', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f8', 'Un parti politique', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f8', 'Une religion', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000f8', 'Un syndicat', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000007d', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'MISE_SITUATION',
 'Je veux déposer une demande de naturalisation française. Quelles sont les principales étapes ?',
 '1. Vérifier l''éligibilité (5 ans de résidence régulière, niveau B2, intégration). 2. Réunir le dossier (état civil, fiches d''imposition, justificatifs). 3. Déposer en ligne. 4. Examen civique. 5. Entretien d''assimilation. 6. Décret de naturalisation et cérémonie.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007d', 'Éligibilité, dossier, examen civique, entretien, décret', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007d', 'Aucune démarche spécifique', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007d', 'Demander au pape', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007d', 'Verser une caution', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000007e', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'MISE_SITUATION',
 'Je passe l''examen civique pour ma naturalisation. Quel score minimum ?',
 'Il faut obtenir au moins 32 réponses correctes sur 40 (80%) pour réussir l''examen civique introduit par le décret du 1er janvier 2026.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007e', '32/40 minimum (80%)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007e', '20/40', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007e', '10/40', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007e', 'Aucun minimum', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000007f', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'MISE_SITUATION',
 'Je veux préparer la cérémonie d''accueil dans la citoyenneté française. À quoi m''attendre ?',
 'Réception officielle en préfecture en présence du préfet ou du maire. Remise du décret de naturalisation et de la Charte des droits et devoirs. Souvent moment d''émotion et de solennité, avec Marseillaise et symboles républicains.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007f', 'Réception officielle en préfecture avec remise du décret', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007f', 'Une fête privée', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007f', 'Aucune cérémonie', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000007f', 'Une messe religieuse', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000080', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'MISE_SITUATION',
 'Je découvre que je peux perdre la nationalité française. Dans quels cas ?',
 'La nationalité française peut être retirée en cas de fraude lors de l''acquisition (dans les 2 ans). La déchéance (rare) frappe ceux condamnés pour terrorisme/crimes graves contre la nation, et binationaux ayant acquis la nationalité française.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000080', 'Fraude à l''acquisition ou déchéance pour terrorisme grave', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000080', 'Aucune perte possible', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000080', 'Sur simple décision administrative', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000080', 'À 65 ans automatiquement', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000081', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'MISE_SITUATION',
 'Je veux comprendre l''impact d''un casier judiciaire sur ma demande de nationalité. Quels repères ?',
 'Toute condamnation à au moins 6 mois de prison ferme rend en principe la naturalisation impossible (sauf réhabilitation). Une condamnation pour terrorisme ou crime contre les intérêts de la nation est un obstacle absolu.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000081', 'Condamnation à 6 mois ferme = en principe rejet', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000081', 'Aucune incidence', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000081', 'Avantage pour la demande', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000081', 'Cela accélère la procédure', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000082', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'MISE_SITUATION',
 'Je veux faire reconnaître mes diplômes étrangers en France. À qui m''adresser ?',
 'Le Centre ENIC-NARIC (au sein de France Éducation international) délivre une attestation de comparabilité des diplômes étrangers. Cela facilite l''inscription à une formation ou un emploi.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000082', 'Au centre ENIC-NARIC', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000082', 'Au commissariat', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000082', 'À la mairie uniquement', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000082', 'Au pape', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000083', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'MISE_SITUATION',
 'Je veux comprendre la différence entre nationalité et citoyenneté. Quelle distinction ?',
 'La nationalité est le lien juridique d''une personne avec un État. La citoyenneté est le statut conférant des droits politiques (vote, éligibilité). En France, citoyenneté et nationalité sont généralement liées pour les Français.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000083', 'Nationalité = lien juridique ; Citoyenneté = droits politiques', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000083', 'Aucune différence', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000083', 'La nationalité est temporaire', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000083', 'La citoyenneté est privée', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000084', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'MISE_SITUATION',
 'Je viens d''obtenir la nationalité française. Quels droits nouveaux ?',
 'Le droit de vote à toutes les élections (présidentielle, législatives, etc.), l''éligibilité à tous les mandats électifs, l''accès aux emplois publics réservés aux Français, la protection consulaire française à l''étranger.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000084', 'Vote toutes élections, éligibilité, emplois publics, protection consulaire', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000084', 'Aucun nouveau droit', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000084', 'Uniquement le droit de port d''arme', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000084', 'Uniquement le droit à la santé', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000085', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'MISE_SITUATION',
 'Je veux comprendre ce qu''implique ''l''assimilation à la communauté française'' lors de l''examen pour la nationalité.',
 'L''entretien d''assimilation évalue : connaissance de l''histoire/culture française, adhésion aux valeurs républicaines (laïcité, égalité F/H), maîtrise de la langue, intégration sociale et professionnelle, absence de polygamie.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000085', 'Évaluation langue, valeurs, intégration, connaissance société', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000085', 'Test religieux', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000085', 'Examen militaire', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000085', 'Examen sportif', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000086', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'NAT', 'MISE_SITUATION',
 'Je veux comprendre pourquoi la laïcité est si centrale en France. Quels repères ?',
 'La laïcité est issue de la loi de 1905 (séparation des Églises et de l''État) et est inscrite dans la Constitution (article 1er). Elle garantit la liberté de conscience, la neutralité religieuse de l''État, et l''égalité des citoyens.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000086', 'Loi de 1905, principe constitutionnel, liberté de conscience', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000086', 'Une coutume folklorique', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000086', 'Une obligation religieuse', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000086', 'Un décret récent', FALSE, 3);
