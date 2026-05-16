-- Flyway: reformulations thème 4 HISTOIRE_GEO lot 2/4 (R13-R24) - is_active=FALSE

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-00000000000d', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'En quelle année l''esclavage a-t-il été définitivement aboli en France ?',
 'L''esclavage a été definitivement aboli en France en 1848 par un décret signé par Victor Schoelcher, sous la IIe République.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000000d', '1848 (décret de Victor Schoelcher)', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000000d', '1789', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000000d', '1881', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000000d', '1944', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-00000000000e', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Depuis quelle année l''école publique est-elle gratuite en France ?',
 'L''école publique est gratuite en France depuis 1881 (loi Ferry du 16 juin 1881). L''obligation et la laïcité ont suivi en 1882.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000000e', '1881 (loi Ferry)', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000000e', '1789', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000000e', '1905', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000000e', '1958', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-00000000000f', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Combien de républiques la France a-t-elle connues à ce jour ?',
 'La France a connu 5 républiques : Ire (1792-1804), IIe (1848-1852), IIIe (1870-1940), IVe (1946-1958) et Ve (depuis 1958).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000000f', 'Cinq républiques', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000000f', 'Trois républiques', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000000f', 'Sept républiques', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000000f', 'Une seule', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000010', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quel roi était sur le trône au moment de la Révolution française ?',
 'Louis XVI était roi de France lorsque la Révolution a éclaté en 1789. Il a été guillotiné le 21 janvier 1793 après l''abolition de la monarchie.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000010', 'Louis XVI', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000010', 'Louis XIV', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000010', 'Henri IV', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000010', 'Napoléon Ier', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000011', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Qui est l''instigateur de la Ve République ?',
 'Charles de Gaulle a fondé la Ve République en 1958 à la suite de la crise algérienne. La nouvelle Constitution a été adoptée par référendum.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000011', 'Charles de Gaulle', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000011', 'Vincent Auriol', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000011', 'Napoléon III', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000011', 'Robespierre', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000012', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Que commémore le 14 juillet ?',
 'Le 14 juillet est la fête nationale française. Elle commémore la prise de la Bastille en 1789 (début de la Révolution) et la fête de la Fédération en 1790 (union nationale).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000012', 'La prise de la Bastille (1789)', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000012', 'L''armistice de 1918', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000012', 'L''abolition de l''esclavage', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000012', 'La fin de la guerre d''Algérie', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000013', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quelle guerre s''est déroulée entre 1914 et 1918 ?',
 'La Première Guerre mondiale s''est déroulée de 1914 à 1918. Elle s''est terminée par l''armistice du 11 novembre 1918, signé à Rethondes.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000013', 'La Première Guerre mondiale', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000013', 'La Seconde Guerre mondiale', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000013', 'La guerre d''Algerie', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000013', 'La Révolution française', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000014', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Pourquoi l''année 1958 est-elle marquante pour la France ?',
 '1958 est l''année de la fondation de la Ve République, avec l''adoption d''une nouvelle Constitution sous l''impulsion de Charles de Gaulle, mettant fin à la IVe République en crise.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000014', 'Adoption de la Constitution de la Ve République', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000014', 'Fin de la Seconde Guerre mondiale', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000014', 'Début de la Révolution', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000014', 'Abolition de l''esclavage', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000015', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quel fleuve traverse la France ?',
 'Plusieurs grands fleuves traversent la France : la Loire (le plus long), la Seine (qui passe à Paris), le Rhône (qui se jette dans la Méditerranée), la Garonne (Bordeaux).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000015', 'La Seine', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000015', 'Le Nil', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000015', 'Le Danube', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000015', 'L''Amazone', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000016', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quelle ville parmi ces propositions est française ?',
 'Paris, Marseille, Lyon, Toulouse, Nice, Bordeaux, Lille, Strasbourg sont parmi les principales villes françaises.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000016', 'Marseille', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000016', 'Berlin', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000016', 'Madrid', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000016', 'Londres', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000017', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quel océan borde la côte ouest de la France métropolitaine ?',
 'La côte ouest de la France métropolitaine est bordée par l''océan Atlantique. La côte sud par la mer Méditerranée, la côte nord par la Manche et la mer du Nord.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000017', 'L''océan Atlantique', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000017', 'L''océan Pacifique', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000017', 'L''océan Indien', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000017', 'L''océan Arctique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000018', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Qu''est-ce que Paris ?',
 'Paris est la capitale de la France, la ville la plus peuplée du pays (environ 2,1 millions d''habitants intra-muros, plus de 12 millions pour l''aire urbaine).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000018', 'La capitale de la France', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000018', 'Une région', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000018', 'Un fleuve', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000018', 'Un département d''outre-mer', FALSE, 3);
