-- Flyway: niveau 3 thème 3 DROITS_DEVOIRS - 50 CSP (40 CONN + 10 MS) - is_active=FALSE

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000001', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'CONNAISSANCE',
 'En France, peut-on être arrete sans motif précis ?',
 'Non. Toute privation de liberté doit avoir un fondement légal. La police judiciaire ne peut placer en garde a vue qu''une personne soupconnee d''avoir commis ou tente une infraction.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000001', 'Non, il faut un motif légal', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000001', 'Oui, sans aucune raison', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000001', 'Oui, sur ordre du maire', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000001', 'Oui, le week-end uniquement', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000002', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'CONNAISSANCE',
 'Toute personne accusee d''une infraction peut-elle se taire devant la police ?',
 'Oui. Le droit au silence est un droit fondamental. Une personne en garde a vue à le droit de ne faire aucune déclaration et d''attendre la presence d''un avocat.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000002', 'Oui, le droit au silence est garanti', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000002', 'Non, elle doit tout dire', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000002', 'Uniquement les enfants y ont droit', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000002', 'Uniquement avec accord du maire', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000003', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'CONNAISSANCE',
 'Quel numéro d''urgence permet d''appeler les pompiers en France ?',
 'Le 18 est le numéro des pompiers en France. Il est gratuit et accessible 24h/24.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000003', 'Le 18', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000003', 'Le 17', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000003', 'Le 15', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000003', 'Le 12', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000004', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'CONNAISSANCE',
 'Quel numéro d''urgence permet d''appeler le SAMU (urgences médicales) ?',
 'Le 15 est le numéro du SAMU (service d''aide médicale urgente). Il est gratuit, accessible 24h/24, et joint un médecin regulateur.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000004', 'Le 15', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000004', 'Le 17', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000004', 'Le 18', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000004', 'Le 36 36', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000005', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'CONNAISSANCE',
 'Quel numéro européen permet de joindre toutes les urgences en Europe ?',
 'Le 112 est le numéro d''urgence européen unique, accessible gratuitement dans tous les pays de l''UE. Il peut être utilise pour la police, les pompiers ou le SAMU.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000005', 'Le 112', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000005', 'Le 18', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000005', 'Le 36 36', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000005', 'Le 911', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000006', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'CONNAISSANCE',
 'Quel est l''âge minimum pour conduire une voiture en France ?',
 'L''âge minimum pour conduire une voiture (permis B) est de 18 ans. Une conduite accompagnée est possible des 15 ans, mais l''examen n''est passe qu''à partir de 17 ans dans certains cas.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000006', '18 ans (avec quelques exceptions)', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000006', '16 ans', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000006', '21 ans', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000006', '25 ans', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000007', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'CONNAISSANCE',
 'Le port de la ceinture de sécurité est-il obligatoire en voiture ?',
 'Oui. Le port de la ceinture est obligatoire pour tous les occupants du vehicule (avant et arrière). Ne pas la porter est une infraction passible d''amende.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000007', 'Oui, pour tous les passagers', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000007', 'Non, uniquement le conducteur', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000007', 'Uniquement sur l''autoroute', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000007', 'Uniquement la nuit', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000008', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'CONNAISSANCE',
 'Conduire en état d''ivresse est-il un delit en France ?',
 'Oui. Conduire avec un taux d''alcool supérieur à 0,5 g par litre de sang (0,2 g pour les jeunes conducteurs) est une infraction. Au-dela de 0,8 g, c''est un delit puni de prison.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000008', 'Oui, c''est une infraction sanctionnee', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000008', 'Non, c''est libre', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000008', 'Uniquement la nuit', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000008', 'Uniquement les jours feries', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000009', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'CONNAISSANCE',
 'L''enregistrement audio sans accord d''une personne est-il légal ?',
 'Non, en général. Enregistrer une conversation privée sans le consentement des participants est interdit et puni penalement (article 226-1 du Code pénal).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000009', 'Non, c''est interdit sans consentement', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000009', 'Oui, sans condition', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000009', 'Uniquement en presence d''un avocat', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000009', 'Uniquement sur autoroute', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000000a', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'CONNAISSANCE',
 'Filmer ou photographier une personne sans son accord est-il autorisé ?',
 'Non, en général. Toute personne a droit à son image. Diffuser ou utiliser l''image de quelqu''un sans son accord est une atteinte à la vie privée, punie par la loi.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000000a', 'Non, le droit à l''image protege chacun', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000000a', 'Oui, sans condition', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000000a', 'Oui, dans la rue uniquement', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000000a', 'Oui, si la personne est connue', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000000b', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'CONNAISSANCE',
 'Voler quelque chose dans un magasin est-il une infraction ?',
 'Oui. Le vol est un delit (article 311-1 du Code pénal), puni de jusqu''à 3 ans de prison et 45 000 EUR d''amende, plus selon les circonstances (vol avec violence, en bande, etc.).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000000b', 'Oui, c''est un delit puni penalement', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000000b', 'Non, c''est gratuit en cas d''oubli', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000000b', 'Uniquement pour des sommes supérieures à 100 EUR', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000000b', 'Uniquement la nuit', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000000c', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'CONNAISSANCE',
 'Frapper quelqu''un dans la rue est-il une infraction en France ?',
 'Oui. Les violences volontaires sont des delits punis par la loi (de l''amende a plusieurs années de prison selon les blessures). Ne pas avoir blesse n''exonere pas de sanction.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000000c', 'Oui, les violences volontaires sont sanctionnees', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000000c', 'Non, c''est libre', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000000c', 'Uniquement en cas de blessures', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000000c', 'Uniquement entre adultes', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000000d', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'CONNAISSANCE',
 'A-t-on le droit de fumer dans les lieux publics fermés en France ?',
 'Non. Depuis 2008, il est interdit de fumer dans tous les lieux publics fermés (restaurants, bars, transports, bureaux). Des espaces extérieurs peuvent être aménagés.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000000d', 'Non, c''est interdit depuis 2008', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000000d', 'Oui, partout', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000000d', 'Uniquement le soir', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000000d', 'Uniquement les hommes', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000000e', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'CONNAISSANCE',
 'La consommation de drogues comme le cannabis est-elle légale en France ?',
 'Non. La consommation, la détention et le trafic de stupefiants (cannabis inclus) sont interdités et punis par la loi.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000000e', 'Non, c''est interdit et puni', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000000e', 'Oui, sans condition', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000000e', 'Uniquement le 14 juillet', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000000e', 'Uniquement avec autorisation préfectorale', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000000f', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'CONNAISSANCE',
 'L''achat et la consommation d''alcool sont-ils interdits aux mineurs ?',
 'Oui. La vente d''alcool aux mineurs (moins de 18 ans) est interditée et punie par la loi. Les commerçants peuvent demander une piece d''identité.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000000f', 'Oui, interdit aux moins de 18 ans', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000000f', 'Non, c''est libre', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000000f', 'Uniquement le vin', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000000f', 'Uniquement les boissons fortes', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000010', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'CONNAISSANCE',
 'Que faut-il faire en cas de cambriolage ?',
 'Il faut prevenir immediatement la police (17) ou la gendarmerie, et déposer plainte au commissariat. Ne rien toucher avant l''arrivée des enquêteurs.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000010', 'Appeler la police (17) et déposer plainte', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000010', 'Ranger soi-même la maison', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000010', 'Rien dire a personne', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000010', 'Affronter le cambrioleur seul', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000011', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'CONNAISSANCE',
 'Quel âge donne accès à la majorité civile en France ?',
 'La majorité civile est fixée à 18 ans. À partir de cet âge, on est juridiquement responsable de ses actes et on peut signer un contrat, voter, se marier.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000011', '18 ans', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000011', '16 ans', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000011', '21 ans', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000011', '25 ans', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000012', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'CONNAISSANCE',
 'Un parent peut-il frapper son enfant en France ?',
 'Non. La loi de 2019 a inscrit dans le Code civil l''interdiction des violences éducatives ordinaires (chatiments corporels et humiliations).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000012', 'Non, les violences éducatives sont interditées', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000012', 'Oui, sans condition', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000012', 'Uniquement la mère', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000012', 'Uniquement les jours feries', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000013', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'CONNAISSANCE',
 'Doit-on payer ses impots en France ?',
 'Oui. Payer ses impots est une obligation civique. C''est inscrit dans la Déclaration de 1789 (article 13) : la contribution commune est indispensable au fonctionnement de l''État.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000013', 'Oui, c''est un devoir civique', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000013', 'Non, c''est facultatif', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000013', 'Uniquement les riches', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000013', 'Uniquement les fonctionnaires', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000014', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'CONNAISSANCE',
 'La protection des enfants est-elle un devoir en France ?',
 'Oui. Tous les adultes ont l''obligation de proteger les enfants et de signaler toute situation de maltraitance. Le numéro 119 est dedie à l''enfance en danger.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000014', 'Oui, et le 119 permet de signaler', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000014', 'Non, c''est aux parents seulement', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000014', 'Uniquement les enseignants', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000014', 'Uniquement les voisins', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000015', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'CONNAISSANCE',
 'Que doit-on faire si on connait un enfant en danger ?',
 'Il faut le signaler immediatement. On peut appeler le 119 (enfance en danger), contacter une assistante sociale ou la police. Le silence peut être puni.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000015', 'Le signaler (119, services sociaux, police)', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000015', 'Rien faire', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000015', 'Le signaler dans 6 mois', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000015', 'Demander à la famille', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000016', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'CONNAISSANCE',
 'Une personne malade a-t-elle droit à la sécurité sociale ?',
 'Oui. Toute personne résidant régulièrement en France a droit à la protection maladie universelle (PUMA), qui rembourse une partie des frais de sante.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000016', 'Oui, via la Sécurité sociale (PUMA)', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000016', 'Non, jamais', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000016', 'Uniquement les Français', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000016', 'Uniquement les retraites', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000017', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'CONNAISSANCE',
 'Les enfants ont-ils l''obligation d''aller à l''école ?',
 'Oui. L''instruction est obligatoire pour tous les enfants de 3 à 16 ans, qu''ils soient français ou étrangers, résidant en France.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000017', 'Oui, de 3 à 16 ans', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000017', 'Non, c''est facultatif', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000017', 'Uniquement les français', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000017', 'Uniquement les filles', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000018', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'CONNAISSANCE',
 'L''école publique est-elle payante en France ?',
 'Non. L''école publique est gratuite. La gratuite a été instaurée en 1881 par les lois Jules Ferry.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000018', 'Non, elle est gratuite (depuis 1881)', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000018', 'Oui, l''inscription coûte cher', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000018', 'Uniquement le lycée est gratuit', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000018', 'Uniquement les enfants pauvres', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000019', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'CONNAISSANCE',
 'Un employeur peut-il payer son salarié en dessous du SMIC ?',
 'Non. Le SMIC (Salaire minimum interprofessionnel de croissance) est un minimum légal. Tout employeur doit verser au moins le SMIC pour un travail à temps plein.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000019', 'Non, le SMIC est un minimum légal', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000019', 'Oui, c''est libre', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000019', 'Uniquement aux jeunes', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000019', 'Uniquement aux apprentis', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000001a', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'CONNAISSANCE',
 'Le travail au noir (non declare) est-il légal en France ?',
 'Non. Le travail dissimule (sans déclaration ni cotisations) est interdit et puni par la loi, autant pour l''employeur que pour le salarié. Cela privé aussi de droits sociaux.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000001a', 'Non, c''est interdit et puni', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000001a', 'Oui, c''est libre', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000001a', 'Uniquement quelques heures', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000001a', 'Uniquement entre proches', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000001b', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'CONNAISSANCE',
 'Combien d''heures peut-on travailler maximum par semaine en France ?',
 'La durée légale du travail est de 35 heures par semaine. Au-dela, ce sont des heures supplementaires (majorees). Le plafond absolu est de 48 heures hebdomadaires.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000001b', '35 heures légales, 48 heures maximum absolu', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000001b', '20 heures maximum', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000001b', '60 heures légales', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000001b', 'Aucune limite', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000001c', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'CONNAISSANCE',
 'Combien de semaines de congés payes annuels minimum à un salarié à temps plein ?',
 'Tout salarié a droit à 5 semaines (25 jours ouvres) de congés payes par an, en France, pour une année complète de travail.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000001c', '5 semaines (25 jours ouvres)', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000001c', '2 semaines', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000001c', '10 semaines', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000001c', 'Aucun conge légal', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000001d', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'CONNAISSANCE',
 'Quels sont les numéros d''urgence essentiels en France ?',
 'Les principaux numéros d''urgence sont : 17 (police), 18 (pompiers), 15 (SAMU), 112 (urgence européenne), 119 (enfance en danger), 3919 (violences conjugales).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000001d', '17 police, 18 pompiers, 15 SAMU, 112 européen', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000001d', 'Un seul numéro suffit', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000001d', 'Le 36 36 pour tout', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000001d', 'Aucun numéro spécifique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000001e', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'CONNAISSANCE',
 'Faire confiance et respecter la décision d''un tribunal est-il important ?',
 'Oui. Respecter les décisions de justice est un devoir civique. La force publique fait exécuter les jugements, et ne pas s''y soumettre constitue souvent une nouvelle infraction.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000001e', 'Oui, c''est un devoir civique', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000001e', 'Non, c''est facultatif', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000001e', 'Uniquement les décisions favorables', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000001e', 'Uniquement les décisions européennes', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000001f', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'CONNAISSANCE',
 'Doit-on dire la vérité quand on est témoin devant la justice ?',
 'Oui. Le faux témoignage devant une juridiction est un delit puni par la loi. Tout témoin doit dire la vérité sous serment.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000001f', 'Oui, le faux témoignage est puni', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000001f', 'Non, on peut mentir', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000001f', 'Uniquement les adultes doivent dire vrai', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000001f', 'Uniquement les ecrits sont obligatoires', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000020', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'CONNAISSANCE',
 'Comment appelle-t-on l''obligation de ne pas reveler ce qu''on apprend dans son métier (médecin, avocat, pretre) ?',
 'Le secret professionnel impose a certaines professions de ne pas reveler les informations confidentielles obtenues dans l''exercice de leur métier. Le violer est un delit.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000020', 'Le secret professionnel', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000020', 'Le silence administratif', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000020', 'Le serment d''allegeance', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000020', 'La discretion volontaire', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000021', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'CONNAISSANCE',
 'Un policier peut-il fouiller mon sac sans aucune raison ?',
 'Non. Pour fouiller un sac, le policier doit avoir un cadre légal (contrôle d''identité avec motifs, enquête, plan Vigipirate dans certaines zones).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000021', 'Non, un cadre légal est nécessaire', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000021', 'Oui, sans aucune condition', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000021', 'Oui, uniquement la nuit', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000021', 'Oui, sur autoroute uniquement', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000022', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'CONNAISSANCE',
 'Quel droit fondamental garantit la liberté de se deplacer en France ?',
 'La liberté d''aller et venir est un droit fondamental. Elle permet a chacun de circuler librement sur le territoire, sauf restrictions légales (zone interdite, ordre judiciaire).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000022', 'La liberté d''aller et venir', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000022', 'La liberté de propriété', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000022', 'La liberté de la presse', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000022', 'La liberté religieuse', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000023', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'CONNAISSANCE',
 'Une victime peut-elle demander reparation à l''auteur d''une infraction ?',
 'Oui. La victime peut se constituer partie civile lors du procès pénal pour obtenir des dommages et intérêts, ou engager une procedure civile parallele.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000023', 'Oui, en se constituant partie civile', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000023', 'Non, jamais', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000023', 'Uniquement pour les agressions physiques', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000023', 'Uniquement les Français', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000024', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'CONNAISSANCE',
 'L''esclavage est-il interdit en France ?',
 'Oui. L''esclavage a été definitivement aboli en 1848. Tout traitement assimile (servitude, travail force) est aujourd''hui un crime puni penalement.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000024', 'Oui, aboli en 1848 et puni en tant que crime', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000024', 'Non, encore tolere parfois', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000024', 'Uniquement entre adultes', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000024', 'Uniquement dans certains métiers', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000025', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'CONNAISSANCE',
 'Un agent public peut-il accepter de l''argent pour rendre un service ?',
 'Non. Accepter de l''argent ou un avantage pour rendre un service public est de la corruption, un delit grave puni par la loi.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000025', 'Non, c''est de la corruption, un delit grave', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000025', 'Oui, c''est une coutume', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000025', 'Uniquement sur les marches', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000025', 'Uniquement le dimanche', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000026', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'CONNAISSANCE',
 'Doit-on respecter les consignes de tri des dechets ?',
 'Oui. Le tri selectif est obligatoire dans la plupart des communes. Ne pas respecter le tri ou déposer des dechets hors des bacs prévus est une infraction passible d''amende.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000026', 'Oui, c''est une obligation civique et légale', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000026', 'Non, c''est facultatif', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000026', 'Uniquement les week-ends', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000026', 'Uniquement le verre', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000027', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'CONNAISSANCE',
 'Quel est le numéro national d''aide aux femmes victimes de violences ?',
 'Le 3919 est le numéro national d''ecoute pour les femmes victimes de violences (conjugales, sexuelles, harcelement). C''est gratuit et confidentiel.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000027', 'Le 3919', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000027', 'Le 15', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000027', 'Le 17', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000027', 'Le 36 36', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000028', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'CONNAISSANCE',
 'Le racisme est-il puni par la loi française ?',
 'Oui. Les actes et propos racistes (injures, discriminations, provocation à la haine) sont des delits punis par la loi (loi du 29 juillet 1881 sur la liberté de la presse).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000028', 'Oui, c''est un delit puni par la loi', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000028', 'Non, c''est une opinion protegée', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000028', 'Uniquement en public', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000028', 'Uniquement sur internet', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000029', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'MISE_SITUATION',
 'Je vois quelqu''un en train de voler dans un magasin. Que faire ?',
 'Vous pouvez prevenir le personnel du magasin ou la police (17). Ne tentez pas d''intervenir physiquement vous-même : c''est dangereux et l''intervention revient aux professionnels.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000029', 'Prevenir le personnel ou appeler la police', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000029', 'Voler aussi', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000029', 'Filmer pour les réseaux sociaux', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000029', 'Rester sans rien faire', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000002a', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'MISE_SITUATION',
 'Je suis témoin d''un accident de la route. Que dois-je faire ?',
 'Sécuriser la zone, appeler les secours (112, 15, 18), porter assistance dans la limite de ses capacités et attendre les autorités. Ne pas deplacer les victimes sauf danger imminent.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000002a', 'Sécuriser, appeler les secours, porter assistance', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000002a', 'Continuer ma route', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000002a', 'Voler les biens des victimes', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000002a', 'Filmer la scène pour le partager', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000002b', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'MISE_SITUATION',
 'Mon voisin fait du bruit toute la nuit. Quel recours ?',
 'On peut d''abord essayer le dialogue. Sinon : prevenir la mairie ou la police, demander un constat par huissier en cas de nuisances repetees, ou saisir le tribunal.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000002b', 'Dialogue, mairie/police, voire huissier ou tribunal', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000002b', 'Aller le frapper', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000002b', 'Rien faire', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000002b', 'Quitter le pays', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000002c', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'MISE_SITUATION',
 'Un inconnu prend des photos de mes enfants dans un parc. Que faire ?',
 'Demandez-lui de cesser et de supprimer les photos. Si refus, prevenez la police : la prise de vue et la diffusion d''images de mineurs sans accord parental sont penalement sanctionnees.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000002c', 'Demander l''arret et prevenir la police', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000002c', 'Sourire et l''encourager', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000002c', 'Le frapper', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000002c', 'Lui demander un tirage gratuit', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000002d', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'MISE_SITUATION',
 'Je suis contrôle par un policier. Quels droits dois-je connaitre ?',
 'Vous devez presenter une piece d''identité si demandee. Vous avez le droit de demander la raison du contrôle, d''être traité avec respect, et de ne pas être fouille sans cadre légal.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000002d', 'Presenter une piece d''identité, demander le motif, être traité avec respect', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000002d', 'Refuser tout dialogue', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000002d', 'Frapper le policier', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000002d', 'Mentir sur mon identité', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000002e', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'MISE_SITUATION',
 'Je decouvre qu''un colis livre n''est pas le mien et contient de l''argent. Que faire ?',
 'Il faut le remettre au transporteur, à la police ou à la mairie. Garder un objet qui ne vous appartient pas est un delit (recel ou abus de confiance).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000002e', 'Le remettre à la police, au transporteur ou à la mairie', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000002e', 'Le garder discrètement', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000002e', 'Le vendre rapidement', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000002e', 'Le brûler', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000002f', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'MISE_SITUATION',
 'Mon employeur me demande de travailler le dimanche sans paye supplementaire. Est-ce légal ?',
 'Le travail dominical est encadré. Selon la convention collective, il peut donner droit à une majoration salariale ou un repos compensateur. Refuser le paiement majore peut être conteste aux prud''hommes.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000002f', 'C''est encadré par la loi et la convention collective ; saisir les prud''hommes au besoin', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000002f', 'Accepter sans discussion', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000002f', 'Demissionner immediatement', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000002f', 'Faire greve seul', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000030', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'MISE_SITUATION',
 'Je veux divorcer mais mon conjoint refuse. Est-ce possible ?',
 'Oui. Même sans le consentement de l''autre conjoint, le divorce reste possible : divorce pour faute, divorce pour alteration definitive du lien conjugal (après 1 an de separation), divorce pour acceptation.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000030', 'Oui, plusieurs formes de divorce existent même sans accord', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000030', 'Non, l''accord est obligatoire', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000030', 'Uniquement les hommes peuvent demander', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000030', 'Uniquement après 20 ans', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000031', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'MISE_SITUATION',
 'Un voisin me menace verbalement et physiquement. Que faire ?',
 'Notez les faits par ecrit avec dates et heures. Allez déposer plainte au commissariat ou en gendarmerie. Si besoin urgent, appelez le 17.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000031', 'Noter les faits et déposer plainte', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000031', 'Rendre les coups en retour', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000031', 'Faire comme si de rien n''était', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000031', 'Demenager immediatement', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000032', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'MISE_SITUATION',
 'Je suis témoin d''un acte raciste dans la rue. Quel comportement adopter ?',
 'On peut soutenir la victime, appeler la police (17), recueillir des témoignages. Les actes racistes sont des delits que la loi punit severement.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000032', 'Soutenir la victime, prevenir la police', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000032', 'Encourager le raciste', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000032', 'Faire de même', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000032', 'Filmer pour rire', FALSE, 3);
