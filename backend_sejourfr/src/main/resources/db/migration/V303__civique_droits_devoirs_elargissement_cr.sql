-- Flyway: niveau 3 theme 3 DROITS_DEVOIRS - 50 CR (40 CONN + 10 MS) - is_active=FALSE

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000033', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Que prevoit l''article 1er de la DDHC de 1789 ?',
 'L''article 1er de la Declaration de 1789 enonce : ''Les hommes naissent et demeurent libres et egaux en droits.'' Il pose le principe d''egalite et de liberte.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000033', 'Que les hommes naissent libres et egaux en droits', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000033', 'Que tout est gratuit pour les nobles', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000033', 'Que la religion est obligatoire', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000033', 'Que la France est un royaume', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000034', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Quels sont les droits naturels imprescriptibles selon la DDHC de 1789 ?',
 'L''article 2 de la DDHC de 1789 cite quatre droits naturels et imprescriptibles : la liberte, la propriete, la surete (securite) et la resistance a l''oppression.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000034', 'Liberte, propriete, surete et resistance a l''oppression', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000034', 'Travail, famille, patrie', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000034', 'Sante, education, retraite', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000034', 'Vote, eligibilite, education', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000035', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Que stipule l''article 4 de la DDHC sur la liberte ?',
 'L''article 4 enonce : ''La liberte consiste a pouvoir faire tout ce qui ne nuit pas a autrui''. Elle s''arrete la ou commence celle des autres.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000035', 'La liberte est de faire ce qui ne nuit pas a autrui', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000035', 'La liberte est totale sans limite', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000035', 'La liberte est reservee aux nobles', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000035', 'La liberte est definie par le pape', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000036', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Le droit a la presomption d''innocence figure-t-il dans la DDHC ?',
 'Oui. L''article 9 dispose : ''Tout homme etant presume innocent jusqu''a ce qu''il ait ete declare coupable...'' C''est un principe fondamental du droit penal francais.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000036', 'Oui, article 9 de la DDHC', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000036', 'Non, c''est une invention recente', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000036', 'Non, c''est un principe religieux', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000036', 'Oui, mais reserve aux Francais', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000037', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Que dit la DDHC concernant l''egalite devant la loi ?',
 'L''article 6 dispose que ''la loi est l''expression de la volonte generale'' et que ''tous les citoyens sont egaux a ses yeux''. C''est le principe d''egalite devant la loi.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000037', 'Tous les citoyens sont egaux devant la loi', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000037', 'La loi varie selon la classe sociale', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000037', 'La loi est differente pour les hommes et les femmes', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000037', 'La loi favorise les militaires', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000038', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Quel article de la DDHC etablit la liberte d''expression ?',
 'L''article 11 de la DDHC dispose que ''la libre communication des pensees et des opinions est un des droits les plus precieux de l''homme''. C''est le fondement de la liberte d''expression.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000038', 'L''article 11', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000038', 'L''article 1er', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000038', 'L''article 17', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000038', 'Aucun article ne le prevoit', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000039', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'La liberte d''expression est-elle absolue selon le droit francais ?',
 'Non. La liberte d''expression est limitee par la loi (injure, diffamation, incitation a la haine, apologie du terrorisme, atteinte a la vie privee). Ces limites visent a proteger autrui.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000039', 'Non, elle est encadree par la loi', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000039', 'Oui, totalement absolue', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000039', 'Uniquement pour la presse', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000039', 'Uniquement dans les universites', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000003a', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Quel principe protege le secret des correspondances ?',
 'L''inviolabilite des correspondances est un droit fondamental. Ouvrir le courrier d''autrui, intercepter ses communications ou pirater ses comptes est un delit puni penalement.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000003a', 'L''inviolabilite des correspondances', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000003a', 'Le droit a la propriete', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000003a', 'Le droit a la sante', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000003a', 'Le droit a la retraite', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000003b', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Le droit a la vie privee est-il protege en France ?',
 'Oui. L''article 9 du Code civil dispose que ''chacun a droit au respect de sa vie privee''. Sa violation peut donner lieu a des dommages et interets et a des sanctions penales.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000003b', 'Oui, article 9 du Code civil', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000003b', 'Non, c''est aboli', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000003b', 'Uniquement pour les celebrites', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000003b', 'Uniquement dans les hopitaux', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000003c', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Que prevoit le droit a l''image ?',
 'Le droit a l''image protege chacun contre l''utilisation non autorisee de son image. La diffusion sans consentement peut donner lieu a des dommages et interets et a une condamnation penale.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000003c', 'Le consentement est requis pour utiliser l''image d''une personne', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000003c', 'Toute image peut etre librement diffusee', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000003c', 'Uniquement pour les enfants', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000003c', 'Uniquement les images publiques', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000003d', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Le droit a un proces equitable est-il garanti en France ?',
 'Oui. Il est garanti par la Constitution, la DDHC et la Convention europeenne des droits de l''homme (article 6). Il comprend l''acces au juge, l''egalite des armes, la presomption d''innocence, le droit a la defense.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000003d', 'Oui, garanti par la Constitution et la CEDH', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000003d', 'Non, c''est une formalite', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000003d', 'Uniquement pour les Francais', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000003d', 'Uniquement en matiere civile', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000003e', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Que prevoit le principe de legalite des delits et des peines ?',
 'Article 8 de la DDHC : ''Nul ne peut etre puni qu''en vertu d''une loi etablie et promulguee anterieurement au delit''. Une infraction et sa peine doivent etre prevues par la loi.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000003e', 'Nul ne peut etre puni sans loi prealable (article 8 DDHC)', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000003e', 'Le juge cree les peines', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000003e', 'Le pape determine les delits', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000003e', 'Aucune regle n''existe', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000003f', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Que designe la presomption d''innocence ?',
 'La presomption d''innocence signifie qu''une personne est consideree innocente tant qu''elle n''a pas ete jugee coupable definitivement. C''est la charge de la preuve qui incombe a l''accusation.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000003f', 'L''accuse est presume innocent jusqu''a condamnation definitive', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000003f', 'L''accuse doit prouver son innocence', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000003f', 'L''accuse est coupable par defaut', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000003f', 'L''accuse est ignore par la justice', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000040', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Quel est le delai general de prescription pour les delits en France ?',
 'Le delai de prescription pour les delits est de 6 ans depuis 2017 (porte de 3 a 6 ans par la loi du 27 fevrier 2017). Au-dela, l''action publique ne peut plus etre exercee.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000040', '6 ans depuis 2017', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000040', '10 ans toujours', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000040', '30 jours', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000040', 'Aucune prescription', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000041', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'La torture est-elle interdite par la loi francaise ?',
 'Oui. La torture, les traitements inhumains ou degradants sont prohibes par la Constitution, la Convention europeenne des droits de l''homme (article 3) et le Code penal francais. C''est une interdiction absolue.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000041', 'Oui, c''est interdit de facon absolue', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000041', 'Non, sous certaines conditions', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000041', 'Uniquement en temps de paix', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000041', 'Uniquement pour les Francais', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000042', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Que designe la ''liberte d''aller et venir'' ?',
 'C''est la liberte de circuler librement sur le territoire francais et de le quitter. C''est un droit fondamental, qui peut etre restreint par la loi (controles, mesures judiciaires).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000042', 'La liberte de circuler et de quitter le territoire', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000042', 'La liberte religieuse', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000042', 'La liberte d''opinion', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000042', 'La liberte de commerce', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000043', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Le droit d''asile est-il reconnu en France ?',
 'Oui. La France accorde l''asile aux personnes persecutees dans leur pays en raison de leur action en faveur de la liberte (preambule de la Constitution de 1946). L''OFPRA traite les demandes.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000043', 'Oui, garanti par le preambule de la Constitution', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000043', 'Non, c''est interdit', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000043', 'Uniquement aux Europeens', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000043', 'Uniquement temporairement', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000044', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Qu''est-ce que le droit a la dignite humaine ?',
 'Le principe de dignite humaine, principe constitutionnel depuis 1994, protege chaque personne de toute atteinte degradant sa condition d''etre humain. Il fonde de nombreux droits fondamentaux.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000044', 'Un principe constitutionnel protegeant la condition humaine', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000044', 'Un avantage fiscal', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000044', 'Une obligation religieuse', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000044', 'Un droit reserve aux femmes', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000045', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Quels sont les droits sociaux fondamentaux en France ?',
 'Le preambule de 1946 reconnait notamment : le droit a la sante, a l''education, au travail, a la securite materielle, au logement, a la participation a la gestion des entreprises.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000045', 'Droit a la sante, education, travail, securite materielle', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000045', 'Aucun droit social', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000045', 'Uniquement le droit a l''argent', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000045', 'Droits reserves aux militaires', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000046', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Que prevoit le droit au logement opposable (DALO) ?',
 'La loi DALO de 2007 reconnait un droit au logement decent. Les personnes en difficulte peuvent saisir une commission de mediation, voire le tribunal pour faire valoir ce droit.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000046', 'Un recours legal pour obtenir un logement decent', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000046', 'L''attribution automatique d''un logement', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000046', 'Un droit reserve aux fonctionnaires', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000046', 'Un droit europeen non transpose', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000047', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'L''aide juridictionnelle existe-t-elle pour les justiciables modestes ?',
 'Oui. L''aide juridictionnelle, totale ou partielle, est accordee aux personnes dont les revenus ne depassent pas un certain plafond. Elle permet de payer les frais d''avocat et de proces.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000047', 'Oui, sous conditions de ressources', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000047', 'Non, c''est paye par tous', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000047', 'Uniquement pour les retraites', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000047', 'Uniquement pour les Francais', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000048', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'L''esclavage est-il considere comme un crime contre l''humanite en droit francais ?',
 'Oui. La loi Taubira de 2001 reconnait la traite negriere et l''esclavage comme crimes contre l''humanite. Le 10 mai est journee nationale de commemoration.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000048', 'Oui, depuis la loi Taubira de 2001', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000048', 'Non, c''est un simple delit', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000048', 'Uniquement en outre-mer', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000048', 'Uniquement pour le 19e siecle', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000049', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Que dit la loi sur la haine en ligne ?',
 'Les propos haineux (racistes, sexistes, homophobes, etc.) sur internet relevent du droit penal francais (loi de 1881 sur la presse). Les plateformes ont aussi des obligations de moderation (loi Avia/DSA).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000049', 'Punis par la loi de 1881 et la regulation des plateformes', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000049', 'Liberte totale sur internet', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000049', 'Uniquement les commentaires anonymes', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000049', 'Uniquement entre adultes', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000004a', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Qu''est-ce que la double peine pour un etranger ?',
 'La double peine designe la situation ou un etranger condamne a une peine de prison est ensuite expulse du territoire francais. La loi de 2003 a limite cette pratique mais pas supprime.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000004a', 'Une peine de prison suivie d''une expulsion du territoire', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000004a', 'Deux peines successives a domicile', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000004a', 'Une amende doublee', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000004a', 'Une peine annulee', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000004b', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Une victime peut-elle beneficier d''aides specifiques en France ?',
 'Oui. Les victimes peuvent etre indemnisees par la Commission d''indemnisation des victimes d''infractions (CIVI), beneficier d''un accompagnement par des associations (France Victimes au 116 006).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000004b', 'Oui, via la CIVI et les associations (116 006)', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000004b', 'Non, aucune aide n''existe', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000004b', 'Uniquement les Francais', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000004b', 'Uniquement les adultes', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000004c', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Quels sont les principaux devoirs du citoyen francais ?',
 'Respecter la loi, payer ses impots, accomplir les obligations militaires (Journee defense et citoyennete), defendre la patrie, etre solidaire, respecter les autres et l''environnement.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000004c', 'Respecter la loi, payer ses impots, etre solidaire', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000004c', 'Aucun devoir', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000004c', 'Uniquement servir l''armee', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000004c', 'Uniquement assister aux ceremonies', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000004d', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'La Journee defense et citoyennete est-elle obligatoire pour les jeunes Francais ?',
 'Oui. Tous les jeunes francais (filles et garcons) doivent participer a la Journee defense et citoyennete (JDC) entre 16 et 25 ans. C''est une condition pour passer le permis ou les concours.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000004d', 'Oui, entre 16 et 25 ans', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000004d', 'Non, c''est facultatif', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000004d', 'Uniquement les garcons', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000004d', 'Uniquement les filles', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000004e', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Que represente la Charte de l''environnement de 2004 ?',
 'La Charte de l''environnement, adossee a la Constitution depuis 2005, reconnait le droit a un environnement sain et l''obligation pour chacun de proteger l''environnement.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000004e', 'Le droit a un environnement sain et le devoir de le proteger', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000004e', 'Une charte facultative', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000004e', 'Un texte sans valeur juridique', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000004e', 'Une loi europeenne uniquement', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000004f', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Quel principe environnemental impose de prevenir les dommages graves a l''environnement ?',
 'Le principe de precaution (article 5 de la Charte de l''environnement) impose des mesures provisoires pour prevenir un risque grave de dommage a l''environnement, meme en cas d''incertitude scientifique.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000004f', 'Le principe de precaution (Charte de l''environnement)', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000004f', 'Le principe de proportionnalite', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000004f', 'Le principe de neutralite', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000004f', 'Le principe de subsidiarite', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000050', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Le harcelement moral au travail est-il sanctionne ?',
 'Oui. Le harcelement moral est un delit puni par le Code du travail et le Code penal (article 222-33-2). La victime peut saisir les prud''hommes et porter plainte.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000050', 'Oui, c''est un delit puni penalement', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000050', 'Non, c''est libre', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000050', 'Uniquement entre superieurs', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000050', 'Uniquement les femmes y ont droit', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000051', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Le harcelement sexuel est-il interdit en France ?',
 'Oui. Le harcelement sexuel est un delit (article 222-33 du Code penal) puni de 2 ans de prison et 30 000 EUR d''amende, plus selon les circonstances (mineur, autorite, etc.).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000051', 'Oui, c''est un delit grave puni penalement', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000051', 'Non, c''est tolere', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000051', 'Uniquement physique', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000051', 'Uniquement avec menaces explicites', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000052', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Le droit a la mort digne (fin de vie) existe-t-il en France ?',
 'La loi Claeys-Leonetti (2016) reconnait le droit a une sedation profonde et continue pour les malades en fin de vie. L''euthanasie active reste interdite ; un debat parlementaire est en cours sur l''aide a mourir.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000052', 'Oui, par sedation profonde (loi Claeys-Leonetti 2016)', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000052', 'Non, aucun cadre legal', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000052', 'Oui, l''euthanasie est legalisee', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000052', 'Uniquement pour les hommes', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-0000000000a1', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Quel principe interdit toute peine cruelle ou degradante ?',
 'Le principe de dignite humaine et l''article 3 de la Convention europeenne des droits de l''homme prohibent absolument les traitements cruels, inhumains ou degradants, meme en temps de guerre.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a1', 'L''interdiction des traitements degradants (article 3 CEDH)', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a1', 'Le principe de proportionnalite', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a1', 'Le droit a la propriete', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a1', 'La liberte d''expression', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-0000000000a2', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Qu''est-ce que le ''droit a l''oubli'' numerique ?',
 'Le droit a l''oubli permet a une personne de demander le dereferencement (suppression des resultats de recherche) ou l''effacement de donnees personnelles obsoletes ou inappropriees, garanti par le RGPD.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a2', 'Le droit de demander l''effacement de donnees personnelles', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a2', 'Le droit d''effacer toute sa vie', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a2', 'Un droit reserve aux mineurs', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a2', 'Aucun droit specifique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-0000000000a3', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Que protege le RGPD (Reglement general sur la protection des donnees) ?',
 'Le RGPD, en vigueur depuis 2018, protege les donnees personnelles des citoyens europeens. Il impose aux entreprises consentement, transparence, securite, et accorde plusieurs droits (acces, rectification, effacement).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a3', 'Les donnees personnelles des citoyens europeens', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a3', 'Les donnees bancaires uniquement', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a3', 'Les donnees medicales uniquement', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a3', 'Aucune donnee', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-0000000000a4', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Le viol est-il un crime en droit francais ?',
 'Oui. Le viol est un crime (article 222-23 du Code penal), puni de 15 ans de reclusion criminelle, plus selon les circonstances aggravantes (mineur, autorite, etc.).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a4', 'Oui, c''est un crime juge en cour d''assises', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a4', 'Non, c''est un simple delit', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a4', 'Uniquement entre etrangers', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a4', 'Uniquement avec violence visible', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-0000000000a5', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'L''incitation a la haine raciale est-elle reprimee en France ?',
 'Oui. La provocation a la haine, la discrimination ou la violence en raison de l''origine, de la religion ou du sexe est un delit puni par la loi de 1881 sur la presse (1 an de prison, 45 000 EUR d''amende).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a5', 'Oui, c''est un delit puni par la loi', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a5', 'Non, c''est de l''opinion', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a5', 'Uniquement les insultes directes', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a5', 'Uniquement en public', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-0000000000a6', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Quel principe protege chacun de la ''rétroactivité'' d''une loi penale plus severe ?',
 'Le principe de non-retroactivite de la loi penale plus severe (article 8 DDHC, article 112-1 du Code penal) interdit d''appliquer une loi nouvelle plus dure aux faits commis avant son entree en vigueur.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a6', 'La non-retroactivite de la loi penale plus severe', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a6', 'La presomption d''innocence', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a6', 'La double incrimination', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a6', 'L''amnistie generale', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-0000000000a7', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Le mariage pour tous (entre personnes de meme sexe) est-il legal en France ?',
 'Oui. La loi du 17 mai 2013, dite ''Mariage pour tous'', autorise le mariage entre personnes de meme sexe et leur ouvre l''adoption.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a7', 'Oui, depuis la loi du 17 mai 2013', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a7', 'Non, c''est interdit', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a7', 'Uniquement le PACS', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a7', 'Uniquement entre adultes consentants etrangers', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-0000000000a8', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
 'Qu''est-ce que le pacte civil de solidarite (PACS) ?',
 'Le PACS, cree en 1999, est un contrat conclu entre deux personnes majeures (de meme sexe ou non) pour organiser leur vie commune. C''est moins formel que le mariage mais a des effets juridiques.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a8', 'Un contrat pour organiser la vie commune (entre 2 majeurs)', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a8', 'Un permis de conduire', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a8', 'Une assurance medicale', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-0000000000a8', 'Une carte de transport', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000053', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'MISE_SITUATION',
 'Mon employeur cumule plusieurs comportements de harcelement moral. Que faire ?',
 'Conservez les preuves (mails, temoignages). Alertez le service RH, les representants du personnel, l''inspection du travail. Saisissez les prud''hommes. Vous pouvez aussi porter plainte penalement.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000053', 'Reunir des preuves et saisir les prud''hommes / porter plainte', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000053', 'Demissionner immediatement sans rien', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000053', 'Insulter l''employeur', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000053', 'Quitter la France', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000054', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'MISE_SITUATION',
 'Je suis victime de discrimination au logement en raison de mon origine. Quel recours ?',
 'Saisissez le Defenseur des droits, deposez plainte penale (la discrimination au logement est punie de 3 ans de prison et 45 000 EUR d''amende). Une association comme SOS Racisme peut aider.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000054', 'Saisir le Defenseur des droits et porter plainte', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000054', 'Aucun recours possible', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000054', 'Changer de nom', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000054', 'Renoncer a chercher un logement', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000055', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'MISE_SITUATION',
 'Un commercant refuse de me servir car je porte un signe religieux discret. Est-ce legal ?',
 'Non. Le refus de service fonde sur la religion est une discrimination punie par la loi. Vous pouvez deposer plainte et saisir le Defenseur des droits.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000055', 'Non, c''est une discrimination interdite', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000055', 'Oui, c''est son droit', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000055', 'Uniquement avec accord du maire', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000055', 'Uniquement la nuit', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000056', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'MISE_SITUATION',
 'Un site internet diffuse des photos privees de moi sans consentement. Que faire ?',
 'Vous pouvez demander le retrait au site (procedure prevue par la loi), saisir la CNIL pour les donnees personnelles, porter plainte (atteinte a la vie privee, droit a l''image) et engager une action civile.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000056', 'Demander le retrait, saisir la CNIL, porter plainte', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000056', 'Rien faire', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000056', 'Diffuser aussi des images de la personne', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000056', 'Quitter internet', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000057', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'MISE_SITUATION',
 'Mon enfant subit du harcelement scolaire. Quels recours ?',
 'Alertez immediatement le directeur d''ecole, ecrivez a l''inspection academique. Le 3018 est dedie au harcelement scolaire. Une plainte penale est possible (delit de harcelement).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000057', 'Alerter l''ecole, l''inspection, appeler le 3018, porter plainte', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000057', 'Rien faire', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000057', 'Punir l''enfant victime', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000057', 'Changer de pays', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000058', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'MISE_SITUATION',
 'On me reclame une somme d''argent sans justificatif. Comment me defendre ?',
 'Demandez par ecrit le detail et le fondement de la creance. En cas de litige, saisissez le tribunal judiciaire (ou des litiges < 10 000 EUR sans avocat obligatoire).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000058', 'Demander le justificatif et saisir le tribunal au besoin', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000058', 'Payer immediatement sans questions', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000058', 'Insulter le creancier', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000058', 'Fuir le pays', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-000000000059', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'MISE_SITUATION',
 'Mon proprietaire veut m''expulser sans suivre la procedure legale. Est-ce autorise ?',
 'Non. L''expulsion d''un locataire ne peut se faire que par decision de justice et avec l''intervention d''un huissier. Toute expulsion forcee sans cette procedure est illegale et punie penalement.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000059', 'Non, une decision de justice est obligatoire', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000059', 'Oui, le proprietaire decide', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000059', 'Oui, en l''absence de famille', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-000000000059', 'Oui, en periode estivale', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000005a', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'MISE_SITUATION',
 'Je veux signaler un acte de maltraitance sur un animal. Quelles demarches ?',
 'Vous pouvez contacter la SPA ou une autre association de protection animale, prevenir la police ou la gendarmerie. La maltraitance animale est un delit puni (article 521-1 du Code penal).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000005a', 'Prevenir la SPA, la police ou la gendarmerie', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000005a', 'Rien faire', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000005a', 'Le faire moi-meme aussi', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000005a', 'Quitter la France', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000005b', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'MISE_SITUATION',
 'Je suis percu comme suspect par un policier qui me parle agressivement. Quels droits ?',
 'Restez calme et coopere. Vous pouvez demander la raison du controle, l''identite du policier. Si vous estimez avoir ete maltraite, vous pouvez deposer plainte aupres du procureur ou saisir l''IGPN.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000005b', 'Cooperer, demander le motif, deposer plainte si abus', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000005b', 'Frapper le policier', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000005b', 'Crier dans la rue', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000005b', 'Mentir sur mon identite', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f3000002-0000-0000-0000-00000000005c', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', 'CR', 'MISE_SITUATION',
 'On me propose un travail tres bien paye mais sans contrat ni declaration. Que penser ?',
 'C''est du travail dissimule, illegal en France. Vous n''aurez aucun droit social (assurance maladie, retraite, chomage), et vous risquez des sanctions. Refuser et signaler aux autorites.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000005c', 'Refuser et signaler : c''est du travail dissimule illegal', TRUE, 0),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000005c', 'Accepter, c''est plus avantageux', FALSE, 1),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000005c', 'Negocier un meilleur taux', FALSE, 2),
(gen_random_uuid(), 'f3000002-0000-0000-0000-00000000005c', 'Accepter mais en informer le pape', FALSE, 3);
