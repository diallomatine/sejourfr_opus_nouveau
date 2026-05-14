-- Flyway: reformulations theme 4 HISTOIRE_GEO lot 4/4 (R37-R47) - is_active=FALSE

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000025', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Qui etait Simone de Beauvoir ?',
 'Simone de Beauvoir (1908-1986) etait une philosophe et ecrivaine francaise du XXe siecle, figure majeure de l''existentialisme et du feminisme (Le Deuxieme Sexe, 1949).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000025', 'Une philosophe et ecrivaine francaise feministe', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000025', 'Une chanteuse de jazz', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000025', 'Une politicienne du XIXe siecle', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000025', 'Une artiste peintre', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000026', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Qui etait Albert Camus ?',
 'Albert Camus (1913-1960) etait un ecrivain et philosophe francais, prix Nobel de litterature 1957. Romans : L''Etranger, La Peste. Essais : Le Mythe de Sisyphe, L''Homme revolte.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000026', 'Un ecrivain francais, prix Nobel de litterature', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000026', 'Un peintre cubiste', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000026', 'Un president', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000026', 'Un sportif', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000027', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Qui etait Paul Cezanne ?',
 'Paul Cezanne (1839-1906) etait un peintre francais, considere comme l''un des precurseurs du cubisme. Ses paysages provencaux et ses natures mortes sont mondialement connus.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000027', 'Un peintre francais precurseur du cubisme', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000027', 'Un compositeur classique', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000027', 'Un philosophe', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000027', 'Un homme d''Etat', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000028', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Qui etait Marc Chagall ?',
 'Marc Chagall (1887-1985) etait un peintre francais d''origine russe (juif), une des grandes figures de l''art moderne. Il a peint le plafond de l''Opera Garnier de Paris.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000028', 'Un peintre francais d''origine russe', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000028', 'Un sculpteur antique', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000028', 'Un physicien', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000028', 'Un explorateur', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000029', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Qui etait Josephine Baker ?',
 'Josephine Baker (1906-1975), americaine devenue francaise, etait une chanteuse, danseuse et resistante. Premiere femme noire entree au Pantheon en 2021 pour son engagement contre le racisme et pour la France libre.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000029', 'Une chanteuse americano-francaise et resistante (au Pantheon)', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000029', 'Une scientifique', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000029', 'Une reine d''Angleterre', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000029', 'Une politicienne contemporaine', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-00000000002a', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Laquelle de ces personnes a ete une chanteuse francaise celebre ?',
 'Plusieurs chanteuses francaises celebres : Edith Piaf, Dalida, Mireille Mathieu, Barbara, Catherine Deneuve, Vanessa Paradis, Mylene Farmer, Patricia Kaas.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000002a', 'Edith Piaf', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000002a', 'Marie Curie', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000002a', 'Jeanne d''Arc', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000002a', 'Simone Veil', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-00000000002b', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Qu''est-ce que le Louvre ?',
 'Le Louvre est un musee situe a Paris, l''un des plus visites au monde. Il abrite des oeuvres celebres comme la Joconde de Leonard de Vinci ou la Venus de Milo.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000002b', 'Un musee parisien mondialement connu', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000002b', 'Un parc', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000002b', 'Un fleuve', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000002b', 'Un theatre', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-00000000002c', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Qui etait Jean de La Fontaine ?',
 'Jean de La Fontaine (1621-1695) etait un poete francais du XVIIe siecle, celebre pour ses Fables (Le Corbeau et le Renard, La Cigale et la Fourmi, etc.).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000002c', 'Un poete francais du XVIIe siecle, auteur des Fables', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000002c', 'Un philosophe des Lumieres', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000002c', 'Un peintre baroque', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000002c', 'Un roi', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-00000000002d', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Lequel de ces ecrivains est francais ?',
 'Parmi les grands ecrivains francais : Victor Hugo, Emile Zola, Marcel Proust, Albert Camus, Simone de Beauvoir, Antoine de Saint-Exupery, Marguerite Duras.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000002d', 'Victor Hugo', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000002d', 'William Shakespeare', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000002d', 'Goethe', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000002d', 'Cervantes', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-00000000002e', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Dans quelle ville francaise se trouve la tour Eiffel ?',
 'La tour Eiffel se trouve a Paris. Construite par Gustave Eiffel pour l''Exposition universelle de 1889, elle est l''un des monuments les plus visites au monde.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000002e', 'A Paris', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000002e', 'A Lyon', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000002e', 'A Marseille', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000002e', 'A Bordeaux', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-00000000002f', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quand celebre-t-on Noel en France ?',
 'Noel est celebre le 25 decembre. C''est une fete chretienne celebrant la naissance de Jesus, devenue aussi une fete populaire et familiale en France.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000002f', 'Le 25 decembre', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000002f', 'Le 1er janvier', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000002f', 'Le 14 juillet', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000002f', 'Le 11 novembre', FALSE, 3);
