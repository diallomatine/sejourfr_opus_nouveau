-- ============================================================================
-- V701 — TCF EE T1 — lot 01 (10 nouveaux sujets)
-- ----------------------------------------------------------------------------
-- Expression écrite, Tâche 1 : message court à un proche (30-60 mots).
-- Table production_tasks uniquement. 10 sujets, niveaux 4×A2 / 3×B1 / 3×B2.
-- Thèmes : inviter · décliner une invitation · bonne nouvelle · décrire une
-- personne · demander un service · féliciter · remercier · donner de ses
-- nouvelles · proposer un rendez-vous · répondre à une demande d''information.
-- UUID déterministes 77777777-e101-1000-0000-0000000000NN (NN = 01..0a).
-- ============================================================================

INSERT INTO production_tasks
  (id, epreuve, tache_numero, niveau_cible, consigne, contexte, duree_max_sec, mots_min,
   mots_max, is_active, created_at, duree_min_sec)
VALUES
  -- 01 — A2 — inviter
  ('77777777-e101-1000-0000-000000000001', 'TCF_EE', '1', 'A2',
   'Écrivez un message à Fatou pour l''inviter à ce pique-nique : indiquez le lieu et l''heure, et demandez-lui d''apporter quelque chose à partager.',
   'Vous organisez un pique-nique au parc des Cerisiers samedi midi avec quelques amis. Vous voulez inviter votre amie Fatou.',
   NULL, '30', '60', 'true', '2026-06-07 12:00:00+02', NULL),

  -- 02 — B2 — décliner poliment une invitation
  ('77777777-e101-1000-0000-000000000002', 'TCF_EE', '1', 'B2',
   'Répondez à Wei pour décliner son invitation avec tact : exprimez votre regret, expliquez la raison de votre absence et proposez-lui un autre moment pour marquer l''occasion ensemble.',
   'Votre collègue Wei vous a écrit : « Salut ! Je fête mes dix ans dans l''entreprise vendredi soir au restaurant Le Vieux Moulin, tu viens ? ». Vous avez déjà un engagement ce soir-là.',
   NULL, '30', '60', 'true', '2026-06-07 12:00:00+02', NULL),

  -- 03 — A2 — annoncer une bonne nouvelle
  ('77777777-e101-1000-0000-000000000003', 'TCF_EE', '1', 'A2',
   'Écrivez un message à votre frère Amadou pour lui annoncer la nouvelle : dites quel est ce travail, exprimez votre joie et proposez de fêter cela ensemble.',
   'Après plusieurs mois de recherche, vous venez de trouver un travail de cuisinier dans un restaurant de Nantes. Vous voulez l''annoncer à votre frère Amadou.',
   NULL, '30', '60', 'true', '2026-06-07 12:00:00+02', NULL),

  -- 04 — A2 — décrire une personne
  ('77777777-e101-1000-0000-000000000004', 'TCF_EE', '1', 'A2',
   'Répondez à Lucia : décrivez votre collègue (son apparence, son caractère) et dites ce que vous aimez faire avec elle pendant les pauses.',
   'Votre amie Lucia vous a écrit : « Alors, cette nouvelle collègue de bureau, elle est comment ? Raconte ! ».',
   NULL, '30', '60', 'true', '2026-06-07 12:00:00+02', NULL),

  -- 05 — B1 — demander un service
  ('77777777-e101-1000-0000-000000000005', 'TCF_EE', '1', 'B1',
   'Écrivez un message à Rachid pour lui demander d''arroser vos plantes et de relever votre courrier pendant votre absence : expliquez la situation et proposez-lui de lui rendre la pareille à son retour de vacances.',
   'Vous partez une semaine à Lyon pour une formation professionnelle. Votre voisin Rachid, avec qui vous vous entendez bien, reste chez lui cette semaine-là.',
   NULL, '30', '60', 'true', '2026-06-07 12:00:00+02', NULL),

  -- 06 — B1 — féliciter quelqu''un
  ('77777777-e101-1000-0000-000000000006', 'TCF_EE', '1', 'B1',
   'Écrivez un message à Olena pour la féliciter : rappelez un moment difficile qu''elle a surmonté pendant ses études et souhaitez-lui une belle réussite pour son premier poste.',
   'Votre amie Olena vient d''obtenir son diplôme d''infirmière après trois années d''études en travaillant le soir dans une boulangerie.',
   NULL, '30', '60', 'true', '2026-06-07 12:00:00+02', NULL),

  -- 07 — A2 — remercier
  ('77777777-e101-1000-0000-000000000007', 'TCF_EE', '1', 'A2',
   'Écrivez un message à Diego pour le remercier : dites pourquoi son vélo vous a été utile et indiquez quand vous allez le lui rapporter.',
   'Votre vélo était en réparation toute la semaine. Votre ami Diego vous a prêté le sien pour aller au travail.',
   NULL, '30', '60', 'true', '2026-06-07 12:00:00+02', NULL),

  -- 08 — B1 — donner de ses nouvelles
  ('77777777-e101-1000-0000-000000000008', 'TCF_EE', '1', 'B1',
   'Répondez à Priya : donnez de vos nouvelles (votre travail, vos activités, un changement récent dans votre vie) et posez-lui une question sur sa vie à Montréal.',
   'Votre cousine Priya, qui vit à Montréal, vous a écrit : « Ça fait des mois que je n''ai pas de nouvelles ! Quoi de neuf chez toi ? ».',
   NULL, '30', '60', 'true', '2026-06-07 12:00:00+02', NULL),

  -- 09 — B2 — proposer un rendez-vous
  ('77777777-e101-1000-0000-000000000009', 'TCF_EE', '1', 'B2',
   'Écrivez un message à Nadia pour lui proposer un rendez-vous : reconnaissez que son emploi du temps est chargé, suggérez deux créneaux précis et exprimez votre envie sincère de la revoir.',
   'Cela fait deux mois que vous essayez de voir votre amie Nadia, mais vos horaires de travail décalés rendent chaque tentative impossible. Vous voulez enfin fixer un moment qui lui convienne.',
   NULL, '30', '60', 'true', '2026-06-07 12:00:00+02', NULL),

  -- 10 — B2 — répondre à une demande d''information
  ('77777777-e101-1000-0000-00000000000a', 'TCF_EE', '1', 'B2',
   'Répondez à Tomás : donnez un avis nuancé sur le cours, expliquez la démarche d''inscription (tarif, horaire) et signalez-lui un point auquel il devra faire attention.',
   'Votre ami Tomás vous a écrit : « J''ai entendu dire que tu suis un cours de théâtre le jeudi soir. C''est bien ? Comment on fait pour s''inscrire ? ».',
   NULL, '30', '60', 'true', '2026-06-07 12:00:00+02', NULL);

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes 77777777-e101-1000-0000-0000000000NN (01..0a),
--     tous uniques.
-- [x] Répartition niveau_cible : 4×A2 (01, 03, 04, 07) / 3×B1 (05, 06, 08) /
--     3×B2 (02, 09, 10), gradation effective (concret quotidien → nuances et
--     relance → tact, registre, concession).
-- [x] Un sujet par thème imposé, dans l''ordre du bon de commande ; aucun
--     recouvrement avec les sujets existants (emménagement, événement de
--     quartier, réclamation) ni avec les thèmes réservés au lot 02.
-- [x] Schéma conforme à l''exemplaire V700 : mêmes colonnes, même ordre ;
--     contexte = mise en situation / message reçu, consigne = tâche (2-3 actions).
-- [x] epreuve='TCF_EE', tache_numero=1, mots_min=30, mots_max=60,
--     duree_max_sec=NULL, duree_min_sec=NULL, is_active=true,
--     created_at='2026-06-07 12:00:00+02'.
-- [x] Apostrophes SQL doublées partout ; SQL valide.
-- [x] Distribution des bonnes réponses : N/A (production_tasks, pas de QCM).
-- [x] SVG/SSML : N/A (épreuve écrite, aucun média).
-- [x] Contenu 100 % original ; situations toutes différentes ; prénoms variés
--     (Fatou, Wei, Amadou, Lucia, Rachid, Olena, Diego, Priya, Nadia, Tomás).
-- ============================================================================
