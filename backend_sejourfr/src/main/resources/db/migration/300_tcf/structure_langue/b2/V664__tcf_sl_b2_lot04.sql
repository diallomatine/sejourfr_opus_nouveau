-- ============================================================================
-- V664 — TCF SL B2 — lot 04 (point : conditionnel passé)
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id 22222222-0000-0000-0000-000000000003, difficulty='B2'.
-- 7 items, tous sur le conditionnel passé (reproche, regret, information non
-- confirmée, irréel du passé, souhait non réalisé). Contenu original, déterministe.
-- ============================================================================

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('33333333-c004-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Tu ___ me prévenir que la réunion de jeudi était annulée : j''ai traversé tout Lyon pour rien. »',
   'Le **reproche portant sur un fait passé** s''exprime au **conditionnel passé** du verbe devoir : « tu aurais dû me prévenir » (l''action attendue n''a pas eu lieu, et ses conséquences sont consommées). « Devais » (imparfait) décrirait une obligation en cours dans le passé, sans la valeur d''irréel propre au reproche. « Auras dû » (futur antérieur) projetterait l''obligation dans l''avenir, incompatible avec « j''ai traversé tout Lyon pour rien ». « Avais dû » (plus-que-parfait) affirmerait que l''obligation a bel et bien été remplie avant un autre fait passé, alors que justement rien n''a été fait.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_conditionnel_passe'),

  ('33333333-c004-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Selon les premiers témoignages, la tempête ___ une trentaine de toitures à Brest ; le bilan reste à confirmer. »',
   'Le **conditionnel passé journalistique** signale une **information passée non confirmée** : « selon les premiers témoignages » et « le bilan reste à confirmer » imposent « aurait endommagé », qui attribue l''information à une source sans la prendre en charge. « A endommagé » (passé composé) présenterait le fait comme avéré, en contradiction avec la réserve exprimée. « Aura endommagé » (futur antérieur de conjecture) marquerait une probabilité assumée par le locuteur lui-même, pas la prudence d''un fait rapporté. « Avait endommagé » (plus-que-parfait) exigerait une antériorité par rapport à un autre fait passé, absent de la phrase.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_conditionnel_passe'),

  ('33333333-c004-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « À vingt-cinq ans, Fatou ___ sans hésiter ce poste à Singapour ; aujourd''hui, sa vie de famille passe avant sa carrière. »',
   'L''**irréel du passé** : le repère temporel « à vingt-cinq ans » situe l''éventualité dans une période révolue → **conditionnel passé** « aurait accepté » (l''occasion appartient au passé et ne s''est pas réalisée). « Accepterait » (conditionnel présent) conviendrait pour un irréel du présent, ce que l''opposition avec « aujourd''hui » exclut précisément. « Acceptait » (imparfait) décrirait un fait ou une habitude réels de l''époque, pas une éventualité non réalisée. « Aura accepté » (futur antérieur) renverrait à un fait supposé accompli dans l''avenir, sans rapport avec le contexte.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_conditionnel_passe'),

  ('33333333-c004-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « J''___ découvrir le musée maritime pendant mon escale à La Rochelle, mais il était fermé pour travaux. »',
   'Le **regret portant sur une action passée non réalisée** s''exprime au **conditionnel passé** : « j''aurais aimé découvrir… mais il était fermé » (l''escale est terminée, la visite n''a pas pu avoir lieu). « Aimerais » (conditionnel présent) formulerait un souhait encore réalisable, incompatible avec une escale déjà passée. « Ai aimé » (passé composé) affirmerait que la visite a eu lieu et a plu, ce que « mais il était fermé » contredit. « Avais aimé » (plus-que-parfait) supposerait une visite antérieure réellement effectuée, l''inverse de ce que dit la phrase.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_conditionnel_passe'),

  ('33333333-c004-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Diego s''en veut encore : en réservant son vol pour Dakar trois mois plus tôt, il ___ près de deux cents euros. »',
   'Le gérondif « en réservant… plus tôt » exprime ici une **condition non réalisée dans le passé**, et « s''en veut encore » confirme le regret d''un fait accompli → **conditionnel passé** « aurait économisé ». « Économiserait » (conditionnel présent) laisserait entendre que la réservation est encore possible, ce que le regret exclut : le billet est déjà payé. « Avait économisé » (plus-que-parfait) affirmerait une économie réellement réalisée avant un autre fait passé. « Aura économisé » (futur antérieur) présenterait l''économie comme acquise à un moment de l''avenir, hors de propos pour un achat déjà conclu au mauvais prix.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_conditionnel_passe'),

  ('33333333-c004-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Votre dossier a été refusé ; vous ___ vérifier la date de validité de votre justificatif avant de le déposer. »',
   'Le **reproche atténué après coup** s''exprime au **conditionnel passé** du verbe pouvoir : « vous auriez pu vérifier » (l''occasion existait, elle n''a pas été saisie, et le refus est désormais consommé). « Pourriez » (conditionnel présent) formulerait une suggestion encore valable, incompatible avec « a été refusé ». « Pouviez » (imparfait) constaterait une simple capacité de l''époque, sans la valeur d''irréel que le reproche standard exige ici. « Avez pu » (passé composé) affirmerait que la vérification a effectivement eu lieu, en contradiction directe avec le refus du dossier.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_conditionnel_passe'),

  ('33333333-c004-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Olena ___ volontiers une semaine de plus à Lisbonne, mais son visa expirait le lendemain de son départ. »',
   'Le **souhait non réalisé dans le passé** appelle le **conditionnel passé**, ici avec l''auxiliaire être accordé : « serait restée » (le séjour est terminé, la prolongation n''a pas eu lieu à cause du visa). « Resterait » (conditionnel présent) exprimerait une envie encore d''actualité, incompatible avec le récit au passé (« expirait »). « Restait » (imparfait) décrirait un fait réel en cours de déroulement, ce que la concessive « mais » dément. « Était restée » (plus-que-parfait) affirmerait que la semaine supplémentaire a bel et bien été passée sur place, l''inverse du sens voulu.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_conditionnel_passe');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('33333333-c004-2100-0000-000000000001', '33333333-c004-1000-0000-000000000001', 'devais', 'false', '1'),
  ('33333333-c004-2200-0000-000000000001', '33333333-c004-1000-0000-000000000001', 'aurais dû', 'true', '2'),
  ('33333333-c004-2300-0000-000000000001', '33333333-c004-1000-0000-000000000001', 'auras dû', 'false', '3'),
  ('33333333-c004-2400-0000-000000000001', '33333333-c004-1000-0000-000000000001', 'avais dû', 'false', '4'),

  ('33333333-c004-2100-0000-000000000002', '33333333-c004-1000-0000-000000000002', 'aurait endommagé', 'true', '1'),
  ('33333333-c004-2200-0000-000000000002', '33333333-c004-1000-0000-000000000002', 'a endommagé', 'false', '2'),
  ('33333333-c004-2300-0000-000000000002', '33333333-c004-1000-0000-000000000002', 'aura endommagé', 'false', '3'),
  ('33333333-c004-2400-0000-000000000002', '33333333-c004-1000-0000-000000000002', 'avait endommagé', 'false', '4'),

  ('33333333-c004-2100-0000-000000000003', '33333333-c004-1000-0000-000000000003', 'accepterait', 'false', '1'),
  ('33333333-c004-2200-0000-000000000003', '33333333-c004-1000-0000-000000000003', 'acceptait', 'false', '2'),
  ('33333333-c004-2300-0000-000000000003', '33333333-c004-1000-0000-000000000003', 'aura accepté', 'false', '3'),
  ('33333333-c004-2400-0000-000000000003', '33333333-c004-1000-0000-000000000003', 'aurait accepté', 'true', '4'),

  ('33333333-c004-2100-0000-000000000004', '33333333-c004-1000-0000-000000000004', 'aimerais', 'false', '1'),
  ('33333333-c004-2200-0000-000000000004', '33333333-c004-1000-0000-000000000004', 'ai aimé', 'false', '2'),
  ('33333333-c004-2300-0000-000000000004', '33333333-c004-1000-0000-000000000004', 'aurais aimé', 'true', '3'),
  ('33333333-c004-2400-0000-000000000004', '33333333-c004-1000-0000-000000000004', 'avais aimé', 'false', '4'),

  ('33333333-c004-2100-0000-000000000005', '33333333-c004-1000-0000-000000000005', 'aurait économisé', 'true', '1'),
  ('33333333-c004-2200-0000-000000000005', '33333333-c004-1000-0000-000000000005', 'économiserait', 'false', '2'),
  ('33333333-c004-2300-0000-000000000005', '33333333-c004-1000-0000-000000000005', 'avait économisé', 'false', '3'),
  ('33333333-c004-2400-0000-000000000005', '33333333-c004-1000-0000-000000000005', 'aura économisé', 'false', '4'),

  ('33333333-c004-2100-0000-000000000006', '33333333-c004-1000-0000-000000000006', 'pouviez', 'false', '1'),
  ('33333333-c004-2200-0000-000000000006', '33333333-c004-1000-0000-000000000006', 'avez pu', 'false', '2'),
  ('33333333-c004-2300-0000-000000000006', '33333333-c004-1000-0000-000000000006', 'pourriez', 'false', '3'),
  ('33333333-c004-2400-0000-000000000006', '33333333-c004-1000-0000-000000000006', 'auriez pu', 'true', '4'),

  ('33333333-c004-2100-0000-000000000007', '33333333-c004-1000-0000-000000000007', 'restait', 'false', '1'),
  ('33333333-c004-2200-0000-000000000007', '33333333-c004-1000-0000-000000000007', 'serait restée', 'true', '2'),
  ('33333333-c004-2300-0000-000000000007', '33333333-c004-1000-0000-000000000007', 'resterait', 'false', '3'),
  ('33333333-c004-2400-0000-000000000007', '33333333-c004-1000-0000-000000000007', 'était restée', 'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes (33333333-c004-1000-…-01..07 / choices 2100-2400).
-- [x] 4 propositions / 1 seule correcte par item ; options de même catégorie
--     (4 formes verbales conjuguées du même verbe à chaque fois, toutes
--     grammaticalement existantes).
-- [x] Distribution des bonnes réponses : pos1:2, pos2:2, pos3:1, pos4:2
--     (4 positions utilisées, aucune ne dépasse 2).
-- [x] Point unique : conditionnel passé sous ses emplois B2 — reproche
--     (aurais dû, auriez pu), information non confirmée (aurait endommagé),
--     irréel du passé (aurait accepté, aurait économisé), regret (aurais aimé),
--     souhait non réalisé avec auxiliaire être (serait restée) — aucun point
--     de la liste interdite (pas de si + temps, pas de concordance, pas de
--     discours rapporté, pas de futur antérieur testé comme point).
-- [x] explanation ≥ 80 caractères, nomme la valeur du conditionnel passé
--     (**gras**) et démonte chacun des 3 distracteurs.
-- [x] Contextes tous différents (réunion annulée à Lyon, tempête à Brest,
--     carrière à Singapour, escale à La Rochelle, vol pour Dakar, dossier
--     administratif refusé, séjour à Lisbonne) ; prénoms variés (Fatou, Diego,
--     Olena) + je/tu/vous.
-- [x] Contenu 100 % original ; pas de SVG ni SSML dans ce lot (items texte purs).
-- [x] Apostrophes SQL doublées ; pas de JSONB dans ce schéma (table choices).
-- ============================================================================
