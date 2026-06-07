-- ============================================================================
-- V711 — TCF EE T2 — lot 01 (10 nouveaux sujets)
-- ----------------------------------------------------------------------------
-- TCF Expression écrite (EE) — Tâche 2 : récit d''une expérience (40-90 mots).
-- 10 sujets originaux (4 A2 / 3 B1 / 3 B2). Table production_tasks uniquement.
-- Mise en situation portée par la colonne contexte (pas de colonne declencheur).
-- UUID déterministes 77777777-e201-1000-0000-0000000000NN (NN = 01..0a).
-- ============================================================================

INSERT INTO production_tasks
  (id, epreuve, tache_numero, niveau_cible, consigne, contexte, duree_max_sec, mots_min,
   mots_max, is_active, created_at, duree_min_sec)
VALUES
  -- 01 — un mariage (A2)
  ('77777777-e201-1000-0000-000000000001', 'TCF_EE', '2', 'A2',
   'Racontez ce mariage : quand c''était, où, qui se mariait, ce que vous avez fait pendant la fête, et ce que vous avez préféré.',
   'Votre amie Fatou vous écrit : « Coucou ! Tu étais au mariage de ta cousine le week-end dernier, non ? Raconte-moi, je veux tout savoir ! »',
   NULL, '40', '90', 'true', '2026-06-07 12:00:00+02', NULL),

  -- 02 — un voyage (B1)
  ('77777777-e201-1000-0000-000000000002', 'TCF_EE', '2', 'B1',
   'Racontez ce voyage : où vous êtes allé, avec qui, comment c''était sur place, un moment qui vous a marqué, et ce que vous avez ressenti en rentrant.',
   'Votre ami Diego vous envoie ce message : « Alors, ce voyage à Marseille ? Tu en rêvais depuis des mois ! Comment ça s''est passé ? »',
   NULL, '40', '90', 'true', '2026-06-07 12:00:00+02', NULL),

  -- 03 — un premier jour de travail (B2)
  ('77777777-e201-1000-0000-000000000003', 'TCF_EE', '2', 'B2',
   'Racontez votre premier jour dans ce nouveau travail : ce que vous imaginiez avant, comment la journée s''est réellement déroulée, ce qui vous a surpris, et ce que cette expérience vous a appris sur vous-même.',
   'Votre amie Olena vous écrit : « Ça y est, tu as commencé ton nouveau poste à la clinique de Nantes ! Alors, cette première journée ? J''attends ton récit avec impatience. »',
   NULL, '40', '90', 'true', '2026-06-07 12:00:00+02', NULL),

  -- 04 — une rencontre marquante (B2)
  ('77777777-e201-1000-0000-000000000004', 'TCF_EE', '2', 'B2',
   'Racontez cette rencontre : dans quelles circonstances elle a eu lieu, qui était cette personne, ce qui vous a frappé chez elle, et en quoi elle a changé votre façon de voir les choses.',
   'Sur un groupe d''anciens élèves de votre cours de français, Wei lance une discussion : « On dit qu''une seule rencontre peut changer une vie. Racontez-nous une rencontre qui vous a marqués. »',
   NULL, '40', '90', 'true', '2026-06-07 12:00:00+02', NULL),

  -- 05 — un week-end (A2)
  ('77777777-e201-1000-0000-000000000005', 'TCF_EE', '2', 'A2',
   'Racontez votre week-end : où vous étiez, avec qui, ce que vous avez fait samedi et dimanche, et si vous avez passé un bon moment.',
   'Votre collègue Priya vous écrit lundi matin : « Salut ! Tu as l''air en pleine forme aujourd''hui. Qu''est-ce que tu as fait ce week-end ? Raconte ! »',
   NULL, '40', '90', 'true', '2026-06-07 12:00:00+02', NULL),

  -- 06 — un déménagement (A2)
  ('77777777-e201-1000-0000-000000000006', 'TCF_EE', '2', 'A2',
   'Racontez votre déménagement : quand vous avez déménagé, qui vous a aidé, comment la journée s''est passée, et comment vous vous sentez dans votre nouveau logement.',
   'Votre ami Rachid vous envoie ce message : « Alors, tu as enfin déménagé dans ton nouvel appartement à Lille ? Comment ça s''est passé ? »',
   NULL, '40', '90', 'true', '2026-06-07 12:00:00+02', NULL),

  -- 07 — un imprévu drôle (B1)
  ('77777777-e201-1000-0000-000000000007', 'TCF_EE', '2', 'B1',
   'Racontez cet imprévu : où vous étiez, ce qui devait se passer normalement, ce qui est arrivé à la place, comment vous avez réagi, et pourquoi cela vous fait rire aujourd''hui.',
   'Votre amie Lucia vous écrit : « Hier tu m''as dit qu''il t''était arrivé un truc trop drôle au supermarché, mais tu n''as pas eu le temps de finir l''histoire. Raconte-moi tout ! »',
   NULL, '40', '90', 'true', '2026-06-07 12:00:00+02', NULL),

  -- 08 — une sortie culturelle (B1)
  ('77777777-e201-1000-0000-000000000008', 'TCF_EE', '2', 'B1',
   'Racontez cette sortie : ce que vous êtes allé voir, avec qui, comment s''est déroulée la visite ou le spectacle, ce qui vous a plu ou déçu, et si vous le recommanderiez.',
   'Votre ami Amadou vous envoie ce message : « Tu m''as dit que tu allais à une expo ou un concert ce mois-ci, c''est fait ? Ça valait le coup ? Raconte, j''hésite à y aller aussi. »',
   NULL, '40', '90', 'true', '2026-06-07 12:00:00+02', NULL),

  -- 09 — une réussite personnelle (B2)
  ('77777777-e201-1000-0000-000000000009', 'TCF_EE', '2', 'B2',
   'Racontez cette réussite : quel était votre objectif, les obstacles que vous avez rencontrés, comment vous les avez surmontés, et le regard que vous portez aujourd''hui sur ce parcours.',
   'Sur le forum de votre association de quartier, on vous propose ce thème du mois : « Une réussite dont vous êtes fier : un diplôme, un permis, un défi sportif, un projet abouti... Partagez votre histoire. »',
   NULL, '40', '90', 'true', '2026-06-07 12:00:00+02', NULL),

  -- 0a — une journée spéciale (A2)
  ('77777777-e201-1000-0000-00000000000a', 'TCF_EE', '2', 'A2',
   'Racontez cette journée spéciale : quel jour c''était, pourquoi elle était importante, ce que vous avez fait du matin au soir, et ce que vous avez ressenti.',
   'Votre amie Yuki vous écrit : « Tu m''as dit que jeudi dernier était un jour très important pour toi. Qu''est-ce qui s''est passé ? Raconte-moi cette journée ! »',
   NULL, '40', '90', 'true', '2026-06-07 12:00:00+02', NULL);

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes 77777777-e201-1000-0000-0000000000{01..0a},
--     tous uniques, un thème par sujet (mariage, voyage, premier jour de
--     travail, rencontre marquante, week-end, déménagement, imprévu drôle,
--     sortie culturelle, réussite personnelle, journée spéciale).
-- [x] niveau_cible : 4 A2 (01, 05, 06, 0a) / 3 B1 (02, 07, 08) / 3 B2 (03, 04, 09).
--     Gradation respectée : A2 = succession d''actions simples ; B1 = récit
--     structuré + ressenti ; B2 = récit avec recul, surprise et analyse.
-- [x] Schéma identique à l''exemplaire V710 : epreuve='TCF_EE', tache_numero='2',
--     mots_min='40', mots_max='90', duree_max_sec=NULL, duree_min_sec=NULL,
--     is_active='true', created_at '2026-06-07 12:00:00+02'. Pas de colonne
--     declencheur : mise en situation portée par contexte.
-- [x] Aucun recoupement avec les sujets existants (restaurant/fête, expérience
--     d''apprentissage sur soi, décision difficile) ni avec les thèmes réservés
--     au lot 02.
-- [x] Distribution des bonnes réponses : n/a (sujets de production, pas de QCM).
-- [x] SVG / SSML : n/a (épreuve écrite, aucun média).
-- [x] Apostrophes SQL doublées partout ; contenu 100 % original ; prénoms et
--     villes variés (Fatou, Diego, Olena, Wei, Priya, Rachid, Lucia, Amadou,
--     Yuki ; Marseille, Nantes, Lille) ; situations toutes différentes.
-- ============================================================================
