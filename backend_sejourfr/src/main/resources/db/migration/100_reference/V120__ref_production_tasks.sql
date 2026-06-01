-- ============================================================================
-- V120 — Référence : sujets EO/EE (production_tasks)
-- ----------------------------------------------------------------------------
-- Table production_tasks (sans criteres_evaluation, supprimée). 18 sujets EO/EE.
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
   NULL, '30', '60', 'true', '2026-05-27 17:09:16.06608+02', NULL),

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
   NULL, '40', '90', 'true', '2026-05-27 17:09:16.06608+02', NULL),

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
   NULL, '40', '90', 'true', '2026-05-27 17:09:16.06608+02', NULL),

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
   '180', NULL, NULL, 'true', '2026-05-27 17:09:16.06608+02', '120'),

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
   '210', NULL, NULL, 'true', '2026-05-27 17:09:16.06608+02', '120'),

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
