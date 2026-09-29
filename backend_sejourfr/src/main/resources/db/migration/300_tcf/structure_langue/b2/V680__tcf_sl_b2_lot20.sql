-- ============================================================================
-- V680 — TCF SL B2 — lot 20 (point : mode après verbes d'opinion à la forme négative)
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id 22222222-0000-0000-0000-000000000003, difficulty='B2'.
-- 7 items, tous sur le mode (subjonctif vs indicatif/conditionnel) après un verbe
-- d'opinion nié (ne pas penser/croire/trouver/estimer/juger que, ne pas être
-- sûr/certain que). Contenu original, déterministe.
-- ============================================================================

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('33333333-c014-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Mariam ne pense pas que ce restaurant de Bordeaux ___ ouvert le dimanche soir. »',
   '**« Penser que » à la forme négative** ne présente plus le fait comme certain : la subordonnée passe au **subjonctif** → « soit ». « Est » (indicatif présent) ne s''emploierait qu''après l''opinion affirmative (« Mariam pense que ce restaurant est ouvert »), qui asserte le fait. « Sera » (futur de l''indicatif) affirmerait un fait à venir, incompatible avec le doute introduit par la négation. « Serait » (conditionnel) signalerait une information rapportée ou une hypothèse, pas la dépendance grammaticale à une opinion niée.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_subjonctif_opinion_negative'),

  ('33333333-c014-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Karim ne croit pas que sa cousine ___ assister à la remise des diplômes de mardi. »',
   '**« Croire que » nié** retire au fait son caractère assuré : la subordonnée exige le **subjonctif** → « puisse ». « Peut » (indicatif présent) conviendrait après la forme affirmative (« Karim croit que sa cousine peut venir »), où le fait est tenu pour vrai. « Pourra » (futur de l''indicatif) asserterait une capacité future, ce que la négation interdit justement d''affirmer. « Pourrait » (conditionnel) exprimerait une éventualité atténuée ou un fait non confirmé, mais ce n''est pas le mode appelé par un verbe d''opinion à la forme négative.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_subjonctif_opinion_negative'),

  ('33333333-c014-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Les habitants ne trouvent pas que leur quartier ___ beaucoup changé depuis la rénovation de 2023. »',
   '**« Trouver que » à la forme négative** introduit un jugement contesté : la subordonnée se met au **subjonctif passé** (fait accompli) → « ait » (ait changé). « A » (passé composé de l''indicatif) suivrait l''opinion affirmative (« ils trouvent que le quartier a changé »), qui valide le constat. « Aura » (futur antérieur) situerait le changement dans l''avenir, contresens avec « depuis la rénovation ». « Aurait » (conditionnel passé) marquerait une information non vérifiée de type journalistique, pas le mode requis après un verbe d''opinion nié.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_subjonctif_opinion_negative'),

  ('33333333-c014-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Aïcha n''est pas sûre que son dossier de naturalisation ___ complet avant le rendez-vous. »',
   '**« Être sûr que » nié** bascule la subordonnée dans l''incertain : on emploie le **subjonctif** → « soit ». « Est » (indicatif présent) s''utiliserait après la certitude affirmée (« Aïcha est sûre que son dossier est complet »). « Sera » (futur de l''indicatif) présenterait l''achèvement du dossier comme un fait acquis, ce que « n''est pas sûre » exclut. « Était » (imparfait de l''indicatif) renverrait à un état passé et resterait à l''indicatif, mode réservé aux faits assertés, pas aux faits mis en doute par la négation.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_subjonctif_opinion_negative'),

  ('33333333-c014-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « La directrice n''estime pas que l''achat de trois imprimantes ___ indispensable cette année. »',
   '**« Estimer que » à la forme négative** refuse d''asserter le contenu de la subordonnée : le **subjonctif** s''impose → « soit ». « Est » (indicatif présent) suivrait la forme affirmative (« elle estime que cet achat est indispensable »), où le jugement est posé comme vrai. « Sera » (futur de l''indicatif) affirmerait une nécessité future malgré la négation, contradiction de modalité. « Serait » (conditionnel) exprimerait une supposition prudente ou un fait conditionné, mais le déclencheur ici est grammatical : opinion niée → subjonctif.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_subjonctif_opinion_negative'),

  ('33333333-c014-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Je ne suis pas certain que vous ___ raison au sujet des horaires du musée de Nancy. »',
   '**« Être certain que » nié** suspend la vérité de la subordonnée : on passe au **subjonctif** → « ayez » (que vous ayez raison). « Avez » (indicatif présent) ne conviendrait qu''après la certitude affirmée (« je suis certain que vous avez raison »). « Aurez » (futur de l''indicatif) asserterait un fait futur, alors que la négation interdit précisément d''asserter. « Auriez » (conditionnel) suggérerait une hypothèse ou un reproche atténué (« vous auriez raison si… »), pas le mode commandé par un verbe de certitude à la forme négative.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_subjonctif_opinion_negative'),

  ('33333333-c014-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Olena ne juge pas que cette formation en ligne ___ vraiment à ses besoins professionnels. »',
   '**« Juger que » à la forme négative** fonctionne comme penser/estimer niés : la subordonnée prend le **subjonctif** → « réponde ». « Répond » (indicatif présent) suivrait le jugement affirmatif (« Olena juge que cette formation répond à ses besoins »), qui valide le fait. « Répondra » (futur de l''indicatif) poserait comme certaine une adéquation future, ce que la négation refuse. « Répondrait » (conditionnel) marquerait une éventualité soumise à condition, alors que c''est la structure « verbe d''opinion nié + que » qui déclenche mécaniquement le subjonctif.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_subjonctif_opinion_negative');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('33333333-c014-2100-0000-000000000001', '33333333-c014-1000-0000-000000000001', 'est', 'false', '1'),
  ('33333333-c014-2200-0000-000000000001', '33333333-c014-1000-0000-000000000001', 'soit', 'true', '2'),
  ('33333333-c014-2300-0000-000000000001', '33333333-c014-1000-0000-000000000001', 'sera', 'false', '3'),
  ('33333333-c014-2400-0000-000000000001', '33333333-c014-1000-0000-000000000001', 'serait', 'false', '4'),

  ('33333333-c014-2100-0000-000000000002', '33333333-c014-1000-0000-000000000002', 'peut', 'false', '1'),
  ('33333333-c014-2200-0000-000000000002', '33333333-c014-1000-0000-000000000002', 'pourra', 'false', '2'),
  ('33333333-c014-2300-0000-000000000002', '33333333-c014-1000-0000-000000000002', 'puisse', 'true', '3'),
  ('33333333-c014-2400-0000-000000000002', '33333333-c014-1000-0000-000000000002', 'pourrait', 'false', '4'),

  ('33333333-c014-2100-0000-000000000003', '33333333-c014-1000-0000-000000000003', 'a', 'false', '1'),
  ('33333333-c014-2200-0000-000000000003', '33333333-c014-1000-0000-000000000003', 'aura', 'false', '2'),
  ('33333333-c014-2300-0000-000000000003', '33333333-c014-1000-0000-000000000003', 'aurait', 'false', '3'),
  ('33333333-c014-2400-0000-000000000003', '33333333-c014-1000-0000-000000000003', 'ait', 'true', '4'),

  ('33333333-c014-2100-0000-000000000004', '33333333-c014-1000-0000-000000000004', 'soit', 'true', '1'),
  ('33333333-c014-2200-0000-000000000004', '33333333-c014-1000-0000-000000000004', 'est', 'false', '2'),
  ('33333333-c014-2300-0000-000000000004', '33333333-c014-1000-0000-000000000004', 'sera', 'false', '3'),
  ('33333333-c014-2400-0000-000000000004', '33333333-c014-1000-0000-000000000004', 'était', 'false', '4'),

  ('33333333-c014-2100-0000-000000000005', '33333333-c014-1000-0000-000000000005', 'est', 'false', '1'),
  ('33333333-c014-2200-0000-000000000005', '33333333-c014-1000-0000-000000000005', 'sera', 'false', '2'),
  ('33333333-c014-2300-0000-000000000005', '33333333-c014-1000-0000-000000000005', 'soit', 'true', '3'),
  ('33333333-c014-2400-0000-000000000005', '33333333-c014-1000-0000-000000000005', 'serait', 'false', '4'),

  ('33333333-c014-2100-0000-000000000006', '33333333-c014-1000-0000-000000000006', 'avez', 'false', '1'),
  ('33333333-c014-2200-0000-000000000006', '33333333-c014-1000-0000-000000000006', 'ayez', 'true', '2'),
  ('33333333-c014-2300-0000-000000000006', '33333333-c014-1000-0000-000000000006', 'aurez', 'false', '3'),
  ('33333333-c014-2400-0000-000000000006', '33333333-c014-1000-0000-000000000006', 'auriez', 'false', '4'),

  ('33333333-c014-2100-0000-000000000007', '33333333-c014-1000-0000-000000000007', 'réponde', 'true', '1'),
  ('33333333-c014-2200-0000-000000000007', '33333333-c014-1000-0000-000000000007', 'répond', 'false', '2'),
  ('33333333-c014-2300-0000-000000000007', '33333333-c014-1000-0000-000000000007', 'répondra', 'false', '3'),
  ('33333333-c014-2400-0000-000000000007', '33333333-c014-1000-0000-000000000007', 'répondrait', 'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes (33333333-c014-1000-…-01..07 / choices 2100-2400).
-- [x] 4 propositions / 1 seule correcte par item ; options de même catégorie
--     (4 formes conjuguées du même verbe : indicatif présent/futur/imparfait,
--     subjonctif, conditionnel — toutes grammaticalement existantes).
-- [x] Distribution des bonnes réponses : pos1:2, pos2:2, pos3:2, pos4:1
--     (4 positions utilisées, aucune ne dépasse 2).
-- [x] Point unique : mode après verbes d''opinion à la forme négative (ne pas
--     penser/croire/trouver/estimer/juger que, ne pas être sûr/certain que →
--     subjonctif) — aucun point de la liste interdite (relatifs composés,
--     concordance, conditionnel passé, voix passive, etc. absents en tant que
--     point testé).
-- [x] explanation ≥ 80 caractères, règle nommée en **gras** (verbe d''opinion
--     nié → subjonctif), chacun des 3 distracteurs démonté (indicatif réservé
--     à l''affirmative, futur assertif, conditionnel d''hypothèse/information
--     non vérifiée).
-- [x] Contextes tous différents (restaurant le dimanche, remise de diplômes,
--     rénovation de quartier, dossier de naturalisation, achat d''imprimantes,
--     horaires de musée, formation en ligne) ; prénoms et villes variés
--     (Mariam/Bordeaux, Karim, Aïcha, Olena, Nancy).
-- [x] Contenu 100 % original ; items texte purs (pas de SVG ni SSML).
-- [x] Apostrophes SQL doublées ; pas de JSONB dans ce schéma (table choices).
-- ============================================================================
