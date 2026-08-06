-- ============================================================================
-- V303 — Competences TCF : EO1 « Entretien dirige : parler de soi »
--
-- Seed du module « Competences » pour la tache EO1 (EO).
-- 8 competences, 40 petits sujets, 120 references.
--
-- Tables : skills, skill_prompts, skill_references (DDL en V025).
--
-- FICHIER GENERE — NE PAS EDITER A LA MAIN.
--
--   cd backend_sejourfr && python3 tools/competences/generer_seed.py
--
-- On edite la fiche de contenu tools/competences/contenu/EO1.json,
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
  -- EO1-C1 — Se présenter avec les informations essentielles
  ('efc651c0-ebcf-5fad-bd93-41597e1ab042', 'EO', 'EO1', 'EO1-C1', 'Se présenter avec les informations essentielles',
   'Vous apprenez à vous présenter en donnant les informations vraiment utiles : qui vous êtes, ce que vous faites, où vous vivez. Au TCF, l''entretien commence toujours par là : une présentation complète met l''examinateur en confiance dès les premières secondes.',
   'Donner une présentation personnelle courte, claire et adaptée à la question.',
   'A2', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C2 — Répondre directement à une question personnelle
  ('d5ab2eff-d292-5b71-8357-087a1a43618d', 'EO', 'EO1', 'EO1-C2', 'Répondre directement à une question personnelle',
   'Vous apprenez à répondre vraiment à la question posée, au lieu de dire seulement « oui », « non » ou de parler d''autre chose. Au TCF, une réponse directe suivie d''une courte explication montre tout de suite que vous avez compris.',
   'Éviter les réponses hors sujet ou limitées à « oui », « non » ou un seul mot.',
   'A2', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C3 — Développer une réponse avec une précision
  ('c2779ba8-d1eb-5ece-a141-da1a060d23d2', 'EO', 'EO1', 'EO1-C3', 'Développer une réponse avec une précision',
   'Vous apprenez à ajouter un détail utile à votre réponse : quand, où, avec qui, à quelle fréquence ou pourquoi. Au TCF, c''est cette petite précision qui transforme une réponse minimale en réponse convaincante.',
   'Ajouter un détail utile : quand, où, avec qui, à quelle fréquence ou pourquoi.',
   'A2', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C4 — Parler de son quotidien
  ('a54ff295-7eea-597c-9010-7e31262c1f24', 'EO', 'EO1', 'EO1-C4', 'Parler de son quotidien',
   'Vous apprenez à décrire vos habitudes et vos horaires dans un ordre que l''examinateur suit facilement. Au TCF, les mots comme « d''abord », « après », « vers huit heures » rendent votre journée compréhensible sans effort.',
   'Décrire ses habitudes, ses horaires ou une journée habituelle dans un ordre compréhensible.',
   'A2', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C5 — Décrire son entourage ou son environnement
  ('dd958627-f768-5dd4-90c8-247f40c0c124', 'EO', 'EO1', 'EO1-C5', 'Décrire son entourage ou son environnement',
   'Vous apprenez à décrire votre famille, votre logement, votre quartier ou votre lieu de travail avec des informations concrètes. Au TCF, deux détails réels valent mieux qu''une longue phrase générale comme « c''est très bien ».',
   'Parler simplement de sa famille, de son logement, de son quartier ou de son lieu de travail.',
   'A2', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C6 — Raconter brièvement une expérience passée
  ('28d9cf86-6477-52b3-907e-eafc44ab95cd', 'EO', 'EO1', 'EO1-C6', 'Raconter brièvement une expérience passée',
   'Vous apprenez à raconter un événement court en disant quand c''était et ce qui s''est passé, dans l''ordre. Au TCF, l''examinateur demande souvent un souvenir récent : un petit récit clair vaut mieux qu''une phrase isolée.',
   'Répondre à une question personnelle en racontant un événement court et compréhensible.',
   'A2', 6, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C7 — Parler de ses projets futurs
  ('d4ae8ef5-ae01-5802-b8ee-737ff8284599', 'EO', 'EO1', 'EO1-C7', 'Parler de ses projets futurs',
   'Vous apprenez à exprimer une intention ou un objectif et à le rendre concret : quand, comment ou pourquoi. Au TCF, dire « je voudrais travailler » suffit rarement ; une précision montre que votre projet existe vraiment.',
   'Exprimer une intention, un projet ou un objectif et donner une précision.',
   'A2', 7, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C8 — Réagir à une relance et maintenir l'échange
  ('5104b4b5-df87-503d-8d9b-4b6d19b619f1', 'EO', 'EO1', 'EO1-C8', 'Réagir à une relance et maintenir l''échange',
   'Vous apprenez à comprendre une demande de précision et à compléter votre réponse sans répéter ce que vous venez de dire. Au TCF, l''examinateur relance presque toujours : c''est le moment d''apporter une information nouvelle.',
   'Comprendre une demande de précision, compléter sa réponse et continuer naturellement.',
   'A2', 8, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02');

INSERT INTO skill_prompts (id, skill_id, section, code, title, context, instruction,
                           unique_criterion, recommended_min_words, recommended_max_words,
                           recommended_duration_seconds, difficulty_level, display_order,
                           is_active, created_at, updated_at)
VALUES
  -- EO1-C1-S1 — EASY — Première question de l'examinateur
  ('993e9d2f-fe45-55ee-ba9d-93772696acaa', 'efc651c0-ebcf-5fad-bd93-41597e1ab042', 'EO', 'EO1-C1-S1', 'Première question de l''examinateur',
   'L''entretien commence. L''examinateur vous accueille et vous demande de vous présenter.',
   'Répondez à la question : « Bonjour, pouvez-vous vous présenter ? » Donnez votre prénom, votre situation actuelle et la ville où vous habitez.',
   'Donner les trois informations demandées : prénom, situation actuelle, ville.',
   NULL, NULL, 25, 'EASY', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C1-S2 — EASY — Se présenter à une association
  ('b6ebfa6e-f0f3-5fa2-9602-3abd0d893424', 'efc651c0-ebcf-5fad-bd93-41597e1ab042', 'EO', 'EO1-C1-S2', 'Se présenter à une association',
   'Vous participez à la première séance d''une association sportive de votre ville. L''animateur demande à chacun de se présenter au groupe.',
   'Répondez à la question : « Et vous, vous pouvez vous présenter en quelques mots ? » Dites votre prénom, ce que vous faites dans la vie et pourquoi vous venez dans cette association.',
   'Donner son prénom, son occupation et la raison de sa venue.',
   NULL, NULL, 25, 'EASY', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C1-S3 — MEDIUM — Nouveau dans l'équipe
  ('f6c68d94-ab10-53bc-aefd-9fe95e52c366', 'efc651c0-ebcf-5fad-bd93-41597e1ab042', 'EO', 'EO1-C1-S3', 'Nouveau dans l''équipe',
   'C''est votre premier jour dans une entreprise. Votre responsable vous demande de vous présenter devant vos nouveaux collègues.',
   'Répondez à la question : « Vous voulez bien vous présenter à l''équipe ? » Donnez votre prénom, votre poste et une information sur votre expérience.',
   'Donner son prénom, son poste et une information sur son expérience.',
   NULL, NULL, 30, 'MEDIUM', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C1-S4 — MEDIUM — Inscription à un atelier
  ('cb770840-da4f-558f-8098-a0bd47a443db', 'efc651c0-ebcf-5fad-bd93-41597e1ab042', 'EO', 'EO1-C1-S4', 'Inscription à un atelier',
   'Vous vous inscrivez à un atelier de cuisine organisé par la maison de quartier. La personne à l''accueil vous demande de vous présenter rapidement.',
   'Répondez à la question : « Vous pouvez me dire qui vous êtes et depuis combien de temps vous habitez le quartier ? » Donnez votre prénom, votre situation et depuis quand vous vivez ici.',
   'Donner son prénom, sa situation et depuis quand on habite le quartier.',
   NULL, NULL, 30, 'MEDIUM', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C1-S5 — HARD — Présentation pour un stage
  ('8bfc66a7-819a-5d45-93f4-cae3bf3df543', 'efc651c0-ebcf-5fad-bd93-41597e1ab042', 'EO', 'EO1-C1-S5', 'Présentation pour un stage',
   'Vous rencontrez la responsable d''une structure qui propose des stages. Elle vous demande de vous présenter avant de parler du poste.',
   'Répondez à la question : « Présentez-vous, s''il vous plaît. » Donnez votre prénom, votre formation, votre expérience et ce que vous cherchez.',
   'Donner quatre informations : prénom, formation, expérience et objectif.',
   NULL, NULL, 45, 'HARD', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C2-S1 — EASY — Aimer son quartier
  ('b146bf08-a860-59fd-b446-9a72a6924fac', 'd5ab2eff-d292-5b71-8357-087a1a43618d', 'EO', 'EO1-C2-S1', 'Aimer son quartier',
   'L''examinateur vous pose une question simple sur l''endroit où vous vivez.',
   'Répondez à la question : « Est-ce que vous aimez votre quartier ? » Répondez clairement par oui ou par non, puis expliquez brièvement.',
   'Répondre clairement à la question posée et donner une raison.',
   NULL, NULL, 25, 'EASY', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C2-S2 — EASY — Faire du sport ou non
  ('e9e29f09-0cfa-5a82-98e6-12bc4f0c2453', 'd5ab2eff-d292-5b71-8357-087a1a43618d', 'EO', 'EO1-C2-S2', 'Faire du sport ou non',
   'L''examinateur s''intéresse à vos activités physiques.',
   'Répondez à la question : « Est-ce que vous faites du sport ? » Répondez directement et dites lequel, ou expliquez pourquoi vous n''en faites pas.',
   'Répondre directement par oui ou non et compléter par une information utile.',
   NULL, NULL, 25, 'EASY', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C2-S3 — MEDIUM — Cuisiner ou aller au restaurant
  ('d71dd68e-9ec4-5a1e-8c30-190a71067150', 'd5ab2eff-d292-5b71-8357-087a1a43618d', 'EO', 'EO1-C2-S3', 'Cuisiner ou aller au restaurant',
   'L''examinateur vous interroge sur vos habitudes alimentaires.',
   'Répondez à la question : « Est-ce que vous préférez cuisiner chez vous ou manger au restaurant ? » Annoncez votre choix et expliquez-le.',
   'Annoncer clairement son choix entre les deux possibilités et le justifier.',
   NULL, NULL, 30, 'MEDIUM', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C2-S4 — MEDIUM — Les transports en commun
  ('0d1a0c9f-0f4e-5e5f-ac3d-4aac8203ddd2', 'd5ab2eff-d292-5b71-8357-087a1a43618d', 'EO', 'EO1-C2-S4', 'Les transports en commun',
   'L''examinateur vous pose une question sur vos déplacements dans la ville.',
   'Répondez à la question : « Est-ce que vous utilisez les transports en commun ? » Répondez directement et expliquez comment vous vous déplacez.',
   'Répondre directement à la question et préciser son mode de déplacement.',
   NULL, NULL, 30, 'MEDIUM', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C2-S5 — HARD — Votre travail vous plaît-il
  ('efdbadc8-cb80-54c7-8e97-e00db015034c', 'd5ab2eff-d292-5b71-8357-087a1a43618d', 'EO', 'EO1-C2-S5', 'Votre travail vous plaît-il',
   'L''examinateur vous interroge sur votre activité professionnelle actuelle ou passée.',
   'Répondez à la question : « Est-ce que votre travail vous plaît ? » Prenez position clairement et expliquez ce qui vous plaît ou ce qui est difficile.',
   'Prendre position clairement sur la question et expliquer avec au moins deux éléments.',
   NULL, NULL, 40, 'HARD', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C3-S1 — EASY — Vos week-ends
  ('3a6acd6d-9984-5514-b950-4049041985de', 'c2779ba8-d1eb-5ece-a141-da1a060d23d2', 'EO', 'EO1-C3-S1', 'Vos week-ends',
   'L''examinateur vous pose une question sur votre temps libre.',
   'Répondez à la question : « Que faites-vous le week-end ? » Donnez une activité et au moins une précision : quand, où ou avec qui.',
   'Donner une activité et au moins une précision.',
   NULL, NULL, 30, 'EASY', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C3-S2 — EASY — Ce que vous aimez manger
  ('059160bf-c510-56c9-ba31-80e28194f719', 'c2779ba8-d1eb-5ece-a141-da1a060d23d2', 'EO', 'EO1-C3-S2', 'Ce que vous aimez manger',
   'L''examinateur vous interroge sur vos goûts alimentaires.',
   'Répondez à la question : « Qu''est-ce que vous aimez manger ? » Nommez un plat et ajoutez une précision : quand vous le mangez, avec qui ou pourquoi vous l''aimez.',
   'Nommer un plat et ajouter au moins une précision.',
   NULL, NULL, 30, 'EASY', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C3-S3 — MEDIUM — Aller au travail
  ('28911009-6ee7-56f8-bcdf-cefcd71aff91', 'c2779ba8-d1eb-5ece-a141-da1a060d23d2', 'EO', 'EO1-C3-S3', 'Aller au travail',
   'L''examinateur vous pose une question sur vos trajets quotidiens.',
   'Répondez à la question : « Comment allez-vous au travail ? » Donnez votre moyen de transport et au moins une précision : la durée, l''horaire ou le trajet.',
   'Donner son moyen de transport et au moins une précision.',
   NULL, NULL, 35, 'MEDIUM', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C3-S4 — MEDIUM — Faire ses courses
  ('fd031079-a922-5fe7-beac-425e2d0b5787', 'c2779ba8-d1eb-5ece-a141-da1a060d23d2', 'EO', 'EO1-C3-S4', 'Faire ses courses',
   'L''examinateur s''intéresse à votre organisation quotidienne.',
   'Répondez à la question : « Où est-ce que vous faites vos courses ? » Nommez l''endroit et ajoutez au moins une précision : quand, à quelle fréquence ou pourquoi là.',
   'Nommer l''endroit et ajouter au moins une précision.',
   NULL, NULL, 35, 'MEDIUM', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C3-S5 — HARD — Apprendre quelque chose
  ('b6298e28-9a9c-5b40-9585-70b904df3ef0', 'c2779ba8-d1eb-5ece-a141-da1a060d23d2', 'EO', 'EO1-C3-S5', 'Apprendre quelque chose',
   'L''examinateur vous interroge sur ce que vous apprenez en ce moment.',
   'Répondez à la question : « Est-ce que vous apprenez quelque chose en ce moment ? » Dites quoi et donnez deux précisions : depuis quand, où, comment ou pourquoi.',
   'Nommer ce que l''on apprend et donner au moins deux précisions.',
   NULL, NULL, 45, 'HARD', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C4-S1 — EASY — Votre matinée habituelle
  ('03de11fd-3357-5b92-b445-a6cb0788f1df', 'a54ff295-7eea-597c-9010-7e31262c1f24', 'EO', 'EO1-C4-S1', 'Votre matinée habituelle',
   'L''examinateur veut savoir comment se passent vos matins.',
   'Répondez à la question : « Que faites-vous habituellement le matin ? » Racontez au moins trois actions dans l''ordre.',
   'Enchaîner au moins trois actions habituelles dans un ordre clair.',
   NULL, NULL, 35, 'EASY', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C4-S2 — EASY — Vos soirées
  ('fbebe3e6-3ae2-5f2b-9c76-183d9904fd60', 'a54ff295-7eea-597c-9010-7e31262c1f24', 'EO', 'EO1-C4-S2', 'Vos soirées',
   'L''examinateur vous interroge sur la fin de votre journée.',
   'Répondez à la question : « Que faites-vous le soir après le travail ? » Racontez vos habitudes du soir dans l''ordre.',
   'Décrire au moins trois habitudes du soir dans un ordre compréhensible.',
   NULL, NULL, 35, 'EASY', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C4-S3 — MEDIUM — Un dimanche ordinaire
  ('9fd4d95f-af49-5463-b631-950d8584dbf2', 'a54ff295-7eea-597c-9010-7e31262c1f24', 'EO', 'EO1-C4-S3', 'Un dimanche ordinaire',
   'L''examinateur veut savoir comment vous occupez votre jour de repos.',
   'Répondez à la question : « Comment se passe un dimanche ordinaire pour vous ? » Racontez votre journée du matin au soir.',
   'Couvrir les différents moments de la journée dans l''ordre, du matin au soir.',
   NULL, NULL, 45, 'MEDIUM', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C4-S4 — MEDIUM — Votre semaine de travail
  ('1c4f4124-161f-51aa-bf7b-271ec2dbeb7a', 'a54ff295-7eea-597c-9010-7e31262c1f24', 'EO', 'EO1-C4-S4', 'Votre semaine de travail',
   'L''examinateur s''intéresse à l''organisation de votre semaine.',
   'Répondez à la question : « Comment est organisée votre semaine ? » Parlez de vos horaires et de vos jours de travail ou de cours.',
   'Décrire ses horaires et ses jours de manière ordonnée et compréhensible.',
   NULL, NULL, 45, 'MEDIUM', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C4-S5 — HARD — Une journée bien remplie
  ('38011a05-5773-5e19-b5ec-e21a0b886176', 'a54ff295-7eea-597c-9010-7e31262c1f24', 'EO', 'EO1-C4-S5', 'Une journée bien remplie',
   'L''examinateur vous demande de raconter une journée où vous avez beaucoup de choses à faire.',
   'Répondez à la question : « Racontez-moi une journée où vous avez beaucoup de choses à organiser. » Enchaînez vos activités dans l''ordre et dites comment vous vous organisez.',
   'Enchaîner au moins cinq activités dans l''ordre en marquant clairement les moments.',
   NULL, NULL, 55, 'HARD', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C5-S1 — EASY — Votre quartier en deux détails
  ('b2397bd5-c600-52f0-984f-43ea8367b189', 'dd958627-f768-5dd4-90c8-247f40c0c124', 'EO', 'EO1-C5-S1', 'Votre quartier en deux détails',
   'L''examinateur vous demande de parler de l''endroit où vous habitez.',
   'Répondez à la question : « Pouvez-vous décrire votre quartier ? » Donnez au moins deux informations concrètes : commerces, transports, ambiance, lieux.',
   'Donner au moins deux informations concrètes sur le quartier.',
   NULL, NULL, 30, 'EASY', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C5-S2 — EASY — Votre logement
  ('8297a512-f987-5491-8898-9981c5f5aa37', 'dd958627-f768-5dd4-90c8-247f40c0c124', 'EO', 'EO1-C5-S2', 'Votre logement',
   'L''examinateur s''intéresse à l''endroit où vous vivez.',
   'Répondez à la question : « Comment est votre logement ? » Donnez au moins deux informations concrètes : type, pièces, étage, luminosité.',
   'Donner au moins deux informations concrètes sur le logement.',
   NULL, NULL, 30, 'EASY', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C5-S3 — MEDIUM — Une personne proche
  ('599a5f4f-5e8a-5f56-b338-01a144ad671a', 'dd958627-f768-5dd4-90c8-247f40c0c124', 'EO', 'EO1-C5-S3', 'Une personne proche',
   'L''examinateur vous demande de parler d''une personne importante pour vous.',
   'Répondez à la question : « Parlez-moi d''une personne proche de vous. » Dites qui c''est et donnez au moins deux informations : ce qu''elle fait, son caractère, ce que vous faites ensemble.',
   'Identifier la personne et donner au moins deux informations concrètes sur elle.',
   NULL, NULL, 35, 'MEDIUM', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C5-S4 — MEDIUM — Votre lieu de travail
  ('32d344ee-0071-5dcd-9d40-68a6231baa50', 'dd958627-f768-5dd4-90c8-247f40c0c124', 'EO', 'EO1-C5-S4', 'Votre lieu de travail',
   'L''examinateur veut se représenter l''endroit où vous travaillez ou étudiez.',
   'Répondez à la question : « Comment est votre lieu de travail ou votre lieu d''études ? » Donnez au moins trois informations concrètes : taille, équipe, ambiance, organisation.',
   'Donner au moins trois informations concrètes sur ce lieu.',
   NULL, NULL, 40, 'MEDIUM', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C5-S5 — HARD — Présenter votre ville à un ami
  ('7a1578c2-51b0-5ff1-a6d3-f222922f6e03', 'dd958627-f768-5dd4-90c8-247f40c0c124', 'EO', 'EO1-C5-S5', 'Présenter votre ville à un ami',
   'L''examinateur vous demande de présenter votre ville comme si un ami venait vous rendre visite pour la première fois.',
   'Répondez à la question : « Comment décririez-vous votre ville à quelqu''un qui ne la connaît pas ? » Donnez au moins trois informations concrètes et dites ce que vous lui feriez découvrir.',
   'Donner au moins trois informations concrètes sur la ville et proposer un lieu à découvrir.',
   NULL, NULL, 50, 'HARD', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C6-S1 — EASY — Une sortie récente
  ('777c8de5-6ddd-5d02-b0b0-f4071fd91647', '28d9cf86-6477-52b3-907e-eafc44ab95cd', 'EO', 'EO1-C6-S1', 'Une sortie récente',
   'L''examinateur vous interroge sur vos loisirs des dernières semaines.',
   'Répondez à la question : « Parlez-moi d''une sortie que vous avez faite récemment. » Dites quand c''était et racontez au moins deux actions dans l''ordre.',
   'Situer le moment de la sortie et raconter au moins deux actions dans l''ordre.',
   NULL, NULL, 35, 'EASY', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C6-S2 — EASY — Un repas de fête
  ('2074e7c7-7b32-510a-a8d7-1a75a89727bd', '28d9cf86-6477-52b3-907e-eafc44ab95cd', 'EO', 'EO1-C6-S2', 'Un repas de fête',
   'L''examinateur vous demande de parler d''une occasion où vous avez mangé avec d''autres personnes.',
   'Répondez à la question : « Racontez-moi un repas de fête auquel vous avez participé. » Dites quand c''était, avec qui, et racontez deux ou trois moments.',
   'Situer le moment et raconter au moins deux moments du repas dans l''ordre.',
   NULL, NULL, 35, 'EASY', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C6-S3 — MEDIUM — Un rendez-vous médical
  ('b7c2f0d0-8cdb-50b2-aedc-75efc91a12f8', '28d9cf86-6477-52b3-907e-eafc44ab95cd', 'EO', 'EO1-C6-S3', 'Un rendez-vous médical',
   'L''examinateur vous demande de raconter une démarche liée à votre santé.',
   'Répondez à la question : « Racontez-moi votre dernier rendez-vous chez le médecin. » Dites quand c''était et racontez comment le rendez-vous s''est passé, étape par étape.',
   'Situer le moment et raconter au moins trois étapes du rendez-vous dans l''ordre.',
   NULL, NULL, 45, 'MEDIUM', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C6-S4 — MEDIUM — Un déplacement compliqué
  ('6f50b544-6803-5392-950f-f220133e44a5', '28d9cf86-6477-52b3-907e-eafc44ab95cd', 'EO', 'EO1-C6-S4', 'Un déplacement compliqué',
   'L''examinateur vous demande de raconter un trajet qui ne s''est pas passé comme prévu.',
   'Répondez à la question : « Racontez-moi un voyage ou un trajet difficile. » Dites quand c''était, ce qui s''est passé et comment cela s''est terminé.',
   'Situer le moment, raconter le problème et dire comment la situation s''est terminée.',
   NULL, NULL, 45, 'MEDIUM', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C6-S5 — HARD — Votre premier jour
  ('4415d427-0a8c-5417-bd41-eaac6143ea1d', '28d9cf86-6477-52b3-907e-eafc44ab95cd', 'EO', 'EO1-C6-S5', 'Votre premier jour',
   'L''examinateur vous demande de raconter un début important pour vous : un premier jour de travail, de formation ou de cours.',
   'Répondez à la question : « Racontez-moi votre premier jour de travail ou de formation. » Dites quand c''était, racontez le déroulement et expliquez ce que vous avez ressenti.',
   'Situer le moment, raconter au moins trois étapes dans l''ordre et exprimer un ressenti.',
   NULL, NULL, 55, 'HARD', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C7-S1 — EASY — L'année prochaine
  ('751eb297-c3d8-5f66-8da3-ceb4174d2e8a', 'd4ae8ef5-ae01-5802-b8ee-737ff8284599', 'EO', 'EO1-C7-S1', 'L''année prochaine',
   'L''examinateur vous interroge sur vos intentions pour la période à venir.',
   'Répondez à la question : « Qu''est-ce que vous aimeriez faire l''année prochaine ? » Donnez un projet et au moins une précision.',
   'Exprimer un projet et donner au moins une précision.',
   NULL, NULL, 30, 'EASY', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C7-S2 — EASY — Vos prochaines vacances
  ('d3ce3ff8-dfa5-5ec7-a86a-81a833c4e691', 'd4ae8ef5-ae01-5802-b8ee-737ff8284599', 'EO', 'EO1-C7-S2', 'Vos prochaines vacances',
   'L''examinateur vous demande de parler de vos projets de vacances.',
   'Répondez à la question : « Qu''allez-vous faire pendant vos prochaines vacances ? » Donnez votre projet et au moins une précision : quand, où ou avec qui.',
   'Exprimer un projet de vacances et donner au moins une précision.',
   NULL, NULL, 30, 'EASY', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C7-S3 — MEDIUM — Une formation à venir
  ('84c1a231-9595-5f9f-9211-66b815138c72', 'd4ae8ef5-ae01-5802-b8ee-737ff8284599', 'EO', 'EO1-C7-S3', 'Une formation à venir',
   'L''examinateur s''intéresse à ce que vous voulez apprendre.',
   'Répondez à la question : « Est-ce que vous avez un projet de formation ou d''études ? » Dites lequel et donnez deux précisions : quand, où ou pourquoi.',
   'Nommer un projet de formation et donner au moins deux précisions.',
   NULL, NULL, 40, 'MEDIUM', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C7-S4 — MEDIUM — Changer de logement
  ('e70702d7-7f1e-53b7-9171-c23b7bb8a1c8', 'd4ae8ef5-ae01-5802-b8ee-737ff8284599', 'EO', 'EO1-C7-S4', 'Changer de logement',
   'L''examinateur vous demande si vous envisagez de déménager.',
   'Répondez à la question : « Est-ce que vous pensez changer de logement bientôt ? » Donnez votre intention et expliquez avec deux précisions.',
   'Exprimer une intention claire sur le logement et donner au moins deux précisions.',
   NULL, NULL, 40, 'MEDIUM', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C7-S5 — HARD — Votre projet professionnel
  ('4033c19f-60d9-58ab-a933-4f1703c3fc71', 'd4ae8ef5-ae01-5802-b8ee-737ff8284599', 'EO', 'EO1-C7-S5', 'Votre projet professionnel',
   'L''examinateur vous demande où vous voulez en être dans quelques années.',
   'Répondez à la question : « Que voudriez-vous faire dans deux ou trois ans ? » Exprimez votre objectif et expliquez au moins deux étapes pour y arriver.',
   'Exprimer un objectif à moyen terme et nommer au moins deux étapes pour l''atteindre.',
   NULL, NULL, 50, 'HARD', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C8-S1 — EASY — L'examinateur demande pourquoi
  ('b59be02e-ca03-5d38-8338-e3686b7681d1', '5104b4b5-df87-503d-8d9b-4b6d19b619f1', 'EO', 'EO1-C8-S1', 'L''examinateur demande pourquoi',
   'Vous venez de dire : « J''aime bien mon quartier. » L''examinateur veut en savoir plus.',
   'L''examinateur vous relance : « Pourquoi ? » Répondez en donnant une raison nouvelle, sans répéter votre phrase précédente.',
   'Donner une raison qui apporte une information nouvelle.',
   NULL, NULL, 25, 'EASY', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C8-S2 — EASY — Avec qui faites-vous ça
  ('ef89ae26-3fd1-5247-8118-87e56e2f896b', '5104b4b5-df87-503d-8d9b-4b6d19b619f1', 'EO', 'EO1-C8-S2', 'Avec qui faites-vous ça',
   'Vous venez de dire : « Le dimanche, je fais de la randonnée. » L''examinateur veut une précision.',
   'L''examinateur vous relance : « Avec qui ? » Répondez en apportant une information nouvelle sur les personnes qui vous accompagnent.',
   'Répondre à la relance en donnant une information nouvelle sur les personnes.',
   NULL, NULL, 25, 'EASY', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C8-S3 — MEDIUM — Depuis quand
  ('90ca0e8e-6bfb-5ba4-96bc-7702193c6da1', '5104b4b5-df87-503d-8d9b-4b6d19b619f1', 'EO', 'EO1-C8-S3', 'Depuis quand',
   'Vous venez de dire : « Je travaille dans un restaurant. » L''examinateur demande une précision de durée.',
   'L''examinateur vous relance : « Et depuis quand ? » Répondez à la relance et ajoutez une information nouvelle sur cette période.',
   'Indiquer la durée demandée et ajouter une information nouvelle.',
   NULL, NULL, 30, 'MEDIUM', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C8-S4 — MEDIUM — Est-ce que c'est facile
  ('440ca805-b378-59a4-bdab-63b8c928ca5d', '5104b4b5-df87-503d-8d9b-4b6d19b619f1', 'EO', 'EO1-C8-S4', 'Est-ce que c''est facile',
   'Vous venez de dire : « Je suis des cours de français le soir. » L''examinateur veut savoir comment cela se passe.',
   'L''examinateur vous relance : « Et ce n''est pas trop difficile ? » Répondez clairement et expliquez avec au moins deux éléments nouveaux.',
   'Répondre clairement à la relance et apporter au moins deux éléments nouveaux.',
   NULL, NULL, 35, 'MEDIUM', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C8-S5 — HARD — Le conseilleriez-vous
  ('7a6b7b72-2383-5acb-9c80-97f1286761e3', '5104b4b5-df87-503d-8d9b-4b6d19b619f1', 'EO', 'EO1-C8-S5', 'Le conseilleriez-vous',
   'Vous venez de parler d''une activité que vous pratiquez, par exemple un sport ou une activité associative. L''examinateur pousse l''échange un peu plus loin.',
   'L''examinateur vous relance : « Et vous le conseilleriez à quelqu''un ? » Prenez position, justifiez et dites à qui vous le conseilleriez.',
   'Prendre position sur la relance, justifier et préciser à qui le conseil s''adresse.',
   NULL, NULL, 45, 'HARD', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02');

INSERT INTO skill_references (id, skill_prompt_id, level, text, pedagogical_note,
                              created_at, updated_at)
VALUES
  -- EO1-C1-S1 / INSUFFICIENT
  ('b2005111-91bd-5023-a4ea-bb4aa62629ea', '993e9d2f-fe45-55ee-ba9d-93772696acaa', 'INSUFFICIENT',
   'Bonjour, je m''appelle Amina. Voilà.',
   'Seul le prénom est donné : la situation et la ville manquent.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C1-S1 / EXPECTED
  ('9d9c3a34-d568-5318-807f-a170387cd29a', '993e9d2f-fe45-55ee-ba9d-93772696acaa', 'EXPECTED',
   'Bonjour, je m''appelle Amina. Je travaille dans un magasin et j''habite à Lyon.',
   'Les trois informations demandées sont présentes et claires.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C1-S1 / EXCELLENT
  ('fd69ec8a-b068-5145-8efe-983e70c4de05', '993e9d2f-fe45-55ee-ba9d-93772696acaa', 'EXCELLENT',
   'Bonjour, je m''appelle Amina. Je suis vendeuse dans un magasin de vêtements et j''habite à Lyon, dans le troisième arrondissement.',
   'Chaque information est précisée : métier exact et quartier.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C1-S2 / INSUFFICIENT
  ('ee4d215d-ba16-5baf-a4a0-b8e41729a72b', 'b6ebfa6e-f0f3-5fa2-9602-3abd0d893424', 'INSUFFICIENT',
   'Je m''appelle Karim et je suis content d''être ici.',
   'L''occupation et la raison de la venue ne sont pas données.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C1-S2 / EXPECTED
  ('3ee42b91-dc38-5fe7-90d1-f8a01d02c0df', 'b6ebfa6e-f0f3-5fa2-9602-3abd0d893424', 'EXPECTED',
   'Bonjour, je m''appelle Karim. Je suis cuisinier et je viens ici pour faire du sport et rencontrer des gens.',
   'Prénom, occupation et raison sont bien présents.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C1-S2 / EXCELLENT
  ('ccde186d-8406-50d0-a876-d7e1c31727bd', 'b6ebfa6e-f0f3-5fa2-9602-3abd0d893424', 'EXCELLENT',
   'Bonjour, je m''appelle Karim, je suis cuisinier dans un restaurant du centre. Je viens ici parce que je travaille beaucoup le soir et je veux bouger un peu la journée.',
   'La raison est expliquée avec un détail personnel concret.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C1-S3 / INSUFFICIENT
  ('e7be8b14-0bb3-5792-b931-948a23242013', 'f6c68d94-ab10-53bc-aefd-9fe95e52c366', 'INSUFFICIENT',
   'Bonjour tout le monde, moi c''est Elena. Je suis très contente de commencer avec vous.',
   'Le poste et l''expérience ne sont pas mentionnés.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C1-S3 / EXPECTED
  ('aea0d548-5faa-55eb-b7b8-ff34a83a6759', 'f6c68d94-ab10-53bc-aefd-9fe95e52c366', 'EXPECTED',
   'Bonjour, je m''appelle Elena. Je commence aujourd''hui comme assistante et j''ai déjà travaillé deux ans dans un bureau.',
   'Prénom, poste et expérience sont donnés simplement.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C1-S3 / EXCELLENT
  ('ae40ed13-589d-5d8f-9b51-17639504622b', 'f6c68d94-ab10-53bc-aefd-9fe95e52c366', 'EXCELLENT',
   'Bonjour, je m''appelle Elena, je commence aujourd''hui comme assistante administrative. Avant, j''ai travaillé deux ans dans un bureau à Marseille, surtout pour l''accueil et les dossiers.',
   'L''expérience est située et le contenu du poste précisé.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C1-S4 / INSUFFICIENT
  ('41bcaee8-fe40-5f03-b7d6-7ddff594920c', 'cb770840-da4f-558f-8098-a0bd47a443db', 'INSUFFICIENT',
   'Je m''appelle Diego et j''habite ici, pas très loin.',
   'La situation et la durée ne sont pas indiquées.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C1-S4 / EXPECTED
  ('72c3d68d-cdc6-5d7c-acf7-dd68ed726a60', 'cb770840-da4f-558f-8098-a0bd47a443db', 'EXPECTED',
   'Bonjour, je m''appelle Diego. Je suis étudiant et j''habite dans le quartier depuis un an.',
   'Les trois informations attendues sont présentes.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C1-S4 / EXCELLENT
  ('57394221-420c-537b-bac4-5b9e4c1c998c', 'cb770840-da4f-558f-8098-a0bd47a443db', 'EXCELLENT',
   'Bonjour, je m''appelle Diego. Je suis étudiant en informatique et j''habite dans le quartier depuis un an, juste à côté de la place du marché.',
   'La situation est détaillée et le lieu rendu concret.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C1-S5 / INSUFFICIENT
  ('72e19e3e-39a8-5858-8b66-fcac9d97da1c', '8bfc66a7-819a-5d45-93f4-cae3bf3df543', 'INSUFFICIENT',
   'Je m''appelle Fatou, j''ai vingt-six ans et je cherche un stage.',
   'La formation et l''expérience manquent encore.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C1-S5 / EXPECTED
  ('80bad492-b0e5-5597-81cf-da61dc4f51f3', '8bfc66a7-819a-5d45-93f4-cae3bf3df543', 'EXPECTED',
   'Bonjour, je m''appelle Fatou. Je suis une formation en comptabilité et j''ai déjà travaillé six mois dans un magasin. Je cherche un stage pour pratiquer.',
   'Les quatre informations demandées sont bien données.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C1-S5 / EXCELLENT
  ('98b7ab54-8535-52c9-b91b-d5e1be8a9764', '8bfc66a7-819a-5d45-93f4-cae3bf3df543', 'EXCELLENT',
   'Bonjour, je m''appelle Fatou. Je suis une formation en comptabilité depuis septembre et j''ai travaillé six mois dans un magasin, à la caisse. Je cherche un stage de trois mois pour apprendre à faire les factures.',
   'Chaque information porte une précision utile et l''objectif est clair.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C2-S1 / INSUFFICIENT
  ('2028be49-13b0-5da2-8865-8cecfe46fff0', 'b146bf08-a860-59fd-b446-9a72a6924fac', 'INSUFFICIENT',
   'Oui.',
   'La réponse est correcte mais trop courte : la raison manque.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C2-S1 / EXPECTED
  ('aeaaa4d0-1280-5b46-85ee-e54a670128ca', 'b146bf08-a860-59fd-b446-9a72a6924fac', 'EXPECTED',
   'Oui, j''aime bien mon quartier parce qu''il est calme.',
   'La réponse est directe et une raison est donnée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C2-S1 / EXCELLENT
  ('c17962aa-a02c-54bb-9012-f7e43ae4aa4f', 'b146bf08-a860-59fd-b446-9a72a6924fac', 'EXCELLENT',
   'Oui, j''aime beaucoup mon quartier. Il est calme et il y a un marché le samedi, donc je fais mes courses à pied.',
   'La raison est illustrée par un détail de la vie réelle.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C2-S2 / INSUFFICIENT
  ('592eaeec-6c87-5361-bea9-3201027e83cc', 'e9e29f09-0cfa-5a82-98e6-12bc4f0c2453', 'INSUFFICIENT',
   'Le sport, c''est très bon pour la santé.',
   'L''idée est juste, mais la question personnelle reste sans réponse.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C2-S2 / EXPECTED
  ('09b6cde0-d0bf-568e-bffd-202a6e471778', 'e9e29f09-0cfa-5a82-98e6-12bc4f0c2453', 'EXPECTED',
   'Oui, je fais du sport. Je vais à la piscine.',
   'La réponse est directe et l''activité est nommée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C2-S2 / EXCELLENT
  ('43f95e9d-49c9-51a5-8972-a75b133406b9', 'e9e29f09-0cfa-5a82-98e6-12bc4f0c2453', 'EXCELLENT',
   'Oui, je fais du sport. Je vais à la piscine deux fois par semaine, le mardi et le jeudi soir.',
   'L''activité est complétée par la fréquence et les jours.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C2-S3 / INSUFFICIENT
  ('c1cb1e1b-d6ac-5204-bdc3-b52c6eafb98d', 'd71dd68e-9ec4-5a1e-8c30-190a71067150', 'INSUFFICIENT',
   'Les deux sont bien, ça dépend des jours.',
   'Aucun choix n''est annoncé : la question reste ouverte.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C2-S3 / EXPECTED
  ('7bfe8220-de35-5219-9469-99a6392db3f4', 'd71dd68e-9ec4-5a1e-8c30-190a71067150', 'EXPECTED',
   'Je préfère cuisiner chez moi parce que c''est moins cher.',
   'Le choix est net et une raison le soutient.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C2-S3 / EXCELLENT
  ('2481a026-dea5-5246-bca1-2758c311e676', 'd71dd68e-9ec4-5a1e-8c30-190a71067150', 'EXCELLENT',
   'Je préfère cuisiner chez moi. C''est moins cher et je choisis mes produits. Je vais au restaurant seulement pour les anniversaires.',
   'Le choix est justifié deux fois et la limite est précisée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C2-S4 / INSUFFICIENT
  ('df8d9acf-9eda-5e0c-aba9-bf7bb349d525', '0d1a0c9f-0f4e-5e5f-ac3d-4aac8203ddd2', 'INSUFFICIENT',
   'Dans ma ville, il y a beaucoup de bus et aussi un tramway.',
   'On décrit la ville, mais on ne dit pas ce que l''on fait soi-même.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C2-S4 / EXPECTED
  ('82c60ed0-81a8-5228-b59e-411c1bad30ca', '0d1a0c9f-0f4e-5e5f-ac3d-4aac8203ddd2', 'EXPECTED',
   'Oui, j''utilise les transports en commun. Je prends le bus pour aller au travail.',
   'La réponse est personnelle, directe et complétée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C2-S4 / EXCELLENT
  ('2f69755f-b3f2-5070-8dab-ec7a9eb2e08f', '0d1a0c9f-0f4e-5e5f-ac3d-4aac8203ddd2', 'EXCELLENT',
   'Oui, tous les jours. Je prends le bus le matin pour aller au travail et parfois le tramway le soir quand je passe au marché.',
   'Deux trajets réels sont donnés avec leur moment.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C2-S5 / INSUFFICIENT
  ('0b4c4545-6d9c-5267-ac95-2990837c1072', 'efdbadc8-cb80-54c7-8e97-e00db015034c', 'INSUFFICIENT',
   'Mon travail, c''est dans un entrepôt. Je commence à sept heures du matin.',
   'Le travail est décrit, mais l''avis demandé n''apparaît pas.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C2-S5 / EXPECTED
  ('ecbe5cac-5c34-5a0a-a8ee-f549f1350e88', 'efdbadc8-cb80-54c7-8e97-e00db015034c', 'EXPECTED',
   'Oui, mon travail me plaît. J''aime bien mes collègues et les horaires sont réguliers.',
   'La position est claire et deux éléments l''expliquent.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C2-S5 / EXCELLENT
  ('8059c5d3-d72b-56ba-87ea-428576bbcb45', 'efdbadc8-cb80-54c7-8e97-e00db015034c', 'EXCELLENT',
   'Oui, globalement mon travail me plaît. J''aime bien l''équipe et les horaires sont réguliers, donc je vois mes enfants le soir. Le seul problème, c''est que je porte des choses lourdes.',
   'L''avis est net, expliqué, et une limite est reconnue simplement.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C3-S1 / INSUFFICIENT
  ('43f531e8-2a42-5350-9c82-d4d856f5587b', '3a6acd6d-9984-5514-b950-4049041985de', 'INSUFFICIENT',
   'J''aime le sport.',
   'L''activité est là, mais aucune précision ne l''accompagne.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C3-S1 / EXPECTED
  ('87238dda-dace-5f2b-9b1d-ebd575de1d46', '3a6acd6d-9984-5514-b950-4049041985de', 'EXPECTED',
   'Le week-end, je fais du sport. Le samedi matin, je joue au football.',
   'L''activité est située dans le temps : le critère est atteint.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C3-S1 / EXCELLENT
  ('23737cfa-6f60-585f-9c06-3564b3fa526c', '3a6acd6d-9984-5514-b950-4049041985de', 'EXCELLENT',
   'Le week-end, je fais du sport. Le samedi matin, je joue au football avec mes amis dans le parc à côté de chez moi.',
   'Trois précisions utiles : le moment, les personnes et le lieu.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C3-S2 / INSUFFICIENT
  ('69177c1b-44a6-5256-8b6a-e7d1d65cf368', '059160bf-c510-56c9-ba31-80e28194f719', 'INSUFFICIENT',
   'J''aime beaucoup le poisson.',
   'Le plat est donné, mais rien ne vient l''éclairer.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C3-S2 / EXPECTED
  ('770a1c08-5ac6-5dd7-b5fa-b32bf3269d11', '059160bf-c510-56c9-ba31-80e28194f719', 'EXPECTED',
   'J''aime beaucoup le poisson. Je le prépare souvent le dimanche.',
   'Une précision de fréquence et de moment est ajoutée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C3-S2 / EXCELLENT
  ('4477181a-748a-5176-8ae4-f5b8d4e06da2', '059160bf-c510-56c9-ba31-80e28194f719', 'EXCELLENT',
   'J''aime beaucoup le poisson. Je le prépare le dimanche avec du riz, parce que toute la famille mange ensemble ce jour-là.',
   'Le détail et la raison rendent la réponse vivante.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C3-S3 / INSUFFICIENT
  ('8fca6477-f85f-5583-a6f2-aa9bd39deb5b', '28911009-6ee7-56f8-bcdf-cefcd71aff91', 'INSUFFICIENT',
   'Je prends le métro.',
   'Le moyen de transport est donné sans aucune précision.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C3-S3 / EXPECTED
  ('dc1e9334-85f0-546c-89e0-5b1df65cd297', '28911009-6ee7-56f8-bcdf-cefcd71aff91', 'EXPECTED',
   'Je prends le métro. Le trajet dure environ vingt minutes.',
   'La durée précise utilement la réponse.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C3-S3 / EXCELLENT
  ('832f9f89-75b8-5300-b9d6-4b6b85687b13', '28911009-6ee7-56f8-bcdf-cefcd71aff91', 'EXCELLENT',
   'Je prends le métro à sept heures et demie et le trajet dure vingt minutes. Après, je marche cinq minutes jusqu''au bureau.',
   'L''horaire, la durée et la fin du trajet sont donnés.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C3-S4 / INSUFFICIENT
  ('ae11dbd2-a7b4-577e-8c88-adf139f64999', 'fd031079-a922-5fe7-beac-425e2d0b5787', 'INSUFFICIENT',
   'Je fais mes courses au supermarché.',
   'L''endroit est nommé, mais la précision demandée manque.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C3-S4 / EXPECTED
  ('170d52c2-ee52-569b-aff5-778fea353f75', 'fd031079-a922-5fe7-beac-425e2d0b5787', 'EXPECTED',
   'Je fais mes courses au supermarché près de chez moi, le samedi matin.',
   'Le lieu est situé et le moment indiqué.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C3-S4 / EXCELLENT
  ('01319cbc-ddd6-5ad0-9bf3-81ce0ad3d93d', 'fd031079-a922-5fe7-beac-425e2d0b5787', 'EXCELLENT',
   'Je fais mes courses au supermarché près de chez moi, le samedi matin. J''y vais tôt parce qu''il y a moins de monde et je prends tout pour la semaine.',
   'La raison du choix rend la précision très concrète.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C3-S5 / INSUFFICIENT
  ('1b1ed006-14a4-52c2-8aea-f6ace412185e', 'b6298e28-9a9c-5b40-9585-70b904df3ef0', 'INSUFFICIENT',
   'Oui, j''apprends le français en ce moment.',
   'La réponse est juste, mais elle reste sans aucune précision.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C3-S5 / EXPECTED
  ('a6e84f1a-4ed1-519b-a498-29c66aebc354', 'b6298e28-9a9c-5b40-9585-70b904df3ef0', 'EXPECTED',
   'Oui, j''apprends le français. Je suis des cours depuis six mois dans une association.',
   'La durée et le lieu apportent les précisions attendues.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C3-S5 / EXCELLENT
  ('7bbc6b63-a046-5539-b3f7-0a542b23711f', 'b6298e28-9a9c-5b40-9585-70b904df3ef0', 'EXCELLENT',
   'Oui, j''apprends le français. Je suis des cours depuis six mois dans une association du quartier, deux soirs par semaine, et je révise avec une application le matin dans le bus.',
   'Durée, lieu, rythme et méthode : la réponse est riche et simple.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C4-S1 / INSUFFICIENT
  ('07b3cccf-1d6c-5c07-9a5e-a2d34884c077', '03de11fd-3357-5b92-b445-a6cb0788f1df', 'INSUFFICIENT',
   'Le matin, je me lève tôt et je pars.',
   'Deux actions seulement, et l''ordre reste très vague.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C4-S1 / EXPECTED
  ('a430ebeb-733f-5161-b6de-014ab1f3ec10', '03de11fd-3357-5b92-b445-a6cb0788f1df', 'EXPECTED',
   'Le matin, je me lève à six heures. Je prends mon petit-déjeuner, puis je pars au travail.',
   'Trois actions se suivent dans un ordre clair.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C4-S1 / EXCELLENT
  ('2c7a3eee-10b3-5f3a-9dc3-ada687f3ad7b', '03de11fd-3357-5b92-b445-a6cb0788f1df', 'EXCELLENT',
   'Le matin, je me lève à six heures. D''abord je prends une douche, ensuite je prends mon petit-déjeuner avec ma fille, et vers sept heures je pars au travail.',
   'Les mots d''ordre et les horaires guident bien l''auditeur.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C4-S2 / INSUFFICIENT
  ('6ddb2734-9fc3-5455-ab78-5dfc008fc6f6', 'fbebe3e6-3ae2-5f2b-9c76-183d9904fd60', 'INSUFFICIENT',
   'Le soir, je suis fatigué, alors je me repose à la maison.',
   'On comprend l''ambiance, mais les actions ne sont pas racontées.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C4-S2 / EXPECTED
  ('6b7b0199-a465-5bdb-82b1-d25cb3045291', 'fbebe3e6-3ae2-5f2b-9c76-183d9904fd60', 'EXPECTED',
   'Le soir, je rentre vers dix-huit heures. Je prépare le dîner, puis je regarde un peu la télévision.',
   'Les habitudes se suivent clairement, avec un horaire.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C4-S2 / EXCELLENT
  ('627ab91f-7e45-5dc4-ab57-5ecd2944e622', 'fbebe3e6-3ae2-5f2b-9c76-183d9904fd60', 'EXCELLENT',
   'Le soir, je rentre vers dix-huit heures. D''abord je prépare le dîner, ensuite nous mangeons tous ensemble, et après je regarde une série ou j''appelle ma sœur.',
   'L''enchaînement est net et une variante habituelle est ajoutée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C4-S3 / INSUFFICIENT
  ('ecb055fa-41ca-5330-82e9-0a2089417aad', '9fd4d95f-af49-5463-b631-950d8584dbf2', 'INSUFFICIENT',
   'Le dimanche, je me repose et je vois des amis, c''est tout.',
   'La journée n''est pas découpée : on ne suit aucun déroulement.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C4-S3 / EXPECTED
  ('15279816-7392-57f8-9656-9521fde7224c', '9fd4d95f-af49-5463-b631-950d8584dbf2', 'EXPECTED',
   'Le dimanche, je me lève tard. Le matin, je fais le ménage. L''après-midi, je vois des amis et le soir je prépare mes affaires pour lundi.',
   'Les trois moments de la journée sont bien distingués.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C4-S3 / EXCELLENT
  ('87b77612-3cfc-5f40-a617-ab9a0ff4c4d3', '9fd4d95f-af49-5463-b631-950d8584dbf2', 'EXCELLENT',
   'Le dimanche, je me lève vers neuf heures. Le matin, je fais le ménage et un peu de lessive. L''après-midi, je vais au parc avec des amis quand il fait beau. Et le soir, je prépare mes vêtements pour lundi et je me couche tôt.',
   'Chaque moment porte une action précise et une petite condition.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C4-S4 / INSUFFICIENT
  ('4d81fbd2-d475-593b-913c-a0ccb1667495', '1c4f4124-161f-51aa-bf7b-271ec2dbeb7a', 'INSUFFICIENT',
   'Je travaille beaucoup pendant la semaine, c''est un peu fatigant.',
   'Ni les jours ni les horaires ne sont donnés.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C4-S4 / EXPECTED
  ('9bad3ba2-85d6-5a8a-8238-dcd758a47e2a', '1c4f4124-161f-51aa-bf7b-271ec2dbeb7a', 'EXPECTED',
   'Je travaille du lundi au vendredi, de neuf heures à dix-sept heures. Le samedi, je fais mes courses et le dimanche je me repose.',
   'Jours et horaires sont clairs et bien répartis.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C4-S4 / EXCELLENT
  ('5ec45f2f-6d64-5f9b-994e-60ee211790ec', '1c4f4124-161f-51aa-bf7b-271ec2dbeb7a', 'EXCELLENT',
   'Je travaille du lundi au vendredi, de neuf heures à dix-sept heures, avec une pause à midi. Le mardi soir, j''ai un cours de français. Le samedi, je fais mes courses le matin, et le dimanche je me repose.',
   'La semaine complète est structurée, avec une exception nommée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C4-S5 / INSUFFICIENT
  ('b7251e2c-0798-5245-88f7-c97c0d4ef81b', '38011a05-5773-5e19-b5ec-e21a0b886176', 'INSUFFICIENT',
   'Il y a des jours où j''ai vraiment beaucoup de choses à faire et je cours partout.',
   'Aucune activité concrète n''est nommée ni située.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C4-S5 / EXPECTED
  ('39ec198d-8940-58ad-a744-bcd07de7fa28', '38011a05-5773-5e19-b5ec-e21a0b886176', 'EXPECTED',
   'Le mercredi, je me lève à six heures. J''emmène les enfants à l''école, après je vais au travail. À midi, je fais les courses, et le soir je récupère les enfants et je prépare le dîner.',
   'Cinq activités s''enchaînent dans un ordre facile à suivre.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C4-S5 / EXCELLENT
  ('16a3e8e5-d2e9-59f7-9561-846da7b4ccb4', '38011a05-5773-5e19-b5ec-e21a0b886176', 'EXCELLENT',
   'Le mercredi, je me lève à six heures. D''abord j''emmène les enfants à l''école, ensuite je vais au travail jusqu''à midi. Pendant la pause, je fais les courses au magasin d''à côté pour gagner du temps. Après, je retourne au bureau. Enfin, à dix-sept heures, je récupère les enfants et je prépare le dîner.',
   'L''ordre est explicite et une stratégie d''organisation apparaît.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C5-S1 / INSUFFICIENT
  ('6d9d1f2f-2623-51a0-9644-c22452bb406d', 'b2397bd5-c600-52f0-984f-43ea8367b189', 'INSUFFICIENT',
   'Mon quartier est très bien, je l''aime beaucoup.',
   'L''avis est donné, mais aucune information concrète n''apparaît.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C5-S1 / EXPECTED
  ('afcdae99-955c-57cf-8b23-4865b69c911e', 'b2397bd5-c600-52f0-984f-43ea8367b189', 'EXPECTED',
   'Mon quartier est calme. Il y a une boulangerie et un arrêt de bus juste en bas de chez moi.',
   'Deux éléments concrets décrivent vraiment le lieu.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C5-S1 / EXCELLENT
  ('11f28bf0-7fa7-5037-8ff0-303d8ea07feb', 'b2397bd5-c600-52f0-984f-43ea8367b189', 'EXCELLENT',
   'Mon quartier est calme, surtout le soir. Il y a une boulangerie et un arrêt de bus en bas de chez moi, et un petit parc à cinq minutes où je vais le week-end.',
   'Trois détails situés donnent une image précise du quartier.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C5-S2 / INSUFFICIENT
  ('228d13eb-cd05-5061-8835-91f24563c389', '8297a512-f987-5491-8898-9981c5f5aa37', 'INSUFFICIENT',
   'J''habite dans un appartement, c''est confortable.',
   'Une seule information générale : le logement reste flou.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C5-S2 / EXPECTED
  ('d7b22f78-4583-5c69-8c96-4fac63686de6', '8297a512-f987-5491-8898-9981c5f5aa37', 'EXPECTED',
   'J''habite dans un appartement de deux pièces, au troisième étage.',
   'Deux informations précises décrivent bien le logement.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C5-S2 / EXCELLENT
  ('28af6686-f5d0-5c82-a9a3-dd7a23128dd8', '8297a512-f987-5491-8898-9981c5f5aa37', 'EXCELLENT',
   'J''habite dans un appartement de deux pièces, au troisième étage. Il y a un petit balcon et la cuisine est très claire le matin.',
   'Les détails ajoutés rendent le logement facile à imaginer.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C5-S3 / INSUFFICIENT
  ('aa40c8d6-f9f6-50cc-9b4c-fad8b1a2d489', '599a5f4f-5e8a-5f56-b338-01a144ad671a', 'INSUFFICIENT',
   'Je vais parler de ma sœur. Elle est très gentille avec moi.',
   'Une seule qualité générale : on ne sait presque rien d''elle.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C5-S3 / EXPECTED
  ('f5d569e5-995b-5d83-8212-445d401d32cc', '599a5f4f-5e8a-5f56-b338-01a144ad671a', 'EXPECTED',
   'Je vais parler de ma sœur. Elle est infirmière et elle habite à Nantes. On s''appelle souvent le dimanche.',
   'Métier, lieu et lien concret : la description est vivante.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C5-S3 / EXCELLENT
  ('bd0b04ff-7fc3-5fc7-bdb2-7cb782828001', '599a5f4f-5e8a-5f56-b338-01a144ad671a', 'EXCELLENT',
   'Je vais parler de ma sœur, Sonia. Elle est infirmière dans un hôpital à Nantes et elle travaille souvent la nuit. Elle est très calme, et on s''appelle le dimanche pour parler de la semaine.',
   'Chaque information est précisée et le lien est illustré.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C5-S4 / INSUFFICIENT
  ('89db7a67-196c-562b-86b3-1a72f8b87e78', '32d344ee-0071-5dcd-9d40-68a6231baa50', 'INSUFFICIENT',
   'Je travaille dans un magasin. C''est un bon endroit et les gens sont sympas.',
   'L''impression domine : il manque des faits concrets.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C5-S4 / EXPECTED
  ('f1260e11-9e2c-5c73-b15a-626c4686162c', '32d344ee-0071-5dcd-9d40-68a6231baa50', 'EXPECTED',
   'Je travaille dans un magasin de vêtements, dans le centre-ville. Nous sommes six personnes et le magasin ouvre à dix heures.',
   'Type, lieu, taille de l''équipe et horaire : c''est précis.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C5-S4 / EXCELLENT
  ('70977943-6dcc-5988-ba2d-a821d924b982', '32d344ee-0071-5dcd-9d40-68a6231baa50', 'EXCELLENT',
   'Je travaille dans un magasin de vêtements du centre-ville. Nous sommes six et chacun s''occupe d''un rayon. Le magasin ouvre à dix heures et le samedi est notre journée la plus chargée.',
   'L''organisation interne du lieu est expliquée, pas seulement listée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C5-S5 / INSUFFICIENT
  ('4966383c-b7ec-5ec1-a996-3f8baec78950', '7a1578c2-51b0-5ff1-a6d3-f222922f6e03', 'INSUFFICIENT',
   'Ma ville est agréable et il y a beaucoup de choses à voir, ça lui plairait sûrement.',
   'Rien de concret : ni lieu, ni détail, ni proposition.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C5-S5 / EXPECTED
  ('482569aa-9b99-5e5e-9606-a46fd28d2d8c', '7a1578c2-51b0-5ff1-a6d3-f222922f6e03', 'EXPECTED',
   'Ma ville n''est pas très grande. Il y a une rivière, un vieux centre et beaucoup de cafés. Je l''emmènerais au marché du samedi.',
   'Trois informations claires et une proposition précise.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C5-S5 / EXCELLENT
  ('bff08291-6fbf-5ab7-9bbc-9a3c89105bee', '7a1578c2-51b0-5ff1-a6d3-f222922f6e03', 'EXCELLENT',
   'Ma ville n''est pas très grande, on traverse le centre à pied en vingt minutes. Il y a une rivière avec un chemin pour marcher, un vieux centre avec des cafés, et un marché le samedi matin. Je l''emmènerais d''abord au marché, parce que c''est là qu''on voit vraiment la ville.',
   'Les détails sont situés et la proposition est justifiée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C6-S1 / INSUFFICIENT
  ('0e742210-4265-596e-9bf8-9ae7b6459825', '777c8de5-6ddd-5d02-b0b0-f4071fd91647', 'INSUFFICIENT',
   'Je suis allé au cinéma, c''était bien.',
   'Le moment manque et une seule action est racontée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C6-S1 / EXPECTED
  ('b4bc8679-b241-5f34-a068-26464978ce56', '777c8de5-6ddd-5d02-b0b0-f4071fd91647', 'EXPECTED',
   'Samedi dernier, je suis allé au cinéma avec un ami. Après le film, on a mangé une pizza.',
   'Le moment est donné et deux actions se suivent.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C6-S1 / EXCELLENT
  ('bb8687fb-0245-5db8-be2e-ee016524e5e6', '777c8de5-6ddd-5d02-b0b0-f4071fd91647', 'EXCELLENT',
   'Samedi dernier, je suis allé au cinéma avec un ami. On a vu une comédie française, et après le film on a mangé une pizza à côté du cinéma. On est rentrés vers minuit.',
   'Le récit se déroule et se termine, avec des détails simples.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C6-S2 / INSUFFICIENT
  ('489e2b8c-0c15-58a1-9ced-adc078184489', '2074e7c7-7b32-510a-a8d7-1a75a89727bd', 'INSUFFICIENT',
   'On a fait un grand repas à la maison, il y avait beaucoup de monde.',
   'La scène est posée, mais rien n''est situé ni raconté.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C6-S2 / EXPECTED
  ('291d2dd5-3bc1-532a-9b2f-b7c40eed4d37', '2074e7c7-7b32-510a-a8d7-1a75a89727bd', 'EXPECTED',
   'Le mois dernier, on a fêté l''anniversaire de ma mère. On a préparé le repas ensemble, puis on a mangé et chanté.',
   'Le moment est clair et les étapes s''enchaînent.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C6-S2 / EXCELLENT
  ('bb7c7a10-6f13-523a-8b7e-980fd9bc46a1', '2074e7c7-7b32-510a-a8d7-1a75a89727bd', 'EXCELLENT',
   'Le mois dernier, on a fêté l''anniversaire de ma mère chez ma tante. D''abord, on a cuisiné toute la matinée. Ensuite, tout le monde est arrivé vers midi. On a mangé, puis on a apporté le gâteau et on a chanté. Elle était très contente.',
   'Le récit est ordonné et se termine sur une réaction.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C6-S3 / INSUFFICIENT
  ('2672ac33-19c6-5d01-9c8a-98fceec086e3', 'b7c2f0d0-8cdb-50b2-aedc-75efc91a12f8', 'INSUFFICIENT',
   'Je suis allée chez le médecin parce que j''avais mal à la gorge.',
   'La raison est donnée, mais le déroulement n''est pas raconté.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C6-S3 / EXPECTED
  ('d18526e8-5b3d-5573-8a8a-2adbc9306044', 'b7c2f0d0-8cdb-50b2-aedc-75efc91a12f8', 'EXPECTED',
   'Il y a deux semaines, j''ai pris rendez-vous chez le médecin. J''ai attendu un peu dans la salle d''attente, puis le médecin m''a examinée et il m''a donné un traitement.',
   'Trois étapes claires, situées dans le temps.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C6-S3 / EXCELLENT
  ('75862e97-1e54-542b-aa81-c5a5984112d7', 'b7c2f0d0-8cdb-50b2-aedc-75efc91a12f8', 'EXCELLENT',
   'Il y a deux semaines, j''ai pris rendez-vous en ligne pour le jeudi matin. Je suis arrivée dix minutes avant et j''ai attendu dans la salle d''attente. Ensuite, le médecin m''a examinée et m''a posé des questions. À la fin, il m''a donné une ordonnance et je suis passée à la pharmacie.',
   'Le récit couvre l''avant, le pendant et l''après.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C6-S4 / INSUFFICIENT
  ('d0f083fc-5ae6-597d-856f-52b91f5983d1', '6f50b544-6803-5392-950f-f220133e44a5', 'INSUFFICIENT',
   'Une fois, il y a eu un problème avec le train et j''étais très en retard.',
   'Le moment et la fin de l''histoire ne sont pas donnés.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C6-S4 / EXPECTED
  ('91c539dd-77f2-598e-9469-b05b1ccc6dba', '6f50b544-6803-5392-950f-f220133e44a5', 'EXPECTED',
   'L''hiver dernier, je suis allé à Paris en train. Le train a eu deux heures de retard à cause de la neige. Je suis arrivé tard, mais tout s''est bien terminé.',
   'Moment, problème et conclusion sont tous présents.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C6-S4 / EXCELLENT
  ('01930d37-b530-5d1e-8a5f-fccddf743fe2', '6f50b544-6803-5392-950f-f220133e44a5', 'EXCELLENT',
   'L''hiver dernier, je suis allé à Paris en train pour voir un ami. Le matin, il y avait beaucoup de neige et le train a eu deux heures de retard. J''ai attendu sur le quai et j''ai prévenu mon ami par message. Finalement, je suis arrivé le soir et il est venu me chercher à la gare.',
   'Le récit progresse, avec une réaction et une fin nette.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C6-S5 / INSUFFICIENT
  ('f58bee40-3c14-5bc6-a9a0-e8f435f04ff4', '4415d427-0a8c-5417-bd41-eaac6143ea1d', 'INSUFFICIENT',
   'Mon premier jour, j''étais très stressée, mais après ça a été.',
   'Le ressenti est là, mais rien n''est situé ni raconté.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C6-S5 / EXPECTED
  ('abf8270d-9f88-51a7-a518-56b840a119c1', '4415d427-0a8c-5417-bd41-eaac6143ea1d', 'EXPECTED',
   'L''année dernière, j''ai commencé dans une boulangerie. Le premier jour, je suis arrivée à six heures, la responsable m''a montré le travail et j''ai servi les clients. J''étais fatiguée, mais contente.',
   'Le récit est situé, ordonné, et le ressenti apparaît.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C6-S5 / EXCELLENT
  ('33c6a93e-22b2-54b4-bf1e-b842363246a1', '4415d427-0a8c-5417-bd41-eaac6143ea1d', 'EXCELLENT',
   'L''année dernière, en septembre, j''ai commencé dans une boulangerie. Le premier jour, je suis arrivée à six heures du matin. D''abord, la responsable m''a montré la machine à café et les prix. Ensuite, j''ai servi mes premiers clients et j''ai fait une erreur avec la monnaie. Une collègue m''a aidée tout de suite. Le soir, j''étais fatiguée, mais vraiment contente d''avoir tenu.',
   'Récit détaillé, avec un incident, une aide et un ressenti final.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C7-S1 / INSUFFICIENT
  ('6e72988d-5428-5977-8a79-b52d5adee0a3', '751eb297-c3d8-5f66-8da3-ceb4174d2e8a', 'INSUFFICIENT',
   'L''année prochaine, je voudrais changer des choses dans ma vie.',
   'L''intention reste vague : aucun projet identifiable.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C7-S1 / EXPECTED
  ('97c75695-b72c-5047-990a-915ece682912', '751eb297-c3d8-5f66-8da3-ceb4174d2e8a', 'EXPECTED',
   'L''année prochaine, je voudrais passer le permis de conduire. Je vais m''inscrire en janvier.',
   'Le projet est nommé et une date le rend concret.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C7-S1 / EXCELLENT
  ('6777499f-bbdc-5f61-839d-2373ff91c701', '751eb297-c3d8-5f66-8da3-ceb4174d2e8a', 'EXCELLENT',
   'L''année prochaine, je voudrais passer le permis de conduire. Je vais m''inscrire en janvier dans une auto-école près de mon travail, parce que j''ai besoin de la voiture pour aller sur les chantiers.',
   'Le projet est daté, situé et justifié par un besoin réel.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C7-S2 / INSUFFICIENT
  ('ded59d30-d651-535a-9958-44e7df890623', 'd3ce3ff8-dfa5-5ec7-a86a-81a833c4e691', 'INSUFFICIENT',
   'Je vais me reposer, j''ai vraiment besoin de vacances.',
   'Le besoin est exprimé, mais il n''y a ni projet ni précision.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C7-S2 / EXPECTED
  ('6be16592-456e-5690-be38-e3b1c6d8661f', 'd3ce3ff8-dfa5-5ec7-a86a-81a833c4e691', 'EXPECTED',
   'En août, je vais aller à la mer avec ma famille. On va rester une semaine.',
   'Le projet est daté et la durée est indiquée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C7-S2 / EXCELLENT
  ('6cafd213-021b-5b6c-8919-1dbf9d4227a7', 'd3ce3ff8-dfa5-5ec7-a86a-81a833c4e691', 'EXCELLENT',
   'En août, je vais aller à la mer avec ma famille. On va rester une semaine dans un petit appartement à Sète. On veut surtout se baigner et marcher le soir.',
   'Lieu, durée et activités prévues rendent le projet crédible.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C7-S3 / INSUFFICIENT
  ('084b5a9b-3cab-5414-b5dc-1ae9c32917b6', '84c1a231-9595-5f9f-9211-66b815138c72', 'INSUFFICIENT',
   'Oui, je veux faire une formation pour avoir un meilleur travail.',
   'La formation n''est pas nommée et rien n''est précisé.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C7-S3 / EXPECTED
  ('a99aae85-61ee-5a1e-a195-af14f102c30e', '84c1a231-9595-5f9f-9211-66b815138c72', 'EXPECTED',
   'Oui, je veux faire une formation en informatique. Je vais commencer en septembre, dans un centre près de chez moi.',
   'Le domaine, la date et le lieu sont donnés.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C7-S3 / EXCELLENT
  ('8e821263-335d-5681-a4be-96937b8a372a', '84c1a231-9595-5f9f-9211-66b815138c72', 'EXCELLENT',
   'Oui, je veux faire une formation en informatique, surtout pour la maintenance. Je vais commencer en septembre dans un centre près de chez moi, le soir, parce que je travaille la journée.',
   'Le projet est précisé et l''organisation pratique est expliquée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C7-S4 / INSUFFICIENT
  ('4cfbe560-516c-50f6-9197-4f42dba453a4', 'e70702d7-7f1e-53b7-9171-c23b7bb8a1c8', 'INSUFFICIENT',
   'Peut-être un jour, on verra bien.',
   'Aucune intention claire, donc aucun projet à évaluer.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C7-S4 / EXPECTED
  ('17634378-8f68-50f5-9bec-6a9f7d818bd1', 'e70702d7-7f1e-53b7-9171-c23b7bb8a1c8', 'EXPECTED',
   'Oui, je voudrais déménager l''année prochaine. Je cherche un appartement plus grand, avec deux chambres.',
   'L''intention est datée et le besoin est précisé.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C7-S4 / EXCELLENT
  ('cb70a2b7-ab0f-57f4-9b78-23875b0ba740', 'e70702d7-7f1e-53b7-9171-c23b7bb8a1c8', 'EXCELLENT',
   'Oui, je voudrais déménager l''année prochaine. Je cherche un appartement avec deux chambres, parce que ma fille grandit. Et si c''est possible, je voudrais rester dans le même quartier, près de son école.',
   'Besoin, raison et contrainte de lieu sont bien articulés.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C7-S5 / INSUFFICIENT
  ('e9cf622e-fd04-5de8-8922-8ecf97b0d094', '4033c19f-60d9-58ab-a933-4f1703c3fc71', 'INSUFFICIENT',
   'Dans deux ou trois ans, j''espère avoir une meilleure situation qu''aujourd''hui.',
   'L''objectif reste général et aucune étape n''est proposée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C7-S5 / EXPECTED
  ('9b7622ad-453d-599a-b844-3e5425618b8d', '4033c19f-60d9-58ab-a933-4f1703c3fc71', 'EXPECTED',
   'Dans deux ans, je voudrais travailler comme aide-soignante. D''abord, je dois améliorer mon français, ensuite je vais passer le concours d''entrée.',
   'L''objectif est clair et deux étapes sont annoncées.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C7-S5 / EXCELLENT
  ('4db3f032-8665-50a0-9955-801f054f3366', '4033c19f-60d9-58ab-a933-4f1703c3fc71', 'EXCELLENT',
   'Dans deux ans, je voudrais travailler comme aide-soignante dans un hôpital. D''abord, je dois améliorer mon français, donc je suis des cours le samedi. Ensuite, je vais passer le concours d''entrée au printemps prochain. Et pendant la formation, je continuerai à travailler à mi-temps.',
   'Chaque étape est datée ou expliquée : le plan est solide.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C8-S1 / INSUFFICIENT
  ('812d2a28-8843-5923-a2f0-56223b9589c0', 'b59be02e-ca03-5d38-8338-e3686b7681d1', 'INSUFFICIENT',
   'Parce que je l''aime bien, voilà.',
   'La phrase reprend la réponse précédente sans rien ajouter.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C8-S1 / EXPECTED
  ('26a7630a-5bed-5d49-8399-2141944e745e', 'b59be02e-ca03-5d38-8338-e3686b7681d1', 'EXPECTED',
   'Parce qu''il est calme et que tout est près : l''école, la boulangerie, la pharmacie.',
   'La raison est nouvelle et appuyée par des exemples.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C8-S1 / EXCELLENT
  ('bb43533e-b166-5270-b5ca-1cb5decb6984', 'b59be02e-ca03-5d38-8338-e3686b7681d1', 'EXCELLENT',
   'Parce qu''il est calme et que tout est près. Je vais à l''école de ma fille à pied en cinq minutes, donc je gagne du temps le matin.',
   'La raison est illustrée par une conséquence concrète.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C8-S2 / INSUFFICIENT
  ('69d2b2d2-c457-5082-a57b-ca3139168b81', 'ef89ae26-3fd1-5247-8118-87e56e2f896b', 'INSUFFICIENT',
   'Oui, je fais de la randonnée le dimanche.',
   'La relance n''est pas prise en compte : la question était « avec qui ».', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C8-S2 / EXPECTED
  ('775beda0-6af7-5dc0-adce-4bb2e52c54b2', 'ef89ae26-3fd1-5247-8118-87e56e2f896b', 'EXPECTED',
   'Avec deux amis. On part ensemble en voiture le matin.',
   'La question est traitée et une information s''ajoute.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C8-S2 / EXCELLENT
  ('f4544e7a-33ef-5793-97e1-21ec161e50ed', 'ef89ae26-3fd1-5247-8118-87e56e2f896b', 'EXCELLENT',
   'Avec deux amis du travail. On part en voiture vers huit heures, et parfois mon frère vient aussi quand il n''est pas de service.',
   'Les personnes sont identifiées et une variante est ajoutée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C8-S3 / INSUFFICIENT
  ('48ceb3c2-5333-5851-8216-69cbaf74af44', '90ca0e8e-6bfb-5ba4-96bc-7702193c6da1', 'INSUFFICIENT',
   'Depuis un moment, oui, ça fait déjà un certain temps.',
   'La durée reste imprécise et rien de nouveau n''est apporté.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C8-S3 / EXPECTED
  ('f5ce18be-29c6-5948-87c2-45cddbfb0720', '90ca0e8e-6bfb-5ba4-96bc-7702193c6da1', 'EXPECTED',
   'Depuis deux ans. J''ai commencé en salle et maintenant je suis en cuisine.',
   'La durée est nette et une évolution est racontée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C8-S3 / EXCELLENT
  ('373eb24b-beb7-59e3-b222-ef390b47f57f', '90ca0e8e-6bfb-5ba4-96bc-7702193c6da1', 'EXCELLENT',
   'Depuis deux ans, presque jour pour jour. J''ai commencé en salle, et depuis l''hiver dernier je travaille en cuisine, surtout sur les entrées.',
   'La durée est précise et l''évolution est bien située.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C8-S4 / INSUFFICIENT
  ('3bd00833-064a-547c-948a-c6b72a7c87fb', '440ca805-b378-59a4-bdab-63b8c928ca5d', 'INSUFFICIENT',
   'Oui, c''est un peu difficile parfois.',
   'La réponse est directe, mais aucune explication ne suit.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C8-S4 / EXPECTED
  ('b7ae5dcd-333c-57b6-8b41-7f0559089b2c', '440ca805-b378-59a4-bdab-63b8c928ca5d', 'EXPECTED',
   'C''est un peu difficile parce que je finis le travail à dix-huit heures. Mais le groupe est petit et la professeure explique bien.',
   'La difficulté et deux éléments concrets sont exposés.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C8-S4 / EXCELLENT
  ('4b4ffaf5-3874-5bff-8333-7f2fb301ce04', '440ca805-b378-59a4-bdab-63b8c928ca5d', 'EXCELLENT',
   'C''est un peu difficile, surtout le mardi, parce que je finis le travail à dix-huit heures et le cours commence à dix-neuf heures. Mais le groupe est petit, la professeure explique bien, et je révise dans le bus le matin.',
   'Difficulté située, compensations nommées, solution personnelle ajoutée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C8-S5 / INSUFFICIENT
  ('03927099-e32d-5caa-8332-0341acf2b18b', '7a6b7b72-2383-5acb-9c80-97f1286761e3', 'INSUFFICIENT',
   'Oui, bien sûr, c''est une très bonne activité.',
   'La position est là, mais la justification et le destinataire manquent.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C8-S5 / EXPECTED
  ('367bbe34-366c-5f00-9bc5-e2769ce4d085', '7a6b7b72-2383-5acb-9c80-97f1286761e3', 'EXPECTED',
   'Oui, je le conseillerais, surtout aux personnes qui travaillent assis toute la journée. Ça fait bouger et on rencontre du monde.',
   'Position, justification et public visé sont tous présents.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO1-C8-S5 / EXCELLENT
  ('704641e1-02c6-5516-902f-3340c86046d7', '7a6b7b72-2383-5acb-9c80-97f1286761e3', 'EXCELLENT',
   'Oui, je le conseillerais, surtout aux personnes qui travaillent assis toute la journée, comme moi avant. Ça fait bouger et on rencontre du monde facilement. Par contre, il faut venir régulièrement, sinon on perd vite l''habitude.',
   'Le conseil est ciblé, justifié, et une réserve utile est ajoutée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02');
