-- ============================================================================
-- V431 — TCF CE B1 — lot 01 (support : e-mails personnels)
-- ----------------------------------------------------------------------------
-- 10 items de compréhension écrite B1. Support unique : e-mail personnel
-- (proposition de week-end, organisation d''événement, nouvelles d''un proche,
-- demande de service, remerciement, annulation, conseil entre amis,
-- covoiturage, naissance, don de meubles). Passages TEXTE (~60-120 mots),
-- questions + choices (4 rows/question). theme_id =
-- 22222222-0000-0000-0000-000000000002, difficulty='B1', question_type='CE'.
-- Données déterministes, rejouables dev+recette.
-- ============================================================================


-- passages — supports de lecture référencés par les questions ci-dessous
INSERT INTO passages
  (id, type, content, media_id, theme_id)
VALUES
  ('11111111-b001-4000-0000-000000000001', 'TEXTE',
   'Salut Karim,

J''espère que tu vas bien ! Avec Sonia, on a réservé un gîte près d''Annecy pour le week-end du 14 juin. Il reste une chambre libre et on a tout de suite pensé à toi. Au programme : randonnée le samedi autour du lac et marché le dimanche matin. Le gîte coûte 45 euros par personne pour les deux nuits, repas non compris. Pas besoin de voiture, on passe te prendre vendredi vers 18 h. Dis-moi avant mercredi si tu viens, pour que je confirme la réservation.

À très vite,
Amadou',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b001-4000-0000-000000000002', 'TEXTE',
   'Coucou Mehdi,

Comme tu le sais, Inès fête ses 30 ans le samedi 21. Je voudrais organiser une fête surprise chez moi, vers 19 h. J''ai déjà prévu le gâteau et la décoration. De ton côté, est-ce que tu pourrais t''occuper de la faire venir sans éveiller ses soupçons ? Tu pourrais lui proposer un cinéma, puis passer « par hasard » chez moi en sortant. Surtout, ne parle de rien à personne, même pas à son frère : il ne sait pas garder un secret !

Merci d''avance,
Lucia',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b001-4000-0000-000000000003', 'TEXTE',
   'Chère Nadia,

Ça y est, je suis enfin installé à Bordeaux ! Le déménagement s''est bien passé, même si tous les cartons ne sont pas encore ouverts. J''ai commencé lundi mon nouveau poste d''infirmier à la clinique Saint-Augustin : l''équipe est accueillante et les horaires sont plus réguliers qu''à Paris. Le seul point difficile, c''est que je ne connais encore personne ici. Si tu passes dans la région cet été, ma porte t''est grande ouverte : j''ai même une chambre d''amis.

Je t''embrasse,
Wei',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b001-4000-0000-000000000004', 'TEXTE',
   'Bonjour Estelle,

J''ai un petit service à te demander. Je pars à Marrakech du 3 au 12 août pour le mariage de ma cousine, et je ne peux pas emmener Câline, ma chatte. Est-ce que tu accepterais de passer chez moi un jour sur deux pour lui donner ses croquettes et changer sa litière ? Je te laisserais les clés et tout le nécessaire. En échange, je te rapporterai des pâtisseries marocaines, promis ! Si ce n''est pas possible, pas de souci : je demanderai à ma voisine.

Merci d''avance,
Rachid',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b001-4000-0000-000000000005', 'TEXTE',
   'Cher Bruno,

Je voulais encore te remercier pour samedi dernier. Sans toi et ta camionnette, je serais encore en train de porter mes cartons dans l''escalier ! Tu as donné ta journée entière alors que tu travaillais le lendemain, et tu as même réussi à monter le canapé par la fenêtre, ce que les déménageurs professionnels avaient refusé de faire. Pour te remercier, je t''invite à dîner samedi prochain dans mon nouvel appartement : ce sera l''occasion de te le montrer enfin rangé.

Amitiés,
Olena',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b001-4000-0000-000000000006', 'TEXTE',
   'Salut Pauline,

Je suis vraiment désolé, mais je dois annuler notre dîner de jeudi soir. Mon directeur vient de m''annoncer un déplacement à Lille toute la semaine pour former la nouvelle équipe, et je ne rentre que vendredi tard. J''avais tellement envie de te faire découvrir ce restaurant péruvien ! Est-ce qu''on peut reporter au jeudi suivant, même heure, même endroit ? La réservation est à mon nom, je m''occupe de la décaler. Encore pardon pour ce changement de dernière minute.

À bientôt,
Diego',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b001-4000-0000-000000000007', 'TEXTE',
   'Bonjour Samuel,

Tu m''as dit que tu stressais pour ton entretien de mardi à la médiathèque. Voici ce qui m''a aidée quand j''ai passé le mien : renseigne-toi sur leurs projets récents, ils adorent qu''on en parle. Prépare aussi deux ou trois questions à leur poser à la fin, ça montre ta motivation. Par contre, évite d''arriver trop en avance : la responsable m''avait dit que dix minutes suffisent largement. Et surtout, dors bien la veille plutôt que de réviser tard !

Tu vas y arriver,
Priya',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b001-4000-0000-000000000008', 'TEXTE',
   'Salut Théo,

J''ai vu que tu étais invité toi aussi au mariage d''Awa et Julien, le 19 juillet à Tours. Comme on habite le même quartier, je me disais qu''on pourrait faire la route ensemble. Je pars le vendredi vers 16 h pour éviter les bouchons, et je reviens le dimanche après le brunch. Il me reste deux places dans la voiture : si ta sœur veut venir aussi, c''est possible. On partagerait simplement l''essence et le péage, environ 25 euros chacun. Dis-moi vite, d''autres amis m''ont déjà demandé.

Bises,
Fatou',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b001-4000-0000-000000000009', 'TEXTE',
   'Chère Hanna,

Grande nouvelle : notre fille Lena est née mardi matin ! Elle pèse 3,2 kilos et dort déjà presque toute la nuit, ses parents ont de la chance. Agnieszka est encore un peu fatiguée, mais elle va bien ; elles sortent toutes les deux de la maternité jeudi. On préfère attendre deux ou trois semaines avant de recevoir des visites, le temps de trouver notre rythme. Je te propose donc de passer à la maison le premier week-end de juillet, autour d''un café. Ça nous ferait très plaisir.

Amitiés,
Marek',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b001-4000-0000-00000000000a', 'TEXTE',
   'Bonjour Clément,

Comme tu le sais peut-être, je pars travailler deux ans à Montréal à partir de septembre. Je ne peux presque rien emporter, alors je donne une partie de mes meubles plutôt que de les vendre : une bibliothèque, une table ronde et deux fauteuils en très bon état. Tu m''avais dit que tu venais d''emménager dans un appartement presque vide, alors j''ai pensé à toi en premier. Passe les voir quand tu veux avant le 25 août ; après cette date, je donnerai tout à une association.

À bientôt,
Aïcha',
   NULL, '22222222-0000-0000-0000-000000000002');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-b001-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b001-4000-0000-000000000001',
   NULL, 'B1', 'CE',
   'Que propose Amadou à Karim ?',
   'Amadou écrit : « Il reste une chambre libre et on a tout de suite pensé à toi » à propos du gîte réservé pour « le week-end du 14 juin ». Il s''agit d''un **repérage explicite de l''invitation** : la bonne réponse reformule ce week-end partagé au gîte. La réponse A est fausse car le gîte est déjà réservé par Amadou et Sonia, Karim n''a rien à réserver. La réponse B confond les jours : le marché a lieu le dimanche, la randonnée le samedi. La réponse D contredit le texte : « Pas besoin de voiture, on passe te prendre », aucune voiture n''est demandée à Karim.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b001-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b001-4000-0000-000000000002',
   NULL, 'B1', 'CE',
   'Quel rôle Lucia confie-t-elle à Mehdi ?',
   'Lucia demande : « est-ce que tu pourrais t''occuper de la faire venir sans éveiller ses soupçons ? ». C''est une **inférence d''intention** : la mission de Mehdi est d''amener Inès chez Lucia sans trahir la surprise. La réponse B est fausse car Lucia précise « J''ai déjà prévu le gâteau et la décoration » — elle s''en charge elle-même. La réponse C inverse la consigne : Lucia interdit justement de prévenir le frère, qui « ne sait pas garder un secret ». La réponse D confond le moyen et le but : le cinéma n''est qu''un **prétexte suggéré** pour conduire Inès chez Lucia, pas une réservation à effectuer.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-b001-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b001-4000-0000-000000000003',
   NULL, 'B1', 'CE',
   'Qu''apprend-on dans le message de Wei ?',
   'Wei annonce deux faits accomplis : « je suis enfin installé à Bordeaux » et « J''ai commencé lundi mon nouveau poste d''infirmier ». La bonne réponse est une **reformulation** de ce double constat positif (« l''équipe est accueillante »). La réponse A se trompe de temps : Wei ne cherche pas un poste, il l''a déjà commencé — le passé composé marque l''action réalisée. La réponse C inverse la comparaison : les horaires sont « plus réguliers qu''à Paris », donc meilleurs à Bordeaux. La réponse D inverse le sens de l''invitation : c''est Nadia qui est invitée chez Wei (« ma porte t''est grande ouverte »), Wei ne prévoit pas de rentrer à Paris.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reformulation'),

  ('11111111-b001-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b001-4000-0000-000000000004',
   NULL, 'B1', 'CE',
   'Que demande Rachid à Estelle ?',
   'Rachid demande explicitement : « passer chez moi un jour sur deux pour lui donner ses croquettes et changer sa litière ». C''est un **repérage explicite du service demandé** : nourrir la chatte au domicile de Rachid. La réponse A déforme le lieu : Estelle doit passer chez Rachid, pas héberger l''animal chez elle — confusion entre « passer chez moi » et « garder chez toi ». La réponse B confond la cause du voyage (le mariage de la cousine) avec l''objet de la demande. La réponse C confond les rôles : la voisine n''est que la **solution de repli** envisagée si Estelle refuse, ce n''est pas à Estelle de la contacter.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b001-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b001-4000-0000-000000000005',
   NULL, 'B1', 'CE',
   'Pourquoi Olena écrit-elle à Bruno ?',
   'Le message a une **double intention explicite** : « Je voulais encore te remercier pour samedi dernier » puis « Pour te remercier, je t''invite à dîner samedi prochain ». La bonne réponse combine remerciement et invitation. La réponse A confond passé et futur : le déménagement a déjà eu lieu (« samedi dernier »), aucune nouvelle aide n''est demandée. La réponse C prend un **détail secondaire** (le refus des déménageurs professionnels) pour l''objet du message : il ne sert qu''à valoriser l''exploit de Bruno. La réponse D est fausse car la camionnette a déjà été utilisée ; rien n''est emprunté dans ce message.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-b001-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b001-4000-0000-000000000006',
   NULL, 'B1', 'CE',
   'Quel est l''objet principal du message de Diego ?',
   'Diego écrit : « je dois annuler notre dîner de jeudi soir » puis « Est-ce qu''on peut reporter au jeudi suivant ? ». L''objet réel du message est cette **annulation assortie d''une proposition de report**. La réponse A confond la **cause et l''objet** : le déplacement à Lille explique l''annulation, mais n''est pas le but du message — mécanisme classique cause/intention. La réponse B prend un détail affectif (« J''avais tellement envie de te faire découvrir ce restaurant ») pour une recommandation. La réponse D inverse les rôles : Diego précise « je m''occupe de la décaler », il ne demande rien à Pauline concernant la réservation.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-b001-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b001-4000-0000-000000000007',
   NULL, 'B1', 'CE',
   'Que conseille Priya à Samuel pour son entretien ?',
   'Priya conseille en premier : « renseigne-toi sur leurs projets récents, ils adorent qu''on en parle ». C''est un **repérage explicite** du conseil donné. La réponse B contredit le texte : Priya recommande d''« éviter d''arriver trop en avance », dix minutes suffisent — le distracteur joue sur la croyance commune qu''arriver très tôt est une qualité. La réponse C inverse la recommandation finale : « dors bien la veille **plutôt que** de réviser tard » — la locution « plutôt que » marque la préférence excluante. La réponse D inverse aussi le conseil : préparer des questions à poser est encouragé (« ça montre ta motivation »), pas déconseillé.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b001-1000-0000-000000000008', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b001-4000-0000-000000000008',
   NULL, 'B1', 'CE',
   'Que propose Fatou à Théo ?',
   'Fatou suggère : « on pourrait faire la route ensemble » et précise « Il me reste deux places dans la voiture ». La bonne réponse **reformule cette proposition de covoiturage** vers le mariage. La réponse A invente un hébergement : le message parle du trajet et des horaires, jamais d''un logement à Tours. La réponse B déforme une information temporelle : le départ est prévu « le vendredi vers 16 h », pas le samedi matin — piège de **confusion entre deux données proches** (jour/heure). La réponse C déforme la répartition des frais : « On partagerait simplement l''essence et le péage », chacun paie sa part (~25 euros), Théo ne paie pas tout.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reformulation'),

  ('11111111-b001-1000-0000-000000000009', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b001-4000-0000-000000000009',
   NULL, 'B1', 'CE',
   'Que faut-il comprendre concernant les visites ?',
   'Marek explique : « On préfère attendre deux ou trois semaines avant de recevoir des visites » puis « Je te propose donc de passer à la maison le premier week-end de juillet ». Par **inférence simple**, on comprend que Hanna est invitée début juillet, pas avant — le connecteur « donc » relie le délai souhaité et la date proposée. La réponse A contredit ce souhait : jeudi est le jour de sortie de la maternité, pas un jour de visite. La réponse C est une **exagération** : le délai est de deux à trois semaines, pas jusqu''à la fin de l''été. La réponse D déforme l''état d''Agnieszka : elle est « un peu fatiguée, mais elle va bien », pas malade.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-b001-1000-0000-00000000000a', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b001-4000-0000-00000000000a',
   NULL, 'B1', 'CE',
   'Pourquoi Aïcha écrit-elle à Clément ?',
   'Aïcha précise : « je donne une partie de mes meubles plutôt que de les vendre » et « j''ai pensé à toi en premier ». La bonne réponse **reformule cette offre de don** : Clément peut récupérer gratuitement les meubles. La réponse A contredit le verbe choisi : « donner **plutôt que** vendre » exclut toute vente — la locution marque l''alternative écartée. La réponse B confond le contexte (le départ à Montréal) avec l''objet du message : aucune aide au déménagement n''est demandée. La réponse D confond la proposition principale et le **plan de repli** : l''association ne récupérera les meubles qu''après le 25 août, si Clément ne les prend pas.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reformulation');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  -- Q01 — gîte d''Amadou (bonne réponse : position 3)
  ('11111111-b001-2100-0000-000000000001', '11111111-b001-1000-0000-000000000001',
   'De réserver lui-même un gîte pour tout le groupe',
   'false', '1'),
  ('11111111-b001-2200-0000-000000000001', '11111111-b001-1000-0000-000000000001',
   'De l''accompagner au marché le samedi matin',
   'false', '2'),
  ('11111111-b001-2300-0000-000000000001', '11111111-b001-1000-0000-000000000001',
   'De passer le week-end du 14 juin avec eux dans un gîte',
   'true', '3'),
  ('11111111-b001-2400-0000-000000000001', '11111111-b001-1000-0000-000000000001',
   'De prendre sa voiture pour le trajet jusqu''à Annecy',
   'false', '4'),

  -- Q02 — surprise de Lucia (bonne réponse : position 1)
  ('11111111-b001-2100-0000-000000000002', '11111111-b001-1000-0000-000000000002',
   'Amener Inès chez elle sans révéler la surprise',
   'true', '1'),
  ('11111111-b001-2200-0000-000000000002', '11111111-b001-1000-0000-000000000002',
   'Préparer le gâteau d''anniversaire',
   'false', '2'),
  ('11111111-b001-2300-0000-000000000002', '11111111-b001-1000-0000-000000000002',
   'Prévenir le frère d''Inès de la fête',
   'false', '3'),
  ('11111111-b001-2400-0000-000000000002', '11111111-b001-1000-0000-000000000002',
   'Réserver des places de cinéma pour tous les invités',
   'false', '4'),

  -- Q03 — installation de Wei (bonne réponse : position 2)
  ('11111111-b001-2100-0000-000000000003', '11111111-b001-1000-0000-000000000003',
   'Il cherche un poste d''infirmier à Bordeaux',
   'false', '1'),
  ('11111111-b001-2200-0000-000000000003', '11111111-b001-1000-0000-000000000003',
   'Il a déménagé et commencé un nouveau travail qui lui plaît',
   'true', '2'),
  ('11111111-b001-2300-0000-000000000003', '11111111-b001-1000-0000-000000000003',
   'Il regrette ses horaires parisiens, plus réguliers',
   'false', '3'),
  ('11111111-b001-2400-0000-000000000003', '11111111-b001-1000-0000-000000000003',
   'Il rentre à Paris cet été pour rendre visite à Nadia',
   'false', '4'),

  -- Q04 — chatte de Rachid (bonne réponse : position 4)
  ('11111111-b001-2100-0000-000000000004', '11111111-b001-1000-0000-000000000004',
   'De garder sa chatte chez elle pendant dix jours',
   'false', '1'),
  ('11111111-b001-2200-0000-000000000004', '11111111-b001-1000-0000-000000000004',
   'De l''accompagner au mariage de sa cousine',
   'false', '2'),
  ('11111111-b001-2300-0000-000000000004', '11111111-b001-1000-0000-000000000004',
   'De demander à sa voisine de s''occuper de la chatte',
   'false', '3'),
  ('11111111-b001-2400-0000-000000000004', '11111111-b001-1000-0000-000000000004',
   'De venir nourrir sa chatte à son domicile',
   'true', '4'),

  -- Q05 — remerciement d''Olena (bonne réponse : position 2)
  ('11111111-b001-2100-0000-000000000005', '11111111-b001-1000-0000-000000000005',
   'Pour lui demander de l''aider à déménager samedi prochain',
   'false', '1'),
  ('11111111-b001-2200-0000-000000000005', '11111111-b001-1000-0000-000000000005',
   'Pour le remercier de son aide et l''inviter à dîner',
   'true', '2'),
  ('11111111-b001-2300-0000-000000000005', '11111111-b001-1000-0000-000000000005',
   'Pour se plaindre des déménageurs professionnels',
   'false', '3'),
  ('11111111-b001-2400-0000-000000000005', '11111111-b001-1000-0000-000000000005',
   'Pour lui emprunter sa camionnette le week-end prochain',
   'false', '4'),

  -- Q06 — annulation de Diego (bonne réponse : position 3)
  ('11111111-b001-2100-0000-000000000006', '11111111-b001-1000-0000-000000000006',
   'Annoncer sa nouvelle mission de formation à Lille',
   'false', '1'),
  ('11111111-b001-2200-0000-000000000006', '11111111-b001-1000-0000-000000000006',
   'Recommander un restaurant péruvien à Pauline',
   'false', '2'),
  ('11111111-b001-2300-0000-000000000006', '11111111-b001-1000-0000-000000000006',
   'Annuler le dîner de jeudi et proposer une nouvelle date',
   'true', '3'),
  ('11111111-b001-2400-0000-000000000006', '11111111-b001-1000-0000-000000000006',
   'Demander à Pauline de décaler la réservation',
   'false', '4'),

  -- Q07 — conseils de Priya (bonne réponse : position 1)
  ('11111111-b001-2100-0000-000000000007', '11111111-b001-1000-0000-000000000007',
   'De se renseigner sur les projets récents de la médiathèque',
   'true', '1'),
  ('11111111-b001-2200-0000-000000000007', '11111111-b001-1000-0000-000000000007',
   'D''arriver au moins trente minutes en avance',
   'false', '2'),
  ('11111111-b001-2300-0000-000000000007', '11111111-b001-1000-0000-000000000007',
   'De réviser tard la veille de l''entretien',
   'false', '3'),
  ('11111111-b001-2400-0000-000000000007', '11111111-b001-1000-0000-000000000007',
   'D''éviter de poser des questions à la fin de l''entretien',
   'false', '4'),

  -- Q08 — covoiturage de Fatou (bonne réponse : position 4)
  ('11111111-b001-2100-0000-000000000008', '11111111-b001-1000-0000-000000000008',
   'De l''héberger à Tours le week-end du mariage',
   'false', '1'),
  ('11111111-b001-2200-0000-000000000008', '11111111-b001-1000-0000-000000000008',
   'De partir le samedi matin pour éviter les bouchons',
   'false', '2'),
  ('11111111-b001-2300-0000-000000000008', '11111111-b001-1000-0000-000000000008',
   'De payer l''intégralité de l''essence et du péage',
   'false', '3'),
  ('11111111-b001-2400-0000-000000000008', '11111111-b001-1000-0000-000000000008',
   'De faire le trajet jusqu''au mariage dans sa voiture',
   'true', '4'),

  -- Q09 — naissance chez Marek (bonne réponse : position 2)
  ('11111111-b001-2100-0000-000000000009', '11111111-b001-1000-0000-000000000009',
   'Hanna peut passer à la maternité dès jeudi',
   'false', '1'),
  ('11111111-b001-2200-0000-000000000009', '11111111-b001-1000-0000-000000000009',
   'Marek invite Hanna chez lui début juillet, pas avant',
   'true', '2'),
  ('11111111-b001-2300-0000-000000000009', '11111111-b001-1000-0000-000000000009',
   'Les visites sont impossibles avant la fin de l''été',
   'false', '3'),
  ('11111111-b001-2400-0000-000000000009', '11111111-b001-1000-0000-000000000009',
   'Agnieszka est trop malade pour recevoir qui que ce soit',
   'false', '4'),

  -- Q10 — meubles d''Aïcha (bonne réponse : position 3)
  ('11111111-b001-2100-0000-00000000000a', '11111111-b001-1000-0000-00000000000a',
   'Pour lui vendre ses meubles avant son départ',
   'false', '1'),
  ('11111111-b001-2200-0000-00000000000a', '11111111-b001-1000-0000-00000000000a',
   'Pour lui demander de l''aider à déménager à Montréal',
   'false', '2'),
  ('11111111-b001-2300-0000-00000000000a', '11111111-b001-1000-0000-00000000000a',
   'Pour lui proposer de récupérer gratuitement des meubles',
   'true', '3'),
  ('11111111-b001-2400-0000-00000000000a', '11111111-b001-1000-0000-00000000000a',
   'Pour lui annoncer qu''elle donne tout à une association',
   'false', '4');

