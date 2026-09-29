-- ============================================================================
-- V712 — TCF EE T2 — lot 02 (7 nouveaux sujets)
-- ----------------------------------------------------------------------------
-- TCF Expression écrite (EE) — Tâche 2 : récit d''une expérience (40-90 mots).
-- 7 sujets originaux (3 A2 / 2 B1 / 2 B2). Table production_tasks uniquement.
-- Mise en situation portée par la colonne contexte (pas de colonne declencheur).
-- UUID déterministes 77777777-e202-1000-0000-0000000000NN (NN = 01..07).
-- ============================================================================

INSERT INTO production_tasks
  (id, epreuve, tache_numero, niveau_cible, consigne, contexte, duree_max_sec, mots_min,
   mots_max, is_active, created_at, duree_min_sec)
VALUES
  -- 01 — une découverte (A2)
  ('77777777-e202-1000-0000-000000000001', 'TCF_EE', '2', 'A2',
   'Racontez cette découverte : ce que vous avez découvert, où c''était, avec qui vous étiez, ce que vous avez fait, et si vous avez aimé.',
   'Votre amie Mariam vous écrit : « Tu m''as dit que tu avais goûté un plat que tu ne connaissais pas du tout chez tes voisins. C''était quoi ? Raconte-moi ! »',
   NULL, '40', '90', 'true', '2026-06-07 12:00:00+02', NULL),

  -- 02 — une fête de famille (A2)
  ('77777777-e202-1000-0000-000000000002', 'TCF_EE', '2', 'A2',
   'Racontez cette fête de famille : quelle était l''occasion, qui était présent, ce que vous avez mangé, ce que vous avez fait ensemble, et votre moment préféré.',
   'Votre ami Kofi vous envoie ce message : « Alors, cette grande fête chez tes grands-parents dimanche ? Toute la famille était là ? Raconte-moi comment ça s''est passé ! »',
   NULL, '40', '90', 'true', '2026-06-07 12:00:00+02', NULL),

  -- 03 — un objet perdu puis retrouvé (A2)
  ('77777777-e202-1000-0000-000000000003', 'TCF_EE', '2', 'A2',
   'Racontez cette histoire : quel objet vous avez perdu, où et quand, comment vous l''avez cherché, qui l''a retrouvé, et ce que vous avez ressenti à la fin.',
   'Votre amie Linh vous écrit : « Tu as retrouvé ton téléphone, c''est vrai ? Tu étais tellement inquiet hier ! Raconte-moi tout, j''ai eu peur pour toi. »',
   NULL, '40', '90', 'true', '2026-06-07 12:00:00+02', NULL),

  -- 04 — une panne ou un incident (B1)
  ('77777777-e202-1000-0000-000000000004', 'TCF_EE', '2', 'B1',
   'Racontez cet incident : où vous alliez et pourquoi, ce qui est tombé en panne, comment vous avez réagi, qui vous a aidé, et comment l''histoire s''est terminée.',
   'Votre ami Tomás vous envoie ce message : « On m''a dit que tu étais resté bloqué sur la route en allant à Bordeaux samedi ! Qu''est-ce qui s''est passé exactement ? Raconte ! »',
   NULL, '40', '90', 'true', '2026-06-07 12:00:00+02', NULL),

  -- 05 — un coup de main donné à quelqu''un (B1)
  ('77777777-e202-1000-0000-000000000005', 'TCF_EE', '2', 'B1',
   'Racontez ce moment : qui vous avez aidé, quel était son problème, ce que vous avez fait concrètement, comment la personne a réagi, et ce que cela vous a apporté.',
   'Votre amie Aïcha vous écrit : « La voisine du troisième m''a dit que tu l''avais beaucoup aidée la semaine dernière. Qu''est-ce que tu as fait pour elle ? Raconte-moi ! »',
   NULL, '40', '90', 'true', '2026-06-07 12:00:00+02', NULL),

  -- 06 — un souvenir d''enfance (B2)
  ('77777777-e202-1000-0000-000000000006', 'TCF_EE', '2', 'B2',
   'Racontez ce souvenir d''enfance : le contexte de l''époque, ce qui s''est passé, pourquoi ce moment est resté gravé dans votre mémoire, et le regard que vous portez sur lui aujourd''hui, adulte.',
   'Sur le forum de votre cours de français à Strasbourg, Pavlo lance le thème de la semaine : « On garde tous un souvenir d''enfance plus vif que les autres. Racontez le vôtre et dites pourquoi il compte encore. »',
   NULL, '40', '90', 'true', '2026-06-07 12:00:00+02', NULL),

  -- 07 — une première démarche administrative en France (B2)
  ('77777777-e202-1000-0000-000000000007', 'TCF_EE', '2', 'B2',
   'Racontez cette première démarche : ce que vous deviez obtenir, comment vous vous étiez préparé, les difficultés ou surprises rencontrées sur place, et ce que cette expérience vous a appris sur la vie en France.',
   'Votre amie Ingrid, qui vient d''arriver à Rennes, vous écrit : « Je dois faire ma première demande de titre de séjour et je suis stressée. Toi, comment s''était passée ta toute première démarche ici ? Raconte-moi, ça me rassurera. »',
   NULL, '40', '90', 'true', '2026-06-07 12:00:00+02', NULL);

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes 77777777-e202-1000-0000-0000000000{01..07},
--     tous uniques, un thème imposé par sujet (découverte, fête de famille,
--     objet perdu puis retrouvé, panne/incident, coup de main donné,
--     souvenir d''enfance, première démarche administrative en France).
-- [x] niveau_cible : 3 A2 (01, 02, 03) / 2 B1 (04, 05) / 2 B2 (06, 07).
--     Gradation respectée : A2 = succession d''actions concrètes + ressenti
--     simple ; B1 = récit structuré avec réaction et résolution ; B2 = récit
--     avec recul, mémoire/analyse et leçon tirée.
-- [x] Schéma identique à l''exemplaire V711 : epreuve='TCF_EE',
--     tache_numero='2', mots_min='40', mots_max='90', duree_max_sec=NULL,
--     duree_min_sec=NULL, is_active='true', created_at '2026-06-07 12:00:00+02'.
--     Pas de colonne declencheur : mise en situation portée par contexte.
-- [x] Aucun recoupement avec les sujets existants (restaurant/fête, expérience
--     d''apprentissage sur soi, décision difficile) ni avec les 10 thèmes du
--     lot 01 (mariage, voyage, premier jour de travail, rencontre marquante,
--     week-end, déménagement, imprévu drôle, sortie culturelle, réussite
--     personnelle, journée spéciale).
-- [x] Distribution des bonnes réponses : n/a (sujets de production, pas de QCM).
-- [x] SVG / SSML : n/a (épreuve écrite, aucun média).
-- [x] Apostrophes SQL doublées partout ; contenu 100 % original ; prénoms et
--     villes variés (Mariam, Kofi, Linh, Tomás, Aïcha, Pavlo, Ingrid ;
--     Bordeaux, Strasbourg, Rennes) ; situations toutes différentes.
-- ============================================================================
