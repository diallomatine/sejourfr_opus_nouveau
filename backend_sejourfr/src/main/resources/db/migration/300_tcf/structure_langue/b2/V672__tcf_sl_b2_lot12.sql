-- ============================================================================
-- V672 — TCF SL B2 — lot 12 (point : connecteurs concessifs)
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id 22222222-0000-0000-0000-000000000003, difficulty='B2'.
-- 7 items, tous sur les connecteurs concessifs (malgré, bien que, avoir beau,
-- quoi que, aussi…que, quel(le)s que, même si). Contenu original, déterministe.
-- ============================================================================

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('33333333-c00c-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « ___ une grève des transports, les maraîchers d''Annecy ont tous rejoint le marché ce samedi. »',
   'Le trou est suivi d''un **groupe nominal** (« une grève des transports »), pas d''une proposition conjuguée : seule la **préposition concessive « malgré »** convient. « Bien que » est une conjonction qui introduit une proposition au subjonctif (bien qu''il y ait une grève). « Même si » introduit une proposition à l''indicatif (même s''il y a une grève). « Pourtant » est un adverbe qui relie deux propositions indépendantes et ne peut jamais être suivi directement d''un nom.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_connecteur_concessif'),

  ('33333333-c00c-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « ___ Fatou ait révisé chaque soir pendant un mois, elle aborde son entretien de naturalisation avec appréhension. »',
   'Le verbe est au **subjonctif passé** (« ait révisé ») : c''est la marque de la conjonction concessive **« bien que » + subjonctif**. « Même si » exprime aussi la concession mais se construit obligatoirement avec l''indicatif (même si Fatou a révisé). « Malgré » est une préposition : elle exige un groupe nominal (malgré ses révisions), pas une proposition conjuguée. « Pourtant » est un adverbe de liaison entre deux phrases autonomes ; il ne peut pas introduire une subordonnée.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_connecteur_concessif'),

  ('33333333-c00c-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Mehdi a beau ___ à l''aube, il retrouve chaque matin les mêmes embouteillages sur le périphérique de Lyon. »',
   'La tournure concessive **« avoir beau » se construit toujours avec l''infinitif** : « Mehdi a beau partir à l''aube ». « Parte » (subjonctif) serait appelé par « bien que », pas par « avoir beau ». « Part » (indicatif) conviendrait après « même si » (même s''il part à l''aube) mais jamais après « a beau ». « Partant » (participe présent) s''emploierait dans la tournure « tout en partant à l''aube », pas ici. La règle est mécanique : avoir beau + infinitif, sans exception.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_connecteur_concessif'),

  ('33333333-c00c-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « ___ tu en dises, le quartier de la gare à Lille est devenu bien plus agréable qu''en 2015. »',
   'Il faut **« quoi que » en deux mots** : pronom relatif indéfini (= quelle que soit la chose que), il sert de **COD au verbe « dire »** et appelle le subjonctif (« dises »). « Quoique » en un seul mot signifie « bien que » : c''est une simple conjonction, et la proposition « tu en dises » resterait alors sans COD, donc agrammaticale. « Bien que » pose exactement le même problème de COD manquant. « Même si » cumule deux fautes : COD manquant et indicatif obligatoire, incompatible avec « dises ».',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_connecteur_concessif'),

  ('33333333-c00c-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « ___ étonnant que cela puisse paraître, le petit cinéma associatif d''Aurillac remplit sa salle tous les mardis. »',
   'C''est la tournure concessive **« aussi + adjectif + que + subjonctif »** (avec « puisse ») : aussi étonnant que cela puisse paraître = bien que cela paraisse très étonnant. « Tellement » et « tant » expriment l''intensité suivie d''une **conséquence à l''indicatif** (tellement étonnant que la presse en a parlé), pas une concession au subjonctif ; « tant » ne modifie d''ailleurs pas directement un adjectif. « Autant » porte sur un verbe ou un nom (autant de spectateurs), jamais sur un adjectif dans cette structure.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_connecteur_concessif'),

  ('33333333-c00c-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « ___ soient les conditions météo annoncées, la brocante de Périgueux se tiendra dimanche sur la place principale. »',
   'Devant le verbe **« être » au subjonctif suivi d''un sujet nominal**, on emploie **« quel(le)(s) que »** en deux mots, accordé avec le sujet : « les conditions » est féminin pluriel → « quelles que soient ». « Quelque » en un mot est un déterminant ou un adverbe (quelque cinquante exposants) et ne se place jamais devant « être ». « Quoi que » est un pronom qui doit être COD d''un verbe (quoi que l''on prévoie), or « soient » n''admet pas de COD. « Quoique » (= bien que) introduirait une proposition complète, pas une inversion avec « être » + sujet.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_connecteur_concessif'),

  ('33333333-c00c-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « ___ le sentier était verglacé ce matin-là, Aïcha a atteint le sommet du puy de Sancy avant midi. »',
   'Le verbe de la subordonnée est à l''**indicatif** (« était ») : parmi les connecteurs concessifs, seul **« même si » se construit avec l''indicatif**. « Bien que » et « quoique » exigent le subjonctif (bien que le sentier fût/soit verglacé) ; avec « était », ils sont fautifs. « Malgré » est une préposition qui demande un groupe nominal (malgré le verglas), pas une proposition conjuguée. Le mode du verbe est donc le critère qui tranche entre ces quatre concessifs.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_connecteur_concessif');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('33333333-c00c-2100-0000-000000000001', '33333333-c00c-1000-0000-000000000001', 'Bien que', 'false', '1'),
  ('33333333-c00c-2200-0000-000000000001', '33333333-c00c-1000-0000-000000000001', 'Malgré', 'true', '2'),
  ('33333333-c00c-2300-0000-000000000001', '33333333-c00c-1000-0000-000000000001', 'Même si', 'false', '3'),
  ('33333333-c00c-2400-0000-000000000001', '33333333-c00c-1000-0000-000000000001', 'Pourtant', 'false', '4'),

  ('33333333-c00c-2100-0000-000000000002', '33333333-c00c-1000-0000-000000000002', 'Même si', 'false', '1'),
  ('33333333-c00c-2200-0000-000000000002', '33333333-c00c-1000-0000-000000000002', 'Malgré', 'false', '2'),
  ('33333333-c00c-2300-0000-000000000002', '33333333-c00c-1000-0000-000000000002', 'Bien que', 'true', '3'),
  ('33333333-c00c-2400-0000-000000000002', '33333333-c00c-1000-0000-000000000002', 'Pourtant', 'false', '4'),

  ('33333333-c00c-2100-0000-000000000003', '33333333-c00c-1000-0000-000000000003', 'partir', 'true', '1'),
  ('33333333-c00c-2200-0000-000000000003', '33333333-c00c-1000-0000-000000000003', 'parte', 'false', '2'),
  ('33333333-c00c-2300-0000-000000000003', '33333333-c00c-1000-0000-000000000003', 'part', 'false', '3'),
  ('33333333-c00c-2400-0000-000000000003', '33333333-c00c-1000-0000-000000000003', 'partant', 'false', '4'),

  ('33333333-c00c-2100-0000-000000000004', '33333333-c00c-1000-0000-000000000004', 'Quoique', 'false', '1'),
  ('33333333-c00c-2200-0000-000000000004', '33333333-c00c-1000-0000-000000000004', 'Bien que', 'false', '2'),
  ('33333333-c00c-2300-0000-000000000004', '33333333-c00c-1000-0000-000000000004', 'Même si', 'false', '3'),
  ('33333333-c00c-2400-0000-000000000004', '33333333-c00c-1000-0000-000000000004', 'Quoi que', 'true', '4'),

  ('33333333-c00c-2100-0000-000000000005', '33333333-c00c-1000-0000-000000000005', 'Aussi', 'true', '1'),
  ('33333333-c00c-2200-0000-000000000005', '33333333-c00c-1000-0000-000000000005', 'Tellement', 'false', '2'),
  ('33333333-c00c-2300-0000-000000000005', '33333333-c00c-1000-0000-000000000005', 'Tant', 'false', '3'),
  ('33333333-c00c-2400-0000-000000000005', '33333333-c00c-1000-0000-000000000005', 'Autant', 'false', '4'),

  ('33333333-c00c-2100-0000-000000000006', '33333333-c00c-1000-0000-000000000006', 'Quoique', 'false', '1'),
  ('33333333-c00c-2200-0000-000000000006', '33333333-c00c-1000-0000-000000000006', 'Quelles que', 'true', '2'),
  ('33333333-c00c-2300-0000-000000000006', '33333333-c00c-1000-0000-000000000006', 'Quelque', 'false', '3'),
  ('33333333-c00c-2400-0000-000000000006', '33333333-c00c-1000-0000-000000000006', 'Quoi que', 'false', '4'),

  ('33333333-c00c-2100-0000-000000000007', '33333333-c00c-1000-0000-000000000007', 'Bien que', 'false', '1'),
  ('33333333-c00c-2200-0000-000000000007', '33333333-c00c-1000-0000-000000000007', 'Quoique', 'false', '2'),
  ('33333333-c00c-2300-0000-000000000007', '33333333-c00c-1000-0000-000000000007', 'Même si', 'true', '3'),
  ('33333333-c00c-2400-0000-000000000007', '33333333-c00c-1000-0000-000000000007', 'Malgré', 'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes (33333333-c00c-1000-…-01..07 / choices 2100-2400).
-- [x] 4 propositions / 1 seule correcte par item ; options de même catégorie
--     (connecteurs concessifs entre eux, 4 formes du même verbe pour « avoir
--     beau », 4 adverbes de degré pour « aussi…que »).
-- [x] Distribution des bonnes réponses : pos1:2, pos2:2, pos3:2, pos4:1
--     (4 positions utilisées, aucune ne dépasse 2).
-- [x] Point unique : connecteurs concessifs (malgré + nom, bien que + subjonctif,
--     avoir beau + infinitif, quoi que vs quoique, aussi + adj + que + subjonctif,
--     quelles que + être, même si + indicatif) — aucun point de la liste interdite.
-- [x] explanation ≥ 80 caractères, règle nommée et **en gras**, chacun des
--     3 distracteurs démonté (mode exigé, catégorie grammaticale, construction).
-- [x] Contextes tous différents (marché sous grève à Annecy, entretien de
--     naturalisation, embouteillages lyonnais, quartier de gare à Lille,
--     cinéma associatif d''Aurillac, brocante de Périgueux, randonnée au puy
--     de Sancy) ; prénoms variés (Fatou, Mehdi, Aïcha).
-- [x] Contenu 100 % original ; pas de SVG ni SSML dans ce lot (items texte purs).
-- [x] Apostrophes SQL doublées ; pas de JSONB dans ce schéma (table choices).
-- ============================================================================
