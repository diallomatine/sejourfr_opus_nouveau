-- ============================================================================
-- V704 — TCF Expression écrite (EE) — Tâche 3 : sujets (production_tasks)
-- ----------------------------------------------------------------------------
-- 3 sujets (A2 / B1 / B2). Table production_tasks.
-- Données régénérées depuis l'état final (déterministe, rejouable dev+recette).
-- ============================================================================

INSERT INTO production_tasks
  (id, epreuve, tache_numero, niveau_cible, consigne, contexte, duree_max_sec, mots_min,
   mots_max, is_active, created_at, duree_min_sec)
VALUES
  ('7c323ad8-639f-4122-be5c-44badb65b010', 'TCF_EE', '3', 'A2',
   'Préférez-vous vivre en ville ou à la campagne ? Donnez votre opinion et expliquez deux raisons.',
   NULL,
   NULL, '40', '90', 'true', '2026-05-27 17:09:16.06608+02', NULL),

  ('67837e55-303b-437a-a513-e8f33125de06', 'TCF_EE', '3', 'B1',
   'Faut-il limiter le temps d''écran des enfants ? Donnez votre avis en défendant votre position avec deux arguments concrets et au moins un exemple personnel ou observé.',
   NULL,
   NULL, '40', '90', 'true', '2026-05-27 17:09:16.06608+02', NULL),

  ('525cc021-4103-4260-8c7b-695f152eea8b', 'TCF_EE', '3', 'B2',
   'L''intelligence artificielle va-t-elle améliorer ou dégrader la qualité de l''éducation dans les années à venir ? Défendez une position nuancée : exposez votre thèse, étayez-la avec au moins deux arguments, et envisagez explicitement une objection que vous discutez.',
   NULL,
   NULL, '40', '90', 'true', '2026-05-27 17:09:16.06608+02', NULL);
