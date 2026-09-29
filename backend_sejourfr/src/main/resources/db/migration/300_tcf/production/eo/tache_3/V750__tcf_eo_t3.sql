-- ============================================================================
-- V714 — TCF Expression orale (EO) — Tâche 3 : sujets (production_tasks)
-- ----------------------------------------------------------------------------
-- 3 sujets (A2 / B1 / B2). Table production_tasks.
-- Données régénérées depuis l'état final (déterministe, rejouable dev+recette).
-- ============================================================================

INSERT INTO production_tasks
  (id, epreuve, tache_numero, niveau_cible, consigne, contexte, duree_max_sec, mots_min,
   mots_max, is_active, created_at, duree_min_sec)
VALUES
  ('91d0f63c-3127-40ef-af9f-8e677910e59b', 'TCF_EO', '3', 'A2',
   'Quel est votre moyen de transport préféré pour vous déplacer dans une grande ville ? Donnez deux avantages et un inconvénient.',
   NULL,
   '210', NULL, NULL, 'true', '2026-05-27 17:09:16.06608+02', '120'),

  ('5e739a88-a418-49ad-a7f2-8266c899ad2a', 'TCF_EO', '3', 'B1',
   'Pensez-vous que les réseaux sociaux ont plus d''avantages ou plus d''inconvénients dans la vie quotidienne ? Donnez votre avis avec au moins deux arguments illustrés par des exemples.',
   NULL,
   '210', NULL, NULL, 'true', '2026-05-27 17:09:16.06608+02', '120'),

  ('f0fe3fcd-93b2-4f33-aa49-7ac040f04626', 'TCF_EO', '3', 'B2',
   'Certaines entreprises imposent le retour au bureau cinq jours par semaine, d''autres laissent la liberté totale aux salariés. Quelle organisation du travail vous semble la plus juste et la plus efficace ? Défendez votre position en envisageant au moins une objection que pourrait formuler quelqu''un en désaccord avec vous.',
   NULL,
   '210', NULL, NULL, 'true', '2026-05-27 17:09:16.06608+02', '120');
