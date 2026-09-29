-- ============================================================================
-- V668 — TCF SL B2 — lot 08 (point : paronymes)
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id 22222222-0000-0000-0000-000000000003, difficulty='B2'.
-- 7 items, tous sur les paronymes (imminent/éminent, invoquer/évoquer,
-- effraction/infraction, conjoncture/conjecture, allocution/allocation,
-- recouvrer/recouvrir, collision/collusion). Contenu original, déterministe.
-- ============================================================================

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('33333333-c008-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « L''éruption du volcan étant jugée ___, les autorités ont fait évacuer le village en pleine nuit. »',
   'Il faut distinguer les **paronymes en -minent/-manent** : « imminent » signifie « qui va se produire d''un instant à l''autre », seul sens compatible avec une évacuation d''urgence. « Éminent » signifie « remarquable, de grande valeur » (un éminent volcanologue) et ne qualifie pas un événement à venir. « Immanent », terme de philosophie, désigne ce qui est contenu dans la nature même d''une chose (une justice immanente). « Permanent » signifie « qui dure sans interruption », ce qui contredit l''idée d''un danger soudain qui déclenche une évacuation nocturne.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_paronymes'),

  ('33333333-c008-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Pour contester son amende, Rachid a ___ un vice de procédure devant le tribunal de police. »',
   'Parmi ces **paronymes de la famille de « voquer »**, seul « invoqué » convient : « invoquer » = faire valoir quelque chose comme argument ou justification à l''appui de sa cause (invoquer un texte de loi, un vice de procédure). « Évoqué » = mentionner, rappeler au passage, sans valeur d''argument juridique — trop faible ici, où Rachid s''appuie sur ce vice pour contester. « Révoqué » = destituer quelqu''un de ses fonctions ou annuler un acte (révoquer un fonctionnaire, une donation). « Convoqué » = appeler officiellement quelqu''un à se présenter (convoquer un témoin) — on ne « convoque » pas un argument.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_paronymes'),

  ('33333333-c008-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Les cambrioleurs ont pénétré par ___ dans la bijouterie de la rue Gambetta avant l''aube. »',
   'Le **couple de paronymes effraction/infraction** est le piège classique : « effraction » désigne le fait de forcer une serrure, une porte ou une fenêtre pour entrer — c''est le terme consacré de l''expression « pénétrer par effraction ». « Infraction » désigne toute violation d''une règle de droit (commettre une infraction au code de la route) : le cambriolage EST une infraction, mais on n''entre pas « par infraction ». « Extraction » = action de retirer quelque chose (l''extraction d''une dent, du minerai). « Attraction » = force qui attire ou divertissement (une attraction touristique) — hors sujet.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_paronymes'),

  ('33333333-c008-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Dans une ___ économique aussi incertaine, la coopérative de Mariam préfère reporter ses investissements. »',
   'Les **paronymes conjoncture/conjecture** se confondent souvent : « conjoncture » désigne la situation d''ensemble qui résulte d''un concours de circonstances, notamment économiques (une conjoncture favorable, défavorable) — c''est le seul mot qui se combine avec « économique ». « Conjecture » = supposition, hypothèse fondée sur des probabilités (se perdre en conjectures). « Conjonction » = rencontre, réunion de plusieurs éléments, ou catégorie grammaticale (la conjonction « mais »). « Jonction » = point de contact ou de raccordement entre deux choses (la jonction de deux autoroutes) — aucun de ces trois ne décrit un climat économique.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_paronymes'),

  ('33333333-c008-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « La directrice du conservatoire de Pau a prononcé une courte ___ pour remercier les mécènes du festival. »',
   'Parmi ces **paronymes en -location/-locution**, seul « allocution » convient : une « allocution » est un discours bref prononcé par une personnalité dans une circonstance officielle — et c''est le seul nom qui se construit avec « prononcer ». « Allocation » = somme d''argent versée par un organisme (les allocations familiales) : on attribue ou verse une allocation, on ne la prononce pas. « Élocution » = manière articulée de s''exprimer oralement (avoir une bonne élocution) : c''est une qualité, pas un acte de parole ponctuel. « Locution » = groupe de mots figé formant une unité (une locution adverbiale) — terme de grammaire, hors contexte.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_paronymes'),

  ('33333333-c008-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Après son opération du genou, Tomas a enfin ___ l''usage complet de sa jambe gauche. »',
   'Le **couple de paronymes recouvrer/recouvrir** est déterminant : « recouvrer » signifie « retrouver ce qu''on avait perdu » (recouvrer la santé, la vue, l''usage d''un membre) → participe passé « recouvré ». « Recouvert » vient de « recouvrir » = mettre une couverture, une couche sur quelque chose (recouvrir un livre, un toit) : on ne « recouvre » pas l''usage d''une jambe. « Recouru » vient de « recourir à » = faire appel à (recourir à un avocat), construction impossible avec un COD direct ici. « Recoupé » vient de « recouper » = couper de nouveau ou confirmer par croisement (recouper des informations) — aucun rapport avec une convalescence.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_paronymes'),

  ('33333333-c008-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Sur le périphérique de Nantes, une ___ entre un bus et une camionnette a fait trois blessés légers ce matin. »',
   'Les **paronymes collision/collusion** ne doivent pas être confondus : « collision » désigne le choc matériel entre deux corps ou véhicules en mouvement — seul sens compatible avec un accident de la route et des blessés. « Collusion » désigne une entente secrète entre deux parties au détriment d''un tiers (une collusion entre un élu et une entreprise) : aucun choc physique. « Collation » = repas léger (une collation servie à la pause). « Coalition » = alliance de pays, de partis ou de groupes en vue d''un objectif commun (une coalition gouvernementale) — rien à voir avec deux véhicules qui se percutent.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_paronymes');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('33333333-c008-2100-0000-000000000001', '33333333-c008-1000-0000-000000000001', 'éminente', 'false', '1'),
  ('33333333-c008-2200-0000-000000000001', '33333333-c008-1000-0000-000000000001', 'imminente', 'true', '2'),
  ('33333333-c008-2300-0000-000000000001', '33333333-c008-1000-0000-000000000001', 'immanente', 'false', '3'),
  ('33333333-c008-2400-0000-000000000001', '33333333-c008-1000-0000-000000000001', 'permanente', 'false', '4'),

  ('33333333-c008-2100-0000-000000000002', '33333333-c008-1000-0000-000000000002', 'évoqué', 'false', '1'),
  ('33333333-c008-2200-0000-000000000002', '33333333-c008-1000-0000-000000000002', 'révoqué', 'false', '2'),
  ('33333333-c008-2300-0000-000000000002', '33333333-c008-1000-0000-000000000002', 'convoqué', 'false', '3'),
  ('33333333-c008-2400-0000-000000000002', '33333333-c008-1000-0000-000000000002', 'invoqué', 'true', '4'),

  ('33333333-c008-2100-0000-000000000003', '33333333-c008-1000-0000-000000000003', 'effraction', 'true', '1'),
  ('33333333-c008-2200-0000-000000000003', '33333333-c008-1000-0000-000000000003', 'infraction', 'false', '2'),
  ('33333333-c008-2300-0000-000000000003', '33333333-c008-1000-0000-000000000003', 'extraction', 'false', '3'),
  ('33333333-c008-2400-0000-000000000003', '33333333-c008-1000-0000-000000000003', 'attraction', 'false', '4'),

  ('33333333-c008-2100-0000-000000000004', '33333333-c008-1000-0000-000000000004', 'conjecture', 'false', '1'),
  ('33333333-c008-2200-0000-000000000004', '33333333-c008-1000-0000-000000000004', 'conjonction', 'false', '2'),
  ('33333333-c008-2300-0000-000000000004', '33333333-c008-1000-0000-000000000004', 'conjoncture', 'true', '3'),
  ('33333333-c008-2400-0000-000000000004', '33333333-c008-1000-0000-000000000004', 'jonction', 'false', '4'),

  ('33333333-c008-2100-0000-000000000005', '33333333-c008-1000-0000-000000000005', 'allocation', 'false', '1'),
  ('33333333-c008-2200-0000-000000000005', '33333333-c008-1000-0000-000000000005', 'allocution', 'true', '2'),
  ('33333333-c008-2300-0000-000000000005', '33333333-c008-1000-0000-000000000005', 'élocution', 'false', '3'),
  ('33333333-c008-2400-0000-000000000005', '33333333-c008-1000-0000-000000000005', 'locution', 'false', '4'),

  ('33333333-c008-2100-0000-000000000006', '33333333-c008-1000-0000-000000000006', 'recouvré', 'true', '1'),
  ('33333333-c008-2200-0000-000000000006', '33333333-c008-1000-0000-000000000006', 'recouvert', 'false', '2'),
  ('33333333-c008-2300-0000-000000000006', '33333333-c008-1000-0000-000000000006', 'recouru', 'false', '3'),
  ('33333333-c008-2400-0000-000000000006', '33333333-c008-1000-0000-000000000006', 'recoupé', 'false', '4'),

  ('33333333-c008-2100-0000-000000000007', '33333333-c008-1000-0000-000000000007', 'collusion', 'false', '1'),
  ('33333333-c008-2200-0000-000000000007', '33333333-c008-1000-0000-000000000007', 'collation', 'false', '2'),
  ('33333333-c008-2300-0000-000000000007', '33333333-c008-1000-0000-000000000007', 'collision', 'true', '3'),
  ('33333333-c008-2400-0000-000000000007', '33333333-c008-1000-0000-000000000007', 'coalition', 'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes (33333333-c008-1000-…-01..07 / choices 2100-2400).
-- [x] 4 propositions / 1 seule correcte par item ; options de même catégorie
--     (4 adjectifs, 4 participes passés ou 4 noms paronymiques, tous existants).
-- [x] Distribution des bonnes réponses : pos1:2, pos2:2, pos3:2, pos4:1
--     (4 positions utilisées, aucune ne dépasse 2).
-- [x] Point unique : paronymes (imminent/éminent/immanent/permanent,
--     invoquer/évoquer/révoquer/convoquer, effraction/infraction,
--     conjoncture/conjecture, allocution/allocation/élocution/locution,
--     recouvrer/recouvrir/recourir/recouper, collision/collusion/collation/
--     coalition) — aucun point de la liste interdite.
-- [x] explanation ≥ 80 caractères, nomme le couple de paronymes (**gras**)
--     avec la définition de chaque terme et démonte chacun des 3 distracteurs.
-- [x] Contextes tous différents (évacuation volcanique, contestation d''amende,
--     cambriolage de bijouterie, investissements d''une coopérative, discours
--     d''inauguration à Pau, convalescence après opération, accident de la route
--     à Nantes) ; prénoms variés (Rachid, Mariam, Tomas).
-- [x] Contenu 100 % original ; pas de SVG ni SSML dans ce lot (items texte purs).
-- [x] Apostrophes SQL doublées ; pas de JSONB dans ce schéma (table choices).
-- ============================================================================
