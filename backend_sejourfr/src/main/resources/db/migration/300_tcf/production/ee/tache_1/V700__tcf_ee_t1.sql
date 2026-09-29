-- ============================================================================
-- V700 — TCF Expression écrite (EE) — Tâche 1 : sujets (production_tasks)
-- ----------------------------------------------------------------------------
-- 3 sujets (A2 / B1 / B2). Table production_tasks.
-- Données régénérées depuis l'état final (déterministe, rejouable dev+recette).
-- ============================================================================

INSERT INTO production_tasks
  (id, epreuve, tache_numero, niveau_cible, consigne, contexte, duree_max_sec, mots_min,
   mots_max, is_active, created_at, duree_min_sec)
VALUES
  ('48b8be40-994f-4afb-b03c-b9a56b670cd1', 'TCF_EE', '1', 'A2',
   'Vous venez d''emménager dans un nouveau quartier. Écrivez un message à un ami pour lui annoncer la nouvelle, lui décrire brièvement votre nouveau logement, et l''inviter à venir vous voir un week-end.',
   NULL,
   NULL, '30', '60', 'true', '2026-05-27 17:09:16.06608+02', NULL),

  ('84941b89-6ec6-4ae6-91b9-0cc26a83e5df', 'TCF_EE', '1', 'B1',
   'Vous avez assisté à un événement marquant dans votre quartier (panne d''électricité, embouteillage exceptionnel, fête locale...). Écrivez un message à un proche pour lui raconter ce qui s''est passé et expliquer comment vous avez vécu la situation.',
   NULL,
   NULL, '30', '60', 'true', '2026-05-27 17:09:16.06608+02', NULL),

  ('26b5d842-04c6-46b6-92e2-c324a9c39490', 'TCF_EE', '1', 'B2',
   'Vous avez reçu un service de mauvaise qualité (restaurant, hôtel, service en ligne...). Écrivez un message courtois mais ferme au prestataire pour décrire ce qui ne vous a pas convenu, demander une compensation, et indiquer ce que vous attendez en retour.',
   NULL,
   NULL, '30', '60', 'true', '2026-05-27 17:09:16.06608+02', NULL);
