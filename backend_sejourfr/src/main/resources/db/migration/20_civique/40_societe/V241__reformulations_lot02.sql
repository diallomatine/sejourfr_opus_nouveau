-- Flyway: reformulations thème 5 SOCIÉTÉ lot 2/2 (R16-R31) - is_active=FALSE

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-000000000010', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Auprès de quel organisme demande-t-on le remboursement de ses frais de santé ?',
 'C''est l''Assurance Maladie (Caisse primaire d''assurance maladie - CPAM) qui rembourse les frais de santé. La carte Vitale facilite ces remboursements.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000010', 'L''Assurance Maladie (CPAM)', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000010', 'La mairie', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000010', 'Le commissariat', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000010', 'Le tribunal', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-000000000011', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Que peut-on dire de l''accès aux soins en France ?',
 'L''accès aux soins est un droit garanti. Toute personne résidant régulièrement en France a droit à la protection maladie universelle (PUMA), qui rembourse une partie des frais.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000011', 'Garanti à tous les résidents réguliers via la PUMA', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000011', 'Réservé aux Français', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000011', 'Payant intégralement pour tous', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000011', 'Inexistant', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-000000000012', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'MISE_SITUATION',
 'En cas de problème de santé non urgent, vers qui se diriger en premier ?',
 'Le médecin traitant (médecin généraliste) est le premier interlocuteur pour les problèmes de santé non urgents. Il oriente vers un spécialiste si nécessaire (parcours de soins coordonné).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000012', 'Le médecin traitant', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000012', 'Les urgences', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000012', 'La police', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000012', 'L''avocat', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-000000000013', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Quel est le rôle d''un médecin traitant en France ?',
 'Le médecin traitant assure le suivi médical de premier recours, oriente vers les spécialistes si nécessaire, coordonne les soins. Le déclarer permet un meilleur remboursement.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000013', 'Suivi de premier recours et orientation vers spécialistes', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000013', 'Opérer en hôpital', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000013', 'Vendre des médicaments', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000013', 'Être uniquement urgentiste', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-000000000014', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'MISE_SITUATION',
 'Dans quels cas doit-on se rendre aux urgences hospitalières ?',
 'Les urgences sont réservées aux situations médicales graves, soudaines ou potentiellement dangereuses : douleur thoracique, perte de connaissance, hémorragie, trauma sérieux. Pour les soins non urgents, voir le médecin traitant ou SOS Médecins.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000014', 'Pour les situations médicales graves ou soudaines', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000014', 'Pour un rhume', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000014', 'Pour un contrôle de routine', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000014', 'Pour acheter des médicaments', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-000000000015', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Pourquoi certaines vaccinations sont-elles obligatoires en France ?',
 'Les vaccinations obligatoires protègent l''individu et l''ensemble de la population (immunité collective). Depuis 2018, 11 vaccins sont obligatoires pour les nourrissons (rougeole, tétanos, etc.).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000015', 'Pour protéger l''individu et l''immunité collective', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000015', 'Pour des raisons économiques', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000015', 'Pour vendre des médicaments', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000015', 'Sans raison particulière', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-000000000016', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'À quoi sert la carte Vitale en France ?',
 'La carte Vitale prouve l''affiliation à la Sécurité sociale. Elle permet aux professionnels de santé de transmettre les feuilles de soins électroniquement et d''être remboursé rapidement.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000016', 'Justifier l''affiliation et faciliter le remboursement', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000016', 'Payer les courses', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000016', 'Voter', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000016', 'Conduire une voiture', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-000000000017', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'À quoi sert une complémentaire santé (mutuelle) ?',
 'La mutuelle complète les remboursements de la Sécurité sociale (qui ne rembourse pas toujours 100% des frais). Elle peut couvrir des soins comme l''optique, le dentaire, l''audioprothèse.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000017', 'Compléter les remboursements de la Sécurité sociale', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000017', 'Remplacer la Sécurité sociale', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000017', 'Payer le loyer', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000017', 'Être obligatoire pour voter', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-000000000018', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Jusqu''à quel âge l''instruction est-elle obligatoire en France ?',
 'L''instruction est obligatoire jusqu''à 16 ans (loi de 1959, abaissée à 3 ans en 2019). L''obligation de formation a été instaurée jusqu''à 18 ans depuis 2020.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000018', '16 ans (obligation d''instruction) ; 18 ans (obligation de formation)', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000018', '6 ans', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000018', '21 ans', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000018', 'Aucune obligation', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-000000000019', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Que prévoit l''autorité parentale en France ?',
 'L''autorité parentale impose aux parents (ensemble en général) de protéger, éduquer, nourrir et soigner leur enfant mineur, jusqu''à sa majorité ou son émancipation.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000019', 'Protéger, éduquer, nourrir et soigner l''enfant mineur', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000019', 'Ne s''occuper de rien', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000019', 'Uniquement le père', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000019', 'Uniquement la mère', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-00000000001a', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Pour quels enfants l''école est-elle obligatoire ?',
 'L''instruction est obligatoire pour tous les enfants de 3 à 16 ans résidant en France, quelle que soit leur nationalité (française ou étrangère).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000001a', 'Tous les enfants de 3 à 16 ans en France', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000001a', 'Uniquement les Français', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000001a', 'Uniquement les garçons', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000001a', 'Uniquement en métropole', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-00000000001b', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Quel diplôme obtient-on à la fin du lycée général ou technologique ?',
 'Le baccalauréat (général, technologique ou professionnel) est le diplôme obtenu en fin de lycée. Il permet d''accéder à l''enseignement supérieur.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000001b', 'Le baccalauréat', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000001b', 'Le brevet', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000001b', 'Le CAP', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000001b', 'Le doctorat', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-00000000001c', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Après l''école élémentaire, dans quel établissement vont les élèves ?',
 'Après l''école élémentaire (CP à CM2), les élèves entrent au collège (6e à 3e), puis au lycée (2nde à Terminale). Le collège accueille tous les enfants jusqu''au brevet.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000001c', 'Au collège (de la 6e à la 3e)', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000001c', 'Directement à l''université', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000001c', 'Au lycée directement', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000001c', 'Aucun établissement', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-00000000001d', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Pour quels élèves l''école publique est-elle obligatoire ?',
 'L''instruction (à l''école, en famille avec contrôle, ou en établissement privé) est obligatoire pour tous les enfants de 3 à 16 ans résidant en France, sans distinction.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000001d', 'Tous les enfants de 3 à 16 ans résidant en France', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000001d', 'Uniquement les Français nés en France', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000001d', 'Uniquement les enfants de classe moyenne', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000001d', 'Personne', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-00000000001e', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Que prévoit l''inscription d''un enfant à l''école ?',
 'L''inscription à l''école publique se fait à la mairie (puis à l''école). Elle implique des droits (instruction gratuite, restauration scolaire) et des obligations (assiduité, respect du règlement).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000001e', 'Inscription à la mairie, instruction gratuite, assiduité obligatoire', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000001e', 'Aucune obligation', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000001e', 'Payer une cotisation annuelle', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000001e', 'Être français', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-00000000001f', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'MISE_SITUATION',
 'Que prévoit l''école pour les enfants qui ne parlent pas français à leur arrivée ?',
 'L''Éducation nationale propose un accompagnement spécifique : UPE2A (unité pédagogique pour élèves allophones arrivants), enseignants formés au FLE/FLS, soutien linguistique adapté.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000001f', 'Un accompagnement spécifique (UPE2A, enseignants FLE)', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000001f', 'Aucune aide, ils se débrouillent', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000001f', 'Une exclusion temporaire', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000001f', 'Un retour au pays d''origine', FALSE, 3);
