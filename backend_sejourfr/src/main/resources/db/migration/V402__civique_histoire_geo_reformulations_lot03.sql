-- Flyway: reformulations theme 4 HISTOIRE_GEO lot 3/4 (R25-R36) - is_active=FALSE

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000019', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quelle est la ville capitale de la France ?',
 'Paris est la capitale de la France. C''est le siege des institutions nationales (Assemblee, Elysee, Senat, Matignon).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000019', 'Paris', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000019', 'Lyon', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000019', 'Marseille', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000019', 'Toulouse', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-00000000001a', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Sur quel continent se trouve la France metropolitaine ?',
 'La France metropolitaine se situe sur le continent europeen, dans l''Europe occidentale.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000001a', 'L''Europe', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000001a', 'L''Afrique', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000001a', 'L''Asie', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000001a', 'L''Amerique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-00000000001b', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quelle ile est un departement francais d''outre-mer ?',
 'Les departements d''outre-mer francais incluent : la Guadeloupe, la Martinique, la Reunion (toutes des iles), la Guyane (en Amerique du Sud) et Mayotte.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000001b', 'La Reunion', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000001b', 'Madagascar', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000001b', 'Cuba', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000001b', 'Haiti', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-00000000001c', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Combien de regions compte la France metropolitaine depuis 2016 ?',
 'Depuis la reforme territoriale de 2016, la France metropolitaine compte 13 regions (contre 22 auparavant). S''ajoutent les regions d''outre-mer.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000001c', '13 regions', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000001c', '22 regions', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000001c', '10 regions', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000001c', '27 regions', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-00000000001d', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quelle ville francaise est un important port maritime ?',
 'Marseille (Mediterranee), Le Havre (Atlantique), Dunkerque (mer du Nord) sont parmi les principaux ports francais.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000001d', 'Marseille', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000001d', 'Lyon', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000001d', 'Toulouse', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000001d', 'Strasbourg', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-00000000001e', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quelle mer borde la France au sud ?',
 'La mer Mediterranee borde la France au sud (cotes provencale, languedocienne et corse). Au nord se trouvent la Manche et la mer du Nord, a l''ouest l''ocean Atlantique.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000001e', 'La mer Mediterranee', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000001e', 'La mer Baltique', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000001e', 'La mer Noire', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000001e', 'La mer du Nord', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-00000000001f', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quelle ville francaise est situee au bord de la mer Mediterranee ?',
 'Plusieurs villes francaises bordent la Mediterranee : Marseille, Nice, Montpellier, Toulon, Cannes, Perpignan, Ajaccio (Corse).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000001f', 'Marseille', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000001f', 'Strasbourg', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000001f', 'Lille', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000001f', 'Brest', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000020', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Ou se trouve la Corse ?',
 'La Corse est une ile francaise situee en mer Mediterranee, au sud-est de la France metropolitaine. C''est une collectivite territoriale unique depuis 2018.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000020', 'En mer Mediterranee, au sud-est de la France', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000020', 'Dans l''ocean Atlantique', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000020', 'Au nord de la France', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000020', 'En Amerique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000021', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quelle chaine de montagnes se trouve entre la France et l''Italie ?',
 'Les Alpes constituent la frontiere naturelle entre la France et l''Italie (et la Suisse). Le Mont-Blanc, plus haut sommet d''Europe occidentale (4 809 m), s''y trouve.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000021', 'Les Alpes', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000021', 'Les Pyrenees', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000021', 'Les Vosges', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000021', 'Le Massif central', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000022', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Qui etait Moliere ?',
 'Moliere (Jean-Baptiste Poquelin, 1622-1673) etait un dramaturge francais du XVIIe siecle. Il est considere comme l''un des plus grands auteurs de comedie. Oeuvres : Le Tartuffe, L''Avare, Le Misanthrope.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000022', 'Un dramaturge francais du XVIIe siecle', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000022', 'Un peintre du XIXe siecle', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000022', 'Un roi de France', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000022', 'Un explorateur', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000023', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Qui etait Charles Baudelaire ?',
 'Charles Baudelaire (1821-1867) etait un poete francais du XIXe siecle, auteur des Fleurs du mal, un des recueils majeurs de la poesie francaise.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000023', 'Un poete francais (auteur des Fleurs du mal)', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000023', 'Un peintre romantique', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000023', 'Un compositeur', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000023', 'Un homme politique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000024', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Qui etait George Sand ?',
 'George Sand (Aurore Dupin, 1804-1876) etait une romanciere francaise du XIXe siecle, figure du romantisme et pionniere de la cause feminine.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000024', 'Une romanciere francaise du XIXe siecle', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000024', 'Une chanteuse contemporaine', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000024', 'Une scientifique', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000024', 'Une reine de France', FALSE, 3);
