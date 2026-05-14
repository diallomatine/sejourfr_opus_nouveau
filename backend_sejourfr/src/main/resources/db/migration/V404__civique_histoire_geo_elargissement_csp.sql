-- Flyway: niveau 3 theme 4 HISTOIRE_GEO - 50 CSP (40 CONN + 10 MS) - is_active=FALSE

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000001', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quelle ville est appelee la ''ville lumiere'' ?',
 'Paris est surnommee la ''ville lumiere'' depuis le XVIIIe siecle. Ce surnom evoque a la fois son rayonnement intellectuel et sa precocite dans l''eclairage public urbain.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000001', 'Paris', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000001', 'Marseille', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000001', 'Lyon', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000001', 'Toulouse', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000002', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quel monument se trouve au centre de Paris ?',
 'Plusieurs monuments emblematiques se trouvent a Paris : tour Eiffel, Notre-Dame, Louvre, Arc de Triomphe, Pantheon, basilique du Sacre-Coeur.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000002', 'La tour Eiffel', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000002', 'La statue de la Liberte', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000002', 'Big Ben', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000002', 'Le Colisee', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000003', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Sur quelle place s''eleve l''Arc de Triomphe a Paris ?',
 'L''Arc de Triomphe se trouve sur la place Charles-de-Gaulle (anciennement place de l''Etoile), au sommet des Champs-Elysees.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000003', 'Place Charles-de-Gaulle (l''Etoile)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000003', 'Place de la Concorde', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000003', 'Place de la Bastille', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000003', 'Place de la Republique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000004', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Combien la France a-t-elle de cotes maritimes (en simplifie) ?',
 'La France a trois facades maritimes : mer du Nord/Manche au nord, ocean Atlantique a l''ouest, mer Mediterranee au sud, plus les outre-mer.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000004', 'Trois grandes facades maritimes', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000004', 'Aucune', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000004', 'Une seule', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000004', 'Dix differentes', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000005', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Comment s''appelle le fleuve qui traverse Paris ?',
 'La Seine traverse Paris d''est en ouest. Elle a faconne le paysage parisien et borde de nombreux monuments (Notre-Dame, Louvre, tour Eiffel).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000005', 'La Seine', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000005', 'La Loire', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000005', 'Le Rhone', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000005', 'La Garonne', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000006', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quel monument celebre a ete inaugure en 1889 ?',
 'La tour Eiffel a ete construite pour l''Exposition universelle de 1889 a Paris, pour celebrer le centenaire de la Revolution francaise. Elle mesure 330 m de haut.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000006', 'La tour Eiffel', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000006', 'Le Pantheon', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000006', 'L''Arc de Triomphe', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000006', 'La basilique du Sacre-Coeur', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000007', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Que represente le drapeau francais ?',
 'Le drapeau francais (bleu-blanc-rouge) est l''embleme de la Republique. Adopte en 1794, il symbolise l''union du peuple (bleu et rouge, couleurs de Paris) et de la royaute (blanc).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000007', 'Le drapeau de la Republique francaise', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000007', 'Le drapeau d''une region', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000007', 'Un drapeau europeen', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000007', 'Le drapeau de Paris', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000008', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quel hymne national est chante en France ?',
 'La Marseillaise est l''hymne national francais. Compose en 1792 a Strasbourg par Rouget de Lisle, il a ete adopte definitivement par la IIIe Republique.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000008', 'La Marseillaise', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000008', 'God Save the Queen', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000008', 'L''Ode a la joie', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000008', 'L''Internationale', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000009', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quelle est la devise de la Republique francaise ?',
 'La devise de la Republique francaise est ''Liberte, Egalite, Fraternite''. Elle est inscrite dans la Constitution (article 2).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000009', 'Liberte, Egalite, Fraternite', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000009', 'Travail, Famille, Patrie', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000009', 'Un pour tous, tous pour un', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000009', 'In God we trust', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000000a', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quel symbole feminin represente la Republique francaise ?',
 'Marianne est l''allegorie de la Republique francaise. On la trouve sur les timbres, les pieces, dans les mairies. Elle porte souvent un bonnet phrygien.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000000a', 'Marianne', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000000a', 'Jeanne d''Arc', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000000a', 'Brigitte Bardot', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000000a', 'La Vierge Marie', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000000b', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quel coq est un embleme animal de la France ?',
 'Le coq gaulois est un embleme officieux de la France. On le retrouve sur les maillots de l''equipe de France de football et de rugby.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000000b', 'Le coq gaulois', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000000b', 'L''aigle imperial', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000000b', 'Le lion britannique', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000000b', 'L''ours russe', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000000c', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quel evenement annuel sportif passe par les Champs-Elysees ?',
 'L''arrivee finale du Tour de France de cyclisme, course mythique creee en 1903, se fait traditionnellement sur les Champs-Elysees a Paris.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000000c', 'L''arrivee du Tour de France', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000000c', 'Roland-Garros', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000000c', 'Le marathon de Paris', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000000c', 'Les 24 heures du Mans', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000000d', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quel tournoi de tennis est joue a Paris ?',
 'Roland-Garros est le tournoi de tennis francais du Grand Chelem, joue chaque annee sur terre battue a Paris (Porte d''Auteuil), en mai-juin.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000000d', 'Roland-Garros', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000000d', 'Wimbledon', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000000d', 'US Open', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000000d', 'Australian Open', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000000e', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quel sport collectif est tres populaire en France ?',
 'Le football est le sport le plus populaire en France. L''equipe de France masculine a remporte la Coupe du monde en 1998 et 2018.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000000e', 'Le football', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000000e', 'Le base-ball', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000000e', 'Le cricket', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000000e', 'Le golf', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000000f', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quel produit alimentaire est emblematique de la France ?',
 'Plusieurs produits sont emblematiques de la cuisine francaise : la baguette de pain, le fromage (camembert, brie, roquefort), le vin, le foie gras, les croissants.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000000f', 'La baguette de pain', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000000f', 'Le riz blanc', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000000f', 'Le hamburger', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000000f', 'Le sushi', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000010', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quel jour ferie celebre la victoire des Allies en 1945 ?',
 'Le 8 mai est ferie en France. Il commemore la victoire des Allies sur l''Allemagne nazie, le 8 mai 1945, qui a mis fin a la Seconde Guerre mondiale en Europe.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000010', 'Le 8 mai', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000010', 'Le 11 novembre', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000010', 'Le 14 juillet', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000010', 'Le 1er mai', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000011', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Que celebre-t-on le 1er mai en France ?',
 'Le 1er mai est la fete du Travail. C''est un jour ferie en France. On y offre traditionnellement du muguet.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000011', 'La fete du Travail', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000011', 'La fete nationale', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000011', 'L''armistice', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000011', 'La fete de l''Europe', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000012', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quelle fete est celebree le 1er janvier en France ?',
 'Le 1er janvier marque le jour de l''An (debut de l''annee civile). C''est un jour ferie. On souhaite la bonne annee a ses proches.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000012', 'Le jour de l''An', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000012', 'Noel', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000012', 'Paques', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000012', 'L''Ascension', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000013', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quel saint celebre la fete de la Toussaint, jour ferie ?',
 'La Toussaint, le 1er novembre, est un jour ferie en France. C''est une fete catholique qui honore tous les saints.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000013', 'Tous les saints (fete catholique)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000013', 'Saint Nicolas', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000013', 'Saint Patrick', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000013', 'Saint Valentin', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000014', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quelle ville accueille la cathedrale de Notre-Dame, restauree apres l''incendie de 2019 ?',
 'Notre-Dame de Paris, gravement endommagee par un incendie en avril 2019, a ete rouverte au public le 7 decembre 2024 apres une restauration majeure.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000014', 'Paris', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000014', 'Reims', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000014', 'Strasbourg', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000014', 'Lyon', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000015', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quelle ville celebre est connue pour ses festivals de cinema ?',
 'Cannes accueille chaque annee en mai le Festival international du film, l''un des plus prestigieux au monde. La Palme d''or y est decernee.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000015', 'Cannes (Festival du film)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000015', 'Lille', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000015', 'Brest', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000015', 'Limoges', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000016', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quelle ville francaise est appelee la ''capitale des Alpes'' ?',
 'Grenoble est souvent qualifiee de ''capitale des Alpes'', en raison de sa position au coeur du massif et de son role economique et universitaire dans la region.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000016', 'Grenoble', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000016', 'Lyon', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000016', 'Nice', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000016', 'Annecy', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000017', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quelle region est celebre pour ses vins (Bordeaux, etc.) ?',
 'La Nouvelle-Aquitaine, autour de Bordeaux, est une des plus grandes regions viticoles de France. D''autres regions viticoles celebres : Bourgogne, Champagne, Alsace, vallee du Rhone.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000017', 'La Nouvelle-Aquitaine (region de Bordeaux)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000017', 'L''Ile-de-France', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000017', 'Le Nord', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000017', 'La Bretagne', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000018', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quelle region a comme capitale Strasbourg et est proche de l''Allemagne ?',
 'Le Grand Est (anciennes regions Alsace, Lorraine, Champagne-Ardenne), avec Strasbourg pour capitale, est frontaliere de l''Allemagne, du Luxembourg, de la Belgique et de la Suisse.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000018', 'Le Grand Est', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000018', 'La Bretagne', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000018', 'La Provence', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000018', 'L''Ile-de-France', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000019', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quel evenement historique a eu lieu sur les plages de Normandie en 1944 ?',
 'Le debarquement allie en Normandie a eu lieu le 6 juin 1944 (D-Day). Il a marque le debut de la liberation de la France et de l''Europe occidentale par les forces alliees.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000019', 'Le debarquement des Allies (6 juin 1944)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000019', 'La Revolution francaise', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000019', 'La Premiere Guerre mondiale', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000019', 'L''expedition d''Egypte', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000001a', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quelle reine francaise est connue pour avoir ete decapitee en 1793 ?',
 'Marie-Antoinette, epouse de Louis XVI, a ete guillotinee le 16 octobre 1793 pendant la Revolution francaise.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000001a', 'Marie-Antoinette', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000001a', 'Catherine de Medicis', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000001a', 'Jeanne d''Arc', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000001a', 'Eleonore d''Aquitaine', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000001b', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quel general francais a appele a la resistance le 18 juin 1940 depuis Londres ?',
 'Charles de Gaulle a lance l''appel du 18 juin 1940 depuis la BBC a Londres, appelant les Francais a poursuivre le combat contre l''occupation nazie. Cet appel a fonde la France libre.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000001b', 'Charles de Gaulle', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000001b', 'Philippe Petain', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000001b', 'Joseph Joffre', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000001b', 'Ferdinand Foch', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000001c', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quel roi est dit le ''Roi-Soleil'' ?',
 'Louis XIV, qui a regne de 1643 a 1715, est surnomme le ''Roi-Soleil''. Il a fait construire le chateau de Versailles et a marque le rayonnement de la France au XVIIe siecle.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000001c', 'Louis XIV (Roi-Soleil)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000001c', 'Louis XVI', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000001c', 'Henri IV', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000001c', 'Francois Ier', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000001d', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Ou se trouve le chateau de Versailles ?',
 'Le chateau de Versailles est situe a Versailles, dans les Yvelines, a environ 20 km au sud-ouest de Paris. C''etait la residence des rois de France de Louis XIV a Louis XVI.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000001d', 'A Versailles, pres de Paris', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000001d', 'A Paris meme', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000001d', 'A Lyon', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000001d', 'A Marseille', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000001e', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Qui a peint la Joconde, exposee au Louvre ?',
 'La Joconde (Mona Lisa) a ete peinte par Leonard de Vinci, peintre italien venu finir ses jours en France a la cour de Francois Ier (debut XVIe siecle).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000001e', 'Leonard de Vinci', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000001e', 'Pablo Picasso', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000001e', 'Claude Monet', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000001e', 'Vincent Van Gogh', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000001f', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Qui etait Jeanne d''Arc, heroine francaise ?',
 'Jeanne d''Arc (1412-1431) est une heroine francaise du Moyen Age. Elle a libere Orleans, conduit Charles VII a Reims pour son sacre, puis a ete brulee vive a Rouen.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000001f', 'Une heroine francaise du XVe siecle', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000001f', 'Une reine de France', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000001f', 'Une scientifique', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000001f', 'Une chanteuse', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000020', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quel celebre scientifique francaise a recu deux prix Nobel ?',
 'Marie Curie (1867-1934), francaise d''origine polonaise, a obtenu le prix Nobel de physique (1903) et de chimie (1911). Elle a decouvert la radioactivite avec son mari Pierre Curie.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000020', 'Marie Curie', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000020', 'Marie-Antoinette', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000020', 'Edith Piaf', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000020', 'Coco Chanel', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000021', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quel chien francais est associe a Louis Pasteur ?',
 'Louis Pasteur (1822-1895), chimiste et biologiste francais, a invente le vaccin contre la rage en 1885. Il a aussi mis au point la pasteurisation.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000021', 'Le chien vaccine contre la rage (Pasteur, 1885)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000021', 'Le berger allemand', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000021', 'Le caniche royal', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000021', 'Aucun chien specifique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000022', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quelle femme politique francaise a porte la loi sur l''IVG en 1975 ?',
 'Simone Veil (1927-2017), ministre de la Sante, a fait adopter la loi du 17 janvier 1975 depenalisant l''IVG (avortement). Elle est entree au Pantheon en 2018.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000022', 'Simone Veil', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000022', 'Simone de Beauvoir', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000022', 'Edith Cresson', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000022', 'Olympe de Gouges', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000023', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Comment appelle-t-on en France un pain long et croustillant typique ?',
 'La baguette est le pain emblematique de la France. Inscrite au patrimoine culturel immateriel de l''UNESCO en 2022.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000023', 'La baguette', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000023', 'La galette', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000023', 'Le bagel', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000023', 'Le pain de mie', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000024', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quel fromage francais est produit en Normandie ?',
 'Le camembert est un fromage normand emblematique, fabrique a base de lait de vache. La Normandie produit aussi le livarot, le pont-l''eveque, le neufchatel.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000024', 'Le camembert', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000024', 'Le parmesan', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000024', 'Le cheddar', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000024', 'La feta', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000025', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quelle viennoiserie est typiquement francaise ?',
 'Le croissant est une viennoiserie emblematique du petit-dejeuner francais. Inventee a Vienne mais popularisee en France au XIXe siecle.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000025', 'Le croissant', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000025', 'Le donut', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000025', 'Le bagel', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000025', 'Le pretzel', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000026', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quelle est la langue officielle de la France ?',
 'Le francais est la seule langue officielle de la Republique francaise (article 2 de la Constitution). Les langues regionales (breton, basque, occitan, corse) appartiennent au patrimoine.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000026', 'Le francais', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000026', 'L''anglais', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000026', 'L''allemand', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000026', 'L''espagnol', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000027', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quelle institution promeut la langue francaise dans le monde ?',
 'La Francophonie (OIF - Organisation internationale de la Francophonie) regroupe les pays ayant le francais en partage. Plus de 320 millions de francophones dans le monde.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000027', 'L''Organisation internationale de la Francophonie (OIF)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000027', 'L''ONU', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000027', 'L''OTAN', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000027', 'L''UNESCO', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000028', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
 'Quand a eu lieu la prise de la Bastille ?',
 'La prise de la Bastille a eu lieu le 14 juillet 1789. Cet evenement symbolique du debut de la Revolution francaise est commemore comme fete nationale.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000028', 'Le 14 juillet 1789', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000028', 'Le 4 aout 1789', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000028', 'Le 26 aout 1789', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000028', 'Le 14 juillet 1880', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000029', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'MISE_SITUATION',
 'Je veux visiter un monument historique francais celebre. Quels lieux gratuits ou peu chers existent ?',
 'Beaucoup de monuments offrent acces gratuit le 1er dimanche du mois (notamment musees nationaux). Les Journees du patrimoine en septembre permettent d''entrer dans des lieux d''ordinaire fermes.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000029', 'Le 1er dimanche du mois ou les Journees du patrimoine', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000029', 'Aucune visite gratuite', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000029', 'Uniquement avec un guide paye', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000029', 'Uniquement les militaires', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000002a', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'MISE_SITUATION',
 'On me demande de citer un fleuve qui se jette dans la Mediterranee. Lequel choisir ?',
 'Le Rhone est le fleuve francais qui se jette dans la mer Mediterranee (apres Lyon, vers Marseille/la Camargue). Les autres grands fleuves (Seine, Loire, Garonne) se jettent dans l''Atlantique.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000002a', 'Le Rhone', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000002a', 'La Seine', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000002a', 'La Loire', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000002a', 'La Garonne', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000002b', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'MISE_SITUATION',
 'Quelle attitude adopter face a la Marseillaise lors d''une ceremonie publique ?',
 'Il est d''usage de se tenir debout et silencieux pendant la Marseillaise. C''est une marque de respect envers l''hymne national et envers les personnes presentes a la ceremonie.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000002b', 'Se lever et rester silencieux par respect', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000002b', 'Continuer ses conversations', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000002b', 'Sortir de la salle', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000002b', 'Mettre une musique differente', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000002c', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'MISE_SITUATION',
 'Je veux participer aux Journees du patrimoine. Quand ont-elles lieu ?',
 'Les Journees europeennes du patrimoine ont lieu chaque annee le troisieme week-end de septembre. De nombreux monuments publics et prives ouvrent leurs portes gratuitement.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000002c', 'Le troisieme week-end de septembre', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000002c', 'Le 14 juillet', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000002c', 'Au mois de mai', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000002c', 'A Noel', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000002d', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'MISE_SITUATION',
 'Quel comportement avoir devant un monument historique ou un musee ?',
 'Il faut respecter les lieux : ne pas toucher les oeuvres, ne pas faire de bruit, suivre les indications, ne pas voler ni degrader. Certaines photos peuvent etre interdites.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000002d', 'Respect des lieux, des regles, et silence', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000002d', 'Toucher les oeuvres', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000002d', 'Faire la fete bruyamment', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000002d', 'Voler des souvenirs', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000002e', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'MISE_SITUATION',
 'On me demande pourquoi le 14 juillet est important. Que dire ?',
 'Le 14 juillet est la fete nationale francaise. Il commemore la prise de la Bastille en 1789 (debut de la Revolution) et la fete de la Federation en 1790 (union nationale).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000002e', 'Fete nationale (prise de la Bastille en 1789)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000002e', 'Anniversaire du roi', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000002e', 'Jour de la rentree scolaire', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000002e', 'Jour de l''Europe', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000002f', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'MISE_SITUATION',
 'Je veux assister a un defile militaire francais. Quel jour est-ce traditionnel ?',
 'Le defile militaire du 14 juillet sur les Champs-Elysees a Paris est le grand defile national francais. D''autres ceremonies ont lieu dans les villes de garnison.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000002f', 'Le 14 juillet (defile sur les Champs-Elysees)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000002f', 'Le 1er janvier', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000002f', 'Le 25 decembre', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000002f', 'Le 1er avril', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000030', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'MISE_SITUATION',
 'J''apprends que le 11 novembre est ferie. Pourquoi est-il important ?',
 'Le 11 novembre commemore l''armistice signe en 1918, qui a mis fin a la Premiere Guerre mondiale. C''est l''occasion d''honorer les soldats morts pour la France et de cultiver la memoire.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000030', 'Armistice de 1918 et hommage aux soldats morts', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000030', 'Fete des familles', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000030', 'Naissance d''un president', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000030', 'Independance de l''Algerie', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000031', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'MISE_SITUATION',
 'Quelqu''un me dit que la France est une monarchie. Comment lui repondre ?',
 'Non, la France n''est plus une monarchie depuis 1870 (chute de Napoleon III). Aujourd''hui, c''est une republique democratique semi-presidentielle, sous la Ve Republique depuis 1958.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000031', 'Non, la France est une republique depuis 1870', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000031', 'Oui, le roi gouverne', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000031', 'Cela depend du jour', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000031', 'C''est une monarchie d''Europe', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000032', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CSP', 'MISE_SITUATION',
 'Je veux ecouter de la musique francaise classique. Quels compositeurs ?',
 'Parmi les grands compositeurs francais : Claude Debussy, Maurice Ravel, Hector Berlioz, Georges Bizet (Carmen), Camille Saint-Saens, Erik Satie.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000032', 'Debussy, Ravel, Berlioz, Bizet', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000032', 'Mozart, Bach, Beethoven', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000032', 'Verdi, Puccini, Rossini', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000032', 'Aucun compositeur francais celebre', FALSE, 3);
