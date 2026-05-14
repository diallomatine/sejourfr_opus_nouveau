-- Flyway: niveau 3 thème 3 DROITS_DEVOIRS - 50 NAT (40 CONN + 10 MS) - is_active=FALSE

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000005d', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Quel article de la DDHC consacre le principe de la souveraineté nationale ?',
 'L''article 3 de la DDHC enonce : ''Le principe de toute souveraineté réside essentiellement dans la Nation''. Reaffirme par l''article 3 de la Constitution actuelle.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000005d', 'L''article 3 de la DDHC', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000005d', 'L''article 1er', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000005d', 'L''article 17', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000005d', 'L''article 89', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000005e', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Le preambule de la Constitution de 1946 fait-il partie du bloc de constitutionnalite ?',
 'Oui. Depuis la décision du Conseil constitutionnel de 1971, le preambule de 1946 (qui reconnait notamment les droits sociaux) fait partie du bloc de constitutionnalite et a valeur constitutionnelle.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000005e', 'Oui, depuis 1971', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000005e', 'Non, c''est un texte historique sans portée', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000005e', 'Uniquement les economistes', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000005e', 'Uniquement les ouvriers', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000005f', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Quel principe constitutionnel garantit l''égalité entre hommes et femmes pour les mandats électoraux ?',
 'La parite, inscrite dans la Constitution depuis 1999 (article 1er), impose aux partis politiques de favoriser l''égal accès des femmes et des hommes aux mandats électifs et aux fonctions électives.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000005f', 'La parite (Constitution depuis 1999)', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000005f', 'L''unicite du suffrage', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000005f', 'La proportionnelle intégrale', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000005f', 'Aucun principe particulier', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000060', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Que prévoit la Convention européenne des droits de l''homme (CEDH) ?',
 'La CEDH, adoptée en 1950 par le Conseil de l''Europe, garantit les droits fondamentaux (vie, liberté, procès équitable, etc.). La France l''a ratifiée en 1974. La Cour européenne des droits de l''homme (Strasbourg) la fait respecter.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000060', 'Les droits fondamentaux des Européens, contrôles par la CourEDH', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000060', 'Une convention sur le commerce', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000060', 'Un accord sur la peche', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000060', 'Un traité militaire', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000061', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Ou siège la Cour européenne des droits de l''homme (CEDH) ?',
 'La Cour européenne des droits de l''homme siège à Strasbourg. C''est l''organe juridictionnel du Conseil de l''Europe (a distinguer de la Cour de justice de l''UE située à Luxembourg).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000061', 'À Strasbourg', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000061', 'À Bruxelles', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000061', 'À Paris', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000061', 'À Luxembourg', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000062', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Un citoyen français peut-il saisir directement la Cour européenne des droits de l''homme ?',
 'Oui, après epuisement des voies de recours internes (jugement definitif en France), un citoyen peut saisir la CEDH s''il estime que ses droits garantis par la Convention ont été violes.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000062', 'Oui, après epuisement des recours internes', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000062', 'Non, jamais directement', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000062', 'Uniquement les associations peuvent', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000062', 'Uniquement avec accord du président', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000063', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'La Cour pénale internationale (CPI) juge-t-elle des actes commis en France ?',
 'La CPI, basee a La Haye, juge les genocides, crimes contre l''humanite, crimes de guerre et crimes d''agression, subsidiairement aux juridictions nationales. La France l''a reconnue en 2002.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000063', 'Subsidiairement, pour les crimes les plus graves', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000063', 'Pour tous les delits français', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000063', 'Jamais', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000063', 'Uniquement les crimes économiques', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000064', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'L''imprescriptibilite des crimes contre l''humanite est-elle reconnue en droit français ?',
 'Oui. Les crimes contre l''humanite (loi de 1964) sont imprescriptibles : il n''existe aucun delai au-delà duquel leurs auteurs ne pourraient plus être poursuivis.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000064', 'Oui, ces crimes sont imprescriptibles', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000064', 'Non, ils suivent la prescription normale', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000064', 'Uniquement pour les Français', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000064', 'Uniquement pour la Seconde Guerre mondiale', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000065', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Quel principe interdit toute forme de torture, même en temps de guerre ?',
 'L''interdiction absolue de la torture (article 3 CEDH, Convention contre la torture de 1984). Aucune circonstance, même l''état de guerre ou de nécessité, ne peut justifier la torture.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000065', 'L''interdiction absolue (article 3 CEDH)', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000065', 'L''interdiction conditionnelle', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000065', 'L''interdiction uniquement civile', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000065', 'L''interdiction uniquement pour les Français', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000066', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Qu''est-ce que le ''droit international humanitaire'' ?',
 'Le droit international humanitaire (Conventions de Genève de 1949) regit la conduite des conflits armes : protection des civils, des prisonniers, des blesses, et restriction des méthodes de guerre.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000066', 'Les règles applicables en cas de conflit arme', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000066', 'Le droit du commerce mondial', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000066', 'Le droit de l''environnement', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000066', 'Le droit familial international', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000067', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Quel est l''apport de la Charte des droits fondamentaux de l''Union européenne ?',
 'La Charte des droits fondamentaux de l''UE (2000, valeur juridique depuis le traité de Lisbonne en 2009) consacre l''ensemble des droits applicables dans l''UE : dignite, libertés, égalité, solidarité, citoyenneté, justice.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000067', 'Elle consacre les droits fondamentaux applicables dans l''UE', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000067', 'Elle reglemente le commerce européen', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000067', 'Elle definit la PAC', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000067', 'Elle organise les élections européennes', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000068', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Le mariage entre personnes du même sexe a-t-il une valeur dans toute l''Union européenne ?',
 'Pas obligatoirement. Chaque État membre choisit s''il legalise le mariage homosexuel. Toutefois, la libre circulation des couples maries (et leur reconnaissance) progresse.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000068', 'Cela dépend de chaque État membre', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000068', 'Oui, c''est uniforme dans toute l''UE', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000068', 'Non, c''est interdit partout en Europe', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000068', 'Uniquement dans les pays scandinaves', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000069', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Qu''est-ce que le ''noyau dur'' des droits intangibles selon la CEDH ?',
 'Certains droits sont absolus, indispensables : droit à la vie, interdiction de la torture, interdiction de l''esclavage, principe de légalité pénale. Aucune derogation n''est possible, même en cas de guerre.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000069', 'Vie, interdiction de torture, d''esclavage, légalité pénale', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000069', 'Tous les droits sont intangibles', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000069', 'Aucun droit n''est intangible', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000069', 'Uniquement le droit à la propriété', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000006a', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Que prévoit le ''principe de proportionnalite'' en droit pénal ?',
 'Le principe de proportionnalite impose que la peine prononcée soit en rapport avec la gravite de l''infraction commise. Une amende excessive ou une prison disproportionnee peut être censuree.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000006a', 'La peine doit être proportionnee à la gravite de l''infraction', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000006a', 'Toutes les peines sont égales', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000006a', 'Les peines sont fixées au hasard', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000006a', 'Les peines sont décidées par le maire', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000006b', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Quelle juridiction européenne assure l''application uniforme du droit de l''UE ?',
 'La Cour de justice de l''Union européenne (CJUE), basee à Luxembourg, assure l''application uniforme du droit de l''UE et tranche les questions soumises par les juges nationaux.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000006b', 'La Cour de justice de l''UE (Luxembourg)', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000006b', 'La Cour européenne des droits de l''homme', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000006b', 'La Cour pénale internationale', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000006b', 'Le Conseil constitutionnel français', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000006c', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'La hiérarchie des normes françaises place la Constitution en tête. Quels sont les rangs suivants ?',
 'Hiérarchie : 1. Constitution (et bloc de constitutionnalite), 2. Traités internationaux et droit européen, 3. Lois, 4. Règlements (décrets, arretes), 5. Conventions collectives, jurisprudence.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000006c', 'Constitution > traités > lois > règlements', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000006c', 'Lois > Constitution > traités', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000006c', 'Règlements > tous', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000006c', 'Tout est égal', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000006d', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Que représente le principe ''non bis in idem'' en droit pénal ?',
 'Le principe ''non bis in idem'' (article 4 du Protocole 7 CEDH) interdit de juger ou de punir une personne deux fois pour les mêmes faits. Une exception : la découverte de faits nouveaux après jugement.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000006d', 'Interdiction d''être jugé deux fois pour les mêmes faits', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000006d', 'Interdiction de mentir', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000006d', 'Obligation de comparaitre', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000006d', 'Interdiction de l''avocat', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000006e', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Le droit à un recours effectif est-il garanti ?',
 'Oui. Article 13 de la CEDH : toute personne dont les droits ont été violes a droit à un recours effectif devant une instance nationale. Garantie aussi par la Constitution et le droit européen.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000006e', 'Oui, article 13 de la CEDH', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000006e', 'Non, c''est facultatif', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000006e', 'Uniquement pour les Français', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000006e', 'Uniquement pour les Européens', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000006f', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Que désigne la notion d''''état d''urgence'' en droit français ?',
 'L''état d''urgence (loi de 1955, révisée depuis) permet au gouvernement de prendre des mesures restrictives des libertés en cas de peril imminent (terrorisme, catastrophe). Il a notamment été declaré après 2015.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000006f', 'Un régime d''exception restreignant temporairement certaines libertés', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000006f', 'Un service hospitalier', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000006f', 'Une procedure administrative ordinaire', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000006f', 'Une mesure économique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000070', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Quel principe limite la durée maximum d''une garde a vue ?',
 'La garde a vue est limitée à 24 heures, prolongeable à 48 heures par le procureur (et jusqu''à 96 heures pour terrorisme/criminalite organisée). La personne doit être informée de ses droits.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000070', '24 heures, prolongeable jusqu''à 96h dans certains cas', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000070', '1 semaine sans limite', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000070', 'Indefinie selon le juge', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000070', 'Aucune limite', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000071', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Quel droit fondamental protège le secret médical ?',
 'Le secret médical (article 4 du Code de deontologie médicale, article 226-13 du Code pénal) protège la confidentialite des informations transmises au médecin. Sa violation est un delit.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000071', 'Le secret médical (protege par la deontologie et le Code pénal)', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000071', 'Le droit à la sante', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000071', 'Le droit à la formation', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000071', 'Aucun droit spécifique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000072', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'L''avortement (IVG) est-il aujourd''hui un droit constitutionnel ?',
 'Oui. La révision constitutionnelle du 8 mars 2024 a inscrit dans la Constitution la ''liberté garantie à la femme d''avoir recours à une interruption volontaire de grossesse''.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000072', 'Oui, depuis la révision constitutionnelle de mars 2024', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000072', 'Non, c''est une simple loi', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000072', 'Uniquement en cas de viol', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000072', 'Uniquement les jours pairs', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000073', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Que protège la loi sur la presse de 1881 ?',
 'La loi du 29 juillet 1881 garantit la liberté de la presse et encadre les abus (diffamation, injure, provocation à la haine, fausse nouvelle). C''est le texte fondateur de la liberté d''expression médiatique.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000073', 'La liberté de la presse, avec ses limites légales', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000073', 'Le droit des imprimeurs', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000073', 'Le commerce des livres', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000073', 'Aucune liberté particulière', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000074', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Que designe l''expression ''État de droit'' en philosophie politique ?',
 'Un État de droit est un État soumis à la loi, ou les pouvoirs publics doivent respecter les règles juridiques et ou les droits des citoyens sont garantis et contrôles par des juges indépendants.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000074', 'Un État soumis à la loi avec contrôle juridictionnel', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000074', 'Un État avec beaucoup de lois', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000074', 'Un État sans lois', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000074', 'Un État monarchique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000075', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Quel article de la CEDH protège le droit à un procès équitable ?',
 'L''article 6 de la CEDH garantit le droit à un procès équitable : tribunal indépendant et impartial, jugement public dans un delai raisonnable, présomption d''innocence, droits de la défense.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000075', 'L''article 6', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000075', 'L''article 1er', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000075', 'L''article 12', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000075', 'L''article 30', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000076', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Comment la France peut-elle être condamnée par la Cour européenne des droits de l''homme ?',
 'Sur recours individuel d''une personne ayant epuise ses voies de recours internes, la CEDH peut déclarer que la France a viole la Convention. La France doit alors modifier sa pratique et indemniser le requerant.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000076', 'Sur recours individuel après epuisement des recours internes', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000076', 'Automatiquement chaque année', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000076', 'Par décision du Parlement européen', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000076', 'Jamais', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000077', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Quels sont les principaux ''devoirs constitutionnels'' du citoyen ?',
 'La Constitution implique des devoirs : respect de la loi, paiement des contributions communes, défense de la patrie (article 35), préservation de l''environnement (Charte de 2004), respect de la dignite humaine.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000077', 'Respect de la loi, contributions, défense, environnement', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000077', 'Aucun devoir n''est constitutionnel', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000077', 'Uniquement payer la TVA', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000077', 'Uniquement le service militaire', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000078', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'L''objection de conscience militaire est-elle reconnue en France ?',
 'Le statut d''objecteur de conscience a existe en France jusqu''à la suspension du service militaire en 1997. Avec la professionnalisation, la question ne se pose plus de la même manière. Aujourd''hui, le service est volontaire.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000078', 'Anciennement, mais le service militaire est suspendu depuis 1997', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000078', 'Non, jamais reconnu', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000078', 'Uniquement pour les religieux', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000078', 'Uniquement les hommes', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000079', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Que signifie le principe d''''égalité reelle'' ?',
 'L''égalité reelle (par opposition à l''égalité formelle) vise a corriger les inégalités de fait, par des politiques publiques (éducation prioritaire, parite, accessibilite handicap, discrimination positive).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000079', 'Corriger les inégalités de fait par des politiques publiques', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000079', 'Faire tous identiques', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000079', 'Supprimer la propriété', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000079', 'Donner plus aux puissants', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000007a', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'L''arret ''Marbury vs Madison'' équivalent français reconnaissant la portée constitutionnelle des principes ?',
 'La décision du Conseil constitutionnel du 16 juillet 1971 (''liberté d''association'') a reconnu la valeur constitutionnelle du preambule de 1946, donc des droits sociaux et de la DDHC. Équivalent français d''un contrôle de constitutionnalite renforce.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000007a', 'La décision du 16 juillet 1971 sur la liberté d''association', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000007a', 'L''arret Sarran de 1998', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000007a', 'L''arret Nicolo de 1989', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000007a', 'Aucune décision française comparable', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000007b', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Que prévoit le principe de subsidiarite dans l''Union européenne ?',
 'Le principe de subsidiarite (article 5 TUE) impose que l''UE n''agisse, dans les domaines non exclusifs, que si l''action est plus efficace au niveau européen qu''au niveau national.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000007b', 'L''UE agit si l''action est plus efficace au niveau européen', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000007b', 'L''UE remplace toujours les États', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000007b', 'Les États peuvent ignorer l''UE', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000007b', 'Tout est décide à Bruxelles', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000007c', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'L''apatridie est-elle protegée par le droit français ?',
 'Oui. La Convention de 1954 et le droit français protegent les apatrides (personnes sans nationalité). L''OFPRA peut leur accorder un statut leur permettant de sejourner et de circuler.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000007c', 'Oui, statut d''apatride accordé par l''OFPRA', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000007c', 'Non, ils sont expulses', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000007c', 'Ils ne peuvent pas exister', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000007c', 'Uniquement les enfants', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-0000000000b1', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Qu''est-ce que le droit à un environnement équilibre selon la Charte de 2004 ?',
 'L''article 1er de la Charte de l''environnement reconnait le droit pour chacun de vivre dans un environnement équilibre et respectueux de la sante. Adossee à la Constitution depuis 2005.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b1', 'Le droit à un environnement équilibre et respectueux de la sante', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b1', 'Le droit à la pollution', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b1', 'Un droit européen non intégré', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b1', 'Aucun droit spécifique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-0000000000b2', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Qu''est-ce que la ''liberté syndicale'' en droit français ?',
 'La liberté syndicale (preambule de 1946) garantit le droit de créer ou d''adherer à un syndicat pour défendre ses intérêts professionnels. Elle est protégée constitutionnellement.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b2', 'Le droit de créer et d''adherer à un syndicat', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b2', 'L''obligation d''être syndique', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b2', 'Un droit interdit', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b2', 'Un droit réserve aux fonctionnaires', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-0000000000b3', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Le droit de greve est-il garanti constitutionnellement en France ?',
 'Oui. Le droit de greve est garanti par le preambule de la Constitution de 1946. Il s''exerce dans le cadre des lois qui le reglementent (preavis pour les fonctionnaires, etc.).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b3', 'Oui, par le preambule de 1946', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b3', 'Non, c''est interdit', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b3', 'Uniquement pour le privé', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b3', 'Uniquement pour le public', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-0000000000b4', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Que prévoit le droit à l''instruction selon la Constitution ?',
 'Le preambule de 1946 dispose que ''l''organisation de l''enseignement public gratuit et laïque à tous les degres est un devoir de l''État''. L''instruction est gratuite jusqu''au lycée.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b4', 'L''enseignement public gratuit et laïque à tous les degres', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b4', 'L''enseignement uniquement religieux', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b4', 'L''enseignement payant pour tous', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b4', 'Aucun droit à l''instruction', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-0000000000b5', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Que désigne la notion de ''service public'' en droit administratif français ?',
 'Un service public est une activité d''intérêt général assuree par une personne publique (État, collectivites) ou sous son contrôle. Il est regi par les principes d''égalité, de continuite et d''adaptabilite.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b5', 'Une activité d''intérêt général assuree par une personne publique', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b5', 'Une entreprise privée', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b5', 'Une association religieuse', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b5', 'Un loisir', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-0000000000b6', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Quels principes regissent le service public en France ?',
 'Les ''lois de Rolland'' enoncent trois principes : continuite (le service ne s''interrompt pas), égalité (même service pour tous les usagers) et mutabilite/adaptabilite (le service s''adapte aux besoins).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b6', 'Continuite, égalité, mutabilite', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b6', 'Gratuite, secret, rapidite', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b6', 'Religion, tradition, hiérarchie', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b6', 'Aucun principe particulier', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-0000000000b7', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Le droit à la sante est-il reconnu en France ?',
 'Oui. Le preambule de 1946 garantit à tous, notamment à l''enfant, à la mère, aux travailleurs âges, la protection de la sante. C''est un droit constitutionnel.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b7', 'Oui, garanti par le preambule de 1946', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b7', 'Non, c''est privatise', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b7', 'Uniquement les retraites', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b7', 'Uniquement les Français nes en France', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-0000000000b8', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Qu''est-ce que le ''devoir de fraternité'' reconnu en France ?',
 'Le Conseil constitutionnel a reconnu en 2018 le principe de fraternité comme principe a valeur constitutionnelle, decoulant de la devise républicaine. Il a notamment justifie l''aide humanitaire desinteressee.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b8', 'Un principe constitutionnel decoulant de la devise républicaine (2018)', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b8', 'Une obligation religieuse', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b8', 'Une simple coutume', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b8', 'Aucune valeur juridique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000007d', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'MISE_SITUATION',
 'Après avoir epuise tous les recours en France, je veux saisir la Cour européenne des droits de l''homme. Quelle est la demarche ?',
 'Vous adressez une requete (formulaire officiel) à la CEDH à Strasbourg, dans les 4 mois suivant la décision interne definitive. Pas d''avocat obligatoire pour la requete initiale. La cour examine la recevabilite.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000007d', 'Requete à Strasbourg dans les 4 mois après recours interne definitif', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000007d', 'Aucune demarche possible', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000007d', 'Demander à l''ambassadeur', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000007d', 'Saisir le pape', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000007e', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'MISE_SITUATION',
 'Une mesure de l''état d''urgence me privé d''une liberté (assignation a résidence) et je la conteste. Quel recours ?',
 'Les mesures de l''état d''urgence peuvent être contestées devant le juge administratif (refere-liberté si l''urgence est grande, ou recours classique). Le juge contrôle leur proportionnalite.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000007e', 'Saisir le juge administratif (refere-liberté ou recours)', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000007e', 'Aucun recours possible', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000007e', 'Saisir le pape', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000007e', 'Faire la greve de la faim', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000007f', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'MISE_SITUATION',
 'Je decouvre qu''une loi en vigueur depuis 5 ans porte atteinte à un de mes droits constitutionnels. Quels recours ?',
 'Vous pouvez soulever une Question prioritaire de constitutionnalite (QPC) lors d''une procedure judiciaire ou administrative. Le Conseil constitutionnel peut alors abroger la loi pour l''avenir.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000007f', 'Soulever une QPC lors d''une procedure judiciaire', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000007f', 'Reecrire la loi soi-même', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000007f', 'Forcer le Parlement a voter', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000007f', 'Aucun recours possible', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000080', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'MISE_SITUATION',
 'Mon employeur privé me discrimine en raison de mes convictions religieuses. Que faire ?',
 'Vous pouvez saisir le Defenseur des droits, les prud''hommes (juridiction du travail), ou déposer plainte pénale. La discrimination religieuse au travail est un delit. La chargé de la preuve est partagee.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000080', 'Saisir le Defenseur des droits, les prud''hommes, porter plainte', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000080', 'Aucune action possible', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000080', 'Changer de religion', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000080', 'Faire de même avec d''autres salariés', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000081', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'MISE_SITUATION',
 'Je suis témoin d''un crime contre l''humanite commis à l''étranger par une personne résidant maintenant en France. Que prévoit le droit ?',
 'La France peut juger les auteurs de crimes contre l''humanite, même commis à l''étranger, en vertu de la competence universelle. Vous pouvez signaler les faits au procureur, qui pourra ouvrir une enquête.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000081', 'Signaler au procureur ; la competence universelle peut s''appliquer', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000081', 'Aucune action possible en France', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000081', 'Saisir directement la CPI', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000081', 'Renvoyer la personne dans son pays', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000082', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'MISE_SITUATION',
 'Le gouvernement adopte une mesure restrictive par ordonnance. Quels contrôles existent ?',
 'Les ordonnances peuvent être contestées devant le Conseil d''État. Elles doivent ensuite être ratifiées par le Parlement, sinon elles perdent leur valeur. Le Conseil constitutionnel peut aussi être saisi de la loi de ratification.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000082', 'Recours devant le Conseil d''État, ratification parlementaire ensuite', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000082', 'Aucun contrôle', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000082', 'Uniquement contrôle de l''ONU', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000082', 'Uniquement le pape peut intervenir', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000083', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'MISE_SITUATION',
 'Une chaine de télévision refuse de diffuser un débat contradictoire pendant une campagne. Quel recours ?',
 'L''ARCOM (ex-CSA) veille au respect du pluralisme dans l''audiovisuel. Vous pouvez la saisir d''un signalement. Elle peut sanctionner les chaines manquant à leurs obligations.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000083', 'Saisir l''ARCOM, qui peut sanctionner la chaine', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000083', 'Aucune action possible', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000083', 'Forcer le studio a diffuser', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000083', 'Demander au pape de diffuser', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000084', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'MISE_SITUATION',
 'Une donnée personnelle me concernant est conservee illegalement par une entreprise. Que faire ?',
 'Saisir la CNIL (Commission nationale de l''informatique et des libertés). Elle peut sanctionner l''entreprise. Vous pouvez aussi faire valoir vos droits RGPD : effacement, portabilite, opposition.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000084', 'Saisir la CNIL et faire valoir vos droits RGPD', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000084', 'Aucun recours possible', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000084', 'Pirater l''entreprise', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000084', 'Demander au pape', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000085', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'MISE_SITUATION',
 'Un journal publie un article diffamatoire sur moi. Quels recours pénaux et civils ?',
 'Diffamation = imputation d''un fait portant atteinte à l''honneur. Vous pouvez déposer plainte pénale (delai de prescription très court : 3 mois) et engager une action civile pour obtenir reparation et un droit de réponse.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000085', 'Plainte pénale (dans 3 mois) + action civile + droit de réponse', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000085', 'Aucun recours', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000085', 'Diffamer aussi le journaliste', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000085', 'Fermer le journal', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000086', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'MISE_SITUATION',
 'L''administration prend une décision qui me touche sans m''avoir entendu. Quel recours ?',
 'Le ''principe du contradictoire'' impose souvent un echange préalable. Si une décision individuelle defavorable est prise sans procedure contradictoire requise, vous pouvez demander son annulation au tribunal administratif.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000086', 'Saisir le tribunal administratif pour vice de procedure', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000086', 'Aucun recours possible', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000086', 'Refuser d''obeir sans formalite', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000086', 'Saisir l''OTAN', FALSE, 3);
