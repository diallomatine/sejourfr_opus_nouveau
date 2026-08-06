-- ============================================================================
-- V305 — Competences TCF : EO3 « Exprimer et developper un point de vue »
--
-- Seed du module « Competences » pour la tache EO3 (EO).
-- 8 competences, 40 petits sujets, 120 references.
--
-- Tables : skills, skill_prompts, skill_references (DDL en V025).
--
-- FICHIER GENERE — NE PAS EDITER A LA MAIN.
--
--   cd backend_sejourfr && python3 tools/competences/generer_seed.py
--
-- On edite la fiche de contenu tools/competences/contenu/EO3.json,
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
  -- EO3-C1 — Annoncer une position claire
  ('fd864b63-031c-53a1-9ff2-5e1ddfc32624', 'EO', 'EO3', 'EO3-C1', 'Annoncer une position claire',
   'Vous apprenez à dire tout de suite ce que vous pensez, sans tourner autour de la question. Au TCF, l''examinateur doit pouvoir identifier votre position dès vos premiers mots.',
   'Répondre immédiatement à la question et rendre son opinion identifiable.',
   'B2', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C2 — Donner un argument pertinent
  ('e4d1eab2-4e8c-54a0-9f46-c68247d05045', 'EO', 'EO3', 'EO3-C2', 'Donner un argument pertinent',
   'Vous vous entraînez à donner une raison qui soutient vraiment votre position. Au TCF, une opinion sans raison reste une affirmation : l''examinateur attend le « parce que ».',
   'Présenter une première raison directement liée à la position.',
   'B2', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C3 — Développer oralement un argument
  ('952b4a77-9e62-5b98-a311-7aeab4bc1d06', 'EO', 'EO3', 'EO3-C3', 'Développer oralement un argument',
   'Vous apprenez à ne pas laisser une raison toute seule : vous ajoutez la cause, la conséquence ou la précision qui la rendent solide. C''est ce développement qui fait la différence au niveau B2.',
   'Expliquer la raison avec une cause, une conséquence ou une précision.',
   'B2', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C4 — Donner un exemple concret
  ('ac99e275-7cdb-54cc-9422-6c8a53fa326a', 'EO', 'EO3', 'EO3-C4', 'Donner un exemple concret',
   'Vous vous entraînez à illustrer une idée par une situation précise, avec un lieu, un moment ou une personne. Au TCF, un exemple bien choisi prouve que vous maîtrisez ce que vous avancez.',
   'Illustrer l''argument par une situation personnelle ou vraisemblable.',
   'B2', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C5 — Ajouter un deuxième argument distinct
  ('c1020458-df53-59b8-b0f4-3b8423b9f13b', 'EO', 'EO3', 'EO3-C5', 'Ajouter un deuxième argument distinct',
   'Vous apprenez à enchaîner sur une deuxième raison réellement différente de la première. Au TCF, redire autrement le même argument ne fait pas avancer votre discours.',
   'Continuer le discours avec une nouvelle raison sans répéter la première.',
   'B2', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C6 — Comparer ou présenter avantages et inconvénients
  ('d05831f8-0c84-52eb-8276-059e3f38d0dc', 'EO', 'EO3', 'EO3-C6', 'Comparer ou présenter avantages et inconvénients',
   'Vous vous entraînez à mettre deux possibilités en relation sur un même point, au lieu de les décrire l''une après l''autre. Le TCF valorise la comparaison explicite : « alors que », « en revanche », « c''est l''inverse ».',
   'Mettre en relation deux situations et expliquer leurs principales différences.',
   'B2', 6, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C7 — Nuancer ou reconnaître une limite
  ('34e1c9d0-c7ab-5353-90e2-b461717289da', 'EO', 'EO3', 'EO3-C7', 'Nuancer ou reconnaître une limite',
   'Vous apprenez à reconnaître une limite sans renoncer à votre avis. Au TCF, une nuance bien posée montre que vous maîtrisez le sujet ; mal posée, elle efface votre position.',
   'Introduire une réserve, une concession ou une exception sans perdre sa position.',
   'B2', 7, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C8 — Organiser un discours continu et conclure
  ('b06d1bb7-03a1-54f0-92fe-1c4ee8b7dfd6', 'EO', 'EO3', 'EO3-C8', 'Organiser un discours continu et conclure',
   'Vous vous entraînez à tenir une réponse complète du début à la fin : votre avis, une raison, un exemple, puis une conclusion. C''est exactement le format attendu à la tâche 3 du TCF.',
   'Utiliser des connecteurs naturels, éviter l''accumulation d''idées et terminer clairement.',
   'B2', 8, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02');

INSERT INTO skill_prompts (id, skill_id, section, code, title, context, instruction,
                           unique_criterion, recommended_min_words, recommended_max_words,
                           recommended_duration_seconds, difficulty_level, display_order,
                           is_active, created_at, updated_at)
VALUES
  -- EO3-C1-S1 — EASY — Ville ou campagne
  ('9d9f414a-7449-54fb-9ba5-33287dca1aca', 'fd864b63-031c-53a1-9ff2-5e1ddfc32624', 'EO', 'EO3-C1-S1', 'Ville ou campagne',
   'Pendant l''entretien, l''examinateur vous demande où vous préféreriez vivre. Beaucoup de candidats décrivent les deux possibilités sans jamais choisir.',
   'Dites si vous préférez vivre en ville ou à la campagne. Annoncez votre choix dès le début de votre réponse.',
   'Votre position est annoncée dès la première phrase et on sait laquelle vous choisissez.',
   NULL, NULL, 30, 'EASY', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C1-S2 — EASY — Cuisiner ou acheter tout prêt
  ('060a596f-7da1-54ed-99df-db79f09477fe', 'fd864b63-031c-53a1-9ff2-5e1ddfc32624', 'EO', 'EO3-C1-S2', 'Cuisiner ou acheter tout prêt',
   'Une discussion s''engage sur la façon de se nourrir quand les journées sont chargées. Certains cuisinent chaque soir, d''autres achètent des plats déjà préparés.',
   'Dites ce que vous préférez : cuisiner vous-même ou acheter des plats préparés. Votre préférence doit s''entendre tout de suite.',
   'On identifie votre préférence dès les premiers mots, sans avoir à la deviner.',
   NULL, NULL, 28, 'EASY', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C1-S3 — MEDIUM — Voiture ou vélo en ville
  ('a2ec367a-5af2-5b59-9646-96185c6627a8', 'fd864b63-031c-53a1-9ff2-5e1ddfc32624', 'EO', 'EO3-C1-S3', 'Voiture ou vélo en ville',
   'Votre ville développe des pistes cyclables et réduit les places de stationnement. Le sujet fait beaucoup parler dans le quartier.',
   'Dites si, pour vos trajets quotidiens en ville, vous choisiriez plutôt la voiture ou le vélo. Annoncez votre position avant tout le reste.',
   'Votre position est identifiable dès le début, même si vous reconnaissez ensuite un point à l''autre option.',
   NULL, NULL, 30, 'MEDIUM', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C1-S4 — MEDIUM — Téléphone au collège
  ('588aee77-d478-51f3-8582-17e88b133656', 'fd864b63-031c-53a1-9ff2-5e1ddfc32624', 'EO', 'EO3-C1-S4', 'Téléphone au collège',
   'Un collège de votre quartier envisage d''interdire complètement les téléphones portables pendant toute la journée. Les parents en discutent beaucoup.',
   'Dites si vous êtes pour ou contre cette interdiction. On doit comprendre votre position sans attendre la fin de votre réponse.',
   'Vous vous positionnez clairement pour ou contre, dès l''ouverture de votre réponse.',
   NULL, NULL, 30, 'MEDIUM', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C1-S5 — HARD — Semaine de quatre jours
  ('51caefe9-9a54-501f-936b-42a1e492c9f5', 'fd864b63-031c-53a1-9ff2-5e1ddfc32624', 'EO', 'EO3-C1-S5', 'Semaine de quatre jours',
   'Plusieurs entreprises testent la semaine de quatre jours, à salaire égal mais avec des journées plus longues. Le sujet divise les salariés.',
   'Dites si vous seriez favorable à ce rythme dans votre travail. Votre position doit rester la même du début à la fin.',
   'Une seule position est annoncée d''emblée et elle ne change pas au cours de la réponse.',
   NULL, NULL, 30, 'HARD', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C2-S1 — EASY — Une raison pour le télétravail
  ('cf9f4496-e07f-5ba2-88d3-c582c17281a0', 'e4d1eab2-4e8c-54a0-9f46-c68247d05045', 'EO', 'EO3-C2-S1', 'Une raison pour le télétravail',
   'Votre entreprise propose deux jours de télétravail par semaine. Un collègue vous demande pourquoi vous trouvez cela intéressant.',
   'Donnez une raison en faveur du télétravail. Une seule raison suffit, mais elle doit soutenir clairement cette position.',
   'Vous donnez une raison identifiable qui explique pourquoi le télétravail est un avantage.',
   NULL, NULL, 35, 'EASY', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C2-S2 — EASY — Une raison de bouger
  ('fa584456-137c-5bf0-a497-77facd68128d', 'e4d1eab2-4e8c-54a0-9f46-c68247d05045', 'EO', 'EO3-C2-S2', 'Une raison de bouger',
   'Un ami vous dit qu''il n''a jamais le temps de faire du sport. Vous voulez lui donner une bonne raison de s''y mettre.',
   'Donnez une raison pour laquelle une activité physique régulière est utile. Une seule raison, mais qui tienne debout.',
   'Une raison claire est donnée et elle explique réellement l''intérêt de l''activité physique.',
   NULL, NULL, 35, 'EASY', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C2-S3 — MEDIUM — Partir hors saison
  ('1dfeec6e-5009-5981-a525-191fe5695fcf', 'e4d1eab2-4e8c-54a0-9f46-c68247d05045', 'EO', 'EO3-C2-S3', 'Partir hors saison',
   'Une collègue hésite entre partir en vacances en août ou attendre septembre. Vous lui conseillez de partir hors saison.',
   'Donnez une raison qui justifie ce conseil. Elle doit porter précisément sur le fait de partir hors saison.',
   'La raison donnée porte bien sur la période choisie, pas sur le voyage en général.',
   NULL, NULL, 38, 'MEDIUM', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C2-S4 — MEDIUM — Les langues dès le primaire
  ('5a980d50-604f-5d3b-9861-4d4e0d0edfcd', 'e4d1eab2-4e8c-54a0-9f46-c68247d05045', 'EO', 'EO3-C2-S4', 'Les langues dès le primaire',
   'Dans une réunion de parents, quelqu''un propose de commencer les langues étrangères dès l''école primaire. On vous demande votre avis.',
   'Défendez cette proposition avec une raison. Cette raison doit expliquer pourquoi commencer tôt change quelque chose.',
   'La raison explique précisément l''intérêt de commencer tôt, et pas seulement d''apprendre une langue.',
   NULL, NULL, 40, 'MEDIUM', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C2-S5 — HARD — Défendre l'achat d'occasion
  ('a4b7a784-8f64-5ed5-92c1-c3f6b2202844', 'e4d1eab2-4e8c-54a0-9f46-c68247d05045', 'EO', 'EO3-C2-S5', 'Défendre l''achat d''occasion',
   'Un voisin trouve étrange d''acheter des vêtements ou des meubles de seconde main. Vous, vous le faites régulièrement.',
   'Donnez une raison qui défend l''achat d''occasion. Choisissez une seule raison et rendez-la convaincante.',
   'Une seule raison est présentée, clairement rattachée à l''achat d''occasion.',
   NULL, NULL, 40, 'HARD', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C3-S1 — EASY — Les transports publics au quotidien
  ('22507410-e2b6-548e-b1a6-e26036a47e01', '952b4a77-9e62-5b98-a311-7aeab4bc1d06', 'EO', 'EO3-C3-S1', 'Les transports publics au quotidien',
   'Une amie affirme que les transports publics facilitent la vie de tous les jours. L''idée est juste, mais elle reste très générale.',
   'Développez cette idée : expliquez comment les transports publics facilitent concrètement le quotidien. L''argument vous est donné, c''est l''explication qui compte.',
   'Vous expliquez l''argument par une cause ou une conséquence concrète, sans vous contenter de le répéter.',
   NULL, NULL, 40, 'EASY', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C3-S2 — EASY — Dormir assez pour travailler
  ('247e0ebd-b9a4-5055-99c2-a7529ba77105', '952b4a77-9e62-5b98-a311-7aeab4bc1d06', 'EO', 'EO3-C3-S2', 'Dormir assez pour travailler',
   'Dans une discussion sur la fatigue au travail, quelqu''un dit qu''il faudrait d''abord dormir assez. L''idée est admise, mais pas expliquée.',
   'Développez cette idée : expliquez pourquoi un sommeil suffisant change quelque chose dans une journée de travail.',
   'L''idée est expliquée par un enchaînement cause-conséquence, pas simplement affirmée.',
   NULL, NULL, 40, 'EASY', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C3-S3 — MEDIUM — Ce que le bénévolat rapporte
  ('ae39168b-160c-54e1-8131-fd656faf9dd0', '952b4a77-9e62-5b98-a311-7aeab4bc1d06', 'EO', 'EO3-C3-S3', 'Ce que le bénévolat rapporte',
   'Une association de quartier cherche des bénévoles. On dit souvent que le bénévolat apporte autant à celui qui donne qu''à celui qui reçoit.',
   'Développez cette idée en expliquant pourquoi le bénévolat apporte quelque chose au bénévole lui-même.',
   'Vous expliquez le bénéfice pour le bénévole par une cause ou une conséquence identifiable.',
   NULL, NULL, 42, 'MEDIUM', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C3-S4 — MEDIUM — Trier ses déchets
  ('b1cae959-63bf-5c29-9ed7-884d7d0db156', '952b4a77-9e62-5b98-a311-7aeab4bc1d06', 'EO', 'EO3-C3-S4', 'Trier ses déchets',
   'Votre immeuble installe de nouveaux bacs de tri. Un habitant dit que trier ne sert à rien à son échelle.',
   'Développez l''idée que le tri des déchets a un effet réel. Expliquez le mécanisme, ne vous contentez pas de l''affirmer.',
   'Un enchaînement explicatif rend visible l''effet du tri, au lieu de le poser comme évident.',
   NULL, NULL, 45, 'MEDIUM', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C3-S5 — HARD — Se former en ligne
  ('c94cbd90-cd54-52b4-9264-65726dac260d', '952b4a77-9e62-5b98-a311-7aeab4bc1d06', 'EO', 'EO3-C3-S5', 'Se former en ligne',
   'Un centre de formation propose des cours du soir entièrement en ligne. Un stagiaire dit que cela permet de reprendre des études quand on travaille.',
   'Développez cette idée en expliquant précisément ce que la formation en ligne rend possible.',
   'L''argument est développé par une explication qui va au-delà du mot « pratique ».',
   NULL, NULL, 45, 'HARD', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C4-S1 — EASY — Un exemple pour le sport
  ('fc1af6dc-65c8-54f5-8c23-20d041c4e66f', 'ac99e275-7cdb-54cc-9422-6c8a53fa326a', 'EO', 'EO3-C4-S1', 'Un exemple pour le sport',
   'Vous soutenez que le sport aide à tenir le rythme d''une semaine chargée. Votre interlocuteur vous demande de rendre cela concret.',
   'Donnez un exemple, vécu ou vraisemblable, qui illustre cette idée. Une seule situation, mais précise.',
   'Vous racontez une situation précise qui illustre l''idée, avec au moins un détail concret.',
   NULL, NULL, 35, 'EASY', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C4-S2 — EASY — Un samedi au marché
  ('d3da62f6-54e4-54ff-9198-e9cf0a8816e0', 'ac99e275-7cdb-54cc-9422-6c8a53fa326a', 'EO', 'EO3-C4-S2', 'Un samedi au marché',
   'Vous défendez l''idée qu''acheter au marché change la façon de manger. On vous demande d''illustrer votre propos.',
   'Donnez un exemple concret, tiré de votre expérience ou d''une situation crédible.',
   'L''exemple décrit une situation identifiable, avec un lieu, un moment ou une personne.',
   NULL, NULL, 38, 'EASY', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C4-S3 — MEDIUM — La colocation au-delà du loyer
  ('ea7e2a6b-c24a-53f2-9567-d32663f6993e', 'ac99e275-7cdb-54cc-9422-6c8a53fa326a', 'EO', 'EO3-C4-S3', 'La colocation au-delà du loyer',
   'Vous affirmez que la colocation ne se résume pas à un loyer partagé. On vous demande de le montrer par un cas précis.',
   'Donnez un exemple concret qui illustre ce que la colocation apporte au-delà de l''aspect financier.',
   'L''exemple est situé et il illustre bien l''aspect non financier annoncé.',
   NULL, NULL, 40, 'MEDIUM', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C4-S4 — MEDIUM — Trois semaines de formation
  ('7ecc8ab7-d5bf-55be-ac46-c5dfe68caba6', 'ac99e275-7cdb-54cc-9422-6c8a53fa326a', 'EO', 'EO3-C4-S4', 'Trois semaines de formation',
   'Vous soutenez qu''une formation courte peut débloquer une situation professionnelle. Votre interlocuteur reste sceptique.',
   'Illustrez votre idée par un exemple concret, vécu ou plausible.',
   'Une situation professionnelle précise est racontée et elle appuie l''idée défendue.',
   NULL, NULL, 42, 'MEDIUM', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C4-S5 — HARD — La bibliothèque du quartier
  ('ac23e5e6-19fc-58b0-8205-23ce938bb3fe', 'ac99e275-7cdb-54cc-9422-6c8a53fa326a', 'EO', 'EO3-C4-S5', 'La bibliothèque du quartier',
   'Vous défendez l''idée qu''une bibliothèque de quartier sert à bien plus qu''emprunter des livres.',
   'Donnez un exemple concret qui montre un autre usage de la bibliothèque. Un seul exemple, mais développé.',
   'L''exemple montre un usage précis et différent de l''emprunt de livres.',
   NULL, NULL, 45, 'HARD', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C5-S1 — EASY — Deuxième raison, le travail d'équipe
  ('41b73b60-27c8-5112-8b5f-7f4567518cc7', 'c1020458-df53-59b8-b0f4-3b8423b9f13b', 'EO', 'EO3-C5-S1', 'Deuxième raison, le travail d''équipe',
   'Vous avez déjà dit que travailler en équipe permet de terminer un projet plus vite. Votre interlocuteur attend la suite.',
   'Ajoutez un deuxième argument en faveur du travail en équipe. Il doit porter sur autre chose que la rapidité.',
   'Le deuxième argument est nettement différent du premier, il ne le reformule pas.',
   NULL, NULL, 40, 'EASY', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C5-S2 — EASY — Deuxième raison pour le vélo
  ('53694445-a8ab-5406-a180-d1aedb1ad44c', 'c1020458-df53-59b8-b0f4-3b8423b9f13b', 'EO', 'EO3-C5-S2', 'Deuxième raison pour le vélo',
   'Vous avez expliqué que le vélo coûte très peu cher à l''usage. Il vous reste à convaincre autrement.',
   'Ajoutez un deuxième argument en faveur du vélo en ville, sur un autre terrain que l''argent.',
   'Un deuxième argument est ajouté et il ne parle plus du coût.',
   NULL, NULL, 40, 'EASY', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C5-S3 — MEDIUM — Autre intérêt des sorties scolaires
  ('21afd132-0c73-5c78-90e7-ff9048bd4ba3', 'c1020458-df53-59b8-b0f4-3b8423b9f13b', 'EO', 'EO3-C5-S3', 'Autre intérêt des sorties scolaires',
   'Vous avez soutenu que les sorties scolaires motivent les élèves. Un parent vous demande si c''est le seul intérêt.',
   'Ajoutez un deuxième argument en faveur des sorties scolaires, différent de la motivation.',
   'Le deuxième argument ouvre un autre aspect que celui déjà évoqué.',
   NULL, NULL, 42, 'MEDIUM', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C5-S4 — MEDIUM — Au-delà du dépistage
  ('0a7eb51d-5e64-5655-a81a-58214315b82e', 'c1020458-df53-59b8-b0f4-3b8423b9f13b', 'EO', 'EO3-C5-S4', 'Au-delà du dépistage',
   'Vous avez dit qu''un rendez-vous médical de prévention permet de repérer un problème tôt. On vous demande une autre raison d''y aller.',
   'Ajoutez un deuxième argument en faveur de ces rendez-vous, sur un autre aspect que le dépistage précoce.',
   'Le deuxième argument porte sur un aspect nouveau, sans revenir au dépistage.',
   NULL, NULL, 42, 'MEDIUM', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C5-S5 — HARD — Au-delà du lien familial
  ('d475cf65-93dc-53f3-9824-4862252f3866', 'c1020458-df53-59b8-b0f4-3b8423b9f13b', 'EO', 'EO3-C5-S5', 'Au-delà du lien familial',
   'Vous avez dit que les messageries permettent de garder le lien avec une famille éloignée. Il vous reste à ouvrir un autre angle.',
   'Ajoutez un deuxième argument en faveur de ces outils, clairement distinct du lien familial.',
   'Le deuxième argument aborde un domaine différent du maintien du lien familial.',
   NULL, NULL, 45, 'HARD', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C6-S1 — EASY — Acheter en ligne ou en magasin
  ('cc17ca88-a1b3-579c-a9d8-9cbec6808882', 'd05831f8-0c84-52eb-8276-059e3f38d0dc', 'EO', 'EO3-C6-S1', 'Acheter en ligne ou en magasin',
   'Une amie hésite à faire ses achats sur internet plutôt qu''en magasin. Elle vous demande ce qui change vraiment.',
   'Comparez les achats en ligne et les achats en magasin. Mettez-les en relation sur un ou deux points précis.',
   'Les deux options sont mises en relation sur un même point, avec un mot de comparaison.',
   NULL, NULL, 45, 'EASY', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C6-S2 — EASY — Salle de sport ou plein air
  ('165e787e-b50f-54bc-820a-54d7975d863b', 'd05831f8-0c84-52eb-8276-059e3f38d0dc', 'EO', 'EO3-C6-S2', 'Salle de sport ou plein air',
   'Un collègue veut se remettre au sport et hésite entre s''inscrire en salle ou courir dehors.',
   'Comparez ces deux possibilités en les mettant en relation sur des points précis.',
   'La comparaison porte sur des points communs aux deux options, pas sur deux listes séparées.',
   NULL, NULL, 45, 'EASY', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C6-S3 — MEDIUM — Centre-ville ou périphérie
  ('1011b278-d4cf-520d-8645-8b45cc8e4162', 'd05831f8-0c84-52eb-8276-059e3f38d0dc', 'EO', 'EO3-C6-S3', 'Centre-ville ou périphérie',
   'Une famille hésite entre un petit appartement en centre-ville et une maison plus grande à vingt kilomètres.',
   'Comparez les deux choix en montrant leurs principales différences.',
   'Les deux logements sont comparés sur les mêmes critères, avec des marqueurs de comparaison.',
   NULL, NULL, 48, 'MEDIUM', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C6-S4 — MEDIUM — Voyage organisé ou voyage libre
  ('20730fba-8c86-5ff0-929b-c5597c2d8994', 'd05831f8-0c84-52eb-8276-059e3f38d0dc', 'EO', 'EO3-C6-S4', 'Voyage organisé ou voyage libre',
   'Deux amis préparent un voyage : l''un veut réserver un séjour organisé, l''autre veut tout gérer lui-même.',
   'Comparez ces deux façons de voyager sur des points précis.',
   'La comparaison relie explicitement les deux formules sur des critères identiques.',
   NULL, NULL, 48, 'MEDIUM', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C6-S5 — HARD — Cours du soir ou en ligne
  ('cf1b5766-86ab-5ccf-9129-8a2ba7bd3bee', 'd05831f8-0c84-52eb-8276-059e3f38d0dc', 'EO', 'EO3-C6-S5', 'Cours du soir ou en ligne',
   'Un centre de formation propose la même formation en salle le soir ou entièrement en ligne. On vous demande de conseiller un futur stagiaire.',
   'Comparez les deux formules en pesant leurs avantages et leurs inconvénients.',
   'Avantages et inconvénients sont mis en balance sur des critères communs aux deux formules.',
   NULL, NULL, 50, 'HARD', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C7-S1 — EASY — Réseaux sociaux, avantage et limite
  ('1cb06299-fece-5629-8da8-0f18e4be25e6', '34e1c9d0-c7ab-5353-90e2-b461717289da', 'EO', 'EO3-C7-S1', 'Réseaux sociaux, avantage et limite',
   'Vous défendez l''idée que les réseaux sociaux rendent de vrais services. Votre interlocuteur attend que vous reconnaissiez aussi une limite.',
   'Donnez un avantage des réseaux sociaux, puis ajoutez une limite. Votre position de départ doit rester reconnaissable.',
   'Une limite est clairement introduite et la position initiale tient toujours à la fin.',
   NULL, NULL, 40, 'EASY', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C7-S2 — EASY — Des horaires vraiment flexibles
  ('c20c538f-23a5-5f78-9199-fdfd5e1914ce', '34e1c9d0-c7ab-5353-90e2-b461717289da', 'EO', 'EO3-C7-S2', 'Des horaires vraiment flexibles',
   'Votre entreprise laisse chacun choisir son heure d''arrivée. Vous trouvez cela positif, mais vous voyez aussi une difficulté.',
   'Présentez un avantage des horaires flexibles, puis reconnaissez une limite, sans changer d''avis.',
   'Vous introduisez une limite explicite tout en maintenant votre avis favorable.',
   NULL, NULL, 40, 'EASY', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C7-S3 — MEDIUM — Se faire livrer un repas
  ('c5426afe-4cda-54ff-a42d-e996370f5258', '34e1c9d0-c7ab-5353-90e2-b461717289da', 'EO', 'EO3-C7-S3', 'Se faire livrer un repas',
   'Vous trouvez que la livraison de repas à domicile dépanne réellement. On vous demande de rester honnête sur ses limites.',
   'Défendez cet avantage puis introduisez une réserve, sans abandonner votre position.',
   'Une réserve est formulée et la position initiale reste identifiable en fin de réponse.',
   NULL, NULL, 42, 'MEDIUM', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C7-S4 — MEDIUM — Trottinettes en libre-service
  ('87453541-2796-5201-87c7-e248d7b01863', '34e1c9d0-c7ab-5353-90e2-b461717289da', 'EO', 'EO3-C7-S4', 'Trottinettes en libre-service',
   'Votre ville a installé des trottinettes en libre-service. Vous y voyez un intérêt réel malgré les critiques.',
   'Présentez un avantage de ce service, puis reconnaissez une limite sérieuse, tout en gardant votre position.',
   'Une limite sérieuse est reconnue sans que votre position de départ soit abandonnée.',
   NULL, NULL, 45, 'MEDIUM', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C7-S5 — HARD — La voiture électrique en question
  ('cc2d7f13-633c-5198-8e06-959ffab482ac', '34e1c9d0-c7ab-5353-90e2-b461717289da', 'EO', 'EO3-C7-S5', 'La voiture électrique en question',
   'Vous défendez l''intérêt de la voiture électrique. Votre interlocuteur vous rappelle qu''elle n''est pas parfaite.',
   'Défendez un avantage réel de la voiture électrique, puis concédez une limite, sans renoncer à votre avis.',
   'La concession est explicite et votre avis initial reste tenu jusqu''à la fin.',
   NULL, NULL, 45, 'HARD', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C8-S1 — EASY — Sport seul ou en club
  ('f73aceb2-5cbf-529a-b7e1-c3a9fd7c2796', 'b06d1bb7-03a1-54f0-92fe-1c4ee8b7dfd6', 'EO', 'EO3-C8-S1', 'Sport seul ou en club',
   'On vous demande s''il vaut mieux pratiquer un sport seul ou dans un club. La réponse doit tenir en une seule prise de parole.',
   'Répondez en quatre temps : votre avis, une raison, un exemple, puis une conclusion. Gardez cet ordre.',
   'Les quatre étapes sont présentes, dans l''ordre, et reliées par des connecteurs.',
   NULL, NULL, 50, 'EASY', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C8-S2 — EASY — Réparer plutôt que racheter
  ('1418562f-6e0b-569e-9eee-52029c28ca02', 'b06d1bb7-03a1-54f0-92fe-1c4ee8b7dfd6', 'EO', 'EO3-C8-S2', 'Réparer plutôt que racheter',
   'Un atelier de réparation ouvre dans votre quartier. On vous demande s''il vaut la peine de faire réparer un appareil plutôt que d''en racheter un.',
   'Répondez en enchaînant votre avis, une raison, un exemple et une conclusion.',
   'La réponse enchaîne les quatre étapes attendues et se termine par une vraie conclusion.',
   NULL, NULL, 52, 'EASY', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C8-S3 — MEDIUM — Vivre ici suffit-il
  ('3b20205c-2a5a-5341-a477-335716573ad8', 'b06d1bb7-03a1-54f0-92fe-1c4ee8b7dfd6', 'EO', 'EO3-C8-S3', 'Vivre ici suffit-il',
   'On vous demande si vivre en France suffit pour progresser en français, ou s''il faut aussi suivre des cours.',
   'Répondez en une prise de parole continue : avis, raison, exemple, conclusion.',
   'Le discours suit les quatre étapes dans l''ordre, sans revenir en arrière.',
   NULL, NULL, 55, 'MEDIUM', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C8-S4 — MEDIUM — Le repas du midi
  ('694acd25-5238-56f1-9129-1ccb476a278d', 'b06d1bb7-03a1-54f0-92fe-1c4ee8b7dfd6', 'EO', 'EO3-C8-S4', 'Le repas du midi',
   'Dans votre entreprise, certains apportent leur repas, d''autres achètent quelque chose à côté. On vous demande ce que vous conseillez.',
   'Donnez votre avis, une raison, un exemple et une conclusion, dans une réponse continue.',
   'Les quatre étapes s''enchaînent avec des connecteurs et la réponse se referme clairement.',
   NULL, NULL, 55, 'MEDIUM', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C8-S5 — HARD — Une ville et ses visiteurs
  ('6926dbb1-6d8b-5333-8c3b-9f195c64f380', 'b06d1bb7-03a1-54f0-92fe-1c4ee8b7dfd6', 'EO', 'EO3-C8-S5', 'Une ville et ses visiteurs',
   'Une ville que vous connaissez reçoit beaucoup de visiteurs chaque année. On vous demande si ce tourisme est une bonne chose pour ses habitants.',
   'Répondez de manière continue et organisée : avis, raison, exemple, conclusion. Terminez par une phrase qui referme le propos.',
   'La réponse est organisée en quatre étapes reliées et se termine par une conclusion nette.',
   NULL, NULL, 58, 'HARD', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02');

INSERT INTO skill_references (id, skill_prompt_id, level, text, pedagogical_note,
                              created_at, updated_at)
VALUES
  -- EO3-C1-S1 / INSUFFICIENT
  ('317ed83b-5ac8-51ec-81ea-c561458316e5', '9d9f414a-7449-54fb-9ba5-33287dca1aca', 'INSUFFICIENT',
   'Alors, la ville, il y a beaucoup de choses, les magasins, les transports, c''est pratique. Et la campagne aussi c''est bien, c''est calme, il y a la nature. Les deux ont des avantages, ça dépend vraiment des gens.',
   'Les deux options sont décrites, mais votre choix personnel n''apparaît jamais.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C1-S1 / EXPECTED
  ('248d92fe-a040-57f6-b696-ababb7d73f58', '9d9f414a-7449-54fb-9ba5-33287dca1aca', 'EXPECTED',
   'Moi, je préfère vivre en ville. C''est mon choix parce que tout est proche : le travail, les magasins, les transports. La campagne est agréable, mais je ne m''y vois pas au quotidien.',
   'La position est donnée d''entrée et elle reste la même jusqu''au bout.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C1-S1 / EXCELLENT
  ('46093730-95eb-5b37-a24d-6e6bb9cfaccd', '9d9f414a-7449-54fb-9ba5-33287dca1aca', 'EXCELLENT',
   'Sans hésiter, je préfère la ville. Je sais qu''on vante beaucoup le calme de la campagne, mais pour moi, vivre en ville, c''est avoir tout à portée de main, et c''est ça qui compte dans ma vie de tous les jours.',
   'Le choix est net et l''autre option est écartée sans détour.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C1-S2 / INSUFFICIENT
  ('fd7e9a59-fb1d-59ff-b45c-3a037be7c99e', '060a596f-7da1-54ed-99df-db79f09477fe', 'INSUFFICIENT',
   'C''est une question intéressante. Cuisiner, ça prend du temps, il faut faire les courses, préparer, laver. Les plats préparés, c''est rapide, mais on ne sait pas toujours ce qu''il y a dedans. Voilà, chacun fait comme il peut.',
   'Vous pesez le pour et le contre sans jamais dire ce que vous préférez.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C1-S2 / EXPECTED
  ('a2b1a15d-9e70-5c0d-9db1-97f6cc3104d4', '060a596f-7da1-54ed-99df-db79f09477fe', 'EXPECTED',
   'Je préfère cuisiner moi-même. Ça me prend du temps, c''est vrai, mais je sais ce que je mange et ça me revient moins cher à la fin du mois.',
   'La préférence est posée en premier, le reste vient l''appuyer.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C1-S2 / EXCELLENT
  ('98310cb9-5154-5698-aaef-40f92b7b3e4b', '060a596f-7da1-54ed-99df-db79f09477fe', 'EXCELLENT',
   'Moi, c''est clair : je cuisine moi-même, toujours. Les plats préparés me dépannent une fois de temps en temps, mais ma préférence ne bouge pas, parce que cuisiner, c''est le seul moment calme de ma journée.',
   'La position est ferme et l''exception ne l''affaiblit pas.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C1-S3 / INSUFFICIENT
  ('c5aeb9ed-fefa-5101-ada6-523c941b482a', 'a2ec367a-5af2-5b59-9646-96185c6627a8', 'INSUFFICIENT',
   'En fait, ça dépend de la distance, de la météo, de ce qu''on transporte. Il y a des jours où la voiture est plus pratique, d''autres où le vélo passe mieux. Franchement, les deux se défendent selon les situations.',
   'Tout reste conditionnel : l''examinateur ne peut retenir aucune position.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C1-S3 / EXPECTED
  ('c2867b4a-27a2-570d-af90-cbe106cad1c2', 'a2ec367a-5af2-5b59-9646-96185c6627a8', 'EXPECTED',
   'Pour mes trajets de tous les jours, je choisis le vélo. En ville, les distances sont courtes et je perds moins de temps qu''en voiture, surtout aux heures de pointe.',
   'Le choix est annoncé puis tenu jusqu''à la fin.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C1-S3 / EXCELLENT
  ('4d6f87f7-18f8-5ae3-a589-ec2a47bcca19', 'a2ec367a-5af2-5b59-9646-96185c6627a8', 'EXCELLENT',
   'Mon choix est fait : le vélo, pour tous mes trajets en ville. La voiture reste utile le week-end pour les grosses courses, ça je ne le nie pas, mais au quotidien, rien ne me fera changer d''avis.',
   'La concession est encadrée : elle ne remplace jamais la position annoncée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C1-S4 / INSUFFICIENT
  ('917fb3ec-f7f6-54b0-b9c6-fde6597f61d6', '588aee77-d478-51f3-8582-17e88b133656', 'INSUFFICIENT',
   'Le téléphone, aujourd''hui, tout le monde en a. Les jeunes l''utilisent pour parler avec leurs amis, pour chercher des informations. Bien sûr, en classe, ça peut déranger. Les établissements doivent réfléchir à la meilleure solution.',
   'Vous décrivez la situation ; l''avis attendu n''est jamais formulé.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C1-S4 / EXPECTED
  ('4cc12a27-94f9-5778-bb76-65356a32f14c', '588aee77-d478-51f3-8582-17e88b133656', 'EXPECTED',
   'Je suis pour cette interdiction. Pendant les cours et les récréations, les élèves ont besoin de se concentrer et de se parler entre eux, pas de regarder un écran.',
   'Le « je suis pour » ouvre la réponse : la position est nette.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C1-S4 / EXCELLENT
  ('3dced9f6-8e01-59b7-9fbe-6605988cd201', '588aee77-d478-51f3-8582-17e88b133656', 'EXCELLENT',
   'Personnellement, je suis franchement pour. Je comprends les parents qui veulent joindre leur enfant, c''est légitime, mais ça ne change rien à ma position : sur le temps scolaire, le téléphone reste dans le sac.',
   'L''objection est entendue, puis la position est reformulée sans reculer.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C1-S5 / INSUFFICIENT
  ('b410e628-838c-5594-b7c5-f7e0caebd78e', '51caefe9-9a54-501f-936b-42a1e492c9f5', 'INSUFFICIENT',
   'Au départ, je dirais oui, un jour de repos en plus, c''est appréciable. Mais si les journées durent dix heures, ce n''est plus vraiment un cadeau. Donc finalement, je ne sais pas trop, il faudrait tester pour voir.',
   'La réponse bascule en cours de route et se termine sans position.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C1-S5 / EXPECTED
  ('46f8a182-f8a7-5bb5-a627-d02cd08b54d5', '51caefe9-9a54-501f-936b-42a1e492c9f5', 'EXPECTED',
   'Je serais favorable à la semaine de quatre jours. Une journée de plus à la maison, ça change vraiment l''organisation d''une famille, et je suis prêt à faire des journées plus longues pour ça.',
   'La position tient du premier au dernier mot.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C1-S5 / EXCELLENT
  ('2010714e-45d2-5d31-b678-7d78f3595453', '51caefe9-9a54-501f-936b-42a1e492c9f5', 'EXCELLENT',
   'Oui, je signerais tout de suite. Les journées plus longues me font un peu peur, je l''admets, mais ma réponse reste la même : ce jour libre vaut largement l''effort demandé le reste de la semaine.',
   'Une réserve est exprimée sans jamais déplacer la position initiale.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C2-S1 / INSUFFICIENT
  ('860fa896-6ec5-52e6-ac76-2f0f489ef957', 'cf9f4496-e07f-5ba2-88d3-c582c17281a0', 'INSUFFICIENT',
   'Le télétravail, c''est bien. Vraiment, je trouve ça très pratique et très agréable. C''est une bonne chose pour les salariés, je pense que beaucoup de gens sont contents avec ça.',
   'L''opinion est répétée avec d''autres mots, mais aucune raison n''apparaît.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C2-S1 / EXPECTED
  ('db727a54-5597-5479-9691-c8c5026770c2', 'cf9f4496-e07f-5ba2-88d3-c582c17281a0', 'EXPECTED',
   'Le télétravail me convient parce que je ne passe pas deux heures dans les transports. Ce temps-là, je le récupère pour mon travail et pour ma famille.',
   'Une raison précise est donnée et elle soutient bien la position.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C2-S1 / EXCELLENT
  ('28caa972-0da0-5dea-889d-ea2b197ae3f9', 'cf9f4496-e07f-5ba2-88d3-c582c17281a0', 'EXCELLENT',
   'Ce qui compte surtout pour moi, c''est le temps de trajet : deux heures par jour, ça fait dix heures par semaine. Le télétravail me rend ces heures-là, et c''est exactement pour ça que j''y tiens.',
   'La raison est chiffrée et rattachée explicitement à la position.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C2-S2 / INSUFFICIENT
  ('7b5ae5a7-130f-548a-be32-bda4b708c0ca', 'fa584456-137c-5bf0-a497-77facd68128d', 'INSUFFICIENT',
   'Le sport, c''est important, tout le monde le sait. Il faut faire du sport, c''est bon, c''est nécessaire. Moi je pense que chaque personne devrait faire du sport dans sa vie.',
   'La phrase tourne sur elle-même : « important » n''explique pas pourquoi.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C2-S2 / EXPECTED
  ('0b9bb7a7-fb41-5a8b-9615-dd6ee9bb3b34', 'fa584456-137c-5bf0-a497-77facd68128d', 'EXPECTED',
   'Une raison simple : quand on bouge trente minutes par jour, on dort beaucoup mieux la nuit. Et quand on dort mieux, la journée de travail est plus facile.',
   'La raison est concrète et on voit bien son lien avec le sport.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C2-S2 / EXCELLENT
  ('5887b7b6-82f6-5ec9-a2ad-738b0fbd1165', 'fa584456-137c-5bf0-a497-77facd68128d', 'EXCELLENT',
   'La raison qui me convainc le plus, c''est le sommeil. Une demi-heure de marche rapide en fin de journée, et je m''endors sans difficulté. C''est ce qui rend le reste de la semaine tenable.',
   'Une seule raison, tenue jusqu''au bout, sans en empiler d''autres.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C2-S3 / INSUFFICIENT
  ('b42cb4f4-96e7-5393-81f6-74226fad8ec2', '1dfeec6e-5009-5981-a525-191fe5695fcf', 'INSUFFICIENT',
   'Partir en vacances, c''est toujours agréable. On découvre des endroits, on se repose, on rencontre des gens. Je lui conseille vraiment de partir, ça fait du bien à tout le monde.',
   'L''argument parle des vacances, pas du choix de la basse saison.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C2-S3 / EXPECTED
  ('483edd5d-8536-5f45-8adc-e32f02c7c563', '1dfeec6e-5009-5981-a525-191fe5695fcf', 'EXPECTED',
   'Je lui conseille septembre parce que tout coûte moins cher : les billets, l''hébergement, même les activités sur place. Avec le même budget, elle part plus longtemps.',
   'La raison est bien centrée sur la période, comme demandé.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C2-S3 / EXCELLENT
  ('6cdfdea6-1d38-5683-b1e0-c28c1edaa693', '1dfeec6e-5009-5981-a525-191fe5695fcf', 'EXCELLENT',
   'Ce qui fait la différence, c''est le prix de la période : en septembre, le même hôtel se loue parfois moitié moins qu''en août. Voilà pourquoi je lui dis d''attendre trois semaines.',
   'La raison colle exactement au conseil et se referme sur lui.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C2-S4 / INSUFFICIENT
  ('9e7de987-7f1e-57db-8175-e3bbf693c8b4', '5a980d50-604f-5d3b-9861-4d4e0d0edfcd', 'INSUFFICIENT',
   'Les langues, c''est très utile aujourd''hui. Pour le travail, pour voyager, pour comprendre le monde. Donc oui, je suis d''accord avec cette proposition, les enfants doivent apprendre les langues.',
   'L''utilité des langues est dite, mais pas l''intérêt du « tôt ».', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C2-S4 / EXPECTED
  ('aa0d139f-5b22-5c0a-a797-558d714ed271', '5a980d50-604f-5d3b-9861-4d4e0d0edfcd', 'EXPECTED',
   'Je suis d''accord parce qu''un enfant de sept ans n''a pas peur de se tromper. Il répète, il essaie, il ose parler, alors qu''à quinze ans on se bloque devant la classe.',
   'L''âge est au cœur de la raison : la consigne est bien respectée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C2-S4 / EXCELLENT
  ('5262d679-99c5-536d-8fd7-84f13b590de0', '5a980d50-604f-5d3b-9861-4d4e0d0edfcd', 'EXCELLENT',
   'Ce qui joue vraiment, c''est le rapport à l''erreur : à sept ans, un enfant se trompe sans en faire une affaire. C''est cette liberté-là qu''on perd plus tard, et c''est pour ça que je dis : le plus tôt possible.',
   'La raison vise l''âge et se conclut sur la position défendue.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C2-S5 / INSUFFICIENT
  ('e6d61c84-4389-5aa0-aed9-47dd9f29d58d', 'a4b7a784-8f64-5ed5-92c1-c3f6b2202844', 'INSUFFICIENT',
   'L''occasion, c''est moins cher, c''est écologique, et puis on trouve des choses originales qu''on ne voit plus en magasin. Et ça évite le gaspillage aussi. Bref, il y a plein de bonnes raisons.',
   'Quatre raisons sont énumérées : aucune n''est vraiment posée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C2-S5 / EXPECTED
  ('c7deada0-9b7b-54db-a3bb-443804cba994', 'a4b7a784-8f64-5ed5-92c1-c3f6b2202844', 'EXPECTED',
   'Ma raison, c''est la qualité. Un meuble ancien est souvent en bois massif, alors qu''un meuble neuf au même prix ne tiendra pas cinq ans chez moi.',
   'Une raison est choisie et développée assez pour convaincre.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C2-S5 / EXCELLENT
  ('34cb56c0-d7ff-541c-be40-64ca28af9a37', 'a4b7a784-8f64-5ed5-92c1-c3f6b2202844', 'EXCELLENT',
   'Si je dois n''en garder qu''une, c''est la solidité. Une armoire de trente ans a déjà prouvé qu''elle tenait ; celle que j''achèterais neuve au même prix, je ne sais pas si elle passera un déménagement.',
   'Une seule raison, assumée comme telle, et défendue jusqu''au bout.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C3-S1 / INSUFFICIENT
  ('bb9a543e-a13c-5899-8be6-713a4ae2e748', '22507410-e2b6-548e-b1a6-e26036a47e01', 'INSUFFICIENT',
   'Oui, c''est vrai, les transports publics facilitent la vie. C''est plus simple, c''est plus pratique pour tout le monde. Vraiment, la vie quotidienne est plus facile avec les transports en commun.',
   'L''idée est reformulée trois fois, mais elle n''est jamais expliquée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C3-S1 / EXPECTED
  ('b3330e76-3b89-5947-9612-8ddb1dc4b7ca', '22507410-e2b6-548e-b1a6-e26036a47e01', 'EXPECTED',
   'C''est vrai, surtout parce qu''on n''a plus besoin de voiture. Sans voiture, pas d''assurance, pas de stationnement à chercher, et ça enlève une grosse dépense chaque mois.',
   'Une conséquence est déroulée : l''idée avance au lieu de tourner.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C3-S1 / EXCELLENT
  ('f12fb8ab-a172-5b80-9dd9-5622d9531b58', '22507410-e2b6-548e-b1a6-e26036a47e01', 'EXCELLENT',
   'Ça tient surtout au fait qu''on peut vivre sans voiture. Et ça, ça se voit sur le budget : plus d''assurance, plus d''essence, plus de parking à payer. Résultat, une famille peut habiter en ville sans que le transport devienne son premier poste de dépense.',
   'Cause puis conséquence : l''argument est vraiment déplié.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C3-S2 / INSUFFICIENT
  ('8ca5d3de-879e-574f-89ae-93599bd24dbc', '247e0ebd-b9a4-5055-99c2-a7529ba77105', 'INSUFFICIENT',
   'C''est sûr, il faut dormir. Le sommeil, c''est très important pour la santé. Quand on ne dort pas assez, ce n''est pas bon du tout. Il faut vraiment dormir suffisamment.',
   'L''affirmation revient en boucle sans jamais expliquer le mécanisme.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C3-S2 / EXPECTED
  ('a844146a-7f12-582d-84e1-ad376e048526', '247e0ebd-b9a4-5055-99c2-a7529ba77105', 'EXPECTED',
   'Quand on dort sept heures, on se concentre mieux. Du coup, on fait moins d''erreurs, on ne refait pas deux fois le même travail, et la journée paraît moins longue.',
   'L''explication avance par étapes : concentration, erreurs, ressenti.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C3-S2 / EXCELLENT
  ('7e8248a3-a662-58e4-b08f-6ef554e34609', '247e0ebd-b9a4-5055-99c2-a7529ba77105', 'EXCELLENT',
   'Le lien passe par la concentration : avec sept heures de sommeil, l''attention tient jusqu''en fin d''après-midi. Et comme on fait moins d''erreurs, on ne recommence pas le travail le lendemain. C''est là qu''on gagne vraiment du temps.',
   'Chaque étape découle de la précédente jusqu''à une conséquence claire.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C3-S3 / INSUFFICIENT
  ('04f21c18-65af-5fee-8849-bbdcb321a8e2', 'ae39168b-160c-54e1-8131-fd656faf9dd0', 'INSUFFICIENT',
   'Le bénévolat, c''est une belle chose. Ça aide les gens et ça fait plaisir. C''est bien pour celui qui aide et pour celui qui reçoit, tout le monde y gagne, c''est certain.',
   'Le jugement positif remplace l''explication attendue.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C3-S3 / EXPECTED
  ('bdc6ce90-4751-587e-886a-fe0a11a08a3a', 'ae39168b-160c-54e1-8131-fd656faf9dd0', 'EXPECTED',
   'Le bénévole y gagne parce qu''il rencontre des personnes qu''il n''aurait jamais croisées autrement. Petit à petit, il connaît son quartier, et il se sent beaucoup moins isolé.',
   'Une cause est posée, puis sa conséquence : c''est bien développé.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C3-S3 / EXCELLENT
  ('6a39a902-cac8-54b0-ad89-4cffd9888514', 'ae39168b-160c-54e1-8131-fd656faf9dd0', 'EXCELLENT',
   'Ce que le bénévole récupère, c''est un réseau. En donnant deux heures le samedi, il finit par connaître le boulanger, la voisine du dessus, l''animateur du centre social. Et le jour où c''est lui qui a besoin d''un coup de main, il ne le demande plus à des inconnus.',
   'La conséquence est poussée jusqu''à un effet concret sur le bénévole.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C3-S4 / INSUFFICIENT
  ('1eff3cf2-5b25-5f58-909d-33c3dc0f04b8', 'b1cae959-63bf-5c29-9ed7-884d7d0db156', 'INSUFFICIENT',
   'Il faut trier, c''est notre devoir à tous. Si tout le monde trie, la planète ira mieux. Ne pas trier, c''est mauvais pour l''environnement et pour les générations futures.',
   'Le principe est répété, mais on ne voit pas comment ça marche.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C3-S4 / EXPECTED
  ('c3af7965-226c-5055-ac39-d7e2786a5deb', 'b1cae959-63bf-5c29-9ed7-884d7d0db156', 'EXPECTED',
   'Trier sert parce qu''un carton propre repart à l''usine et redevient un autre carton. S''il est mélangé aux ordures, il finit brûlé et il faut couper de nouveaux arbres.',
   'Le mécanisme est expliqué, du bac jusqu''à sa conséquence.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C3-S4 / EXCELLENT
  ('e54657b6-6cdb-5162-9ae4-aa8192ff69cb', 'b1cae959-63bf-5c29-9ed7-884d7d0db156', 'EXCELLENT',
   'Tout se joue au moment du ramassage : un carton propre repart en usine et redevient du carton, alors qu''un carton taché de gras part à l''incinération. Autrement dit, chaque bac mal rempli oblige à fabriquer du neuf, et c''est ce neuf-là qui coûte des arbres et de l''énergie.',
   'La chaîne complète est décrite, du geste à sa conséquence finale.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C3-S5 / INSUFFICIENT
  ('826512a8-05b7-5adf-bb11-a72ca08b9bda', 'c94cbd90-cd54-52b4-9264-65726dac260d', 'INSUFFICIENT',
   'Les cours en ligne, c''est pratique quand on travaille. C''est plus flexible, c''est plus facile. Beaucoup de gens choisissent ça aujourd''hui parce que c''est vraiment plus arrangeant.',
   '« Pratique » et « flexible » restent des étiquettes, pas des explications.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C3-S5 / EXPECTED
  ('b432eda2-a7c3-57f7-9bad-67118dbd7187', 'c94cbd90-cd54-52b4-9264-65726dac260d', 'EXPECTED',
   'Ça change tout parce que le cours reste disponible après. Quelqu''un qui finit à vingt heures peut le suivre à vingt-deux heures, sans demander à changer ses horaires de travail.',
   'L''explication montre concrètement ce que la formation rend possible.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C3-S5 / EXCELLENT
  ('e5d69da0-464f-5e70-8aa4-d9a0a99ad3d2', 'c94cbd90-cd54-52b4-9264-65726dac260d', 'EXCELLENT',
   'L''élément décisif, c''est que le cours est enregistré. Un salarié qui termine à vingt heures ne demande plus d''aménagement à son employeur : il rattrape le soir même. Et comme il ne touche pas à ses horaires, il ne perd pas de salaire. C''est ça qui rend la reprise d''études possible.',
   'L''explication va jusqu''au bout : disponibilité, horaires, salaire.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C4-S1 / INSUFFICIENT
  ('8cd2a216-814d-5be9-8aa9-bdb378ae1f3f', 'fc1af6dc-65c8-54f5-8c23-20d041c4e66f', 'INSUFFICIENT',
   'Oui, il y a beaucoup d''exemples. Par exemple, les gens qui font du sport sont en meilleure forme, on le voit tous les jours. C''est un très bon exemple de ce que je dis.',
   'L''exemple est annoncé mais aucune situation n''est réellement racontée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C4-S1 / EXPECTED
  ('67e8870d-e36d-5728-b472-4100d745b620', 'fc1af6dc-65c8-54f5-8c23-20d041c4e66f', 'EXPECTED',
   'Par exemple, ma sœur travaille de nuit à l''hôpital. Depuis qu''elle nage deux fois par semaine le matin, elle dit qu''elle tient beaucoup mieux ses semaines.',
   'Une personne, une activité, un effet : l''exemple existe vraiment.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C4-S1 / EXCELLENT
  ('ec857ec0-54a6-5a9f-baf4-fa3aa07c5851', 'fc1af6dc-65c8-54f5-8c23-20d041c4e66f', 'EXCELLENT',
   'Je pense à ma sœur : infirmière de nuit, elle rentrait épuisée le vendredi. Depuis un an, elle nage une heure les mardis et jeudis matin, et elle a arrêté de dormir tout son samedi. C''est le seul changement qu''elle a fait.',
   'Détails situés et effet observable : l''exemple devient une preuve.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C4-S2 / INSUFFICIENT
  ('d6ce3dd9-4ed3-5497-9d36-e69cc16fdbf6', 'd3da62f6-54e4-54ff-9198-e9cf0a8816e0', 'INSUFFICIENT',
   'Au marché, c''est différent, on trouve de bons produits. Par exemple les fruits et les légumes sont meilleurs, c''est bien connu. Voilà, c''est un exemple parmi d''autres.',
   'La généralité est présentée comme un exemple : il manque la scène.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C4-S2 / EXPECTED
  ('2f684eb5-86a1-5ed3-a112-f4826294d0e6', 'd3da62f6-54e4-54ff-9198-e9cf0a8816e0', 'EXPECTED',
   'Par exemple, le samedi matin, je vais au marché de ma commune. Le maraîcher me dit ce qui vient d''arriver, et je cuisine ce qu''il me conseille au lieu de suivre ma liste.',
   'Lieu, moment et geste : la situation est facile à se représenter.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C4-S2 / EXCELLENT
  ('f4770d90-743b-590e-8203-f266ae82fa55', 'd3da62f6-54e4-54ff-9198-e9cf0a8816e0', 'EXCELLENT',
   'Je pense à un samedi de novembre : je venais pour des tomates, le maraîcher m''a dit qu''il n''en avait plus et m''a montré ses courges. Je suis rentrée avec une courge et j''ai cherché une recette le soir même. Je n''en avais jamais cuisiné.',
   'Une scène unique et datée, avec un effet net sur la pratique.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C4-S3 / INSUFFICIENT
  ('4b8acb34-4da9-5451-bae1-690350c0ebe4', 'ea7e2a6b-c24a-53f2-9567-d32663f6993e', 'INSUFFICIENT',
   'Par exemple, la colocation coûte moins cher, on partage le loyer et les charges. C''est un bon exemple, beaucoup d''étudiants font ça pour payer moins tous les mois.',
   'L''exemple porte sur l''argent, justement ce qu''il fallait dépasser.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C4-S3 / EXPECTED
  ('a9e93dfb-f9fa-5711-a1fe-5b9ca8048fed', 'ea7e2a6b-c24a-53f2-9567-d32663f6993e', 'EXPECTED',
   'Par exemple, quand je suis arrivée à Lyon, ma colocataire m''a expliqué comment ouvrir un compte et où déposer mes papiers. Toute seule, j''aurais mis des semaines.',
   'Une situation datée qui illustre exactement le point demandé.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C4-S3 / EXCELLENT
  ('d81bfb0c-98c8-535b-ae48-9e76031932b0', 'ea7e2a6b-c24a-53f2-9567-d32663f6993e', 'EXCELLENT',
   'Je pense à ma première semaine à Lyon : je ne savais pas où déposer mon dossier de logement. Ma colocataire a sorti son ordinateur un soir et on a rempli le formulaire ensemble. Ce n''est pas de l''argent, ça, c''est du temps : trois semaines gagnées.',
   'L''exemple est précis et son lien avec l''idée est explicité.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C4-S4 / INSUFFICIENT
  ('b827dc0f-b9bc-5390-a8cd-f3db740ee081', '7ecc8ab7-d5bf-55be-ac46-c5dfe68caba6', 'INSUFFICIENT',
   'Par exemple, les formations aident beaucoup les salariés. Il y a des gens qui suivent des formations et après ça va mieux pour eux, ils progressent dans leur travail.',
   '« Des gens » et « ça va mieux » : rien n''est situé.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C4-S4 / EXPECTED
  ('1a7a2614-aab4-57ba-af6c-68cd1a86e19d', '7ecc8ab7-d5bf-55be-ac46-c5dfe68caba6', 'EXPECTED',
   'Par exemple, un collègue faisait de la manutention depuis dix ans. Il a suivi une formation de trois semaines pour conduire les chariots, et il est passé chef d''équipe l''année suivante.',
   'Métier, durée, résultat : l''exemple soutient bien l''idée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C4-S4 / EXCELLENT
  ('4aaf1857-c297-5be9-90ce-00cdccbec3d4', '7ecc8ab7-d5bf-55be-ac46-c5dfe68caba6', 'EXCELLENT',
   'Je pense à Karim, qui déchargeait des camions depuis dix ans. Trois semaines de formation aux chariots élévateurs, un certificat en poche, et son responsable lui a confié l''équipe du matin six mois plus tard. Trois semaines, après dix ans au même poste.',
   'La progression est datée et l''exemple se referme sur l''idée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C4-S5 / INSUFFICIENT
  ('4efc567a-b1be-5eeb-9cc4-734609ebd0d8', 'ac23e5e6-19fc-58b0-8205-23ce938bb3fe', 'INSUFFICIENT',
   'Par exemple, à la bibliothèque il y a beaucoup de livres, des romans, des documentaires. Les gens viennent lire et emprunter. C''est un lieu très utile pour tout le monde.',
   'L''exemple retombe sur les livres, alors qu''il fallait en sortir.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C4-S5 / EXPECTED
  ('b97849f3-26f8-5bd3-9891-429fdc78fce9', 'ac23e5e6-19fc-58b0-8205-23ce938bb3fe', 'EXPECTED',
   'Par exemple, dans ma bibliothèque, il y a un atelier d''écriture de CV le jeudi après-midi. Des personnes viennent avec leur clé USB et repartent avec un document imprimé.',
   'L''usage choisi est bien distinct de l''emprunt, et il est situé.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C4-S5 / EXCELLENT
  ('7fce4410-2546-5c74-8eae-ed15b0c1ddfc', 'ac23e5e6-19fc-58b0-8205-23ce938bb3fe', 'EXCELLENT',
   'Je pense au jeudi après-midi chez nous : un bénévole tient un atelier CV au premier étage. Une voisine y est allée avec une feuille écrite à la main ; elle est ressortie avec un CV imprimé et une adresse mail créée le jour même.',
   'Une scène complète, avec un avant et un après très nets.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C5-S1 / INSUFFICIENT
  ('26e54197-50b5-5a08-95d7-4cf414701460', '41b73b60-27c8-5112-8b5f-7f4567518cc7', 'INSUFFICIENT',
   'Et puis en équipe, on va plus vite, on avance mieux, le travail se fait plus rapidement parce qu''on est plusieurs. Donc c''est vraiment un gain de temps important.',
   'C''est le premier argument redit autrement : rien de nouveau n''apparaît.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C5-S1 / EXPECTED
  ('0034fb08-9028-5f60-b315-c16ae102cb3c', '41b73b60-27c8-5112-8b5f-7f4567518cc7', 'EXPECTED',
   'Ensuite, il y a autre chose : en équipe, on se corrige mutuellement. Ce qu''un collègue ne voit pas, un autre le repère, et les erreurs sortent avant la fin du projet.',
   'Un terrain différent est ouvert : la qualité, plus la vitesse.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C5-S1 / EXCELLENT
  ('5666fc7b-f396-5130-8887-52a803ea07c5', '41b73b60-27c8-5112-8b5f-7f4567518cc7', 'EXCELLENT',
   'Deuxième point, et il n''a rien à voir avec le temps : la qualité. À plusieurs, chacun relit le travail de l''autre, et une erreur qui aurait coûté cher est repérée dès le début, pas à la livraison.',
   'La distinction avec le premier argument est annoncée puis tenue.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C5-S2 / INSUFFICIENT
  ('432d181d-e08d-5ce8-ab26-25757cb9821d', '53694445-a8ab-5406-a180-d1aedb1ad44c', 'INSUFFICIENT',
   'En plus, le vélo ne coûte presque rien : pas d''essence, pas d''assurance, pas de parking à payer. Financièrement, c''est vraiment la meilleure solution en ville.',
   'Le nouvel argument reprend le budget, terrain déjà couvert.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C5-S2 / EXPECTED
  ('aa5f7ec3-1912-5a1e-8403-595e322df05c', '53694445-a8ab-5406-a180-d1aedb1ad44c', 'EXPECTED',
   'Autre chose : à vélo, on connaît son temps de trajet. Il n''y a pas d''embouteillage, donc on arrive à l''heure même quand la circulation est difficile.',
   'La fiabilité horaire est un argument neuf, clairement séparé.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C5-S2 / EXCELLENT
  ('a29cc457-0727-515e-8d2f-b7020ac5774c', '53694445-a8ab-5406-a180-d1aedb1ad44c', 'EXCELLENT',
   'Deuxième argument, sur un tout autre plan : la régularité. Un trajet à vélo dure vingt minutes le lundi comme le vendredi soir, alors qu''en voiture le même trajet peut doubler. On ne parle plus de budget là, on parle de fiabilité.',
   'Le changement de terrain est signalé : la réponse est très lisible.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C5-S3 / INSUFFICIENT
  ('994548cc-b39c-59d5-9056-6bd6c0645e53', '21afd132-0c73-5c78-90e7-ff9048bd4ba3', 'INSUFFICIENT',
   'Et puis les élèves aiment ça, ils sont contents de sortir, ça leur donne envie de travailler. Franchement, la motivation, c''est vraiment l''essentiel dans une sortie scolaire.',
   'La réponse insiste sur la motivation au lieu d''ouvrir autre chose.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C5-S3 / EXPECTED
  ('8b869ea9-f710-5bbc-9a48-3b01b2da4e46', '21afd132-0c73-5c78-90e7-ff9048bd4ba3', 'EXPECTED',
   'Il y a aussi le groupe : pendant une sortie, des élèves qui ne se parlent jamais en classe passent la journée ensemble. Au retour, l''ambiance n''est plus la même.',
   'La vie du groupe est un argument bien distinct du premier.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C5-S3 / EXCELLENT
  ('e56ead03-c3d9-513a-8e33-2bb081bf8f85', '21afd132-0c73-5c78-90e7-ff9048bd4ba3', 'EXCELLENT',
   'Un deuxième aspect, qui n''a rien à voir avec l''envie d''apprendre : les relations. Dans le car et pendant le pique-nique, des élèves qui s''ignoraient se découvrent. Et cette journée-là continue de se sentir en classe pendant des semaines.',
   'L''argument est neuf, situé, et son effet durable est précisé.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C5-S4 / INSUFFICIENT
  ('1fcc1681-90b8-5e9c-a9b9-ca99d906ac63', '0a7eb51d-5e64-5655-a81a-58214315b82e', 'INSUFFICIENT',
   'Et aussi, ça permet de détecter les problèmes rapidement, avant que ce soit grave. Plus on trouve tôt, mieux on soigne, c''est vraiment le plus important.',
   'Le dépistage revient : c''est le premier argument, pas un second.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C5-S4 / EXPECTED
  ('a9b9e4b4-f9fc-5e09-8915-8183a138c37e', '0a7eb51d-5e64-5655-a81a-58214315b82e', 'EXPECTED',
   'Il y a un autre intérêt : on repart avec des conseils adaptés. Le médecin regarde votre travail, vos horaires, et il vous dit quoi changer concrètement.',
   'Le conseil personnalisé est un angle vraiment différent.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C5-S4 / EXCELLENT
  ('a79ee244-9693-512f-ac9c-81327031f4eb', '0a7eb51d-5e64-5655-a81a-58214315b82e', 'EXCELLENT',
   'Un second intérêt, et il ne concerne pas la maladie : le conseil. En vingt minutes, le médecin regarde vos horaires, votre poste, votre sommeil, et il propose deux ou trois changements réalistes. C''est une consultation qui sert même quand tous les résultats sont normaux.',
   'L''argument tient debout seul, y compris si rien n''est détecté.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C5-S5 / INSUFFICIENT
  ('ba199466-be5a-5e07-9183-756d23e27194', 'd475cf65-93dc-53f3-9824-4862252f3866', 'INSUFFICIENT',
   'Et puis ça permet de parler avec sa famille, de voir les enfants, les parents, même très loin. C''est le grand avantage, on garde le contact avec ceux qu''on aime.',
   'L''argument familial est simplement redéveloppé, pas remplacé.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C5-S5 / EXPECTED
  ('c472ef7a-39b4-540e-8a46-b084995f8ca7', 'd475cf65-93dc-53f3-9824-4862252f3866', 'EXPECTED',
   'Il y a aussi le côté pratique au quotidien : les groupes de voisins ou de parents d''élèves. Une information circule en cinq minutes alors qu''avant il fallait une réunion.',
   'L''organisation collective est un domaine neuf, bien séparé.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C5-S5 / EXCELLENT
  ('975dfd82-a5b9-5996-bcfd-ac3b5bbe0f17', 'd475cf65-93dc-53f3-9824-4862252f3866', 'EXCELLENT',
   'Deuxième argument, sur un terrain complètement différent : l''organisation locale. Dans mon immeuble, le groupe de discussion règle en cinq minutes une panne d''ascenseur ou une clé perdue. Ça n''a plus rien à voir avec la famille, c''est du service entre voisins.',
   'Le changement de domaine est explicite et l''exemple le confirme.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C6-S1 / INSUFFICIENT
  ('58e43acb-44f0-56e8-8cfd-7ffb1ae8584c', 'cc17ca88-a1b3-579c-a9d8-9cbec6808882', 'INSUFFICIENT',
   'En ligne, il y a beaucoup de choix, on commande à toute heure, c''est livré à la maison. En magasin, il y a des vendeurs, on peut toucher les produits, l''ambiance est agréable, on sort de chez soi.',
   'Deux descriptions se suivent : elles ne se répondent jamais.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C6-S1 / EXPECTED
  ('e207a5ba-00c9-549c-88b3-a8f3fe46be68', 'cc17ca88-a1b3-579c-a9d8-9cbec6808882', 'EXPECTED',
   'Sur le choix, internet gagne : on trouve toutes les tailles, alors qu''en magasin il manque souvent la vôtre. En revanche, pour essayer, le magasin reste imbattable.',
   'Deux points de comparaison, chacun tranché entre les deux options.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C6-S1 / EXCELLENT
  ('6b45855c-e464-56bd-bb47-d0f33a035140', 'cc17ca88-a1b3-579c-a9d8-9cbec6808882', 'EXCELLENT',
   'Tout se joue sur deux points. Le choix, d''abord : en ligne on a toutes les tailles, alors qu''en magasin on repart souvent les mains vides. L''essayage, ensuite : là, c''est l''inverse, on voit tout de suite si ça tombe bien, ce qu''aucune photo ne remplace.',
   'Les points sont annoncés, comparés, et l''inversion est soulignée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C6-S2 / INSUFFICIENT
  ('2d771e81-8885-5255-8503-d2bf979d751a', '165e787e-b50f-54bc-820a-54d7975d863b', 'INSUFFICIENT',
   'La salle, il y a des machines, un coach, c''est chauffé, on paie un abonnement. Dehors, c''est gratuit, il y a l''air frais, les parcs, on est libre de ses horaires.',
   'Chaque option est décrite dans son coin, sans point de rencontre.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C6-S2 / EXPECTED
  ('fb671ec5-12f8-52ec-9319-906783265954', '165e787e-b50f-54bc-820a-54d7975d863b', 'EXPECTED',
   'Côté prix, courir dehors ne coûte rien, alors que la salle demande trente euros par mois. Par contre, sur la régularité, la salle aide davantage : quand on paie, on y va.',
   'Prix puis régularité : deux points traités des deux côtés.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C6-S2 / EXCELLENT
  ('8e3c565f-5b44-594f-8bbb-235d6bddf36a', '165e787e-b50f-54bc-820a-54d7975d863b', 'EXCELLENT',
   'Deux critères suffisent. Le coût : dehors, zéro euro, alors qu''une salle tourne autour de trente euros par mois. La régularité : là c''est l''inverse, l''abonnement pousse à y aller, tandis que dehors, une semaine de pluie suffit à tout arrêter.',
   'Chaque critère est traité des deux côtés, avec l''écart expliqué.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C6-S3 / INSUFFICIENT
  ('2722568e-2644-5a02-bcab-324fa53304a3', '1011b278-d4cf-520d-8645-8b45cc8e4162', 'INSUFFICIENT',
   'L''appartement en centre-ville, c''est petit mais tout est proche. La maison est plus grande, avec un jardin, et c''est plus calme pour les enfants. Les deux solutions ont leurs avantages.',
   'Les deux sont décrits, mais aucun critère ne les met face à face.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C6-S3 / EXPECTED
  ('b82af869-deec-5573-aa70-6cfcd537e902', '1011b278-d4cf-520d-8645-8b45cc8e4162', 'EXPECTED',
   'Sur l''espace, la maison l''emporte largement : le double de surface pour le même loyer. Mais sur les trajets, c''est l''appartement qui gagne, parce qu''on va à l''école à pied alors qu''en périphérie il faut deux voitures.',
   'Espace et trajets sont traités pour les deux logements.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C6-S3 / EXCELLENT
  ('2d48c153-21db-5f05-842d-ee0b0a9bd2a0', '1011b278-d4cf-520d-8645-8b45cc8e4162', 'EXCELLENT',
   'Je comparerais sur deux choses. La surface : à loyer égal, la maison offre le double, alors que le centre-ville se paie au mètre carré. Les déplacements : là c''est l''inverse, en ville l''école est à pied, tandis qu''à vingt kilomètres il faut deux voitures. Et deux voitures, ça reprend une bonne partie de ce qu''on gagne sur le loyer.',
   'La comparaison est bouclée : le second critère répond au premier.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C6-S4 / INSUFFICIENT
  ('8c2d7b24-0867-5a12-a056-930be56200ab', '20730fba-8c86-5ff0-929b-c5597c2d8994', 'INSUFFICIENT',
   'Le voyage organisé, tout est prévu, on ne s''occupe de rien, il y a un guide. Le voyage libre, on choisit ses horaires, on va où on veut, on rencontre plus de monde.',
   'Deux portraits parallèles : la mise en relation manque.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C6-S4 / EXPECTED
  ('2959fc1a-12f6-5e45-baa6-c5862716885e', '20730fba-8c86-5ff0-929b-c5597c2d8994', 'EXPECTED',
   'Sur la préparation, l''organisé gagne : on ne réserve rien soi-même. Mais sur la liberté, c''est l''inverse, parce qu''on suit le programme du groupe alors qu''en voyage libre on change d''avis le matin même.',
   'Préparation et liberté sont examinées des deux côtés.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C6-S4 / EXCELLENT
  ('3a755c44-e54f-514f-b757-bfa78d746567', '20730fba-8c86-5ff0-929b-c5597c2d8994', 'EXCELLENT',
   'Deux critères les séparent vraiment. L''effort de préparation : quasi nul en séjour organisé, alors qu''en libre il faut y passer des soirées entières. La marge de manœuvre : là c''est l''inverse, le groupe impose ses horaires, tandis qu''en libre on peut rester trois jours de plus dans une ville qu''on aime.',
   'Le renversement entre les deux critères est clairement montré.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C6-S5 / INSUFFICIENT
  ('67452d8f-ee33-5b2f-98f3-c8d1463b0001', 'cf1b5766-86ab-5ccf-9129-8a2ba7bd3bee', 'INSUFFICIENT',
   'Les cours en ligne, c''est flexible, on suit quand on veut, on ne se déplace pas. Les cours du soir, il y a un professeur en face, des camarades, un vrai cadre. Chacun choisit selon son caractère.',
   'Les avantages s''empilent sans jamais être mis en balance.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C6-S5 / EXPECTED
  ('f3eb098b-89d8-5e81-9825-4585e149962c', 'cf1b5766-86ab-5ccf-9129-8a2ba7bd3bee', 'EXPECTED',
   'En ligne, l''avantage, c''est l''horaire libre, mais l''inconvénient, c''est qu''on abandonne facilement. En salle, c''est l''inverse : l''horaire est imposé, par contre le groupe vous oblige à revenir chaque semaine.',
   'Chaque avantage est accompagné de son revers, des deux côtés.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C6-S5 / EXCELLENT
  ('561d901a-d490-5e3b-bc34-32af113073b8', 'cf1b5766-86ab-5ccf-9129-8a2ba7bd3bee', 'EXCELLENT',
   'Les deux formules s''opposent point par point. La souplesse : totale en ligne, nulle en salle. La persévérance : c''est l''inverse, on décroche vite seul devant un écran, alors qu''en salle le professeur remarque une absence dès la deuxième fois. Donc tout dépend de ce qui manque le plus au stagiaire : du temps, ou de la discipline.',
   'Chaque critère est retourné, puis la comparaison débouche sur un critère de choix.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C7-S1 / INSUFFICIENT
  ('78cd35fc-2556-5fb3-ad97-3cc63b484bc1', '1cb06299-fece-5629-8da8-0f18e4be25e6', 'INSUFFICIENT',
   'Les réseaux sociaux, c''est utile pour rester en contact. Mais en fait il y a beaucoup de fausses informations, les gens perdent leur temps, ça crée des disputes. Finalement, je me demande si c''est vraiment une bonne chose.',
   'La limite emporte tout : la position de départ a disparu.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C7-S1 / EXPECTED
  ('3f344cf0-441c-58d2-906d-95ab25caaf77', '1cb06299-fece-5629-8da8-0f18e4be25e6', 'EXPECTED',
   'Les réseaux sociaux permettent de garder le contact avec une famille loin. Cela dit, ils prennent facilement trop de place dans une soirée. Mais globalement, je trouve qu''on y gagne.',
   'La réserve est posée, puis la position est reprise en fin de réponse.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C7-S1 / EXCELLENT
  ('5e74fcce-4551-5a52-87b0-91edb50ddae7', '1cb06299-fece-5629-8da8-0f18e4be25e6', 'EXCELLENT',
   'Leur vrai apport, c''est le lien avec une famille à l''étranger. Après, je ne vais pas prétendre que tout est parfait : on y passe vite une soirée entière sans s''en rendre compte. Ça reste, pour moi, un problème d''usage, pas une raison de s''en priver.',
   'La limite est reconnue puis remise à sa place, sans renoncement.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C7-S2 / INSUFFICIENT
  ('c81dca74-61f6-5017-bbbf-b9aa32945366', 'c20c538f-23a5-5f78-9199-fdfd5e1914ce', 'INSUFFICIENT',
   'Les horaires libres, c''est bien pour s''organiser. Le problème, c''est qu''on ne se croise plus, on ne sait plus qui est là, les réunions deviennent impossibles. Bref, ce n''est pas si simple à gérer.',
   'L''avis favorable annoncé au début n''est plus défendu à la fin.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C7-S2 / EXPECTED
  ('99dc9b6b-3637-5368-9f0f-8c99dbeb92fc', 'c20c538f-23a5-5f78-9199-fdfd5e1914ce', 'EXPECTED',
   'L''avantage, c''est de pouvoir déposer les enfants avant de commencer. Il y a une limite quand même : on se croise moins entre collègues. Mais je reste favorable à ce système.',
   'L''avantage, la limite, puis la position : l''ordre est très lisible.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C7-S2 / EXCELLENT
  ('b0c1d18d-41c1-581c-ab25-47e02cd65fdb', 'c20c538f-23a5-5f78-9199-fdfd5e1914ce', 'EXCELLENT',
   'Ce que ça change vraiment, c''est de pouvoir déposer les enfants sans courir. Je reconnais une difficulté : il faut fixer une plage commune, sinon plus personne ne se croise. Mais c''est une question d''organisation, pas un défaut du système, et j''y suis toujours favorable.',
   'La limite est traitée comme un ajustement, pas comme une objection.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C7-S3 / INSUFFICIENT
  ('1cb8088c-be48-5988-ab6b-209a211165fc', 'c5426afe-4cda-54ff-a42d-e996370f5258', 'INSUFFICIENT',
   'La livraison, ça dépanne. Mais c''est cher, les plats sont souvent trop gras, et les emballages finissent à la poubelle. Honnêtement, je préfère éviter au maximum.',
   'La réserve devient la conclusion : votre position s''est inversée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C7-S3 / EXPECTED
  ('8105bfe0-9e8f-5d39-8025-8fe3c48adac7', 'c5426afe-4cda-54ff-a42d-e996370f5258', 'EXPECTED',
   'Se faire livrer dépanne vraiment quand on rentre à vingt et une heures. Il faut reconnaître que ça revient cher si on en abuse. Mais comme solution de dépannage, je continue de trouver ça utile.',
   'La réserve est cadrée par un usage : la position reste debout.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C7-S3 / EXCELLENT
  ('afcd0ace-9688-5146-9827-ba5c6aa3654e', 'c5426afe-4cda-54ff-a42d-e996370f5258', 'EXCELLENT',
   'Un soir où l''on rentre à vingt et une heures, la livraison sauve un repas, c''est indéniable. J''admets une limite : au-delà d''une fois par semaine, le budget grimpe très vite. Mais cette limite dit surtout comment l''utiliser, elle ne me fait pas changer d''avis sur son utilité.',
   'La limite est transformée en règle d''usage, sans céder la position.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C7-S4 / INSUFFICIENT
  ('2272ab93-2564-5e28-9f35-62a9f9da364c', '87453541-2796-5201-87c7-e248d7b01863', 'INSUFFICIENT',
   'C''est pratique pour les petits trajets. Mais elles sont garées n''importe où, elles gênent les piétons, il y a des accidents. Je pense que la ville devrait revoir tout ça, c''est vraiment problématique.',
   'La fin ne défend plus rien de ce qui avait été annoncé.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C7-S4 / EXPECTED
  ('176e6190-f7c2-569c-91ff-6bd62f21a3cf', '87453541-2796-5201-87c7-e248d7b01863', 'EXPECTED',
   'L''intérêt, c''est le dernier kilomètre entre la gare et le bureau. Je reconnais que le stationnement sauvage pose un vrai problème sur les trottoirs. Mais je reste favorable au service, avec des emplacements dédiés.',
   'La limite est sérieuse, et la position revient avec une condition.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C7-S4 / EXCELLENT
  ('6527785c-dfff-5a9b-9fcd-d6fa07db1e37', '87453541-2796-5201-87c7-e248d7b01863', 'EXCELLENT',
   'Ce service règle le dernier kilomètre, celui que ni le bus ni la marche ne couvrent bien. Cela dit, je ne minimise pas le problème : une trottinette en travers d''un trottoir, pour une personne en fauteuil, c''est bloquant. Ça demande des emplacements marqués, pas la suppression du service.',
   'La limite est prise au sérieux et la position se conclut par une solution.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C7-S5 / INSUFFICIENT
  ('df501773-4a0d-5026-8653-95c6bd2cb314', 'cc2d7f13-633c-5198-8e06-959ffab482ac', 'INSUFFICIENT',
   'L''électrique ne pollue pas en ville, c''est vrai. Après, la fabrication des batteries pollue beaucoup, l''électricité vient bien de quelque part, et les bornes manquent. Du coup je ne suis pas sûr que ce soit la solution.',
   'La concession efface l''avantage : plus aucun avis n''est défendu.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C7-S5 / EXPECTED
  ('ffe8dd1a-e835-5614-b794-8c8fbf97bbcf', 'cc2d7f13-633c-5198-8e06-959ffab482ac', 'EXPECTED',
   'Son intérêt principal, c''est l''air des villes : plus de gaz d''échappement dans les rues où les enfants marchent. Je reconnais que la fabrication des batteries a un coût écologique. Mais sur toute la vie du véhicule, je pense que le bilan reste favorable.',
   'La concession est réelle et la position est reprise avec un argument.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C7-S5 / EXCELLENT
  ('0b83dfe1-98bc-5d85-ae0b-8598421666f9', 'cc2d7f13-633c-5198-8e06-959ffab482ac', 'EXCELLENT',
   'Ce qu''elle change vraiment, c''est la qualité de l''air là où les gens vivent. Je concède volontiers le point sensible : produire une batterie coûte cher en énergie, ce n''est pas un détail. Simplement, ce coût se rembourse au fil des kilomètres, donc ma position ne bouge pas, même si je comprends qu''on la discute.',
   'La concession est franche, puis retournée par un argument précis.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C8-S1 / INSUFFICIENT
  ('1fb51f7f-fb76-5b8f-84c1-f6e8047886d5', 'f73aceb2-5cbf-529a-b7e1-c3a9fd7c2796', 'INSUFFICIENT',
   'Le club, c''est bien. Il y a un entraîneur, des horaires, des compétitions, des amis, du matériel. Seul, on est libre, on choisit son moment. Il y a aussi le prix, et puis les déplacements le week-end.',
   'Les idées s''accumulent : ni raison suivie, ni exemple, ni conclusion.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C8-S1 / EXPECTED
  ('e20edf0d-85b6-5612-8448-77c44c380f3d', 'f73aceb2-5cbf-529a-b7e1-c3a9fd7c2796', 'EXPECTED',
   'Je préfère le club. D''abord parce que les horaires fixes m''obligent à y aller. Par exemple, mon cours de volley est le mardi à dix-neuf heures, donc je ne réfléchis plus. Au final, c''est le club qui me fait tenir toute l''année.',
   'Avis, raison, exemple, conclusion : les quatre temps sont là.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C8-S1 / EXCELLENT
  ('f5a5d7db-cf08-5b69-9621-ea23d4294a48', 'f73aceb2-5cbf-529a-b7e1-c3a9fd7c2796', 'EXCELLENT',
   'Pour moi, c''est le club, sans hésitation. La raison principale, c''est que l''horaire est décidé à ma place, donc je ne peux plus me trouver d''excuse. Par exemple, mon volley du mardi à dix-neuf heures : même fatiguée, j''y vais parce que l''équipe m''attend. Au bout du compte, ce qui me fait tenir, ce n''est pas la motivation, c''est le rendez-vous.',
   'Chaque étape prépare la suivante et la conclusion apporte une idée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C8-S2 / INSUFFICIENT
  ('0d9e64c8-620a-5398-91cd-14082ebd1b62', '1418562f-6e0b-569e-9eee-52029c28ca02', 'INSUFFICIENT',
   'Réparer, c''est bien pour la planète, ça coûte moins cher, ça crée du travail, et puis on garde ses affaires. Racheter, c''est rapide mais on jette beaucoup. Voilà, il y a plusieurs choses à dire là-dessus.',
   'Beaucoup d''idées, aucune développée, et la réponse s''arrête sans fin.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C8-S2 / EXPECTED
  ('ab4e7f2f-9951-5785-9fb9-da9ad39ee726', '1418562f-6e0b-569e-9eee-52029c28ca02', 'EXPECTED',
   'Je pense qu''il faut réparer. La raison, c''est qu''un appareil réparé dure encore des années. Par exemple, ma machine à laver a été réparée pour quatre-vingts euros au lieu de quatre cents. Donc oui, l''atelier du quartier a tout son sens.',
   'L''enchaînement est net et la conclusion revient sur la question posée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C8-S2 / EXCELLENT
  ('d77052ba-4e6b-5468-af04-f93f065bb2f4', '1418562f-6e0b-569e-9eee-52029c28ca02', 'EXCELLENT',
   'Je suis clairement pour la réparation. Ce qui me convainc, c''est que la panne concerne souvent une seule pièce, pas tout l''appareil. Par exemple, ma machine à laver s''est arrêtée l''hiver dernier : une pompe changée, quatre-vingts euros, contre quatre cents pour une neuve. Au final, un atelier de quartier ne fait pas qu''économiser de l''argent, il évite de jeter une machine qui marche encore.',
   'L''exemple sert l''argument et la conclusion élargit sans changer de sujet.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C8-S3 / INSUFFICIENT
  ('8ff18944-25cc-5dac-a1f0-e76ab8315393', '3b20205c-2a5a-5341-a477-335716573ad8', 'INSUFFICIENT',
   'Vivre en France, on entend le français partout, à la boulangerie, au travail, à la télévision. Les cours aussi c''est utile, la grammaire, l''écrit, les professeurs. Les deux ensemble, c''est mieux, je crois.',
   'L''avis arrive à la fin, sans raison développée ni exemple.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C8-S3 / EXPECTED
  ('b25b9347-f026-5aab-96fd-b36f58736289', '3b20205c-2a5a-5341-a477-335716573ad8', 'EXPECTED',
   'Je pense que vivre ici ne suffit pas. Parce que dans la vie courante, on répète toujours les mêmes phrases. Par exemple, j''ai passé deux ans à comprendre mes collègues sans jamais savoir écrire un mail correct. Donc pour moi, les cours restent nécessaires.',
   'Les quatre temps s''enchaînent et la conclusion répond à la question.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C8-S3 / EXCELLENT
  ('2633300b-1d78-5712-86d2-432429f2c294', '3b20205c-2a5a-5341-a477-335716573ad8', 'EXCELLENT',
   'Ma réponse est non, vivre ici ne suffit pas. La raison, c''est que le quotidien fait tourner un vocabulaire très limité : les courses, le travail, les horaires. Par exemple, pendant deux ans j''ai compris tous mes collègues, mais devant un courriel à écrire à l''administration, j''étais bloquée. Donc l''immersion donne l''oreille et le cours donne le reste : il faut les deux, pas l''un à la place de l''autre.',
   'La conclusion synthétise au lieu de répéter la position initiale.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C8-S4 / INSUFFICIENT
  ('49e61ffc-ae77-5474-81db-35d8b6bf5474', '694acd25-5238-56f1-9129-1ccb476a278d', 'INSUFFICIENT',
   'Apporter son repas, c''est moins cher et plus sain. Acheter dehors, c''est plus rapide, on sort un peu, on change d''air. Après ça dépend des gens, des horaires, du quartier, de ce qu''on aime manger.',
   'La réponse énumère puis se dilue : aucune conclusion n''est prise.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C8-S4 / EXPECTED
  ('819e1ffe-da36-5b93-a334-c87e6fa96079', '694acd25-5238-56f1-9129-1ccb476a278d', 'EXPECTED',
   'Je conseille d''apporter son repas. D''abord parce qu''on maîtrise ce qu''on mange et ce qu''on dépense. Par exemple, je prépare le dimanche pour trois midis, et ça me coûte moins de trois euros par jour. Donc c''est vraiment ce que je recommanderais.',
   'L''enchaînement est complet, avec un exemple chiffré bien placé.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C8-S4 / EXCELLENT
  ('a6d915a9-ea70-511f-866b-33882d5e38c3', '694acd25-5238-56f1-9129-1ccb476a278d', 'EXCELLENT',
   'Mon conseil, c''est d''apporter son repas. La raison principale, c''est le contrôle : sur le contenu de l''assiette comme sur le budget. Par exemple, je cuisine le dimanche pour trois midis, ce qui me revient à moins de trois euros par jour, contre dix à la boulangerie d''en bas. Au final, ce n''est pas seulement une question d''argent : c''est une pause de midi où je ne cours pas.',
   'La conclusion ajoute un bénéfice nouveau tout en restant dans le sujet.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C8-S5 / INSUFFICIENT
  ('162e0ca8-d6cc-56db-90c8-e7668610ee80', '6926dbb1-6d8b-5333-8c3b-9f195c64f380', 'INSUFFICIENT',
   'Le tourisme amène de l''argent, des emplois, des restaurants. Mais les loyers montent, il y a du bruit, les commerces changent. Les habitants sont partagés, il y a du positif et du négatif, c''est compliqué à dire.',
   'Deux listes se répondent, mais aucune position n''est tenue ni conclue.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C8-S5 / EXPECTED
  ('d4689c87-3741-5662-a5cf-821f24d934ab', '6926dbb1-6d8b-5333-8c3b-9f195c64f380', 'EXPECTED',
   'Je pense que c''est plutôt une bonne chose, à condition d''encadrer. La raison, c''est que le tourisme fait vivre beaucoup de familles. Par exemple, dans la ville où j''habitais, la moitié des commerces du centre fermait en hiver sans les visiteurs. Donc oui, mais avec des règles sur les locations.',
   'Position, raison, exemple, conclusion nuancée : tout est en place.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO3-C8-S5 / EXCELLENT
  ('3d07eaee-648a-5209-98e0-ac13ad439b89', '6926dbb1-6d8b-5333-8c3b-9f195c64f380', 'EXCELLENT',
   'Ma réponse est oui, mais un oui encadré. Ce qui me convainc, c''est que le tourisme maintient une activité toute l''année dans des villes moyennes qui, sinon, se videraient. Par exemple, dans la ville où j''ai vécu, la moitié des commerces du centre baissait le rideau en hiver dès que les visiteurs partaient. Donc le vrai sujet n''est pas d''en avoir moins, c''est de décider ce qu''on en fait, en commençant par le logement.',
   'Le propos progresse et la conclusion déplace la question sans la fuir.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02');
