-- ============================================================================
-- V301 — Competences TCF : EE2 « Raconter une experience »
--
-- Seed du module « Competences » pour la tache EE2 (EE).
-- 8 competences, 40 petits sujets, 120 references.
--
-- Tables : skills, skill_prompts, skill_references (DDL en V025).
--
-- FICHIER GENERE — NE PAS EDITER A LA MAIN.
--
--   cd backend_sejourfr && python3 tools/competences/generer_seed.py
--
-- On edite la fiche de contenu tools/competences/contenu/EE2.json,
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
  -- EE2-C1 — Situer le moment et le lieu
  ('5f943cec-aa21-5a34-9e74-126491d284cb', 'EE', 'EE2', 'EE2-C1', 'Situer le moment et le lieu',
   'Vous apprenez à dire quand et où se passe votre histoire, dès les premiers mots. Au TCF, un correcteur qui sait tout de suite le moment et l''endroit suit votre récit sans effort.',
   'Donner un repère temporel et spatial clair dès le début du récit.',
   'B1', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C2 — Présenter la situation initiale
  ('15aa5262-578e-576c-a7c9-901a01d8db53', 'EE', 'EE2', 'EE2-C2', 'Présenter la situation initiale',
   'Vous apprenez à planter le décor avant l''événement principal : où vous étiez, avec qui, et ce que vous étiez en train de faire. Au TCF, ce début rend toute la suite du récit facile à suivre.',
   'Expliquer où l''on était, avec qui et ce que l''on faisait avant l''événement principal.',
   'B1', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C3 — Utiliser les temps du passé de manière compréhensible
  ('f66306a9-36b9-5c62-9bcc-ef80e4f3b0d5', 'EE', 'EE2', 'EE2-C3', 'Utiliser les temps du passé de manière compréhensible',
   'Vous apprenez à employer le passé composé pour les actions terminées et l''imparfait pour le décor. Au TCF, un récit écrit au présent ou aux temps mélangés devient vite difficile à suivre.',
   'Employer le passé composé et, lorsque nécessaire, l''imparfait pour distinguer les actions et le contexte.',
   'B1', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C4 — Introduire un événement déclencheur
  ('74659ee1-d718-562f-8af7-48948606d1c8', 'EE', 'EE2', 'EE2-C4', 'Introduire un événement déclencheur',
   'Vous apprenez à faire apparaître le moment où tout change : un problème, une surprise, un imprévu. Au TCF, un récit sans déclencheur reste plat et ne raconte pas vraiment une histoire.',
   'Faire apparaître clairement le changement, le problème ou l''événement inattendu.',
   'B1', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C5 — Raconter les actions dans l'ordre
  ('fcf4e59e-6108-582d-a9e5-16ea8296c822', 'EE', 'EE2', 'EE2-C5', 'Raconter les actions dans l''ordre',
   'Vous apprenez à enchaîner les événements avec des mots simples comme « d''abord », « ensuite », « finalement ». Au TCF, un récit bien ordonné se lit sans effort et montre que vous maîtrisez la chronologie.',
   'Organiser les événements avec des connecteurs temporels simples et naturels.',
   'B1', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C6 — Ajouter des détails utiles
  ('26cd2325-19d3-5e49-890b-86fc3b40a70a', 'EE', 'EE2', 'EE2-C6', 'Ajouter des détails utiles',
   'Vous apprenez à ajouter des précisions concrètes — un lieu, une personne, un objet, une heure — qui rendent le récit vivant sans vous éloigner du sujet. Au TCF, un récit trop vague donne l''impression d''un texte pauvre.',
   'Préciser les personnes, les actions, l''environnement ou les circonstances sans s''éloigner du sujet.',
   'B1', 6, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C7 — Exprimer une réaction ou un ressenti
  ('a905601b-384e-5a50-92c2-5f3239991459', 'EE', 'EE2', 'EE2-C7', 'Exprimer une réaction ou un ressenti',
   'Vous apprenez à dire ce que vous avez ressenti et à relier ce sentiment à ce qui venait de se passer. Au TCF, un récit sans réaction reste une simple liste de faits.',
   'Dire ce que l''on a pensé ou ressenti et relier ce ressenti à la situation vécue.',
   'B1', 7, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C8 — Terminer par le résultat ou la conséquence
  ('aa05171a-171d-5003-a405-e9c01fbb58d5', 'EE', 'EE2', 'EE2-C8', 'Terminer par le résultat ou la conséquence',
   'Vous apprenez à terminer votre récit par un résultat clair et par ce que la situation a changé pour vous. Au TCF, un texte qui s''arrête sans conclusion donne l''impression d''être inachevé.',
   'Expliquer comment la situation s''est terminée et ce qu''elle a changé.',
   'B1', 8, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02');

INSERT INTO skill_prompts (id, skill_id, section, code, title, context, instruction,
                           unique_criterion, recommended_min_words, recommended_max_words,
                           recommended_duration_seconds, difficulty_level, display_order,
                           is_active, created_at, updated_at)
VALUES
  -- EE2-C1-S1 — EASY — Une sortie au marché
  ('c0ca9a20-5ea9-587b-a078-a05d3401dee2', '5f943cec-aa21-5a34-9e74-126491d284cb', 'EE', 'EE2-C1-S1', 'Une sortie au marché',
   'Le week-end dernier, vous êtes allé(e) au marché de votre ville avec un ami.',
   'Écrivez la première phrase de votre récit. Dites quand cette sortie a eu lieu et où vous étiez.',
   'La première phrase donne un repère de temps et un repère de lieu.',
   15, 35, NULL, 'EASY', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C1-S2 — EASY — Le premier jour de travail
  ('02640b00-135c-54b4-a24b-541ea0af4c70', '5f943cec-aa21-5a34-9e74-126491d284cb', 'EE', 'EE2-C1-S2', 'Le premier jour de travail',
   'Vous avez commencé un nouvel emploi il y a quelques semaines.',
   'Écrivez la phrase qui ouvre le récit de ce premier jour. Indiquez quand c''était et où vous vous trouviez.',
   'La phrase indique la période et le lieu de travail.',
   15, 35, NULL, 'EASY', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C1-S3 — MEDIUM — Un rendez-vous à la préfecture
  ('5e0ef96f-8e6d-5d7d-b120-50a71a7feef4', '5f943cec-aa21-5a34-9e74-126491d284cb', 'EE', 'EE2-C1-S3', 'Un rendez-vous à la préfecture',
   'Vous racontez à une amie votre rendez-vous à la préfecture pour renouveler votre titre de séjour.',
   'Écrivez les deux premières phrases de ce récit. Situez le jour, l''heure et l''endroit où vous étiez.',
   'Le début du récit donne un repère de temps précis et un lieu identifiable.',
   25, 55, NULL, 'MEDIUM', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C1-S4 — MEDIUM — Un matin de grève
  ('1401563f-95de-5cfa-b9df-35c8039d8056', '5f943cec-aa21-5a34-9e74-126491d284cb', 'EE', 'EE2-C1-S4', 'Un matin de grève',
   'Un jour de grève, vous n''avez pas pu prendre votre train comme prévu.',
   'Commencez ce récit en deux phrases. Le lecteur doit savoir tout de suite quand et où vous étiez.',
   'Les deux premières phrases situent le récit dans le temps et dans un lieu précis.',
   25, 55, NULL, 'MEDIUM', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C1-S5 — HARD — Le jour de l'emménagement
  ('c492b3dc-1857-5826-9e38-5f61e0be92eb', '5f943cec-aa21-5a34-9e74-126491d284cb', 'EE', 'EE2-C1-S5', 'Le jour de l''emménagement',
   'Vous avez emménagé dans un nouvel appartement il y a quelques mois.',
   'Écrivez le début de ce récit en deux phrases. Situez le moment et le lieu, puis reliez-les à ce que vous étiez en train de faire.',
   'Le moment et le lieu sont précis et introduisent directement l''action du récit.',
   25, 55, NULL, 'HARD', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C2-S1 — EASY — Une fête dans le quartier
  ('a92b207d-9cac-5f67-8dbb-4eac43376990', '15aa5262-578e-576c-a7c9-901a01d8db53', 'EE', 'EE2-C2-S1', 'Une fête dans le quartier',
   'Votre quartier a organisé une fête un samedi de juin.',
   'Présentez en deux phrases le début de cette soirée : où vous étiez, avec qui, et ce que vous faisiez.',
   'Le début du récit dit le lieu, les personnes présentes et l''activité en cours.',
   25, 55, NULL, 'EASY', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C2-S2 — EASY — Un cours du soir
  ('d70d4fa2-cb55-5340-9441-39a99f5749b7', '15aa5262-578e-576c-a7c9-901a01d8db53', 'EE', 'EE2-C2-S2', 'Un cours du soir',
   'Vous suivez des cours de français le soir, deux fois par semaine.',
   'Racontez le début d''une de ces soirées en deux phrases : où vous étiez, avec qui et ce que vous faisiez avant le début du cours.',
   'La situation de départ précise le lieu, les personnes et l''activité en cours.',
   25, 55, NULL, 'EASY', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C2-S3 — MEDIUM — Dans la salle d'attente
  ('e0e269d9-dd84-5cef-8a64-a693f796e782', '15aa5262-578e-576c-a7c9-901a01d8db53', 'EE', 'EE2-C2-S3', 'Dans la salle d''attente',
   'Vous accompagnez votre fille chez le médecin pour une visite de contrôle.',
   'Présentez en deux phrases la situation avant d''entrer dans le cabinet : où vous étiez, avec qui, ce que vous faisiez.',
   'Le lecteur sait où vous êtes, qui vous accompagne et ce que vous faites avant l''événement.',
   25, 55, NULL, 'MEDIUM', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C2-S4 — MEDIUM — Un départ en covoiturage
  ('2c6aad67-05df-5298-8b75-2136f4fcd0b0', '15aa5262-578e-576c-a7c9-901a01d8db53', 'EE', 'EE2-C2-S4', 'Un départ en covoiturage',
   'Vous êtes parti(e) en covoiturage pour rendre visite à votre famille dans une autre ville.',
   'Écrivez trois phrases pour présenter le début du trajet : où vous étiez, avec qui, ce que vous faisiez.',
   'Les trois phrases posent le lieu, les personnes et l''activité avant le départ.',
   40, 80, NULL, 'MEDIUM', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C2-S5 — HARD — Juste avant l'incident
  ('a56d2f64-b850-586b-b866-09ad7cb58059', '15aa5262-578e-576c-a7c9-901a01d8db53', 'EE', 'EE2-C2-S5', 'Juste avant l''incident',
   'Un jour, un incident est arrivé pendant votre service au travail. Vous racontez d''abord ce qui se passait juste avant.',
   'Écrivez trois phrases qui présentent la situation initiale : le lieu, les personnes et votre activité, sans raconter encore l''incident.',
   'Les trois phrases décrivent la situation d''avant l''incident, sans le raconter.',
   40, 80, NULL, 'HARD', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C3-S1 — EASY — Les courses de samedi
  ('690cabeb-365d-524a-bbd9-149d65e221f3', 'f66306a9-36b9-5c62-9bcc-ef80e4f3b0d5', 'EE', 'EE2-C3-S1', 'Les courses de samedi',
   'Samedi, vous avez fait vos courses de la semaine.',
   'Racontez en une phrase une action que vous avez terminée pendant ces courses.',
   'L''action terminée est écrite au passé composé.',
   15, 35, NULL, 'EASY', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C3-S2 — EASY — La journée d'école d'hier
  ('e6ea5311-e340-59a7-bc5b-0c31f46a9555', 'f66306a9-36b9-5c62-9bcc-ef80e4f3b0d5', 'EE', 'EE2-C3-S2', 'La journée d''école d''hier',
   'Votre enfant vous a raconté sa journée d''hier à l''école et vous la rapportez à une amie.',
   'Racontez en deux phrases deux choses qui se sont passées hier à l''école.',
   'Les deux actions passées sont écrites au passé composé, pas au présent.',
   25, 55, NULL, 'EASY', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C3-S3 — MEDIUM — Pendant que j'attendais le bus
  ('78efcddd-6b49-5f4e-80ef-acf20c4a6802', 'f66306a9-36b9-5c62-9bcc-ef80e4f3b0d5', 'EE', 'EE2-C3-S3', 'Pendant que j''attendais le bus',
   'Un matin, vous attendiez le bus pour aller travailler quand quelque chose est arrivé.',
   'Racontez en deux phrases une action terminée qui s''est produite pendant que vous attendiez.',
   'L''imparfait décrit l''attente et le passé composé marque l''action terminée.',
   25, 55, NULL, 'MEDIUM', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C3-S4 — MEDIUM — Une coupure d'eau le soir
  ('e76d19dc-c024-51fe-9a95-8cbdc641def3', 'f66306a9-36b9-5c62-9bcc-ef80e4f3b0d5', 'EE', 'EE2-C3-S4', 'Une coupure d''eau le soir',
   'Un soir, l''eau s''est coupée dans votre immeuble.',
   'Racontez en trois phrases ce qui se passait chez vous et ce que vous avez fait ensuite.',
   'Le contexte est à l''imparfait et les actions terminées au passé composé.',
   40, 80, NULL, 'MEDIUM', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C3-S5 — HARD — Le jour de l'entretien
  ('5a869709-a731-5e10-81d4-39024c91769b', 'f66306a9-36b9-5c62-9bcc-ef80e4f3b0d5', 'EE', 'EE2-C3-S5', 'Le jour de l''entretien',
   'Vous avez passé un entretien pour un emploi il y a quelques semaines.',
   'Racontez cet entretien en trois phrases : le décor, ce que vous avez fait, et la fin du rendez-vous.',
   'Le récit alterne l''imparfait pour le décor et le passé composé pour les actions.',
   40, 80, NULL, 'HARD', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C4-S1 — EASY — Un retrait au distributeur
  ('affa70f5-3e1b-582f-9ffc-199ed9671153', '74659ee1-d718-562f-8af7-48948606d1c8', 'EE', 'EE2-C4-S1', 'Un retrait au distributeur',
   'Vous vouliez retirer de l''argent au distributeur près de chez vous.',
   'Écrivez la phrase qui montre le moment précis où un problème est apparu.',
   'Une phrase marque nettement l''instant où le problème survient.',
   15, 35, NULL, 'EASY', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C4-S2 — EASY — L'orage pendant le match
  ('56c9f948-fd27-5549-9f50-7ea2ec5444de', '74659ee1-d718-562f-8af7-48948606d1c8', 'EE', 'EE2-C4-S2', 'L''orage pendant le match',
   'Vous êtes allé(e) voir un match de football avec des amis, un dimanche après-midi.',
   'Écrivez une ou deux phrases qui introduisent l''événement inattendu de cet après-midi.',
   'L''événement inattendu est introduit par une expression de rupture comme « soudain » ou « tout à coup ».',
   20, 45, NULL, 'EASY', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C4-S3 — MEDIUM — Un incident dans le bus
  ('5195131e-e903-5255-a708-d8bf03590c5e', '74659ee1-d718-562f-8af7-48948606d1c8', 'EE', 'EE2-C4-S3', 'Un incident dans le bus',
   'Vous rentriez du travail en bus, un soir de semaine.',
   'Racontez en deux phrases le moment où la situation a changé dans ce bus.',
   'Le récit indique clairement l''instant où la situation bascule.',
   25, 55, NULL, 'MEDIUM', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C4-S4 — MEDIUM — Le train supprimé
  ('708d2ed6-0690-55c1-a7e5-e54e93732811', '74659ee1-d718-562f-8af7-48948606d1c8', 'EE', 'EE2-C4-S4', 'Le train supprimé',
   'Vous attendiez votre train pour partir en week-end.',
   'Racontez en deux phrases l''annonce qui a tout changé et ce qu''elle a provoqué.',
   'L''annonce fonctionne comme un déclencheur et entraîne un effet immédiat.',
   25, 55, NULL, 'MEDIUM', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C4-S5 — HARD — Un document qui manque
  ('39be895e-a669-5f56-b634-22bf3f0acb09', '74659ee1-d718-562f-8af7-48948606d1c8', 'EE', 'EE2-C4-S5', 'Un document qui manque',
   'Au guichet d''une administration, votre dossier a posé un problème.',
   'Racontez en trois phrases le moment où l''employée vous a annoncé le problème et ce que cela a provoqué.',
   'Le déclencheur est nettement marqué et entraîne une conséquence immédiate.',
   40, 80, NULL, 'HARD', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C5-S1 — EASY — Une inscription à la bibliothèque
  ('973e7719-9fe5-55e3-9532-85625621d4ab', 'fcf4e59e-6108-582d-a9e5-16ea8296c822', 'EE', 'EE2-C5-S1', 'Une inscription à la bibliothèque',
   'Vous vous êtes inscrit(e) à la bibliothèque de votre ville.',
   'Racontez cette inscription en trois phrases : ce que vous avez fait d''abord, ensuite et finalement.',
   'Les trois étapes se suivent dans l''ordre et sont reliées par des connecteurs de temps.',
   40, 80, NULL, 'EASY', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C5-S2 — EASY — Le chauffage en panne
  ('0cd035b2-55e7-5e9a-92fe-5a7e7a854869', 'fcf4e59e-6108-582d-a9e5-16ea8296c822', 'EE', 'EE2-C5-S2', 'Le chauffage en panne',
   'En plein hiver, le chauffage de votre logement est tombé en panne.',
   'Racontez en trois phrases ce que vous avez fait, dans l''ordre, pour régler ce problème.',
   'Les actions se suivent dans un ordre logique marqué par des connecteurs.',
   40, 80, NULL, 'EASY', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C5-S3 — MEDIUM — Le jour du test de français
  ('3c6360e2-8073-5e75-90ca-27102b0b6aba', 'fcf4e59e-6108-582d-a9e5-16ea8296c822', 'EE', 'EE2-C5-S3', 'Le jour du test de français',
   'Vous avez passé un test de français dans un centre d''examen.',
   'Racontez le déroulement de cette journée en trois phrases, dans l''ordre.',
   'Le récit suit l''ordre réel des étapes de la journée, avec des connecteurs.',
   40, 80, NULL, 'MEDIUM', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C5-S4 — MEDIUM — Une carte bancaire perdue
  ('990fc0b5-a5c1-5d5f-bf2f-0c0b9468238c', 'fcf4e59e-6108-582d-a9e5-16ea8296c822', 'EE', 'EE2-C5-S4', 'Une carte bancaire perdue',
   'Vous avez perdu votre carte bancaire dans la rue.',
   'Racontez en trois phrases les étapes que vous avez suivies après cette perte.',
   'Les étapes sont racontées dans l''ordre chronologique avec des connecteurs variés.',
   40, 80, NULL, 'MEDIUM', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C5-S5 — HARD — Un déménagement en une journée
  ('bc5e259c-d41c-5adb-a322-7bae18e71bd3', 'fcf4e59e-6108-582d-a9e5-16ea8296c822', 'EE', 'EE2-C5-S5', 'Un déménagement en une journée',
   'Vous avez déménagé d''un studio vers un appartement plus grand.',
   'Racontez ce déménagement en trois phrases. Faites apparaître au moins quatre étapes dans l''ordre.',
   'Au moins quatre étapes s''enchaînent dans l''ordre, sans répéter le même connecteur.',
   40, 80, NULL, 'HARD', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C6-S1 — EASY — Le train raté de justesse
  ('89cda19d-5c34-5786-814f-5dc2fefbb5ed', '26cd2325-19d3-5e49-890b-86fc3b40a70a', 'EE', 'EE2-C6-S1', 'Le train raté de justesse',
   'Un matin, vous êtes arrivé(e) à la gare trop tard et votre train est parti sans vous.',
   'Racontez ce moment en deux phrases et ajoutez un détail concret sur la gare ou sur le voyage.',
   'Le récit contient au moins un détail concret sur le lieu ou le voyage.',
   25, 55, NULL, 'EASY', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C6-S2 — EASY — Un repas chez les voisins
  ('54df9807-b352-545e-8bb5-f64cb44d963a', '26cd2325-19d3-5e49-890b-86fc3b40a70a', 'EE', 'EE2-C6-S2', 'Un repas chez les voisins',
   'Vos voisins vous ont invité(e) à partager un repas chez eux.',
   'Racontez un moment de ce repas en deux phrases, avec un détail précis sur les plats ou sur les invités.',
   'Au moins un détail précis décrit les plats, la table ou les personnes.',
   25, 55, NULL, 'EASY', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C6-S3 — MEDIUM — Avant l'entretien d'embauche
  ('a385b183-9189-5b1e-89c7-3cc857e1ce49', '26cd2325-19d3-5e49-890b-86fc3b40a70a', 'EE', 'EE2-C6-S3', 'Avant l''entretien d''embauche',
   'Vous êtes arrivé(e) en avance pour un entretien d''embauche.',
   'Racontez ces minutes d''attente en trois phrases, avec deux détails concrets sur le lieu ou sur les personnes.',
   'Deux détails concrets rendent la scène d''attente précise.',
   40, 80, NULL, 'MEDIUM', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C6-S4 — MEDIUM — Un passage à la pharmacie
  ('3da289ca-4821-5787-bec5-cfb6f37743f1', '26cd2325-19d3-5e49-890b-86fc3b40a70a', 'EE', 'EE2-C6-S4', 'Un passage à la pharmacie',
   'Vous êtes allé(e) à la pharmacie chercher un médicament pour un proche.',
   'Racontez ce passage en deux phrases et ajoutez un détail utile sur l''échange avec le pharmacien.',
   'Un détail précis décrit l''échange, le médicament ou l''attente.',
   25, 55, NULL, 'MEDIUM', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C6-S5 — HARD — La visite de l'appartement
  ('03c3742e-e06d-5102-9105-e5dc93744764', '26cd2325-19d3-5e49-890b-86fc3b40a70a', 'EE', 'EE2-C6-S5', 'La visite de l''appartement',
   'Vous avez visité un appartement que vous vouliez louer.',
   'Racontez cette visite en trois phrases, avec deux détails concrets qui aident à comprendre votre décision.',
   'Deux détails concrets éclairent la visite sans sortir du sujet.',
   40, 80, NULL, 'HARD', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C7-S1 — EASY — Les clés introuvables
  ('a6933d70-2df7-5b48-b163-6ff858699fc3', 'a905601b-384e-5a50-92c2-5f3239991459', 'EE', 'EE2-C7-S1', 'Les clés introuvables',
   'Un soir, vous êtes rentré(e) chez vous et vos clés n''étaient plus dans votre sac.',
   'Expliquez en deux phrases ce que vous avez ressenti à ce moment-là et pourquoi.',
   'Un sentiment est nommé et relié à la situation vécue.',
   25, 55, NULL, 'EASY', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C7-S2 — EASY — Le permis enfin obtenu
  ('471a25ac-4c8b-5fea-85f9-dc26031ca93a', 'a905601b-384e-5a50-92c2-5f3239991459', 'EE', 'EE2-C7-S2', 'Le permis enfin obtenu',
   'Vous avez appris que vous aviez réussi votre permis de conduire.',
   'Racontez en deux phrases votre réaction au moment où vous avez appris la nouvelle.',
   'La réaction est exprimée et rattachée à la nouvelle reçue.',
   25, 55, NULL, 'EASY', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C7-S3 — MEDIUM — Ma première démarche seul
  ('60fbb16e-2d6b-5963-926f-a9e01f236a45', 'a905601b-384e-5a50-92c2-5f3239991459', 'EE', 'EE2-C7-S3', 'Ma première démarche seul',
   'Vous avez fait une démarche administrative seul(e) pour la première fois, sans accompagnant ni traducteur.',
   'Racontez en trois phrases comment vous vous êtes senti(e) avant, pendant et après ce rendez-vous.',
   'Le ressenti évolue et reste relié à chaque moment du rendez-vous.',
   40, 80, NULL, 'MEDIUM', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C7-S4 — MEDIUM — Un coup de main du voisin
  ('1657c8d4-5da5-5918-88a9-c2db12eefefb', 'a905601b-384e-5a50-92c2-5f3239991459', 'EE', 'EE2-C7-S4', 'Un coup de main du voisin',
   'Un voisin vous a aidé(e) alors que vous étiez en difficulté.',
   'Racontez en deux phrases ce que ce geste a provoqué chez vous.',
   'Le sentiment exprimé est clairement lié au geste du voisin.',
   25, 55, NULL, 'MEDIUM', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C7-S5 — HARD — Un entretien décevant
  ('19fc4fe1-74f8-5052-9c38-c483c1dd98ab', 'a905601b-384e-5a50-92c2-5f3239991459', 'EE', 'EE2-C7-S5', 'Un entretien décevant',
   'Vous avez passé un entretien pour un emploi et vous avez compris assez vite que cela ne se passait pas bien.',
   'Racontez en trois phrases comment votre ressenti a changé pendant et après cet entretien.',
   'Deux sentiments différents apparaissent, chacun expliqué par la situation.',
   40, 80, NULL, 'HARD', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C8-S1 — EASY — Le colis enfin retrouvé
  ('127f09ce-98c4-546e-8dd1-6305375b48da', 'aa05171a-171d-5003-a405-e9c01fbb58d5', 'EE', 'EE2-C8-S1', 'Le colis enfin retrouvé',
   'Un colis important n''était jamais arrivé chez vous et vous avez contacté le transporteur.',
   'Écrivez la fin de ce récit en deux phrases : dites comment le problème s''est terminé.',
   'La fin dit clairement comment le problème s''est résolu.',
   25, 55, NULL, 'EASY', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C8-S2 — EASY — La fin des cours du soir
  ('aa305497-6f7f-51bb-aa5e-6acdfab3a767', 'aa05171a-171d-5003-a405-e9c01fbb58d5', 'EE', 'EE2-C8-S2', 'La fin des cours du soir',
   'Vous avez terminé une année de cours de français dans une association.',
   'Racontez la fin de cette année en deux phrases : le résultat et ce que cela a changé pour vous.',
   'Le résultat est donné et une conséquence concrète est indiquée.',
   25, 55, NULL, 'EASY', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C8-S3 — MEDIUM — La fuite d'eau réparée
  ('0cb661d2-89a7-5964-9021-a72c5751e9ac', 'aa05171a-171d-5003-a405-e9c01fbb58d5', 'EE', 'EE2-C8-S3', 'La fuite d''eau réparée',
   'Une fuite d''eau a abîmé le plafond de votre salle de bains.',
   'Racontez la fin de cette histoire en trois phrases : la réparation, le résultat et la conséquence pour vous.',
   'Le récit se termine par un résultat net suivi d''une conséquence.',
   40, 80, NULL, 'MEDIUM', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C8-S4 — MEDIUM — Un gros retard au travail
  ('4ca39470-94ad-5946-94d5-5224c42c8630', 'aa05171a-171d-5003-a405-e9c01fbb58d5', 'EE', 'EE2-C8-S4', 'Un gros retard au travail',
   'Un jour, vous êtes arrivé(e) très en retard à votre travail à cause des transports.',
   'Racontez la fin de cette journée en trois phrases : ce qui s''est passé avec votre responsable et ce que vous avez changé ensuite.',
   'La conclusion présente le résultat de l''incident et un changement qui en découle.',
   40, 80, NULL, 'MEDIUM', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C8-S5 — HARD — Un dossier qui aboutit
  ('ccef48ba-9091-5429-bded-41de31cfc92b', 'aa05171a-171d-5003-a405-e9c01fbb58d5', 'EE', 'EE2-C8-S5', 'Un dossier qui aboutit',
   'Après plusieurs mois de démarches, votre dossier administratif a enfin abouti.',
   'Écrivez la fin de ce récit en trois phrases : le résultat, ce que cela change concrètement et ce que vous en retenez.',
   'La fin donne le résultat, une conséquence concrète et un bilan personnel.',
   40, 80, NULL, 'HARD', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02');

INSERT INTO skill_references (id, skill_prompt_id, level, text, pedagogical_note,
                              created_at, updated_at)
VALUES
  -- EE2-C1-S1 / INSUFFICIENT
  ('940525a3-288a-58d6-aeb5-8f7edd8c8d5e', 'c0ca9a20-5ea9-587b-a078-a05d3401dee2', 'INSUFFICIENT',
   'Je suis allé faire des courses avec un ami et nous avons acheté beaucoup de fruits et des légumes.',
   'Le récit démarre sans dire quand ni où cela s''est passé.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C1-S1 / EXPECTED
  ('4a336ac4-a6c1-5e67-8cc8-71887bd3bf9e', 'c0ca9a20-5ea9-587b-a078-a05d3401dee2', 'EXPECTED',
   'Samedi dernier, je suis allé au marché de mon quartier avec un ami pour acheter des légumes.',
   'Le jour et l''endroit sont donnés dès le début : c''est l''essentiel.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C1-S1 / EXCELLENT
  ('6de543bc-098b-5325-80dd-1f10d6ebe384', 'c0ca9a20-5ea9-587b-a078-a05d3401dee2', 'EXCELLENT',
   'Samedi dernier, vers dix heures du matin, je me suis promené avec un ami au marché de la place Gambetta, près de chez moi.',
   'L''heure et le nom du lieu rendent la scène immédiatement précise.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C1-S2 / INSUFFICIENT
  ('55d6f660-1bff-5a87-9620-b6e7015ffcda', '02640b00-135c-54b4-a24b-541ea0af4c70', 'INSUFFICIENT',
   'J''ai commencé un nouveau travail il y a quelques semaines et j''étais très stressé pendant toute la première journée.',
   'Le lecteur ne sait ni quand ni dans quel endroit vous avez commencé.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C1-S2 / EXPECTED
  ('d7caecd4-50ea-522a-a743-7c93175f952a', '02640b00-135c-54b4-a24b-541ea0af4c70', 'EXPECTED',
   'Le mois dernier, j''ai commencé à travailler dans une boulangerie du centre-ville de Tours, tout près de chez moi.',
   'La période et le lieu apparaissent clairement dès la première phrase.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C1-S2 / EXCELLENT
  ('83cde4f5-479c-5cbf-bdce-ed1896b13211', '02640b00-135c-54b4-a24b-541ea0af4c70', 'EXCELLENT',
   'Le premier lundi de septembre, à six heures du matin, je suis entré pour la première fois dans la boulangerie du centre-ville où je travaille aujourd''hui.',
   'Un jour précis et une heure ancrent le récit dans un moment réel.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C1-S3 / INSUFFICIENT
  ('0f621222-708d-5724-8328-426b00cfa107', '5e0ef96f-8e6d-5d7d-b120-50a71a7feef4', 'INSUFFICIENT',
   'J''avais un rendez-vous à la préfecture pour mon titre de séjour. Il y avait beaucoup de monde et j''ai attendu très longtemps avant mon tour.',
   'Le lieu apparaît, mais le lecteur ignore complètement quand c''était.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C1-S3 / EXPECTED
  ('8fc9e2fe-adb0-5292-8ee1-545d8dcb7467', '5e0ef96f-8e6d-5d7d-b120-50a71a7feef4', 'EXPECTED',
   'Mardi dernier, j''avais rendez-vous à la préfecture de Lyon pour renouveler mon titre de séjour. Je suis arrivée à huit heures devant l''entrée principale, avec mon dossier sous le bras.',
   'Jour, heure et lieu : le décor temporel est posé en deux phrases.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C1-S3 / EXCELLENT
  ('b5f83612-f702-5cb2-9a5f-5d572e3e21a8', '5e0ef96f-8e6d-5d7d-b120-50a71a7feef4', 'EXCELLENT',
   'Mardi 12 mars, j''avais rendez-vous à la préfecture de Lyon pour renouveler mon titre de séjour. À huit heures du matin, j''attendais déjà devant l''entrée principale, dans le froid.',
   'La date exacte et le lieu détaillé installent le récit très nettement.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C1-S4 / INSUFFICIENT
  ('a031acda-b2ab-5c81-8639-af8dd93c7e01', '1401563f-95de-5cfa-b9df-35c8039d8056', 'INSUFFICIENT',
   'Il y avait une grève ce jour-là et mon train n''est pas parti. J''ai dû attendre très longtemps sur le quai, avec ma valise et mon billet à la main.',
   'On devine une gare, mais ni le jour ni la ville ne sont donnés.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C1-S4 / EXPECTED
  ('53069271-77d3-5aa9-ab45-ecf91aaa62a5', '1401563f-95de-5cfa-b9df-35c8039d8056', 'EXPECTED',
   'Jeudi dernier, j''étais à la gare de Bordeaux à sept heures du matin. Une grève des trains avait commencé pendant la nuit et tous les départs étaient annulés.',
   'Le jour, l''heure et la gare permettent de suivre le récit sans effort.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C1-S4 / EXCELLENT
  ('66cead03-f3d1-584e-9151-1c9b70ef9483', '1401563f-95de-5cfa-b9df-35c8039d8056', 'EXCELLENT',
   'Jeudi dernier, à sept heures du matin, j''étais sur le quai numéro trois de la gare de Bordeaux. Une grève des trains avait commencé pendant la nuit et presque personne ne le savait.',
   'Le quai nommé transforme un lieu général en endroit vraiment précis.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C1-S5 / INSUFFICIENT
  ('1ad8096b-6a8d-5e5e-9e60-a681ddf6480c', 'c492b3dc-1857-5826-9e38-5f61e0be92eb', 'INSUFFICIENT',
   'Je suis arrivé dans mon nouvel appartement avec toutes mes valises et mes cartons. C''était vraiment une journée très fatigante pour moi et pour mes amis.',
   'Sans date ni ville, le récit commence dans le flou.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C1-S5 / EXPECTED
  ('84b66cc4-6ff2-5ae2-836b-bb91275fd688', 'c492b3dc-1857-5826-9e38-5f61e0be92eb', 'EXPECTED',
   'Au début du mois de juin, j''ai emménagé dans un appartement à Nantes. Ce matin-là, je montais mes cartons au troisième étage avec mon frère.',
   'Le moment et le lieu conduisent naturellement vers l''action.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C1-S5 / EXCELLENT
  ('3f2ff281-8417-512f-a862-9505954cb646', 'c492b3dc-1857-5826-9e38-5f61e0be92eb', 'EXCELLENT',
   'Le 3 juin, en fin de matinée, je suis arrivé devant mon nouvel immeuble, rue des Acacias, à Nantes. Il faisait déjà très chaud et je montais mes cartons au troisième étage.',
   'L''adresse et l''heure servent l''action au lieu d''être ajoutées à côté.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C2-S1 / INSUFFICIENT
  ('03fb7f70-72bf-57aa-b639-1f7d94ff1c7f', 'a92b207d-9cac-5f67-8dbb-4eac43376990', 'INSUFFICIENT',
   'La fête du quartier était vraiment très réussie cette année encore. Tout le monde a beaucoup aimé la musique, les plats et l''ambiance de la soirée.',
   'C''est un avis général : ni lieu, ni personnes, ni activité de départ.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C2-S1 / EXPECTED
  ('ff18052f-13b8-5125-973c-43b6564aa187', 'a92b207d-9cac-5f67-8dbb-4eac43376990', 'EXPECTED',
   'J''étais dans la cour de mon immeuble avec mes voisins et leurs enfants. Nous préparions les tables et les chaises pour le repas du soir.',
   'Lieu, personnes et activité : la situation initiale est complète.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C2-S1 / EXCELLENT
  ('445a3ba0-78d9-50af-94fa-3e3cbb3c4878', 'a92b207d-9cac-5f67-8dbb-4eac43376990', 'EXCELLENT',
   'Ce samedi-là, j''étais dans la cour de mon immeuble avec ma voisine Fatou et son fils. Nous installions les tables et nous coupions des fruits pendant que la musique commençait.',
   'Les prénoms et les gestes précis rendent la scène facile à imaginer.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C2-S2 / INSUFFICIENT
  ('47e75188-5b13-597b-a53f-28bf8068247a', 'd70d4fa2-cb55-5340-9441-39a99f5749b7', 'INSUFFICIENT',
   'Le cours de français est très intéressant et la professeure explique toujours très bien. J''apprends beaucoup de choses nouvelles chaque semaine avec mes camarades de classe.',
   'Vous décrivez le cours en général, pas le moment qui ouvre le récit.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C2-S2 / EXPECTED
  ('7a388118-c8f3-55c9-94b6-3aaa8f819975', 'd70d4fa2-cb55-5340-9441-39a99f5749b7', 'EXPECTED',
   'J''étais assis dans la salle 4 de l''association avec cinq autres élèves. Nous relisions nos exercices de grammaire en attendant l''arrivée de la professeure de français.',
   'Le lecteur voit tout de suite où vous êtes et ce que vous faites.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C2-S2 / EXCELLENT
  ('8dedfd72-082e-5035-ac75-0d66d736eb74', 'd70d4fa2-cb55-5340-9441-39a99f5749b7', 'EXCELLENT',
   'Mardi soir, j''étais assis au fond de la salle 4 de l''association avec cinq autres élèves. Nous comparions nos exercices à voix basse pendant que la professeure installait le tableau.',
   'La place dans la salle et le détail sonore donnent une vraie scène.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C2-S3 / INSUFFICIENT
  ('78913823-dafa-56d1-a3b9-1b1589094b03', 'e0e269d9-dd84-5cef-8a64-a693f796e782', 'INSUFFICIENT',
   'Nous avons attendu très longtemps dans le couloir avant de voir le médecin. Ensuite, la visite s''est très bien passée et nous sommes rentrés à la maison.',
   'Le récit avance déjà alors que la situation de départ n''est pas posée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C2-S3 / EXPECTED
  ('0857c575-9b43-56bb-8d6a-a6f159c65baf', 'e0e269d9-dd84-5cef-8a64-a693f796e782', 'EXPECTED',
   'J''étais dans la salle d''attente du cabinet médical avec ma fille et son carnet de santé. Elle dessinait tranquillement et je remplissais un formulaire pour la mutuelle.',
   'Trois informations utiles en deux phrases : c''est exactement la cible.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C2-S3 / EXCELLENT
  ('1a4a5103-81e5-591d-b3d5-74b56f5a9df3', 'e0e269d9-dd84-5cef-8a64-a693f796e782', 'EXCELLENT',
   'Mercredi après-midi, j''étais assise dans la petite salle d''attente du cabinet, avec ma fille Awa sur les genoux. Elle regardait un livre d''images et je remplissais tranquillement le formulaire de la mutuelle.',
   'Chaque personne a une activité propre : la scène devient vivante.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C2-S4 / INSUFFICIENT
  ('8ed9d984-7a8d-5a82-8f11-093db213f9f2', '2c6aad67-05df-5298-8b75-2136f4fcd0b0', 'INSUFFICIENT',
   'Le voyage a duré presque quatre heures sur l''autoroute, avec un seul arrêt. Le conducteur roulait assez vite et il écoutait la radio pendant tout le trajet. Je suis arrivé très fatigué chez ma sœur, en fin d''après-midi, avec mal au dos.',
   'Ces phrases racontent déjà le trajet sans installer le point de départ.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C2-S4 / EXPECTED
  ('f50dd698-3071-58c5-8521-b8f7a286f9ae', '2c6aad67-05df-5298-8b75-2136f4fcd0b0', 'EXPECTED',
   'Samedi matin, j''étais devant la gare de Rennes, à côté d''une voiture grise. Le conducteur et deux autres passagers m''attendaient déjà sur le trottoir, avec leurs valises. Nous rangions nos sacs et nos manteaux dans le grand coffre avant de partir.',
   'Le décor est en place avant que le voyage ne commence.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C2-S4 / EXCELLENT
  ('42c4b902-9c4d-5cf8-8e59-398e0f76f331', '2c6aad67-05df-5298-8b75-2136f4fcd0b0', 'EXCELLENT',
   'Samedi matin, j''attendais devant la gare de Rennes avec mon sac à dos. Une voiture grise s''est arrêtée : le conducteur, Marc, voyageait avec deux autres passagers. Pendant que nous rangions les bagages dans le coffre, nous parlions de la route à faire.',
   'L''activité partagée relie naturellement les personnes au lieu.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C2-S5 / INSUFFICIENT
  ('4aa62337-ccdb-5648-aab5-98b70e0c6301', 'a56d2f64-b850-586b-b866-09ad7cb58059', 'INSUFFICIENT',
   'Un client s''est énervé à la caisse numéro deux et j''ai appelé mon responsable tout de suite. Après quelques minutes de discussion, tout est redevenu calme dans le magasin. C''était vraiment une journée très difficile pour toute l''équipe et pour moi.',
   'L''incident est déjà raconté ; la situation de départ reste absente.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C2-S5 / EXPECTED
  ('3d5a369f-abe3-5211-a333-d7d8d2cede3b', 'a56d2f64-b850-586b-b866-09ad7cb58059', 'EXPECTED',
   'C''était un vendredi soir, dans le grand magasin où je travaille depuis un an. J''étais à la caisse avec ma collègue Sonia. Il y avait beaucoup de clients dans les rayons et nous étions toutes les deux très occupées ce soir-là.',
   'Le décor est complet et l''incident n''est pas encore dévoilé.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C2-S5 / EXCELLENT
  ('4744fe53-1b30-56a9-9265-43124f75064c', 'a56d2f64-b850-586b-b866-09ad7cb58059', 'EXCELLENT',
   'Ce vendredi-là, vers dix-huit heures, le magasin était plein de clients pressés. J''étais à la caisse numéro deux et ma collègue Sonia rangeait les rayons juste à côté de moi. Nous travaillions vite, sans nous parler, mais tout se passait normalement.',
   'La dernière phrase crée une attente sans rien révéler : c''est habile.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C3-S1 / INSUFFICIENT
  ('2acd6ddd-0d88-52a0-8f88-6dd1ad823244', '690cabeb-365d-524a-bbd9-149d65e221f3', 'INSUFFICIENT',
   'Je fais mes courses au supermarché du quartier et j''achète du riz, des légumes et du poisson.',
   'L''action est au présent alors qu''elle appartient clairement au passé.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C3-S1 / EXPECTED
  ('6acee3f4-d52a-510d-b9d7-25857bdb7d15', '690cabeb-365d-524a-bbd9-149d65e221f3', 'EXPECTED',
   'Samedi matin, j''ai acheté du riz, des légumes et du poisson au supermarché de mon quartier.',
   'Le passé composé montre bien que l''action est terminée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C3-S1 / EXCELLENT
  ('f36d1a45-2a45-501d-a46c-5bc201632588', '690cabeb-365d-524a-bbd9-149d65e221f3', 'EXCELLENT',
   'Samedi matin, j''ai fait toutes mes courses en une heure et j''ai même trouvé le poisson frais que je cherchais depuis deux semaines.',
   'Deux actions terminées s''enchaînent, avec un imparfait bien placé pour le contexte.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C3-S2 / INSUFFICIENT
  ('76200684-16fe-5d01-8434-f5b55977349a', 'e6ea5311-e340-59a7-bc5b-0c31f46a9555', 'INSUFFICIENT',
   'Mon fils va à l''école tous les matins et il mange à la cantine avec ses camarades. Après le repas, il joue toujours au ballon avec ses amis dans la cour.',
   'Tout est au présent : rien n''indique que cela s''est passé hier.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C3-S2 / EXPECTED
  ('360fa52d-e7b4-59c5-842c-aea5449c9b1e', 'e6ea5311-e340-59a7-bc5b-0c31f46a9555', 'EXPECTED',
   'Hier, mon fils a mangé à la cantine avec ses camarades de classe. Ensuite, il a joué au ballon dans la cour pendant toute la récréation.',
   'Le passé composé situe correctement les deux actions dans la journée d''hier.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C3-S2 / EXCELLENT
  ('a9da3ff2-b0a7-5898-8fc6-163336fd5c7c', 'e6ea5311-e340-59a7-bc5b-0c31f46a9555', 'EXCELLENT',
   'Hier, mon fils a mangé à la cantine, puis il a joué au ballon toute la récréation. Le soir, il m''a montré le dessin qu''il a fait en classe.',
   'Trois actions terminées s''enchaînent sans jamais glisser vers le présent.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C3-S3 / INSUFFICIENT
  ('38e64005-6bdc-55af-8584-98a8a06112ca', '78efcddd-6b49-5f4e-80ef-acf20c4a6802', 'INSUFFICIENT',
   'J''ai attendu le bus à l''arrêt pendant plus de dix minutes ce matin-là. Une dame m''a demandé son chemin et je lui ai répondu avant l''arrivée du bus.',
   'Tout est au passé composé : le décor ne se distingue plus de l''action.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C3-S3 / EXPECTED
  ('ef886fb4-7cac-5086-b372-d9a106e694f6', '78efcddd-6b49-5f4e-80ef-acf20c4a6802', 'EXPECTED',
   'J''attendais le bus depuis dix minutes, à l''arrêt près de chez moi, quand une dame m''a demandé son chemin. Je lui ai expliqué la direction de la mairie.',
   'L''imparfait installe l''attente, le passé composé apporte l''événement.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C3-S3 / EXCELLENT
  ('a539e5cf-94ea-5185-ae1c-409ee7bfcfb1', '78efcddd-6b49-5f4e-80ef-acf20c4a6802', 'EXCELLENT',
   'Il pleuvait et j''attendais le bus depuis dix minutes lorsqu''une dame perdue m''a demandé son chemin. Je lui ai expliqué la direction de la mairie et elle m''a remercié deux fois.',
   'Deux imparfaits pour le décor, trois passés composés pour les actions : c''est net.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C3-S4 / INSUFFICIENT
  ('24bd2bc9-a212-58dd-a11e-0d60a29caa14', 'e76d19dc-c024-51fe-9a95-8cbdc641def3', 'INSUFFICIENT',
   'L''eau se coupe dans tout l''immeuble pendant que je prépare le dîner pour mes enfants. Je descends tout de suite voir la gardienne, qui habite au rez-de-chaussée. Elle appelle un plombier et elle me dit d''attendre chez moi jusqu''au soir.',
   'Le récit est au présent : les actions ne semblent pas terminées.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C3-S4 / EXPECTED
  ('03a064ea-09c0-5ad8-8b1e-b8f0f6612f16', 'e76d19dc-c024-51fe-9a95-8cbdc641def3', 'EXPECTED',
   'Je préparais le dîner dans la cuisine quand l''eau s''est arrêtée d''un coup. Je suis descendu voir la gardienne au rez-de-chaussée pour lui expliquer le problème. Elle a appelé un plombier tout de suite et elle m''a promis une réparation rapide.',
   'Le décor et les actions se répartissent correctement entre les deux temps.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C3-S4 / EXCELLENT
  ('4d86de97-bf01-569c-b29a-317da97c563c', 'e76d19dc-c024-51fe-9a95-8cbdc641def3', 'EXCELLENT',
   'Je préparais le dîner et mes enfants faisaient leurs devoirs quand l''eau s''est arrêtée d''un coup. Je suis descendu voir la gardienne, qui téléphonait déjà au syndic. Le plombier est passé une heure plus tard et a rouvert la vanne.',
   'Les temps alternent avec souplesse, même à l''intérieur d''une phrase.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C3-S5 / INSUFFICIENT
  ('67f4ef6d-ea3b-5186-afa9-eb3de72ac6fc', '5a869709-a731-5e10-81d4-39024c91769b', 'INSUFFICIENT',
   'J''étais un peu stressé en arrivant dans les bureaux de l''entreprise. La recruteuse était gentille et souriante, et la salle était très grande. Il y avait beaucoup de questions sur mon parcours et sur mes diplômes, et c''était assez long.',
   'Tout reste à l''imparfait : aucune action terminée n''apparaît.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C3-S5 / EXPECTED
  ('7c58550b-1173-5c6f-9a07-b5cd4bdd36a2', '5a869709-a731-5e10-81d4-39024c91769b', 'EXPECTED',
   'J''étais un peu stressé parce que la salle était grande et très silencieuse. La recruteuse m''a posé plusieurs questions sur mon expérience et sur mes horaires. J''ai répondu calmement à toutes ses questions et je suis sorti du bureau après trente minutes d''entretien.',
   'Le décor est à l''imparfait, les trois actions au passé composé.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C3-S5 / EXCELLENT
  ('5c58adcc-043b-5260-8e2b-0c8dc7b5592a', '5a869709-a731-5e10-81d4-39024c91769b', 'EXCELLENT',
   'Il faisait chaud dans la salle et j''attendais depuis dix minutes quand la recruteuse est entrée. Elle m''a posé des questions sur mon expérience et j''ai expliqué mon travail précédent. Nous nous sommes serré la main et je suis sorti, plus rassuré qu''à l''arrivée.',
   'Le passage d''un temps à l''autre suit exactement le rythme du récit.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C4-S1 / INSUFFICIENT
  ('b2218506-8360-5717-b2b2-08153632367f', 'affa70f5-3e1b-582f-9ffc-199ed9671153', 'INSUFFICIENT',
   'Je suis allé au distributeur près de chez moi, puis je suis rentré tranquillement à la maison.',
   'Rien ne change dans le récit : aucun événement ne se produit.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C4-S1 / EXPECTED
  ('0d7509b3-88e8-594a-ac18-e03283453efb', 'affa70f5-3e1b-582f-9ffc-199ed9671153', 'EXPECTED',
   'Soudain, l''écran s''est éteint et le distributeur a gardé ma carte bancaire à l''intérieur de la machine.',
   'Le mot « soudain » et l''action inattendue créent une vraie rupture.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C4-S1 / EXCELLENT
  ('da8bf52c-f477-543f-ae6f-d615140b6819', 'affa70f5-3e1b-582f-9ffc-199ed9671153', 'EXCELLENT',
   'J''ai tapé mon code et attendu les billets quand, tout à coup, l''écran s''est éteint et la machine a avalé ma carte.',
   'L''attente juste avant rend la surprise beaucoup plus forte.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C4-S2 / INSUFFICIENT
  ('a294d92f-bc6f-5f46-918d-3bf251734b36', '56c9f948-fd27-5549-9f50-7ea2ec5444de', 'INSUFFICIENT',
   'Nous avons regardé le match avec mes amis et il a plu un peu pendant la deuxième mi-temps, sur le stade.',
   'L''imprévu est noyé dans la phrase : on ne sent aucune rupture.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C4-S2 / EXPECTED
  ('37a3e1e3-92c6-5846-9287-7533521f5fb8', '56c9f948-fd27-5549-9f50-7ea2ec5444de', 'EXPECTED',
   'Tout à coup, un orage très fort a éclaté sur le stade et l''arbitre a arrêté le match pendant vingt minutes.',
   'L''expression de rupture annonce clairement le changement de situation.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C4-S2 / EXCELLENT
  ('fca4153a-6126-5ff2-aeec-362d5db60fa9', '56c9f948-fd27-5549-9f50-7ea2ec5444de', 'EXCELLENT',
   'À la vingtième minute, le ciel est devenu tout noir ; soudain, un orage a éclaté et l''arbitre a arrêté le match.',
   'Le ciel qui s''assombrit prépare le déclencheur : l''effet est plus fort.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C4-S3 / INSUFFICIENT
  ('f9e0aafb-ee93-5cb8-89c1-84753cd27398', '5195131e-e903-5255-a708-d8bf03590c5e', 'INSUFFICIENT',
   'Le trajet était normal ce soir-là et le bus n''était pas trop plein. Une personne ne se sentait pas bien et le bus s''est arrêté un moment sur le côté.',
   'L''événement arrive sans marque : on ne voit pas le basculement.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C4-S3 / EXPECTED
  ('d8e6f370-ff29-5214-bbee-fabe2bd0b22f', '5195131e-e903-5255-a708-d8bf03590c5e', 'EXPECTED',
   'Le bus roulait tranquillement sur l''avenue quand, tout à coup, un passager s''est senti mal. Le chauffeur s''est arrêté immédiatement et a ouvert les portes.',
   'La rupture est marquée et une conséquence suit tout de suite.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C4-S3 / EXCELLENT
  ('2d3a9341-74d5-5bcc-a298-76c0c217d3e8', '5195131e-e903-5255-a708-d8bf03590c5e', 'EXCELLENT',
   'Le bus roulait tranquillement et je lisais mes messages quand, brusquement, un passager assis devant moi a demandé de l''aide. Le chauffeur a garé le bus sur le côté et a appelé les secours.',
   'Le calme d''avant fait ressortir le déclencheur avec beaucoup de netteté.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C4-S4 / INSUFFICIENT
  ('3a0963ab-e44a-544b-b9e5-3152a6e722ec', '708d2ed6-0690-55c1-a7e5-e54e93732811', 'INSUFFICIENT',
   'Mon train de 14 heures était supprimé ce jour-là à cause d''un problème technique. J''ai pris un autre train un peu plus tard dans l''après-midi.',
   'L''information est donnée, mais rien ne montre l''effet de surprise.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C4-S4 / EXPECTED
  ('1123ca91-2169-5545-a37c-69fe71d5f6ba', '708d2ed6-0690-55c1-a7e5-e54e93732811', 'EXPECTED',
   'Soudain, une voix a annoncé dans le haut-parleur que le train de 14 heures était supprimé. Tous les voyageurs se sont dirigés vers le guichet.',
   'L''annonce déclenche une réaction visible : le récit avance.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C4-S4 / EXCELLENT
  ('1b274279-6896-5569-bbd0-b4810654360a', '708d2ed6-0690-55c1-a7e5-e54e93732811', 'EXCELLENT',
   'J''étais assis sur un banc quand une annonce a résonné dans toute la gare : le train de 14 heures était supprimé. En quelques secondes, une longue file s''est formée devant le guichet.',
   'La vitesse de la réaction montre la force du déclencheur.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C4-S5 / INSUFFICIENT
  ('ac03a5e2-b27d-5405-bc55-e83830344fb2', '39be895e-a669-5f56-b634-22bf3f0acb09', 'INSUFFICIENT',
   'L''employée a regardé mon dossier au guichet pendant quelques minutes, sans rien dire. Il manquait un papier important, le justificatif de domicile, pour terminer ma demande. Je suis donc revenu une autre fois avec le document, quinze jours plus tard.',
   'Les faits sont exacts, mais la rupture n''est pas mise en valeur.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C4-S5 / EXPECTED
  ('1ecef998-d13b-5977-b69f-1e192c8ce70a', '39be895e-a669-5f56-b634-22bf3f0acb09', 'EXPECTED',
   'J''ai posé mon dossier sur le comptoir et l''employée l''a ouvert devant moi. Soudain, elle m''a annoncé qu''il manquait mon justificatif de domicile de moins de trois mois. J''ai dû quitter le guichet et reprendre un rendez-vous pour le mois suivant.',
   'L''annonce coupe le récit en deux et provoque une conséquence claire.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C4-S5 / EXCELLENT
  ('04106fa2-e11c-5e6e-bee8-3ef082a0eacd', '39be895e-a669-5f56-b634-22bf3f0acb09', 'EXCELLENT',
   'J''attendais depuis une heure quand mon numéro est enfin apparu à l''écran. L''employée a feuilleté mon dossier, puis elle a levé les yeux d''un coup : il manquait mon justificatif de domicile. En une minute, mon rendez-vous était terminé et j''ai dû en reprendre un autre pour le mois suivant.',
   'L''attente longue puis la bascule en une minute rendent le choc sensible.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C5-S1 / INSUFFICIENT
  ('9a4c5106-74b4-5ad1-9132-dbb0e909f680', '973e7719-9fe5-55e3-9532-85625621d4ab', 'INSUFFICIENT',
   'J''ai reçu ma carte de bibliothèque à la fin de la visite. Je suis allé au guichet avec mes papiers d''identité et un justificatif de domicile. J''ai choisi deux livres dans le rayon des romans avant de partir chez moi.',
   'Les étapes sont justes mais mélangées, sans mot pour guider le lecteur.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C5-S1 / EXPECTED
  ('409cac43-9cd0-5298-9e01-b9b0ebeabbef', '973e7719-9fe5-55e3-9532-85625621d4ab', 'EXPECTED',
   'D''abord, je suis allé au guichet de la bibliothèque avec ma pièce d''identité et un justificatif de domicile. Ensuite, l''employée a créé mon compte de lecteur dans l''ordinateur. Finalement, j''ai emprunté deux livres et un magazine pour une durée de deux semaines.',
   'Trois connecteurs, trois étapes dans le bon ordre : c''est très lisible.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C5-S1 / EXCELLENT
  ('5cb660c9-5744-5191-a2d5-86b60b7df606', '973e7719-9fe5-55e3-9532-85625621d4ab', 'EXCELLENT',
   'D''abord, je me suis présenté au guichet avec ma pièce d''identité et un justificatif de domicile. Ensuite, l''employée a rempli ma fiche et m''a remis une carte bleue à mon nom. Finalement, j''ai emprunté deux romans et je suis reparti très content.',
   'L''ordre est net et chaque étape porte une information utile.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C5-S2 / INSUFFICIENT
  ('0fec7f15-e49b-5141-bcb2-188cce0cd698', '0cd035b2-55e7-5e9a-92fe-5a7e7a854869', 'INSUFFICIENT',
   'Le technicien est venu réparer le chauffage un matin de la semaine suivante, vers neuf heures. J''ai envoyé un message et une photo à mon propriétaire. J''ai remarqué que l''appartement était vraiment très froid depuis deux ou trois jours déjà.',
   'Le récit remonte le temps : l''ordre des actions est inversé.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C5-S2 / EXPECTED
  ('49f3e944-e434-58d6-91a1-bb4da2651d7d', '0cd035b2-55e7-5e9a-92fe-5a7e7a854869', 'EXPECTED',
   'D''abord, un matin, j''ai vu que tous les radiateurs de l''appartement restaient froids malgré le thermostat. Ensuite, j''ai téléphoné à mon propriétaire pour lui expliquer la panne. Finalement, un technicien est venu le lendemain matin pour réparer la chaudière collective.',
   'L''enchaînement suit l''ordre réel et se comprend du premier coup.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C5-S2 / EXCELLENT
  ('68975b16-87bb-57d4-85a9-0e3ab27252bb', '0cd035b2-55e7-5e9a-92fe-5a7e7a854869', 'EXCELLENT',
   'Le matin, j''ai d''abord remarqué que les radiateurs restaient froids malgré le thermostat. J''ai ensuite envoyé une photo de la chaudière à mon propriétaire, qui a appelé une entreprise. Le technicien est finalement venu le lendemain et a changé une pièce.',
   'Les connecteurs sont placés à l''intérieur des phrases, ce qui est plus naturel.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C5-S3 / INSUFFICIENT
  ('bc7c1ff0-650e-5162-82fa-2fe40e62f7d6', '3c6360e2-8073-5e75-90ca-27102b0b6aba', 'INSUFFICIENT',
   'J''ai passé l''oral avec l''examinatrice vers midi, dans une petite salle. Avant, il y avait les épreuves écrites avec tous les autres candidats. Je suis arrivé à huit heures le matin et j''ai montré ma convocation à l''accueil du centre.',
   'L''ordre se reconstruit en cours de route, ce qui gêne la lecture.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C5-S3 / EXPECTED
  ('da6fec11-c4da-509c-998e-9d4f2dff4100', '3c6360e2-8073-5e75-90ca-27102b0b6aba', 'EXPECTED',
   'D''abord, j''ai présenté ma convocation et ma pièce d''identité à l''accueil, à huit heures. Ensuite, j''ai passé les épreuves écrites pendant deux heures dans une grande salle. Finalement, je suis passé à l''oral en fin de matinée, avec une examinatrice.',
   'La chronologie est respectée et facile à suivre du début à la fin.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C5-S3 / EXCELLENT
  ('47dbea72-a61a-50b7-9d99-c85c08bff400', '3c6360e2-8073-5e75-90ca-27102b0b6aba', 'EXCELLENT',
   'D''abord, je suis arrivé à huit heures et j''ai montré ma convocation à l''accueil. On nous a ensuite installés dans une grande salle pour les épreuves écrites, qui ont duré deux heures. Finalement, je suis passé à l''oral vers midi et je suis sorti soulagé.',
   'Les durées ajoutées renforcent la chronologie sans l''alourdir.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C5-S4 / INSUFFICIENT
  ('52933775-87c0-5dd4-8239-903da05bff72', '990fc0b5-a5c1-5d5f-bf2f-0c0b9468238c', 'INSUFFICIENT',
   'J''ai appelé ma banque pour faire opposition sur ma carte bancaire. Ma carte n''était plus dans mon portefeuille quand j''ai voulu payer mes courses. Après, j''ai cherché partout dans mes poches et dans mon sac à dos, pendant dix minutes.',
   'Les actions sont vraies, mais leur ordre ne correspond pas à la réalité.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C5-S4 / EXPECTED
  ('9bb6bdfe-925d-556d-b43c-17cf9e8fdea3', '990fc0b5-a5c1-5d5f-bf2f-0c0b9468238c', 'EXPECTED',
   'D''abord, j''ai remarqué que ma carte n''était plus dans mon portefeuille, en sortant du magasin. Ensuite, j''ai téléphoné à ma banque pour faire opposition tout de suite. Finalement, j''ai reçu une nouvelle carte à mon adresse une semaine plus tard.',
   'Trois étapes claires, dans l''ordre où elles se sont réellement produites.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C5-S4 / EXCELLENT
  ('fbd83499-5d16-55f9-9bb0-5c8bbc3cc4b4', '990fc0b5-a5c1-5d5f-bf2f-0c0b9468238c', 'EXCELLENT',
   'En sortant du supermarché, j''ai d''abord remarqué que ma carte n''était plus dans mon portefeuille. J''ai aussitôt appelé ma banque pour faire opposition, puis je suis passé à l''agence signer un papier. Une semaine plus tard, j''ai finalement reçu une nouvelle carte à mon adresse.',
   'Quatre étapes s''enchaînent avec des connecteurs différents, sans répétition.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C5-S5 / INSUFFICIENT
  ('b3c1b353-4dde-544b-93fd-383e7ced60d4', 'bc5e259c-d41c-5adb-a322-7bae18e71bd3', 'INSUFFICIENT',
   'D''abord, j''ai fait tous les cartons du studio pendant le week-end, avec ma sœur. Ensuite, j''ai déménagé le samedi avec un ami et sa vieille camionnette. Ensuite, j''ai rangé toutes mes affaires dans le nouvel appartement pendant plusieurs jours, sans me presser.',
   'Les étapes sont trop peu nombreuses et le même connecteur revient.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C5-S5 / EXPECTED
  ('e4d249fb-253d-5260-994c-14ff223800fb', 'bc5e259c-d41c-5adb-a322-7bae18e71bd3', 'EXPECTED',
   'D''abord, j''ai fait mes cartons pendant deux soirées, après le travail. Ensuite, un ami est venu avec sa camionnette et nous avons chargé les meubles. Puis nous avons tout monté au deuxième étage et j''ai enfin rangé la cuisine avant la nuit.',
   'Quatre étapes distinctes, avec des connecteurs qui ne se répètent pas.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C5-S5 / EXCELLENT
  ('ea3db49f-cfae-5f32-81c8-e96f5a986a5e', 'bc5e259c-d41c-5adb-a322-7bae18e71bd3', 'EXCELLENT',
   'D''abord, j''ai trié mes affaires et rempli une dizaine de cartons pendant la semaine. Le samedi matin, un ami est arrivé avec une camionnette ; nous avons chargé les meubles, puis traversé la ville en une demi-heure. Nous avons ensuite tout monté au deuxième étage et j''ai finalement installé la cuisine avant la nuit.',
   'Six étapes s''enchaînent et le récit garde un rythme très clair.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C6-S1 / INSUFFICIENT
  ('342358e6-3fc4-5bbf-bffe-abb4f6af7e0f', '89cda19d-5c34-5786-814f-5dc2fefbb5ed', 'INSUFFICIENT',
   'Je suis arrivé en retard à la gare ce matin-là et j''ai raté mon train. C''était vraiment dommage parce que j''avais un rendez-vous important à Paris.',
   'Le récit reste général : aucun détail ne permet d''imaginer la scène.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C6-S1 / EXPECTED
  ('cdf3f2dd-b00e-586c-b6bf-b27fedef7ea6', '89cda19d-5c34-5786-814f-5dc2fefbb5ed', 'EXPECTED',
   'Je suis arrivé à la gare de Lille à 7 h 35, cinq minutes trop tard. Mon train pour Paris partait du quai 12 et il roulait déjà.',
   'L''heure et le numéro de quai suffisent à rendre la scène concrète.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C6-S1 / EXCELLENT
  ('d73f0095-b3a6-5241-8feb-db7ce2f8d82f', '89cda19d-5c34-5786-814f-5dc2fefbb5ed', 'EXCELLENT',
   'Je suis arrivé à la gare de Lille à 7 h 35, essoufflé, avec ma valise à roulettes. Sur le grand panneau jaune, mon train de 7 h 30 pour Paris était déjà indiqué « parti », quai 12.',
   'Le panneau et la valise ancrent le récit sans le faire dévier.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C6-S2 / INSUFFICIENT
  ('92a6e6e0-a981-507d-9a25-69bfc155ae6a', '54df9807-b352-545e-8bb5-f64cb44d963a', 'INSUFFICIENT',
   'Le repas était vraiment très bon et tous les invités étaient sympathiques avec moi. Nous avons passé une excellente soirée ensemble, chez mes voisins du deuxième étage.',
   'Ce sont des impressions ; rien de concret n''apparaît dans le texte.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C6-S2 / EXPECTED
  ('4b8e4b9a-bb2f-5fa1-8cd6-679e32f2273d', '54df9807-b352-545e-8bb5-f64cb44d963a', 'EXPECTED',
   'Ma voisine avait préparé un couscous aux légumes et un gâteau au citron pour le dessert. Nous étions huit autour d''une grande table, dans le salon.',
   'Les plats nommés et le nombre d''invités rendent la scène réelle.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C6-S2 / EXCELLENT
  ('a3080be5-99d0-5a90-9bd5-c2e93ffc556f', '54df9807-b352-545e-8bb5-f64cb44d963a', 'EXCELLENT',
   'Ma voisine Nadia avait préparé un couscous aux légumes et un gâteau au citron encore tiède. Nous étions huit, serrés autour d''une table un peu trop petite, dans son salon décoré de guirlandes.',
   'Trois détails choisis, tous au service du même moment de la soirée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C6-S3 / INSUFFICIENT
  ('0ec31f85-74cf-5846-8a5f-340dc1e01eef', 'a385b183-9189-5b1e-89c7-3cc857e1ce49', 'INSUFFICIENT',
   'Je suis arrivé assez en avance et j''ai attendu un long moment avant l''heure du rendez-vous. Il y avait une salle d''attente au rez-de-chaussée de l''immeuble, comme partout. Ensuite, l''entretien a commencé et tout s''est passé assez normalement pour moi.',
   'Le décor est nommé mais jamais décrit : la scène reste vide.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C6-S3 / EXPECTED
  ('fdb115a6-2f3f-54b5-99fb-6f2d1dd2adbd', 'a385b183-9189-5b1e-89c7-3cc857e1ce49', 'EXPECTED',
   'Je suis arrivé vingt minutes en avance devant un immeuble en verre. Dans le hall, une hôtesse m''a demandé mon nom et m''a donné un badge. J''ai attendu sur un canapé noir, mon dossier posé sur les genoux, pendant dix minutes.',
   'Deux détails visuels suffisent à installer clairement le lieu.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C6-S3 / EXCELLENT
  ('82f09a4c-a76f-539c-881f-a5af37441174', 'a385b183-9189-5b1e-89c7-3cc857e1ce49', 'EXCELLENT',
   'Je suis arrivé vingt minutes en avance devant un immeuble en verre, juste à côté de l''arrêt de tramway. Dans le hall, une hôtesse en veste bleue a noté mon nom et m''a donné un badge. J''ai attendu sur un canapé noir, mon dossier serré sur les genoux, en écoutant l''ascenseur monter et descendre.',
   'Chaque détail sert l''attente : rien n''est décoratif ni hors sujet.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C6-S4 / INSUFFICIENT
  ('943b2ed8-a1a8-5683-a4e6-ff730046307c', '3da289ca-4821-5787-bec5-cfb6f37743f1', 'INSUFFICIENT',
   'Je suis allé à la pharmacie près de chez moi et j''ai acheté le médicament. C''était assez rapide finalement et je suis rentré tout de suite.',
   'Le lecteur ne voit ni le produit, ni l''échange, ni le moment.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C6-S4 / EXPECTED
  ('4edaa8e6-3ef5-502a-bd09-878d0f96219d', '3da289ca-4821-5787-bec5-cfb6f37743f1', 'EXPECTED',
   'À la pharmacie de la place, j''ai donné l''ordonnance de ma mère au pharmacien. Il m''a expliqué de lui donner un comprimé le matin et un le soir.',
   'L''explication du pharmacien donne un contenu concret à l''échange.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C6-S4 / EXCELLENT
  ('ae3643c5-40bb-5319-a594-9d7d2691828d', '3da289ca-4821-5787-bec5-cfb6f37743f1', 'EXCELLENT',
   'Vers dix-huit heures, la pharmacie de la place était pleine et j''ai attendu derrière trois personnes. Le pharmacien a lu l''ordonnance de ma mère, a entouré la posologie au stylo et m''a répété de donner un comprimé matin et soir.',
   'Le geste du stylo rend l''échange vivant en très peu de mots.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C6-S5 / INSUFFICIENT
  ('b77c6f34-5568-55bd-8775-ab8ef2f2f579', '03c3742e-e06d-5102-9105-e5dc93744764', 'INSUFFICIENT',
   'L''appartement était plutôt bien mais vraiment un peu trop cher pour mon petit budget. J''ai visité pendant une demi-heure avec l''agent immobilier de l''agence du quartier. J''ai réfléchi ensuite pendant deux ou trois jours avant de donner ma réponse à l''agence.',
   'Les jugements remplacent les détails : rien ne se voit dans le texte.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C6-S5 / EXPECTED
  ('f3bbe4bd-7196-53c3-bec4-3e907db51232', '03c3742e-e06d-5102-9105-e5dc93744764', 'EXPECTED',
   'L''agence m''a fait visiter un deux-pièces au quatrième étage, dans un immeuble sans ascenseur. La cuisine était petite, mais le salon donnait sur une cour très calme. Le loyer était de 650 euros par mois, charges comprises, et sans travaux à prévoir.',
   'Chaque détail donné pèse vraiment dans la décision de louer.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C6-S5 / EXCELLENT
  ('a1f1e00c-f4ff-571a-8217-2cd97d6fdff2', '03c3742e-e06d-5102-9105-e5dc93744764', 'EXCELLENT',
   'L''agent m''a ouvert un deux-pièces au quatrième étage, dans un immeuble sans ascenseur. La cuisine tenait dans trois mètres carrés, mais le salon donnait sur une cour calme et recevait le soleil du matin. À 650 euros charges comprises, j''ai compris que j''accepterais les escaliers.',
   'Les détails s''opposent entre eux et expliquent le choix final.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C7-S1 / INSUFFICIENT
  ('512c3499-5f0c-5f49-86f1-88cd91631c0c', 'a6933d70-2df7-5b48-b163-6ff858699fc3', 'INSUFFICIENT',
   'J''ai cherché mes clés dans tout mon sac et dans mes poches, sans les trouver. J''ai attendu devant la porte de mon appartement pendant presque une heure.',
   'Les faits sont clairs, mais le ressenti n''apparaît nulle part.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C7-S1 / EXPECTED
  ('80364f7f-6eaa-5092-8fe2-d8d914b0541e', 'a6933d70-2df7-5b48-b163-6ff858699fc3', 'EXPECTED',
   'Quand j''ai compris que mes clés étaient vraiment perdues, j''ai eu très peur. Je pensais que je ne pourrais pas dormir chez moi cette nuit-là.',
   'Le sentiment est nommé et sa cause est immédiatement expliquée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C7-S1 / EXCELLENT
  ('8442bd36-23c6-5de8-b29b-6aee3bb3f8a5', 'a6933d70-2df7-5b48-b163-6ff858699fc3', 'EXCELLENT',
   'Devant ma porte fermée, j''ai d''abord senti la panique monter : il était vingt-deux heures et je ne savais qui appeler. Puis je me suis souvenu du double chez ma voisine et je me suis calmé tout de suite.',
   'Le ressenti change avec la situation : c''est ce qui rend le récit vrai.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C7-S2 / INSUFFICIENT
  ('ba5082e5-267c-552e-876f-f8021461aca5', '471a25ac-4c8b-5fea-85f9-dc26031ca93a', 'INSUFFICIENT',
   'J''ai reçu le résultat de mon permis de conduire sur le site Internet de l''auto-école. Il était positif et j''ai appelé ma famille le soir même.',
   'L''émotion manque alors que le moment s''y prête vraiment.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C7-S2 / EXPECTED
  ('3b2145e6-470f-56ff-b43a-e64f0c4d9e8b', '471a25ac-4c8b-5fea-85f9-dc26031ca93a', 'EXPECTED',
   'Quand j''ai vu le résultat sur le site, j''étais tellement heureuse que j''ai crié dans la cuisine. J''ai téléphoné à ma sœur tout de suite.',
   'La joie est exprimée et directement liée à la lecture du résultat.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C7-S2 / EXCELLENT
  ('bbc138d6-4773-5729-a1b4-76c11d68b150', '471a25ac-4c8b-5fea-85f9-dc26031ca93a', 'EXCELLENT',
   'Quand le mot « favorable » est apparu sur l''écran, je suis restée immobile deux secondes, puis j''ai éclaté de rire toute seule. Après deux échecs, ce petit mot valait tous les efforts de l''année.',
   'La réaction physique et le passé difficile donnent du poids à la joie.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C7-S3 / INSUFFICIENT
  ('2d9691e0-92ef-5258-8dc2-3d7d8d32b54f', '60fbb16e-2d6b-5963-926f-a9e01f236a45', 'INSUFFICIENT',
   'J''étais très stressé avant le rendez-vous à la mairie de mon quartier. Le rendez-vous s''est bien passé avec l''employée du guichet et il n''a pas duré longtemps. J''étais vraiment content après, en rentrant chez moi à pied ce jour-là, avec mes papiers.',
   'Les émotions sont là, mais jamais expliquées par la situation.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C7-S3 / EXPECTED
  ('122664eb-a1d1-5256-be70-a94a13b6defb', '60fbb16e-2d6b-5963-926f-a9e01f236a45', 'EXPECTED',
   'Avant le rendez-vous, j''avais peur de ne pas comprendre les questions de l''employée. Pendant l''entretien, elle a parlé lentement et je me suis senti beaucoup plus calme. En sortant de la mairie, j''étais fier d''avoir réussi cette démarche tout seul.',
   'Chaque sentiment a une cause précise et l''ensemble progresse bien.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C7-S3 / EXCELLENT
  ('2d307bcc-ecb0-58a6-8a0f-b9aa23fee269', '60fbb16e-2d6b-5963-926f-a9e01f236a45', 'EXCELLENT',
   'En montant les marches de la mairie, j''avais le cœur qui battait vite : je craignais de ne pas comprendre les questions. L''employée a parlé lentement et a répété deux fois ; petit à petit, ma voix est devenue plus sûre. En sortant avec mon récépissé, j''étais fier, parce que c''était la première fois que je faisais tout sans aide.',
   'Le corps, la voix et la fierté racontent l''émotion sans la répéter.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C7-S4 / INSUFFICIENT
  ('545e4ffb-98bb-5ffe-bd22-cbfc9a07a288', '1657c8d4-5da5-5918-88a9-c2db12eefefb', 'INSUFFICIENT',
   'Mon voisin du dessus m''a aidée à porter mes courses jusqu''au troisième étage, un jour de pluie. C''était vraiment très gentil de sa part de faire ça.',
   '« Gentil » qualifie le voisin sans dire ce que vous avez ressenti.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C7-S4 / EXPECTED
  ('52bcfaec-e116-56ad-b946-661990ac48a3', '1657c8d4-5da5-5918-88a9-c2db12eefefb', 'EXPECTED',
   'Mon voisin est descendu m''aider à porter mes courses sous la pluie, sans hésiter. J''ai été très touchée par son geste, parce que je le connaissais à peine.',
   'Le sentiment est nommé et sa raison est donnée en quelques mots.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C7-S4 / EXCELLENT
  ('1e46fce3-4ae3-599a-a68e-87456cd19bc8', '1657c8d4-5da5-5918-88a9-c2db12eefefb', 'EXCELLENT',
   'Quand mon sac s''est déchiré dans l''escalier, mon voisin du dessus est descendu ramasser mes courses sans que je demande rien. J''ai été touchée par ce geste si simple : ce jour-là, je me suis vraiment sentie chez moi dans cet immeuble.',
   'Le ressenti dépasse l''instant et dit quelque chose de plus large.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C7-S5 / INSUFFICIENT
  ('44642cad-8e68-52e9-8fba-d9edd0eeda5e', '19fc4fe1-74f8-5052-9c38-c483c1dd98ab', 'INSUFFICIENT',
   'L''entretien pour ce poste de vendeur n''a pas bien marché ce jour-là, malgré ma longue préparation. J''étais vraiment déçu en sortant du bureau de l''entreprise, en fin de matinée. Je cherche un autre travail maintenant, dans le même domaine, près de chez moi.',
   'Un seul sentiment est cité, sans lien clair avec ce qui s''est passé.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C7-S5 / EXPECTED
  ('d51f6a0d-8a71-5bcf-9322-d1b8f760994f', '19fc4fe1-74f8-5052-9c38-c483c1dd98ab', 'EXPECTED',
   'Au début, j''étais confiant parce que je connaissais bien le métier. Quand le recruteur m''a dit que mon expérience ne suffisait pas, je me suis senti découragé. Le soir, j''étais plus calme et j''ai décidé de mieux me préparer pour la prochaine fois.',
   'Trois moments, trois états : le lecteur suit toute l''évolution.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C7-S5 / EXCELLENT
  ('a37c8b20-e6d0-52b6-b7c0-2b4c87eb19b5', '19fc4fe1-74f8-5052-9c38-c483c1dd98ab', 'EXCELLENT',
   'Je suis entré confiant : j''avais préparé mes réponses et je connaissais le métier. Mais quand le recruteur a répété que mon expérience française était trop courte, ma gorge s''est serrée et je n''ai plus trouvé mes mots. Le soir, la déception était encore là, pourtant j''y ai vu une chose utile : je sais maintenant quelle question me met en difficulté.',
   'La déception débouche sur une prise de recul, sans discours tout fait.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C8-S1 / INSUFFICIENT
  ('a5f5ca46-2578-58b0-9cbe-9d60bf12078e', '127f09ce-98c4-546e-8dd1-6305375b48da', 'INSUFFICIENT',
   'J''ai appelé le service client plusieurs fois et j''ai expliqué mon problème à chaque nouvel interlocuteur. C''était vraiment très long et très fatigant pour moi.',
   'Le récit s''arrête avant la fin : on ne sait pas comment cela se termine.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C8-S1 / EXPECTED
  ('9579b9f9-ddfb-524d-8a2d-4ec141d8653f', '127f09ce-98c4-546e-8dd1-6305375b48da', 'EXPECTED',
   'Finalement, le transporteur a retrouvé mon colis dans un autre dépôt, près de Lyon. Je l''ai reçu chez moi trois jours plus tard, en bon état.',
   'Le résultat est net : le lecteur sait exactement comment cela finit.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C8-S1 / EXCELLENT
  ('1ed6f71a-673d-592a-93e3-e2a60391c31b', '127f09ce-98c4-546e-8dd1-6305375b48da', 'EXCELLENT',
   'Après trois appels, le transporteur a retrouvé mon colis dans un dépôt voisin. Je l''ai reçu le vendredi suivant et, depuis, je fais toujours livrer mes commandes en point relais.',
   'Au résultat s''ajoute une habitude nouvelle : la fin est complète.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C8-S2 / INSUFFICIENT
  ('287adafb-81fc-5496-89bb-9a6edbda0669', 'aa305497-6f7f-51bb-aa5e-6acdfab3a767', 'INSUFFICIENT',
   'Les cours étaient très intéressants et la professeure était toujours patiente avec nous. J''ai beaucoup aimé cette année passée dans cette association, avec mes camarades.',
   'Le bilan reste au niveau du plaisir ; le résultat concret manque.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C8-S2 / EXPECTED
  ('94383d06-9e05-5593-8ef3-0ae1bbd2d8f2', 'aa305497-6f7f-51bb-aa5e-6acdfab3a767', 'EXPECTED',
   'À la fin de l''année, j''ai obtenu mon attestation de niveau A2. Maintenant, je peux téléphoner à l''école de mes enfants sans demander de l''aide à personne.',
   'Un résultat précis, puis un changement visible dans la vie quotidienne.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C8-S2 / EXCELLENT
  ('47615684-d06e-5c08-a2b2-a3233482ec23', 'aa305497-6f7f-51bb-aa5e-6acdfab3a767', 'EXCELLENT',
   'En juin, j''ai obtenu mon attestation de niveau A2 avec une bonne note à l''oral. Depuis, je téléphone moi-même à l''école de mes enfants et j''ai osé m''inscrire au cours suivant.',
   'Deux conséquences concrètes montrent l''effet réel de cette année.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C8-S3 / INSUFFICIENT
  ('181d43b6-1c98-5d7a-bb7a-eb212e097e6b', '0cb661d2-89a7-5964-9021-a72c5751e9ac', 'INSUFFICIENT',
   'Le plombier est venu et il a regardé le plafond de la salle de bains pendant un moment. Il a dit que la fuite venait de l''appartement du dessus, au quatrième étage. J''ai attendu des nouvelles de l''assurance pendant plusieurs jours.',
   'Le récit s''interrompt : ni réparation terminée, ni suite pour vous.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C8-S3 / EXPECTED
  ('54b6be21-2c5b-50b7-97ec-c88cba6ee0e8', '0cb661d2-89a7-5964-9021-a72c5751e9ac', 'EXPECTED',
   'Le plombier est venu réparer le tuyau du voisin du dessus dès le lendemain. Les travaux de peinture ont été faits deux semaines plus tard. Depuis, la salle de bains est bien sèche et le plafond n''a plus aucune trace d''humidité.',
   'La réparation, le résultat et l''état actuel sont tous les trois donnés.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C8-S3 / EXCELLENT
  ('765dba32-df05-582d-8353-7e6f2d72f6ac', '0cb661d2-89a7-5964-9021-a72c5751e9ac', 'EXCELLENT',
   'Le plombier a trouvé la fuite chez le voisin du dessus et a changé le tuyau le jour même. L''assurance de l''immeuble a payé la peinture, refaite deux semaines plus tard. Depuis, le plafond est propre et j''ai appris à prévenir la gardienne dès la première tache.',
   'La leçon tirée à la fin donne au récit une vraie conclusion.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C8-S4 / INSUFFICIENT
  ('3843f1be-4e45-56e9-a1ba-abf75cca1c87', '4ca39470-94ad-5946-94d5-5224c42c8630', 'INSUFFICIENT',
   'Je suis arrivé une heure en retard ce matin-là à cause de la grève des trains. Mon responsable n''était pas content du tout quand il m''a vu. La journée a été très longue et très fatigante pour moi et mes collègues.',
   'On reste sur l''incident : aucune issue ni suite n''est donnée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C8-S4 / EXPECTED
  ('945155b0-fed1-533e-8e4d-b5ef3cb51e41', '4ca39470-94ad-5946-94d5-5224c42c8630', 'EXPECTED',
   'Mon responsable a compris la situation parce que la grève était annoncée partout depuis la veille. J''ai rattrapé mon heure de retard le soir même, après la fermeture. Depuis, je pars vingt minutes plus tôt le matin pour être tranquille.',
   'L''incident se referme et un changement durable est indiqué.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C8-S4 / EXCELLENT
  ('ec55cd81-1a09-5343-b73f-c8a53a27eae7', '4ca39470-94ad-5946-94d5-5224c42c8630', 'EXCELLENT',
   'Mon responsable a d''abord soupiré, puis il a vu l''annonce de la grève sur son téléphone et il a accepté mon explication. J''ai rattrapé mon heure le soir même, sans discuter. Depuis, je regarde l''application des transports avant de me coucher et je pars vingt minutes plus tôt.',
   'La conséquence est double et se voit concrètement dans vos habitudes.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C8-S5 / INSUFFICIENT
  ('3827d3a4-c44b-5ecc-829d-df6f7fd9ed03', 'ccef48ba-9091-5429-bded-41de31cfc92b', 'INSUFFICIENT',
   'Après beaucoup de rendez-vous et beaucoup d''attente, j''ai enfin reçu une réponse à ma demande, au mois d''avril. J''étais vraiment très soulagé ce jour-là, en ouvrant le courrier. C''était une période longue et difficile pour moi et pour ma famille.',
   'Le résultat reste flou et rien ne dit ce qui change pour vous.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C8-S5 / EXPECTED
  ('d536b70c-73d9-5c75-8d45-3e1dd933d765', 'ccef48ba-9091-5429-bded-41de31cfc92b', 'EXPECTED',
   'Au mois d''avril, j''ai reçu ma carte de séjour de deux ans. Je peux maintenant signer un contrat de travail sans expliquer ma situation à chaque employeur. Cette longue attente m''a appris à préparer chaque document à l''avance et à en garder une copie.',
   'Résultat, conséquence et bilan : les trois éléments attendus sont là.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE2-C8-S5 / EXCELLENT
  ('f9ddec4e-3c71-5f3f-9ce2-e877e6147f3a', 'ccef48ba-9091-5429-bded-41de31cfc92b', 'EXCELLENT',
   'Au mois d''avril, après huit mois d''attente, j''ai enfin retiré ma carte de séjour de deux ans au guichet. Depuis, j''ai signé un contrat de travail et j''ai pu déposer un dossier de logement, deux choses impossibles avant. Je retiens surtout une leçon : garder une copie de chaque papier m''a évité de tout recommencer.',
   'La leçon finale est précise et sort du bilan général tout fait.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02');
