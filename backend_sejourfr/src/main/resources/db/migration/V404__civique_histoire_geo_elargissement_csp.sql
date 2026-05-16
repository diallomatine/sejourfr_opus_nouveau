-- Flyway: niveau 3 thème 4 HISTOIRE_GEO - 50 CSP (40 CONN + 10 MS) - is_active=FALSE

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000001', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quelle ville est appelée la ''ville lumière'' ?',
 'Paris est surnommée la ''ville lumière'' depuis le XVIIIe siècle. Ce surnom évoque à la fois son rayonnement intellectuel et sa précocité dans l''éclairage public urbain.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000001', 'Paris', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000001', 'Marseille', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000001', 'Lyon', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000001', 'Toulouse', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000002', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quel monument se trouve au centre de Paris ?',
 'Plusieurs monuments emblématiques se trouvent à Paris : tour Eiffel, Notre-Dame, Louvre, Arc de Triomphe, Panthéon, basilique du Sacré-Cœur.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000002', 'La tour Eiffel', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000002', 'La statue de la Liberté', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000002', 'Big Ben', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000002', 'Le Colisée', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000003', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Sur quelle place s''élève l''Arc de Triomphe à Paris ?',
 'L''Arc de Triomphe se trouve sur la place Charles-de-Gaulle (anciennement place de l''Étoile), au sommet des Champs-Élysées.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000003', 'Place Charles-de-Gaulle (l''Étoile)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000003', 'Place de la Concorde', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000003', 'Place de la Bastille', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000003', 'Place de la République', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000004', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Combien la France a-t-elle de côtes maritimes (en simplifié) ?',
 'La France a trois façades maritimes : mer du Nord/Manche au nord, océan Atlantique à l''ouest, mer Méditerranée au sud, plus les outre-mer.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000004', 'Trois grandes façades maritimes', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000004', 'Aucune', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000004', 'Une seule', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000004', 'Dix différentes', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000005', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Comment s''appelle le fleuve qui traverse Paris ?',
 'La Seine traverse Paris d''est en ouest. Elle a façonné le paysage parisien et borde de nombreux monuments (Notre-Dame, Louvre, tour Eiffel).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000005', 'La Seine', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000005', 'La Loire', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000005', 'Le Rhône', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000005', 'La Garonne', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000006', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quel monument célèbre a été inauguré en 1889 ?',
 'La tour Eiffel a été construite pour l''Exposition universelle de 1889 à Paris, pour célébrer le centenaire de la Révolution française. Elle mesure 330 m de haut.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000006', 'La tour Eiffel', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000006', 'Le Panthéon', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000006', 'L''Arc de Triomphe', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000006', 'La basilique du Sacré-Cœur', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000007', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Que représente le drapeau français ?',
 'Le drapeau français (bleu-blanc-rouge) est l''emblème de la République. Adopté en 1794, il symbolise l''union du peuple (bleu et rouge, couleurs de Paris) et de la royauté (blanc).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000007', 'Le drapeau de la République française', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000007', 'Le drapeau d''une région', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000007', 'Un drapeau européen', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000007', 'Le drapeau de Paris', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000008', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quel hymne national est chanté en France ?',
 'La Marseillaise est l''hymne national français. Composé en 1792 à Strasbourg par Rouget de Lisle, il a été adopté définitivement par la IIIe République.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000008', 'La Marseillaise', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000008', 'God Save the Queen', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000008', 'L''Ode à la joie', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000008', 'L''Internationale', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000009', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quelle est la devise de la République française ?',
 'La devise de la République française est ''Liberté, Égalité, Fraternité''. Elle est inscrite dans la Constitution (article 2).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000009', 'Liberté, Égalité, Fraternité', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000009', 'Travail, Famille, Patrie', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000009', 'Un pour tous, tous pour un', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000009', 'In God we trust', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000000a', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quel symbole féminin représente la République française ?',
 'Marianne est l''allégorie de la République française. On la trouve sur les timbres, les pièces, dans les mairies. Elle porte souvent un bonnet phrygien.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000000a', 'Marianne', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000000a', 'Jeanne d''Arc', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000000a', 'Brigitte Bardot', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000000a', 'La Vierge Marie', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000000b', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quel coq est un emblème animal de la France ?',
 'Le coq gaulois est un emblème officieux de la France. On le retrouve sur les maillots de l''équipe de France de football et de rugby.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000000b', 'Le coq gaulois', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000000b', 'L''aigle impérial', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000000b', 'Le lion britannique', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000000b', 'L''ours russe', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000000c', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quel événement annuel sportif passe par les Champs-Élysées ?',
 'L''arrivée finale du Tour de France de cyclisme, course mythique créée en 1903, se fait traditionnellement sur les Champs-Élysées à Paris.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000000c', 'L''arrivée du Tour de France', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000000c', 'Roland-Garros', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000000c', 'Le marathon de Paris', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000000c', 'Les 24 heures du Mans', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000000d', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quel tournoi de tennis est joué à Paris ?',
 'Roland-Garros est le tournoi de tennis français du Grand Chelem, joué chaque année sur terre battue à Paris (Porte d''Auteuil), en mai-juin.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000000d', 'Roland-Garros', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000000d', 'Wimbledon', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000000d', 'US Open', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000000d', 'Australian Open', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000000e', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quel sport collectif est très populaire en France ?',
 'Le football est le sport le plus populaire en France. L''équipe de France masculine a remporté la Coupe du monde en 1998 et 2018.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000000e', 'Le football', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000000e', 'Le base-ball', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000000e', 'Le cricket', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000000e', 'Le golf', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000000f', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quel produit alimentaire est emblématique de la France ?',
 'Plusieurs produits sont emblématiques de la cuisine française : la baguette de pain, le fromage (camembert, brie, roquefort), le vin, le foie gras, les croissants.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000000f', 'La baguette de pain', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000000f', 'Le riz blanc', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000000f', 'Le hamburger', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000000f', 'Le sushi', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000010', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quel jour férié célèbre la victoire des Alliés en 1945 ?',
 'Le 8 mai est férié en France. Il commémore la victoire des Alliés sur l''Allemagne nazie, le 8 mai 1945, qui a mis fin à la Seconde Guerre mondiale en Europe.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000010', 'Le 8 mai', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000010', 'Le 11 novembre', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000010', 'Le 14 juillet', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000010', 'Le 1er mai', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000011', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Que célèbre-t-on le 1er mai en France ?',
 'Le 1er mai est la fête du Travail. C''est un jour férié en France. On y offre traditionnellement du muguet.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000011', 'La fête du Travail', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000011', 'La fête nationale', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000011', 'L''armistice', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000011', 'La fête de l''Europe', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000012', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quelle fête est célébrée le 1er janvier en France ?',
 'Le 1er janvier marque le jour de l''An (début de l''année civile). C''est un jour férié. On souhaite la bonne année à ses proches.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000012', 'Le jour de l''An', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000012', 'Noël', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000012', 'Pâques', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000012', 'L''Ascension', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000013', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quel saint célèbre la fête de la Toussaint, jour férié ?',
 'La Toussaint, le 1er novembre, est un jour férié en France. C''est une fête catholique qui honore tous les saints.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000013', 'Tous les saints (fête catholique)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000013', 'Saint Nicolas', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000013', 'Saint Patrick', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000013', 'Saint Valentin', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000014', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quelle ville accueille la cathédrale de Notre-Dame, restaurée après l''incendie de 2019 ?',
 'Notre-Dame de Paris, gravement endommagée par un incendie en avril 2019, a été rouverte au public le 7 décembre 2024 après une restauration majeure.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000014', 'Paris', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000014', 'Reims', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000014', 'Strasbourg', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000014', 'Lyon', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000015', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quelle ville célèbre est connue pour ses festivals de cinéma ?',
 'Cannes accueille chaque année en mai le Festival international du film, l''un des plus prestigieux au monde. La Palme d''or y est décernée.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000015', 'Cannes (Festival du film)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000015', 'Lille', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000015', 'Brest', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000015', 'Limoges', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000016', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quelle ville française est appelée la ''capitale des Alpes'' ?',
 'Grenoble est souvent qualifiée de ''capitale des Alpes'', en raison de sa position au cœur du massif et de son rôle économique et universitaire dans la région.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000016', 'Grenoble', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000016', 'Lyon', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000016', 'Nice', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000016', 'Annecy', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000017', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quelle région est célébrée pour ses vins (Bordeaux, etc.) ?',
 'La Nouvelle-Aquitaine, autour de Bordeaux, est une des plus grandes régions viticoles de France. D''autres régions viticoles célèbres : Bourgogne, Champagne, Alsace, vallée du Rhône.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000017', 'La Nouvelle-Aquitaine (région de Bordeaux)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000017', 'L''Île-de-France', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000017', 'Le Nord', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000017', 'La Bretagne', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000018', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quelle région a comme capitale Strasbourg et est proche de l''Allemagne ?',
 'Le Grand Est (anciennes régions Alsace, Lorraine, Champagne-Ardenne), avec Strasbourg pour capitale, est frontalière de l''Allemagne, du Luxembourg, de la Belgique et de la Suisse.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000018', 'Le Grand Est', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000018', 'La Bretagne', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000018', 'La Provence', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000018', 'L''Île-de-France', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000019', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quel événement historique a eu lieu sur les plages de Normandie en 1944 ?',
 'Le débarquement allié en Normandie a eu lieu le 6 juin 1944 (D-Day). Il a marqué le début de la libération de la France et de l''Europe occidentale par les forces alliées.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000019', 'Le débarquement des Alliés (6 juin 1944)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000019', 'La Révolution française', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000019', 'La Première Guerre mondiale', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000019', 'L''expédition d''Égypte', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000001a', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quelle reine française est connue pour avoir été décapitée en 1793 ?',
 'Marie-Antoinette, épouse de Louis XVI, a été guillotinée le 16 octobre 1793 pendant la Révolution française.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000001a', 'Marie-Antoinette', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000001a', 'Catherine de Médicis', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000001a', 'Jeanne d''Arc', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000001a', 'Aliénor d''Aquitaine', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000001b', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quel général français a appelé à la résistance le 18 juin 1940 depuis Londres ?',
 'Charles de Gaulle a lancé l''appel du 18 juin 1940 depuis la BBC à Londres, appelant les Français à poursuivre le combat contre l''occupation nazie. Cet appel a fondé la France libre.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000001b', 'Charles de Gaulle', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000001b', 'Philippe Pétain', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000001b', 'Joseph Joffre', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000001b', 'Ferdinand Foch', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000001c', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quel roi est dit le ''Roi-Soleil'' ?',
 'Louis XIV, qui a régné de 1643 à 1715, est surnommé le ''Roi-Soleil''. Il a fait construire le château de Versailles et a marqué le rayonnement de la France au XVIIe siècle.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000001c', 'Louis XIV (Roi-Soleil)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000001c', 'Louis XVI', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000001c', 'Henri IV', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000001c', 'François Ier', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000001d', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Où se trouve le château de Versailles ?',
 'Le château de Versailles est situé à Versailles, dans les Yvelines, à environ 20 km au sud-ouest de Paris. C''était la résidence des rois de France de Louis XIV à Louis XVI.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000001d', 'À Versailles, près de Paris', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000001d', 'À Paris même', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000001d', 'À Lyon', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000001d', 'À Marseille', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000001e', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Qui a peint la Joconde, exposée au Louvre ?',
 'La Joconde (Mona Lisa) a été peinte par Léonard de Vinci, peintre italien venu finir ses jours en France à la cour de François Ier (début XVIe siècle).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000001e', 'Léonard de Vinci', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000001e', 'Pablo Picasso', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000001e', 'Claude Monet', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000001e', 'Vincent Van Gogh', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000001f', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Qui était Jeanne d''Arc, héroïne française ?',
 'Jeanne d''Arc (1412-1431) est une héroïne française du Moyen Âge. Elle a libéré Orléans, conduit Charles VII à Reims pour son sacre, puis a été brûlée vive à Rouen.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000001f', 'Une héroïne française du XVe siècle', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000001f', 'Une reine de France', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000001f', 'Une scientifique', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000001f', 'Une chanteuse', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000020', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quelle célèbre scientifique française a reçu deux prix Nobel ?',
 'Marie Curie (1867-1934), française d''origine polonaise, a obtenu le prix Nobel de physique (1903) et de chimie (1911). Elle a découvert la radioactivité avec son mari Pierre Curie.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000020', 'Marie Curie', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000020', 'Marie-Antoinette', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000020', 'Édith Piaf', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000020', 'Coco Chanel', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000021', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quel chien français est associé à Louis Pasteur ?',
 'Louis Pasteur (1822-1895), chimiste et biologiste français, a inventé le vaccin contre la rage en 1885. Il a aussi mis au point la pasteurisation.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000021', 'Le chien vacciné contre la rage (Pasteur, 1885)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000021', 'Le berger allemand', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000021', 'Le caniche royal', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000021', 'Aucun chien spécifique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000022', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quelle femme politique française a porté la loi sur l''IVG en 1975 ?',
 'Simone Veil (1927-2017), ministre de la Santé, a fait adopter la loi du 17 janvier 1975 dépénalisant l''IVG (avortement). Elle est entrée au Panthéon en 2018.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000022', 'Simone Veil', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000022', 'Simone de Beauvoir', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000022', 'Édith Cresson', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000022', 'Olympe de Gouges', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000023', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Comment appelle-t-on en France un pain long et croustillant typique ?',
 'La baguette est le pain emblématique de la France. Inscrite au patrimoine culturel immatériel de l''UNESCO en 2022.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000023', 'La baguette', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000023', 'La galette', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000023', 'Le bagel', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000023', 'Le pain de mie', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000024', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quel fromage français est produit en Normandie ?',
 'Le camembert est un fromage normand emblématique, fabriqué à base de lait de vache. La Normandie produit aussi le livarot, le pont-l''évêque, le neufchâtel.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000024', 'Le camembert', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000024', 'Le parmesan', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000024', 'Le cheddar', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000024', 'La feta', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000025', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quelle viennoiserie est typiquement française ?',
 'Le croissant est une viennoiserie emblématique du petit-déjeuner français. Inventée à Vienne mais popularisée en France au XIXe siècle.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000025', 'Le croissant', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000025', 'Le donut', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000025', 'Le bagel', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000025', 'Le pretzel', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000026', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quelle est la langue officielle de la France ?',
 'Le français est la seule langue officielle de la République française (article 2 de la Constitution). Les langues régionales (breton, basque, occitan, corse) appartiennent au patrimoine.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000026', 'Le français', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000026', 'L''anglais', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000026', 'L''allemand', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000026', 'L''espagnol', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000027', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quelle institution promeut la langue française dans le monde ?',
 'La Francophonie (OIF - Organisation internationale de la Francophonie) regroupe les pays ayant le français en partage. Plus de 320 millions de francophones dans le monde.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000027', 'L''Organisation internationale de la Francophonie (OIF)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000027', 'L''ONU', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000027', 'L''OTAN', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000027', 'L''UNESCO', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000028', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quand a eu lieu la prise de la Bastille ?',
 'La prise de la Bastille a eu lieu le 14 juillet 1789. Cet événement symbolique du début de la Révolution française est commémoré comme fête nationale.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000028', 'Le 14 juillet 1789', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000028', 'Le 4 août 1789', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000028', 'Le 26 août 1789', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000028', 'Le 14 juillet 1880', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000029', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'MISE_SITUATION',
 'Je veux visiter un monument historique français célèbre. Quels lieux gratuits ou peu chers existent ?',
 'Beaucoup de monuments offrent accès gratuit le 1er dimanche du mois (notamment musées nationaux). Les Journées du patrimoine en septembre permettent d''entrer dans des lieux d''ordinaire fermés.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000029', 'Le 1er dimanche du mois ou les Journées du patrimoine', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000029', 'Aucune visite gratuite', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000029', 'Uniquement avec un guide payé', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000029', 'Uniquement les militaires', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000002a', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'MISE_SITUATION',
 'On me demande de citer un fleuve qui se jette dans la Méditerranée. Lequel choisir ?',
 'Le Rhône est le fleuve français qui se jette dans la mer Méditerranée (après Lyon, vers Marseille/la Camargue). Les autres grands fleuves (Seine, Loire, Garonne) se jettent dans l''Atlantique.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000002a', 'Le Rhône', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000002a', 'La Seine', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000002a', 'La Loire', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000002a', 'La Garonne', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000002b', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'MISE_SITUATION',
 'Quelle attitude adopter face à la Marseillaise lors d''une cérémonie publique ?',
 'Il est d''usage de se tenir debout et silencieux pendant la Marseillaise. C''est une marque de respect envers l''hymne national et envers les personnes présentes à la cérémonie.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000002b', 'Se lever et rester silencieux par respect', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000002b', 'Continuer ses conversations', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000002b', 'Sortir de la salle', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000002b', 'Mettre une musique différente', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000002c', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'MISE_SITUATION',
 'Je veux participer aux Journées du patrimoine. Quand ont-elles lieu ?',
 'Les Journées européennes du patrimoine ont lieu chaque année le troisième week-end de septembre. De nombreux monuments publics et privés ouvrent leurs portes gratuitement.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000002c', 'Le troisième week-end de septembre', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000002c', 'Le 14 juillet', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000002c', 'Au mois de mai', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000002c', 'À Noël', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000002d', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'MISE_SITUATION',
 'Quel comportement avoir devant un monument historique ou un musée ?',
 'Il faut respecter les lieux : ne pas toucher les œuvres, ne pas faire de bruit, suivre les indications, ne pas voler ni dégrader. Certaines photos peuvent être interdites.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000002d', 'Respect des lieux, des règles, et silence', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000002d', 'Toucher les œuvres', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000002d', 'Faire la fête bruyamment', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000002d', 'Voler des souvenirs', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000002e', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'MISE_SITUATION',
 'On me demande pourquoi le 14 juillet est important. Que dire ?',
 'Le 14 juillet est la fête nationale française. Il commémore la prise de la Bastille en 1789 (début de la Révolution) et la fête de la Fédération en 1790 (union nationale).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000002e', 'Fête nationale (prise de la Bastille en 1789)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000002e', 'Anniversaire du roi', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000002e', 'Jour de la rentrée scolaire', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000002e', 'Jour de l''Europe', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000002f', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'MISE_SITUATION',
 'Je veux assister à un défilé militaire français. Quel jour est-ce traditionnel ?',
 'Le défilé militaire du 14 juillet sur les Champs-Élysées à Paris est le grand défilé national français. D''autres cérémonies ont lieu dans les villes de garnison.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000002f', 'Le 14 juillet (défilé sur les Champs-Élysées)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000002f', 'Le 1er janvier', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000002f', 'Le 25 décembre', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000002f', 'Le 1er avril', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000030', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'MISE_SITUATION',
 'J''apprends que le 11 novembre est férié. Pourquoi est-il important ?',
 'Le 11 novembre commémore l''armistice signé en 1918, qui a mis fin à la Première Guerre mondiale. C''est l''occasion d''honorer les soldats morts pour la France et de cultiver la mémoire.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000030', 'Armistice de 1918 et hommage aux soldats morts', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000030', 'Fête des familles', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000030', 'Naissance d''un président', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000030', 'Indépendance de l''Algérie', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000031', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'MISE_SITUATION',
 'Quelqu''un me dit que la France est une monarchie. Comment lui répondre ?',
 'Non, la France n''est plus une monarchie depuis 1870 (chute de Napoléon III). Aujourd''hui, c''est une république démocratique semi-présidentielle, sous la Ve République depuis 1958.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000031', 'Non, la France est une république depuis 1870', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000031', 'Oui, le roi gouverne', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000031', 'Cela dépend du jour', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000031', 'C''est une monarchie d''Europe', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000032', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'MISE_SITUATION',
 'Je veux écouter de la musique française classique. Quels compositeurs ?',
 'Parmi les grands compositeurs français : Claude Debussy, Maurice Ravel, Hector Berlioz, Georges Bizet (Carmen), Camille Saint-Saëns, Erik Satie.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000032', 'Debussy, Ravel, Berlioz, Bizet', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000032', 'Mozart, Bach, Beethoven', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000032', 'Verdi, Puccini, Rossini', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000032', 'Aucun compositeur français célèbre', FALSE, 3);
