-- ============================================================================
-- V663 — TCF SL B2 — lot 03 (point : subjonctif vs indicatif selon la nuance)
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id 22222222-0000-0000-0000-000000000003, difficulty='B2'.
-- 7 items, tous sur le choix subjonctif/indicatif piloté par la nuance de sens
-- (espérer vs souhaiter, il semble que vs il me semble que, antécédent
-- indéterminé, superlatif, après que, il est probable que, douter vs se douter).
-- Contenu original, déterministe.
-- ============================================================================

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('33333333-c003-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Amadou espère que sa fille ___ son diplôme d''infirmière en juillet. »',
   'Contrairement à « souhaiter que » (+ subjonctif), **« espérer que » exprime une quasi-certitude tournée vers l''avenir et appelle l''indicatif**, ici le futur « obtiendra ». « Obtienne » (subjonctif présent) est l''erreur classique par analogie avec « souhaiter que » — le mode est faux après « espérer ». « Ait obtenu » cumule le mode faux et une antériorité que rien ne justifie. « Obtenait » (imparfait de l''indicatif) renvoie à un fait passé ou habituel, incompatible avec l''échéance « en juillet » à venir.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_subjonctif_indicatif_nuance'),

  ('33333333-c003-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Il semble que le centre-ville de Mulhouse ___ énormément en dix ans. »',
   'La nuance oppose deux tournures : **« il semble que » (apparence non confirmée) gouverne le subjonctif**, ici le subjonctif passé « ait changé », alors que « il me semble que » (jugement personnel assumé) prendrait l''indicatif. « A changé » (passé composé) ne serait correct qu''après « il **me** semble que ». « Avait changé » (plus-que-parfait de l''indicatif) marque un mode faux et une antériorité par rapport à un repère passé absent de la phrase. « Aura changé » (futur antérieur) projette le constat dans l''avenir, contresens avec « en dix ans » déjà écoulés.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_subjonctif_indicatif_nuance'),

  ('33333333-c003-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Le cabinet bordelais recherche un juriste qui ___ le droit des étrangers sur le bout des doigts. »',
   'Dans une relative dont **l''antécédent est indéterminé (profil recherché, existence non avérée), on emploie le subjonctif** : « un juriste qui connaisse » décrit un candidat idéal, peut-être introuvable. « Connaît » (indicatif présent) supposerait un juriste réel déjà identifié — on dirait alors « nous avons trouvé un juriste qui connaît… ». « Connaîtra » (futur) affirme comme certain un fait à venir, incompatible avec la simple recherche. « A connu » (passé composé) constate un fait avéré et passé, à l''opposé de l''exigence hypothétique exprimée.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_subjonctif_indicatif_nuance'),

  ('33333333-c003-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « C''est la réforme la plus ambitieuse que le conseil régional ___ depuis sa création. »',
   'Après un **superlatif (« la plus ambitieuse »), la relative prend le subjonctif** car le jugement reste subjectif : « qu''il ait adoptée » (subjonctif passé, participe accordé avec le COD « que » = la réforme, placé avant). « A adoptée » (indicatif) présenterait le classement comme un fait brut et neutre, ce que la tournure superlative n''admet pas en français soigné. « Adoptait » (imparfait) décrirait une habitude passée, sans lien avec un bilan « depuis sa création ». « Avait adoptée » (plus-que-parfait) introduit une antériorité injustifiée et reste à l''indicatif.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_subjonctif_indicatif_nuance'),

  ('33333333-c003-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Au théâtre de Limoges, les spectateurs ont quitté la salle après que le rideau ___. »',
   'La règle oppose les deux conjonctions temporelles : **« après que » introduit un fait réel, accompli, donc l''indicatif** (« est tombé »), tandis que « avant que » + subjonctif vise un fait encore non réalisé. « Soit tombé » (subjonctif passé) est l''hypercorrection la plus répandue, calquée à tort sur « avant que ». « Tombe » (présent) brise la logique temporelle : le rideau était déjà tombé quand les spectateurs sont sortis. « Fût tombé » (subjonctif plus-que-parfait littéraire) reste au mauvais mode, quel que soit le registre.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_subjonctif_indicatif_nuance'),

  ('33333333-c003-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Il est probable que le tribunal de Rouen ___ sa décision avant la fin du mois. »',
   'La nuance de degré de certitude tranche : **« il est probable que » (forte probabilité) appelle l''indicatif**, ici le futur « rendra », alors que « il est possible que » (simple éventualité) exigerait le subjonctif. « Rende » (subjonctif présent) ne serait correct qu''après « il est possible que » ou « il est peu probable que ». « Ait rendu » cumule mode faux et antériorité non motivée par le contexte. « Rendrait » (conditionnel) présenterait l''information comme non confirmée, ce qui contredit l''affirmation de probabilité posée par la principale.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_subjonctif_indicatif_nuance'),

  ('33333333-c003-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Selma doute que le garagiste ___ remettre la fourgonnette en état avant samedi. »',
   'La paire piège oppose deux verbes proches : **« douter que » (incertitude, mise en cause) gouverne le subjonctif** — « puisse » —, tandis que « se douter que » (= soupçonner, quasi-certitude) prendrait l''indicatif. « Peut » (indicatif présent) conviendrait après « Selma se doute que… », pas après « douter que ». « Pourra » (futur de l''indicatif) affirme une capacité future certaine, à l''inverse du doute exprimé. « Pourrait » (conditionnel) marque une éventualité atténuée mais reste au mauvais mode : le subjonctif est obligatoire après « douter que ».',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_subjonctif_indicatif_nuance');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('33333333-c003-2100-0000-000000000001', '33333333-c003-1000-0000-000000000001', 'obtienne', 'false', '1'),
  ('33333333-c003-2200-0000-000000000001', '33333333-c003-1000-0000-000000000001', 'obtiendra', 'true', '2'),
  ('33333333-c003-2300-0000-000000000001', '33333333-c003-1000-0000-000000000001', 'ait obtenu', 'false', '3'),
  ('33333333-c003-2400-0000-000000000001', '33333333-c003-1000-0000-000000000001', 'obtenait', 'false', '4'),

  ('33333333-c003-2100-0000-000000000002', '33333333-c003-1000-0000-000000000002', 'a changé', 'false', '1'),
  ('33333333-c003-2200-0000-000000000002', '33333333-c003-1000-0000-000000000002', 'avait changé', 'false', '2'),
  ('33333333-c003-2300-0000-000000000002', '33333333-c003-1000-0000-000000000002', 'aura changé', 'false', '3'),
  ('33333333-c003-2400-0000-000000000002', '33333333-c003-1000-0000-000000000002', 'ait changé', 'true', '4'),

  ('33333333-c003-2100-0000-000000000003', '33333333-c003-1000-0000-000000000003', 'connaisse', 'true', '1'),
  ('33333333-c003-2200-0000-000000000003', '33333333-c003-1000-0000-000000000003', 'connaît', 'false', '2'),
  ('33333333-c003-2300-0000-000000000003', '33333333-c003-1000-0000-000000000003', 'connaîtra', 'false', '3'),
  ('33333333-c003-2400-0000-000000000003', '33333333-c003-1000-0000-000000000003', 'a connu', 'false', '4'),

  ('33333333-c003-2100-0000-000000000004', '33333333-c003-1000-0000-000000000004', 'a adoptée', 'false', '1'),
  ('33333333-c003-2200-0000-000000000004', '33333333-c003-1000-0000-000000000004', 'adoptait', 'false', '2'),
  ('33333333-c003-2300-0000-000000000004', '33333333-c003-1000-0000-000000000004', 'ait adoptée', 'true', '3'),
  ('33333333-c003-2400-0000-000000000004', '33333333-c003-1000-0000-000000000004', 'avait adoptée', 'false', '4'),

  ('33333333-c003-2100-0000-000000000005', '33333333-c003-1000-0000-000000000005', 'soit tombé', 'false', '1'),
  ('33333333-c003-2200-0000-000000000005', '33333333-c003-1000-0000-000000000005', 'est tombé', 'true', '2'),
  ('33333333-c003-2300-0000-000000000005', '33333333-c003-1000-0000-000000000005', 'tombe', 'false', '3'),
  ('33333333-c003-2400-0000-000000000005', '33333333-c003-1000-0000-000000000005', 'fût tombé', 'false', '4'),

  ('33333333-c003-2100-0000-000000000006', '33333333-c003-1000-0000-000000000006', 'rende', 'false', '1'),
  ('33333333-c003-2200-0000-000000000006', '33333333-c003-1000-0000-000000000006', 'ait rendu', 'false', '2'),
  ('33333333-c003-2300-0000-000000000006', '33333333-c003-1000-0000-000000000006', 'rendra', 'true', '3'),
  ('33333333-c003-2400-0000-000000000006', '33333333-c003-1000-0000-000000000006', 'rendrait', 'false', '4'),

  ('33333333-c003-2100-0000-000000000007', '33333333-c003-1000-0000-000000000007', 'puisse', 'true', '1'),
  ('33333333-c003-2200-0000-000000000007', '33333333-c003-1000-0000-000000000007', 'pourra', 'false', '2'),
  ('33333333-c003-2300-0000-000000000007', '33333333-c003-1000-0000-000000000007', 'peut', 'false', '3'),
  ('33333333-c003-2400-0000-000000000007', '33333333-c003-1000-0000-000000000007', 'pourrait', 'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes (33333333-c003-1000-…-01..07 / choices 2100-2400).
-- [x] 4 propositions / 1 seule correcte par item ; options de même catégorie
--     (4 formes conjuguées du même verbe à chaque fois, toutes existantes).
-- [x] Distribution des bonnes réponses : pos1:2, pos2:2, pos3:2, pos4:1
--     (4 positions utilisées, aucune ne dépasse 2).
-- [x] Point unique : subjonctif vs indicatif selon la nuance (espérer vs
--     souhaiter, il semble que vs il me semble que, antécédent indéterminé,
--     superlatif + relative, après que vs avant que, il est probable que vs
--     il est possible que, douter que vs se douter que) — aucun point de la
--     liste interdite (pas de bien que, pas d''opinion négative, pas de si,
--     pas de discours rapporté, pas de concordance des temps testée).
-- [x] explanation ≥ 80 caractères, nuance/règle nommée en **gras** et chacun
--     des 3 distracteurs démonté (mode, temps ou tournure qui l''appellerait).
-- [x] Contextes tous différents (diplôme d''infirmière, centre-ville de
--     Mulhouse, recrutement juridique à Bordeaux, réforme régionale, théâtre
--     de Limoges, tribunal de Rouen, réparation de fourgonnette) ; prénoms et
--     villes variés (Amadou, Selma ; Mulhouse, Bordeaux, Limoges, Rouen).
-- [x] Contenu 100 % original ; pas de SVG ni SSML dans ce lot (items texte purs).
-- [x] Apostrophes SQL doublées ; pas de JSONB dans ce schéma (table choices).
-- ============================================================================