-- ============================================================================
-- CHECKLIST — contrôles passés
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes (11111111-b001-1000/4000/21..2400-…-NN, NN=01..0a).
-- [x] Support unique : e-mail personnel (10 expéditeurs et situations toutes
--     différentes : week-end gîte, fête surprise, installation/nouveau travail,
--     garde de chat, remerciement déménagement, annulation dîner, conseils
--     entretien, covoiturage mariage, naissance, don de meubles).
-- [x] Passages TEXTE ~60-120 mots, mise en forme mail (salutation, corps,
--     signature), media_id NULL.
-- [x] 4 propositions / 1 correcte par item. Distribution des bonnes réponses :
--     pos1:2, pos2:3, pos3:3, pos4:2 (max 3 par position, 4 positions utilisées).
-- [x] competence_code : ce_reperage_explicite x3, ce_inference_intention x4,
--     ce_reformulation x3.
-- [x] explanation ≥ 80 caractères : bonne réponse justifiée + les 3 distracteurs
--     expliqués, point clé en **gras**, mécanisme linguistique nommé (cause vs
--     objet, inférence d''intention, reformulation, alternative excluante…).
-- [x] Pas de SVG ni SSML dans ce lot (supports textuels uniquement) — rien à
--     équilibrer.
-- [x] Apostrophes SQL doublées partout, contenu 100% original, items autonomes.
-- ============================================================================
