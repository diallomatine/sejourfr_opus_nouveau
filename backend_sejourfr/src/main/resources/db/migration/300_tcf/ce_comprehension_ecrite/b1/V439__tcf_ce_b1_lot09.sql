-- ============================================================================
-- V439 — TCF CE B1 — lot 09 (support : note d''information)
-- ----------------------------------------------------------------------------
-- 10 items de compréhension écrite B1. Support unique : note d''information
-- affichée ou distribuée (coupure d''eau en résidence, nouveaux badges en
-- entreprise, horaires d''école modifiés, fermeture de médiathèque, travaux
-- dans un club de sport, laverie de résidence étudiante déplacée, prise de
-- rendez-vous en centre de santé, vidange de piscine municipale, ravalement
-- de copropriété, restaurant d''entreprise en offre froide). Passages TEXTE
-- (~60-120 mots), questions + choices (4 rows/question). theme_id =
-- 22222222-0000-0000-0000-000000000002, difficulty='B1', question_type='CE'.
-- Données déterministes, rejouables dev+recette.
-- ============================================================================


-- passages — supports de lecture référencés par les questions ci-dessous
INSERT INTO passages
  (id, type, content, media_id, theme_id)
VALUES
  ('11111111-b009-4000-0000-000000000001', 'TEXTE',
   'NOTE D''INFORMATION — Résidence Les Tilleuls
À l''attention de tous les résidents

En raison du remplacement des canalisations du bâtiment B, l''eau sera coupée le mardi 16 juin, de 8 h à 17 h, dans l''ensemble de la résidence. Nous vous conseillons de remplir quelques bouteilles et une bassine la veille au soir. Les travaux ne concernent ni l''électricité ni le chauffage. Si la coupure devait se prolonger après 17 h, un message serait affiché dans chaque hall. Pour toute question, le gardien, M. Amadou Sow, vous reçoit à la loge de 9 h à 12 h.

Le syndic — Cabinet Verdéa',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b009-4000-0000-000000000002', 'TEXTE',
   'NOTE D''INFORMATION — Société Klervia
À l''ensemble du personnel

À partir du lundi 22 juin, l''accès aux locaux se fera uniquement avec le nouveau badge bleu. Les anciens badges gris seront désactivés ce jour-là à 8 h. Si vous n''avez pas encore retiré votre badge bleu, présentez-vous à l''accueil avant vendredi, muni d''une pièce d''identité. Rappel : ce badge ouvre aussi la barrière du parking ; il n''est donc plus nécessaire de demander une télécommande. En cas de perte, prévenez immédiatement le service sécurité au poste 4512.

La direction — Lucia Ferreira',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b009-4000-0000-000000000003', 'TEXTE',
   'NOTE D''INFORMATION — École élémentaire Jean-Moulin
Aux parents d''élèves

En raison d''une formation des enseignants, les cours se termineront à 15 h au lieu de 16 h 30 tous les vendredis du mois de juin. Les enfants inscrits à l''étude resteront accueillis jusqu''à 18 h, comme d''habitude, sans démarche supplémentaire. Les autres élèves devront être récupérés à 15 h précises au portail. Si personne ne peut venir à cet horaire, vous pouvez inscrire votre enfant à l''étude pour ces quatre vendredis, auprès du secrétariat, avant le 5 juin. Les horaires de la cantine ne changent pas.

La directrice — Mme Olena Kovalenko',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b009-4000-0000-000000000004', 'TEXTE',
   'NOTE D''INFORMATION — Médiathèque Georges-Brassens
Chers usagers,

La médiathèque sera fermée du 8 au 13 juin inclus pour son inventaire annuel. Pendant cette période, les documents empruntés peuvent être déposés dans la boîte de retour située à gauche de l''entrée, accessible jour et nuit. Aucune pénalité ne sera appliquée pour les retours prévus pendant la fermeture. La réouverture aura lieu le dimanche 14 juin à 10 h, avec un café d''accueil offert. Les réservations en ligne restent possibles sur notre site, mais les retraits de documents ne reprendront qu''à la réouverture.

Le responsable — Rachid Benani',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b009-4000-0000-000000000005', 'TEXTE',
   'NOTE D''INFORMATION — Club Form''Cité
À tous les adhérents

Les vestiaires hommes seront en travaux du 15 au 30 juin. Les cours collectifs sont maintenus aux horaires habituels. Nous invitons les adhérents concernés à arriver déjà en tenue de sport ; des casiers provisoires sont installés près de l''accueil pour déposer les sacs. Les douches restent accessibles au sous-sol, à côté de la piscine. Pour compenser cette gêne, deux semaines seront ajoutées gratuitement à tous les abonnements en cours, sans aucune démarche de votre part.

La direction du club — Diego Morales',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b009-4000-0000-000000000006', 'TEXTE',
   'NOTE D''INFORMATION — Résidence étudiante Le Cèdre
À l''attention des résidents

À compter du 1er juillet, la laverie du rez-de-chaussée sera transformée en salle de travail. Les machines à laver seront déplacées au bâtiment C, local 12, accessible avec votre carte de résident. Les jetons déjà achetés restent valables. Attention : le nouveau local sera ouvert de 7 h à 22 h, et non plus en continu ; merci de ne pas lancer de machine après 21 h. Une permanence d''aide à l''installation de l''application de réservation se tiendra le 28 juin dans le hall.

La gestionnaire — Priya Sharma',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b009-4000-0000-000000000007', 'TEXTE',
   'NOTE D''INFORMATION — Centre de santé des Remparts
À l''attention des patients

À partir du 1er septembre, les rendez-vous ne seront plus pris à l''accueil, mais uniquement par téléphone au 04 78 52 31 90, du lundi au vendredi de 8 h 30 à 12 h 30, ou sur notre site internet à toute heure. Les consultations sans rendez-vous restent possibles le samedi matin, pour les urgences uniquement. Pensez à apporter votre carte Vitale à chaque visite. En cas d''empêchement, merci d''annuler au moins 24 heures à l''avance afin de libérer le créneau pour un autre patient.

Le secrétariat médical — Fatou Ndiaye',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b009-4000-0000-000000000008', 'TEXTE',
   'NOTE D''INFORMATION — Piscine municipale Aqualune
Aux abonnés et usagers

Comme chaque année, le grand bassin fermera pour vidange et nettoyage du 20 juin au 4 juillet. Le petit bassin et les séances de bébés nageurs sont maintenus aux horaires habituels. Sur présentation de leur carte, les abonnés peuvent accéder gratuitement à la piscine des Glycines, située à dix minutes en bus (ligne 7). Les leçons de natation pour adultes du mardi soir sont suspendues et reprendront le 7 juillet. Aucune démarche n''est nécessaire : les séances manquées seront automatiquement reportées.

Le service des sports — Wei Zhang',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b009-4000-0000-000000000009', 'TEXTE',
   'NOTE D''INFORMATION — Copropriété du 12, rue des Acacias
À l''attention des occupants

Le ravalement de la façade débutera le lundi 6 juillet et durera environ huit semaines. Un échafaudage sera monté côté rue à partir du 2 juillet. Nous vous demandons de retirer avant cette date tout objet présent sur les balcons : pots de fleurs, mobilier, étendoirs. Les objets restants seront descendus à la cave par l''entreprise, à vos frais. Les fenêtres pourront rester ouvertes, sauf les jours de peinture, qui seront annoncés 48 heures à l''avance par une affiche dans le hall.

Pour le conseil syndical — Karim Haddad',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b009-4000-0000-00000000000a', 'TEXTE',
   'NOTE D''INFORMATION — Restaurant d''entreprise, site de Beaulieu
À l''ensemble des salariés

En raison du remplacement des fours, le restaurant servira uniquement une offre froide (salades, sandwichs, desserts) du 9 au 20 juin, aux horaires habituels, de 11 h 45 à 14 h. Pour ceux qui souhaitent un plat chaud, des micro-ondes supplémentaires sont installés à la cafétéria du bâtiment A, et les repas apportés de la maison sont exceptionnellement autorisés dans la salle. Pendant toute la période, les tarifs de l''offre froide sont réduits de 20 %.

La responsable de la restauration — Sofia Almeida',
   NULL, '22222222-0000-0000-0000-000000000002');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-b009-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b009-4000-0000-000000000001',
   NULL, 'B1', 'CE',
   'Que conseille cette note aux résidents ?',
   'La note indique : « Nous vous conseillons de remplir quelques bouteilles et une bassine la veille au soir » — la veille du mardi 16 étant le lundi. C''est un **repérage explicite du conseil** donné aux résidents avant la coupure d''eau. La réponse A contredit le texte : « Les travaux ne concernent ni l''électricité ni le chauffage ». La réponse C transforme une simple possibilité (« Pour toute question ») en obligation — confusion entre **conseil et obligation**. La réponse D invente une évacuation : les canalisations remplacées sont celles du bâtiment B, mais personne ne doit quitter les lieux pendant la journée.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b009-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b009-4000-0000-000000000002',
   NULL, 'B1', 'CE',
   'Que doivent faire les salariés qui n''ont pas encore leur badge bleu ?',
   'La consigne est explicite : « présentez-vous à l''accueil avant vendredi, muni d''une pièce d''identité ». C''est un **repérage explicite de la consigne** adressée aux retardataires. La réponse A contredit le rappel : le badge bleu ouvre la barrière du parking, « il n''est donc plus nécessaire de demander une télécommande ». La réponse B confond deux situations : le poste 4512 ne sert qu''**en cas de perte** d''un badge, pas pour le retrait initial. La réponse C est impossible : les badges gris « seront désactivés » dès le lundi 22 juin à 8 h, pas à la fin du mois — piège de **confusion entre deux dates proches**.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b009-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b009-4000-0000-000000000003',
   NULL, 'B1', 'CE',
   'Que faut-il comprendre pour les enfants déjà inscrits à l''étude ?',
   'La note précise : « Les enfants inscrits à l''étude resteront accueillis jusqu''à 18 h, comme d''habitude, sans démarche supplémentaire ». Par **inférence d''opposition entre deux groupes** (inscrits / non inscrits), on comprend que rien ne change pour eux. La réponse B concerne « les autres élèves », ceux qui ne fréquentent pas l''étude. La réponse C déforme la phrase suivante : l''inscription avant le 5 juin vise les enfants **pas encore inscrits** dont les parents ne peuvent pas venir à 15 h. La réponse D contredit la dernière ligne : « Les horaires de la cantine ne changent pas », personne ne perd le déjeuner du vendredi.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-b009-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b009-4000-0000-000000000004',
   NULL, 'B1', 'CE',
   'Que peuvent faire les usagers pendant la fermeture de la médiathèque ?',
   'Le texte indique que « les documents empruntés peuvent être déposés dans la boîte de retour située à gauche de l''entrée, accessible jour et nuit ». La bonne réponse est une **reformulation** de cette possibilité (déposer = rendre). La réponse A confond réservation et retrait : on peut réserver en ligne, mais « les retraits de documents ne reprendront qu''à la réouverture ». La réponse B contredit le texte : « Aucune pénalité ne sera appliquée » pendant la fermeture. La réponse D déplace une information dans le temps : le café d''accueil est offert **uniquement le dimanche 14 juin**, jour de réouverture — piège de **confusion de dates**.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reformulation'),

  ('11111111-b009-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b009-4000-0000-000000000005',
   NULL, 'B1', 'CE',
   'Que propose le club pour compenser la gêne des travaux ?',
   'La note annonce : « Pour compenser cette gêne, deux semaines seront ajoutées gratuitement à tous les abonnements en cours ». La bonne réponse en est la **reformulation** : ajouter deux semaines = prolonger l''abonnement sans frais. La réponse A déforme le texte : les cours collectifs sont « maintenus », pas augmentés. La réponse C prend un repère de lieu pour un avantage : la piscine n''est citée que pour **situer les douches** au sous-sol, aucun accès gratuit n''est offert. La réponse D transforme les « casiers provisoires » installés pendant les travaux en location annuelle à prix réduit — piège de **confusion entre mesure temporaire et offre durable**.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reformulation'),

  ('11111111-b009-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b009-4000-0000-000000000006',
   NULL, 'B1', 'CE',
   'Qu''est-ce qui change pour les résidents qui utilisent la laverie ?',
   'En **recoupant deux informations** — « Les machines à laver seront déplacées au bâtiment C » et « ouvert de 7 h à 22 h, et non plus en continu » —, on déduit que la laverie change de bâtiment et n''est plus accessible la nuit. La réponse B contredit le texte : « Les jetons déjà achetés restent valables », aucun remboursement n''est prévu. La réponse C opère une **inversion** : c''est la laverie qui part au bâtiment C ; la salle de travail, elle, prend sa place au rez-de-chaussée. La réponse D détourne une date : le 28 juin est une simple permanence d''aide pour l''application, pas une date limite pour laver son linge.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-b009-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b009-4000-0000-000000000007',
   NULL, 'B1', 'CE',
   'Comment pourra-t-on prendre rendez-vous à partir du 1er septembre ?',
   'La note énonce les deux seuls canaux : « uniquement par téléphone […] du lundi au vendredi de 8 h 30 à 12 h 30, ou sur notre site internet à toute heure ». C''est un **repérage explicite des modalités**. La réponse A décrit justement ce qui disparaît : « les rendez-vous ne seront plus pris à l''accueil ». La réponse B confond **deux dispositifs proches** : le samedi matin correspond aux consultations sans rendez-vous, réservées aux urgences. La réponse C élargit abusivement les plages : le téléphone ne fonctionne que du lundi au vendredi, le matin uniquement — piège d''**extension d''horaires** par rapport au texte.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b009-1000-0000-000000000008', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b009-4000-0000-000000000008',
   NULL, 'B1', 'CE',
   'Que peut faire un abonné pendant la fermeture du grand bassin ?',
   'Par **inférence simple**, on relie « Sur présentation de leur carte » et « accéder gratuitement à la piscine des Glycines » : l''abonné peut aller nager ailleurs sans payer. La réponse A contredit le texte : les leçons du mardi soir « sont suspendues » jusqu''au 7 juillet. La réponse B inverse le fonctionnement annoncé : « Aucune démarche n''est nécessaire », le report des séances est **automatique**, il n''y a rien à demander au guichet — piège de **confusion entre démarche et automatisme**. La réponse D invente un remboursement : le texte ne parle que de séances « automatiquement reportées », jamais d''argent rendu.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-b009-1000-0000-000000000009', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b009-4000-0000-000000000009',
   NULL, 'B1', 'CE',
   'Que risquent les occupants qui laissent des objets sur leur balcon ?',
   'Le texte prévient : « Les objets restants seront descendus à la cave par l''entreprise, à vos frais ». Par **inférence sur la locution « à vos frais »**, on comprend que ce déplacement sera facturé aux occupants concernés. La réponse B exagère la sanction : les objets sont descendus à la cave, pas jetés — ils restent récupérables. La réponse C déforme une autre consigne : les fenêtres peuvent rester ouvertes, sauf « les jours de peinture », pas pendant les huit semaines. La réponse D confond deux informations proches : l''affiche posée 48 heures à l''avance annonce les jours de peinture à tout l''immeuble, ce n''est pas un avertissement personnel — piège de **confusion entre deux dispositifs du texte**.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-b009-1000-0000-00000000000a', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b009-4000-0000-00000000000a',
   NULL, 'B1', 'CE',
   'Que propose la note aux salariés qui veulent manger chaud ?',
   'La note prévoit deux solutions : « des micro-ondes supplémentaires sont installés à la cafétéria du bâtiment A » et « les repas apportés de la maison sont exceptionnellement autorisés ». La bonne réponse **reformule cette double possibilité** : réchauffer sur place ou apporter son repas. La réponse A déplace la remise : les 20 % de réduction concernent **l''offre froide**, pas des plats chauds (qui n''existent plus pendant les travaux). La réponse B est vraie dans le texte mais répond à une autre question : commander des salades, c''est manger froid. La réponse D invente un assouplissement : le service garde ses « horaires habituels, de 11 h 45 à 14 h ».',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reformulation');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  -- Q01 — coupure d''eau résidence Les Tilleuls (bonne réponse : position 2)
  ('11111111-b009-2100-0000-000000000001', '11111111-b009-1000-0000-000000000001',
   'De couper leur chauffage pendant la journée de mardi',
   'false', '1'),
  ('11111111-b009-2200-0000-000000000001', '11111111-b009-1000-0000-000000000001',
   'De faire une réserve d''eau lundi soir',
   'true', '2'),
  ('11111111-b009-2300-0000-000000000001', '11111111-b009-1000-0000-000000000001',
   'De passer obligatoirement à la loge avant les travaux',
   'false', '3'),
  ('11111111-b009-2400-0000-000000000001', '11111111-b009-1000-0000-000000000001',
   'De quitter le bâtiment B pendant toute la journée',
   'false', '4'),

  -- Q02 — badges société Klervia (bonne réponse : position 4)
  ('11111111-b009-2100-0000-000000000002', '11111111-b009-1000-0000-000000000002',
   'Demander une télécommande pour la barrière du parking',
   'false', '1'),
  ('11111111-b009-2200-0000-000000000002', '11111111-b009-1000-0000-000000000002',
   'Appeler le poste 4512 pour en commander un',
   'false', '2'),
  ('11111111-b009-2300-0000-000000000002', '11111111-b009-1000-0000-000000000002',
   'Utiliser leur badge gris jusqu''à la fin du mois',
   'false', '3'),
  ('11111111-b009-2400-0000-000000000002', '11111111-b009-1000-0000-000000000002',
   'Le retirer à l''accueil avant vendredi avec une pièce d''identité',
   'true', '4'),

  -- Q03 — horaires école Jean-Moulin (bonne réponse : position 1)
  ('11111111-b009-2100-0000-000000000003', '11111111-b009-1000-0000-000000000003',
   'Rien ne change : ils restent à l''école jusqu''à 18 h',
   'true', '1'),
  ('11111111-b009-2200-0000-000000000003', '11111111-b009-1000-0000-000000000003',
   'Ils devront être récupérés à 15 h précises au portail',
   'false', '2'),
  ('11111111-b009-2300-0000-000000000003', '11111111-b009-1000-0000-000000000003',
   'Leurs parents doivent les réinscrire avant le 5 juin',
   'false', '3'),
  ('11111111-b009-2400-0000-000000000003', '11111111-b009-1000-0000-000000000003',
   'Ils ne pourront plus déjeuner à la cantine le vendredi',
   'false', '4'),

  -- Q04 — fermeture médiathèque Georges-Brassens (bonne réponse : position 3)
  ('11111111-b009-2100-0000-000000000004', '11111111-b009-1000-0000-000000000004',
   'Retirer à l''accueil les documents réservés en ligne',
   'false', '1'),
  ('11111111-b009-2200-0000-000000000004', '11111111-b009-1000-0000-000000000004',
   'Payer leurs pénalités de retard au guichet',
   'false', '2'),
  ('11111111-b009-2300-0000-000000000004', '11111111-b009-1000-0000-000000000004',
   'Rendre leurs documents dans la boîte située à l''entrée',
   'true', '3'),
  ('11111111-b009-2400-0000-000000000004', '11111111-b009-1000-0000-000000000004',
   'Profiter d''un café offert tous les matins',
   'false', '4'),

  -- Q05 — travaux club Form''Cité (bonne réponse : position 2)
  ('11111111-b009-2100-0000-000000000005', '11111111-b009-1000-0000-000000000005',
   'Des cours collectifs supplémentaires pendant deux semaines',
   'false', '1'),
  ('11111111-b009-2200-0000-000000000005', '11111111-b009-1000-0000-000000000005',
   'Une prolongation gratuite des abonnements en cours',
   'true', '2'),
  ('11111111-b009-2300-0000-000000000005', '11111111-b009-1000-0000-000000000005',
   'L''accès gratuit à la piscine du sous-sol',
   'false', '3'),
  ('11111111-b009-2400-0000-000000000005', '11111111-b009-1000-0000-000000000005',
   'La location de casiers à prix réduit toute l''année',
   'false', '4'),

  -- Q06 — laverie résidence Le Cèdre (bonne réponse : position 1)
  ('11111111-b009-2100-0000-000000000006', '11111111-b009-1000-0000-000000000006',
   'Elle change de bâtiment et ferme désormais la nuit',
   'true', '1'),
  ('11111111-b009-2200-0000-000000000006', '11111111-b009-1000-0000-000000000006',
   'Les jetons achetés devront être remboursés',
   'false', '2'),
  ('11111111-b009-2300-0000-000000000006', '11111111-b009-1000-0000-000000000006',
   'La salle de travail est déplacée au bâtiment C',
   'false', '3'),
  ('11111111-b009-2400-0000-000000000006', '11111111-b009-1000-0000-000000000006',
   'Il sera interdit de laver son linge après le 28 juin',
   'false', '4'),

  -- Q07 — rendez-vous centre de santé des Remparts (bonne réponse : position 4)
  ('11111111-b009-2100-0000-000000000007', '11111111-b009-1000-0000-000000000007',
   'Directement à l''accueil du centre, comme avant',
   'false', '1'),
  ('11111111-b009-2200-0000-000000000007', '11111111-b009-1000-0000-000000000007',
   'Uniquement le samedi matin, sur place',
   'false', '2'),
  ('11111111-b009-2300-0000-000000000007', '11111111-b009-1000-0000-000000000007',
   'Par téléphone, du lundi au samedi, toute la journée',
   'false', '3'),
  ('11111111-b009-2400-0000-000000000007', '11111111-b009-1000-0000-000000000007',
   'Par téléphone en matinée ou sur internet à toute heure',
   'true', '4'),

  -- Q08 — vidange piscine Aqualune (bonne réponse : position 3)
  ('11111111-b009-2100-0000-000000000008', '11111111-b009-1000-0000-000000000008',
   'Continuer les leçons de natation du mardi soir',
   'false', '1'),
  ('11111111-b009-2200-0000-000000000008', '11111111-b009-1000-0000-000000000008',
   'Demander au guichet le report de ses séances',
   'false', '2'),
  ('11111111-b009-2300-0000-000000000008', '11111111-b009-1000-0000-000000000008',
   'Nager gratuitement à la piscine des Glycines avec sa carte',
   'true', '3'),
  ('11111111-b009-2400-0000-000000000008', '11111111-b009-1000-0000-000000000008',
   'Se faire rembourser son abonnement par le service des sports',
   'false', '4'),

  -- Q09 — ravalement rue des Acacias (bonne réponse : position 1)
  ('11111111-b009-2100-0000-000000000009', '11111111-b009-1000-0000-000000000009',
   'Devoir payer le transport de leurs objets à la cave',
   'true', '1'),
  ('11111111-b009-2200-0000-000000000009', '11111111-b009-1000-0000-000000000009',
   'Voir leurs objets jetés définitivement par l''entreprise',
   'false', '2'),
  ('11111111-b009-2300-0000-000000000009', '11111111-b009-1000-0000-000000000009',
   'Devoir garder leurs fenêtres fermées pendant huit semaines',
   'false', '3'),
  ('11111111-b009-2400-0000-000000000009', '11111111-b009-1000-0000-000000000009',
   'Recevoir une affiche d''avertissement 48 heures à l''avance',
   'false', '4'),

  -- Q10 — offre froide restaurant de Beaulieu (bonne réponse : position 3)
  ('11111111-b009-2100-0000-00000000000a', '11111111-b009-1000-0000-00000000000a',
   'Profiter d''une réduction de 20 % sur les plats chauds',
   'false', '1'),
  ('11111111-b009-2200-0000-00000000000a', '11111111-b009-1000-0000-00000000000a',
   'Commander des salades et des sandwichs au restaurant',
   'false', '2'),
  ('11111111-b009-2300-0000-00000000000a', '11111111-b009-1000-0000-00000000000a',
   'Réchauffer leur repas à la cafétéria ou l''apporter de chez eux',
   'true', '3'),
  ('11111111-b009-2400-0000-00000000000a', '11111111-b009-1000-0000-00000000000a',
   'Déjeuner en dehors des horaires habituels du service',
   'false', '4');

-- ============================================================================
-- CHECKLIST — contrôles passés
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes (11111111-b009-1000/4000/21..2400-…-NN, NN=01..0a).
-- [x] Support unique : note d''information (10 émetteurs et situations toutes
--     différentes : syndic/coupure d''eau, entreprise/badges, école/horaires,
--     médiathèque/inventaire, club de sport/vestiaires, résidence étudiante/
--     laverie, centre de santé/rendez-vous, piscine municipale/vidange,
--     copropriété/ravalement, restaurant d''entreprise/offre froide).
-- [x] Aucun support interdit utilisé (pas d''e-mail, pas de message
--     administratif, pas d''article, pas de forum, etc.).
-- [x] Passages TEXTE ~60-120 mots, mise en forme note (bandeau NOTE
--     D''INFORMATION, destinataires, corps, signature), media_id NULL.
-- [x] 4 propositions / 1 correcte par item. Distribution des bonnes réponses :
--     pos1:3, pos2:2, pos3:3, pos4:2 (max 3 par position, 4 positions utilisées).
-- [x] competence_code : ce_reperage_explicite x3 (Q1, Q2, Q7),
--     ce_inference_intention x4 (Q3, Q6, Q8, Q9), ce_reformulation x3 (Q4, Q5, Q10).
-- [x] explanation ≥ 80 caractères : bonne réponse justifiée + les 3 distracteurs
--     expliqués, point clé en **gras**, mécanisme linguistique nommé (conseil vs
--     obligation, confusion de dates, inversion, démarche vs automatisme,
--     inférence sur « à vos frais », reformulation…).
-- [x] Pas de SVG ni SSML dans ce lot (supports textuels uniquement) — rien à
--     équilibrer.
-- [x] Apostrophes SQL doublées partout, contenu 100% original, items autonomes,
--     prénoms variés (Amadou, Lucia, Olena, Rachid, Diego, Priya, Fatou, Wei,
--     Karim, Sofia).
-- ============================================================================
