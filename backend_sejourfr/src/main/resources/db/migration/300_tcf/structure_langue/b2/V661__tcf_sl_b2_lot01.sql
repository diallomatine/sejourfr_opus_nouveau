-- ============================================================================
-- V661 — TCF SL B2 — lot 01 (point : pronoms relatifs composés)
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id 22222222-0000-0000-0000-000000000003, difficulty='B2'.
-- 7 items, tous sur les relatifs composés (avec/pour/sans/grâce à/à côté de/
-- au cours de + lequel, auquel, duquel…). Contenu original, déterministe.
-- ============================================================================

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('33333333-c001-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Les ingénieurs ___ Wei collabore sur ce prototype travaillent à Toulouse. »',
   'La **rection du verbe** tranche : « collaborer **avec** quelqu''un ». Pour reprendre un complément masculin pluriel introduit par « avec », on emploie « avec lesquels ». « Que » reprendrait un COD, or « collaborer » ne se construit pas avec un COD (on ne « collabore » pas quelqu''un). « Dont » reprendrait un complément introduit par « de » (les ingénieurs dont Wei parle). « Auxquels » reprendrait un complément introduit par « à » (les ingénieurs auxquels Wei a écrit).',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_pronom_relatif_compose'),

  ('33333333-c001-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Le voyage ___ Rachid a renoncé l''an dernier coûtait trop cher. »',
   'La **rection du verbe** est « renoncer **à** quelque chose ». Pour reprendre un complément masculin singulier introduit par « à », on emploie le relatif composé « auquel » (contraction de « à + lequel »). « Dont » reprendrait un complément introduit par « de » (le voyage dont Rachid rêvait). « Que » reprendrait un COD (le voyage que Rachid a annulé). « Pour lequel » reprendrait un complément de but ou de destination introduit par « pour » (le voyage pour lequel il économisait).',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_pronom_relatif_compose'),

  ('33333333-c001-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « La bourse ___ Priya a pu financer son master lui a été attribuée en septembre. »',
   'Le sens exige d''exprimer le **moyen** : Priya a financé son master **grâce à** cette bourse → « grâce à laquelle » (locution prépositionnelle + relatif composé féminin singulier). « Dont » reprendrait un complément introduit par « de » seul (la bourse dont elle a bénéficié). « À laquelle » reprendrait un complément introduit par « à » (la bourse à laquelle elle a candidaté). « Que » reprendrait un COD (la bourse que Priya a obtenue) — or « financer » a déjà son COD, « son master ».',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_pronom_relatif_compose'),

  ('33333333-c001-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « C''est un logiciel ___ Diego ne pourrait plus organiser ses chantiers. »',
   'Le sens exprime la **privation** : Diego ne pourrait plus travailler **sans** ce logiciel → « sans lequel » (préposition « sans » + relatif composé masculin singulier). « Dont » reprendrait un complément introduit par « de » (un logiciel dont il se sert). « Auquel » reprendrait un complément introduit par « à » (un logiciel auquel il s''est habitué). « Que » reprendrait un COD (un logiciel que Diego utilise) — mais ici « organiser » a déjà son COD, « ses chantiers ».',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_pronom_relatif_compose'),

  ('33333333-c001-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « La boulangerie ___ Lucia gare sa voiture chaque matin appartient à son oncle. »',
   'La **locution prépositionnelle de lieu** « à côté **de** » impose le relatif composé contracté : Lucia gare sa voiture à côté de la boulangerie → « à côté de laquelle » (de + laquelle, féminin singulier). « Que » reprendrait un COD (la boulangerie que Lucia préfère) — or « garer » a déjà son COD, « sa voiture ». « Dans laquelle » est grammaticalement correct mais absurde ici : on ne gare pas une voiture à l''intérieur d''une boulangerie. « Dont » reprendrait un complément en « de » seul (la boulangerie dont elle parle).',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_pronom_relatif_compose'),

  ('33333333-c001-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « L''association ___ Olena collecte des fonds vient en aide aux réfugiés. »',
   'La **rection** est « collecter des fonds **pour** quelqu''un » : le bénéficiaire est introduit par « pour » → « pour laquelle » (féminin singulier). « Dont » reprendrait un complément introduit par « de » (l''association dont Olena est membre). « Que » reprendrait un COD (l''association qu''Olena soutient) — or le COD de « collecter » est déjà « des fonds ». « À laquelle » reprendrait un complément introduit par « à » (l''association à laquelle Olena a adhéré).',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_pronom_relatif_compose'),

  ('33333333-c001-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Le stage ___ Amadou a obtenu sa certification de soudeur durait six semaines. »',
   'La **locution prépositionnelle de temps** « au cours **de** » exige le relatif composé contracté : la certification a été obtenue au cours de ce stage → « au cours duquel » (de + lequel, masculin singulier). « Dont » reprendrait un complément en « de » seul (le stage dont Amadou garde un bon souvenir). « Auquel » reprendrait un complément introduit par « à » (le stage auquel il s''est inscrit). « Que » reprendrait un COD (le stage qu''Amadou a suivi) — or « obtenir » a déjà son COD, « sa certification ».',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_pronom_relatif_compose');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('33333333-c001-2100-0000-000000000001', '33333333-c001-1000-0000-000000000001', 'que', 'false', '1'),
  ('33333333-c001-2200-0000-000000000001', '33333333-c001-1000-0000-000000000001', 'dont', 'false', '2'),
  ('33333333-c001-2300-0000-000000000001', '33333333-c001-1000-0000-000000000001', 'avec lesquels', 'true', '3'),
  ('33333333-c001-2400-0000-000000000001', '33333333-c001-1000-0000-000000000001', 'auxquels', 'false', '4'),

  ('33333333-c001-2100-0000-000000000002', '33333333-c001-1000-0000-000000000002', 'auquel', 'true', '1'),
  ('33333333-c001-2200-0000-000000000002', '33333333-c001-1000-0000-000000000002', 'dont', 'false', '2'),
  ('33333333-c001-2300-0000-000000000002', '33333333-c001-1000-0000-000000000002', 'que', 'false', '3'),
  ('33333333-c001-2400-0000-000000000002', '33333333-c001-1000-0000-000000000002', 'pour lequel', 'false', '4'),

  ('33333333-c001-2100-0000-000000000003', '33333333-c001-1000-0000-000000000003', 'dont', 'false', '1'),
  ('33333333-c001-2200-0000-000000000003', '33333333-c001-1000-0000-000000000003', 'à laquelle', 'false', '2'),
  ('33333333-c001-2300-0000-000000000003', '33333333-c001-1000-0000-000000000003', 'que', 'false', '3'),
  ('33333333-c001-2400-0000-000000000003', '33333333-c001-1000-0000-000000000003', 'grâce à laquelle', 'true', '4'),

  ('33333333-c001-2100-0000-000000000004', '33333333-c001-1000-0000-000000000004', 'dont', 'false', '1'),
  ('33333333-c001-2200-0000-000000000004', '33333333-c001-1000-0000-000000000004', 'sans lequel', 'true', '2'),
  ('33333333-c001-2300-0000-000000000004', '33333333-c001-1000-0000-000000000004', 'auquel', 'false', '3'),
  ('33333333-c001-2400-0000-000000000004', '33333333-c001-1000-0000-000000000004', 'que', 'false', '4'),

  ('33333333-c001-2100-0000-000000000005', '33333333-c001-1000-0000-000000000005', 'que', 'false', '1'),
  ('33333333-c001-2200-0000-000000000005', '33333333-c001-1000-0000-000000000005', 'dans laquelle', 'false', '2'),
  ('33333333-c001-2300-0000-000000000005', '33333333-c001-1000-0000-000000000005', 'à côté de laquelle', 'true', '3'),
  ('33333333-c001-2400-0000-000000000005', '33333333-c001-1000-0000-000000000005', 'dont', 'false', '4'),

  ('33333333-c001-2100-0000-000000000006', '33333333-c001-1000-0000-000000000006', 'pour laquelle', 'true', '1'),
  ('33333333-c001-2200-0000-000000000006', '33333333-c001-1000-0000-000000000006', 'dont', 'false', '2'),
  ('33333333-c001-2300-0000-000000000006', '33333333-c001-1000-0000-000000000006', 'que', 'false', '3'),
  ('33333333-c001-2400-0000-000000000006', '33333333-c001-1000-0000-000000000006', 'à laquelle', 'false', '4'),

  ('33333333-c001-2100-0000-000000000007', '33333333-c001-1000-0000-000000000007', 'dont', 'false', '1'),
  ('33333333-c001-2200-0000-000000000007', '33333333-c001-1000-0000-000000000007', 'au cours duquel', 'true', '2'),
  ('33333333-c001-2300-0000-000000000007', '33333333-c001-1000-0000-000000000007', 'auquel', 'false', '3'),
  ('33333333-c001-2400-0000-000000000007', '33333333-c001-1000-0000-000000000007', 'que', 'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes (33333333-c001-1000-…-01..07 / choices 2100-2400).
-- [x] 4 propositions / 1 seule correcte par item ; options de même catégorie
--     (4 pronoms relatifs grammaticalement existants à chaque fois).
-- [x] Distribution des bonnes réponses : pos1:2, pos2:2, pos3:2, pos4:1
--     (4 positions utilisées, aucune ne dépasse 2).
-- [x] Point unique : pronoms relatifs composés (avec lesquels, auquel,
--     grâce à laquelle, sans lequel, à côté de laquelle, pour laquelle,
--     au cours duquel) — aucun point de la liste interdite.
-- [x] explanation ≥ 80 caractères, nomme la rection / la locution prépositionnelle
--     (**gras**) et démonte chacun des 3 distracteurs.
-- [x] Contextes tous différents (prototype industriel, voyage, bourse d''études,
--     logiciel de chantier, stationnement, collecte associative, stage de soudure) ;
--     prénoms variés (Wei, Rachid, Priya, Diego, Lucia, Olena, Amadou).
-- [x] Contenu 100 % original ; pas de SVG ni SSML dans ce lot (items texte purs).
-- [x] Apostrophes SQL doublées ; pas de JSONB dans ce schéma (table choices).
-- ============================================================================
