-- ============================================================================
-- V676 — TCF SL B2 — lot 16 (point : participe présent vs gérondif vs adjectif verbal)
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id 22222222-0000-0000-0000-000000000003, difficulty='B2'.
-- 7 items, tous sur la distinction participe présent (invariable, + COD) /
-- gérondif (en + -ant, moyen/manière) / adjectif verbal (accordé, orthographe
-- parfois différente : -cant/-quant, -gant/-guant, -ent/-ant) / participe passé.
-- Contenu original, déterministe.
-- ============================================================================

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('33333333-c010-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Les arguments de Rachid, particulièrement ___, ont rallié tout le conseil municipal de Brest. »',
   'Précédé de l''adverbe d''intensité « particulièrement » et sans complément d''objet, le mot fonctionne comme un **adjectif verbal** : il s''accorde avec « arguments » et s''écrit avec -c- → « convaincants ». « Convainquant » est le participe présent (invariable, orthographe en -qu-) : il exigerait un COD (des arguments convainquant les élus). « En convainquant » est un gérondif : il se rapporte à un verbe, jamais en apposition à un nom. « Convaincus » est le participe passé : il signifierait que les arguments sont eux-mêmes persuadés, ce qui est un contresens.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_gerondif_vs_participe'),

  ('33333333-c010-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Priya a enrichi son vocabulaire ___ un chapitre de roman chaque soir. »',
   'Le **gérondif de moyen** (« en » + participe présent) exprime comment Priya a progressé, avec le même sujet que le verbe principal → « en lisant ». « Lisant » seul (participe présent) ne peut pas, placé après le verbe conjugué, exprimer le moyen : la préposition « en » est obligatoire. « Ayant lu » (participe composé) marquerait une antériorité achevée, incompatible avec une pratique répétée (« chaque soir »). « Lu » (participe passé) produirait une construction agrammaticale devant le COD « un chapitre ».',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_gerondif_vs_participe'),

  ('33333333-c010-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Les copropriétaires ___ l''entretien des parties communes s''exposent à une amende de 450 euros. »',
   'Le mot est suivi d''un **COD** (« l''entretien ») : seul le **participe présent**, forme verbale invariable orthographiée -geant, peut en recevoir un → « négligeant ». « Négligents » est l''adjectif verbal (orthographe -gent) : un adjectif ne peut jamais être suivi d''un COD. « En négligeant » est un gérondif : il complète un verbe, pas un nom — il ne peut pas jouer le rôle de relative réduite après « copropriétaires ». « Négligé » est le participe passé : de sens passif, il inverserait la relation (les copropriétaires seraient négligés).',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_gerondif_vs_participe'),

  ('33333333-c010-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Son intervention au débat télévisé, jugée trop ___, a été coupée par le modérateur. »',
   'Après « jugée trop », on attend un attribut : c''est l''**adjectif verbal**, qui s''accorde avec « intervention » et s''écrit avec -c- → « provocante ». « Provoquant » est le participe présent (invariable, orthographe en -qu-) : il exigerait un COD (une intervention provoquant des sifflets) et refuse l''adverbe « trop ». « En provoquant » est un gérondif, impossible en position d''attribut après un adverbe d''intensité. « Provoquée » est le participe passé : de sens passif (l''intervention aurait été déclenchée par quelque chose), il ne décrit pas une qualité de l''intervention.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_gerondif_vs_participe'),

  ('33333333-c010-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Pour Amadou, le trajet quotidien entre Melun et la Défense est vraiment ___. »',
   'Attribut du sujet après « est vraiment » : c''est l''**adjectif verbal**, qui perd le « u » du radical → « fatigant ». « Fatiguant » est le participe présent (il garde le « u ») : forme verbale, il exigerait un COD ou un emploi en proposition participiale, pas une position d''attribut. « En fatiguant » est un gérondif : il modifie un verbe, jamais le verbe « être » en attribut. « Fatigué » est le participe passé exprimant l''état subi : c''est le voyageur qui serait fatigué, pas le trajet — le sens actif requis (le trajet fatigue) impose l''adjectif en -ant.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_gerondif_vs_participe'),

  ('33333333-c010-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Olena s''est fait mal au dos ___ un carton de livres pendant son déménagement. »',
   'Le **gérondif de manière** (« en » + participe présent) indique la circonstance simultanée de la blessure, avec le même sujet → « en soulevant ». « Soulevant » seul (participe présent) ne peut pas, après le verbe principal, exprimer cette circonstance : détaché en tête de phrase il serait possible, mais pas ici sans « en ». « Ayant soulevé » (participe composé) marquerait une action antérieure accomplie, or la douleur survient pendant l''effort, pas après. « Soulevé » (participe passé) est agrammatical devant le COD « un carton ».',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_gerondif_vs_participe'),

  ('33333333-c010-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « La réunion ___ le vote du budget s''est prolongée jusqu''à minuit à la mairie de Bayonne. »',
   'Le mot est suivi du **COD** « le vote » : seule la forme verbale convient, c''est le **participe présent** invariable, orthographié -ant → « précédant ». « Précédente » est l''adjectif verbal (orthographe -ent) : il ne peut pas recevoir de COD (on dirait « la réunion précédente », sans complément). « En précédant » est un gérondif : il complète un verbe, pas le nom « réunion ». « Précédée » est le participe passé de sens passif : il exigerait un complément d''agent (« précédée par le vote ») et inverserait l''ordre des événements.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_gerondif_vs_participe');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('33333333-c010-2100-0000-000000000001', '33333333-c010-1000-0000-000000000001', 'convainquant', 'false', '1'),
  ('33333333-c010-2200-0000-000000000001', '33333333-c010-1000-0000-000000000001', 'convaincants', 'true', '2'),
  ('33333333-c010-2300-0000-000000000001', '33333333-c010-1000-0000-000000000001', 'en convainquant', 'false', '3'),
  ('33333333-c010-2400-0000-000000000001', '33333333-c010-1000-0000-000000000001', 'convaincus', 'false', '4'),

  ('33333333-c010-2100-0000-000000000002', '33333333-c010-1000-0000-000000000002', 'lisant', 'false', '1'),
  ('33333333-c010-2200-0000-000000000002', '33333333-c010-1000-0000-000000000002', 'ayant lu', 'false', '2'),
  ('33333333-c010-2300-0000-000000000002', '33333333-c010-1000-0000-000000000002', 'lu', 'false', '3'),
  ('33333333-c010-2400-0000-000000000002', '33333333-c010-1000-0000-000000000002', 'en lisant', 'true', '4'),

  ('33333333-c010-2100-0000-000000000003', '33333333-c010-1000-0000-000000000003', 'négligeant', 'true', '1'),
  ('33333333-c010-2200-0000-000000000003', '33333333-c010-1000-0000-000000000003', 'négligents', 'false', '2'),
  ('33333333-c010-2300-0000-000000000003', '33333333-c010-1000-0000-000000000003', 'en négligeant', 'false', '3'),
  ('33333333-c010-2400-0000-000000000003', '33333333-c010-1000-0000-000000000003', 'négligé', 'false', '4'),

  ('33333333-c010-2100-0000-000000000004', '33333333-c010-1000-0000-000000000004', 'provoquant', 'false', '1'),
  ('33333333-c010-2200-0000-000000000004', '33333333-c010-1000-0000-000000000004', 'en provoquant', 'false', '2'),
  ('33333333-c010-2300-0000-000000000004', '33333333-c010-1000-0000-000000000004', 'provocante', 'true', '3'),
  ('33333333-c010-2400-0000-000000000004', '33333333-c010-1000-0000-000000000004', 'provoquée', 'false', '4'),

  ('33333333-c010-2100-0000-000000000005', '33333333-c010-1000-0000-000000000005', 'fatiguant', 'false', '1'),
  ('33333333-c010-2200-0000-000000000005', '33333333-c010-1000-0000-000000000005', 'fatigant', 'true', '2'),
  ('33333333-c010-2300-0000-000000000005', '33333333-c010-1000-0000-000000000005', 'en fatiguant', 'false', '3'),
  ('33333333-c010-2400-0000-000000000005', '33333333-c010-1000-0000-000000000005', 'fatigué', 'false', '4'),

  ('33333333-c010-2100-0000-000000000006', '33333333-c010-1000-0000-000000000006', 'soulevant', 'false', '1'),
  ('33333333-c010-2200-0000-000000000006', '33333333-c010-1000-0000-000000000006', 'ayant soulevé', 'false', '2'),
  ('33333333-c010-2300-0000-000000000006', '33333333-c010-1000-0000-000000000006', 'soulevé', 'false', '3'),
  ('33333333-c010-2400-0000-000000000006', '33333333-c010-1000-0000-000000000006', 'en soulevant', 'true', '4'),

  ('33333333-c010-2100-0000-000000000007', '33333333-c010-1000-0000-000000000007', 'précédant', 'true', '1'),
  ('33333333-c010-2200-0000-000000000007', '33333333-c010-1000-0000-000000000007', 'précédente', 'false', '2'),
  ('33333333-c010-2300-0000-000000000007', '33333333-c010-1000-0000-000000000007', 'en précédant', 'false', '3'),
  ('33333333-c010-2400-0000-000000000007', '33333333-c010-1000-0000-000000000007', 'précédée', 'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes (33333333-c010-1000-…-01..07 / choices 2100-2400).
-- [x] 4 propositions / 1 seule correcte par item ; options de même catégorie
--     (4 formes du MÊME verbe : participe présent, adjectif verbal, gérondif,
--     participe passé/composé — toutes grammaticalement existantes).
-- [x] Distribution des bonnes réponses : pos1:2, pos2:2, pos3:1, pos4:2
--     (4 positions utilisées, aucune ne dépasse 2).
-- [x] Point unique : participe présent vs gérondif vs adjectif verbal
--     (convaincants, en lisant, négligeant, provocante, fatigant, en soulevant,
--     précédant) — aucun point de la liste interdite (pas de concessifs, pas de
--     paronymes, pas de place de l''adverbe, etc.).
-- [x] explanation ≥ 80 caractères, nomme le mécanisme (**adjectif verbal accordé**,
--     **participe présent + COD invariable**, **gérondif de moyen/manière**,
--     orthographes -c-/-qu-, -g-/-gu-, -ant/-ent) et démonte chacun des 3
--     distracteurs.
-- [x] Contextes tous différents (conseil municipal de Brest, lecture du soir,
--     copropriété, débat télévisé, trajet Melun–la Défense, déménagement,
--     réunion budgétaire à Bayonne) ; prénoms variés (Rachid, Priya, Amadou,
--     Olena).
-- [x] Contenu 100 % original ; pas de SVG ni SSML dans ce lot (items texte purs).
-- [x] Apostrophes SQL doublées ; pas de JSONB dans ce schéma (table choices).
-- ============================================================================
