-- ============================================================================
-- V712 — TCF Expression orale (EO) — Tâche 2 : sujets (production_tasks)
-- ----------------------------------------------------------------------------
-- 3 sujets (A2 / B1 / B2). Table production_tasks.
-- Données régénérées depuis l'état final (déterministe, rejouable dev+recette).
-- ============================================================================

INSERT INTO production_tasks
  (id, epreuve, tache_numero, niveau_cible, consigne, contexte, duree_max_sec, mots_min,
   mots_max, is_active, created_at, duree_min_sec)
VALUES
  ('21b1b1d9-5411-49a8-99b7-9c18b1abd8b6', 'TCF_EO', '2', 'A2',
   'Vous êtes à la poste pour envoyer un colis à un ami en France. Demandez au guichetier le prix, le délai de livraison, et comment suivre le colis. Posez au moins 4 questions claires.',
   'Vous parlez avec l''examinateur qui joue le rôle du guichetier.',
   '210', NULL, NULL, 'true', '2026-05-27 17:09:16.06608+02', '120'),

  ('aafce71c-0b12-4945-8a28-02f5d0f2299f', 'TCF_EO', '2', 'B1',
   'Vous avez acheté un appareil électronique qui ne fonctionne pas correctement depuis sa livraison. Vous appelez le service après-vente pour expliquer le problème, demander une réparation ou un remboursement, et négocier un délai. Soyez clair et courtois.',
   'L''examinateur joue le conseiller du service après-vente.',
   '210', NULL, NULL, 'true', '2026-05-27 17:09:16.06608+02', '120'),

  ('67b1bc04-5275-4cc6-b6f3-df4f28c2a0aa', 'TCF_EO', '2', 'B2',
   'Vous postulez pour un emploi qui vous intéresse beaucoup mais pour lequel vous êtes un peu sous-qualifié sur un critère précis. Lors d''un entretien téléphonique, vous devez expliquer pourquoi vous restez un bon candidat, donner des exemples concrets de vos compétences, et proposer une voie de progression.',
   'L''examinateur joue le recruteur, plutôt réservé.',
   '210', NULL, NULL, 'true', '2026-05-27 17:09:16.06608+02', '120');
