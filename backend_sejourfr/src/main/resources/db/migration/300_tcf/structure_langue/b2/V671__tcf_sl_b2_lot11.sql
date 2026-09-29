-- ============================================================================
-- V671 — TCF SL B2 — lot 11 (point : expressions figées)
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id 22222222-0000-0000-0000-000000000003, difficulty='B2'.
-- 7 items, tous sur les expressions figées (faire contre mauvaise fortune bon
-- cœur, faire la sourde oreille, ne pas être dans son assiette, jouer sur les
-- deux tableaux, mettre les bouchées doubles, mettre de l''eau dans son vin,
-- vendre la mèche). Contenu original, déterministe.
-- ============================================================================

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('33333333-c00b-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Quand le festival de Bayonne a été annulé, Bianca a fait contre mauvaise fortune ___ cœur. »',
   'Le **figement lexical** interdit toute substitution : l''expression est « faire contre mauvaise fortune **bon** cœur » (accepter un revers avec philosophie), et seul « bon » est admis. « Grand » appartient à une autre expression, « avoir grand cœur » (être généreux). « Gros » renvoie à « avoir le cœur gros » (être triste). « Léger » renvoie à « avoir le cœur léger » (être insouciant). Ces trois adjectifs existent avec « cœur », mais dans d''autres locutions : ici, le proverbe figé impose « bon ».',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_expressions_figees'),

  ('33333333-c00b-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Interpellé sur l''état des gymnases, le maire de Mulhouse a fait la sourde ___ pendant tout le conseil municipal. »',
   'L''expression figée est « faire la sourde **oreille** » : refuser délibérément d''entendre une demande. Le **figement** bloque les synonymes, même proches par le sens. « Ouïe » désigne bien le sens de l''audition, mais appartient à « avoir l''ouïe fine ». « Écoute » s''emploie dans « être à l''écoute », qui signifie l''inverse (se montrer attentif). « Voix » renvoie à « faire la grosse voix » (chercher à intimider). Seule « oreille » forme la locution attendue avec l''adjectif « sourde ».',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_expressions_figees'),

  ('33333333-c00b-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Depuis son déménagement à Limoges, Karim n''est plus dans son ___ : il dort mal et n''a goût à rien. »',
   'L''expression figée « ne pas être dans son **assiette** » signifie se sentir mal, physiquement ou moralement — le mot vient de l''ancien sens d''« assiette » : position, équilibre. Le **figement** exclut les autres récipients, pourtant tous plausibles. « Plat » appartient à « mettre les pieds dans le plat » (commettre une maladresse). « Bol » renvoie à « en avoir ras le bol » (être excédé). « Tasse » renvoie à « boire la tasse » (avaler de l''eau en nageant, ou subir un échec). Seule « assiette » exprime le malaise décrit.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_expressions_figees'),

  ('33333333-c00b-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « En négociant en secret avec deux fournisseurs concurrents, Nadia joue sur les deux ___. »',
   'L''expression figée est « jouer sur les deux **tableaux** » : ménager deux options opposées pour gagner dans tous les cas. Le **figement lexical** rejette les autres noms, qui appartiennent pourtant à des locutions voisines. « Terrains » évoque « trouver un terrain d''entente » (parvenir à un accord). « Fronts » évoque « être sur tous les fronts » (mener plusieurs combats à la fois, sans idée de duplicité). « Registres » évoque « changer de registre » (modifier son ton). Seul « tableaux » porte la nuance de double jeu intéressé.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_expressions_figees'),

  ('33333333-c00b-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Pour rendre le mémoire avant le 15 mars, Mariama a mis les bouchées ___ tout le week-end. »',
   'L''expression figée est « mettre les bouchées **doubles** » : accélérer fortement le rythme de travail, comme si l''on avalait deux bouchées à la fois. Le **figement** fixe l''adjectif une fois pour toutes : aucune gradation n''est permise. « Triples » est une surenchère logique mais inexistante dans la langue — l''expression ne se décline pas. « Larges » et « longues » sont des adjectifs courants avec d''autres noms (vues larges, dents longues), mais aucune locution « bouchées larges/longues » n''existe. Seul « doubles » est consacré par l''usage.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_expressions_figees'),

  ('33333333-c00b-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Après six mois de blocage à l''usine de Saint-Étienne, la direction a accepté de mettre de l''eau dans son ___. »',
   'L''expression figée est « mettre de l''eau dans son **vin** » : modérer ses exigences, faire des concessions. L''image vient du vin coupé d''eau, donc adouci — le **figement** rend la boisson non substituable. « Café » appartient à une autre locution, familière : « c''est fort de café » (c''est exagéré). « Thé » n''entre dans aucune expression française consacrée de ce type. « Lait » renvoie à « boire du petit-lait » (savourer un compliment ou une victoire). Seul « vin » exprime l''idée d''assouplir sa position.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_expressions_figees'),

  ('33333333-c00b-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « La fête d''anniversaire devait rester secrète, mais Théo a vendu la ___ dès le lundi matin. »',
   'L''expression figée est « vendre la **mèche** » : révéler un secret, trahir un projet préparé en cachette (la mèche était celle d''une mine que l''on dévoilait à l''ennemi). Le **figement** écarte les autres noms féminins, rattachés à d''autres locutions. « Ficelle » appartient à « tirer les ficelles » (manœuvrer en coulisse). « Corde » renvoie à « tirer sur la corde » (abuser d''une situation). « Perle » renvoie à « une perle rare » (une personne exceptionnelle). Seule « mèche » porte le sens de divulgation d''un secret.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_expressions_figees');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('33333333-c00b-2100-0000-000000000001', '33333333-c00b-1000-0000-000000000001', 'grand', 'false', '1'),
  ('33333333-c00b-2200-0000-000000000001', '33333333-c00b-1000-0000-000000000001', 'bon', 'true', '2'),
  ('33333333-c00b-2300-0000-000000000001', '33333333-c00b-1000-0000-000000000001', 'gros', 'false', '3'),
  ('33333333-c00b-2400-0000-000000000001', '33333333-c00b-1000-0000-000000000001', 'léger', 'false', '4'),

  ('33333333-c00b-2100-0000-000000000002', '33333333-c00b-1000-0000-000000000002', 'ouïe', 'false', '1'),
  ('33333333-c00b-2200-0000-000000000002', '33333333-c00b-1000-0000-000000000002', 'écoute', 'false', '2'),
  ('33333333-c00b-2300-0000-000000000002', '33333333-c00b-1000-0000-000000000002', 'oreille', 'true', '3'),
  ('33333333-c00b-2400-0000-000000000002', '33333333-c00b-1000-0000-000000000002', 'voix', 'false', '4'),

  ('33333333-c00b-2100-0000-000000000003', '33333333-c00b-1000-0000-000000000003', 'assiette', 'true', '1'),
  ('33333333-c00b-2200-0000-000000000003', '33333333-c00b-1000-0000-000000000003', 'plat', 'false', '2'),
  ('33333333-c00b-2300-0000-000000000003', '33333333-c00b-1000-0000-000000000003', 'bol', 'false', '3'),
  ('33333333-c00b-2400-0000-000000000003', '33333333-c00b-1000-0000-000000000003', 'tasse', 'false', '4'),

  ('33333333-c00b-2100-0000-000000000004', '33333333-c00b-1000-0000-000000000004', 'terrains', 'false', '1'),
  ('33333333-c00b-2200-0000-000000000004', '33333333-c00b-1000-0000-000000000004', 'fronts', 'false', '2'),
  ('33333333-c00b-2300-0000-000000000004', '33333333-c00b-1000-0000-000000000004', 'registres', 'false', '3'),
  ('33333333-c00b-2400-0000-000000000004', '33333333-c00b-1000-0000-000000000004', 'tableaux', 'true', '4'),

  ('33333333-c00b-2100-0000-000000000005', '33333333-c00b-1000-0000-000000000005', 'doubles', 'true', '1'),
  ('33333333-c00b-2200-0000-000000000005', '33333333-c00b-1000-0000-000000000005', 'triples', 'false', '2'),
  ('33333333-c00b-2300-0000-000000000005', '33333333-c00b-1000-0000-000000000005', 'larges', 'false', '3'),
  ('33333333-c00b-2400-0000-000000000005', '33333333-c00b-1000-0000-000000000005', 'longues', 'false', '4'),

  ('33333333-c00b-2100-0000-000000000006', '33333333-c00b-1000-0000-000000000006', 'café', 'false', '1'),
  ('33333333-c00b-2200-0000-000000000006', '33333333-c00b-1000-0000-000000000006', 'thé', 'false', '2'),
  ('33333333-c00b-2300-0000-000000000006', '33333333-c00b-1000-0000-000000000006', 'vin', 'true', '3'),
  ('33333333-c00b-2400-0000-000000000006', '33333333-c00b-1000-0000-000000000006', 'lait', 'false', '4'),

  ('33333333-c00b-2100-0000-000000000007', '33333333-c00b-1000-0000-000000000007', 'ficelle', 'false', '1'),
  ('33333333-c00b-2200-0000-000000000007', '33333333-c00b-1000-0000-000000000007', 'mèche', 'true', '2'),
  ('33333333-c00b-2300-0000-000000000007', '33333333-c00b-1000-0000-000000000007', 'corde', 'false', '3'),
  ('33333333-c00b-2400-0000-000000000007', '33333333-c00b-1000-0000-000000000007', 'perle', 'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes (33333333-c00b-1000-…-01..07 / choices 2100-2400).
-- [x] 4 propositions / 1 seule correcte par item ; options de même catégorie
--     (4 adjectifs ou 4 noms grammaticalement existants à chaque fois).
-- [x] Distribution des bonnes réponses : pos1:2, pos2:2, pos3:2, pos4:1
--     (4 positions utilisées, aucune ne dépasse 2).
-- [x] Point unique : expressions figées (contre mauvaise fortune bon cœur,
--     la sourde oreille, dans son assiette, les deux tableaux, les bouchées
--     doubles, de l''eau dans son vin, vendre la mèche) — aucun point de la
--     liste interdite (pas de relatifs composés, concordance, passif, etc.).
-- [x] explanation ≥ 80 caractères, nomme le **figement lexical** (gras) et
--     démonte chacun des 3 distracteurs en citant la locution dont il relève.
-- [x] Contextes tous différents (festival annulé, conseil municipal, déménagement
--     et moral, négociation fournisseurs, rendu de mémoire, conflit social en
--     usine, fête d''anniversaire surprise) ; prénoms et villes variés (Bianca/
--     Bayonne, Mulhouse, Karim/Limoges, Nadia, Mariama, Saint-Étienne, Théo).
-- [x] Contenu 100 % original ; pas de SVG ni SSML dans ce lot (items texte purs).
-- [x] Apostrophes SQL doublées ; pas de JSONB dans ce schéma (table choices).
-- ============================================================================
