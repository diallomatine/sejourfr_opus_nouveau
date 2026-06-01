-- ============================================================================
-- V263 — Civique : Histoire, géo, culture (lot 3)
-- ----------------------------------------------------------------------------
-- Questions + choix. Filtre: 11111111-0000-0000-0000-000000000004 .
-- Données régénérées depuis l'état final (déterministe, rejouable dev+recette).
-- ============================================================================

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('f4000002-0000-0000-0000-000000000007', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Que représente le drapeau français ?',
   'Le drapeau français (bleu-blanc-rouge) est l''emblème de la République. Adopté en 1794, il symbolise l''union du peuple (bleu et rouge, couleurs de Paris) et de la royauté (blanc).',
   'true', '2026-05-27 17:40:30.021056+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-000000000008', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quel hymne national est chanté en France ?',
   'La Marseillaise est l''hymne national français. Composé en 1792 à Strasbourg par Rouget de Lisle, il a été adopté définitivement par la IIIe République.',
   'true', '2026-05-27 17:40:30.021056+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-000000000009', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quelle est la devise de la République française ?',
   'La devise de la République française est ''Liberté, Égalité, Fraternité''. Elle est inscrite dans la Constitution (article 2).',
   'true', '2026-05-27 17:40:30.021056+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-00000000000a', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quel symbole féminin représente la République française ?',
   'Marianne est l''allégorie de la République française. On la trouve sur les timbres, les pièces, dans les mairies. Elle porte souvent un bonnet phrygien.',
   'true', '2026-05-27 17:40:30.021056+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-00000000000b', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quel coq est un emblème animal de la France ?',
   'Le coq gaulois est un emblème officieux de la France. On le retrouve sur les maillots de l''équipe de France de football et de rugby.',
   'true', '2026-05-27 17:40:30.021056+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-00000000000c', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quel événement annuel sportif passe par les Champs-Élysées ?',
   'L''arrivée finale du Tour de France de cyclisme, course mythique créée en 1903, se fait traditionnellement sur les Champs-Élysées à Paris.',
   'true', '2026-05-27 17:40:30.021056+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-00000000000d', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quel tournoi de tennis est joué à Paris ?',
   'Roland-Garros est le tournoi de tennis français du Grand Chelem, joué chaque année sur terre battue à Paris (Porte d''Auteuil), en mai-juin.',
   'true', '2026-05-27 17:40:30.021056+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-00000000000e', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quel sport collectif est très populaire en France ?',
   'Le football est le sport le plus populaire en France. L''équipe de France masculine a remporté la Coupe du monde en 1998 et 2018.',
   'true', '2026-05-27 17:40:30.021056+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-00000000000f', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quel produit alimentaire est emblématique de la France ?',
   'Plusieurs produits sont emblématiques de la cuisine française : la baguette de pain, le fromage (camembert, brie, roquefort), le vin, le foie gras, les croissants.',
   'true', '2026-05-27 17:40:30.021056+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-000000000010', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quel jour férié célèbre la victoire des Alliés en 1945 ?',
   'Le 8 mai est férié en France. Il commémore la victoire des Alliés sur l''Allemagne nazie, le 8 mai 1945, qui a mis fin à la Seconde Guerre mondiale en Europe.',
   'true', '2026-05-27 17:40:30.021056+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-000000000011', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Que célèbre-t-on le 1er mai en France ?',
   'Le 1er mai est la fête du Travail. C''est un jour férié en France. On y offre traditionnellement du muguet.',
   'true', '2026-05-27 17:40:30.021056+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-000000000012', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quelle fête est célébrée le 1er janvier en France ?',
   'Le 1er janvier marque le jour de l''An (début de l''année civile). C''est un jour férié. On souhaite la bonne année à ses proches.',
   'true', '2026-05-27 17:40:30.021056+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-000000000013', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quel saint célèbre la fête de la Toussaint, jour férié ?',
   'La Toussaint, le 1er novembre, est un jour férié en France. C''est une fête catholique qui honore tous les saints.',
   'true', '2026-05-27 17:40:30.021056+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-000000000014', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quelle ville accueille la cathédrale de Notre-Dame, restaurée après l''incendie de 2019 ?',
   'Notre-Dame de Paris, gravement endommagée par un incendie en avril 2019, a été rouverte au public le 7 décembre 2024 après une restauration majeure.',
   'true', '2026-05-27 17:40:30.021056+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-000000000015', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quelle ville célèbre est connue pour ses festivals de cinéma ?',
   'Cannes accueille chaque année en mai le Festival international du film, l''un des plus prestigieux au monde. La Palme d''or y est décernée.',
   'true', '2026-05-27 17:40:30.021056+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-000000000016', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quelle ville française est appelée la ''capitale des Alpes'' ?',
   'Grenoble est souvent qualifiée de ''capitale des Alpes'', en raison de sa position au cœur du massif et de son rôle économique et universitaire dans la région.',
   'true', '2026-05-27 17:40:30.021056+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-000000000017', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quelle région est célébrée pour ses vins (Bordeaux, etc.) ?',
   'La Nouvelle-Aquitaine, autour de Bordeaux, est une des plus grandes régions viticoles de France. D''autres régions viticoles célèbres : Bourgogne, Champagne, Alsace, vallée du Rhône.',
   'true', '2026-05-27 17:40:30.021056+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-000000000018', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quelle région a comme capitale Strasbourg et est proche de l''Allemagne ?',
   'Le Grand Est (anciennes régions Alsace, Lorraine, Champagne-Ardenne), avec Strasbourg pour capitale, est frontalière de l''Allemagne, du Luxembourg, de la Belgique et de la Suisse.',
   'true', '2026-05-27 17:40:30.021056+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-000000000019', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quel événement historique a eu lieu sur les plages de Normandie en 1944 ?',
   'Le débarquement allié en Normandie a eu lieu le 6 juin 1944 (D-Day). Il a marqué le début de la libération de la France et de l''Europe occidentale par les forces alliées.',
   'true', '2026-05-27 17:40:30.021056+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-00000000001a', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quelle reine française est connue pour avoir été décapitée en 1793 ?',
   'Marie-Antoinette, épouse de Louis XVI, a été guillotinée le 16 octobre 1793 pendant la Révolution française.',
   'true', '2026-05-27 17:40:30.021056+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-00000000001b', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quel général français a appelé à la résistance le 18 juin 1940 depuis Londres ?',
   'Charles de Gaulle a lancé l''appel du 18 juin 1940 depuis la BBC à Londres, appelant les Français à poursuivre le combat contre l''occupation nazie. Cet appel a fondé la France libre.',
   'true', '2026-05-27 17:40:30.021056+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-00000000001c', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quel roi est dit le ''Roi-Soleil'' ?',
   'Louis XIV, qui a régné de 1643 à 1715, est surnommé le ''Roi-Soleil''. Il a fait construire le château de Versailles et a marqué le rayonnement de la France au XVIIe siècle.',
   'true', '2026-05-27 17:40:30.021056+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-00000000001d', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Où se trouve le château de Versailles ?',
   'Le château de Versailles est situé à Versailles, dans les Yvelines, à environ 20 km au sud-ouest de Paris. C''était la résidence des rois de France de Louis XIV à Louis XVI.',
   'true', '2026-05-27 17:40:30.021056+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-00000000001e', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Qui a peint la Joconde, exposée au Louvre ?',
   'La Joconde (Mona Lisa) a été peinte par Léonard de Vinci, peintre italien venu finir ses jours en France à la cour de François Ier (début XVIe siècle).',
   'true', '2026-05-27 17:40:30.021056+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-00000000001f', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Qui était Jeanne d''Arc, héroïne française ?',
   'Jeanne d''Arc (1412-1431) est une héroïne française du Moyen Âge. Elle a libéré Orléans, conduit Charles VII à Reims pour son sacre, puis a été brûlée vive à Rouen.',
   'true', '2026-05-27 17:40:30.021056+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-000000000020', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quelle célèbre scientifique française a reçu deux prix Nobel ?',
   'Marie Curie (1867-1934), française d''origine polonaise, a obtenu le prix Nobel de physique (1903) et de chimie (1911). Elle a découvert la radioactivité avec son mari Pierre Curie.',
   'true', '2026-05-27 17:40:30.021056+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-000000000021', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quel chien français est associé à Louis Pasteur ?',
   'Louis Pasteur (1822-1895), chimiste et biologiste français, a inventé le vaccin contre la rage en 1885. Il a aussi mis au point la pasteurisation.',
   'true', '2026-05-27 17:40:30.021056+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-000000000022', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quelle femme politique française a porté la loi sur l''IVG en 1975 ?',
   'Simone Veil (1927-2017), ministre de la Santé, a fait adopter la loi du 17 janvier 1975 dépénalisant l''IVG (avortement). Elle est entrée au Panthéon en 2018.',
   'true', '2026-05-27 17:40:30.021056+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-000000000023', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Comment appelle-t-on en France un pain long et croustillant typique ?',
   'La baguette est le pain emblématique de la France. Inscrite au patrimoine culturel immatériel de l''UNESCO en 2022.',
   'true', '2026-05-27 17:40:30.021056+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-000000000024', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quel fromage français est produit en Normandie ?',
   'Le camembert est un fromage normand emblématique, fabriqué à base de lait de vache. La Normandie produit aussi le livarot, le pont-l''évêque, le neufchâtel.',
   'true', '2026-05-27 17:40:30.021056+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-000000000025', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quelle viennoiserie est typiquement française ?',
   'Le croissant est une viennoiserie emblématique du petit-déjeuner français. Inventée à Vienne mais popularisée en France au XIXe siècle.',
   'true', '2026-05-27 17:40:30.021056+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-000000000026', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quelle est la langue officielle de la France ?',
   'Le français est la seule langue officielle de la République française (article 2 de la Constitution). Les langues régionales (breton, basque, occitan, corse) appartiennent au patrimoine.',
   'true', '2026-05-27 17:40:30.021056+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-000000000027', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quelle institution promeut la langue française dans le monde ?',
   'La Francophonie (OIF - Organisation internationale de la Francophonie) regroupe les pays ayant le français en partage. Plus de 320 millions de francophones dans le monde.',
   'true', '2026-05-27 17:40:30.021056+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-000000000028', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quand a eu lieu la prise de la Bastille ?',
   'La prise de la Bastille a eu lieu le 14 juillet 1789. Cet événement symbolique du début de la Révolution française est commémoré comme fête nationale.',
   'true', '2026-05-27 17:40:30.021056+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-000000000029', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'MISE_SITUATION',
   'Je veux visiter un monument historique français célèbre. Quels lieux gratuits ou peu chers existent ?',
   'Beaucoup de monuments offrent accès gratuit le 1er dimanche du mois (notamment musées nationaux). Les Journées du patrimoine en septembre permettent d''entrer dans des lieux d''ordinaire fermés.',
   'true', '2026-05-27 17:40:30.021056+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-00000000002a', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'MISE_SITUATION',
   'On me demande de citer un fleuve qui se jette dans la Méditerranée. Lequel choisir ?',
   'Le Rhône est le fleuve français qui se jette dans la mer Méditerranée (après Lyon, vers Marseille/la Camargue). Les autres grands fleuves (Seine, Loire, Garonne) se jettent dans l''Atlantique.',
   'true', '2026-05-27 17:40:30.021056+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-00000000002b', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'MISE_SITUATION',
   'Quelle attitude adopter face à la Marseillaise lors d''une cérémonie publique ?',
   'Il est d''usage de se tenir debout et silencieux pendant la Marseillaise. C''est une marque de respect envers l''hymne national et envers les personnes présentes à la cérémonie.',
   'true', '2026-05-27 17:40:30.021056+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-00000000002c', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'MISE_SITUATION',
   'Je veux participer aux Journées du patrimoine. Quand ont-elles lieu ?',
   'Les Journées européennes du patrimoine ont lieu chaque année le troisième week-end de septembre. De nombreux monuments publics et privés ouvrent leurs portes gratuitement.',
   'true', '2026-05-27 17:40:30.021056+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-00000000002d', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'MISE_SITUATION',
   'Quel comportement avoir devant un monument historique ou un musée ?',
   'Il faut respecter les lieux : ne pas toucher les œuvres, ne pas faire de bruit, suivre les indications, ne pas voler ni dégrader. Certaines photos peuvent être interdites.',
   'true', '2026-05-27 17:40:30.021056+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-00000000002e', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'MISE_SITUATION',
   'On me demande pourquoi le 14 juillet est important. Que dire ?',
   'Le 14 juillet est la fête nationale française. Il commémore la prise de la Bastille en 1789 (début de la Révolution) et la fête de la Fédération en 1790 (union nationale).',
   'true', '2026-05-27 17:40:30.021056+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-00000000002f', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'MISE_SITUATION',
   'Je veux assister à un défilé militaire français. Quel jour est-ce traditionnel ?',
   'Le défilé militaire du 14 juillet sur les Champs-Élysées à Paris est le grand défilé national français. D''autres cérémonies ont lieu dans les villes de garnison.',
   'true', '2026-05-27 17:40:30.021056+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-000000000030', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'MISE_SITUATION',
   'J''apprends que le 11 novembre est férié. Pourquoi est-il important ?',
   'Le 11 novembre commémore l''armistice signé en 1918, qui a mis fin à la Première Guerre mondiale. C''est l''occasion d''honorer les soldats morts pour la France et de cultiver la mémoire.',
   'true', '2026-05-27 17:40:30.021056+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-000000000031', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'MISE_SITUATION',
   'Quelqu''un me dit que la France est une monarchie. Comment lui répondre ?',
   'Non, la France n''est plus une monarchie depuis 1870 (chute de Napoléon III). Aujourd''hui, c''est une république démocratique semi-présidentielle, sous la Ve République depuis 1958.',
   'true', '2026-05-27 17:40:30.021056+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-000000000032', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CSP', 'MISE_SITUATION',
   'Je veux écouter de la musique française classique. Quels compositeurs ?',
   'Parmi les grands compositeurs français : Claude Debussy, Maurice Ravel, Hector Berlioz, Georges Bizet (Carmen), Camille Saint-Saëns, Erik Satie.',
   'true', '2026-05-27 17:40:30.021056+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-000000000033', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quel événement a abouti à l''abolition des privilèges en France ?',
   'La nuit du 4 août 1789, pendant la Révolution, l''Assemblée constituante a voté l''abolition des privilèges féodaux, mettant fin à l''Ancien Régime.',
   'true', '2026-05-27 17:40:30.037678+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-000000000034', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quel slogan symbolise la Révolution de 1789 ?',
   '''Liberté, Égalité, Fraternité'' est devenue la devise officielle de la République, héritage des principes de la Révolution. Elle est inscrite dans la Constitution.',
   'true', '2026-05-27 17:40:30.037678+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-000000000035', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Comment s''appelait l''État français pendant la Seconde Guerre mondiale, dirigé par Pétain ?',
   'Le régime de Vichy (1940-1944), dirigé par le maréchal Philippe Pétain, a collaboré avec l''Allemagne nazie. Sa devise était ''Travail, Famille, Patrie''.',
   'true', '2026-05-27 17:40:30.037678+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-000000000036', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Comment s''appelait le mouvement de Charles de Gaulle pendant la Seconde Guerre mondiale ?',
   'La France libre (puis France combattante) fut le mouvement de résistance fondé par Charles de Gaulle depuis Londres après l''appel du 18 juin 1940.',
   'true', '2026-05-27 17:40:30.037678+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-000000000037', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CR', 'CONNAISSANCE',
   'En quelle année la France a-t-elle accordé le droit de vote aux femmes ?',
   'Les femmes françaises ont obtenu le droit de vote par l''ordonnance du 21 avril 1944, signée par le général de Gaulle à Alger. Elles ont voté pour la première fois en 1945.',
   'true', '2026-05-27 17:40:30.037678+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f4000002-0000-0000-0000-000000000038', 'CIVIQUE', '11111111-0000-0000-0000-000000000004', NULL, NULL, 'CR', 'CONNAISSANCE',
   'En quelle année la guerre d''Algérie s''est-elle terminée ?',
   'La guerre d''Algérie (1954-1962) s''est terminée par les accords d''Évian le 18 mars 1962. L''indépendance de l''Algérie a été proclamée le 5 juillet 1962.',
   'true', '2026-05-27 17:40:30.037678+02', NULL, 'ACTIVE', NULL, NULL, NULL);

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('636bed8a-3815-4bfd-823f-6a3200cf23c3', 'f4000002-0000-0000-0000-000000000007',
   'Le drapeau de la République française',
   'true', '0'),

  ('39b26051-2216-4f2f-afac-d010c1db4517', 'f4000002-0000-0000-0000-000000000007',
   'Le drapeau d''une région',
   'false', '1'),

  ('61ab7293-4640-48a5-9908-a3a1a34fb0db', 'f4000002-0000-0000-0000-000000000007',
   'Un drapeau européen',
   'false', '2'),

  ('c2d4dbe7-8b8f-4e5f-877d-cc2d8c9718ba', 'f4000002-0000-0000-0000-000000000007',
   'Le drapeau de Paris',
   'false', '3'),

  ('883631d4-2407-4085-92a7-38b031ba15f3', 'f4000002-0000-0000-0000-000000000008',
   'La Marseillaise',
   'true', '0'),

  ('49b22755-bc2a-466e-9653-4c5a40f23658', 'f4000002-0000-0000-0000-000000000008',
   'God Save the Queen',
   'false', '1'),

  ('18ced5d7-7b8f-4a46-a08f-7ad6cc9be106', 'f4000002-0000-0000-0000-000000000008',
   'L''Ode à la joie',
   'false', '2'),

  ('3d24d867-ea81-4151-b089-1cf33cf51b28', 'f4000002-0000-0000-0000-000000000008',
   'L''Internationale',
   'false', '3'),

  ('ee03af40-c595-47e8-b0a8-bc759089d132', 'f4000002-0000-0000-0000-000000000009',
   'Liberté, Égalité, Fraternité',
   'true', '0'),

  ('bced8466-24d5-4043-949b-a520b731f3c0', 'f4000002-0000-0000-0000-000000000009',
   'Travail, Famille, Patrie',
   'false', '1'),

  ('be816036-0bfc-4566-9ba5-5c201bb47ac2', 'f4000002-0000-0000-0000-000000000009',
   'Un pour tous, tous pour un',
   'false', '2'),

  ('597cf9f4-b833-4cb5-ae37-dd887c17f53a', 'f4000002-0000-0000-0000-000000000009',
   'In God we trust',
   'false', '3'),

  ('9db84487-1904-4294-9ca8-0f7d504ddccf', 'f4000002-0000-0000-0000-00000000000a',
   'Marianne',
   'true', '0'),

  ('d283dd75-1375-418d-992c-c3530885b7ce', 'f4000002-0000-0000-0000-00000000000a',
   'Jeanne d''Arc',
   'false', '1'),

  ('68d9acc4-7c78-457a-916b-33de19e7dc1b', 'f4000002-0000-0000-0000-00000000000a',
   'Brigitte Bardot',
   'false', '2'),

  ('56f6f653-9f5b-4698-819d-9b4c9edcba51', 'f4000002-0000-0000-0000-00000000000a',
   'La Vierge Marie',
   'false', '3'),

  ('09beae48-434d-42c2-b20d-2cf87d3959a7', 'f4000002-0000-0000-0000-00000000000b',
   'Le coq gaulois',
   'true', '0'),

  ('3f315b7b-edc1-457d-bb52-5ce6994afdbd', 'f4000002-0000-0000-0000-00000000000b',
   'L''aigle impérial',
   'false', '1'),

  ('293d9182-0220-443a-90dd-c061cd9ce409', 'f4000002-0000-0000-0000-00000000000b',
   'Le lion britannique',
   'false', '2'),

  ('444ab9ca-60b5-44cf-9c70-b97a6b419ca5', 'f4000002-0000-0000-0000-00000000000b',
   'L''ours russe',
   'false', '3'),

  ('8410c4cc-7afb-490a-9ebd-5f8f6bae1e5e', 'f4000002-0000-0000-0000-00000000000c',
   'L''arrivée du Tour de France',
   'true', '0'),

  ('11eb54e5-f1c7-48b6-89f5-e502e96658d0', 'f4000002-0000-0000-0000-00000000000c',
   'Roland-Garros',
   'false', '1'),

  ('b2267c4c-1d2f-4dff-9a91-14d4dd3574be', 'f4000002-0000-0000-0000-00000000000c',
   'Le marathon de Paris',
   'false', '2'),

  ('ad7afe34-977d-4825-a9a3-8791f574d200', 'f4000002-0000-0000-0000-00000000000c',
   'Les 24 heures du Mans',
   'false', '3'),

  ('c0c9664c-0c0d-4411-ae60-7d17d7b22257', 'f4000002-0000-0000-0000-00000000000d',
   'Roland-Garros',
   'true', '0'),

  ('695ef44a-564f-421e-bd5f-4cb07224ccb1', 'f4000002-0000-0000-0000-00000000000d',
   'Wimbledon',
   'false', '1'),

  ('d8f491da-3ade-407c-8aa8-9af800b0a1ad', 'f4000002-0000-0000-0000-00000000000d',
   'US Open',
   'false', '2'),

  ('afacaa40-d821-4120-8526-ff9fe53e8760', 'f4000002-0000-0000-0000-00000000000d',
   'Australian Open',
   'false', '3'),

  ('4443a6fb-1f67-4782-b2ab-d1d7faa8ab06', 'f4000002-0000-0000-0000-00000000000e',
   'Le football',
   'true', '0'),

  ('0b4937ae-7767-4364-80b6-c8b89b27f386', 'f4000002-0000-0000-0000-00000000000e',
   'Le base-ball',
   'false', '1'),

  ('f7d4745e-1516-46c1-b769-f81a2f08e009', 'f4000002-0000-0000-0000-00000000000e',
   'Le cricket',
   'false', '2'),

  ('3a6bbb01-b623-4914-a15b-51c5055fca5f', 'f4000002-0000-0000-0000-00000000000e',
   'Le golf',
   'false', '3'),

  ('4f46ef71-bf9b-4a75-8e70-7fdc19bcbf7b', 'f4000002-0000-0000-0000-00000000000f',
   'La baguette de pain',
   'true', '0'),

  ('25347ce1-9dbf-4bd4-8b7d-1f4722ea9b35', 'f4000002-0000-0000-0000-00000000000f',
   'Le riz blanc',
   'false', '1'),

  ('7dbba8a5-efc7-4db5-8da9-f816db814edb', 'f4000002-0000-0000-0000-00000000000f',
   'Le hamburger',
   'false', '2'),

  ('42756cb6-46c9-4fe6-a629-43e1f64ddc39', 'f4000002-0000-0000-0000-00000000000f',
   'Le sushi',
   'false', '3'),

  ('b8da38a8-7303-4508-92c3-f92c022e3ad1', 'f4000002-0000-0000-0000-000000000010',
   'Le 8 mai',
   'true', '0'),

  ('3027eb3e-d1fa-4300-b1fb-3075704cc70c', 'f4000002-0000-0000-0000-000000000010',
   'Le 11 novembre',
   'false', '1'),

  ('d7d80d58-4565-435a-86c6-8657be557cc7', 'f4000002-0000-0000-0000-000000000010',
   'Le 14 juillet',
   'false', '2'),

  ('290d10ad-447a-4004-a403-5f651b3d03bc', 'f4000002-0000-0000-0000-000000000010',
   'Le 1er mai',
   'false', '3'),

  ('e6910d40-209f-4acc-b6d2-9f0c98f540c5', 'f4000002-0000-0000-0000-000000000011',
   'La fête du Travail',
   'true', '0'),

  ('49248e8d-bf8c-470b-be65-40db53901ed1', 'f4000002-0000-0000-0000-000000000011',
   'La fête nationale',
   'false', '1'),

  ('f475f884-b555-45ae-abb1-15be1d314fcb', 'f4000002-0000-0000-0000-000000000011',
   'L''armistice',
   'false', '2'),

  ('1a8c6a67-244c-4f8e-a88b-ca8c69ea24ca', 'f4000002-0000-0000-0000-000000000011',
   'La fête de l''Europe',
   'false', '3'),

  ('cec0afee-44d0-4008-ae3b-a5ffcd548bab', 'f4000002-0000-0000-0000-000000000012',
   'Le jour de l''An',
   'true', '0'),

  ('fc6d7bee-a2c9-4d3d-981b-3646513ceb9d', 'f4000002-0000-0000-0000-000000000012',
   'Noël',
   'false', '1'),

  ('df796ba0-b8d2-4d64-ab99-e3b170554108', 'f4000002-0000-0000-0000-000000000012',
   'Pâques',
   'false', '2'),

  ('912ed6c6-1711-432a-bc5a-6acbe0c0deb9', 'f4000002-0000-0000-0000-000000000012',
   'L''Ascension',
   'false', '3'),

  ('58339a3f-5ed1-46ac-9512-be1008a31bb7', 'f4000002-0000-0000-0000-000000000013',
   'Tous les saints (fête catholique)',
   'true', '0'),

  ('a474cce2-06a0-4779-8a05-a088bc396b0d', 'f4000002-0000-0000-0000-000000000013',
   'Saint Nicolas',
   'false', '1'),

  ('0b0ba300-faf7-434a-a79d-61be3c18ced2', 'f4000002-0000-0000-0000-000000000013',
   'Saint Patrick',
   'false', '2'),

  ('0bf69ca5-78dc-4584-8581-aded23e9e2bd', 'f4000002-0000-0000-0000-000000000013',
   'Saint Valentin',
   'false', '3'),

  ('78ae7be6-0c77-4ab2-b8dd-20c4a50ef9fb', 'f4000002-0000-0000-0000-000000000014',
   'Paris',
   'true', '0'),

  ('b8536c5d-8408-4ad8-8289-66c6525bd06d', 'f4000002-0000-0000-0000-000000000014',
   'Reims',
   'false', '1'),

  ('94a12688-d9e1-49ad-b9cb-747a0c67de94', 'f4000002-0000-0000-0000-000000000014',
   'Strasbourg',
   'false', '2'),

  ('264ff183-8b59-4805-a2e2-0e12b663c5a4', 'f4000002-0000-0000-0000-000000000014',
   'Lyon',
   'false', '3'),

  ('b9f267e3-4c24-4f78-adb1-f6e596854495', 'f4000002-0000-0000-0000-000000000015',
   'Cannes (Festival du film)',
   'true', '0'),

  ('23651694-2afd-48dc-a934-98a57b56e442', 'f4000002-0000-0000-0000-000000000015',
   'Lille',
   'false', '1'),

  ('eecfda2b-12d8-4def-a5a6-7376c5adb373', 'f4000002-0000-0000-0000-000000000015',
   'Brest',
   'false', '2'),

  ('161a82e3-75f8-4869-b1d9-12eeda2ef7a3', 'f4000002-0000-0000-0000-000000000015',
   'Limoges',
   'false', '3'),

  ('c65c018e-88e7-462c-8d89-9a09dd3026ba', 'f4000002-0000-0000-0000-000000000016',
   'Grenoble',
   'true', '0'),

  ('3382aa42-fe70-4db2-ad77-51126ec7e627', 'f4000002-0000-0000-0000-000000000016',
   'Lyon',
   'false', '1'),

  ('94f94aea-d9db-41fc-8bc3-e1d1eec34646', 'f4000002-0000-0000-0000-000000000016',
   'Nice',
   'false', '2'),

  ('72921217-b0b0-463c-8663-25fdc8292c08', 'f4000002-0000-0000-0000-000000000016',
   'Annecy',
   'false', '3'),

  ('6519b44a-c56d-4108-8b8c-12b288b60877', 'f4000002-0000-0000-0000-000000000017',
   'La Nouvelle-Aquitaine (région de Bordeaux)',
   'true', '0'),

  ('26b0f840-98d0-42f1-b278-fcfc958d1e7b', 'f4000002-0000-0000-0000-000000000017',
   'L''Île-de-France',
   'false', '1'),

  ('cb02aa7a-bc53-4ff7-be5f-f7a47a844614', 'f4000002-0000-0000-0000-000000000017',
   'Le Nord',
   'false', '2'),

  ('2cd2f319-0c69-43d9-a12f-1fa8b9e9ac15', 'f4000002-0000-0000-0000-000000000017',
   'La Bretagne',
   'false', '3'),

  ('a82586d4-477a-4f4d-a778-ff293217cde4', 'f4000002-0000-0000-0000-000000000018',
   'Le Grand Est',
   'true', '0'),

  ('bc99d166-c979-4000-8388-58f5138d6a36', 'f4000002-0000-0000-0000-000000000018',
   'La Bretagne',
   'false', '1'),

  ('d0e27396-9222-4a00-b71c-72300557ca85', 'f4000002-0000-0000-0000-000000000018',
   'La Provence',
   'false', '2'),

  ('87b17f76-5088-4a4e-9507-9828f72deb1d', 'f4000002-0000-0000-0000-000000000018',
   'L''Île-de-France',
   'false', '3'),

  ('f983b954-63fa-4394-adb9-accec53f723d', 'f4000002-0000-0000-0000-000000000019',
   'Le débarquement des Alliés (6 juin 1944)',
   'true', '0'),

  ('d174ec46-c653-49d4-b3c5-05e6f8c830a8', 'f4000002-0000-0000-0000-000000000019',
   'La Révolution française',
   'false', '1'),

  ('aa5a4770-ee08-44bf-9039-3dd4beb8efd5', 'f4000002-0000-0000-0000-000000000019',
   'La Première Guerre mondiale',
   'false', '2'),

  ('d74b8ab5-d604-476f-abe0-5fc1da241919', 'f4000002-0000-0000-0000-000000000019',
   'L''expédition d''Égypte',
   'false', '3'),

  ('42cbfbb6-af85-417c-89b8-16f1840f9000', 'f4000002-0000-0000-0000-00000000001a',
   'Marie-Antoinette',
   'true', '0'),

  ('e7aac10a-25e2-4d11-b387-d55f8b630db0', 'f4000002-0000-0000-0000-00000000001a',
   'Catherine de Médicis',
   'false', '1'),

  ('d74fc551-df9c-4b7c-8849-ed4bdb7e5f50', 'f4000002-0000-0000-0000-00000000001a',
   'Jeanne d''Arc',
   'false', '2'),

  ('c2fafcc9-b02b-433c-83f9-75e9a72ab011', 'f4000002-0000-0000-0000-00000000001a',
   'Aliénor d''Aquitaine',
   'false', '3'),

  ('f6314e06-acca-4116-933c-3b8e79212a0c', 'f4000002-0000-0000-0000-00000000001b',
   'Charles de Gaulle',
   'true', '0'),

  ('fd2acdfd-84be-4a0d-a9e1-826aca3b1e82', 'f4000002-0000-0000-0000-00000000001b',
   'Philippe Pétain',
   'false', '1'),

  ('457b3fa0-630e-4aee-93b7-06612cd2c208', 'f4000002-0000-0000-0000-00000000001b',
   'Joseph Joffre',
   'false', '2'),

  ('1dfbf882-bad9-4e59-8299-7d4698fce4b6', 'f4000002-0000-0000-0000-00000000001b',
   'Ferdinand Foch',
   'false', '3'),

  ('7b65c65f-b6f2-4c93-950f-a7944f2001e7', 'f4000002-0000-0000-0000-00000000001c',
   'Louis XIV (Roi-Soleil)',
   'true', '0'),

  ('ba573d65-1d22-4eed-b966-a2883840dfbc', 'f4000002-0000-0000-0000-00000000001c',
   'Louis XVI',
   'false', '1'),

  ('d45d1301-dab6-4201-bf4a-9a4dd7111182', 'f4000002-0000-0000-0000-00000000001c',
   'Henri IV',
   'false', '2'),

  ('7b24522f-c037-4f59-84da-45e8cc816c38', 'f4000002-0000-0000-0000-00000000001c',
   'François Ier',
   'false', '3'),

  ('b67d32fb-c4a6-4d8e-8980-24b0d2b5fff3', 'f4000002-0000-0000-0000-00000000001d',
   'À Versailles, près de Paris',
   'true', '0'),

  ('fb1d007b-b9bf-4427-a800-204f37b2b925', 'f4000002-0000-0000-0000-00000000001d',
   'À Paris même',
   'false', '1'),

  ('2f956608-54e3-4a4a-b138-fa708c198cdf', 'f4000002-0000-0000-0000-00000000001d',
   'À Lyon',
   'false', '2'),

  ('5c7573c8-ea2f-4e32-ac29-fef0490a8f8e', 'f4000002-0000-0000-0000-00000000001d',
   'À Marseille',
   'false', '3'),

  ('b90afa83-7e8e-4ffc-a515-e46dac63901a', 'f4000002-0000-0000-0000-00000000001e',
   'Léonard de Vinci',
   'true', '0'),

  ('24da3273-092a-4e0f-868e-b44b0cb937c4', 'f4000002-0000-0000-0000-00000000001e',
   'Pablo Picasso',
   'false', '1'),

  ('fe66179c-8a47-4436-ac3e-6c7f42bc21d3', 'f4000002-0000-0000-0000-00000000001e',
   'Claude Monet',
   'false', '2'),

  ('61d0b31e-7e7d-4f3c-ac8f-1b8cdd745fb5', 'f4000002-0000-0000-0000-00000000001e',
   'Vincent Van Gogh',
   'false', '3'),

  ('9703cb14-27f4-470c-bf9d-e89d290d02d2', 'f4000002-0000-0000-0000-00000000001f',
   'Une héroïne française du XVe siècle',
   'true', '0'),

  ('3835a36e-8650-438b-bfc6-c0fe0b53a1f3', 'f4000002-0000-0000-0000-00000000001f',
   'Une reine de France',
   'false', '1'),

  ('bcbb7710-5552-40f3-a33b-9d1279a2cc3b', 'f4000002-0000-0000-0000-00000000001f',
   'Une scientifique',
   'false', '2'),

  ('b527e8a9-2a77-4270-bdad-db6fea68e74a', 'f4000002-0000-0000-0000-00000000001f',
   'Une chanteuse',
   'false', '3'),

  ('76ef5cf4-bae9-4145-811a-19a756527efd', 'f4000002-0000-0000-0000-000000000020',
   'Marie Curie',
   'true', '0'),

  ('20d844b9-6cfb-4575-b869-38b8071578d6', 'f4000002-0000-0000-0000-000000000020',
   'Marie-Antoinette',
   'false', '1'),

  ('12743612-0e9d-46c3-919e-f887601372ab', 'f4000002-0000-0000-0000-000000000020',
   'Édith Piaf',
   'false', '2'),

  ('19cb49d2-cf57-481d-8b9a-67bb1df96351', 'f4000002-0000-0000-0000-000000000020',
   'Coco Chanel',
   'false', '3'),

  ('328f0816-84cf-4162-852f-e15d1d09b17e', 'f4000002-0000-0000-0000-000000000021',
   'Le chien vacciné contre la rage (Pasteur, 1885)',
   'true', '0'),

  ('6d4ee976-1fbb-47d2-b60f-96e087f67f56', 'f4000002-0000-0000-0000-000000000021',
   'Le berger allemand',
   'false', '1'),

  ('fa80c6a8-21aa-44ba-9f88-f056df5282e9', 'f4000002-0000-0000-0000-000000000021',
   'Le caniche royal',
   'false', '2'),

  ('af609099-df5f-4948-aa78-9e73a9935d3c', 'f4000002-0000-0000-0000-000000000021',
   'Aucun chien spécifique',
   'false', '3'),

  ('5decbeeb-caa2-4c0d-9ce8-d7d2f339e68d', 'f4000002-0000-0000-0000-000000000022',
   'Simone Veil',
   'true', '0'),

  ('4b395339-9757-4119-b6f4-f0a78af42d11', 'f4000002-0000-0000-0000-000000000022',
   'Simone de Beauvoir',
   'false', '1'),

  ('377d0942-7124-4c6a-acdc-e057f5821fec', 'f4000002-0000-0000-0000-000000000022',
   'Édith Cresson',
   'false', '2'),

  ('65fff493-08e5-4e03-8c39-940d1dd0a451', 'f4000002-0000-0000-0000-000000000022',
   'Olympe de Gouges',
   'false', '3'),

  ('8ddb05be-8a4e-43fb-94be-555ca1de3eb7', 'f4000002-0000-0000-0000-000000000023',
   'La baguette',
   'true', '0'),

  ('273aee19-08bc-4a17-86bd-9aa8edbbdfa4', 'f4000002-0000-0000-0000-000000000023',
   'La galette',
   'false', '1'),

  ('333ed82e-17e0-4924-9d11-b4fd17776392', 'f4000002-0000-0000-0000-000000000023',
   'Le bagel',
   'false', '2'),

  ('bae8e8df-e0c3-4b35-9f0b-5454b87f1020', 'f4000002-0000-0000-0000-000000000023',
   'Le pain de mie',
   'false', '3'),

  ('5b78527f-f848-4b38-a1c1-c7166cae43f5', 'f4000002-0000-0000-0000-000000000024',
   'Le camembert',
   'true', '0'),

  ('cdd09ab0-b83a-47c9-9240-b62ae79b541d', 'f4000002-0000-0000-0000-000000000024',
   'Le parmesan',
   'false', '1'),

  ('8e84826a-5c2e-45a1-a239-b63a5d40d682', 'f4000002-0000-0000-0000-000000000024',
   'Le cheddar',
   'false', '2'),

  ('cba0bb44-12fe-41ff-b333-32a082f2232a', 'f4000002-0000-0000-0000-000000000024',
   'La feta',
   'false', '3'),

  ('786ef4a7-b0bd-4547-a316-c06ff854320b', 'f4000002-0000-0000-0000-000000000025',
   'Le croissant',
   'true', '0'),

  ('75062c18-2e24-4847-a9b4-81caa5eb3cfa', 'f4000002-0000-0000-0000-000000000025',
   'Le donut',
   'false', '1'),

  ('30590233-58b4-447a-877c-7c0c149d26b6', 'f4000002-0000-0000-0000-000000000025',
   'Le bagel',
   'false', '2'),

  ('0f079e4c-45b0-4668-a817-c9f9b6e9326d', 'f4000002-0000-0000-0000-000000000025',
   'Le pretzel',
   'false', '3'),

  ('5a2d1bf6-afdc-4742-8ec0-7db77ef9690a', 'f4000002-0000-0000-0000-000000000026',
   'Le français',
   'true', '0'),

  ('cf583477-e64f-4cee-a796-803fc350e880', 'f4000002-0000-0000-0000-000000000026',
   'L''anglais',
   'false', '1'),

  ('9e589373-060b-4dff-a71d-c65ef0a042c4', 'f4000002-0000-0000-0000-000000000026',
   'L''allemand',
   'false', '2'),

  ('3ec5c600-c249-4456-8721-ea6b81037074', 'f4000002-0000-0000-0000-000000000026',
   'L''espagnol',
   'false', '3'),

  ('2a099403-8d0c-46a6-9cf1-19087853637f', 'f4000002-0000-0000-0000-000000000027',
   'L''Organisation internationale de la Francophonie (OIF)',
   'true', '0'),

  ('64384c97-3903-4393-9df7-15514328f81d', 'f4000002-0000-0000-0000-000000000027',
   'L''ONU',
   'false', '1'),

  ('7785ee86-2a05-48ce-b0d9-c9aff8b9cc38', 'f4000002-0000-0000-0000-000000000027',
   'L''OTAN',
   'false', '2'),

  ('1a2015ea-e78f-4969-99a2-39c57fce5724', 'f4000002-0000-0000-0000-000000000027',
   'L''UNESCO',
   'false', '3'),

  ('61d3e3f2-922c-42b8-8805-5a4e9a9a842f', 'f4000002-0000-0000-0000-000000000028',
   'Le 14 juillet 1789',
   'true', '0'),

  ('c5652f0c-d1c3-4dac-9d75-6ed00ee075fb', 'f4000002-0000-0000-0000-000000000028',
   'Le 4 août 1789',
   'false', '1'),

  ('6e144611-aa3a-474d-94b5-7655461c45d0', 'f4000002-0000-0000-0000-000000000028',
   'Le 26 août 1789',
   'false', '2'),

  ('c78facfe-3b04-4189-bf5c-0b3f7aa86e7c', 'f4000002-0000-0000-0000-000000000028',
   'Le 14 juillet 1880',
   'false', '3'),

  ('96ca5450-05b6-42a3-a39e-70e10ad66592', 'f4000002-0000-0000-0000-000000000029',
   'Le 1er dimanche du mois ou les Journées du patrimoine',
   'true', '0'),

  ('587ffa0e-aca1-4d31-b30f-7fb065a37dba', 'f4000002-0000-0000-0000-000000000029',
   'Aucune visite gratuite',
   'false', '1'),

  ('66d0d14e-2ade-4c58-9279-76d63cbb0935', 'f4000002-0000-0000-0000-000000000029',
   'Uniquement avec un guide payé',
   'false', '2'),

  ('8c691f1a-e453-4807-905a-25381cf911bd', 'f4000002-0000-0000-0000-000000000029',
   'Uniquement les militaires',
   'false', '3'),

  ('b5c1687f-d0f4-4589-88bb-13b4f7732c15', 'f4000002-0000-0000-0000-00000000002a',
   'Le Rhône',
   'true', '0'),

  ('c12e31f6-9d90-4113-93b3-fd9891372b19', 'f4000002-0000-0000-0000-00000000002a',
   'La Seine',
   'false', '1'),

  ('1f3910c3-1111-47ac-9a35-9df57c2db2d9', 'f4000002-0000-0000-0000-00000000002a',
   'La Loire',
   'false', '2'),

  ('36b17db9-32c8-471a-b0b4-95e249c03d51', 'f4000002-0000-0000-0000-00000000002a',
   'La Garonne',
   'false', '3'),

  ('60cef56e-51c9-4574-9ddd-113b8521577c', 'f4000002-0000-0000-0000-00000000002b',
   'Se lever et rester silencieux par respect',
   'true', '0'),

  ('ece09f35-3d66-411e-a688-62ec2b3a42db', 'f4000002-0000-0000-0000-00000000002b',
   'Continuer ses conversations',
   'false', '1'),

  ('708930ab-494a-4cc0-a0f7-5cf2c5d00b79', 'f4000002-0000-0000-0000-00000000002b',
   'Sortir de la salle',
   'false', '2'),

  ('6bf87886-a8d3-496b-8814-3c8e9cfd7c40', 'f4000002-0000-0000-0000-00000000002b',
   'Mettre une musique différente',
   'false', '3'),

  ('6065a118-a3c7-4a33-8c6c-ed23948f8cbd', 'f4000002-0000-0000-0000-00000000002c',
   'Le troisième week-end de septembre',
   'true', '0'),

  ('1fa6016f-311c-4ac2-ac7c-603e0e542f18', 'f4000002-0000-0000-0000-00000000002c',
   'Le 14 juillet',
   'false', '1'),

  ('fc6e17fe-8f2c-4cf6-87a1-c73a7d2f81e8', 'f4000002-0000-0000-0000-00000000002c',
   'Au mois de mai',
   'false', '2'),

  ('84eeb761-2b78-42a8-9f6b-6b7ca2b0deac', 'f4000002-0000-0000-0000-00000000002c',
   'À Noël',
   'false', '3'),

  ('51639751-2ce7-4791-8822-9f4fb9249289', 'f4000002-0000-0000-0000-00000000002d',
   'Respect des lieux, des règles, et silence',
   'true', '0'),

  ('2da6784b-f2d9-4a65-94c4-27b37ca83f93', 'f4000002-0000-0000-0000-00000000002d',
   'Toucher les œuvres',
   'false', '1'),

  ('6c7ce1e9-1819-4899-b6d5-6aeaf39fe28b', 'f4000002-0000-0000-0000-00000000002d',
   'Faire la fête bruyamment',
   'false', '2'),

  ('a0bb2b35-2890-4859-94fc-eb5dd1d8e0a9', 'f4000002-0000-0000-0000-00000000002d',
   'Voler des souvenirs',
   'false', '3'),

  ('7035f40f-9428-4c3b-adbd-7b4ee7a26574', 'f4000002-0000-0000-0000-00000000002e',
   'Fête nationale (prise de la Bastille en 1789)',
   'true', '0'),

  ('4de1fde9-43fc-4d47-9475-d99b05bff68d', 'f4000002-0000-0000-0000-00000000002e',
   'Anniversaire du roi',
   'false', '1'),

  ('4e6d6286-888e-44e2-aec5-5bfce86db961', 'f4000002-0000-0000-0000-00000000002e',
   'Jour de la rentrée scolaire',
   'false', '2'),

  ('58994bec-9bc3-4ed6-a675-0028e8b049f2', 'f4000002-0000-0000-0000-00000000002e',
   'Jour de l''Europe',
   'false', '3'),

  ('6e2bd38e-006d-49a4-a523-876a8238b2c3', 'f4000002-0000-0000-0000-00000000002f',
   'Le 14 juillet (défilé sur les Champs-Élysées)',
   'true', '0'),

  ('80bed8a2-1fb5-45c9-bfc4-7b0aae27848e', 'f4000002-0000-0000-0000-00000000002f',
   'Le 1er janvier',
   'false', '1'),

  ('ec3ee7a0-97f2-4d54-b4b8-48df69b3ef51', 'f4000002-0000-0000-0000-00000000002f',
   'Le 25 décembre',
   'false', '2'),

  ('f919fd06-db5f-41da-a6cb-fcf8bd0b6f41', 'f4000002-0000-0000-0000-00000000002f',
   'Le 1er avril',
   'false', '3'),

  ('5ce7309a-fa63-434a-988c-bf19531eb88e', 'f4000002-0000-0000-0000-000000000030',
   'Armistice de 1918 et hommage aux soldats morts',
   'true', '0'),

  ('708a0aca-7dad-442a-814c-fc4a6fc8dc2e', 'f4000002-0000-0000-0000-000000000030',
   'Fête des familles',
   'false', '1'),

  ('3844062b-2b3a-455f-8a28-65a9060e06d3', 'f4000002-0000-0000-0000-000000000030',
   'Naissance d''un président',
   'false', '2'),

  ('4360f3cb-3659-4c65-a007-c88e0e6b2c01', 'f4000002-0000-0000-0000-000000000030',
   'Indépendance de l''Algérie',
   'false', '3'),

  ('2e838573-28bc-4ef6-9562-648260c16205', 'f4000002-0000-0000-0000-000000000031',
   'Non, la France est une république depuis 1870',
   'true', '0'),

  ('cf7ea0e9-3e4e-456d-bfbf-66eba6b68f2c', 'f4000002-0000-0000-0000-000000000031',
   'Oui, le roi gouverne',
   'false', '1'),

  ('5944ca05-8fd3-40b6-8739-07061c372db0', 'f4000002-0000-0000-0000-000000000031',
   'Cela dépend du jour',
   'false', '2'),

  ('35b68239-fc3f-4283-bf17-97d85f533b8e', 'f4000002-0000-0000-0000-000000000031',
   'C''est une monarchie d''Europe',
   'false', '3'),

  ('9dcb7f83-6165-45f8-a46e-6391b90b351e', 'f4000002-0000-0000-0000-000000000032',
   'Debussy, Ravel, Berlioz, Bizet',
   'true', '0'),

  ('3a8661ab-4f54-4641-ad53-e87d860def9f', 'f4000002-0000-0000-0000-000000000032',
   'Mozart, Bach, Beethoven',
   'false', '1'),

  ('725506ec-a1da-4cde-9876-48ea42d8fc09', 'f4000002-0000-0000-0000-000000000032',
   'Verdi, Puccini, Rossini',
   'false', '2'),

  ('10757383-9763-4d57-aa09-72ed887de5bb', 'f4000002-0000-0000-0000-000000000032',
   'Aucun compositeur français célèbre',
   'false', '3'),

  ('439c45ff-4bf3-40e4-a076-4c421e953939', 'f4000002-0000-0000-0000-000000000033',
   'La nuit du 4 août 1789',
   'true', '0'),

  ('f1554c21-2812-4a36-a5b6-5034adeaa946', 'f4000002-0000-0000-0000-000000000033',
   'La prise de la Bastille',
   'false', '1'),

  ('de0d1e28-7a26-43c3-b088-4865097a0322', 'f4000002-0000-0000-0000-000000000033',
   'Le couronnement de Napoléon',
   'false', '2'),

  ('028c7549-76a8-4991-9388-f917ddc924b9', 'f4000002-0000-0000-0000-000000000033',
   'La Libération de Paris',
   'false', '3'),

  ('4d2618ac-96db-4c47-931e-f3c7e7d27f9d', 'f4000002-0000-0000-0000-000000000034',
   'Liberté, Égalité, Fraternité',
   'true', '0'),

  ('12d6c25c-dd48-4f8a-9017-e28e6a5c6a84', 'f4000002-0000-0000-0000-000000000034',
   'Travail, Famille, Patrie',
   'false', '1'),

  ('e602b088-69cd-4096-b7a0-5b4a76157673', 'f4000002-0000-0000-0000-000000000034',
   'Tous pour un, un pour tous',
   'false', '2'),

  ('95da3625-a46c-4302-94f4-5137ec090e9a', 'f4000002-0000-0000-0000-000000000034',
   'Dieu, le roi, la patrie',
   'false', '3'),

  ('84d047e1-7885-4862-9912-85ef54491faa', 'f4000002-0000-0000-0000-000000000035',
   'Le régime de Vichy',
   'true', '0'),

  ('941cd1c2-e33b-4d28-90a9-2a6d87ed0260', 'f4000002-0000-0000-0000-000000000035',
   'La IIIe République',
   'false', '1'),

  ('97f225f2-b252-4246-8e09-abe79f90575c', 'f4000002-0000-0000-0000-000000000035',
   'La France libre',
   'false', '2'),

  ('3618ff48-de24-41ca-be13-c0df786c6f45', 'f4000002-0000-0000-0000-000000000035',
   'L''Empire napoléonien',
   'false', '3'),

  ('39194ba8-40a7-4379-a760-4834bf387174', 'f4000002-0000-0000-0000-000000000036',
   'La France libre',
   'true', '0'),

  ('74a34dc1-253a-4cde-8e3c-ede743aeae9e', 'f4000002-0000-0000-0000-000000000036',
   'Le Front populaire',
   'false', '1'),

  ('274ff46a-43d4-44d2-8f6a-9da78914d243', 'f4000002-0000-0000-0000-000000000036',
   'La Commune',
   'false', '2'),

  ('7f7f6f32-8adb-4422-958d-ef8a4078e218', 'f4000002-0000-0000-0000-000000000036',
   'La Sainte Alliance',
   'false', '3'),

  ('66782e47-8492-4ad1-aa9c-15f146efe9ce', 'f4000002-0000-0000-0000-000000000037',
   '1944',
   'true', '0'),

  ('a1fefef3-6e1c-48d5-8db9-fdfc6b304a92', 'f4000002-0000-0000-0000-000000000037',
   '1789',
   'false', '1'),

  ('5cd6e454-9c76-4df0-b5c9-ec0c9908c4c3', 'f4000002-0000-0000-0000-000000000037',
   '1881',
   'false', '2'),

  ('f1eee0ad-fb17-4246-b3ad-bf2e81e08ce5', 'f4000002-0000-0000-0000-000000000037',
   '1958',
   'false', '3'),

  ('2d233aaf-3339-494a-82fc-17d03bb7fecc', 'f4000002-0000-0000-0000-000000000038',
   '1962 (accords d''Évian)',
   'true', '0'),

  ('111195ec-2813-4c3e-b7e7-4282c2f201f3', 'f4000002-0000-0000-0000-000000000038',
   '1945',
   'false', '1'),

  ('58ffe24f-2e14-46ca-9be2-b29377ec1b66', 'f4000002-0000-0000-0000-000000000038',
   '1968',
   'false', '2'),

  ('15483c1c-d3aa-46fe-b8e6-347b08615f47', 'f4000002-0000-0000-0000-000000000038',
   '1981',
   'false', '3');
