-- ============================================================================
-- V640 — TCF SL B1 — lot 06 (point : comparatifs / superlatifs + accord du participe passé (cas simples))
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id 22222222-0000-0000-0000-000000000003, difficulty='B1'.
-- 10 items, haut du B1 : meilleur (adjectif, accord) vs mieux (adverbe),
-- autant de + nom, superlatif « le mieux », superlatif de quantité « le plus
-- de », accord du participe passé avec être (sujet féminin pluriel, sujet
-- coordonné mixte), accord avec avoir (COD antéposé par « que », COD postposé
-- donc invariable, COD antéposé par le pronom « les »).
-- UUID déterministes, rejouables dev + recette.
-- ============================================================================

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('33333333-b006-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « Les résultats du bac blanc de Nadia sont ___ que ceux du premier trimestre, surtout en mathématiques. »',
   'Le point testé est le **comparatif de l''adjectif « bon »** : attribut du sujet après « être », il prend sa forme irrégulière « meilleur » et s''accorde avec « les résultats », masculin pluriel → « meilleurs ». « Mieux » est le comparatif de l''adverbe « bien » : il modifierait un verbe (« elle travaille mieux »), pas un nom via « être ». « Plus bons » n''existe pas en français standard : « bon » a un comparatif irrégulier obligatoire. « Meilleur » au singulier oublie l''accord avec le sujet pluriel « résultats ».',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_comparatif'),

  ('33333333-b006-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « Depuis qu''il a quitté son studio donnant sur le périphérique de Villeurbanne, Hugo dort ___ qu''avant. »',
   'Le mécanisme est le **comparatif de l''adverbe « bien »** : « dormir » réclame un adverbe, et le comparatif de « bien » est la forme irrégulière « mieux » → « dort mieux qu''avant ». « Meilleur » est le comparatif de l''adjectif « bon » : il qualifierait un nom (« un meilleur sommeil »), jamais directement le verbe « dort ». « Bien » seul ne porte pas la comparaison exigée par « qu''avant » — et la suite « bien qu''avant » serait lue comme la conjonction de concession « bien que ». « Le mieux » est un superlatif : il classerait Hugo au premier rang d''un groupe, alors qu''on compare seulement deux périodes de sa vie.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_comparatif'),

  ('33333333-b006-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « Malgré les travaux de la gare, le festival du livre de Saint-Malo a accueilli ___ de visiteurs que l''an dernier. »',
   'Il s''agit du **comparatif d''égalité portant sur un nom** : devant « de + nom » (« de visiteurs »), l''égalité s''exprime obligatoirement avec « autant de… que » → « autant ». « Aussi » marque l''égalité devant un adjectif ou un adverbe (« aussi fréquenté que »), jamais devant « de + nom ». « Si » et « tellement » sont des intensifs de conséquence : ils appelleraient un « que » consécutif (« tellement de visiteurs qu''il a fallu fermer les portes »), incompatible avec le « que » comparatif de « que l''an dernier ». Le sens confirme : « malgré les travaux », la fréquentation s''est maintenue au même niveau.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_comparatif'),

  ('33333333-b006-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « De toute l''équipe du chantier de Clermont-Ferrand, Mehdi connaît ___ les consignes de sécurité. »',
   'Le point testé est le **superlatif de l''adverbe « bien »** : le complément « de toute l''équipe » impose un classement au sommet d''un ensemble, et le superlatif de « bien » est « le mieux » (article « le » invariable + forme irrégulière) → « connaît le mieux ». « Le meilleur » est le superlatif de l''adjectif « bon » : il qualifierait une personne ou une chose (« le meilleur ouvrier »), pas le verbe « connaît ». « Mieux » seul est un comparatif : il exigerait un second terme en « que » et ne répond pas au cadre superlatif posé par « de toute l''équipe ». « Le plus bien » n''existe pas : « bien » possède un superlatif irrégulier obligatoire.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_superlatif'),

  ('33333333-b006-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « De tout le marché couvert de Dijon, l''étal de Madame Keita propose ___ fromages fermiers. »',
   'Le mécanisme est le **superlatif de quantité devant un nom** : la tournure figée « le plus de + nom », avec article « le » invariable, exprime la plus grande quantité → « le plus de fromages fermiers ». « Les plus de » accorde à tort l''article : dans cette structure, « le » ne varie jamais, même devant un nom pluriel. « Le plus » sans « de » ne peut pas introduire un nom : il modifierait un verbe (« c''est elle qui vend le plus »). « La plupart des » signifie « la majorité des » et décrirait une proportion interne à l''étal, alors que le complément « de tout le marché » exige un classement superlatif entre les étals.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_superlatif'),

  ('33333333-b006-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « Samira et ses deux filles sont ___ à Lyon dimanche soir pour le mariage d''une cousine. »',
   'La règle est l''**accord du participe passé avec l''auxiliaire « être »** : le participe s''accorde en genre et en nombre avec le sujet « Samira et ses deux filles », féminin pluriel → « arrivées ». « Arrivé » laisse le participe invariable, comme s''il était employé avec « avoir » et un COD postposé — règle inapplicable ici. « Arrivée » accorde au féminin mais oublie le pluriel du sujet coordonné (trois personnes). « Arrivés » choisit un masculin pluriel alors qu''aucun élément masculin n''apparaît dans le sujet.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_passe_compose_etre'),

  ('33333333-b006-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « Paolo et sa sœur sont ___ d''Argentine au printemps pour reprendre la ferme familiale près de Pau. »',
   'Le piège porte sur l''**accord avec « être » quand le sujet coordonné est mixte** : un masculin (« Paolo ») + un féminin (« sa sœur ») entraînent l''accord au masculin pluriel → « revenus ». « Revenues » est le piège de proximité : on accorde avec le nom le plus proche (« sa sœur ») au lieu de l''ensemble du sujet — erreur classique du haut B1. « Revenu » respecte le masculin mais ignore le pluriel des deux personnes. « Revenue » cumule les deux fautes : féminin et singulier pour un sujet mixte pluriel.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_passe_compose_etre'),

  ('33333333-b006-1000-0000-000000000008', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « Voici les photos que Hamid a ___ pendant la fête des voisins de sa résidence, à Créteil. »',
   'La règle testée est l''**accord du participe passé avec « avoir » quand le COD est antéposé** : le COD « les photos », repris par « que », est placé AVANT le verbe, donc le participe s''accorde avec lui, au féminin pluriel → « prises ». « Pris » applique la règle générale « avoir = invariable », qui ne vaut que lorsque le COD suit le verbe — ce n''est pas le cas ici. « Prise » accorde au féminin mais néglige le pluriel de « photos ». « Prit » est un passé simple (« il prit »), pas un participe passé : il ne peut pas se combiner avec l''auxiliaire « a ».',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_accord_pp_avoir'),

  ('33333333-b006-1000-0000-000000000009', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « Pendant sa convalescence à Tours, Leïla a ___ plusieurs cartes postales à ses anciennes collègues. »',
   'Le point clé : **avec « avoir », le participe reste invariable quand le COD est placé après le verbe**. Ici le COD « plusieurs cartes postales » suit le participe, donc aucun accord → « écrit ». « Écrites » accorde à tort avec un COD pourtant postposé — l''accord n''aurait lieu que si le COD précédait (« les cartes qu''elle a écrites »). « Écrite » invente un accord au féminin singulier sans aucun donneur d''accord antéposé. « Écrits » fait de même au masculin pluriel : aucun élément avant le verbe ne justifie cette marque.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_accord_pp_avoir'),

  ('33333333-b006-1000-0000-00000000000a', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « Ses lunettes, Nordine les a enfin ___ au fond de la poche de son manteau d''hiver. »',
   'Le mécanisme est l''**accord avec « avoir » quand le COD antéposé est un pronom** : « les » reprend « ses lunettes » (féminin pluriel) et précède l''auxiliaire, donc le participe s''accorde avec ce COD → « retrouvées ». La règle : avec « avoir », accord avec le COD **seulement s''il est placé avant** le verbe — condition remplie ici. « Retrouvé » garde l''invariabilité comme si le COD suivait le verbe. « Retrouvés » se trompe de genre : « lunettes » est féminin. « Retrouvée » respecte le genre mais pas le nombre, alors que « lunettes » est toujours pluriel.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_accord_pp_avoir');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('33333333-b006-2100-0000-000000000001', '33333333-b006-1000-0000-000000000001', 'mieux', 'false', '1'),
  ('33333333-b006-2200-0000-000000000001', '33333333-b006-1000-0000-000000000001', 'meilleurs', 'true', '2'),
  ('33333333-b006-2300-0000-000000000001', '33333333-b006-1000-0000-000000000001', 'plus bons', 'false', '3'),
  ('33333333-b006-2400-0000-000000000001', '33333333-b006-1000-0000-000000000001', 'meilleur', 'false', '4'),

  ('33333333-b006-2100-0000-000000000002', '33333333-b006-1000-0000-000000000002', 'mieux', 'true', '1'),
  ('33333333-b006-2200-0000-000000000002', '33333333-b006-1000-0000-000000000002', 'meilleur', 'false', '2'),
  ('33333333-b006-2300-0000-000000000002', '33333333-b006-1000-0000-000000000002', 'bien', 'false', '3'),
  ('33333333-b006-2400-0000-000000000002', '33333333-b006-1000-0000-000000000002', 'le mieux', 'false', '4'),

  ('33333333-b006-2100-0000-000000000003', '33333333-b006-1000-0000-000000000003', 'aussi', 'false', '1'),
  ('33333333-b006-2200-0000-000000000003', '33333333-b006-1000-0000-000000000003', 'tellement', 'false', '2'),
  ('33333333-b006-2300-0000-000000000003', '33333333-b006-1000-0000-000000000003', 'autant', 'true', '3'),
  ('33333333-b006-2400-0000-000000000003', '33333333-b006-1000-0000-000000000003', 'si', 'false', '4'),

  ('33333333-b006-2100-0000-000000000004', '33333333-b006-1000-0000-000000000004', 'mieux', 'false', '1'),
  ('33333333-b006-2200-0000-000000000004', '33333333-b006-1000-0000-000000000004', 'le meilleur', 'false', '2'),
  ('33333333-b006-2300-0000-000000000004', '33333333-b006-1000-0000-000000000004', 'le plus bien', 'false', '3'),
  ('33333333-b006-2400-0000-000000000004', '33333333-b006-1000-0000-000000000004', 'le mieux', 'true', '4'),

  ('33333333-b006-2100-0000-000000000005', '33333333-b006-1000-0000-000000000005', 'le plus de', 'true', '1'),
  ('33333333-b006-2200-0000-000000000005', '33333333-b006-1000-0000-000000000005', 'les plus de', 'false', '2'),
  ('33333333-b006-2300-0000-000000000005', '33333333-b006-1000-0000-000000000005', 'le plus', 'false', '3'),
  ('33333333-b006-2400-0000-000000000005', '33333333-b006-1000-0000-000000000005', 'la plupart des', 'false', '4'),

  ('33333333-b006-2100-0000-000000000006', '33333333-b006-1000-0000-000000000006', 'arrivé', 'false', '1'),
  ('33333333-b006-2200-0000-000000000006', '33333333-b006-1000-0000-000000000006', 'arrivée', 'false', '2'),
  ('33333333-b006-2300-0000-000000000006', '33333333-b006-1000-0000-000000000006', 'arrivés', 'false', '3'),
  ('33333333-b006-2400-0000-000000000006', '33333333-b006-1000-0000-000000000006', 'arrivées', 'true', '4'),

  ('33333333-b006-2100-0000-000000000007', '33333333-b006-1000-0000-000000000007', 'revenu', 'false', '1'),
  ('33333333-b006-2200-0000-000000000007', '33333333-b006-1000-0000-000000000007', 'revenue', 'false', '2'),
  ('33333333-b006-2300-0000-000000000007', '33333333-b006-1000-0000-000000000007', 'revenus', 'true', '3'),
  ('33333333-b006-2400-0000-000000000007', '33333333-b006-1000-0000-000000000007', 'revenues', 'false', '4'),

  ('33333333-b006-2100-0000-000000000008', '33333333-b006-1000-0000-000000000008', 'pris', 'false', '1'),
  ('33333333-b006-2200-0000-000000000008', '33333333-b006-1000-0000-000000000008', 'prises', 'true', '2'),
  ('33333333-b006-2300-0000-000000000008', '33333333-b006-1000-0000-000000000008', 'prise', 'false', '3'),
  ('33333333-b006-2400-0000-000000000008', '33333333-b006-1000-0000-000000000008', 'prit', 'false', '4'),

  ('33333333-b006-2100-0000-000000000009', '33333333-b006-1000-0000-000000000009', 'écrit', 'true', '1'),
  ('33333333-b006-2200-0000-000000000009', '33333333-b006-1000-0000-000000000009', 'écrite', 'false', '2'),
  ('33333333-b006-2300-0000-000000000009', '33333333-b006-1000-0000-000000000009', 'écrits', 'false', '3'),
  ('33333333-b006-2400-0000-000000000009', '33333333-b006-1000-0000-000000000009', 'écrites', 'false', '4'),

  ('33333333-b006-2100-0000-00000000000a', '33333333-b006-1000-0000-00000000000a', 'retrouvé', 'false', '1'),
  ('33333333-b006-2200-0000-00000000000a', '33333333-b006-1000-0000-00000000000a', 'retrouvés', 'false', '2'),
  ('33333333-b006-2300-0000-00000000000a', '33333333-b006-1000-0000-00000000000a', 'retrouvée', 'false', '3'),
  ('33333333-b006-2400-0000-00000000000a', '33333333-b006-1000-0000-00000000000a', 'retrouvées', 'true', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes (33333333-b006-1000-…-01..0a, choices 2100/2200/2300/2400).
-- [x] 4 propositions / 1 correcte par item ; options de même catégorie à chaque fois
--     (formes de bon/bien, intensifs devant « de + nom », expressions de quantité,
--     4 formes du même participe).
-- [x] Distribution des bonnes réponses : pos1=3, pos2=2, pos3=2, pos4=3 (équilibrée, 4 positions).
-- [x] Tous les items sur comparatifs/superlatifs + accord du PP, mécanismes tous différents :
--     meilleur (adjectif accordé), mieux (adverbe), autant de + nom, le mieux (superlatif
--     d''adverbe), le plus de + nom, être + sujet fém. pluriel, être + sujet mixte (piège
--     de proximité), avoir + COD antéposé par « que », avoir + COD postposé (invariable),
--     avoir + COD pronom « les ».
-- [x] Aucun point interdit testé : « que » (item 8) et « les » (item 0a) servent uniquement
--     de véhicules à l''antéposition du COD — le choix porte sur l''accord du participe,
--     jamais sur le relatif ou le pronom. Pas d''imparfait/PC, pas de y/en, pas de
--     subjonctif, pas de connecteurs/gérondif.
-- [x] competence_code conformes : struct_comparatif ×3, struct_superlatif ×2,
--     struct_passe_compose_etre ×2, struct_accord_pp_avoir ×3.
-- [x] explanation ≥ 80 caractères, point clé en **gras**, règle nommée, 3 distracteurs démontés.
-- [x] Contextes tous différents (bac blanc, sommeil, festival, chantier, marché, mariage,
--     ferme familiale, fête des voisins, convalescence, lunettes perdues) ; prénoms/villes
--     variés (Nadia, Hugo, Mehdi, Mme Keita, Samira, Paolo, Hamid, Leïla, Nordine —
--     Villeurbanne, Saint-Malo, Clermont-Ferrand, Dijon, Lyon, Pau, Créteil, Tours).
-- [x] Apostrophes SQL doublées partout ; pas de medias/passages (SVG/SSML : N/A pour SL).
-- [x] Calibrage haut B1 : pièges fins (proximité, « bien que », plus bons, les plus de),
--     contexte qui tranche sans ambiguïté.
-- ============================================================================
