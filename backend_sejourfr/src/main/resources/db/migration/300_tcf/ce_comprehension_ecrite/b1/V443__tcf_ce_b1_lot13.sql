-- ============================================================================
-- V443 — TCF CE B1 — lot 13 (support : lettre de motivation courte)
-- ----------------------------------------------------------------------------
-- 10 items de compréhension écrite B1. Support unique : lettre de motivation
-- courte (vente en boulangerie, serveur saisonnier, bénévolat aide aux
-- devoirs, formation auxiliaire de puériculture, stage en cuisine, agent
-- d''accueil de médiathèque, livreur à vélo, apprentissage coiffure,
-- animateur de centre de loisirs, femme de chambre saisonnière). Passages
-- TEXTE (~60-120 mots), questions + choices (4 rows/question). theme_id =
-- 22222222-0000-0000-0000-000000000002, difficulty='B1', question_type='CE'.
-- Données déterministes, rejouables dev+recette.
-- ============================================================================


-- passages — supports de lecture référencés par les questions ci-dessous
INSERT INTO passages
  (id, type, content, media_id, theme_id)
VALUES
  ('11111111-b00d-4000-0000-000000000001', 'TEXTE',
   'Madame, Monsieur,

Cliente régulière de votre boulangerie du quartier Saint-Michel, j''ai remarqué l''affiche indiquant que vous cherchez une vendeuse pour les week-ends. Je travaille en semaine comme aide de cuisine dans une cantine scolaire et je souhaite compléter mes revenus. J''ai tenu une caisse pendant deux ans dans une épicerie, et je connais bien vos produits. Je suis disponible le samedi et le dimanche dès 6 h 30. Je me tiens à votre disposition pour un entretien à l''heure qui vous conviendra.

Cordialement,
Fatou Sylla',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00d-4000-0000-000000000002', 'TEXTE',
   'Madame, Monsieur,

Je vous écris en réponse à votre annonce parue le 12 mai sur le site de la mairie de Royan, pour un poste de serveur du 1er juillet au 31 août. Étudiant en école de commerce, j''ai travaillé l''été dernier dans une brasserie à Saintes, où je servais jusqu''à quatre-vingts couverts par service. Je parle espagnol et anglais, un atout avec votre clientèle de touristes. Je serai libre dès la fin de mes examens, le 26 juin. Vous trouverez ci-joint mon CV.

Dans l''attente de votre réponse, je vous prie d''agréer mes salutations distinguées.

Diego Fernández',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00d-4000-0000-000000000003', 'TEXTE',
   'Madame la Présidente,

J''ai appris par votre site internet que l''association Coup de Pouce recherche des bénévoles pour accompagner des collégiens dans leurs devoirs, le mercredi après-midi. Professeure de mathématiques à la retraite depuis septembre, je dispose de temps libre et j''aimerais le consacrer à la transmission. J''ai enseigné pendant trente ans en collège, notamment auprès d''élèves en difficulté. Je précise que je ne suis disponible que deux mercredis par mois, car je garde mes petits-enfants les autres semaines. Pourrions-nous convenir d''un rendez-vous pour en parler ?

Bien cordialement,
Priya Sharma',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00d-4000-0000-000000000004', 'TEXTE',
   'Madame, Monsieur,

Je souhaite intégrer la formation d''auxiliaire de puériculture que propose votre institut à la rentrée de janvier. Assistante maternelle depuis cinq ans, je garde trois enfants à mon domicile et je veux maintenant obtenir un diplôme pour travailler en crèche. Mon expérience m''a appris la patience et le sens de l''observation, mais il me manque les connaissances théoriques que votre programme apporte. Je suis prête à passer les épreuves de sélection à la date de votre choix.

Veuillez agréer, Madame, Monsieur, mes salutations respectueuses.

Olena Kovalenko',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00d-4000-0000-000000000005', 'TEXTE',
   'Monsieur le Chef,

Élève en première année de CAP cuisine au lycée hôtelier de Dijon, je dois effectuer un stage de six semaines à partir du 3 mars. Votre restaurant m''attire particulièrement : j''ai lu que vous travaillez uniquement des légumes de producteurs locaux, une démarche qui correspond exactement à ce que je veux apprendre. Je suis sérieux, ponctuel et habitué aux horaires du soir, car j''aide déjà mes parents dans leur propre restaurant le week-end. Je peux passer me présenter quand vous le souhaitez.

Respectueusement,
Wei Zhang',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00d-4000-0000-000000000006', 'TEXTE',
   'Madame la Directrice,

Votre médiathèque recrute un agent d''accueil à mi-temps, comme l''indique l''annonce affichée à l''entrée. Ce poste m''intéresse vivement. Ancien réceptionniste d''hôtel pendant huit ans, je sais accueillir tous les publics, gérer les inscriptions et rester calme dans les moments d''affluence. Lecteur assidu, je fréquente vos salles depuis mon arrivée à Limoges, il y a trois ans. Un mi-temps me conviendrait parfaitement, car je suis des cours de comptabilité le matin. Je serais heureux de vous exposer ma motivation lors d''un entretien.

Veuillez croire, Madame, en mon entier dévouement.

Rachid Benali',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00d-4000-0000-000000000007', 'TEXTE',
   'Madame, Monsieur,

J''ai vu sur la vitrine de votre magasin de fruits et légumes que vous cherchez un livreur pour les commandes du matin. Sportif et matinal, je connais parfaitement les rues du centre de Nantes, où j''habite depuis dix ans. Je possède mon propre vélo équipé de sacoches et je suis libre tous les jours de 6 h à 11 h, avant mes cours de français à l''université. Je peux commencer dès la semaine prochaine si vous le souhaitez.

Cordialement,
Amadou Diop',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00d-4000-0000-000000000008', 'TEXTE',
   'Madame,

Actuellement en troisième au collège Jean-Moulin, je recherche un salon pour préparer un CAP coiffure en apprentissage à partir de septembre. Votre salon m''a été recommandé par ma tante, qui est cliente chez vous depuis des années et qui apprécie l''ambiance de votre équipe. J''ai effectué mon stage de découverte dans un salon de mon quartier : j''y ai appris à faire les shampoings, à accueillir les clientes et à garder le bac de lavage propre. Je suis motivée, souriante et je n''ai pas peur des journées debout.

Je vous remercie de votre attention,
Lucia Moreira',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00d-4000-0000-000000000009', 'TEXTE',
   'Monsieur le Directeur,

Titulaire du BAFA depuis avril, je propose ma candidature pour animer votre centre de loisirs cet été. Votre annonce précise que vous cherchez quelqu''un pour le mois de juillet ; je tiens cependant à être honnête : je pars en stage la dernière semaine du mois, du 25 au 31 juillet. Si cette absence est un obstacle, je comprendrai. En revanche, je suis aussi disponible tout le mois d''août, si vous avez besoin de renfort à cette période. J''ai encadré des enfants de six à dix ans lors de deux colonies de vacances.

Sincèrement,
Marek Nowak',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00d-4000-0000-00000000000a', 'TEXTE',
   'Madame, Monsieur,

Votre hôtel recherche une femme de chambre pour la saison, d''après l''annonce publiée à l''agence pour l''emploi de La Rochelle. J''ai occupé ce poste pendant trois saisons dans une résidence de vacances sur l''île de Ré : préparation des chambres, gestion du linge, signalement des réparations nécessaires. Mon ancienne responsable, Mme Carvalho, peut être contactée pour confirmer mon sérieux ; ses coordonnées figurent sur mon CV. Je précise que je suis logée à La Rochelle et que je n''ai donc pas besoin d''hébergement sur place.

Salutations distinguées,
Aïcha Traoré',
   NULL, '22222222-0000-0000-0000-000000000002');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-b00d-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00d-4000-0000-000000000001',
   NULL, 'B1', 'CE',
   'Quel poste Fatou souhaite-t-elle obtenir ?',
   'Fatou écrit : « vous cherchez une vendeuse pour les week-ends » et propose sa candidature avec sa disponibilité « le samedi et le dimanche dès 6 h 30 ». C''est un **repérage explicite du poste visé** : vendeuse en boulangerie le week-end. La réponse A confond le poste visé avec son **emploi actuel** : elle travaille déjà « en semaine comme aide de cuisine dans une cantine scolaire ». La réponse C confond le poste visé avec son **expérience passée** : la caisse de l''épicerie est un argument, pas une candidature. La réponse D déforme à la fois le métier (vendre, pas fabriquer le pain) et le volume horaire : elle vise un complément de week-end, pas un temps plein.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b00d-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00d-4000-0000-000000000002',
   NULL, 'B1', 'CE',
   'Quelle expérience professionnelle Diego met-il en avant ?',
   'Diego écrit : « j''ai travaillé l''été dernier dans une brasserie à Saintes, où je servais jusqu''à quatre-vingts couverts par service ». C''est un **repérage explicite de l''expérience citée** : une saison de serveur à Saintes. La réponse A confond formation et expérience : l''école de commerce décrit son statut d''étudiant, pas un emploi exercé. La réponse B déforme l''argument des langues : parler espagnol et anglais est un **atout pour servir** la clientèle touristique, il n''a jamais été guide. La réponse D inverse les lieux, piège de **confusion entre deux informations proches** : Royan est la ville du poste visé, la brasserie où il a déjà travaillé se trouve à Saintes.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b00d-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00d-4000-0000-000000000003',
   NULL, 'B1', 'CE',
   'Quelle est la disponibilité réelle de Priya ?',
   'Priya précise : « je ne suis disponible que deux mercredis par mois, car je garde mes petits-enfants les autres semaines ». C''est un **repérage explicite de la restriction** marquée par « ne… que », qui limite la disponibilité. La réponse B confond le créneau proposé par l''association (« le mercredi après-midi », tous les mercredis) avec la disponibilité personnelle de Priya — piège de **confusion entre deux informations proches**. La réponse C invente une contrainte de vacances que la lettre ne mentionne jamais. La réponse D inverse la logique de la phrase : les mercredis où elle garde ses petits-enfants sont précisément ceux où elle n''est **pas** disponible.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b00d-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00d-4000-0000-000000000004',
   NULL, 'B1', 'CE',
   'Quel est l''objectif professionnel d''Olena ?',
   'Olena écrit : « je veux maintenant obtenir un diplôme pour travailler en crèche ». La bonne réponse **reformule ce but** : se diplômer pour changer de cadre de travail. La réponse A confond l''objectif avec sa **situation actuelle** : garder trois enfants à domicile est ce qu''elle fait déjà depuis cinq ans, et l''adverbe « maintenant » marque justement la volonté de changement. La réponse B est une **sur-généralisation** : travailler en crèche ne signifie pas en ouvrir une, rien dans la lettre n''évoque une création d''établissement. La réponse C déforme son rapport à l''institut : elle veut y suivre la formation comme élève, pas y enseigner.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reformulation'),

  ('11111111-b00d-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00d-4000-0000-000000000005',
   NULL, 'B1', 'CE',
   'Pourquoi Wei a-t-il choisi ce restaurant pour son stage ?',
   'Wei explique : « vous travaillez uniquement des légumes de producteurs locaux, une démarche qui correspond exactement à ce que je veux apprendre ». C''est une **inférence d''intention simple** : son choix est motivé par cette cuisine de produits locaux. La réponse B confond deux restaurants, piège de **confusion entre informations proches** : le restaurant de ses parents est celui où il aide le week-end, pas celui où il postule. La réponse C déforme l''objet de la lettre : il demande un stage obligatoire de six semaines, personne ne lui a proposé de poste. La réponse D invente une exclusivité : rien n''indique que ce soit le seul établissement acceptant les élèves de son lycée.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-b00d-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00d-4000-0000-000000000006',
   NULL, 'B1', 'CE',
   'Quel est l''objet de la lettre de Rachid ?',
   'Rachid annonce : « Votre médiathèque recrute un agent d''accueil à mi-temps […] Ce poste m''intéresse vivement », puis demande un entretien. La bonne réponse **reformule cette candidature** au poste d''agent d''accueil. La réponse A confond l''objet de la lettre avec un détail biographique : il est déjà « lecteur assidu » qui « fréquente vos salles depuis trois ans », il n''a pas besoin de s''inscrire. La réponse C confond le poste visé avec son **ancien métier** : réceptionniste d''hôtel est l''expérience qu''il met en avant, pas ce qu''il recherche. La réponse D déforme la mention des cours de comptabilité : il les suit déjà le matin, c''est la **raison** pour laquelle un mi-temps lui convient, pas une demande.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reformulation'),

  ('11111111-b00d-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00d-4000-0000-000000000007',
   NULL, 'B1', 'CE',
   'Que comprend-on de l''emploi du temps d''Amadou ?',
   'Amadou écrit : « je suis libre tous les jours de 6 h à 11 h, avant mes cours de français à l''université ». Par **inférence simple**, on comprend que ses matinées sont libres et que ses cours commencent après 11 h — c''est ce qui rend les livraisons du matin possibles. La réponse A inverse l''ordre des activités marqué par la préposition « avant » : les cours viennent **après** le créneau libre, pas tôt le matin. La réponse C est une **sur-généralisation** : sa disponibilité s''arrête à 11 h, il ne peut pas livrer toute la journée. La réponse D contredit la fin de la lettre : il peut commencer « dès la semaine prochaine », pas dans un mois.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-b00d-1000-0000-000000000008', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00d-4000-0000-000000000008',
   NULL, 'B1', 'CE',
   'Que cherche Lucia ?',
   'Lucia écrit : « je recherche un salon pour préparer un CAP coiffure en apprentissage à partir de septembre ». La bonne réponse **reformule cette recherche d''apprentissage** : un salon qui l''accueillera pendant sa formation. La réponse A confond ce qu''elle cherche avec ce qu''elle a **déjà fait** : le stage de découverte est terminé, le passé composé « j''ai effectué » marque l''action accomplie. La réponse B anticipe trop : élève de troisième sans diplôme, elle ne peut pas postuler comme coiffeuse qualifiée — c''est justement le but du CAP. La réponse D détourne un détail secondaire : la tante n''est citée que comme cliente qui a **recommandé** le salon, il n''est jamais question de lui prendre un rendez-vous.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reformulation'),

  ('11111111-b00d-1000-0000-000000000009', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00d-4000-0000-000000000009',
   NULL, 'B1', 'CE',
   'Que propose Marek si son absence de fin juillet pose problème ?',
   'Marek écrit : « En revanche, je suis aussi disponible tout le mois d''août, si vous avez besoin de renfort à cette période ». Par **inférence d''intention**, on comprend qu''il offre une solution de remplacement : travailler en août si son absence du 25 au 31 juillet est un obstacle — le connecteur d''opposition « en revanche » introduit cette alternative. La réponse A contredit sa lettre : le stage est présenté comme un engagement ferme, il ne propose jamais d''y renoncer. La réponse B invente un remplaçant dont il n''est jamais question. La réponse C inverse la situation, piège de **confusion entre deux informations proches** : la dernière semaine de juillet est précisément celle où il est absent, pas celle où il travaillerait.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-b00d-1000-0000-00000000000a', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00d-4000-0000-00000000000a',
   NULL, 'B1', 'CE',
   'Pourquoi Aïcha mentionne-t-elle Mme Carvalho ?',
   'Aïcha écrit : « Mon ancienne responsable, Mme Carvalho, peut être contactée pour confirmer mon sérieux ». C''est un **repérage explicite de la fonction de cette personne** : une référence professionnelle issue de la résidence de vacances de l''île de Ré. La réponse B confond les deux établissements, piège de **confusion entre informations proches** : Mme Carvalho dirigeait son ancien lieu de travail, pas l''hôtel où elle postule. La réponse C mélange deux passages sans lien : le logement à La Rochelle explique seulement qu''elle n''a pas besoin d''hébergement, aucune logeuse n''est nommée. La réponse D invente un rôle : l''annonce a été publiée à l''agence pour l''emploi, rien ne la relie à Mme Carvalho.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  -- Q01 — candidature de Fatou en boulangerie (bonne réponse : position 2)
  ('11111111-b00d-2100-0000-000000000001', '11111111-b00d-1000-0000-000000000001',
   'Aide de cuisine dans une cantine scolaire',
   'false', '1'),
  ('11111111-b00d-2200-0000-000000000001', '11111111-b00d-1000-0000-000000000001',
   'Vendeuse en boulangerie le week-end',
   'true', '2'),
  ('11111111-b00d-2300-0000-000000000001', '11111111-b00d-1000-0000-000000000001',
   'Caissière dans une épicerie de quartier',
   'false', '3'),
  ('11111111-b00d-2400-0000-000000000001', '11111111-b00d-1000-0000-000000000001',
   'Boulangère à temps plein',
   'false', '4'),

  -- Q02 — saison de Diego (bonne réponse : position 3)
  ('11111111-b00d-2100-0000-000000000002', '11111111-b00d-1000-0000-000000000002',
   'Ses études dans une école de commerce',
   'false', '1'),
  ('11111111-b00d-2200-0000-000000000002', '11111111-b00d-1000-0000-000000000002',
   'Un emploi de guide pour touristes étrangers',
   'false', '2'),
  ('11111111-b00d-2300-0000-000000000002', '11111111-b00d-1000-0000-000000000002',
   'Une saison comme serveur dans une brasserie à Saintes',
   'true', '3'),
  ('11111111-b00d-2400-0000-000000000002', '11111111-b00d-1000-0000-000000000002',
   'Un poste de serveur dans un restaurant de Royan',
   'false', '4'),

  -- Q03 — bénévolat de Priya (bonne réponse : position 1)
  ('11111111-b00d-2100-0000-000000000003', '11111111-b00d-1000-0000-000000000003',
   'Deux mercredis par mois seulement',
   'true', '1'),
  ('11111111-b00d-2200-0000-000000000003', '11111111-b00d-1000-0000-000000000003',
   'Tous les mercredis après-midi',
   'false', '2'),
  ('11111111-b00d-2300-0000-000000000003', '11111111-b00d-1000-0000-000000000003',
   'Toutes les semaines, sauf pendant les vacances scolaires',
   'false', '3'),
  ('11111111-b00d-2400-0000-000000000003', '11111111-b00d-1000-0000-000000000003',
   'Les mercredis où elle garde ses petits-enfants',
   'false', '4'),

  -- Q04 — projet d''Olena (bonne réponse : position 4)
  ('11111111-b00d-2100-0000-000000000004', '11111111-b00d-1000-0000-000000000004',
   'Continuer à garder des enfants à son domicile',
   'false', '1'),
  ('11111111-b00d-2200-0000-000000000004', '11111111-b00d-1000-0000-000000000004',
   'Ouvrir sa propre crèche après la formation',
   'false', '2'),
  ('11111111-b00d-2300-0000-000000000004', '11111111-b00d-1000-0000-000000000004',
   'Enseigner la puériculture dans l''institut',
   'false', '3'),
  ('11111111-b00d-2400-0000-000000000004', '11111111-b00d-1000-0000-000000000004',
   'Obtenir un diplôme pour travailler en crèche',
   'true', '4'),

  -- Q05 — stage de Wei (bonne réponse : position 1)
  ('11111111-b00d-2100-0000-000000000005', '11111111-b00d-1000-0000-000000000005',
   'La cuisine de légumes locaux correspond à ce qu''il veut apprendre',
   'true', '1'),
  ('11111111-b00d-2200-0000-000000000005', '11111111-b00d-1000-0000-000000000005',
   'Le restaurant appartient à ses parents',
   'false', '2'),
  ('11111111-b00d-2300-0000-000000000005', '11111111-b00d-1000-0000-000000000005',
   'Le chef lui a proposé un poste pour les soirs de week-end',
   'false', '3'),
  ('11111111-b00d-2400-0000-000000000005', '11111111-b00d-1000-0000-000000000005',
   'C''est le seul restaurant qui accepte les élèves de son lycée',
   'false', '4'),

  -- Q06 — lettre de Rachid (bonne réponse : position 2)
  ('11111111-b00d-2100-0000-000000000006', '11111111-b00d-1000-0000-000000000006',
   'S''inscrire comme lecteur à la médiathèque',
   'false', '1'),
  ('11111111-b00d-2200-0000-000000000006', '11111111-b00d-1000-0000-000000000006',
   'Poser sa candidature au poste d''agent d''accueil',
   'true', '2'),
  ('11111111-b00d-2300-0000-000000000006', '11111111-b00d-1000-0000-000000000006',
   'Retrouver un emploi de réceptionniste d''hôtel',
   'false', '3'),
  ('11111111-b00d-2400-0000-000000000006', '11111111-b00d-1000-0000-000000000006',
   'Demander des renseignements sur des cours de comptabilité',
   'false', '4'),

  -- Q07 — matinées d''Amadou (bonne réponse : position 2)
  ('11111111-b00d-2100-0000-000000000007', '11111111-b00d-1000-0000-000000000007',
   'Il a cours à l''université tôt le matin',
   'false', '1'),
  ('11111111-b00d-2200-0000-000000000007', '11111111-b00d-1000-0000-000000000007',
   'Il est libre le matin, avant ses cours de français',
   'true', '2'),
  ('11111111-b00d-2300-0000-000000000007', '11111111-b00d-1000-0000-000000000007',
   'Il peut livrer à n''importe quelle heure de la journée',
   'false', '3'),
  ('11111111-b00d-2400-0000-000000000007', '11111111-b00d-1000-0000-000000000007',
   'Il ne sera disponible qu''à partir du mois prochain',
   'false', '4'),

  -- Q08 — apprentissage de Lucia (bonne réponse : position 3)
  ('11111111-b00d-2100-0000-000000000008', '11111111-b00d-1000-0000-000000000008',
   'Un stage de découverte dans un salon de coiffure',
   'false', '1'),
  ('11111111-b00d-2200-0000-000000000008', '11111111-b00d-1000-0000-000000000008',
   'Un emploi de coiffeuse diplômée',
   'false', '2'),
  ('11111111-b00d-2300-0000-000000000008', '11111111-b00d-1000-0000-000000000008',
   'Un salon pour préparer son CAP coiffure en apprentissage',
   'true', '3'),
  ('11111111-b00d-2400-0000-000000000008', '11111111-b00d-1000-0000-000000000008',
   'Un rendez-vous chez le coiffeur pour sa tante',
   'false', '4'),

  -- Q09 — alternative de Marek (bonne réponse : position 4)
  ('11111111-b00d-2100-0000-000000000009', '11111111-b00d-1000-0000-000000000009',
   'Renoncer à son stage pour rester tout le mois de juillet',
   'false', '1'),
  ('11111111-b00d-2200-0000-000000000009', '11111111-b00d-1000-0000-000000000009',
   'Faire venir un remplaçant du 25 au 31 juillet',
   'false', '2'),
  ('11111111-b00d-2300-0000-000000000009', '11111111-b00d-1000-0000-000000000009',
   'Ne travailler que la dernière semaine de juillet',
   'false', '3'),
  ('11111111-b00d-2400-0000-000000000009', '11111111-b00d-1000-0000-000000000009',
   'Travailler pendant le mois d''août',
   'true', '4'),

  -- Q10 — référence d''Aïcha (bonne réponse : position 1)
  ('11111111-b00d-2100-0000-00000000000a', '11111111-b00d-1000-0000-00000000000a',
   'C''est une ancienne responsable qui peut confirmer son sérieux',
   'true', '1'),
  ('11111111-b00d-2200-0000-00000000000a', '11111111-b00d-1000-0000-00000000000a',
   'C''est la directrice de l''hôtel où elle postule',
   'false', '2'),
  ('11111111-b00d-2300-0000-00000000000a', '11111111-b00d-1000-0000-00000000000a',
   'C''est la personne qui la loge à La Rochelle',
   'false', '3'),
  ('11111111-b00d-2400-0000-00000000000a', '11111111-b00d-1000-0000-00000000000a',
   'C''est elle qui a publié l''annonce à l''agence pour l''emploi',
   'false', '4');

-- ============================================================================
-- CHECKLIST — contrôles passés
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes (11111111-b00d-1000/4000/2100..2400-…-NN,
--     NN=01..0a).
-- [x] Support unique : lettre de motivation courte (10 expéditeurs et
--     situations toutes différentes : vente en boulangerie le week-end,
--     serveur saisonnier, bénévolat aide aux devoirs, formation auxiliaire
--     de puériculture, stage CAP cuisine, agent d''accueil de médiathèque,
--     livreur à vélo, apprentissage coiffure, animateur BAFA, femme de
--     chambre saisonnière).
-- [x] Passages TEXTE ~60-120 mots, mise en forme lettre (formule d''appel,
--     corps, formule de politesse, signature), media_id NULL.
-- [x] 4 propositions / 1 correcte par item. Distribution des bonnes réponses :
--     pos1:3 (Q3,Q5,Q10), pos2:3 (Q1,Q6,Q7), pos3:2 (Q2,Q8), pos4:2 (Q4,Q9)
--     — max 3 par position, 4 positions utilisées.
-- [x] competence_code : ce_reperage_explicite x4 (Q1,Q2,Q3,Q10),
--     ce_inference_intention x3 (Q5,Q7,Q9), ce_reformulation x3 (Q4,Q6,Q8).
-- [x] explanation ≥ 80 caractères : bonne réponse justifiée + les 3
--     distracteurs expliqués, point clé en **gras**, mécanisme linguistique
--     nommé (restriction « ne… que », passé composé d''action accomplie,
--     connecteur d''opposition « en revanche », confusion d''informations
--     proches, sur-généralisation…).
-- [x] Pas de SVG ni SSML dans ce lot (supports textuels uniquement) — rien à
--     équilibrer.
-- [x] Apostrophes SQL doublées partout, contenu 100% original, items autonomes.
-- ============================================================================
