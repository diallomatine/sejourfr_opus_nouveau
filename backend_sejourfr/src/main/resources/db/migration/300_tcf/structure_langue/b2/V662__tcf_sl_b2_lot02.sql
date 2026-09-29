-- ============================================================================
-- V662 — TCF SL B2 — lot 02 (point : concordance des temps)
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id 22222222-0000-0000-0000-000000000003, difficulty='B2'.
-- 7 items, tous sur la concordance des temps dans la subordonnée complétive :
-- simultanéité (imparfait), postériorité (conditionnel présent = futur du
-- passé), principale au présent (futur simple conservé). Contenu original,
-- déterministe.
-- ============================================================================

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('33333333-c002-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Nadia croyait que son frère ___ encore dans une imprimerie de Lyon. »',
   'La **concordance des temps** impose l''imparfait pour exprimer la **simultanéité dans le passé** : au moment où Nadia « croyait », son frère y travaillait (croyance et situation sont contemporaines, confirmé par « encore ») → « travaillait ». « Travaille » laisse un présent non transposé après une principale au passé, faute de concordance en français standard (ce n''est pas une vérité générale). « Travaillera » est impossible : après une principale au passé, la postériorité se rend par le conditionnel, jamais par le futur simple. « Avait travaillé » (plus-que-parfait) marquerait une antériorité achevée, contredite par « encore ».',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_concordance_temps'),

  ('33333333-c002-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Bilal était convaincu que les travaux de ravalement de son immeuble à Strasbourg ___ avant l''hiver. »',
   'La **concordance des temps** exige le **conditionnel présent à valeur de futur du passé** pour la **postériorité** : la fin des travaux est postérieure au moment où Bilal « était convaincu » → « s''achèveraient ». « S''achèveront » conserve un futur simple, incompatible avec une principale au passé (le futur simple ne s''emploie qu''après une principale au présent). « S''achevaient » exprimerait une simultanéité, or les travaux ne sont pas en train de se terminer au moment de sa conviction. « S''achèvent » est un présent non transposé, faute de concordance.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_concordance_temps'),

  ('33333333-c002-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Lan sait que les notes du semestre ___ publiées jeudi prochain sur le portail de l''université de Rennes. »',
   'La principale est au **présent** (« sait ») : la **concordance des temps** n''impose alors aucune transposition, et un fait à venir (« jeudi prochain ») se rend par le **futur simple** → « seront ». « Seraient » est un futur du passé : il ne se justifierait que si la principale était au passé (« Lan savait que… seraient »). « Étaient » (imparfait) renverrait à une situation passée, incompatible avec « jeudi prochain ». « Avaient été » (plus-que-parfait) marquerait une antériorité dans le passé, doublement incohérente avec une principale au présent et une date future.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_concordance_temps'),

  ('33333333-c002-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Depuis le quai, Fatou a remarqué que le ferry ___ déjà du port d''Ajaccio. »',
   'La **concordance des temps** demande l''**imparfait de simultanéité** : l''action est en cours au moment de la perception passée (« a remarqué »), ce que renforce « déjà » → « s''éloignait ». « S''éloigne » laisse un présent non transposé après une principale au passé, faute de concordance. « S''est éloigné » présenterait le départ comme un fait entièrement accompli, alors que Fatou observe le mouvement en train de se faire. « S''éloignerait » (futur du passé) placerait le départ après la perception, absurde puisqu''elle voit la scène en direct.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_concordance_temps'),

  ('33333333-c002-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Yusuf espérait que son propriétaire ___ la chaudière avant les premières gelées. »',
   'Après « espérait » (principale au passé), la **concordance des temps** rend la **postériorité** par le **conditionnel présent, futur du passé** : le remplacement est attendu pour plus tard → « remplacerait ». « Remplacera » garde un futur simple, réservé aux principales au présent (« Yusuf espère que… remplacera »). « Remplaçait » exprimerait une simultanéité (réparation en cours), contraire au sens : l''espoir porte sur un fait encore à venir. « A remplacé » présenterait le fait comme accompli, ce qui annulerait l''attente exprimée par « espérait ».',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_concordance_temps'),

  ('33333333-c002-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « En arrivant au laboratoire, Ana s''est aperçue que son badge d''accès ne ___ plus. »',
   'La **concordance des temps** veut l''**imparfait de simultanéité** : l''état constaté (la panne) coïncide avec le moment du constat passé (« s''est aperçue ») → « fonctionnait ». « Fonctionne » conserve un présent non transposé après une principale au passé : la concordance l''exclut en français standard, car il ne s''agit pas d''une vérité générale. « Fonctionnera » (futur simple) est doublement fautif : postériorité non pertinente et futur interdit après une principale au passé. « A fonctionné » décrirait un fait accompli antérieur, contredit par « ne … plus » qui exprime une panne en cours au moment du constat.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_concordance_temps'),

  ('33333333-c002-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Ce matin-là, Marco ignorait encore qu''il ___ son permis de conduire deux semaines plus tard. »',
   'Le repère est passé (« ignorait ») et « deux semaines plus tard » situe le fait **après** ce repère : la **concordance des temps** impose le **conditionnel présent à valeur de futur du passé** → « obtiendrait ». « Obtiendra » garde un futur simple, qui ne peut suivre une principale au passé (il faudrait « Marco ignore qu''il obtiendra »). « Obtient » est un présent non transposé, faute de concordance. « Avait obtenu » (plus-que-parfait) exprimerait une antériorité, en contradiction directe avec « plus tard », qui oriente vers l''avenir du point de vue passé.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_concordance_temps');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('33333333-c002-2100-0000-000000000001', '33333333-c002-1000-0000-000000000001', 'travaille', 'false', '1'),
  ('33333333-c002-2200-0000-000000000001', '33333333-c002-1000-0000-000000000001', 'travaillait', 'true', '2'),
  ('33333333-c002-2300-0000-000000000001', '33333333-c002-1000-0000-000000000001', 'travaillera', 'false', '3'),
  ('33333333-c002-2400-0000-000000000001', '33333333-c002-1000-0000-000000000001', 'avait travaillé', 'false', '4'),

  ('33333333-c002-2100-0000-000000000002', '33333333-c002-1000-0000-000000000002', 's''achèvent', 'false', '1'),
  ('33333333-c002-2200-0000-000000000002', '33333333-c002-1000-0000-000000000002', 's''achevaient', 'false', '2'),
  ('33333333-c002-2300-0000-000000000002', '33333333-c002-1000-0000-000000000002', 's''achèveront', 'false', '3'),
  ('33333333-c002-2400-0000-000000000002', '33333333-c002-1000-0000-000000000002', 's''achèveraient', 'true', '4'),

  ('33333333-c002-2100-0000-000000000003', '33333333-c002-1000-0000-000000000003', 'seront', 'true', '1'),
  ('33333333-c002-2200-0000-000000000003', '33333333-c002-1000-0000-000000000003', 'seraient', 'false', '2'),
  ('33333333-c002-2300-0000-000000000003', '33333333-c002-1000-0000-000000000003', 'étaient', 'false', '3'),
  ('33333333-c002-2400-0000-000000000003', '33333333-c002-1000-0000-000000000003', 'avaient été', 'false', '4'),

  ('33333333-c002-2100-0000-000000000004', '33333333-c002-1000-0000-000000000004', 's''éloigne', 'false', '1'),
  ('33333333-c002-2200-0000-000000000004', '33333333-c002-1000-0000-000000000004', 's''est éloigné', 'false', '2'),
  ('33333333-c002-2300-0000-000000000004', '33333333-c002-1000-0000-000000000004', 's''éloignait', 'true', '3'),
  ('33333333-c002-2400-0000-000000000004', '33333333-c002-1000-0000-000000000004', 's''éloignerait', 'false', '4'),

  ('33333333-c002-2100-0000-000000000005', '33333333-c002-1000-0000-000000000005', 'remplacerait', 'true', '1'),
  ('33333333-c002-2200-0000-000000000005', '33333333-c002-1000-0000-000000000005', 'remplacera', 'false', '2'),
  ('33333333-c002-2300-0000-000000000005', '33333333-c002-1000-0000-000000000005', 'remplaçait', 'false', '3'),
  ('33333333-c002-2400-0000-000000000005', '33333333-c002-1000-0000-000000000005', 'a remplacé', 'false', '4'),

  ('33333333-c002-2100-0000-000000000006', '33333333-c002-1000-0000-000000000006', 'fonctionne', 'false', '1'),
  ('33333333-c002-2200-0000-000000000006', '33333333-c002-1000-0000-000000000006', 'fonctionnera', 'false', '2'),
  ('33333333-c002-2300-0000-000000000006', '33333333-c002-1000-0000-000000000006', 'a fonctionné', 'false', '3'),
  ('33333333-c002-2400-0000-000000000006', '33333333-c002-1000-0000-000000000006', 'fonctionnait', 'true', '4'),

  ('33333333-c002-2100-0000-000000000007', '33333333-c002-1000-0000-000000000007', 'obtient', 'false', '1'),
  ('33333333-c002-2200-0000-000000000007', '33333333-c002-1000-0000-000000000007', 'obtiendrait', 'true', '2'),
  ('33333333-c002-2300-0000-000000000007', '33333333-c002-1000-0000-000000000007', 'obtiendra', 'false', '3'),
  ('33333333-c002-2400-0000-000000000007', '33333333-c002-1000-0000-000000000007', 'avait obtenu', 'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes (33333333-c002-1000-…-01..07 / choices 2100-2400).
-- [x] 4 propositions / 1 seule correcte par item ; options de même catégorie
--     (4 formes conjuguées du même verbe, toutes grammaticalement existantes).
-- [x] Distribution des bonnes réponses : pos1:2, pos2:2, pos3:1, pos4:2
--     (4 positions utilisées, aucune ne dépasse 2).
-- [x] Point unique : concordance des temps — simultanéité → imparfait (items
--     1, 4, 6), postériorité → conditionnel présent / futur du passé (items
--     2, 5, 7), principale au présent → futur simple conservé (item 3).
--     Aucun point de la liste interdite (pas de si + temps, pas de discours
--     rapporté transposé, pas de plus-que-parfait ni de futur antérieur en
--     réponse correcte, pas de conditionnel passé).
-- [x] explanation ≥ 80 caractères, nomme la règle (**gras**) et démonte
--     chacun des 3 distracteurs.
-- [x] Contextes tous différents (emploi du frère à Lyon, ravalement d''immeuble
--     à Strasbourg, notes universitaires à Rennes, ferry à Ajaccio, chaudière
--     à remplacer, badge de laboratoire, permis de conduire) ; prénoms variés
--     (Nadia, Bilal, Lan, Fatou, Yusuf, Ana, Marco).
-- [x] Contenu 100 % original ; pas de SVG ni SSML dans ce lot (items texte purs).
-- [x] Apostrophes SQL doublées ; pas de JSONB dans ce schéma (table choices).
-- ============================================================================
