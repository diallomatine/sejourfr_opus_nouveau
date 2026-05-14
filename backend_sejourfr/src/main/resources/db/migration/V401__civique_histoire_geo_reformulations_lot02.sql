-- Flyway: reformulations theme 4 HISTOIRE_GEO lot 2/4 (R13-R24) - is_active=FALSE

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-00000000000d', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'En quelle annee l''esclavage a-t-il ete definitivement aboli en France ?',
 'L''esclavage a ete definitivement aboli en France en 1848 par un decret signe par Victor Schoelcher, sous la IIe Republique.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000000d', '1848 (decret de Victor Schoelcher)', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000000d', '1789', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000000d', '1881', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000000d', '1944', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-00000000000e', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Depuis quelle annee l''ecole publique est-elle gratuite en France ?',
 'L''ecole publique est gratuite en France depuis 1881 (loi Ferry du 16 juin 1881). L''obligation et la laicite ont suivi en 1882.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000000e', '1881 (loi Ferry)', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000000e', '1789', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000000e', '1905', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000000e', '1958', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-00000000000f', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Combien de republiques la France a-t-elle connues a ce jour ?',
 'La France a connu 5 republiques : Ire (1792-1804), IIe (1848-1852), IIIe (1870-1940), IVe (1946-1958) et Ve (depuis 1958).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000000f', 'Cinq republiques', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000000f', 'Trois republiques', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000000f', 'Sept republiques', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000000f', 'Une seule', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000010', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quel roi etait sur le trone au moment de la Revolution francaise ?',
 'Louis XVI etait roi de France lorsque la Revolution a eclate en 1789. Il a ete guillotine le 21 janvier 1793 apres l''abolition de la monarchie.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000010', 'Louis XVI', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000010', 'Louis XIV', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000010', 'Henri IV', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000010', 'Napoleon Ier', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000011', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Qui est l''instigateur de la Ve Republique ?',
 'Charles de Gaulle a fonde la Ve Republique en 1958 a la suite de la crise algerienne. La nouvelle Constitution a ete adoptee par referendum.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000011', 'Charles de Gaulle', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000011', 'Vincent Auriol', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000011', 'Napoleon III', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000011', 'Robespierre', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000012', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Que commemore le 14 juillet ?',
 'Le 14 juillet est la fete nationale francaise. Elle commemore la prise de la Bastille en 1789 (debut de la Revolution) et la fete de la Federation en 1790 (union nationale).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000012', 'La prise de la Bastille (1789)', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000012', 'L''armistice de 1918', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000012', 'L''abolition de l''esclavage', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000012', 'La fin de la guerre d''Algerie', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000013', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quelle guerre s''est deroulee entre 1914 et 1918 ?',
 'La Premiere Guerre mondiale s''est deroulee de 1914 a 1918. Elle s''est terminee par l''armistice du 11 novembre 1918, signe a Rethondes.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000013', 'La Premiere Guerre mondiale', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000013', 'La Seconde Guerre mondiale', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000013', 'La guerre d''Algerie', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000013', 'La Revolution francaise', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000014', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Pourquoi l''annee 1958 est-elle marquante pour la France ?',
 '1958 est l''annee de la fondation de la Ve Republique, avec l''adoption d''une nouvelle Constitution sous l''impulsion de Charles de Gaulle, mettant fin a la IVe Republique en crise.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000014', 'Adoption de la Constitution de la Ve Republique', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000014', 'Fin de la Seconde Guerre mondiale', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000014', 'Debut de la Revolution', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000014', 'Abolition de l''esclavage', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000015', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quel fleuve traverse la France ?',
 'Plusieurs grands fleuves traversent la France : la Loire (le plus long), la Seine (qui passe a Paris), le Rhone (qui se jette dans la Mediterranee), la Garonne (Bordeaux).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000015', 'La Seine', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000015', 'Le Nil', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000015', 'Le Danube', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000015', 'L''Amazone', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000016', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quelle ville parmi ces propositions est francaise ?',
 'Paris, Marseille, Lyon, Toulouse, Nice, Bordeaux, Lille, Strasbourg sont parmi les principales villes francaises.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000016', 'Marseille', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000016', 'Berlin', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000016', 'Madrid', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000016', 'Londres', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000017', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quel ocean borde la cote ouest de la France metropolitaine ?',
 'La cote ouest de la France metropolitaine est bordee par l''ocean Atlantique. La cote sud par la mer Mediterranee, la cote nord par la Manche et la mer du Nord.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000017', 'L''ocean Atlantique', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000017', 'L''ocean Pacifique', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000017', 'L''ocean Indien', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000017', 'L''ocean Arctique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000018', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Qu''est-ce que Paris ?',
 'Paris est la capitale de la France, la ville la plus peuplee du pays (environ 2,1 millions d''habitants intra-muros, plus de 12 millions pour l''aire urbaine).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000018', 'La capitale de la France', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000018', 'Une region', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000018', 'Un fleuve', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000018', 'Un departement d''outre-mer', FALSE, 3);
