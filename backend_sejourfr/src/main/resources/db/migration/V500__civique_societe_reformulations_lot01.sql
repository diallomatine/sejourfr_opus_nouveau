-- Flyway: reformulations theme 5 SOCIETE lot 1/2 (R01-R15) - is_active=FALSE

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-000000000001', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Quel numero d''urgence permet d''appeler le SAMU (urgences medicales) ?',
 'Le 15 est le numero du SAMU (service d''aide medicale urgente). Il est gratuit et accessible 24h/24.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000001', 'Le 15', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000001', 'Le 17', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000001', 'Le 18', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000001', 'Le 112', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-000000000002', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Quel numero d''urgence permet d''appeler les pompiers en France ?',
 'Le 18 est le numero des pompiers en France. Il est gratuit et accessible 24h/24.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000002', 'Le 18', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000002', 'Le 15', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000002', 'Le 17', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000002', 'Le 112', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-000000000003', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Que designe un numero d''urgence en France ?',
 'Un numero d''urgence est un numero court, gratuit, accessible 24h/24, qui permet d''appeler les services de secours (police 17, pompiers 18, SAMU 15, urgence europeenne 112).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000003', 'Un numero gratuit pour joindre les secours 24h/24', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000003', 'Un numero payant', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000003', 'Un numero reserve aux fonctionnaires', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000003', 'Un numero europeen uniquement', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-000000000004', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'MISE_SITUATION',
 'Apres avoir obtenu le permis de conduire, que faut-il faire pour conduire legalement ?',
 'Il faut s''assurer (assurance auto obligatoire), avoir le certificat d''immatriculation (carte grise) du vehicule, respecter le Code de la route, et avoir un controle technique a jour.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000004', 'S''assurer, immatriculer le vehicule, respecter le Code', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000004', 'Rien d''autre', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000004', 'Acheter un nouveau vehicule chaque annee', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000004', 'Demander a la mairie', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-000000000005', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'A quelles conditions un mariage civil est-il valable en France ?',
 'Le mariage civil est valable si : les deux personnes sont majeures, libres (non mariees ailleurs), consentantes, sans lien de parente proche, et que le mariage est celebre par un officier d''etat civil (maire/adjoint).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000005', 'Majeurs, libres, consentants, sans empechement, devant officier', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000005', 'Avec accord de l''employeur', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000005', 'Apres 2 ans de cohabitation seulement', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000005', 'Sans aucune formalite', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-000000000006', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'MISE_SITUATION',
 'Quand doit-on declarer la naissance d''un enfant a l''etat civil ?',
 'La declaration de naissance doit etre faite dans les 5 jours qui suivent la naissance (ou 8 jours pour l''outre-mer), a la mairie du lieu de naissance, par le pere ou un proche.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000006', 'Dans les 5 jours suivant la naissance', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000006', 'Dans l''annee', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000006', 'A la majorite de l''enfant', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000006', 'Aucune declaration', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-000000000007', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Que designe le ''travail non declare'' en droit francais ?',
 'Le travail non declare (travail dissimule, travail au noir) est l''exercice d''une activite remuneree sans declaration aux organismes sociaux et fiscaux. C''est un delit puni par la loi.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000007', 'Un travail sans declaration, illegal et puni', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000007', 'Un travail legal', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000007', 'Un travail benevole', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000007', 'Un travail saisonnier autorise', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-000000000008', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Comment un employeur doit-il fixer le salaire d''un salarie ?',
 'Le salaire doit respecter le SMIC (minimum legal), la convention collective applicable (qui peut fixer un minimum superieur), et le contrat de travail. Il doit etre verse mensuellement.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000008', 'Respecter le SMIC, la convention collective et le contrat', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000008', 'Comme il veut, sans regle', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000008', 'Au moins 5000 EUR pour tous', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000008', 'Aleatoire selon l''humeur', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-000000000009', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Que designe le SMIC en France ?',
 'Le SMIC (Salaire minimum interprofessionnel de croissance) est le salaire horaire minimum legal en France. Il est revalorise chaque annee (au 1er janvier) en fonction de l''inflation.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000009', 'Le salaire horaire minimum legal en France', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000009', 'Un syndicat', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000009', 'Une cotisation sociale', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000009', 'Un type d''emploi', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-00000000000a', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'MISE_SITUATION',
 'Quelle est la premiere demarche pour rechercher un emploi en France ?',
 'S''inscrire a France Travail (ex Pole emploi) permet de beneficier d''un accompagnement, d''offres d''emploi, et eventuellement d''une indemnisation chomage si on a deja cotise.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000000a', 'S''inscrire a France Travail', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000000a', 'Acheter un journal', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000000a', 'Demander a la mairie', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000000a', 'Aucune demarche specifique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-00000000000b', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Quelle est la duree legale du travail hebdomadaire en France ?',
 'La duree legale du travail est de 35 heures par semaine pour un salarie a temps plein. Au-dela, ce sont des heures supplementaires (majorees).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000000b', '35 heures par semaine', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000000b', '40 heures par semaine', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000000b', '20 heures par semaine', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000000b', '60 heures par semaine', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-00000000000c', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Qui est accompagne par France Travail (ex Pole emploi) ?',
 'France Travail accompagne les personnes en recherche d''emploi : chomeurs (avec ou sans indemnites), salaries cherchant a changer de poste, jeunes diplomes, personnes en reconversion.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000000c', 'Les personnes en recherche d''emploi', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000000c', 'Les enfants', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000000c', 'Uniquement les patrons', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000000c', 'Uniquement les retraites', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-00000000000d', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'MISE_SITUATION',
 'Une personne etrangere en situation reguliere peut-elle creer son entreprise en France ?',
 'Oui. Une personne etrangere en situation reguliere peut creer son entreprise en France. Certains titres de sejour permettent expressement l''exercice d''une activite professionnelle.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000000d', 'Oui, en situation reguliere', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000000d', 'Non, c''est interdit', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000000d', 'Uniquement avec un visa special', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000000d', 'Uniquement les Europeens', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-00000000000e', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'MISE_SITUATION',
 'Une femme peut-elle creer son entreprise en France ?',
 'Oui. Les femmes ont exactement les memes droits que les hommes pour creer une entreprise. Il n''existe aucune restriction liee au sexe. Diverses aides existent meme pour encourager l''entrepreneuriat feminin.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000000e', 'Oui, comme tout le monde, avec des aides specifiques possibles', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000000e', 'Non, c''est reserve aux hommes', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000000e', 'Uniquement avec accord du conjoint', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000000e', 'Uniquement apres 30 ans', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-00000000000f', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'A quel age un mineur peut-il commencer a travailler en France ?',
 'Un mineur peut travailler a partir de 14 ans pour des travaux legers et adaptes, avec autorisation parentale. A partir de 16 ans, il peut etre apprenti ou salarie ordinaire (avec encore des restrictions).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000000f', '14 ans (travaux legers), 16 ans (salarie/apprenti)', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000000f', '12 ans', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000000f', '18 ans uniquement', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000000f', '10 ans', FALSE, 3);
