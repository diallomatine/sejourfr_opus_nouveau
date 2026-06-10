-- ============================================================================
-- V635 — TCF SL B1 — lot 01 (point : imparfait vs passé composé)
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id 22222222-0000-0000-0000-000000000003, difficulty='B1'.
-- 10 items, tous sur le contraste imparfait / passé composé (haut du B1) :
-- action en cours interrompue, événement daté, habitude passée, verbe d''état
-- ponctuel, durée close, arrière-plan descriptif, habitude rompue, depuis au
-- passé, succession de premier plan, « un jour » dans un cadre imparfait.
-- UUID déterministes, rejouables dev + recette.
-- ============================================================================

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('33333333-b001-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « Lucia ___ tranquillement sur son balcon quand l''orage a éclaté au-dessus de Toulouse. »',
   'Le mécanisme testé est l''**action en cours interrompue** : la lecture forme l''arrière-plan installé au moment où surgit l''événement ponctuel « l''orage a éclaté » (passé composé) → imparfait « lisait ». « A lu » présenterait la lecture comme un second événement ponctuel achevé du premier plan, en concurrence avec l''orage, alors qu''elle était en cours. « Lira » est un futur simple, impossible dans un récit au passé. « Aurait lu » est un conditionnel passé, qui exprimerait une hypothèse irréelle ou un regret.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_imparfait_passe_compose'),

  ('33333333-b001-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « En mars 2021, Wei ___ son premier restaurant de cuisine du Sichuan à Nantes. »',
   'L''indicateur daté « en mars 2021 » associé à un **événement unique qui fait avancer le récit** (l''ouverture, fait accompli et délimité) impose le passé composé « a ouvert ». « Ouvrait » poserait un arrière-plan ou une habitude — incompatible avec un fait unique localisé à une date précise. « Ouvrira » est un futur, contradictoire avec la date passée. « Avait ouvert » (plus-que-parfait) marquerait une antériorité par rapport à une autre action passée, qui n''existe pas dans la phrase.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_imparfait_passe_compose'),

  ('33333333-b001-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « Quand elle vivait à Porto, Priya ___ chaque matin le long du fleuve avant d''aller à l''hôpital. »',
   'Le cadre « quand elle vivait » et l''indicateur de fréquence « chaque matin » signalent une **habitude répétée dans le passé** → imparfait « courait ». « A couru » désignerait une course ponctuelle, faite une seule fois et achevée — contradictoire avec « chaque matin ». « Courra » est un futur, hors du cadre passé posé par « vivait ». « Aurait couru » est un conditionnel passé : il exprimerait un fait non réalisé ou une information non confirmée, pas une habitude réelle.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_imparfait_passe_compose'),

  ('33333333-b001-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « Quand la directrice a annoncé la fermeture de l''atelier, Rachid ___ d''abord stupéfait, puis il a posé des questions. »',
   'Piège fin : un verbe d''état peut prendre le passé composé quand il exprime un **changement d''état ponctuel déclenché par un événement** et inscrit dans une succession (« d''abord… puis il a posé ») → « a été ». « Était » décrirait un état d''arrière-plan déjà installé AVANT l''annonce ; or la stupéfaction naît de l''annonce, c''est une réaction. « Serait » est un conditionnel présent (hypothèse), « sera » un futur simple : aucun des deux ne s''insère dans cette chaîne de récit au passé.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_imparfait_passe_compose'),

  ('33333333-b001-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « Diego ___ huit ans à Marseille avant de s''installer définitivement à Lille en 2023. »',
   'Une **durée chiffrée et close** (« huit ans… avant de s''installer ») se traite comme un bloc achevé : passé composé « a vécu », même pour un verbe duratif comme « vivre ». « Vivait » servirait à planter un décor sans bornes (« à l''époque, il vivait à Marseille »), pas à mesurer une période terminée. « Vivra » est un futur, incompatible avec 2023 déjà passé. « Vivrait » est un conditionnel présent : il exprimerait une hypothèse ou un futur dans le passé, pas un fait accompli.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_imparfait_passe_compose'),

  ('33333333-b001-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « Le soir de la panne générale, le quartier ___ étrangement silencieux : on n''entendait que la pluie sur les toits. »',
   'La phrase est une pure **description d''arrière-plan** : aucun événement ne survient, aucune borne, et le second verbe (« on n''entendait ») confirme le décor → imparfait « était ». « A été » transformerait l''état en événement délimité du premier plan ; il faudrait alors une borne explicite (« le quartier a été silencieux pendant deux heures »). « Serait » est un conditionnel (information supposée). « Avait été » (plus-que-parfait) renverrait à un état antérieur à un autre repère passé, absent ici.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_imparfait_passe_compose'),

  ('33333333-b001-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « D''habitude, Fatou prenait le tramway pour aller à la clinique, mais ce matin-là elle ___ à vélo à cause de la grève. »',
   'Contraste classique du haut B1 : l''habitude est posée à l''imparfait (« prenait »), puis « mais » + l''indicateur « ce matin-là » isolent un **événement unique qui rompt l''habitude** → passé composé « est allée ». « Allait » prolongerait l''habitude alors que « mais » signale précisément la rupture. « Ira » est un futur, étranger au récit passé. « Serait allée » est un conditionnel passé : il décrirait un scénario irréel (« sans le tramway, elle serait allée à vélo »), or le fait a bien eu lieu.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_imparfait_passe_compose'),

  ('33333333-b001-1000-0000-000000000008', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « Le concert ___ depuis à peine une heure quand l''alarme incendie a obligé les musiciens à quitter la scène. »',
   '« **Depuis + durée** » dans un contexte passé décrit une action encore en cours, non achevée, au moment où survient l''interruption (« l''alarme a obligé », passé composé) → imparfait « durait ». « A duré » donnerait la durée totale et close du concert (« le concert a duré une heure » = il est terminé), contradictoire avec une interruption en plein déroulement. « Aura duré » est un futur antérieur (bilan projeté). « Durerait » est un conditionnel, qui marquerait une supposition.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_imparfait_passe_compose'),

  ('33333333-b001-1000-0000-000000000009', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « Hier soir, Olena est rentrée tard, ___ la lumière du salon et a découvert le colis posé sur la table. »',
   'La phrase enchaîne des **actions ponctuelles successives de premier plan** (« est rentrée » → ? → « a découvert ») : chaque maillon de la chaîne prend le passé composé → « a allumé ». « Allumait » casserait la succession en basculant l''action en arrière-plan, comme si elle était en cours pendant les autres. « Allumera » est un futur, impossible avec « hier soir ». « Avait allumé » (plus-que-parfait) rendrait l''action antérieure au retour — absurde, puisqu''elle allume APRÈS être rentrée.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_imparfait_passe_compose'),

  ('33333333-b001-1000-0000-00000000000a', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « Enfant, Aïcha refusait d''approcher de l''eau ; pourtant, un jour, elle ___ dans le grand bassin avec sa classe, et tout a changé. »',
   'Le cadre d''habitude est à l''imparfait (« refusait ») ; l''indicateur « **un jour** », renforcé par « pourtant », fait surgir un **événement unique** qui tranche avec ce cadre → passé composé « a plongé ». « Plongeait » décrirait une habitude répétée, en contradiction directe avec « refusait d''approcher de l''eau ». « Plongera » est un futur, hors du récit d''enfance. « Aurait plongé » est un conditionnel passé : il signalerait un fait non réalisé, alors que la suite (« tout a changé ») prouve que le plongeon a bien eu lieu.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_imparfait_passe_compose');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('33333333-b001-2100-0000-000000000001', '33333333-b001-1000-0000-000000000001', 'a lu', 'false', '1'),
  ('33333333-b001-2200-0000-000000000001', '33333333-b001-1000-0000-000000000001', 'lisait', 'true', '2'),
  ('33333333-b001-2300-0000-000000000001', '33333333-b001-1000-0000-000000000001', 'lira', 'false', '3'),
  ('33333333-b001-2400-0000-000000000001', '33333333-b001-1000-0000-000000000001', 'aurait lu', 'false', '4'),

  ('33333333-b001-2100-0000-000000000002', '33333333-b001-1000-0000-000000000002', 'a ouvert', 'true', '1'),
  ('33333333-b001-2200-0000-000000000002', '33333333-b001-1000-0000-000000000002', 'ouvrait', 'false', '2'),
  ('33333333-b001-2300-0000-000000000002', '33333333-b001-1000-0000-000000000002', 'ouvrira', 'false', '3'),
  ('33333333-b001-2400-0000-000000000002', '33333333-b001-1000-0000-000000000002', 'avait ouvert', 'false', '4'),

  ('33333333-b001-2100-0000-000000000003', '33333333-b001-1000-0000-000000000003', 'a couru', 'false', '1'),
  ('33333333-b001-2200-0000-000000000003', '33333333-b001-1000-0000-000000000003', 'courra', 'false', '2'),
  ('33333333-b001-2300-0000-000000000003', '33333333-b001-1000-0000-000000000003', 'courait', 'true', '3'),
  ('33333333-b001-2400-0000-000000000003', '33333333-b001-1000-0000-000000000003', 'aurait couru', 'false', '4'),

  ('33333333-b001-2100-0000-000000000004', '33333333-b001-1000-0000-000000000004', 'était', 'false', '1'),
  ('33333333-b001-2200-0000-000000000004', '33333333-b001-1000-0000-000000000004', 'a été', 'true', '2'),
  ('33333333-b001-2300-0000-000000000004', '33333333-b001-1000-0000-000000000004', 'serait', 'false', '3'),
  ('33333333-b001-2400-0000-000000000004', '33333333-b001-1000-0000-000000000004', 'sera', 'false', '4'),

  ('33333333-b001-2100-0000-000000000005', '33333333-b001-1000-0000-000000000005', 'vivait', 'false', '1'),
  ('33333333-b001-2200-0000-000000000005', '33333333-b001-1000-0000-000000000005', 'vivra', 'false', '2'),
  ('33333333-b001-2300-0000-000000000005', '33333333-b001-1000-0000-000000000005', 'vivrait', 'false', '3'),
  ('33333333-b001-2400-0000-000000000005', '33333333-b001-1000-0000-000000000005', 'a vécu', 'true', '4'),

  ('33333333-b001-2100-0000-000000000006', '33333333-b001-1000-0000-000000000006', 'était', 'true', '1'),
  ('33333333-b001-2200-0000-000000000006', '33333333-b001-1000-0000-000000000006', 'a été', 'false', '2'),
  ('33333333-b001-2300-0000-000000000006', '33333333-b001-1000-0000-000000000006', 'serait', 'false', '3'),
  ('33333333-b001-2400-0000-000000000006', '33333333-b001-1000-0000-000000000006', 'avait été', 'false', '4'),

  ('33333333-b001-2100-0000-000000000007', '33333333-b001-1000-0000-000000000007', 'allait', 'false', '1'),
  ('33333333-b001-2200-0000-000000000007', '33333333-b001-1000-0000-000000000007', 'ira', 'false', '2'),
  ('33333333-b001-2300-0000-000000000007', '33333333-b001-1000-0000-000000000007', 'est allée', 'true', '3'),
  ('33333333-b001-2400-0000-000000000007', '33333333-b001-1000-0000-000000000007', 'serait allée', 'false', '4'),

  ('33333333-b001-2100-0000-000000000008', '33333333-b001-1000-0000-000000000008', 'a duré', 'false', '1'),
  ('33333333-b001-2200-0000-000000000008', '33333333-b001-1000-0000-000000000008', 'durait', 'true', '2'),
  ('33333333-b001-2300-0000-000000000008', '33333333-b001-1000-0000-000000000008', 'aura duré', 'false', '3'),
  ('33333333-b001-2400-0000-000000000008', '33333333-b001-1000-0000-000000000008', 'durerait', 'false', '4'),

  ('33333333-b001-2100-0000-000000000009', '33333333-b001-1000-0000-000000000009', 'allumait', 'false', '1'),
  ('33333333-b001-2200-0000-000000000009', '33333333-b001-1000-0000-000000000009', 'allumera', 'false', '2'),
  ('33333333-b001-2300-0000-000000000009', '33333333-b001-1000-0000-000000000009', 'avait allumé', 'false', '3'),
  ('33333333-b001-2400-0000-000000000009', '33333333-b001-1000-0000-000000000009', 'a allumé', 'true', '4'),

  ('33333333-b001-2100-0000-00000000000a', '33333333-b001-1000-0000-00000000000a', 'plongeait', 'false', '1'),
  ('33333333-b001-2200-0000-00000000000a', '33333333-b001-1000-0000-00000000000a', 'plongera', 'false', '2'),
  ('33333333-b001-2300-0000-00000000000a', '33333333-b001-1000-0000-00000000000a', 'a plongé', 'true', '3'),
  ('33333333-b001-2400-0000-00000000000a', '33333333-b001-1000-0000-00000000000a', 'aurait plongé', 'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes (33333333-b001-1000-…-01..0a, choices 2100/2200/2300/2400).
-- [x] 4 propositions / 1 correcte par item ; 4 formes verbales du même verbe à chaque fois.
-- [x] Distribution des bonnes réponses : pos1=2, pos2=3, pos3=3, pos4=2 (équilibrée, 4 positions utilisées).
-- [x] Tous les items sur imparfait vs passé composé, mécanismes tous différents :
--     interruption, événement daté, habitude, verbe d''état ponctuel, durée close,
--     arrière-plan, habitude rompue (« ce matin-là »), depuis au passé, succession, « un jour ».
-- [x] Aucun point interdit (pas de relatifs, y/en, subjonctif, connecteurs+gérondif, comparatifs/accord PP).
-- [x] explanation ≥ 80 caractères, point clé en **gras**, mécanisme nommé, 3 distracteurs démontés.
-- [x] Prénoms/villes variés et originaux (Lucia, Wei, Priya, Rachid, Diego, Fatou, Olena, Aïcha).
-- [x] Apostrophes SQL doublées partout ; pas de medias/passages (SVG/SSML : N/A pour SL).
-- [x] Longueurs de phrases homogènes, calibrées haut B1.
-- ============================================================================
