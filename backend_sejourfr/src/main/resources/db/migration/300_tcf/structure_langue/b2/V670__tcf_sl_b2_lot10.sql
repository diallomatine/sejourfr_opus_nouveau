-- ============================================================================
-- V670 — TCF SL B2 — lot 10 (point : prépositions fines (rection des verbes et adjectifs))
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id 22222222-0000-0000-0000-000000000003, difficulty='B2'.
-- 7 items, tous sur la rection des verbes et adjectifs (consister à, soucieux de,
-- se heurter à, se traduire par, susceptible de, veiller à, remédier à).
-- Contenu original, déterministe.
-- ============================================================================

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('33333333-c00a-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Le nouveau poste de Mei consiste ___ coordonner les équipes de nuit de l''entrepôt de Lyon. »',
   'La **rection du verbe « consister »** dépend de ce qui suit : devant un **infinitif**, on emploie « consister **à** » (consister à coordonner). « En » existe bien, mais uniquement devant un **nom** (le poste consiste en une série de contrôles). « De » est la rection d''autres verbes (s''occuper de, se charger de), jamais de « consister ». « Par » introduirait un moyen (commencer par), ce qui n''est pas la construction de « consister ».',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_prepositions_fines'),

  ('33333333-c00a-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Soucieuse ___ la qualité de l''air, la mairie de Nantes a remplacé ses quarante bus diesel. »',
   'La **rection de l''adjectif « soucieux »** est fixe : on est soucieux **de** quelque chose (soucieux de la qualité de l''air). « Pour » vient d''une analogie fautive avec « s''inquiéter pour quelqu''un », qui concerne une personne. « Envers » s''emploie avec des adjectifs d''attitude dirigée vers autrui (bienveillant envers, loyal envers), pas avec « soucieux ». « À » est la rection d''adjectifs comme « attentif à » ou « sensible à » — proches par le sens, mais la rection ne se transfère pas d''un adjectif à l''autre.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_prepositions_fines'),

  ('33333333-c00a-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « En créant sa coopérative maraîchère près de Valence, Yusuf s''est heurté ___ de nombreux obstacles administratifs. »',
   'La **rection du verbe pronominal « se heurter »**, au sens figuré de « rencontrer une difficulté », est « se heurter **à** » (se heurter à des obstacles). « Contre » vient d''une analogie avec le sens physique (se cogner contre un mur) ; au sens abstrait, seul « à » est correct. « Avec » construirait des verbes de conflit réciproque (se disputer avec, se brouiller avec), pas « se heurter ». « Devant » exprime une simple position ou l''hésitation (reculer devant), ce qui ne correspond pas à la construction du verbe.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_prepositions_fines'),

  ('33333333-c00a-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Sur le marché de Perpignan, la sécheresse de l''été s''est traduite ___ une hausse de douze pour cent du prix des légumes. »',
   'Au sens figuré de « avoir pour conséquence visible », la **rection est « se traduire par »** : la sécheresse s''est traduite **par** une hausse des prix. « En » appartient au sens propre, linguistique, du verbe (traduire un roman en italien). « Dans » exprimerait un simple cadre spatial ou temporel, ce que le verbe n''admet pas ici. « Avec » introduirait un accompagnement (s''accompagner avec est d''ailleurs fautif : on dit s''accompagner **de**), pas le résultat exigé par « se traduire ».',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_prepositions_fines'),

  ('33333333-c00a-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « La pharmacienne de Mulhouse prévient Olena : ce sirop est susceptible ___ provoquer des somnolences. »',
   'La **rection de l''adjectif « susceptible »** devant un infinitif est « susceptible **de** » (susceptible de provoquer). « À » vient d''une confusion avec des adjectifs voisins de sens mais de rection différente : « apte **à** », « enclin **à** » — chaque adjectif impose sa propre préposition. « Pour » construirait « doué pour » ou un complément de but, pas « susceptible ». « En » ne s''emploie jamais devant un infinitif après un adjectif (il introduit le gérondif ou un nom : doué en chimie).',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_prepositions_fines'),

  ('33333333-c00a-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Chaque soir, Bogdan, le gardien du parc municipal de Tours, veille ___ la fermeture des grilles. »',
   'La **double rection de « veiller »** distingue deux sens : « veiller **à** » + chose = s''assurer qu''elle est faite (veiller à la fermeture), tandis que « veiller **sur** » + personne ou être vulnérable = protéger (veiller sur un enfant malade). Ici le complément est une chose à garantir, donc « à ». « De » n''est pas une rection de « veiller » — c''est celle de « s''assurer de », d''où la confusion fréquente. « Pour » exprimerait un but ou un bénéficiaire, construction que « veiller » n''admet pas.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_prepositions_fines'),

  ('33333333-c00a-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Pour remédier ___ la pénurie de logements étudiants, la ville de Bordeaux construira trois résidences d''ici 2028. »',
   'La **rection du verbe « remédier »** est invariable : on remédie **à** un problème (remédier à la pénurie), comme « pallier » se construit, lui, sans préposition. « De » est la rection d''autres verbes (souffrir de, se plaindre de), jamais de « remédier ». « Contre » vient d''une analogie avec « lutter contre » ou « se battre contre » : le sens est proche, mais la rection ne se copie pas d''un verbe à l''autre. « Pour » indiquerait un but, or le complément de « remédier » est l''objet même de l''action, introduit obligatoirement par « à ».',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_prepositions_fines');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('33333333-c00a-2100-0000-000000000001', '33333333-c00a-1000-0000-000000000001', 'en', 'false', '1'),
  ('33333333-c00a-2200-0000-000000000001', '33333333-c00a-1000-0000-000000000001', 'à', 'true', '2'),
  ('33333333-c00a-2300-0000-000000000001', '33333333-c00a-1000-0000-000000000001', 'de', 'false', '3'),
  ('33333333-c00a-2400-0000-000000000001', '33333333-c00a-1000-0000-000000000001', 'par', 'false', '4'),

  ('33333333-c00a-2100-0000-000000000002', '33333333-c00a-1000-0000-000000000002', 'de', 'true', '1'),
  ('33333333-c00a-2200-0000-000000000002', '33333333-c00a-1000-0000-000000000002', 'pour', 'false', '2'),
  ('33333333-c00a-2300-0000-000000000002', '33333333-c00a-1000-0000-000000000002', 'envers', 'false', '3'),
  ('33333333-c00a-2400-0000-000000000002', '33333333-c00a-1000-0000-000000000002', 'à', 'false', '4'),

  ('33333333-c00a-2100-0000-000000000003', '33333333-c00a-1000-0000-000000000003', 'contre', 'false', '1'),
  ('33333333-c00a-2200-0000-000000000003', '33333333-c00a-1000-0000-000000000003', 'avec', 'false', '2'),
  ('33333333-c00a-2300-0000-000000000003', '33333333-c00a-1000-0000-000000000003', 'devant', 'false', '3'),
  ('33333333-c00a-2400-0000-000000000003', '33333333-c00a-1000-0000-000000000003', 'à', 'true', '4'),

  ('33333333-c00a-2100-0000-000000000004', '33333333-c00a-1000-0000-000000000004', 'en', 'false', '1'),
  ('33333333-c00a-2200-0000-000000000004', '33333333-c00a-1000-0000-000000000004', 'dans', 'false', '2'),
  ('33333333-c00a-2300-0000-000000000004', '33333333-c00a-1000-0000-000000000004', 'par', 'true', '3'),
  ('33333333-c00a-2400-0000-000000000004', '33333333-c00a-1000-0000-000000000004', 'avec', 'false', '4'),

  ('33333333-c00a-2100-0000-000000000005', '33333333-c00a-1000-0000-000000000005', 'à', 'false', '1'),
  ('33333333-c00a-2200-0000-000000000005', '33333333-c00a-1000-0000-000000000005', 'de', 'true', '2'),
  ('33333333-c00a-2300-0000-000000000005', '33333333-c00a-1000-0000-000000000005', 'pour', 'false', '3'),
  ('33333333-c00a-2400-0000-000000000005', '33333333-c00a-1000-0000-000000000005', 'en', 'false', '4'),

  ('33333333-c00a-2100-0000-000000000006', '33333333-c00a-1000-0000-000000000006', 'à', 'true', '1'),
  ('33333333-c00a-2200-0000-000000000006', '33333333-c00a-1000-0000-000000000006', 'sur', 'false', '2'),
  ('33333333-c00a-2300-0000-000000000006', '33333333-c00a-1000-0000-000000000006', 'de', 'false', '3'),
  ('33333333-c00a-2400-0000-000000000006', '33333333-c00a-1000-0000-000000000006', 'pour', 'false', '4'),

  ('33333333-c00a-2100-0000-000000000007', '33333333-c00a-1000-0000-000000000007', 'de', 'false', '1'),
  ('33333333-c00a-2200-0000-000000000007', '33333333-c00a-1000-0000-000000000007', 'contre', 'false', '2'),
  ('33333333-c00a-2300-0000-000000000007', '33333333-c00a-1000-0000-000000000007', 'pour', 'false', '3'),
  ('33333333-c00a-2400-0000-000000000007', '33333333-c00a-1000-0000-000000000007', 'à', 'true', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes (33333333-c00a-1000-…-01..07 / choices 2100-2400).
-- [x] 4 propositions / 1 seule correcte par item ; options de même catégorie
--     (4 prépositions grammaticalement existantes à chaque fois).
-- [x] Distribution des bonnes réponses : pos1:2, pos2:2, pos3:1, pos4:2
--     (4 positions utilisées, aucune ne dépasse 2).
-- [x] Point unique : prépositions fines — rection des verbes et adjectifs
--     (consister à + inf, soucieux de, se heurter à, se traduire par,
--     susceptible de + inf, veiller à vs veiller sur, remédier à) — aucun
--     point de la liste interdite (pas de relatifs, subjonctif, passif,
--     connecteurs, etc.).
-- [x] explanation ≥ 80 caractères, nomme la **rection** en gras et démonte
--     chacun des 3 distracteurs (rection voisine, analogie fautive, sens propre
--     vs figuré).
-- [x] Contextes tous différents (logistique d''entrepôt, politique municipale
--     air, coopérative maraîchère, prix sur un marché, conseil en pharmacie,
--     gardiennage de parc, logement étudiant) ; prénoms et villes variés
--     (Mei/Lyon, Nantes, Yusuf/Valence, Perpignan, Olena/Mulhouse,
--     Bogdan/Tours, Bordeaux).
-- [x] Contenu 100 % original ; pas de SVG ni SSML dans ce lot (items texte purs).
-- [x] Apostrophes SQL doublées ; pas de JSONB dans ce schéma (table choices).
-- ============================================================================
