-- ============================================================================
-- V434 — TCF CE B1 — lot 04 (support : message de forum)
-- ----------------------------------------------------------------------------
-- 10 items de compréhension écrite B1. Support unique : message de forum
-- (jardin partagé, pain raté, radiateur bruyant, transport aéroport, sport
-- pour enfant timide, troc de graines, ordinateur lent, partenaires de course,
-- chien qui aboie, groupe de conversation). Passages TEXTE (~60-120 mots),
-- questions + choices (4 rows/question). theme_id =
-- 22222222-0000-0000-0000-000000000002, difficulty='B1', question_type='CE'.
-- Données déterministes, rejouables dev+recette.
-- ============================================================================


-- passages — supports de lecture référencés par les questions ci-dessous
INSERT INTO passages
  (id, type, content, media_id, theme_id)
VALUES
  ('11111111-b004-4000-0000-000000000001', 'TEXTE',
   'Sujet : Jardin partagé rue des Lilas — on cherche du monde !
Posté par Amadou93, le 12 mars

Bonjour à tous,

La mairie vient de nous accorder une parcelle au bout de la rue des Lilas pour créer un jardin partagé. Nous sommes déjà huit, mais il reste quatre places. Pas besoin d''expérience : Monique, ancienne maraîchère à la retraite, nous montrera les bases. La cotisation est de 20 euros par an, outils fournis. Première réunion samedi 22 mars à 10 h, directement sur la parcelle. Si vous voulez nous rejoindre, répondez à ce message avant jeudi.

Amadou93',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b004-4000-0000-000000000002', 'TEXTE',
   'Sujet : Mon pain ne lève pas, à l''aide !
Posté par Lucia_Porto, le 5 février

Bonjour à toutes et à tous,

Cela fait trois fois que j''essaie de faire mon pain moi-même, et le résultat est toujours le même : la pâte reste plate, dure comme une brique. Je suis pourtant la recette à la lettre : farine, eau tiède, sel et levure de boulanger. Je pétris dix minutes et je laisse reposer une heure près de la fenêtre. Mon four marche très bien, ce n''est pas le problème. Est-ce que quelqu''un voit ce que je fais mal ? Merci d''avance pour vos idées !

Lucia_Porto',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b004-4000-0000-000000000003', 'TEXTE',
   'Sujet : Radiateur qui claque la nuit
Posté par Wei_Bricole, le 28 novembre

Bonsoir,

Depuis le retour du froid, le radiateur de ma chambre fait un claquement toutes les dix minutes, surtout la nuit. J''ai déjà purgé l''air : le bruit a disparu deux jours, puis il est revenu. Le chauffagiste de mon propriétaire ne peut pas passer avant trois semaines. En attendant, j''aimerais savoir si je peux régler ça moi-même sans risque, ou s''il vaut mieux éteindre ce radiateur et chauffer la pièce autrement. Merci pour vos retours d''expérience !

Wei_Bricole',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b004-4000-0000-000000000004', 'TEXTE',
   'Sujet : Rejoindre le centre de Lyon depuis l''aéroport, tard le soir
Posté par Rachid_Voyage, le 14 avril

Bonjour,

J''atterris à Lyon Saint-Exupéry le 2 mai à 22 h 30 et je dois rejoindre mon hôtel près de la place Bellecour. Le tram express coûte presque 17 euros, ce qui me semble cher, et je ne sais même pas s''il circule encore à cette heure-là. Le taxi est hors budget pour moi. Quelqu''un connaît-il une solution moins chère à cette heure tardive ? Je voyage seul avec une valise cabine, donc je peux marcher un peu. Merci !

Rachid_Voyage',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b004-4000-0000-000000000005', 'TEXTE',
   'Sujet : Quel sport pour une fille de 7 ans très réservée ?
Posté par Olena_Maman, le 30 août

Bonjour à tous,

Ma fille Daryna, 7 ans, est très timide : à l''école, elle ose à peine parler aux autres enfants. La pédiatre nous conseille une activité de groupe pour l''aider à prendre confiance, sans la brusquer. J''ai pensé au judo, qu''une collègue m''a recommandé, mais j''ai peur que ce soit trop brutal pour elle. La danse la tente, mais le seul cours du quartier est complet. Des parents d''enfants timides ont-ils des activités à me suggérer ? Merci beaucoup.

Olena_Maman',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b004-4000-0000-000000000006', 'TEXTE',
   'Sujet : Échange graines de tomates anciennes contre plants d''aromatiques
Posté par Diego_Jardin, le 9 mars

Bonjour les jardiniers,

Cette année, j''ai récolté beaucoup trop de graines de tomates anciennes : noire de Crimée, cœur de bœuf et ananas. Plutôt que de les laisser perdre, je propose de les échanger contre des plants d''herbes aromatiques (basilic, menthe, thym…), car mes semis d''aromatiques ont tous gelé en février. Je peux envoyer les graines par courrier ou les remettre en main propre si vous êtes du côté de Toulouse. Pas de vente : uniquement du troc entre passionnés !

Diego_Jardin',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b004-4000-0000-000000000007', 'TEXTE',
   'Sujet : Ordinateur portable très lent au démarrage
Posté par Priya_Tech, le 17 janvier

Bonjour,

Mon ordinateur portable, acheté il y a quatre ans, met maintenant presque dix minutes à démarrer. Une fois allumé, il fonctionne à peu près normalement. Un vendeur m''a dit qu''il fallait le remplacer, mais je n''ai pas les moyens d''en acheter un autre cette année. Avant de me résigner, je voudrais savoir s''il existe une manipulation simple ou une pièce pas trop chère qui pourrait lui redonner de la vitesse. Je précise que je débute en informatique, alors merci de m''expliquer simplement !

Priya_Tech',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b004-4000-0000-000000000008', 'TEXTE',
   'Sujet : Qui pour courir le matin au parc de la Tête d''Or ?
Posté par Fatou_Run, le 3 juin

Bonjour à tous,

Je me suis inscrite au semi-marathon d''octobre, mais toute seule, j''ai du mal à me motiver : sur les trois sorties prévues chaque semaine, je n''en fais qu''une ! Je cherche donc une ou deux personnes pour courir ensemble le mardi et le jeudi, vers 7 h, au parc de la Tête d''Or. Mon rythme est tranquille, environ 6 minutes 30 au kilomètre : on peut discuter en courant. Peu importe votre niveau, c''est la régularité qui compte. Qui est partant ?

Fatou_Run',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b004-4000-0000-000000000009', 'TEXTE',
   'Sujet : Mon chien aboie dès que je pars travailler
Posté par Mariam_et_Pacha, le 21 septembre

Bonjour,

J''ai adopté Pacha, un berger croisé de deux ans, il y a un mois. Tout se passe bien, sauf un gros problème : dès que je quitte l''appartement, il aboie sans s''arrêter. Ma voisine, très compréhensive jusqu''ici, commence à perdre patience, et je la comprends. J''ai essayé de laisser la radio allumée et un jouet rempli de croquettes : ça ne change rien. Avant de payer un éducateur canin, ce qui coûte cher, j''aimerais connaître vos astuces. Pacha est adorable quand je suis là !

Mariam_et_Pacha',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b004-4000-0000-00000000000a', 'TEXTE',
   'Sujet : Créer un groupe de conversation en français à Nantes
Posté par Andrei_Nantes, le 11 octobre

Bonjour à tous,

Je vis à Nantes depuis huit mois et je prépare l''examen de français pour ma carte de résident. Je comprends bien les cours en ligne, mais je manque d''occasions de parler : au travail, tout le monde communique en anglais. Je propose donc de créer un petit groupe de conversation, le mercredi soir dans un café du centre, ouvert à tous les niveaux. L''idée : discuter une heure uniquement en français, dans la bonne humeur. Trois personnes m''ont déjà répondu en message privé. Qui d''autre veut se joindre à nous ?

Andrei_Nantes',
   NULL, '22222222-0000-0000-0000-000000000002');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-b004-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b004-4000-0000-000000000001',
   NULL, 'B1', 'CE',
   'Que propose Amadou93 aux habitants du quartier ?',
   'Amadou93 écrit : « il reste quatre places » et « Si vous voulez nous rejoindre, répondez à ce message avant jeudi ». C''est un **repérage explicite de l''invitation** : la bonne réponse reformule l''appel à rejoindre le jardin partagé en création. La réponse A invente une vente : aucun légume n''est proposé à l''achat, le jardin n''existe même pas encore. La réponse B déforme un détail : Monique « montrera les bases » bénévolement — ce n''est ni une formation payante ni une initiative de la mairie, qui n''a fait qu''accorder la parcelle. La réponse D inverse l''information : les « outils fournis » sont compris dans la cotisation, personne ne demande d''en prêter.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b004-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b004-4000-0000-000000000002',
   NULL, 'B1', 'CE',
   'Pourquoi Lucia_Porto écrit-elle sur ce forum ?',
   'Lucia_Porto raconte trois échecs (« la pâte reste plate, dure comme une brique ») puis demande : « Est-ce que quelqu''un voit ce que je fais mal ? ». Par **inférence d''intention**, le but du message est d''obtenir un diagnostic des membres du forum sur sa méthode. La réponse B inverse la situation : sa recette échoue, elle ne partage aucune réussite. La réponse C contredit une précision du texte : « Mon four marche très bien, ce n''est pas le problème » — phrase justement placée pour écarter cette piste. La réponse D invente un commerce : il s''agit de pain fait pour elle-même, rien n''est à vendre.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-b004-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b004-4000-0000-000000000003',
   NULL, 'B1', 'CE',
   'Que veut savoir Wei_Bricole ?',
   'Wei_Bricole demande : « j''aimerais savoir si je peux régler ça moi-même sans risque ». La bonne réponse **reformule cette demande** : intervenir seul, sans danger, en attendant le professionnel. La réponse A est le piège principal : la purge a **déjà été faite** (« J''ai déjà purgé l''air ») et n''a pas suffi — confusion entre une action passée et la demande actuelle. La réponse C déforme le texte : le chauffagiste est déjà identifié, il est simplement indisponible avant trois semaines. La réponse D invente un conflit : Wei ne réclame aucun remplacement et ne se plaint pas de son propriétaire.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reformulation'),

  ('11111111-b004-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b004-4000-0000-000000000004',
   NULL, 'B1', 'CE',
   'Que cherche Rachid_Voyage ?',
   'Rachid_Voyage demande : « Quelqu''un connaît-il une solution moins chère à cette heure tardive ? ». C''est un **repérage explicite de la demande** : un transport bon marché entre l''aéroport et le centre après 22 h 30. La réponse A contredit le texte : « Le taxi est hors budget pour moi », il n''envisage pas même de le partager. La réponse B confond deux informations proches : l''hôtel près de la place Bellecour est la **destination déjà fixée**, pas l''objet de la recherche. La réponse C déplace la question dans le temps : Rachid arrive le soir même et craint au contraire que le tram ne circule plus, il ne s''intéresse pas au lendemain matin.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b004-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b004-4000-0000-000000000005',
   NULL, 'B1', 'CE',
   'Pourquoi Olena_Maman consulte-t-elle le forum ?',
   'Olena_Maman conclut : « Des parents d''enfants timides ont-ils des activités à me suggérer ? ». Par **inférence d''intention**, le but est de recueillir des idées d''activités de groupe qui mettent sa fille en confiance. La réponse A prend un **détail secondaire** pour l''objet du message : le cours de danse est complet, Olena ne demande pas de place, elle cherche d''autres pistes. La réponse C transforme une crainte personnelle (« j''ai peur que ce soit trop brutal ») en question posée au forum — le judo n''est qu''une option déjà envisagée. La réponse D contredit le texte : le conseil de la pédiatre est suivi, il n''est pas question d''en changer.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-b004-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b004-4000-0000-000000000006',
   NULL, 'B1', 'CE',
   'Que propose Diego_Jardin aux membres du forum ?',
   'Diego_Jardin écrit : « je propose de les échanger contre des plants d''herbes aromatiques » et conclut « Pas de vente : uniquement du troc ». La bonne réponse **reformule ce troc**. La réponse A est explicitement exclue par la formule « Pas de vente » — négation à repérer dans le texte. La réponse B confond troc et don : « Plutôt que de les laisser perdre » ne signifie pas donner sans contrepartie, Diego attend des plants en échange. La réponse D transforme l''échange en achat : il veut obtenir les aromatiques contre ses graines, pas les payer — confusion entre deux **modes d''obtention proches** (acheter / troquer).',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reformulation'),

  ('11111111-b004-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b004-4000-0000-000000000007',
   NULL, 'B1', 'CE',
   'Que veut savoir Priya_Tech ?',
   'Priya_Tech demande : « je voudrais savoir s''il existe une manipulation simple ou une pièce pas trop chère qui pourrait lui redonner de la vitesse ». C''est un **repérage explicite de la question posée** : accélérer la machine sans la remplacer. La réponse A reprend le conseil du vendeur, que Priya écarte justement : « je n''ai pas les moyens d''en acheter un autre cette année ». La réponse C confond deux pannes proches : l''ordinateur **démarre lentement** mais s''allume bien et « fonctionne à peu près normalement » ensuite. La réponse D détourne une simple précision (« je débute en informatique »), donnée pour obtenir des explications simples, pas pour chercher une formation.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b004-1000-0000-000000000008', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b004-4000-0000-000000000008',
   NULL, 'B1', 'CE',
   'Pourquoi Fatou_Run publie-t-elle ce message ?',
   'Fatou_Run explique : « toute seule, j''ai du mal à me motiver » puis « Je cherche donc une ou deux personnes pour courir ensemble ». Par **inférence d''intention**, le connecteur « donc » relie le manque de motivation à la recherche de partenaires : c''est l''objet réel du message. La réponse B inverse les rôles : Fatou ne propose d''encadrer personne, « peu importe votre niveau » signifie seulement que tous sont bienvenus. La réponse C invente une demande : son rythme « tranquille » lui convient, elle ne cherche pas à courir plus vite. La réponse D confond avec une action **déjà accomplie** : « Je me suis inscrite au semi-marathon » est au passé composé.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-b004-1000-0000-000000000009', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b004-4000-0000-000000000009',
   NULL, 'B1', 'CE',
   'Que faut-il comprendre du message de Mariam_et_Pacha ?',
   'Mariam écrit : « Avant de payer un éducateur canin, ce qui coûte cher, j''aimerais connaître vos astuces ». La bonne réponse **reformule cette stratégie** : tester d''abord les solutions gratuites des membres, l''éducateur restant le dernier recours. La réponse A contredit le ton du message : « Pacha est adorable quand je suis là », il n''est jamais question d''abandon. La réponse B est le piège par **confusion de deux informations proches** : l''éducateur est mentionné comme option coûteuse à repousser, pas comme recherche d''un tarif réduit. La réponse D déforme un élément de contexte : la voisine qui « commence à perdre patience » explique l''urgence, mais les conseils demandés portent sur le chien, pas sur elle.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reformulation'),

  ('11111111-b004-1000-0000-00000000000a', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b004-4000-0000-00000000000a',
   NULL, 'B1', 'CE',
   'Que propose Andrei_Nantes ?',
   'Andrei_Nantes propose : « créer un petit groupe de conversation, le mercredi soir dans un café du centre » pour « discuter une heure uniquement en français ». C''est un **repérage explicite de la proposition** : une rencontre hebdomadaire pour pratiquer l''oral. La réponse A contredit le texte : les cours en ligne ne lui posent aucun problème (« Je comprends bien les cours en ligne »), c''est l''oral qui manque. La réponse B confond le **contexte et la demande** : le travail en anglais explique le manque de pratique, Andrei ne cherche pas d''emploi. La réponse C déforme l''objectif : l''examen est sa motivation personnelle, mais le groupe est ouvert à tous pour discuter, pas pour réviser un écrit.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  -- Q01 — jardin partagé d''Amadou93 (bonne réponse : position 3)
  ('11111111-b004-2100-0000-000000000001', '11111111-b004-1000-0000-000000000001',
   'D''acheter les légumes cultivés sur la parcelle',
   'false', '1'),
  ('11111111-b004-2200-0000-000000000001', '11111111-b004-1000-0000-000000000001',
   'De suivre une formation payante organisée par la mairie',
   'false', '2'),
  ('11111111-b004-2300-0000-000000000001', '11111111-b004-1000-0000-000000000001',
   'De rejoindre le jardin partagé en cours de création',
   'true', '3'),
  ('11111111-b004-2400-0000-000000000001', '11111111-b004-1000-0000-000000000001',
   'De prêter leurs outils de jardinage au groupe',
   'false', '4'),

  -- Q02 — pain raté de Lucia_Porto (bonne réponse : position 1)
  ('11111111-b004-2100-0000-000000000002', '11111111-b004-1000-0000-000000000002',
   'Elle veut comprendre pourquoi sa pâte à pain ne gonfle pas',
   'true', '1'),
  ('11111111-b004-2200-0000-000000000002', '11111111-b004-1000-0000-000000000002',
   'Elle souhaite partager sa recette de pain réussie',
   'false', '2'),
  ('11111111-b004-2300-0000-000000000002', '11111111-b004-1000-0000-000000000002',
   'Elle cherche un réparateur pour son four en panne',
   'false', '3'),
  ('11111111-b004-2400-0000-000000000002', '11111111-b004-1000-0000-000000000002',
   'Elle propose de vendre du pain fait maison',
   'false', '4'),

  -- Q03 — radiateur de Wei_Bricole (bonne réponse : position 2)
  ('11111111-b004-2100-0000-000000000003', '11111111-b004-1000-0000-000000000003',
   'Comment purger correctement son radiateur',
   'false', '1'),
  ('11111111-b004-2200-0000-000000000003', '11111111-b004-1000-0000-000000000003',
   'S''il peut intervenir lui-même sur le radiateur sans danger',
   'true', '2'),
  ('11111111-b004-2300-0000-000000000003', '11111111-b004-1000-0000-000000000003',
   'Comment trouver le chauffagiste de son propriétaire',
   'false', '3'),
  ('11111111-b004-2400-0000-000000000003', '11111111-b004-1000-0000-000000000003',
   'Comment obliger son propriétaire à changer le radiateur',
   'false', '4'),

  -- Q04 — transport de Rachid_Voyage (bonne réponse : position 4)
  ('11111111-b004-2100-0000-000000000004', '11111111-b004-1000-0000-000000000004',
   'Une personne pour partager un taxi depuis l''aéroport',
   'false', '1'),
  ('11111111-b004-2200-0000-000000000004', '11111111-b004-1000-0000-000000000004',
   'Un hôtel abordable près de la place Bellecour',
   'false', '2'),
  ('11111111-b004-2300-0000-000000000004', '11111111-b004-1000-0000-000000000004',
   'Les horaires du tram express pour le lendemain matin',
   'false', '3'),
  ('11111111-b004-2400-0000-000000000004', '11111111-b004-1000-0000-000000000004',
   'Un moyen économique de rejoindre le centre tard le soir',
   'true', '4'),

  -- Q05 — activité pour la fille d''Olena_Maman (bonne réponse : position 2)
  ('11111111-b004-2100-0000-000000000005', '11111111-b004-1000-0000-000000000005',
   'Pour obtenir une place dans le cours de danse du quartier',
   'false', '1'),
  ('11111111-b004-2200-0000-000000000005', '11111111-b004-1000-0000-000000000005',
   'Pour recueillir des idées d''activités adaptées à une enfant timide',
   'true', '2'),
  ('11111111-b004-2300-0000-000000000005', '11111111-b004-1000-0000-000000000005',
   'Pour demander aux membres si le judo est un sport dangereux',
   'false', '3'),
  ('11111111-b004-2400-0000-000000000005', '11111111-b004-1000-0000-000000000005',
   'Pour trouver une nouvelle pédiatre pour sa fille',
   'false', '4'),

  -- Q06 — troc de graines de Diego_Jardin (bonne réponse : position 3)
  ('11111111-b004-2100-0000-000000000006', '11111111-b004-1000-0000-000000000006',
   'De vendre ses graines de tomates anciennes',
   'false', '1'),
  ('11111111-b004-2200-0000-000000000006', '11111111-b004-1000-0000-000000000006',
   'De donner ses graines à qui les veut, sans contrepartie',
   'false', '2'),
  ('11111111-b004-2300-0000-000000000006', '11111111-b004-1000-0000-000000000006',
   'D''échanger ses graines contre des plants d''aromatiques',
   'true', '3'),
  ('11111111-b004-2400-0000-000000000006', '11111111-b004-1000-0000-000000000006',
   'D''acheter des plants de basilic, de menthe et de thym',
   'false', '4'),

  -- Q07 — ordinateur lent de Priya_Tech (bonne réponse : position 2)
  ('11111111-b004-2100-0000-000000000007', '11111111-b004-1000-0000-000000000007',
   'Quel ordinateur neuf choisir pour remplacer le sien',
   'false', '1'),
  ('11111111-b004-2200-0000-000000000007', '11111111-b004-1000-0000-000000000007',
   'S''il existe un moyen simple de rendre son ordinateur plus rapide',
   'true', '2'),
  ('11111111-b004-2300-0000-000000000007', '11111111-b004-1000-0000-000000000007',
   'Comment réparer un ordinateur qui ne s''allume plus',
   'false', '3'),
  ('11111111-b004-2400-0000-000000000007', '11111111-b004-1000-0000-000000000007',
   'Où suivre une formation d''informatique pour débutants',
   'false', '4'),

  -- Q08 — partenaires de course de Fatou_Run (bonne réponse : position 1)
  ('11111111-b004-2100-0000-000000000008', '11111111-b004-1000-0000-000000000008',
   'Pour trouver des partenaires et courir à plusieurs régulièrement',
   'true', '1'),
  ('11111111-b004-2200-0000-000000000008', '11111111-b004-1000-0000-000000000008',
   'Pour proposer d''entraîner des débutants au semi-marathon',
   'false', '2'),
  ('11111111-b004-2300-0000-000000000008', '11111111-b004-1000-0000-000000000008',
   'Pour demander des conseils afin de courir plus vite',
   'false', '3'),
  ('11111111-b004-2400-0000-000000000008', '11111111-b004-1000-0000-000000000008',
   'Pour s''inscrire au semi-marathon d''octobre',
   'false', '4'),

  -- Q09 — chien de Mariam_et_Pacha (bonne réponse : position 3)
  ('11111111-b004-2100-0000-000000000009', '11111111-b004-1000-0000-000000000009',
   'Elle veut confier Pacha à une nouvelle famille',
   'false', '1'),
  ('11111111-b004-2200-0000-000000000009', '11111111-b004-1000-0000-000000000009',
   'Elle cherche un éducateur canin à prix réduit',
   'false', '2'),
  ('11111111-b004-2300-0000-000000000009', '11111111-b004-1000-0000-000000000009',
   'Elle veut essayer des astuces gratuites avant de payer un professionnel',
   'true', '3'),
  ('11111111-b004-2400-0000-000000000009', '11111111-b004-1000-0000-000000000009',
   'Elle demande comment calmer sa voisine mécontente',
   'false', '4'),

  -- Q10 — groupe de conversation d''Andrei_Nantes (bonne réponse : position 4)
  ('11111111-b004-2100-0000-00000000000a', '11111111-b004-1000-0000-00000000000a',
   'De suivre ensemble des cours de français en ligne',
   'false', '1'),
  ('11111111-b004-2200-0000-00000000000a', '11111111-b004-1000-0000-00000000000a',
   'De l''aider à trouver un emploi où l''on parle français',
   'false', '2'),
  ('11111111-b004-2300-0000-00000000000a', '11111111-b004-1000-0000-00000000000a',
   'De réviser ensemble l''examen écrit de la carte de résident',
   'false', '3'),
  ('11111111-b004-2400-0000-00000000000a', '11111111-b004-1000-0000-00000000000a',
   'De se retrouver chaque semaine dans un café pour parler français',
   'true', '4');

-- ============================================================================
-- CHECKLIST — contrôles passés
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes (11111111-b004-1000/4000/21..2400-…-NN, NN=01..0a).
-- [x] Support unique : message de forum (10 pseudos et situations toutes
--     différentes : jardin partagé de quartier, pain qui ne lève pas, radiateur
--     bruyant, transport aéroport-centre, sport pour enfant timide, troc de
--     graines, ordinateur lent, partenaires de course, chien qui aboie seul,
--     groupe de conversation en français).
-- [x] Aucun support interdit (pas d''e-mail, lettre, article, annonce,
--     témoignage/blog, FAQ, etc.) — uniquement des posts de forum (Sujet +
--     Posté par + corps + pseudo).
-- [x] Passages TEXTE ~60-120 mots, mise en forme forum réaliste, media_id NULL.
-- [x] 4 propositions / 1 correcte par item. Distribution des bonnes réponses :
--     pos1:2, pos2:3, pos3:3, pos4:2 (max 3 par position, 4 positions utilisées).
-- [x] competence_code : ce_reperage_explicite x4, ce_inference_intention x3,
--     ce_reformulation x3.
-- [x] explanation ≥ 80 caractères : bonne réponse justifiée + les 3 distracteurs
--     expliqués, point clé en **gras**, mécanisme linguistique nommé (inférence
--     d''intention, connecteur « donc », négation excluante, action passée vs
--     demande actuelle, confusion d''informations proches…).
-- [x] Pas de SVG ni SSML dans ce lot (supports textuels uniquement) — rien à
--     équilibrer.
-- [x] Apostrophes SQL doublées partout, contenu 100% original, items autonomes.
-- ============================================================================
