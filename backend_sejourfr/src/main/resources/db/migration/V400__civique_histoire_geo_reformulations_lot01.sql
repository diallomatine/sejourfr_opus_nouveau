-- Flyway: reformulations theme 4 HISTOIRE_GEO lot 1/4 (R01-R12) - is_active=FALSE

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000001', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'En quelle annee a commence la Revolution francaise ?',
 'La Revolution francaise a commence en 1789, marquee par la prise de la Bastille le 14 juillet 1789 et la Declaration des droits de l''homme et du citoyen le 26 aout 1789.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000001', '1789', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000001', '1815', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000001', '1870', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000001', '1958', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000002', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Qui etait Napoleon Bonaparte (Napoleon Ier) ?',
 'Napoleon Bonaparte (1769-1821) fut un general puis empereur des Francais (1804-1814 et 1815). Il a redige le Code civil, conquis l''Europe et a marque profondement l''histoire de France.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000002', 'Empereur des Francais (1804-1814)', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000002', 'Roi a vie', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000002', 'President de la Republique', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000002', 'Cardinal de France', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000003', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Parmi ces personnages historiques, lequel est francais ?',
 'Plusieurs personnages francais celebres : Jeanne d''Arc (heroine du XVe siecle), Napoleon Bonaparte, Charles de Gaulle, Marie Curie (scientifique). Tous ont marque l''histoire de France.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000003', 'Jeanne d''Arc', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000003', 'Christophe Colomb', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000003', 'Winston Churchill', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000003', 'Albert Einstein', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000004', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Sous quelle Republique vivons-nous actuellement en France ?',
 'La France vit actuellement sous la Ve Republique, instauree par la Constitution de 1958 a l''initiative du general de Gaulle.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000004', 'La Ve Republique (depuis 1958)', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000004', 'La IIIe Republique', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000004', 'La VIe Republique', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000004', 'La Ire Republique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000005', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Que designe la Shoah ?',
 'La Shoah designe l''extermination systematique de 6 millions de Juifs (dont 1,5 million d''enfants) par l''Allemagne nazie pendant la Seconde Guerre mondiale (1939-1945).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000005', 'L''extermination des Juifs par les nazis pendant la Seconde Guerre', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000005', 'Une fete religieuse', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000005', 'Une bataille napoleonienne', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000005', 'Un mouvement artistique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000006', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Lequel de ces territoires a ete colonise par la France a un moment de son histoire ?',
 'La France a colonise de nombreux territoires : Algerie, Maroc, Tunisie, Indochine (Vietnam), Madagascar, Senegal, Cote d''Ivoire, Antilles, etc. La plupart sont devenus independants au XXe siecle.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000006', 'L''Algerie', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000006', 'Le Royaume-Uni', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000006', 'L''Allemagne', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000006', 'La Russie', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000007', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quel homme politique a rendu l''ecole obligatoire et laique a la fin du XIXe siecle ?',
 'Jules Ferry, ministre de l''Instruction publique, a fait voter les lois de 1881-1882 rendant l''ecole primaire gratuite, laique et obligatoire pour les enfants de 6 a 13 ans.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000007', 'Jules Ferry', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000007', 'Napoleon Bonaparte', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000007', 'Louis XIV', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000007', 'Francois Mitterrand', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000008', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'A quelles dates la Seconde Guerre mondiale s''est-elle deroulee ?',
 'La Seconde Guerre mondiale a eu lieu de 1939 a 1945. Elle a oppose les Allies (France, Royaume-Uni, USA, URSS) aux puissances de l''Axe (Allemagne, Italie, Japon).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000008', '1939-1945', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000008', '1914-1918', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000008', '1870-1871', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000008', '1958-1962', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000009', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'A quelles dates la Premiere Guerre mondiale s''est-elle deroulee ?',
 'La Premiere Guerre mondiale a eu lieu de 1914 a 1918. Elle a oppose la Triple-Entente (France, Royaume-Uni, Russie, USA en 1917) aux Empires centraux (Allemagne, Autriche-Hongrie).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000009', '1914-1918', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000009', '1939-1945', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000009', '1939-1944', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000009', '1870-1871', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-00000000000a', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'En quelle annee a ete creee la Communaute economique europeenne (CEE) ?',
 'La CEE a ete creee en 1957 par le traite de Rome, signe par 6 pays fondateurs (France, Allemagne, Italie, Belgique, Pays-Bas, Luxembourg).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000000a', '1957 (traite de Rome)', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000000a', '1945', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000000a', '1968', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000000a', '1992', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-00000000000b', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Que commemore le 11 novembre, jour ferie en France ?',
 'Le 11 novembre commemore l''armistice de 1918, qui a mis fin a la Premiere Guerre mondiale. C''est un hommage aux soldats morts pour la France.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000000b', 'L''armistice de la Premiere Guerre mondiale (1918)', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000000b', 'La Revolution francaise', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000000b', 'La fin de l''esclavage', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000000b', 'La fete nationale', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-00000000000c', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quel a ete le premier president de la Ve Republique ?',
 'Charles de Gaulle a ete le premier president de la Ve Republique (1959-1969). Il a fonde le regime en 1958, ete elu par les grands electeurs en 1958 puis au suffrage universel direct en 1965.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000000c', 'Charles de Gaulle', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000000c', 'Vincent Auriol', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000000c', 'Georges Pompidou', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000000c', 'Francois Mitterrand', FALSE, 3);
