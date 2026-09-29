-- ============================================================================
-- V677 — TCF SL B2 — lot 17 (point : accord du participe passé des verbes pronominaux)
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id 22222222-0000-0000-0000-000000000003, difficulty='B2'.
-- 7 items, tous sur l''accord du participe passé des verbes pronominaux
-- (pronom COD vs COI, COD antéposé/postposé, essentiellement pronominaux,
-- locutions figées type « se rendre compte »). Contenu original, déterministe.
-- ============================================================================

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('33333333-c011-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Fatou et sa cousine se sont ___ pendant plus d''une heure hier soir. »',
   'Avec « téléphoner », le pronom « se » est **complément d''objet indirect** (on téléphone **à** quelqu''un) : le participe passé d''un verbe pronominal reste **invariable** quand le pronom réfléchi est COI et qu''aucun COD ne précède → « téléphoné ». « téléphonées » applique à tort l''accord avec le sujet, valable seulement si « se » était COD. « téléphonés » cumule deux erreurs : accord injustifié et genre masculin alors que le sujet est féminin. « téléphonée » accorde au féminin singulier alors que, de toute façon, aucun accord n''est possible ici.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_accord_pp_pronominaux'),

  ('33333333-c011-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Avant de pétrir la pâte, Olena s''est soigneusement ___ les mains. »',
   'Le **COD est placé après le verbe** : Olena a lavé quoi ? « les mains » (le « s'' » est ici COI : elle lave les mains *à elle-même*). Or le participe passé d''un verbe pronominal ne s''accorde qu''avec un **COD antéposé** → « lavé », invariable. « lavée » accorde avec le sujet comme si « se » était COD — faux, le COD est « les mains » et il suit le verbe. « lavées » accorderait avec « les mains », ce qui ne vaudrait que si ce COD précédait (« les mains qu''elle s''est lavées »). « lavés » est un accord masculin pluriel sans aucun support dans la phrase.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_accord_pp_pronominaux'),

  ('33333333-c011-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Salma et Inès se sont ___ toute la semaine pour le concours d''éloquence de Nantes. »',
   'Ici « se » est **COD** : elles ont préparé qui ? elles-mêmes. Quand le pronom réfléchi est COD et précède le verbe, le participe passé **s''accorde avec ce COD**, donc avec le sujet féminin pluriel → « préparées ». « préparée » respecte le genre mais oublie le pluriel (deux personnes). « préparé » laisse le participe invariable comme si « se » était COI ou comme s''il y avait un COD postposé (« elles se sont préparé un café ») — ce n''est pas le cas ici. « préparés » accorde au masculin alors que les deux sujets sont féminins.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_accord_pp_pronominaux'),

  ('33333333-c011-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « En feuilletant l''album, Priya s''est ___ de ses premières vendanges en Bourgogne. »',
   '« Se souvenir » est un verbe **essentiellement pronominal** (il n''existe pas sans « se ») : son participe passé **s''accorde toujours avec le sujet** → « souvenue » (Priya, féminin singulier). « souvenu » laisse le participe invariable comme s''il s''agissait d''un pronominal à pronom COI (type « se téléphoner ») — la règle des essentiellement pronominaux l''exclut. « souvenues » et « souvenus » accordent au pluriel alors que le sujet est une seule personne, et « souvenus » se trompe en outre de genre.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_accord_pp_pronominaux'),

  ('33333333-c011-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Diego a relu toutes les cartes postales que Mariam et lui se sont ___ durant leurs deux ans à distance. »',
   'Avec « s''écrire », « se » est COI (on écrit **à** quelqu''un), mais il y a un **COD antéposé** : le relatif « que », mis pour « les cartes postales » (féminin pluriel). Le participe passé s''accorde alors avec ce COD placé avant → « écrites ». « écrit » serait correct sans COD antéposé (« ils se sont écrit pendant deux ans ») mais ignore ici le relatif. « écrite » accorde avec le bon genre mais oublie le pluriel des cartes. « écrits » accorde au masculin pluriel comme si le COD était masculin, or « carte postale » est féminin.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_accord_pp_pronominaux'),

  ('33333333-c011-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Amadou et Rachid se sont ___ compte trop tard que le devis du plombier comportait une erreur. »',
   'Dans la locution « **se rendre compte** », le COD est le nom « compte », **placé après le participe** : aucun accord n''est donc possible → « rendu », invariable. « rendus » applique mécaniquement l''accord avec le sujet masculin pluriel, en oubliant que « se » n''est pas COD ici (on rend compte *à soi-même*). « rendue » et « rendues » accordent au féminin alors que ni le sujet ni « compte » (masculin) ne le justifient — et l''accord est de toute façon bloqué par la position du COD.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_accord_pp_pronominaux'),

  ('33333333-c011-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Les pannes se sont ___ tout l''hiver dans l''atelier de céramique de Mme Nguyen. »',
   'Avec « se succéder », le pronom « se » est **COI** : une panne succède **à** une autre. Le participe passé d''un pronominal à pronom COI reste **invariable** en l''absence de COD antéposé → « succédé ». « succédées » est l''erreur classique : accorder avec le sujet féminin pluriel comme si « se » était COD — impossible, « succéder » n''admet pas de COD. « succédés » commet la même faute d''accord en y ajoutant un masculin injustifié. « succédée » accorde au féminin singulier alors que le verbe doit rester invariable.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_accord_pp_pronominaux');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('33333333-c011-2100-0000-000000000001', '33333333-c011-1000-0000-000000000001', 'téléphonées', 'false', '1'),
  ('33333333-c011-2200-0000-000000000001', '33333333-c011-1000-0000-000000000001', 'téléphoné', 'true', '2'),
  ('33333333-c011-2300-0000-000000000001', '33333333-c011-1000-0000-000000000001', 'téléphonés', 'false', '3'),
  ('33333333-c011-2400-0000-000000000001', '33333333-c011-1000-0000-000000000001', 'téléphonée', 'false', '4'),

  ('33333333-c011-2100-0000-000000000002', '33333333-c011-1000-0000-000000000002', 'lavé', 'true', '1'),
  ('33333333-c011-2200-0000-000000000002', '33333333-c011-1000-0000-000000000002', 'lavée', 'false', '2'),
  ('33333333-c011-2300-0000-000000000002', '33333333-c011-1000-0000-000000000002', 'lavées', 'false', '3'),
  ('33333333-c011-2400-0000-000000000002', '33333333-c011-1000-0000-000000000002', 'lavés', 'false', '4'),

  ('33333333-c011-2100-0000-000000000003', '33333333-c011-1000-0000-000000000003', 'préparé', 'false', '1'),
  ('33333333-c011-2200-0000-000000000003', '33333333-c011-1000-0000-000000000003', 'préparée', 'false', '2'),
  ('33333333-c011-2300-0000-000000000003', '33333333-c011-1000-0000-000000000003', 'préparés', 'false', '3'),
  ('33333333-c011-2400-0000-000000000003', '33333333-c011-1000-0000-000000000003', 'préparées', 'true', '4'),

  ('33333333-c011-2100-0000-000000000004', '33333333-c011-1000-0000-000000000004', 'souvenu', 'false', '1'),
  ('33333333-c011-2200-0000-000000000004', '33333333-c011-1000-0000-000000000004', 'souvenues', 'false', '2'),
  ('33333333-c011-2300-0000-000000000004', '33333333-c011-1000-0000-000000000004', 'souvenue', 'true', '3'),
  ('33333333-c011-2400-0000-000000000004', '33333333-c011-1000-0000-000000000004', 'souvenus', 'false', '4'),

  ('33333333-c011-2100-0000-000000000005', '33333333-c011-1000-0000-000000000005', 'écrites', 'true', '1'),
  ('33333333-c011-2200-0000-000000000005', '33333333-c011-1000-0000-000000000005', 'écrit', 'false', '2'),
  ('33333333-c011-2300-0000-000000000005', '33333333-c011-1000-0000-000000000005', 'écrite', 'false', '3'),
  ('33333333-c011-2400-0000-000000000005', '33333333-c011-1000-0000-000000000005', 'écrits', 'false', '4'),

  ('33333333-c011-2100-0000-000000000006', '33333333-c011-1000-0000-000000000006', 'rendus', 'false', '1'),
  ('33333333-c011-2200-0000-000000000006', '33333333-c011-1000-0000-000000000006', 'rendue', 'false', '2'),
  ('33333333-c011-2300-0000-000000000006', '33333333-c011-1000-0000-000000000006', 'rendu', 'true', '3'),
  ('33333333-c011-2400-0000-000000000006', '33333333-c011-1000-0000-000000000006', 'rendues', 'false', '4'),

  ('33333333-c011-2100-0000-000000000007', '33333333-c011-1000-0000-000000000007', 'succédées', 'false', '1'),
  ('33333333-c011-2200-0000-000000000007', '33333333-c011-1000-0000-000000000007', 'succédé', 'true', '2'),
  ('33333333-c011-2300-0000-000000000007', '33333333-c011-1000-0000-000000000007', 'succédés', 'false', '3'),
  ('33333333-c011-2400-0000-000000000007', '33333333-c011-1000-0000-000000000007', 'succédée', 'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes (33333333-c011-1000-…-01..07 / choices 2100-2400).
-- [x] 4 propositions / 1 seule correcte par item ; options de même catégorie
--     (4 formes du même participe passé, toutes grammaticalement existantes).
-- [x] Distribution des bonnes réponses : pos1:2, pos2:2, pos3:2, pos4:1
--     (4 positions utilisées, aucune ne dépasse 2).
-- [x] Point unique : accord du PP des verbes pronominaux — pronom COI invariable
--     (se téléphoner, se succéder), COD postposé (se laver les mains, se rendre
--     compte), pronom COD accordé (se préparer), essentiellement pronominal
--     (se souvenir), COD antéposé par relatif (les cartes qu''ils se sont
--     écrites) — aucun point de la liste interdite.
-- [x] explanation ≥ 80 caractères, règle nommée en **gras** (COI/COD antéposé/
--     essentiellement pronominal/locution figée) et démonte les 3 distracteurs.
-- [x] Contextes tous différents (appel téléphonique, cuisine, concours
--     d''éloquence, album photo et vendanges, correspondance à distance,
--     devis de plomberie, atelier de céramique) ; prénoms variés (Fatou, Olena,
--     Salma, Inès, Priya, Diego, Mariam, Amadou, Rachid, Mme Nguyen).
-- [x] Contenu 100 % original ; pas de SVG ni SSML dans ce lot (items texte purs).
-- [x] Apostrophes SQL doublées ; pas de JSONB dans ce schéma (table choices).
-- ============================================================================
