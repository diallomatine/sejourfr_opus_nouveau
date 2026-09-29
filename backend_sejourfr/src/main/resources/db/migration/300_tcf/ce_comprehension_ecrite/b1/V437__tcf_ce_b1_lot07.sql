-- ============================================================================
-- V437 — TCF CE B1 — lot 07 (support : témoignage / blog)
-- ----------------------------------------------------------------------------
-- 10 items de compréhension écrite B1. Support unique : témoignage / billet de
-- blog à la première personne (apprentissage du français par podcasts, concours
-- de pâtisserie, reconversion professionnelle, voyage à vélo, bénévolat en
-- épicerie solidaire, potager sur le toit, permis de conduire à 42 ans,
-- première course de 10 km, colocation intergénérationnelle, club de lecture).
-- Passages TEXTE (~60-120 mots), questions + choices (4 rows/question).
-- theme_id = 22222222-0000-0000-0000-000000000002, difficulty='B1',
-- question_type='CE'. Données déterministes, rejouables dev+recette.
-- ============================================================================


-- passages — supports de lecture référencés par les questions ci-dessous
INSERT INTO passages
  (id, type, content, media_id, theme_id)
VALUES
  ('11111111-b007-4000-0000-000000000001', 'TEXTE',
   'Quand je suis arrivé à Lyon il y a trois ans, je comprenais à peine les conversations de mes collègues. Je me suis inscrit à des cours du soir, mais entre mon travail au dépôt et les enfants, j''ai abandonné au bout d''un mois. C''est ma fille qui m''a parlé des podcasts : depuis, j''écoute des émissions en français pendant mes quarante minutes de bus, matin et soir. Au début, je comprenais un mot sur trois. Aujourd''hui, je suis les débats sans effort et j''ose même prendre la parole en réunion.

Amadou, témoignage publié sur le blog « Parler enfin »',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b007-4000-0000-000000000002', 'TEXTE',
   'Samedi dernier, j''ai enfin osé : j''ai présenté ma tarte aux poires et au romarin au concours de pâtisserie amateur de la médiathèque. Douze candidats, trois heures de préparation sur place, et un trac terrible ! Le premier prix est revenu à un jeune homme qui avait réalisé un gâteau au chocolat spectaculaire. Je n''ai donc rien gagné, mais le jury a tenu à mentionner l''originalité de ma recette, et plusieurs visiteurs m''ont demandé de la partager. Une chose est sûre : je me réinscris l''année prochaine.

Lucia, blog « Ma cuisine et moi »',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b007-4000-0000-000000000003', 'TEXTE',
   'Pendant huit ans, j''ai été comptable dans un grand cabinet. Un salaire confortable, un bureau avec vue… et l''impression de passer ma vie devant des tableaux de chiffres. Il y a deux ans, j''ai suivi une formation de fleuriste en parallèle de mon travail, puis j''ai démissionné pour ouvrir ma boutique. Je gagne moins qu''avant et je me lève à cinq heures pour aller au marché aux fleurs, mais je ne regrette rien : pour la première fois, j''ai hâte d''aller travailler le matin.

Wei, témoignage publié sur le blog « Changer de vie »',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b007-4000-0000-000000000004', 'TEXTE',
   'Troisième jour de notre voyage à vélo le long du canal du Midi. Ce matin, nous avons parcouru quarante-cinq kilomètres sous les platanes, avec une pause déjeuner dans un village dont le marché sentait bon le melon. Petit conseil pour ceux qui veulent tenter l''aventure : réservez vos chambres d''hôtes à l''avance, surtout en juillet — hier soir, tout était complet et nous avons dû pédaler quinze kilomètres de plus pour trouver un lit. Demain, dernière étape jusqu''à Sète, où nous prendrons le train du retour.

Rachid, blog « Deux roues, zéro souci »',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b007-4000-0000-000000000005', 'TEXTE',
   'Chaque mercredi depuis un an, je suis bénévole à l''épicerie solidaire de mon quartier. Au début, j''y allais pour rendre service deux heures par semaine ; aujourd''hui, c''est le rendez-vous que je n''annulerais pour rien au monde. On y trie des fruits, on tient la caisse, mais surtout on prend le temps de discuter avec les habitués. Beaucoup pensent qu''il faut des compétences particulières pour s''engager : c''est faux, il suffit d''un peu de temps et d''envie. L''équipe cherche justement des volontaires pour le samedi. Si vous hésitez, venez voir, tout simplement.

Olena, blog « Quartier vivant »',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b007-4000-0000-000000000006', 'TEXTE',
   'Il y a un an, le toit de notre immeuble n''était qu''une surface de béton gris. Aujourd''hui, dix familles y cultivent tomates, courgettes et herbes aromatiques dans de grands bacs en bois. Le projet a demandé des mois de démarches : il a fallu convaincre le syndic, vérifier la solidité du toit et installer un accès sécurisé. Le plus surprenant, ce ne sont pas les légumes — c''est que des voisins qui ne se saluaient même pas organisent maintenant des dîners ensemble. Le béton est toujours là, mais on ne le voit plus.

Diego, blog « Vert sur la ville »',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b007-4000-0000-000000000007', 'TEXTE',
   'J''ai eu mon permis de conduire le mois dernier, à quarante-deux ans. Pendant des années, j''ai repoussé : trop cher, pas le temps, et surtout la peur de l''échec. C''est mon nouveau travail d''aide à domicile, à trente kilomètres de chez moi, qui m''a obligée à me lancer. J''ai échoué une première fois à l''examen — une priorité ratée — avant de réussir au deuxième passage. À celles et ceux qui n''osent pas : l''âge n''est pas un obstacle, les moniteurs ont l''habitude. Ma seule erreur a été d''attendre si longtemps.

Priya, témoignage pour le blog « Jamais trop tard »',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b007-4000-0000-000000000008', 'TEXTE',
   'Dimanche, j''ai couru mes premiers dix kilomètres aux Foulées de la Garonne. Moi qui m''essoufflais en montant trois étages il y a six mois ! Tout a commencé par un défi lancé par ma sœur, que j''ai accepté sans réfléchir. J''ai suivi un programme d''entraînement pour débutants : trois sorties par semaine, en augmentant les distances petit à petit. Le jour de la course, je visais simplement l''arrivée ; j''ai franchi la ligne en une heure et huit minutes, loin derrière les premiers, mais avec une fierté immense. Prochain objectif : le semi-marathon de Toulouse, au printemps.

Fatou, blog « Courir au féminin »',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b007-4000-0000-000000000009', 'TEXTE',
   'Quand j''ai commencé mes études à Strasbourg, les loyers m''ont vite découragé. C''est par une association que j''ai découvert la colocation intergénérationnelle : je loge chez Madeleine, quatre-vingt-un ans, pour un loyer très réduit. En échange, je partage quelques repas avec elle, je l''aide pour les courses et je suis présent le soir. Au départ, je voyais surtout l''économie ; aujourd''hui, c''est elle qui me raconte l''histoire du quartier et moi qui lui apprends à utiliser sa tablette. Si vous cherchez un logement étudiant, renseignez-vous : ces associations existent dans la plupart des grandes villes.

Tomas, témoignage sur le blog « Étudier sans se ruiner »',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b007-4000-0000-00000000000a', 'TEXTE',
   'Il y a six mois, j''ai déposé une petite annonce à la boulangerie : « Cherche voisins pour parler de livres autour d''un thé. » Nous étions quatre à la première rencontre ; nous sommes aujourd''hui quinze, de dix-neuf à soixante-quatorze ans. Chaque premier vendredi du mois, l''un de nous propose un roman, et la discussion dure souvent plus longtemps que prévu. Pas besoin d''être un grand lecteur : certains viennent sans avoir terminé le livre, juste pour écouter. Nous nous retrouvons désormais à la salle des fêtes, la mienne étant devenue trop petite. Les curieux sont les bienvenus le 4 juillet.

Mariam, blog « Lire ensemble »',
   NULL, '22222222-0000-0000-0000-000000000002');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-b007-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b007-4000-0000-000000000001',
   NULL, 'B1', 'CE',
   'Qu''est-ce qui a permis à Amadou de progresser en français ?',
   'Amadou écrit : « depuis, j''écoute des émissions en français pendant mes quarante minutes de bus, matin et soir », puis décrit ses progrès. C''est un **repérage explicite du moyen** : l''écoute régulière de podcasts pendant ses trajets. La réponse A confond la tentative et la solution : il s''est bien inscrit à des cours du soir, mais « j''ai abandonné au bout d''un mois ». La réponse C prend le **résultat pour la cause** : prendre la parole en réunion est l''aboutissement de ses progrès, pas leur origine. La réponse D déforme le rôle de sa fille : elle lui a seulement « parlé des podcasts », elle ne lui donne aucune leçon.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b007-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b007-4000-0000-000000000002',
   NULL, 'B1', 'CE',
   'Quel a été le résultat de Lucia au concours de pâtisserie ?',
   'Lucia écrit : « Je n''ai donc rien gagné, mais le jury a tenu à mentionner l''originalité de ma recette ». C''est un **repérage explicite** qui demande de distinguer deux informations proches : le prix et la mention. La réponse A confond Lucia avec le vainqueur : « Le premier prix est revenu à un jeune homme » au gâteau au chocolat. La réponse B contredit l''ouverture du billet : « j''ai enfin osé : j''ai présenté ma tarte », elle a bien concouru. La réponse C inverse la conclusion : « je me réinscris l''année prochaine » — le futur proche marque sa décision de retenter, pas d''abandonner.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b007-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b007-4000-0000-000000000003',
   NULL, 'B1', 'CE',
   'Que faut-il comprendre du témoignage de Wei ?',
   'Wei conclut : « Je gagne moins qu''avant… mais je ne regrette rien : pour la première fois, j''ai hâte d''aller travailler ». La bonne réponse **reformule ce bilan concessif** (« mais » oppose la perte de salaire au bonheur retrouvé). La réponse B contredit mot pour mot « je ne regrette rien » — le confort de l''ancien poste est cité pour mieux être écarté. La réponse C déforme la cause du départ : « j''ai démissionné » indique un choix volontaire, pas un licenciement. La réponse D se trompe de temps : la formation est déjà suivie et la boutique ouverte — le **passé composé** marque les actions accomplies.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reformulation'),

  ('11111111-b007-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b007-4000-0000-000000000004',
   NULL, 'B1', 'CE',
   'Quel conseil Rachid donne-t-il à ses lecteurs ?',
   'Rachid écrit : « réservez vos chambres d''hôtes à l''avance, surtout en juillet ». C''est un **repérage explicite du conseil**, signalé par l''impératif « réservez » et l''annonce « Petit conseil ». La réponse A déforme l''information : juillet est la période où il faut réserver tôt, pas une période à éviter sur le canal. La réponse B confond deux données chiffrées proches : les quinze kilomètres sont la distance pédalée en plus faute de chambre, pas une limite conseillée — l''étape du jour fait quarante-cinq kilomètres. La réponse D détourne un détail : le train n''est mentionné que pour le retour depuis Sète, pas comme alternative au vélo.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b007-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b007-4000-0000-000000000005',
   NULL, 'B1', 'CE',
   'Pourquoi Olena a-t-elle écrit ce billet ?',
   'Tout le billet prépare l''appel final : « L''équipe cherche justement des volontaires pour le samedi. Si vous hésitez, venez voir ». C''est une **inférence d''intention** : Olena lève les freins (« il faut des compétences particulières : c''est faux ») pour encourager ses lecteurs à s''engager. La réponse A contredit « le rendez-vous que je n''annulerais pour rien au monde » — elle continue. La réponse C prend un **détail illustratif** (tenir la caisse) pour l''objet du billet. La réponse D confond information et plainte : le besoin de volontaires le samedi est annoncé sur un ton enthousiaste, comme une invitation, pas comme un reproche.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-b007-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b007-4000-0000-000000000006',
   NULL, 'B1', 'CE',
   'Qu''est-ce qui surprend le plus Diego dans ce projet ?',
   'Diego écrit : « Le plus surprenant, ce ne sont pas les légumes — c''est que des voisins qui ne se saluaient même pas organisent maintenant des dîners ensemble ». La bonne réponse **reformule cette opposition** : la vraie surprise est le lien social créé. La réponse A reprend exactement ce que la phrase écarte (« ce ne sont pas les légumes ») — piège de la **négation oubliée**. La réponse B contredit « des mois de démarches » : convaincre le syndic a été long, pas rapide. La réponse C transforme une étape technique (« vérifier la solidité du toit ») en surprise, alors que rien n''indique un résultat inattendu de cette vérification.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reformulation'),

  ('11111111-b007-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b007-4000-0000-000000000007',
   NULL, 'B1', 'CE',
   'Qu''est-ce qui a poussé Priya à passer le permis de conduire ?',
   'Priya explique : « C''est mon nouveau travail d''aide à domicile, à trente kilomètres de chez moi, qui m''a obligée à me lancer ». Le **présentatif « c''est… qui »** met en relief la cause : un emploi éloigné de son domicile. La réponse B inverse une excuse : le prix (« trop cher ») était l''une des raisons de repousser, rien n''indique une baisse des tarifs. La réponse C contredit le récit : elle a « échoué une première fois » avant de réussir « au deuxième passage » — confusion entre deux tentatives proches. La réponse D déforme la mention des moniteurs : ils « ont l''habitude » sert à rassurer les lecteurs, ce ne sont pas eux qui l''ont décidée.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b007-1000-0000-000000000008', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b007-4000-0000-000000000008',
   NULL, 'B1', 'CE',
   'Qu''apprend-on sur Fatou dans ce billet ?',
   'Fatou oppose deux images d''elle-même : « Moi qui m''essoufflais en montant trois étages il y a six mois ! » et la ligne d''arrivée des dix kilomètres franchie dimanche. La bonne réponse **reformule ce contraste avant/après** : d''énormes progrès en six mois d''entraînement progressif. La réponse A contredit « mes premiers dix kilomètres » : c''est une débutante, pas une habituée des compétitions. La réponse B déforme le classement : elle a fini « loin derrière les premiers », en une heure et huit minutes. La réponse D inverse la conclusion : son « prochain objectif » est justement une course plus longue, le semi-marathon de Toulouse.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reformulation'),

  ('11111111-b007-1000-0000-000000000009', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b007-4000-0000-000000000009',
   NULL, 'B1', 'CE',
   'Que faut-il comprendre du témoignage de Tomas ?',
   'Tomas oppose deux moments : « Au départ, je voyais surtout l''économie ; aujourd''hui, c''est elle qui me raconte l''histoire du quartier et moi qui lui apprends à utiliser sa tablette ». Par **inférence sur l''évolution du regard**, on comprend que la colocation lui apporte désormais un véritable échange, au-delà de l''argent. La réponse A contredit le ton du billet : il décrit les services rendus (repas, courses, présence) sans s''en plaindre et recommande la formule. La réponse C est démentie par le présent « je loge chez Madeleine » — il n''est pas parti. La réponse D contredit « un loyer très réduit », avantage central du dispositif.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-b007-1000-0000-00000000000a', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b007-4000-0000-00000000000a',
   NULL, 'B1', 'CE',
   'Quel est le but de ce billet de Mariam ?',
   'Le billet se conclut par « Les curieux sont les bienvenus le 4 juillet », après avoir levé les freins : « Pas besoin d''être un grand lecteur ». C''est une **inférence d''intention** : tout le récit de la réussite du club sert à inviter de nouveaux participants. La réponse A inverse le sens de la croissance : passer de quatre à quinze membres est présenté comme une fierté, pas comme une raison de fermer. La réponse B confond un problème **déjà résolu** avec une demande : « Nous nous retrouvons désormais à la salle des fêtes ». La réponse D invente une vente : chaque membre « propose un roman » à discuter, rien n''est à vendre.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  -- Q01 — podcasts d''Amadou (bonne réponse : position 2)
  ('11111111-b007-2100-0000-000000000001', '11111111-b007-1000-0000-000000000001',
   'Les cours du soir qu''il a suivis pendant trois ans',
   'false', '1'),
  ('11111111-b007-2200-0000-000000000001', '11111111-b007-1000-0000-000000000001',
   'L''écoute de podcasts pendant ses trajets en bus',
   'true', '2'),
  ('11111111-b007-2300-0000-000000000001', '11111111-b007-1000-0000-000000000001',
   'Ses prises de parole régulières en réunion',
   'false', '3'),
  ('11111111-b007-2400-0000-000000000001', '11111111-b007-1000-0000-000000000001',
   'Les leçons de français données par sa fille',
   'false', '4'),

  -- Q02 — concours de Lucia (bonne réponse : position 4)
  ('11111111-b007-2100-0000-000000000002', '11111111-b007-1000-0000-000000000002',
   'Elle a remporté le premier prix avec sa tarte',
   'false', '1'),
  ('11111111-b007-2200-0000-000000000002', '11111111-b007-1000-0000-000000000002',
   'Elle a renoncé à présenter sa tarte au dernier moment',
   'false', '2'),
  ('11111111-b007-2300-0000-000000000002', '11111111-b007-1000-0000-000000000002',
   'Elle a décidé de ne plus jamais participer au concours',
   'false', '3'),
  ('11111111-b007-2400-0000-000000000002', '11111111-b007-1000-0000-000000000002',
   'Elle n''a pas gagné, mais le jury a salué sa recette',
   'true', '4'),

  -- Q03 — reconversion de Wei (bonne réponse : position 1)
  ('11111111-b007-2100-0000-000000000003', '11111111-b007-1000-0000-000000000003',
   'Il est plus heureux comme fleuriste, malgré un salaire plus bas',
   'true', '1'),
  ('11111111-b007-2200-0000-000000000003', '11111111-b007-1000-0000-000000000003',
   'Il regrette le confort de son ancien poste de comptable',
   'false', '2'),
  ('11111111-b007-2300-0000-000000000003', '11111111-b007-1000-0000-000000000003',
   'Il a été licencié par son cabinet avant d''ouvrir sa boutique',
   'false', '3'),
  ('11111111-b007-2400-0000-000000000003', '11111111-b007-1000-0000-000000000003',
   'Il cherche une formation pour devenir fleuriste',
   'false', '4'),

  -- Q04 — vélo de Rachid (bonne réponse : position 3)
  ('11111111-b007-2100-0000-000000000004', '11111111-b007-1000-0000-000000000004',
   'Éviter le canal du Midi pendant le mois de juillet',
   'false', '1'),
  ('11111111-b007-2200-0000-000000000004', '11111111-b007-1000-0000-000000000004',
   'Limiter les étapes à quinze kilomètres par jour',
   'false', '2'),
  ('11111111-b007-2300-0000-000000000004', '11111111-b007-1000-0000-000000000004',
   'Réserver ses hébergements à l''avance en été',
   'true', '3'),
  ('11111111-b007-2400-0000-000000000004', '11111111-b007-1000-0000-000000000004',
   'Préférer le train au vélo pour faire ce trajet',
   'false', '4'),

  -- Q05 — bénévolat d''Olena (bonne réponse : position 2)
  ('11111111-b007-2100-0000-000000000005', '11111111-b007-1000-0000-000000000005',
   'Annoncer qu''elle arrête son bénévolat du mercredi',
   'false', '1'),
  ('11111111-b007-2200-0000-000000000005', '11111111-b007-1000-0000-000000000005',
   'Encourager ses lecteurs à s''engager comme bénévoles',
   'true', '2'),
  ('11111111-b007-2300-0000-000000000005', '11111111-b007-1000-0000-000000000005',
   'Expliquer le fonctionnement de la caisse de l''épicerie',
   'false', '3'),
  ('11111111-b007-2400-0000-000000000005', '11111111-b007-1000-0000-000000000005',
   'Se plaindre du manque de volontaires le samedi',
   'false', '4'),

  -- Q06 — potager de Diego (bonne réponse : position 4)
  ('11111111-b007-2100-0000-000000000006', '11111111-b007-1000-0000-000000000006',
   'La quantité de légumes récoltés sur le toit',
   'false', '1'),
  ('11111111-b007-2200-0000-000000000006', '11111111-b007-1000-0000-000000000006',
   'La rapidité des démarches auprès du syndic',
   'false', '2'),
  ('11111111-b007-2300-0000-000000000006', '11111111-b007-1000-0000-000000000006',
   'La solidité inattendue du toit de l''immeuble',
   'false', '3'),
  ('11111111-b007-2400-0000-000000000006', '11111111-b007-1000-0000-000000000006',
   'Les nouveaux liens créés entre les habitants',
   'true', '4'),

  -- Q07 — permis de Priya (bonne réponse : position 1)
  ('11111111-b007-2100-0000-000000000007', '11111111-b007-1000-0000-000000000007',
   'Un nouvel emploi situé à trente kilomètres de chez elle',
   'true', '1'),
  ('11111111-b007-2200-0000-000000000007', '11111111-b007-1000-0000-000000000007',
   'La baisse du prix des leçons de conduite',
   'false', '2'),
  ('11111111-b007-2300-0000-000000000007', '11111111-b007-1000-0000-000000000007',
   'Sa réussite à l''examen dès le premier passage',
   'false', '3'),
  ('11111111-b007-2400-0000-000000000007', '11111111-b007-1000-0000-000000000007',
   'Les encouragements de son moniteur d''auto-école',
   'false', '4'),

  -- Q08 — course de Fatou (bonne réponse : position 3)
  ('11111111-b007-2100-0000-000000000008', '11111111-b007-1000-0000-000000000008',
   'Elle court des compétitions depuis de nombreuses années',
   'false', '1'),
  ('11111111-b007-2200-0000-000000000008', '11111111-b007-1000-0000-000000000008',
   'Elle a terminé parmi les premières de la course',
   'false', '2'),
  ('11111111-b007-2300-0000-000000000008', '11111111-b007-1000-0000-000000000008',
   'Elle a fait d''énormes progrès en six mois d''entraînement',
   'true', '3'),
  ('11111111-b007-2400-0000-000000000008', '11111111-b007-1000-0000-000000000008',
   'Elle renonce désormais aux courses plus longues',
   'false', '4'),

  -- Q09 — colocation de Tomas (bonne réponse : position 2)
  ('11111111-b007-2100-0000-000000000009', '11111111-b007-1000-0000-000000000009',
   'Il trouve l''aide demandée en échange du loyer trop lourde',
   'false', '1'),
  ('11111111-b007-2200-0000-000000000009', '11111111-b007-1000-0000-000000000009',
   'La colocation lui apporte désormais plus qu''une économie',
   'true', '2'),
  ('11111111-b007-2300-0000-000000000009', '11111111-b007-1000-0000-000000000009',
   'Il a quitté Madeleine pour un logement étudiant classique',
   'false', '3'),
  ('11111111-b007-2400-0000-000000000009', '11111111-b007-1000-0000-000000000009',
   'Son loyer est aussi élevé que dans le reste de la ville',
   'false', '4'),

  -- Q10 — club de lecture de Mariam (bonne réponse : position 3)
  ('11111111-b007-2100-0000-00000000000a', '11111111-b007-1000-0000-00000000000a',
   'Annoncer la fermeture du club, devenu trop nombreux',
   'false', '1'),
  ('11111111-b007-2200-0000-00000000000a', '11111111-b007-1000-0000-00000000000a',
   'Chercher une salle plus grande pour les rencontres',
   'false', '2'),
  ('11111111-b007-2300-0000-00000000000a', '11111111-b007-1000-0000-00000000000a',
   'Inviter de nouveaux lecteurs à rejoindre le club',
   'true', '3'),
  ('11111111-b007-2400-0000-00000000000a', '11111111-b007-1000-0000-00000000000a',
   'Vendre les romans déjà lus par les membres',
   'false', '4');

-- ============================================================================
-- CHECKLIST — contrôles passés
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes (11111111-b007-1000/4000/21..2400-…-NN, NN=01..0a).
-- [x] Support unique : témoignage / billet de blog à la première personne
--     (10 auteurs et situations toutes différentes : podcasts pour apprendre le
--     français, concours de pâtisserie, reconversion comptable→fleuriste,
--     voyage à vélo canal du Midi, bénévolat épicerie solidaire, potager
--     partagé sur le toit, permis à 42 ans, première course de 10 km,
--     colocation intergénérationnelle, club de lecture de quartier).
-- [x] Aucun support interdit (pas d''e-mail, message administratif, article,
--     forum, lettre, annonce, FAQ, brochure, avis/critique…).
-- [x] Passages TEXTE ~60-120 mots, mise en forme blog (récit à la 1re
--     personne, ton personnel, signature + nom du blog), media_id NULL.
-- [x] 4 propositions / 1 correcte par item. Distribution des bonnes réponses :
--     pos1:2 (Q3,Q7), pos2:3 (Q1,Q5,Q9), pos3:3 (Q4,Q8,Q10), pos4:2 (Q2,Q6)
--     — max 3 par position, 4 positions utilisées.
-- [x] competence_code : ce_reperage_explicite x4 (Q1,Q2,Q4,Q7),
--     ce_inference_intention x3 (Q5,Q9,Q10), ce_reformulation x3 (Q3,Q6,Q8).
-- [x] explanation ≥ 80 caractères : bonne réponse justifiée + les 3
--     distracteurs expliqués, point clé en **gras**, mécanisme linguistique
--     nommé (présentatif c''est…qui, bilan concessif, négation oubliée,
--     passé composé accompli, inférence d''intention, contraste avant/après…).
-- [x] Pas de SVG ni SSML dans ce lot (supports textuels uniquement) — rien à
--     équilibrer.
-- [x] Apostrophes SQL doublées partout, contenu 100% original, items autonomes,
--     prénoms variés (Amadou, Lucia, Wei, Rachid, Olena, Diego, Priya, Fatou,
--     Tomas, Mariam).
-- ============================================================================
