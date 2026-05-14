-- Flyway: niveau 3 theme 3 DROITS_DEVOIRS - 50 NAT (40 CONN + 10 MS) - is_active=FALSE

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000005d', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Quel article de la DDHC consacre le principe de la souverainete nationale ?',
 'L''article 3 de la DDHC enonce : ''Le principe de toute souverainete reside essentiellement dans la Nation''. Reaffirme par l''article 3 de la Constitution actuelle.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000005d', 'L''article 3 de la DDHC', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000005d', 'L''article 1er', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000005d', 'L''article 17', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000005d', 'L''article 89', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000005e', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Le preambule de la Constitution de 1946 fait-il partie du bloc de constitutionnalite ?',
 'Oui. Depuis la decision du Conseil constitutionnel de 1971, le preambule de 1946 (qui reconnait notamment les droits sociaux) fait partie du bloc de constitutionnalite et a valeur constitutionnelle.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000005e', 'Oui, depuis 1971', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000005e', 'Non, c''est un texte historique sans portee', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000005e', 'Uniquement les economistes', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000005e', 'Uniquement les ouvriers', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000005f', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Quel principe constitutionnel garantit l''egalite entre hommes et femmes pour les mandats electoraux ?',
 'La parite, inscrite dans la Constitution depuis 1999 (article 1er), impose aux partis politiques de favoriser l''egal acces des femmes et des hommes aux mandats electifs et aux fonctions electives.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000005f', 'La parite (Constitution depuis 1999)', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000005f', 'L''unicite du suffrage', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000005f', 'La proportionnelle integrale', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000005f', 'Aucun principe particulier', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000060', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Que prevoit la Convention europeenne des droits de l''homme (CEDH) ?',
 'La CEDH, adoptee en 1950 par le Conseil de l''Europe, garantit les droits fondamentaux (vie, liberte, proces equitable, etc.). La France l''a ratifiee en 1974. La Cour europeenne des droits de l''homme (Strasbourg) la fait respecter.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000060', 'Les droits fondamentaux des Europeens, controles par la CourEDH', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000060', 'Une convention sur le commerce', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000060', 'Un accord sur la peche', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000060', 'Un traite militaire', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000061', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Ou siege la Cour europeenne des droits de l''homme (CEDH) ?',
 'La Cour europeenne des droits de l''homme siege a Strasbourg. C''est l''organe juridictionnel du Conseil de l''Europe (a distinguer de la Cour de justice de l''UE situee a Luxembourg).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000061', 'A Strasbourg', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000061', 'A Bruxelles', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000061', 'A Paris', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000061', 'A Luxembourg', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000062', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Un citoyen francais peut-il saisir directement la Cour europeenne des droits de l''homme ?',
 'Oui, apres epuisement des voies de recours internes (jugement definitif en France), un citoyen peut saisir la CEDH s''il estime que ses droits garantis par la Convention ont ete violes.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000062', 'Oui, apres epuisement des recours internes', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000062', 'Non, jamais directement', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000062', 'Uniquement les associations peuvent', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000062', 'Uniquement avec accord du president', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000063', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'La Cour penale internationale (CPI) juge-t-elle des actes commis en France ?',
 'La CPI, basee a La Haye, juge les genocides, crimes contre l''humanite, crimes de guerre et crimes d''agression, subsidiairement aux juridictions nationales. La France l''a reconnue en 2002.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000063', 'Subsidiairement, pour les crimes les plus graves', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000063', 'Pour tous les delits francais', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000063', 'Jamais', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000063', 'Uniquement les crimes economiques', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000064', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'L''imprescriptibilite des crimes contre l''humanite est-elle reconnue en droit francais ?',
 'Oui. Les crimes contre l''humanite (loi de 1964) sont imprescriptibles : il n''existe aucun delai au-dela duquel leurs auteurs ne pourraient plus etre poursuivis.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000064', 'Oui, ces crimes sont imprescriptibles', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000064', 'Non, ils suivent la prescription normale', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000064', 'Uniquement pour les Francais', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000064', 'Uniquement pour la Seconde Guerre mondiale', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000065', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Quel principe interdit toute forme de torture, meme en temps de guerre ?',
 'L''interdiction absolue de la torture (article 3 CEDH, Convention contre la torture de 1984). Aucune circonstance, meme l''etat de guerre ou de necessite, ne peut justifier la torture.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000065', 'L''interdiction absolue (article 3 CEDH)', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000065', 'L''interdiction conditionnelle', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000065', 'L''interdiction uniquement civile', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000065', 'L''interdiction uniquement pour les Francais', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000066', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Qu''est-ce que le ''droit international humanitaire'' ?',
 'Le droit international humanitaire (Conventions de Geneve de 1949) regit la conduite des conflits armes : protection des civils, des prisonniers, des blesses, et restriction des methodes de guerre.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000066', 'Les regles applicables en cas de conflit arme', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000066', 'Le droit du commerce mondial', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000066', 'Le droit de l''environnement', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000066', 'Le droit familial international', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000067', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Quel est l''apport de la Charte des droits fondamentaux de l''Union europeenne ?',
 'La Charte des droits fondamentaux de l''UE (2000, valeur juridique depuis le traite de Lisbonne en 2009) consacre l''ensemble des droits applicables dans l''UE : dignite, libertes, egalite, solidarite, citoyennete, justice.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000067', 'Elle consacre les droits fondamentaux applicables dans l''UE', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000067', 'Elle reglemente le commerce europeen', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000067', 'Elle definit la PAC', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000067', 'Elle organise les elections europeennes', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000068', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Le mariage entre personnes du meme sexe a-t-il une valeur dans toute l''Union europeenne ?',
 'Pas obligatoirement. Chaque Etat membre choisit s''il legalise le mariage homosexuel. Toutefois, la libre circulation des couples maries (et leur reconnaissance) progresse.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000068', 'Cela depend de chaque Etat membre', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000068', 'Oui, c''est uniforme dans toute l''UE', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000068', 'Non, c''est interdit partout en Europe', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000068', 'Uniquement dans les pays scandinaves', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000069', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Qu''est-ce que le ''noyau dur'' des droits intangibles selon la CEDH ?',
 'Certains droits sont absolus, indispensables : droit a la vie, interdiction de la torture, interdiction de l''esclavage, principe de legalite penale. Aucune derogation n''est possible, meme en cas de guerre.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000069', 'Vie, interdiction de torture, d''esclavage, legalite penale', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000069', 'Tous les droits sont intangibles', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000069', 'Aucun droit n''est intangible', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000069', 'Uniquement le droit a la propriete', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000006a', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Que prevoit le ''principe de proportionnalite'' en droit penal ?',
 'Le principe de proportionnalite impose que la peine prononcee soit en rapport avec la gravite de l''infraction commise. Une amende excessive ou une prison disproportionnee peut etre censuree.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000006a', 'La peine doit etre proportionnee a la gravite de l''infraction', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000006a', 'Toutes les peines sont egales', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000006a', 'Les peines sont fixees au hasard', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000006a', 'Les peines sont decidees par le maire', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000006b', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Quelle juridiction europeenne assure l''application uniforme du droit de l''UE ?',
 'La Cour de justice de l''Union europeenne (CJUE), basee a Luxembourg, assure l''application uniforme du droit de l''UE et tranche les questions soumises par les juges nationaux.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000006b', 'La Cour de justice de l''UE (Luxembourg)', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000006b', 'La Cour europeenne des droits de l''homme', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000006b', 'La Cour penale internationale', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000006b', 'Le Conseil constitutionnel francais', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000006c', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'La hierarchie des normes francaises place la Constitution en tete. Quels sont les rangs suivants ?',
 'Hierarchie : 1. Constitution (et bloc de constitutionnalite), 2. Traites internationaux et droit europeen, 3. Lois, 4. Reglements (decrets, arretes), 5. Conventions collectives, jurisprudence.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000006c', 'Constitution > traites > lois > reglements', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000006c', 'Lois > Constitution > traites', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000006c', 'Reglements > tous', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000006c', 'Tout est egal', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000006d', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Que represente le principe ''non bis in idem'' en droit penal ?',
 'Le principe ''non bis in idem'' (article 4 du Protocole 7 CEDH) interdit de juger ou de punir une personne deux fois pour les memes faits. Une exception : la decouverte de faits nouveaux apres jugement.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000006d', 'Interdiction d''etre juge deux fois pour les memes faits', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000006d', 'Interdiction de mentir', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000006d', 'Obligation de comparaitre', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000006d', 'Interdiction de l''avocat', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000006e', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Le droit a un recours effectif est-il garanti ?',
 'Oui. Article 13 de la CEDH : toute personne dont les droits ont ete violes a droit a un recours effectif devant une instance nationale. Garantie aussi par la Constitution et le droit europeen.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000006e', 'Oui, article 13 de la CEDH', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000006e', 'Non, c''est facultatif', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000006e', 'Uniquement pour les Francais', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000006e', 'Uniquement pour les Europeens', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000006f', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Que designe la notion d''''etat d''urgence'' en droit francais ?',
 'L''etat d''urgence (loi de 1955, revisee depuis) permet au gouvernement de prendre des mesures restrictives des libertes en cas de peril imminent (terrorisme, catastrophe). Il a notamment ete declare apres 2015.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000006f', 'Un regime d''exception restreignant temporairement certaines libertes', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000006f', 'Un service hospitalier', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000006f', 'Une procedure administrative ordinaire', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000006f', 'Une mesure economique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000070', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Quel principe limite la duree maximum d''une garde a vue ?',
 'La garde a vue est limitee a 24 heures, prolongeable a 48 heures par le procureur (et jusqu''a 96 heures pour terrorisme/criminalite organisee). La personne doit etre informee de ses droits.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000070', '24 heures, prolongeable jusqu''a 96h dans certains cas', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000070', '1 semaine sans limite', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000070', 'Indefinie selon le juge', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000070', 'Aucune limite', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000071', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Quel droit fondamental protege le secret medical ?',
 'Le secret medical (article 4 du Code de deontologie medicale, article 226-13 du Code penal) protege la confidentialite des informations transmises au medecin. Sa violation est un delit.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000071', 'Le secret medical (protege par la deontologie et le Code penal)', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000071', 'Le droit a la sante', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000071', 'Le droit a la formation', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000071', 'Aucun droit specifique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000072', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'L''avortement (IVG) est-il aujourd''hui un droit constitutionnel ?',
 'Oui. La revision constitutionnelle du 8 mars 2024 a inscrit dans la Constitution la ''liberte garantie a la femme d''avoir recours a une interruption volontaire de grossesse''.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000072', 'Oui, depuis la revision constitutionnelle de mars 2024', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000072', 'Non, c''est une simple loi', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000072', 'Uniquement en cas de viol', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000072', 'Uniquement les jours pairs', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000073', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Que protege la loi sur la presse de 1881 ?',
 'La loi du 29 juillet 1881 garantit la liberte de la presse et encadre les abus (diffamation, injure, provocation a la haine, fausse nouvelle). C''est le texte fondateur de la liberte d''expression mediatique.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000073', 'La liberte de la presse, avec ses limites legales', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000073', 'Le droit des imprimeurs', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000073', 'Le commerce des livres', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000073', 'Aucune liberte particuliere', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000074', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Que designe l''expression ''Etat de droit'' en philosophie politique ?',
 'Un Etat de droit est un Etat soumis a la loi, ou les pouvoirs publics doivent respecter les regles juridiques et ou les droits des citoyens sont garantis et controles par des juges independants.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000074', 'Un Etat soumis a la loi avec controle juridictionnel', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000074', 'Un Etat avec beaucoup de lois', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000074', 'Un Etat sans lois', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000074', 'Un Etat monarchique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000075', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Quel article de la CEDH protege le droit a un proces equitable ?',
 'L''article 6 de la CEDH garantit le droit a un proces equitable : tribunal independant et impartial, jugement public dans un delai raisonnable, presomption d''innocence, droits de la defense.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000075', 'L''article 6', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000075', 'L''article 1er', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000075', 'L''article 12', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000075', 'L''article 30', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000076', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Comment la France peut-elle etre condamnee par la Cour europeenne des droits de l''homme ?',
 'Sur recours individuel d''une personne ayant epuise ses voies de recours internes, la CEDH peut declarer que la France a viole la Convention. La France doit alors modifier sa pratique et indemniser le requerant.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000076', 'Sur recours individuel apres epuisement des recours internes', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000076', 'Automatiquement chaque annee', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000076', 'Par decision du Parlement europeen', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000076', 'Jamais', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000077', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Quels sont les principaux ''devoirs constitutionnels'' du citoyen ?',
 'La Constitution implique des devoirs : respect de la loi, paiement des contributions communes, defense de la patrie (article 35), preservation de l''environnement (Charte de 2004), respect de la dignite humaine.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000077', 'Respect de la loi, contributions, defense, environnement', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000077', 'Aucun devoir n''est constitutionnel', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000077', 'Uniquement payer la TVA', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000077', 'Uniquement le service militaire', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000078', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'L''objection de conscience militaire est-elle reconnue en France ?',
 'Le statut d''objecteur de conscience a existe en France jusqu''a la suspension du service militaire en 1997. Avec la professionnalisation, la question ne se pose plus de la meme maniere. Aujourd''hui, le service est volontaire.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000078', 'Anciennement, mais le service militaire est suspendu depuis 1997', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000078', 'Non, jamais reconnu', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000078', 'Uniquement pour les religieux', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000078', 'Uniquement les hommes', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000079', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Que signifie le principe d''''egalite reelle'' ?',
 'L''egalite reelle (par opposition a l''egalite formelle) vise a corriger les inegalites de fait, par des politiques publiques (education prioritaire, parite, accessibilite handicap, discrimination positive).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000079', 'Corriger les inegalites de fait par des politiques publiques', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000079', 'Faire tous identiques', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000079', 'Supprimer la propriete', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000079', 'Donner plus aux puissants', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000007a', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'L''arret ''Marbury vs Madison'' equivalent francais reconnaissant la portee constitutionnelle des principes ?',
 'La decision du Conseil constitutionnel du 16 juillet 1971 (''liberte d''association'') a reconnu la valeur constitutionnelle du preambule de 1946, donc des droits sociaux et de la DDHC. Equivalent francais d''un controle de constitutionnalite renforce.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000007a', 'La decision du 16 juillet 1971 sur la liberte d''association', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000007a', 'L''arret Sarran de 1998', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000007a', 'L''arret Nicolo de 1989', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000007a', 'Aucune decision francaise comparable', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000007b', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Que prevoit le principe de subsidiarite dans l''Union europeenne ?',
 'Le principe de subsidiarite (article 5 TUE) impose que l''UE n''agisse, dans les domaines non exclusifs, que si l''action est plus efficace au niveau europeen qu''au niveau national.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000007b', 'L''UE agit si l''action est plus efficace au niveau europeen', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000007b', 'L''UE remplace toujours les Etats', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000007b', 'Les Etats peuvent ignorer l''UE', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000007b', 'Tout est decide a Bruxelles', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000007c', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'L''apatridie est-elle protegee par le droit francais ?',
 'Oui. La Convention de 1954 et le droit francais protegent les apatrides (personnes sans nationalite). L''OFPRA peut leur accorder un statut leur permettant de sejourner et de circuler.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000007c', 'Oui, statut d''apatride accorde par l''OFPRA', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000007c', 'Non, ils sont expulses', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000007c', 'Ils ne peuvent pas exister', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000007c', 'Uniquement les enfants', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-0000000000b1', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Qu''est-ce que le droit a un environnement equilibre selon la Charte de 2004 ?',
 'L''article 1er de la Charte de l''environnement reconnait le droit pour chacun de vivre dans un environnement equilibre et respectueux de la sante. Adossee a la Constitution depuis 2005.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b1', 'Le droit a un environnement equilibre et respectueux de la sante', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b1', 'Le droit a la pollution', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b1', 'Un droit europeen non integre', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b1', 'Aucun droit specifique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-0000000000b2', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Qu''est-ce que la ''liberte syndicale'' en droit francais ?',
 'La liberte syndicale (preambule de 1946) garantit le droit de creer ou d''adherer a un syndicat pour defendre ses interets professionnels. Elle est protegee constitutionnellement.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b2', 'Le droit de creer et d''adherer a un syndicat', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b2', 'L''obligation d''etre syndique', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b2', 'Un droit interdit', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b2', 'Un droit reserve aux fonctionnaires', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-0000000000b3', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Le droit de greve est-il garanti constitutionnellement en France ?',
 'Oui. Le droit de greve est garanti par le preambule de la Constitution de 1946. Il s''exerce dans le cadre des lois qui le reglementent (preavis pour les fonctionnaires, etc.).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b3', 'Oui, par le preambule de 1946', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b3', 'Non, c''est interdit', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b3', 'Uniquement pour le prive', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b3', 'Uniquement pour le public', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-0000000000b4', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Que prevoit le droit a l''instruction selon la Constitution ?',
 'Le preambule de 1946 dispose que ''l''organisation de l''enseignement public gratuit et laique a tous les degres est un devoir de l''Etat''. L''instruction est gratuite jusqu''au lycee.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b4', 'L''enseignement public gratuit et laique a tous les degres', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b4', 'L''enseignement uniquement religieux', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b4', 'L''enseignement payant pour tous', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b4', 'Aucun droit a l''instruction', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-0000000000b5', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Que designe la notion de ''service public'' en droit administratif francais ?',
 'Un service public est une activite d''interet general assuree par une personne publique (Etat, collectivites) ou sous son controle. Il est regi par les principes d''egalite, de continuite et d''adaptabilite.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b5', 'Une activite d''interet general assuree par une personne publique', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b5', 'Une entreprise privee', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b5', 'Une association religieuse', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b5', 'Un loisir', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-0000000000b6', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Quels principes regissent le service public en France ?',
 'Les ''lois de Rolland'' enoncent trois principes : continuite (le service ne s''interrompt pas), egalite (meme service pour tous les usagers) et mutabilite/adaptabilite (le service s''adapte aux besoins).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b6', 'Continuite, egalite, mutabilite', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b6', 'Gratuite, secret, rapidite', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b6', 'Religion, tradition, hierarchie', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b6', 'Aucun principe particulier', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-0000000000b7', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Le droit a la sante est-il reconnu en France ?',
 'Oui. Le preambule de 1946 garantit a tous, notamment a l''enfant, a la mere, aux travailleurs ages, la protection de la sante. C''est un droit constitutionnel.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b7', 'Oui, garanti par le preambule de 1946', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b7', 'Non, c''est privatise', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b7', 'Uniquement les retraites', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b7', 'Uniquement les Francais nes en France', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-0000000000b8', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Qu''est-ce que le ''devoir de fraternite'' reconnu en France ?',
 'Le Conseil constitutionnel a reconnu en 2018 le principe de fraternite comme principe a valeur constitutionnelle, decoulant de la devise republicaine. Il a notamment justifie l''aide humanitaire desinteressee.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b8', 'Un principe constitutionnel decoulant de la devise republicaine (2018)', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b8', 'Une obligation religieuse', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b8', 'Une simple coutume', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000b8', 'Aucune valeur juridique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000007d', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'MISE_SITUATION',
 'Apres avoir epuise tous les recours en France, je veux saisir la Cour europeenne des droits de l''homme. Quelle est la demarche ?',
 'Vous adressez une requete (formulaire officiel) a la CEDH a Strasbourg, dans les 4 mois suivant la decision interne definitive. Pas d''avocat obligatoire pour la requete initiale. La cour examine la recevabilite.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000007d', 'Requete a Strasbourg dans les 4 mois apres recours interne definitif', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000007d', 'Aucune demarche possible', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000007d', 'Demander a l''ambassadeur', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000007d', 'Saisir le pape', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000007e', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'MISE_SITUATION',
 'Une mesure de l''etat d''urgence me prive d''une liberte (assignation a residence) et je la conteste. Quel recours ?',
 'Les mesures de l''etat d''urgence peuvent etre contestees devant le juge administratif (refere-liberte si l''urgence est grande, ou recours classique). Le juge controle leur proportionnalite.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000007e', 'Saisir le juge administratif (refere-liberte ou recours)', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000007e', 'Aucun recours possible', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000007e', 'Saisir le pape', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000007e', 'Faire la greve de la faim', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000007f', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'MISE_SITUATION',
 'Je decouvre qu''une loi en vigueur depuis 5 ans porte atteinte a un de mes droits constitutionnels. Quels recours ?',
 'Vous pouvez soulever une Question prioritaire de constitutionnalite (QPC) lors d''une procedure judiciaire ou administrative. Le Conseil constitutionnel peut alors abroger la loi pour l''avenir.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000007f', 'Soulever une QPC lors d''une procedure judiciaire', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000007f', 'Reecrire la loi soi-meme', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000007f', 'Forcer le Parlement a voter', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000007f', 'Aucun recours possible', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000080', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'MISE_SITUATION',
 'Mon employeur prive me discrimine en raison de mes convictions religieuses. Que faire ?',
 'Vous pouvez saisir le Defenseur des droits, les prud''hommes (juridiction du travail), ou deposer plainte penale. La discrimination religieuse au travail est un delit. La charge de la preuve est partagee.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000080', 'Saisir le Defenseur des droits, les prud''hommes, porter plainte', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000080', 'Aucune action possible', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000080', 'Changer de religion', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000080', 'Faire de meme avec d''autres salaries', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000081', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'MISE_SITUATION',
 'Je suis temoin d''un crime contre l''humanite commis a l''etranger par une personne residant maintenant en France. Que prevoit le droit ?',
 'La France peut juger les auteurs de crimes contre l''humanite, meme commis a l''etranger, en vertu de la competence universelle. Vous pouvez signaler les faits au procureur, qui pourra ouvrir une enquete.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000081', 'Signaler au procureur ; la competence universelle peut s''appliquer', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000081', 'Aucune action possible en France', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000081', 'Saisir directement la CPI', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000081', 'Renvoyer la personne dans son pays', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000082', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'MISE_SITUATION',
 'Le gouvernement adopte une mesure restrictive par ordonnance. Quels controles existent ?',
 'Les ordonnances peuvent etre contestees devant le Conseil d''Etat. Elles doivent ensuite etre ratifiees par le Parlement, sinon elles perdent leur valeur. Le Conseil constitutionnel peut aussi etre saisi de la loi de ratification.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000082', 'Recours devant le Conseil d''Etat, ratification parlementaire ensuite', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000082', 'Aucun controle', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000082', 'Uniquement controle de l''ONU', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000082', 'Uniquement le pape peut intervenir', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000083', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'MISE_SITUATION',
 'Une chaine de television refuse de diffuser un debat contradictoire pendant une campagne. Quel recours ?',
 'L''ARCOM (ex-CSA) veille au respect du pluralisme dans l''audiovisuel. Vous pouvez la saisir d''un signalement. Elle peut sanctionner les chaines manquant a leurs obligations.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000083', 'Saisir l''ARCOM, qui peut sanctionner la chaine', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000083', 'Aucune action possible', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000083', 'Forcer le studio a diffuser', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000083', 'Demander au pape de diffuser', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000084', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'MISE_SITUATION',
 'Une donnee personnelle me concernant est conservee illegalement par une entreprise. Que faire ?',
 'Saisir la CNIL (Commission nationale de l''informatique et des libertes). Elle peut sanctionner l''entreprise. Vous pouvez aussi faire valoir vos droits RGPD : effacement, portabilite, opposition.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000084', 'Saisir la CNIL et faire valoir vos droits RGPD', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000084', 'Aucun recours possible', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000084', 'Pirater l''entreprise', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000084', 'Demander au pape', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000085', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'MISE_SITUATION',
 'Un journal publie un article diffamatoire sur moi. Quels recours penaux et civils ?',
 'Diffamation = imputation d''un fait portant atteinte a l''honneur. Vous pouvez deposer plainte penale (delai de prescription tres court : 3 mois) et engager une action civile pour obtenir reparation et un droit de reponse.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000085', 'Plainte penale (dans 3 mois) + action civile + droit de reponse', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000085', 'Aucun recours', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000085', 'Diffamer aussi le journaliste', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000085', 'Fermer le journal', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000086', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'MISE_SITUATION',
 'L''administration prend une decision qui me touche sans m''avoir entendu. Quel recours ?',
 'Le ''principe du contradictoire'' impose souvent un echange prealable. Si une decision individuelle defavorable est prise sans procedure contradictoire requise, vous pouvez demander son annulation au tribunal administratif.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000086', 'Saisir le tribunal administratif pour vice de procedure', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000086', 'Aucun recours possible', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000086', 'Refuser d''obeir sans formalite', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000086', 'Saisir l''OTAN', FALSE, 3);
