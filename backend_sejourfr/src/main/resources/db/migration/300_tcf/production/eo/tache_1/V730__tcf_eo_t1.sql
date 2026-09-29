-- ============================================================================
-- V710 — TCF Expression orale (EO) — Tâche 1 : sujets (production_tasks)
-- ----------------------------------------------------------------------------
-- 3 sujets (A2 / B1 / B2). Table production_tasks.
-- Données régénérées depuis l'état final (déterministe, rejouable dev+recette).
-- ============================================================================

INSERT INTO production_tasks
  (id, epreuve, tache_numero, niveau_cible, consigne, contexte, duree_max_sec, mots_min,
   mots_max, is_active, created_at, duree_min_sec)
VALUES
  ('1e31fd83-af31-4d93-b103-c38856b254a4', 'TCF_EO', '1', 'A2',
   'Présentez-vous : votre nom, votre âge, votre nationalité, votre profession ou vos études, et la ville où vous habitez. Parlez aussi de votre famille (parents, frères, sœurs, conjoint, enfants).',
   NULL,
   '180', NULL, NULL, 'true', '2026-05-27 17:09:16.06608+02', '120'),

  ('2d1bea33-2ba8-4524-948c-89595c55fea6', 'TCF_EO', '1', 'B1',
   'Présentez-vous en développant : votre parcours scolaire ou professionnel, vos centres d''intérêt, et ce qui vous a amené en France (ou ce qui vous y attire si vous êtes à l''étranger).',
   NULL,
   '180', NULL, NULL, 'true', '2026-05-27 17:09:16.06608+02', '120'),

  ('6bf79a5c-7fe1-45c5-bc93-c638e33f86e4', 'TCF_EO', '1', 'B2',
   'Présentez-vous en mettant en avant un projet personnel ou professionnel qui vous tient particulièrement à cœur. Expliquez d''où il vient, ce qu''il représente pour vous, et ce que vous espérez en retirer.',
   NULL,
   '180', NULL, NULL, 'true', '2026-05-27 17:09:16.06608+02', '120');
