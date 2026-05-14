-- ============================================================================
-- Flyway : niveau 3 (elargissement) - THEME 2 INSTITUTIONS
-- Lot NAT : 50 questions (40 CONNAISSANCE + 10 MISE_SITUATION)
-- IDs : f2000002-0000-0000-0000-000000000069 a 00000000009a
-- is_active = FALSE
-- ============================================================================

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000069', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Qui a redige le projet de Constitution de la Ve Republique adopte en 1958 ?',
 'La Constitution de 1958 a ete redigee sous l''autorite de Charles de Gaulle et de Michel Debre (alors garde des sceaux), avec l''aide de juristes comme Rene Cassin.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000069', 'Charles de Gaulle et Michel Debre', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000069', 'Napoleon III', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000069', 'Robespierre', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000069', 'Francois Mitterrand', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000006a', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Pourquoi la IVe Republique a-t-elle pris fin en 1958 ?',
 'La IVe Republique souffrait d''instabilite gouvernementale chronique et a ete renversee par la crise algerienne de mai 1958, ouvrant la voie a la Ve Republique avec de Gaulle.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000006a', 'Crise algerienne et instabilite chronique', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000006a', 'Une invasion etrangere', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000006a', 'Un referendum europeen', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000006a', 'Un attentat contre le president', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000006b', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'En quelle annee le quinquennat presidentiel a-t-il remplace le septennat ?',
 'Le quinquennat a remplace le septennat suite au referendum du 24 septembre 2000. Le premier president elu pour 5 ans a ete Jacques Chirac en 2002.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000006b', 'En 2000', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000006b', 'En 1958', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000006b', 'En 1981', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000006b', 'En 2017', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000006c', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Qui a ete le premier president de la Ve Republique elu au suffrage universel direct ?',
 'Charles de Gaulle a ete le premier president elu au suffrage universel direct en 1965, apres la revision constitutionnelle de 1962.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000006c', 'Charles de Gaulle (1965)', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000006c', 'Vincent Auriol', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000006c', 'Francois Mitterrand', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000006c', 'Georges Pompidou', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000006d', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Quel referendum de 1962 a transforme l''election du president ?',
 'Le referendum du 28 octobre 1962 a instaure l''election du president au suffrage universel direct, sur l''initiative de Charles de Gaulle.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000006d', 'Le referendum de 1962 sur le suffrage direct', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000006d', 'Le referendum sur l''Algerie', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000006d', 'Le referendum sur Maastricht', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000006d', 'Le referendum sur l''euro', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000006e', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Que signifie l''expression ''cohabitation'' en politique francaise ?',
 'La cohabitation designe la situation ou le president de la Republique et le Premier ministre appartiennent a des bords politiques opposes. Trois cohabitations ont eu lieu : 1986-88, 1993-95, 1997-2002.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000006e', 'President et Premier ministre de bords opposes', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000006e', 'Deux presidents simultanes', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000006e', 'Un partage de l''Elysee', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000006e', 'Un meeting commun', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000006f', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Quel article permet au president d''exercer des pouvoirs exceptionnels en cas de crise grave ?',
 'L''article 16 de la Constitution autorise le president, en cas de menace grave et immediate sur les institutions, a prendre des mesures exceptionnelles. Il n''a ete utilise qu''une fois, en 1961 par de Gaulle.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000006f', 'L''article 16', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000006f', 'L''article 49', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000006f', 'L''article 89', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000006f', 'L''article 1er', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000070', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Combien de fois l''article 16 de la Constitution a-t-il ete utilise depuis 1958 ?',
 'L''article 16 (pouvoirs exceptionnels) n''a ete applique qu''une seule fois, par Charles de Gaulle du 23 avril au 29 septembre 1961, lors du putsch des generaux a Alger.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000070', 'Une seule fois (en 1961)', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000070', 'Jamais', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000070', 'Dix fois', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000070', 'A chaque crise', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000071', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Quelle revision constitutionnelle de 2008 a renforce le role du Parlement ?',
 'La revision constitutionnelle du 23 juillet 2008 a renforce le Parlement (controle de l''ordre du jour partiellement partage, encadrement du 49.3, creation de la QPC) et limite le president (2 mandats consecutifs maximum).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000071', 'La revision constitutionnelle du 23 juillet 2008', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000071', 'La revision de 1962', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000071', 'La revision de 1992', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000071', 'Aucune revision n''a renforce le Parlement', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000072', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Quel principe limite a deux le nombre de mandats consecutifs du president ?',
 'Depuis la revision de 2008 (article 6 de la Constitution), nul ne peut exercer plus de deux mandats consecutifs comme president de la Republique.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000072', 'Deux mandats consecutifs maximum (article 6)', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000072', 'Aucune limite', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000072', 'Trois mandats consecutifs', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000072', 'Cinq mandats consecutifs', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000073', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Qui peut saisir le Conseil constitutionnel sur une loi avant sa promulgation ?',
 'Le Conseil constitutionnel peut etre saisi par : le president de la Republique, le Premier ministre, les presidents de l''Assemblee et du Senat, ou 60 deputes / 60 senateurs.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000073', 'Le president, le PM, les presidents des chambres, 60 parlementaires', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000073', 'N''importe quel citoyen seul', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000073', 'Uniquement le pape', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000073', 'Uniquement les magistrats', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000074', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Combien de membres compte le Conseil constitutionnel ?',
 'Le Conseil constitutionnel compte 9 membres nommes (3 par le president, 3 par le president de l''Assemblee, 3 par le president du Senat), plus les anciens presidents de la Republique de droit.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000074', '9 membres nommes (plus les anciens presidents de droit)', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000074', '27 membres elus', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000074', '100 membres', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000074', '1 seul juge', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000075', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Pour quelle duree sont nommes les membres du Conseil constitutionnel ?',
 'Les membres nommes du Conseil constitutionnel sont designes pour 9 ans, non renouvelables. Le Conseil est renouvele par tiers tous les 3 ans.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000075', '9 ans non renouvelables', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000075', 'A vie', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000075', '5 ans renouvelables', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000075', '1 an', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000076', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Comment s''appelle l''organe qui juge le president en cas de manquement grave a ses devoirs ?',
 'La Haute Cour, composee des membres du Parlement (Assemblee + Senat), peut destituer le president en cas de manquement incompatible avec l''exercice du mandat (article 68).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000076', 'La Haute Cour', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000076', 'La Cour de cassation', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000076', 'Le tribunal de Paris', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000076', 'Le conseil municipal', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000077', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'La revision constitutionnelle peut-elle modifier le caractere republicain de la France ?',
 'Non. L''article 89 de la Constitution interdit toute revision portant atteinte a la forme republicaine du gouvernement. C''est l''une des ''clauses d''eternite'' de la Constitution.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000077', 'Non, la forme republicaine est intouchable', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000077', 'Oui, par referendum', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000077', 'Oui, avec accord du pape', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000077', 'Oui, en cas de guerre', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000078', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Quel organe gere la carriere et la discipline des magistrats ?',
 'Le Conseil superieur de la magistrature (CSM) gere la nomination, l''avancement et la discipline des magistrats. Il garantit leur independance.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000078', 'Le Conseil superieur de la magistrature (CSM)', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000078', 'Le ministre de la Justice seul', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000078', 'Le maire de Paris', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000078', 'Le president seul', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000079', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Quelle est la difference principale entre un magistrat du siege et un magistrat du parquet ?',
 'Les magistrats du siege jugent (juges, presidents de tribunaux), les magistrats du parquet poursuivent les infractions au nom de la societe (procureurs, substituts). Tous deux relevent de l''autorite judiciaire.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000079', 'Le siege juge, le parquet poursuit au nom de la societe', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000079', 'Aucune difference', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000079', 'Le siege paie, le parquet recoit', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000079', 'Le siege est elu, le parquet est nomme', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000007a', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Qu''est-ce que l''ordre administratif distingue de l''ordre judiciaire ?',
 'L''ordre administratif (Conseil d''Etat, tribunaux administratifs) juge les litiges impliquant l''administration. L''ordre judiciaire juge les litiges entre particuliers et les affaires penales.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000007a', 'L''ordre administratif juge les litiges avec l''administration', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000007a', 'Aucune distinction', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000007a', 'L''ordre administratif juge les crimes', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000007a', 'L''ordre administratif est europeen', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000007b', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Quel est le role du procureur de la Republique ?',
 'Le procureur de la Republique dirige les enquetes penales, decide des poursuites contre les auteurs presumes d''infractions et requiert l''application de la loi devant les tribunaux.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000007b', 'Diriger les enquetes et engager les poursuites penales', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000007b', 'Voter les lois', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000007b', 'Diriger la commune', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000007b', 'Nommer le president', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000007c', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Qu''est-ce qu''une ''loi organique'' en droit francais ?',
 'Une loi organique precise l''organisation et le fonctionnement des pouvoirs publics. Elle est adoptee selon une procedure renforcee et est soumise obligatoirement au controle du Conseil constitutionnel.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000007c', 'Une loi precisant l''organisation des pouvoirs publics', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000007c', 'Une loi religieuse', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000007c', 'Une loi sur les organes humains', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000007c', 'Un decret du maire', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000007d', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Quelle est la difference entre un decret et une loi ?',
 'La loi est votee par le Parlement, le decret est pris par le pouvoir executif (president ou Premier ministre). Les decrets precisent l''application des lois ou interviennent dans le domaine reglementaire.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000007d', 'La loi est votee par le Parlement, le decret est pris par l''executif', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000007d', 'Aucune difference', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000007d', 'Le decret est superieur a la loi', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000007d', 'La loi est religieuse, le decret est civil', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000007e', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'La Constitution prevoit-elle un partage entre domaine de la loi et domaine du reglement ?',
 'Oui. L''article 34 enumere les domaines reserves au Parlement (lois). L''article 37 confie au gouvernement les autres domaines (reglements).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000007e', 'Oui, articles 34 (loi) et 37 (reglement)', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000007e', 'Non, tout est legislatif', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000007e', 'Non, tout est reglementaire', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000007e', 'Uniquement en Belgique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000007f', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Quelle institution europeenne represente les gouvernements des Etats membres ?',
 'Le Conseil de l''Union europeenne (a distinguer du Conseil europeen, qui reunit les chefs d''Etat) reunit les ministres specialises de chaque pays membre. Il vote les lois avec le Parlement europeen.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000007f', 'Le Conseil de l''Union europeenne', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000007f', 'Le Parlement europeen', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000007f', 'La Commission europeenne', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000007f', 'La Cour de justice', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000080', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Qui siege au Conseil europeen ?',
 'Le Conseil europeen reunit les chefs d''Etat et de gouvernement des 27 pays membres, plus le president de la Commission et son president permanent. Il fixe les grandes orientations de l''UE.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000080', 'Les chefs d''Etat et de gouvernement des 27 pays', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000080', 'Les maires des grandes villes europeennes', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000080', 'Des deputes tires au sort', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000080', 'Uniquement des Francais', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000081', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Quelle est la difference entre un reglement et une directive europeens ?',
 'Le reglement europeen s''applique directement dans tous les Etats membres sans transposition. La directive fixe des objectifs et laisse les Etats libres des moyens, avec un delai de transposition en droit national.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000081', 'Le reglement s''applique directement, la directive doit etre transposee', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000081', 'Aucune difference', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000081', 'Le reglement est francais, la directive europeenne', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000081', 'Le reglement est militaire, la directive civile', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000082', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Comment une revision de la Constitution peut-elle aboutir ?',
 'Une revision constitutionnelle est adoptee par les deux chambres du Parlement, puis ratifiee soit par referendum, soit par le Congres (Parlement reuni a Versailles) a la majorite des 3/5e.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000082', 'Vote des deux chambres + referendum ou Congres aux 3/5e', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000082', 'Decision du seul president', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000082', 'Decret du gouvernement', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000082', 'Vote des maires', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000083', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Quel article de la Constitution organise la revision constitutionnelle ?',
 'L''article 89 organise la procedure de revision de la Constitution. Il prevoit le vote des deux chambres puis le referendum ou le Congres.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000083', 'L''article 89', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000083', 'L''article 11', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000083', 'L''article 16', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000083', 'L''article 1er', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000084', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Une loi votee par le Parlement entre-t-elle en vigueur immediatement ?',
 'Non. Une fois la loi votee, le president dispose de 15 jours pour la promulguer. Elle entre en vigueur apres sa publication au Journal officiel, parfois apres parution des decrets d''application.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000084', 'Non, elle doit etre promulguee et publiee au Journal officiel', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000084', 'Oui, immediatement au vote', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000084', 'Apres 1 an obligatoirement', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000084', 'Apres accord du pape', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000085', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Le president peut-il refuser de promulguer une loi ?',
 'Non, il doit la promulguer dans les 15 jours. Il peut cependant demander une nouvelle deliberation au Parlement, ou saisir le Conseil constitutionnel pour controle.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000085', 'Non, mais il peut demander une nouvelle deliberation ou saisir le Conseil constitutionnel', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000085', 'Oui, sans condition', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000085', 'Oui, par referendum', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000085', 'Oui, en cas de guerre', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000086', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Quel est le delai standard pour saisir le Conseil constitutionnel apres le vote d''une loi ?',
 'La saisine doit intervenir dans le delai de 15 jours qui suivent la promulgation possible, c''est-a-dire avant que le president ne signe la loi.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000086', 'Dans les 15 jours avant promulgation', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000086', '1 an apres', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000086', 'Jamais', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000086', '10 ans apres', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000087', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Qu''est-ce qu''un referendum d''initiative partagee ?',
 'Le referendum d''initiative partagee (RIP), cree en 2008, permet l''organisation d''un referendum a la demande d''1/5e des parlementaires soutenus par 10% des electeurs inscrits.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000087', 'Referendum lance par parlementaires + 10% des electeurs', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000087', 'Referendum local de quartier', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000087', 'Vote informatique uniquement', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000087', 'Sondage televise', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000088', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Combien y a-t-il eu de referendums sous la Ve Republique ?',
 'Sous la Ve Republique, environ 10 referendums ont ete organises au niveau national, sur des sujets tels que l''Algerie, l''election du president, l''Europe, le quinquennat ou les traites europeens.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000088', 'Environ 10 referendums depuis 1958', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000088', 'Aucun referendum', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000088', 'Plus de 100', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000088', 'Un seul referendum', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000089', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'En quoi consiste le ''controle a posteriori'' des lois ?',
 'Le controle a posteriori, par voie de Question prioritaire de constitutionnalite (QPC), permet de contester une loi deja en vigueur si elle porte atteinte aux droits constitutionnels. Cree en 2008.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000089', 'Contestation d''une loi en vigueur via QPC (2008)', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000089', 'Reecriture spontanee d''une loi', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000089', 'Verification annuelle par l''ONU', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000089', 'Sondage des citoyens', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000008a', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Quel est le principe d''autonomie financiere des collectivites territoriales ?',
 'Les collectivites territoriales (communes, departements, regions) disposent d''une part de ressources propres et peuvent fixer le taux de certains impots locaux dans les limites de la loi (article 72-2 de la Constitution).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000008a', 'Les collectivites disposent de ressources propres et peuvent fixer certains impots', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000008a', 'Tout est decide par l''Etat', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000008a', 'Aucune autonomie financiere', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000008a', 'Elles depossedent l''Etat', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000008b', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Quelle institution gere les finances et le budget de l''Etat ?',
 'Le budget de l''Etat est prepare par le gouvernement (ministere de l''Economie et des Finances), vote par le Parlement chaque automne, et son execution est controlee par la Cour des comptes.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000008b', 'Prepare par le gouvernement, vote par le Parlement, controle par la Cour des comptes', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000008b', 'Decide par le pape', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000008b', 'Vote par les maires', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000008b', 'Aucun budget officiel', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000008c', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Quelle institution evalue l''execution des politiques publiques et les comptes de l''Etat ?',
 'La Cour des comptes est une juridiction financiere independante qui controle l''usage des fonds publics et publie des rapports souvent commentes dans le debat public.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000008c', 'La Cour des comptes', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000008c', 'Le Conseil constitutionnel', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000008c', 'L''Assemblee nationale seule', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000008c', 'L''ONU', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000008d', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Le mediateur entre l''administration et les citoyens existe-t-il sous une forme officielle en France ?',
 'Oui, c''est le Defenseur des droits, autorite constitutionnelle independante (depuis 2011) qui defend les droits et libertes des citoyens face aux administrations et lutte contre les discriminations.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000008d', 'Oui, le Defenseur des droits', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000008d', 'Non, il n''existe pas', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000008d', 'Uniquement les avocats', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000008d', 'Uniquement le pape', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000008e', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Quel principe constitutionnel garantit l''egal acces des femmes et des hommes aux mandats electifs ?',
 'Le principe de parite, inscrit dans la Constitution depuis 1999 (article 1er, alinea 2), impose aux partis politiques de favoriser l''egal acces des femmes et des hommes aux mandats et fonctions electives.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000008e', 'La parite (inscrite dans la Constitution en 1999)', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000008e', 'Le quota religieux', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000008e', 'La hierarchie par age', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000008e', 'Aucun principe particulier', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000008f', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Quel principe encadre le financement des campagnes electorales en France ?',
 'Les campagnes electorales sont strictement encadrees : plafond de depenses, interdiction des dons d''entreprises depuis 1995, remboursement partiel par l''Etat, controle par la Commission nationale des comptes de campagne.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000008f', 'Plafonnement des depenses et controle public', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000008f', 'Aucune regle, c''est libre', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000008f', 'Financement uniquement religieux', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000008f', 'Financement uniquement etranger', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000090', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Que prevoit la loi pour assurer la transparence de la vie publique ?',
 'Depuis 2013, les elus et hauts responsables doivent declarer leur patrimoine et leurs interets a la Haute Autorite pour la transparence de la vie publique (HATVP), qui controle d''eventuels conflits d''interets.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000090', 'Declarations de patrimoine et d''interets a la HATVP', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000090', 'Rien n''est prevu', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000090', 'Uniquement pour le president', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000090', 'Declarations religieuses', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000091', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'MISE_SITUATION',
 'Un president sortant a deja effectue deux mandats consecutifs. Peut-il se representer immediatement apres ?',
 'Non. Depuis la revision de 2008 (article 6), un president ne peut pas exercer plus de deux mandats consecutifs. Il devra attendre au moins un mandat avant de se representer.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000091', 'Non, il faut attendre au moins un mandat avant de se representer', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000091', 'Oui, immediatement', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000091', 'Oui, mais pour 3 ans', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000091', 'Non, jamais a vie', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000092', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'MISE_SITUATION',
 'Une loi votee me semble priver d''un droit fondamental. Avant promulgation, qui peut saisir le Conseil constitutionnel ?',
 'Un citoyen seul ne peut pas saisir directement. Mais 60 deputes ou 60 senateurs peuvent saisir le Conseil dans les 15 jours suivant l''adoption de la loi. Apres promulgation, il reste la QPC.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000092', '60 deputes ou 60 senateurs (avant promulgation), QPC apres', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000092', 'N''importe quel citoyen seul', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000092', 'Uniquement le president', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000092', 'Uniquement le pape', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000093', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'MISE_SITUATION',
 'Le president veut organiser un referendum sur une question economique. En a-t-il le pouvoir ?',
 'L''article 11 permet au president de soumettre au referendum un projet de loi portant sur l''organisation des pouvoirs publics, des reformes economiques, sociales ou environnementales, ou la ratification d''un traite.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000093', 'Oui, l''article 11 le permet pour les reformes economiques et sociales', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000093', 'Non, jamais', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000093', 'Oui, sur toute question sans limite', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000093', 'Uniquement avec accord du pape', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000094', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'MISE_SITUATION',
 'Un depute francais peut-il sieger simultanement au Senat ?',
 'Non. Les mandats parlementaires sont incompatibles entre eux : on ne peut pas etre depute et senateur en meme temps. La loi limite aussi le cumul des mandats locaux.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000094', 'Non, les mandats parlementaires sont incompatibles', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000094', 'Oui, sans aucune limite', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000094', 'Uniquement les week-ends', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000094', 'Uniquement les femmes', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000095', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'MISE_SITUATION',
 'Un parti politique recoit des financements etrangers importants. Que dit le droit ?',
 'Les partis politiques francais ne peuvent recevoir aucune contribution ou aide materielle directe ou indirecte d''un Etat etranger ou d''une personne morale de droit etranger. C''est interdit par la loi.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000095', 'C''est interdit par la loi sur le financement des partis', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000095', 'C''est autorise sans limite', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000095', 'Uniquement avec accord du pape', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000095', 'Uniquement avant les elections', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000096', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'MISE_SITUATION',
 'Une commune ne respecte pas un jugement du tribunal administratif. Que peut-on faire ?',
 'Le requerant peut demander au tribunal administratif d''ordonner l''execution sous astreinte (somme due par jour de retard). Le prefet peut aussi se substituer a la commune dans certains cas.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000096', 'Demander l''execution sous astreinte au tribunal', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000096', 'Rien faire', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000096', 'Forcer l''execution manu militari', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000096', 'Quitter la commune', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000097', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'MISE_SITUATION',
 'Le president signe un traite international sans autorisation parlementaire pour un traite important. Est-ce legal ?',
 'Non. Les traites importants (qui modifient des dispositions legislatives, engagent les finances, affectent l''etat des personnes, cedent ou echangent du territoire) doivent etre autorises par une loi (article 53).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000097', 'Non, certains traites doivent etre autorises par une loi (article 53)', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000097', 'Oui, sans condition', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000097', 'Uniquement pour les traites militaires', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000097', 'Uniquement avec accord du pape', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000098', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'MISE_SITUATION',
 'Un ministre prend une decision contraire a une directive europeenne. Quels recours sont possibles ?',
 'Le droit europeen prime sur le droit national. Un acte contraire peut etre conteste devant le juge administratif francais (Conseil d''Etat). La Commission europeenne peut aussi engager une procedure d''infraction contre la France.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000098', 'Recours administratif francais + procedure d''infraction europeenne', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000098', 'Aucun recours possible', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000098', 'Demander un referendum europeen', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000098', 'Saisir le pape', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-000000000099', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'MISE_SITUATION',
 'Le president souhaite dissoudre l''Assemblee nationale. Y a-t-il des limites ?',
 'Oui. L''article 12 permet la dissolution apres consultation du Premier ministre et des presidents des chambres. Mais il ne peut y avoir de nouvelle dissolution dans l''annee qui suit ces elections.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000099', 'Oui, pas de seconde dissolution dans l''annee suivant les elections', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000099', 'Aucune limite', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000099', 'Uniquement le 14 juillet', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-000000000099', 'Uniquement en cas de guerre', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000002-0000-0000-0000-00000000009a', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'MISE_SITUATION',
 'Une personne souhaite obtenir une information detenue par une administration mais celle-ci refuse. Quel recours ?',
 'La Commission d''acces aux documents administratifs (CADA) peut etre saisie en cas de refus. Elle donne un avis non contraignant ; le tribunal administratif peut ensuite etre saisi.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000009a', 'Saisir la CADA puis le tribunal administratif', TRUE, 0),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000009a', 'Forcer la porte', FALSE, 1),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000009a', 'Rien faire', FALSE, 2),
(gen_random_uuid(), 'f2000002-0000-0000-0000-00000000009a', 'Saisir l''OTAN', FALSE, 3);
