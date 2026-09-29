-- ============================================================================
-- V435 — TCF CE B1 — lot 05 (support : lettre courte)
-- ----------------------------------------------------------------------------
-- 10 items de compréhension écrite B1. Support unique : lettre courte
-- (excuses pour des travaux, remerciement à une professeure, lettre de
-- vacances, lettre au gardien d''immeuble, invitation surprise, remerciement
-- à une famille d''accueil, lettre accompagnant un livre rendu, projet de
-- visite à une amie, invitation d''anniversaire, nouvelles à une voisine
-- âgée). Passages TEXTE (~60-120 mots), questions + choices (4 rows/question).
-- theme_id = 22222222-0000-0000-0000-000000000002, difficulty='B1',
-- question_type='CE'. Données déterministes, rejouables dev+recette.
-- ============================================================================


-- passages — supports de lecture référencés par les questions ci-dessous
INSERT INTO passages
  (id, type, content, media_id, theme_id)
VALUES
  ('11111111-b005-4000-0000-000000000001', 'TEXTE',
   'Lyon, le 3 mai

Chère Madame Garnier,

Je vous écris pour vous prévenir que des travaux auront lieu dans mon appartement du lundi 12 au vendredi 16 mai. Les ouvriers vont refaire l''ancienne salle de bains : il y aura donc du bruit, surtout le matin. Je suis désolée pour la gêne, car je sais que vous travaillez de nuit et que vous dormez en journée. Si le bruit devient vraiment difficile à supporter, n''hésitez pas à sonner chez moi : je demanderai aux ouvriers de commencer plus tard. Encore toutes mes excuses.

Votre voisine du troisième,
Olena',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b005-4000-0000-000000000002', 'TEXTE',
   'Nantes, le 18 juin

Chère Madame Roussel,

Je tenais à vous annoncer une grande nouvelle : j''ai réussi mon examen de français la semaine dernière, avec le niveau B2 ! Sans vos cours du soir et votre patience, je n''y serais jamais arrivé. Grâce à ce résultat, je peux maintenant déposer mon dossier de naturalisation. Une petite fête est organisée chez moi le samedi 28 juin pour remercier tous ceux qui m''ont aidé : votre présence me ferait très plaisir. Vous pouvez venir accompagnée, bien sûr.

Avec toute ma reconnaissance,
Amadou',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b005-4000-0000-000000000003', 'TEXTE',
   'Saint-Malo, le 9 août

Chère Bianca,

Un petit mot de Bretagne, où je passe deux semaines avec mes cousins. Le temps change sans arrêt : nous avons eu de la pluie lundi, mais depuis mercredi le soleil est revenu. Hier, nous avons fait le tour des remparts et goûté des crêpes au caramel — tu adorerais ! Je rentre à Lyon le 17 août. Si tu es libre le week-end suivant, viens dormir à la maison : je te montrerai mes photos et je t''ai rapporté un petit cadeau.

Grosses bises,
Lucia',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b005-4000-0000-000000000004', 'TEXTE',
   'Paris, le 28 juin

Cher Monsieur Brunet,

Je pars en Chine du 1er juillet au 2 août pour rendre visite à ma famille. Pendant mon absence, j''attends un colis important : il contient des documents pour mon nouveau travail. Pourriez-vous le garder dans votre loge si le facteur le dépose ? Je le récupérerai dès mon retour. Ma sœur Mei passera aussi arroser mes plantes le mercredi ; je lui ai confié mes clés, ne soyez donc pas surpris de la croiser dans l''escalier. Merci beaucoup pour votre aide.

Bien cordialement,
Wei',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b005-4000-0000-000000000005', 'TEXTE',
   'Strasbourg, le 2 mars

Chère tante Yamina,

J''espère que tu vas bien depuis ta visite de janvier. Je t''écris pour t''inviter au repas que nous organisons pour les 70 ans de papa, le dimanche 23 mars à midi, au restaurant Le Cèdre, près de la gare. C''est une surprise : il croit que nous déjeunerons simplement tous les deux. Surtout, ne lui en parle pas au téléphone ! Réponds-moi par courrier ou sur mon portable. Si tu viens en train, je viendrai te chercher à la gare.

Je t''embrasse,
Rachid',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b005-4000-0000-000000000006', 'TEXTE',
   'Kochi, le 5 octobre

Chers Monsieur et Madame Lefort,

Me voici bien rentrée en Inde après mes trois mois passés chez vous. Je garde un merveilleux souvenir de votre accueil, des dîners dans le jardin et de nos conversations qui m''ont tant fait progresser en français. Pour vous remercier, je vous ai envoyé hier un colis avec du thé de ma région et un livre de photos sur le Kerala. Il devrait arriver d''ici deux semaines. J''espère revenir vous voir l''été prochain : cette fois, c''est moi qui cuisinerai pour vous !

Affectueusement,
Priya',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b005-4000-0000-000000000007', 'TEXTE',
   'Montpellier, le 14 février

Cher Tomas,

Je te rends enfin ton livre sur l''histoire de l''Espagne, avec presque deux mois de retard — pardonne-moi ! Je l''ai tellement aimé que je l''ai relu une deuxième fois, d''où ce long délai. Tu trouveras dans l''enveloppe un marque-page en cuir acheté chez un artisan de ma rue : c''est ma façon de m''excuser. Si tu as d''autres livres du même auteur, je suis preneur. En échange, je peux te prêter mon roman préféré ; je te le montrerai samedi au club d''échecs.

Amicalement,
Diego',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b005-4000-0000-000000000008', 'TEXTE',
   'Lille, le 20 septembre

Chère Aminata,

Depuis ton déménagement à Bayonne, le quartier n''est plus pareil ! J''ai une bonne nouvelle : mes congés d''automne sont enfin confirmés, du 25 au 31 octobre. J''aimerais beaucoup venir te voir pendant cette semaine, trois ou quatre jours, si cela t''arrange. Je peux dormir à l''hôtel si ton appartement est trop petit, ce n''est pas un problème. Dis-moi simplement quelles dates te conviennent le mieux, et je réserverai mon billet de train dès ta réponse.

Ton amie qui pense à toi,
Fatou',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b005-4000-0000-000000000009', 'TEXTE',
   'Dijon, le 12 avril

Cher Étienne,

Eh oui, j''aurai bientôt 40 ans ! Pour marquer le coup, j''ai réservé une salle au bord du lac Kir le samedi 17 mai, à partir de 18 h. Une trentaine d''amis sont déjà prévus, mais la fête ne serait pas complète sans mon plus vieux copain d''école. Tu peux venir avec Claire et les enfants, il y aura un coin jeux pour les petits. Pas de cadeau, s''il te plaît : ta présence suffit. Réponds-moi avant le 30 avril pour le traiteur.

À très vite, j''espère,
Marek',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b005-4000-0000-00000000000a', 'TEXTE',
   'Rennes, le 8 janvier

Chère Madame Morel,

Comment allez-vous depuis mon départ ? Mon installation à Rennes s''est bien passée et mon nouveau travail à la pharmacie me plaît beaucoup. Mais nos après-midis de lecture me manquent ! C''est Olga qui s''occupe de vos courses maintenant : elle est sérieuse, vous pouvez lui faire confiance. Je reviendrai à Angers pour le week-end de Pâques et je passerai vous voir, avec des chouquettes de votre boulangerie préférée, comme avant. D''ici là, prenez bien soin de vous.

Toutes mes pensées,
Hanna',
   NULL, '22222222-0000-0000-0000-000000000002');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-b005-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b005-4000-0000-000000000001',
   NULL, 'B1', 'CE',
   'Pourquoi Olena écrit-elle à sa voisine ?',
   'Olena annonce « des travaux auront lieu… il y aura donc du bruit » puis présente « toutes mes excuses ». L''**intention réelle de la lettre** est de prévenir et de s''excuser — une **inférence d''intention** à partir de ces deux énoncés. La réponse A se projette après les travaux : rien n''est dit d''une visite, la salle de bains n''est pas encore refaite. La réponse B **inverse les rôles** : c''est Olena qui fera du bruit ; Madame Garnier dort le jour parce qu''elle travaille de nuit. La réponse D déforme la proposition finale : Olena offre une solution (sonner chez elle pour décaler les horaires), elle ne demande aucune aide.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-b005-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b005-4000-0000-000000000002',
   NULL, 'B1', 'CE',
   'Pourquoi Amadou écrit-il à Madame Roussel ?',
   'La lettre enchaîne trois énoncés : « j''ai réussi mon examen », « Sans vos cours… je n''y serais jamais arrivé » et « votre présence me ferait très plaisir » pour la fête du 28 juin. La bonne réponse **reformule ce triple message** (réussite + remerciement + invitation). La réponse B confond passé et présent : les cours du soir appartiennent au passé, Amadou a déjà obtenu son B2. La réponse C transforme une conséquence (« je peux maintenant déposer mon dossier ») en demande d''aide : il ne sollicite rien. La réponse D déforme la fête de remerciement en cours de français — **confusion entre l''événement et son prétexte**.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reformulation'),

  ('11111111-b005-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b005-4000-0000-000000000003',
   NULL, 'B1', 'CE',
   'Que propose Lucia à Bianca ?',
   'Lucia écrit : « Je rentre à Lyon le 17 août. Si tu es libre le week-end suivant, viens dormir à la maison ». La bonne réponse **reformule cette invitation à Lyon après le retour** — il faut relier la date de retour et l''expression « le week-end suivant ». La réponse A inverse le lieu et le moment : Lucia n''invite pas Bianca en Bretagne, son séjour s''y termine. La réponse C confond un souvenir raconté (« Hier, nous avons fait le tour des remparts ») avec une proposition à venir — piège sur la **valeur du passé composé**. La réponse D déforme la fin de la lettre : les photos seront montrées sur place, à la maison, rien n''est envoyé par courrier.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reformulation'),

  ('11111111-b005-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b005-4000-0000-000000000004',
   NULL, 'B1', 'CE',
   'Que demande Wei à Monsieur Brunet ?',
   'Wei formule une demande explicite : « Pourriez-vous le garder dans votre loge si le facteur le dépose ? », à propos du colis attendu. C''est un **repérage explicite du service demandé**. La réponse A confond les personnes : c''est Mei, la sœur, qui arrosera les plantes le mercredi, pas le gardien. La réponse B se trompe de temps : les clés ont **déjà été confiées** à Mei (« je lui ai confié mes clés »), il n''y a rien à remettre. La réponse C mélange deux informations : le colis **contient** des documents pour le travail, mais rien ne doit être envoyé — piège de **confusion entre contenu et action**.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b005-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b005-4000-0000-000000000005',
   NULL, 'B1', 'CE',
   'Que demande Rachid à sa tante ?',
   'Rachid invite sa tante au repas du 23 mars et précise : « C''est une surprise… Surtout, ne lui en parle pas au téléphone ! ». Par **inférence simple**, on comprend que Yamina doit venir tout en gardant le secret. La réponse A invente une tâche : le restaurant est déjà choisi et c''est Rachid qui organise le repas. La réponse C **inverse exactement la consigne** : le téléphone avec le père est précisément le canal interdit pour ne pas trahir la surprise. La réponse D exagère le rôle de la tante : elle est invitée, mais l''organisation (restaurant, accueil à la gare) reste entièrement à la charge de Rachid.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-b005-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b005-4000-0000-000000000006',
   NULL, 'B1', 'CE',
   'Pourquoi Priya a-t-elle envoyé un colis aux Lefort ?',
   'Priya écrit : « Pour vous remercier, je vous ai envoyé hier un colis avec du thé de ma région et un livre de photos ». Le but du colis est **explicitement introduit par « pour vous remercier »** — repérage direct de la finalité. La réponse B invente un contenu : le colis contient des cadeaux choisis (thé, livre), pas des affaires oubliées. La réponse C inverse le sens du voyage espéré : c''est Priya qui veut **revenir chez eux** l''été prochain, elle ne les invite pas en Inde. La réponse D confond passé et avenir : les conversations ont fait progresser son français pendant le séjour, aucun nouveau cours n''est demandé.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b005-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b005-4000-0000-000000000007',
   NULL, 'B1', 'CE',
   'Pourquoi Diego offre-t-il un marque-page à Tomas ?',
   'Diego écrit : « Tu trouveras dans l''enveloppe un marque-page… c''est ma façon de m''excuser », juste après avoir reconnu « presque deux mois de retard ». Par **inférence de cause**, le cadeau répare le retard — la formule « c''est ma façon de » relie explicitement le don à l''excuse. La réponse A invente une invitation : le club d''échecs n''est que le lieu où ils se verront samedi. La réponse B contredit le texte : le livre est **rendu**, pas perdu — Diego l''a même relu deux fois. La réponse C détourne la demande finale (« Si tu as d''autres livres du même auteur ») en événement : aucune sortie de livre n''est mentionnée.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-b005-1000-0000-000000000008', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b005-4000-0000-000000000008',
   NULL, 'B1', 'CE',
   'Qu''attend Fatou de la part d''Aminata ?',
   'Fatou conclut : « Dis-moi simplement quelles dates te conviennent le mieux, et je réserverai mon billet de train dès ta réponse ». C''est un **repérage explicite de la demande** : indiquer les dates qui conviennent. La réponse A confond un regret affectif (« le quartier n''est plus pareil ») avec une demande de retour à Lille. La réponse B déforme l''hypothèse de l''hôtel : Fatou dit qu''elle **peut** y dormir si l''appartement est trop petit, sans rien demander à Aminata. La réponse D inverse les rôles : c''est Fatou elle-même qui réservera son billet une fois les dates connues — piège classique sur **qui fait quoi**.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b005-1000-0000-000000000009', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b005-4000-0000-000000000009',
   NULL, 'B1', 'CE',
   'Pourquoi Marek demande-t-il une réponse avant le 30 avril ?',
   'Marek écrit : « Réponds-moi avant le 30 avril pour le traiteur ». Par **inférence simple**, la date limite sert à confirmer le nombre de convives au traiteur — la préposition « pour » introduit le **but** de la demande. La réponse A se trompe d''étape : la salle est déjà réservée (« j''ai réservé une salle… le samedi 17 mai »). La réponse B contredit la lettre : Marek refuse justement les cadeaux (« Pas de cadeau, s''il te plaît : ta présence suffit »). La réponse D inverse les rôles : c''est Étienne qui peut venir avec Claire et les enfants ; Marek n''a personne à prévenir de son côté.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-b005-1000-0000-00000000000a', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b005-4000-0000-00000000000a',
   NULL, 'B1', 'CE',
   'Qu''annonce Hanna à Madame Morel ?',
   'Hanna écrit : « Je reviendrai à Angers pour le week-end de Pâques et je passerai vous voir ». La bonne réponse **reformule cette visite annoncée**. La réponse A inverse la situation professionnelle : Hanna est installée à Rennes et son « nouveau travail à la pharmacie » lui plaît, elle ne cherche rien à Angers. La réponse C confond les personnes : les courses sont désormais assurées par Olga, présentée comme digne de confiance. La réponse D déforme le mode de remise : les chouquettes seront apportées en main propre lors de la visite (« je passerai vous voir, avec des chouquettes »), rien n''est expédié — piège sur le **moyen vs l''action**.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reformulation');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  -- Q01 — travaux d''Olena (bonne réponse : position 3)
  ('11111111-b005-2100-0000-000000000001', '11111111-b005-1000-0000-000000000001',
   'Pour l''inviter à visiter sa salle de bains rénovée',
   'false', '1'),
  ('11111111-b005-2200-0000-000000000001', '11111111-b005-1000-0000-000000000001',
   'Pour se plaindre du bruit que fait Madame Garnier la nuit',
   'false', '2'),
  ('11111111-b005-2300-0000-000000000001', '11111111-b005-1000-0000-000000000001',
   'Pour la prévenir de travaux bruyants et s''excuser de la gêne',
   'true', '3'),
  ('11111111-b005-2400-0000-000000000001', '11111111-b005-1000-0000-000000000001',
   'Pour lui demander de l''aider pendant les travaux',
   'false', '4'),

  -- Q02 — réussite d''Amadou (bonne réponse : position 1)
  ('11111111-b005-2100-0000-000000000002', '11111111-b005-1000-0000-000000000002',
   'Pour annoncer sa réussite, la remercier et l''inviter à une fête',
   'true', '1'),
  ('11111111-b005-2200-0000-000000000002', '11111111-b005-1000-0000-000000000002',
   'Pour s''inscrire à ses nouveaux cours du soir',
   'false', '2'),
  ('11111111-b005-2300-0000-000000000002', '11111111-b005-1000-0000-000000000002',
   'Pour lui demander de l''aider à remplir son dossier de naturalisation',
   'false', '3'),
  ('11111111-b005-2400-0000-000000000002', '11111111-b005-1000-0000-000000000002',
   'Pour l''informer qu''il donne des cours de français chez lui',
   'false', '4'),

  -- Q03 — vacances de Lucia (bonne réponse : position 2)
  ('11111111-b005-2100-0000-000000000003', '11111111-b005-1000-0000-000000000003',
   'De la rejoindre en Bretagne avant le 17 août',
   'false', '1'),
  ('11111111-b005-2200-0000-000000000003', '11111111-b005-1000-0000-000000000003',
   'De venir dormir chez elle à Lyon après son retour',
   'true', '2'),
  ('11111111-b005-2300-0000-000000000003', '11111111-b005-1000-0000-000000000003',
   'De faire ensemble le tour des remparts de Saint-Malo',
   'false', '3'),
  ('11111111-b005-2400-0000-000000000003', '11111111-b005-1000-0000-000000000003',
   'De lui envoyer ses photos de vacances par courrier',
   'false', '4'),

  -- Q04 — colis de Wei (bonne réponse : position 4)
  ('11111111-b005-2100-0000-000000000004', '11111111-b005-1000-0000-000000000004',
   'D''arroser ses plantes tous les mercredis',
   'false', '1'),
  ('11111111-b005-2200-0000-000000000004', '11111111-b005-1000-0000-000000000004',
   'De remettre ses clés à sa sœur Mei',
   'false', '2'),
  ('11111111-b005-2300-0000-000000000004', '11111111-b005-1000-0000-000000000004',
   'D''envoyer des documents à son nouveau travail',
   'false', '3'),
  ('11111111-b005-2400-0000-000000000004', '11111111-b005-1000-0000-000000000004',
   'De garder un colis dans sa loge pendant son absence',
   'true', '4'),

  -- Q05 — surprise de Rachid (bonne réponse : position 2)
  ('11111111-b005-2100-0000-000000000005', '11111111-b005-1000-0000-000000000005',
   'De réserver une table au restaurant Le Cèdre',
   'false', '1'),
  ('11111111-b005-2200-0000-000000000005', '11111111-b005-1000-0000-000000000005',
   'De venir au repas d''anniversaire sans prévenir son père',
   'true', '2'),
  ('11111111-b005-2300-0000-000000000005', '11111111-b005-1000-0000-000000000005',
   'D''annoncer la fête à son père par téléphone',
   'false', '3'),
  ('11111111-b005-2400-0000-000000000005', '11111111-b005-1000-0000-000000000005',
   'D''organiser elle-même la surprise des 70 ans',
   'false', '4'),

  -- Q06 — colis de Priya (bonne réponse : position 1)
  ('11111111-b005-2100-0000-000000000006', '11111111-b005-1000-0000-000000000006',
   'Pour les remercier de leur accueil pendant son séjour',
   'true', '1'),
  ('11111111-b005-2200-0000-000000000006', '11111111-b005-1000-0000-000000000006',
   'Pour leur rendre des affaires oubliées chez eux',
   'false', '2'),
  ('11111111-b005-2300-0000-000000000006', '11111111-b005-1000-0000-000000000006',
   'Pour les inviter à venir la voir au Kerala',
   'false', '3'),
  ('11111111-b005-2400-0000-000000000006', '11111111-b005-1000-0000-000000000006',
   'Pour leur demander de nouveaux cours de français',
   'false', '4'),

  -- Q07 — marque-page de Diego (bonne réponse : position 4)
  ('11111111-b005-2100-0000-000000000007', '11111111-b005-1000-0000-000000000007',
   'Pour le remercier de l''avoir invité au club d''échecs',
   'false', '1'),
  ('11111111-b005-2200-0000-000000000007', '11111111-b005-1000-0000-000000000007',
   'Parce qu''il a perdu le livre que Tomas lui avait prêté',
   'false', '2'),
  ('11111111-b005-2300-0000-000000000007', '11111111-b005-1000-0000-000000000007',
   'Pour fêter la sortie du nouveau livre de leur auteur préféré',
   'false', '3'),
  ('11111111-b005-2400-0000-000000000007', '11111111-b005-1000-0000-000000000007',
   'Pour se faire pardonner d''avoir rendu le livre en retard',
   'true', '4'),

  -- Q08 — visite de Fatou (bonne réponse : position 3)
  ('11111111-b005-2100-0000-000000000008', '11111111-b005-1000-0000-000000000008',
   'Qu''elle revienne s''installer à Lille',
   'false', '1'),
  ('11111111-b005-2200-0000-000000000008', '11111111-b005-1000-0000-000000000008',
   'Qu''elle lui réserve une chambre d''hôtel à Bayonne',
   'false', '2'),
  ('11111111-b005-2300-0000-000000000008', '11111111-b005-1000-0000-000000000008',
   'Qu''elle lui indique les dates de visite qui lui conviennent',
   'true', '3'),
  ('11111111-b005-2400-0000-000000000008', '11111111-b005-1000-0000-000000000008',
   'Qu''elle lui achète un billet de train pour octobre',
   'false', '4'),

  -- Q09 — anniversaire de Marek (bonne réponse : position 3)
  ('11111111-b005-2100-0000-000000000009', '11111111-b005-1000-0000-000000000009',
   'Pour pouvoir réserver la salle au bord du lac',
   'false', '1'),
  ('11111111-b005-2200-0000-000000000009', '11111111-b005-1000-0000-000000000009',
   'Pour avoir le temps d''acheter les cadeaux',
   'false', '2'),
  ('11111111-b005-2300-0000-000000000009', '11111111-b005-1000-0000-000000000009',
   'Pour donner le nombre d''invités au traiteur',
   'true', '3'),
  ('11111111-b005-2400-0000-000000000009', '11111111-b005-1000-0000-000000000009',
   'Pour prévenir Claire et les enfants de la fête',
   'false', '4'),

  -- Q10 — nouvelles de Hanna (bonne réponse : position 2)
  ('11111111-b005-2100-0000-00000000000a', '11111111-b005-1000-0000-00000000000a',
   'Qu''elle cherche un nouveau travail à Angers',
   'false', '1'),
  ('11111111-b005-2200-0000-00000000000a', '11111111-b005-1000-0000-00000000000a',
   'Qu''elle viendra la voir au moment de Pâques',
   'true', '2'),
  ('11111111-b005-2300-0000-00000000000a', '11111111-b005-1000-0000-00000000000a',
   'Qu''elle continuera de s''occuper de ses courses',
   'false', '3'),
  ('11111111-b005-2400-0000-00000000000a', '11111111-b005-1000-0000-00000000000a',
   'Qu''elle lui enverra des chouquettes par colis',
   'false', '4');

