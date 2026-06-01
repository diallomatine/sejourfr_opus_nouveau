-- ============================================================================
-- V265 — Civique : Histoire, géo, culture (lot 5)
-- ----------------------------------------------------------------------------
-- Questions + choix. Filtre: 11111111-0000-0000-0000-000000000004 .
-- Données régénérées depuis l'état final (déterministe, rejouable dev+recette).
-- ============================================================================

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('f4000002-0000-0000-0000-00000000006b', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quel mouvement social a eu lieu en France en 1936 ?',
   'Le Front populaire (1936-1938), coalition de gauche dirigée par Léon Blum, a marqué une série de réformes sociales majeures : congés payés, semaine de 40 heures, conventions collectives.',
   'true', '2026-05-27 17:40:30.05703+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-00000000006c', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quels congés ont été créés par le Front populaire en 1936 ?',
   'En 1936, le Front populaire de Léon Blum a institué les congés payés (2 semaines au départ, aujourd''hui 5 semaines). Cette mesure a transformé les vacances en France.',
   'true', '2026-05-27 17:40:30.05703+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-00000000006d', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quel acte symbolique du général de Gaulle a fondé la France libre ?',
   'L''appel du 18 juin 1940 lancé par le général de Gaulle depuis Londres (BBC) a appelé à la résistance contre l''occupation nazie. C''est l''acte fondateur de la France libre.',
   'true', '2026-05-27 17:40:30.05703+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-00000000006e', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quelle organisation clandestine a unifié la Résistance française pendant la guerre ?',
   'Le Conseil national de la Résistance (CNR), créé par Jean Moulin le 27 mai 1943, a unifié les mouvements de Résistance intérieure. Son programme a inspiré les réformes d''après-guerre (Sécurité sociale).',
   'true', '2026-05-27 17:40:30.05703+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-00000000006f', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quelle réalisation majeure d''après-guerre a établi la protection sociale en France ?',
   'La Sécurité sociale a été créée par les ordonnances des 4 et 19 octobre 1945, sur la base des programmes du CNR. Elle garantit l''accès aux soins, les retraites, les allocations familiales.',
   'true', '2026-05-27 17:40:30.05703+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-000000000070', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quand la France a-t-elle accordé l''indépendance à ses colonies d''Afrique sub-saharienne ?',
   'Les anciennes colonies françaises d''Afrique sub-saharienne ont accédé à l''indépendance en 1960 (Sénégal, Mali, Niger, Côte d''Ivoire, etc.). C''est l''''année de l''Afrique''.',
   'true', '2026-05-27 17:40:30.05703+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-000000000071', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quel ministre, en 1945, a participé à la fondation de la Sécurité sociale ?',
   'Pierre Laroque (1907-1997), haut fonctionnaire, a été le principal architecte de la Sécurité sociale française créée en 1945. Le ministre du Travail était alors Ambroise Croizat.',
   'true', '2026-05-27 17:40:30.05703+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-000000000072', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Qui sont les ''pères fondateurs'' de la construction européenne du côté français ?',
   'Jean Monnet et Robert Schuman sont considérés comme les pères fondateurs de la construction européenne, avec la Déclaration Schuman du 9 mai 1950 et la CECA.',
   'true', '2026-05-27 17:40:30.05703+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-000000000073', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Que désigne la ''CECA'' créée en 1951 ?',
   'La Communauté européenne du charbon et de l''acier (CECA), créée en 1951 par le traité de Paris, est l''ancêtre de l''Union européenne. Elle mettait en commun les productions de charbon et d''acier.',
   'true', '2026-05-27 17:40:30.05703+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-000000000074', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quelle décolonisation a particulièrement marqué la France après 1945 ?',
   'Deux décolonisations marquantes : l''Indochine (guerre 1946-1954, défaite de Diên Biên Phu, accords de Genève) et l''Algérie (guerre 1954-1962, accords d''Évian).',
   'true', '2026-05-27 17:40:30.05703+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-000000000075', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quel accord a mis fin à la guerre d''Indochine en 1954 ?',
   'Les accords de Genève (juillet 1954) ont mis fin à la guerre d''Indochine, après la défaite française de Diên Biên Phu (mai 1954). Le Vietnam a été divisé en deux.',
   'true', '2026-05-27 17:40:30.05703+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-000000000076', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quel référendum décisif a eu lieu en 1962 sur le mode d''élection du président ?',
   'Le référendum du 28 octobre 1962, proposé par de Gaulle, a instauré l''élection du président au suffrage universel direct. Cette réforme a renforcé la légitimité présidentielle.',
   'true', '2026-05-27 17:40:30.05703+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-000000000077', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quelle crise politique majeure a frappé la France de mai à juin 1968 ?',
   'Mai 68 a combiné une crise étudiante (occupation de la Sorbonne, barricades), une crise sociale (10 millions de grévistes) et une crise politique. De Gaulle a dissous l''Assemblée et son parti a remporté les élections.',
   'true', '2026-05-27 17:40:30.05703+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-000000000078', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quel président a accordé la majorité à 18 ans en 1974 ?',
   'Valéry Giscard d''Estaing (président de 1974 à 1981) a fait abaisser l''âge de la majorité de 21 à 18 ans en 1974, ouvrant le droit de vote des jeunes.',
   'true', '2026-05-27 17:40:30.05703+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-000000000079', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Qui a été le premier président socialiste de la Ve République ?',
   'François Mitterrand (président de 1981 à 1995) a été le premier président socialiste de la Ve République. Il a fait abolir la peine de mort, décentralisé l''État, instauré les 39h hebdomadaires.',
   'true', '2026-05-27 17:40:30.05703+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-00000000007a', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quel traité européen a été signé en 1992, ratifié par référendum en France ?',
   'Le traité de Maastricht (signé le 7 février 1992) a créé l''Union européenne. La France l''a ratifié par référendum le 20 septembre 1992 (oui à 51,04%).',
   'true', '2026-05-27 17:40:30.05703+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-00000000007b', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quel référendum français de 2005 a rejeté le traité constitutionnel européen ?',
   'Le référendum du 29 mai 2005 a rejeté le projet de Constitution européenne (54,68% de non). Le traité de Lisbonne (2007) a intégré l''essentiel des dispositions sans référendum.',
   'true', '2026-05-27 17:40:30.05703+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-00000000007c', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quel événement tragique a marqué Paris le 13 novembre 2015 ?',
   'Les attentats du 13 novembre 2015 (Bataclan, terrasses de cafés, Stade de France) ont fait 130 morts et plus de 400 blessés à Paris et Saint-Denis. L''état d''urgence a été déclaré.',
   'true', '2026-05-27 17:40:30.05703+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-00000000007d', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'MISE_SITUATION',
   'Je veux honorer la mémoire des victimes des attentats de 2015. Que faire en tant que citoyen ?',
   'Participer aux cérémonies de commémoration (notamment le 13 novembre), respecter une minute de silence, soutenir les associations de victimes, transmettre la mémoire aux jeunes générations.',
   'true', '2026-05-27 17:40:30.05703+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-00000000007e', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'MISE_SITUATION',
   'Quelqu''un me demande quand la France a aboli la peine de mort. Quels repères donner ?',
   'La peine de mort a été abolie par la loi du 9 octobre 1981, sous la présidence de François Mitterrand, sur proposition de Robert Badinter. Abolition inscrite dans la Constitution en 2007.',
   'true', '2026-05-27 17:40:30.05703+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-00000000007f', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'MISE_SITUATION',
   'Je veux comprendre l''importance du général de Gaulle dans l''histoire française. Quels repères ?',
   'De Gaulle a incarné la France libre pendant la guerre (1940-1945), libéré le pays, fondé la Ve République (1958), réorganisé les institutions, décolonisé (Algérie en 1962). Président de 1959 à 1969.',
   'true', '2026-05-27 17:40:30.05703+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-000000000080', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'MISE_SITUATION',
   'Je veux comprendre pourquoi le 9 mai est la fête de l''Europe. Quelle origine ?',
   'Le 9 mai 1950, Robert Schuman a prononcé la ''Déclaration Schuman'' proposant la mise en commun des productions de charbon et d''acier de France et d''Allemagne (CECA). C''est l''acte fondateur de l''Europe.',
   'true', '2026-05-27 17:40:30.05703+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-000000000081', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'MISE_SITUATION',
   'On me demande qui étaient Jean Monnet et Robert Schuman. Que répondre ?',
   'Tous deux Français, pères fondateurs de l''Europe : Jean Monnet (1888-1979) économiste à l''origine de la CECA et de la CEE. Robert Schuman (1886-1963) ministre auteur de la Déclaration de 1950.',
   'true', '2026-05-27 17:40:30.05703+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-000000000082', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'MISE_SITUATION',
   'J''apprends que la France était en guerre d''Algérie. Quels repères historiques essentiels ?',
   'Guerre d''Algérie : 1954-1962. Indépendance de l''Algérie le 5 juillet 1962 après les accords d''Évian (mars 1962). Cette guerre a marqué la fin de l''Empire colonial français et la chute de la IVe République.',
   'true', '2026-05-27 17:40:30.05703+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-000000000083', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'MISE_SITUATION',
   'Je veux mieux connaître les Lumières. Quels penseurs français essentiels ?',
   'Les Lumières (XVIIIe siècle) : Voltaire (tolérance, liberté d''expression), Rousseau (Du contrat social, souveraineté populaire), Diderot (l''Encyclopédie), Montesquieu (séparation des pouvoirs).',
   'true', '2026-05-27 17:40:30.05703+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-000000000084', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'MISE_SITUATION',
   'Quelqu''un me dit que toutes les républiques françaises sont identiques. Que répondre ?',
   'Non. Les 5 républiques diffèrent par leurs institutions : Ire (1792, première République, Directoire), IIe (1848, suffrage universel masculin), IIIe (1870-1940, régime parlementaire), IVe (1946-1958, instable), Ve (1958, exécutif renforcé).',
   'true', '2026-05-27 17:40:30.05703+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-000000000085', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'MISE_SITUATION',
   'Je veux connaître les Justes de France. Que désigne ce terme ?',
   'Les ''Justes parmi les Nations'' sont des non-Juifs ayant aidé à sauver des Juifs pendant la Shoah. Plus de 4 000 Français ont été distingués par Israël. Le 16 juillet, journée nationale à leur mémoire.',
   'true', '2026-05-27 17:40:30.05703+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-000000000086', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'MISE_SITUATION',
   'Je veux comprendre la décentralisation française de 1982. En quoi consiste-t-elle ?',
   'Les lois Defferre de 1982 (sous Mitterrand) ont transféré des compétences de l''État vers les collectivités locales (régions, départements, communes), donnant plus de pouvoir aux élus locaux.',
   'true', '2026-05-27 17:40:30.05703+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-0000000000c1', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quel célèbre cuisinier français a popularisé la gastronomie au XXe siècle ?',
   'Paul Bocuse (1926-2018), surnommé ''le pape de la gastronomie'', était l''un des chefs les plus influents du XXe siècle. Il a reçu de nombreuses étoiles Michelin et a formé des générations de cuisiniers.',
   'true', '2026-05-27 17:40:30.037678+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-0000000000c2', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quelle invention française du XXe siècle a révolutionné la photographie ?',
   'Les frères Lumière ont inventé le cinématographe (cinéma) en 1895 à Lyon. La première projection publique payante a eu lieu le 28 décembre 1895 à Paris.',
   'true', '2026-05-27 17:40:30.037678+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-0000000000c3', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Qui était Louis Braille ?',
   'Louis Braille (1809-1852), français devenu aveugle après un accident, a inventé vers 1825 le système d''écriture en relief portant son nom, utilisé par les aveugles dans le monde entier.',
   'true', '2026-05-27 17:40:30.037678+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-0000000000c4', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quel écrivain a écrit ''À la recherche du temps perdu'' ?',
   'Marcel Proust (1871-1922) a écrit ''À la recherche du temps perdu'', vaste roman en 7 volumes publié entre 1913 et 1927, considéré comme une œuvre majeure de la littérature mondiale.',
   'true', '2026-05-27 17:40:30.037678+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-0000000000c5', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quelle révolution a eu lieu en France en 1830 ?',
   'Les Trois Glorieuses (27, 28, 29 juillet 1830) ont renversé Charles X et mis fin à la Restauration. Louis-Philippe d''Orléans est devenu roi des Français (monarchie de Juillet).',
   'true', '2026-05-27 17:40:30.037678+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-0000000000c6', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quel désastre a marqué la guerre de 1870-1871 ?',
   'La défaite de Sedan (1 septembre 1870) a entraîné la capitulation de Napoléon III et la chute du Second Empire. La IIIe République a été proclamée le 4 septembre 1870.',
   'true', '2026-05-27 17:40:30.037678+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-0000000000c7', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quelle région française comporte un volcan célèbre, le Puy de Dôme ?',
   'L''Auvergne-Rhône-Alpes, autour de Clermont-Ferrand, abrite la chaîne des Puys (volcans éteints), avec le Puy de Dôme comme sommet emblématique.',
   'true', '2026-05-27 17:40:30.037678+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-0000000000c8', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quel célèbre couturier français a révolutionné la mode au XXe siècle ?',
   'Gabrielle ''Coco'' Chanel (1883-1971) a révolutionné la mode féminine avec la petite robe noire, le tailleur Chanel et le parfum N°5. D''autres couturiers français célèbres : Christian Dior, Yves Saint Laurent.',
   'true', '2026-05-27 17:40:30.037678+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-0000000000d1', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quelle écrivaine française a reçu le prix Nobel de littérature en 2022 ?',
   'Annie Ernaux, écrivaine française née en 1940, a reçu le prix Nobel de littérature en 2022 pour son œuvre autobiographique et sociologique. Première Française à obtenir ce prix.',
   'true', '2026-05-27 17:40:30.05703+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-0000000000d2', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quel monument parisien a brûlé en 2019 et a été restauré en 2024 ?',
   'La cathédrale Notre-Dame de Paris a subi un grave incendie le 15 avril 2019. Sa restauration s''est achevée en décembre 2024, permettant sa réouverture au public.',
   'true', '2026-05-27 17:40:30.05703+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-0000000000d3', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quel philosophe français existentialiste a refusé le prix Nobel en 1964 ?',
   'Jean-Paul Sartre (1905-1980), philosophe existentialiste et écrivain, a refusé le prix Nobel de littérature qui lui était décerné en 1964. Il était le compagnon de Simone de Beauvoir.',
   'true', '2026-05-27 17:40:30.05703+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-0000000000d4', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quelle école prestigieuse française forme les hauts fonctionnaires de l''État ?',
   'L''ENA (École nationale d''administration), créée en 1945, a formé les hauts fonctionnaires français. Remplacée en 2022 par l''INSP (Institut national du service public).',
   'true', '2026-05-27 17:40:30.05703+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-0000000000d5', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quelle île française du Pacifique a connu plusieurs référendums sur l''indépendance ?',
   'La Nouvelle-Calédonie, collectivité française sui generis du Pacifique sud, a organisé trois référendums sur l''indépendance (2018, 2020, 2021), tous rejetés.',
   'true', '2026-05-27 17:40:30.05703+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-0000000000d6', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quel événement annuel important du sport français a lieu en juillet depuis 1903 ?',
   'Le Tour de France de cyclisme, créé en 1903, est une course mythique de trois semaines en juillet, traversant la France et les pays voisins. L''arrivée est aux Champs-Élysées.',
   'true', '2026-05-27 17:40:30.05703+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-0000000000d7', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quel sommet mondial s''est tenu à Paris en décembre 2015 sur le climat ?',
   'La COP21 (décembre 2015) a abouti à l''Accord de Paris sur le climat, qui engage les États à limiter le réchauffement climatique. Premier accord universel sur le climat.',
   'true', '2026-05-27 17:40:30.05703+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-0000000000d8', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quels grands événements sportifs internationaux la France a-t-elle accueillis en 2024 ?',
   'La France a accueilli les Jeux olympiques d''été à Paris (26 juillet - 11 août 2024) et les Jeux paralympiques (28 août - 8 septembre 2024), 100 ans après les précédents JO parisiens de 1924.',
   'true', '2026-05-27 17:40:30.05703+02', NULL, 'ACTIVE', NULL, NULL, NULL);

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('14100de4-e629-454b-876c-103aa9ac9fc2', 'f4000002-0000-0000-0000-00000000006b',
   'Le Front populaire (Léon Blum, 1936)',
   'true', '0'),

  ('4806a578-50c6-4ba2-8c81-781ac5e7a543', 'f4000002-0000-0000-0000-00000000006b',
   'La Résistance',
   'false', '1'),

  ('6462ef7d-c82e-4abc-8989-2aed4a7f1cef', 'f4000002-0000-0000-0000-00000000006b',
   'Mai 68',
   'false', '2'),

  ('e18533fb-afb7-4433-95f2-279ae39a43eb', 'f4000002-0000-0000-0000-00000000006b',
   'La Libération',
   'false', '3'),

  ('1c9454c6-605a-4a91-9c7c-89458017b8ec', 'f4000002-0000-0000-0000-00000000006c',
   'Les premiers congés payés (1936)',
   'true', '0'),

  ('83e5f95b-654c-4a74-a5d8-9511924f4274', 'f4000002-0000-0000-0000-00000000006c',
   'Les congés parentaux',
   'false', '1'),

  ('ee81d98b-043e-44f1-b1eb-e70dfc3a45c4', 'f4000002-0000-0000-0000-00000000006c',
   'Les vacances scolaires',
   'false', '2'),

  ('266a2d8e-2154-499c-a63b-6b2740cb0eb4', 'f4000002-0000-0000-0000-00000000006c',
   'Les jours fériés',
   'false', '3'),

  ('54b04e32-1736-4e2c-ad2d-080750bc0ccf', 'f4000002-0000-0000-0000-00000000006d',
   'L''appel du 18 juin 1940 (BBC, Londres)',
   'true', '0'),

  ('7f084517-3b59-4fbd-b855-921174044c1b', 'f4000002-0000-0000-0000-00000000006d',
   'L''appel du 25 août 1944',
   'false', '1'),

  ('93c1d940-b02c-45cc-9810-382f09970083', 'f4000002-0000-0000-0000-00000000006d',
   'L''appel du 8 mai 1945',
   'false', '2'),

  ('80133eb8-9b15-4772-8f3a-0bc19ed70d26', 'f4000002-0000-0000-0000-00000000006d',
   'Le discours de Bayeux',
   'false', '3'),

  ('80e3d408-5947-41d5-98db-c0ceaff3b9de', 'f4000002-0000-0000-0000-00000000006e',
   'Le Conseil national de la Résistance (CNR, 1943)',
   'true', '0'),

  ('eeb6b730-49a9-4cc1-b766-1f04b8c79586', 'f4000002-0000-0000-0000-00000000006e',
   'Le Front populaire',
   'false', '1'),

  ('ae04f181-8e27-424f-b087-6ca9187f177d', 'f4000002-0000-0000-0000-00000000006e',
   'Le Conseil d''État',
   'false', '2'),

  ('2cc296c7-7339-49c0-8b0a-9f1f98e9422d', 'f4000002-0000-0000-0000-00000000006e',
   'La Croix-Rouge',
   'false', '3'),

  ('75977aa0-a7bc-452f-8d01-9fc8234cb6c2', 'f4000002-0000-0000-0000-00000000006f',
   'La Sécurité sociale (créée en 1945)',
   'true', '0'),

  ('498a12e9-cb3e-4a06-8fca-f317ac522920', 'f4000002-0000-0000-0000-00000000006f',
   'L''Éducation nationale',
   'false', '1'),

  ('7160cd40-4128-483d-82bd-165857d5d46b', 'f4000002-0000-0000-0000-00000000006f',
   'Le Code du travail',
   'false', '2'),

  ('ef9a629b-0d7b-4f49-bee2-7b23be252b6d', 'f4000002-0000-0000-0000-00000000006f',
   'Le SMIC',
   'false', '3'),

  ('cb64d275-92e2-4d4c-a9e2-6369f2c7896e', 'f4000002-0000-0000-0000-000000000070',
   'En 1960 (année de l''Afrique)',
   'true', '0'),

  ('ddad673b-6d7a-402e-a7f7-c9558c9ce2f4', 'f4000002-0000-0000-0000-000000000070',
   'En 1945',
   'false', '1'),

  ('a83b8cfa-9f3e-4f7f-843f-e0d677a61c9c', 'f4000002-0000-0000-0000-000000000070',
   'En 1981',
   'false', '2'),

  ('c0c05fbf-badd-4fc3-8137-7a08827dd9cc', 'f4000002-0000-0000-0000-000000000070',
   'En 2000',
   'false', '3'),

  ('164b5060-89cc-4ae6-bfff-5bc263c2298c', 'f4000002-0000-0000-0000-000000000071',
   'Pierre Laroque (avec Ambroise Croizat)',
   'true', '0'),

  ('5f7ca878-0595-429b-9aff-11107f5d557c', 'f4000002-0000-0000-0000-000000000071',
   'Robert Schuman',
   'false', '1'),

  ('ba899073-d28c-40eb-8c36-0bf4094ca199', 'f4000002-0000-0000-0000-000000000071',
   'Jean Monnet',
   'false', '2'),

  ('418b9789-3a88-4200-b35f-634fe0dc3cba', 'f4000002-0000-0000-0000-000000000071',
   'De Gaulle seul',
   'false', '3'),

  ('a0db5bcd-c198-4898-981c-573b72e0fa5e', 'f4000002-0000-0000-0000-000000000072',
   'Jean Monnet et Robert Schuman',
   'true', '0'),

  ('80c27da6-7a7a-4948-a698-396e01116135', 'f4000002-0000-0000-0000-000000000072',
   'Napoléon et Bismarck',
   'false', '1'),

  ('5af5082d-d96d-4395-a43b-b699d392ad51', 'f4000002-0000-0000-0000-000000000072',
   'De Gaulle et Adenauer uniquement',
   'false', '2'),

  ('1d79cd49-b24b-47af-9f4b-9269866fa295', 'f4000002-0000-0000-0000-000000000072',
   'Hugo et Zola',
   'false', '3'),

  ('1e8152f0-b1fe-4489-a882-a866b2a94604', 'f4000002-0000-0000-0000-000000000073',
   'La Communauté européenne du charbon et de l''acier (1951)',
   'true', '0'),

  ('9d7a655b-53ad-4f48-b388-cdd62ba1f383', 'f4000002-0000-0000-0000-000000000073',
   'Une compagnie ferroviaire',
   'false', '1'),

  ('1da0195c-0341-4c4f-8885-26d3f10964a6', 'f4000002-0000-0000-0000-000000000073',
   'Un club sportif',
   'false', '2'),

  ('6d40ea44-8f66-4d68-aa20-b49eea0bdc3c', 'f4000002-0000-0000-0000-000000000073',
   'Un parti politique',
   'false', '3'),

  ('f6911143-61df-4657-8d72-03708e7a5ae3', 'f4000002-0000-0000-0000-000000000074',
   'L''Indochine puis l''Algérie',
   'true', '0'),

  ('9d53e8fb-b022-4293-956e-5afcec2b7663', 'f4000002-0000-0000-0000-000000000074',
   'Le Canada',
   'false', '1'),

  ('f0f9a2a7-f25d-4139-b887-445b864a7d10', 'f4000002-0000-0000-0000-000000000074',
   'Le Royaume-Uni',
   'false', '2'),

  ('129f0c69-a639-45d9-8d4a-a2f0336d4be4', 'f4000002-0000-0000-0000-000000000074',
   'L''Espagne',
   'false', '3'),

  ('89ec415b-9af3-47b8-9acc-fa29ea6e302b', 'f4000002-0000-0000-0000-000000000075',
   'Les accords de Genève (1954)',
   'true', '0'),

  ('2242205b-c7ea-4517-bb57-543742f92cfe', 'f4000002-0000-0000-0000-000000000075',
   'Les accords d''Évian',
   'false', '1'),

  ('2eeb3e4b-a241-4385-8ee7-efab2d7b17a6', 'f4000002-0000-0000-0000-000000000075',
   'Le traité de Versailles',
   'false', '2'),

  ('3570efb8-d2fe-46ef-a1c6-45e2d8e76ed3', 'f4000002-0000-0000-0000-000000000075',
   'Les accords de Yalta',
   'false', '3'),

  ('9c7c9aa0-70d9-4c79-a33f-81968bff1890', 'f4000002-0000-0000-0000-000000000076',
   'Le référendum sur l''élection présidentielle au suffrage direct (1962)',
   'true', '0'),

  ('0988a058-675a-4fdf-a13e-3c0fff8fadad', 'f4000002-0000-0000-0000-000000000076',
   'Le référendum sur Maastricht',
   'false', '1'),

  ('baccb226-69d9-4dd4-9f1c-373ccbfe3ce8', 'f4000002-0000-0000-0000-000000000076',
   'Le référendum sur l''Algérie',
   'false', '2'),

  ('c74b7221-6928-4315-8053-80b8d8070cfe', 'f4000002-0000-0000-0000-000000000076',
   'Le référendum sur le quinquennat',
   'false', '3'),

  ('083951ea-e3b6-4c16-8fe6-d67811bdb816', 'f4000002-0000-0000-0000-000000000077',
   'Une crise étudiante, sociale et politique (Mai 68)',
   'true', '0'),

  ('56171ca6-dda9-40e2-a724-770ae503b5c4', 'f4000002-0000-0000-0000-000000000077',
   'Une guerre civile',
   'false', '1'),

  ('97a7c1db-ae80-4ec3-87f5-0a170097a89a', 'f4000002-0000-0000-0000-000000000077',
   'Une famine',
   'false', '2'),

  ('16345802-bf76-4c48-ba57-0ca1c4632842', 'f4000002-0000-0000-0000-000000000077',
   'Une épidémie',
   'false', '3'),

  ('de0ad965-e443-4b2a-a9e7-a7c778a6c66e', 'f4000002-0000-0000-0000-000000000078',
   'Valéry Giscard d''Estaing (1974)',
   'true', '0'),

  ('782c3069-e3c3-4780-80dd-b0723ed141d0', 'f4000002-0000-0000-0000-000000000078',
   'François Mitterrand',
   'false', '1'),

  ('a975ed15-5acb-43b0-9628-2961603d5bfb', 'f4000002-0000-0000-0000-000000000078',
   'Jacques Chirac',
   'false', '2'),

  ('146a8b82-a8ce-40ae-bd99-e06503f0cbf1', 'f4000002-0000-0000-0000-000000000078',
   'Charles de Gaulle',
   'false', '3'),

  ('0d330215-9ddd-462e-9ccf-a897a14fa5ca', 'f4000002-0000-0000-0000-000000000079',
   'François Mitterrand',
   'true', '0'),

  ('266b6944-8087-4ce4-9d7a-6cda150b35f6', 'f4000002-0000-0000-0000-000000000079',
   'Charles de Gaulle',
   'false', '1'),

  ('ff17dc5b-c23d-4907-a0de-1b10062af132', 'f4000002-0000-0000-0000-000000000079',
   'Georges Pompidou',
   'false', '2'),

  ('610eabf1-4f6f-4f0c-8d11-75ccafc41f34', 'f4000002-0000-0000-0000-000000000079',
   'Jacques Chirac',
   'false', '3'),

  ('8ff6df03-f19a-41c4-9cd9-0fa6560d7e36', 'f4000002-0000-0000-0000-00000000007a',
   'Le traité de Maastricht (1992)',
   'true', '0'),

  ('9926744b-f977-412d-8a48-e8b8b64715e8', 'f4000002-0000-0000-0000-00000000007a',
   'Le traité de Lisbonne',
   'false', '1'),

  ('f948dd0a-7bc0-4021-afe4-5ae49ff7c8eb', 'f4000002-0000-0000-0000-00000000007a',
   'Le traité de Rome',
   'false', '2'),

  ('8fc604b0-b04c-4d84-99f8-381718f1f2cc', 'f4000002-0000-0000-0000-00000000007a',
   'Le traité de Schengen',
   'false', '3'),

  ('6f1f0d50-e7a4-44b4-aa2d-aa15740faf13', 'f4000002-0000-0000-0000-00000000007b',
   'Le référendum sur la Constitution européenne (29 mai 2005)',
   'true', '0'),

  ('ec0da5ac-03f2-4753-b54a-b115dbadb5cb', 'f4000002-0000-0000-0000-00000000007b',
   'Le référendum sur Maastricht',
   'false', '1'),

  ('919b1876-e34e-429e-9331-9d7d91a88d4e', 'f4000002-0000-0000-0000-00000000007b',
   'Le référendum sur le quinquennat',
   'false', '2'),

  ('76133e47-65e6-4b42-bcb3-51fd496e32ba', 'f4000002-0000-0000-0000-00000000007b',
   'Le référendum sur le Brexit',
   'false', '3'),

  ('0609a80f-2e10-42fb-9db9-a9ddbbdf98a8', 'f4000002-0000-0000-0000-00000000007c',
   'Les attentats terroristes du 13 novembre 2015',
   'true', '0'),

  ('8a312e5c-52e5-4f17-b031-045668031903', 'f4000002-0000-0000-0000-00000000007c',
   'Une inondation',
   'false', '1'),

  ('e9609112-5bb3-4c46-a64c-6925eaf3b9b5', 'f4000002-0000-0000-0000-00000000007c',
   'Une grève générale',
   'false', '2'),

  ('16ee73b5-9b23-420f-ac2b-e11a31d6dc20', 'f4000002-0000-0000-0000-00000000007c',
   'Un incendie accidentel',
   'false', '3'),

  ('28ad5218-e598-4ca2-8e39-b0e724cc107a', 'f4000002-0000-0000-0000-00000000007d',
   'Cérémonies, silence, associations, transmission',
   'true', '0'),

  ('1600a4e4-b3ca-404d-85c4-59c3c6f8e48a', 'f4000002-0000-0000-0000-00000000007d',
   'Ne rien faire',
   'false', '1'),

  ('fcc2273a-159c-4a4c-a2e0-d1c152a2abc8', 'f4000002-0000-0000-0000-00000000007d',
   'Refuser de sortir',
   'false', '2'),

  ('8b444639-6309-4d61-bf64-81a14c07ac9c', 'f4000002-0000-0000-0000-00000000007d',
   'Quitter le pays',
   'false', '3'),

  ('88781cc5-6deb-437a-bba9-6678e5a022d7', 'f4000002-0000-0000-0000-00000000007e',
   '1981 (loi Badinter sous Mitterrand) ; constitutionnel depuis 2007',
   'true', '0'),

  ('a3185258-aead-4a7b-8caa-fbcbb475667d', 'f4000002-0000-0000-0000-00000000007e',
   '1789',
   'false', '1'),

  ('d9069fb0-879b-44a5-ab6d-3f82e6f1131c', 'f4000002-0000-0000-0000-00000000007e',
   '1944',
   'false', '2'),

  ('61e8b479-a8bd-4f05-9347-28dd339bd70f', 'f4000002-0000-0000-0000-00000000007e',
   '2000',
   'false', '3'),

  ('40fd415b-142f-4488-a41c-871714de20ab', 'f4000002-0000-0000-0000-00000000007f',
   'France libre, Libération, Ve République, décolonisation',
   'true', '0'),

  ('8948d3d2-fa22-4e8a-8c0d-5d3ae60abd45', 'f4000002-0000-0000-0000-00000000007f',
   'Aucun rôle majeur',
   'false', '1'),

  ('2851b2d9-209d-42c0-9232-1a375c24327f', 'f4000002-0000-0000-0000-00000000007f',
   'Uniquement un président pacifique',
   'false', '2'),

  ('e731bac2-7de7-46e6-ac61-a37482662090', 'f4000002-0000-0000-0000-00000000007f',
   'Uniquement un militaire',
   'false', '3'),

  ('9534f3cc-f5d7-43f3-9785-11179e25459a', 'f4000002-0000-0000-0000-000000000080',
   'La Déclaration Schuman du 9 mai 1950',
   'true', '0'),

  ('ec420b54-b19f-4b64-a6af-b3933443549c', 'f4000002-0000-0000-0000-000000000080',
   'Le jour de la Libération',
   'false', '1'),

  ('e1166115-7c86-4fa6-8b23-7e9e0475d53e', 'f4000002-0000-0000-0000-000000000080',
   'La fête d''un saint',
   'false', '2'),

  ('f4166227-047f-4def-bf8c-2630e54c80d6', 'f4000002-0000-0000-0000-000000000080',
   'Une bataille napoléonienne',
   'false', '3'),

  ('72a3b7bb-b4fa-49f0-ba87-d59dcc5c8fbd', 'f4000002-0000-0000-0000-000000000081',
   'Les pères fondateurs français de la construction européenne',
   'true', '0'),

  ('ad6bb07a-3f43-45d2-913f-c3be2ae6b8d8', 'f4000002-0000-0000-0000-000000000081',
   'Des explorateurs',
   'false', '1'),

  ('96614da2-ad5b-444c-af37-b35f43a6bb03', 'f4000002-0000-0000-0000-000000000081',
   'Des philosophes',
   'false', '2'),

  ('7cc75bb4-c508-4439-a733-12047f0addab', 'f4000002-0000-0000-0000-000000000081',
   'Des compositeurs',
   'false', '3'),

  ('15fc97b6-02fc-4df7-a9bb-daba836b1a8a', 'f4000002-0000-0000-0000-000000000082',
   'Guerre 1954-1962, accords d''Évian, indépendance le 5 juillet 1962',
   'true', '0'),

  ('2aa5185f-1a14-4902-bc46-4428d4d463b5', 'f4000002-0000-0000-0000-000000000082',
   'Guerre 1939-1945',
   'false', '1'),

  ('794d8fcd-c4eb-4152-b602-4fec7e33e388', 'f4000002-0000-0000-0000-000000000082',
   'Bataille napoléonienne',
   'false', '2'),

  ('53a45eb0-4a91-4fdb-ab62-8560697853b0', 'f4000002-0000-0000-0000-000000000082',
   'Une simple crise économique',
   'false', '3'),

  ('0bace614-6ba6-4a9c-9e51-1fa73ba56ea5', 'f4000002-0000-0000-0000-000000000083',
   'Voltaire, Rousseau, Diderot, Montesquieu',
   'true', '0'),

  ('52c6ef8c-ec39-4243-ba97-ef9753c892ca', 'f4000002-0000-0000-0000-000000000083',
   'Sartre et Camus',
   'false', '1'),

  ('58e0ae37-607c-4329-a810-9bd2e4c4475b', 'f4000002-0000-0000-0000-000000000083',
   'Hugo et Zola',
   'false', '2'),

  ('77b708a0-7aca-40a1-b1d4-e4b96b91b3e5', 'f4000002-0000-0000-0000-000000000083',
   'Aucun penseur français',
   'false', '3'),

  ('fee97127-2c12-4340-841d-b7d0409247bd', 'f4000002-0000-0000-0000-000000000084',
   'Chaque République a un cadre institutionnel différent',
   'true', '0'),

  ('c7086a55-b293-4eb0-845e-db27d69070ec', 'f4000002-0000-0000-0000-000000000084',
   'Elles sont identiques',
   'false', '1'),

  ('308d99c2-7a3f-4175-8ee8-660dd8a7ec1a', 'f4000002-0000-0000-0000-000000000084',
   'Il n''y en a eu qu''une',
   'false', '2'),

  ('5c095f01-ccf3-4e4f-9c85-6826fc01f6d0', 'f4000002-0000-0000-0000-000000000084',
   'Elles n''existent pas',
   'false', '3'),

  ('6213f9e9-e084-4e47-9b25-8594f1bf315e', 'f4000002-0000-0000-0000-000000000085',
   'Non-Juifs ayant sauvé des Juifs pendant la Shoah',
   'true', '0'),

  ('075e85be-422d-4400-a833-b8f2db645c50', 'f4000002-0000-0000-0000-000000000085',
   'Des héros militaires',
   'false', '1'),

  ('e114d3e9-f871-44c7-b1c1-d8a034aff2ba', 'f4000002-0000-0000-0000-000000000085',
   'Des dirigeants politiques',
   'false', '2'),

  ('8dbd98c0-9dd2-43cf-81f2-b5896b497859', 'f4000002-0000-0000-0000-000000000085',
   'Des scientifiques',
   'false', '3'),

  ('75f950d2-372a-48bc-abeb-b9cbe5628991', 'f4000002-0000-0000-0000-000000000086',
   'Transfert de pouvoirs vers les collectivités locales (1982)',
   'true', '0'),

  ('0139ee00-19bd-42a2-9882-d7fd88a80afd', 'f4000002-0000-0000-0000-000000000086',
   'Suppression de l''État',
   'false', '1'),

  ('0b87019b-2b96-4100-8a45-e305bdc075ab', 'f4000002-0000-0000-0000-000000000086',
   'Indépendance des régions',
   'false', '2'),

  ('f64351e7-7694-4396-910c-2f0c5a595232', 'f4000002-0000-0000-0000-000000000086',
   'Aucune réforme territoriale',
   'false', '3'),

  ('105d7945-a1f1-43d4-a154-a69e392f0aeb', 'f4000002-0000-0000-0000-0000000000c1',
   'Paul Bocuse',
   'true', '0'),

  ('f8b87cdc-f2d9-4e34-8df1-ee1a37223455', 'f4000002-0000-0000-0000-0000000000c1',
   'Gustave Eiffel',
   'false', '1'),

  ('66396126-1ba2-417f-be97-3719bb74acfe', 'f4000002-0000-0000-0000-0000000000c1',
   'Marie Curie',
   'false', '2'),

  ('f74deb47-bc6e-47eb-97d8-604dbe910feb', 'f4000002-0000-0000-0000-0000000000c1',
   'Charles de Gaulle',
   'false', '3'),

  ('b341a1fc-77d0-4331-81cf-a355f7655773', 'f4000002-0000-0000-0000-0000000000c2',
   'Le cinématographe (frères Lumière, 1895)',
   'true', '0'),

  ('e2cec55f-f53e-4fb8-a272-8462bf68a6c7', 'f4000002-0000-0000-0000-0000000000c2',
   'L''ordinateur',
   'false', '1'),

  ('e05ee470-bad6-4ec8-be7e-ed756558e0fc', 'f4000002-0000-0000-0000-0000000000c2',
   'La voiture',
   'false', '2'),

  ('6c7d1624-195b-4e7e-8851-7236119b5260', 'f4000002-0000-0000-0000-0000000000c2',
   'La télévision',
   'false', '3'),

  ('abd4339d-29d6-403a-98a3-a3ed0b3724df', 'f4000002-0000-0000-0000-0000000000c3',
   'L''inventeur de l''écriture en relief pour les aveugles',
   'true', '0'),

  ('6854b900-89ff-4bad-a38c-6a0cc3a8d5d5', 'f4000002-0000-0000-0000-0000000000c3',
   'Un peintre',
   'false', '1'),

  ('c0c9c17f-40e4-45f5-8999-79985603264a', 'f4000002-0000-0000-0000-0000000000c3',
   'Un compositeur',
   'false', '2'),

  ('bc7e0936-ac9e-4b25-989b-770272047403', 'f4000002-0000-0000-0000-0000000000c3',
   'Un explorateur',
   'false', '3'),

  ('f7316961-e961-43ea-8497-ca4456f15df9', 'f4000002-0000-0000-0000-0000000000c4',
   'Marcel Proust',
   'true', '0'),

  ('ef85707e-fb5e-4fdb-b37e-aa87e8d269a4', 'f4000002-0000-0000-0000-0000000000c4',
   'Victor Hugo',
   'false', '1'),

  ('aa076143-042c-4bec-aa31-188434d2da89', 'f4000002-0000-0000-0000-0000000000c4',
   'Émile Zola',
   'false', '2'),

  ('ecc95946-b0da-4ab7-93c2-936a403f4147', 'f4000002-0000-0000-0000-0000000000c4',
   'Albert Camus',
   'false', '3'),

  ('1dc7d1ed-ef2b-4ecc-99bc-8b75b53d5251', 'f4000002-0000-0000-0000-0000000000c5',
   'Les Trois Glorieuses (1830)',
   'true', '0'),

  ('0fb7d26f-e733-4e7d-bf93-955c208b02b3', 'f4000002-0000-0000-0000-0000000000c5',
   'La Révolution de 1789',
   'false', '1'),

  ('c79cbd9c-f422-4684-92f2-fa01b38c7097', 'f4000002-0000-0000-0000-0000000000c5',
   'La Commune de Paris',
   'false', '2'),

  ('f22af4b1-7505-433b-855a-24a601084e55', 'f4000002-0000-0000-0000-0000000000c5',
   'La Libération',
   'false', '3'),

  ('dfa2009a-d5d0-48b4-9140-bb790e8a0bfd', 'f4000002-0000-0000-0000-0000000000c6',
   'La défaite de Sedan et la chute de Napoléon III',
   'true', '0'),

  ('cf1a86a2-68bb-4c93-b626-98df88c94431', 'f4000002-0000-0000-0000-0000000000c6',
   'La bataille de Waterloo',
   'false', '1'),

  ('451ffb11-fddc-4d5a-9b1b-164f8af5193e', 'f4000002-0000-0000-0000-0000000000c6',
   'La prise de la Bastille',
   'false', '2'),

  ('e2f0799e-f3be-49e8-94a8-019d6a860f07', 'f4000002-0000-0000-0000-0000000000c6',
   'La débâcle de 1940',
   'false', '3'),

  ('dc335299-03b2-4435-8066-5ece6d0b1beb', 'f4000002-0000-0000-0000-0000000000c7',
   'L''Auvergne-Rhône-Alpes (chaîne des Puys)',
   'true', '0'),

  ('c3abcf74-532e-4cba-b794-efc1560e2141', 'f4000002-0000-0000-0000-0000000000c7',
   'La Bretagne',
   'false', '1'),

  ('86f87ba8-73da-46e6-827a-ed119bc7809f', 'f4000002-0000-0000-0000-0000000000c7',
   'La Picardie',
   'false', '2'),

  ('f751592e-de83-40b1-a000-dda524123180', 'f4000002-0000-0000-0000-0000000000c7',
   'La Corse',
   'false', '3'),

  ('a00b4c97-b7d5-49ce-aeec-86c67e2e511f', 'f4000002-0000-0000-0000-0000000000c8',
   'Coco Chanel',
   'true', '0'),

  ('5ac95939-0ba1-4e4e-a5c3-598a3d2ef35a', 'f4000002-0000-0000-0000-0000000000c8',
   'Marie Curie',
   'false', '1'),

  ('19dbcf65-2881-4439-b564-5488e51fe8f3', 'f4000002-0000-0000-0000-0000000000c8',
   'Édith Piaf',
   'false', '2'),

  ('629ad171-9b5e-43c7-892a-858ea750af33', 'f4000002-0000-0000-0000-0000000000c8',
   'Simone Veil',
   'false', '3'),

  ('3f20d2ac-c941-4cf7-a653-25f93cdb4a85', 'f4000002-0000-0000-0000-0000000000d1',
   'Annie Ernaux (2022)',
   'true', '0'),

  ('9f55365d-f721-4ac1-b277-1f1f4dc8c9bb', 'f4000002-0000-0000-0000-0000000000d1',
   'Marguerite Duras',
   'false', '1'),

  ('efb95ec8-3954-4da7-a87e-8c5e4d37dd3d', 'f4000002-0000-0000-0000-0000000000d1',
   'Françoise Sagan',
   'false', '2'),

  ('7e3a1db2-2557-4b77-b6f5-2321ecf78dd7', 'f4000002-0000-0000-0000-0000000000d1',
   'Colette',
   'false', '3'),

  ('e831fe96-3429-4f09-85ca-10ca1191614d', 'f4000002-0000-0000-0000-0000000000d2',
   'Notre-Dame de Paris (incendie 2019, réouverture 2024)',
   'true', '0'),

  ('3fe1eecc-d35c-4d52-85b6-034cee0d3ab0', 'f4000002-0000-0000-0000-0000000000d2',
   'La tour Eiffel',
   'false', '1'),

  ('34a082ff-115d-4a6a-9f91-28104a637f59', 'f4000002-0000-0000-0000-0000000000d2',
   'Le Louvre',
   'false', '2'),

  ('3396b39e-f403-4819-b066-1b2abfe42499', 'f4000002-0000-0000-0000-0000000000d2',
   'L''Arc de Triomphe',
   'false', '3'),

  ('f27f2f9b-7d4f-4074-9538-c8ea60641826', 'f4000002-0000-0000-0000-0000000000d3',
   'Jean-Paul Sartre',
   'true', '0'),

  ('b75e4113-adae-4778-b3dd-f51fb5beafec', 'f4000002-0000-0000-0000-0000000000d3',
   'Albert Camus',
   'false', '1'),

  ('38b96ead-6dbb-4801-b48c-14bbba49c060', 'f4000002-0000-0000-0000-0000000000d3',
   'André Malraux',
   'false', '2'),

  ('5334b07b-4a79-4553-9fd3-068b57ffb705', 'f4000002-0000-0000-0000-0000000000d3',
   'Raymond Aron',
   'false', '3'),

  ('ee0430e3-9e27-4df2-8f48-24cfda3b6ca7', 'f4000002-0000-0000-0000-0000000000d4',
   'L''ENA, devenue INSP en 2022',
   'true', '0'),

  ('bec45e3d-2f5d-4315-a3a7-e0aaffd8f9fc', 'f4000002-0000-0000-0000-0000000000d4',
   'Polytechnique',
   'false', '1'),

  ('6428e010-b767-49a2-99a8-f451862c19e7', 'f4000002-0000-0000-0000-0000000000d4',
   'HEC',
   'false', '2'),

  ('b05aedc7-4897-41ab-870e-ae54afccb055', 'f4000002-0000-0000-0000-0000000000d4',
   'La Sorbonne',
   'false', '3'),

  ('5aaa1e87-1e8b-4c3b-8ead-641785c258a9', 'f4000002-0000-0000-0000-0000000000d5',
   'La Nouvelle-Calédonie',
   'true', '0'),

  ('22b86c96-87ab-4c27-aa46-5eb117554342', 'f4000002-0000-0000-0000-0000000000d5',
   'La Réunion',
   'false', '1'),

  ('34654f63-32c4-4008-978b-dc3338f4d934', 'f4000002-0000-0000-0000-0000000000d5',
   'La Guadeloupe',
   'false', '2'),

  ('9960e260-c8ea-4ed3-a154-275c1d24b9e5', 'f4000002-0000-0000-0000-0000000000d5',
   'Mayotte',
   'false', '3'),

  ('dd09562a-10e6-49da-8827-eef6eef1a8a1', 'f4000002-0000-0000-0000-0000000000d6',
   'Le Tour de France de cyclisme (depuis 1903)',
   'true', '0'),

  ('405bc6a2-9709-490e-b6b9-9420c0686c82', 'f4000002-0000-0000-0000-0000000000d6',
   'La Coupe du monde de football',
   'false', '1'),

  ('ee6ad970-cccf-45fb-8d92-dfe38cc7b526', 'f4000002-0000-0000-0000-0000000000d6',
   'Roland-Garros',
   'false', '2'),

  ('246bfae6-a464-432b-a289-bec07e698965', 'f4000002-0000-0000-0000-0000000000d6',
   'Le marathon de Paris',
   'false', '3'),

  ('0ea3977f-128f-4118-a725-58ac7d32ec4a', 'f4000002-0000-0000-0000-0000000000d7',
   'La COP21 (Accord de Paris sur le climat)',
   'true', '0'),

  ('af08f0e6-b422-4c95-8c93-25149516aec3', 'f4000002-0000-0000-0000-0000000000d7',
   'Un sommet de l''OTAN',
   'false', '1'),

  ('f0dfa356-d532-4183-b75c-4032f1555832', 'f4000002-0000-0000-0000-0000000000d7',
   'Une conférence économique',
   'false', '2'),

  ('3aa370e7-d2a7-490e-bce2-1ee27cf2739f', 'f4000002-0000-0000-0000-0000000000d7',
   'Aucun sommet majeur',
   'false', '3'),

  ('5453c2e7-eea6-44e1-affb-16eebeeca61a', 'f4000002-0000-0000-0000-0000000000d8',
   'Les Jeux olympiques et paralympiques de Paris 2024',
   'true', '0'),

  ('130ef098-bad4-4d04-baae-e83fed629f8e', 'f4000002-0000-0000-0000-0000000000d8',
   'La Coupe du monde de football',
   'false', '1'),

  ('87d5c302-1772-4b44-b972-6b373f94cf6e', 'f4000002-0000-0000-0000-0000000000d8',
   'Un seul tournoi de tennis',
   'false', '2'),

  ('c282b2b7-5fb1-4d99-a888-3708ba1b7d22', 'f4000002-0000-0000-0000-0000000000d8',
   'Aucun événement',
   'false', '3');
