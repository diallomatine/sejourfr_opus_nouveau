-- ============================================================================
-- V752 — TCF EO T3 — lot 02 (7 nouveaux sujets)
-- ----------------------------------------------------------------------------
-- Tâche 3 : exprimer ses goûts / opinions (monologue oral, 3 min 30).
-- 7 sujets : 3×A2, 2×B1, 2×B2. Table production_tasks uniquement.
-- A2 = position + 2 raisons + exemple ; B1 = arguments illustrés + concession ;
-- B2 = thèse nuancée + objection anticipée et discutée.
-- Thèmes : tourisme · technologies et IA · gestes pour l'environnement ·
-- vie associative · équilibre vie pro/perso · habiter seul ou en famille ·
-- cuisine de son pays vs cuisine locale.
-- UUID déterministes : 88888888-3002-1000-0000-0000000000NN (NN = 01..07).
-- ============================================================================

INSERT INTO production_tasks
  (id, epreuve, tache_numero, niveau_cible, consigne, contexte, duree_max_sec, mots_min,
   mots_max, is_active, created_at, duree_min_sec)
VALUES
  -- 01 · B1 · le tourisme
  ('88888888-3002-1000-0000-000000000001', 'TCF_EO', '3', 'B1',
   'Chaque été, certains quartiers et certains villages reçoivent beaucoup plus de touristes que d''habitants. Selon vous, le tourisme est-il une bonne chose pour les lieux qui le reçoivent ? Donnez votre avis avec au moins deux arguments illustrés par des exemples (un lieu que vous avez visité, votre propre ville), puis reconnaissez un inconvénient du tourisme pour les habitants.',
   NULL,
   '210', NULL, NULL, 'true', '2026-06-07 12:00:00+02', '120'),

  -- 02 · B2 · les technologies et l'IA au quotidien
  ('88888888-3002-1000-0000-000000000002', 'TCF_EO', '3', 'B2',
   'Les assistants d''intelligence artificielle écrivent désormais des lettres, traduisent des documents et répondent à nos questions à notre place. Pensez-vous que cette aide quotidienne nous rend plus efficaces ou progressivement plus dépendants ? Défendez une position nuancée, anticipez l''objection d''une personne convaincue du contraire — par exemple votre collègue Wei, qui utilise l''IA pour tout — et répondez-y avant de conclure.',
   NULL,
   '210', NULL, NULL, 'true', '2026-06-07 12:00:00+02', '120'),

  -- 03 · A2 · les gestes pour l'environnement
  ('88888888-3002-1000-0000-000000000003', 'TCF_EO', '3', 'A2',
   'Que faites-vous pour protéger l''environnement dans votre vie de tous les jours ? Présentez deux gestes que vous faites (trier les déchets, économiser l''eau, marcher au lieu de prendre la voiture...), expliquez pourquoi ils sont importants pour vous et donnez un exemple précis de votre quotidien.',
   NULL,
   '210', NULL, NULL, 'true', '2026-06-07 12:00:00+02', '120'),

  -- 04 · B1 · la vie associative
  ('88888888-3002-1000-0000-000000000004', 'TCF_EO', '3', 'B1',
   'Dans de nombreuses villes, des bénévoles donnent de leur temps dans des associations : aide aux devoirs, distribution de repas, clubs de sport ou de quartier. Selon vous, est-il important de s''engager dans une association ? Donnez votre avis avec au moins deux arguments illustrés par des exemples (une association que vous connaissez, une expérience de bénévolat, l''histoire d''une personne comme votre voisine Fatou), puis admettez une difficulté que rencontrent les bénévoles.',
   NULL,
   '210', NULL, NULL, 'true', '2026-06-07 12:00:00+02', '120'),

  -- 05 · B2 · l'équilibre vie professionnelle / vie personnelle
  ('88888888-3002-1000-0000-000000000005', 'TCF_EO', '3', 'B2',
   'Certains salariés répondent à leurs messages professionnels le soir et pendant leurs congés ; d''autres estiment qu''une fois la journée terminée, le travail doit attendre le lendemain. Selon vous, faut-il séparer strictement la vie professionnelle de la vie personnelle, ou une certaine souplesse est-elle préférable ? Défendez une thèse nuancée, envisagez l''objection d''une personne dont le métier exige une grande disponibilité (un médecin, un commerçant, un parent entrepreneur comme Diego) et discutez-la avant de conclure.',
   NULL,
   '210', NULL, NULL, 'true', '2026-06-07 12:00:00+02', '120'),

  -- 06 · A2 · habiter seul ou en famille
  ('88888888-3002-1000-0000-000000000006', 'TCF_EO', '3', 'A2',
   'Préférez-vous habiter seul ou avec votre famille ? Donnez votre choix, expliquez deux raisons (la liberté, la compagnie, le partage des tâches, le prix du logement...) et racontez un moment de votre vie quotidienne qui montre pourquoi vous préférez cette façon d''habiter.',
   NULL,
   '210', NULL, NULL, 'true', '2026-06-07 12:00:00+02', '120'),

  -- 07 · A2 · la cuisine de son pays et la cuisine locale
  ('88888888-3002-1000-0000-000000000007', 'TCF_EO', '3', 'A2',
   'Préférez-vous manger les plats de votre pays d''origine ou découvrir la cuisine du pays où vous vivez ? Dites votre préférence, donnez deux raisons et décrivez un plat précis que vous aimez : ses ingrédients, quand vous le mangez et avec qui.',
   NULL,
   '210', NULL, NULL, 'true', '2026-06-07 12:00:00+02', '120');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 7 sujets, UUID déterministes 88888888-3002-1000-0000-0000000000NN (01..07).
-- [x] niveau_cible : 3×A2 (03, 06, 07), 2×B1 (01, 04), 2×B2 (02, 05).
-- [x] Calibration : A2 = position + 2 raisons + exemple ; B1 = arguments
--     illustrés + concession ; B2 = thèse nuancée + objection anticipée et
--     discutée.
-- [x] epreuve='TCF_EO', tache_numero=3, duree_max_sec=210, duree_min_sec=120,
--     mots_min/mots_max NULL, is_active=true, created_at 2026-06-07 12:00:00+02.
-- [x] 1 sujet par thème imposé : tourisme (01), technologies/IA (02),
--     gestes environnement (03), vie associative (04), équilibre pro/perso (05),
--     habiter seul ou en famille (06), cuisine du pays vs locale (07).
-- [x] Aucun doublon avec l'existant (transport préféré, réseaux sociaux,
--     télétravail) ni avec les 10 thèmes du lot 01 (V751).
-- [x] Distribution des bonnes réponses : N/A (sujets de production, pas de QCM).
-- [x] SVG/SSML : N/A (aucun media dans production_tasks).
-- [x] Contenu 100 % original ; prénoms variés (Wei, Fatou, Diego) ;
--     apostrophes SQL doublées ; consignes autonomes.
-- ============================================================================
