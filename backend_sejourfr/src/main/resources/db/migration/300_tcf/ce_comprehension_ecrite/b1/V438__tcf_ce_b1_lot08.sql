-- ============================================================================
-- V438 — TCF CE B1 — lot 08 (support : courriel professionnel simple)
-- ----------------------------------------------------------------------------
-- 10 items de compréhension écrite B1. Support unique : courriel professionnel
-- simple (réunion déplacée, demande de remplacement, maintenance informatique,
-- relecture de chiffres, congés partiellement acceptés, formation reportée,
-- accueil premier jour, demande de tableau de synthèse, note de frais
-- incomplète, proposition d''évolution de poste). Passages TEXTE (~60-120
-- mots), questions + choices (4 rows/question). theme_id =
-- 22222222-0000-0000-0000-000000000002, difficulty='B1', question_type='CE'.
-- Données déterministes, rejouables dev+recette.
-- ============================================================================


-- passages — supports de lecture référencés par les questions ci-dessous
INSERT INTO passages
  (id, type, content, media_id, theme_id)
VALUES
  ('11111111-b008-4000-0000-000000000001', 'TEXTE',
   'Objet : réunion d''équipe déplacée

Bonjour à tous,

La réunion d''équipe prévue jeudi 12 à 14 h est déplacée au mardi 10 à 9 h 30, car la salle Vauban est réservée toute la journée de jeudi pour un audit. Nous nous retrouverons donc en salle Lumière, au deuxième étage. L''ordre du jour reste le même : bilan du trimestre et organisation des plannings d''été. Merci de confirmer votre présence avant lundi midi et d''apporter vos tableaux de suivi. En cas d''absence, prévenez directement Sofia, qui prendra des notes pour vous.

Bonne journée,
Olena Kovalenko
Cheffe d''équipe',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b008-4000-0000-000000000002', 'TEXTE',
   'Objet : remplacement samedi 21

Bonjour Marta,

Karol est arrêté toute la semaine et personne n''est prévu à l''accueil samedi 21 au matin. Serais-tu d''accord pour assurer ce créneau, de 8 h 30 à 13 h ? Bien entendu, ce n''est pas une obligation : si tu acceptes, tu pourras récupérer ta matinée le lundi suivant, comme le prévoit notre accord d''équipe. J''ai aussi posé la question à Bilal, donc réponds-moi avant jeudi soir pour que j''organise le planning. Si aucun de vous deux n''est disponible, je viendrai moi-même.

Merci d''avance,
Amadou Sow
Responsable du magasin',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b008-4000-0000-000000000003', 'TEXTE',
   'Objet : maintenance des serveurs vendredi soir

Bonjour à toutes et à tous,

Une opération de maintenance aura lieu vendredi 19, de 18 h à minuit. Pendant cette période, la messagerie et les dossiers partagés seront inaccessibles. Pour éviter toute perte de données, merci d''enregistrer vos documents en cours et de fermer vos sessions avant 17 h 30. Les postes pourront rester allumés : les mises à jour s''installeront automatiquement pendant la nuit. Lundi matin, tout fonctionnera normalement ; en cas de problème, contactez l''assistance au poste 4512.

Cordialement,
Wei Zhang
Service informatique',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b008-4000-0000-000000000004', 'TEXTE',
   'Objet : présentation client Morel

Bonjour Inga,

Je viens de terminer la présentation pour le client Morel, que j''envoie mercredi matin. Avant cela, pourrais-tu vérifier uniquement les chiffres des pages 4 à 7 ? Ce sont ceux du dernier trimestre et je veux être sûr de ne pas avoir fait d''erreur de calcul. Pas besoin de regarder la mise en page ni les textes : Salim s''en est déjà occupé hier. Si tu peux me renvoyer tes remarques mardi avant 16 h, ce serait parfait.

Merci beaucoup,
Rachid Benali',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b008-4000-0000-000000000005', 'TEXTE',
   'Objet : votre demande de congés

Bonjour Bogdan,

Nous avons bien étudié votre demande de congés du 7 au 25 juillet. Les deux premières semaines sont acceptées sans difficulté. En revanche, la semaine du 21 juillet pose problème : trois personnes de votre service seront déjà absentes à cette date. Nous vous invitons donc à proposer une autre semaine, par exemple fin août, où le planning est plus souple. Merci de nous transmettre votre nouveau choix avant le 30 juin, afin que nous puissions valider l''ensemble de vos dates.

Cordialement,
Lucia Fernández
Service des ressources humaines',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b008-4000-0000-000000000006', 'TEXTE',
   'Objet : report de la formation « premiers secours »

Bonjour à tous,

La formation prévue les 9 et 10 juin est reportée aux 23 et 24 juin, notre formateur étant indisponible. Attention : les inscriptions ne sont pas transférées automatiquement. Si vous souhaitez participer aux nouvelles dates, vous devez donc vous inscrire de nouveau sur l''intranet, rubrique « Formations », avant le 16 juin. Les places restent limitées à douze participants. Ceux qui ne seraient pas disponibles fin juin pourront s''inscrire à la session d''automne, dont les dates seront publiées en septembre.

Bien cordialement,
Priya Sharma
Responsable formation',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b008-4000-0000-000000000007', 'TEXTE',
   'Objet : votre premier jour parmi nous

Bonjour Diego,

Toute l''équipe se réjouit de vous accueillir lundi 16. Présentez-vous à l''accueil du bâtiment B à 9 h, muni d''une pièce d''identité : votre badge d''accès vous y sera remis. Je viendrai ensuite vous chercher pour vous faire visiter les locaux et vous présenter vos collègues. Votre ordinateur sera déjà configuré ; la signature de votre contrat aura lieu, elle, à 14 h au service des ressources humaines, bâtiment A. À midi, l''équipe vous invite à déjeuner pour faire connaissance.

À lundi,
Fatou Ndiaye
Votre tutrice',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b008-4000-0000-000000000008', 'TEXTE',
   'Objet : réunion budget de lundi

Bonjour Olga,

Pour préparer la réunion budget de lundi, j''aurais besoin des résultats de ventes du deuxième trimestre. Inutile de rédiger le rapport complet, que tu présenteras comme prévu en septembre : un simple tableau d''une page, avec les totaux par région et la comparaison avec l''an dernier, suffira largement. Peux-tu me l''envoyer vendredi avant midi, pour que j''aie le temps de le relire pendant le week-end ? Si certains chiffres manquent encore, indique-le simplement dans le tableau.

Merci d''avance,
Yusuf Demir
Directeur commercial',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b008-4000-0000-000000000009', 'TEXTE',
   'Objet : note de frais de mai — pièce manquante

Bonjour Tomás,

Nous avons bien reçu votre note de frais pour votre déplacement à Lyon. Les billets de train et les repas sont validés. Il manque toutefois le justificatif de votre nuit d''hôtel du 12 mai : sans ce document, nous ne pouvons pas rembourser les 89 euros correspondants. Merci de le déposer sur l''application interne, ou de m''en envoyer une photo lisible, avant le 15 juin. Passé cette date, le remboursement de l''hôtel sera reporté sur la paie du mois suivant.

Bien à vous,
Khadija El Amrani
Service comptabilité',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b008-4000-0000-00000000000a', 'TEXTE',
   'Objet : proposition d''entretien

Bonjour Mariam,

Depuis votre arrivée il y a deux ans, vous avez pris en charge l''accueil des nouveaux clients avec beaucoup de sérieux, et les retours de l''équipe sont excellents. Le poste de coordinatrice du service client sera libre en septembre, après le départ de M. Lefort, et j''aimerais vous le proposer. Il ne s''agit pas d''une décision à prendre aujourd''hui : réfléchissez-y, puis prenez rendez-vous avec mon assistante pour que nous en parlions ensemble. Cette évolution s''accompagnerait d''une formation de trois semaines à Nantes.

Cordialement,
Aminata Diallo
Directrice d''agence',
   NULL, '22222222-0000-0000-0000-000000000002');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-b008-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b008-4000-0000-000000000001',
   NULL, 'B1', 'CE',
   'Qu''apprend-on à propos de la réunion d''équipe ?',
   'Le message annonce : « La réunion… est déplacée au mardi 10 à 9 h 30 » et « en salle Lumière, au deuxième étage ». C''est un **repérage explicite de la nouvelle date et du nouveau lieu**. La réponse A confond déplacement et annulation : l''audit occupe la salle Vauban, mais la réunion est seulement déplacée, pas supprimée. La réponse C reprend les **anciennes informations** (jeudi, salle Vauban) que le courriel vient justement remplacer. La réponse D contredit la phrase « L''ordre du jour reste le même » — piège de confusion entre changement d''organisation et changement de contenu.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b008-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b008-4000-0000-000000000002',
   NULL, 'B1', 'CE',
   'Que propose Amadou à Marta ?',
   'Amadou demande d''assurer le créneau du samedi matin et précise : « tu pourras récupérer ta matinée le lundi suivant ». Par **inférence simple**, on relie ces deux informations : un remplacement contre un repos compensé. La réponse A exagère la durée : Karol est arrêté toute la semaine, mais seul le **samedi matin** est à couvrir — piège de confusion entre deux durées proches du texte. La réponse B contredit « ce n''est pas une obligation ». La réponse C inverse les rôles : c''est Amadou qui organise le planning, Marta doit seulement répondre avant jeudi soir.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-b008-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b008-4000-0000-000000000003',
   NULL, 'B1', 'CE',
   'Que doivent faire les employés avant vendredi 17 h 30 ?',
   'Le message demande explicitement « d''enregistrer vos documents en cours et de fermer vos sessions avant 17 h 30 ». C''est un **repérage explicite de la consigne**. La réponse B contredit « Les postes pourront rester allumés » — piège de confusion entre fermer sa session et éteindre son poste. La réponse C contredit le texte : les mises à jour « s''installeront automatiquement », personne ne les installe soi-même. La réponse D déplace une information : le poste 4512 ne sert qu''**en cas de problème lundi matin**, ce n''est pas une action à effectuer avant vendredi.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b008-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b008-4000-0000-000000000004',
   NULL, 'B1', 'CE',
   'Que demande Rachid à Inga ?',
   'Rachid demande : « pourrais-tu vérifier uniquement les chiffres des pages 4 à 7 ? ». La bonne réponse **reformule cette vérification ciblée** de données chiffrées. La réponse A attribue à Inga ce que Salim a déjà fait : « la mise en page ni les textes : Salim s''en est déjà occupé hier ». La réponse B inverse les rôles : c''est Rachid qui « envoie mercredi matin » la présentation au client. La réponse D élargit abusivement la demande : l''adverbe « **uniquement** » restreint la relecture aux chiffres de quatre pages, pas à l''ensemble du document — piège de sur-généralisation.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reformulation'),

  ('11111111-b008-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b008-4000-0000-000000000005',
   NULL, 'B1', 'CE',
   'Que faut-il comprendre concernant les congés de Bogdan ?',
   'Lucia écrit : « Les deux premières semaines sont acceptées » puis « la semaine du 21 juillet pose problème… proposer une autre semaine ». Par **inférence simple**, on comprend une acceptation partielle assortie d''une demande de report. La réponse B exagère : seule la semaine du 21 juillet est refusée, pas l''ensemble de la demande. La réponse C transforme une suggestion en obligation : « **par exemple** fin août » n''impose rien, Bogdan choisit librement sa nouvelle semaine. La réponse D déforme un chiffre du texte : les « trois personnes » déjà absentes sont la cause du refus, pas des semaines offertes en plus.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-b008-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b008-4000-0000-000000000006',
   NULL, 'B1', 'CE',
   'Que doivent faire les personnes intéressées par les nouvelles dates de formation ?',
   'Priya prévient : « les inscriptions ne sont pas transférées automatiquement » puis « vous devez donc vous inscrire de nouveau sur l''intranet… avant le 16 juin ». Le connecteur « **donc** » relie ces deux informations : c''est l''action attendue, par **inférence simple**. La réponse A contredit directement la mise en garde sur l''absence de transfert automatique. La réponse B confond la session principale et le **plan de repli** : la session d''automne ne concerne que ceux qui ne sont pas disponibles fin juin. La réponse D invente un contact : l''indisponibilité du formateur est la cause du report, personne ne doit le joindre.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-b008-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b008-4000-0000-000000000007',
   NULL, 'B1', 'CE',
   'Que doit faire Diego en arrivant lundi matin ?',
   'Fatou indique : « Présentez-vous à l''accueil du bâtiment B à 9 h, muni d''une pièce d''identité ». C''est un **repérage explicite de la consigne du matin**. La réponse A confond les moments : la signature du contrat a lieu « à 14 h » au bâtiment A, pas en arrivant — piège de confusion entre deux rendez-vous proches du texte. La réponse C contredit « Votre ordinateur sera déjà configuré ». La réponse D mélange deux lieux : le badge est remis à l''**accueil du bâtiment B**, pas aux ressources humaines, qui ne servent qu''à la signature de l''après-midi.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b008-1000-0000-000000000008', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b008-4000-0000-000000000008',
   NULL, 'B1', 'CE',
   'Qu''attend exactement Yusuf de la part d''Olga ?',
   'Yusuf précise : « Inutile de rédiger le rapport complet… un simple tableau d''une page… suffira largement ». La bonne réponse **reformule cette attente réduite** : un document court de synthèse des ventes. La réponse A reprend exactement ce que Yusuf écarte : le rapport complet est prévu « comme prévu en septembre ». La réponse B invente une intervention orale : Olga doit envoyer un tableau vendredi avant midi, pas présenter lundi. La réponse C transforme un **détail secondaire** en demande principale : les chiffres manquants sont simplement à signaler dans le tableau, pas à lister à part — piège de confusion entre consigne et précision annexe.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reformulation'),

  ('11111111-b008-1000-0000-000000000009', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b008-4000-0000-000000000009',
   NULL, 'B1', 'CE',
   'Que doit envoyer Tomás au service comptabilité ?',
   'Khadija écrit : « Il manque toutefois le justificatif de votre nuit d''hôtel du 12 mai » et demande de le déposer ou d''en envoyer une photo « avant le 15 juin ». C''est un **repérage explicite de la pièce demandée**. La réponse A confond les documents : les billets de train « sont validés », ils ne manquent pas. La réponse B exagère la demande : la note de frais est bien reçue, **une seule pièce** fait défaut, inutile de tout refaire. La réponse D inverse le sens du remboursement : les 89 euros seront versés à Tomás par l''entreprise, ce n''est pas lui qui paie — piège d''inversion des rôles.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b008-1000-0000-00000000000a', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b008-4000-0000-00000000000a',
   NULL, 'B1', 'CE',
   'Pourquoi Aminata écrit-elle à Mariam ?',
   'Aminata annonce : « Le poste de coordinatrice du service client sera libre en septembre… j''aimerais vous le proposer ». La bonne réponse **reformule cette proposition d''évolution professionnelle**. La réponse B confond les personnes : c''est M. Lefort qui quitte son poste, pas Aminata — piège de confusion entre deux acteurs du texte. La réponse C contredit « Il ne s''agit pas d''une décision à prendre aujourd''hui » : Mariam a le temps de réfléchir avant l''entretien. La réponse D déforme le statut de la formation : au **conditionnel** (« s''accompagnerait »), elle dépend de l''acceptation du poste, ce n''est pas une inscription imposée.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reformulation');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  -- Q01 — réunion déplacée (bonne réponse : position 2)
  ('11111111-b008-2100-0000-000000000001', '11111111-b008-1000-0000-000000000001',
   'La réunion est annulée à cause d''un audit',
   'false', '1'),
  ('11111111-b008-2200-0000-000000000001', '11111111-b008-1000-0000-000000000001',
   'Elle aura lieu mardi matin en salle Lumière',
   'true', '2'),
  ('11111111-b008-2300-0000-000000000001', '11111111-b008-1000-0000-000000000001',
   'Elle se tiendra jeudi en salle Vauban, comme prévu',
   'false', '3'),
  ('11111111-b008-2400-0000-000000000001', '11111111-b008-1000-0000-000000000001',
   'Son ordre du jour a été entièrement modifié',
   'false', '4'),

  -- Q02 — remplacement samedi (bonne réponse : position 4)
  ('11111111-b008-2100-0000-000000000002', '11111111-b008-1000-0000-000000000002',
   'De remplacer Karol pendant toute la semaine',
   'false', '1'),
  ('11111111-b008-2200-0000-000000000002', '11111111-b008-1000-0000-000000000002',
   'De venir obligatoirement travailler samedi matin',
   'false', '2'),
  ('11111111-b008-2300-0000-000000000002', '11111111-b008-1000-0000-000000000002',
   'D''organiser elle-même le planning avec Bilal',
   'false', '3'),
  ('11111111-b008-2400-0000-000000000002', '11111111-b008-1000-0000-000000000002',
   'De travailler samedi matin en échange d''une matinée de repos',
   'true', '4'),

  -- Q03 — maintenance informatique (bonne réponse : position 1)
  ('11111111-b008-2100-0000-000000000003', '11111111-b008-1000-0000-000000000003',
   'Enregistrer leurs documents et fermer leur session',
   'true', '1'),
  ('11111111-b008-2200-0000-000000000003', '11111111-b008-1000-0000-000000000003',
   'Éteindre obligatoirement leur poste de travail',
   'false', '2'),
  ('11111111-b008-2300-0000-000000000003', '11111111-b008-1000-0000-000000000003',
   'Installer eux-mêmes les mises à jour',
   'false', '3'),
  ('11111111-b008-2400-0000-000000000003', '11111111-b008-1000-0000-000000000003',
   'Appeler l''assistance au poste 4512',
   'false', '4'),

  -- Q04 — relecture des chiffres (bonne réponse : position 3)
  ('11111111-b008-2100-0000-000000000004', '11111111-b008-1000-0000-000000000004',
   'De corriger la mise en page de la présentation',
   'false', '1'),
  ('11111111-b008-2200-0000-000000000004', '11111111-b008-1000-0000-000000000004',
   'D''envoyer la présentation au client mercredi matin',
   'false', '2'),
  ('11111111-b008-2300-0000-000000000004', '11111111-b008-1000-0000-000000000004',
   'De contrôler les chiffres de quelques pages du document',
   'true', '3'),
  ('11111111-b008-2400-0000-000000000004', '11111111-b008-1000-0000-000000000004',
   'De relire l''ensemble du document avant mardi',
   'false', '4'),

  -- Q05 — congés de Bogdan (bonne réponse : position 1)
  ('11111111-b008-2100-0000-000000000005', '11111111-b008-1000-0000-000000000005',
   'Ses congés sont acceptés en partie ; il doit déplacer une semaine',
   'true', '1'),
  ('11111111-b008-2200-0000-000000000005', '11111111-b008-1000-0000-000000000005',
   'Toute sa demande de congés est refusée',
   'false', '2'),
  ('11111111-b008-2300-0000-000000000005', '11111111-b008-1000-0000-000000000005',
   'Il est obligé de prendre sa semaine de congés fin août',
   'false', '3'),
  ('11111111-b008-2400-0000-000000000005', '11111111-b008-1000-0000-000000000005',
   'Trois semaines de congés supplémentaires lui sont proposées',
   'false', '4'),

  -- Q06 — formation reportée (bonne réponse : position 3)
  ('11111111-b008-2100-0000-000000000006', '11111111-b008-1000-0000-000000000006',
   'Rien : leur inscription est conservée automatiquement',
   'false', '1'),
  ('11111111-b008-2200-0000-000000000006', '11111111-b008-1000-0000-000000000006',
   'Attendre la publication des dates de septembre',
   'false', '2'),
  ('11111111-b008-2300-0000-000000000006', '11111111-b008-1000-0000-000000000006',
   'S''inscrire de nouveau sur l''intranet avant le 16 juin',
   'true', '3'),
  ('11111111-b008-2400-0000-000000000006', '11111111-b008-1000-0000-000000000006',
   'Contacter directement le formateur de la session',
   'false', '4'),

  -- Q07 — premier jour de Diego (bonne réponse : position 2)
  ('11111111-b008-2100-0000-000000000007', '11111111-b008-1000-0000-000000000007',
   'Aller signer son contrat au bâtiment A',
   'false', '1'),
  ('11111111-b008-2200-0000-000000000007', '11111111-b008-1000-0000-000000000007',
   'Se présenter à l''accueil du bâtiment B avec une pièce d''identité',
   'true', '2'),
  ('11111111-b008-2300-0000-000000000007', '11111111-b008-1000-0000-000000000007',
   'Configurer lui-même son ordinateur de travail',
   'false', '3'),
  ('11111111-b008-2400-0000-000000000007', '11111111-b008-1000-0000-000000000007',
   'Récupérer son badge au service des ressources humaines',
   'false', '4'),

  -- Q08 — tableau de synthèse pour Yusuf (bonne réponse : position 4)
  ('11111111-b008-2100-0000-000000000008', '11111111-b008-1000-0000-000000000008',
   'Le rapport complet prévu pour le mois de septembre',
   'false', '1'),
  ('11111111-b008-2200-0000-000000000008', '11111111-b008-1000-0000-000000000008',
   'Une présentation orale lors de la réunion de lundi',
   'false', '2'),
  ('11111111-b008-2300-0000-000000000008', '11111111-b008-1000-0000-000000000008',
   'La liste détaillée des chiffres encore manquants',
   'false', '3'),
  ('11111111-b008-2400-0000-000000000008', '11111111-b008-1000-0000-000000000008',
   'Un tableau d''une page résumant les ventes du trimestre',
   'true', '4'),

  -- Q09 — note de frais de Tomás (bonne réponse : position 3)
  ('11111111-b008-2100-0000-000000000009', '11111111-b008-1000-0000-000000000009',
   'Ses billets de train pour le déplacement à Lyon',
   'false', '1'),
  ('11111111-b008-2200-0000-000000000009', '11111111-b008-1000-0000-000000000009',
   'Une nouvelle note de frais entièrement refaite',
   'false', '2'),
  ('11111111-b008-2300-0000-000000000009', '11111111-b008-1000-0000-000000000009',
   'Le justificatif de sa nuit d''hôtel du 12 mai',
   'true', '3'),
  ('11111111-b008-2400-0000-000000000009', '11111111-b008-1000-0000-000000000009',
   'Un remboursement de 89 euros à l''entreprise',
   'false', '4'),

  -- Q10 — proposition d''Aminata (bonne réponse : position 1)
  ('11111111-b008-2100-0000-00000000000a', '11111111-b008-1000-0000-00000000000a',
   'Pour lui proposer un poste de coordinatrice à partir de septembre',
   'true', '1'),
  ('11111111-b008-2200-0000-00000000000a', '11111111-b008-1000-0000-00000000000a',
   'Pour lui annoncer son propre départ de l''agence',
   'false', '2'),
  ('11111111-b008-2300-0000-00000000000a', '11111111-b008-1000-0000-00000000000a',
   'Pour exiger une réponse immédiate à sa proposition',
   'false', '3'),
  ('11111111-b008-2400-0000-00000000000a', '11111111-b008-1000-0000-00000000000a',
   'Pour l''inscrire d''office à une formation à Nantes',
   'false', '4');

