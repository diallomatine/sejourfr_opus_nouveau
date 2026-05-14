-- Flyway: reformulations theme 3 DROITS_DEVOIRS lot 1/2 (R01-R15) - is_active=FALSE

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000001-0000-0000-0000-000000000001', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Quel est le nom de la Constitution actuellement en vigueur en France ?',
 'La Constitution actuelle est celle de la Ve Republique, adoptee en 1958 sous l''impulsion du general de Gaulle.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000001', 'La Constitution de 1958 (Ve Republique)', TRUE, 0),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000001', 'La Constitution de 1791', FALSE, 1),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000001', 'La Charte de 1830', FALSE, 2),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000001', 'Le Code Napoleon', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000001-0000-0000-0000-000000000002', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Quel document presente les droits et devoirs des personnes residant en France ?',
 'Le Livret du citoyen (et la Charte des droits et devoirs du citoyen francais pour les naturalisations) presente les droits et devoirs essentiels des residents en France.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000002', 'Le Livret du citoyen', TRUE, 0),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000002', 'Le Code de la route', FALSE, 1),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000002', 'La Bible', FALSE, 2),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000002', 'Le Code Napoleon', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000001-0000-0000-0000-000000000003', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Concernant les droits individuels, quelle affirmation est exacte ?',
 'Les droits individuels (liberte, surete, propriete) sont reconnus a toute personne en France. Ils peuvent etre limites par la loi pour proteger l''ordre public et les droits d''autrui.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000003', 'Ils sont reconnus a tous, dans les limites posees par la loi', TRUE, 0),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000003', 'Ils n''existent pas en France', FALSE, 1),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000003', 'Ils sont reserves aux Francais', FALSE, 2),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000003', 'Ils sont absolus, sans aucune limite', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000001-0000-0000-0000-000000000004', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'En quelle annee la Declaration des droits de l''homme et du citoyen a-t-elle ete adoptee ?',
 'La Declaration des droits de l''homme et du citoyen a ete adoptee le 26 aout 1789, pendant la Revolution francaise.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000004', '1789', TRUE, 0),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000004', '1789 (annee de la Revolution francaise)', FALSE, 1),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000004', '1804', FALSE, 2),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000004', '1848', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000001-0000-0000-0000-000000000005', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Parmi ces droits, lequel est considere comme un droit fondamental ?',
 'Le droit a la vie, a la liberte et a la surete sont des droits fondamentaux, reconnus notamment par la Declaration de 1789 et la Constitution.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000005', 'Le droit a la liberte', TRUE, 0),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000005', 'Le droit de gagner aux jeux d''argent', FALSE, 1),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000005', 'Le droit de stationnement gratuit', FALSE, 2),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000005', 'Le droit d''avoir un animal exotique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000001-0000-0000-0000-000000000006', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Parmi ces textes, lequel garantit les droits et libertes en France ?',
 'La Constitution (preambule et bloc de constitutionnalite, incluant la DDHC de 1789) garantit les droits et libertes fondamentaux.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000006', 'La Constitution et la Declaration de 1789', TRUE, 0),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000006', 'Le code de la consommation', FALSE, 1),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000006', 'Le menu d''un restaurant', FALSE, 2),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000006', 'Le permis de conduire', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000001-0000-0000-0000-000000000007', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Que signifie la liberte d''expression en France ?',
 'La liberte d''expression permet d''exprimer ses opinions par la parole, l''ecrit ou l''image, dans les limites posees par la loi (interdiction de la diffamation, de l''incitation a la haine).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000007', 'Le droit d''exprimer ses opinions, dans les limites de la loi', TRUE, 0),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000007', 'Le droit d''insulter qui on veut', FALSE, 1),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000007', 'Une liberte reservee aux journalistes', FALSE, 2),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000007', 'Une liberte sans aucune limite', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000001-0000-0000-0000-000000000008', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Quel droit permet de se defendre devant un tribunal en France ?',
 'Le droit a un proces equitable inclut le droit a la defense : etre assiste par un avocat, presenter sa version, contredire les preuves. C''est un droit fondamental.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000008', 'Le droit a la defense (proces equitable)', TRUE, 0),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000008', 'Le droit a la propriete', FALSE, 1),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000008', 'Le droit de voter', FALSE, 2),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000008', 'Le droit a la sante', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000001-0000-0000-0000-000000000009', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Quel texte historique etablit les droits et devoirs fondamentaux des citoyens en France ?',
 'La Declaration des droits de l''homme et du citoyen de 1789 est le texte fondateur. Elle est integree au bloc de constitutionnalite et a aujourd''hui valeur constitutionnelle.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000009', 'La Declaration des droits de l''homme et du citoyen de 1789', TRUE, 0),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000009', 'Le Code Napoleon', FALSE, 1),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000009', 'La Magna Carta', FALSE, 2),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000009', 'La Charte de l''environnement', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000001-0000-0000-0000-00000000000a', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Quel texte fondateur a ete adopte pendant la Revolution francaise ?',
 'La Declaration des droits de l''homme et du citoyen, adoptee le 26 aout 1789, est le texte symbole de la Revolution francaise.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000001-0000-0000-0000-00000000000a', 'La Declaration des droits de l''homme et du citoyen (1789)', TRUE, 0),
