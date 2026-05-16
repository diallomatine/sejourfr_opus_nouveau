-- ============================================================================
-- Flyway : niveau 3 (élargissement) - THÈME 2 INSTITUTIONS
-- Lot NAT : 50 questions (40 CONNAISSANCE + 10 MISE_SITUATION)
-- IDs : f2000002-0000-0000-0000-000000000069 à 00000000009a
-- is_active = FALSE
-- ============================================================================

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000069', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Qui a rédigé le projet de Constitution de la Ve République adopté en 1958 ?',
 'La Constitution de 1958 a été rédigée sous l''autorité de Charles de Gaulle et de Michel Debré (alors garde des sceaux), avec l''aide de juristes comme René Cassin.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000069', 'Charles de Gaulle et Michel Debré', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000069', 'Napoléon III', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000069', 'Robespierre', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000069', 'François Mitterrand', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000006a', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Pourquoi la IVe République a-t-elle pris fin en 1958 ?',
 'La IVe République souffrait d''instabilité gouvernementale chronique et a été renversée par la crise algérienne de mai 1958, ouvrant la voie à la Ve République avec de Gaulle.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000006a', 'Crise algérienne et instabilité chronique', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000006a', 'Une invasion étrangère', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000006a', 'Un référendum européen', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000006a', 'Un attentat contre le président', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000006b', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'En quelle année le quinquennat présidentiel a-t-il remplacé le septennat ?',
 'Le quinquennat a remplacé le septennat suite au référendum du 24 septembre 2000. Le premier président élu pour 5 ans a été Jacques Chirac en 2002.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000006b', 'En 2000', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000006b', 'En 1958', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000006b', 'En 1981', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000006b', 'En 2017', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000006c', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Qui a été le premier président de la Ve République élu au suffrage universel direct ?',
 'Charles de Gaulle a été le premier président élu au suffrage universel direct en 1965, après la révision constitutionnelle de 1962.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000006c', 'Charles de Gaulle (1965)', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000006c', 'Vincent Auriol', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000006c', 'François Mitterrand', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000006c', 'Georges Pompidou', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000006d', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Quel référendum de 1962 a transformé l''élection du président ?',
 'Le référendum du 28 octobre 1962 a instauré l''élection du président au suffrage universel direct, sur l''initiative de Charles de Gaulle.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000006d', 'Le référendum de 1962 sur le suffrage direct', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000006d', 'Le référendum sur l''Algérie', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000006d', 'Le référendum sur Maastricht', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000006d', 'Le référendum sur l''euro', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000006e', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Que signifie l''expression ''cohabitation'' en politique française ?',
 'La cohabitation désigne la situation où le président de la République et le Premier ministre appartiennent à des bords politiques opposés. Trois cohabitations ont eu lieu : 1986-88, 1993-95, 1997-2002.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000006e', 'Président et Premier ministre de bords opposés', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000006e', 'Deux présidents simultanés', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000006e', 'Un partage de l''Élysée', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000006e', 'Un meeting commun', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000006f', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Quel article permet au président d''exercer des pouvoirs exceptionnels en cas de crise grave ?',
 'L''article 16 de la Constitution autorise le président, en cas de menace grave et immédiate sur les institutions, à prendre des mesures exceptionnelles. Il n''a été utilisé qu''une fois, en 1961 par de Gaulle.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000006f', 'L''article 16', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000006f', 'L''article 49', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000006f', 'L''article 89', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000006f', 'L''article 1er', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000070', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Combien de fois l''article 16 de la Constitution a-t-il été utilisé depuis 1958 ?',
 'L''article 16 (pouvoirs exceptionnels) n''a été appliqué qu''une seule fois, par Charles de Gaulle du 23 avril au 29 septembre 1961, lors du putsch des généraux à Alger.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000070', 'Une seule fois (en 1961)', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000070', 'Jamais', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000070', 'Dix fois', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000070', 'À chaque crise', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000071', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Quelle révision constitutionnelle de 2008 a renforcé le rôle du Parlement ?',
 'La révision constitutionnelle du 23 juillet 2008 a renforcé le Parlement (contrôle de l''ordre du jour partiellement partagé, encadrement du 49.3, création de la QPC) et limite le président (2 mandats consécutifs maximum).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000071', 'La révision constitutionnelle du 23 juillet 2008', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000071', 'La révision de 1962', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000071', 'La révision de 1992', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000071', 'Aucune révision n''a renforcé le Parlement', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000072', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Quel principe limite à deux le nombre de mandats consécutifs du président ?',
 'Depuis la révision de 2008 (article 6 de la Constitution), nul ne peut exercer plus de deux mandats consécutifs comme président de la République.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000072', 'Deux mandats consécutifs maximum (article 6)', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000072', 'Aucune limite', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000072', 'Trois mandats consécutifs', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000072', 'Cinq mandats consécutifs', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000073', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Qui peut saisir le Conseil constitutionnel sur une loi avant sa promulgation ?',
 'Le Conseil constitutionnel peut être saisi par : le président de la République, le Premier ministre, les présidents de l''Assemblée et du Sénat, ou 60 députés / 60 sénateurs.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000073', 'Le président, le PM, les présidents des chambres, 60 parlementaires', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000073', 'N''importe quel citoyen seul', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000073', 'Uniquement le pape', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000073', 'Uniquement les magistrats', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000074', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Combien de membres compte le Conseil constitutionnel ?',
 'Le Conseil constitutionnel compte 9 membres nommés (3 par le président, 3 par le président de l''Assemblée, 3 par le président du Sénat), plus les anciens présidents de la République de droit.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000074', '9 membres nommés (plus les anciens présidents de droit)', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000074', '27 membres élus', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000074', '100 membres', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000074', '1 seul juge', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000075', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Pour quelle durée sont nommés les membres du Conseil constitutionnel ?',
 'Les membres nommés du Conseil constitutionnel sont désignés pour 9 ans, non renouvelables. Le Conseil est renouvelé par tiers tous les 3 ans.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000075', '9 ans non renouvelables', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000075', 'À vie', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000075', '5 ans renouvelables', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000075', '1 an', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000076', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Comment s''appelle l''organe qui juge le président en cas de manquement grave à ses devoirs ?',
 'La Haute Cour, composée des membres du Parlement (Assemblée + Sénat), peut destituer le président en cas de manquement incompatible avec l''exercice du mandat (article 68).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000076', 'La Haute Cour', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000076', 'La Cour de cassation', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000076', 'Le tribunal de Paris', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000076', 'Le conseil municipal', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000077', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'La révision constitutionnelle peut-elle modifier le caractère républicain de la France ?',
 'Non. L''article 89 de la Constitution interdit toute révision portant atteinte à la forme républicaine du gouvernement. C''est l''une des ''clauses d''éternité'' de la Constitution.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000077', 'Non, la forme républicaine est intouchable', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000077', 'Oui, par référendum', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000077', 'Oui, avec accord du pape', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000077', 'Oui, en cas de guerre', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000078', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Quel organe gère la carrière et la discipline des magistrats ?',
 'Le Conseil supérieur de la magistrature (CSM) gère la nomination, l''avancement et la discipline des magistrats. Il garantit leur indépendance.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000078', 'Le Conseil supérieur de la magistrature (CSM)', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000078', 'Le ministre de la Justice seul', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000078', 'Le maire de Paris', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000078', 'Le président seul', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000079', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Quelle est la différence principale entre un magistrat du siège et un magistrat du parquet ?',
 'Les magistrats du siège jugent (juges, présidents de tribunaux), les magistrats du parquet poursuivent les infractions au nom de la société (procureurs, substituts). Tous deux relèvent de l''autorité judiciaire.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000079', 'Le siège juge, le parquet poursuit au nom de la société', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000079', 'Aucune différence', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000079', 'Le siège paie, le parquet reçoit', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000079', 'Le siège est élu, le parquet est nommé', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000007a', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Qu''est-ce que l''ordre administratif distingue de l''ordre judiciaire ?',
 'L''ordre administratif (Conseil d''État, tribunaux administratifs) juge les litiges impliquant l''administration. L''ordre judiciaire juge les litiges entre particuliers et les affaires pénales.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000007a', 'L''ordre administratif juge les litiges avec l''administration', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000007a', 'Aucune distinction', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000007a', 'L''ordre administratif juge les crimes', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000007a', 'L''ordre administratif est européen', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000007b', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Quel est le rôle du procureur de la République ?',
 'Le procureur de la République dirige les enquêtes pénales, décide des poursuites contre les auteurs présumés d''infractions et requiert l''application de la loi devant les tribunaux.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000007b', 'Diriger les enquêtes et engager les poursuites pénales', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000007b', 'Voter les lois', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000007b', 'Diriger la commune', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000007b', 'Nommer le président', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000007c', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Qu''est-ce qu''une ''loi organique'' en droit français ?',
 'Une loi organique précise l''organisation et le fonctionnement des pouvoirs publics. Elle est adoptée selon une procédure renforcée et est soumise obligatoirement au contrôle du Conseil constitutionnel.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000007c', 'Une loi précisant l''organisation des pouvoirs publics', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000007c', 'Une loi religieuse', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000007c', 'Une loi sur les organes humains', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000007c', 'Un décret du maire', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000007d', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Quelle est la différence entre un décret et une loi ?',
 'La loi est votée par le Parlement, le décret est pris par le pouvoir exécutif (président ou Premier ministre). Les décrets précisent l''application des lois ou interviennent dans le domaine réglementaire.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000007d', 'La loi est votée par le Parlement, le décret est pris par l''exécutif', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000007d', 'Aucune différence', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000007d', 'Le décret est supérieur à la loi', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000007d', 'La loi est religieuse, le décret est civil', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000007e', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'La Constitution prévoit-elle un partage entre domaine de la loi et domaine du règlement ?',
 'Oui. L''article 34 énumère les domaines réservés au Parlement (lois). L''article 37 confie au gouvernement les autres domaines (règlements).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000007e', 'Oui, articles 34 (loi) et 37 (règlement)', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000007e', 'Non, tout est législatif', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000007e', 'Non, tout est réglementaire', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000007e', 'Uniquement en Belgique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000007f', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Quelle institution européenne représente les gouvernements des États membres ?',
 'Le Conseil de l''Union européenne (à distinguer du Conseil européen, qui réunit les chefs d''État) réunit les ministres spécialisés de chaque pays membre. Il vote les lois avec le Parlement européen.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000007f', 'Le Conseil de l''Union européenne', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000007f', 'Le Parlement européen', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000007f', 'La Commission européenne', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000007f', 'La Cour de justice', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000080', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Qui siège au Conseil européen ?',
 'Le Conseil européen réunit les chefs d''État et de gouvernement des 27 pays membres, plus le président de la Commission et son président permanent. Il fixe les grandes orientations de l''UE.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000080', 'Les chefs d''État et de gouvernement des 27 pays', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000080', 'Les maires des grandes villes européennes', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000080', 'Des députés tirés au sort', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000080', 'Uniquement des Français', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000081', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Quelle est la différence entre un règlement et une directive européens ?',
 'Le règlement européen s''applique directement dans tous les États membres sans transposition. La directive fixe des objectifs et laisse les États libres des moyens, avec un délai de transposition en droit national.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000081', 'Le règlement s''applique directement, la directive doit être transposée', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000081', 'Aucune différence', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000081', 'Le règlement est français, la directive européenne', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000081', 'Le règlement est militaire, la directive civile', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000082', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Comment une révision de la Constitution peut-elle aboutir ?',
 'Une révision constitutionnelle est adoptée par les deux chambres du Parlement, puis ratifiée soit par référendum, soit par le Congrès (Parlement réuni à Versailles) à la majorité des 3/5e.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000082', 'Vote des deux chambres + référendum ou Congrès aux 3/5e', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000082', 'Décision du seul président', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000082', 'Décret du gouvernement', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000082', 'Vote des maires', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000083', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Quel article de la Constitution organise la révision constitutionnelle ?',
 'L''article 89 organise la procédure de révision de la Constitution. Il prévoit le vote des deux chambres puis le référendum ou le Congrès.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000083', 'L''article 89', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000083', 'L''article 11', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000083', 'L''article 16', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000083', 'L''article 1er', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000084', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Une loi votée par le Parlement entre-t-elle en vigueur immédiatement ?',
 'Non. Une fois la loi votée, le président dispose de 15 jours pour la promulguer. Elle entre en vigueur après sa publication au Journal officiel, parfois après parution des décrets d''application.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000084', 'Non, elle doit être promulguée et publiée au Journal officiel', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000084', 'Oui, immédiatement au vote', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000084', 'Après 1 an obligatoirement', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000084', 'Après accord du pape', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000085', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Le président peut-il refuser de promulguer une loi ?',
 'Non, il doit la promulguer dans les 15 jours. Il peut cependant demander une nouvelle délibération au Parlement, ou saisir le Conseil constitutionnel pour contrôle.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000085', 'Non, mais il peut demander une nouvelle délibération ou saisir le Conseil constitutionnel', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000085', 'Oui, sans condition', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000085', 'Oui, par référendum', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000085', 'Oui, en cas de guerre', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000086', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Quel est le délai standard pour saisir le Conseil constitutionnel après le vote d''une loi ?',
 'La saisine doit intervenir dans le délai de 15 jours qui suivent la promulgation possible, c''est-à-dire avant que le président ne signe la loi.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000086', 'Dans les 15 jours avant promulgation', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000086', '1 an après', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000086', 'Jamais', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000086', '10 ans après', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000087', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Qu''est-ce qu''un référendum d''initiative partagée ?',
 'Le référendum d''initiative partagée (RIP), créé en 2008, permet l''organisation d''un référendum à la demande d''1/5e des parlementaires soutenus par 10% des électeurs inscrits.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000087', 'Référendum lancé par parlementaires + 10% des électeurs', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000087', 'Référendum local de quartier', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000087', 'Vote informatique uniquement', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000087', 'Sondage télévisé', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000088', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Combien y a-t-il eu de référendums sous la Ve République ?',
 'Sous la Ve République, environ 10 référendums ont été organisés au niveau national, sur des sujets tels que l''Algérie, l''élection du président, l''Europe, le quinquennat ou les traités européens.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000088', 'Environ 10 référendums depuis 1958', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000088', 'Aucun référendum', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000088', 'Plus de 100', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000088', 'Un seul référendum', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000089', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'En quoi consiste le ''contrôle a posteriori'' des lois ?',
 'Le contrôle a posteriori, par voie de Question prioritaire de constitutionnalité (QPC), permet de contester une loi déjà en vigueur si elle porte atteinte aux droits constitutionnels. Créé en 2008.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000089', 'Contestation d''une loi en vigueur via QPC (2008)', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000089', 'Réécriture spontanée d''une loi', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000089', 'Vérification annuelle par l''ONU', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000089', 'Sondage des citoyens', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000008a', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Quel est le principe d''autonomie financière des collectivités territoriales ?',
 'Les collectivités territoriales (communes, départements, régions) disposent d''une part de ressources propres et peuvent fixer le taux de certains impôts locaux dans les limites de la loi (article 72-2 de la Constitution).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000008a', 'Les collectivités disposent de ressources propres et peuvent fixer certains impôts', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000008a', 'Tout est décidé par l''État', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000008a', 'Aucune autonomie financière', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000008a', 'Elles dépossèdent l''État', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000008b', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Quelle institution gère les finances et le budget de l''État ?',
 'Le budget de l''État est préparé par le gouvernement (ministère de l''Économie et des Finances), voté par le Parlement chaque automne, et son exécution est contrôlée par la Cour des comptes.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000008b', 'Préparé par le gouvernement, voté par le Parlement, contrôlé par la Cour des comptes', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000008b', 'Décidé par le pape', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000008b', 'Voté par les maires', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000008b', 'Aucun budget officiel', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000008c', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Quelle institution évalue l''exécution des politiques publiques et les comptes de l''État ?',
 'La Cour des comptes est une juridiction financière indépendante qui contrôle l''usage des fonds publics et publie des rapports souvent commentés dans le débat public.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000008c', 'La Cour des comptes', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000008c', 'Le Conseil constitutionnel', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000008c', 'L''Assemblée nationale seule', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000008c', 'L''ONU', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000008d', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Le médiateur entre l''administration et les citoyens existe-t-il sous une forme officielle en France ?',
 'Oui, c''est le Défenseur des droits, autorité constitutionnelle indépendante (depuis 2011) qui défend les droits et libertés des citoyens face aux administrations et lutte contre les discriminations.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000008d', 'Oui, le Défenseur des droits', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000008d', 'Non, il n''existe pas', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000008d', 'Uniquement les avocats', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000008d', 'Uniquement le pape', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000008e', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Quel principe constitutionnel garantit l''égal accès des femmes et des hommes aux mandats électifs ?',
 'Le principe de parité, inscrit dans la Constitution depuis 1999 (article 1er, alinéa 2), impose aux partis politiques de favoriser l''égal accès des femmes et des hommes aux mandats et fonctions électives.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000008e', 'La parité (inscrite dans la Constitution en 1999)', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000008e', 'Le quota religieux', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000008e', 'La hiérarchie par âge', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000008e', 'Aucun principe particulier', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000008f', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Quel principe encadre le financement des campagnes électorales en France ?',
 'Les campagnes électorales sont strictement encadrées : plafond de dépenses, interdiction des dons d''entreprises depuis 1995, remboursement partiel par l''État, contrôle par la Commission nationale des comptes de campagne.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000008f', 'Plafonnement des dépenses et contrôle public', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000008f', 'Aucune règle, c''est libre', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000008f', 'Financement uniquement religieux', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000008f', 'Financement uniquement étranger', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000090', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Que prévoit la loi pour assurer la transparence de la vie publique ?',
 'Depuis 2013, les élus et hauts responsables doivent déclarer leur patrimoine et leurs intérêts à la Haute Autorité pour la transparence de la vie publique (HATVP), qui contrôle d''éventuels conflits d''intérêts.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000090', 'Déclarations de patrimoine et d''intérêts à la HATVP', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000090', 'Rien n''est prévu', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000090', 'Uniquement pour le président', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000090', 'Déclarations religieuses', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000091', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'MISE_SITUATION',
 'Un président sortant a déjà effectué deux mandats consécutifs. Peut-il se représenter immédiatement après ?',
 'Non. Depuis la révision de 2008 (article 6), un président ne peut pas exercer plus de deux mandats consécutifs. Il devra attendre au moins un mandat avant de se représenter.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000091', 'Non, il faut attendre au moins un mandat avant de se représenter', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000091', 'Oui, immédiatement', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000091', 'Oui, mais pour 3 ans', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000091', 'Non, jamais à vie', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000092', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'MISE_SITUATION',
 'Une loi votée me semble priver d''un droit fondamental. Avant promulgation, qui peut saisir le Conseil constitutionnel ?',
 'Un citoyen seul ne peut pas saisir directement. Mais 60 députés ou 60 sénateurs peuvent saisir le Conseil dans les 15 jours suivant l''adoption de la loi. Après promulgation, il reste la QPC.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000092', '60 députés ou 60 sénateurs (avant promulgation), QPC après', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000092', 'N''importe quel citoyen seul', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000092', 'Uniquement le président', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000092', 'Uniquement le pape', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000093', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'MISE_SITUATION',
 'Le président veut organiser un référendum sur une question économique. En a-t-il le pouvoir ?',
 'L''article 11 permet au président de soumettre au référendum un projet de loi portant sur l''organisation des pouvoirs publics, des réformes économiques, sociales ou environnementales, ou la ratification d''un traité.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000093', 'Oui, l''article 11 le permet pour les réformes économiques et sociales', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000093', 'Non, jamais', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000093', 'Oui, sur toute question sans limite', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000093', 'Uniquement avec accord du pape', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000094', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'MISE_SITUATION',
 'Un député français peut-il siéger simultanément au Sénat ?',
 'Non. Les mandats parlementaires sont incompatibles entre eux : on ne peut pas être député et sénateur en même temps. La loi limite aussi le cumul des mandats locaux.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000094', 'Non, les mandats parlementaires sont incompatibles', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000094', 'Oui, sans aucune limite', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000094', 'Uniquement les week-ends', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000094', 'Uniquement les femmes', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000095', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'MISE_SITUATION',
 'Un parti politique reçoit des financements étrangers importants. Que dit le droit ?',
 'Les partis politiques français ne peuvent recevoir aucune contribution ou aide matérielle directe ou indirecte d''un État étranger ou d''une personne morale de droit étranger. C''est interdit par la loi.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000095', 'C''est interdit par la loi sur le financement des partis', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000095', 'C''est autorisé sans limite', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000095', 'Uniquement avec accord du pape', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000095', 'Uniquement avant les élections', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000096', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'MISE_SITUATION',
 'Une commune ne respecte pas un jugement du tribunal administratif. Que peut-on faire ?',
 'Le requérant peut demander au tribunal administratif d''ordonner l''exécution sous astreinte (somme due par jour de retard). Le préfet peut aussi se substituer à la commune dans certains cas.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000096', 'Demander l''exécution sous astreinte au tribunal', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000096', 'Rien faire', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000096', 'Forcer l''exécution manu militari', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000096', 'Quitter la commune', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000097', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'MISE_SITUATION',
 'Le président signe un traité international sans autorisation parlementaire pour un traité important. Est-ce légal ?',
 'Non. Les traités importants (qui modifient des dispositions législatives, engagent les finances, affectent l''état des personnes, cèdent ou échangent du territoire) doivent être autorisés par une loi (article 53).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000097', 'Non, certains traités doivent être autorisés par une loi (article 53)', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000097', 'Oui, sans condition', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000097', 'Uniquement pour les traités militaires', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000097', 'Uniquement avec accord du pape', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000098', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'MISE_SITUATION',
 'Un ministre prend une décision contraire à une directive européenne. Quels recours sont possibles ?',
 'Le droit européen prime sur le droit national. Un acte contraire peut être contesté devant le juge administratif français (Conseil d''État). La Commission européenne peut aussi engager une procédure d''infraction contre la France.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000098', 'Recours administratif français + procédure d''infraction européenne', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000098', 'Aucun recours possible', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000098', 'Demander un référendum européen', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000098', 'Saisir le pape', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000099', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'MISE_SITUATION',
 'Le président souhaite dissoudre l''Assemblée nationale. Y a-t-il des limites ?',
 'Oui. L''article 12 permet la dissolution après consultation du Premier ministre et des présidents des chambres. Mais il ne peut y avoir de nouvelle dissolution dans l''année qui suit ces élections.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000099', 'Oui, pas de seconde dissolution dans l''année suivant les élections', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000099', 'Aucune limite', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000099', 'Uniquement le 14 juillet', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000099', 'Uniquement en cas de guerre', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000009a', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'MISE_SITUATION',
 'Une personne souhaite obtenir une information détenue par une administration mais celle-ci refuse. Quel recours ?',
 'La Commission d''accès aux documents administratifs (CADA) peut être saisie en cas de refus. Elle donne un avis non contraignant ; le tribunal administratif peut ensuite être saisi.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000009a', 'Saisir la CADA puis le tribunal administratif', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000009a', 'Forcer la porte', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000009a', 'Rien faire', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000009a', 'Saisir l''OTAN', FALSE, 3);
