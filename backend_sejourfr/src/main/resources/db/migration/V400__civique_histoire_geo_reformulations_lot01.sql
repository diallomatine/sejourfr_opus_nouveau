-- Flyway: reformulations thème 4 HISTOIRE_GEO lot 1/4 (R01-R12) - is_active=FALSE

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000001', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'En quelle année a commence la Révolution française ?',
 'La Révolution française a commence en 1789, marquée par la prise de la Bastille le 14 juillet 1789 et la Déclaration des droits de l''homme et du citoyen le 26 août 1789.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000001', '1789', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000001', '1815', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000001', '1870', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000001', '1958', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000002', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Qui était Napoléon Bonaparte (Napoléon Ier) ?',
 'Napoléon Bonaparte (1769-1821) fut un général puis empereur des Français (1804-1814 et 1815). Il a rédigé le Code civil, conquis l''Europe et a marqué profondement l''histoire de France.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000002', 'Empereur des Français (1804-1814)', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000002', 'Roi à vie', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000002', 'Président de la République', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000002', 'Cardinal de France', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000003', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Parmi ces personnages historiques, lequel est français ?',
 'Plusieurs personnages français célèbres : Jeanne d''Arc (héroïne du XVe siècle), Napoléon Bonaparte, Charles de Gaulle, Marie Curie (scientifique). Tous ont marqué l''histoire de France.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000003', 'Jeanne d''Arc', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000003', 'Christophe Colomb', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000003', 'Winston Churchill', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000003', 'Albert Einstein', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000004', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Sous quelle République vivons-nous actuellement en France ?',
 'La France vit actuellement sous la Ve République, instauree par la Constitution de 1958 à l''initiative du général de Gaulle.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000004', 'La Ve République (depuis 1958)', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000004', 'La IIIe République', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000004', 'La VIe République', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000004', 'La Ire République', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000005', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Que désigne la Shoah ?',
 'La Shoah designe l''extermination systématique de 6 millions de Juifs (dont 1,5 million d''enfants) par l''Allemagne nazie pendant la Seconde Guerre mondiale (1939-1945).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000005', 'L''extermination des Juifs par les nazis pendant la Seconde Guerre', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000005', 'Une fête religieuse', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000005', 'Une bataille napoleonienne', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000005', 'Un mouvement artistique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000006', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Lequel de ces territoires a été colonise par la France à un moment de son histoire ?',
 'La France a colonise de nombreux territoires : Algerie, Maroc, Tunisie, Indochine (Vietnam), Madagascar, Sénégal, Côté d''Ivoire, Antilles, etc. La plupart sont devenus indépendants au XXe siècle.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000006', 'L''Algerie', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000006', 'Le Royaume-Uni', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000006', 'L''Allemagne', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000006', 'La Russie', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000007', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quel homme politique a rendu l''école obligatoire et laïque à la fin du XIXe siècle ?',
 'Jules Ferry, ministre de l''Instruction publique, a fait voter les lois de 1881-1882 rendant l''école primaire gratuite, laïque et obligatoire pour les enfants de 6 à 13 ans.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000007', 'Jules Ferry', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000007', 'Napoléon Bonaparte', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000007', 'Louis XIV', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000007', 'François Mitterrand', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000008', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'À quelles dates la Seconde Guerre mondiale s''est-elle deroulée ?',
 'La Seconde Guerre mondiale a eu lieu de 1939 à 1945. Elle a opposé les Allies (France, Royaume-Uni, USA, URSS) aux puissances de l''Axe (Allemagne, Italie, Japon).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000008', '1939-1945', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000008', '1914-1918', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000008', '1870-1871', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000008', '1958-1962', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000009', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'À quelles dates la Première Guerre mondiale s''est-elle deroulée ?',
 'La Première Guerre mondiale a eu lieu de 1914 à 1918. Elle a opposé la Triple-Entente (France, Royaume-Uni, Russie, USA en 1917) aux Empires centraux (Allemagne, Autriche-Hongrie).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000009', '1914-1918', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000009', '1939-1945', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000009', '1939-1944', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000009', '1870-1871', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-00000000000a', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'En quelle année a été creée la Communauté économique européenne (CEE) ?',
 'La CEE a été créée en 1957 par le traité de Rome, signé par 6 pays fondateurs (France, Allemagne, Italie, Belgique, Pays-Bas, Luxembourg).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000000a', '1957 (traité de Rome)', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000000a', '1945', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000000a', '1968', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000000a', '1992', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-00000000000b', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Que commemore le 11 novembre, jour ferie en France ?',
 'Le 11 novembre commemore l''armistice de 1918, qui a mis fin à la Première Guerre mondiale. C''est un hommage aux soldats morts pour la France.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000000b', 'L''armistice de la Première Guerre mondiale (1918)', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000000b', 'La Révolution française', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000000b', 'La fin de l''esclavage', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000000b', 'La fête nationale', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-00000000000c', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quel a été le premier président de la Ve République ?',
 'Charles de Gaulle a été le premier président de la Ve République (1959-1969). Il a fondé le régime en 1958, été élu par les grands électeurs en 1958 puis au suffrage universel direct en 1965.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000000c', 'Charles de Gaulle', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000000c', 'Vincent Auriol', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000000c', 'Georges Pompidou', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000000c', 'François Mitterrand', FALSE, 3);
