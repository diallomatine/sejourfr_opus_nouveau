-- Flyway: niveau 3 thème 3 DROITS_DEVOIRS - 50 CR (40 CONN + 10 MS) - is_active=FALSE

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000033', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Que prévoit l''article 1er de la DDHC de 1789 ?',
 'L''article 1er de la Déclaration de 1789 énonce : ''Les hommes naissent et demeurent libres et égaux en droits.'' Il pose le principe d''égalité et de liberté.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000033', 'Que les hommes naissent libres et égaux en droits', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000033', 'Que tout est gratuit pour les nobles', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000033', 'Que la religion est obligatoire', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000033', 'Que la France est un royaume', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000034', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Quels sont les droits naturels imprescriptibles selon la DDHC de 1789 ?',
 'L''article 2 de la DDHC de 1789 cite quatre droits naturels et imprescriptibles : la liberté, la propriété, la sûreté (sécurité) et la résistance à l''oppression.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000034', 'Liberté, propriété, sûreté et résistance à l''oppression', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000034', 'Travail, famille, patrie', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000034', 'Santé, éducation, retraite', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000034', 'Vote, éligibilité, éducation', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000035', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Que stipule l''article 4 de la DDHC sur la liberté ?',
 'L''article 4 énonce : ''La liberté consiste à pouvoir faire tout ce qui ne nuit pas à autrui''. Elle s''arrête là où commence celle des autres.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000035', 'La liberté est de faire ce qui ne nuit pas à autrui', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000035', 'La liberté est totale sans limite', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000035', 'La liberté est réservée aux nobles', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000035', 'La liberté est définie par le pape', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000036', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Le droit à la présomption d''innocence figure-t-il dans la DDHC ?',
 'Oui. L''article 9 dispose : ''Tout homme étant présumé innocent jusqu''à ce qu''il ait été déclaré coupable...'' C''est un principe fondamental du droit pénal français.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000036', 'Oui, article 9 de la DDHC', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000036', 'Non, c''est une invention récente', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000036', 'Non, c''est un principe religieux', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000036', 'Oui, mais réservé aux Français', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000037', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Que dit la DDHC concernant l''égalité devant la loi ?',
 'L''article 6 dispose que ''la loi est l''expression de la volonté générale'' et que ''tous les citoyens sont égaux à ses yeux''. C''est le principe d''égalité devant la loi.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000037', 'Tous les citoyens sont égaux devant la loi', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000037', 'La loi varie selon la classe sociale', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000037', 'La loi est différente pour les hommes et les femmes', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000037', 'La loi favorise les militaires', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000038', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Quel article de la DDHC établit la liberté d''expression ?',
 'L''article 11 de la DDHC dispose que ''la libre communication des pensées et des opinions est un des droits les plus précieux de l''homme''. C''est le fondement de la liberté d''expression.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000038', 'L''article 11', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000038', 'L''article 1er', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000038', 'L''article 17', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000038', 'Aucun article ne le prévoit', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000039', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'La liberté d''expression est-elle absolue selon le droit français ?',
 'Non. La liberté d''expression est limitée par la loi (injure, diffamation, incitation à la haine, apologie du terrorisme, atteinte à la vie privée). Ces limites visent à protéger autrui.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000039', 'Non, elle est encadrée par la loi', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000039', 'Oui, totalement absolue', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000039', 'Uniquement pour la presse', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000039', 'Uniquement dans les universités', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000003a', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Quel principe protège le secret des correspondances ?',
 'L''inviolabilité des correspondances est un droit fondamental. Ouvrir le courrier d''autrui, intercepter ses communications ou pirater ses comptes est un délit puni pénalement.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000003a', 'L''inviolabilité des correspondances', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000003a', 'Le droit à la propriété', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000003a', 'Le droit à la santé', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000003a', 'Le droit à la retraite', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000003b', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Le droit à la vie privée est-il protégé en France ?',
 'Oui. L''article 9 du Code civil dispose que ''chacun a droit au respect de sa vie privée''. Sa violation peut donner lieu à des dommages et intérêts et à des sanctions pénales.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000003b', 'Oui, article 9 du Code civil', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000003b', 'Non, c''est aboli', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000003b', 'Uniquement pour les célébrités', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000003b', 'Uniquement dans les hôpitaux', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000003c', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Que prévoit le droit à l''image ?',
 'Le droit à l''image protège chacun contre l''utilisation non autorisée de son image. La diffusion sans consentement peut donner lieu à des dommages et intérêts et à une condamnation pénale.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000003c', 'Le consentement est requis pour utiliser l''image d''une personne', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000003c', 'Toute image peut être librement diffusée', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000003c', 'Uniquement pour les enfants', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000003c', 'Uniquement les images publiques', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000003d', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Le droit à un procès équitable est-il garanti en France ?',
 'Oui. Il est garanti par la Constitution, la DDHC et la Convention européenne des droits de l''homme (article 6). Il comprend l''accès au juge, l''égalité des armes, la présomption d''innocence, le droit à la défense.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000003d', 'Oui, garanti par la Constitution et la CEDH', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000003d', 'Non, c''est une formalité', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000003d', 'Uniquement pour les Français', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000003d', 'Uniquement en matière civile', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000003e', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Que prévoit le principe de légalité des délits et des peines ?',
 'Article 8 de la DDHC : ''Nul ne peut être puni qu''en vertu d''une loi établie et promulguée antérieurement au délit''. Une infraction et sa peine doivent être prévues par la loi.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000003e', 'Nul ne peut être puni sans loi préalable (article 8 DDHC)', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000003e', 'Le juge crée les peines', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000003e', 'Le pape détermine les délits', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000003e', 'Aucune règle n''existe', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000003f', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Que désigne la présomption d''innocence ?',
 'La présomption d''innocence signifie qu''une personne est considérée innocente tant qu''elle n''a pas été jugée coupable définitivement. C''est la charge de la preuve qui incombe à l''accusation.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000003f', 'L''accusé est présumé innocent jusqu''à condamnation définitive', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000003f', 'L''accusé doit prouver son innocence', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000003f', 'L''accusé est coupable par défaut', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000003f', 'L''accusé est ignoré par la justice', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000040', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Quel est le délai général de prescription pour les délits en France ?',
 'Le délai de prescription pour les délits est de 6 ans depuis 2017 (porté de 3 à 6 ans par la loi du 27 février 2017). Au-delà, l''action publique ne peut plus être exercée.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000040', '6 ans depuis 2017', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000040', '10 ans toujours', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000040', '30 jours', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000040', 'Aucune prescription', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000041', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'La torture est-elle interdite par la loi française ?',
 'Oui. La torture, les traitements inhumains ou dégradants sont prohibés par la Constitution, la Convention européenne des droits de l''homme (article 3) et le Code pénal français. C''est une interdiction absolue.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000041', 'Oui, c''est interdit de façon absolue', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000041', 'Non, sous certaines conditions', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000041', 'Uniquement en temps de paix', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000041', 'Uniquement pour les Français', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000042', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Que désigne la ''liberté d''aller et venir'' ?',
 'C''est la liberté de circuler librement sur le territoire français et de le quitter. C''est un droit fondamental, qui peut être restreint par la loi (contrôles, mesures judiciaires).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000042', 'La liberté de circuler et de quitter le territoire', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000042', 'La liberté religieuse', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000042', 'La liberté d''opinion', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000042', 'La liberté de commerce', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000043', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Le droit d''asile est-il reconnu en France ?',
 'Oui. La France accorde l''asile aux personnes persécutées dans leur pays en raison de leur action en faveur de la liberté (préambule de la Constitution de 1946). L''OFPRA traite les demandes.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000043', 'Oui, garanti par le préambule de la Constitution', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000043', 'Non, c''est interdit', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000043', 'Uniquement aux Européens', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000043', 'Uniquement temporairement', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000044', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Qu''est-ce que le droit à la dignité humaine ?',
 'Le principe de dignité humaine, principe constitutionnel depuis 1994, protège chaque personne de toute atteinte dégradant sa condition d''être humain. Il fonde de nombreux droits fondamentaux.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000044', 'Un principe constitutionnel protégeant la condition humaine', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000044', 'Un avantage fiscal', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000044', 'Une obligation religieuse', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000044', 'Un droit réservé aux femmes', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000045', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Quels sont les droits sociaux fondamentaux en France ?',
 'Le préambule de 1946 reconnaît notamment : le droit à la santé, à l''éducation, au travail, à la sécurité matérielle, au logement, à la participation à la gestion des entreprises.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000045', 'Droit à la santé, éducation, travail, sécurité matérielle', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000045', 'Aucun droit social', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000045', 'Uniquement le droit à l''argent', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000045', 'Droits réservés aux militaires', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000046', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Que prévoit le droit au logement opposable (DALO) ?',
 'La loi DALO de 2007 reconnaît un droit au logement décent. Les personnes en difficulté peuvent saisir une commission de médiation, voire le tribunal pour faire valoir ce droit.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000046', 'Un recours légal pour obtenir un logement décent', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000046', 'L''attribution automatique d''un logement', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000046', 'Un droit réservé aux fonctionnaires', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000046', 'Un droit européen non transposé', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000047', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'L''aide juridictionnelle existe-t-elle pour les justiciables modestes ?',
 'Oui. L''aide juridictionnelle, totale ou partielle, est accordée aux personnes dont les revenus ne dépassent pas un certain plafond. Elle permet de payer les frais d''avocat et de procès.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000047', 'Oui, sous conditions de ressources', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000047', 'Non, c''est payé par tous', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000047', 'Uniquement pour les retraités', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000047', 'Uniquement pour les Français', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000048', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'L''esclavage est-il considéré comme un crime contre l''humanité en droit français ?',
 'Oui. La loi Taubira de 2001 reconnaît la traite négrière et l''esclavage comme crimes contre l''humanité. Le 10 mai est journée nationale de commémoration.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000048', 'Oui, depuis la loi Taubira de 2001', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000048', 'Non, c''est un simple délit', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000048', 'Uniquement en outre-mer', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000048', 'Uniquement pour le 19e siècle', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000049', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Que dit la loi sur la haine en ligne ?',
 'Les propos haineux (racistes, sexistes, homophobes, etc.) sur internet relèvent du droit pénal français (loi de 1881 sur la presse). Les plateformes ont aussi des obligations de modération (loi Avia/DSA).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000049', 'Punis par la loi de 1881 et la régulation des plateformes', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000049', 'Liberté totale sur internet', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000049', 'Uniquement les commentaires anonymes', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000049', 'Uniquement entre adultes', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000004a', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Qu''est-ce que la double peine pour un étranger ?',
 'La double peine désigne la situation où un étranger condamné à une peine de prison est ensuite expulsé du territoire français. La loi de 2003 a limité cette pratique mais pas supprimée.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000004a', 'Une peine de prison suivie d''une expulsion du territoire', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000004a', 'Deux peines successives à domicile', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000004a', 'Une amende doublée', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000004a', 'Une peine annulée', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000004b', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Une victime peut-elle bénéficier d''aides spécifiques en France ?',
 'Oui. Les victimes peuvent être indemnisées par la Commission d''indemnisation des victimes d''infractions (CIVI), bénéficier d''un accompagnement par des associations (France Victimes au 116 006).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000004b', 'Oui, via la CIVI et les associations (116 006)', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000004b', 'Non, aucune aide n''existe', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000004b', 'Uniquement les Français', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000004b', 'Uniquement les adultes', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000004c', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Quels sont les principaux devoirs du citoyen français ?',
 'Respecter la loi, payer ses impôts, accomplir les obligations militaires (Journée défense et citoyenneté), défendre la patrie, être solidaire, respecter les autres et l''environnement.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000004c', 'Respecter la loi, payer ses impôts, être solidaire', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000004c', 'Aucun devoir', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000004c', 'Uniquement servir l''armée', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000004c', 'Uniquement assister aux cérémonies', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000004d', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'La Journée défense et citoyenneté est-elle obligatoire pour les jeunes Français ?',
 'Oui. Tous les jeunes français (filles et garçons) doivent participer à la Journée défense et citoyenneté (JDC) entre 16 et 25 ans. C''est une condition pour passer le permis ou les concours.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000004d', 'Oui, entre 16 et 25 ans', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000004d', 'Non, c''est facultatif', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000004d', 'Uniquement les garçons', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000004d', 'Uniquement les filles', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000004e', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Que représente la Charte de l''environnement de 2004 ?',
 'La Charte de l''environnement, adossée à la Constitution depuis 2005, reconnaît le droit à un environnement sain et l''obligation pour chacun de protéger l''environnement.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000004e', 'Le droit à un environnement sain et le devoir de le protéger', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000004e', 'Une charte facultative', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000004e', 'Un texte sans valeur juridique', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000004e', 'Une loi européenne uniquement', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000004f', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Quel principe environnemental impose de prévenir les dommages graves à l''environnement ?',
 'Le principe de précaution (article 5 de la Charte de l''environnement) impose des mesures provisoires pour prévenir un risque grave de dommage à l''environnement, même en cas d''incertitude scientifique.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000004f', 'Le principe de précaution (Charte de l''environnement)', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000004f', 'Le principe de proportionnalité', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000004f', 'Le principe de neutralité', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000004f', 'Le principe de subsidiarité', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000050', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Le harcèlement moral au travail est-il sanctionné ?',
 'Oui. Le harcèlement moral est un délit puni par le Code du travail et le Code pénal (article 222-33-2). La victime peut saisir les prud''hommes et porter plainte.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000050', 'Oui, c''est un délit puni pénalement', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000050', 'Non, c''est libre', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000050', 'Uniquement entre supérieurs', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000050', 'Uniquement les femmes y ont droit', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000051', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Le harcèlement sexuel est-il interdit en France ?',
 'Oui. Le harcèlement sexuel est un délit (article 222-33 du Code pénal) puni de 2 ans de prison et 30 000 EUR d''amende, plus selon les circonstances (mineur, autorité, etc.).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000051', 'Oui, c''est un délit grave puni pénalement', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000051', 'Non, c''est toléré', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000051', 'Uniquement physique', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000051', 'Uniquement avec menaces explicites', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000052', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Le droit à la mort digne (fin de vie) existe-t-il en France ?',
 'La loi Claeys-Leonetti (2016) reconnaît le droit à une sédation profonde et continue pour les malades en fin de vie. L''euthanasie active reste interdite ; un débat parlementaire est en cours sur l''aide à mourir.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000052', 'Oui, par sédation profonde (loi Claeys-Leonetti 2016)', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000052', 'Non, aucun cadre légal', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000052', 'Oui, l''euthanasie est légalisée', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000052', 'Uniquement pour les hommes', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-0000000000a1', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Quel principe interdit toute peine cruelle ou dégradante ?',
 'Le principe de dignité humaine et l''article 3 de la Convention européenne des droits de l''homme prohibent absolument les traitements cruels, inhumains ou dégradants, même en temps de guerre.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a1', 'L''interdiction des traitements dégradants (article 3 CEDH)', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a1', 'Le principe de proportionnalité', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a1', 'Le droit à la propriété', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a1', 'La liberté d''expression', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-0000000000a2', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Qu''est-ce que le ''droit à l''oubli'' numérique ?',
 'Le droit à l''oubli permet à une personne de demander le déréférencement (suppression des résultats de recherche) ou l''effacement de données personnelles obsolètes ou inappropriées, garanti par le RGPD.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a2', 'Le droit de demander l''effacement de données personnelles', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a2', 'Le droit d''effacer toute sa vie', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a2', 'Un droit réservé aux mineurs', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a2', 'Aucun droit spécifique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-0000000000a3', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Que protège le RGPD (Règlement général sur la protection des données) ?',
 'Le RGPD, en vigueur depuis 2018, protège les données personnelles des citoyens européens. Il impose aux entreprises consentement, transparence, sécurité, et accorde plusieurs droits (accès, rectification, effacement).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a3', 'Les données personnelles des citoyens européens', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a3', 'Les données bancaires uniquement', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a3', 'Les données médicales uniquement', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a3', 'Aucune donnée', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-0000000000a4', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Le viol est-il un crime en droit français ?',
 'Oui. Le viol est un crime (article 222-23 du Code pénal), puni de 15 ans de réclusion criminelle, plus selon les circonstances aggravantes (mineur, autorité, etc.).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a4', 'Oui, c''est un crime jugé en cour d''assises', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a4', 'Non, c''est un simple délit', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a4', 'Uniquement entre étrangers', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a4', 'Uniquement avec violence visible', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-0000000000a5', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'L''incitation à la haine raciale est-elle réprimée en France ?',
 'Oui. La provocation à la haine, la discrimination ou la violence en raison de l''origine, de la religion ou du sexe est un délit puni par la loi de 1881 sur la presse (1 an de prison, 45 000 EUR d''amende).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a5', 'Oui, c''est un délit puni par la loi', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a5', 'Non, c''est de l''opinion', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a5', 'Uniquement les insultes directes', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a5', 'Uniquement en public', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-0000000000a6', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Quel principe protège chacun de la ''rétroactivité'' d''une loi pénale plus sévère ?',
 'Le principe de non-rétroactivité de la loi pénale plus sévère (article 8 DDHC, article 112-1 du Code pénal) interdit d''appliquer une loi nouvelle plus dure aux faits commis avant son entrée en vigueur.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a6', 'La non-rétroactivité de la loi pénale plus sévère', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a6', 'La présomption d''innocence', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a6', 'La double incrimination', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a6', 'L''amnistie générale', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-0000000000a7', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Le mariage pour tous (entre personnes de même sexe) est-il légal en France ?',
 'Oui. La loi du 17 mai 2013, dite ''Mariage pour tous'', autorise le mariage entre personnes de même sexe et leur ouvre l''adoption.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a7', 'Oui, depuis la loi du 17 mai 2013', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a7', 'Non, c''est interdit', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a7', 'Uniquement le PACS', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a7', 'Uniquement entre adultes consentants étrangers', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-0000000000a8', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Qu''est-ce que le pacte civil de solidarité (PACS) ?',
 'Le PACS, créé en 1999, est un contrat conclu entre deux personnes majeures (de même sexe ou non) pour organiser leur vie commune. C''est moins formel que le mariage mais a des effets juridiques.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a8', 'Un contrat pour organiser la vie commune (entre 2 majeurs)', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a8', 'Un permis de conduire', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a8', 'Une assurance médicale', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a8', 'Une carte de transport', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000053', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'MISE_SITUATION',
 'Mon employeur cumule plusieurs comportements de harcèlement moral. Que faire ?',
 'Conservez les preuves (mails, témoignages). Alertez le service RH, les représentants du personnel, l''inspection du travail. Saisissez les prud''hommes. Vous pouvez aussi porter plainte pénalement.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000053', 'Réunir des preuves et saisir les prud''hommes / porter plainte', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000053', 'Démissionner immédiatement sans rien', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000053', 'Insulter l''employeur', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000053', 'Quitter la France', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000054', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'MISE_SITUATION',
 'Je suis victime de discrimination au logement en raison de mon origine. Quel recours ?',
 'Saisissez le Défenseur des droits, déposez plainte pénale (la discrimination au logement est punie de 3 ans de prison et 45 000 EUR d''amende). Une association comme SOS Racisme peut aider.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000054', 'Saisir le Défenseur des droits et porter plainte', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000054', 'Aucun recours possible', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000054', 'Changer de nom', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000054', 'Renoncer à chercher un logement', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000055', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'MISE_SITUATION',
 'Un commerçant refuse de me servir car je porte un signe religieux discret. Est-ce légal ?',
 'Non. Le refus de service fondé sur la religion est une discrimination punie par la loi. Vous pouvez déposer plainte et saisir le Défenseur des droits.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000055', 'Non, c''est une discrimination interdite', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000055', 'Oui, c''est son droit', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000055', 'Uniquement avec accord du maire', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000055', 'Uniquement la nuit', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000056', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'MISE_SITUATION',
 'Un site internet diffuse des photos privées de moi sans consentement. Que faire ?',
 'Vous pouvez demander le retrait au site (procédure prévue par la loi), saisir la CNIL pour les données personnelles, porter plainte (atteinte à la vie privée, droit à l''image) et engager une action civile.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000056', 'Demander le retrait, saisir la CNIL, porter plainte', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000056', 'Rien faire', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000056', 'Diffuser aussi des images de la personne', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000056', 'Quitter internet', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000057', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'MISE_SITUATION',
 'Mon enfant subit du harcèlement scolaire. Quels recours ?',
 'Alertez immédiatement le directeur d''école, écrivez à l''inspection académique. Le 3018 est dédié au harcèlement scolaire. Une plainte pénale est possible (délit de harcèlement).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000057', 'Alerter l''école, l''inspection, appeler le 3018, porter plainte', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000057', 'Rien faire', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000057', 'Punir l''enfant victime', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000057', 'Changer de pays', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000058', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'MISE_SITUATION',
 'On me réclame une somme d''argent sans justificatif. Comment me défendre ?',
 'Demandez par écrit le détail et le fondement de la créance. En cas de litige, saisissez le tribunal judiciaire (où des litiges < 10 000 EUR sans avocat obligatoire).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000058', 'Demander le justificatif et saisir le tribunal au besoin', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000058', 'Payer immédiatement sans questions', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000058', 'Insulter le créancier', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000058', 'Fuir le pays', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000059', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'MISE_SITUATION',
 'Mon propriétaire veut m''expulser sans suivre la procédure légale. Est-ce autorisé ?',
 'Non. L''expulsion d''un locataire ne peut se faire que par décision de justice et avec l''intervention d''un huissier. Toute expulsion forcée sans cette procédure est illégale et punie pénalement.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000059', 'Non, une décision de justice est obligatoire', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000059', 'Oui, le propriétaire décide', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000059', 'Oui, en l''absence de famille', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000059', 'Oui, en période estivale', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000005a', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'MISE_SITUATION',
 'Je veux signaler un acte de maltraitance sur un animal. Quelles démarches ?',
 'Vous pouvez contacter la SPA ou une autre association de protection animale, prévenir la police ou la gendarmerie. La maltraitance animale est un délit puni (article 521-1 du Code pénal).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000005a', 'Prévenir la SPA, la police ou la gendarmerie', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000005a', 'Rien faire', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000005a', 'Le faire moi-même aussi', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000005a', 'Quitter la France', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000005b', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'MISE_SITUATION',
 'Je suis perçu comme suspect par un policier qui me parle agressivement. Quels droits ?',
 'Restez calme et coopérez. Vous pouvez demander la raison du contrôle, l''identité du policier. Si vous estimez avoir été maltraité, vous pouvez déposer plainte auprès du procureur ou saisir l''IGPN.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000005b', 'Coopérer, demander le motif, déposer plainte si abus', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000005b', 'Frapper le policier', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000005b', 'Crier dans la rue', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000005b', 'Mentir sur mon identité', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000005c', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'MISE_SITUATION',
 'On me propose un travail très bien payé mais sans contrat ni déclaration. Que penser ?',
 'C''est du travail dissimulé, illégal en France. Vous n''aurez aucun droit social (assurance maladie, retraite, chômage), et vous risquez des sanctions. Refuser et signaler aux autorités.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000005c', 'Refuser et signaler : c''est du travail dissimulé illégal', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000005c', 'Accepter, c''est plus avantageux', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000005c', 'Négocier un meilleur taux', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000005c', 'Accepter mais en informer le pape', FALSE, 3);