-- ============================================================================
-- CHECKLIST — contrôles passés
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes (11111111-b005-1000/4000/21..2400-…-NN, NN=01..0a).
-- [x] Support unique : lettre courte (10 expéditeurs et situations toutes
--     différentes : excuses travaux voisine, remerciement professeure + fête,
--     lettre de vacances de Bretagne, lettre au gardien pour un colis,
--     invitation repas surprise 70 ans, remerciement famille d''accueil,
--     lettre jointe à un livre rendu, projet de visite à une amie,
--     invitation 40 ans, nouvelles à une voisine âgée).
-- [x] Passages TEXTE ~60-120 mots, mise en forme lettre (lieu + date,
--     formule d''appel, corps, formule de clôture, signature), media_id NULL.
-- [x] 4 propositions / 1 correcte par item. Distribution des bonnes réponses :
--     pos1:2, pos2:3, pos3:3, pos4:2 (max 3 par position, 4 positions utilisées).
-- [x] competence_code : ce_reperage_explicite x3 (Q4, Q6, Q8),
--     ce_inference_intention x4 (Q1, Q5, Q7, Q9), ce_reformulation x3 (Q2, Q3, Q10).
-- [x] explanation ≥ 80 caractères : bonne réponse justifiée + les 3 distracteurs
--     expliqués, point clé en **gras**, mécanisme linguistique nommé (inférence
--     d''intention, inférence de cause, but introduit par « pour », valeur du
--     passé composé, inversion des rôles, contenu vs action…).
-- [x] Pas de SVG ni SSML dans ce lot (supports textuels uniquement) — rien à
--     équilibrer.
-- [x] Apostrophes SQL doublées partout, contenu 100% original, items autonomes.
-- ============================================================================
