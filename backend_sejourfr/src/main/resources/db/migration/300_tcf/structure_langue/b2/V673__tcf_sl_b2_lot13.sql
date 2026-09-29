-- ============================================================================
-- V673 — TCF SL B2 — lot 13 (point : connecteurs de cause / conséquence)
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id 22222222-0000-0000-0000-000000000003, difficulty='B2'.
-- 7 items, tous sur les connecteurs de cause / conséquence (comme en tête de
-- phrase, sous prétexte que, si … que, si bien que, faute de, à force de, d''où).
-- Contenu original, déterministe.
-- ============================================================================

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('33333333-c00d-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « ___ il pleuvait des cordes sur Brest, le tournoi de pétanque du quartier a été reporté à dimanche. »',
   '« Comme » est le seul connecteur de cause qui se place **en tête de phrase**, avant la principale. « Car » introduit bien une cause, mais il ne peut pas ouvrir l''énoncé : il relie une cause à une affirmation déjà posée (le tournoi a été reporté, car il pleuvait). « C''est pourquoi » introduit une conséquence, pas une cause : la logique serait inversée (la pluie deviendrait le résultat du report). « En effet » sert à justifier une affirmation précédente et ne peut pas non plus annoncer, en ouverture, la cause d''une principale à venir.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_connecteur_consequence'),

  ('33333333-c00d-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Bilal a refusé de payer sa part au restaurant, ___ il n''avait rien commandé — alors que le serveur a retrouvé ses deux plats sur le ticket. »',
   'La fin de la phrase démontre que la raison invoquée est **fausse** : « sous prétexte que » présente une cause alléguée par le sujet mais que le locuteur ne valide pas. « Puisque » présenterait la cause comme une évidence admise par tous — contradictoire avec le démenti du ticket. « Étant donné que » poserait un fait objectif et avéré, ce que la phrase nie précisément. « Comme » exprimerait une cause neutre et réelle, et se place en outre de préférence en tête de phrase.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_connecteur_consequence'),

  ('33333333-c00d-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « La conférence d''ouverture du salon de Nantes était ___ ennuyeuse que la moitié de la salle consultait son téléphone. »',
   'Devant un **adjectif**, la corrélation d''intensité-conséquence s''exprime par « si … que » (ou « tellement … que »). « Tant » s''emploie avec un verbe (elle a tant travaillé que…) ou dans « tant de » + nom, jamais directement devant un adjectif. « Tellement de » exige un nom (tellement de bruit que…) et ne peut pas précéder « ennuyeuse ». « Autant » sert à la comparaison d''égalité (autant que) et ne forme pas de corrélative d''intensité avec un adjectif.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_connecteur_consequence'),

  ('33333333-c00d-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Le verglas a bloqué la rocade de Clermont-Ferrand toute la matinée, ___ Naïma est arrivée à son entretien d''embauche avec deux heures de retard. »',
   'Le trou introduit la **conséquence** du verglas : « si bien que » enchaîne un fait et son résultat. « Parce que », « puisque » et « sous prétexte que » introduisent tous une cause et inverseraient la logique : le retard de Naïma deviendrait la cause du verglas, ce qui est absurde. « Puisque » ajouterait de surcroît l''idée d''une évidence partagée, et « sous prétexte que » celle d''une raison contestée — aucun ne convient à l''enchaînement fait → résultat.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_connecteur_consequence'),

  ('33333333-c00d-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « ___ preuves suffisantes, le tribunal de Limoges a relaxé le prévenu à l''issue de l''audience. »',
   '« Faute de » signifie « par **manque de** » : c''est l''absence de preuves qui explique la relaxe. « Grâce à des » exprime une cause positive : des preuves suffisantes auraient au contraire mené à une condamnation, non à une relaxe. « À force de » suppose une accumulation ou une répétition (à force d''efforts) et ne peut pas exprimer un manque. « En raison de » introduit une cause réelle et neutre : « en raison de preuves suffisantes » affirmerait que ces preuves existaient, ce qui contredit la relaxe.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_connecteur_consequence'),

  ('33333333-c00d-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « ___ répéter les mêmes mesures chaque soir, Svetlana a fini par jouer ce concerto sans partition. »',
   '« À force de » + infinitif exprime une cause par **répétition persévérante**, ce que confirment « chaque soir » et « a fini par ». « Faute de » signifierait « par manque de répétition », contradictoire avec le résultat obtenu. « En raison de » se construit avec un nom (en raison des travaux), pas avec un infinitif, et exprime une cause neutre sans idée d''effort répété. « Sous prétexte de » + infinitif avance une fausse raison pour justifier autre chose — aucune mauvaise foi ici, la cause est réelle.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_connecteur_consequence'),

  ('33333333-c00d-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Notre fournisseur de légumes a doublé ses tarifs en janvier, ___ la hausse du prix des menus à la cantine scolaire de Roubaix. »',
   '« D''où » introduit une conséquence exprimée par un **groupe nominal** (« la hausse du prix… »), sans verbe conjugué. « Si bien que » introduit aussi une conséquence, mais exige une proposition conjuguée (si bien que les menus ont augmenté) : il ne peut pas précéder un simple nom. « Car » et « puisque » introduisent une cause et inverseraient la logique (la hausse des menus deviendrait la cause du doublement des tarifs) ; ils demandent eux aussi une proposition conjuguée.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_connecteur_consequence');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('33333333-c00d-2100-0000-000000000001', '33333333-c00d-1000-0000-000000000001', 'Car', 'false', '1'),
  ('33333333-c00d-2200-0000-000000000001', '33333333-c00d-1000-0000-000000000001', 'Comme', 'true', '2'),
  ('33333333-c00d-2300-0000-000000000001', '33333333-c00d-1000-0000-000000000001', 'C''est pourquoi', 'false', '3'),
  ('33333333-c00d-2400-0000-000000000001', '33333333-c00d-1000-0000-000000000001', 'En effet', 'false', '4'),

  ('33333333-c00d-2100-0000-000000000002', '33333333-c00d-1000-0000-000000000002', 'puisque', 'false', '1'),
  ('33333333-c00d-2200-0000-000000000002', '33333333-c00d-1000-0000-000000000002', 'étant donné que', 'false', '2'),
  ('33333333-c00d-2300-0000-000000000002', '33333333-c00d-1000-0000-000000000002', 'comme', 'false', '3'),
  ('33333333-c00d-2400-0000-000000000002', '33333333-c00d-1000-0000-000000000002', 'sous prétexte que', 'true', '4'),

  ('33333333-c00d-2100-0000-000000000003', '33333333-c00d-1000-0000-000000000003', 'si', 'true', '1'),
  ('33333333-c00d-2200-0000-000000000003', '33333333-c00d-1000-0000-000000000003', 'tant', 'false', '2'),
  ('33333333-c00d-2300-0000-000000000003', '33333333-c00d-1000-0000-000000000003', 'tellement de', 'false', '3'),
  ('33333333-c00d-2400-0000-000000000003', '33333333-c00d-1000-0000-000000000003', 'autant', 'false', '4'),

  ('33333333-c00d-2100-0000-000000000004', '33333333-c00d-1000-0000-000000000004', 'parce que', 'false', '1'),
  ('33333333-c00d-2200-0000-000000000004', '33333333-c00d-1000-0000-000000000004', 'puisque', 'false', '2'),
  ('33333333-c00d-2300-0000-000000000004', '33333333-c00d-1000-0000-000000000004', 'si bien que', 'true', '3'),
  ('33333333-c00d-2400-0000-000000000004', '33333333-c00d-1000-0000-000000000004', 'sous prétexte que', 'false', '4'),

  ('33333333-c00d-2100-0000-000000000005', '33333333-c00d-1000-0000-000000000005', 'Faute de', 'true', '1'),
  ('33333333-c00d-2200-0000-000000000005', '33333333-c00d-1000-0000-000000000005', 'Grâce à des', 'false', '2'),
  ('33333333-c00d-2300-0000-000000000005', '33333333-c00d-1000-0000-000000000005', 'À force de', 'false', '3'),
  ('33333333-c00d-2400-0000-000000000005', '33333333-c00d-1000-0000-000000000005', 'En raison de', 'false', '4'),

  ('33333333-c00d-2100-0000-000000000006', '33333333-c00d-1000-0000-000000000006', 'En raison de', 'false', '1'),
  ('33333333-c00d-2200-0000-000000000006', '33333333-c00d-1000-0000-000000000006', 'Faute de', 'false', '2'),
  ('33333333-c00d-2300-0000-000000000006', '33333333-c00d-1000-0000-000000000006', 'À force de', 'true', '3'),
  ('33333333-c00d-2400-0000-000000000006', '33333333-c00d-1000-0000-000000000006', 'Sous prétexte de', 'false', '4'),

  ('33333333-c00d-2100-0000-000000000007', '33333333-c00d-1000-0000-000000000007', 'car', 'false', '1'),
  ('33333333-c00d-2200-0000-000000000007', '33333333-c00d-1000-0000-000000000007', 'd''où', 'true', '2'),
  ('33333333-c00d-2300-0000-000000000007', '33333333-c00d-1000-0000-000000000007', 'si bien que', 'false', '3'),
  ('33333333-c00d-2400-0000-000000000007', '33333333-c00d-1000-0000-000000000007', 'puisque', 'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes (33333333-c00d-1000-…-01..07 / choices 2100-2400).
-- [x] 4 propositions / 1 seule correcte par item ; options de même catégorie
--     (connecteurs logiques de cause / conséquence grammaticalement existants).
-- [x] Distribution des bonnes réponses : pos1:2, pos2:2, pos3:2, pos4:1
--     (4 positions utilisées, aucune ne dépasse 2).
-- [x] Point unique : connecteurs de cause / conséquence (comme en tête de phrase,
--     sous prétexte que, si … que d''intensité, si bien que, faute de, à force de,
--     d''où + groupe nominal) — aucun point de la liste interdite (ni concessifs,
--     ni articulateurs argumentatifs, ni comparaison complexe, ni hypothèse).
-- [x] explanation ≥ 80 caractères, règle nommée et point clé en **gras**,
--     chacun des 3 distracteurs démonté.
-- [x] Contextes tous différents (tournoi de pétanque sous la pluie, addition au
--     restaurant, conférence de salon, verglas avant un entretien, audience au
--     tribunal, répétition d''un concerto, tarifs d''une cantine scolaire) ;
--     prénoms et villes variés (Bilal, Naïma, Svetlana ; Brest, Nantes,
--     Clermont-Ferrand, Limoges, Roubaix).
-- [x] Contenu 100 % original ; pas de SVG ni SSML dans ce lot (items texte purs).
-- [x] Apostrophes SQL doublées ; pas de JSONB dans ce schéma (table choices).
-- ============================================================================
