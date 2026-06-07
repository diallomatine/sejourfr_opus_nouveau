-- ============================================================================
-- V674 — TCF SL B2 — lot 14 (point : discours rapporté)
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id 22222222-0000-0000-0000-000000000003, difficulty='B2'.
-- 7 items, tous sur le discours rapporté (interrogation indirecte totale « si »,
-- partielle « ce que » / « ce qui », ordre rapporté « de + infinitif »,
-- transposition « hier → la veille », futur → conditionnel présent,
-- déclarative « que »). Contenu original, déterministe.
-- ============================================================================

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('33333333-c00e-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « À l''accueil de la préfecture de Besançon, l''agente a demandé à Bakary ___ il avait bien joint son justificatif de domicile. »',
   'Au discours rapporté, une **question totale** (réponse oui/non : « Avez-vous joint le justificatif ? ») s''introduit par « si » : c''est l''interrogation indirecte totale. « Que » introduirait une déclaration rapportée (elle a dit que…), jamais une question. « Ce que » rapporterait une question partielle portant sur le COD (« Qu''est-ce que vous avez joint ? »). « Ce qui » rapporterait une question partielle portant sur le sujet (« Qu''est-ce qui manque ? »).',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_discours_rapporte'),

  ('33333333-c00e-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « À la fin de l''atelier sur les gestes de premiers secours, la formatrice a voulu savoir ___ les stagiaires avaient retenu de la démonstration. »',
   'La question directe est « Qu''est-ce que vous avez retenu ? » : l''élément inconnu est le **COD** du verbe, donc l''interrogation indirecte partielle s''introduit par « ce que ». « Si » rapporterait une question totale (savoir s''ils avaient retenu quelque chose, oui ou non). « Ce qui » correspondrait à une question portant sur le sujet (« Qu''est-ce qui vous a marqués ? »). « Que » seul introduit une complétive déclarative (elle a dit que…), pas une interrogative indirecte.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_discours_rapporte'),

  ('33333333-c00e-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Pendant la séance, la kinésithérapeute a demandé à Tarek ___ le faisait souffrir depuis sa chute de vélo. »',
   'La question directe est « Qu''est-ce qui vous fait souffrir ? » : l''élément inconnu est le **sujet inanimé** de la subordonnée, donc on rapporte avec « ce qui ». « Ce que » supposerait que l''inconnu soit un COD (« Qu''est-ce que vous sentez ? »). « Qui » rapporterait une question sur une personne (« Qui vous a soigné ? »), incohérent ici : c''est une douleur, pas quelqu''un, qui fait souffrir. « Si » rapporterait une question totale (demander s''il souffrait).',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_discours_rapporte'),

  ('33333333-c00e-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Excédée par le bruit, la bibliothécaire de Clermont-Ferrand a prié les étudiants ___ le ton dans la salle de lecture. »',
   'Un **ordre rapporté** se construit avec « verbe introducteur + de + infinitif » : « prier quelqu''un **de** faire quelque chose » (l''impératif direct « Baissez le ton ! » devient « de baisser le ton »). « Baisser » sans préposition ne s''emploie qu''après un semi-auxiliaire comme « faire » ou « laisser », pas après « prier ». « À baisser » est impossible : « prier » ne régit pas la préposition « à ». « Qu''ils baissent » (complétive au subjonctif) conviendrait après « exiger que », mais « prier quelqu''un » appelle l''infinitif prépositionnel.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_discours_rapporte'),

  ('33333333-c00e-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « ''J''ai vu la fourgonnette hier soir'', a expliqué Svitlana aux policiers de Mulhouse. Le procès-verbal indique qu''elle avait vu la fourgonnette ___ au soir. »',
   'Au discours rapporté au passé, les **déictiques temporels se transposent** : « hier » du discours direct devient « la veille » (le repère n''est plus le moment de la parole mais celui du récit). « Hier » garderait un repère déictique lié au moment présent, incompatible avec un procès-verbal relu plus tard. « Le lendemain » transposerait « demain », soit le jour suivant la déposition. « L''avant-veille » transposerait « avant-hier », soit deux jours avant — or Svitlana a bien dit « hier ».',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_discours_rapporte'),

  ('33333333-c00e-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Avant le départ de la randonnée au-dessus d''Annecy, le guide avait promis que le groupe ___ au refuge avant la tombée de la nuit. »',
   'Quand le verbe introducteur est au passé, le **futur simple du discours direct devient conditionnel présent** au discours rapporté (« Nous arriverons » → « arriverait ») : c''est le futur dans le passé. « Arrivera » conserverait le futur simple, agrammatical après « avait promis ». « Arrivait » transposerait un présent du discours direct (« Nous arrivons »), or une promesse vise un fait à venir. « Est arrivé » présenterait le fait comme déjà accompli au moment de la promesse, contradictoire avec « avant le départ ».',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_discours_rapporte'),

  ('33333333-c00e-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Au téléphone, le plombier a garanti à Nadia ___ la fuite sous l''évier serait colmatée avant le week-end. »',
   'Une **déclaration rapportée** s''introduit par la conjonction « que » après un verbe déclaratif : « garantir **que** + proposition conjuguée ». « De » introduirait un infinitif (« garantir de colmater »), impossible ici car la subordonnée a son propre sujet (« la fuite »). « Si » introduirait une interrogation indirecte totale (demander si…), or le plombier affirme, il n''interroge pas. « Ce que » introduirait une interrogation indirecte partielle portant sur un COD (demander ce que…), même contresens.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_discours_rapporte');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('33333333-c00e-2100-0000-000000000001', '33333333-c00e-1000-0000-000000000001', 'que', 'false', '1'),
  ('33333333-c00e-2200-0000-000000000001', '33333333-c00e-1000-0000-000000000001', 'si', 'true', '2'),
  ('33333333-c00e-2300-0000-000000000001', '33333333-c00e-1000-0000-000000000001', 'ce que', 'false', '3'),
  ('33333333-c00e-2400-0000-000000000001', '33333333-c00e-1000-0000-000000000001', 'ce qui', 'false', '4'),

  ('33333333-c00e-2100-0000-000000000002', '33333333-c00e-1000-0000-000000000002', 'si', 'false', '1'),
  ('33333333-c00e-2200-0000-000000000002', '33333333-c00e-1000-0000-000000000002', 'ce qui', 'false', '2'),
  ('33333333-c00e-2300-0000-000000000002', '33333333-c00e-1000-0000-000000000002', 'que', 'false', '3'),
  ('33333333-c00e-2400-0000-000000000002', '33333333-c00e-1000-0000-000000000002', 'ce que', 'true', '4'),

  ('33333333-c00e-2100-0000-000000000003', '33333333-c00e-1000-0000-000000000003', 'ce qui', 'true', '1'),
  ('33333333-c00e-2200-0000-000000000003', '33333333-c00e-1000-0000-000000000003', 'ce que', 'false', '2'),
  ('33333333-c00e-2300-0000-000000000003', '33333333-c00e-1000-0000-000000000003', 'qui', 'false', '3'),
  ('33333333-c00e-2400-0000-000000000003', '33333333-c00e-1000-0000-000000000003', 'si', 'false', '4'),

  ('33333333-c00e-2100-0000-000000000004', '33333333-c00e-1000-0000-000000000004', 'baisser', 'false', '1'),
  ('33333333-c00e-2200-0000-000000000004', '33333333-c00e-1000-0000-000000000004', 'à baisser', 'false', '2'),
  ('33333333-c00e-2300-0000-000000000004', '33333333-c00e-1000-0000-000000000004', 'de baisser', 'true', '3'),
  ('33333333-c00e-2400-0000-000000000004', '33333333-c00e-1000-0000-000000000004', 'qu''ils baissent', 'false', '4'),

  ('33333333-c00e-2100-0000-000000000005', '33333333-c00e-1000-0000-000000000005', 'la veille', 'true', '1'),
  ('33333333-c00e-2200-0000-000000000005', '33333333-c00e-1000-0000-000000000005', 'hier', 'false', '2'),
  ('33333333-c00e-2300-0000-000000000005', '33333333-c00e-1000-0000-000000000005', 'le lendemain', 'false', '3'),
  ('33333333-c00e-2400-0000-000000000005', '33333333-c00e-1000-0000-000000000005', 'l''avant-veille', 'false', '4'),

  ('33333333-c00e-2100-0000-000000000006', '33333333-c00e-1000-0000-000000000006', 'arrivera', 'false', '1'),
  ('33333333-c00e-2200-0000-000000000006', '33333333-c00e-1000-0000-000000000006', 'arrivait', 'false', '2'),
  ('33333333-c00e-2300-0000-000000000006', '33333333-c00e-1000-0000-000000000006', 'est arrivé', 'false', '3'),
  ('33333333-c00e-2400-0000-000000000006', '33333333-c00e-1000-0000-000000000006', 'arriverait', 'true', '4'),

  ('33333333-c00e-2100-0000-000000000007', '33333333-c00e-1000-0000-000000000007', 'de', 'false', '1'),
  ('33333333-c00e-2200-0000-000000000007', '33333333-c00e-1000-0000-000000000007', 'que', 'true', '2'),
  ('33333333-c00e-2300-0000-000000000007', '33333333-c00e-1000-0000-000000000007', 'si', 'false', '3'),
  ('33333333-c00e-2400-0000-000000000007', '33333333-c00e-1000-0000-000000000007', 'ce que', 'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes (33333333-c00e-1000-…-01..07 / choices 2100-2400).
-- [x] 4 propositions / 1 seule correcte par item ; options de même catégorie
--     (subordonnants, formes verbales, expressions temporelles).
-- [x] Distribution des bonnes réponses : pos1:2, pos2:2, pos3:1, pos4:2
--     (4 positions utilisées, aucune ne dépasse 2).
-- [x] Point unique : discours rapporté (interrogation indirecte totale « si »,
--     partielle « ce que »/« ce qui », ordre rapporté « de + infinitif »,
--     « hier » → « la veille », futur → conditionnel présent (futur dans le
--     passé), déclarative « que ») — aucun point de la liste interdite.
-- [x] explanation ≥ 80 caractères, nomme le mécanisme (**gras**) et démonte
--     chacun des 3 distracteurs.
-- [x] Contextes tous différents (préfecture, atelier premiers secours,
--     kinésithérapie, bibliothèque universitaire, déposition au commissariat,
--     randonnée en montagne, dépannage de plomberie) ; prénoms variés (Bakary,
--     Tarek, Svitlana, Nadia) ; villes variées (Besançon, Clermont-Ferrand,
--     Mulhouse, Annecy).
-- [x] Contenu 100 % original ; pas de SVG ni SSML dans ce lot (items texte purs).
-- [x] Apostrophes SQL doublées ; pas de JSONB dans ce schéma (table choices).
-- ============================================================================
