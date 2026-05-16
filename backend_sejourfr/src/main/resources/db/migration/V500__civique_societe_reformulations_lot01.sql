-- Flyway: reformulations thème 5 SOCIÉTÉ lot 1/2 (R01-R15) - is_active=FALSE

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-000000000001', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Quel numéro d''urgence permet d''appeler le SAMU (urgences médicales) ?',
 'Le 15 est le numéro du SAMU (service d''aide médicale urgente). Il est gratuit et accessible 24h/24.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000001', 'Le 15', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000001', 'Le 17', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000001', 'Le 18', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000001', 'Le 112', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-000000000002', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Quel numéro d''urgence permet d''appeler les pompiers en France ?',
 'Le 18 est le numéro des pompiers en France. Il est gratuit et accessible 24h/24.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000002', 'Le 18', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000002', 'Le 15', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000002', 'Le 17', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000002', 'Le 112', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-000000000003', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Que désigne un numéro d''urgence en France ?',
 'Un numéro d''urgence est un numéro court, gratuit, accessible 24h/24, qui permet d''appeler les services de secours (police 17, pompiers 18, SAMU 15, urgence européenne 112).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000003', 'Un numéro gratuit pour joindre les secours 24h/24', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000003', 'Un numéro payant', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000003', 'Un numéro réservé aux fonctionnaires', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000003', 'Un numéro européen uniquement', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-000000000004', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'MISE_SITUATION',
 'Après avoir obtenu le permis de conduire, que faut-il faire pour conduire légalement ?',
 'Il faut s''assurer (assurance auto obligatoire), avoir le certificat d''immatriculation (carte grise) du véhicule, respecter le Code de la route, et avoir un contrôle technique à jour.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000004', 'S''assurer, immatriculer le véhicule, respecter le Code', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000004', 'Rien d''autre', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000004', 'Acheter un nouveau véhicule chaque année', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000004', 'Demander à la mairie', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-000000000005', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'À quelles conditions un mariage civil est-il valable en France ?',
 'Le mariage civil est valable si : les deux personnes sont majeures, libres (non mariées ailleurs), consentantes, sans lien de parenté proche, et que le mariage est célébré par un officier d''état civil (maire/adjoint).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000005', 'Majeurs, libres, consentants, sans empêchement, devant officier', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000005', 'Avec accord de l''employeur', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000005', 'Après 2 ans de cohabitation seulement', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000005', 'Sans aucune formalité', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-000000000006', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'MISE_SITUATION',
 'Quand doit-on déclarer la naissance d''un enfant à l''état civil ?',
 'La déclaration de naissance doit être faite dans les 5 jours qui suivent la naissance (ou 8 jours pour l''outre-mer), à la mairie du lieu de naissance, par le père ou un proche.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000006', 'Dans les 5 jours suivant la naissance', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000006', 'Dans l''année', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000006', 'À la majorité de l''enfant', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000006', 'Aucune déclaration', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-000000000007', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Que désigne le ''travail non déclaré'' en droit français ?',
 'Le travail non déclaré (travail dissimulé, travail au noir) est l''exercice d''une activité rémunérée sans déclaration aux organismes sociaux et fiscaux. C''est un délit puni par la loi.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000007', 'Un travail sans déclaration, illégal et puni', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000007', 'Un travail légal', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000007', 'Un travail bénévole', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000007', 'Un travail saisonnier autorisé', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-000000000008', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Comment un employeur doit-il fixer le salaire d''un salarié ?',
 'Le salaire doit respecter le SMIC (minimum légal), la convention collective applicable (qui peut fixer un minimum supérieur), et le contrat de travail. Il doit être versé mensuellement.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000008', 'Respecter le SMIC, la convention collective et le contrat', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000008', 'Comme il veut, sans règle', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000008', 'Au moins 5000 EUR pour tous', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000008', 'Aléatoire selon l''humeur', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-000000000009', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Que désigne le SMIC en France ?',
 'Le SMIC (Salaire minimum interprofessionnel de croissance) est le salaire horaire minimum légal en France. Il est revalorisé chaque année (au 1er janvier) en fonction de l''inflation.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000009', 'Le salaire horaire minimum légal en France', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000009', 'Un syndicat', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000009', 'Une cotisation sociale', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000009', 'Un type d''emploi', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-00000000000a', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'MISE_SITUATION',
 'Quelle est la première démarche pour rechercher un emploi en France ?',
 'S''inscrire à France Travail (ex Pôle emploi) permet de bénéficier d''un accompagnement, d''offres d''emploi, et éventuellement d''une indemnisation chômage si on a déjà cotisé.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000000a', 'S''inscrire à France Travail', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000000a', 'Acheter un journal', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000000a', 'Demander à la mairie', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000000a', 'Aucune démarche spécifique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-00000000000b', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Quelle est la durée légale du travail hebdomadaire en France ?',
 'La durée légale du travail est de 35 heures par semaine pour un salarié à temps plein. Au-delà, ce sont des heures supplémentaires (majorées).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000000b', '35 heures par semaine', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000000b', '40 heures par semaine', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000000b', '20 heures par semaine', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000000b', '60 heures par semaine', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-00000000000c', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Qui est accompagné par France Travail (ex Pôle emploi) ?',
 'France Travail accompagne les personnes en recherche d''emploi : chômeurs (avec ou sans indemnités), salariés cherchant à changer de poste, jeunes diplômés, personnes en reconversion.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000000c', 'Les personnes en recherche d''emploi', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000000c', 'Les enfants', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000000c', 'Uniquement les patrons', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000000c', 'Uniquement les retraités', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-00000000000d', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'MISE_SITUATION',
 'Une personne étrangère en situation régulière peut-elle créer son entreprise en France ?',
 'Oui. Une personne étrangère en situation régulière peut créer son entreprise en France. Certains titres de séjour permettent expressément l''exercice d''une activité professionnelle.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000000d', 'Oui, en situation régulière', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000000d', 'Non, c''est interdit', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000000d', 'Uniquement avec un visa spécial', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000000d', 'Uniquement les Européens', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-00000000000e', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'MISE_SITUATION',
 'Une femme peut-elle créer son entreprise en France ?',
 'Oui. Les femmes ont exactement les mêmes droits que les hommes pour créer une entreprise. Il n''existe aucune restriction liée au sexe. Diverses aides existent même pour encourager l''entrepreneuriat féminin.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000000e', 'Oui, comme tout le monde, avec des aides spécifiques possibles', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000000e', 'Non, c''est réservé aux hommes', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000000e', 'Uniquement avec accord du conjoint', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000000e', 'Uniquement après 30 ans', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-00000000000f', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'À quel âge un mineur peut-il commencer à travailler en France ?',
 'Un mineur peut travailler à partir de 14 ans pour des travaux légers et adaptés, avec autorisation parentale. À partir de 16 ans, il peut être apprenti ou salarié ordinaire (avec encore des restrictions).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000000f', '14 ans (travaux légers), 16 ans (salarié/apprenti)', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000000f', '12 ans', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000000f', '18 ans uniquement', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000000f', '10 ans', FALSE, 3);
