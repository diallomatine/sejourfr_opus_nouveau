-- ============================================================================
-- V683 — TCF SL B2 — lot 23 (point : comparaison complexe (d'autant plus que, plus…plus…))
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id 22222222-0000-0000-0000-000000000003, difficulty='B2'.
-- 7 items, tous sur la comparaison complexe : corrélatives proportionnelles
-- (plus…plus, moins…plus), corrélation d'opposition (autant…autant) et cause
-- intensive/atténuante (d'autant plus/moins que). Contenu original, déterministe.
-- ============================================================================

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('33333333-c017-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Plus l''hiver approche à Strasbourg, ___ les journées raccourcissent. »',
   'La **corrélation proportionnelle « plus…, plus… »** exige « plus » nu en tête de chacune des deux propositions : les deux phénomènes évoluent ensemble. « davantage » existe mais ne peut pas ouvrir une corrélative — il se place après le verbe (« les journées raccourcissent davantage »). « autant » appartient à la corrélation d''opposition « autant…, autant… » et exigerait « autant » aussi dans la première proposition. « aussi » en tête de proposition exprimerait une conséquence avec inversion du sujet (« aussi les journées raccourcissent-elles »), pas une proportion.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_comparaison_complexe'),

  ('33333333-c017-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Moins Fatou passe de temps assise devant son ordinateur, ___ elle se sent en forme le soir. »',
   'C''est la **corrélation inverse « moins…, plus… »** : la diminution d''un fait (le temps assis) entraîne l''augmentation de l''autre (la forme) — le sens impose « plus ». « moins » est grammaticalement possible mais produit un contresens : rester moins assise ne peut pas dégrader sa forme. « autant » exigerait la symétrie « autant…, autant… » dès la première proposition. « tant » exprime l''intensité dans une cause finale (« tant elle bouge ») et ne fonctionne pas comme tête de corrélative proportionnelle.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_comparaison_complexe'),

  ('33333333-c017-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Le trajet entre Limoges et Brive a paru ___ long aux voyageurs que le train s''est arrêté deux fois en rase campagne. »',
   '**« d''autant plus + adjectif + que »** introduit une cause qui renforce le jugement : les deux arrêts imprévus expliquent pourquoi le trajet a semblé long. « si … que » et « tellement … que » expriment une conséquence : ils signifieraient que la longueur ressentie du trajet a provoqué les arrêts du train, ce qui est absurde. « aussi … que » est un comparatif d''égalité et exigerait un terme de comparaison (« aussi long que la veille »), pas une subordonnée causale.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_comparaison_complexe'),

  ('33333333-c017-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Karim mérite ___ d''éloges qu''il a préparé le concours d''aide-soignant seul, sans organisme de formation. »',
   '**« d''autant plus de + nom + que »** : la subordonnée exprime une cause qui intensifie la quantité — la préparation en autonomie justifie encore plus d''éloges. « autant de … que » établit une égalité et demanderait un comparant (« autant d''éloges que sa collègue »). « davantage de … que » et « bien plus de … que » sont des comparatifs de supériorité : leur « que » devrait introduire le terme comparé, pas une proposition causale complète.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_comparaison_complexe'),

  ('33333333-c017-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Olena s''inquiète ___ pour sa fille installée à Nantes que celle-ci lui téléphone chaque soir. »',
   '**« d''autant moins que »** introduit une cause qui atténue : les appels quotidiens rassurent, donc l''inquiétude diminue. « d''autant plus que » est la construction symétrique mais produit un contresens — un appel chaque soir ne peut pas nourrir l''inquiétude, il l''apaise. « beaucoup moins … que » est un comparatif de supériorité inversée dont le « que » devrait introduire un comparant (« que pour son fils »), pas une cause. « aussi peu … que » est un comparatif d''égalité, même problème de construction.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_comparaison_complexe'),

  ('33333333-c017-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « ___ Diego avançait dans la lecture de son contrat de bail, plus ses questions se multipliaient. »',
   'Le second membre « plus ses questions se multipliaient » impose la **corrélative « plus…, plus… »** : « plus » nu doit ouvrir aussi la première proposition. « À mesure que » exprime bien une progression, mais il ne se combine pas avec un « plus » corrélatif en seconde proposition (on dirait : « à mesure qu''il avançait, ses questions se multipliaient »). « D''autant plus que » introduit une cause placée après une principale, jamais en tête de la première proposition. « Tant que » signifie « aussi longtemps que » et ne crée aucune corrélation proportionnelle.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_comparaison_complexe'),

  ('33333333-c017-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « ___ Wei apprécie le calme de son village du Jura, autant son frère ne se voit vivre qu''à Marseille. »',
   'La **corrélation d''opposition « autant…, autant… »** met deux attitudes en parallèle contrasté et exige la symétrie : le second « autant » impose « Autant » en tête de la première proposition. « Plus » appellerait un corrélat proportionnel (« plus…, plus/moins… ») et exprimerait une évolution graduée, pas un parallèle figé. « D''autant que » introduit une justification après une principale, jamais en ouverture de corrélative. « Tellement » exprime l''intensité suivie d''une conséquence (« tellement … que ») et ne se construit pas en miroir avec « autant ».',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_comparaison_complexe');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('33333333-c017-2100-0000-000000000001', '33333333-c017-1000-0000-000000000001', 'davantage', 'false', '1'),
  ('33333333-c017-2200-0000-000000000001', '33333333-c017-1000-0000-000000000001', 'plus', 'true', '2'),
  ('33333333-c017-2300-0000-000000000001', '33333333-c017-1000-0000-000000000001', 'autant', 'false', '3'),
  ('33333333-c017-2400-0000-000000000001', '33333333-c017-1000-0000-000000000001', 'aussi', 'false', '4'),

  ('33333333-c017-2100-0000-000000000002', '33333333-c017-1000-0000-000000000002', 'plus', 'true', '1'),
  ('33333333-c017-2200-0000-000000000002', '33333333-c017-1000-0000-000000000002', 'moins', 'false', '2'),
  ('33333333-c017-2300-0000-000000000002', '33333333-c017-1000-0000-000000000002', 'autant', 'false', '3'),
  ('33333333-c017-2400-0000-000000000002', '33333333-c017-1000-0000-000000000002', 'tant', 'false', '4'),

  ('33333333-c017-2100-0000-000000000003', '33333333-c017-1000-0000-000000000003', 'aussi', 'false', '1'),
  ('33333333-c017-2200-0000-000000000003', '33333333-c017-1000-0000-000000000003', 'si', 'false', '2'),
  ('33333333-c017-2300-0000-000000000003', '33333333-c017-1000-0000-000000000003', 'd''autant plus', 'true', '3'),
  ('33333333-c017-2400-0000-000000000003', '33333333-c017-1000-0000-000000000003', 'tellement', 'false', '4'),

  ('33333333-c017-2100-0000-000000000004', '33333333-c017-1000-0000-000000000004', 'd''autant plus', 'true', '1'),
  ('33333333-c017-2200-0000-000000000004', '33333333-c017-1000-0000-000000000004', 'autant', 'false', '2'),
  ('33333333-c017-2300-0000-000000000004', '33333333-c017-1000-0000-000000000004', 'davantage', 'false', '3'),
  ('33333333-c017-2400-0000-000000000004', '33333333-c017-1000-0000-000000000004', 'bien plus', 'false', '4'),

  ('33333333-c017-2100-0000-000000000005', '33333333-c017-1000-0000-000000000005', 'd''autant plus', 'false', '1'),
  ('33333333-c017-2200-0000-000000000005', '33333333-c017-1000-0000-000000000005', 'beaucoup moins', 'false', '2'),
  ('33333333-c017-2300-0000-000000000005', '33333333-c017-1000-0000-000000000005', 'aussi peu', 'false', '3'),
  ('33333333-c017-2400-0000-000000000005', '33333333-c017-1000-0000-000000000005', 'd''autant moins', 'true', '4'),

  ('33333333-c017-2100-0000-000000000006', '33333333-c017-1000-0000-000000000006', 'À mesure que', 'false', '1'),
  ('33333333-c017-2200-0000-000000000006', '33333333-c017-1000-0000-000000000006', 'D''autant plus que', 'false', '2'),
  ('33333333-c017-2300-0000-000000000006', '33333333-c017-1000-0000-000000000006', 'Plus', 'true', '3'),
  ('33333333-c017-2400-0000-000000000006', '33333333-c017-1000-0000-000000000006', 'Tant que', 'false', '4'),

  ('33333333-c017-2100-0000-000000000007', '33333333-c017-1000-0000-000000000007', 'Plus', 'false', '1'),
  ('33333333-c017-2200-0000-000000000007', '33333333-c017-1000-0000-000000000007', 'Autant', 'true', '2'),
  ('33333333-c017-2300-0000-000000000007', '33333333-c017-1000-0000-000000000007', 'D''autant que', 'false', '3'),
  ('33333333-c017-2400-0000-000000000007', '33333333-c017-1000-0000-000000000007', 'Tellement', 'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes (33333333-c017-1000-…-01..07 / choices 2100-2400).
-- [x] 4 propositions / 1 seule correcte par item ; options de même catégorie
--     (adverbes/locutions corrélatives ou comparatives grammaticalement
--     existants à chaque fois).
-- [x] Distribution des bonnes réponses : pos1:2, pos2:2, pos3:2, pos4:1
--     (4 positions utilisées, aucune ne dépasse 2 — max 3 respecté).
-- [x] Point unique : comparaison complexe — plus…plus (1, 6), moins…plus (2),
--     d''autant plus + adj + que (3), d''autant plus de + nom + que (4),
--     d''autant moins que (5), autant…autant (7) — aucun point de la liste
--     interdite (pas de concessifs, cause/conséquence simples, hypothèse, etc.).
-- [x] explanation ≥ 80 caractères, nomme la règle (corrélation proportionnelle,
--     corrélation inverse, cause intensive/atténuante, corrélation d''opposition)
--     en **gras** et démonte chacun des 3 distracteurs.
-- [x] Contextes tous différents (journées d''hiver à Strasbourg, sédentarité et
--     forme physique, trajet ferroviaire Limoges-Brive, concours d''aide-soignant,
--     fille installée à Nantes, contrat de bail, village du Jura vs Marseille) ;
--     prénoms variés (Fatou, Karim, Olena, Diego, Wei).
-- [x] Contenu 100 % original ; pas de SVG ni SSML dans ce lot (items texte purs).
-- [x] Apostrophes SQL doublées ; pas de JSONB dans ce schéma (table choices).
-- ============================================================================