(gen_random_uuid(), 'f3000001-0000-0000-0000-00000000000a', 'Le Code civil', FALSE, 1),
(gen_random_uuid(), 'f3000001-0000-0000-0000-00000000000a', 'La Constitution de 1958', FALSE, 2),
(gen_random_uuid(), 'f3000001-0000-0000-0000-00000000000a', 'Le Code penal', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000001-0000-0000-0000-00000000000b', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Quelle liberte autorise une personne a ne pratiquer aucune religion ?',
 'La liberte de conscience inclut le droit de ne pas croire (etre athee, agnostique). Personne ne peut etre force d''adherer a une religion.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000001-0000-0000-0000-00000000000b', 'La liberte de conscience', TRUE, 0),
(gen_random_uuid(), 'f3000001-0000-0000-0000-00000000000b', 'La liberte de circulation', FALSE, 1),
(gen_random_uuid(), 'f3000001-0000-0000-0000-00000000000b', 'La liberte de commerce', FALSE, 2),
(gen_random_uuid(), 'f3000001-0000-0000-0000-00000000000b', 'La liberte de la presse', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000001-0000-0000-0000-00000000000c', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Une femme peut-elle recourir a une interruption volontaire de grossesse (IVG) en France ?',
 'Oui. L''IVG est legale en France depuis la loi Veil de 1975. Elle a ete inscrite dans la Constitution en mars 2024 comme liberte fondamentale.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000001-0000-0000-0000-00000000000c', 'Oui, c''est legal depuis 1975 et constitutionnel depuis 2024', TRUE, 0),
(gen_random_uuid(), 'f3000001-0000-0000-0000-00000000000c', 'Non, c''est interdit', FALSE, 1),
(gen_random_uuid(), 'f3000001-0000-0000-0000-00000000000c', 'Uniquement avant 5 semaines', FALSE, 2),
(gen_random_uuid(), 'f3000001-0000-0000-0000-00000000000c', 'Uniquement avec accord du conjoint', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000001-0000-0000-0000-00000000000d', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'MISE_SITUATION',
 'Le divorce est-il toujours possible en France ?',
 'Oui. Le divorce est legal en France depuis 1792 (avec interruption sous la Restauration). Plusieurs procedures existent : par consentement mutuel, pour faute, pour acceptation, pour alteration definitive du lien conjugal.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000001-0000-0000-0000-00000000000d', 'Oui, plusieurs formes de divorce existent', TRUE, 0),
(gen_random_uuid(), 'f3000001-0000-0000-0000-00000000000d', 'Non, c''est interdit', FALSE, 1),
(gen_random_uuid(), 'f3000001-0000-0000-0000-00000000000d', 'Uniquement pour les hommes', FALSE, 2),
(gen_random_uuid(), 'f3000001-0000-0000-0000-00000000000d', 'Uniquement apres 20 ans de mariage', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000001-0000-0000-0000-00000000000e', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Quel est le statut de la peine de mort en France ?',
 'La peine de mort est abolie en France depuis 1981 (loi du 9 octobre 1981, portee par Robert Badinter). L''abolition a ete inscrite dans la Constitution en 2007.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000001-0000-0000-0000-00000000000e', 'Abolie depuis 1981, inscrite dans la Constitution depuis 2007', TRUE, 0),
(gen_random_uuid(), 'f3000001-0000-0000-0000-00000000000e', 'Toujours en vigueur', FALSE, 1),
(gen_random_uuid(), 'f3000001-0000-0000-0000-00000000000e', 'Limitee aux crimes de guerre', FALSE, 2),
(gen_random_uuid(), 'f3000001-0000-0000-0000-00000000000e', 'Decidee par le maire', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000001-0000-0000-0000-00000000000f', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Que dit le droit francais sur les limites possibles aux libertes individuelles ?',
 'Les libertes individuelles ne sont pas absolues. Elles peuvent etre limitees par la loi pour proteger l''ordre public, les droits d''autrui ou la securite nationale.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000001-0000-0000-0000-00000000000f', 'Elles peuvent etre limitees par la loi pour l''ordre public et les droits d''autrui', TRUE, 0),
(gen_random_uuid(), 'f3000001-0000-0000-0000-00000000000f', 'Elles sont absolues sans limite', FALSE, 1),
(gen_random_uuid(), 'f3000001-0000-0000-0000-00000000000f', 'Elles n''existent pas', FALSE, 2),
(gen_random_uuid(), 'f3000001-0000-0000-0000-00000000000f', 'Elles dependent du maire', FALSE, 3);
