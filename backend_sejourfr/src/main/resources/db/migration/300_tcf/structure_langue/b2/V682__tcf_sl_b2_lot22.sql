-- ============================================================================
-- V682 — TCF SL B2 — lot 22 (point : mise en relief (c'est…qui / c'est…que))
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id 22222222-0000-0000-0000-000000000003, difficulty='B2'.
-- 7 items, tous sur la mise en relief : phrase clivée « c'est… qui/que » (sujet
-- vs complément, préposition déplacée, temps/lieu) et pseudo-clivée
-- « ce qui / ce que…, c'est… ». Contenu original, déterministe.
-- ============================================================================

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('33333333-c016-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « C''est la voisine de Samba ___ a signalé la fuite d''eau au syndic de l''immeuble. »',
   'Dans une **phrase clivée (mise en relief « c''est… qui / c''est… que »)**, on emploie « qui » quand l''élément encadré est le **sujet** du verbe de la relative : c''est bien la voisine qui signale → « c''est la voisine qui a signalé ». « Que » s''emploierait si l''élément mis en relief était un complément (c''est la fuite d''eau que la voisine a signalée). « Dont » reprend un complément introduit par « de » (la voisine dont Samba parle), ce qui ne correspond pas à « signaler ». « Où » met en relief un lieu ou un moment, absents ici.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_mise_en_relief'),

  ('33333333-c016-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « C''est en septembre 2021 ___ Mariam a décroché son premier contrat à Strasbourg. »',
   'Pour mettre en relief un **complément de temps dans la clivée**, on referme toujours la structure par « c''est… **que** » : la préposition « en » reste dans le segment encadré → « c''est en septembre 2021 que ». « Où » est le piège classique : il appartient à la relative ordinaire (l''année où Mariam a signé), pas à la clivée. « Qui » exigerait que l''élément encadré soit le sujet du verbe, or « septembre 2021 » ne décroche rien. « Dont » reprend un complément introduit par « de » (le contrat dont elle rêvait), sans rapport ici.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_mise_en_relief'),

  ('33333333-c016-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « C''est dans cette médiathèque ___ Tomás prépare son concours d''aide-soignant chaque soir. »',
   'Même pour un **complément de lieu, la clivée se referme par « que »** : la préposition « dans » figure déjà dans le segment mis en relief → « c''est dans cette médiathèque que ». « Où » conviendrait seulement dans une relative ordinaire sans clivée (la médiathèque où Tomás travaille) ; après « c''est dans… », il ferait doublon avec « dans ». « Qui » supposerait que la médiathèque soit le sujet de « prépare ». « Dont » reprendrait un complément introduit par « de » (la médiathèque dont il parle).',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_mise_en_relief'),

  ('33333333-c016-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Ce ___ Bintou redoute avant tout, c''est l''entretien oral de fin de formation. »',
   'Dans la **pseudo-clivée « ce que…, c''est… » (mise en relief)**, « que » s''impose quand l''élément détaché est le **COD** du verbe : « redouter quelque chose » est transitif direct → « ce que Bintou redoute ». « Qui » ferait de « ce » le sujet (ce qui inquiète Bintou…), or le sujet de « redoute » est déjà « Bintou ». « Dont » exigerait un verbe construit avec « de » (se souvenir de). « À quoi » exigerait un verbe construit avec « à » (ce à quoi Bintou pense), ce qui n''est pas le cas de « redouter ».',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_mise_en_relief'),

  ('33333333-c016-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Ce ___ motive Karim depuis son arrivée à Lille, c''est l''idée d''ouvrir son propre atelier de couture. »',
   'Dans la **pseudo-clivée « ce qui…, c''est… » (mise en relief)**, « qui » s''impose quand « ce » est le **sujet** du verbe : quelque chose motive Karim → « ce qui motive Karim ». « Que » ferait de « ce » un COD, or « motive » a déjà son COD (« Karim ») et il lui manquerait alors un sujet. « Dont » exigerait une construction en « de » (ce dont Karim se réjouit). « À quoi » exigerait une construction en « à » (ce à quoi Karim aspire), incompatible avec « motiver quelqu''un », transitif direct.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_mise_en_relief'),

  ('33333333-c016-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « C''est à sa formatrice ___ Aïcha doit ses progrès rapides à l''oral. »',
   'Quand on met en relief un **complément prépositionnel dans la clivée, la préposition accompagne l''élément encadré et la structure se referme par « que »** : « devoir quelque chose **à** quelqu''un » → « c''est à sa formatrice que ». « À laquelle » créerait un pléonasme, la préposition « à » étant exprimée deux fois (c''est à sa formatrice à laquelle…) — faute fréquente à l''oral. « Qui » supposerait que la formatrice soit le sujet de « doit », or le sujet est « Aïcha ». « Dont » reprendrait un complément introduit par « de » (la formatrice dont elle parle).',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_mise_en_relief'),

  ('33333333-c016-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Ce n''est pas le salaire ___ a fait hésiter Pavel, c''est la durée du trajet quotidien jusqu''à Cergy. »',
   'La **clivée négative « ce n''est pas… qui »** obéit à la même règle que la clivée affirmative : l''élément mis en relief (« le salaire ») est le **sujet** de « a fait hésiter » → « qui ». « Que » s''emploierait si l''élément détaché était un complément (ce n''est pas le salaire que Pavel critique). « Dont » reprendrait un complément introduit par « de » (le salaire dont il se contente). « Où » met en relief un cadre spatial ou temporel, ce que « le salaire » n''est pas.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_mise_en_relief');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('33333333-c016-2100-0000-000000000001', '33333333-c016-1000-0000-000000000001', 'que', 'false', '1'),
  ('33333333-c016-2200-0000-000000000001', '33333333-c016-1000-0000-000000000001', 'qui', 'true', '2'),
  ('33333333-c016-2300-0000-000000000001', '33333333-c016-1000-0000-000000000001', 'dont', 'false', '3'),
  ('33333333-c016-2400-0000-000000000001', '33333333-c016-1000-0000-000000000001', 'où', 'false', '4'),

  ('33333333-c016-2100-0000-000000000002', '33333333-c016-1000-0000-000000000002', 'qui', 'false', '1'),
  ('33333333-c016-2200-0000-000000000002', '33333333-c016-1000-0000-000000000002', 'où', 'false', '2'),
  ('33333333-c016-2300-0000-000000000002', '33333333-c016-1000-0000-000000000002', 'dont', 'false', '3'),
  ('33333333-c016-2400-0000-000000000002', '33333333-c016-1000-0000-000000000002', 'que', 'true', '4'),

  ('33333333-c016-2100-0000-000000000003', '33333333-c016-1000-0000-000000000003', 'que', 'true', '1'),
  ('33333333-c016-2200-0000-000000000003', '33333333-c016-1000-0000-000000000003', 'où', 'false', '2'),
  ('33333333-c016-2300-0000-000000000003', '33333333-c016-1000-0000-000000000003', 'qui', 'false', '3'),
  ('33333333-c016-2400-0000-000000000003', '33333333-c016-1000-0000-000000000003', 'dont', 'false', '4'),

  ('33333333-c016-2100-0000-000000000004', '33333333-c016-1000-0000-000000000004', 'qui', 'false', '1'),
  ('33333333-c016-2200-0000-000000000004', '33333333-c016-1000-0000-000000000004', 'dont', 'false', '2'),
  ('33333333-c016-2300-0000-000000000004', '33333333-c016-1000-0000-000000000004', 'que', 'true', '3'),
  ('33333333-c016-2400-0000-000000000004', '33333333-c016-1000-0000-000000000004', 'à quoi', 'false', '4'),

  ('33333333-c016-2100-0000-000000000005', '33333333-c016-1000-0000-000000000005', 'qui', 'true', '1'),
  ('33333333-c016-2200-0000-000000000005', '33333333-c016-1000-0000-000000000005', 'que', 'false', '2'),
  ('33333333-c016-2300-0000-000000000005', '33333333-c016-1000-0000-000000000005', 'à quoi', 'false', '3'),
  ('33333333-c016-2400-0000-000000000005', '33333333-c016-1000-0000-000000000005', 'dont', 'false', '4'),

  ('33333333-c016-2100-0000-000000000006', '33333333-c016-1000-0000-000000000006', 'qui', 'false', '1'),
  ('33333333-c016-2200-0000-000000000006', '33333333-c016-1000-0000-000000000006', 'que', 'true', '2'),
  ('33333333-c016-2300-0000-000000000006', '33333333-c016-1000-0000-000000000006', 'à laquelle', 'false', '3'),
  ('33333333-c016-2400-0000-000000000006', '33333333-c016-1000-0000-000000000006', 'dont', 'false', '4'),

  ('33333333-c016-2100-0000-000000000007', '33333333-c016-1000-0000-000000000007', 'que', 'false', '1'),
  ('33333333-c016-2200-0000-000000000007', '33333333-c016-1000-0000-000000000007', 'dont', 'false', '2'),
  ('33333333-c016-2300-0000-000000000007', '33333333-c016-1000-0000-000000000007', 'où', 'false', '3'),
  ('33333333-c016-2400-0000-000000000007', '33333333-c016-1000-0000-000000000007', 'qui', 'true', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes (33333333-c016-1000-…-01..07 / choices 2100-2400).
-- [x] 4 propositions / 1 seule correcte par item ; options de même catégorie
--     (pronoms de la clivée : qui, que, dont, où, à quoi, à laquelle — toutes
--     grammaticalement existantes).
-- [x] Distribution des bonnes réponses : pos1:2, pos2:2, pos3:1, pos4:2
--     (4 positions utilisées, aucune ne dépasse 2).
-- [x] Point unique : mise en relief « c''est… qui / c''est… que » — clivée sujet
--     (items 1, 7), clivée temps/lieu avec piège « où » (items 2, 3), clivée à
--     préposition déplacée avec piège pléonasme (item 6), pseudo-clivée
--     « ce qui / ce que…, c''est… » (items 4, 5). Aucun point de la liste interdite
--     (« dont »/« à quoi »/« à laquelle » n''apparaissent qu''en distracteurs).
-- [x] explanation ≥ 80 caractères, règle nommée en **gras** (clivée, pseudo-clivée,
--     préposition déplacée) et démonte chacun des 3 distracteurs.
-- [x] Contextes tous différents (fuite d''eau / syndic, premier contrat à
--     Strasbourg, concours d''aide-soignant en médiathèque, entretien oral de
--     formation, projet d''atelier de couture à Lille, formatrice et progrès à
--     l''oral, hésitation salaire vs trajet jusqu''à Cergy) ; prénoms variés
--     (Samba, Mariam, Tomás, Bintou, Karim, Aïcha, Pavel).
-- [x] Contenu 100 % original ; pas de SVG ni SSML dans ce lot (items texte purs).
-- [x] Apostrophes SQL doublées ; pas de JSONB dans ce schéma (table choices).
-- ============================================================================
