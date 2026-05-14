-- Flyway: reformulations thème 4 HISTOIRE_GEO lot 3/4 (R25-R36) - is_active=FALSE

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000019', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quelle est la ville capitale de la France ?',
 'Paris est la capitale de la France. C''est le siège des institutions nationales (Assemblée, Élysée, Sénat, Matignon).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000019', 'Paris', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000019', 'Lyon', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000019', 'Marseille', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000019', 'Toulouse', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-00000000001a', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Sur quel continent se trouve la France métropolitaine ?',
 'La France métropolitaine se situé sur le continent européen, dans l''Europe occidentale.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000001a', 'L''Europe', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000001a', 'L''Afrique', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000001a', 'L''Asie', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000001a', 'L''Amérique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-00000000001b', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quelle île est un département français d''outre-mer ?',
 'Les départements d''outre-mer français incluent : la Guadeloupe, la Martinique, la Réunion (toutes des îles), la Guyane (en Amérique du Sud) et Mayotte.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000001b', 'La Réunion', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000001b', 'Madagascar', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000001b', 'Cuba', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000001b', 'Haïti', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-00000000001c', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Combien de régions compte la France métropolitaine depuis 2016 ?',
 'Depuis la réforme territoriale de 2016, la France métropolitaine compte 13 régions (contre 22 auparavant). S''ajoutent les régions d''outre-mer.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000001c', '13 régions', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000001c', '22 régions', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000001c', '10 régions', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000001c', '27 régions', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-00000000001d', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quelle ville française est un important port maritime ?',
 'Marseille (Méditerranée), Le Havre (Atlantique), Dunkerque (mer du Nord) sont parmi les principaux ports français.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000001d', 'Marseille', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000001d', 'Lyon', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000001d', 'Toulouse', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000001d', 'Strasbourg', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-00000000001e', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quelle mer borde la France au sud ?',
 'La mer Méditerranée borde la France au sud (côtés provencale, languedocienne et corse). Au nord se trouvent la Manche et la mer du Nord, à l''ouest l''ocean Atlantique.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000001e', 'La mer Méditerranée', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000001e', 'La mer Baltique', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000001e', 'La mer Noire', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000001e', 'La mer du Nord', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-00000000001f', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quelle ville française est située au bord de la mer Méditerranée ?',
 'Plusieurs villes françaises bordent la Méditerranée : Marseille, Nice, Montpellier, Toulon, Cannes, Perpignan, Ajaccio (Corse).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000001f', 'Marseille', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000001f', 'Strasbourg', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000001f', 'Lille', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000001f', 'Brest', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000020', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Où se trouve la Corse ?',
 'La Corse est une île française située en mer Méditerranée, au sud-est de la France métropolitaine. C''est une collectivite territoriale unique depuis 2018.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000020', 'En mer Méditerranée, au sud-est de la France', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000020', 'Dans l''ocean Atlantique', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000020', 'Au nord de la France', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000020', 'En Amérique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000021', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quelle chaine de montagnes se trouve entre la France et l''Italie ?',
 'Les Alpes constituent la frontière naturelle entre la France et l''Italie (et la Suisse). Le Mont-Blanc, plus haut sommet d''Europe occidentale (4 809 m), s''y trouve.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000021', 'Les Alpes', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000021', 'Les Pyrénées', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000021', 'Les Vosges', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000021', 'Le Massif central', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000022', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Qui était Molière ?',
 'Molière (Jean-Baptiste Poquelin, 1622-1673) était un dramaturge français du XVIIe siècle. Il est consideré comme l''un des plus grands auteurs de comedie. Œuvres : Le Tartuffe, L''Avare, Le Misanthrope.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000022', 'Un dramaturge français du XVIIe siècle', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000022', 'Un peintre du XIXe siècle', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000022', 'Un roi de France', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000022', 'Un explorateur', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000023', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Qui était Charles Baudelaire ?',
 'Charles Baudelaire (1821-1867) était un poète français du XIXe siècle, auteur des Fleurs du mal, un des recueils majeurs de la poésie française.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000023', 'Un poète français (auteur des Fleurs du mal)', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000023', 'Un peintre romantique', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000023', 'Un compositeur', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000023', 'Un homme politique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000024', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Qui était George Sand ?',
 'George Sand (Aurore Dupin, 1804-1876) était une romanciere française du XIXe siècle, figure du romantisme et pionniere de la cause feminine.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000024', 'Une romanciere française du XIXe siècle', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000024', 'Une chanteuse contemporaine', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000024', 'Une scientifique', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000024', 'Une reine de France', FALSE, 3);
