-- Flyway: reformulations thème 3 DROITS_DEVOIRS lot 2/2 (R16-R30) - is_active=FALSE

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000001-0000-0000-0000-000000000010', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'MISE_SITUATION',
 'En France, est-il légal d''être marie a plusieurs personnes simultanement ?',
 'Non. La polygamie est interditée par la loi française. Le mariage civil n''est valable qu''entre deux personnes. La polygamie est un delit et fait obstacle à la naturalisation.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000010', 'Non, c''est interdit par la loi française', TRUE, 0),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000010', 'Oui, c''est libre', FALSE, 1),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000010', 'Oui, avec accord du premier conjoint', FALSE, 2),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000010', 'Uniquement pour certaines communautés', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000001-0000-0000-0000-000000000011', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'MISE_SITUATION',
 'Est-il important de reduire la quantité de ses dechets au quotidien ?',
 'Oui. Reduire ses dechets est un geste citoyen important pour proteger l''environnement et respecter le principe de developpement durable, inscrit dans la Charte de l''environnement de 2004.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000011', 'Oui, c''est un geste citoyen et ecologique', TRUE, 0),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000011', 'Non, c''est inutile', FALSE, 1),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000011', 'Uniquement le dimanche', FALSE, 2),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000011', 'Uniquement les retraites', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000001-0000-0000-0000-000000000012', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'MISE_SITUATION',
 'Jeter une bouteille dans la rue est-il autorisé en France ?',
 'Non. Jeter des dechets sur la voie publique est une infraction, punie d''une contravention. C''est aussi un manque de respect envers l''environnement et les autres.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000012', 'Non, c''est une infraction punie d''une amende', TRUE, 0),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000012', 'Oui, c''est libre', FALSE, 1),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000012', 'Uniquement le week-end', FALSE, 2),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000012', 'Uniquement les bouteilles en verre', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000001-0000-0000-0000-000000000013', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Pour quelles raisons les libertés individuelles peuvent-elles être encadrées par la loi ?',
 'Les libertés individuelles peuvent être limitées pour proteger l''ordre public, la sécurité, la sante publique, les droits d''autrui ou prevenir les atteintes à la dignite.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000013', 'Pour proteger l''ordre public, la sante, les droits des autres', TRUE, 0),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000013', 'Pour faire plaisir au gouvernement', FALSE, 1),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000013', 'Pour des raisons religieuses', FALSE, 2),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000013', 'Pour reduire les depenses publiques', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000001-0000-0000-0000-000000000014', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'MISE_SITUATION',
 'Que doit faire toute personne présente sur les lieux d''un accident grave ?',
 'Toute personne doit porter assistance à une personne en danger, ou au moins prevenir les secours (15, 17, 18, 112). Ne pas le faire constitue un delit de non-assistance a personne en danger.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000014', 'Porter assistance ou appeler les secours (112)', TRUE, 0),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000014', 'Continuer son chemin sans rien faire', FALSE, 1),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000014', 'Filmer l''accident pour les réseaux', FALSE, 2),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000014', 'Voler les affaires de la victime', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000001-0000-0000-0000-000000000015', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Quels droits la citoyenneté française permet-elle d''exercer ?',
 'La citoyenneté française donne droit de vote et d''éligibilité à toutes les élections, droit à la protection de l''État (à l''étranger), droit d''occuper des fonctions publiques.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000015', 'Voter, être éligible, bénéficier de la protection de l''État', TRUE, 0),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000015', 'Aucun droit particulier', FALSE, 1),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000015', 'Uniquement le droit de porter le drapeau', FALSE, 2),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000015', 'Le droit à un revenu universel', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000001-0000-0000-0000-000000000016', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'CONNAISSANCE',
 'Que risque une personne qui ne respecte pas la loi en France ?',
 'Une personne qui enfreint la loi s''expose à des sanctions (amendes, prison, travaux d''intérêt général), prononcées par les tribunaux selon la gravite de l''infraction.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000016', 'Des sanctions pénales (amendes, prison, TIG)', TRUE, 0),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000016', 'Rien du tout', FALSE, 1),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000016', 'Uniquement un avertissement verbal', FALSE, 2),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000016', 'Une recompense', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000001-0000-0000-0000-000000000017', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Quel est le rôle de la gendarmerie en France ?',
 'La gendarmerie assure la sécurité publique et la lutte contre la délinquance, principalement en zones rurales et periurbaines. C''est une force militaire placée sous l''autorité du ministère de l''Intérieur.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000017', 'Sécurité publique en zones rurales et periurbaines', TRUE, 0),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000017', 'Gerer les écoles', FALSE, 1),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000017', 'Voter les lois', FALSE, 2),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000017', 'Distribuer le courrier', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000001-0000-0000-0000-000000000018', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'CONNAISSANCE',
 'Quel est le rôle de la police nationale en France ?',
 'La police nationale est chargée de la sécurité publique principalement en zones urbaines : prevenir et constater les infractions, proteger les personnes et les biens, maintenir l''ordre.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000018', 'Sécurité publique principalement en zones urbaines', TRUE, 0),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000018', 'Voter les lois', FALSE, 1),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000018', 'Diriger les écoles', FALSE, 2),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000018', 'Reparer les routes', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000001-0000-0000-0000-000000000019', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Que designe-t-on par ''infraction'' en droit français ?',
 'Une infraction est un comportement interdit et puni par la loi. Elle comprend les contraventions (peu graves), les delits (moyennes) et les crimes (graves).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000019', 'Un acte interdit puni par la loi (contravention, delit, crime)', TRUE, 0),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000019', 'Un avis personnel', FALSE, 1),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000019', 'Une croyance religieuse', FALSE, 2),
