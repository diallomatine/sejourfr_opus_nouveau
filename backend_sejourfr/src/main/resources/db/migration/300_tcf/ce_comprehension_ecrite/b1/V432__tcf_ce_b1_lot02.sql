-- ============================================================================
-- V432 — TCF CE B1 — lot 02 (support : message administratif)
-- ----------------------------------------------------------------------------
-- 10 items de compréhension écrite B1. Support unique : message administratif
-- (CAF pièce manquante, préfecture remise de titre, CPAM RIB invalide,
-- France Travail convocation, mairie inscription scolaire, finances publiques
-- remboursement, OFII formation civique reportée, bailleur social enquête
-- ressources, état civil retrait CNI, restauration scolaire facture impayée).
-- Passages TEXTE (~60-120 mots), questions + choices (4 rows/question).
-- theme_id = 22222222-0000-0000-0000-000000000002, difficulty='B1',
-- question_type='CE'. Données déterministes, rejouables dev+recette.
-- ============================================================================


-- passages — supports de lecture référencés par les questions ci-dessous
INSERT INTO passages
  (id, type, content, media_id, theme_id)
VALUES
  ('11111111-b002-4000-0000-000000000001', 'TEXTE',
   'Objet : pièce manquante — dossier d''aide au logement

Monsieur Barry,

Votre demande d''aide au logement du 12 mai est en cours d''instruction. Toutefois, votre dossier est incomplet : il manque votre avis d''imposition 2025. Sans ce document, le calcul de vos droits ne peut pas être effectué. Merci de le transmettre avant le 15 juillet, de préférence depuis votre espace personnel, rubrique « Mes démarches ». Vous pouvez aussi le déposer à l''accueil de votre agence, sans rendez-vous. Passé ce délai, votre demande sera classée sans suite et vous devrez en déposer une nouvelle.

Caisse d''allocations familiales du Rhône',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b002-4000-0000-000000000002', 'TEXTE',
   'Objet : remise de votre titre de séjour

Madame Fernandes,

Votre carte de séjour pluriannuelle est disponible. Vous êtes invitée à venir la retirer au guichet 4 de la préfecture du Bas-Rhin, le mardi 23 juin à 10 h 30. Vous devrez présenter ce courrier, votre passeport, votre récépissé, ainsi que des timbres fiscaux d''un montant de 225 euros, à acheter en ligne avant le rendez-vous. Attention : aucun paiement n''est possible sur place. En cas d''indisponibilité, signalez-le depuis notre module de prise de rendez-vous afin de choisir un autre créneau.

Service des étrangers — Préfecture du Bas-Rhin',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b002-4000-0000-000000000003', 'TEXTE',
   'Objet : remboursement de soins en attente

Monsieur Zhang,

Nous avons tenté de vous verser la somme de 67,40 euros correspondant à vos consultations du mois d''avril. Ce virement a été rejeté par votre banque : les coordonnées bancaires enregistrées dans votre dossier ne sont plus valides. Pour recevoir ce remboursement, connectez-vous à votre compte ameli, rubrique « Mes informations », et enregistrez votre nouveau RIB. Le virement sera ensuite relancé automatiquement sous huit jours. Sans mise à jour de votre part, la somme restera en attente. Aucun document papier n''est nécessaire.

Votre caisse primaire d''assurance maladie',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b002-4000-0000-000000000004', 'TEXTE',
   'Objet : convocation à un entretien de suivi

Monsieur Benali,

Dans le cadre de votre accompagnement, vous êtes convoqué à un entretien avec votre conseillère, Madame Lefort, le jeudi 2 juillet à 14 h, à l''agence de Saint-Étienne Centre. Pensez à apporter votre CV à jour. Cet entretien est obligatoire : une absence non justifiée peut entraîner une radiation de la liste des demandeurs d''emploi. Si vous n''êtes pas disponible à cette date, vous pouvez déplacer le rendez-vous depuis votre espace personnel, au plus tard 48 heures à l''avance. Aucun changement n''est accepté par téléphone.

France Travail — Agence de Saint-Étienne Centre',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b002-4000-0000-000000000005', 'TEXTE',
   'Objet : inscription scolaire de votre fille

Madame Kovalenko,

Nous avons bien reçu la demande d''inscription de votre fille Daryna à l''école élémentaire pour la rentrée de septembre. Votre dossier a été enregistré. Toutefois, l''affectation dans l''école de votre secteur ne deviendra définitive qu''à réception d''un justificatif de domicile de moins de trois mois. Vous pouvez le déposer au service des affaires scolaires ou l''envoyer par courriel avant le 30 juin. Sans ce document, une place ne pourra pas être garantie dans l''école demandée. La liste des fournitures sera communiquée par l''école début juillet.

Service des affaires scolaires — Mairie de Roubaix',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b002-4000-0000-000000000006', 'TEXTE',
   'Objet : avis de remboursement

Monsieur Morales,

Après vérification de votre déclaration de revenus, nos services ont constaté que le montant prélevé à la source en 2025 est supérieur à l''impôt réellement dû. Vous bénéficiez donc d''un remboursement de 184 euros. Cette somme sera versée avant le 31 juillet sur le compte bancaire connu de notre administration. Vous n''avez aucune démarche à effectuer. Toutefois, si vos coordonnées bancaires ont changé récemment, pensez à les mettre à jour dans votre espace particulier. Ce courriel est envoyé automatiquement : merci de ne pas y répondre.

Centre des finances publiques de Perpignan',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b002-4000-0000-000000000007', 'TEXTE',
   'Objet : report de votre formation civique

Madame Sharma,

Dans le cadre de votre contrat d''intégration républicaine, vous étiez convoquée à une journée de formation civique le lundi 15 juin. En raison d''un mouvement social, cette session est reportée au lundi 29 juin, de 9 h à 17 h, à la même adresse. Votre présence reste obligatoire pendant toute la journée : l''attestation, indispensable pour la suite de votre parcours, n''est remise qu''aux personnes présentes du début à la fin. Le déjeuner est pris en charge. Aucune nouvelle convocation papier ne sera envoyée : ce message en tient lieu.

Office français de l''immigration et de l''intégration — Direction de Lyon',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b002-4000-0000-000000000008', 'TEXTE',
   'Objet : enquête annuelle sur vos ressources

Madame Ndiaye,

Comme chaque année, la réglementation nous oblige à vérifier les ressources des locataires du parc social. Vous trouverez en pièce jointe le formulaire d''enquête à compléter. Merci de nous le retourner, accompagné de votre avis d''imposition 2025, avant le 31 octobre, par courrier ou depuis votre espace locataire. Attention : sans réponse de votre part dans ce délai, la loi nous impose d''appliquer un supplément de loyer maximal dès le mois de novembre, ainsi que des frais de relance de 25 euros. Ce contrôle ne concerne pas le montant de vos charges.

Habitat Sud Loire — Service gestion locative',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b002-4000-0000-000000000009', 'TEXTE',
   'Objet : votre carte nationale d''identité est disponible

Monsieur Kowalski,

La carte d''identité que vous avez demandée le 4 mai est arrivée en mairie. Vous pouvez la retirer au service état civil, sans rendez-vous, du mardi au samedi entre 8 h 30 et 12 h. Le retrait doit être effectué par vous-même : aucune autre personne ne peut venir à votre place, même avec une procuration. Présentez le récépissé de votre demande ainsi que votre ancienne carte, qui sera détruite. Attention : tout titre non retiré dans un délai de trois mois est renvoyé, puis détruit, et la démarche complète devra être recommencée.

Service état civil — Mairie de Villeneuve-sur-Lot',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b002-4000-0000-00000000000a', 'TEXTE',
   'Objet : facture de restauration scolaire impayée

Madame Haddad,

Sauf erreur de notre part, la facture de cantine du mois d''avril, d''un montant de 58,60 euros, n''a pas encore été réglée. Merci de régulariser votre situation sous quinze jours, en ligne sur le portail famille ou par chèque à l''ordre du Trésor public. Si vous rencontrez des difficultés financières, notre service peut vous proposer un paiement en plusieurs fois : il suffit de nous appeler avant la fin du délai. Sans paiement ni appel de votre part, le dossier sera transmis à la trésorerie pour recouvrement. L''accès de votre fils à la cantine n''est pas remis en cause.

Service de restauration scolaire — Ville de Givors',
   NULL, '22222222-0000-0000-0000-000000000002');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-b002-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b002-4000-0000-000000000001',
   NULL, 'B1', 'CE',
   'Que doit faire Amadou pour que sa demande soit traitée ?',
   'La CAF écrit : « il manque votre avis d''imposition 2025 » et « Merci de le transmettre avant le 15 juillet ». C''est un **repérage explicite de l''action demandée** : envoyer le document manquant dans le délai. La réponse A confond l''action demandée et la **conséquence du retard** : déposer une nouvelle demande n''arrive que si le délai est dépassé. La réponse B invente une contrainte : le dépôt à l''agence se fait justement « sans rendez-vous ». La réponse D contredit le texte : sans le document, « le calcul de vos droits ne peut pas être effectué », attendre bloquerait le dossier.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b002-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b002-4000-0000-000000000002',
   NULL, 'B1', 'CE',
   'Pourquoi Lucia est-elle convoquée à la préfecture ?',
   'Le message annonce : « Votre carte de séjour pluriannuelle est disponible. Vous êtes invitée à venir la retirer ». C''est un **repérage explicite de l''objet de la convocation** : récupérer le titre déjà fabriqué. La réponse B se trompe d''étape : la demande est terminée puisque la carte est prête, il ne s''agit pas d''un dépôt de renouvellement. La réponse C contredit le texte : les timbres fiscaux doivent être achetés « en ligne avant le rendez-vous », « aucun paiement n''est possible sur place ». La réponse D confond les documents : le récépissé est seulement une **pièce à présenter**, pas l''objet du rendez-vous.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b002-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b002-4000-0000-000000000003',
   NULL, 'B1', 'CE',
   'Quel est l''objet réel du message de l''assurance maladie ?',
   'La caisse explique que le virement « a été rejeté » car les coordonnées « ne sont plus valides », puis demande : « enregistrez votre nouveau RIB ». Par **inférence d''intention**, l''objet réel est d''obtenir la mise à jour des coordonnées bancaires pour débloquer le paiement. La réponse A déforme la situation : le remboursement n''est pas refusé, il est « en attente » et sera « relancé automatiquement ». La réponse C inverse le **sens du virement** : les 67,40 euros sont dus à Wei, on ne lui réclame rien. La réponse D contredit la dernière phrase : « Aucun document papier n''est nécessaire », tout se fait sur le compte ameli.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-b002-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b002-4000-0000-000000000004',
   NULL, 'B1', 'CE',
   'Que doit faire Rachid s''il n''est pas disponible le 2 juillet ?',
   'Le message précise : « vous pouvez déplacer le rendez-vous depuis votre espace personnel, au plus tard 48 heures à l''avance ». Par **inférence simple**, en cas d''indisponibilité, Rachid doit modifier la date en ligne dans ce délai. La réponse A contredit la dernière phrase : « Aucun changement n''est accepté par téléphone » — le distracteur joue sur le réflexe courant d''appeler son conseiller. La réponse B invente une possibilité absente du texte : aucune autre agence n''est mentionnée. La réponse C prend un **détail matériel** (apporter son CV à jour) pour la solution au problème de disponibilité.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-b002-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b002-4000-0000-000000000005',
   NULL, 'B1', 'CE',
   'Que faut-il comprendre concernant l''inscription de Daryna ?',
   'La mairie indique : « l''affectation ne deviendra définitive qu''à réception d''un justificatif de domicile de moins de trois mois ». La bonne réponse **reformule cette condition** : l''inscription dépend de l''envoi du justificatif avant le 30 juin — la restriction « ne… que » marque la condition nécessaire. La réponse A exagère : le dossier est « enregistré », il n''est pas refusé, il est seulement incomplet. La réponse C affirme l''inverse : la place dans l''école du secteur n''est justement **pas encore garantie**. La réponse D promeut un détail secondaire (la liste des fournitures, communiquée plus tard par l''école) en condition d''inscription.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reformulation'),

  ('11111111-b002-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b002-4000-0000-000000000006',
   NULL, 'B1', 'CE',
   'Que doit faire Diego pour recevoir les 184 euros ?',
   'Le texte est explicite : « Vous n''avez aucune démarche à effectuer », le versement est automatique « avant le 31 juillet ». Par **inférence simple**, la seule action possible est conditionnelle : mettre à jour son RIB **si** ses coordonnées ont changé — la conjonction « si » marque cette hypothèse. La réponse A contredit la consigne finale : « merci de ne pas y répondre », le courriel est automatique. La réponse B inverse le **sens du paiement** : c''est l''administration qui verse 184 euros à Diego, pas l''inverse. La réponse D invente une démarche : la déclaration a déjà été vérifiée, rien n''est à refaire.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-b002-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b002-4000-0000-000000000007',
   NULL, 'B1', 'CE',
   'Qu''apprend Priya en lisant ce message ?',
   'L''OFII annonce : « cette session est reportée au lundi 29 juin […] à la même adresse ». La bonne réponse **reformule ce report** : nouvelle date, lieu inchangé — le verbe « reporter » signifie décaler, pas supprimer. La réponse B confond précisément **report et annulation** : la formation aura bien lieu, deux semaines plus tard. La réponse C contredit la fin du message : « Aucune nouvelle convocation papier ne sera envoyée : ce message en tient lieu ». La réponse D contredit la condition de l''attestation, remise uniquement « aux personnes présentes du début à la fin » — partir plus tôt ferait perdre ce document indispensable.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reformulation'),

  ('11111111-b002-1000-0000-000000000008', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b002-4000-0000-000000000008',
   NULL, 'B1', 'CE',
   'Que risque Fatou si elle ne renvoie pas le formulaire avant le 31 octobre ?',
   'Le bailleur prévient : « sans réponse de votre part dans ce délai, la loi nous impose d''appliquer un supplément de loyer maximal dès le mois de novembre ». C''est un **repérage explicite de la conséquence** : une hausse du loyer à partir de novembre. La réponse A exagère la sanction : il n''est jamais question de perdre le logement ni de résilier le bail. La réponse B confond **loyer et charges**, alors que le texte écarte précisément cette confusion : « Ce contrôle ne concerne pas le montant de vos charges ». La réponse C déforme les frais de relance : 25 euros en une fois, pas une amende répétée chaque mois.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b002-1000-0000-000000000009', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b002-4000-0000-000000000009',
   NULL, 'B1', 'CE',
   'Que doit comprendre Marek concernant le retrait de sa carte ?',
   'Deux informations sont à relier par **inférence simple** : « Le retrait doit être effectué par vous-même » et « tout titre non retiré dans un délai de trois mois est renvoyé, puis détruit ». La bonne réponse combine ces deux contraintes : venir en personne, dans les trois mois. La réponse A contredit le texte : le retrait se fait « sans rendez-vous », aux horaires indiqués. La réponse C contredit l''interdiction explicite : « aucune autre personne ne peut venir à votre place, **même avec une procuration** ». La réponse D inverse le sort de l''ancienne carte : elle doit être présentée pour être **détruite**, pas conservée comme justificatif.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-b002-1000-0000-00000000000a', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b002-4000-0000-00000000000a',
   NULL, 'B1', 'CE',
   'Que propose le service à Aïcha en cas de difficultés financières ?',
   'Le message indique : « notre service peut vous proposer un paiement en plusieurs fois : il suffit de nous appeler avant la fin du délai ». La bonne réponse **reformule cette aide** : un règlement échelonné de la facture, à condition de téléphoner. La réponse A invente un geste commercial : le montant de 58,60 euros n''est jamais réduit. La réponse B déforme le délai : la régularisation reste due « sous quinze jours », l''étalement ne prolonge pas ce délai sans appel. La réponse D confond la proposition d''aide et la **conséquence en cas de silence** : la transmission à la trésorerie n''est pas une offre, c''est la menace finale du recouvrement.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reformulation');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  -- Q01 — pièce manquante CAF (bonne réponse : position 3)
  ('11111111-b002-2100-0000-000000000001', '11111111-b002-1000-0000-000000000001',
   'Déposer une nouvelle demande d''aide au logement',
   'false', '1'),
  ('11111111-b002-2200-0000-000000000001', '11111111-b002-1000-0000-000000000001',
   'Prendre rendez-vous à l''accueil de son agence',
   'false', '2'),
  ('11111111-b002-2300-0000-000000000001', '11111111-b002-1000-0000-000000000001',
   'Transmettre son avis d''imposition avant le 15 juillet',
   'true', '3'),
  ('11111111-b002-2400-0000-000000000001', '11111111-b002-1000-0000-000000000001',
   'Attendre la fin de l''instruction sans rien envoyer',
   'false', '4'),

  -- Q02 — convocation préfecture (bonne réponse : position 1)
  ('11111111-b002-2100-0000-000000000002', '11111111-b002-1000-0000-000000000002',
   'Pour récupérer sa carte de séjour au guichet',
   'true', '1'),
  ('11111111-b002-2200-0000-000000000002', '11111111-b002-1000-0000-000000000002',
   'Pour déposer une demande de renouvellement de titre',
   'false', '2'),
  ('11111111-b002-2300-0000-000000000002', '11111111-b002-1000-0000-000000000002',
   'Pour acheter des timbres fiscaux sur place',
   'false', '3'),
  ('11111111-b002-2400-0000-000000000002', '11111111-b002-1000-0000-000000000002',
   'Pour faire prolonger la validité de son récépissé',
   'false', '4'),

  -- Q03 — RIB invalide CPAM (bonne réponse : position 2)
  ('11111111-b002-2100-0000-000000000003', '11111111-b002-1000-0000-000000000003',
   'L''informer que ses soins d''avril ne seront pas remboursés',
   'false', '1'),
  ('11111111-b002-2200-0000-000000000003', '11111111-b002-1000-0000-000000000003',
   'Lui demander de mettre à jour ses coordonnées bancaires en ligne',
   'true', '2'),
  ('11111111-b002-2300-0000-000000000003', '11111111-b002-1000-0000-000000000003',
   'Lui réclamer le remboursement de 67,40 euros versés en trop',
   'false', '3'),
  ('11111111-b002-2400-0000-000000000003', '11111111-b002-1000-0000-000000000003',
   'Lui demander d''envoyer son nouveau RIB par courrier',
   'false', '4'),

  -- Q04 — convocation France Travail (bonne réponse : position 4)
  ('11111111-b002-2100-0000-000000000004', '11111111-b002-1000-0000-000000000004',
   'Prévenir sa conseillère par téléphone',
   'false', '1'),
  ('11111111-b002-2200-0000-000000000004', '11111111-b002-1000-0000-000000000004',
   'Se présenter le même jour dans une autre agence',
   'false', '2'),
  ('11111111-b002-2300-0000-000000000004', '11111111-b002-1000-0000-000000000004',
   'Envoyer simplement son CV à jour à l''agence',
   'false', '3'),
  ('11111111-b002-2400-0000-000000000004', '11111111-b002-1000-0000-000000000004',
   'Déplacer le rendez-vous en ligne au moins 48 heures avant',
   'true', '4'),

  -- Q05 — inscription scolaire (bonne réponse : position 2)
  ('11111111-b002-2100-0000-000000000005', '11111111-b002-1000-0000-000000000005',
   'Elle est refusée parce que le dossier est arrivé trop tard',
   'false', '1'),
  ('11111111-b002-2200-0000-000000000005', '11111111-b002-1000-0000-000000000005',
   'Elle ne sera définitive qu''après l''envoi d''un justificatif de domicile récent',
   'true', '2'),
  ('11111111-b002-2300-0000-000000000005', '11111111-b002-1000-0000-000000000005',
   'Elle est déjà garantie dans l''école du secteur',
   'false', '3'),
  ('11111111-b002-2400-0000-000000000005', '11111111-b002-1000-0000-000000000005',
   'Elle dépend de l''achat des fournitures avant juillet',
   'false', '4'),

  -- Q06 — remboursement des impôts (bonne réponse : position 3)
  ('11111111-b002-2100-0000-000000000006', '11111111-b002-1000-0000-000000000006',
   'Répondre au courriel pour confirmer son compte bancaire',
   'false', '1'),
  ('11111111-b002-2200-0000-000000000006', '11111111-b002-1000-0000-000000000006',
   'Verser 184 euros à l''administration avant le 31 juillet',
   'false', '2'),
  ('11111111-b002-2300-0000-000000000006', '11111111-b002-1000-0000-000000000006',
   'Rien, sauf si ses coordonnées bancaires ont changé',
   'true', '3'),
  ('11111111-b002-2400-0000-000000000006', '11111111-b002-1000-0000-000000000006',
   'Déposer une nouvelle déclaration de revenus corrigée',
   'false', '4'),

  -- Q07 — formation civique OFII (bonne réponse : position 1)
  ('11111111-b002-2100-0000-000000000007', '11111111-b002-1000-0000-000000000007',
   'Sa formation est décalée au 29 juin, au même endroit',
   'true', '1'),
  ('11111111-b002-2200-0000-000000000007', '11111111-b002-1000-0000-000000000007',
   'Sa formation civique est définitivement annulée',
   'false', '2'),
  ('11111111-b002-2300-0000-000000000007', '11111111-b002-1000-0000-000000000007',
   'Elle recevra bientôt une nouvelle convocation par courrier',
   'false', '3'),
  ('11111111-b002-2400-0000-000000000007', '11111111-b002-1000-0000-000000000007',
   'Elle pourra quitter la formation avant 17 h si nécessaire',
   'false', '4'),

  -- Q08 — enquête ressources bailleur (bonne réponse : position 4)
  ('11111111-b002-2100-0000-000000000008', '11111111-b002-1000-0000-000000000008',
   'La résiliation de son bail et la perte du logement',
   'false', '1'),
  ('11111111-b002-2200-0000-000000000008', '11111111-b002-1000-0000-000000000008',
   'Une augmentation du montant de ses charges',
   'false', '2'),
  ('11111111-b002-2300-0000-000000000008', '11111111-b002-1000-0000-000000000008',
   'Une amende de 25 euros pour chaque mois de retard',
   'false', '3'),
  ('11111111-b002-2400-0000-000000000008', '11111111-b002-1000-0000-000000000008',
   'Un supplément de loyer appliqué dès le mois de novembre',
   'true', '4'),

  -- Q09 — retrait de la carte d''identité (bonne réponse : position 2)
  ('11111111-b002-2100-0000-000000000009', '11111111-b002-1000-0000-000000000009',
   'Il doit d''abord prendre rendez-vous au service état civil',
   'false', '1'),
  ('11111111-b002-2200-0000-000000000009', '11111111-b002-1000-0000-000000000009',
   'Il doit venir lui-même chercher sa carte dans les trois mois',
   'true', '2'),
  ('11111111-b002-2300-0000-000000000009', '11111111-b002-1000-0000-000000000009',
   'Il peut envoyer un proche muni d''une procuration',
   'false', '3'),
  ('11111111-b002-2400-0000-000000000009', '11111111-b002-1000-0000-000000000009',
   'Il doit conserver son ancienne carte comme justificatif',
   'false', '4'),

  -- Q10 — facture de cantine (bonne réponse : position 3)
  ('11111111-b002-2100-0000-00000000000a', '11111111-b002-1000-0000-00000000000a',
   'Une réduction du montant de la facture d''avril',
   'false', '1'),
  ('11111111-b002-2200-0000-00000000000a', '11111111-b002-1000-0000-00000000000a',
   'Un report automatique du paiement de plusieurs mois',
   'false', '2'),
  ('11111111-b002-2300-0000-00000000000a', '11111111-b002-1000-0000-00000000000a',
   'Un paiement de la facture en plusieurs fois, sur simple appel',
   'true', '3'),
  ('11111111-b002-2400-0000-00000000000a', '11111111-b002-1000-0000-00000000000a',
   'La transmission immédiate du dossier à la trésorerie',
   'false', '4');

