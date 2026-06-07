-- ============================================================================
-- V686 — TCF SL B2 — lot 26 (point : plus-que-parfait & antériorité dans le passé)
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id 22222222-0000-0000-0000-000000000003, difficulty='B2'.
-- 6 items, tous sur le plus-que-parfait comme marqueur d''antériorité dans un
-- récit au passé (repères : déjà, la veille, la nuit précédente, depuis,
-- quinze ans plus tôt, auparavant). Contenu original, déterministe.
-- ============================================================================

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('33333333-c01a-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Quand Fatou est arrivée sur le quai, le train pour Bordeaux ___ déjà. »',
   'Le **plus-que-parfait** marque l''**antériorité dans le passé** : le départ du train a eu lieu **avant** l''arrivée de Fatou, elle-même déjà située au passé (« est arrivée »), et l''adverbe « déjà » signale une action accomplie → « était parti ». « Est parti » (passé composé) placerait les deux événements sur le même plan temporel, comme si le train démarrait au moment où elle arrive. « Partait » (imparfait) décrirait un départ en train de se faire sous ses yeux, incompatible avec « déjà ». « Partit » (passé simple) raconterait un événement qui suit l''arrivée dans la chronologie du récit, pas un événement antérieur.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_plus_que_parfait'),

  ('33333333-c01a-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Mehdi a enfin retrouvé le contrat que sa collègue ___ la veille dans la mauvaise armoire. »',
   'Le repère relatif « **la veille** » impose le **plus-que-parfait** : dans un récit au passé, il situe le classement **un jour avant** le moment où Mehdi retrouve le contrat → « avait classé » (**antériorité dans le passé**). « A classé » (passé composé) mettrait les deux faits sur le même plan, alors que « la veille » (et non « hier ») exige un décalage en arrière par rapport à un repère déjà passé. « Classait » (imparfait) présenterait l''action comme en cours, sans son résultat — or c''est justement le résultat (le contrat mal rangé) qui compte. « Classa » (passé simple) ferait avancer le récit au lieu de revenir en arrière.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_plus_que_parfait'),

  ('33333333-c01a-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Tomas s''est endormi pendant la réunion de lundi : il ___ toute la nuit précédente sur son mémoire. »',
   'La cause est **antérieure** à l''effet : la nuit de travail précède l''endormissement, lui-même déjà au passé → **plus-que-parfait** « avait travaillé » (**antériorité dans le passé**), renforcé par le repère relatif « la nuit **précédente** ». « A travaillé » (passé composé) alignerait la cause sur le même plan temporel que « s''est endormi », ce que « précédente » interdit. « Travaillait » (imparfait) ne convient pas à une durée bornée et achevée (« toute la nuit ») présentée comme cause révolue. « Travailla » (passé simple) enchaînerait les actions dans l''ordre du récit, donc le travail viendrait après l''endormissement — contresens.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_plus_que_parfait'),

  ('33333333-c01a-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Quand les pompiers de Nantes sont entrés dans l''immeuble, les habitants ___ les lieux depuis plusieurs minutes. »',
   '« **Depuis plusieurs minutes** » mesure l''**état résultant** d''une action accomplie **avant** l''arrivée des pompiers : seul le **plus-que-parfait** « avaient quitté » exprime cette **antériorité dans le passé** dont le résultat dure encore au moment de référence. « Ont quitté » (passé composé) est incompatible avec ce repère passé : il rattacherait l''action au présent du locuteur, pas au moment où les pompiers entrent. « Quittaient » (imparfait) décrirait une évacuation en cours, contradictoire avec une durée déjà écoulée depuis la sortie. « Quittèrent » (passé simple) ferait de la sortie l''événement suivant du récit, alors qu''elle est antérieure.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_plus_que_parfait'),

  ('33333333-c01a-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Pavel a aussitôt reconnu son ancien professeur : il ___ ses cours de chimie pendant deux ans, quinze ans plus tôt. »',
   'Le repère relatif « **quinze ans plus tôt** » (et non « il y a quinze ans ») situe les cours **avant** le moment passé de la reconnaissance → **plus-que-parfait** « avait suivi » (**antériorité dans le passé**). « A suivi » (passé composé) s''emploierait avec « il y a quinze ans », repère compté depuis le présent du locuteur, pas depuis un point du passé. « Suivait » (imparfait) est exclu par la durée bornée « pendant deux ans », qui présente l''expérience comme un bloc achevé et non comme une toile de fond. « Suivit » (passé simple) raconterait un fait nouveau qui ferait avancer le récit, au lieu d''expliquer la reconnaissance par un retour en arrière.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_plus_que_parfait'),

  ('33333333-c01a-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Aïcha a impressionné le jury de son entretien d''embauche, alors qu''elle ___ en public auparavant. »',
   '« **Auparavant** » renvoie à tout ce qui précède un repère **déjà passé** (l''entretien) : l''absence d''expérience est **antérieure** à ce moment → **plus-que-parfait** « n''avait jamais parlé » (**antériorité dans le passé**). « N''a jamais parlé » (passé composé) dresserait un bilan depuis le présent du locuteur, ce qui contredirait la phrase : elle vient justement de parler devant un jury. « Ne parlait jamais » (imparfait) décrirait une habitude de fond sans la borner avant l''entretien, et s''accorde mal avec « auparavant ». « Ne parla jamais » (passé simple) énoncerait un fait définitif sur toute sa vie, incompatible avec sa prestation réussie.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_plus_que_parfait');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('33333333-c01a-2100-0000-000000000001', '33333333-c01a-1000-0000-000000000001', 'partait', 'false', '1'),
  ('33333333-c01a-2200-0000-000000000001', '33333333-c01a-1000-0000-000000000001', 'était parti', 'true', '2'),
  ('33333333-c01a-2300-0000-000000000001', '33333333-c01a-1000-0000-000000000001', 'est parti', 'false', '3'),
  ('33333333-c01a-2400-0000-000000000001', '33333333-c01a-1000-0000-000000000001', 'partit', 'false', '4'),

  ('33333333-c01a-2100-0000-000000000002', '33333333-c01a-1000-0000-000000000002', 'a classé', 'false', '1'),
  ('33333333-c01a-2200-0000-000000000002', '33333333-c01a-1000-0000-000000000002', 'classait', 'false', '2'),
  ('33333333-c01a-2300-0000-000000000002', '33333333-c01a-1000-0000-000000000002', 'classa', 'false', '3'),
  ('33333333-c01a-2400-0000-000000000002', '33333333-c01a-1000-0000-000000000002', 'avait classé', 'true', '4'),

  ('33333333-c01a-2100-0000-000000000003', '33333333-c01a-1000-0000-000000000003', 'avait travaillé', 'true', '1'),
  ('33333333-c01a-2200-0000-000000000003', '33333333-c01a-1000-0000-000000000003', 'a travaillé', 'false', '2'),
  ('33333333-c01a-2300-0000-000000000003', '33333333-c01a-1000-0000-000000000003', 'travaillait', 'false', '3'),
  ('33333333-c01a-2400-0000-000000000003', '33333333-c01a-1000-0000-000000000003', 'travailla', 'false', '4'),

  ('33333333-c01a-2100-0000-000000000004', '33333333-c01a-1000-0000-000000000004', 'ont quitté', 'false', '1'),
  ('33333333-c01a-2200-0000-000000000004', '33333333-c01a-1000-0000-000000000004', 'quittaient', 'false', '2'),
  ('33333333-c01a-2300-0000-000000000004', '33333333-c01a-1000-0000-000000000004', 'avaient quitté', 'true', '3'),
  ('33333333-c01a-2400-0000-000000000004', '33333333-c01a-1000-0000-000000000004', 'quittèrent', 'false', '4'),

  ('33333333-c01a-2100-0000-000000000005', '33333333-c01a-1000-0000-000000000005', 'avait suivi', 'true', '1'),
  ('33333333-c01a-2200-0000-000000000005', '33333333-c01a-1000-0000-000000000005', 'suivait', 'false', '2'),
  ('33333333-c01a-2300-0000-000000000005', '33333333-c01a-1000-0000-000000000005', 'a suivi', 'false', '3'),
  ('33333333-c01a-2400-0000-000000000005', '33333333-c01a-1000-0000-000000000005', 'suivit', 'false', '4'),

  ('33333333-c01a-2100-0000-000000000006', '33333333-c01a-1000-0000-000000000006', 'n''a jamais parlé', 'false', '1'),
  ('33333333-c01a-2200-0000-000000000006', '33333333-c01a-1000-0000-000000000006', 'ne parlait jamais', 'false', '2'),
  ('33333333-c01a-2300-0000-000000000006', '33333333-c01a-1000-0000-000000000006', 'n''avait jamais parlé', 'true', '3'),
  ('33333333-c01a-2400-0000-000000000006', '33333333-c01a-1000-0000-000000000006', 'ne parla jamais', 'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 6 items, UUID déterministes (33333333-c01a-1000-…-01..06 / choices 2100-2400).
-- [x] 4 propositions / 1 seule correcte par item ; options de même catégorie
--     (4 formes conjuguées du même verbe : plus-que-parfait, passé composé,
--     imparfait, passé simple — toutes grammaticalement existantes).
-- [x] Distribution des bonnes réponses : pos1:2, pos2:1, pos3:2, pos4:1
--     (4 positions utilisées, aucune ne dépasse 2 — max autorisé 3).
-- [x] Point unique : plus-que-parfait & antériorité dans le passé, avec un
--     ancrage non ambigu par item (« déjà », « la veille », « la nuit
--     précédente », « depuis plusieurs minutes », « quinze ans plus tôt »,
--     « auparavant ») — aucun point de la liste interdite (pas de concordance
--     des temps en complétive, pas de discours rapporté, pas de conditionnel
--     passé ni de futur antérieur dans les options).
-- [x] explanation ≥ 80 caractères, point clé en **gras**, règle nommée
--     (antériorité dans le passé / repère relatif / état résultant), et les
--     3 distracteurs démontés un à un.
-- [x] Contextes tous différents (quai de gare, contrat égaré au bureau,
--     endormissement en réunion, évacuation d''immeuble, retrouvailles avec un
--     professeur, entretien d''embauche) ; prénoms et lieux variés (Fatou,
--     Mehdi, Tomas, Pavel, Aïcha — Bordeaux, Nantes).
-- [x] Contenu 100 % original ; pas de SVG ni SSML (items texte purs).
-- [x] Apostrophes SQL doublées ; format identique à l''exemplaire V661.
-- ============================================================================
