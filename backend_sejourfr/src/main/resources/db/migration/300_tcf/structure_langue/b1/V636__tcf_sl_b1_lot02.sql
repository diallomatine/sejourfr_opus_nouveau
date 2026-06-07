-- ============================================================================
-- V636 — TCF SL B1 — lot 02 (point : pronoms relatifs simples (qui, que, où, dont))
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id 22222222-0000-0000-0000-000000000003, difficulty='B1'.
-- 10 items, tous sur les relatifs simples qui / que / où / dont (haut du B1) :
-- qui sujet, que COD, dont après « parler de », dont après « avoir besoin de »,
-- où temporel (« le jour où » malgré « se souvenir de »), où de lieu, dont
-- complément du nom (dont + le + nom), qui sujet avec incise piège, que avec
-- sujet inversé (« que me donne ma tante »), où temporel (« à l''époque où »).
-- UUID déterministes, rejouables dev + recette.
-- ============================================================================

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('33333333-b002-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « Amadou a chaleureusement remercié la conseillère ___ avait suivi son dossier pendant deux ans à la mairie de Tours. »',
   'Dans la relative, « avait suivi son dossier » n''a pas d''autre sujet exprimé : l''antécédent « la conseillère » est le **sujet du verbe** → relatif sujet « qui ». « Que » reprendrait un COD ; or le COD est déjà là (« son dossier ») et il manquerait alors un sujet à « avait suivi ». « Dont » exigerait un verbe construit avec « de » (parler de, s''occuper de), absent ici. « Où » reprend un lieu ou un moment, pas une personne qui agit.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_relatif_qui_que'),

  ('33333333-b002-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « Le couscous ___ Nadia avait préparé pour la fête des voisins a été terminé en moins d''une heure. »',
   'La relative a déjà son sujet (« Nadia ») et « préparer » attend un **complément d''objet direct** : l''antécédent « le couscous » est ce COD → « que » (préparer quelque chose). « Qui » ferait du couscous le sujet de « avait préparé », en conflit avec « Nadia ». « Dont » supposerait une construction en « de » (« préparer de » n''existe pas). « Où » renverrait à un lieu ou à un moment, pas à la chose préparée.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_relatif_qui_que'),

  ('33333333-b002-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « Le documentaire ___ tout le quartier parlait depuis des semaines a enfin été projeté à la médiathèque de Rennes. »',
   'Le verbe de la relative se construit avec la préposition « de » : on **parle DE quelque chose** → le relatif « dont » reprend ce complément introduit par « de » (on parlait du documentaire). « Que » conviendrait à un verbe transitif direct (« le documentaire que le quartier attendait »), or « parler quelque chose » est impossible ici. « Qui » ferait du documentaire le sujet de « parlait », alors que le sujet est « tout le quartier ». « Où » marquerait un lieu ou un moment, sans rapport.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_pronom_relatif_dont'),

  ('33333333-b002-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « La préfecture a publié la liste des pièces ___ chaque candidat aura besoin le jour de l''entretien. »',
   'L''expression de la relative est « **avoir besoin DE** quelque chose » : le complément en « de » (les pièces) est repris par « dont » (on aura besoin de ces pièces). « Que » supposerait un COD direct, mais « avoir besoin » ne se construit jamais sans « de ». « Qui » ferait des pièces le sujet de « aura besoin », rôle déjà occupé par « chaque candidat ». « Où » reprendrait un cadre de lieu ou de temps — c''est « le jour de l''entretien » qui joue ce rôle, pas l''antécédent.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_pronom_relatif_dont'),

  ('33333333-b002-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « Bilal se souvient encore du jour ___ une tempête de neige a immobilisé tous les trains en gare de Strasbourg. »',
   'Piège du haut B1 : « se souvenir **de** » attire vers « dont », mais ce « de » est déjà consommé dans « DU jour ». À l''intérieur de la relative, l''antécédent « le jour » indique **le moment où l''événement se produit** (la tempête a immobilisé les trains CE jour-là) → « où » temporel. « Dont » ferait du jour le complément en « de » du verbe de la relative, or on n''immobilise pas « de » un jour. « Que » exigerait que « le jour » soit COD d''« immobiliser » — absurde. « Qui » en ferait le sujet, alors que le sujet est « une tempête de neige ».',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_relatif_ou_temps'),

  ('33333333-b002-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « Le café associatif ___ Diego suit ses cours de français le mardi soir cherche de nouveaux bénévoles. »',
   'Dans la relative, l''antécédent « le café associatif » est le **lieu où se déroule l''action** (Diego suit ses cours DANS ce café) → relatif de lieu « où ». « Que » en ferait le COD de « suit », or Diego suit « ses cours », pas le café. « Dont » réclamerait un verbe en « de » (« dont il parle », « dont il a besoin »), absent ici. « Qui » ferait du café le sujet de « suit », rôle déjà tenu par « Diego ».',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_pronom_relatif_simple'),

  ('33333333-b002-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « Olena a adopté dans un refuge de Dijon une chienne ___ le pelage gris clair attire tous les regards. »',
   '« Dont » exprime ici le **complément du nom** : le pelage DE la chienne → « une chienne dont le pelage… ». Repère fiable : « dont » est suivi d''un groupe « le/la/les + nom » qui appartient à l''antécédent. « Qui » ferait de la chienne le sujet d''« attire », mais le sujet est « le pelage ». « Que » en ferait le COD d''« attire », ce qui laisserait « le pelage » sans fonction. « Où » désignerait un lieu — une chienne n''est pas un lieu.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_pronom_relatif_dont'),

  ('33333333-b002-1000-0000-000000000008', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « Les habitants de Besançon ___, depuis des années, réclamaient une piste cyclable sécurisée ont enfin obtenu satisfaction. »',
   'L''incise « depuis des années » sépare le relatif de son verbe, mais la fonction ne change pas : « les habitants » sont le **sujet de « réclamaient »** → « qui ». Astuce : on supprime mentalement l''incise (« les habitants qui réclamaient… »). « Que » supposerait un autre sujet après le trou pour « réclamaient », or il n''y en a pas. « Dont » demanderait une construction en « de » (réclamer ne se construit pas avec « de » ici). « Où » reprendrait un cadre spatial ou temporel, pas un groupe de personnes.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_relatif_qui_que'),

  ('33333333-b002-1000-0000-000000000009', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « Les conseils ___ me donne régulièrement ma tante Mariam m''ont évité bien des erreurs administratives. »',
   'Piège de l''**inversion du sujet** : le verbe « donne » suit le trou, ce qui pousse vers « qui », mais le vrai sujet est placé APRÈS le verbe (« ma tante Mariam »). L''antécédent « les conseils » est le COD de « donner » (elle donne ces conseils) → « que ». « Qui » créerait deux sujets concurrents (les conseils + ma tante). « Dont » exigerait « donner de », construction inexistante. « Où » renverrait à un lieu ou un moment, pas à la chose donnée.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_relatif_qui_que'),

  ('33333333-b002-1000-0000-00000000000a', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « À l''époque ___ Rachid travaillait de nuit dans un entrepôt de Lille, il ne voyait presque jamais ses enfants. »',
   'L''antécédent « l''époque » est un repère de temps et la relative décrit ce qui se passait **pendant cette période** → « où » temporel (à cette époque-LÀ, il travaillait de nuit). « Que » ferait de l''époque le COD de « travaillait », or « travailler » est intransitif ici. « Qui » en ferait le sujet, rôle occupé par « Rachid ». « Dont » réclamerait un complément en « de » du verbe ou du nom (« l''époque dont il parle »), construction absente de la phrase.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_relatif_ou_temps');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('33333333-b002-2100-0000-000000000001', '33333333-b002-1000-0000-000000000001', 'que', 'false', '1'),
  ('33333333-b002-2200-0000-000000000001', '33333333-b002-1000-0000-000000000001', 'qui', 'true', '2'),
  ('33333333-b002-2300-0000-000000000001', '33333333-b002-1000-0000-000000000001', 'dont', 'false', '3'),
  ('33333333-b002-2400-0000-000000000001', '33333333-b002-1000-0000-000000000001', 'où', 'false', '4'),

  ('33333333-b002-2100-0000-000000000002', '33333333-b002-1000-0000-000000000002', 'que', 'true', '1'),
  ('33333333-b002-2200-0000-000000000002', '33333333-b002-1000-0000-000000000002', 'qui', 'false', '2'),
  ('33333333-b002-2300-0000-000000000002', '33333333-b002-1000-0000-000000000002', 'où', 'false', '3'),
  ('33333333-b002-2400-0000-000000000002', '33333333-b002-1000-0000-000000000002', 'dont', 'false', '4'),

  ('33333333-b002-2100-0000-000000000003', '33333333-b002-1000-0000-000000000003', 'que', 'false', '1'),
  ('33333333-b002-2200-0000-000000000003', '33333333-b002-1000-0000-000000000003', 'qui', 'false', '2'),
  ('33333333-b002-2300-0000-000000000003', '33333333-b002-1000-0000-000000000003', 'dont', 'true', '3'),
  ('33333333-b002-2400-0000-000000000003', '33333333-b002-1000-0000-000000000003', 'où', 'false', '4'),

  ('33333333-b002-2100-0000-000000000004', '33333333-b002-1000-0000-000000000004', 'que', 'false', '1'),
  ('33333333-b002-2200-0000-000000000004', '33333333-b002-1000-0000-000000000004', 'où', 'false', '2'),
  ('33333333-b002-2300-0000-000000000004', '33333333-b002-1000-0000-000000000004', 'qui', 'false', '3'),
  ('33333333-b002-2400-0000-000000000004', '33333333-b002-1000-0000-000000000004', 'dont', 'true', '4'),

  ('33333333-b002-2100-0000-000000000005', '33333333-b002-1000-0000-000000000005', 'dont', 'false', '1'),
  ('33333333-b002-2200-0000-000000000005', '33333333-b002-1000-0000-000000000005', 'où', 'true', '2'),
  ('33333333-b002-2300-0000-000000000005', '33333333-b002-1000-0000-000000000005', 'que', 'false', '3'),
  ('33333333-b002-2400-0000-000000000005', '33333333-b002-1000-0000-000000000005', 'qui', 'false', '4'),

  ('33333333-b002-2100-0000-000000000006', '33333333-b002-1000-0000-000000000006', 'où', 'true', '1'),
  ('33333333-b002-2200-0000-000000000006', '33333333-b002-1000-0000-000000000006', 'que', 'false', '2'),
  ('33333333-b002-2300-0000-000000000006', '33333333-b002-1000-0000-000000000006', 'dont', 'false', '3'),
  ('33333333-b002-2400-0000-000000000006', '33333333-b002-1000-0000-000000000006', 'qui', 'false', '4'),

  ('33333333-b002-2100-0000-000000000007', '33333333-b002-1000-0000-000000000007', 'qui', 'false', '1'),
  ('33333333-b002-2200-0000-000000000007', '33333333-b002-1000-0000-000000000007', 'que', 'false', '2'),
  ('33333333-b002-2300-0000-000000000007', '33333333-b002-1000-0000-000000000007', 'où', 'false', '3'),
  ('33333333-b002-2400-0000-000000000007', '33333333-b002-1000-0000-000000000007', 'dont', 'true', '4'),

  ('33333333-b002-2100-0000-000000000008', '33333333-b002-1000-0000-000000000008', 'que', 'false', '1'),
  ('33333333-b002-2200-0000-000000000008', '33333333-b002-1000-0000-000000000008', 'dont', 'false', '2'),
  ('33333333-b002-2300-0000-000000000008', '33333333-b002-1000-0000-000000000008', 'qui', 'true', '3'),
  ('33333333-b002-2400-0000-000000000008', '33333333-b002-1000-0000-000000000008', 'où', 'false', '4'),

  ('33333333-b002-2100-0000-000000000009', '33333333-b002-1000-0000-000000000009', 'qui', 'false', '1'),
  ('33333333-b002-2200-0000-000000000009', '33333333-b002-1000-0000-000000000009', 'que', 'true', '2'),
  ('33333333-b002-2300-0000-000000000009', '33333333-b002-1000-0000-000000000009', 'dont', 'false', '3'),
  ('33333333-b002-2400-0000-000000000009', '33333333-b002-1000-0000-000000000009', 'où', 'false', '4'),

  ('33333333-b002-2100-0000-00000000000a', '33333333-b002-1000-0000-00000000000a', 'que', 'false', '1'),
  ('33333333-b002-2200-0000-00000000000a', '33333333-b002-1000-0000-00000000000a', 'dont', 'false', '2'),
  ('33333333-b002-2300-0000-00000000000a', '33333333-b002-1000-0000-00000000000a', 'où', 'true', '3'),
  ('33333333-b002-2400-0000-00000000000a', '33333333-b002-1000-0000-00000000000a', 'qui', 'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes (33333333-b002-1000-…-01..0a, choices 2100/2200/2300/2400).
-- [x] 4 propositions / 1 correcte par item ; toujours les 4 relatifs simples qui/que/où/dont.
-- [x] Distribution des bonnes réponses : pos1=2, pos2=3, pos3=3, pos4=2 (équilibrée, 4 positions utilisées).
-- [x] Tous les items sur les relatifs simples, mécanismes tous différents :
--     qui sujet, que COD, dont (parler de), dont (avoir besoin de), où temporel
--     malgré « se souvenir de » (piège), où de lieu, dont complément du nom,
--     qui sujet avec incise, que avec sujet inversé, où temporel (« à l''époque où »).
-- [x] Aucun point interdit (pas d''imparfait/PC testé, pas de y/en, subjonctif,
--     connecteurs+gérondif, comparatifs/accord PP).
-- [x] explanation ≥ 80 caractères, point clé en **gras**, règle nommée, 3 distracteurs démontés.
-- [x] Prénoms/villes variés et originaux (Amadou/Tours, Nadia, Bilal/Strasbourg,
--     Diego, Olena/Dijon, Besançon, Mariam, Rachid/Lille, Rennes).
-- [x] Apostrophes SQL doublées partout ; pas de medias/passages (SVG/SSML : N/A pour SL).
-- [x] Calibrage haut B1 : aucun trou suivi d''une voyelle quand « que » est correct
--     (pas de problème d''élision), contexte tranchant sans ambiguïté.
-- ============================================================================
