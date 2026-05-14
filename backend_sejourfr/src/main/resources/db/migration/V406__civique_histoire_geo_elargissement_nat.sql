-- Flyway: niveau 3 theme 4 HISTOIRE_GEO - 50 NAT (40 CONN + 10 MS) - is_active=FALSE

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000005d', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quel traite a mis fin a la guerre de Trente Ans (1648) ?',
 'Les traites de Westphalie (1648) ont mis fin a la guerre de Trente Ans. Ils ont pose les bases du droit international moderne et confirme la puissance de la France de Louis XIV.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000005d', 'Les traites de Westphalie (1648)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000005d', 'Le traite de Versailles', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000005d', 'Le traite de Maastricht', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000005d', 'Le traite de Rome', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000005e', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quelle dynastie regnait sur la France a la veille de la Revolution ?',
 'La dynastie des Bourbons regnait sur la France depuis 1589 (Henri IV). Louis XVI etait le dernier Bourbon a regner avant la Revolution et l''abolition de la monarchie en 1792.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000005e', 'Les Bourbons', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000005e', 'Les Valois', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000005e', 'Les Capetiens directs', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000005e', 'Les Plantagenets', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000005f', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quel evenement majeur a eu lieu le 20 juin 1789 a Versailles ?',
 'Le serment du Jeu de paume (20 juin 1789) : les deputes du tiers etat, rejoints par d''autres, ont jure de ne pas se separer avant d''avoir donne une constitution a la France.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000005f', 'Le serment du Jeu de paume', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000005f', 'La prise de la Bastille', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000005f', 'La nuit du 4 aout', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000005f', 'La Terreur', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000060', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Que designe la Terreur dans le contexte de la Revolution francaise ?',
 'La Terreur (1793-1794) fut une periode de la Revolution caracterisee par des executions massives (guillotine) sous l''impulsion de Robespierre et du Comite de salut public. Robespierre lui-meme fut guillotine en juillet 1794.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000060', 'Une periode de repression revolutionnaire (1793-1794)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000060', 'Une bataille', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000060', 'Une famine', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000060', 'Une epidemie', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000061', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quel personnage est dit ''l''Incorruptible'' pendant la Revolution ?',
 'Maximilien de Robespierre (1758-1794) etait surnomme ''l''Incorruptible''. Figure du club des Jacobins, il a domine la Terreur, avant d''etre guillotine le 28 juillet 1794 (9 thermidor an II).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000061', 'Robespierre', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000061', 'Danton', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000061', 'Marat', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000061', 'Saint-Just', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000062', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quel coup d''Etat a porte Napoleon Bonaparte au pouvoir ?',
 'Le coup d''Etat du 18 brumaire an VIII (9 novembre 1799) a porte Napoleon Bonaparte au pouvoir. Il a mis fin au Directoire et installe le Consulat, prelude a l''Empire (1804).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000062', 'Le coup d''Etat du 18 brumaire (1799)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000062', 'La prise de la Bastille', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000062', 'La nuit du 4 aout', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000062', 'La revolution de 1848', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000063', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quelle bataille a marque la chute definitive de Napoleon en 1815 ?',
 'La bataille de Waterloo (18 juin 1815), en Belgique, a marque la defaite definitive de Napoleon face aux forces alliees (Wellington, Blucher). Il fut ensuite exile a Sainte-Helene.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000063', 'La bataille de Waterloo (1815)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000063', 'La bataille d''Austerlitz', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000063', 'La bataille de la Marne', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000063', 'La bataille de Verdun', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000064', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quel regime politique a suivi la chute de Napoleon en 1815 ?',
 'La Restauration (1815-1830) a ramene les Bourbons sur le trone : Louis XVIII (1815-1824) puis Charles X (1824-1830). Charles X fut renverse par la revolution de juillet 1830.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000064', 'La Restauration (Louis XVIII puis Charles X)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000064', 'La Republique', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000064', 'La Commune', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000064', 'Le Front populaire', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000065', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Que designe le ''Second Empire'' francais ?',
 'Le Second Empire (1852-1870) fut le regime de Napoleon III (Louis-Napoleon Bonaparte, neveu de Napoleon Ier). Il a transforme Paris (travaux Haussmann) avant de tomber a Sedan en 1870.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000065', 'Le regime de Napoleon III (1852-1870)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000065', 'Le regne de Louis XIV', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000065', 'La Restauration', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000065', 'Le regime de Vichy', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000066', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quel evenement a fait naitre la IIIe Republique ?',
 'La IIIe Republique a ete proclamee le 4 septembre 1870 apres la defaite de Sedan et la capitulation de Napoleon III face a la Prusse. C''est le plus long regime republicain francais (jusqu''en 1940).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000066', 'La defaite de Sedan et la chute de Napoleon III en 1870', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000066', 'La Revolution de 1789', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000066', 'L''armistice de 1918', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000066', 'La Liberation de 1944', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000067', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Que designe l''affaire Dreyfus ?',
 'L''affaire Dreyfus (1894-1906) : Alfred Dreyfus, officier juif, accuse a tort de trahison, condamne au bagne. Sa rehabilitation a divise la France et marque la lutte contre l''antisemitisme et l''erreur judiciaire.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000067', 'L''erreur judiciaire d''un officier juif accuse de trahison (1894-1906)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000067', 'Une affaire d''espionnage industriel', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000067', 'Une bataille militaire', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000067', 'Un proces ordinaire', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000068', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'En quelle annee la France a-t-elle perdu l''Alsace-Lorraine, recuperee en 1918 ?',
 'L''Alsace-Lorraine a ete annexee par l''Allemagne apres la defaite de 1870-1871 (traite de Francfort, 1871). Elle a ete restituee a la France apres la Premiere Guerre mondiale (traite de Versailles, 1919).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000068', 'En 1871 (apres la guerre franco-prussienne)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000068', 'En 1789', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000068', 'En 1815', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000068', 'En 1940', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000069', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quelle bataille terrible de la Premiere Guerre a dure de fevrier a decembre 1916 ?',
 'La bataille de Verdun (21 fevrier - 18 decembre 1916) est l''une des plus longues et meurtrieres de la Premiere Guerre mondiale : environ 700 000 victimes (morts, blesses, disparus) francais et allemands.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000069', 'La bataille de Verdun (1916)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000069', 'La bataille de la Somme', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000069', 'La bataille de la Marne', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000069', 'La bataille de Waterloo', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000006a', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quel celebre marechal francais a defendu Verdun ?',
 'Philippe Petain a commande la defense francaise a Verdun en 1916, ce qui lui a valu une reputation de heros militaire. Apres 1940, devenu chef de l''Etat francais (Vichy), il s''est compromis avec l''Allemagne nazie.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000006a', 'Philippe Petain (puis chef de l''Etat de Vichy)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000006a', 'Charles de Gaulle', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000006a', 'Joseph Joffre', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000006a', 'Napoleon Ier', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000006b', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quel mouvement social a eu lieu en France en 1936 ?',
 'Le Front populaire (1936-1938), coalition de gauche dirigee par Leon Blum, a marque une serie de reformes sociales majeures : conges payes, semaine de 40 heures, conventions collectives.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000006b', 'Le Front populaire (Leon Blum, 1936)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000006b', 'La Resistance', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000006b', 'Mai 68', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000006b', 'La Liberation', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000006c', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quels conges ont ete crees par le Front populaire en 1936 ?',
 'En 1936, le Front populaire de Leon Blum a institue les conges payes (2 semaines au depart, aujourd''hui 5 semaines). Cette mesure a transforme les vacances en France.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000006c', 'Les premiers conges payes (1936)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000006c', 'Les conges parentaux', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000006c', 'Les vacances scolaires', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000006c', 'Les jours feries', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000006d', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quel acte symbolique du general de Gaulle a fonde la France libre ?',
 'L''appel du 18 juin 1940 lance par le general de Gaulle depuis Londres (BBC) a appele a la resistance contre l''occupation nazie. C''est l''acte fondateur de la France libre.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000006d', 'L''appel du 18 juin 1940 (BBC, Londres)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000006d', 'L''appel du 25 aout 1944', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000006d', 'L''appel du 8 mai 1945', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000006d', 'Le discours de Bayeux', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000006e', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quelle organisation clandestine a unifie la Resistance francaise pendant la guerre ?',
 'Le Conseil national de la Resistance (CNR), cree par Jean Moulin le 27 mai 1943, a unifie les mouvements de Resistance interieure. Son programme a inspire les reformes d''apres-guerre (Securite sociale).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000006e', 'Le Conseil national de la Resistance (CNR, 1943)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000006e', 'Le Front populaire', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000006e', 'Le Conseil d''Etat', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000006e', 'La Croix-Rouge', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000006f', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quelle realisation majeure d''apres-guerre a etabli la protection sociale en France ?',
 'La Securite sociale a ete creee par les ordonnances des 4 et 19 octobre 1945, sur la base des programmes du CNR. Elle garantit l''acces aux soins, les retraites, les allocations familiales.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000006f', 'La Securite sociale (creee en 1945)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000006f', 'L''Education nationale', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000006f', 'Le Code du travail', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000006f', 'Le SMIC', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000070', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quand la France a-t-elle accorde l''independance a ses colonies d''Afrique sub-saharienne ?',
 'Les anciennes colonies francaises d''Afrique sub-saharienne ont accede a l''independance en 1960 (Senegal, Mali, Niger, Cote d''Ivoire, etc.). C''est l''''annee de l''Afrique''.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000070', 'En 1960 (annee de l''Afrique)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000070', 'En 1945', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000070', 'En 1981', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000070', 'En 2000', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000071', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quel ministre, en 1945, a participe a la fondation de la Securite sociale ?',
 'Pierre Laroque (1907-1997), haut fonctionnaire, a ete le principal architecte de la Securite sociale francaise creee en 1945. Le ministre du Travail etait alors Ambroise Croizat.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000071', 'Pierre Laroque (avec Ambroise Croizat)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000071', 'Robert Schuman', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000071', 'Jean Monnet', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000071', 'De Gaulle seul', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000072', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Qui sont les ''peres fondateurs'' de la construction europeenne du cote francais ?',
 'Jean Monnet et Robert Schuman sont consideres comme les peres fondateurs de la construction europeenne, avec la Declaration Schuman du 9 mai 1950 et la CECA.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000072', 'Jean Monnet et Robert Schuman', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000072', 'Napoleon et Bismarck', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000072', 'De Gaulle et Adenauer uniquement', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000072', 'Hugo et Zola', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000073', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Que designe la ''CECA'' creee en 1951 ?',
 'La Communaute europeenne du charbon et de l''acier (CECA), creee en 1951 par le traite de Paris, est l''ancetre de l''Union europeenne. Elle mettait en commun les productions de charbon et d''acier.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000073', 'La Communaute europeenne du charbon et de l''acier (1951)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000073', 'Une compagnie ferroviaire', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000073', 'Un club sportif', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000073', 'Un parti politique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000074', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quelle decolonisation a particulierement marque la France apres 1945 ?',
 'Deux decolonisations marquantes : l''Indochine (guerre 1946-1954, defaite de Dien Bien Phu, accords de Geneve) et l''Algerie (guerre 1954-1962, accords d''Evian).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000074', 'L''Indochine puis l''Algerie', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000074', 'Le Canada', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000074', 'Le Royaume-Uni', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000074', 'L''Espagne', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000075', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quel accord a mis fin a la guerre d''Indochine en 1954 ?',
 'Les accords de Geneve (juillet 1954) ont mis fin a la guerre d''Indochine, apres la defaite francaise de Dien Bien Phu (mai 1954). Le Vietnam a ete divise en deux.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000075', 'Les accords de Geneve (1954)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000075', 'Les accords d''Evian', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000075', 'Le traite de Versailles', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000075', 'Les accords de Yalta', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000076', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quel referendum decisif a eu lieu en 1962 sur le mode d''election du president ?',
 'Le referendum du 28 octobre 1962, propose par de Gaulle, a instaure l''election du president au suffrage universel direct. Cette reforme a renforce la legitimite presidentielle.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000076', 'Le referendum sur l''election presidentielle au suffrage direct (1962)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000076', 'Le referendum sur Maastricht', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000076', 'Le referendum sur l''Algerie', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000076', 'Le referendum sur le quinquennat', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000077', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quelle crise politique majeure a frappe la France de mai a juin 1968 ?',
 'Mai 68 a combine une crise etudiante (occupation de la Sorbonne, barricades), une crise sociale (10 millions de grevistes) et une crise politique. De Gaulle a dissous l''Assemblee et son parti a remporte les elections.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000077', 'Une crise etudiante, sociale et politique (Mai 68)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000077', 'Une guerre civile', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000077', 'Une famine', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000077', 'Une epidemie', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000078', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quel president a accorde la majorite a 18 ans en 1974 ?',
 'Valery Giscard d''Estaing (president de 1974 a 1981) a fait abaisser l''age de la majorite de 21 a 18 ans en 1974, ouvrant le droit de vote des jeunes.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000078', 'Valery Giscard d''Estaing (1974)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000078', 'Francois Mitterrand', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000078', 'Jacques Chirac', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000078', 'Charles de Gaulle', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000079', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Qui a ete le premier president socialiste de la Ve Republique ?',
 'Francois Mitterrand (president de 1981 a 1995) a ete le premier president socialiste de la Ve Republique. Il a fait abolir la peine de mort, decentralise l''Etat, instaure les 39h hebdomadaires.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000079', 'Francois Mitterrand', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000079', 'Charles de Gaulle', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000079', 'Georges Pompidou', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000079', 'Jacques Chirac', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000007a', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quel traite europeen a ete signe en 1992, ratifie par referendum en France ?',
 'Le traite de Maastricht (signe le 7 fevrier 1992) a cree l''Union europeenne. La France l''a ratifie par referendum le 20 septembre 1992 (oui a 51,04%).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000007a', 'Le traite de Maastricht (1992)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000007a', 'Le traite de Lisbonne', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000007a', 'Le traite de Rome', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000007a', 'Le traite de Schengen', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000007b', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quel referendum francais de 2005 a rejete le traite constitutionnel europeen ?',
 'Le referendum du 29 mai 2005 a rejete le projet de Constitution europeenne (54,68% de non). Le traite de Lisbonne (2007) a integre l''essentiel des dispositions sans referendum.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000007b', 'Le referendum sur la Constitution europeenne (29 mai 2005)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000007b', 'Le referendum sur Maastricht', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000007b', 'Le referendum sur le quinquennat', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000007b', 'Le referendum sur le Brexit', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000007c', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quel evenement tragique a marque Paris le 13 novembre 2015 ?',
 'Les attentats du 13 novembre 2015 (Bataclan, terrasses de cafes, Stade de France) ont fait 130 morts et plus de 400 blesses a Paris et Saint-Denis. L''etat d''urgence a ete declare.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000007c', 'Les attentats terroristes du 13 novembre 2015', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000007c', 'Une inondation', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000007c', 'Une greve generale', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000007c', 'Un incendie accidentel', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-0000000000d1', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quelle ecrivaine francaise a recu le prix Nobel de litterature en 2022 ?',
 'Annie Ernaux, ecrivaine francaise nee en 1940, a recu le prix Nobel de litterature en 2022 pour son oeuvre autobiographique et sociologique. Premiere Francaise a obtenir ce prix.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d1', 'Annie Ernaux (2022)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d1', 'Marguerite Duras', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d1', 'Francoise Sagan', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d1', 'Colette', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-0000000000d2', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quel monument parisien a brule en 2019 et a ete restaure en 2024 ?',
 'La cathedrale Notre-Dame de Paris a subi un grave incendie le 15 avril 2019. Sa restauration s''est achevee en decembre 2024, permettant sa reouverture au public.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d2', 'Notre-Dame de Paris (incendie 2019, reouverture 2024)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d2', 'La tour Eiffel', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d2', 'Le Louvre', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d2', 'L''Arc de Triomphe', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-0000000000d3', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quel philosophe francais existentialiste a refuse le prix Nobel en 1964 ?',
 'Jean-Paul Sartre (1905-1980), philosophe existentialiste et ecrivain, a refuse le prix Nobel de litterature qui lui etait decerne en 1964. Il etait le compagnon de Simone de Beauvoir.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d3', 'Jean-Paul Sartre', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d3', 'Albert Camus', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d3', 'Andre Malraux', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d3', 'Raymond Aron', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-0000000000d4', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quelle ecole prestigieuse francaise forme les hauts fonctionnaires de l''Etat ?',
 'L''ENA (Ecole nationale d''administration), creee en 1945, a forme les hauts fonctionnaires francais. Remplacee en 2022 par l''INSP (Institut national du service public).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d4', 'L''ENA, devenue INSP en 2022', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d4', 'Polytechnique', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d4', 'HEC', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d4', 'La Sorbonne', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-0000000000d5', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quelle ile francaise du Pacifique a connu plusieurs referendums sur l''independance ?',
 'La Nouvelle-Caledonie, collectivite francaise sui generis du Pacifique sud, a organise trois referendums sur l''independance (2018, 2020, 2021), tous rejetes.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d5', 'La Nouvelle-Caledonie', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d5', 'La Reunion', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d5', 'La Guadeloupe', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d5', 'Mayotte', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-0000000000d6', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quel evenement annuel important du sport francais a lieu en juillet depuis 1903 ?',
 'Le Tour de France de cyclisme, cree en 1903, est une course mythique de trois semaines en juillet, traversant la France et les pays voisins. L''arrivee est aux Champs-Elysees.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d6', 'Le Tour de France de cyclisme (depuis 1903)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d6', 'La Coupe du monde de football', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d6', 'Roland-Garros', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d6', 'Le marathon de Paris', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-0000000000d7', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quel sommet mondial s''est tenu a Paris en decembre 2015 sur le climat ?',
 'La COP21 (decembre 2015) a abouti a l''Accord de Paris sur le climat, qui engage les Etats a limiter le rechauffement climatique. Premier accord universel sur le climat.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d7', 'La COP21 (Accord de Paris sur le climat)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d7', 'Un sommet de l''OTAN', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d7', 'Une conference economique', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d7', 'Aucun sommet majeur', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-0000000000d8', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
 'Quels grands evenements sportifs internationaux la France a-t-elle accueillis en 2024 ?',
 'La France a accueilli les Jeux olympiques d''ete a Paris (26 juillet - 11 aout 2024) et les Jeux paralympiques (28 aout - 8 septembre 2024), 100 ans apres les precedents JO parisiens de 1924.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d8', 'Les Jeux olympiques et paralympiques de Paris 2024', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d8', 'La Coupe du monde de football', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d8', 'Un seul tournoi de tennis', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-0000000000d8', 'Aucun evenement', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000007d', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'MISE_SITUATION',
 'Je veux honorer la memoire des victimes des attentats de 2015. Que faire de citoyen ?',
 'Participer aux ceremonies de commemoration (notamment le 13 novembre), respecter une minute de silence, soutenir les associations de victimes, transmettre la memoire aux jeunes generations.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000007d', 'Ceremonies, silence, associations, transmission', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000007d', 'Rien faire', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000007d', 'Refuser de sortir', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000007d', 'Quitter le pays', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000007e', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'MISE_SITUATION',
 'Quelqu''un me demande quand la France a aboli la peine de mort. Quels reperes donner ?',
 'La peine de mort a ete abolie par la loi du 9 octobre 1981, sous la presidence de Francois Mitterrand, sur proposition de Robert Badinter. Abolition inscrite dans la Constitution en 2007.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000007e', '1981 (loi Badinter sous Mitterrand) ; constitutionnel depuis 2007', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000007e', '1789', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000007e', '1944', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000007e', '2000', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-00000000007f', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'MISE_SITUATION',
 'Je veux comprendre l''importance du general de Gaulle dans l''histoire francaise. Quels reperes ?',
 'De Gaulle a incarne la France libre pendant la guerre (1940-1945), libere le pays, fonde la Ve Republique (1958), reorganise les institutions, decolonise (Algerie en 1962). President de 1959 a 1969.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000007f', 'France libre, Liberation, Ve Republique, decolonisation', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000007f', 'Aucun role majeur', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000007f', 'Uniquement un president pacifique', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-00000000007f', 'Uniquement un militaire', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000080', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'MISE_SITUATION',
 'Je veux comprendre pourquoi le 9 mai est la fete de l''Europe. Quelle origine ?',
 'Le 9 mai 1950, Robert Schuman a prononce la ''Declaration Schuman'' proposant la mise en commun des productions de charbon et d''acier de France et d''Allemagne (CECA). C''est l''acte fondateur de l''Europe.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000080', 'La Declaration Schuman du 9 mai 1950', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000080', 'Le jour de la Liberation', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000080', 'La fete d''un saint', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000080', 'Une bataille napoleonienne', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000081', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'MISE_SITUATION',
 'On me demande qui etaient Jean Monnet et Robert Schuman. Que repondre ?',
 'Tous deux Francais, peres fondateurs de l''Europe : Jean Monnet (1888-1979) economiste a l''origine de la CECA et de la CEE. Robert Schuman (1886-1963) ministre auteur de la Declaration de 1950.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000081', 'Les peres fondateurs francais de la construction europeenne', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000081', 'Des explorateurs', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000081', 'Des philosophes', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000081', 'Des compositeurs', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000082', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'MISE_SITUATION',
 'J''apprends que la France etait en guerre d''Algerie. Quels reperes historiques essentiels ?',
 'Guerre d''Algerie : 1954-1962. Independance de l''Algerie le 5 juillet 1962 apres les accords d''Evian (mars 1962). Cette guerre a marque la fin de l''Empire colonial francais et la chute de la IVe Republique.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000082', 'Guerre 1954-1962, accords d''Evian, independance le 5 juillet 1962', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000082', 'Guerre 1939-1945', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000082', 'Bataille napoleonienne', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000082', 'Une simple crise economique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000083', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'MISE_SITUATION',
 'Je veux mieux connaitre les Lumieres. Quels penseurs francais essentiels ?',
 'Les Lumieres (XVIIIe siecle) : Voltaire (tolerance, liberte d''expression), Rousseau (Du contrat social, souverainete populaire), Diderot (l''Encyclopedie), Montesquieu (separation des pouvoirs).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000083', 'Voltaire, Rousseau, Diderot, Montesquieu', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000083', 'Sartre et Camus', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000083', 'Hugo et Zola', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000083', 'Aucun penseur francais', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000084', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'MISE_SITUATION',
 'Quelqu''un me dit que toutes les republiques francaises sont identiques. Que repondre ?',
 'Non. Les 5 republiques different par leurs institutions : Ire (1792, premiere Republique, Directoire), IIe (1848, suffrage universel masculin), IIIe (1870-1940, regime parlementaire), IVe (1946-1958, instable), Ve (1958, executif renforce).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000084', 'Chaque Republique a un cadre institutionnel different', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000084', 'Elles sont identiques', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000084', 'Il n''y en a eu qu''une', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000084', 'Elles n''existent pas', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000085', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'MISE_SITUATION',
 'Je veux connaitre les Justes de France. Que designe ce terme ?',
 'Les ''Justes parmi les Nations'' sont des non-Juifs ayant aide a sauver des Juifs pendant la Shoah. Plus de 4 000 Francais ont ete distingues par Israel. Le 16 juillet, journee nationale a leur memoire.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000085', 'Non-Juifs ayant sauve des Juifs pendant la Shoah', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000085', 'Des heros militaires', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000085', 'Des dirigeants politiques', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000085', 'Des scientifiques', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f4000002-0000-0000-0000-000000000086', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', 'NAT', 'MISE_SITUATION',
 'Je veux comprendre la decentralisation francaise de 1982. En quoi consiste-t-elle ?',
 'Les lois Defferre de 1982 (sous Mitterrand) ont transfere des competences de l''Etat vers les collectivites locales (regions, departements, communes), donnant plus de pouvoir aux elus locaux.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000086', 'Transfert de pouvoirs vers les collectivites locales (1982)', TRUE, 0),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000086', 'Suppression de l''Etat', FALSE, 1),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000086', 'Independance des regions', FALSE, 2),
(gen_random_uuid(), 'f4000002-0000-0000-0000-000000000086', 'Aucune reforme territoriale', FALSE, 3);
