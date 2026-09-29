-- ============================================================================
-- V446 — TCF CE B1 — lot 16 (support : brochure)
-- ----------------------------------------------------------------------------
-- 10 items de compréhension écrite B1. Support unique : brochure
-- (ateliers numériques en médiathèque, stage de natation adultes, visite
-- guidée d''office de tourisme, jardin partagé, ateliers nutrition, cours
-- d''essai en école de musique, vélos en libre-service, ateliers de
-- conversation, sorties nature, distribution de composteurs). Passages TEXTE
-- (~60-120 mots), questions + choices (4 rows/question). theme_id =
-- 22222222-0000-0000-0000-000000000002, difficulty='B1', question_type='CE'.
-- Données déterministes, rejouables dev+recette.
-- ============================================================================


-- passages — supports de lecture référencés par les questions ci-dessous
INSERT INTO passages
  (id, type, content, media_id, theme_id)
VALUES
  ('11111111-b010-4000-0000-000000000001', 'TEXTE',
   'MÉDIATHÈQUE JEAN-MOULIN — ATELIERS NUMÉRIQUES

Vous débutez avec l''ordinateur ou le smartphone ? Nos bénévoles vous accompagnent pas à pas.

Au programme : créer une adresse e-mail, faire ses démarches en ligne, protéger ses données personnelles.

Quand ? Tous les mardis, de 10 h à 12 h, hors vacances scolaires.
Pour qui ? Adultes débutants, aucun niveau requis.
Tarif : gratuit, sur inscription, dans la limite de 8 places par séance.
Matériel : des tablettes sont prêtées sur place ; vous pouvez aussi apporter votre propre appareil.

Inscription à l''accueil ou au 04 72 18 30 25.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b010-4000-0000-000000000002', 'TEXTE',
   'PISCINE DES TROIS-RIVIÈRES — APPRENDRE À NAGER À TOUT ÂGE

Il n''est jamais trop tard ! Notre stage « Adultes grands débutants » s''adresse aux personnes qui n''ont jamais appris à nager.

Groupes de 6 personnes maximum, encadrés par Amadou, maître-nageur diplômé.
Sessions : 10 séances de 45 minutes, le jeudi à 19 h 30 ou le samedi à 9 h.
Tarif : 95 € la session complète, bonnet de bain fourni.

Un test de positionnement gratuit est proposé avant l''inscription, afin d''orienter chacun vers le groupe le mieux adapté.

Renseignements à l''accueil de la piscine.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b010-4000-0000-000000000003', 'TEXTE',
   'OFFICE DE TOURISME DE SAINT-AUBRAC — DÉCOUVREZ LA VIEILLE VILLE

Suivez Diego, notre guide conférencier, dans les ruelles médiévales : remparts, maisons à colombages, lavoir du XVIIIᵉ siècle.

Départ : tous les samedis à 15 h, devant la fontaine de la place du Marché.
Durée : 1 h 30 de marche tranquille, accessible aux familles.
Tarif : 7 € par adulte, gratuit pour les moins de 12 ans.

Attention : la visite est annulée en cas de forte pluie ; un report ou un remboursement vous est alors proposé.

Billets en vente uniquement à l''office de tourisme, la veille au plus tard.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b010-4000-0000-000000000004', 'TEXTE',
   'LES JARDINS DE LA ROSELIÈRE — CULTIVEZ VOTRE PARCELLE

Notre jardin partagé propose 40 parcelles de 20 m² pour faire pousser légumes et fleurs en pleine ville.

L''association met à disposition l''eau, les outils communs et un composteur.
Cotisation : 35 € par an.
Condition : habiter la commune et participer aux deux matinées d''entretien collectif, au printemps et à l''automne.

Liste d''attente : les demandes sont traitées dans l''ordre d''arrivée ; comptez actuellement six mois environ avant d''obtenir une parcelle.

Dossier à retirer à la mairie ou sur place le mercredi, auprès de Fatou, la coordinatrice.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b010-4000-0000-000000000005', 'TEXTE',
   'MAISON DE SANTÉ DES TILLEULS — BIEN MANGER SANS SE RUINER

Un cycle de quatre ateliers animés par Priya, diététicienne.

Au menu : composer des repas équilibrés à petit budget, lire les étiquettes, cuisiner les restes. Chaque atelier se termine par une dégustation préparée ensemble.

Dates : les lundis 6, 13, 20 et 27 octobre, de 18 h à 20 h.
Participation : 5 € pour le cycle complet, ingrédients compris.

Les ateliers forment un ensemble : il est demandé de s''engager sur les quatre dates.

Inscription au secrétariat avant le 30 septembre.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b010-4000-0000-000000000006', 'TEXTE',
   'ÉCOLE DE MUSIQUE DU VAL-FLEURI — SEMAINE D''ESSAI

Envie d''apprendre un instrument ? Avant de vous engager pour l''année, testez !

Du 2 au 6 septembre, chaque professeur propose un cours d''essai gratuit de 30 minutes : guitare, piano, violon, batterie ou chant. Les instruments sont prêtés pendant l''essai.

Sur rendez-vous uniquement : réservez votre créneau au 03 88 41 27 90.

À noter : le cours d''essai n''engage à rien. L''inscription annuelle (290 €, instrument non compris) reste possible jusqu''au 20 septembre.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b010-4000-0000-000000000007', 'TEXTE',
   'RÉSEAU CYCLO''VILLE — LE VÉLO EN LIBRE-SERVICE

150 vélos répartis dans 20 stations, disponibles 24 h/24.

Nos formules :
— Ticket 24 h : 2 €, les 30 premières minutes gratuites à chaque trajet.
— Abonnement annuel : 28 €, les 45 premières minutes gratuites à chaque trajet.
Au-delà du temps gratuit, chaque demi-heure coûte 1 €.

Bon à savoir : rapportez le vélo dans n''importe quelle station, pas forcément celle du départ.

Abonnement en ligne ou à l''agence mobilité, près de la gare routière. Casque recommandé, non fourni.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b010-4000-0000-000000000008', 'TEXTE',
   'CENTRE SOCIAL DE LA FONTAINE — ATELIERS DE CONVERSATION FRANÇAISE

Vous apprenez le français et souhaitez pratiquer à l''oral ? Rejoignez les ateliers animés par Olena et son équipe de bénévoles.

Fonctionnement : petits groupes, discussions sur la vie quotidienne, jeux de rôle (chez le médecin, à la mairie, au travail).
Quand ? Mercredi de 14 h à 15 h 30 ou vendredi de 10 h à 11 h 30.
Gratuit, sans inscription : venez quand vous voulez, même en cours d''année.

Ces ateliers ne remplacent pas un cours de langue : aucune leçon de grammaire n''y est donnée.

Une garde d''enfants est assurée pendant la séance du vendredi.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b010-4000-0000-000000000009', 'TEXTE',
   'PARC NATUREL DU HAUT-VERDON — SORTIES « OISEAUX DES MARAIS »

Accompagné de Wei, animateur nature, observez hérons, martins-pêcheurs et canards sauvages au cœur des roselières.

Rendez-vous : un dimanche par mois, d''avril à septembre, à 7 h du matin — c''est tôt, mais c''est l''heure où les oiseaux sont les plus actifs !
Prévoir : des chaussures imperméables et des vêtements discrets ; les jumelles sont prêtées.
Tarif : 4 €. Enfants bienvenus à partir de 8 ans.

Groupes limités à 12 personnes : réservation indispensable sur notre site.

En cas de vent fort, la sortie est remplacée par une projection en salle.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b010-4000-0000-00000000000a', 'TEXTE',
   'COMMUNAUTÉ DE COMMUNES DU VAL D''ORGE — ADOPTEZ UN COMPOSTEUR

Réduisez vos déchets de 30 % ! La communauté de communes distribue des composteurs individuels aux habitants.

Comment ça marche ?
1. Réservez votre composteur sur valdorge-dechets.fr.
2. Assistez à la réunion de remise (45 minutes) : conseils d''utilisation et réponses à vos questions.
3. Repartez avec votre composteur et un guide pratique.

Participation : 15 € (au lieu de 60 €, le reste est pris en charge par la collectivité).
Prochaines remises : samedi 18 octobre et mercredi 5 novembre, salle des fêtes de Lormaye.

Un composteur par foyer. Justificatif de domicile demandé.',
   NULL, '22222222-0000-0000-0000-000000000002');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-b010-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b010-4000-0000-000000000001',
   NULL, 'B1', 'CE',
   'Que faut-il faire pour participer aux ateliers numériques ?',
   'La brochure indique « gratuit, **sur inscription** » puis « Inscription à l''accueil ou au 04 72 18 30 25 ». C''est un **repérage explicite de la condition de participation** : il suffit de s''inscrire. La réponse A invente un tarif : l''atelier est gratuit, et le chiffre 8 correspond au nombre de **places** par séance, pas à un prix — piège de confusion entre deux nombres proches. La réponse C contredit le texte : « des tablettes sont prêtées sur place », apporter son appareil n''est qu''une possibilité, pas une obligation. La réponse D contredit la mention « Adultes débutants, aucun niveau requis ».',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b010-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b010-4000-0000-000000000002',
   NULL, 'B1', 'CE',
   'À qui s''adresse le stage présenté dans cette brochure ?',
   'La brochure précise : le stage « Adultes grands débutants » « s''adresse aux personnes qui n''ont **jamais appris à nager** ». C''est un **repérage explicite du public visé**. La réponse A se trompe de public : le titre annonce « à tout âge » mais le stage est réservé aux **adultes**, aucun cours enfant n''est mentionné. La réponse B inverse le niveau : « grands débutants » exclut le perfectionnement des nageurs confirmés. La réponse C confond les rôles : Amadou, le maître-nageur diplômé, **encadre** les groupes — la brochure ne propose aucune formation au diplôme.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b010-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b010-4000-0000-000000000003',
   NULL, 'B1', 'CE',
   'Comment peut-on obtenir un billet pour la visite guidée ?',
   'La brochure indique : « Billets en vente **uniquement à l''office de tourisme**, la veille au plus tard ». L''adverbe restrictif « uniquement » exclut tout autre point de vente : c''est un **repérage explicite** du mode d''achat. La réponse B invente une vente en ligne dont le texte ne parle jamais. La réponse C confond le **lieu de départ** (la fontaine de la place du Marché) avec un point de vente : le guide ne vend pas de billets. La réponse D mélange deux informations : la gratuité ne concerne que les moins de 12 ans, et la place du Marché est le point de rendez-vous, pas un guichet.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b010-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b010-4000-0000-000000000004',
   NULL, 'B1', 'CE',
   'Que doit comprendre une personne qui demande une parcelle ?',
   'La brochure annonce une liste d''attente : « les demandes sont traitées dans l''ordre d''arrivée ; comptez actuellement **six mois environ** ». Par **inférence simple**, déposer un dossier ne donne pas une parcelle tout de suite : il faut patienter. La réponse A contredit directement cette liste d''attente. La réponse B contredit la phrase « L''association met à disposition l''eau, **les outils communs** et un composteur » : rien n''est à acheter. La réponse D invente une condition : les seules exigences sont d''habiter la commune et de participer aux deux matinées d''entretien, aucune expérience n''est demandée.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-b010-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b010-4000-0000-000000000005',
   NULL, 'B1', 'CE',
   'Que doit accepter un participant au moment de l''inscription ?',
   'La brochure précise : « Les ateliers forment un ensemble : il est demandé de **s''engager sur les quatre dates** ». Par **inférence d''engagement**, s''inscrire implique d''être présent aux quatre séances du cycle. La réponse A contredit la mention « ingrédients **compris** » : rien n''est à apporter. La réponse C déforme le tarif : 5 € couvrent « le cycle complet », pas chaque séance — piège classique entre **prix global et prix unitaire**. La réponse D confond les rôles : c''est Priya, la diététicienne, qui anime les ateliers ; les participants préparent seulement la dégustation ensemble, pendant la séance.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-b010-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b010-4000-0000-000000000006',
   NULL, 'B1', 'CE',
   'Que propose l''école de musique du 2 au 6 septembre ?',
   'La bonne réponse **reformule** l''offre centrale : « chaque professeur propose un **cours d''essai gratuit** de 30 minutes » et « Sur rendez-vous uniquement ». La réponse B mélange deux informations distinctes : l''inscription annuelle existe (290 €, jusqu''au 20 septembre) mais sans aucun tarif réduit — piège de **confusion entre deux infos proches** du texte. La réponse C sur-étend le prêt : les instruments ne sont prêtés que « pendant l''essai », et l''inscription annuelle est « instrument non compris ». La réponse D invente un événement : aucune représentation des professeurs n''est annoncée, on vient essayer, pas écouter.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reformulation'),

  ('11111111-b010-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b010-4000-0000-000000000007',
   NULL, 'B1', 'CE',
   'Qu''offre l''abonnement annuel au réseau Cyclo''Ville ?',
   'La brochure indique : « Abonnement annuel : 28 €, les **45 premières minutes** gratuites à chaque trajet ». C''est un **repérage explicite** d''une donnée chiffrée. La réponse A exagère l''avantage : « Au-delà du temps gratuit, chaque demi-heure coûte 1 € », la gratuité est donc limitée dans le temps. La réponse B confond les deux formules : les 30 minutes gratuites correspondent au **ticket 24 h**, pas à l''abonnement — piège typique entre deux valeurs proches du texte. La réponse D contredit la dernière ligne : « Casque recommandé, **non fourni** », rien n''est offert à la souscription.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b010-1000-0000-000000000008', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b010-4000-0000-000000000008',
   NULL, 'B1', 'CE',
   'Que précise la brochure au sujet des ateliers de conversation ?',
   'La bonne réponse **reformule** deux phrases clés : on vient « pratiquer à l''oral » et « **aucune leçon de grammaire** n''y est donnée » (« Ces ateliers ne remplacent pas un cours de langue »). La réponse A contredit le fonctionnement : « Gratuit, **sans inscription** : venez quand vous voulez, même en cours d''année ». La réponse B invente une restriction de niveau : les ateliers s''adressent à toute personne qui apprend le français, sans condition. La réponse D **généralise un détail** : la garde d''enfants n''est assurée que pendant la séance du vendredi, pas à chaque séance — piège d''extension abusive d''une information ponctuelle.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reformulation'),

  ('11111111-b010-1000-0000-000000000009', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b010-4000-0000-000000000009',
   NULL, 'B1', 'CE',
   'Que comprend-on au sujet du matériel pour la sortie ?',
   'Il faut relier deux informations de la rubrique « Prévoir » : apporter « des chaussures imperméables et des vêtements discrets », tandis que « les jumelles sont **prêtées** ». Cette **inférence simple** (combiner ce qu''on apporte et ce qui est fourni) donne la bonne réponse. La réponse A **sur-généralise** : seul le prêt des jumelles est prévu, pas celui des chaussures ni des vêtements. La réponse C inverse les deux éléments : ce sont les jumelles qui sont prêtées, aucune botte n''est proposée à l''accueil. La réponse D contredit le texte : inutile d''acheter des jumelles puisqu''elles sont fournies gratuitement.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-b010-1000-0000-00000000000a', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b010-4000-0000-00000000000a',
   NULL, 'B1', 'CE',
   'Comment les habitants peuvent-ils obtenir un composteur ?',
   'La bonne réponse **reformule la procédure en trois étapes** : « Réservez votre composteur sur valdorge-dechets.fr », « Assistez à la réunion de remise », « Repartez avec votre composteur ». La réponse A invente un lieu : aucun retrait en déchetterie n''est prévu, la remise a lieu à la salle des fêtes de Lormaye. La réponse B confond deux montants proches du texte : 60 € est le **coût réel** pris en charge en partie par la collectivité, la participation demandée est de 15 € — piège prix affiché vs prix payé. La réponse D déforme une condition : le justificatif de domicile est demandé lors de la remise, il ne se dépose pas à la mairie.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reformulation');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  -- Q01 — ateliers numériques médiathèque (bonne réponse : position 2)
  ('11111111-b010-2100-0000-000000000001', '11111111-b010-1000-0000-000000000001',
   'Payer 8 € par séance à l''accueil',
   'false', '1'),
  ('11111111-b010-2200-0000-000000000001', '11111111-b010-1000-0000-000000000001',
   'S''inscrire à l''accueil ou par téléphone',
   'true', '2'),
  ('11111111-b010-2300-0000-000000000001', '11111111-b010-1000-0000-000000000001',
   'Apporter obligatoirement sa propre tablette',
   'false', '3'),
  ('11111111-b010-2400-0000-000000000001', '11111111-b010-1000-0000-000000000001',
   'Avoir déjà des bases en informatique',
   'false', '4'),

  -- Q02 — stage natation adultes (bonne réponse : position 4)
  ('11111111-b010-2100-0000-000000000002', '11111111-b010-1000-0000-000000000002',
   'Aux enfants qui apprennent à nager',
   'false', '1'),
  ('11111111-b010-2200-0000-000000000002', '11111111-b010-1000-0000-000000000002',
   'Aux nageurs qui souhaitent se perfectionner',
   'false', '2'),
  ('11111111-b010-2300-0000-000000000002', '11111111-b010-1000-0000-000000000002',
   'Aux personnes qui préparent le diplôme de maître-nageur',
   'false', '3'),
  ('11111111-b010-2400-0000-000000000002', '11111111-b010-1000-0000-000000000002',
   'Aux adultes qui n''ont jamais appris à nager',
   'true', '4'),

  -- Q03 — visite guidée Saint-Aubrac (bonne réponse : position 1)
  ('11111111-b010-2100-0000-000000000003', '11111111-b010-1000-0000-000000000003',
   'En l''achetant à l''office de tourisme, au plus tard la veille',
   'true', '1'),
  ('11111111-b010-2200-0000-000000000003', '11111111-b010-1000-0000-000000000003',
   'En le réservant en ligne sur le site de la ville',
   'false', '2'),
  ('11111111-b010-2300-0000-000000000003', '11111111-b010-1000-0000-000000000003',
   'En payant le guide au départ de la visite',
   'false', '3'),
  ('11111111-b010-2400-0000-000000000003', '11111111-b010-1000-0000-000000000003',
   'En le retirant gratuitement place du Marché',
   'false', '4'),

  -- Q04 — jardin partagé (bonne réponse : position 3)
  ('11111111-b010-2100-0000-000000000004', '11111111-b010-1000-0000-000000000004',
   'Elle obtiendra une parcelle dès le dépôt du dossier',
   'false', '1'),
  ('11111111-b010-2200-0000-000000000004', '11111111-b010-1000-0000-000000000004',
   'Elle devra acheter ses propres outils de jardinage',
   'false', '2'),
  ('11111111-b010-2300-0000-000000000004', '11111111-b010-1000-0000-000000000004',
   'Elle devra patienter environ six mois avant d''avoir une parcelle',
   'true', '3'),
  ('11111111-b010-2400-0000-000000000004', '11111111-b010-1000-0000-000000000004',
   'Elle devra prouver son expérience du jardinage',
   'false', '4'),

  -- Q05 — ateliers nutrition (bonne réponse : position 2)
  ('11111111-b010-2100-0000-000000000005', '11111111-b010-1000-0000-000000000005',
   'Apporter les ingrédients de chaque dégustation',
   'false', '1'),
  ('11111111-b010-2200-0000-000000000005', '11111111-b010-1000-0000-000000000005',
   'Être présent aux quatre ateliers du cycle',
   'true', '2'),
  ('11111111-b010-2300-0000-000000000005', '11111111-b010-1000-0000-000000000005',
   'Payer 5 € à chacune des quatre séances',
   'false', '3'),
  ('11111111-b010-2400-0000-000000000005', '11111111-b010-1000-0000-000000000005',
   'Animer lui-même l''un des ateliers du cycle',
   'false', '4'),

  -- Q06 — école de musique (bonne réponse : position 1)
  ('11111111-b010-2100-0000-000000000006', '11111111-b010-1000-0000-000000000006',
   'Des cours d''essai gratuits, sur rendez-vous',
   'true', '1'),
  ('11111111-b010-2200-0000-000000000006', '11111111-b010-1000-0000-000000000006',
   'Des inscriptions annuelles à tarif réduit',
   'false', '2'),
  ('11111111-b010-2300-0000-000000000006', '11111111-b010-1000-0000-000000000006',
   'La location d''instruments pour toute l''année',
   'false', '3'),
  ('11111111-b010-2400-0000-000000000006', '11111111-b010-1000-0000-000000000006',
   'Un concert gratuit donné par les professeurs',
   'false', '4'),

  -- Q07 — vélos en libre-service (bonne réponse : position 4)
  ('11111111-b010-2100-0000-000000000007', '11111111-b010-1000-0000-000000000007',
   'Des trajets gratuits sans limite de durée',
   'false', '1'),
  ('11111111-b010-2200-0000-000000000007', '11111111-b010-1000-0000-000000000007',
   'Les 30 premières minutes gratuites à chaque trajet',
   'false', '2'),
  ('11111111-b010-2300-0000-000000000007', '11111111-b010-1000-0000-000000000007',
   'Un casque offert à la souscription',
   'false', '3'),
  ('11111111-b010-2400-0000-000000000007', '11111111-b010-1000-0000-000000000007',
   'Les 45 premières minutes gratuites à chaque trajet',
   'true', '4'),

  -- Q08 — ateliers de conversation (bonne réponse : position 3)
  ('11111111-b010-2100-0000-000000000008', '11111111-b010-1000-0000-000000000008',
   'Il faut s''y inscrire en début d''année',
   'false', '1'),
  ('11111111-b010-2200-0000-000000000008', '11111111-b010-1000-0000-000000000008',
   'Ils sont réservés aux débutants complets',
   'false', '2'),
  ('11111111-b010-2300-0000-000000000008', '11111111-b010-1000-0000-000000000008',
   'On y pratique l''oral, sans leçons de grammaire',
   'true', '3'),
  ('11111111-b010-2400-0000-000000000008', '11111111-b010-1000-0000-000000000008',
   'Une garde d''enfants est proposée à chaque séance',
   'false', '4'),

  -- Q09 — sorties nature (bonne réponse : position 2)
  ('11111111-b010-2100-0000-000000000009', '11111111-b010-1000-0000-000000000009',
   'Le parc fournit l''ensemble de l''équipement',
   'false', '1'),
  ('11111111-b010-2200-0000-000000000009', '11111111-b010-1000-0000-000000000009',
   'Il faut des chaussures adaptées, mais pas ses propres jumelles',
   'true', '2'),
  ('11111111-b010-2300-0000-000000000009', '11111111-b010-1000-0000-000000000009',
   'Des bottes sont prêtées à l''accueil du parc',
   'false', '3'),
  ('11111111-b010-2400-0000-000000000009', '11111111-b010-1000-0000-000000000009',
   'Il faut acheter des jumelles avant la sortie',
   'false', '4'),

  -- Q10 — distribution de composteurs (bonne réponse : position 3)
  ('11111111-b010-2100-0000-00000000000a', '11111111-b010-1000-0000-00000000000a',
   'En le retirant directement à la déchetterie',
   'false', '1'),
  ('11111111-b010-2200-0000-00000000000a', '11111111-b010-1000-0000-00000000000a',
   'En payant 60 € le jour de la remise',
   'false', '2'),
  ('11111111-b010-2300-0000-00000000000a', '11111111-b010-1000-0000-00000000000a',
   'En réservant en ligne puis en assistant à une réunion de remise',
   'true', '3'),
  ('11111111-b010-2400-0000-00000000000a', '11111111-b010-1000-0000-00000000000a',
   'En déposant un justificatif de domicile à la mairie',
   'false', '4');

