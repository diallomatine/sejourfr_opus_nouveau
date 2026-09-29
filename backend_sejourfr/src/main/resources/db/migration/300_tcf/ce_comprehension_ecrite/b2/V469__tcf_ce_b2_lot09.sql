-- ============================================================================
-- V469 — TCF CE B2 — lot 09 (thème : ville & mobilité)
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id = 22222222-0000-0000-0000-000000000002,
-- difficulty = 'B2'. 7 items, textes longs (~185-215 mots), compréhension
-- implicite (idée principale, inférence d'intention, ton de l'auteur).
-- Angles : piétonnisation des centres-villes, trottinettes en libre-service,
-- gratuité des transports en commun, ville du quart d'heure, limitation à
-- 30 km/h, politique cyclable, RER métropolitains.
-- UUID déterministes, rejouables dev + recette.
-- ============================================================================


-- passages — supports de lecture référencés par les questions ci-dessous
INSERT INTO passages
  (id, type, content, media_id, theme_id)
VALUES
  ('11111111-c009-4000-0000-000000000001', 'TEXTE',
   'La piétonnisation du centre-ville fait partout lever les mêmes boucliers. À Angoulême comme à Mulhouse, les commerçants prédisent la désertification : sans voitures, plus de clients. L''argument paraît frappé au coin du bon sens ; il résiste pourtant mal à l''examen.

Les études menées dans une trentaine de villes européennes convergent : un an après la fermeture d''une rue aux voitures, la fréquentation des commerces baisse légèrement, le temps que les habitudes se recomposent. Puis la tendance s''inverse : à trois ans, le chiffre d''affaires des boutiques situées dans les zones piétonnes dépasse en moyenne de quinze pour cent celui des rues restées ouvertes au trafic. La raison est simple : un piéton flâne, compare, entre ; un automobiliste passe.

Faut-il pour autant piétonniser à marche forcée ? Ce serait oublier que ces réussites ont toutes été préparées : parkings relais en périphérie, créneaux de livraison garantis, navettes pour les personnes à mobilité réduite. Là où la fermeture a été décrétée sans accompagnement, l''échec a donné raison aux sceptiques. La leçon vaut d''être retenue : ce n''est pas la piétonnisation qui fait vivre ou mourir un centre-ville, c''est la manière dont on la conduit.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c009-4000-0000-000000000002', 'TEXTE',
   'Après Paris, plusieurs grandes villes envisagent à leur tour de bannir les trottinettes en libre-service. Le geste est populaire : qui n''a jamais pesté contre un engin abandonné au milieu d''un trottoir ou frôlé par un conducteur pressé ? Mais la popularité d''une mesure n''a jamais garanti sa pertinence.

Regardons les chiffres de près. Selon l''observatoire de la sécurité routière, les accidents impliquant une trottinette ont certes doublé en quatre ans ; mais les trois quarts concernent des engins personnels, qui ne sont nullement visés par les interdictions. Quant à l''encombrement des trottoirs, il a fortement reculé dans les villes qui ont imposé des stationnements dédiés et bridé la vitesse à dix kilomètres-heure dans les zones piétonnes — preuve qu''une régulation ferme produit des effets sans qu''il soit besoin de tout supprimer.

Surtout, on oublie de poser la seule question qui vaille : que deviennent les déplacements supprimés ? Les enquêtes menées après les retraits montrent qu''un tiers des trajets bascule vers la voiture ou les VTC. Interdire au nom de l''espace public pour renvoyer les gens vers l''automobile, voilà un singulier progrès. La trottinette partagée n''est ni un fléau ni une solution miracle : c''est un outil, qui réclame des règles plutôt qu''un bûcher.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c009-4000-0000-000000000003', 'TEXTE',
   'La gratuité des bus séduit de plus en plus de municipalités : une quarantaine de réseaux français l''ont adoptée, et chaque élection en ajoute à la liste. Promesse simple, populaire, immédiatement lisible — au point qu''on en oublie de vérifier ce qu''elle produit réellement.

Les bilans disponibles racontent une histoire plus nuancée que les discours. Oui, la fréquentation bondit : plus quarante pour cent en moyenne dans les deux ans. Mais lorsqu''on interroge les nouveaux passagers, la surprise est de taille : la majorité d''entre eux marchait ou pédalait auparavant. Les automobilistes, eux, n''ont que marginalement abandonné leur volant — moins d''un nouveau voyageur sur dix vient de la voiture. Autrement dit, la mesure remplit les bus sans guère désengorger les rues.

Faut-il en conclure que la gratuité est une fausse bonne idée ? Pas si vite. Elle redonne de la mobilité à des publics qui s''autocensuraient : adolescents, retraités modestes, demandeurs d''emploi. C''est un acquis social réel, qui mérite d''être défendu pour ce qu''il est. Mais qu''on cesse de la présenter comme une politique de report modal : pour faire descendre un automobiliste de sa voiture, l''expérience montre qu''un bus fréquent, rapide et fiable compte bien davantage qu''un bus gratuit. La question du prix vient après celle du service.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c009-4000-0000-000000000004', 'TEXTE',
   'Pouvoir tout faire à quinze minutes de chez soi — travailler, se soigner, faire ses courses, se cultiver : la « ville du quart d''heure » est devenue le mantra des programmes municipaux. Le concept, popularisé par un urbaniste franco-colombien, a l''élégance des grandes idées simples. Trop simple, peut-être.

Premier malentendu : il ne s''agit nullement d''assigner chacun à son quartier, comme l''affirment certains polémistes, mais de réduire les déplacements contraints en rapprochant les services. Personne ne propose d''interdire de traverser la ville.

Le vrai problème est ailleurs, et il est rarement nommé : la ville du quart d''heure existe déjà, mais seulement pour certains. Dans les centres anciens, denses et bien dotés, tout est effectivement à portée de marche. Dans les quartiers périphériques et les lotissements, où vivent pourtant la majorité des habitants des aires urbaines, le moindre rendez-vous médical suppose une voiture. Promouvoir le quart d''heure sans investir massivement dans ces territoires délaissés, c''est offrir un supplément de confort à ceux qui sont déjà bien servis.

L''idée mérite donc mieux que les éloges convenus comme les procès absurdes : elle vaut comme une boussole, à condition que l''effort se concentre là où le quart d''heure relève aujourd''hui de la fiction.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c009-4000-0000-000000000005', 'TEXTE',
   'Trois ans après le passage de la quasi-totalité de ses rues à trente kilomètres-heure, Brive-la-Gaillarde dresse un bilan que bien des métropoles feraient bien de lire. Les opposants annonçaient des embouteillages monstres et des automobilistes exaspérés ; les partisans, une ville apaisée du jour au lendemain. Les chiffres ne donnent entièrement raison à personne.

Côté circulation, la catastrophe n''a pas eu lieu : sur un trajet urbain moyen, la mesure coûte moins de trente secondes, car en ville, ce sont les feux et les carrefours qui dictent le tempo, pas la vitesse maximale autorisée. Côté sécurité, les collisions graves impliquant piétons et cyclistes ont reculé d''un quart — un progrès réel, quoique inférieur aux prédictions des promoteurs de la mesure.

Mais l''enseignement le plus précieux est ailleurs. Sur les grands axes rectilignes, où rien n''a été modifié hormis les panneaux, la vitesse réellement pratiquée n''a presque pas bougé : les conducteurs roulent comme la rue les y invite. Là où la chaussée a été rétrécie, les trottoirs élargis, des plateaux surélevés installés, le trente s''impose de lui-même. Un panneau ne fait pas une politique : c''est le dessin de la rue qui commande le comportement, bien plus que le règlement.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c009-4000-0000-000000000006', 'TEXTE',
   'On nous écrit chaque semaine pour dénoncer la « dictature du vélo » : des pistes qui auraient vidé les rues de leurs voitures, des cyclistes rois ignorant les feux, des piétons devenus gibier. Le tableau est si noir qu''il mérite d''être confronté au réel.

Le réel, le voici. Dans notre agglomération, les aménagements cyclables occupent à ce jour moins de trois pour cent de la voirie ; on peine à voir la dictature. La part des trajets effectués à bicyclette a triplé en six ans, ce qui reste modeste — un déplacement sur dix — mais suffit déjà à décongestionner certains axes aux heures de pointe, au bénéfice de ceux-là mêmes qui restent en voiture.

Cela dit, balayer toutes les critiques d''un revers de main serait une faute. Certaines pistes, tracées à la hâte sur les trottoirs, organisent réellement le conflit avec les piétons, et les aînés comme les personnes malvoyantes en font les frais ; il faut les reprendre, et certaines villes ont commencé. De même, l''indiscipline d''une minorité de cyclistes n''est pas une légende, et la tolérance dont elle bénéficie nourrit l''exaspération.

Défendre le vélo n''oblige pas à nier ses ratés. Mais entre corriger des erreurs d''exécution et renoncer à une politique qui fait ses preuves, il y a un gouffre que nous nous garderons de franchir.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c009-4000-0000-000000000007', 'TEXTE',
   'Quinze métropoles françaises se sont vu promettre leur « RER », sur le modèle francilien : des trains fréquents, du matin au soir, reliant les couronnes périurbaines au centre. L''annonce a soulevé un enthousiasme compréhensible chez les centaines de milliers d''habitants qui, faute d''alternative, s''entassent chaque matin sur des rocades saturées.

Précisons d''abord ce dont il s''agit, car le mot prête à confusion : dans la plupart des cas, il n''est pas question de percer de nouvelles lignes, mais de faire circuler beaucoup plus de trains sur des voies existantes — un départ toutes les dix minutes aux heures de pointe, là où certaines gares ne voient aujourd''hui passer que cinq trains par jour. Une révolution d''usage, pas de génie civil.

Reste la question que les discours inauguraux évitent soigneusement : qui paiera ? Moderniser la signalisation, doubler des tronçons, acheter des rames : les études chiffrent l''ensemble à plusieurs dizaines de milliards, quand l''enveloppe débloquée à ce jour en couvre à peine un dixième. Les collectivités, déjà à l''os, regardent l''État ; l''État renvoie vers des financements « innovants » dont personne ne connaît le contenu.

L''histoire des transports regorge de cartes magnifiques restées dans les tiroirs. Pour que celle-ci connaisse un autre sort, il faudra un jour faire ce que les annonces ne font jamais : aligner les milliards sur les promesses.',
   NULL, '22222222-0000-0000-0000-000000000002');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-c009-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c009-4000-0000-000000000001',
   NULL, 'B2', 'CE',
   'Quelle est l''idée principale défendue par l''auteur ?',
   'La conclusion du texte est explicite : « ce n''est pas la piétonnisation qui fait vivre ou mourir un centre-ville, c''est la manière dont on la conduit ». **L''idée principale est que la réussite dépend de l''accompagnement de la mesure** (parkings relais, livraisons, navettes). La réponse A est une sur-généralisation : le gain de chiffre d''affaires n''est ni systématique ni immédiat — là où la fermeture a été décrétée sans accompagnement, « l''échec a donné raison aux sceptiques ». La réponse C contredit la démonstration : l''argument des commerçants « résiste mal à l''examen ». La réponse D déforme le détail-piège : la fréquentation « baisse légèrement » la première année, puis « la tendance s''inverse » — rien de durable ni d''un effondrement. Mécanisme : dégager la **thèse conditionnelle** contre une sur-généralisation tentante.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_idee_principale'),

  ('11111111-c009-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c009-4000-0000-000000000002',
   NULL, 'B2', 'CE',
   'Quelle est la position de l''auteur sur l''interdiction des trottinettes en libre-service ?',
   'L''auteur démonte l''interdiction (« la popularité d''une mesure n''a jamais garanti sa pertinence », « voilà un singulier progrès ») et conclut que la trottinette « réclame des règles plutôt qu''un bûcher » : **il la juge contre-productive et défend une régulation exigeante** (stationnements dédiés, vitesse bridée). La réponse A inverse sa position : il reconnaît l''exaspération mais conteste la réponse qu''on lui apporte. La réponse B contredit la concession « les accidents ont certes doublé » — il ne nie pas le problème. La réponse C déforme le détail-piège : « les trois quarts concernent des engins personnels », non visés par les interdictions ; les engins partagés ne causent donc pas la majorité des accidents. Mécanisme : repérer la **concession rhétorique** (certes… mais) qui prépare une critique, non une adhésion.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_ton_auteur'),

  ('11111111-c009-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c009-4000-0000-000000000003',
   NULL, 'B2', 'CE',
   'Quelle est l''idée principale de ce texte ?',
   'Le texte articule deux constats : la gratuité est « un acquis social réel » pour les publics modestes, mais « la mesure remplit les bus sans guère désengorger les rues ». **L''idée principale est cette double évaluation : portée sociale réelle, effet quasi nul sur le trafic automobile.** La réponse B inverse le détail-piège : la majorité des nouveaux passagers « marchait ou pédalait auparavant », et moins d''un sur dix vient de la voiture. La réponse C contredit le mouvement du texte : à « Faut-il en conclure que la gratuité est une fausse bonne idée ? », l''auteur répond « Pas si vite ». La réponse D inverse la conclusion : un bus « fréquent, rapide et fiable compte bien davantage qu''un bus gratuit » pour attirer les automobilistes. Mécanisme : synthèse d''un **jugement nuancé** contre des distracteurs en inversion de détail.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_idee_principale'),

  ('11111111-c009-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c009-4000-0000-000000000004',
   NULL, 'B2', 'CE',
   'Quelle est l''intention principale de l''auteur de ce texte ?',
   'L''auteur conclut que l''idée « vaut comme une boussole, à condition que l''effort se concentre là où le quart d''heure relève aujourd''hui de la fiction » : **son intention est de défendre le concept tout en exigeant qu''il profite d''abord aux quartiers périphériques mal dotés**. La réponse A reprend la thèse des polémistes, explicitement réfutée (« il ne s''agit nullement d''assigner chacun à son quartier »). La réponse B sur-généralise : l''auteur ne rejette pas le concept, il en corrige l''usage. La réponse D inverse un détail : dans les centres anciens, « tout est effectivement à portée de marche » — ce sont les périphéries qui manquent de services. Mécanisme : **inférence d''intention** à partir d''une structure concessive (ni éloge convenu ni procès absurde).',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c009-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c009-4000-0000-000000000005',
   NULL, 'B2', 'CE',
   'Que cherche à montrer l''auteur à travers ce bilan ?',
   'L''« enseignement le plus précieux » du texte tient dans sa chute : « Un panneau ne fait pas une politique : c''est le dessin de la rue qui commande le comportement ». **La bonne réponse reformule cette thèse : le respect du 30 km/h dépend de l''aménagement physique des rues, pas de la seule signalisation.** La réponse A inverse les faits : « la catastrophe n''a pas eu lieu », le trajet moyen ne coûte que trente secondes de plus. La réponse C inverse le détail-piège : le recul d''un quart des collisions graves est « inférieur aux prédictions des promoteurs », pas supérieur. La réponse D contredit le texte : sur les grands axes rectilignes, « la vitesse réellement pratiquée n''a presque pas bougé ». Mécanisme : hiérarchiser les constats pour isoler la **conclusion implicite principale** face à des détails vrais mais secondaires.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c009-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c009-4000-0000-000000000006',
   NULL, 'B2', 'CE',
   'Comment l''auteur répond-il aux lecteurs qui dénoncent une « dictature du vélo » ?',
   'L''auteur réfute le procès d''ensemble par les chiffres (« moins de trois pour cent de la voirie ; on peine à voir la dictature ») puis concède des torts réels : pistes mal tracées « à reprendre », indiscipline d''une minorité qui « n''est pas une légende ». **Sa position : réfutation du tableau global, reconnaissance d''erreurs d''exécution à corriger.** La réponse A inverse sa conclusion : renoncer à cette politique est « un gouffre que nous nous garderons de franchir ». La réponse B contredit la concession explicite : « balayer toutes les critiques d''un revers de main serait une faute ». La réponse C sur-généralise le détail-piège : le vélo représente « un déplacement sur dix », pas la majorité des trajets. Mécanisme : le **mouvement concessif** (cela dit… mais) signale une défense nuancée, ni déni ni capitulation.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_ton_auteur'),

  ('11111111-c009-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c009-4000-0000-000000000007',
   NULL, 'B2', 'CE',
   'Qu''apprend-on dans ce texte sur les « RER métropolitains » ?',
   'Le texte présente un projet utile aux habitants des couronnes périurbaines, mais bute sur « la question que les discours inauguraux évitent soigneusement : qui paiera ? » — l''enveloppe débloquée couvre « à peine un dixième » des dizaines de milliards nécessaires. **La bonne réponse synthétise cette tension : projet pertinent, financement presque entièrement à trouver.** La réponse B inverse le détail-piège : « il n''est pas question de percer de nouvelles lignes », mais d''exploiter davantage les voies existantes. La réponse C inverse les proportions : l''État n''a financé qu''un dixième et renvoie vers des financements « innovants » indéfinis. La réponse D inverse le ton : l''enthousiasme des habitants est qualifié de « compréhensible ». Mécanisme : **inférence globale** reliant l''annonce au déficit de financement, contre des distracteurs en inversion de détail et de ton.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  -- item 01 — piétonnisation des centres-villes (bonne réponse : position 2)
  ('11111111-c009-2100-0000-000000000001', '11111111-c009-1000-0000-000000000001',
   'La piétonnisation fait systématiquement grimper le chiffre d''affaires des commerces de centre-ville',
   'false', '1'),

  ('11111111-c009-2200-0000-000000000001', '11111111-c009-1000-0000-000000000001',
   'La réussite d''une piétonnisation tient surtout aux mesures qui l''accompagnent',
   'true', '2'),

  ('11111111-c009-2300-0000-000000000001', '11111111-c009-1000-0000-000000000001',
   'Les commerçants ont raison de redouter une désertification durable des rues fermées aux voitures',
   'false', '3'),

  ('11111111-c009-2400-0000-000000000001', '11111111-c009-1000-0000-000000000001',
   'La fréquentation des commerces s''effondre durablement dès la première année de fermeture',
   'false', '4'),

  -- item 02 — trottinettes en libre-service (bonne réponse : position 4)
  ('11111111-c009-2100-0000-000000000002', '11111111-c009-1000-0000-000000000002',
   'Il l''approuve, car elle répond à l''exaspération légitime des piétons',
   'false', '1'),

  ('11111111-c009-2200-0000-000000000002', '11111111-c009-1000-0000-000000000002',
   'Il nie que les trottinettes posent le moindre problème de sécurité',
   'false', '2'),

  ('11111111-c009-2300-0000-000000000002', '11111111-c009-1000-0000-000000000002',
   'Il rappelle que les engins en libre-service causent la majorité des accidents',
   'false', '3'),

  ('11111111-c009-2400-0000-000000000002', '11111111-c009-1000-0000-000000000002',
   'Il la juge contre-productive et lui préfère une régulation exigeante',
   'true', '4'),

  -- item 03 — gratuité des transports en commun (bonne réponse : position 1)
  ('11111111-c009-2100-0000-000000000003', '11111111-c009-1000-0000-000000000003',
   'La gratuité des bus est un acquis social réel mais ne réduit guère le trafic automobile',
   'true', '1'),

  ('11111111-c009-2200-0000-000000000003', '11111111-c009-1000-0000-000000000003',
   'La majorité des nouveaux passagers des bus gratuits sont d''anciens automobilistes',
   'false', '2'),

  ('11111111-c009-2300-0000-000000000003', '11111111-c009-1000-0000-000000000003',
   'L''auteur appelle les municipalités à abandonner une gratuité jugée fausse bonne idée',
   'false', '3'),

  ('11111111-c009-2400-0000-000000000003', '11111111-c009-1000-0000-000000000003',
   'Un bus gratuit attire davantage les automobilistes qu''un bus fréquent et fiable',
   'false', '4'),

  -- item 04 — ville du quart d'heure (bonne réponse : position 3)
  ('11111111-c009-2100-0000-000000000004', '11111111-c009-1000-0000-000000000004',
   'Démontrer que le concept vise à confiner les habitants dans leur quartier',
   'false', '1'),

  ('11111111-c009-2200-0000-000000000004', '11111111-c009-1000-0000-000000000004',
   'Rejeter une idée jugée inapplicable dans les villes françaises',
   'false', '2'),

  ('11111111-c009-2300-0000-000000000004', '11111111-c009-1000-0000-000000000004',
   'Défendre le concept à condition de le déployer d''abord dans les quartiers mal dotés',
   'true', '3'),

  ('11111111-c009-2400-0000-000000000004', '11111111-c009-1000-0000-000000000004',
   'Montrer que les centres-villes anciens manquent encore de services de proximité',
   'false', '4'),

  -- item 05 — limitation à 30 km/h (bonne réponse : position 2)
  ('11111111-c009-2100-0000-000000000005', '11111111-c009-1000-0000-000000000005',
   'La limitation a provoqué les embouteillages que ses opposants annonçaient',
   'false', '1'),

  ('11111111-c009-2200-0000-000000000005', '11111111-c009-1000-0000-000000000005',
   'Le respect du 30 km/h dépend bien plus de l''aménagement des rues que des panneaux',
   'true', '2'),

  ('11111111-c009-2300-0000-000000000005', '11111111-c009-1000-0000-000000000005',
   'Les collisions graves ont reculé davantage que ne le prédisaient les promoteurs de la mesure',
   'false', '3'),

  ('11111111-c009-2400-0000-000000000005', '11111111-c009-1000-0000-000000000005',
   'Les conducteurs ont réduit leur vitesse sur l''ensemble des axes de la ville',
   'false', '4'),

  -- item 06 — politique cyclable (bonne réponse : position 4)
  ('11111111-c009-2100-0000-000000000006', '11111111-c009-1000-0000-000000000006',
   'Il leur donne raison et réclame l''arrêt des aménagements cyclables',
   'false', '1'),

  ('11111111-c009-2200-0000-000000000006', '11111111-c009-1000-0000-000000000006',
   'Il écarte toutes leurs critiques comme des exagérations sans fondement',
   'false', '2'),

  ('11111111-c009-2300-0000-000000000006', '11111111-c009-1000-0000-000000000006',
   'Il reconnaît que le vélo assure désormais la majorité des déplacements urbains',
   'false', '3'),

  ('11111111-c009-2400-0000-000000000006', '11111111-c009-1000-0000-000000000006',
   'Il réfute le procès d''ensemble tout en admettant des erreurs à corriger',
   'true', '4'),

  -- item 07 — RER métropolitains (bonne réponse : position 1)
  ('11111111-c009-2100-0000-000000000007', '11111111-c009-1000-0000-000000000007',
   'Le projet, jugé pertinent, bute sur un financement qui reste presque entièrement à trouver',
   'true', '1'),

  ('11111111-c009-2200-0000-000000000007', '11111111-c009-1000-0000-000000000007',
   'Il exigera de percer de nouvelles lignes dans la plupart des métropoles concernées',
   'false', '2'),

  ('11111111-c009-2300-0000-000000000007', '11111111-c009-1000-0000-000000000007',
   'L''État a déjà débloqué l''essentiel des sommes nécessaires aux travaux',
   'false', '3'),

  ('11111111-c009-2400-0000-000000000007', '11111111-c009-1000-0000-000000000007',
   'L''auteur juge déraisonnable l''enthousiasme des habitants des couronnes périurbaines',
   'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes (11111111-c009-1000/4000/21xx-…-NN, NN=01..07).
-- [x] Thème unique « ville & mobilité », 7 angles tous différents :
--     piétonnisation des centres-villes / trottinettes en libre-service /
--     gratuité des transports en commun / ville du quart d'heure /
--     limitation à 30 km/h / politique cyclable / RER métropolitains.
--     Aucun thème interdit (pas d'environnement, énergie, logement, tourisme…).
-- [x] Textes B2 longs : 185 / 198 / 202 / 195 / 195 / 213 / 212 mots
--     (tous dans la fourchette 150-280), denses, avec détail-piège
--     (baisse temporaire la 1re année, trois quarts d'accidents = engins
--     personnels, nouveaux passagers ex-piétons, centres déjà bien dotés,
--     recul inférieur aux prédictions, un déplacement sur dix, un dixième
--     de l'enveloppe débloqué).
-- [x] 4 propositions / exactement 1 correcte par item.
-- [x] Distribution des bonnes réponses : pos1:2, pos2:2, pos3:1, pos4:2
--     (4 positions utilisées, max 2 par position).
-- [x] competence_code : ce_idee_principale ×2 (items 1, 3),
--     ce_ton_auteur ×2 (items 2, 6), ce_inference_intention ×3 (items 4, 5, 7).
-- [x] explanation ≥ 80 caractères : bonne réponse justifiée + les 3
--     distracteurs réfutés, point clé en **gras**, mécanisme linguistique
--     nommé (concession rhétorique, inversion de détail/ton, sur-généralisation,
--     thèse conditionnelle, inférence d'intention, inférence globale).
-- [x] Apostrophes SQL doublées ('') partout ; pas de SVG/SSML (passages TEXTE,
--     media_id NULL) ; contenu 100 % original (villes, chiffres, études inventés).
-- ============================================================================
