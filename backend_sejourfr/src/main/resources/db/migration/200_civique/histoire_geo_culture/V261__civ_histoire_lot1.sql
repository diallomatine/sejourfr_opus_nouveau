-- ============================================================================
-- V261 — Civique : Histoire, géo, culture (lot 1)
-- ----------------------------------------------------------------------------
-- Questions + choix. Filtre: 11111111-0000-0000-0000-000000000004 .
-- Données régénérées depuis l'état final (déterministe, rejouable dev+recette).
-- ============================================================================

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('f4000000-0000-0000-0000-000000000001', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'En quelle année a débuté la Révolution française ?',
   'La Révolution française débute en 1789. La prise de la Bastille a lieu le 14 juillet 1789.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000000-0000-0000-0000-000000000002', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Qui était Napoléon Ier ?',
   'Napoléon Bonaparte (1769-1821) fut empereur des Français de 1804 à 1814 puis en 1815. Il a réorganisé l''État (Code civil, préfets, lycées) et conquis une grande partie de l''Europe.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000000-0000-0000-0000-000000000003', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Lequel de ces personnages historiques est français ?',
   'Jeanne d''Arc (1412-1431), originaire de Domrémy, est une figure majeure de l''histoire de France. Elle a contribué à libérer la France pendant la guerre de Cent Ans.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000000-0000-0000-0000-000000000004', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Dans quelle République est-on aujourd''hui ?',
   'Nous sommes sous la Ve République, fondée en 1958 par Charles de Gaulle.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000000-0000-0000-0000-000000000005', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Qu''est-ce que la Shoah ?',
   'La Shoah est le génocide des Juifs d''Europe par l''Allemagne nazie pendant la Seconde Guerre mondiale (1939-1945). Six millions de Juifs ont été exterminés.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000000-0000-0000-0000-000000000006', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quel pays ou région du monde a été colonisé par la France ?',
   'L''Algérie, la Tunisie, le Maroc, le Sénégal, le Mali, l''Indochine et de nombreux autres pays d''Afrique et d''Asie ont été colonisés par la France entre le XVIIe et le XXe siècle.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000000-0000-0000-0000-000000000007', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Qui a rendu l''école gratuite, laïque et obligatoire ?',
   'Jules Ferry, ministre de l''Instruction publique, a fait voter les lois rendant l''école gratuite (1881), obligatoire et laïque (1882).',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000000-0000-0000-0000-000000000008', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quand a eu lieu la Seconde Guerre mondiale ?',
   'La Seconde Guerre mondiale s''est déroulée de 1939 à 1945. Elle a opposé les Alliés (dont la France libre) à l''Axe (Allemagne nazie, Italie, Japon).',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000000-0000-0000-0000-000000000009', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quand a eu lieu la Première Guerre mondiale ?',
   'La Première Guerre mondiale s''est déroulée de 1914 à 1918. Elle s''est terminée par l''armistice signé le 11 novembre 1918.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000000-0000-0000-0000-00000000000a', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'En quelle année a été créée la Communauté Économique Européenne (CEE) ?',
   'La CEE a été créée en 1957 par le traité de Rome, signé par 6 pays fondateurs : France, Allemagne, Italie, Belgique, Pays-Bas, Luxembourg. Elle est devenue l''Union européenne en 1993.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000000-0000-0000-0000-00000000000b', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Le 11 novembre est un jour férié. À quoi correspond cette date ?',
   'Le 11 novembre commémore l''armistice de 1918, qui a mis fin à la Première Guerre mondiale, et rend hommage aux soldats morts pour la France.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000000-0000-0000-0000-00000000000c', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Qui a été le premier Président élu sous la Ve République ?',
   'Charles de Gaulle a été le premier président de la Ve République, élu en 1958 (par les grands électeurs) puis réélu en 1965 au suffrage universel direct.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000000-0000-0000-0000-00000000000d', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'En quelle année l''esclavage a-t-il été aboli définitivement en France ?',
   'L''esclavage a été aboli définitivement en France le 27 avril 1848, sous l''impulsion de Victor Schœlcher. Il avait déjà été aboli une première fois en 1794, puis rétabli par Napoléon en 1802.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000000-0000-0000-0000-00000000000e', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Depuis quelle année l''école publique est-elle gratuite ?',
   'L''école publique est gratuite depuis 1881, grâce à la loi Jules Ferry. L''instruction est devenue obligatoire et laïque en 1882.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000000-0000-0000-0000-00000000000f', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Combien y a-t-il eu de républiques en France ?',
   'La France a connu cinq républiques : Ire (1792), IIe (1848), IIIe (1870), IVe (1946), Ve (1958, actuelle).',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000000-0000-0000-0000-000000000010', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Qui était le roi de France au moment de la Révolution française ?',
   'Louis XVI était roi de France au début de la Révolution. Il a été guillotiné le 21 janvier 1793, marquant la fin de la monarchie.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000000-0000-0000-0000-000000000011', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Qui a fondé la Ve République ?',
   'Charles de Gaulle a fondé la Ve République en 1958, en rédigeant une nouvelle Constitution adoptée par référendum.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000000-0000-0000-0000-000000000012', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Que célèbre-t-on le 14 juillet ?',
   'Le 14 juillet, fête nationale, commémore la prise de la Bastille (14 juillet 1789), symbole de la Révolution française.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000000-0000-0000-0000-000000000013', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quelle guerre a eu lieu entre 1914 et 1918 ?',
   'La Première Guerre mondiale (Grande Guerre) s''est déroulée de 1914 à 1918. Elle a opposé principalement la France, le Royaume-Uni et la Russie à l''Allemagne et l''Autriche-Hongrie.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000000-0000-0000-0000-000000000014', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Pourquoi l''année 1958 est importante pour la France ?',
   'En 1958, la Ve République est fondée avec l''adoption de la nouvelle Constitution (4 octobre 1958), et Charles de Gaulle revient au pouvoir.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000000-0000-0000-0000-000000000015', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quel fleuve coule en France ?',
   'La Seine, la Loire, le Rhône et la Garonne sont les principaux fleuves français. La Seine traverse Paris.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000000-0000-0000-0000-000000000016', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quelle ville est française ?',
   'Lyon, Marseille, Paris, Bordeaux, Toulouse, Lille, Strasbourg, Nantes... sont les grandes villes françaises.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000000-0000-0000-0000-000000000017', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quel océan borde la côte ouest française ?',
   'L''océan Atlantique borde la côte ouest de la France. La côte sud est bordée par la mer Méditerranée.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000000-0000-0000-0000-000000000018', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Qu''est-ce que Paris ?',
   'Paris est la capitale de la France. C''est le siège du gouvernement, du Parlement et la plus grande ville du pays.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000000-0000-0000-0000-000000000019', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quelle est la capitale de la France ?',
   'Paris est la capitale de la France depuis le Moyen Âge. C''est la plus grande ville de France avec plus de 2 millions d''habitants.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000000-0000-0000-0000-00000000001a', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Sur quel continent se situe la France métropolitaine ?',
   'La France métropolitaine est située sur le continent européen, dans l''ouest de l''Europe.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000000-0000-0000-0000-00000000001b', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quelle île est un département d''outre-mer français ?',
   'La Guadeloupe, la Martinique, La Réunion et Mayotte sont les îles départements d''outre-mer. La Guyane est aussi un DOM mais sur le continent sud-américain.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000000-0000-0000-0000-00000000001c', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Combien y a-t-il de régions en France métropolitaine ?',
   'La France métropolitaine compte 13 régions depuis la réforme territoriale de 2016. Avec les 5 régions d''outre-mer, la France compte 18 régions au total.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000000-0000-0000-0000-00000000001d', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quelle ville est un grand port maritime ?',
   'Marseille est le premier port maritime de France et un des plus grands de Méditerranée. Le Havre, Dunkerque et Bordeaux sont aussi des grands ports.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000000-0000-0000-0000-00000000001e', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quelle est la mer au sud de la France métropolitaine ?',
   'La mer Méditerranée borde le sud de la France, de la frontière espagnole à la frontière italienne, en passant par Marseille, Nice et la Côte d''Azur.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000000-0000-0000-0000-00000000001f', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quelle ville est située au bord de la mer Méditerranée ?',
   'Marseille, Nice, Toulon, Montpellier... Plusieurs grandes villes françaises sont situées sur la côte méditerranéenne.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000000-0000-0000-0000-000000000020', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Où se situe la Corse ?',
   'La Corse est une île française située en mer Méditerranée, au sud de la France métropolitaine, à l''ouest de l''Italie.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000000-0000-0000-0000-000000000021', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quelle chaîne de montagnes est située entre la France et l''Italie ?',
   'Les Alpes séparent la France de l''Italie. Le point culminant est le mont Blanc (4 808 m), plus haut sommet d''Europe occidentale.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000000-0000-0000-0000-000000000022', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Qui était Molière ?',
   'Molière (1622-1673) était un dramaturge et comédien français du XVIIe siècle. Il est l''auteur de comédies célèbres comme "L''Avare", "Le Misanthrope", "Tartuffe".',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000000-0000-0000-0000-000000000023', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Qui était Charles Baudelaire ?',
   'Charles Baudelaire (1821-1867) est un poète français majeur du XIXe siècle, auteur des "Fleurs du Mal" (1857).',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000000-0000-0000-0000-000000000024', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Qui était George Sand ?',
   'George Sand (1804-1876, vrai nom Aurore Dupin) était une romancière française du XIXe siècle. Elle est connue pour ses romans (La Mare au Diable, La Petite Fadette) et son engagement social.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000000-0000-0000-0000-000000000025', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Qui était Simone de Beauvoir ?',
   'Simone de Beauvoir (1908-1986) était une philosophe, romancière et figure du féminisme français. Auteure du "Deuxième Sexe" (1949), texte fondateur du féminisme contemporain.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000000-0000-0000-0000-000000000026', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Qui était Albert Camus ?',
   'Albert Camus (1913-1960) était un écrivain et philosophe français, né en Algérie. Prix Nobel de littérature en 1957, auteur de "L''Étranger", "La Peste".',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000000-0000-0000-0000-000000000027', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Qui était Paul Cézanne ?',
   'Paul Cézanne (1839-1906) était un peintre français post-impressionniste, originaire d''Aix-en-Provence. Considéré comme l''un des plus grands peintres modernes.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000000-0000-0000-0000-000000000028', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Qui était Marc Chagall ?',
   'Marc Chagall (1887-1985) était un peintre français d''origine russe, l''un des plus grands artistes du XXe siècle. Il a notamment peint le plafond de l''Opéra Garnier de Paris.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000000-0000-0000-0000-000000000029', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Qui était Joséphine Baker ?',
   'Joséphine Baker (1906-1975) était une artiste franco-américaine, danseuse et chanteuse, mais aussi résistante pendant la Seconde Guerre mondiale. Entrée au Panthéon en 2021.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000000-0000-0000-0000-00000000002a', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Qui était une chanteuse française célèbre ?',
   'Édith Piaf (1915-1963) est une icône de la chanson française. Ses chansons "La Vie en rose", "Non, je ne regrette rien" sont mondialement célèbres.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000000-0000-0000-0000-00000000002b', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Qu''est-ce que le Louvre ?',
   'Le Louvre est l''un des plus grands musées du monde, situé à Paris. Il abrite des œuvres majeures comme la Joconde, la Vénus de Milo, la Victoire de Samothrace.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000000-0000-0000-0000-00000000002c', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Qui était Jean de La Fontaine ?',
   'Jean de La Fontaine (1621-1695) était un poète français du XVIIe siècle, célèbre pour ses Fables ("Le Corbeau et le Renard", "La Cigale et la Fourmi"...).',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000000-0000-0000-0000-00000000002d', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quel écrivain est français ?',
   'Victor Hugo (1802-1885) est l''un des plus grands écrivains français. Auteur des "Misérables", "Notre-Dame de Paris", il fut aussi homme politique et défenseur des droits humains.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000000-0000-0000-0000-00000000002e', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Dans quelle ville se trouve la tour Eiffel ?',
   'La tour Eiffel se trouve à Paris, sur le Champ-de-Mars. Construite par Gustave Eiffel pour l''Exposition universelle de 1889.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000000-0000-0000-0000-00000000002f', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quand célèbre-t-on Noël ?',
   'Noël est célébré le 25 décembre. C''est une fête chrétienne, mais aussi un jour férié en France et une fête familiale célébrée par beaucoup de Français quelle que soit leur religion.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000001-0000-0000-0000-000000000001', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'En quelle année a commencé la Révolution française ?',
   'La Révolution française a commencé en 1789, marquée par la prise de la Bastille le 14 juillet 1789 et la Déclaration des droits de l''homme et du citoyen le 26 août 1789.',
   'true', '2026-05-27 17:40:29.994036+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000001-0000-0000-0000-000000000002', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Qui était Napoléon Bonaparte (Napoléon Ier) ?',
   'Napoléon Bonaparte (1769-1821) fut un général puis empereur des Français (1804-1814 et 1815). Il a rédigé le Code civil, conquis l''Europe et a marqué profondément l''histoire de France.',
   'true', '2026-05-27 17:40:29.994036+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000001-0000-0000-0000-000000000003', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Parmi ces personnages historiques, lequel est français ?',
   'Plusieurs personnages français célèbres : Jeanne d''Arc (héroïne du XVe siècle), Napoléon Bonaparte, Charles de Gaulle, Marie Curie (scientifique). Tous ont marqué l''histoire de France.',
   'true', '2026-05-27 17:40:29.994036+02', NULL, 'ACTIVE', NULL, NULL, NULL);

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('c43539f2-886e-42fa-b480-fb14247f5cbd', 'f4000000-0000-0000-0000-000000000001',
   '1789',
   'true', '0'),

  ('83c69d54-8ff6-4877-a7e1-66576d119ab0', 'f4000000-0000-0000-0000-000000000001',
   '1689',
   'false', '1'),

  ('1f054950-ce2b-415e-beb9-640529b560d9', 'f4000000-0000-0000-0000-000000000001',
   '1848',
   'false', '2'),

  ('372fa9f8-848a-42c5-b48f-aa96e6298e75', 'f4000000-0000-0000-0000-000000000001',
   '1914',
   'false', '3'),

  ('e490b746-f18b-41ef-80ff-bf290d9cce2f', 'f4000000-0000-0000-0000-000000000002',
   'Un empereur français (début du XIXe siècle)',
   'true', '0'),

  ('b468cd15-59ef-4481-a600-534fd8442deb', 'f4000000-0000-0000-0000-000000000002',
   'Un roi du Moyen Âge',
   'false', '1'),

  ('66964a4a-e0ea-4486-85ca-8438a3ba721b', 'f4000000-0000-0000-0000-000000000002',
   'Un président de la Ve République',
   'false', '2'),

  ('1340ccd5-88b8-4b83-b3a7-e128b1b46c94', 'f4000000-0000-0000-0000-000000000002',
   'Un philosophe des Lumières',
   'false', '3'),

  ('a1cde56f-560f-4b39-a218-d25f0cc7cc4f', 'f4000000-0000-0000-0000-000000000003',
   'Jeanne d''Arc',
   'true', '0'),

  ('b63f34e6-50ae-47e8-b59d-157aa838995b', 'f4000000-0000-0000-0000-000000000003',
   'Winston Churchill',
   'false', '1'),

  ('86d2941a-8e3d-4975-8d8d-ac0ddd966271', 'f4000000-0000-0000-0000-000000000003',
   'George Washington',
   'false', '2'),

  ('3fa65ab5-1fcd-414c-8cfb-8116e840b699', 'f4000000-0000-0000-0000-000000000003',
   'Christophe Colomb',
   'false', '3'),

  ('e00fdbe0-1e04-4fac-908e-f3ac6cd17d1e', 'f4000000-0000-0000-0000-000000000004',
   'La Ve République',
   'true', '0'),

  ('54402122-bd7e-4b2e-96a0-009a7be64d86', 'f4000000-0000-0000-0000-000000000004',
   'La IIIe République',
   'false', '1'),

  ('61c013e1-3072-48c3-9e2c-a841fa913267', 'f4000000-0000-0000-0000-000000000004',
   'La IVe République',
   'false', '2'),

  ('4b26527e-86ac-4247-a353-60dbcdf67510', 'f4000000-0000-0000-0000-000000000004',
   'La VIe République',
   'false', '3'),

  ('a9b5e026-8b73-4dd3-a406-e90894b42c35', 'f4000000-0000-0000-0000-000000000005',
   'Le génocide des Juifs par les nazis (1939-1945)',
   'true', '0'),

  ('35860e13-359c-4e27-9315-791b0ac6a0b8', 'f4000000-0000-0000-0000-000000000005',
   'Une bataille de la Première Guerre mondiale',
   'false', '1'),

  ('09060e4d-9e88-4123-a07a-01901cbf2ea6', 'f4000000-0000-0000-0000-000000000005',
   'Une révolution européenne',
   'false', '2'),

  ('4cb4e41d-aa9d-49ee-9859-ae93b69d9457', 'f4000000-0000-0000-0000-000000000005',
   'Une fête religieuse',
   'false', '3'),

  ('bfba7097-0473-4e6b-afe2-68b36947485e', 'f4000000-0000-0000-0000-000000000006',
   'L''Algérie',
   'true', '0'),

  ('f73b3a82-527f-435f-9361-281d319c245a', 'f4000000-0000-0000-0000-000000000006',
   'La Suède',
   'false', '1'),

  ('f132870c-69d7-45a1-97f0-09d63aaf0058', 'f4000000-0000-0000-0000-000000000006',
   'Le Brésil',
   'false', '2'),

  ('c4f5199a-065f-40ec-b927-db94653556ea', 'f4000000-0000-0000-0000-000000000006',
   'L''Australie',
   'false', '3'),

  ('2164262c-6412-482f-b2f2-ca6a99db6788', 'f4000000-0000-0000-0000-000000000007',
   'Jules Ferry',
   'true', '0'),

  ('34d4df3e-8d85-4333-ac4d-2c623ab515e8', 'f4000000-0000-0000-0000-000000000007',
   'Charles de Gaulle',
   'false', '1'),

  ('dbad1a65-6999-4e79-89ba-f6d17cb55d29', 'f4000000-0000-0000-0000-000000000007',
   'Napoléon Bonaparte',
   'false', '2'),

  ('1fc24275-5226-443e-9ea2-78e7754faa5f', 'f4000000-0000-0000-0000-000000000007',
   'François Mitterrand',
   'false', '3'),

  ('76f7b9bd-6660-44e7-8dbe-8680f27d3b45', 'f4000000-0000-0000-0000-000000000008',
   '1939-1945',
   'true', '0'),

  ('eeb10071-d89c-4025-9a2d-98f1248b0612', 'f4000000-0000-0000-0000-000000000008',
   '1914-1918',
   'false', '1'),

  ('190b6b59-6056-477d-9d32-9552e5ef1c20', 'f4000000-0000-0000-0000-000000000008',
   '1945-1950',
   'false', '2'),

  ('46b0b2ef-ee19-497a-b26b-417cf02b9e62', 'f4000000-0000-0000-0000-000000000008',
   '1789-1799',
   'false', '3'),

  ('28a433ad-76be-4d66-a34d-07286c0e9321', 'f4000000-0000-0000-0000-000000000009',
   '1914-1918',
   'true', '0'),

  ('57154a48-d04a-459e-b8b8-ed7a5fdbe2a0', 'f4000000-0000-0000-0000-000000000009',
   '1939-1945',
   'false', '1'),

  ('4c7e156c-b43a-425e-b9f8-dfb9e9adf9a5', 'f4000000-0000-0000-0000-000000000009',
   '1870-1871',
   'false', '2'),

  ('62d70614-d9bd-495a-b992-4da7ec976bf7', 'f4000000-0000-0000-0000-000000000009',
   '1789-1799',
   'false', '3'),

  ('0e0063fa-acb9-4498-99f5-24a458a13657', 'f4000000-0000-0000-0000-00000000000a',
   '1957',
   'true', '0'),

  ('d72cf222-4417-4c4e-ae57-1ce331706ddb', 'f4000000-0000-0000-0000-00000000000a',
   '1945',
   'false', '1'),

  ('47dc9859-afbb-40e9-bc59-819007421858', 'f4000000-0000-0000-0000-00000000000a',
   '1989',
   'false', '2'),

  ('bb721714-3dd2-4aec-a3cb-36ad7e352f74', 'f4000000-0000-0000-0000-00000000000a',
   '2002',
   'false', '3'),

  ('9d32bffd-94e8-44e8-b3bc-b7e1b3a03935', 'f4000000-0000-0000-0000-00000000000b',
   'L''armistice de 1918 (fin de la Première Guerre mondiale)',
   'true', '0'),

  ('664cf5db-ef94-4063-88ff-6214bcc13b7f', 'f4000000-0000-0000-0000-00000000000b',
   'La fin de la Seconde Guerre mondiale',
   'false', '1'),

  ('ca9fbc7b-9d2d-4ac9-b028-d72218de828f', 'f4000000-0000-0000-0000-00000000000b',
   'La fête nationale',
   'false', '2'),

  ('f0955fb9-1e95-4f76-bafe-76c919fe76e2', 'f4000000-0000-0000-0000-00000000000b',
   'La fête de la République',
   'false', '3'),

  ('f3a6dbb1-bffd-4dbf-8b44-a42a2e403c67', 'f4000000-0000-0000-0000-00000000000c',
   'Charles de Gaulle',
   'true', '0'),

  ('c7e0176c-af24-48d1-b073-084fd001732c', 'f4000000-0000-0000-0000-00000000000c',
   'François Mitterrand',
   'false', '1'),

  ('5535ef5f-28a9-4d22-866b-b12bbd9fb2d7', 'f4000000-0000-0000-0000-00000000000c',
   'Georges Pompidou',
   'false', '2'),

  ('814386bf-9049-4771-9844-716d96ba25ec', 'f4000000-0000-0000-0000-00000000000c',
   'Jacques Chirac',
   'false', '3'),

  ('7ad3fe7a-a00e-4aa0-b406-2926a87a9ec5', 'f4000000-0000-0000-0000-00000000000d',
   '1848',
   'true', '0'),

  ('ee0d9914-876e-420b-987b-3d92af161268', 'f4000000-0000-0000-0000-00000000000d',
   '1789',
   'false', '1'),

  ('63b346ea-a25c-4e13-a2af-b77bba72ce21', 'f4000000-0000-0000-0000-00000000000d',
   '1905',
   'false', '2'),

  ('88762ce4-2c0b-4aa9-b6b0-5c7d8cf40cef', 'f4000000-0000-0000-0000-00000000000d',
   '1945',
   'false', '3'),

  ('34add527-3d94-4698-adfb-9dfb5e6077fb', 'f4000000-0000-0000-0000-00000000000e',
   '1881',
   'true', '0'),

  ('bee60bd3-4595-4671-b3ed-abe103e949bd', 'f4000000-0000-0000-0000-00000000000e',
   '1789',
   'false', '1'),

  ('c02ff740-78b2-439f-8232-ad59f036e497', 'f4000000-0000-0000-0000-00000000000e',
   '1905',
   'false', '2'),

  ('939bd1a5-beb2-4c93-9493-cbf304fe5908', 'f4000000-0000-0000-0000-00000000000e',
   '1968',
   'false', '3'),

  ('fb4d73eb-4ae8-42cd-8d8f-e3b1bdac27f9', 'f4000000-0000-0000-0000-00000000000f',
   '5 républiques',
   'true', '0'),

  ('959181fd-d18e-4c95-ac5f-00e33b80af7b', 'f4000000-0000-0000-0000-00000000000f',
   '3 républiques',
   'false', '1'),

  ('ee64ef3d-a054-4d59-8e20-d065ea588245', 'f4000000-0000-0000-0000-00000000000f',
   '1 seule république',
   'false', '2'),

  ('89508832-741f-4827-82a7-c40252c9fb9e', 'f4000000-0000-0000-0000-00000000000f',
   '10 républiques',
   'false', '3'),

  ('c458863c-baa6-4d8b-ac4f-6236d435c9bc', 'f4000000-0000-0000-0000-000000000010',
   'Louis XVI',
   'true', '0'),

  ('4c851a2e-e9ee-43a5-b561-c9ea9d3a426b', 'f4000000-0000-0000-0000-000000000010',
   'Louis XIV (le Roi-Soleil)',
   'false', '1'),

  ('35b22f35-afb7-4db2-a9c7-43aff94fa391', 'f4000000-0000-0000-0000-000000000010',
   'Napoléon Ier',
   'false', '2'),

  ('8ca48c19-4f1a-4303-842d-7c218d56626e', 'f4000000-0000-0000-0000-000000000010',
   'Henri IV',
   'false', '3'),

  ('905e0437-8708-472f-a9ad-5b696b29e8db', 'f4000000-0000-0000-0000-000000000011',
   'Charles de Gaulle',
   'true', '0'),

  ('901351b6-e1dc-4ebf-9563-33d93c520d37', 'f4000000-0000-0000-0000-000000000011',
   'Napoléon III',
   'false', '1'),

  ('c03aa605-e60f-42ca-b257-1caf76a10c8f', 'f4000000-0000-0000-0000-000000000011',
   'Jules Ferry',
   'false', '2'),

  ('a20d72ef-39c6-4513-a8a2-e939f30a611d', 'f4000000-0000-0000-0000-000000000011',
   'François Mitterrand',
   'false', '3'),

  ('2ba01384-6153-4ee6-a5a1-990869327754', 'f4000000-0000-0000-0000-000000000012',
   'La fête nationale (prise de la Bastille 1789)',
   'true', '0'),

  ('b0ad1f6f-08dd-4cfb-beb7-f8e3d5d7a0f6', 'f4000000-0000-0000-0000-000000000012',
   'La fin de la Seconde Guerre mondiale',
   'false', '1'),

  ('77f977ae-4b9b-4ef2-9730-9dc995dee774', 'f4000000-0000-0000-0000-000000000012',
   'La fête des Mères',
   'false', '2'),

  ('85683955-facb-468f-89f0-7af1379c8bb8', 'f4000000-0000-0000-0000-000000000012',
   'L''anniversaire du président',
   'false', '3'),

  ('30739b66-f2c1-446c-9f59-6ebe316a7d0c', 'f4000000-0000-0000-0000-000000000013',
   'La Première Guerre mondiale',
   'true', '0'),

  ('a6b92dba-e044-45f2-8c4a-6d2a58644d72', 'f4000000-0000-0000-0000-000000000013',
   'La Seconde Guerre mondiale',
   'false', '1'),

  ('675ba20a-d353-45fc-909b-3da7cbba4a45', 'f4000000-0000-0000-0000-000000000013',
   'La guerre d''Algérie',
   'false', '2'),

  ('c44bbf0c-3557-4fce-a2e4-cdba0594583f', 'f4000000-0000-0000-0000-000000000013',
   'La guerre de Cent Ans',
   'false', '3'),

  ('08751120-25d8-48b6-a4a8-5921bbee5e09', 'f4000000-0000-0000-0000-000000000014',
   'Fondation de la Ve République',
   'true', '0'),

  ('24a9a4a1-de89-4261-bcf3-6ad1f29d6bb1', 'f4000000-0000-0000-0000-000000000014',
   'Début de la Première Guerre mondiale',
   'false', '1'),

  ('e0eee20f-bab0-487c-be58-a4c041d115f9', 'f4000000-0000-0000-0000-000000000014',
   'Indépendance de la France',
   'false', '2'),

  ('c16c5b28-a053-4381-90aa-6881bae386cc', 'f4000000-0000-0000-0000-000000000014',
   'Abolition de l''esclavage',
   'false', '3'),

  ('83c24c1b-1989-45c5-9350-337b26dfc8af', 'f4000000-0000-0000-0000-000000000015',
   'La Seine',
   'true', '0'),

  ('257a118e-6e6b-42bd-80cd-fe44e4629611', 'f4000000-0000-0000-0000-000000000015',
   'L''Amazone',
   'false', '1'),

  ('a5ca0a7a-cad1-4331-8d3c-56a02e72c2c1', 'f4000000-0000-0000-0000-000000000015',
   'Le Nil',
   'false', '2'),

  ('bb42b16b-4084-49a1-990b-0b6188cbd099', 'f4000000-0000-0000-0000-000000000015',
   'Le Mississippi',
   'false', '3'),

  ('95388f85-7618-4610-9f64-d30827bb3b88', 'f4000000-0000-0000-0000-000000000016',
   'Lyon',
   'true', '0'),

  ('19710ff4-3e2d-433f-85c2-dcfbd865495a', 'f4000000-0000-0000-0000-000000000016',
   'Madrid',
   'false', '1'),

  ('2c7247dc-d618-4bde-81a9-7d195cd87cc7', 'f4000000-0000-0000-0000-000000000016',
   'Berlin',
   'false', '2'),

  ('c3f3dd79-2e9e-45df-a373-18dd9c510512', 'f4000000-0000-0000-0000-000000000016',
   'Rome',
   'false', '3'),

  ('1e70b8f9-d6ac-4e72-8278-3685f00a696c', 'f4000000-0000-0000-0000-000000000017',
   'L''océan Atlantique',
   'true', '0'),

  ('2cbdf731-18eb-4219-bccb-f7350806a0c2', 'f4000000-0000-0000-0000-000000000017',
   'L''océan Pacifique',
   'false', '1'),

  ('fd4b27d4-a112-4a90-914b-c6a273c9d6f6', 'f4000000-0000-0000-0000-000000000017',
   'L''océan Indien',
   'false', '2'),

  ('137be0e7-26f0-4df5-b56e-b63e6accbcdf', 'f4000000-0000-0000-0000-000000000017',
   'L''océan Arctique',
   'false', '3'),

  ('4d824569-01be-4adb-b0f6-0bc46c39d3c2', 'f4000000-0000-0000-0000-000000000018',
   'La capitale de la France',
   'true', '0'),

  ('8671f1ce-7828-4bdd-afff-0ffac171af42', 'f4000000-0000-0000-0000-000000000018',
   'Un département d''outre-mer',
   'false', '1'),

  ('bef84ba5-5db5-4d67-bb17-b3de5e61b812', 'f4000000-0000-0000-0000-000000000018',
   'Un fleuve',
   'false', '2'),

  ('23e5aed9-84f8-4ba5-9086-ea03aa376220', 'f4000000-0000-0000-0000-000000000018',
   'Une chaîne de montagnes',
   'false', '3'),

  ('303a954e-1c2c-4b28-88b2-dc0cd97bf93c', 'f4000000-0000-0000-0000-000000000019',
   'Paris',
   'true', '0'),

  ('819b0305-eb9b-43cd-b621-ffa207913399', 'f4000000-0000-0000-0000-000000000019',
   'Lyon',
   'false', '1'),

  ('654cf1d2-b47d-471d-9c1c-a3f9503449a5', 'f4000000-0000-0000-0000-000000000019',
   'Marseille',
   'false', '2'),

  ('63483b32-b8fe-4f38-8f9c-67534f203f0c', 'f4000000-0000-0000-0000-000000000019',
   'Bordeaux',
   'false', '3'),

  ('8c6e2bfd-8945-4beb-a9cb-7d5a05151d23', 'f4000000-0000-0000-0000-00000000001a',
   'L''Europe',
   'true', '0'),

  ('82d6cd61-fdef-4c31-9396-56ebaef5ed26', 'f4000000-0000-0000-0000-00000000001a',
   'L''Afrique',
   'false', '1'),

  ('90177ce8-d56e-4cd8-a720-c7f11af8537d', 'f4000000-0000-0000-0000-00000000001a',
   'L''Asie',
   'false', '2'),

  ('fb10ac31-9ebe-46c5-b59b-4c065f5ba6e3', 'f4000000-0000-0000-0000-00000000001a',
   'L''Amérique',
   'false', '3'),

  ('0f3ec5ac-31f6-4da3-bbd5-4b7a0744774e', 'f4000000-0000-0000-0000-00000000001b',
   'La Réunion',
   'true', '0'),

  ('81134048-ad6e-4cbe-b242-c3e6843a4987', 'f4000000-0000-0000-0000-00000000001b',
   'Madagascar',
   'false', '1'),

  ('a9af762d-7c76-4cd1-acec-a0bac65332df', 'f4000000-0000-0000-0000-00000000001b',
   'L''Islande',
   'false', '2'),

  ('2db8dc09-3cb3-4aa9-a2a9-056b4010b279', 'f4000000-0000-0000-0000-00000000001b',
   'Cuba',
   'false', '3'),

  ('2f410132-8863-4017-9abd-21aded5cb635', 'f4000000-0000-0000-0000-00000000001c',
   '13 régions',
   'true', '0'),

  ('745233bb-0004-4a9e-aae4-2377a69e5103', 'f4000000-0000-0000-0000-00000000001c',
   '22 régions',
   'false', '1'),

  ('c15230ab-50c3-4a88-a49d-ca189e147fe9', 'f4000000-0000-0000-0000-00000000001c',
   '101 régions',
   'false', '2'),

  ('13368265-9016-4796-8e80-a9d22446f5c4', 'f4000000-0000-0000-0000-00000000001c',
   '6 régions',
   'false', '3'),

  ('db22f69e-7c8a-4d0b-9713-a3da7737131c', 'f4000000-0000-0000-0000-00000000001d',
   'Marseille',
   'true', '0'),

  ('6f6b5235-6b91-46ba-bac4-7688fb9a7325', 'f4000000-0000-0000-0000-00000000001d',
   'Lyon',
   'false', '1'),

  ('3ca72e1e-2a95-40b7-8f96-e46a84623fb8', 'f4000000-0000-0000-0000-00000000001d',
   'Strasbourg',
   'false', '2'),

  ('606eb66b-a84e-4682-a1fe-f8ce9522779b', 'f4000000-0000-0000-0000-00000000001d',
   'Toulouse',
   'false', '3'),

  ('fe4917f5-b1e4-41b0-8ffc-b669f1aa174d', 'f4000000-0000-0000-0000-00000000001e',
   'La Méditerranée',
   'true', '0'),

  ('434cbbc1-c78b-425e-8135-3f75b13da97f', 'f4000000-0000-0000-0000-00000000001e',
   'La mer du Nord',
   'false', '1'),

  ('407077a2-bad0-4537-a760-34b131d66e4a', 'f4000000-0000-0000-0000-00000000001e',
   'La mer Baltique',
   'false', '2'),

  ('7590ec10-8339-4e0b-b1f2-bd2254dedb68', 'f4000000-0000-0000-0000-00000000001e',
   'La mer Caspienne',
   'false', '3'),

  ('3d558915-ea09-4480-b1d5-00737d39e1f0', 'f4000000-0000-0000-0000-00000000001f',
   'Marseille',
   'true', '0'),

  ('12dbe455-8356-415f-8531-650d9d929b1d', 'f4000000-0000-0000-0000-00000000001f',
   'Lille',
   'false', '1'),

  ('a684242f-d38d-4982-872b-2b3ab2e676e3', 'f4000000-0000-0000-0000-00000000001f',
   'Strasbourg',
   'false', '2'),

  ('cb79fba5-11e7-41ee-8ad2-ae482c0aaeea', 'f4000000-0000-0000-0000-00000000001f',
   'Rennes',
   'false', '3'),

  ('b72fad61-d44c-42d0-8a24-81469828bb32', 'f4000000-0000-0000-0000-000000000020',
   'En mer Méditerranée',
   'true', '0'),

  ('d90e5c78-8bac-49ed-abbb-0a27a38b1426', 'f4000000-0000-0000-0000-000000000020',
   'Dans l''océan Atlantique',
   'false', '1'),

  ('bfdec047-e721-4798-8f6e-329a098b782f', 'f4000000-0000-0000-0000-000000000020',
   'En Manche',
   'false', '2'),

  ('2c5af1bf-ec70-48b7-80bb-29978d4cc046', 'f4000000-0000-0000-0000-000000000020',
   'Dans la mer du Nord',
   'false', '3'),

  ('c4bfee85-f346-44a7-9e2c-6bd9c48e1f1a', 'f4000000-0000-0000-0000-000000000021',
   'Les Alpes',
   'true', '0'),

  ('f47a18a6-d9db-426a-b0aa-cbf602ca68db', 'f4000000-0000-0000-0000-000000000021',
   'Les Pyrénées',
   'false', '1'),

  ('74ec3f35-d444-4d5f-b6a7-8d0a68ce1af7', 'f4000000-0000-0000-0000-000000000021',
   'Le Massif central',
   'false', '2'),

  ('f69941f4-a496-4436-a04f-49dae5c99920', 'f4000000-0000-0000-0000-000000000021',
   'Les Vosges',
   'false', '3'),

  ('d8e26580-5a23-4fa8-a105-32ee0b63b9b1', 'f4000000-0000-0000-0000-000000000022',
   'Un dramaturge français du XVIIe siècle',
   'true', '0'),

  ('af165b68-48a4-4195-8fab-86c2787c7a1c', 'f4000000-0000-0000-0000-000000000022',
   'Un peintre italien',
   'false', '1'),

  ('3a6faa01-a092-43ee-b582-1cf15121b49a', 'f4000000-0000-0000-0000-000000000022',
   'Un explorateur portugais',
   'false', '2'),

  ('6f367415-fd8b-4f85-95c7-deee225045a9', 'f4000000-0000-0000-0000-000000000022',
   'Un compositeur allemand',
   'false', '3'),

  ('08d098c6-faab-411b-ae05-6b3b79625314', 'f4000000-0000-0000-0000-000000000023',
   'Un poète français (XIXe siècle)',
   'true', '0'),

  ('e9bc9cf3-f727-4de1-9e83-b52b85b29173', 'f4000000-0000-0000-0000-000000000023',
   'Un peintre impressionniste',
   'false', '1'),

  ('21aa11e2-07e3-4a0f-ba5b-2c5bfdba712e', 'f4000000-0000-0000-0000-000000000023',
   'Un scientifique',
   'false', '2'),

  ('0e4085b5-25f1-427a-b210-e284fd03c50a', 'f4000000-0000-0000-0000-000000000023',
   'Un homme politique',
   'false', '3'),

  ('8d129b76-0298-4851-84f7-a6fee1b91a74', 'f4000000-0000-0000-0000-000000000024',
   'Une romancière française du XIXe siècle',
   'true', '0'),

  ('63074159-6def-4bad-bffe-300c2f837b9f', 'f4000000-0000-0000-0000-000000000024',
   'Une chanteuse américaine',
   'false', '1'),

  ('573325ef-b12b-4297-a614-049753f68c86', 'f4000000-0000-0000-0000-000000000024',
   'Une reine d''Angleterre',
   'false', '2'),

  ('d52bd6b6-048d-429e-b16e-b62291ee8a8e', 'f4000000-0000-0000-0000-000000000024',
   'Une cinéaste italienne',
   'false', '3'),

  ('251ad147-b406-4b1c-b895-c05af74f9625', 'f4000000-0000-0000-0000-000000000025',
   'Une philosophe et romancière française, figure du féminisme',
   'true', '0'),

  ('25f21a88-314e-4125-a9b1-cbda84fd7399', 'f4000000-0000-0000-0000-000000000025',
   'Une danseuse de l''Opéra',
   'false', '1'),

  ('c7c295c9-825a-4e75-b8ae-b2949c1a78d6', 'f4000000-0000-0000-0000-000000000025',
   'Une chimiste belge',
   'false', '2'),

  ('f5167721-df1c-4d10-8f80-40668e117cf3', 'f4000000-0000-0000-0000-000000000025',
   'Une exploratrice polaire',
   'false', '3'),

  ('5bc65d37-9f42-4480-bddc-cad96bd89498', 'f4000000-0000-0000-0000-000000000026',
   'Un écrivain français (Prix Nobel de littérature 1957)',
   'true', '0'),

  ('bab584aa-458c-4725-a617-f9d16b1724bf', 'f4000000-0000-0000-0000-000000000026',
   'Un footballeur',
   'false', '1'),

  ('2805758d-bf4e-435b-8e2a-f04764f538b8', 'f4000000-0000-0000-0000-000000000026',
   'Un peintre cubiste',
   'false', '2'),

  ('f070ee58-1f80-4eab-bb0f-1b896d71f0d7', 'f4000000-0000-0000-0000-000000000026',
   'Un industriel',
   'false', '3'),

  ('f7352b63-4cff-4f41-a99e-ec6d5787cb61', 'f4000000-0000-0000-0000-000000000027',
   'Un peintre français post-impressionniste',
   'true', '0'),

  ('12e57393-d7cf-4d1d-a217-6b3e083cbf93', 'f4000000-0000-0000-0000-000000000027',
   'Un compositeur',
   'false', '1'),

  ('61671416-3300-4a5d-87ab-380e62b32408', 'f4000000-0000-0000-0000-000000000027',
   'Un explorateur',
   'false', '2'),

  ('1e0e2a7c-c29e-43ad-93e9-31561e590d32', 'f4000000-0000-0000-0000-000000000027',
   'Un homme politique',
   'false', '3'),

  ('659e268d-d820-441f-883f-233720628b2e', 'f4000000-0000-0000-0000-000000000028',
   'Un peintre français d''origine russe',
   'true', '0'),

  ('2a844cc5-9b0e-4ff9-b618-b003772da694', 'f4000000-0000-0000-0000-000000000028',
   'Un musicien anglais',
   'false', '1'),

  ('dffdefbd-b2ed-4e31-83bf-d6cf430c261a', 'f4000000-0000-0000-0000-000000000028',
   'Un sculpteur grec',
   'false', '2'),

  ('347766d2-4726-422c-a1ab-b917ed723f1a', 'f4000000-0000-0000-0000-000000000028',
   'Un cuisinier italien',
   'false', '3'),

  ('0bbe5914-9789-4f74-9561-4b25a10bcdfc', 'f4000000-0000-0000-0000-000000000029',
   'Une artiste, résistante, entrée au Panthéon en 2021',
   'true', '0'),

  ('5a0bd905-fe3d-4ea0-8176-cab76012a7f7', 'f4000000-0000-0000-0000-000000000029',
   'Une scientifique française',
   'false', '1'),

  ('eeb7b462-2b96-4758-aeab-d1d41524f5dc', 'f4000000-0000-0000-0000-000000000029',
   'Une exploratrice',
   'false', '2'),

  ('63177ae6-d31a-484e-a35a-b66a71bfb444', 'f4000000-0000-0000-0000-000000000029',
   'Une religieuse',
   'false', '3'),

  ('9af69ddd-818b-4d49-a16f-dfe29da2c221', 'f4000000-0000-0000-0000-00000000002a',
   'Édith Piaf',
   'true', '0'),

  ('641d12ee-b0e5-42b0-b181-83fb9196fa8b', 'f4000000-0000-0000-0000-00000000002a',
   'Madonna',
   'false', '1'),

  ('ba53710e-68a9-42c7-b969-3cd384890301', 'f4000000-0000-0000-0000-00000000002a',
   'Maria Callas',
   'false', '2'),

  ('775039da-f1c6-41fb-a459-1626329b75f0', 'f4000000-0000-0000-0000-00000000002a',
   'Aretha Franklin',
   'false', '3'),

  ('6d6efea4-ccf4-48fd-928a-64f82e31442b', 'f4000000-0000-0000-0000-00000000002b',
   'Un grand musée à Paris',
   'true', '0'),

  ('e4d533e5-6f1e-45e9-9df4-d6d60da289f9', 'f4000000-0000-0000-0000-00000000002b',
   'Un opéra',
   'false', '1'),

  ('6f55d855-9494-4a39-9bc6-438d2ec1ff2c', 'f4000000-0000-0000-0000-00000000002b',
   'Une bibliothèque universitaire',
   'false', '2'),

  ('4bee490a-794e-48c6-a3ea-0a1d880ad77e', 'f4000000-0000-0000-0000-00000000002b',
   'Un stade de football',
   'false', '3'),

  ('cb622efb-a929-4d8e-9a2d-451d9eb5df99', 'f4000000-0000-0000-0000-00000000002c',
   'Un poète français célèbre pour ses Fables',
   'true', '0'),

  ('d014ac75-9fc3-4720-952c-d93d22d14292', 'f4000000-0000-0000-0000-00000000002c',
   'Un architecte',
   'false', '1'),

  ('21cc8246-6c5d-4a9e-b20b-18ca1768f20d', 'f4000000-0000-0000-0000-00000000002c',
   'Un mathématicien',
   'false', '2'),

  ('192776c7-3c2e-419f-8edb-541a3dff4bae', 'f4000000-0000-0000-0000-00000000002c',
   'Un peintre',
   'false', '3'),

  ('2eb7264f-8ffa-4947-b60b-12c8efbed27b', 'f4000000-0000-0000-0000-00000000002d',
   'Victor Hugo',
   'true', '0'),

  ('9bbf97bf-430a-4c64-a469-b56e43bf209b', 'f4000000-0000-0000-0000-00000000002d',
   'Ernest Hemingway',
   'false', '1'),

  ('b783c5fd-f8d6-4c46-963b-3ec4d0e79dd6', 'f4000000-0000-0000-0000-00000000002d',
   'William Shakespeare',
   'false', '2'),

  ('031e1f53-0592-4a8a-bea6-97904d98fdb8', 'f4000000-0000-0000-0000-00000000002d',
   'Miguel de Cervantes',
   'false', '3'),

  ('9bd18a42-0e56-4f28-81fd-2476e48e31db', 'f4000000-0000-0000-0000-00000000002e',
   'Paris',
   'true', '0'),

  ('3752d5d1-0439-48a3-ae98-17cd80b0a7cd', 'f4000000-0000-0000-0000-00000000002e',
   'Lyon',
   'false', '1'),

  ('1341e99a-9a55-4182-92cb-ab4d2828ce8a', 'f4000000-0000-0000-0000-00000000002e',
   'Marseille',
   'false', '2'),

  ('8daee9ca-0d4b-4783-8a84-f656dd867a40', 'f4000000-0000-0000-0000-00000000002e',
   'Bordeaux',
   'false', '3'),

  ('7805c464-a765-489b-a7dc-3454498d9358', 'f4000000-0000-0000-0000-00000000002f',
   'Le 25 décembre',
   'true', '0'),

  ('0333ad7b-69ed-48a0-8aa1-1aa1d022f207', 'f4000000-0000-0000-0000-00000000002f',
   'Le 1er janvier',
   'false', '1'),

  ('13c81e56-1f62-45e7-a448-b26671f00d0b', 'f4000000-0000-0000-0000-00000000002f',
   'Le 31 octobre',
   'false', '2'),

  ('3d085cc8-71ab-403e-a5df-7a521a70e689', 'f4000000-0000-0000-0000-00000000002f',
   'Le 14 février',
   'false', '3'),

  ('bbe0c5ca-0b3f-40f2-a9b7-deca826b0785', 'f4000001-0000-0000-0000-000000000001',
   '1789',
   'true', '0'),

  ('0591468f-5041-4619-a27b-9314431b848b', 'f4000001-0000-0000-0000-000000000001',
   '1815',
   'false', '1'),

  ('f0c9ebfa-fd8d-4421-a3d8-41580924566b', 'f4000001-0000-0000-0000-000000000001',
   '1870',
   'false', '2'),

  ('76b82890-c280-4903-b85f-e84dc1b5480d', 'f4000001-0000-0000-0000-000000000001',
   '1958',
   'false', '3'),

  ('6087a4f3-02b1-44ca-91be-74da8033b3b1', 'f4000001-0000-0000-0000-000000000002',
   'Empereur des Français (1804-1814)',
   'true', '0'),

  ('3ddf7796-7daa-475e-886e-21220451cb79', 'f4000001-0000-0000-0000-000000000002',
   'Roi à vie',
   'false', '1'),

  ('828a4210-98c2-4b82-9bc3-824139430839', 'f4000001-0000-0000-0000-000000000002',
   'Président de la République',
   'false', '2'),

  ('3e4da2f3-4faf-43a2-825a-7252c6c2fba6', 'f4000001-0000-0000-0000-000000000002',
   'Cardinal de France',
   'false', '3'),

  ('a322dd98-d03c-4db7-8e60-b5ab1d81a3b1', 'f4000001-0000-0000-0000-000000000003',
   'Jeanne d''Arc',
   'true', '0'),

  ('cce024ea-843b-4387-9e46-913b36f4c2d7', 'f4000001-0000-0000-0000-000000000003',
   'Christophe Colomb',
   'false', '1'),

  ('ddd8242f-bbb6-4836-baed-f3484e391af8', 'f4000001-0000-0000-0000-000000000003',
   'Winston Churchill',
   'false', '2'),

  ('29d49796-eca8-4cd4-ae25-114ee93e63db', 'f4000001-0000-0000-0000-000000000003',
   'Albert Einstein',
   'false', '3');
