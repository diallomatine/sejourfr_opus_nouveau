-- ============================================================================
-- V702 — TCF Expression écrite (EE) — Tâche 2 : sujets (production_tasks)
-- ----------------------------------------------------------------------------
-- 3 sujets (A2 / B1 / B2). Table production_tasks.
-- Données régénérées depuis l'état final (déterministe, rejouable dev+recette).
-- ============================================================================

INSERT INTO production_tasks
  (id, epreuve, tache_numero, niveau_cible, consigne, contexte, duree_max_sec, mots_min,
   mots_max, is_active, created_at, duree_min_sec)
VALUES
  ('85ae18b5-b014-426f-a15a-059cae856f8d', 'TCF_EE', '2', 'A2',
   'Racontez la dernière fois que vous êtes allé au restaurant ou à une fête : quand c''était, avec qui, ce que vous avez mangé ou fait, et si vous avez aimé ou non.',
   NULL,
   NULL, '40', '90', 'true', '2026-05-27 17:09:16.06608+02', NULL),

  ('89436b56-7ebb-4ee9-8504-7677fe1164fe', 'TCF_EE', '2', 'B1',
   'Racontez une expérience qui vous a appris quelque chose d''important sur vous-même (un voyage, une rencontre, un travail, un échec...). Décrivez le contexte, ce qui s''est passé, et ce que vous en avez retenu.',
   NULL,
   NULL, '40', '90', 'true', '2026-05-27 17:09:16.06608+02', NULL),

  ('08e3acd5-c88e-4ba3-8166-520862865128', 'TCF_EE', '2', 'B2',
   'Racontez une situation où vous avez dû prendre une décision difficile dont vous mesurez aujourd''hui les conséquences (un choix de carrière, une rupture, un déménagement, un engagement...). Décrivez le contexte, votre cheminement, et le regard que vous portez aujourd''hui sur ce choix.',
   NULL,
   NULL, '40', '90', 'true', '2026-05-27 17:09:16.06608+02', NULL);
