-- ============================================================================
-- V675 — TCF SL B2 — lot 15 (point : hypothèse (si + temps))
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id 22222222-0000-0000-0000-000000000003, difficulty='B2'.
-- 7 items, tous sur le système hypothétique avec « si » : si + présent → futur /
-- impératif (réel), si + imparfait → conditionnel présent (irréel du présent),
-- si + plus-que-parfait → conditionnel passé (irréel du passé). Contenu original,
-- déterministe.
-- ============================================================================

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('33333333-c00f-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Si Mariam obtient son visa avant juillet, elle ___ ses études d''infirmière à Lyon dès la rentrée. »',
   'C''est l''hypothèse **réelle** : « si + présent » (« obtient ») appelle le **futur simple** dans la principale → « commencera » (la condition est jugée réalisable). « Commencerait » (conditionnel présent) exigerait « si + imparfait » (si elle obtenait). « Aurait commencé » (conditionnel passé) exigerait « si + plus-que-parfait » (si elle avait obtenu). « Commençait » (imparfait) appartient à la subordonnée en « si », jamais à la principale d''une hypothèse.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_hypothese_si_temps'),

  ('33333333-c00f-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Si nous ___ plus près du centre de Nantes, nous irions au travail à vélo plutôt qu''en voiture. »',
   'La principale au **conditionnel présent** (« nous irions ») signale l''**irréel du présent** : la subordonnée exige « si + **imparfait** » → « habitions ». Règle clé : **jamais de conditionnel ni de futur après « si » hypothétique**, ce qui élimine « habiterions » (conditionnel) et « habiterons » (futur). « Avions habité » (plus-que-parfait) construirait un irréel du passé et demanderait « nous serions allés » dans la principale, pas « nous irions ».',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_hypothese_si_temps'),

  ('33333333-c00f-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Si Tariq avait réservé son train pour Marseille trois semaines plus tôt, il ___ presque deux fois moins cher. »',
   'C''est l''**irréel du passé** : « si + plus-que-parfait » (« avait réservé ») appelle le **conditionnel passé** dans la principale → « aurait payé » (le fait ne s''est pas produit, on imagine ses conséquences révolues). « Paierait » (conditionnel présent) correspondrait à « si + imparfait » (si Tariq réservait). « Paiera » (futur) correspondrait à « si + présent » (si Tariq réserve). « Avait payé » (plus-que-parfait) ne peut figurer que dans la subordonnée en « si », jamais dans la principale.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_hypothese_si_temps'),

  ('33333333-c00f-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Si tu termines l''inventaire avant la fermeture, ___-moi directement à l''entrepôt de Villeurbanne. »',
   'Avec « si + **présent** » (« tu termines »), la principale peut prendre le futur, le présent ou — comme ici, pour donner une consigne — l''**impératif** → « rejoins » (hypothèse réelle suivie d''un ordre). « Rejoindrais » (conditionnel) supposerait « si + imparfait » et ne s''emploie pas à la 2ᵉ personne en consigne directe avec inversion. « Rejoignais » (imparfait) est un temps de la subordonnée hypothétique, pas de la principale. « Aurais rejoint » (conditionnel passé) exigerait « si + plus-que-parfait ».',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_hypothese_si_temps'),

  ('33333333-c00f-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Le club annulera la sortie en kayak sur la Dordogne s''il ___ trop de vent samedi matin. »',
   'La principale au **futur** (« annulera ») installe une hypothèse **réelle** : après « si », on emploie le **présent de l''indicatif** → « fait ». Règle absolue : **« si » hypothétique n''est jamais suivi du futur ni du conditionnel**, ce qui écarte « fera » et « ferait » malgré le sens futur de la phrase. « Faisait » (imparfait) déclencherait l''irréel du présent et imposerait « annulerait » dans la principale, ce qui ne correspond pas à « annulera ».',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_hypothese_si_temps'),

  ('33333333-c00f-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Si Olena parlait couramment portugais, elle ___ sans hésiter ce poste de cheffe de projet à Porto. »',
   'C''est l''**irréel du présent** : « si + imparfait » (« parlait ») appelle le **conditionnel présent** dans la principale → « accepterait » (situation imaginée, contraire à la réalité actuelle). « Acceptera » (futur) correspondrait à « si + présent » (si Olena parle couramment). « Aurait accepté » (conditionnel passé) correspondrait à « si + plus-que-parfait » (si elle avait parlé). « Acceptait » (imparfait) ne s''emploie pas dans la principale : c''est le temps de la subordonnée en « si ».',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_hypothese_si_temps'),

  ('33333333-c00f-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Si vous ___ le bulletin de la capitainerie, vous ne seriez jamais sortis en mer ce dimanche-là. »',
   'La principale au **conditionnel passé** (« vous ne seriez jamais sortis ») impose l''**irréel du passé** : la subordonnée exige « si + **plus-que-parfait** » → « aviez consulté ». « Auriez consulté » (conditionnel) est impossible : **pas de conditionnel après « si » hypothétique**. « Consultiez » (imparfait) construirait un irréel du présent et appellerait « vous ne sortiriez pas » dans la principale. « Avez consulté » (passé composé) décrirait un fait réel constaté, incompatible avec une principale au conditionnel passé.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_hypothese_si_temps');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('33333333-c00f-2100-0000-000000000001', '33333333-c00f-1000-0000-000000000001', 'commencera', 'true', '1'),
  ('33333333-c00f-2200-0000-000000000001', '33333333-c00f-1000-0000-000000000001', 'commencerait', 'false', '2'),
  ('33333333-c00f-2300-0000-000000000001', '33333333-c00f-1000-0000-000000000001', 'commençait', 'false', '3'),
  ('33333333-c00f-2400-0000-000000000001', '33333333-c00f-1000-0000-000000000001', 'aurait commencé', 'false', '4'),

  ('33333333-c00f-2100-0000-000000000002', '33333333-c00f-1000-0000-000000000002', 'habiterions', 'false', '1'),
  ('33333333-c00f-2200-0000-000000000002', '33333333-c00f-1000-0000-000000000002', 'habiterons', 'false', '2'),
  ('33333333-c00f-2300-0000-000000000002', '33333333-c00f-1000-0000-000000000002', 'habitions', 'true', '3'),
  ('33333333-c00f-2400-0000-000000000002', '33333333-c00f-1000-0000-000000000002', 'avions habité', 'false', '4'),

  ('33333333-c00f-2100-0000-000000000003', '33333333-c00f-1000-0000-000000000003', 'paierait', 'false', '1'),
  ('33333333-c00f-2200-0000-000000000003', '33333333-c00f-1000-0000-000000000003', 'aurait payé', 'true', '2'),
  ('33333333-c00f-2300-0000-000000000003', '33333333-c00f-1000-0000-000000000003', 'avait payé', 'false', '3'),
  ('33333333-c00f-2400-0000-000000000003', '33333333-c00f-1000-0000-000000000003', 'paiera', 'false', '4'),

  ('33333333-c00f-2100-0000-000000000004', '33333333-c00f-1000-0000-000000000004', 'rejoignais', 'false', '1'),
  ('33333333-c00f-2200-0000-000000000004', '33333333-c00f-1000-0000-000000000004', 'rejoindrais', 'false', '2'),
  ('33333333-c00f-2300-0000-000000000004', '33333333-c00f-1000-0000-000000000004', 'aurais rejoint', 'false', '3'),
  ('33333333-c00f-2400-0000-000000000004', '33333333-c00f-1000-0000-000000000004', 'rejoins', 'true', '4'),

  ('33333333-c00f-2100-0000-000000000005', '33333333-c00f-1000-0000-000000000005', 'fera', 'false', '1'),
  ('33333333-c00f-2200-0000-000000000005', '33333333-c00f-1000-0000-000000000005', 'faisait', 'false', '2'),
  ('33333333-c00f-2300-0000-000000000005', '33333333-c00f-1000-0000-000000000005', 'fait', 'true', '3'),
  ('33333333-c00f-2400-0000-000000000005', '33333333-c00f-1000-0000-000000000005', 'ferait', 'false', '4'),

  ('33333333-c00f-2100-0000-000000000006', '33333333-c00f-1000-0000-000000000006', 'accepterait', 'true', '1'),
  ('33333333-c00f-2200-0000-000000000006', '33333333-c00f-1000-0000-000000000006', 'acceptera', 'false', '2'),
  ('33333333-c00f-2300-0000-000000000006', '33333333-c00f-1000-0000-000000000006', 'aurait accepté', 'false', '3'),
  ('33333333-c00f-2400-0000-000000000006', '33333333-c00f-1000-0000-000000000006', 'acceptait', 'false', '4'),

  ('33333333-c00f-2100-0000-000000000007', '33333333-c00f-1000-0000-000000000007', 'consultiez', 'false', '1'),
  ('33333333-c00f-2200-0000-000000000007', '33333333-c00f-1000-0000-000000000007', 'aviez consulté', 'true', '2'),
  ('33333333-c00f-2300-0000-000000000007', '33333333-c00f-1000-0000-000000000007', 'auriez consulté', 'false', '3'),
  ('33333333-c00f-2400-0000-000000000007', '33333333-c00f-1000-0000-000000000007', 'avez consulté', 'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes (33333333-c00f-1000-…-01..07 / choices 2100-2400).
-- [x] 4 propositions / 1 seule correcte par item ; options de même catégorie
--     (4 formes conjuguées du même verbe à chaque fois, toutes existantes).
-- [x] Distribution des bonnes réponses : pos1:2, pos2:2, pos3:2, pos4:1
--     (4 positions utilisées, aucune ne dépasse 2 ; max autorisé 3).
-- [x] Point unique : hypothèse (si + temps) — réel (si + présent → futur ;
--     si + présent → impératif), irréel du présent (si + imparfait ↔ conditionnel
--     présent, testé dans les deux sens), irréel du passé (si + plus-que-parfait ↔
--     conditionnel passé, testé dans les deux sens), interdiction du futur /
--     conditionnel après « si ». Aucun point de la liste interdite comme objet du
--     test.
-- [x] explanation ≥ 80 caractères, règle nommée en **gras** (réel / irréel du
--     présent / irréel du passé / jamais de futur-conditionnel après « si »),
--     chacun des 3 distracteurs démonté.
-- [x] Contextes tous différents (visa et études d''infirmière à Lyon, logement à
--     Nantes et vélotaf, billet de train pour Marseille, inventaire et entrepôt à
--     Villeurbanne, sortie kayak sur la Dordogne, poste de cheffe de projet à
--     Porto, sortie en mer et capitainerie) ; prénoms variés (Mariam, Tariq,
--     Olena).
-- [x] Contenu 100 % original ; pas de SVG ni SSML dans ce lot (items texte purs).
-- [x] Apostrophes SQL doublées ; pas de JSONB dans ce schéma (table choices).
-- ============================================================================
