-- Flyway: niveau 3 theme 5 SOCIETE - 50 CSP (40 CONN + 10 MS) - is_active=FALSE

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000001', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Que designe la ''CAF'' en France ?',
 'La CAF (Caisse d''allocations familiales) verse des prestations aux familles : allocations familiales, prime d''activite, aide au logement (APL), RSA, etc.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000001', 'La Caisse d''allocations familiales', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000001', 'Une banque privee', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000001', 'Une assurance auto', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000001', 'Une compagnie aerienne', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000002', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Que sont les APL ?',
 'Les Aides personnalisees au logement (APL) sont des allocations versees par la CAF aux personnes a faibles revenus pour les aider a payer leur loyer ou leur emprunt immobilier.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000002', 'Aides personnalisees au logement', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000002', 'Une carte de transport', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000002', 'Un impot', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000002', 'Un syndicat', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000003', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Que designe le RSA en France ?',
 'Le RSA (Revenu de solidarite active) est une allocation versee aux personnes sans ressources ou aux faibles revenus, pour leur garantir un revenu minimum.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000003', 'Revenu de solidarite active', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000003', 'Un syndicat', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000003', 'Un parti politique', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000003', 'Une banque', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000004', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'A qui faut-il s''adresser pour obtenir un logement social ?',
 'Pour un logement social (HLM), on depose un dossier en mairie ou aupres d''un bailleur social. Les demandes sont examinees selon des criteres sociaux et de revenus.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000004', 'A la mairie ou un bailleur social', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000004', 'Au commissariat', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000004', 'A l''eglise', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000004', 'Au tribunal', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000005', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Qu''est-ce qu''un HLM ?',
 'Un HLM (Habitation a loyer modere) est un logement social, dont le loyer est plafonne et dont l''attribution est reservee aux personnes aux revenus modestes.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000005', 'Un logement social a loyer modere', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000005', 'Une grande villa', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000005', 'Un hotel', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000005', 'Une boutique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000006', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Quel age minimum pour passer le permis de conduire (B) ?',
 'Le permis B se passe a partir de 17 ans en conduite accompagnee, et 18 ans en filiere classique. Pour conduire seul, il faut 18 ans dans tous les cas.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000006', '18 ans pour conduire seul (17 en conduite accompagnee)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000006', '16 ans', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000006', '21 ans', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000006', 'Pas d''age minimum', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000007', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Que represente le ''titre de sejour'' pour un etranger en France ?',
 'Le titre de sejour (carte de sejour) est un document qui autorise un etranger non europeen a sejourner regulierement en France. Il existe plusieurs types (etudiant, salarie, vie privee, resident).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000007', 'Un document autorisant un etranger non europeen a sejourner', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000007', 'Un permis de conduire', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000007', 'Un passeport', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000007', 'Une carte de bibliotheque', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000008', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Quel age marque l''entree au college en France ?',
 'L''entree au college se fait normalement a 11 ans, en classe de 6e, apres la fin de l''ecole elementaire (CM2). Le college se termine en 3e avec le brevet.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000008', '11 ans (entree en 6e)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000008', '13 ans', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000008', '15 ans', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000008', '18 ans', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000009', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Combien y a-t-il d''annees au college ?',
 'Le college dure 4 ans : 6e, 5e, 4e, 3e. A la fin de la 3e, les eleves passent le diplome national du brevet (DNB).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000009', '4 annees (6e, 5e, 4e, 3e)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000009', '3 annees', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000009', '6 annees', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000009', '2 annees', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000000a', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Quel diplome obtient-on a la fin du college ?',
 'Le brevet (Diplome national du brevet, DNB) est l''examen passe en fin de 3e, a 14-15 ans. C''est le premier diplome de la scolarite obligatoire.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000000a', 'Le brevet (DNB)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000000a', 'Le baccalaureat', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000000a', 'Le CAP', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000000a', 'Le permis de conduire', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000000b', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'A quel age commence l''ecole obligatoire en France ?',
 'Depuis 2019, l''instruction est obligatoire des 3 ans (auparavant 6 ans). C''est l''ecole maternelle qui debute donc l''instruction obligatoire.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000000b', '3 ans (ecole maternelle, depuis 2019)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000000b', '6 ans', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000000b', '8 ans', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000000b', 'Aucun age', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000000c', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Que designe la cantine scolaire en France ?',
 'La cantine scolaire est le service de restauration propose dans les ecoles. Elle est generalement geree par la commune. Son cout est souvent ajuste selon les revenus des familles.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000000c', 'Le service de restauration scolaire', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000000c', 'Une salle de sport', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000000c', 'Une bibliotheque', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000000c', 'Un theatre', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000000d', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'L''ecole publique en France est-elle laique ?',
 'Oui. L''ecole publique est laique depuis les lois Ferry (1881-1882). Cela signifie qu''elle est neutre vis-a-vis des religions et qu''il est interdit d''y afficher des signes religieux ostensibles.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000000d', 'Oui, depuis les lois Ferry (1881-1882)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000000d', 'Non, elle suit la religion catholique', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000000d', 'Cela varie selon les villes', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000000d', 'Uniquement les jours feries', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000000e', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Que designe-t-on par ''mariage civil'' en France ?',
 'Le mariage civil est l''union legale celebree par un officier d''etat civil (maire ou adjoint) a la mairie. C''est le seul mariage reconnu par l''Etat francais. Un mariage religieux n''a pas de valeur civile.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000000e', 'L''union legale celebree a la mairie', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000000e', 'Un mariage religieux', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000000e', 'Une simple cohabitation', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000000e', 'Un contrat commercial', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000000f', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Que designe le PACS ?',
 'Le PACS (Pacte civil de solidarite) est un contrat conclu entre deux personnes majeures pour organiser leur vie commune. C''est une alternative au mariage, sans toutes ses formalites.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000000f', 'Un contrat de vie commune entre deux majeurs', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000000f', 'Un syndicat', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000000f', 'Un parti', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000000f', 'Un diplome', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000010', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Que fait un pharmacien en France ?',
 'Le pharmacien dispense les medicaments en officine, conseille les patients, peut effectuer certaines vaccinations (grippe, COVID), realiser des tests rapides, accompagner les traitements.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000010', 'Dispenser des medicaments, conseiller, vacciner', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000010', 'Operer en hopital', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000010', 'Conduire les ambulances', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000010', 'Diriger un commissariat', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000011', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Quel professionnel donne les premiers soins en cabinet de ville ?',
 'Le medecin generaliste (medecin traitant) est le premier interlocuteur en ville. Il diagnostique, soigne, oriente vers les specialistes. C''est le pivot du parcours de soins.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000011', 'Le medecin generaliste / medecin traitant', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000011', 'Le notaire', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000011', 'L''avocat', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000011', 'Le boulanger', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000012', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Le tabac est-il interdit aux mineurs en France ?',
 'Oui. La vente de tabac aux mineurs (moins de 18 ans) est interdite. Le commercant peut etre sanctionne. La consommation par les mineurs est tres deconseillee.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000012', 'Oui, vente interdite aux moins de 18 ans', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000012', 'Non, c''est libre', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000012', 'Uniquement le tabac fort', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000012', 'Uniquement les cigarettes', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000013', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Quel numero appeler en cas de probleme avec un enfant (urgence non vitale) ?',
 'Le 119 est le numero national ''Allo Enfance en danger'', gratuit, accessible 24h/24, pour signaler une situation d''enfance en difficulte ou en danger. En cas d''urgence vitale, appeler le 15.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000013', 'Le 119 (Allo Enfance en danger)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000013', 'Le 36 36', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000013', 'Le 100', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000013', 'Le 911', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000014', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Quel sigle designe l''ecole en France pour les enfants de 3-5 ans ?',
 'L''ecole maternelle accueille les enfants de 3 a 5/6 ans (petite, moyenne et grande section). Elle precede l''ecole elementaire et est obligatoire depuis 2019.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000014', 'L''ecole maternelle', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000014', 'Le lycee', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000014', 'Le college', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000014', 'La creche', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000015', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Que designe la ''creche'' en France ?',
 'La creche est un mode de garde collectif pour les enfants de 0 a 3 ans environ. Les places sont attribuees par la mairie ou des structures privees. Le tarif depend des revenus des parents.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000015', 'Un mode de garde collectif pour enfants 0-3 ans', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000015', 'Une ecole obligatoire', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000015', 'Une salle de musique', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000015', 'Une bibliotheque', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000016', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Le mariage en France est-il prive ou public ?',
 'Le mariage civil est celebre publiquement a la mairie, generalement dans la salle des mariages. Tout citoyen peut y assister. Le mariage est inscrit a l''etat civil.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000016', 'Public, celebre a la mairie', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000016', 'Strictement prive', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000016', 'Uniquement religieux', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000016', 'Uniquement entre amis', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000017', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Qu''est-ce que le ''parcours du combattant'' administratif ?',
 'L''expression decrit (informellement) les nombreuses demarches administratives parfois complexes (cartes d''identite, permis, allocations, retraites). Le site service-public.fr regroupe les demarches.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000017', 'Les nombreuses demarches administratives a effectuer', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000017', 'Une formation militaire', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000017', 'Un sport olympique', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000017', 'Un examen scolaire', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000018', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Comment s''appelle le document officiel d''etat civil prouvant la naissance ?',
 'L''acte de naissance est le document officiel etabli par la mairie a la declaration de naissance. Il est ensuite necessaire pour de nombreuses demarches (carte d''identite, passeport, mariage).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000018', 'L''acte de naissance', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000018', 'Le permis de conduire', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000018', 'Le passeport', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000018', 'Le carnet de sante', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000019', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Quel document atteste de la nationalite francaise ?',
 'La carte nationale d''identite et le passeport prouvent la nationalite francaise. Un certificat de nationalite francaise (CNF) peut aussi etre delivre par les tribunaux.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000019', 'La carte d''identite ou le passeport', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000019', 'Le permis de conduire', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000019', 'La carte Vitale', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000019', 'Le bulletin de naissance', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000001a', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Quel age permet de quitter le foyer parental ?',
 'A 18 ans (majorite legale), une personne peut quitter le foyer familial sans autorisation. Avant, l''emancipation est possible des 16 ans, mais elle est encadree.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000001a', '18 ans (majorite legale), 16 ans avec emancipation', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000001a', '12 ans', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000001a', '21 ans', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000001a', 'Aucune limite', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000001b', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Le voyage en avion necessite-t-il un document d''identite ?',
 'Oui. Pour tout voyage en avion (interieur ou international), il faut presenter une piece d''identite (carte d''identite, passeport). Pour l''international hors UE, un passeport est generalement obligatoire.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000001b', 'Oui, piece d''identite obligatoire', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000001b', 'Non, jamais', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000001b', 'Uniquement pour l''international', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000001b', 'Uniquement pour les hommes', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000001c', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Quel age minimum pour entrer en boite de nuit en France ?',
 'L''acces aux boites de nuit est generalement reserve aux personnes majeures (18 ans). Certains etablissements peuvent fixer un age plus eleve. La vente d''alcool aux mineurs est interdite.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000001c', '18 ans', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000001c', '16 ans', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000001c', '21 ans', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000001c', '12 ans', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000001d', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'A quoi servent les transports en commun urbains (bus, metro) ?',
 'Les transports en commun urbains permettent de circuler en ville. Ils sont gerees par les autorites locales et offrent des tarifs reduits pour les jeunes, retraites, etudiants, demandeurs d''emploi.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000001d', 'Circuler en ville, avec des tarifs reduits selon les profils', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000001d', 'Les voyages a l''etranger uniquement', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000001d', 'Le transport de marchandises lourdes', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000001d', 'Aucune utilite particuliere', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000001e', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Que designe l''INSEE ?',
 'L''INSEE (Institut national de la statistique et des etudes economiques) produit les statistiques officielles de la France : population, economie, emploi, prix.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000001e', 'Institut national de la statistique et des etudes economiques', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000001e', 'Un syndicat', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000001e', 'Un parti politique', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000001e', 'Un hopital', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000001f', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Quel etablissement gere le pret de livres gratuitement ?',
 'La bibliotheque (ou mediatheque municipale) permet d''emprunter gratuitement des livres, parfois des CD/DVD, et offre l''acces a internet. L''inscription est generalement peu chere ou gratuite.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000001f', 'La bibliotheque ou la mediatheque', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000001f', 'Le cinema', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000001f', 'Le commissariat', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000001f', 'L''hopital', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000020', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Quel age permet de passer le permis de conduire la moto (A1) ?',
 'Le permis A1 (motos de 125 cm3 maximum) peut etre passe a partir de 16 ans. Le permis A2 (moto plus puissante) requiert 18 ans, le permis A (toute moto) 24 ans (ou 20 ans avec A2 pendant 2 ans).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000020', '16 ans pour le permis A1 (125cm3)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000020', '14 ans', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000020', '21 ans', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000020', 'Aucun age minimum', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000021', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Le port du casque est-il obligatoire a velo en France ?',
 'Le port du casque a velo est obligatoire pour les enfants de moins de 12 ans (conducteur ou passager). Pour les adultes, il est seulement recommande mais tres conseille.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000021', 'Obligatoire pour les moins de 12 ans, recommande pour les adultes', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000021', 'Obligatoire pour tous', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000021', 'Interdit a tous', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000021', 'Uniquement la nuit', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000022', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Quel objet est obligatoire dans une voiture en France ?',
 'Les vehicules doivent posseder : un gilet jaune fluorescent, un triangle de signalisation, ainsi qu''un ethylotest (officiellement). Le constat amiable est aussi essentiel.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000022', 'Un gilet jaune et un triangle de signalisation', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000022', 'Un casque de moto', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000022', 'Un parapluie', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000022', 'Rien d''obligatoire', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000023', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Quel numero composer pour les renseignements telephoniques administratifs ?',
 'Le 39 39 (Allo service public) renseigne sur les demarches administratives. Service au cout d''un appel local depuis un fixe.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000023', 'Le 39 39 (Allo service public)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000023', 'Le 17', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000023', 'Le 18', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000023', 'Le 911', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000024', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Que designe la ''piece d''identite'' en France ?',
 'Une piece d''identite (carte nationale d''identite, passeport, titre de sejour) est un document officiel avec photo, permettant de prouver son identite. Elle peut etre exigee dans de nombreuses situations.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000024', 'Un document officiel avec photo prouvant l''identite', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000024', 'Une carte bancaire', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000024', 'Une carte de fidelite', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000024', 'Un journal', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000025', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Combien de temps est valable une carte nationale d''identite francaise ?',
 'Une carte nationale d''identite francaise est valable 15 ans pour les majeurs (depuis 2014), 10 ans pour les mineurs. Pour voyager hors UE, certains pays exigent une carte non perimee.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000025', '15 ans pour les majeurs (10 ans pour mineurs)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000025', '5 ans pour tous', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000025', 'A vie', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000025', '1 an renouvelable', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000026', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Qu''est-ce qu''un ''centre des impots'' en France ?',
 'Le centre des impots (ou service des impots des particuliers) est l''administration qui gere la fiscalite des particuliers : declaration de revenus, impot sur le revenu, impots locaux.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000026', 'L''administration fiscale pour les particuliers', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000026', 'Un syndicat', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000026', 'Une association', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000026', 'Une banque', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000027', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Que doit-on faire en cas de perte de papiers d''identite ?',
 'Il faut signaler la perte au commissariat (declaration de perte). Pour le renouvellement, on demande une nouvelle carte d''identite ou un passeport en mairie.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000027', 'Declarer la perte au commissariat puis demander un renouvellement', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000027', 'Rien faire', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000027', 'Mentir sur son identite', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000027', 'Quitter la France', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000028', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Quel numero europeen aide en cas de disparition d''enfant ?',
 'Le 116 000 est le numero europeen pour signaler une disparition d''enfant. Il est gratuit et fonctionne dans tous les pays de l''UE.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000028', 'Le 116 000', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000028', 'Le 15', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000028', 'Le 17', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000028', 'Le 911', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000029', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'MISE_SITUATION',
 'Je viens d''avoir un enfant. Quelles demarches dois-je faire ?',
 'Declarer la naissance a la mairie dans les 5 jours, prevenir la CAF, l''Assurance Maladie (carte Vitale), l''employeur (conges paternite/maternite), la mutuelle, l''ecole/creche si necessaire.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000029', 'Mairie, CAF, Assurance Maladie, employeur, mutuelle', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000029', 'Aucune demarche', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000029', 'Uniquement l''ecole', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000029', 'Uniquement le pape', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000002a', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'MISE_SITUATION',
 'Je perds mon emploi. Que dois-je faire en premier ?',
 'S''inscrire a France Travail (anciennement Pole emploi) dans les meilleurs delais : c''est la condition pour percevoir des indemnites chomage (selon droits cotises) et beneficier d''un accompagnement.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000002a', 'S''inscrire a France Travail rapidement', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000002a', 'Rien faire', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000002a', 'Quitter la France', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000002a', 'Demander a la mairie un travail', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000002b', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'MISE_SITUATION',
 'J''ai mal et je dois consulter un medecin. Quelles options ?',
 'Si non urgent, prendre rendez-vous avec son medecin traitant (en ligne, par telephone). Sinon, SOS Medecins, maison de garde, telemedecine. En urgence vitale : 15 ou 112.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000002b', 'Medecin traitant en general, urgences en cas grave', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000002b', 'Aller directement aux urgences quoi qu''il arrive', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000002b', 'Attendre que ca passe', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000002b', 'Demander a un voisin', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000002c', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'MISE_SITUATION',
 'Je n''arrive plus a payer mon loyer. A qui demander de l''aide ?',
 'Contacter la CAF (peut etre une APL), le CCAS (centre communal d''action sociale) de la mairie, des associations (Restos du coeur, Secours populaire). Eviter d''accumuler les impayes.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000002c', 'CAF, CCAS de la mairie, associations sociales', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000002c', 'Aucune aide n''existe', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000002c', 'Quitter le logement sans rien dire', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000002c', 'Insulter le proprietaire', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000002d', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'MISE_SITUATION',
 'Mon enfant a besoin de soutien scolaire. Quels recours sont disponibles ?',
 'Demander de l''aide a l''enseignant et au directeur d''ecole, profiter du soutien scolaire propose en classe, recourir au CNED, demander un PPRE (plan d''aide), s''inscrire a des associations d''aide aux devoirs.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000002d', 'Soutien scolaire ecole, aide aux devoirs en associations', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000002d', 'Rien faire', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000002d', 'Changer d''ecole sans concertation', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000002d', 'Renvoyer l''enfant a la maison', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000002e', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'MISE_SITUATION',
 'Je veux inscrire mon enfant a l''ecole publique. Quelle demarche ?',
 'L''inscription se fait a la mairie (avec justificatifs : livret de famille, justificatif de domicile). Ensuite, l''admission est confirmee a l''ecole de secteur. La scolarite est gratuite.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000002e', 'Inscription a la mairie de la commune de residence', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000002e', 'Inscription a la prefecture', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000002e', 'Inscription au commissariat', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000002e', 'Aucune inscription necessaire', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000002f', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'MISE_SITUATION',
 'Je veux acceder a l''aide medicale en cas de difficulte financiere. Quelles options ?',
 'Demander la PUMA (Protection universelle maladie). Si revenus tres bas, demander la Complementaire sante solidaire (C2S) qui prend en charge les frais de mutuelle. Les PASS (permanence d''acces aux soins de sante) dans les hopitaux accueillent aussi.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000002f', 'PUMA + Complementaire sante solidaire (C2S) + PASS hospitaliers', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000002f', 'Renoncer aux soins', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000002f', 'Payer integralement', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000002f', 'Aller chez un guerisseur', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000030', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'MISE_SITUATION',
 'Je veux ouvrir un compte bancaire en France. Que faut-il ?',
 'Justificatif d''identite et de domicile, parfois preuve de revenus. En cas de refus par toutes les banques, on peut exercer le ''droit au compte'' aupres de la Banque de France.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000030', 'Pieces d''identite et de domicile ; droit au compte en cas de refus', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000030', 'Rien n''est necessaire', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000030', 'Une recommandation du maire', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000030', 'Un parrainage de 10 personnes', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000031', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'MISE_SITUATION',
 'Je suis temoin de violences conjugales chez un voisin. Quel comportement ?',
 'Appeler le 17 (police) si la situation est immediate. Sinon, signaler au 3919 (violences conjugales), au 119 (enfance en danger si enfants). Ne pas intervenir physiquement seul.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000031', 'Appeler le 17, signaler au 3919 ou 119', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000031', 'Rien faire', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000031', 'Intervenir physiquement seul', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000031', 'Quitter le quartier', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000032', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'MISE_SITUATION',
 'Mon enfant subit du harcelement a l''ecole. Que faire ?',
 'Alerter l''enseignant et le directeur. Si pas de reponse, l''inspection academique. Appeler le 3018 (numero national contre le harcelement scolaire). Une plainte est possible : le harcelement est un delit.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000032', 'Alerter l''ecole, l''inspection, appeler le 3018, plainte si necessaire', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000032', 'Rien faire', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000032', 'Punir l''enfant victime', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000032', 'Changer de pays', FALSE, 3);
