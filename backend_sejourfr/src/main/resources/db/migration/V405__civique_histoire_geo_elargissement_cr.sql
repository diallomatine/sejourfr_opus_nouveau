-- Flyway: niveau 3 thème 4 HISTOIRE_GEO - 50 CR (40 CONN + 10 MS) - is_active=FALSE

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000033', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quel événement a abouti à l''abolition des privilèges en France ?',
 'La nuit du 4 août 1789, pendant la Révolution, l''Assemblée constituante a voté l''abolition des privilèges féodaux, mettant fin à l''Ancien Régime.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000033', 'La nuit du 4 août 1789', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000033', 'La prise de la Bastille', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000033', 'Le couronnement de Napoléon', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000033', 'La Libération de Paris', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000034', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quel slogan symbolise la Révolution de 1789 ?',
 '''Liberté, Égalité, Fraternité'' est devenue la devise officielle de la République, héritage des principes de la Révolution. Elle est inscrite dans la Constitution.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000034', 'Liberté, Égalité, Fraternité', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000034', 'Travail, Famille, Patrie', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000034', 'Tous pour un, un pour tous', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000034', 'Dieu, le roi, la patrie', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000035', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Comment s''appelait l''État français pendant la Seconde Guerre mondiale, dirigé par Pétain ?',
 'Le régime de Vichy (1940-1944), dirigé par le maréchal Philippe Pétain, a collaboré avec l''Allemagne nazie. Sa devise était ''Travail, Famille, Patrie''.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000035', 'Le régime de Vichy', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000035', 'La IIIe République', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000035', 'La France libre', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000035', 'L''Empire napoléonien', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000036', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Comment s''appelait le mouvement de Charles de Gaulle pendant la Seconde Guerre mondiale ?',
 'La France libre (puis France combattante) fut le mouvement de résistance fondé par Charles de Gaulle depuis Londres après l''appel du 18 juin 1940.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000036', 'La France libre', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000036', 'Le Front populaire', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000036', 'La Commune', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000036', 'La Sainte Alliance', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000037', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'En quelle année la France a-t-elle accordé le droit de vote aux femmes ?',
 'Les femmes françaises ont obtenu le droit de vote par l''ordonnance du 21 avril 1944, signée par le général de Gaulle à Alger. Elles ont voté pour la première fois en 1945.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000037', '1944', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000037', '1789', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000037', '1881', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000037', '1958', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000038', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'En quelle année la guerre d''Algérie s''est-elle terminée ?',
 'La guerre d''Algérie (1954-1962) s''est terminée par les accords d''Évian le 18 mars 1962. L''indépendance de l''Algérie a été proclamée le 5 juillet 1962.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000038', '1962 (accords d''Évian)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000038', '1945', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000038', '1968', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000038', '1981', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000039', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Que désigne l''expression ''Mai 68'' ?',
 'Mai 68 désigne une période de grèves, de manifestations étudiantes et de mouvements sociaux en mai-juin 1968 en France. Ces événements ont marqué la société française.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000039', 'Une période de grèves et de manifestations en 1968', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000039', 'Une bataille militaire', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000039', 'Une exposition universelle', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000039', 'Une fête religieuse', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000003a', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quel président a aboli la peine de mort en France ?',
 'François Mitterrand (président de 1981 à 1995) a fait abolir la peine de mort. La loi a été portée par son garde des sceaux Robert Badinter en octobre 1981.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000003a', 'François Mitterrand (avec Robert Badinter, 1981)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000003a', 'Charles de Gaulle', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000003a', 'Georges Pompidou', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000003a', 'Jacques Chirac', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000003b', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quel roi a établi l''édit de Nantes (1598) pour la liberté de culte protestant ?',
 'Henri IV (1553-1610) a signé l''édit de Nantes en 1598, accordant des droits aux protestants après les guerres de religion. L''edit a été révoqué en 1685 par Louis XIV.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000003b', 'Henri IV', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000003b', 'Louis XIV', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000003b', 'François Ier', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000003b', 'Louis IX', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000003c', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'En quelle année la loi de séparation des Églises et de l''État a-t-elle été votée ?',
 'La loi de separation des Églises et de l''État a été adoptée le 9 décembre 1905. Elle a établi la laïcité en France et la liberté de conscience.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000003c', '1905', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000003c', '1789', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000003c', '1848', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000003c', '1944', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000003d', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quel mouvement intellectuel du XVIIIe siècle a influencé la Révolution française ?',
 'Les Lumières (Voltaire, Rousseau, Diderot, Montesquieu) ont prôné la raison, la liberté, l''égalité et la tolérance. Leurs idées ont inspiré la Révolution de 1789.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000003d', 'Les Lumières (Voltaire, Rousseau, Diderot)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000003d', 'Le surréalisme', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000003d', 'Le romantisme', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000003d', 'L''imprimerie', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000003e', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Qui a rédigé le Code civil français en 1804 ?',
 'Le Code civil (dit Code Napoléon) a été promulgué en 1804 sous Napoléon Bonaparte. Il a uniformisé le droit civil français et influencé de nombreux pays.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000003e', 'Napoléon Bonaparte (Code Napoléon, 1804)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000003e', 'Louis XIV', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000003e', 'Robespierre', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000003e', 'De Gaulle', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000003f', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quel célèbre maréchal français a remporté la bataille de la Marne en 1914 ?',
 'Joseph Joffre, maréchal de France, a commandé l''armée française lors de la victoire de la Marne (5-12 septembre 1914), qui a stoppé l''avance allemande.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000003f', 'Joseph Joffre', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000003f', 'Ferdinand Foch', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000003f', 'Philippe Pétain', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000003f', 'Napoléon Ier', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000040', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quelle ville française a été libérée le 25 août 1944 ?',
 'Paris a été libérée le 25 août 1944. La 2e division blindée du général Leclerc et la Résistance intérieure ont libéré la capitale, suivi du célèbre discours de De Gaulle à l''Hôtel de Ville.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000040', 'Paris', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000040', 'Marseille', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000040', 'Lyon', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000040', 'Bordeaux', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000041', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quelle figure a marqué la Résistance française et est mort en déportation ?',
 'Jean Moulin (1899-1943), préfet et résistant, a unifié les mouvements de Résistance française. Arrêté par la Gestapo, il est mort des suites des tortures. Inhumé au Panthéon en 1964.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000041', 'Jean Moulin', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000041', 'Napoléon Ier', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000041', 'Maurice Thorez', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000041', 'Jacques Chirac', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000042', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quel nom porte la zone occupée par l''Allemagne nazie pendant la Seconde Guerre ?',
 'Pendant la Seconde Guerre mondiale, la France était divisée en zone occupée (nord et façade atlantique) et zone libre (sud, jusqu''en novembre 1942 où elle fut aussi occupée).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000042', 'La zone occupée (et la zone libre)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000042', 'L''Alsace-Lorraine uniquement', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000042', 'Toute la France', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000042', 'Les colonies', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000043', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Qui a rédigé la Déclaration des droits de la femme en 1791 ?',
 'Olympe de Gouges (1748-1793) a rédigé la Déclaration des droits de la femme et de la citoyenne en 1791, en réponse à la DDHC qui excluait les femmes. Elle a été guillotinée en 1793.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000043', 'Olympe de Gouges', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000043', 'Simone Veil', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000043', 'Marie Curie', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000043', 'Marie-Antoinette', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000044', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quel général est associé à la guerre de Cent Ans ?',
 'La guerre de Cent Ans (1337-1453) a opposé la France à l''Angleterre. Jeanne d''Arc a joué un rôle décisif en aidant Charles VII à être sacré roi à Reims en 1429.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000044', 'Jeanne d''Arc (aux côtés de Charles VII)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000044', 'Napoléon Bonaparte', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000044', 'De Gaulle', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000044', 'Louis XIV', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000045', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quel architecte a conçu la pyramide du Louvre ?',
 'Ieoh Ming Pei (1917-2019), architecte sino-américain, a conçu la pyramide du Louvre, inaugurée en 1989 pour le bicentenaire de la Révolution.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000045', 'Ieoh Ming Pei (1989)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000045', 'Gustave Eiffel', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000045', 'Le Corbusier', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000045', 'Auguste Perret', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000046', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Qui était Louise Michel ?',
 'Louise Michel (1830-1905), institutrice et militante anarchiste, a été une figure majeure de la Commune de Paris (1871). Surnommée ''la Vierge rouge'', déportée en Nouvelle-Calédonie.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000046', 'Une militante de la Commune de Paris', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000046', 'Une reine médiévale', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000046', 'Une chanteuse', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000046', 'Une scientifique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000047', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Qu''est-ce que la Commune de Paris (1871) ?',
 'La Commune de Paris (18 mars - 28 mai 1871) fut un mouvement insurrectionnel ayant pris le pouvoir à Paris après la défaite de 1870. Réprimée dans le sang lors de la ''semaine sanglante''.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000047', 'Un mouvement insurrectionnel à Paris en 1871', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000047', 'Une fête communale', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000047', 'Une bataille napoléonienne', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000047', 'Une grève récente', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000048', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quel château de la Loire est appelé ''le plus visité'' ?',
 'Le château de Chambord, construit sous François Ier au XVIe siècle, est l''un des plus célèbres châteaux de la Loire avec son architecture Renaissance.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000048', 'Chambord', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000048', 'Versailles', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000048', 'Fontainebleau', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000048', 'Vincennes', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000049', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quel monument romain antique se trouve à Nîmes ?',
 'L''amphithéâtre des arènes de Nîmes, datant du Ier siècle après J.-C., est l''un des amphithéâtres romains les mieux conservés au monde. La Maison Carrée y est aussi un temple romain.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000049', 'Les arènes (amphithéâtre romain)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000049', 'La tour Eiffel', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000049', 'Le Mont-Saint-Michel', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000049', 'Le Panthéon', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000004a', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quel chef-d''œuvre de l''architecture est sur un îlot rocheux en Normandie ?',
 'Le Mont-Saint-Michel, îlot rocheux à la frontière de la Normandie et de la Bretagne, abrite une abbaye bénédictine. Classé au patrimoine mondial de l''UNESCO.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000004a', 'Le Mont-Saint-Michel', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000004a', 'La tour Eiffel', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000004a', 'Le Louvre', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000004a', 'L''Arc de Triomphe', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000004b', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quel cap rocheux abrupt se trouve en Normandie ?',
 'Les falaises d''Étretat, sur la côte normande, sont célèbres pour leurs arches naturelles spectaculaires. Elles ont inspiré de nombreux peintres (Monet, Courbet).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000004b', 'Les falaises d''Étretat', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000004b', 'Le rocher de Monaco', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000004b', 'Le cap Horn', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000004b', 'Le Mont Blanc', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000004c', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quelle région française est célébrée pour la production de champagne ?',
 'Le champagne est produit dans la région viticole de Champagne, située dans le Grand Est. Le terme ''champagne'' est une appellation d''origine contrôlée protégée.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000004c', 'La Champagne (région viticole protégée)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000004c', 'La Bretagne', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000004c', 'La Provence', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000004c', 'La Corse', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000004d', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quel grand musicien français a composé Carmen ?',
 'Georges Bizet (1838-1875) a composé Carmen, un des opéras les plus joués au monde, créé en 1875 à Paris.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000004d', 'Georges Bizet', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000004d', 'Mozart', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000004d', 'Beethoven', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000004d', 'Wagner', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000004e', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quel peintre impressionniste a peint des nymphéas dans son jardin de Giverny ?',
 'Claude Monet (1840-1926), figure majeure de l''impressionnisme, a peint pendant des années les nymphéas de son étang à Giverny. Ces tableaux sont aussi exposés au musée de l''Orangerie à Paris.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000004e', 'Claude Monet (Giverny)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000004e', 'Pablo Picasso', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000004e', 'Salvador Dali', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000004e', 'Andy Warhol', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000004f', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quel écrivain français a remporté le prix Nobel de littérature en 1957 ?',
 'Albert Camus (1913-1960) a reçu le prix Nobel de littérature en 1957. Né en Algérie française, il est l''auteur de L''Étranger, La Peste, Le Mythe de Sisyphe.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000004f', 'Albert Camus', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000004f', 'Victor Hugo', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000004f', 'Marcel Proust', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000004f', 'André Malraux', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000050', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quel écrivain français a écrit Les Misérables ?',
 'Victor Hugo (1802-1885) a écrit Les Misérables (1862), un des plus grands romans du XIXe siècle. Il a aussi écrit Notre-Dame de Paris.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000050', 'Victor Hugo', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000050', 'Honoré de Balzac', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000050', 'Marcel Proust', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000050', 'Albert Camus', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000051', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Qui a rédigé le ''J''accuse...!'' lors de l''affaire Dreyfus ?',
 'Émile Zola (1840-1902) a publié ''J''accuse...!'' dans L''Aurore le 13 janvier 1898, dénonçant les erreurs judiciaires de l''affaire Dreyfus. Cela lui a valu un procès.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000051', 'Émile Zola', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000051', 'Victor Hugo', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000051', 'Marcel Proust', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000051', 'Anatole France', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000052', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Qui est l''auteur du Petit Prince ?',
 'Antoine de Saint-Exupéry (1900-1944) a écrit Le Petit Prince, publié en 1943. C''est l''un des livres les plus traduits au monde. L''auteur était aussi pilote.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000052', 'Antoine de Saint-Exupéry', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000052', 'Albert Camus', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000052', 'Jean-Paul Sartre', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000052', 'Marcel Proust', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-0000000000c1', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quel célèbre cuisinier français a popularisé la gastronomie au XXe siècle ?',
 'Paul Bocuse (1926-2018), surnommé ''le pape de la gastronomie'', était l''un des chefs les plus influents du XXe siècle. Il a reçu de nombreuses étoiles Michelin et a formé des générations de cuisiniers.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c1', 'Paul Bocuse', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c1', 'Gustave Eiffel', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c1', 'Marie Curie', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c1', 'Charles de Gaulle', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-0000000000c2', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quelle invention française du XXe siècle a révolutionné la photographie ?',
 'Les frères Lumière ont inventé le cinématographe (cinéma) en 1895 à Lyon. La première projection publique payante a eu lieu le 28 décembre 1895 à Paris.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c2', 'Le cinématographe (frères Lumière, 1895)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c2', 'L''ordinateur', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c2', 'La voiture', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c2', 'La télévision', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-0000000000c3', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Qui était Louis Braille ?',
 'Louis Braille (1809-1852), français devenu aveugle après un accident, a inventé vers 1825 le système d''écriture en relief portant son nom, utilisé par les aveugles dans le monde entier.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c3', 'L''inventeur de l''écriture en relief pour les aveugles', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c3', 'Un peintre', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c3', 'Un compositeur', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c3', 'Un explorateur', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-0000000000c4', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quel écrivain a écrit ''À la recherche du temps perdu'' ?',
 'Marcel Proust (1871-1922) a écrit ''À la recherche du temps perdu'', vaste roman en 7 volumes publié entre 1913 et 1927, considéré comme une œuvre majeure de la littérature mondiale.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c4', 'Marcel Proust', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c4', 'Victor Hugo', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c4', 'Émile Zola', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c4', 'Albert Camus', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-0000000000c5', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quelle révolution a eu lieu en France en 1830 ?',
 'Les Trois Glorieuses (27, 28, 29 juillet 1830) ont renversé Charles X et mis fin à la Restauration. Louis-Philippe d''Orléans est devenu roi des Français (monarchie de Juillet).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c5', 'Les Trois Glorieuses (1830)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c5', 'La Révolution de 1789', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c5', 'La Commune de Paris', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c5', 'La Libération', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-0000000000c6', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quel désastre a marqué la guerre de 1870-1871 ?',
 'La défaite de Sedan (1 septembre 1870) a entraîné la capitulation de Napoléon III et la chute du Second Empire. La IIIe République a été proclamée le 4 septembre 1870.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c6', 'La défaite de Sedan et la chute de Napoléon III', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c6', 'La bataille de Waterloo', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c6', 'La prise de la Bastille', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c6', 'La débâcle de 1940', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-0000000000c7', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quelle région française comporte un volcan célèbre, le Puy de Dôme ?',
 'L''Auvergne-Rhône-Alpes, autour de Clermont-Ferrand, abrite la chaîne des Puys (volcans éteints), avec le Puy de Dôme comme sommet emblématique.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c7', 'L''Auvergne-Rhône-Alpes (chaîne des Puys)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c7', 'La Bretagne', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c7', 'La Picardie', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c7', 'La Corse', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-0000000000c8', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
 'Quel célèbre couturier français a révolutionné la mode au XXe siècle ?',
 'Gabrielle ''Coco'' Chanel (1883-1971) a révolutionné la mode féminine avec la petite robe noire, le tailleur Chanel et le parfum N°5. D''autres couturiers français célèbres : Christian Dior, Yves Saint Laurent.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c8', 'Coco Chanel', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c8', 'Marie Curie', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c8', 'Édith Piaf', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000c8', 'Simone Veil', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000053', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'MISE_SITUATION',
 'Je veux comprendre pourquoi le 8 mai est férié. Quelle réponse donner ?',
 'Le 8 mai commémore la capitulation de l''Allemagne nazie en 1945, qui a mis fin à la Seconde Guerre mondiale en Europe. C''est un hommage aux victimes et aux combattants.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000053', 'Capitulation allemande de 1945 (fin de la Seconde Guerre en Europe)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000053', 'Naissance de Napoléon', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000053', 'Indépendance d''un pays', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000053', 'Fête de l''Europe', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000054', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'MISE_SITUATION',
 'J''aimerais visiter un musée gratuitement. Quels sont les jours possibles ?',
 'La plupart des musées nationaux français sont gratuits le 1er dimanche de chaque mois. Les moins de 26 ans résidents de l''UE entrent gratuitement dans les musées nationaux.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000054', 'Le 1er dimanche du mois pour les musées nationaux', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000054', 'Aucun jour gratuit', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000054', 'Uniquement le 1er janvier', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000054', 'Uniquement le 14 juillet', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000055', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'MISE_SITUATION',
 'Je veux comprendre la différence entre la IVe et la Ve République. Quels repères ?',
 'La IVe (1946-1958) était un régime parlementaire instable (24 gouvernements en 12 ans). La Ve (depuis 1958) a renforcé l''exécutif (président au suffrage direct depuis 1962, mandat de 5 ans).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000055', 'IVe République = parlementaire instable ; Ve = exécutif renforcé', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000055', 'Aucune différence', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000055', 'La IVe était monarchique', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000055', 'La Ve était impériale', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000056', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'MISE_SITUATION',
 'Je veux célébrer la fête nationale à Paris. Que se passe-t-il le 14 juillet ?',
 'Le matin : défilé militaire sur les Champs-Élysées. Le soir : feux d''artifice (notamment au Champ-de-Mars sous la tour Eiffel) et bals populaires (notamment dans les casernes de pompiers).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000056', 'Défilé militaire le matin, feux d''artifice et bals le soir', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000056', 'Une seule messe', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000056', 'Rien de spécial', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000056', 'Un concert de Noël', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000057', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'MISE_SITUATION',
 'Je veux mieux connaître les régions de France après avoir emménagé. Comment procéder ?',
 'Vous pouvez visiter les offices de tourisme, consulter les sites des régions, regarder des émissions ou documentaires (Échappées belles, Des racines et des ailes), lire des guides régionaux.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000057', 'Offices de tourisme, documentaires, guides régionaux', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000057', 'Rien faire', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000057', 'Quitter la France', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000057', 'Demander au pape', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000058', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'MISE_SITUATION',
 'Je veux faire découvrir la culture française à mon enfant. Quelles activités concrètes ?',
 'Lire des contes (Charles Perrault), regarder des films français, visiter des musées, écouter des chansons (Piaf, Brel, Brassens), goûter des plats traditionnels, célébrer les fêtes françaises.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000058', 'Lecture, films, musées, chansons, plats, fêtes', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000058', 'Aucune activité culturelle', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000058', 'Uniquement parler anglais', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000058', 'Éviter tout contact avec la culture', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000059', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'MISE_SITUATION',
 'Je veux savoir quels événements historiques sont commémorés dans ma commune. Où me renseigner ?',
 'La mairie organise les cérémonies du 11 novembre, 8 mai, journée des déportés. Les sites internet municipaux et les bulletins communaux donnent le programme.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000059', 'À la mairie ou sur son site internet', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000059', 'Au commissariat', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000059', 'À l''église uniquement', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000059', 'Nulle part', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000005a', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'MISE_SITUATION',
 'Je veux comprendre pourquoi la laïcité est mentionnée constamment en France. Quel ancrage historique ?',
 'La laïcité résulte de la loi de 1905 séparant les Églises et l''État. Elle garantit la liberté de conscience et de culte, et la neutralité de l''État envers les religions.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000005a', 'La loi de 1905 séparant Églises et État', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000005a', 'Une coutume récente', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000005a', 'Un décret européen', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000005a', 'Aucun fondement historique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000005b', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'MISE_SITUATION',
 'Je découvre la culture du vin en France. Quelles régions visiter ?',
 'Les grandes régions viticoles : Bordelais, Bourgogne, Champagne, vallée du Rhône, Alsace, vallée de la Loire, Provence, Beaujolais. Chaque région a ses appellations et ses cépages.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000005b', 'Bordelais, Bourgogne, Champagne, Rhône, Alsace, Loire, Provence', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000005b', 'Une seule région', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000005b', 'Aucune région viticole', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000005b', 'Uniquement à l''étranger', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000005c', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'CR', 'MISE_SITUATION',
 'Je veux comprendre pourquoi Marianne et le coq sont associés à la France. Que répondre ?',
 'Marianne incarne la République et les valeurs républicaines depuis 1792. Le coq, lui, est un emblème historique du peuple français (du latin ''gallus'' = gaulois/coq).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000005c', 'Marianne = République ; coq = ancrage historique gaulois', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000005c', 'Sans signification', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000005c', 'Imposés par l''Europe', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000005c', 'Inventés récemment', FALSE, 3);
