-- ============================================================================
-- V440 — TCF CE B1 — lot 10 (support : programme détaillé)
-- ----------------------------------------------------------------------------
-- 10 items de compréhension écrite B1. Support unique : programme détaillé
-- (portes ouvertes médiathèque, week-end club de randonnée, fête de quartier,
-- formation premiers secours, sortie comité d''entreprise, accueil nouveaux
-- habitants, stage de cuisine, matinée jobs d''été, classe découverte,
-- journée de nettoyage des berges). Passages TEXTE (~60-120 mots),
-- questions + choices (4 rows/question). theme_id =
-- 22222222-0000-0000-0000-000000000002, difficulty='B1', question_type='CE'.
-- Données déterministes, rejouables dev+recette.
-- ============================================================================


-- passages — supports de lecture référencés par les questions ci-dessous
INSERT INTO passages
  (id, type, content, media_id, theme_id)
VALUES
  ('11111111-b00a-4000-0000-000000000001', 'TEXTE',
   'Médiathèque Georges-Perec — Journée portes ouvertes, samedi 14 mars

10 h : visite guidée des coulisses (réservation conseillée)
11 h : atelier découverte des liseuses numériques
12 h 30 : pause — la médiathèque reste ouverte
14 h : lectures de contes pour les enfants de 4 à 8 ans
16 h : rencontre avec l''illustratrice Priya Nair, suivie d''une séance de dédicaces
17 h 30 : tirage au sort — un abonnement d''un an à gagner

Entrée libre toute la journée. Les inscriptions à l''atelier numérique se font à l''accueil, dans la limite de douze places.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00a-4000-0000-000000000002', 'TEXTE',
   'Club Évasion Nature — Week-end d''accueil des nouveaux membres, 6-7 septembre

Samedi
9 h : départ en minibus depuis le gymnase Jean-Moulin
10 h 30 : randonnée facile autour du lac de Charmes (3 heures)
19 h : barbecue au refuge — chacun apporte une boisson

Dimanche
9 h 30 : initiation à la lecture de carte avec Amadou, notre président
14 h : départ du refuge, retour vers 17 h au gymnase

Prévoir des chaussures de marche et un pique-nique pour le samedi midi ; le club fournit les bâtons. En cas d''orage, la randonnée est remplacée par une visite du musée de la montagne.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00a-4000-0000-000000000003', 'TEXTE',
   'Fête du quartier des Tilleuls — dimanche 22 juin, place du Marché

11 h : ouverture par la fanfare Les Cuivres Joyeux
12 h : grand repas partagé — chacun apporte un plat à mettre en commun
14 h : tournoi de pétanque (inscription sur place, 2 euros par équipe)
15 h 30 : spectacle de marionnettes offert aux enfants
17 h : concert du groupe Wei & Co
18 h 30 : tombola — billets en vente toute la journée au stand de l''association

Toutes les animations sont gratuites, sauf le tournoi de pétanque et la tombola. En cas de pluie, repli dans la salle des fêtes.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00a-4000-0000-000000000004', 'TEXTE',
   'Formation premiers secours (PSC1) — Croix Blanche de Vandel
Samedi 18 octobre, salle polyvalente, 8 h 45 - 18 h. Formatrice : Lucia Moreno.

8 h 45 : accueil des participants
9 h : protéger et alerter
10 h 30 : la victime s''étouffe ou saigne
12 h 30 : pause déjeuner libre (repas tiré du sac ou restaurants à proximité)
13 h 45 : malaise et perte de connaissance
15 h 30 : massage cardiaque et défibrillateur — exercices sur mannequin
17 h 30 : évaluation et remise des attestations

Tenue confortable indispensable : les exercices se font au sol. Formation gratuite, financée par la mairie ; toute absence non signalée 48 heures à l''avance sera facturée 20 euros.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00a-4000-0000-000000000005', 'TEXTE',
   'Comité d''entreprise TexNord — Sortie d''automne à Honfleur, samedi 11 octobre

7 h 15 : rendez-vous sur le parking de l''usine — départ du car à 7 h 30 précises
10 h : visite guidée du vieux port et des ruelles (2 heures)
12 h 30 : déjeuner au restaurant La Marée (inclus dans le tarif)
14 h 30 : temps libre — musée, boutiques ou promenade sur la plage
17 h : départ du car, retour vers 19 h 30

Tarif : 25 euros par salarié, 35 euros par accompagnant. Inscription auprès de Rachid avant le 30 septembre. Attention : au retour, le car n''attendra pas les retardataires.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00a-4000-0000-000000000006', 'TEXTE',
   'Ville de Roncey — Matinée d''accueil des nouveaux habitants, samedi 7 février, hôtel de ville

9 h 30 : café de bienvenue dans le hall
10 h : mot du maire et présentation des services municipaux
10 h 45 : forum des associations — stands sport, culture et solidarité
11 h 30 : visite du centre historique en petit groupe, guidée par Olena, du service du patrimoine
12 h 30 : verre de l''amitié et remise d''un guide pratique de la ville

La visite du centre historique étant limitée à vingt personnes, merci de vous inscrire au moment du café de bienvenue. Les enfants sont les bienvenus : un espace jeux est prévu dans le hall.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00a-4000-0000-000000000007', 'TEXTE',
   'Atelier Saveurs — Stage « Cuisines du monde », du lundi 4 au vendredi 8 août, 9 h 30 - 13 h

Lundi : tajines et pâtisseries du Maghreb
Mardi : raviolis vapeur et nouilles sautées d''Asie
Mercredi : ceviche et empanadas d''Amérique du Sud, avec le chef invité Diego Ramos
Jeudi : currys et pains indiens
Vendredi : grand repas préparé sur place et partagé avec les familles des participants

Chaque participant repart chaque jour avec ses préparations : apportez seulement deux boîtes hermétiques. Tabliers et ingrédients fournis. Tarif : 180 euros la semaine. Le stage est confirmé à partir de huit inscrits.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00a-4000-0000-000000000008', 'TEXTE',
   'Mission locale de Bresselle — Matinée « Jobs d''été », mercredi 15 avril, 9 h - 13 h, salle des Glycines

9 h : atelier CV — apportez votre CV imprimé ou sur clé USB
10 h : rencontre avec les employeurs : hôtellerie, agriculture, animation
11 h 30 : témoignage de Fatou, animatrice, sur son premier emploi saisonnier
12 h : entretiens express de dix minutes avec les recruteurs présents

Entrée gratuite, sans inscription, ouverte aux 16-25 ans. Pour les entretiens express, prenez un ticket de passage dès votre arrivée : seuls les cinquante premiers tickets donnent accès aux recruteurs.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00a-4000-0000-000000000009', 'TEXTE',
   'École des Acacias — Classe découverte à la ferme, du lundi 12 au mercredi 14 mai (classes de CE2)

Lundi : départ à 8 h 30 — installation, puis soin des animaux l''après-midi
Mardi : fabrication de pain et de fromage ; veillée contes le soir
Mercredi : marché fermier le matin, retour à l''école vers 17 h

Chaque enfant garde un petit sac à dos pour la journée ; la grosse valise voyage en soute. Les téléphones portables restent à la maison : les familles recevront chaque soir des nouvelles par la messagerie de l''école. Réunion d''information pour les parents le jeudi 24 avril à 18 h. La directrice, Hanna Kovacs.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00a-4000-0000-00000000000a', 'TEXTE',
   'Association Rivières Propres — Journée de nettoyage des berges du Lez, dimanche 5 octobre

9 h : accueil au pont de la Fontaine — distribution des gants et des sacs, inscriptions à l''atelier de l''après-midi
9 h 30 : répartition des équipes par zone (centre-ville ou sentier des pêcheurs)
12 h 30 : pique-nique offert par l''association au parc des Saules
14 h : pesée des déchets collectés et photo de groupe
15 h : atelier « fabriquer ses produits ménagers », animé par Aïcha — réservé aux trente premiers inscrits du matin

Matériel fourni ; venez avec des bottes et des vêtements qui ne craignent rien. Les enfants participent sous la responsabilité d''un adulte. Annulation en cas de crue, affichée la veille sur le site de l''association.',
   NULL, '22222222-0000-0000-0000-000000000002');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-b00a-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00a-4000-0000-000000000001',
   NULL, 'B1', 'CE',
   'Que doit faire un visiteur qui veut participer à l''atelier sur les liseuses numériques ?',
   'La dernière ligne du programme précise : « Les inscriptions à l''atelier numérique se font à l''accueil, dans la limite de douze places ». C''est un **repérage explicite de la modalité d''inscription** : on s''inscrit sur place, à l''accueil. La réponse A confond avec la visite guidée des coulisses (« réservation conseillée ») et invente un appel téléphonique absent du texte. La réponse B contredit « Entrée libre toute la journée » : rien n''est payant. La réponse D confond deux horaires proches : 14 h correspond aux contes pour enfants, alors que l''atelier a lieu à 11 h — piège classique de **confusion entre deux créneaux du programme**.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b00a-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00a-4000-0000-000000000002',
   NULL, 'B1', 'CE',
   'Que prévoit le programme du club en cas d''orage ?',
   'Le programme indique : « En cas d''orage, la randonnée est remplacée par une visite du musée de la montagne ». C''est un **repérage explicite de la solution de remplacement** introduite par la locution conditionnelle « en cas de ». La réponse B exagère : rien n''annonce l''annulation ni le report du week-end entier, seule la randonnée est concernée. La réponse C déplace l''information sur une autre activité : le barbecue du soir n''est pas mentionné dans la clause de repli. La réponse D invente un simple retard de départ que le texte ne prévoit pas — le piège consiste à **étendre la condition météo à tout le programme** au lieu de la limiter à la randonnée.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b00a-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00a-4000-0000-000000000003',
   NULL, 'B1', 'CE',
   'Quelles activités de la fête sont payantes ?',
   'Le programme conclut : « Toutes les animations sont gratuites, sauf le tournoi de pétanque et la tombola », ce que confirment les mentions « 2 euros par équipe » et « billets en vente ». La bonne réponse **reformule la restriction introduite par « sauf »** — mécanisme d''exception à repérer. La réponse A contredit le texte : le spectacle de marionnettes est « offert » et le concert fait partie des animations gratuites. La réponse C déforme le repas partagé : chacun « apporte un plat à mettre en commun », personne ne paie. La réponse D sur-généralise en rendant payante toute la journée, alors que la gratuité est la règle et le payant l''exception.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reformulation'),

  ('11111111-b00a-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00a-4000-0000-000000000004',
   NULL, 'B1', 'CE',
   'Que risque un participant absent qui n''a pas prévenu à temps ?',
   'Le programme précise : « toute absence non signalée 48 heures à l''avance sera facturée 20 euros ». Par **inférence simple**, on comprend que la formation, gratuite au départ, devient payante pour celui qui ne prévient pas — le verbe « facturer » signale la **conséquence financière**. La réponse A invente un rattrapage de l''évaluation que le texte ne mentionne nulle part. La réponse B confond : l''attestation est remise aux participants présents à 17 h 30, on ne « perd » rien. La réponse C extrapole une exclusion des formations municipales jamais évoquée — la mairie n''apparaît que comme financeur. Le piège est de chercher une sanction pédagogique alors qu''elle est uniquement financière.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-b00a-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00a-4000-0000-000000000005',
   NULL, 'B1', 'CE',
   'Que comprend le tarif de la sortie à Honfleur ?',
   'Le déjeuner au restaurant La Marée est noté « inclus dans le tarif », et le trajet se fait dans le car affrété pour la sortie (départ 7 h 30, retour 19 h 30) : la bonne réponse **reformule ce que couvre le prix** — transport et repas de midi. La réponse A est fausse : le musée appartient au « temps libre », donc à la charge de chacun. La réponse C transforme la « visite guidée du vieux port et des ruelles », qui se fait à pied, en promenade en bateau — **glissement thématique** sur le vocabulaire du port. La réponse D invente un panier-repas pour le retour, alors que le programme ne prévoit aucun repas après 12 h 30.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reformulation'),

  ('11111111-b00a-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00a-4000-0000-000000000006',
   NULL, 'B1', 'CE',
   'Comment participer à la visite du centre historique ?',
   'Le programme demande : « merci de vous inscrire au moment du café de bienvenue », car la visite est « limitée à vingt personnes ». C''est un **repérage explicite de la consigne d''inscription**, à relier au créneau de 9 h 30. La réponse A invente une démarche préalable par écrit que rien n''exige. La réponse B est le piège principal : se présenter directement à 11 h 30 ne suffit pas, précisément **parce que les places sont limitées** — il faut s''être inscrit le matin. La réponse D confond la personne qui guide (Olena, du service du patrimoine) avec un point d''inscription : le texte ne demande aucune réservation auprès de ce service.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b00a-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00a-4000-0000-000000000007',
   NULL, 'B1', 'CE',
   'Que doivent apporter les participants au stage de cuisine ?',
   'Le programme indique : « apportez seulement deux boîtes hermétiques », parce que « chaque participant repart chaque jour avec ses préparations ». C''est un **repérage explicite renforcé par l''adverbe restrictif « seulement »**, qui exclut tout autre matériel. Les réponses B et C contredisent directement la mention « Tabliers et ingrédients fournis » : ni les uns ni les autres ne sont à la charge des stagiaires. La réponse D déforme le programme du vendredi : le grand repas est « préparé sur place » pendant le stage et partagé avec les familles, il n''est pas apporté de la maison — confusion entre **préparer** et **apporter** un plat.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b00a-1000-0000-000000000008', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00a-4000-0000-000000000008',
   NULL, 'B1', 'CE',
   'Pourquoi a-t-on intérêt à arriver tôt à cette matinée ?',
   'Le texte demande de prendre « un ticket de passage dès votre arrivée » car « seuls les cinquante premiers tickets donnent accès aux recruteurs ». Par **inférence simple**, arriver tôt = obtenir un ticket = pouvoir passer un entretien express : la bonne réponse relie ces deux informations. La réponse A invente une limite de places pour l''atelier CV, jamais mentionnée. La réponse B contredit « Entrée gratuite, sans inscription », valable toute la matinée. La réponse C confond deux créneaux proches : à 11 h 30 a lieu le témoignage de Fatou, et les recruteurs sont justement présents à 12 h pour les entretiens — **confusion entre deux moments du programme**.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-b00a-1000-0000-000000000009', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00a-4000-0000-000000000009',
   NULL, 'B1', 'CE',
   'Comment les parents auront-ils des nouvelles pendant le séjour ?',
   'Le programme annonce : « les familles recevront chaque soir des nouvelles par la messagerie de l''école ». La bonne réponse **reformule ce canal d''information quotidien**. La réponse A est rendue impossible par la phrase précédente : « Les téléphones portables restent à la maison » — le connecteur « : » montre que la messagerie remplace justement les appels. La réponse C confond la chronologie : la réunion du 24 avril a lieu **avant** le départ pour informer les parents, elle ne donne pas de nouvelles pendant le séjour. La réponse D invente un contact direct avec la ferme que le programme ne propose nulle part — l''école reste l''unique intermédiaire.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reformulation'),

  ('11111111-b00a-1000-0000-00000000000a', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00a-4000-0000-00000000000a',
   NULL, 'B1', 'CE',
   'Qui peut participer à l''atelier de 15 h ?',
   'L''atelier « fabriquer ses produits ménagers » est « réservé aux trente premiers inscrits du matin », et la ligne de 9 h précise que les inscriptions se prennent à l''accueil. Par **inférence simple**, il faut relier ces deux moments du programme : seuls ceux qui se sont inscrits dès le matin, dans la limite de trente, y participent. La réponse A sur-généralise : être présent l''après-midi ne suffit pas, l''adjectif « réservé » marque la **restriction d''accès**. La réponse B détourne la phrase sur les enfants, qui concerne la responsabilité des adultes, pas l''atelier. La réponse D invente une condition d''adhésion : la journée est ouverte à tous les bénévoles, pas aux seuls membres.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  -- Q01 — portes ouvertes médiathèque (bonne réponse : position 3)
  ('11111111-b00a-2100-0000-000000000001', '11111111-b00a-1000-0000-000000000001',
   'Réserver sa place par téléphone avant le 14 mars',
   'false', '1'),
  ('11111111-b00a-2200-0000-000000000001', '11111111-b00a-1000-0000-000000000001',
   'Acheter un billet d''entrée à l''accueil de la médiathèque',
   'false', '2'),
  ('11111111-b00a-2300-0000-000000000001', '11111111-b00a-1000-0000-000000000001',
   'S''inscrire à l''accueil, car les places sont limitées',
   'true', '3'),
  ('11111111-b00a-2400-0000-000000000001', '11111111-b00a-1000-0000-000000000001',
   'Se présenter à 14 h dans la salle de lecture',
   'false', '4'),

  -- Q02 — week-end du club de randonnée (bonne réponse : position 1)
  ('11111111-b00a-2100-0000-000000000002', '11111111-b00a-1000-0000-000000000002',
   'La randonnée est remplacée par la visite d''un musée',
   'true', '1'),
  ('11111111-b00a-2200-0000-000000000002', '11111111-b00a-1000-0000-000000000002',
   'Le week-end est annulé et reporté à une autre date',
   'false', '2'),
  ('11111111-b00a-2300-0000-000000000002', '11111111-b00a-1000-0000-000000000002',
   'Le barbecue est déplacé au gymnase Jean-Moulin',
   'false', '3'),
  ('11111111-b00a-2400-0000-000000000002', '11111111-b00a-1000-0000-000000000002',
   'Le départ du minibus est retardé jusqu''à la fin de l''orage',
   'false', '4'),

  -- Q03 — fête du quartier des Tilleuls (bonne réponse : position 2)
  ('11111111-b00a-2100-0000-000000000003', '11111111-b00a-1000-0000-000000000003',
   'Le concert et le spectacle de marionnettes',
   'false', '1'),
  ('11111111-b00a-2200-0000-000000000003', '11111111-b00a-1000-0000-000000000003',
   'Le tournoi de pétanque et la tombola',
   'true', '2'),
  ('11111111-b00a-2300-0000-000000000003', '11111111-b00a-1000-0000-000000000003',
   'Le grand repas partagé de midi',
   'false', '3'),
  ('11111111-b00a-2400-0000-000000000003', '11111111-b00a-1000-0000-000000000003',
   'Toutes les animations de la journée',
   'false', '4'),

  -- Q04 — formation premiers secours (bonne réponse : position 4)
  ('11111111-b00a-2100-0000-000000000004', '11111111-b00a-1000-0000-000000000004',
   'Il devra repasser l''évaluation un autre jour',
   'false', '1'),
  ('11111111-b00a-2200-0000-000000000004', '11111111-b00a-1000-0000-000000000004',
   'Il perdra son attestation de formation',
   'false', '2'),
  ('11111111-b00a-2300-0000-000000000004', '11111111-b00a-1000-0000-000000000004',
   'Il ne pourra plus s''inscrire aux formations de la mairie',
   'false', '3'),
  ('11111111-b00a-2400-0000-000000000004', '11111111-b00a-1000-0000-000000000004',
   'Il devra payer 20 euros',
   'true', '4'),

  -- Q05 — sortie à Honfleur (bonne réponse : position 2)
  ('11111111-b00a-2100-0000-000000000005', '11111111-b00a-1000-0000-000000000005',
   'L''entrée au musée pendant le temps libre',
   'false', '1'),
  ('11111111-b00a-2200-0000-000000000005', '11111111-b00a-1000-0000-000000000005',
   'Le transport en car et le déjeuner au restaurant',
   'true', '2'),
  ('11111111-b00a-2300-0000-000000000005', '11111111-b00a-1000-0000-000000000005',
   'Une promenade en bateau dans le vieux port',
   'false', '3'),
  ('11111111-b00a-2400-0000-000000000005', '11111111-b00a-1000-0000-000000000005',
   'Un panier-repas pour le voyage de retour',
   'false', '4'),

  -- Q06 — accueil des nouveaux habitants (bonne réponse : position 3)
  ('11111111-b00a-2100-0000-000000000006', '11111111-b00a-1000-0000-000000000006',
   'En écrivant à la mairie avant le 7 février',
   'false', '1'),
  ('11111111-b00a-2200-0000-000000000006', '11111111-b00a-1000-0000-000000000006',
   'En se présentant directement à 11 h 30 devant l''hôtel de ville',
   'false', '2'),
  ('11111111-b00a-2300-0000-000000000006', '11111111-b00a-1000-0000-000000000006',
   'En s''inscrivant le matin même, pendant le café de bienvenue',
   'true', '3'),
  ('11111111-b00a-2400-0000-000000000006', '11111111-b00a-1000-0000-000000000006',
   'En réservant auprès du service du patrimoine',
   'false', '4'),

  -- Q07 — stage de cuisine (bonne réponse : position 1)
  ('11111111-b00a-2100-0000-000000000007', '11111111-b00a-1000-0000-000000000007',
   'Des boîtes pour emporter leurs préparations',
   'true', '1'),
  ('11111111-b00a-2200-0000-000000000007', '11111111-b00a-1000-0000-000000000007',
   'Leurs propres ingrédients pour chaque journée',
   'false', '2'),
  ('11111111-b00a-2300-0000-000000000007', '11111111-b00a-1000-0000-000000000007',
   'Un tablier de cuisine personnel',
   'false', '3'),
  ('11111111-b00a-2400-0000-000000000007', '11111111-b00a-1000-0000-000000000007',
   'Un plat préparé pour le repas du vendredi',
   'false', '4'),

  -- Q08 — matinée jobs d''été (bonne réponse : position 4)
  ('11111111-b00a-2100-0000-000000000008', '11111111-b00a-1000-0000-000000000008',
   'L''atelier CV n''accepte que les premiers arrivés',
   'false', '1'),
  ('11111111-b00a-2200-0000-000000000008', '11111111-b00a-1000-0000-000000000008',
   'L''entrée devient payante après 10 h',
   'false', '2'),
  ('11111111-b00a-2300-0000-000000000008', '11111111-b00a-1000-0000-000000000008',
   'Les employeurs quittent la salle à 11 h 30',
   'false', '3'),
  ('11111111-b00a-2400-0000-000000000008', '11111111-b00a-1000-0000-000000000008',
   'Le nombre de tickets pour les entretiens est limité',
   'true', '4'),

  -- Q09 — classe découverte à la ferme (bonne réponse : position 2)
  ('11111111-b00a-2100-0000-000000000009', '11111111-b00a-1000-0000-000000000009',
   'En appelant leur enfant sur son téléphone portable',
   'false', '1'),
  ('11111111-b00a-2200-0000-000000000009', '11111111-b00a-1000-0000-000000000009',
   'En recevant chaque soir un message de l''école',
   'true', '2'),
  ('11111111-b00a-2300-0000-000000000009', '11111111-b00a-1000-0000-000000000009',
   'En assistant à la réunion du jeudi 24 avril',
   'false', '3'),
  ('11111111-b00a-2400-0000-000000000009', '11111111-b00a-1000-0000-000000000009',
   'En contactant directement la ferme',
   'false', '4'),

  -- Q10 — journée de nettoyage des berges (bonne réponse : position 3)
  ('11111111-b00a-2100-0000-00000000000a', '11111111-b00a-1000-0000-00000000000a',
   'Tous les bénévoles présents l''après-midi',
   'false', '1'),
  ('11111111-b00a-2200-0000-00000000000a', '11111111-b00a-1000-0000-00000000000a',
   'Uniquement les adultes accompagnés d''enfants',
   'false', '2'),
  ('11111111-b00a-2300-0000-00000000000a', '11111111-b00a-1000-0000-00000000000a',
   'Les personnes inscrites le matin, dans la limite de trente places',
   'true', '3'),
  ('11111111-b00a-2400-0000-00000000000a', '11111111-b00a-1000-0000-00000000000a',
   'Les membres de l''association seulement',
   'false', '4');

-- ============================================================================
-- CHECKLIST — contrôles passés
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes (11111111-b00a-1000/4000/21..2400-…-NN, NN=01..0a).
-- [x] Support unique : programme détaillé (10 organisateurs et situations toutes
--     différentes : portes ouvertes médiathèque, week-end club de randonnée,
--     fête de quartier, formation PSC1, sortie comité d''entreprise, accueil
--     nouveaux habitants en mairie, stage de cuisine, matinée jobs d''été,
--     classe découverte scolaire, journée de nettoyage associative).
-- [x] Aucun support interdit utilisé (pas d''e-mail, note d''information,
--     brochure, FAQ, communiqué, annonce, etc.) — uniquement des programmes
--     horaires avec en-tête, créneaux et mentions pratiques.
-- [x] Passages TEXTE ~60-120 mots, mise en forme programme (titre, lignes
--     horaires, notes finales), media_id NULL.
-- [x] 4 propositions / 1 correcte par item. Distribution des bonnes réponses :
--     pos1:2, pos2:3, pos3:3, pos4:2 (max 3 par position, 4 positions utilisées).
-- [x] competence_code : ce_reperage_explicite x4 (Q1, Q2, Q6, Q7),
--     ce_inference_intention x3 (Q4, Q8, Q10), ce_reformulation x3 (Q3, Q5, Q9).
-- [x] explanation ≥ 80 caractères : bonne réponse justifiée + les 3 distracteurs
--     expliqués, point clé en **gras**, mécanisme linguistique nommé (restriction
--     par « sauf », adverbe « seulement », inférence de conséquence, confusion
--     de créneaux, glissement thématique…).
-- [x] Pas de SVG ni SSML dans ce lot (supports textuels uniquement) — rien à
--     équilibrer.
-- [x] Apostrophes SQL doublées partout, contenu 100% original, items autonomes,
--     prénoms variés (Priya, Amadou, Wei, Lucia, Rachid, Olena, Diego, Fatou,
--     Hanna, Aïcha).
-- ============================================================================
