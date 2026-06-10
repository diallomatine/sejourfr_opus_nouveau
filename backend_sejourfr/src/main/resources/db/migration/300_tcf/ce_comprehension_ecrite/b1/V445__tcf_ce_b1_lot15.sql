-- ============================================================================
-- V445 — TCF CE B1 — lot 15 (support : FAQ)
-- ----------------------------------------------------------------------------
-- 10 items de compréhension écrite B1. Support unique : FAQ (foire aux
-- questions) de services variés (piscine municipale, covoiturage, médiathèque
-- numérique, festival, paniers de légumes, code de la route en ligne, vélos en
-- libre-service, cours de cuisine, salle de sport, boutique en ligne).
-- Passages TEXTE (~60-120 mots), questions + choices (4 rows/question).
-- theme_id = 22222222-0000-0000-0000-000000000002, difficulty='B1',
-- question_type='CE'. Données déterministes, rejouables dev+recette.
-- ============================================================================


-- passages — supports de lecture référencés par les questions ci-dessous
INSERT INTO passages
  (id, type, content, media_id, theme_id)
VALUES
  ('11111111-b00f-4000-0000-000000000001', 'TEXTE',
   'FAQ — Piscine municipale de Roncey

Question de Wei : Faut-il s''inscrire pour les cours d''aquagym ?
Réponse : Oui. L''inscription se fait uniquement à l''accueil, sur présentation d''un certificat médical de moins de trois mois. Le paiement en ligne n''est pas encore possible.

Question d''Olena : Mon abonnement annuel reste-t-il valable pendant les travaux du grand bassin ?
Réponse : Oui, il est automatiquement prolongé de deux mois, sans aucune démarche de votre part. Le petit bassin reste ouvert aux horaires habituels.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00f-4000-0000-000000000002', 'TEXTE',
   'FAQ — RouleFacile, covoiturage entre particuliers

Question de Diego : Le conducteur a annulé mon trajet au dernier moment. Vais-je être remboursé ?
Réponse : Oui, intégralement et automatiquement, sous cinq jours ouvrés, sur le moyen de paiement utilisé lors de la réservation. Vous n''avez aucune démarche à effectuer.

Question de Fatou : Puis-je voyager avec une grande valise ?
Réponse : Chaque passager a droit à un bagage à main. Pour un bagage plus volumineux, contactez le conducteur par messagerie avant de réserver.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00f-4000-0000-000000000003', 'TEXTE',
   'FAQ — Médiathèque numérique de Trévoux

Question d''Amadou : Combien de livres numériques puis-je emprunter à la fois ?
Réponse : Quatre titres au maximum, pour une durée de trois semaines chacun. Le retour est automatique à la fin du prêt : aucune pénalité de retard n''est donc possible.

Question de Priya : Puis-je prolonger un prêt en cours ?
Réponse : Oui, une seule fois et depuis votre compte, à condition qu''aucun autre lecteur n''ait réservé le titre.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00f-4000-0000-000000000004', 'TEXTE',
   'FAQ — Festival Les Voix du Fleuve

Question de Rachid : Je ne peux plus venir le samedi. Puis-je donner mon billet à un ami ?
Réponse : Oui. Modifiez gratuitement le nom du détenteur depuis votre espace personnel, jusqu''à la veille du concert. En revanche, les billets ne sont ni repris ni remboursés.

Question de Lucia : Les enfants paient-ils leur place ?
Réponse : L''entrée est gratuite pour les moins de dix ans accompagnés d''un adulte, sans billet à présenter.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00f-4000-0000-000000000005', 'TEXTE',
   'FAQ — Les Paniers de la Sorgue, légumes de saison

Question d''Hanna : Je pars en vacances deux semaines. Vais-je perdre mes paniers ?
Réponse : Non. Suspendez la livraison depuis votre compte, au moins trois jours à l''avance : les paniers non livrés seront ajoutés à la fin de votre abonnement.

Question de Marek : Puis-je choisir le contenu de mon panier ?
Réponse : Le contenu dépend des récoltes de la semaine. Vous pouvez seulement exclure deux légumes que vous n''aimez pas.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00f-4000-0000-000000000006', 'TEXTE',
   'FAQ — PermisExpress, préparation au code de la route en ligne

Question de Karim : Mon accès de six mois se termine et je n''ai pas encore passé l''examen. Que se passe-t-il ?
Réponse : Vous pouvez réactiver votre compte pour trois mois à moitié prix. Votre progression est conservée : inutile de refaire les leçons déjà validées.

Question d''Inès : L''inscription à l''examen officiel est-elle comprise ?
Réponse : Non. Elle se fait séparément, sur le site de l''organisme d''examen, pour trente euros.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00f-4000-0000-000000000007', 'TEXTE',
   'FAQ — Vélidoo, vélos en libre-service de Quimperlé

Question de Sonia : Le vélo que j''ai loué est tombé en panne en cours de route. Que dois-je faire ?
Réponse : Verrouillez-le à la station la plus proche et signalez la panne depuis l''application. Le trajet en cours ne vous sera pas facturé.

Question de Mehdi : Puis-je garder un vélo toute la journée ?
Réponse : Oui, mais au-delà de deux heures d''affilée, chaque demi-heure supplémentaire coûte deux euros, même pour les abonnés.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00f-4000-0000-000000000008', 'TEXTE',
   'FAQ — L''Atelier des Saveurs, cours de cuisine à Roubaix

Question de Nadia : Faut-il apporter son propre matériel ?
Réponse : Non, tabliers et ustensiles sont fournis sur place. Prévoyez seulement une boîte pour remporter vos préparations chez vous.

Question de Bruno : Je suis allergique aux fruits à coque. Puis-je quand même participer ?
Réponse : Bien sûr. Signalez votre allergie au moment de la réservation : le chef adaptera la recette servie à l''ensemble du groupe ce soir-là.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00f-4000-0000-000000000009', 'TEXTE',
   'FAQ — Gymvert, salle de sport

Question de Samuel : Je suis blessé pour deux mois. Dois-je résilier mon abonnement ?
Réponse : Pas forcément. Sur présentation d''un certificat médical, l''abonnement peut être gelé jusqu''à trois mois : vous ne payez rien pendant cette période, et la durée gelée est ajoutée à la fin de votre contrat.

Question d''Estelle : Les cours collectifs sont-ils inclus dans la formule de base ?
Réponse : Deux cours par semaine le sont ; chaque cours supplémentaire coûte cinq euros.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00f-4000-0000-00000000000a', 'TEXTE',
   'FAQ — Filature & Co, boutique de vêtements en ligne

Question de Théo : Le pull commandé est trop petit. Comment l''échanger ?
Réponse : Demandez un bon de retour depuis votre commande, sous trente jours. Dès réception de votre colis, nous expédions la nouvelle taille. Le retour est gratuit pour un échange, mais reste à votre charge pour un remboursement.

Question d''Agnieszka : Les articles soldés peuvent-ils être rendus ?
Réponse : Oui, dans les mêmes conditions que les autres articles.',
   NULL, '22222222-0000-0000-0000-000000000002');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-b00f-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00f-4000-0000-000000000001',
   NULL, 'B1', 'CE',
   'D''après cette FAQ, que doit faire Wei pour suivre les cours d''aquagym ?',
   'La réponse faite à Wei indique : « L''inscription se fait uniquement à l''accueil, sur présentation d''un certificat médical de moins de trois mois ». C''est un **repérage explicite de la démarche demandée** : se rendre au guichet avec un certificat récent. La réponse A contredit le texte, qui précise que « le paiement en ligne n''est pas encore possible » — l''adverbe restrictif **« uniquement »** exclut toute autre voie. La réponse C mélange deux rubriques : les travaux concernent la question d''Olena, pas les cours d''aquagym. La réponse D détourne aussi la réponse faite à Olena : la prolongation de deux mois est automatique et n''a rien à voir avec l''inscription aux cours.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b00f-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00f-4000-0000-000000000002',
   NULL, 'B1', 'CE',
   'Que doit faire Diego pour récupérer son argent ?',
   'La réponse précise : « intégralement et automatiquement […] Vous n''avez aucune démarche à effectuer ». **Aucune action n''est attendue de Diego** : c''est un repérage explicite, l''adverbe « automatiquement » porte toute l''information. La réponse A transforme le **délai de traitement** (cinq jours ouvrés pour recevoir l''argent) en délai pour déposer une réclamation — confusion entre deux données proches du texte. La réponse B recycle la consigne donnée à Fatou pour les bagages volumineux, sans aucun rapport avec le remboursement. La réponse C invente une condition absente du texte : aucune nouvelle réservation n''est exigée pour être remboursé.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b00f-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00f-4000-0000-000000000003',
   NULL, 'B1', 'CE',
   'Qu''apprend-on sur la fin du prêt d''un livre numérique ?',
   'La réponse faite à Amadou indique : « Le retour est automatique à la fin du prêt : aucune pénalité de retard n''est donc possible ». La bonne réponse **reformule ce double constat** (retour automatique + absence d''amende), relié par le connecteur logique « donc ». La réponse B suppose un déplacement physique, absurde pour un **livre numérique** : rien n''est à rapporter sur place. La réponse C contredit frontalement la négation « aucune pénalité ». La réponse D déforme la réponse faite à Priya : la prolongation n''est jamais automatique, elle se demande « depuis votre compte », une seule fois et seulement si personne n''a réservé le titre.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reformulation'),

  ('11111111-b00f-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00f-4000-0000-000000000004',
   NULL, 'B1', 'CE',
   'Que peut faire Rachid avec son billet du samedi ?',
   'La réponse autorise Rachid à « modifier gratuitement le nom du détenteur depuis [son] espace personnel ». C''est un **repérage explicite de la seule option offerte** : céder le billet à quelqu''un d''autre. Les réponses A et B contredisent la restriction « les billets ne sont **ni repris ni remboursés** » — la double négation « ni… ni » ferme ces deux portes ; le piège consiste à rattacher « jusqu''à la veille » au remboursement alors que ce délai porte sur le changement de nom. La réponse D invente un report de date que la FAQ n''évoque jamais : seul le nom du détenteur peut changer, pas le jour du concert.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b00f-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00f-4000-0000-000000000005',
   NULL, 'B1', 'CE',
   'Que propose-t-on à Hanna pour ses vacances ?',
   'La réponse indique : « les paniers non livrés seront ajoutés à la fin de votre abonnement », après suspension depuis le compte. La bonne réponse **reformule ce mécanisme de report** : rien n''est perdu, tout est décalé. La réponse A confond report et remboursement : aucun argent n''est rendu, Hanna reçoit des **paniers supplémentaires** en fin de contrat. La réponse C détourne la réponse faite à Marek : le contenu dépend des récoltes de la semaine, on ne compose pas de panier à la carte. La réponse D prend le contre-pied du « Non » initial : l''abonnement continue, il n''est jamais question de le résilier.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reformulation'),

  ('11111111-b00f-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00f-4000-0000-000000000006',
   NULL, 'B1', 'CE',
   'Que propose la plateforme à Karim ?',
   'La réponse propose de « réactiver votre compte pour trois mois à moitié prix » en précisant que « votre progression est conservée ». La bonne réponse **reformule cette offre de prolongation à tarif réduit**. La réponse B inverse le sens de « inutile de refaire les leçons déjà validées » : on lui évite ce travail, on ne le lui offre pas. La réponse C confond les rubriques : l''inscription à trente euros répond à Inès et se fait « séparément », hors plateforme. La réponse D transforme « à **moitié prix** » (réduction sur le futur accès) en remboursement de l''accès passé — piège classique entre remise et remboursement.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reformulation'),

  ('11111111-b00f-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00f-4000-0000-000000000007',
   NULL, 'B1', 'CE',
   'Que doit faire Sonia après la panne de son vélo ?',
   'La consigne est double et explicite : « Verrouillez-le à la station la plus proche et signalez la panne depuis l''application ». C''est un **repérage des deux actions demandées** (déposer le vélo + le signaler). La réponse A invente une agence et une réparation à la charge de l''utilisatrice, absentes du texte. La réponse B recycle le tarif donné à Mehdi pour les locations longues : il sanctionne la durée d''utilisation, pas une panne. La réponse C contredit la phrase « Le trajet en cours **ne vous sera pas facturé** » : il n''y a rien à régler, donc rien à se faire rembourser ensuite.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b00f-1000-0000-000000000008', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00f-4000-0000-000000000008',
   NULL, 'B1', 'CE',
   'Que faut-il comprendre de la réponse faite à Bruno ?',
   'En reliant les deux phrases — « Signalez votre allergie au moment de la réservation » et « le chef adaptera la recette servie à **l''ensemble du groupe** » — on comprend que la condition (prévenir) entraîne une adaptation collective : c''est une **inférence simple sur la portée de l''adaptation**. La réponse A restreint à tort la modification au seul Bruno, alors que le texte dit l''inverse. La réponse B détourne la réponse faite à Nadia : matériel et ingrédients sont fournis, rien n''est à apporter hormis une boîte. La réponse D contredit l''ouverture « Bien sûr » : la participation est acquise, sous simple condition de signalement préalable.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-b00f-1000-0000-000000000009', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00f-4000-0000-000000000009',
   NULL, 'B1', 'CE',
   'Que propose la salle de sport à Samuel ?',
   'La réponse s''ouvre sur « Pas forcément », puis décrit l''alternative : un gel de l''abonnement « sur présentation d''un certificat médical », sans paiement et avec report de la durée gelée en fin de contrat. Par **inférence d''intention**, on comprend que la salle propose une suspension plutôt qu''une résiliation. La réponse B prend le contre-pied du « Pas forcément » : la résiliation est précisément la solution que la FAQ écarte. La réponse C détourne le tarif donné à Estelle (cinq euros le cours supplémentaire) : pendant le gel, Samuel « ne paye rien ». La réponse D mélange les deux rubriques : les cours collectifs relèvent de la formule de base, pas de la blessure de Samuel.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-b00f-1000-0000-00000000000a', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00f-4000-0000-00000000000a',
   NULL, 'B1', 'CE',
   'Que faut-il comprendre sur les frais de retour ?',
   'La phrase clé oppose deux cas : « Le retour est gratuit pour un échange, **mais** reste à votre charge pour un remboursement ». Par **inférence sur cette opposition** (connecteur « mais »), la gratuité dépend du choix du client : échange = offert, remboursement = payant. La réponse A sur-généralise en ignorant le premier cas, où le renvoi est gratuit. La réponse B contredit la réponse faite à Agnieszka : les articles soldés se rendent « dans les mêmes conditions que les autres ». La réponse D mélange deux informations proches : « trente jours » est le **délai pour demander le bon de retour**, pas une promesse de remboursement des frais d''envoi.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  -- Q01 — aquagym piscine de Roncey (bonne réponse : position 2)
  ('11111111-b00f-2100-0000-000000000001', '11111111-b00f-1000-0000-000000000001',
   'Payer son inscription en ligne avant le premier cours',
   'false', '1'),
  ('11111111-b00f-2200-0000-000000000001', '11111111-b00f-1000-0000-000000000001',
   'Se présenter à l''accueil avec un certificat médical récent',
   'true', '2'),
  ('11111111-b00f-2300-0000-000000000001', '11111111-b00f-1000-0000-000000000001',
   'Attendre la fin des travaux du grand bassin',
   'false', '3'),
  ('11111111-b00f-2400-0000-000000000001', '11111111-b00f-1000-0000-000000000001',
   'Demander la prolongation de son abonnement de deux mois',
   'false', '4'),

  -- Q02 — remboursement RouleFacile (bonne réponse : position 4)
  ('11111111-b00f-2100-0000-000000000002', '11111111-b00f-1000-0000-000000000002',
   'Envoyer une réclamation sous cinq jours ouvrés',
   'false', '1'),
  ('11111111-b00f-2200-0000-000000000002', '11111111-b00f-1000-0000-000000000002',
   'Contacter le conducteur par la messagerie du site',
   'false', '2'),
  ('11111111-b00f-2300-0000-000000000002', '11111111-b00f-1000-0000-000000000002',
   'Réserver un nouveau trajet pour obtenir le remboursement',
   'false', '3'),
  ('11111111-b00f-2400-0000-000000000002', '11111111-b00f-1000-0000-000000000002',
   'Rien : le remboursement se fait automatiquement',
   'true', '4'),

  -- Q03 — fin de prêt médiathèque numérique (bonne réponse : position 1)
  ('11111111-b00f-2100-0000-000000000003', '11111111-b00f-1000-0000-000000000003',
   'Le livre est rendu automatiquement, sans risque d''amende',
   'true', '1'),
  ('11111111-b00f-2200-0000-000000000003', '11111111-b00f-1000-0000-000000000003',
   'Il faut rapporter le livre à la médiathèque sous trois semaines',
   'false', '2'),
  ('11111111-b00f-2300-0000-000000000003', '11111111-b00f-1000-0000-000000000003',
   'Une pénalité s''applique après la date de retour',
   'false', '3'),
  ('11111111-b00f-2400-0000-000000000003', '11111111-b00f-1000-0000-000000000003',
   'Le prêt se prolonge tout seul si personne n''a réservé le titre',
   'false', '4'),

  -- Q04 — billet du festival (bonne réponse : position 3)
  ('11111111-b00f-2100-0000-000000000004', '11111111-b00f-1000-0000-000000000004',
   'Se le faire rembourser depuis son espace personnel',
   'false', '1'),
  ('11111111-b00f-2200-0000-000000000004', '11111111-b00f-1000-0000-000000000004',
   'Le revendre au festival jusqu''à la veille du concert',
   'false', '2'),
  ('11111111-b00f-2300-0000-000000000004', '11111111-b00f-1000-0000-000000000004',
   'Le transmettre à un ami en changeant le nom en ligne',
   'true', '3'),
  ('11111111-b00f-2400-0000-000000000004', '11111111-b00f-1000-0000-000000000004',
   'L''utiliser un autre jour du festival',
   'false', '4'),

  -- Q05 — paniers pendant les vacances (bonne réponse : position 2)
  ('11111111-b00f-2100-0000-000000000005', '11111111-b00f-1000-0000-000000000005',
   'Le remboursement des paniers manqués',
   'false', '1'),
  ('11111111-b00f-2200-0000-000000000005', '11111111-b00f-1000-0000-000000000005',
   'Le report de ses paniers à la fin de l''abonnement',
   'true', '2'),
  ('11111111-b00f-2300-0000-000000000005', '11111111-b00f-1000-0000-000000000005',
   'La composition de paniers à la carte avant son départ',
   'false', '3'),
  ('11111111-b00f-2400-0000-000000000005', '11111111-b00f-1000-0000-000000000005',
   'La résiliation de son abonnement sans frais',
   'false', '4'),

  -- Q06 — accès PermisExpress (bonne réponse : position 1)
  ('11111111-b00f-2100-0000-000000000006', '11111111-b00f-1000-0000-000000000006',
   'Prolonger son accès à tarif réduit en gardant sa progression',
   'true', '1'),
  ('11111111-b00f-2200-0000-000000000006', '11111111-b00f-1000-0000-000000000006',
   'Refaire gratuitement toutes les leçons déjà validées',
   'false', '2'),
  ('11111111-b00f-2300-0000-000000000006', '11111111-b00f-1000-0000-000000000006',
   'L''inscrire à l''examen officiel pour trente euros',
   'false', '3'),
  ('11111111-b00f-2400-0000-000000000006', '11111111-b00f-1000-0000-000000000006',
   'Lui rembourser la moitié de ses six mois d''accès',
   'false', '4'),

  -- Q07 — vélo en panne Vélidoo (bonne réponse : position 4)
  ('11111111-b00f-2100-0000-000000000007', '11111111-b00f-1000-0000-000000000007',
   'Rapporter le vélo à l''agence pour le faire réparer',
   'false', '1'),
  ('11111111-b00f-2200-0000-000000000007', '11111111-b00f-1000-0000-000000000007',
   'Payer deux euros pour chaque demi-heure d''immobilisation',
   'false', '2'),
  ('11111111-b00f-2300-0000-000000000007', '11111111-b00f-1000-0000-000000000007',
   'Régler le trajet en cours puis demander un remboursement',
   'false', '3'),
  ('11111111-b00f-2400-0000-000000000007', '11111111-b00f-1000-0000-000000000007',
   'Laisser le vélo à une station et signaler la panne dans l''application',
   'true', '4'),

  -- Q08 — allergie de Bruno au cours de cuisine (bonne réponse : position 3)
  ('11111111-b00f-2100-0000-000000000008', '11111111-b00f-1000-0000-000000000008',
   'Il devra cuisiner une recette différente de celle des autres',
   'false', '1'),
  ('11111111-b00f-2200-0000-000000000008', '11111111-b00f-1000-0000-000000000008',
   'Il doit apporter ses propres ingrédients sans fruits à coque',
   'false', '2'),
  ('11111111-b00f-2300-0000-000000000008', '11111111-b00f-1000-0000-000000000008',
   'Tout le groupe suivra une recette adaptée s''il prévient à la réservation',
   'true', '3'),
  ('11111111-b00f-2400-0000-000000000008', '11111111-b00f-1000-0000-000000000008',
   'Il ne peut pas participer les soirs de recettes aux fruits à coque',
   'false', '4'),

  -- Q09 — abonnement gelé Gymvert (bonne réponse : position 1)
  ('11111111-b00f-2100-0000-000000000009', '11111111-b00f-1000-0000-000000000009',
   'Suspendre son abonnement sans frais grâce à un certificat médical',
   'true', '1'),
  ('11111111-b00f-2200-0000-000000000009', '11111111-b00f-1000-0000-000000000009',
   'Résilier immédiatement son contrat sans pénalité',
   'false', '2'),
  ('11111111-b00f-2300-0000-000000000009', '11111111-b00f-1000-0000-000000000009',
   'Payer cinq euros par séance pendant sa blessure',
   'false', '3'),
  ('11111111-b00f-2400-0000-000000000009', '11111111-b00f-1000-0000-000000000009',
   'Suivre deux cours collectifs adaptés par semaine',
   'false', '4'),

  -- Q10 — frais de retour Filature & Co (bonne réponse : position 3)
  ('11111111-b00f-2100-0000-00000000000a', '11111111-b00f-1000-0000-00000000000a',
   'Le renvoi d''un article est toujours payant',
   'false', '1'),
  ('11111111-b00f-2200-0000-00000000000a', '11111111-b00f-1000-0000-00000000000a',
   'Les articles soldés ne peuvent pas être renvoyés',
   'false', '2'),
  ('11111111-b00f-2300-0000-00000000000a', '11111111-b00f-1000-0000-00000000000a',
   'Le renvoi est offert seulement si le client choisit un échange',
   'true', '3'),
  ('11111111-b00f-2400-0000-00000000000a', '11111111-b00f-1000-0000-00000000000a',
   'La boutique rembourse les frais de retour sous trente jours',
   'false', '4');

-- ============================================================================
-- CHECKLIST — contrôles passés
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes (11111111-b00f-1000/4000/21..2400-…-NN, NN=01..0a).
-- [x] Support unique : FAQ (10 services et situations toutes différentes :
--     piscine municipale, covoiturage, médiathèque numérique, festival,
--     paniers de légumes, code de la route en ligne, vélos en libre-service,
--     cours de cuisine, salle de sport, boutique de vêtements en ligne).
--     Aucun support réservé à un autre lot (pas d''e-mail, pas de note, pas
--     d''annonce, etc.) — uniquement le format question/réponse de FAQ.
-- [x] Passages TEXTE ~60-120 mots, mise en forme FAQ réaliste (titre du
--     service + 2 paires Question/Réponse signées de prénoms variés),
--     media_id NULL.
-- [x] 4 propositions / 1 correcte par item. Distribution des bonnes réponses :
--     pos1:3 (Q3,Q6,Q9), pos2:2 (Q1,Q5), pos3:3 (Q4,Q8,Q10), pos4:2 (Q2,Q7)
--     — max 3 par position, 4 positions utilisées.
-- [x] competence_code : ce_reperage_explicite x4 (Q1,Q2,Q4,Q7),
--     ce_reformulation x3 (Q3,Q5,Q6), ce_inference_intention x3 (Q8,Q9,Q10).
-- [x] explanation ≥ 80 caractères : bonne réponse justifiée + les 3
--     distracteurs expliqués, point clé en **gras**, mécanisme linguistique
--     nommé (adverbe restrictif, double négation ni…ni, connecteur donc/mais,
--     confusion remise/remboursement, inférence d''intention…).
-- [x] Distracteurs tous liés au thème ; piège = confondre deux informations
--     proches (souvent la réponse de l''autre rubrique de la FAQ).
-- [x] Pas de SVG ni SSML dans ce lot (supports textuels uniquement) — rien à
--     équilibrer. Pas de medias.
-- [x] Apostrophes SQL doublées partout, contenu 100% original, items autonomes.
-- ============================================================================