-- ============================================================================
-- CHECKLIST — contrôles passés
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes (11111111-b008-1000/4000/21..2400-…-NN, NN=01..0a).
-- [x] Support unique : courriel professionnel simple (10 expéditeurs et
--     situations toutes différentes : réunion déplacée, remplacement samedi,
--     maintenance informatique, relecture de chiffres, congés partiellement
--     acceptés, formation reportée, accueil premier jour, tableau de synthèse,
--     note de frais incomplète, proposition d''évolution de poste). Aucun
--     support réservé à un autre lot (pas d''e-mail personnel, de note
--     d''information, de message administratif, etc.).
-- [x] Passages TEXTE ~60-120 mots, mise en forme courriel pro (objet,
--     salutation, corps, formule de politesse, signature + fonction),
--     media_id NULL.
-- [x] 4 propositions / 1 correcte par item. Distribution des bonnes réponses :
--     pos1:3, pos2:2, pos3:3, pos4:2 (max 3 par position, 4 positions utilisées).
-- [x] competence_code : ce_reperage_explicite x4 (Q1, Q3, Q7, Q9),
--     ce_inference_intention x3 (Q2, Q5, Q6), ce_reformulation x3 (Q4, Q8, Q10).
-- [x] explanation ≥ 80 caractères : bonne réponse justifiée + les 3 distracteurs
--     expliqués, point clé en **gras**, mécanisme linguistique nommé (repérage
--     explicite, inférence simple, connecteur « donc », suggestion vs
--     obligation, conditionnel, sur-généralisation, inversion des rôles…).
-- [x] Pas de SVG ni SSML dans ce lot (supports textuels uniquement) — rien à
--     équilibrer.
-- [x] Apostrophes SQL doublées partout, contenu 100% original, items autonomes.
-- ============================================================================
