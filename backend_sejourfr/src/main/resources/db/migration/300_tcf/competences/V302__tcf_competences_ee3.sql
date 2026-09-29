-- ============================================================================
-- V302 — Competences TCF : EE3 « Donner son opinion »
--
-- Seed du module « Competences » pour la tache EE3 (EE).
-- 8 competences, 40 petits sujets, 120 references.
--
-- Tables : skills, skill_prompts, skill_references (DDL en V025).
--
-- FICHIER GENERE — NE PAS EDITER A LA MAIN.
--
--   cd backend_sejourfr && python3 tools/competences/generer_seed.py
--
-- On edite la fiche de contenu tools/competences/contenu/EE3.json,
-- puis on regenere. Une correction faite ici serait ecrasee a la prochaine
-- generation, et les deux sources auraient diverge entre-temps.
--
-- (Le contenu vivant, lui, s'edite depuis la console d'administration une fois
-- la migration appliquee. Ce generateur ne sert qu'a republier depuis zero.)
--
-- Les UUID sont DETERMINISTES (uuid5 sur le code metier) : un identifiant de
-- contenu reste stable d'un environnement a l'autre, et rejouer la generation
-- redonne exactement le meme fichier.
--
-- Rappel du contrat : un petit sujet porte UN SEUL critere, et ses 3 references
-- (INSUFFICIENT / EXPECTED / EXCELLENT) ne se distinguent que par le respect de
-- ce critere — jamais par la quantite de fautes de langue.
-- ============================================================================

INSERT INTO skills (id, section, task_code, code, title, description,
                    general_criterion, target_level, display_order, is_active,
                    created_at, updated_at)
VALUES
  -- EE3-C1 — Exprimer une position claire
  ('78182a36-43b8-5257-b8f2-4730bb504d93', 'EE', 'EE3', 'EE3-C1', 'Exprimer une position claire',
   'Vous vous entraînez à dire votre avis dès la première phrase, sans détour. Au TCF, le correcteur doit repérer votre position immédiatement : c''est elle qui rend lisible tout le reste de votre texte.',
   'Répondre directement à la question et rendre son avis identifiable dès le début.',
   'B1', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C2 — Donner un argument pertinent
  ('2930c13d-ce25-54af-b0c6-e602f326fa16', 'EE', 'EE3', 'EE3-C2', 'Donner un argument pertinent',
   'Vous vous entraînez à donner une raison qui soutient réellement votre avis. Au TCF, une opinion répétée autrement ne compte pas comme un argument.',
   'Présenter une raison directement liée à l''opinion annoncée.',
   'B1', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C3 — Développer un argument
  ('50bbf456-9de7-5620-aa31-5cba27bfac70', 'EE', 'EE3', 'EE3-C3', 'Développer un argument',
   'Vous apprenez à expliquer votre raison au lieu de l''énoncer puis de passer à la suivante. Au TCF, c''est ce développement qui sépare une réponse B1 d''une réponse B2.',
   'Expliquer comment ou pourquoi l''argument soutient la position, au lieu de simplement l''énumérer.',
   'B2', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C4 — Illustrer avec un exemple concret
  ('4e7ce6cc-403f-5f70-98bb-393cc625e608', 'EE', 'EE3', 'EE3-C4', 'Illustrer avec un exemple concret',
   'Vous travaillez l''exemple : la situation précise qui rend un argument visible. Au TCF, un argument illustré convainc bien plus qu''une idée générale.',
   'Ajouter un exemple personnel, quotidien ou vraisemblable qui rend l''argument plus clair.',
   'B1', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C5 — Ajouter un deuxième argument distinct
  ('8dfda25f-5808-5e9f-ba3e-bb3970ddf134', 'EE', 'EE3', 'EE3-C5', 'Ajouter un deuxième argument distinct',
   'Vous vous exercez à ajouter une raison qui ouvre un angle nouveau. Au TCF, deux arguments qui disent la même chose comptent pour un seul.',
   'Enrichir la réponse avec une nouvelle raison sans répéter la première.',
   'B2', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C6 — Comparer des possibilités ou présenter avantages et inconvénients
  ('cd4ffb3c-e482-5431-91b5-0422b5ccebf8', 'EE', 'EE3', 'EE3-C6', 'Comparer des possibilités ou présenter avantages et inconvénients',
   'Vous apprenez à mettre deux options face à face et à faire ressortir ce qui les sépare. Au TCF, comparer montre que vous conduisez un raisonnement, pas seulement une opinion.',
   'Mettre en relation deux choix et faire apparaître leurs différences utiles.',
   'B2', 6, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C7 — Nuancer ou concéder
  ('16b70979-21b7-53f8-91a7-70a20bd385ec', 'EE', 'EE3', 'EE3-C7', 'Nuancer ou concéder',
   'Vous apprenez à reconnaître une limite ou un avis contraire sans abandonner votre position. Au TCF, cette nuance est l''un des signes les plus nets d''un niveau B2.',
   'Reconnaître une limite, une exception ou un avis opposé tout en conservant une position claire.',
   'B2', 7, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C8 — Organiser et conclure une réponse argumentée
  ('8c9134c2-ccba-59f4-903f-40067a3737ee', 'EE', 'EE3', 'EE3-C8', 'Organiser et conclure une réponse argumentée',
   'Vous vous entraînez à enchaîner vos idées avec des connecteurs et à terminer par une conclusion. Au TCF, un texte qui s''arrête sans conclure laisse une impression d''inachevé.',
   'Relier les idées avec des connecteurs logiques et terminer par une conclusion cohérente.',
   'B2', 8, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02');

INSERT INTO skill_prompts (id, skill_id, section, code, title, context, instruction,
                           unique_criterion, recommended_min_words, recommended_max_words,
                           recommended_duration_seconds, difficulty_level, display_order,
                           is_active, created_at, updated_at)
VALUES
  -- EE3-C1-S1 — EASY — Votre avis sur le télétravail
  ('1b544fd4-3412-5003-84c3-fa0a9bbffd79', '78182a36-43b8-5257-b8f2-4730bb504d93', 'EE', 'EE3-C1-S1', 'Votre avis sur le télétravail',
   'Un magazine en ligne pose cette question à ses lecteurs : « Faut-il généraliser le télétravail dans les entreprises ? »',
   'Écrivez une seule phrase qui donne votre avis. N''expliquez pas encore vos raisons.',
   'Votre phrase indique clairement si vous êtes pour ou contre la généralisation du télétravail.',
   15, 30, NULL, 'EASY', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C1-S2 — EASY — Gratuité des transports en commun
  ('04462599-ac26-5c1c-acd3-84588db32e6d', '78182a36-43b8-5257-b8f2-4730bb504d93', 'EE', 'EE3-C1-S2', 'Gratuité des transports en commun',
   'Votre ville envisage de rendre les bus et les tramways gratuits pour tous les habitants.',
   'Donnez votre avis sur cette mesure en une phrase. Ne donnez pas encore d''arguments.',
   'Votre phrase dit clairement si vous approuvez ou non la gratuité des transports.',
   15, 30, NULL, 'EASY', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C1-S3 — MEDIUM — Un menu unique à la cantine
  ('f7619b38-e2a3-5942-ad13-f64e43fed883', '78182a36-43b8-5257-b8f2-4730bb504d93', 'EE', 'EE3-C1-S3', 'Un menu unique à la cantine',
   'Le restaurant de votre entreprise annonce un menu unique : moins cher, mais identique pour tout le monde.',
   'En une phrase, dites si vous approuvez ce changement. Ne développez pas vos raisons.',
   'Votre phrase exprime une position tranchée, pour ou contre le menu unique.',
   15, 35, NULL, 'MEDIUM', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C1-S4 — MEDIUM — Un âge minimum sur les réseaux
  ('7368b573-7db7-5820-97ef-af79561811a2', '78182a36-43b8-5257-b8f2-4730bb504d93', 'EE', 'EE3-C1-S4', 'Un âge minimum sur les réseaux',
   'Un journal demande à ses lecteurs s''il faudrait fixer un âge minimum pour ouvrir un compte sur un réseau social.',
   'Répondez en une phrase qui donne votre position. Gardez vos arguments pour plus tard.',
   'Votre phrase dit clairement si vous êtes favorable ou non à un âge minimum.',
   15, 35, NULL, 'MEDIUM', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C1-S5 — HARD — Le centre-ville ou la campagne
  ('3e6418ca-e1f4-54e5-bd4d-a9b82b16ed44', '78182a36-43b8-5257-b8f2-4730bb504d93', 'EE', 'EE3-C1-S5', 'Le centre-ville ou la campagne',
   'Un ami hésite entre un appartement en plein centre-ville et une maison à trente kilomètres, à la campagne. Il vous demande votre avis.',
   'Écrivez une ou deux phrases qui annoncent clairement la solution que vous conseillez. Ne justifiez pas encore votre choix.',
   'Votre réponse désigne sans ambiguïté l''option que vous recommandez.',
   20, 45, NULL, 'HARD', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C2-S1 — EASY — L'utilité des transports publics
  ('f928f912-86be-573f-9e19-5d32ef75c40b', '2930c13d-ce25-54af-b0c6-e602f326fa16', 'EE', 'EE3-C2-S1', 'L''utilité des transports publics',
   'Dans un forum sur la vie urbaine, vous avez écrit : « Les transports publics sont indispensables dans une grande ville. »',
   'Écrivez une phrase qui donne une raison de cet avis. Inutile de la développer longuement ou de donner un exemple.',
   'Votre phrase apporte une raison nouvelle, qui soutient directement l''opinion annoncée.',
   15, 35, NULL, 'EASY', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C2-S2 — EASY — Bouger un peu chaque jour
  ('cc5b70de-4439-5e33-bba4-88200dd3dcfb', '2930c13d-ce25-54af-b0c6-e602f326fa16', 'EE', 'EE3-C2-S2', 'Bouger un peu chaque jour',
   'Un collègue vous dit qu''il n''a pas le temps de faire du sport. Vous pensez qu''une activité physique quotidienne est importante.',
   'Donnez en une phrase une raison qui justifie votre avis. Une seule raison suffit.',
   'Votre phrase donne une raison précise qui explique pourquoi cette activité quotidienne compte.',
   15, 35, NULL, 'EASY', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C2-S3 — MEDIUM — Une langue étrangère dès six ans
  ('3a9c17f1-4bf5-5307-bc77-bba6d255f842', '2930c13d-ce25-54af-b0c6-e602f326fa16', 'EE', 'EE3-C2-S3', 'Une langue étrangère dès six ans',
   'Une école de votre quartier veut commencer l''apprentissage d''une deuxième langue dès six ans. Vous trouvez que c''est une bonne idée.',
   'Écrivez une phrase qui donne la raison principale de votre accord.',
   'La raison donnée explique en quoi commencer à six ans est un avantage.',
   15, 35, NULL, 'MEDIUM', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C2-S4 — MEDIUM — Un atelier de réparation gratuit
  ('5d63eed0-ef1c-595b-b074-9a0d2912d5ae', '2930c13d-ce25-54af-b0c6-e602f326fa16', 'EE', 'EE3-C2-S4', 'Un atelier de réparation gratuit',
   'Un atelier de réparation gratuit vient d''ouvrir dans votre quartier. Vous pensez que ce type de lieu devrait exister partout.',
   'Donnez en une ou deux phrases une raison qui soutient cet avis.',
   'Votre raison dit concrètement ce que cet atelier permet d''obtenir ou d''éviter.',
   20, 40, NULL, 'MEDIUM', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C2-S5 — HARD — Des vêtements de seconde main
  ('fbd8c101-25dc-5015-bf43-26c18b6398fd', '2930c13d-ce25-54af-b0c6-e602f326fa16', 'EE', 'EE3-C2-S5', 'Des vêtements de seconde main',
   'Une amie hésite à acheter des vêtements d''occasion. Vous le faites depuis longtemps et vous le lui recommandez.',
   'Écrivez une ou deux phrases qui donnent la raison la plus convaincante selon vous. Ne racontez pas encore d''expérience personnelle.',
   'La raison avancée justifie précisément l''achat d''occasion plutôt que l''achat neuf.',
   20, 45, NULL, 'HARD', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C3-S1 — EASY — Vivre en ville est pratique
  ('95bb59a9-7d73-595c-b1f8-5c41750a960c', '50bbf456-9de7-5620-aa31-5cba27bfac70', 'EE', 'EE3-C3-S1', 'Vivre en ville est pratique',
   'Vous participez à une discussion sur la vie urbaine et vous avez écrit : « Vivre en ville est pratique. »',
   'Développez cette idée en deux phrases : dites d''où vient ce côté pratique, puis ce que cela change au quotidien. Ne donnez pas d''exemple précis.',
   'Votre texte explique le lien entre la vie en ville et le côté pratique, au lieu de répéter l''idée.',
   30, 60, NULL, 'EASY', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C3-S2 — EASY — De nouvelles pistes cyclables
  ('3f0bc739-bff1-5afd-8bb8-b3d5653a456a', '50bbf456-9de7-5620-aa31-5cba27bfac70', 'EE', 'EE3-C3-S2', 'De nouvelles pistes cyclables',
   'Votre ville vient de construire plusieurs pistes cyclables séparées de la route. Vous pensez que c''est une bonne décision.',
   'Écrivez deux phrases : donnez votre raison, puis expliquez pourquoi elle produit un effet. N''ajoutez pas d''autre argument.',
   'La deuxième phrase explique la première au lieu d''introduire une idée nouvelle.',
   30, 60, NULL, 'EASY', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C3-S3 — MEDIUM — Quinze minutes de lecture
  ('b9855e23-7126-5309-be90-106148e48a82', '50bbf456-9de7-5620-aa31-5cba27bfac70', 'EE', 'EE3-C3-S3', 'Quinze minutes de lecture',
   'Une bibliothèque de quartier lance une campagne : « Quinze minutes de lecture par jour. » Vous soutenez cette idée.',
   'En deux phrases, expliquez pourquoi quinze minutes par jour peuvent suffire à faire une différence.',
   'Votre texte explique par quel mécanisme cette habitude produit un effet.',
   30, 60, NULL, 'MEDIUM', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C3-S4 — MEDIUM — Une visite médicale chaque année
  ('98cb2e34-4a42-5f4c-9d39-520ba11807ad', '50bbf456-9de7-5620-aa31-5cba27bfac70', 'EE', 'EE3-C3-S4', 'Une visite médicale chaque année',
   'Un centre de santé propose une visite médicale gratuite une fois par an. Vous trouvez cette initiative utile.',
   'Développez votre position en deux phrases : donnez la raison, puis expliquez son effet.',
   'Votre deuxième phrase montre la conséquence directe de la raison donnée.',
   30, 60, NULL, 'MEDIUM', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C3-S5 — HARD — Donner du temps à une association
  ('57b8ee98-7ee3-5b8b-b3c7-f3934c65d31f', '50bbf456-9de7-5620-aa31-5cba27bfac70', 'EE', 'EE3-C3-S5', 'Donner du temps à une association',
   'Une association de votre commune cherche des bénévoles. Vous pensez que le bénévolat apporte autant à celui qui donne son temps qu''à ceux qui en bénéficient.',
   'Développez cette idée en deux ou trois phrases. Expliquez comment le bénévolat produit cet effet, sans raconter d''expérience personnelle.',
   'Votre texte explique l''enchaînement par lequel le bénévolat profite aussi au bénévole.',
   45, 90, NULL, 'HARD', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C4-S1 — EASY — Le français au quotidien
  ('94e94e1a-8d0e-52e3-b39c-a5f11e0ffaf0', '4e7ce6cc-403f-5f70-98bb-393cc625e608', 'EE', 'EE3-C4-S1', 'Le français au quotidien',
   'Vous écrivez à un ami qui hésite à suivre des cours de français. Vous lui avez dit : « Parler français change beaucoup de choses au quotidien. »',
   'Ajoutez un exemple concret qui montre cette utilité. Une seule situation précise suffit ; ne répétez pas l''argument.',
   'Votre exemple décrit une situation précise et située où parler français a servi.',
   25, 50, NULL, 'EASY', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C4-S2 — EASY — Cuisiner revient moins cher
  ('8c41805e-d61e-54b3-8cca-fd7adf9a1213', '4e7ce6cc-403f-5f70-98bb-393cc625e608', 'EE', 'EE3-C4-S2', 'Cuisiner revient moins cher',
   'Sur un forum, vous avez écrit : « Préparer ses repas coûte moins cher que d''acheter des plats tout prêts. »',
   'Illustrez cette idée par un exemple concret tiré de votre quotidien.',
   'Votre exemple donne des éléments précis (plat, prix, quantité ou moment) qui appuient l''argument.',
   25, 50, NULL, 'EASY', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C4-S3 — MEDIUM — Les démarches faites en ligne
  ('a295fbaa-f839-51c7-b87f-92e6c2988e46', '4e7ce6cc-403f-5f70-98bb-393cc625e608', 'EE', 'EE3-C4-S3', 'Les démarches faites en ligne',
   'Vous discutez des services accessibles sur Internet et vous avez affirmé : « Les démarches en ligne font gagner du temps. »',
   'Donnez un exemple concret qui illustre cet argument, en une ou deux phrases.',
   'Votre exemple nomme une démarche précise et ce qu''elle a permis de gagner.',
   25, 55, NULL, 'MEDIUM', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C4-S4 — MEDIUM — Résoudre un problème à plusieurs
  ('3563ed2d-2c7f-5f3a-9f39-0b57c039b203', '4e7ce6cc-403f-5f70-98bb-393cc625e608', 'EE', 'EE3-C4-S4', 'Résoudre un problème à plusieurs',
   'Vous répondez à une enquête sur l''organisation du travail. Vous avez écrit : « Travailler en équipe permet de résoudre plus vite les problèmes. »',
   'Illustrez cet argument par un exemple concret, vécu ou vraisemblable.',
   'Votre exemple raconte une situation identifiable où l''équipe a permis de résoudre un problème.',
   25, 55, NULL, 'MEDIUM', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C4-S5 — HARD — Trier à l'échelle d'un immeuble
  ('aed6dd2c-e4e5-5d33-a9e6-60827db51808', '4e7ce6cc-403f-5f70-98bb-393cc625e608', 'EE', 'EE3-C4-S5', 'Trier à l''échelle d''un immeuble',
   'Un voisin pense que le tri des déchets ne sert à rien à l''échelle d''une famille. Vous n''êtes pas d''accord avec lui.',
   'Écrivez deux ou trois phrases contenant un exemple concret qui montre l''effet du tri dans un immeuble ou un quartier.',
   'Votre exemple présente une situation observable et un effet visible ou mesurable.',
   35, 70, NULL, 'HARD', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C5-S1 — EASY — Plus d'heures de sport à l'école
  ('45f3b0da-5699-5000-8601-2c16948c3c14', '8dfda25f-5808-5e9f-ba3e-bb3970ddf134', 'EE', 'EE3-C5-S1', 'Plus d''heures de sport à l''école',
   'Un débat scolaire porte sur l''augmentation des heures de sport. Un premier argument a déjà été donné : le sport améliore la santé des élèves.',
   'Ajoutez un second argument, portant sur un autre aspect que la santé, en une ou deux phrases.',
   'Votre argument ouvre un aspect différent de celui de la santé.',
   20, 45, NULL, 'EASY', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C5-S2 — EASY — Le train plutôt que la voiture
  ('15b90039-b433-5046-b4d8-472285786882', '8dfda25f-5808-5e9f-ba3e-bb3970ddf134', 'EE', 'EE3-C5-S2', 'Le train plutôt que la voiture',
   'Vous conseillez le train plutôt que la voiture pour un trajet de trois cents kilomètres. Vous avez déjà expliqué que le train pollue moins.',
   'Ajoutez une deuxième raison, sur un autre aspect que la pollution.',
   'Votre nouvel argument ne parle pas d''environnement.',
   20, 45, NULL, 'EASY', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C5-S3 — MEDIUM — La bibliothèque ouverte le dimanche
  ('b9d738b2-8c2d-5279-9539-2c6e70d9fe1e', '8dfda25f-5808-5e9f-ba3e-bb3970ddf134', 'EE', 'EE3-C5-S3', 'La bibliothèque ouverte le dimanche',
   'Votre commune envisage d''ouvrir la bibliothèque le dimanche. Un premier argument est déjà connu : cela arrange les personnes qui travaillent en semaine.',
   'Écrivez une ou deux phrases qui apportent un second argument, portant sur autre chose que les horaires de travail.',
   'Votre argument ne repose pas sur les contraintes d''horaires professionnels.',
   25, 50, NULL, 'MEDIUM', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C5-S4 — MEDIUM — Faire réparer son téléphone
  ('71b850be-8389-5cc4-8a32-0175c6510d22', '8dfda25f-5808-5e9f-ba3e-bb3970ddf134', 'EE', 'EE3-C5-S4', 'Faire réparer son téléphone',
   'Vous conseillez à un proche de faire réparer son téléphone plutôt que d''en acheter un neuf. Votre premier argument était le prix.',
   'Ajoutez un second argument distinct, en une ou deux phrases.',
   'Votre argument ne porte pas sur le coût de la réparation ou de l''achat.',
   25, 50, NULL, 'MEDIUM', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C5-S5 — HARD — Venir au travail à pied
  ('984f40e0-7b3a-54d5-a8f0-3b22dfc7e208', '8dfda25f-5808-5e9f-ba3e-bb3970ddf134', 'EE', 'EE3-C5-S5', 'Venir au travail à pied',
   'Vous encouragez un collègue à venir à pied au bureau. Vous avez déjà avancé que la marche évite les embouteillages du matin.',
   'Écrivez deux phrases qui apportent un second argument, portant sur un autre aspect que la circulation.',
   'Votre argument ouvre un aspect différent des trajets et de la circulation.',
   30, 60, NULL, 'HARD', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C6-S1 — EASY — À la maison ou au bureau
  ('fa075cd0-4618-5f0a-8fb0-8f54dc942e6a', 'cd4ffb3c-e482-5431-91b5-0422b5ccebf8', 'EE', 'EE3-C6-S1', 'À la maison ou au bureau',
   'Votre entreprise laisse chacun choisir entre le travail à domicile et le travail au bureau.',
   'Comparez les deux possibilités en trois phrases : un point fort de chaque option, puis la différence qui compte le plus selon vous.',
   'Les deux options sont mises en relation et une différence explicite apparaît.',
   45, 90, NULL, 'EASY', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C6-S2 — EASY — En ligne ou en magasin
  ('8b576857-473d-5009-9d02-d2f19254c501', 'cd4ffb3c-e482-5431-91b5-0422b5ccebf8', 'EE', 'EE3-C6-S2', 'En ligne ou en magasin',
   'Vous devez acheter une paire de chaussures et vous hésitez entre un site Internet et une boutique de votre ville.',
   'Comparez les deux solutions en trois phrases et faites apparaître la différence la plus importante.',
   'Votre texte oppose les deux solutions sur des points comparables.',
   45, 90, NULL, 'EASY', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C6-S3 — MEDIUM — Un studio ou un trois-pièces
  ('5bf96cdd-4a78-545a-8c2d-2ab682816991', 'cd4ffb3c-e482-5431-91b5-0422b5ccebf8', 'EE', 'EE3-C6-S3', 'Un studio ou un trois-pièces',
   'Pour le même loyer, vous pouvez louer un studio en centre-ville ou un trois-pièces à quarante minutes de train.',
   'Comparez les deux logements en trois phrases et dites ce qui les distingue vraiment.',
   'La comparaison porte sur des points comparables et fait ressortir une différence centrale.',
   45, 90, NULL, 'MEDIUM', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C6-S4 — MEDIUM — Cours en ligne ou en salle
  ('956ea187-3edc-5436-8dea-b4843534f69a', 'cd4ffb3c-e482-5431-91b5-0422b5ccebf8', 'EE', 'EE3-C6-S4', 'Cours en ligne ou en salle',
   'Une association propose ses cours de français au choix : en ligne le soir, ou en salle le samedi matin.',
   'Comparez les deux formules en trois phrases et faites apparaître la différence principale.',
   'Les deux formules sont décrites et mises en relation sur des aspects comparables.',
   45, 90, NULL, 'MEDIUM', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C6-S5 — HARD — Le marché ou le supermarché
  ('b6d2a2ec-c3bd-5bc3-b31a-32425836fbc8', 'cd4ffb3c-e482-5431-91b5-0422b5ccebf8', 'EE', 'EE3-C6-S5', 'Le marché ou le supermarché',
   'Vous faites vos courses alimentaires soit au marché du quartier le dimanche matin, soit au supermarché en semaine.',
   'Comparez les deux façons de faire ses courses en trois ou quatre phrases : avantages, inconvénients, puis la différence essentielle.',
   'Votre texte donne un avantage et un inconvénient pour chaque option, puis la différence essentielle.',
   50, 95, NULL, 'HARD', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C7-S1 — EASY — Une limite aux réseaux sociaux
  ('398434de-86b8-5e31-ab45-c6bd99cf8121', '16b70979-21b7-53f8-91a7-70a20bd385ec', 'EE', 'EE3-C7-S1', 'Une limite aux réseaux sociaux',
   'Vous avez écrit que les réseaux sociaux aident à garder le contact avec sa famille restée à l''étranger.',
   'En deux phrases, conservez cette opinion positive et ajoutez une limite que vous reconnaissez.',
   'Vous reconnaissez une limite réelle sans renoncer à votre opinion de départ.',
   30, 60, NULL, 'EASY', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C7-S2 — EASY — Vivre sans voiture
  ('e22b8f78-4a44-5246-887d-a0b3052f0117', '16b70979-21b7-53f8-91a7-70a20bd385ec', 'EE', 'EE3-C7-S2', 'Vivre sans voiture',
   'Vous pensez qu''il est possible de vivre sans voiture dans une ville moyenne.',
   'Défendez cette position en deux phrases, en reconnaissant une situation où la voiture reste nécessaire.',
   'Vous admettez un cas contraire tout en maintenant votre position.',
   30, 60, NULL, 'EASY', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C7-S3 — MEDIUM — Courir tous les jours
  ('26d61839-4fa9-5e2f-ab82-9617e9a692aa', '16b70979-21b7-53f8-91a7-70a20bd385ec', 'EE', 'EE3-C7-S3', 'Courir tous les jours',
   'Un ami veut courir tous les jours pour progresser rapidement. Vous êtes favorable à la régularité.',
   'En deux phrases, soutenez la régularité et reconnaissez une limite de l''entraînement quotidien.',
   'Une limite réelle est reconnue sans que votre position disparaisse.',
   30, 60, NULL, 'MEDIUM', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C7-S4 — MEDIUM — Choisir ses horaires de travail
  ('d372b38f-4322-5403-b9db-67891e2a33d6', '16b70979-21b7-53f8-91a7-70a20bd385ec', 'EE', 'EE3-C7-S4', 'Choisir ses horaires de travail',
   'Votre entreprise étudie la possibilité de laisser chacun choisir son heure d''arrivée et son heure de départ.',
   'Donnez un avis favorable en deux phrases, en reconnaissant un risque de cette organisation.',
   'Le risque reconnu est réel et votre avis favorable reste identifiable.',
   30, 60, NULL, 'MEDIUM', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C7-S5 — HARD — Des emballages à rapporter
  ('b63c117a-c6c9-5929-a15a-7c0841cd4ae1', '16b70979-21b7-53f8-91a7-70a20bd385ec', 'EE', 'EE3-C7-S5', 'Des emballages à rapporter',
   'Un magasin de votre quartier remplace ses emballages jetables par des bocaux consignés, que les clients rapportent après usage.',
   'Écrivez deux ou trois phrases : soutenez cette initiative, reconnaissez ce qu''elle demande aux clients, puis maintenez votre position.',
   'Vous reconnaissez une contrainte réelle et votre position reste la même à la fin.',
   45, 85, NULL, 'HARD', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C8-S1 — EASY — Une langue étrangère au primaire
  ('3257d30c-3505-550e-91de-2724c53dbc47', '8c9134c2-ccba-59f4-903f-40067a3737ee', 'EE', 'EE3-C8-S1', 'Une langue étrangère au primaire',
   'Un journal scolaire vous demande votre avis sur l''apprentissage d''une deuxième langue dès l''école primaire.',
   'Écrivez trois phrases : votre argument, sa conséquence, puis une conclusion qui reprend votre position.',
   'Vos phrases sont reliées par des connecteurs logiques et la dernière conclut.',
   45, 80, NULL, 'EASY', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C8-S2 — EASY — Un marché de producteurs
  ('35a773ef-d7da-5766-93fe-37fe1746f747', '8c9134c2-ccba-59f4-903f-40067a3737ee', 'EE', 'EE3-C8-S2', 'Un marché de producteurs',
   'Un marché de producteurs s''installe une fois par semaine près de chez vous. Le journal du quartier demande votre avis.',
   'Écrivez trois phrases enchaînées : un argument, sa conséquence, puis une conclusion.',
   'L''enchaînement est marqué par des connecteurs et la dernière phrase conclut clairement.',
   45, 80, NULL, 'EASY', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C8-S3 — MEDIUM — Un jardin partagé de quartier
  ('d2691dd4-07f8-5814-a9d6-dc6e65ee54bc', '8c9134c2-ccba-59f4-903f-40067a3737ee', 'EE', 'EE3-C8-S3', 'Un jardin partagé de quartier',
   'Des habitants proposent de transformer un terrain vide en jardin partagé. La mairie recueille les avis avant de décider.',
   'Écrivez trois ou quatre phrases organisées : votre position, deux idées reliées par des connecteurs, puis une conclusion.',
   'Les idées s''enchaînent avec des connecteurs et le texte se termine par une conclusion.',
   50, 90, NULL, 'MEDIUM', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C8-S4 — MEDIUM — Loger un étudiant chez un senior
  ('7a1cc750-72f6-572b-aad5-9f0e0d84a3c3', '8c9134c2-ccba-59f4-903f-40067a3737ee', 'EE', 'EE3-C8-S4', 'Loger un étudiant chez un senior',
   'Une association met en relation des personnes âgées disposant d''une chambre libre et des étudiants qui cherchent un logement.',
   'Donnez votre avis en trois ou quatre phrases organisées, terminées par une conclusion.',
   'Le texte est enchaîné par des connecteurs et se termine par une conclusion cohérente.',
   50, 90, NULL, 'MEDIUM', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C8-S5 — HARD — Une soirée par semaine sans écran
  ('6bf58c02-c307-5d58-93fd-b9e048a741bc', '8c9134c2-ccba-59f4-903f-40067a3737ee', 'EE', 'EE3-C8-S5', 'Une soirée par semaine sans écran',
   'Un magazine propose à ses lecteurs de tester une soirée par semaine sans téléphone ni télévision, et recueille leurs réactions.',
   'Écrivez quatre phrases organisées : votre position, deux idées reliées par des connecteurs différents, puis une conclusion qui ne répète pas votre position mot pour mot.',
   'Les phrases sont reliées par des connecteurs variés et la conclusion apporte une formulation nouvelle.',
   55, 95, NULL, 'HARD', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02');

INSERT INTO skill_references (id, skill_prompt_id, level, text, pedagogical_note,
                              created_at, updated_at)
VALUES
  -- EE3-C1-S1 / INSUFFICIENT
  ('aed7f878-0903-550a-b484-7aa23b90fefa', '1b544fd4-3412-5003-84c3-fa0a9bbffd79', 'INSUFFICIENT',
   'Le télétravail est un sujet très intéressant qui concerne beaucoup de personnes aujourd''hui en France.',
   'Le sujet est annoncé, mais votre avis personnel reste introuvable.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C1-S1 / EXPECTED
  ('9cc93cb0-e153-59e3-84e0-18801c20dd7b', '1b544fd4-3412-5003-84c3-fa0a9bbffd79', 'EXPECTED',
   'À mon avis, le télétravail devrait être généralisé dans les entreprises qui peuvent l''organiser.',
   'Votre position est immédiatement identifiable : c''est exactement ce qu''on attend.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C1-S1 / EXCELLENT
  ('9845dd0d-7835-50b5-8312-d4b9d4186756', '1b544fd4-3412-5003-84c3-fa0a9bbffd79', 'EXCELLENT',
   'Je suis clairement favorable à la généralisation du télétravail dans toutes les entreprises où le travail à distance est possible.',
   'Position nette, et sa portée est précisée en quelques mots.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C1-S2 / INSUFFICIENT
  ('978cc35e-96ed-51ae-9c97-6e86618c1373', '04462599-ac26-5c1c-acd3-84588db32e6d', 'INSUFFICIENT',
   'Beaucoup de gens prennent le bus chaque jour et la question de la gratuité revient souvent.',
   'Vous décrivez la situation ; votre avis personnel n''apparaît pas.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C1-S2 / EXPECTED
  ('1005b5d3-390b-5b38-a078-10f4c4cd4e99', '04462599-ac26-5c1c-acd3-84588db32e6d', 'EXPECTED',
   'Je pense que la gratuité des transports en commun est une bonne mesure pour ma ville.',
   'L''avis est direct et facile à repérer dès la première ligne.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C1-S2 / EXCELLENT
  ('395a8fe2-97b6-5038-ad6b-f42e8e6c9ca9', '04462599-ac26-5c1c-acd3-84588db32e6d', 'EXCELLENT',
   'Je suis résolument favorable à la gratuité des bus et des tramways pour tous les habitants de la ville.',
   'Une position ferme, portée par un verbe d''opinion précis.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C1-S3 / INSUFFICIENT
  ('d60bf3b1-b371-541d-9fb9-49325132ce80', 'f7619b38-e2a3-5942-ad13-f64e43fed883', 'INSUFFICIENT',
   'Ce menu unique a des avantages et des inconvénients, cela dépend vraiment des goûts de chacun.',
   'Vous restez au milieu : le lecteur ne peut pas identifier votre avis.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C1-S3 / EXPECTED
  ('d5d411a8-68bd-5aa9-b0e4-f8eeff268e64', 'f7619b38-e2a3-5942-ad13-f64e43fed883', 'EXPECTED',
   'Personnellement, je ne suis pas d''accord avec ce menu unique au restaurant de l''entreprise.',
   'Le désaccord est annoncé simplement et sans ambiguïté.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C1-S3 / EXCELLENT
  ('97be6fcc-aef5-51ef-86c6-92ae5eb18f7d', 'f7619b38-e2a3-5942-ad13-f64e43fed883', 'EXCELLENT',
   'Je désapprouve nettement ce menu unique, qui me paraît une mauvaise décision pour les salariés de l''entreprise.',
   'L''avis est net et le mot « unique » est repris : aucun flou.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C1-S4 / INSUFFICIENT
  ('9243e18e-0f6b-539b-a8d8-cfe7245d3d6d', '7368b573-7db7-5820-97ef-af79561811a2', 'INSUFFICIENT',
   'Les réseaux sociaux occupent une place énorme dans la vie des jeunes d''aujourd''hui.',
   'C''est un constat juste, mais ce n''est pas une réponse à la question posée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C1-S4 / EXPECTED
  ('9b36f8f6-674b-5fc5-842a-04404a99ce91', '7368b573-7db7-5820-97ef-af79561811a2', 'EXPECTED',
   'Je suis favorable à un âge minimum pour créer un compte sur un réseau social.',
   'Vous répondez directement à la question : la position est identifiable.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C1-S4 / EXCELLENT
  ('caec5b06-0ffe-5d2e-b032-76b6cf6c6d04', '7368b573-7db7-5820-97ef-af79561811a2', 'EXCELLENT',
   'À mon sens, un âge minimum est nécessaire, et il devrait s''appliquer à toutes les plateformes sans exception.',
   'Position affirmée, avec une précision utile sur ce qu''elle couvre.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C1-S5 / INSUFFICIENT
  ('4b758c9b-6b8a-5542-b522-ab341fda781e', '3e6418ca-e1f4-54e5-bd4d-a9b82b16ed44', 'INSUFFICIENT',
   'Les deux possibilités sont intéressantes et beaucoup de personnes se posent exactement la même question aujourd''hui. Tout dépend de la situation de chacun.',
   'Aucune option n''est choisie : votre ami ne sait pas quoi faire.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C1-S5 / EXPECTED
  ('fdfc2858-a97b-5297-9d62-09ec93587367', '3e6418ca-e1f4-54e5-bd4d-a9b82b16ed44', 'EXPECTED',
   'À ta place, je choisirais la maison à la campagne. C''est vraiment la solution que je te conseille.',
   'Le choix est explicite et le lecteur sait immédiatement où vous allez.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C1-S5 / EXCELLENT
  ('0c45c93e-81fe-5560-bdea-d579c04aaa76', '3e6418ca-e1f4-54e5-bd4d-a9b82b16ed44', 'EXCELLENT',
   'Je te recommande clairement l''appartement en centre-ville plutôt que la maison à la campagne : c''est l''option que je choisirais moi-même.',
   'Les deux options sont mises face à face et une seule est retenue.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C2-S1 / INSUFFICIENT
  ('5d492cc2-c3a6-59b1-8e38-eb487e921b79', 'f928f912-86be-573f-9e19-5d32ef75c40b', 'INSUFFICIENT',
   'Les transports publics sont indispensables parce qu''ils sont vraiment très importants pour tout le monde.',
   'La phrase répète l''opinion au lieu d''apporter une raison nouvelle.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C2-S1 / EXPECTED
  ('e1b821f9-830c-5440-a32f-a043be989028', 'f928f912-86be-573f-9e19-5d32ef75c40b', 'EXPECTED',
   'Ils permettent de se déplacer chaque jour sans posséder de voiture, ce qui coûte beaucoup moins cher.',
   'Une raison claire, directement reliée à l''opinion : c''est suffisant.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C2-S1 / EXCELLENT
  ('9bc70ae6-8c79-58b0-878b-81532eaa4c06', 'f928f912-86be-573f-9e19-5d32ef75c40b', 'EXCELLENT',
   'Ils offrent une solution de déplacement à ceux qui n''ont ni voiture ni permis, c''est-à-dire une part importante des habitants.',
   'La raison désigne précisément qui en profite, ce qui la rend plus solide.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C2-S2 / INSUFFICIENT
  ('c41d7a17-7961-59be-b7fc-d6e1e07da423', 'cc5b70de-4439-5e33-bba4-88200dd3dcfb', 'INSUFFICIENT',
   'Le sport est important parce que c''est bien de faire du sport tous les jours.',
   'L''idée tourne en rond : il manque une véritable raison.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C2-S2 / EXPECTED
  ('de46e3c8-3245-5808-86c1-aee2a309e2b6', 'cc5b70de-4439-5e33-bba4-88200dd3dcfb', 'EXPECTED',
   'Une activité physique régulière aide à rester en bonne santé et à mieux dormir la nuit.',
   'Deux effets concrets sont nommés : la raison soutient bien l''opinion.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C2-S2 / EXCELLENT
  ('521625bc-69cb-53e1-b0bb-12a36cda2b5b', 'cc5b70de-4439-5e33-bba4-88200dd3dcfb', 'EXCELLENT',
   'Trente minutes de marche par jour suffisent à faire baisser la fatigue et la tension accumulées au travail.',
   'La raison est précise et parle directement du quotidien de votre collègue.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C2-S3 / INSUFFICIENT
  ('debe7e71-efd6-5bff-baf0-2bd7502182b4', '3a9c17f1-4bf5-5307-bc77-bba6d255f842', 'INSUFFICIENT',
   'Je suis d''accord parce que les langues étrangères sont utiles dans le monde d''aujourd''hui.',
   'La raison est vraie, mais elle ne parle pas de l''âge.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C2-S3 / EXPECTED
  ('3eadfe8d-968b-5cd6-899c-5cd89586b878', '3a9c17f1-4bf5-5307-bc77-bba6d255f842', 'EXPECTED',
   'À six ans, les enfants reproduisent les sons d''une nouvelle langue beaucoup plus facilement.',
   'La raison porte bien sur le fait de commencer tôt : elle est pertinente.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C2-S3 / EXCELLENT
  ('d5e199ab-0c71-5d2b-8cde-e4a6734bf2be', '3a9c17f1-4bf5-5307-bc77-bba6d255f842', 'EXCELLENT',
   'Un enfant de six ans imite les sons sans avoir peur de se tromper, ce qu''un adolescent ose rarement faire.',
   'La raison cible exactement l''âge et dit ce qui change ensuite.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C2-S4 / INSUFFICIENT
  ('a90c0b1a-f18e-54b6-b605-07083e2ba540', '5d63eed0-ef1c-595b-b074-9a0d2912d5ae', 'INSUFFICIENT',
   'Je pense que ces ateliers devraient exister partout parce que c''est très utile pour l''environnement.',
   '« Utile pour l''environnement » reste vague : on ne sait pas en quoi.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C2-S4 / EXPECTED
  ('77bc7338-f062-5f33-b0b1-9f369238c4da', '5d63eed0-ef1c-595b-b074-9a0d2912d5ae', 'EXPECTED',
   'Ces ateliers évitent de jeter des appareils qui fonctionnent encore très bien après une petite réparation.',
   'La raison dit précisément ce que l''atelier permet d''éviter.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C2-S4 / EXCELLENT
  ('b00f1e55-5889-54a8-9871-d81ca40df46e', '5d63eed0-ef1c-595b-b074-9a0d2912d5ae', 'EXCELLENT',
   'Ces ateliers prolongent la vie d''appareils encore utilisables et réduisent donc à la fois les déchets du quartier et les dépenses des habitants.',
   'Une seule raison, mais son double effet est nommé clairement.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C2-S5 / INSUFFICIENT
  ('68ae3382-dd88-55a0-a1e2-c5a71a2bb5de', 'fbd8c101-25dc-5015-bf43-26c18b6398fd', 'INSUFFICIENT',
   'Je te conseille l''occasion parce que c''est vraiment bien et que beaucoup de gens le font maintenant.',
   'La popularité n''est pas une raison : on attend ce que cela apporte.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C2-S5 / EXPECTED
  ('2af9af77-313b-5e70-8668-217bc9f5545c', 'fbd8c101-25dc-5015-bf43-26c18b6398fd', 'EXPECTED',
   'Les vêtements d''occasion coûtent souvent trois fois moins cher que les mêmes articles achetés neufs.',
   'Une raison chiffrée et directement liée au choix de l''occasion.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C2-S5 / EXCELLENT
  ('c26a128c-996e-51d1-852a-1e89da0454aa', 'fbd8c101-25dc-5015-bf43-26c18b6398fd', 'EXCELLENT',
   'Pour le prix d''un seul vêtement neuf, on repart avec plusieurs pièces d''occasion en bon état, souvent de meilleure qualité.',
   'La raison est chiffrée et met en avant ce que l''on gagne réellement.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C3-S1 / INSUFFICIENT
  ('6b934197-c1c1-56d4-9e9f-e93ce521f9fe', '95bb59a9-7d73-595c-b1f8-5c41750a960c', 'INSUFFICIENT',
   'Vivre en ville est très pratique. C''est vraiment beaucoup plus pratique que la campagne pour la vie de tous les jours.',
   'L''idée est répétée en d''autres mots, mais jamais expliquée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C3-S1 / EXPECTED
  ('1598bf23-4acb-5b75-826a-0ba4fd24b37f', '95bb59a9-7d73-595c-b1f8-5c41750a960c', 'EXPECTED',
   'En ville, les commerces, les écoles et les médecins se trouvent près du logement. On perd donc beaucoup moins de temps en déplacements chaque semaine.',
   'Vous dites d''où vient l''avantage et quelle conséquence il a : c''est un vrai développement.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C3-S1 / EXCELLENT
  ('938fd39f-c736-5e92-ba9c-7968ba6bae97', '95bb59a9-7d73-595c-b1f8-5c41750a960c', 'EXCELLENT',
   'En ville, la plupart des services se trouvent à quelques minutes à pied du logement. Ce temps de trajet économisé chaque jour finit par changer complètement l''organisation d''une semaine.',
   'La cause est précise et la conséquence est menée jusqu''au bout.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C3-S2 / INSUFFICIENT
  ('f929a682-17ce-5972-a755-1e3077afff69', '3f0bc739-bff1-5afd-8bb8-b3d5653a456a', 'INSUFFICIENT',
   'Les pistes cyclables sont très utiles. Elles sont aussi bonnes pour l''environnement et pour la santé des habitants.',
   'La deuxième phrase ajoute d''autres idées au lieu d''expliquer la première.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C3-S2 / EXPECTED
  ('cb605b7f-fb3e-5034-8dab-73d30008d539', '3f0bc739-bff1-5afd-8bb8-b3d5653a456a', 'EXPECTED',
   'Les pistes cyclables séparent les vélos des voitures. Les cyclistes se sentent donc plus en sécurité et sont plus nombreux à circuler en ville.',
   'La deuxième phrase découle de la première : l''idée est bien développée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C3-S2 / EXCELLENT
  ('c26deb98-5347-597e-9271-5e72a3965636', '3f0bc739-bff1-5afd-8bb8-b3d5653a456a', 'EXCELLENT',
   'Les pistes cyclables séparent physiquement les vélos de la circulation. Cette séparation rassure surtout ceux qui n''osaient pas rouler en ville, et ce sont précisément eux qui font augmenter le nombre de cyclistes.',
   'L''explication va jusqu''à dire qui change de comportement, et pourquoi.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C3-S3 / INSUFFICIENT
  ('473fa2ff-37a9-57d5-a821-b5bb10db6082', 'b9855e23-7126-5309-be90-106148e48a82', 'INSUFFICIENT',
   'Quinze minutes par jour, c''est une très bonne idée. Lire est important pour tout le monde, à tout âge.',
   'Vous approuvez, mais sans dire comment ces quinze minutes agissent.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C3-S3 / EXPECTED
  ('fb60edac-ed9e-5e7b-9978-3e74db3d0822', 'b9855e23-7126-5309-be90-106148e48a82', 'EXPECTED',
   'Quinze minutes tiennent facilement dans une journée chargée. Comme l''habitude devient régulière, on finit par lire plusieurs livres dans l''année.',
   'Vous reliez la durée courte à un résultat : l''argument est développé.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C3-S3 / EXCELLENT
  ('e9d0db91-0263-51e0-82fe-bee8dba03ab2', 'b9855e23-7126-5309-be90-106148e48a82', 'EXCELLENT',
   'Quinze minutes se glissent dans un trajet ou avant de dormir, sans rien retirer au reste de la journée. C''est cette régularité, bien plus que la durée, qui installe l''habitude et fait progresser le vocabulaire.',
   'Le mécanisme est nommé : c''est la régularité qui produit l''effet.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C3-S4 / INSUFFICIENT
  ('7862a280-9c7e-518c-84e4-1fdd8fdb9deb', '98cb2e34-4a42-5f4c-9d39-520ba11807ad', 'INSUFFICIENT',
   'Cette visite gratuite est une bonne initiative. La santé est quelque chose de très important dans la vie de chacun.',
   'La deuxième phrase élargit le sujet au lieu d''expliquer votre raison.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C3-S4 / EXPECTED
  ('6babb701-21be-5486-a261-c1809af504d3', '98cb2e34-4a42-5f4c-9d39-520ba11807ad', 'EXPECTED',
   'Une visite annuelle permet de repérer un problème avant les premiers symptômes. Le traitement est alors plus simple et beaucoup plus court.',
   'Cause puis conséquence : l''argument tient debout tout seul.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C3-S4 / EXCELLENT
  ('dc631eea-0473-5e0f-9b6d-7aa16af890e4', '98cb2e34-4a42-5f4c-9d39-520ba11807ad', 'EXCELLENT',
   'Une visite annuelle permet de repérer un déséquilibre avant qu''il ne provoque le moindre symptôme. Plus le problème est pris tôt, moins le traitement est lourd et moins la personne s''absente de son travail.',
   'La conséquence est poussée jusqu''à un effet concret sur la vie quotidienne.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C3-S5 / INSUFFICIENT
  ('36b74db9-40c8-5310-a149-d23434e58522', '57b8ee98-7ee3-5b8b-b3c7-f3934c65d31f', 'INSUFFICIENT',
   'Le bénévolat est très enrichissant. Cela fait du bien à ceux qui aident comme à ceux qui sont aidés. C''est pour cette raison que je le recommande à tout le monde.',
   'L''idée est reformulée trois fois : l''explication reste à écrire.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C3-S5 / EXPECTED
  ('9997793f-c1a1-5f2a-845e-f7cfaed260ab', '57b8ee98-7ee3-5b8b-b3c7-f3934c65d31f', 'EXPECTED',
   'En donnant quelques heures, un bénévole rencontre des personnes qu''il n''aurait jamais croisées autrement. Ces rencontres élargissent son réseau et lui font découvrir des compétences qu''il ne se connaissait pas. L''association, de son côté, gagne les bras dont elle manque.',
   'Chaque phrase avance d''un cran : l''idée est réellement développée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C3-S5 / EXCELLENT
  ('9e4805b2-ec30-5123-ae08-7d2b695ad3d5', '57b8ee98-7ee3-5b8b-b3c7-f3934c65d31f', 'EXCELLENT',
   'En donnant quelques heures, un bénévole se retrouve à organiser, à expliquer, parfois à décider. Ces responsabilités, prises sans pression professionnelle, lui apprennent à travailler avec des personnes très différentes de lui. C''est ainsi que le temps donné revient sous une autre forme, pendant que l''association avance.',
   'Le mécanisme est décrit étape par étape jusqu''au bout de l''idée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C4-S1 / INSUFFICIENT
  ('c69ab965-78a5-5968-9149-17dee778fcfb', '94e94e1a-8d0e-52e3-b39c-a5f11e0ffaf0', 'INSUFFICIENT',
   'Par exemple, le français est utile dans beaucoup de situations de la vie de tous les jours.',
   '« Beaucoup de situations » n''est pas un exemple : choisissez-en une seule.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C4-S1 / EXPECTED
  ('af021d1e-97cf-507f-a9b3-4236c1652213', '94e94e1a-8d0e-52e3-b39c-a5f11e0ffaf0', 'EXPECTED',
   'Par exemple, la semaine dernière, j''ai pu expliquer moi-même mon problème à la pharmacie, sans demander à quelqu''un de traduire.',
   'Une situation datée et concrète : l''argument devient visible.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C4-S1 / EXCELLENT
  ('7fca01c3-fb59-5d6f-b871-063b0adf1466', '94e94e1a-8d0e-52e3-b39c-a5f11e0ffaf0', 'EXCELLENT',
   'Par exemple, à la pharmacie, j''ai décrit les symptômes de ma fille et posé deux questions sur le médicament. Il y a un an, je serais reparti avec la boîte sans rien comprendre.',
   'L''exemple montre la situation et ce qui aurait changé sans le français.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C4-S2 / INSUFFICIENT
  ('13284ee6-631f-5738-837f-5c3f088a6930', '8c41805e-d61e-54b3-8cca-fd7adf9a1213', 'INSUFFICIENT',
   'Par exemple, quand on cuisine soi-même, on dépense toujours moins d''argent que si on achète des plats préparés.',
   'C''est encore une généralité : ajoutez un plat, un prix ou un moment.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C4-S2 / EXPECTED
  ('298fd413-1242-5980-ad1e-39d66360dfe7', '8c41805e-d61e-54b3-8cca-fd7adf9a1213', 'EXPECTED',
   'Par exemple, dimanche, j''ai préparé un grand plat de lentilles pour cinq euros et nous avons mangé à quatre pendant deux jours.',
   'Plat, prix et nombre de repas : l''exemple parle de lui-même.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C4-S2 / EXCELLENT
  ('dbccf4c4-4111-51e1-8c88-5cb3e7986875', '8c41805e-d61e-54b3-8cca-fd7adf9a1213', 'EXCELLENT',
   'Par exemple, dimanche dernier, un plat de lentilles au four m''a coûté cinq euros et a nourri quatre personnes pendant deux jours. Le même repas en barquettes m''aurait coûté plus de vingt euros.',
   'Deux montants comparables rendent l''exemple immédiatement parlant.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C4-S3 / INSUFFICIENT
  ('ae3a7f9d-282b-5773-a7ad-65bca962cd61', 'a295fbaa-f839-51c7-b87f-92e6c2988e46', 'INSUFFICIENT',
   'Par exemple, sur Internet, on peut faire beaucoup de démarches sans se déplacer, et c''est bien plus rapide.',
   'Vous reformulez l''argument ; il manque une démarche précise.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C4-S3 / EXPECTED
  ('fd3b604b-f8b8-5d06-926b-c4ebdc96777d', 'a295fbaa-f839-51c7-b87f-92e6c2988e46', 'EXPECTED',
   'Par exemple, j''ai renouvelé ma carte de transport en ligne en dix minutes, un mardi soir, au lieu d''attendre au guichet.',
   'Démarche, durée et moment : l''exemple est bien situé.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C4-S3 / EXCELLENT
  ('914fd15b-9e3e-5ba7-8315-cfa6bdc89db2', 'a295fbaa-f839-51c7-b87f-92e6c2988e46', 'EXCELLENT',
   'Par exemple, j''ai renouvelé ma carte de transport un mardi soir, après le travail : dix minutes sur mon téléphone, contre une matinée entière d''attente au guichet l''an dernier.',
   'L''exemple chiffre le temps gagné, ce qui rend l''argument concret.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C4-S4 / INSUFFICIENT
  ('ace9866c-f920-5468-bf8a-df61fea1de3c', '3563ed2d-2c7f-5f3a-9f39-0b57c039b203', 'INSUFFICIENT',
   'Par exemple, quand on est plusieurs, on trouve toujours des solutions plus rapidement que tout seul.',
   'L''idée est répétée sous une autre forme, sans situation précise.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C4-S4 / EXPECTED
  ('caaa4cd5-1a20-5551-86c7-ab2455310fa7', '3563ed2d-2c7f-5f3a-9f39-0b57c039b203', 'EXPECTED',
   'Par exemple, dans mon service, une commande s''est perdue et nous avons partagé les appels à trois : le problème était réglé avant midi.',
   'Une situation identifiable, avec un début et une fin : l''exemple fonctionne.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C4-S4 / EXCELLENT
  ('bcc39738-ee64-59e1-9c73-65cc21d4b02c', '3563ed2d-2c7f-5f3a-9f39-0b57c039b203', 'EXCELLENT',
   'Par exemple, une commande importante s''était perdue dans mon service. Nous nous sommes réparti les appels à trois, chacun sur un fournisseur différent, et la livraison était reprogrammée avant midi.',
   'L''exemple montre comment l''équipe s''est organisée, pas seulement le résultat.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C4-S5 / INSUFFICIENT
  ('4fffd352-9d3f-552e-93ab-7e870d0c61e1', 'aed6dd2c-e4e5-5d33-a9e6-60827db51808', 'INSUFFICIENT',
   'Par exemple, si tout le monde trie ses déchets, la planète ira mieux et il y aura beaucoup moins de pollution partout.',
   'L''effet annoncé est trop large pour être vérifié : cherchez plus près de vous.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C4-S5 / EXPECTED
  ('74bee0c7-f716-5bd0-b641-7ef4d6f0c834', 'aed6dd2c-e4e5-5d33-a9e6-60827db51808', 'EXPECTED',
   'Par exemple, dans mon immeuble, les habitants ont commencé à trier le verre l''an dernier. Depuis, les poubelles ordinaires débordent beaucoup moins et le local est bien plus propre.',
   'Un lieu, une période, un effet visible : l''exemple soutient l''argument.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C4-S5 / EXCELLENT
  ('38beb23c-27f1-51ca-81e5-909ee9f4c448', 'aed6dd2c-e4e5-5d33-a9e6-60827db51808', 'EXCELLENT',
   'Par exemple, dans mon immeuble de vingt logements, un composteur a été installé au printemps dernier. En quelques mois, le bac ordinaire est passé de trois sorties par semaine à deux, et les habitants récupèrent du terreau pour leurs balcons.',
   'Chiffres et durée transforment l''exemple en preuve, sans quitter le quotidien.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C5-S1 / INSUFFICIENT
  ('7c6f16ed-f43f-5e4b-9aa8-096518b6c4d8', '45f3b0da-5699-5000-8601-2c16948c3c14', 'INSUFFICIENT',
   'De plus, le sport permet aux élèves d''être en meilleure forme physique et de tomber malades moins souvent.',
   'C''est encore la santé : il reste à trouver un autre angle.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C5-S1 / EXPECTED
  ('65e9e530-d984-53af-81b3-5d16c97cc029', '45f3b0da-5699-5000-8601-2c16948c3c14', 'EXPECTED',
   'De plus, le sport apprend aux élèves à respecter des règles et à jouer avec des camarades qu''ils ne choisissent pas.',
   'Un angle social, nettement distinct du premier argument.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C5-S1 / EXCELLENT
  ('8e6cd7dd-b350-5546-b1ac-ada610b3b027', '45f3b0da-5699-5000-8601-2c16948c3c14', 'EXCELLENT',
   'Par ailleurs, le sport est l''un des rares moments où un élève en difficulté scolaire peut réussir devant les autres et reprendre confiance.',
   'Un angle vraiment neuf : la place de l''élève dans le groupe.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C5-S2 / INSUFFICIENT
  ('994b9584-1372-5bef-918a-6fa4c4b4da17', '15b90039-b433-5046-b4d8-472285786882', 'INSUFFICIENT',
   'En plus, le train est bien meilleur pour la planète et rejette beaucoup moins de gaz que la voiture.',
   'Vous reformulez le premier argument : le second angle reste à trouver.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C5-S2 / EXPECTED
  ('910860ce-22b9-5e81-a8b2-926c5a768121', '15b90039-b433-5046-b4d8-472285786882', 'EXPECTED',
   'En plus, dans le train, on peut lire, travailler ou dormir pendant tout le trajet, ce qui est impossible au volant.',
   'Le temps de trajet devient utile : c''est un argument nouveau.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C5-S2 / EXCELLENT
  ('af3ed31c-9db3-5ba4-bc1e-20b077ee3dba', '15b90039-b433-5046-b4d8-472285786882', 'EXCELLENT',
   'En plus, trois heures de train se passent sans embouteillage ni fatigue de conduite : on arrive en état de travailler, ce qui n''est jamais le cas après quatre heures d''autoroute.',
   'L''argument change de terrain : l''état dans lequel on arrive.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C5-S3 / INSUFFICIENT
  ('17a919c7-e536-5620-b3e3-c84e0669793b', 'b9d738b2-8c2d-5279-9539-2c6e70d9fe1e', 'INSUFFICIENT',
   'Ensuite, beaucoup de personnes ne peuvent pas venir en semaine à cause de leurs horaires de bureau.',
   'C''est le même argument, formulé autrement.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C5-S3 / EXPECTED
  ('1c0f5fa8-7202-5823-be72-b99cdb8da186', 'b9d738b2-8c2d-5279-9539-2c6e70d9fe1e', 'EXPECTED',
   'Ensuite, la bibliothèque offrirait aux familles un lieu gratuit et chauffé pour passer un dimanche d''hiver.',
   'Un usage social nouveau : l''angle est bien différent.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C5-S3 / EXCELLENT
  ('1daa38ed-69c5-5e4b-b88f-170cfc631214', 'b9d738b2-8c2d-5279-9539-2c6e70d9fe1e', 'EXCELLENT',
   'Ensuite, le dimanche est souvent le seul jour où parents et enfants sortent ensemble : la bibliothèque deviendrait un lieu de sortie familiale, et plus seulement un service.',
   'L''argument déplace le sujet du service vers la vie familiale.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C5-S4 / INSUFFICIENT
  ('05547f6a-e37b-5673-875b-087b07aa5092', '71b850be-8389-5cc4-8a32-0175c6510d22', 'INSUFFICIENT',
   'D''autre part, une réparation revient beaucoup moins cher qu''un téléphone neuf de la même marque.',
   'L''argument du prix revient : il en faut un autre.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C5-S4 / EXPECTED
  ('a20a76da-5acb-5f74-a237-75565ee12be8', '71b850be-8389-5cc4-8a32-0175c6510d22', 'EXPECTED',
   'D''autre part, on garde ses photos, ses applications et ses habitudes, sans passer une soirée à tout réinstaller.',
   'Le confort d''usage est un angle nouveau et convaincant.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C5-S4 / EXCELLENT
  ('6d80e6e4-dbde-51cd-970b-bc3848969f93', '71b850be-8389-5cc4-8a32-0175c6510d22', 'EXCELLENT',
   'D''autre part, faire réparer son téléphone fait vivre un atelier du quartier et un métier technique qui disparaît lentement des villes moyennes.',
   'L''argument s''ouvre sur l''économie locale : un terrain totalement différent.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C5-S5 / INSUFFICIENT
  ('75e4e00c-e23c-52b0-a325-53271811eee7', '984f40e0-7b3a-54d5-a8f0-3b22dfc7e208', 'INSUFFICIENT',
   'Ensuite, à pied, tu ne restes jamais bloqué dans les bouchons. Tu arrives donc toujours à l''heure au bureau.',
   'C''est encore la circulation : le second angle manque.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C5-S5 / EXPECTED
  ('eb6c6d3d-d0d2-5136-baf8-402abe6a7b15', '984f40e0-7b3a-54d5-a8f0-3b22dfc7e208', 'EXPECTED',
   'Ensuite, vingt minutes de marche le matin réveillent vraiment. On arrive au bureau bien plus concentré qu''après un trajet en voiture.',
   'L''argument porte maintenant sur la forme au travail : c''est bien distinct.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C5-S5 / EXCELLENT
  ('fe8fd179-9a07-533d-abc1-1775b6ce1006', '984f40e0-7b3a-54d5-a8f0-3b22dfc7e208', 'EXCELLENT',
   'Ensuite, ce trajet à pied est souvent le seul moment de la journée où l''on n''a rien d''autre à faire que marcher. Beaucoup de gens y règlent mentalement ce qui les préoccupe avant même d''ouvrir leur ordinateur.',
   'Un angle inattendu : le trajet devient un temps pour soi.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C6-S1 / INSUFFICIENT
  ('33384364-37dd-5791-9ade-99aea8a4bcb9', 'fa075cd0-4618-5f0a-8fb0-8f54dc942e6a', 'INSUFFICIENT',
   'Le télétravail est très agréable et beaucoup de personnes l''apprécient. Le bureau a lui aussi ses avantages. Chacun choisit ce qu''il préfère.',
   'Les deux options sont citées, mais jamais mises face à face.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C6-S1 / EXPECTED
  ('93c9bac4-3c0b-597d-bc46-108b6f7bb90e', 'fa075cd0-4618-5f0a-8fb0-8f54dc942e6a', 'EXPECTED',
   'À la maison, on gagne le temps du trajet et on travaille au calme. Au bureau, on obtient une réponse simplement en se levant de sa chaise. La grande différence, c''est la rapidité des échanges avec les collègues.',
   'Chaque option a son point fort, et la différence principale est nommée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C6-S1 / EXCELLENT
  ('4b8d93ee-14bd-55fa-9d5d-eef1a1d07e47', 'fa075cd0-4618-5f0a-8fb0-8f54dc942e6a', 'EXCELLENT',
   'À la maison, les heures sans interruption permettent d''avancer sur les dossiers longs. Au bureau, une question se règle en trente secondes au lieu de trois courriels. Autrement dit, l''un favorise la concentration, l''autre la coordination : le bon choix dépend du travail de la semaine.',
   'La comparaison se termine par un critère clair pour décider.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C6-S2 / INSUFFICIENT
  ('2791dfbd-d1d4-54b2-86aa-fe98ba0d5f1e', '8b576857-473d-5009-9d02-d2f19254c501', 'INSUFFICIENT',
   'Acheter en ligne est pratique et rapide. Les magasins sont sympathiques aussi. Les deux solutions ont des avantages intéressants.',
   'Les avantages restent séparés : rien n''est réellement comparé.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C6-S2 / EXPECTED
  ('2d449b44-6611-513e-9be7-ba8f5ab6ec45', '8b576857-473d-5009-9d02-d2f19254c501', 'EXPECTED',
   'En ligne, le choix est plus large et les prix souvent plus bas. En magasin, on essaie les chaussures avant de payer. Pour des chaussures, pouvoir essayer reste selon moi le point décisif.',
   'Un même critère des deux côtés, puis un choix justifié : la comparaison tient.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C6-S2 / EXCELLENT
  ('6f4e1588-1f5e-5f39-bd62-c8904f1c4c51', '8b576857-473d-5009-9d02-d2f19254c501', 'EXCELLENT',
   'En ligne, on compare vingt modèles en dix minutes, mais on découvre la taille réelle une semaine plus tard. En magasin, le choix est plus étroit et l''on repart chaussé le jour même. Le partage se fait donc entre l''étendue du choix et la certitude du résultat.',
   'Les options sont opposées point par point, jusqu''à une formule qui résume.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C6-S3 / INSUFFICIENT
  ('5fc47bfc-ef44-5a57-b54f-b0a557b6c392', '5bf96cdd-4a78-545a-8c2d-2ab682816991', 'INSUFFICIENT',
   'Le studio en ville est petit mais bien placé. Le trois-pièces est nettement plus grand. Je pense que les deux logements sont intéressants.',
   'La troisième phrase n''ajoute rien : il manque la différence qui compte.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C6-S3 / EXPECTED
  ('a80363f5-a726-56a5-912a-9e116480ec43', '5bf96cdd-4a78-545a-8c2d-2ab682816991', 'EXPECTED',
   'Le studio offre peu d''espace, mais il met tout à portée de marche. Le trois-pièces donne de la place, au prix de quatre-vingts minutes de train par jour. La question est donc de savoir ce que l''on préfère perdre : de l''espace ou du temps.',
   'Une différence centrale est formulée : l''espace contre le temps.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C6-S3 / EXCELLENT
  ('7b2b1fa0-239f-5386-ae2c-e9cecaaa6b9f', '5bf96cdd-4a78-545a-8c2d-2ab682816991', 'EXCELLENT',
   'Le studio coûte le même loyer mais supprime presque tous les trajets. Le trois-pièces ajoute deux pièces et retire près de sept heures de temps libre par semaine. À loyer égal, on n''achète donc pas la même chose : des mètres carrés d''un côté, des heures de l''autre.',
   'Le loyer identique sert de base commune : la comparaison devient rigoureuse.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C6-S4 / INSUFFICIENT
  ('4c5747f9-4bc5-533f-8876-c0b1ad513056', '956ea187-3edc-5436-8dea-b4843534f69a', 'INSUFFICIENT',
   'Les cours en ligne sont pratiques pour les personnes occupées. Les cours en salle sont bien aussi. Chacun choisit selon son emploi du temps.',
   'La deuxième formule n''est pas décrite : la comparaison reste à moitié faite.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C6-S4 / EXPECTED
  ('27ce0258-8f2f-55c8-8e35-f89439dea900', '956ea187-3edc-5436-8dea-b4843534f69a', 'EXPECTED',
   'En ligne, on suit le cours depuis chez soi, sans transport ni garde d''enfants. En salle, on parle avec de vraies personnes et on ose davantage. Pour progresser à l''oral, la salle me paraît plus efficace.',
   'Chaque formule est décrite, puis un critère tranche : c''est complet.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C6-S4 / EXCELLENT
  ('cb710305-cb95-5b55-8fb8-4f6469788561', '956ea187-3edc-5436-8dea-b4843534f69a', 'EXCELLENT',
   'En ligne, le cours tient dans une soirée et supprime le transport, mais chacun garde son micro fermé. En salle, la matinée coûte un déplacement et offre deux heures de conversation réelle. Selon que l''on manque de temps ou de pratique orale, la bonne formule n''est pas la même.',
   'Chaque avantage est payé par un inconvénient : la comparaison est équilibrée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C6-S5 / INSUFFICIENT
  ('43633b97-ca26-58ca-a5b6-acb38c0fcf19', 'b6d2a2ec-c3bd-5bc3-b31a-32425836fbc8', 'INSUFFICIENT',
   'Au marché, les produits sont frais et les vendeurs sont sympathiques. Le supermarché est ouvert tous les jours et on y trouve de tout. J''aime bien les deux, cela dépend des semaines.',
   'Seuls les avantages apparaissent : les inconvénients et la différence manquent.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C6-S5 / EXPECTED
  ('1b295966-9417-5f9c-98ac-8749e61b1408', 'b6d2a2ec-c3bd-5bc3-b31a-32425836fbc8', 'EXPECTED',
   'Au marché, les fruits et les légumes sont plus frais, mais il faut y aller le dimanche matin. Au supermarché, on trouve tout au même endroit à n''importe quelle heure, avec des produits parfois moins goûteux. La différence essentielle, c''est le choix entre la qualité et la souplesse des horaires.',
   'Avantage et inconvénient des deux côtés, puis une différence claire.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C6-S5 / EXCELLENT
  ('4867a021-db54-5464-98a5-70d8eabe31e6', 'b6d2a2ec-c3bd-5bc3-b31a-32425836fbc8', 'EXCELLENT',
   'Au marché, on achète des légumes récoltés la veille et l''on sait d''où ils viennent, mais tout se joue en trois heures le dimanche. Au supermarché, la course se fait à vingt heures un mardi, au prix d''une origine souvent inconnue. Dans les deux cas, on paie quelque chose : au marché son temps, au supermarché l''information sur ce que l''on mange.',
   'Les options sont jugées sur les mêmes critères, avec une formule qui les résume.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C7-S1 / INSUFFICIENT
  ('52c7a8a9-db2e-578c-9386-5be81515a932', '398434de-86b8-5e31-ab45-c6bd99cf8121', 'INSUFFICIENT',
   'Les réseaux sociaux permettent de garder le contact avec sa famille. Ils sont vraiment très utiles pour tout le monde aujourd''hui.',
   'Aucune limite n''apparaît : l''opinion reste sur un seul côté.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C7-S1 / EXPECTED
  ('6555fb88-d92f-5d8d-afbc-cfed88ecfe1f', '398434de-86b8-5e31-ab45-c6bd99cf8121', 'EXPECTED',
   'Les réseaux sociaux me permettent de parler chaque semaine avec ma famille restée loin. Ils prennent cependant beaucoup de temps, et je conseillerais de se fixer une limite quotidienne.',
   'La limite est nette et votre opinion positive reste visible.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C7-S1 / EXCELLENT
  ('85a5e24f-88ca-5e23-a599-85121b95be18', '398434de-86b8-5e31-ab45-c6bd99cf8121', 'EXCELLENT',
   'Les réseaux sociaux permettent à ma mère de voir grandir ses petits-enfants malgré cinq mille kilomètres. Je reconnais qu''ils occupent parfois des soirées entières, mais cet inconvénient pèse peu face à ce qu''ils rendent possible.',
   'La concession est assumée puis remise à sa place : la position tient.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C7-S2 / INSUFFICIENT
  ('c7e4d06e-843c-524a-99a4-b861766648c4', 'e22b8f78-4a44-5246-887d-a0b3052f0117', 'INSUFFICIENT',
   'On peut très bien vivre sans voiture dans une ville moyenne. Les transports et le vélo suffisent largement pour tous les déplacements.',
   'Aucun cas contraire n''est reconnu : la nuance demandée manque.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C7-S2 / EXPECTED
  ('42489bef-80dc-5239-acc2-13e205d314a2', 'e22b8f78-4a44-5246-887d-a0b3052f0117', 'EXPECTED',
   'Dans une ville moyenne, les bus et le vélo couvrent la plupart des trajets. Je reconnais qu''une voiture reste utile pour aller à la campagne le week-end, mais cela ne justifie pas d''en posséder une.',
   'Le cas contraire est admis et votre position est reprise juste après.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C7-S2 / EXCELLENT
  ('784e05fb-af25-50d4-b0b7-e0e93910949c', 'e22b8f78-4a44-5246-887d-a0b3052f0117', 'EXCELLENT',
   'Dans une ville moyenne, le vélo et les bus suffisent pour aller travailler, faire ses courses et sortir le soir. Certes, une voiture reste précieuse pour un déménagement ou une sortie à la campagne, mais une location de quelques heures répond alors au besoin.',
   'La concession est reconnue puis résolue : votre position sort renforcée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C7-S3 / INSUFFICIENT
  ('9ed74e7d-bf03-50a1-9ae5-c34398b6e65e', '26d61839-4fa9-5e2f-ab82-9617e9a692aa', 'INSUFFICIENT',
   'Courir tous les jours est une excellente idée. Plus on s''entraîne souvent, plus on progresse rapidement.',
   'La limite demandée n''apparaît pas : la position reste sans nuance.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C7-S3 / EXPECTED
  ('83f9f375-5a23-577a-881c-666f8d754321', '26d61839-4fa9-5e2f-ab82-9617e9a692aa', 'EXPECTED',
   'La régularité fait progresser bien plus que trois grosses séances par mois. Il faut toutefois garder un jour de repos, sinon les blessures arrivent vite.',
   'La réserve est concrète et votre position principale reste claire.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C7-S3 / EXCELLENT
  ('2632bd46-86f4-572b-a43f-0dc9689143d3', '26d61839-4fa9-5e2f-ab82-9617e9a692aa', 'EXCELLENT',
   'Courir un peu chaque jour installe une habitude que trois séances intenses ne remplacent pas. Cela dit, le corps progresse pendant le repos autant que pendant l''effort : je conseillerais donc six jours de course et un jour de marche.',
   'La limite devient un conseil précis, sans affaiblir votre position.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C7-S4 / INSUFFICIENT
  ('9a2a3525-6a2f-510d-981f-1466e0a9ddc9', 'd372b38f-4322-5403-b9db-67891e2a33d6', 'INSUFFICIENT',
   'Les horaires libres seraient une très bonne chose pour tout le monde. Chacun pourrait organiser sa journée exactement comme il le souhaite.',
   'L''avis est clair, mais le risque demandé n''est pas évoqué.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C7-S4 / EXPECTED
  ('d9558618-0095-5841-b966-c65aa9c9073b', 'd372b38f-4322-5403-b9db-67891e2a33d6', 'EXPECTED',
   'Les horaires libres permettraient à chacun de travailler au moment où il est le plus efficace. Le risque, c''est que l''équipe ne se croise plus, mais une plage commune l''après-midi suffirait à l''éviter.',
   'Le risque est nommé, puis votre position est maintenue.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C7-S4 / EXCELLENT
  ('c170ee0b-6e10-51b7-bd58-8d8059fccee7', 'd372b38f-4322-5403-b9db-67891e2a33d6', 'EXCELLENT',
   'Choisir ses horaires permettrait de traiter les dossiers difficiles au moment où l''on se concentre le mieux. J''admets qu''une équipe qui ne se croise plus finit par mal faire circuler l''information ; deux heures communes chaque jour régleraient pourtant ce point.',
   'L''objection est prise au sérieux puis traitée : c''est l''attente du niveau B2.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C7-S5 / INSUFFICIENT
  ('021c07c5-48d7-5e37-94c0-50551eef7127', 'b63c117a-c6c9-5929-a15a-7c0841cd4ae1', 'INSUFFICIENT',
   'La consigne des bocaux est une très bonne initiative pour réduire les déchets. J''espère que tous les magasins feront la même chose très rapidement.',
   'L''initiative est soutenue, mais aucune contrainte n''est reconnue.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C7-S5 / EXPECTED
  ('45851016-7d4f-59f9-a0ea-46cf90fbb73a', 'b63c117a-c6c9-5929-a15a-7c0841cd4ae1', 'EXPECTED',
   'Les bocaux consignés évitent des dizaines d''emballages jetables chaque mois. Il faut reconnaître que les rapporter demande de la place chez soi et un peu d''organisation. Cet effort me paraît malgré tout raisonnable au vu des déchets évités.',
   'Contrainte admise puis mise en balance : la position finale est nette.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C7-S5 / EXCELLENT
  ('fa085fbb-403c-50b7-b25f-c360d0ac6a98', 'b63c117a-c6c9-5929-a15a-7c0841cd4ae1', 'EXCELLENT',
   'Les bocaux consignés suppriment des dizaines d''emballages par famille et par mois. Je comprends que cela suppose un carton dans l''entrée et de penser à le rapporter, ce qui décourage les personnes qui font leurs courses en vitesse. Cette contrainte est réelle, mais elle disparaît après quelques semaines d''habitude : je reste favorable à la consigne.',
   'L''objection est décrite du point de vue de ceux qui la vivent, puis dépassée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C8-S1 / INSUFFICIENT
  ('522ffa5f-2ed8-52fd-948c-8a3123bd6d6c', '3257d30c-3505-550e-91de-2724c53dbc47', 'INSUFFICIENT',
   'Apprendre une langue tôt est bien. Les enfants apprennent vite à cet âge. Les langues sont utiles pour le travail.',
   'Trois idées posées côte à côte, sans lien entre elles ni conclusion.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C8-S1 / EXPECTED
  ('27ee3458-0ac7-5cf6-ba6e-2435944f2b86', '3257d30c-3505-550e-91de-2724c53dbc47', 'EXPECTED',
   'Apprendre une deuxième langue dès le primaire est une bonne décision, car les enfants retiennent les sons très facilement à cet âge. Par conséquent, ils arrivent au collège avec une prononciation déjà solide. C''est pourquoi je soutiens pleinement cette mesure.',
   'Les connecteurs relient les idées et la conclusion reprend la position.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C8-S1 / EXCELLENT
  ('166bf74b-9be8-5234-ac85-923111f5b419', '3257d30c-3505-550e-91de-2724c53dbc47', 'EXCELLENT',
   'Apprendre une deuxième langue dès le primaire est une bonne décision, car un enfant imite les sons sans crainte du ridicule. Il arrive donc au collège avec une prononciation que beaucoup d''adultes n''atteignent jamais. Pour cette raison, cet apprentissage précoce devrait être proposé dans toutes les écoles.',
   'Chaque phrase découle de la précédente et la conclusion élargit un peu.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C8-S2 / INSUFFICIENT
  ('75a549d6-bcee-50ec-bfb9-0d644d8f59eb', '35a773ef-d7da-5766-93fe-37fe1746f747', 'INSUFFICIENT',
   'Ce marché de producteurs est une bonne idée. Les légumes sont frais. Les producteurs viennent de la région.',
   'Les idées sont justes, mais rien ne les relie et rien ne conclut.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C8-S2 / EXPECTED
  ('7624fd0a-ed6d-5a18-bbcd-e9a07e885d56', '35a773ef-d7da-5766-93fe-37fe1746f747', 'EXPECTED',
   'Ce marché permet d''acheter des légumes récoltés à moins de trente kilomètres. Les habitants savent donc précisément d''où vient ce qu''ils mangent. Pour toutes ces raisons, je souhaite que ce marché devienne permanent.',
   'Un connecteur de conséquence et une vraie phrase de conclusion.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C8-S2 / EXCELLENT
  ('992a690d-8df7-5337-a16f-8f30d3ccf3c0', '35a773ef-d7da-5766-93fe-37fe1746f747', 'EXCELLENT',
   'Ce marché propose des légumes récoltés à moins de trente kilomètres et vendus par ceux qui les cultivent. Les habitants savent ainsi ce qu''ils mangent, et les producteurs gardent la totalité du prix de vente. En définitive, ce marché profite aux deux côtés de l''étal : il mérite d''être installé chaque semaine.',
   'La conclusion réunit les deux idées au lieu de répéter la première.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C8-S3 / INSUFFICIENT
  ('8e02dd95-f0c5-524b-95ff-f48df2cd88ca', 'd2691dd4-07f8-5814-a9d6-dc6e65ee54bc', 'INSUFFICIENT',
   'Je suis pour le jardin partagé. Le terrain est vide depuis longtemps. Les gens pourraient cultiver des légumes. Les enfants aiment la nature.',
   'Quatre idées alignées : l''ordre et la conclusion restent à construire.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C8-S3 / EXPECTED
  ('8d995ca2-6563-5a3e-9055-83b951e38cd3', 'd2691dd4-07f8-5814-a9d6-dc6e65ee54bc', 'EXPECTED',
   'Je suis favorable à ce jardin partagé. D''abord, il donnerait enfin un usage à un terrain laissé à l''abandon. Ensuite, il ferait se rencontrer des voisins qui ne se parlent jamais. Pour ces deux raisons, la mairie devrait accepter le projet.',
   'D''abord, ensuite, pour ces raisons : l''organisation est visible.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C8-S3 / EXCELLENT
  ('61169a93-a857-5920-ad3d-7bbb29be2a1a', 'd2691dd4-07f8-5814-a9d6-dc6e65ee54bc', 'EXCELLENT',
   'Je soutiens sans réserve le projet de jardin partagé. D''une part, il redonne un usage à un terrain fermé depuis des années. D''autre part, il crée un lieu où des voisins de tous âges travaillent côte à côte, ce qui manque dans le quartier. Au fond, ce jardin ne produirait pas seulement des légumes, mais aussi des relations.',
   'La conclusion apporte une idée neuve tout en fermant le raisonnement.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C8-S4 / INSUFFICIENT
  ('9aba6102-5e23-5908-9d05-b2c7ea3ef848', '7a1cc750-72f6-572b-aad5-9f0e0d84a3c3', 'INSUFFICIENT',
   'C''est une bonne idée. Les étudiants n''ont pas beaucoup d''argent. Les personnes âgées sont souvent seules. Les logements sont chers en ville.',
   'Les idées sont pertinentes, mais rien ne les relie ni ne conclut.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C8-S4 / EXPECTED
  ('448d3d0b-440e-5491-a473-d10087883f83', '7a1cc750-72f6-572b-aad5-9f0e0d84a3c3', 'EXPECTED',
   'Je trouve cette idée excellente. Premièrement, elle offre un logement abordable à des étudiants qui peinent à se loger. Deuxièmement, elle rompt la solitude de personnes qui vivent seules toute la semaine. En conclusion, cette formule répond à deux problèmes avec une seule solution.',
   'Les étapes sont marquées et la conclusion réunit les deux idées.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C8-S4 / EXCELLENT
  ('eb58c7b0-4d91-56fb-b1d2-5ffda47eff4e', '7a1cc750-72f6-572b-aad5-9f0e0d84a3c3', 'EXCELLENT',
   'Cette formule me paraît remarquablement bien pensée. D''un côté, elle loge des étudiants là où les loyers sont devenus inaccessibles. De l''autre, elle rend à des personnes seules une présence quotidienne, sans en faire une aide médicale. On comprend donc pourquoi ce type de colocation se développe : il répond à deux besoins avec le même logement.',
   'Les connecteurs équilibrent les deux parties et la conclusion les relie.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C8-S5 / INSUFFICIENT
  ('51fc27e6-9de7-58db-bee7-b9ed43aefd57', '6bf58c02-c307-5d58-93fd-b9e048a741bc', 'INSUFFICIENT',
   'Je pense que c''est une bonne idée. Une soirée sans écran fait du bien. On peut lire ou parler avec sa famille. Donc je pense que c''est une bonne idée.',
   'La dernière phrase répète la première : la conclusion reste à écrire.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C8-S5 / EXPECTED
  ('3089514b-c689-5ced-92bd-a285f6ee8a0d', '6bf58c02-c307-5d58-93fd-b9e048a741bc', 'EXPECTED',
   'Je trouve cette proposition intéressante. Tout d''abord, une soirée sans écran libère trois heures que l''on ne voit jamais passer autrement. De plus, ce moment permet de faire ce que l''on repousse sans arrêt, comme cuisiner ou appeler un proche. Finalement, une seule soirée par semaine me semble un effort raisonnable pour un vrai bénéfice.',
   'Trois connecteurs différents et une conclusion qui pèse l''effort et le gain.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE3-C8-S5 / EXCELLENT
  ('9ae30c9d-d8f7-5d96-be67-73506c13d973', '6bf58c02-c307-5d58-93fd-b9e048a741bc', 'EXCELLENT',
   'Cette proposition mérite d''être essayée. Tout d''abord, une soirée sans écran rend visibles trois heures qui disparaissent habituellement sans que l''on sache où. Ensuite, ce temps retrouvé se remplit tout seul : on cuisine, on lit, on appelle quelqu''un. Au bout du compte, l''intérêt de l''exercice n''est pas de supprimer les écrans, mais de mesurer la place qu''ils avaient prise.',
   'La conclusion déplace le sujet et referme le texte sans se répéter.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02');