(gen_random_uuid(), 'f3000001-0000-0000-0000-000000000019', 'Un acte de courage', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000001-0000-0000-0000-00000000001a', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CSP', 'MISE_SITUATION',
 'Comment peut-on reduire concretement sa production de dechets ?',
 'On peut reduire ses dechets : trier les recyclables, composter les biodechets, éviter les emballages superflus, reparer plutot que jeter, acheter d''occasion ou en vrac.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000001-0000-0000-0000-00000000001a', 'Trier, composter, éviter les emballages, reparer', TRUE, 0),
(gen_random_uuid(), 'f3000001-0000-0000-0000-00000000001a', 'Tout jeter dans le même sac', FALSE, 1),
(gen_random_uuid(), 'f3000001-0000-0000-0000-00000000001a', 'Bruler les dechets à la maison', FALSE, 2),
(gen_random_uuid(), 'f3000001-0000-0000-0000-00000000001a', 'Les jeter dans la rue', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000001-0000-0000-0000-00000000001b', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'MISE_SITUATION',
 'Est-il autorisé de laisser un gros encombrant (electromenager, meuble) sur le trottoir ?',
 'Non. Déposer un encombrant sur la voie publique sans autorisation est une infraction. Les communes organisent des collectes spécifiques ou disposent de dechetteries.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000001-0000-0000-0000-00000000001b', 'Non, c''est une infraction ; il faut utiliser la dechetterie ou la collecte d''encombrants', TRUE, 0),
(gen_random_uuid(), 'f3000001-0000-0000-0000-00000000001b', 'Oui, c''est libre', FALSE, 1),
(gen_random_uuid(), 'f3000001-0000-0000-0000-00000000001b', 'Uniquement la nuit', FALSE, 2),
(gen_random_uuid(), 'f3000001-0000-0000-0000-00000000001b', 'Uniquement le 14 juillet', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000001-0000-0000-0000-00000000001c', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
 'Que désigne la traité des etres humains ?',
 'La traité des etres humains est le recrutement, le transport ou l''hebergement de personnes à des fins d''exploitation (sexuelle, travail force, mendicite, prelevement d''organes). C''est un crime grave puni severement par la loi.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000001-0000-0000-0000-00000000001c', 'L''exploitation de personnes (travail force, prostitution forcee, etc.)', TRUE, 0),
(gen_random_uuid(), 'f3000001-0000-0000-0000-00000000001c', 'Le commerce d''animaux', FALSE, 1),
(gen_random_uuid(), 'f3000001-0000-0000-0000-00000000001c', 'Un trafic de drogue', FALSE, 2),
(gen_random_uuid(), 'f3000001-0000-0000-0000-00000000001c', 'Un commerce équitable', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000001-0000-0000-0000-00000000001d', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'MISE_SITUATION',
 'Que doit faire une personne victime de violences (conjugales, sexuelles, agression) ?',
 'Une victime de violences doit porter plainte au commissariat ou en gendarmerie. Elle peut être accompagnée par des associations specialisees, des avocats, et a droit à une protection (eloignement de l''agresseur).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000001-0000-0000-0000-00000000001d', 'Porter plainte et se faire accompagner par des associations specialisees', TRUE, 0),
(gen_random_uuid(), 'f3000001-0000-0000-0000-00000000001d', 'Rester silencieuse', FALSE, 1),
(gen_random_uuid(), 'f3000001-0000-0000-0000-00000000001d', 'Se venger elle-même', FALSE, 2),
(gen_random_uuid(), 'f3000001-0000-0000-0000-00000000001d', 'Quitter le pays', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000001-0000-0000-0000-00000000001e', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Quelle est la catégorie d''infractions la plus grave en droit pénal français ?',
 'Le crime est l''infraction la plus grave (meurtre, viol, etc.). Il est jugé par la cour d''assises et puni par des peines pouvant aller jusqu''à la reclusion criminelle a perpetuite.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000001-0000-0000-0000-00000000001e', 'Le crime (meurtre, viol)', TRUE, 0),
(gen_random_uuid(), 'f3000001-0000-0000-0000-00000000001e', 'La contravention de stationnement', FALSE, 1),
(gen_random_uuid(), 'f3000001-0000-0000-0000-00000000001e', 'Le retard de paiement', FALSE, 2),
(gen_random_uuid(), 'f3000001-0000-0000-0000-00000000001e', 'L''oubli d''une obligation', FALSE, 3);
