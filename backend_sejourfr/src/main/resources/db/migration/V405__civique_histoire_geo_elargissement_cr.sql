-- Flyway: niveau 3 theme 4 HISTOIRE_GEO - 50 CR (40 CONN + 10 MS) - is_active=FALSE

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000033', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quel evenement a abouti a l''abolition des privileges en France ?',
 'La nuit du 4 aout 1789, pendant la Revolution, l''Assemblee constituante a vote l''abolition des privileges feodaux, mettant fin a l''Ancien Regime.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000033', 'La nuit du 4 aout 1789', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000033', 'La prise de la Bastille', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000033', 'Le couronnement de Napoleon', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000033', 'La Liberation de Paris', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000034', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quel slogan symbolise la Revolution de 1789 ?',
 '''Liberte, Egalite, Fraternite'' est devenue la devise officielle de la Republique, heritage des principes de la Revolution. Elle est inscrite dans la Constitution.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000034', 'Liberte, Egalite, Fraternite', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000034', 'Travail, Famille, Patrie', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000034', 'Tous pour un, un pour tous', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000034', 'Dieu, le roi, la patrie', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000035', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Comment s''appelait l''Etat francais pendant la Seconde Guerre mondiale, dirige par Petain ?',
 'Le regime de Vichy (1940-1944), dirige par le marechal Philippe Petain, a collabore avec l''Allemagne nazie. Sa devise etait ''Travail, Famille, Patrie''.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000035', 'Le regime de Vichy', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000035', 'La IIIe Republique', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000035', 'La France libre', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000035', 'L''Empire napoleonien', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000036', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Comment s''appelait le mouvement de Charles de Gaulle pendant la Seconde Guerre mondiale ?',
 'La France libre (puis France combattante) fut le mouvement de resistance fonde par Charles de Gaulle depuis Londres apres l''appel du 18 juin 1940.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000036', 'La France libre', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000036', 'Le Front populaire', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000036', 'La Commune', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000036', 'La Sainte Alliance', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000037', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'En quelle annee la France a-t-elle accorde le droit de vote aux femmes ?',
 'Les femmes francaises ont obtenu le droit de vote par l''ordonnance du 21 avril 1944, signee par le general de Gaulle a Alger. Elles ont vote pour la premiere fois en 1945.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000037', '1944', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000037', '1789', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000037', '1881', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000037', '1958', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000038', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'En quelle annee la guerre d''Algerie s''est-elle terminee ?',
 'La guerre d''Algerie (1954-1962) s''est terminee par les accords d''Evian le 18 mars 1962. L''independance de l''Algerie a ete proclamee le 5 juillet 1962.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000038', '1962 (accords d''Evian)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000038', '1945', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000038', '1968', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000038', '1981', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000039', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Que designe l''expression ''Mai 68'' ?',
 'Mai 68 designe une periode de greves, de manifestations etudiantes et de mouvements sociaux en mai-juin 1968 en France. Ces evenements ont marque la societe francaise.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000039', 'Une periode de greves et de manifestations en 1968', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000039', 'Une bataille militaire', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000039', 'Une exposition universelle', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000039', 'Une fete religieuse', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000003a', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quel president a aboli la peine de mort en France ?',
 'Francois Mitterrand (president de 1981 a 1995) a fait abolir la peine de mort. La loi a ete portee par son garde des sceaux Robert Badinter en octobre 1981.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000003a', 'Francois Mitterrand (avec Robert Badinter, 1981)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000003a', 'Charles de Gaulle', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000003a', 'Georges Pompidou', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000003a', 'Jacques Chirac', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000003b', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quel roi a etabli l''edit de Nantes (1598) pour la liberte de culte protestant ?',
 'Henri IV (1553-1610) a signe l''edit de Nantes en 1598, accordant des droits aux protestants apres les guerres de religion. L''edit a ete revoque en 1685 par Louis XIV.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000003b', 'Henri IV', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000003b', 'Louis XIV', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000003b', 'Francois Ier', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000003b', 'Louis IX', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000003c', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'En quelle annee la loi de separation des Eglises et de l''Etat a-t-elle ete votee ?',
 'La loi de separation des Eglises et de l''Etat a ete adoptee le 9 decembre 1905. Elle a etabli la laicite en France et la liberte de conscience.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000003c', '1905', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000003c', '1789', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000003c', '1848', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000003c', '1944', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000003d', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quel mouvement intellectuel du XVIIIe siecle a influence la Revolution francaise ?',
 'Les Lumieres (Voltaire, Rousseau, Diderot, Montesquieu) ont prone la raison, la liberte, l''egalite et la tolerance. Leurs idees ont inspire la Revolution de 1789.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000003d', 'Les Lumieres (Voltaire, Rousseau, Diderot)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000003d', 'Le surrealisme', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000003d', 'Le romantisme', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000003d', 'L''imprimerie', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000003e', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Qui a redige le Code civil francais en 1804 ?',
 'Le Code civil (dit Code Napoleon) a ete promulgue en 1804 sous Napoleon Bonaparte. Il a uniformise le droit civil francais et influence de nombreux pays.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000003e', 'Napoleon Bonaparte (Code Napoleon, 1804)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000003e', 'Louis XIV', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000003e', 'Robespierre', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000003e', 'De Gaulle', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000003f', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quel celebre marechal francais a remporte la bataille de la Marne en 1914 ?',
 'Joseph Joffre, marechal de France, a commande l''armee francaise lors de la victoire de la Marne (5-12 septembre 1914), qui a stoppe l''avance allemande.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000003f', 'Joseph Joffre', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000003f', 'Ferdinand Foch', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000003f', 'Philippe Petain', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000003f', 'Napoleon Ier', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000040', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quelle ville francaise a ete liberee le 25 aout 1944 ?',
 'Paris a ete liberee le 25 aout 1944. La 2e division blindee du general Leclerc et la Resistance interieure ont libere la capitale, suivi du celebre discours de De Gaulle a l''Hotel de Ville.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000040', 'Paris', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000040', 'Marseille', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000040', 'Lyon', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000040', 'Bordeaux', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000041', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quelle figure a marque la Resistance francaise et est mort en deportation ?',
 'Jean Moulin (1899-1943), prefet et resistant, a unifie les mouvements de Resistance francaise. Arrete par la Gestapo, il est mort des suites des tortures. Inhume au Pantheon en 1964.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000041', 'Jean Moulin', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000041', 'Napoleon Ier', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000041', 'Maurice Thorez', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000041', 'Jacques Chirac', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000042', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quel nom porte la zone occupee par l''Allemagne nazie pendant la Seconde Guerre ?',
 'Pendant la Seconde Guerre mondiale, la France etait divisee en zone occupee (nord et facade atlantique) et zone libre (sud, jusqu''en novembre 1942 ou elle fut aussi occupee).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000042', 'La zone occupee (et la zone libre)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000042', 'L''Alsace-Lorraine uniquement', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000042', 'Toute la France', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000042', 'Les colonies', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000043', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Qui a redige la Declaration des droits de la femme en 1791 ?',
 'Olympe de Gouges (1748-1793) a redige la Declaration des droits de la femme et de la citoyenne en 1791, en reponse a la DDHC qui excluait les femmes. Elle a ete guillotinee en 1793.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000043', 'Olympe de Gouges', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000043', 'Simone Veil', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000043', 'Marie Curie', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000043', 'Marie-Antoinette', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000044', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quel general est associe a la guerre de Cent Ans ?',
 'La guerre de Cent Ans (1337-1453) a oppose la France a l''Angleterre. Jeanne d''Arc a joue un role decisif en aidant Charles VII a etre sacre roi a Reims en 1429.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000044', 'Jeanne d''Arc (au cote de Charles VII)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000044', 'Napoleon Bonaparte', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000044', 'De Gaulle', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000044', 'Louis XIV', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000045', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quel architecte a concu la pyramide du Louvre ?',
 'Ieoh Ming Pei (1917-2019), architecte sino-americain, a concu la pyramide du Louvre, inauguree en 1989 pour le bicentenaire de la Revolution.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000045', 'Ieoh Ming Pei (1989)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000045', 'Gustave Eiffel', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000045', 'Le Corbusier', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000045', 'Auguste Perret', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000046', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Qui etait Louise Michel ?',
 'Louise Michel (1830-1905), institutrice et militante anarchiste, a ete une figure majeure de la Commune de Paris (1871). Surnommee ''la Vierge rouge'', deportee en Nouvelle-Caledonie.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000046', 'Une militante de la Commune de Paris', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000046', 'Une reine medievale', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000046', 'Une chanteuse', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000046', 'Une scientifique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000047', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Qu''est-ce que la Commune de Paris (1871) ?',
 'La Commune de Paris (18 mars - 28 mai 1871) fut un mouvement insurrectionnel ayant pris le pouvoir a Paris apres la defaite de 1870. Reprimee dans le sang lors de la ''semaine sanglante''.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000047', 'Un mouvement insurrectionnel a Paris en 1871', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000047', 'Une fete communale', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000047', 'Une bataille napoleonienne', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000047', 'Une greve recente', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000048', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quel chateau de la Loire est appele ''le plus visite'' ?',
 'Le chateau de Chambord, construit sous Francois Ier au XVIe siecle, est l''un des plus celebres chateaux de la Loire avec son architecture Renaissance.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000048', 'Chambord', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000048', 'Versailles', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000048', 'Fontainebleau', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000048', 'Vincennes', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000049', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quel monument romain antique se trouve a Nimes ?',
 'L''amphitheatre des arenes de Nimes, datant du Ier siecle apres J.-C., est l''un des amphitheatres romains les mieux conserves au monde. La Maison Carree y est aussi un temple romain.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000049', 'Les arenes (amphitheatre romain)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000049', 'La tour Eiffel', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000049', 'Le Mont-Saint-Michel', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000049', 'Le Pantheon', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000004a', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quel chef-d''oeuvre de l''architecture est sur un ilot rocheux en Normandie ?',
 'Le Mont-Saint-Michel, ilot rocheux a la frontiere de la Normandie et de la Bretagne, abrite une abbaye benedictine. Classe au patrimoine mondial de l''UNESCO.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000004a', 'Le Mont-Saint-Michel', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000004a', 'La tour Eiffel', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000004a', 'Le Louvre', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000004a', 'L''Arc de Triomphe', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000004b', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quel cap rocheux abrupt se trouve en Normandie ?',
 'Les falaises d''Etretat, sur la cote normande, sont celebres pour leurs arches naturelles spectaculaires. Elles ont inspire de nombreux peintres (Monet, Courbet).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000004b', 'Les falaises d''Etretat', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000004b', 'Le rocher de Monaco', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000004b', 'Le cap Horn', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000004b', 'Le Mont Blanc', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000004c', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quelle region francaise est celebre pour la production de champagne ?',
 'Le champagne est produit dans la region viticole de Champagne, situee dans le Grand Est. Le terme ''champagne'' est une appellation d''origine controlee protegee.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000004c', 'La Champagne (region viticole protegee)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000004c', 'La Bretagne', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000004c', 'La Provence', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000004c', 'La Corse', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000004d', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quel grand musicien francais a compose Carmen ?',
 'Georges Bizet (1838-1875) a compose Carmen, un des operas les plus joues au monde, cree en 1875 a Paris.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000004d', 'Georges Bizet', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000004d', 'Mozart', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000004d', 'Beethoven', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000004d', 'Wagner', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000004e', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quel peintre impressionniste a peint des nympheas dans son jardin de Giverny ?',
 'Claude Monet (1840-1926), figure majeure de l''impressionnisme, a peint pendant des annees les nympheas de son etang a Giverny. Ces tableaux sont aussi exposes au musee de l''Orangerie a Paris.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000004e', 'Claude Monet (Giverny)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000004e', 'Pablo Picasso', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000004e', 'Salvador Dali', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000004e', 'Andy Warhol', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000004f', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quel ecrivain francais a remporte le prix Nobel de litterature en 1957 ?',
 'Albert Camus (1913-1960) a recu le prix Nobel de litterature en 1957. Ne en Algerie francaise, il est l''auteur de L''Etranger, La Peste, Le Mythe de Sisyphe.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000004f', 'Albert Camus', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000004f', 'Victor Hugo', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000004f', 'Marcel Proust', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000004f', 'Andre Malraux', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000050', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quel ecrivain francais a ecrit Les Miserables ?',
 'Victor Hugo (1802-1885) a ecrit Les Miserables (1862), un des plus grands romans du XIXe siecle. Il a aussi ecrit Notre-Dame de Paris.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000050', 'Victor Hugo', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000050', 'Honore de Balzac', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000050', 'Marcel Proust', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000050', 'Albert Camus', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000051', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Qui a redige le ''J''accuse...!'' lors de l''affaire Dreyfus ?',
 'Emile Zola (1840-1902) a publie ''J''accuse...!'' dans L''Aurore le 13 janvier 1898, denoncant les erreurs judiciaires de l''affaire Dreyfus. Cela lui a valu un proces.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000051', 'Emile Zola', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000051', 'Victor Hugo', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000051', 'Marcel Proust', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000051', 'Anatole France', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000052', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Qui est l''auteur du Petit Prince ?',
 'Antoine de Saint-Exupery (1900-1944) a ecrit Le Petit Prince, publie en 1943. C''est l''un des livres les plus traduits au monde. L''auteur etait aussi pilote.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000052', 'Antoine de Saint-Exupery', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000052', 'Albert Camus', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000052', 'Jean-Paul Sartre', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000052', 'Marcel Proust', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-0000000000c1', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quel celebre cuisinier francais a popularise la gastronomie au XXe siecle ?',
 'Paul Bocuse (1926-2018), surnomme ''le pape de la gastronomie'', etait l''un des chefs les plus influents du XXe siecle. Il a recu de nombreuses etoiles Michelin et a forme des generations de cuisiniers.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c1', 'Paul Bocuse', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c1', 'Gustave Eiffel', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c1', 'Marie Curie', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c1', 'Charles de Gaulle', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-0000000000c2', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quelle invention francaise du XXe siecle a revolutionne la photographie ?',
 'Les freres Lumiere ont invente le cinematographe (cinema) en 1895 a Lyon. La premiere projection publique payante a eu lieu le 28 decembre 1895 a Paris.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c2', 'Le cinematographe (freres Lumiere, 1895)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c2', 'L''ordinateur', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c2', 'La voiture', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c2', 'La television', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-0000000000c3', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Qui etait Louis Braille ?',
 'Louis Braille (1809-1852), francais devenu aveugle apres un accident, a invente vers 1825 le systeme d''ecriture en relief portant son nom, utilise par les aveugles dans le monde entier.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c3', 'L''inventeur de l''ecriture en relief pour les aveugles', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c3', 'Un peintre', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c3', 'Un compositeur', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c3', 'Un explorateur', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-0000000000c4', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quel ecrivain a ecrit ''A la recherche du temps perdu'' ?',
 'Marcel Proust (1871-1922) a ecrit ''A la recherche du temps perdu'', vaste roman en 7 volumes publie entre 1913 et 1927, considere comme une oeuvre majeure de la litterature mondiale.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c4', 'Marcel Proust', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c4', 'Victor Hugo', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c4', 'Emile Zola', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c4', 'Albert Camus', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-0000000000c5', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quelle revolution a eu lieu en France en 1830 ?',
 'Les Trois Glorieuses (27, 28, 29 juillet 1830) ont renverse Charles X et mis fin a la Restauration. Louis-Philippe d''Orleans est devenu roi des Francais (monarchie de Juillet).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c5', 'Les Trois Glorieuses (1830)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c5', 'La Revolution de 1789', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c5', 'La Commune de Paris', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c5', 'La Liberation', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-0000000000c6', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quel desastre a marque la guerre de 1870-1871 ?',
 'La defaite de Sedan (1 septembre 1870) a entraine la capitulation de Napoleon III et la chute du Second Empire. La IIIe Republique a ete proclamee le 4 septembre 1870.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c6', 'La defaite de Sedan et la chute de Napoleon III', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c6', 'La bataille de Waterloo', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c6', 'La prise de la Bastille', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c6', 'La debacle de 1940', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-0000000000c7', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quelle region francaise comporte un volcan celebre, le Puy de Dome ?',
 'L''Auvergne-Rhone-Alpes, autour de Clermont-Ferrand, abrite la chaine des Puys (volcans eteints), avec le Puy de Dome comme sommet emblematique.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c7', 'L''Auvergne-Rhone-Alpes (chaine des Puys)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c7', 'La Bretagne', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c7', 'La Picardie', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c7', 'La Corse', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-0000000000c8', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quel celebre couturier francais a revolutionne la mode au XXe siecle ?',
 'Gabrielle ''Coco'' Chanel (1883-1971) a revolutionne la mode feminine avec la petite robe noire, le tailleur Chanel et le parfum N°5. D''autres couturiers francais celebres : Christian Dior, Yves Saint Laurent.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c8', 'Coco Chanel', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c8', 'Marie Curie', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c8', 'Edith Piaf', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c8', 'Simone Veil', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000053', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'MISE_SITUATION',
 'Je veux comprendre pourquoi le 8 mai est ferie. Quelle reponse donner ?',
 'Le 8 mai commemore la capitulation de l''Allemagne nazie en 1945, qui a mis fin a la Seconde Guerre mondiale en Europe. C''est un hommage aux victimes et aux combattants.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000053', 'Capitulation allemande de 1945 (fin de la Seconde Guerre en Europe)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000053', 'Naissance de Napoleon', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000053', 'Independance d''un pays', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000053', 'Fete de l''Europe', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000054', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'MISE_SITUATION',
 'J''aimerais visiter un musee gratuitement. Quels sont les jours possibles ?',
 'La plupart des musees nationaux francais sont gratuits le 1er dimanche de chaque mois. Les moins de 26 ans residents de l''UE entrent gratuitement dans les musees nationaux.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000054', 'Le 1er dimanche du mois pour les musees nationaux', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000054', 'Aucun jour gratuit', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000054', 'Uniquement le 1er janvier', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000054', 'Uniquement le 14 juillet', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000055', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'MISE_SITUATION',
 'Je veux comprendre la difference entre la IVe et la Ve Republique. Quels reperes ?',
 'La IVe (1946-1958) etait un regime parlementaire instable (24 gouvernements en 12 ans). La Ve (depuis 1958) a renforce l''executif (president au suffrage direct depuis 1962, mandat de 5 ans).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000055', 'IVe Republique = parlementaire instable ; Ve = executif renforce', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000055', 'Aucune difference', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000055', 'La IVe etait monarchique', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000055', 'La Ve etait imperiale', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000056', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'MISE_SITUATION',
 'Je veux celebrer la fete nationale a Paris. Que se passe-t-il le 14 juillet ?',
 'Le matin : defile militaire sur les Champs-Elysees. Le soir : feux d''artifice (notamment au Champ-de-Mars sous la tour Eiffel) et bals populaires (notamment dans les casernes de pompiers).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000056', 'Defile militaire le matin, feux d''artifice et bals le soir', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000056', 'Une seule messe', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000056', 'Rien de special', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000056', 'Un concert de Noel', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000057', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'MISE_SITUATION',
 'Je veux mieux connaitre les regions de France apres avoir emmenage. Comment proceder ?',
 'Vous pouvez visiter les offices de tourisme, consulter les sites des regions, regarder des emissions ou documentaires (Echappees belles, Des racines et des ailes), lire des guides regionaux.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000057', 'Offices de tourisme, documentaires, guides regionaux', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000057', 'Rien faire', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000057', 'Quitter la France', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000057', 'Demander au pape', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000058', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'MISE_SITUATION',
 'Je veux faire decouvrir la culture francaise a mon enfant. Quelles activites concretes ?',
 'Lire des contes (Charles Perrault), regarder des films francais, visiter des musees, ecouter des chansons (Piaf, Brel, Brassens), gouter des plats traditionnels, celebrer les fetes francaises.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000058', 'Lecture, films, musees, chansons, plats, fetes', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000058', 'Aucune activite culturelle', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000058', 'Uniquement parler anglais', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000058', 'Eviter tout contact avec la culture', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000059', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'MISE_SITUATION',
 'Je veux savoir quels evenements historiques sont commemores dans ma commune. Ou me renseigner ?',
 'La mairie organise les ceremonies du 11 novembre, 8 mai, journee des deportes. Les sites internet municipaux et les bulletins communaux donnent le programme.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000059', 'A la mairie ou sur son site internet', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000059', 'Au commissariat', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000059', 'A l''eglise uniquement', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000059', 'Nulle part', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000005a', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'MISE_SITUATION',
 'Je veux comprendre pourquoi la laicite est mentionnee constamment en France. Quel ancrage historique ?',
 'La laicite resulte de la loi de 1905 separant les Eglises et l''Etat. Elle garantit la liberte de conscience et de culte, et la neutralite de l''Etat envers les religions.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000005a', 'La loi de 1905 separant Eglises et Etat', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000005a', 'Une coutume recente', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000005a', 'Un decret europeen', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000005a', 'Aucun fondement historique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000005b', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'MISE_SITUATION',
 'Je decouvre la culture du vin en France. Quelles regions visiter ?',
 'Les grandes regions viticoles : Bordelais, Bourgogne, Champagne, vallee du Rhone, Alsace, vallee de la Loire, Provence, Beaujolais. Chaque region a ses appellations et ses cepages.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000005b', 'Bordelais, Bourgogne, Champagne, Rhone, Alsace, Loire, Provence', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000005b', 'Une seule region', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000005b', 'Aucune region viticole', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000005b', 'Uniquement a l''etranger', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000005c', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'MISE_SITUATION',
 'Je veux comprendre pourquoi Marianne et le coq sont associes a la France. Que repondre ?',
 'Marianne incarne la Republique et les valeurs republicaines depuis 1792. Le coq, lui, est un embleme historique du peuple francais (du latin ''gallus'' = gaulois/coq).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000005c', 'Marianne = Republique ; coq = ancrage historique gaulois', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000005c', 'Sans signification', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000005c', 'Imposes par l''Europe', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000005c', 'Inventes recemment', FALSE, 3);