-- ============================================================================
-- CHECKLIST — contrôles passés
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes (11111111-b010-1000/4000/21..2400-…-NN, NN=01..0a).
-- [x] Support unique : brochure (10 émetteurs et situations toutes différentes :
--     médiathèque/ateliers numériques, piscine/stage natation adultes, office
--     de tourisme/visite guidée, jardin partagé, maison de santé/ateliers
--     nutrition, école de musique/cours d''essai, vélos en libre-service,
--     centre social/conversation, parc naturel/sorties oiseaux, communauté de
--     communes/composteurs). Aucun support interdit utilisé.
-- [x] Passages TEXTE ~60-120 mots, mise en forme brochure (titre en capitales,
--     rubriques, infos pratiques, contact), media_id NULL.
-- [x] 4 propositions / 1 correcte par item. Distribution des bonnes réponses :
--     pos1:2, pos2:3, pos3:3, pos4:2 (max 3 par position, 4 positions utilisées).
-- [x] competence_code : ce_reperage_explicite x4, ce_inference_intention x3,
--     ce_reformulation x3.
-- [x] explanation ≥ 80 caractères : bonne réponse justifiée + les 3 distracteurs
--     expliqués, point clé en **gras**, mécanisme linguistique nommé (adverbe
--     restrictif, prix global vs unitaire, généralisation abusive, confusion
--     entre deux infos proches, inférence simple…).
-- [x] Pas de SVG ni SSML dans ce lot (supports textuels uniquement) — rien à
--     équilibrer.
-- [x] Apostrophes SQL doublées partout, contenu 100% original, items autonomes.
-- ============================================================================
