-- Flyway: reformulations thème 4 HISTOIRE_GEO lot 4/4 (R37-R47) - is_active=FALSE

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000025', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Qui était Simone de Beauvoir ?',
 'Simone de Beauvoir (1908-1986) était une philosophe et ecrivaine française du XXe siècle, figure majeure de l''existentialisme et du féminisme (Le Deuxième Sexe, 1949).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000025', 'Une philosophe et ecrivaine française féministe', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000025', 'Une chanteuse de jazz', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000025', 'Une politicienne du XIXe siècle', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000025', 'Une artiste peintre', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000026', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Qui était Albert Camus ?',
 'Albert Camus (1913-1960) était un ecrivain et philosophe français, prix Nobel de litterature 1957. Romans : L''Étranger, La Peste. Essais : Le Mythe de Sisyphe, L''Homme revolte.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000026', 'Un ecrivain français, prix Nobel de litterature', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000026', 'Un peintre cubiste', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000026', 'Un président', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000026', 'Un sportif', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000027', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Qui était Paul Cézanne ?',
 'Paul Cézanne (1839-1906) était un peintre français, considère comme l''un des précurseurs du cubisme. Ses paysages provencaux et ses natures mortes sont mondialement connus.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000027', 'Un peintre français précurseur du cubisme', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000027', 'Un compositeur classique', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000027', 'Un philosophe', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000027', 'Un homme d''État', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000028', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Qui était Marc Chagall ?',
 'Marc Chagall (1887-1985) était un peintre français d''origine russe (juif), une des grandes figures de l''art moderne. Il a peint le plafond de l''Opera Garnier de Paris.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000028', 'Un peintre français d''origine russe', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000028', 'Un sculpteur antique', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000028', 'Un physicien', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000028', 'Un explorateur', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-000000000029', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Qui était Josephine Baker ?',
 'Josephine Baker (1906-1975), américaine devenue française, était une chanteuse, danseuse et resistante. Première femme noire entrée au Pantheon en 2021 pour son engagement contre le racisme et pour la France libre.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000029', 'Une chanteuse americano-française et resistante (au Pantheon)', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000029', 'Une scientifique', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000029', 'Une reine d''Angleterre', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-000000000029', 'Une politicienne contemporaine', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-00000000002a', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Laquelle de ces personnes a été une chanteuse française célèbre ?',
 'Plusieurs chanteuses françaises célèbres : Édith Piaf, Dalida, Mireille Mathieu, Barbara, Catherine Deneuve, Vanessa Paradis, Mylene Farmer, Patricia Kaas.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000002a', 'Édith Piaf', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000002a', 'Marie Curie', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000002a', 'Jeanne d''Arc', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000002a', 'Simone Veil', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-00000000002b', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Qu''est-ce que le Louvre ?',
 'Le Louvre est un musée situé à Paris, l''un des plus visités au monde. Il abrite des œuvres célèbres comme la Joconde de Leonard de Vinci ou la Venus de Milo.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000002b', 'Un musée parisien mondialement connu', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000002b', 'Un parc', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000002b', 'Un fleuve', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000002b', 'Un théâtre', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-00000000002c', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Qui était Jean de La Fontaine ?',
 'Jean de La Fontaine (1621-1695) était un poète français du XVIIe siècle, célèbre pour ses Fables (Le Corbeau et le Renard, La Cigale et la Fourmi, etc.).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000002c', 'Un poète français du XVIIe siècle, auteur des Fables', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000002c', 'Un philosophe des Lumieres', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000002c', 'Un peintre baroque', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000002c', 'Un roi', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-00000000002d', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Lequel de ces ecrivains est français ?',
 'Parmi les grands ecrivains français : Victor Hugo, Émile Zola, Marcel Proust, Albert Camus, Simone de Beauvoir, Antoine de Saint-Exupery, Marguerite Duras.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000002d', 'Victor Hugo', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000002d', 'William Shakespeare', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000002d', 'Goethe', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000002d', 'Cervantes', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-00000000002e', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Dans quelle ville française se trouve la tour Eiffel ?',
 'La tour Eiffel se trouve à Paris. Construite par Gustave Eiffel pour l''Exposition universelle de 1889, elle est l''un des monuments les plus visités au monde.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000002e', 'À Paris', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000002e', 'À Lyon', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000002e', 'À Marseille', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000002e', 'À Bordeaux', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000001-0000-0000-0000-00000000002f', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quand célèbre-t-on Noël en France ?',
 'Noël est célébré le 25 décembre. C''est une fête chrétienne célébrant la naissance de Jésus, devenue aussi une fête populaire et familiale en France.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000002f', 'Le 25 décembre', TRUE, 0),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000002f', 'Le 1er janvier', FALSE, 1),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000002f', 'Le 14 juillet', FALSE, 2),
(gen_random_uuid(), 'f4000001-0000-0000-0000-00000000002f', 'Le 11 novembre', FALSE, 3);
