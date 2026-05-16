-- Flyway: niveau 3 thème 4 HISTOIRE_GEO - 50 NAT (40 CONN + 10 MS) - is_active=FALSE

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000005d', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quel traité a mis fin à la guerre de Trente Ans (1648) ?',
 'Les traités de Westphalie (1648) ont mis fin à la guerre de Trente Ans. Ils ont posé les bases du droit international moderne et confirmé la puissance de la France de Louis XIV.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000005d', 'Les traités de Westphalie (1648)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000005d', 'Le traité de Versailles', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000005d', 'Le traité de Maastricht', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000005d', 'Le traité de Rome', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000005e', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quelle dynastie régnait sur la France à la veille de la Révolution ?',
 'La dynastie des Bourbons régnait sur la France depuis 1589 (Henri IV). Louis XVI était le dernier Bourbon à régner avant la Révolution et l''abolition de la monarchie en 1792.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000005e', 'Les Bourbons', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000005e', 'Les Valois', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000005e', 'Les Capétiens directs', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000005e', 'Les Plantagenets', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000005f', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quel événement majeur a eu lieu le 20 juin 1789 à Versailles ?',
 'Le serment du Jeu de paume (20 juin 1789) : les députés du tiers état, rejoints par d''autres, ont juré de ne pas se séparer avant d''avoir donné une constitution à la France.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000005f', 'Le serment du Jeu de paume', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000005f', 'La prise de la Bastille', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000005f', 'La nuit du 4 août', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000005f', 'La Terreur', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000060', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Que désigne la Terreur dans le contexte de la Révolution française ?',
 'La Terreur (1793-1794) fut une période de la Révolution caractérisée par des exécutions massives (guillotine) sous l''impulsion de Robespierre et du Comité de salut public. Robespierre lui-même fut guillotiné en juillet 1794.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000060', 'Une période de répression révolutionnaire (1793-1794)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000060', 'Une bataille', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000060', 'Une famine', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000060', 'Une épidémie', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000061', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quel personnage est dit ''l''Incorruptible'' pendant la Révolution ?',
 'Maximilien de Robespierre (1758-1794) était surnommé ''l''Incorruptible''. Figure du club des Jacobins, il a dominé la Terreur, avant d''être guillotiné le 28 juillet 1794 (9 thermidor an II).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000061', 'Robespierre', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000061', 'Danton', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000061', 'Marat', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000061', 'Saint-Just', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000062', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quel coup d''État a porté Napoléon Bonaparte au pouvoir ?',
 'Le coup d''État du 18 brumaire an VIII (9 novembre 1799) a porté Napoléon Bonaparte au pouvoir. Il a mis fin au Directoire et installé le Consulat, prélude à l''Empire (1804).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000062', 'Le coup d''État du 18 brumaire (1799)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000062', 'La prise de la Bastille', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000062', 'La nuit du 4 août', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000062', 'La révolution de 1848', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000063', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quelle bataille a marqué la chute définitive de Napoléon en 1815 ?',
 'La bataille de Waterloo (18 juin 1815), en Belgique, a marqué la défaite définitive de Napoléon face aux forces alliées (Wellington, Blücher). Il fut ensuite exilé à Sainte-Hélène.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000063', 'La bataille de Waterloo (1815)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000063', 'La bataille d''Austerlitz', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000063', 'La bataille de la Marne', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000063', 'La bataille de Verdun', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000064', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quel régime politique a suivi la chute de Napoléon en 1815 ?',
 'La Restauration (1815-1830) a ramené les Bourbons sur le trône : Louis XVIII (1815-1824) puis Charles X (1824-1830). Charles X fut renversé par la révolution de juillet 1830.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000064', 'La Restauration (Louis XVIII puis Charles X)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000064', 'La République', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000064', 'La Commune', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000064', 'Le Front populaire', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000065', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Que désigne le ''Second Empire'' français ?',
 'Le Second Empire (1852-1870) fut le régime de Napoléon III (Louis-Napoléon Bonaparte, neveu de Napoléon Ier). Il a transformé Paris (travaux Haussmann) avant de tomber à Sedan en 1870.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000065', 'Le régime de Napoléon III (1852-1870)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000065', 'Le règne de Louis XIV', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000065', 'La Restauration', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000065', 'Le régime de Vichy', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000066', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quel événement a fait naître la IIIe République ?',
 'La IIIe République a été proclamée le 4 septembre 1870 après la défaite de Sedan et la capitulation de Napoléon III face à la Prusse. C''est le plus long régime républicain français (jusqu''en 1940).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000066', 'La défaite de Sedan et la chute de Napoléon III en 1870', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000066', 'La Révolution de 1789', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000066', 'L''armistice de 1918', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000066', 'La Libération de 1944', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000067', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Que désigne l''affaire Dreyfus ?',
 'L''affaire Dreyfus (1894-1906) : Alfred Dreyfus, officier juif, accusé à tort de trahison, condamné au bagne. Sa réhabilitation a divisé la France et marqué la lutte contre l''antisémitisme et l''erreur judiciaire.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000067', 'L''erreur judiciaire d''un officier juif accusé de trahison (1894-1906)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000067', 'Une affaire d''espionnage industriel', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000067', 'Une bataille militaire', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000067', 'Un procès ordinaire', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000068', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'En quelle année la France a-t-elle perdu l''Alsace-Lorraine, récupérée en 1918 ?',
 'L''Alsace-Lorraine a été annexée par l''Allemagne après la défaite de 1870-1871 (traité de Francfort, 1871). Elle a été restituée à la France après la Première Guerre mondiale (traité de Versailles, 1919).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000068', 'En 1871 (après la guerre franco-prussienne)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000068', 'En 1789', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000068', 'En 1815', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000068', 'En 1940', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000069', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quelle bataille terrible de la Première Guerre a duré de février à décembre 1916 ?',
 'La bataille de Verdun (21 février - 18 décembre 1916) est l''une des plus longues et meurtrières de la Première Guerre mondiale : environ 700 000 victimes (morts, blessés, disparus) français et allemands.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000069', 'La bataille de Verdun (1916)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000069', 'La bataille de la Somme', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000069', 'La bataille de la Marne', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000069', 'La bataille de Waterloo', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000006a', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quel célèbre maréchal français a défendu Verdun ?',
 'Philippe Pétain a commandé la défense française à Verdun en 1916, ce qui lui a valu une réputation de héros militaire. Après 1940, devenu chef de l''État français (Vichy), il s''est compromis avec l''Allemagne nazie.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000006a', 'Philippe Pétain (puis chef de l''État de Vichy)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000006a', 'Charles de Gaulle', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000006a', 'Joseph Joffre', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000006a', 'Napoléon Ier', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000006b', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quel mouvement social a eu lieu en France en 1936 ?',
 'Le Front populaire (1936-1938), coalition de gauche dirigée par Léon Blum, a marqué une série de réformes sociales majeures : congés payés, semaine de 40 heures, conventions collectives.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000006b', 'Le Front populaire (Léon Blum, 1936)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000006b', 'La Résistance', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000006b', 'Mai 68', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000006b', 'La Libération', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000006c', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quels congés ont été créés par le Front populaire en 1936 ?',
 'En 1936, le Front populaire de Léon Blum a institué les congés payés (2 semaines au départ, aujourd''hui 5 semaines). Cette mesure a transformé les vacances en France.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000006c', 'Les premiers congés payés (1936)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000006c', 'Les congés parentaux', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000006c', 'Les vacances scolaires', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000006c', 'Les jours fériés', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000006d', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quel acte symbolique du général de Gaulle a fondé la France libre ?',
 'L''appel du 18 juin 1940 lancé par le général de Gaulle depuis Londres (BBC) a appelé à la résistance contre l''occupation nazie. C''est l''acte fondateur de la France libre.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000006d', 'L''appel du 18 juin 1940 (BBC, Londres)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000006d', 'L''appel du 25 août 1944', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000006d', 'L''appel du 8 mai 1945', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000006d', 'Le discours de Bayeux', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000006e', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quelle organisation clandestine a unifié la Résistance française pendant la guerre ?',
 'Le Conseil national de la Résistance (CNR), créé par Jean Moulin le 27 mai 1943, a unifié les mouvements de Résistance intérieure. Son programme a inspiré les réformes d''après-guerre (Sécurité sociale).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000006e', 'Le Conseil national de la Résistance (CNR, 1943)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000006e', 'Le Front populaire', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000006e', 'Le Conseil d''État', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000006e', 'La Croix-Rouge', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000006f', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quelle réalisation majeure d''après-guerre a établi la protection sociale en France ?',
 'La Sécurité sociale a été créée par les ordonnances des 4 et 19 octobre 1945, sur la base des programmes du CNR. Elle garantit l''accès aux soins, les retraites, les allocations familiales.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000006f', 'La Sécurité sociale (créée en 1945)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000006f', 'L''Éducation nationale', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000006f', 'Le Code du travail', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000006f', 'Le SMIC', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000070', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quand la France a-t-elle accordé l''indépendance à ses colonies d''Afrique sub-saharienne ?',
 'Les anciennes colonies françaises d''Afrique sub-saharienne ont accédé à l''indépendance en 1960 (Sénégal, Mali, Niger, Côte d''Ivoire, etc.). C''est l''''année de l''Afrique''.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000070', 'En 1960 (année de l''Afrique)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000070', 'En 1945', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000070', 'En 1981', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000070', 'En 2000', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000071', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quel ministre, en 1945, a participé à la fondation de la Sécurité sociale ?',
 'Pierre Laroque (1907-1997), haut fonctionnaire, a été le principal architecte de la Sécurité sociale française créée en 1945. Le ministre du Travail était alors Ambroise Croizat.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000071', 'Pierre Laroque (avec Ambroise Croizat)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000071', 'Robert Schuman', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000071', 'Jean Monnet', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000071', 'De Gaulle seul', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000072', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Qui sont les ''pères fondateurs'' de la construction européenne du côté français ?',
 'Jean Monnet et Robert Schuman sont considérés comme les pères fondateurs de la construction européenne, avec la Déclaration Schuman du 9 mai 1950 et la CECA.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000072', 'Jean Monnet et Robert Schuman', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000072', 'Napoléon et Bismarck', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000072', 'De Gaulle et Adenauer uniquement', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000072', 'Hugo et Zola', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000073', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Que désigne la ''CECA'' créée en 1951 ?',
 'La Communauté européenne du charbon et de l''acier (CECA), créée en 1951 par le traité de Paris, est l''ancêtre de l''Union européenne. Elle mettait en commun les productions de charbon et d''acier.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000073', 'La Communauté européenne du charbon et de l''acier (1951)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000073', 'Une compagnie ferroviaire', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000073', 'Un club sportif', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000073', 'Un parti politique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000074', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quelle décolonisation a particulièrement marqué la France après 1945 ?',
 'Deux décolonisations marquantes : l''Indochine (guerre 1946-1954, défaite de Diên Biên Phu, accords de Genève) et l''Algérie (guerre 1954-1962, accords d''Évian).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000074', 'L''Indochine puis l''Algérie', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000074', 'Le Canada', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000074', 'Le Royaume-Uni', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000074', 'L''Espagne', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000075', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quel accord a mis fin à la guerre d''Indochine en 1954 ?',
 'Les accords de Genève (juillet 1954) ont mis fin à la guerre d''Indochine, après la défaite française de Diên Biên Phu (mai 1954). Le Vietnam a été divisé en deux.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000075', 'Les accords de Genève (1954)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000075', 'Les accords d''Évian', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000075', 'Le traité de Versailles', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000075', 'Les accords de Yalta', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000076', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quel référendum décisif a eu lieu en 1962 sur le mode d''élection du président ?',
 'Le référendum du 28 octobre 1962, proposé par de Gaulle, a instauré l''élection du président au suffrage universel direct. Cette réforme a renforcé la légitimité présidentielle.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000076', 'Le référendum sur l''élection présidentielle au suffrage direct (1962)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000076', 'Le référendum sur Maastricht', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000076', 'Le référendum sur l''Algérie', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000076', 'Le référendum sur le quinquennat', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000077', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quelle crise politique majeure a frappé la France de mai à juin 1968 ?',
 'Mai 68 a combiné une crise étudiante (occupation de la Sorbonne, barricades), une crise sociale (10 millions de grévistes) et une crise politique. De Gaulle a dissous l''Assemblée et son parti a remporté les élections.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000077', 'Une crise étudiante, sociale et politique (Mai 68)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000077', 'Une guerre civile', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000077', 'Une famine', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000077', 'Une épidémie', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000078', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quel président a accordé la majorité à 18 ans en 1974 ?',
 'Valéry Giscard d''Estaing (président de 1974 à 1981) a fait abaisser l''âge de la majorité de 21 à 18 ans en 1974, ouvrant le droit de vote des jeunes.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000078', 'Valéry Giscard d''Estaing (1974)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000078', 'François Mitterrand', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000078', 'Jacques Chirac', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000078', 'Charles de Gaulle', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000079', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Qui a été le premier président socialiste de la Ve République ?',
 'François Mitterrand (président de 1981 à 1995) a été le premier président socialiste de la Ve République. Il a fait abolir la peine de mort, décentralisé l''État, instauré les 39h hebdomadaires.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000079', 'François Mitterrand', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000079', 'Charles de Gaulle', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000079', 'Georges Pompidou', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000079', 'Jacques Chirac', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000007a', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quel traité européen a été signé en 1992, ratifié par référendum en France ?',
 'Le traité de Maastricht (signé le 7 février 1992) a créé l''Union européenne. La France l''a ratifié par référendum le 20 septembre 1992 (oui à 51,04%).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000007a', 'Le traité de Maastricht (1992)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000007a', 'Le traité de Lisbonne', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000007a', 'Le traité de Rome', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000007a', 'Le traité de Schengen', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000007b', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quel référendum français de 2005 a rejeté le traité constitutionnel européen ?',
 'Le référendum du 29 mai 2005 a rejeté le projet de Constitution européenne (54,68% de non). Le traité de Lisbonne (2007) a intégré l''essentiel des dispositions sans référendum.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000007b', 'Le référendum sur la Constitution européenne (29 mai 2005)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000007b', 'Le référendum sur Maastricht', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000007b', 'Le référendum sur le quinquennat', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000007b', 'Le référendum sur le Brexit', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000007c', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quel événement tragique a marqué Paris le 13 novembre 2015 ?',
 'Les attentats du 13 novembre 2015 (Bataclan, terrasses de cafés, Stade de France) ont fait 130 morts et plus de 400 blessés à Paris et Saint-Denis. L''état d''urgence a été déclaré.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000007c', 'Les attentats terroristes du 13 novembre 2015', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000007c', 'Une inondation', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000007c', 'Une grève générale', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000007c', 'Un incendie accidentel', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-0000000000d1', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quelle écrivaine française a reçu le prix Nobel de littérature en 2022 ?',
 'Annie Ernaux, écrivaine française née en 1940, a reçu le prix Nobel de littérature en 2022 pour son œuvre autobiographique et sociologique. Première Française à obtenir ce prix.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d1', 'Annie Ernaux (2022)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d1', 'Marguerite Duras', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d1', 'Françoise Sagan', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d1', 'Colette', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-0000000000d2', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quel monument parisien a brûlé en 2019 et a été restauré en 2024 ?',
 'La cathédrale Notre-Dame de Paris a subi un grave incendie le 15 avril 2019. Sa restauration s''est achevée en décembre 2024, permettant sa réouverture au public.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d2', 'Notre-Dame de Paris (incendie 2019, réouverture 2024)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d2', 'La tour Eiffel', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d2', 'Le Louvre', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d2', 'L''Arc de Triomphe', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-0000000000d3', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quel philosophe français existentialiste a refusé le prix Nobel en 1964 ?',
 'Jean-Paul Sartre (1905-1980), philosophe existentialiste et écrivain, a refusé le prix Nobel de littérature qui lui était décerné en 1964. Il était le compagnon de Simone de Beauvoir.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d3', 'Jean-Paul Sartre', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d3', 'Albert Camus', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d3', 'André Malraux', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d3', 'Raymond Aron', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-0000000000d4', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quelle école prestigieuse française forme les hauts fonctionnaires de l''État ?',
 'L''ENA (École nationale d''administration), créée en 1945, a formé les hauts fonctionnaires français. Remplacée en 2022 par l''INSP (Institut national du service public).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d4', 'L''ENA, devenue INSP en 2022', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d4', 'Polytechnique', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d4', 'HEC', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d4', 'La Sorbonne', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-0000000000d5', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quelle île française du Pacifique a connu plusieurs référendums sur l''indépendance ?',
 'La Nouvelle-Calédonie, collectivité française sui generis du Pacifique sud, a organisé trois référendums sur l''indépendance (2018, 2020, 2021), tous rejetés.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d5', 'La Nouvelle-Calédonie', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d5', 'La Réunion', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d5', 'La Guadeloupe', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d5', 'Mayotte', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-0000000000d6', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quel événement annuel important du sport français a lieu en juillet depuis 1903 ?',
 'Le Tour de France de cyclisme, créé en 1903, est une course mythique de trois semaines en juillet, traversant la France et les pays voisins. L''arrivée est aux Champs-Élysées.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d6', 'Le Tour de France de cyclisme (depuis 1903)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d6', 'La Coupe du monde de football', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d6', 'Roland-Garros', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d6', 'Le marathon de Paris', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-0000000000d7', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quel sommet mondial s''est tenu à Paris en décembre 2015 sur le climat ?',
 'La COP21 (décembre 2015) a abouti à l''Accord de Paris sur le climat, qui engage les États à limiter le réchauffement climatique. Premier accord universel sur le climat.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d7', 'La COP21 (Accord de Paris sur le climat)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d7', 'Un sommet de l''OTAN', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d7', 'Une conférence économique', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d7', 'Aucun sommet majeur', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-0000000000d8', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quels grands événements sportifs internationaux la France a-t-elle accueillis en 2024 ?',
 'La France a accueilli les Jeux olympiques d''été à Paris (26 juillet - 11 août 2024) et les Jeux paralympiques (28 août - 8 septembre 2024), 100 ans après les précédents JO parisiens de 1924.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d8', 'Les Jeux olympiques et paralympiques de Paris 2024', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d8', 'La Coupe du monde de football', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d8', 'Un seul tournoi de tennis', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d8', 'Aucun événement', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000007d', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'MISE_SITUATION',
 'Je veux honorer la mémoire des victimes des attentats de 2015. Que faire en tant que citoyen ?',
 'Participer aux cérémonies de commémoration (notamment le 13 novembre), respecter une minute de silence, soutenir les associations de victimes, transmettre la mémoire aux jeunes générations.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000007d', 'Cérémonies, silence, associations, transmission', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000007d', 'Ne rien faire', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000007d', 'Refuser de sortir', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000007d', 'Quitter le pays', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000007e', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'MISE_SITUATION',
 'Quelqu''un me demande quand la France a aboli la peine de mort. Quels repères donner ?',
 'La peine de mort a été abolie par la loi du 9 octobre 1981, sous la présidence de François Mitterrand, sur proposition de Robert Badinter. Abolition inscrite dans la Constitution en 2007.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000007e', '1981 (loi Badinter sous Mitterrand) ; constitutionnel depuis 2007', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000007e', '1789', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000007e', '1944', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000007e', '2000', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000007f', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'MISE_SITUATION',
 'Je veux comprendre l''importance du général de Gaulle dans l''histoire française. Quels repères ?',
 'De Gaulle a incarné la France libre pendant la guerre (1940-1945), libéré le pays, fondé la Ve République (1958), réorganisé les institutions, décolonisé (Algérie en 1962). Président de 1959 à 1969.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000007f', 'France libre, Libération, Ve République, décolonisation', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000007f', 'Aucun rôle majeur', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000007f', 'Uniquement un président pacifique', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000007f', 'Uniquement un militaire', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000080', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'MISE_SITUATION',
 'Je veux comprendre pourquoi le 9 mai est la fête de l''Europe. Quelle origine ?',
 'Le 9 mai 1950, Robert Schuman a prononcé la ''Déclaration Schuman'' proposant la mise en commun des productions de charbon et d''acier de France et d''Allemagne (CECA). C''est l''acte fondateur de l''Europe.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000080', 'La Déclaration Schuman du 9 mai 1950', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000080', 'Le jour de la Libération', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000080', 'La fête d''un saint', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000080', 'Une bataille napoléonienne', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000081', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'MISE_SITUATION',
 'On me demande qui étaient Jean Monnet et Robert Schuman. Que répondre ?',
 'Tous deux Français, pères fondateurs de l''Europe : Jean Monnet (1888-1979) économiste à l''origine de la CECA et de la CEE. Robert Schuman (1886-1963) ministre auteur de la Déclaration de 1950.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000081', 'Les pères fondateurs français de la construction européenne', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000081', 'Des explorateurs', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000081', 'Des philosophes', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000081', 'Des compositeurs', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000082', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'MISE_SITUATION',
 'J''apprends que la France était en guerre d''Algérie. Quels repères historiques essentiels ?',
 'Guerre d''Algérie : 1954-1962. Indépendance de l''Algérie le 5 juillet 1962 après les accords d''Évian (mars 1962). Cette guerre a marqué la fin de l''Empire colonial français et la chute de la IVe République.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000082', 'Guerre 1954-1962, accords d''Évian, indépendance le 5 juillet 1962', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000082', 'Guerre 1939-1945', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000082', 'Bataille napoléonienne', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000082', 'Une simple crise économique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000083', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'MISE_SITUATION',
 'Je veux mieux connaître les Lumières. Quels penseurs français essentiels ?',
 'Les Lumières (XVIIIe siècle) : Voltaire (tolérance, liberté d''expression), Rousseau (Du contrat social, souveraineté populaire), Diderot (l''Encyclopédie), Montesquieu (séparation des pouvoirs).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000083', 'Voltaire, Rousseau, Diderot, Montesquieu', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000083', 'Sartre et Camus', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000083', 'Hugo et Zola', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000083', 'Aucun penseur français', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000084', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'MISE_SITUATION',
 'Quelqu''un me dit que toutes les républiques françaises sont identiques. Que répondre ?',
 'Non. Les 5 républiques diffèrent par leurs institutions : Ire (1792, première République, Directoire), IIe (1848, suffrage universel masculin), IIIe (1870-1940, régime parlementaire), IVe (1946-1958, instable), Ve (1958, exécutif renforcé).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000084', 'Chaque République a un cadre institutionnel différent', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000084', 'Elles sont identiques', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000084', 'Il n''y en a eu qu''une', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000084', 'Elles n''existent pas', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000085', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'MISE_SITUATION',
 'Je veux connaître les Justes de France. Que désigne ce terme ?',
 'Les ''Justes parmi les Nations'' sont des non-Juifs ayant aidé à sauver des Juifs pendant la Shoah. Plus de 4 000 Français ont été distingués par Israël. Le 16 juillet, journée nationale à leur mémoire.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000085', 'Non-Juifs ayant sauvé des Juifs pendant la Shoah', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000085', 'Des héros militaires', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000085', 'Des dirigeants politiques', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000085', 'Des scientifiques', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000086', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'MISE_SITUATION',
 'Je veux comprendre la décentralisation française de 1982. En quoi consiste-t-elle ?',
 'Les lois Defferre de 1982 (sous Mitterrand) ont transféré des compétences de l''État vers les collectivités locales (régions, départements, communes), donnant plus de pouvoir aux élus locaux.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000086', 'Transfert de pouvoirs vers les collectivités locales (1982)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000086', 'Suppression de l''État', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000086', 'Indépendance des régions', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000086', 'Aucune réforme territoriale', FALSE, 3);
