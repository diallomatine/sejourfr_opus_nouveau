-- ============================================================================
-- V665 — TCF SL B2 — lot 05 (point : voix passive)
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id 22222222-0000-0000-0000-000000000003, difficulty='B2'.
-- 7 items, tous sur la voix passive (accord du participe au passif, agent en
-- « de » vs « par », pronominal de sens passif, temps du passif, se faire +
-- infinitif, se voir + infinitif, actif vs passif des verbes intransitifs).
-- Contenu original, déterministe.
-- ============================================================================

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('33333333-c005-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « La nouvelle passerelle ___ au public dimanche dernier par les élus de Quimper. »',
   'La **voix passive** se forme avec « être » + participe passé **accordé avec le sujet** : « la passerelle » est féminin singulier → « a été ouverte ». « A été ouvert » oublie l''accord au féminin. « A ouvert » est une forme active, impossible ici : le sujet subit l''action et l''agent réel est introduit par « par les élus ». « S''est ouverte » (pronominal de sens passif) exclurait le complément d''agent — on ne peut pas dire « s''est ouverte par les élus ».',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_voix_passive'),

  ('33333333-c005-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « La maison de Svetlana est entourée ___ grands chênes centenaires. »',
   'Après un participe passif exprimant un **état ou une description** (entouré, couvert, bordé, décoré), le complément d''agent s''introduit par « **de** », sans article devant un pluriel indéterminé : « entourée de grands chênes ». « Par » introduit l''agent d''une véritable action ponctuelle (la maison a été entourée d''une clôture par un maçon) et exigerait ici un déterminant. « Avec » marque l''instrument d''une action active, jamais l''agent d''un passif d''état. « En » indique la matière (une table en chêne) et ne se construit pas après « entourée ».',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_voix_passive'),

  ('33333333-c005-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « En Alsace, ce fromage ___ traditionnellement avec des pommes de terre chaudes. »',
   'Pour exprimer un usage collectif dont l''agent est indéterminé (« les gens en général »), le français emploie la **forme pronominale de sens passif** : « ce fromage se mange ». « Est mangé », passif périphrastique, suppose un agent identifiable et rend la phrase peu naturelle pour une vérité générale d''usage. « S''est mangé », au passé composé, contredit « traditionnellement », qui appelle un présent de vérité générale. « Mange », forme active, ferait du fromage l''auteur de l''action, ce qui est absurde.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_voix_passive'),

  ('33333333-c005-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Les lauréats du concours ___ par courrier au début du mois de mars prochain. »',
   'Le marqueur temporel « au début du mois de mars **prochain** » impose le **futur simple passif** : « seront avertis », avec le participe **accordé** au masculin pluriel (« les lauréats »). « Sont avertis » (présent passif) et « ont été avertis » (passé composé passif) contredisent l''ancrage futur de la phrase. « Seront averti » a le bon temps mais oublie l''accord du participe passé avec le sujet pluriel, obligatoire à la voix passive construite avec « être ».',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_voix_passive'),

  ('33333333-c005-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « À la sortie du tramway de Montpellier, Aïcha ___ contrôler son titre de transport par deux agents. »',
   'La tournure « **se faire + infinitif** » exprime un passif d''événement subi : Aïcha subit le contrôle. Devant un infinitif, le participe « **fait » reste invariable** → « s''est fait contrôler », jamais « s''est faite contrôler » (faute d''accord classique). « A fait contrôler » est un factitif actif : Aïcha aurait fait contrôler quelqu''un d''autre, contresens total. « Est faite » est le passif du verbe « faire » lui-même et ne peut pas se construire avec un infinitif dans cette phrase.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_voix_passive'),

  ('33333333-c005-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Après dix ans dans l''entreprise, Mateus ___ confier la direction de l''agence de Nantes. »',
   'On « confie quelque chose **à** quelqu''un » : le bénéficiaire est un COI et ne peut pas devenir sujet d''un passif classique (« Mateus a été confié… » signifierait qu''on confie Mateus lui-même). La tournure « **se voir + infinitif** » est le seul passif qui donne au destinataire la place de sujet : « s''est vu confier la direction ». « A vu » est actif : Mateus aurait simplement assisté à la scène. « Est vu » (présent passif de « voir ») n''a pas cette valeur et casse le récit au passé. « Se voyait », à l''imparfait, ne convient pas à un événement ponctuel de promotion.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_voix_passive'),

  ('33333333-c005-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Le prix des carburants ___ de trois pour cent au mois d''octobre. »',
   '« Augmenter » s''emploie ici **intransitivement** : le prix monte sans agent exprimé → voix **active** « a augmenté ». C''est le piège inverse de la passivation : tout énoncé n''est pas passivable. « A été augmenté » supposerait un agent décideur explicite (le prix a été augmenté par le distributeur), absent ici — une évolution chiffrée constatée se dit à l''actif. « S''est augmenté » ne s''emploie que pour une personne qui augmente son propre salaire, jamais pour un prix. « Était augmenté » (imparfait passif) cumule les deux défauts : passif sans agent et aspect duratif incompatible avec une variation datée.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_voix_passive');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('33333333-c005-2100-0000-000000000001', '33333333-c005-1000-0000-000000000001', 'a été ouvert', 'false', '1'),
  ('33333333-c005-2200-0000-000000000001', '33333333-c005-1000-0000-000000000001', 'a été ouverte', 'true', '2'),
  ('33333333-c005-2300-0000-000000000001', '33333333-c005-1000-0000-000000000001', 'a ouvert', 'false', '3'),
  ('33333333-c005-2400-0000-000000000001', '33333333-c005-1000-0000-000000000001', 's''est ouverte', 'false', '4'),

  ('33333333-c005-2100-0000-000000000002', '33333333-c005-1000-0000-000000000002', 'de', 'true', '1'),
  ('33333333-c005-2200-0000-000000000002', '33333333-c005-1000-0000-000000000002', 'par', 'false', '2'),
  ('33333333-c005-2300-0000-000000000002', '33333333-c005-1000-0000-000000000002', 'avec', 'false', '3'),
  ('33333333-c005-2400-0000-000000000002', '33333333-c005-1000-0000-000000000002', 'en', 'false', '4'),

  ('33333333-c005-2100-0000-000000000003', '33333333-c005-1000-0000-000000000003', 'est mangé', 'false', '1'),
  ('33333333-c005-2200-0000-000000000003', '33333333-c005-1000-0000-000000000003', 's''est mangé', 'false', '2'),
  ('33333333-c005-2300-0000-000000000003', '33333333-c005-1000-0000-000000000003', 'se mange', 'true', '3'),
  ('33333333-c005-2400-0000-000000000003', '33333333-c005-1000-0000-000000000003', 'mange', 'false', '4'),

  ('33333333-c005-2100-0000-000000000004', '33333333-c005-1000-0000-000000000004', 'sont avertis', 'false', '1'),
  ('33333333-c005-2200-0000-000000000004', '33333333-c005-1000-0000-000000000004', 'ont été avertis', 'false', '2'),
  ('33333333-c005-2300-0000-000000000004', '33333333-c005-1000-0000-000000000004', 'seront averti', 'false', '3'),
  ('33333333-c005-2400-0000-000000000004', '33333333-c005-1000-0000-000000000004', 'seront avertis', 'true', '4'),

  ('33333333-c005-2100-0000-000000000005', '33333333-c005-1000-0000-000000000005', 's''est fait', 'true', '1'),
  ('33333333-c005-2200-0000-000000000005', '33333333-c005-1000-0000-000000000005', 's''est faite', 'false', '2'),
  ('33333333-c005-2300-0000-000000000005', '33333333-c005-1000-0000-000000000005', 'a fait', 'false', '3'),
  ('33333333-c005-2400-0000-000000000005', '33333333-c005-1000-0000-000000000005', 'est faite', 'false', '4'),

  ('33333333-c005-2100-0000-000000000006', '33333333-c005-1000-0000-000000000006', 'a vu', 'false', '1'),
  ('33333333-c005-2200-0000-000000000006', '33333333-c005-1000-0000-000000000006', 'est vu', 'false', '2'),
  ('33333333-c005-2300-0000-000000000006', '33333333-c005-1000-0000-000000000006', 's''est vu', 'true', '3'),
  ('33333333-c005-2400-0000-000000000006', '33333333-c005-1000-0000-000000000006', 'se voyait', 'false', '4'),

  ('33333333-c005-2100-0000-000000000007', '33333333-c005-1000-0000-000000000007', 'a été augmenté', 'false', '1'),
  ('33333333-c005-2200-0000-000000000007', '33333333-c005-1000-0000-000000000007', 'a augmenté', 'true', '2'),
  ('33333333-c005-2300-0000-000000000007', '33333333-c005-1000-0000-000000000007', 's''est augmenté', 'false', '3'),
  ('33333333-c005-2400-0000-000000000007', '33333333-c005-1000-0000-000000000007', 'était augmenté', 'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes (33333333-c005-1000-…-01..07 / choices 2100-2400).
-- [x] 4 propositions / 1 seule correcte par item ; options de même catégorie
--     (formes du même verbe, ou 4 prépositions pour l''agent) — toutes
--     grammaticalement existantes/plausibles.
-- [x] Distribution des bonnes réponses : pos1:2, pos2:2, pos3:2, pos4:1
--     (4 positions utilisées, aucune ne dépasse 2).
-- [x] Point unique : voix passive, sous 7 angles distincts — accord du participe
--     au passif, agent en « de » vs « par » (passif d''état), pronominal de sens
--     passif, temps du passif (futur + accord), « se faire + infinitif » (fait
--     invariable), « se voir + infinitif » (COI promu sujet), actif obligatoire
--     d''un verbe intransitif (énoncé non passivable). Aucun point de la liste
--     interdite.
-- [x] explanation ≥ 80 caractères, règle nommée en **gras**, chacun des 3
--     distracteurs démonté.
-- [x] Contextes tous différents (inauguration d''une passerelle à Quimper,
--     maison à la campagne, gastronomie alsacienne, résultats de concours,
--     contrôle dans le tramway de Montpellier, promotion professionnelle à
--     Nantes, prix des carburants) ; prénoms variés (Svetlana, Aïcha, Mateus).
-- [x] Contenu 100 % original ; pas de SVG ni SSML dans ce lot (items texte purs).
-- [x] Apostrophes SQL doublées ; pas de JSONB dans ce schéma (table choices).
-- ============================================================================
