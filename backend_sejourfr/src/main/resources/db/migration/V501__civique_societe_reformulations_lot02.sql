-- Flyway: reformulations theme 5 SOCIETE lot 2/2 (R16-R31) - is_active=FALSE

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-000000000010', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Aupres de quel organisme demande-t-on le remboursement de ses frais de sante ?',
 'C''est l''Assurance Maladie (Caisse primaire d''assurance maladie - CPAM) qui rembourse les frais de sante. La carte Vitale facilite ces remboursements.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000010', 'L''Assurance Maladie (CPAM)', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000010', 'La mairie', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000010', 'Le commissariat', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000010', 'Le tribunal', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-000000000011', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Que peut-on dire de l''acces aux soins en France ?',
 'L''acces aux soins est un droit garanti. Toute personne residant regulierement en France a droit a la protection maladie universelle (PUMA), qui rembourse une partie des frais.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000011', 'Garantie a tous les residents reguliers via la PUMA', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000011', 'Reserve aux Francais', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000011', 'Payant integralement pour tous', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000011', 'Inexistant', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-000000000012', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'MISE_SITUATION',
 'En cas de probleme de sante non urgent, vers qui se diriger en premier ?',
 'Le medecin traitant (medecin generaliste) est le premier interlocuteur pour les problemes de sante non urgents. Il oriente vers un specialiste si necessaire (parcours de soins coordonne).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000012', 'Le medecin traitant', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000012', 'Les urgences', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000012', 'La police', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000012', 'L''avocat', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-000000000013', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Quel est le role d''un medecin traitant en France ?',
 'Le medecin traitant assure le suivi medical de premier recours, oriente vers les specialistes si necessaire, coordonne les soins. Le declarer permet un meilleur remboursement.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000013', 'Suivi de premier recours et orientation vers specialistes', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000013', 'Operer en hopital', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000013', 'Vendre des medicaments', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000013', 'Etre uniquement urgentiste', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-000000000014', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'MISE_SITUATION',
 'Dans quels cas doit-on se rendre aux urgences hospitalieres ?',
 'Les urgences sont reservees aux situations medicales graves, soudaines ou potentiellement dangereuses : douleur thoracique, perte de connaissance, hemorragie, trauma serieux. Pour les soins non urgents, voir le medecin traitant ou SOS Medecins.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000014', 'Pour les situations medicales graves ou soudaines', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000014', 'Pour un rhume', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000014', 'Pour un controle de routine', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000014', 'Pour acheter des medicaments', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-000000000015', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Pourquoi certaines vaccinations sont-elles obligatoires en France ?',
 'Les vaccinations obligatoires protegent l''individu et l''ensemble de la population (immunite collective). Depuis 2018, 11 vaccins sont obligatoires pour les nourrissons (rougeole, tetanos, etc.).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000015', 'Pour proteger l''individu et l''immunite collective', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000015', 'Pour des raisons economiques', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000015', 'Pour vendre des medicaments', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000015', 'Sans raison particuliere', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-000000000016', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'A quoi sert la carte Vitale en France ?',
 'La carte Vitale prouve l''affiliation a la Securite sociale. Elle permet aux professionnels de sante de transmettre les feuilles de soins electroniquement et d''etre rembourse rapidement.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000016', 'Justifier l''affiliation et faciliter le remboursement', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000016', 'Payer les courses', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000016', 'Voter', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000016', 'Conduire une voiture', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-000000000017', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'A quoi sert une complementaire sante (mutuelle) ?',
 'La mutuelle complete les remboursements de la Securite sociale (qui ne rembourse pas toujours 100% des frais). Elle peut couvrir des soins comme l''optique, le dentaire, l''audioprothese.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000017', 'Completer les remboursements de la Securite sociale', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000017', 'Remplacer la Securite sociale', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000017', 'Payer le loyer', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000017', 'Etre obligatoire pour voter', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-000000000018', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Jusqu''a quel age l''instruction est-elle obligatoire en France ?',
 'L''instruction est obligatoire jusqu''a 16 ans (loi de 1959, abaissee a 3 ans en 2019). L''obligation de formation a ete instauree jusqu''a 18 ans depuis 2020.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000018', '16 ans (obligation d''instruction) ; 18 ans (obligation de formation)', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000018', '6 ans', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000018', '21 ans', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000018', 'Aucune obligation', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-000000000019', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Que prevoit l''autorite parentale en France ?',
 'L''autorite parentale impose aux parents (ensemble en general) de proteger, eduquer, nourrir et soigner leur enfant mineur, jusqu''a sa majorite ou son emancipation.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000019', 'Proteger, eduquer, nourrir et soigner l''enfant mineur', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000019', 'Ne s''occuper de rien', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000019', 'Uniquement le pere', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-000000000019', 'Uniquement la mere', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-00000000001a', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Pour quels enfants l''ecole est-elle obligatoire ?',
 'L''instruction est obligatoire pour tous les enfants de 3 a 16 ans residant en France, quelle que soit leur nationalite (francaise ou etrangere).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000001a', 'Tous les enfants de 3 a 16 ans en France', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000001a', 'Uniquement les francais', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000001a', 'Uniquement les garcons', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000001a', 'Uniquement en metropole', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-00000000001b', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
 'Quel diplome obtient-on a la fin du lycee general ou technologique ?',
 'Le baccalaureat (general, technologique ou professionnel) est le diplome obtenu en fin de lycee. Il permet d''acceder a l''enseignement superieur.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000001b', 'Le baccalaureat', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000001b', 'Le brevet', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000001b', 'Le CAP', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000001b', 'Le doctorat', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-00000000001c', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Apres l''ecole elementaire, dans quel etablissement vont les eleves ?',
 'Apres l''ecole elementaire (CP a CM2), les eleves entrent au college (6e a 3e), puis au lycee (2nde a Terminale). Le college accueille tous les enfants jusqu''au brevet.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000001c', 'Au college (de la 6e a la 3e)', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000001c', 'Directement a l''universite', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000001c', 'Au lycee directement', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000001c', 'Aucun etablissement', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-00000000001d', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Pour quels eleves l''ecole publique est-elle obligatoire ?',
 'L''instruction (a l''ecole, en famille avec controle, ou en etablissement prive) est obligatoire pour tous les enfants de 3 a 16 ans residant en France, sans distinction.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000001d', 'Tous les enfants de 3 a 16 ans residant en France', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000001d', 'Uniquement les Francais nes en France', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000001d', 'Uniquement les enfants de classe moyenne', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000001d', 'Personne', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-00000000001e', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Que prevoit l''inscription d''un enfant a l''ecole ?',
 'L''inscription a l''ecole publique se fait a la mairie (puis a l''ecole). Elle implique des droits (instruction gratuite, restauration scolaire) et des obligations (assiduite, respect du reglement).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000001e', 'Inscription a la mairie, instruction gratuite, assiduite obligatoire', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000001e', 'Aucune obligation', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000001e', 'Payer une cotisation annuelle', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000001e', 'Etre francais', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000001-0000-0000-0000-00000000001f', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'MISE_SITUATION',
 'Que prevoit l''ecole pour les enfants qui ne parlent pas francais a leur arrivee ?',
 'L''Education nationale propose un accompagnement specifique : UPE2A (unite pedagogique pour eleves allophones arrivants), enseignants formes au FLE/FLS, soutien linguistique adapte.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000001f', 'Un accompagnement specifique (UPE2A, enseignants FLE)', TRUE, 0),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000001f', 'Aucune aide, ils se debrouillent', FALSE, 1),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000001f', 'Une exclusion temporaire', FALSE, 2),
(gen_random_uuid(), 'f5000001-0000-0000-0000-00000000001f', 'Un retour au pays d''origine', FALSE, 3);