-- ============================================================================
-- CHECKLIST — contrôles passés
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes (11111111-b002-1000/4000/21..2400-…-NN, NN=01..0a).
-- [x] Support unique : message administratif (10 expéditeurs et situations
--     toutes différentes : CAF pièce manquante, préfecture remise de titre,
--     CPAM RIB invalide, France Travail convocation, mairie inscription
--     scolaire, finances publiques remboursement, OFII formation reportée,
--     bailleur social enquête ressources, état civil retrait CNI, restauration
--     scolaire facture impayée). Aucun support réservé à d''autres lots.
-- [x] Passages TEXTE ~60-120 mots, mise en forme administrative (objet,
--     civilité, corps, signature du service), media_id NULL.
-- [x] 4 propositions / 1 correcte par item. Distribution des bonnes réponses :
--     pos1:2, pos2:3, pos3:3, pos4:2 (max 3 par position, 4 positions utilisées).
-- [x] competence_code : ce_reperage_explicite x3 (Q1, Q2, Q8),
--     ce_inference_intention x4 (Q3, Q4, Q6, Q9), ce_reformulation x3 (Q5, Q7, Q10).
-- [x] explanation ≥ 80 caractères : bonne réponse justifiée + les 3 distracteurs
--     expliqués, point clé en **gras**, mécanisme linguistique nommé (restriction
--     « ne… que », condition « si », report vs annulation, sens du virement,
--     conséquence vs proposition…).
-- [x] Pas de SVG ni SSML dans ce lot (supports textuels uniquement) — rien à
--     équilibrer.
-- [x] Apostrophes SQL doublées partout, contenu 100% original, items autonomes.
-- ============================================================================
